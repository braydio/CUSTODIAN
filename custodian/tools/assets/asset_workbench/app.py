"""Optional Textual FAMILY navigator over the read-only Asset V2 service."""

from __future__ import annotations

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Footer, Header, Input, Static, Tree

from .browser import AssetWorkbenchBrowser
from .service import AssetWorkbenchService


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
    """

    def __init__(self, service: AssetWorkbenchService | None = None) -> None:
        super().__init__()
        self.browser = AssetWorkbenchBrowser(service or AssetWorkbenchService())
        self._search = ""

    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal(id="main"):
            with Vertical(id="navigation"):
                yield Input(placeholder="Search family, state, layer, action…", id="search")
                yield Button("Refresh Asset V2", id="refresh", variant="primary")
                yield Tree("Asset families", id="family-tree")
            with Vertical(id="detail-pane"):
                yield Static("Loading Asset V2…", id="detail", markup=False)
        yield Static("Read only · no asset files are changed", id="activity", markup=False)
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#family-tree", Tree).show_root = False
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
        if event.button.id != "refresh":
            return
        self.action_refresh()

    def action_refresh(self) -> None:
        result = self.browser.refresh()
        self._populate_tree()
        self._render_detail()
        self._set_activity(result.message)

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

    def _set_activity(self, message: str) -> None:
        self.query_one("#activity", Static).update(f"Read only · {message}")


def run_app() -> None:
    AssetWorkbenchApp().run()
