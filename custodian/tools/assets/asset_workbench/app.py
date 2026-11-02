"""Optional Textual FAMILY navigator over the read-only Asset V2 service."""

from __future__ import annotations

from textual.app import App, ComposeResult
from PIL import Image, ImageDraw
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.widgets import Button, Footer, Header, Input, Select, Static, Tree
from textual_image.widget import AutoImage

from .browser import AssetWorkbenchBrowser
from .service import AssetWorkbenchService
from .review import AssetReviewService, ReviewRepresentation, compare_frames, extract_frames, scale_frame_nearest, side_by_side_frames


class AssetWorkbenchApp(App[None]):
    TITLE = "Asset Workbench"
    SUB_TITLE = "FAMILY · read only"
    BINDINGS = [("q", "quit", "Quit"), ("r", "refresh", "Refresh")]
    CSS = """
    Screen { layout: vertical; }
    #main { height: 1fr; }
    #navigation { width: 42%; min-width: 34; border: round $primary; padding: 0 1; }
    #detail-pane { width: 1fr; border: round $secondary; padding: 0 1; }
    #search { margin-bottom: 1; }
    #family-tree { height: 1fr; }
    #activity { height: auto; min-height: 1; padding: 0 1; background: $surface; }
    #detail { height: 1fr; overflow-y: auto; }
    #review-panel { height: 1fr; }
    #review-image { height: 1fr; align: center middle; }
    #review-tools { height: auto; }
    #review-filmstrip { height: 6; max-height: 8; overflow-x: auto; }
    #filmstrip-image { width: auto; height: auto; }
    """

    def __init__(self, service: AssetWorkbenchService | None = None, review_service: AssetReviewService | None = None) -> None:
        super().__init__()
        self.browser = AssetWorkbenchBrowser(service or AssetWorkbenchService())
        project_dir = getattr(service, "project_dir", None)
        self.review_service = review_service or (AssetReviewService(project_dir) if project_dir is not None else AssetReviewService())
        self._search = ""
        self._review_mode = False
        self._representations: tuple[ReviewRepresentation, ...] = ()
        self._selected_representation = 0
        self._frames: tuple[Image.Image, ...] = ()
        self._frame_index = 0
        self._playing = False
        self._loop = True
        self._comparison = "single"
        self._compare_representation = 0
        self._play_timer = None
        self._zoom = 1

    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal(id="main"):
            with Vertical(id="navigation"):
                yield Input(placeholder="Search family, state, layer, action…", id="search")
                yield Button("Refresh Asset V2", id="refresh", variant="primary")
                yield Button("Open REVIEW", id="review-mode")
                yield Tree("Asset families", id="family-tree")
            with Vertical(id="detail-pane"):
                yield Static("Loading Asset V2…", id="detail", markup=False)
                with Vertical(id="review-panel"):
                    yield Select([], prompt="Representation", id="representation")
                    yield Select([(label, value) for label, value in (("Single", "single"), ("Side by side", "side"), ("Overlay", "overlay"), ("Pixel diff", "diff"))], value="single", id="comparison")
                    yield Select([], prompt="Compare with", id="compare-representation")
                    yield Select([(f"{zoom}× integer", str(zoom)) for zoom in (1, 2, 3, 4)], value="1", id="zoom")
                    with Horizontal(id="review-tools"):
                        yield Button("◀ Frame", id="previous-frame")
                        yield Button("Play", id="play")
                        yield Button("Loop: on", id="loop")
                        yield Button("Frame ▶", id="next-frame")
                        yield Static("Frame 0 / 0", id="frame-status", markup=False)
                    yield AutoImage(id="review-image")
                    yield Static("Select an Asset V2 state to review.", id="review-diagnostics", markup=False)
                    with VerticalScroll(id="review-filmstrip"):
                        yield AutoImage(id="filmstrip-image")
                    yield Select([], prompt="Select frame", id="frame-select")
        yield Static("Read only · no asset files are changed", id="activity", markup=False)
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#family-tree", Tree).show_root = False
        self.query_one("#review-panel").display = False
        result = self.browser.refresh()
        self._populate_tree()
        self._render_detail()
        self._set_activity(result.message)

    def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id != "search":
            return
        self._search = event.value
        self._populate_tree()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        identity = event.button.id
        if identity == "refresh": self.action_refresh()
        elif identity == "review-mode": self._set_review_mode(not self._review_mode)
        elif identity == "previous-frame": self._select_frame(self._frame_index - 1)
        elif identity == "next-frame": self._select_frame(self._frame_index + 1)
        elif identity == "play":
            if self._playing:
                self._stop_playback()
            else:
                item = self._representations[self._selected_representation]
                if item.fps is not None and self._frames:
                    self._playing = True
                    event.button.label = "Pause"
                    self._play_timer = self.set_interval(1.0 / item.fps, self._advance_review)
        elif identity == "loop":
            self._loop = not self._loop
            event.button.label = f"Loop: {'on' if self._loop else 'off'}"
        elif identity.startswith("frame-"):
            try: self._select_frame(int(identity.removeprefix("frame-")))
            except ValueError: return

    def action_refresh(self) -> None:
        previous = self._current_representation_identity() if self._review_mode else None
        result = self.browser.refresh()
        self._populate_tree()
        self._render_detail()
        self._set_activity(result.message)
        if self._review_mode:
            self._load_review(previous_representation=previous)

    def on_tree_node_selected(self, event: Tree.NodeSelected) -> None:
        identity = event.node.data
        if not isinstance(identity, tuple) or len(identity) != 3:
            return
        family_id, state_id, is_family = identity
        if is_family:
            self.browser.select_family(family_id)
        else:
            self.browser.select_state(family_id, state_id)
        self._render_detail()
        if self._review_mode:
            self._load_review()

    def on_select_changed(self, event: Select.Changed) -> None:
        if event.select.id == "representation":
            try: self._selected_representation = int(event.value)
            except (TypeError, ValueError): return
            self._load_review_frames()
        elif event.select.id == "compare-representation":
            try: self._compare_representation = int(event.value)
            except (TypeError, ValueError): return
            self._render_review_frame()
        elif event.select.id == "comparison":
            self._comparison = str(event.value)
            self.query_one("#compare-representation", Select).display = self._comparison != "single"
            self._render_review_frame()
        elif event.select.id == "frame-select":
            try: self._select_frame(int(event.value))
            except (TypeError, ValueError): return
        elif event.select.id == "zoom":
            try: self._zoom = int(event.value)
            except (TypeError, ValueError): return
            self._render_review_frame()

    def _populate_tree(self) -> None:
        tree = self.query_one("#family-tree", Tree)
        tree.root.remove_children()
        selected_node = None
        for family in self.browser.visible_families(self._search):
            family_node = tree.root.add(
                f"{family.family_id} · {family.kind} · required {family.required_completeness}",
                data=(family.family_id, None, True),
            )
            family_node.expand()
            if family.family_id == self.browser.selected_family_id:
                selected_node = family_node
            for state in self.browser.visible_states(family, self._search):
                if state.art_present:
                    presence = "ART PRESENT"
                elif state.source_pending:
                    presence = "SOURCE STAGED"
                else:
                    presence = "MISSING"
                state_node = family_node.add(
                    f"{state.role.upper()} · {state.state_id} · {presence}",
                    data=(family.family_id, state.state_id, False),
                )
                if (family.family_id, state.state_id) == (
                    self.browser.selected_family_id,
                    self.browser.selected_state_id,
                ):
                    selected_node = state_node
        if selected_node is not None:
            tree.move_cursor(selected_node)

    def _render_detail(self) -> None:
        detail = self.query_one("#detail", Static)
        family = self.browser.selected_family
        if family is None:
            detail.update("No Asset V2 family is selected.")
            return
        lines = [
            f"FAMILY  {family.family_id}",
            f"Kind: {family.kind}",
            f"Required completeness: {family.required_completeness}",
            f"Canvas: {family.canvas_width} × {family.canvas_height}",
            f"Direction policy: {family.direction_policy} ({', '.join(family.allowed_directions)})",
            f"Auto mirror: {'yes' if family.auto_mirror else 'no'}",
            f"Inbox: {'present' if family.inbox_exists else 'missing'}",
            "Pending source files: " + (", ".join(family.inbox_pending_filenames) or "none"),
            "Consumers:",
        ]
        if family.consumers:
            lines.extend("  " + ", ".join(f"{key}={value}" for key, value in consumer) for consumer in family.consumers)
        else:
            lines.append("  none declared")
        lines.append(f"Runtime outputs: {len(family.runtime_outputs)}")

        state = self.browser.selected_state
        if state is not None:
            lines.extend([
                "",
                f"STATE  {state.state_id}",
                f"Role: {state.role}",
                f"Layer / action group: {state.layer} / {state.action_group}",
                f"Contract: {'animated' if state.animation else 'static'}",
                f"Frame size: {state.frame_width} × {state.frame_height}",
                f"Expected frames: {state.expected_frames if state.expected_frames is not None else 'not declared'}",
                f"FPS: {state.fps if state.fps is not None else 'not declared'}",
                f"Minimum directions: {state.min_direction_count}",
                "Required directions: " + (", ".join(state.required_directions) or "none"),
                "Authored runtime directions: " + (", ".join(state.authored_directions) or "none"),
                "Mirrored runtime directions: " + (", ".join(state.mirrored_directions) or "none"),
                f"Source pending: {'yes' if state.source_pending else 'no'}",
                f"Art present: {'yes' if state.art_present else 'no'}",
                f"Imported: {'yes' if state.imported else 'no'}",
                f"Bound: {'yes' if state.bound else 'no'}",
                f"Runtime verified: {'yes' if state.runtime_verified else 'not verified'}",
                f"Runtime path: {state.runtime_path or 'none'}",
            ])
        detail.update("\n".join(lines))

    def _set_review_mode(self, enabled: bool) -> None:
        self._review_mode = enabled
        self.sub_title = "REVIEW · read only" if enabled else "FAMILY · read only"
        self.query_one("#detail", Static).display = not enabled
        self.query_one("#review-panel").display = enabled
        self.query_one("#review-mode", Button).label = "Open FAMILY" if enabled else "Open REVIEW"
        if enabled:
            self._load_review()

    def _current_representation_identity(self):
        if not (0 <= self._selected_representation < len(self._representations)):
            return None
        item = self._representations[self._selected_representation]
        return item.kind, item.direction, item.source_path

    def _load_review(self, previous_representation=None) -> None:
        family_id, state_id = self.browser.selected_family_id, self.browser.selected_state_id
        if not family_id or not state_id:
            self._representations = ()
            self._frames = ()
            self._set_review_message("Select a family state before opening REVIEW.")
            return
        try:
            result = self.review_service.representations(family_id, state_id)
        except Exception as error:
            self._representations = ()
            self._frames = ()
            self.query_one("#representation", Select).set_options([])
            self.query_one("#compare-representation", Select).set_options([])
            self._load_review_frames()
            self._set_review_message(f"Review load failed; FAMILY selection and accepted snapshot remain available: {error}")
            return
        self._representations = result.representations
        preserved = next((i for i, item in enumerate(self._representations)
                          if previous_representation == (item.kind, item.direction, item.source_path)), None)
        self._selected_representation = preserved if preserved is not None else next((i for i, item in enumerate(self._representations) if item.kind == "runtime" and item.trusted), 0)
        self._compare_representation = next((i for i, item in enumerate(self._representations) if item.kind == "staged"), 0)
        options = [(self._representation_label(item), str(i)) for i, item in enumerate(self._representations)]
        self.query_one("#representation", Select).set_options(options)
        self.query_one("#compare-representation", Select).set_options(options)
        if options:
            self.query_one("#representation", Select).value = str(self._selected_representation)
            self.query_one("#compare-representation", Select).value = str(self._compare_representation)
        self._frame_index = 0
        self._load_review_frames()
        if previous_representation is not None and preserved is None:
            message = "The selected review representation disappeared during refresh; moved to the default available representation."
            self._set_activity(message)
            self._set_review_message(message)
        if result.diagnostics:
            current = self.query_one("#review-diagnostics", Static).renderable
            self._set_review_message("\n".join((str(current), *result.diagnostics)))

    @staticmethod
    def _representation_label(item: ReviewRepresentation) -> str:
        trust = "trusted" if item.trusted else "untrusted"
        provenance = f" · {item.provenance}" if item.provenance else ""
        return f"{item.kind} · {item.direction}{provenance} · {trust}"

    def _load_review_frames(self) -> None:
        self._stop_playback()
        self._frames = ()
        if not (0 <= self._selected_representation < len(self._representations)):
            self.query_one("#play", Button).disabled = True
            self._set_review_message("No staged or cataloged runtime representation is available.")
            self._render_review_frame()
            return
        item = self._representations[self._selected_representation]
        messages = list(item.diagnostics)
        self.query_one("#play", Button).disabled = item.fps is None or not item.trusted
        if item.trusted:
            try:
                inspection = __import__("asset_inspector").inspect_png(
                    item.source_path, item.frame_width, item.frame_height, item.layout.value,
                    item.columns, item.rows,
                )
                self._frames = extract_frames(item.source_path, inspection)
            except Exception as error:
                messages.append(str(error))
        if self._frames:
            self._frame_index = min(self._frame_index, len(self._frames) - 1)
            self.query_one("#frame-select", Select).set_options([(f"Frame {index + 1}", str(index)) for index in range(len(self._frames))])
            self.query_one("#frame-select", Select).value = str(self._frame_index)
            self._render_filmstrip()
        else:
            self.query_one("#frame-select", Select).set_options([])
            self.query_one("#filmstrip-image", AutoImage).image = None
        self._set_review_message("\n".join(messages) if messages else self._representation_details(item))
        self._render_review_frame()

    def _representation_details(self, item: ReviewRepresentation) -> str:
        return (f"{item.kind.upper()} · {item.family_id}/{item.state_id} · direction {item.direction} · "
                f"{item.frame_width}×{item.frame_height} · {item.frame_count} frame(s) · layout {item.layout.value} · "
                f"provenance {item.provenance or 'unknown'} · FPS {item.fps if item.fps is not None else 'not declared'} · INTEGER RGBA {self._zoom}×")

    def _set_review_message(self, message: str) -> None:
        self.query_one("#review-diagnostics", Static).update(message or "No diagnostics.")

    def _select_frame(self, index: int) -> None:
        if not self._frames: return
        if index < 0 or index >= len(self._frames):
            if not self._loop: index = max(0, min(index, len(self._frames) - 1))
            else: index %= len(self._frames)
        self._frame_index = index
        try: self.query_one("#frame-select", Select).value = str(index)
        except Exception: pass
        self._render_filmstrip()
        self._render_review_frame()

    def _render_filmstrip(self) -> None:
        if not self._frames: return
        thumb_width = 24
        sheet = Image.new("RGBA", (thumb_width * len(self._frames), thumb_width), (24, 28, 36, 255))
        draw = ImageDraw.Draw(sheet)
        for index, frame in enumerate(self._frames):
            thumb = frame.convert("RGBA").copy()
            thumb.thumbnail((thumb_width, thumb_width), Image.Resampling.NEAREST)
            sheet.alpha_composite(thumb, (index * thumb_width + (thumb_width - thumb.width) // 2,
                                          (thumb_width - thumb.height) // 2))
            if index == self._frame_index:
                draw.rectangle((index * thumb_width, 0, (index + 1) * thumb_width - 1, thumb_width - 1), outline=(129, 161, 193, 255), width=2)
        self.query_one("#filmstrip-image", AutoImage).image = sheet

    def on_click(self, event) -> None:
        if getattr(event.widget, "id", None) != "filmstrip-image" or not self._frames: return
        strip = self.query_one("#filmstrip-image", AutoImage)
        index = int(max(0, event.x) / max(1, strip.size.width) * len(self._frames))
        self._select_frame(min(index, len(self._frames) - 1))

    def _advance_review(self) -> None:
        if not self._playing or not self._frames: return
        if self._frame_index == len(self._frames) - 1 and not self._loop:
            self._stop_playback()
        else:
            self._select_frame((self._frame_index + 1) % len(self._frames))

    def _stop_playback(self) -> None:
        self._playing = False
        if self._play_timer is not None:
            self._play_timer.stop()
            self._play_timer = None
        try: self.query_one("#play", Button).label = "Play"
        except Exception: pass

    def _render_review_frame(self) -> None:
        image_widget = self.query_one("#review-image", AutoImage)
        if not self._frames:
            image_widget.image = None
            self.query_one("#frame-status", Static).update("Frame 0 / 0")
            return
        left = self._frames[self._frame_index]
        output = left
        message = self._representation_details(self._representations[self._selected_representation])
        alpha_bounds = left.getchannel("A").getbbox()
        message += f" · alpha bounds {alpha_bounds}"
        if self._comparison in {"side", "overlay", "diff"} and 0 <= self._compare_representation < len(self._representations):
            other = self._representations[self._compare_representation]
            try:
                if not other.trusted:
                    raise ValueError("comparison representation is untrusted: " + "; ".join(other.diagnostics))
                inspection = __import__("asset_inspector").inspect_png(
                    other.source_path, other.frame_width, other.frame_height, other.layout.value,
                    other.columns, other.rows,
                )
                right_frames = extract_frames(other.source_path, inspection)
                right = right_frames[min(self._frame_index, len(right_frames) - 1)]
                if self._comparison == "side":
                    output = side_by_side_frames(left, right)
                else:
                    compared, warning, count, bounds = compare_frames(left, right, self._comparison)
                    if warning:
                        message += f" · {warning}"
                        output = left
                    else:
                        output = compared
                        if self._comparison == "diff": message += f" · changed pixels {count} · bounds {bounds}"
                message += " · compare " + self._representation_details(other)
            except Exception as error: message += f" · Comparison unavailable: {error}"
        image_widget.image = scale_frame_nearest(output, self._zoom)
        self._render_filmstrip()
        self.query_one("#frame-status", Static).update(f"Frame {self._frame_index + 1} / {len(self._frames)}")
        self._set_review_message(message)

    def _set_activity(self, message: str) -> None:
        self.query_one("#activity", Static).update(f"Read only · {message}")


def run_app() -> None:
    AssetWorkbenchApp().run()
