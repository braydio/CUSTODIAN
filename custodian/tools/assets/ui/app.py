"""Textual application shell for the Asset Workbench (Slice 1: FAMILY, REVIEW, PIPELINE).

This is a sibling to the Operator Workbench (``custodian/tools/operator/ui``),
not a clone and not a replacement. It reviews any Asset Pipeline V2 family —
``ambient_baby_opossum`` is the acceptance fixture — through the existing
non-Operator authorities in ``custodian/tools/assets``. It never mutates
assets, never edits the family contract, and never talks to Operator-specific
publication/gameplay machinery.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

from PIL import Image
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, Vertical
from textual.widget import Widget
from textual.widgets import Static

ASSETS_DIR = Path(__file__).resolve().parents[1]
TOOLS_DIR = ASSETS_DIR.parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))
# Appended, never inserted at 0 — see service.py for why (stdlib "operator" shadow risk).
if str(TOOLS_DIR) not in sys.path:
    sys.path.append(str(TOOLS_DIR))

from workbench.preview.canvas import PreviewCanvas
from workbench.preview.controls import PreviewControls
from workbench.preview.filmstrip import PreviewFilmstrip
from workbench.preview.frame_ops import compare_frames

from .service import AssetWorkbenchService
from .state import AssetSelection, AssetWorkbenchUIState, ErrorView
from .widgets import ActivityLog, CoveragePanel, FamilyTree, PipelinePanel, StateDetail

ZOOM_MODES = ("auto", "1x", "2x", "3x", "fit")
REVIEW_VIEWS = ("single", "split", "diff")


def _consume_frame_time(elapsed_sec: float, fps: float) -> tuple[bool, float]:
    frame_duration = 1.0 / max(0.001, float(fps))
    if elapsed_sec + 1e-12 < frame_duration:
        return False, max(0.0, elapsed_sec)
    return True, max(0.0, elapsed_sec - frame_duration)


def _blank_frame(size: tuple[int, int]) -> Image.Image:
    return Image.new("RGBA", (max(1, size[0]), max(1, size[1])), (0, 0, 0, 0))


def _side_by_side(left: Image.Image, right: Image.Image) -> Image.Image:
    left, right = left.convert("RGBA"), right.convert("RGBA")
    gap = 4
    width = left.width + gap + right.width
    height = max(left.height, right.height)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.alpha_composite(left, (0, 0))
    canvas.alpha_composite(right, (left.width + gap, 0))
    return canvas


class AssetWorkbenchApp(App):
    TITLE = "Asset Workbench"
    CSS = """
    Screen { background: #11151c; color: #d8dee9; }
    #status-bar { height: 3; padding: 1 2; background: #202734; color: #eceff4; }
    .hidden { display: none; }
    .mode-pane { height: 1fr; }
    #family-row { height: 1fr; }
    #family-nav-pane { width: 40%; min-width: 26; border: solid #4c566a; }
    #family-detail-pane { width: 60%; border: solid #4c566a; }
    #state-detail { height: auto; max-height: 60%; padding: 1 2; }
    #coverage-panel { height: 1fr; padding: 1 2; overflow-y: auto; }
    #review-canvas { height: 1fr; content-align: center middle; }
    #review-filmstrip { height: 7; }
    #review-controls { height: 3; content-align: center middle; background: #202734; }
    #pipeline-panel { height: 1fr; padding: 1 2; overflow-y: auto; }
    #activity-log { height: 8; padding: 0 1; border: solid #4c566a; }
    #key-bar { height: 1; padding: 0 1; background: #202734; color: #d8dee9; }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit", show=False),
        Binding("1", "mode_family", "Family", priority=True, show=False),
        Binding("2", "mode_review", "Review", priority=True, show=False),
        Binding("3", "mode_pipeline", "Pipeline", priority=True, show=False),
        Binding("r", "refresh", "Refresh", show=False),
        Binding("space", "review_toggle", "Play/Pause", show=False),
        Binding("left", "review_previous", "Previous frame", show=False),
        Binding("right", "review_next", "Next frame", show=False),
        Binding("home", "review_first", "First frame", show=False),
        Binding("end", "review_last", "Last frame", show=False),
        Binding("left_square_bracket", "review_slower", "Slower review", show=False),
        Binding("right_square_bracket", "review_faster", "Faster review", show=False),
        Binding("l", "review_loop", "Loop", show=False),
        Binding("z", "review_zoom", "Zoom", show=False),
        Binding("s", "review_source", "Source", show=False),
        Binding("d", "review_view", "Single/Split/Diff", show=False),
    ]

    def __init__(self, service: AssetWorkbenchService | None = None, family_id: str = "") -> None:
        super().__init__()
        self.service = service or AssetWorkbenchService()
        initial_family = family_id or next(iter(self.service.family_ids()), "")
        self.state = AssetWorkbenchUIState(family_id=initial_family)
        self.projection = None
        self.pipeline = None
        self.review_frames: tuple[Image.Image, ...] = ()
        self.review_meta: dict = {}
        self._review_last_tick = time.monotonic()
        self._review_elapsed_sec = 0.0

    def compose(self) -> ComposeResult:
        yield Static("ASSET WORKBENCH", id="status-bar")
        with Container(id="family-mode", classes="mode-pane"):
            with Horizontal(id="family-row"):
                with Container(id="family-nav-pane"):
                    yield FamilyTree()
                with Vertical(id="family-detail-pane"):
                    yield StateDetail("Select a state to inspect its Asset V2 contract.", id="state-detail", markup=False)
                    yield CoveragePanel("", id="coverage-panel", markup=False)
        with Container(id="review-mode", classes="mode-pane hidden"):
            yield PreviewCanvas("Select a state", id="review-canvas")
            yield PreviewFilmstrip(id="review-filmstrip")
            yield PreviewControls("REVIEW", id="review-controls")
        with Container(id="pipeline-mode", classes="mode-pane hidden"):
            yield PipelinePanel("", id="pipeline-panel", markup=False)
        yield ActivityLog(id="activity-log", max_lines=200, markup=True)
        yield Static(
            "1 Family · 2 Review · 3 Pipeline · R Refresh · Space Play · ←/→ Frame · Home/End · "
            "Bracket keys Speed · Z Zoom · S Source · D View · Q Quit",
            id="key-bar", markup=False,
        )

    def on_mount(self) -> None:
        self.query_one(FamilyTree).set_families(self.service.family_ids(), self.state.family_id)
        self.set_interval(1.0 / 30.0, self._review_tick)
        if self.state.family_id:
            self._load_family(self.state.family_id)
        else:
            self._activity("No Asset V2 families are registered.", "WARN")

    # ---- loading -----------------------------------------------------

    def _load_family(self, family_id: str) -> None:
        try:
            self.projection = self.service.family_projection(family_id)
        except Exception as error:
            self._error(error)
            return
        self.state.family_id = family_id
        self.query_one(FamilyTree).set_projection(self.projection)
        self.query_one("#coverage-panel", CoveragePanel).show(self.projection)
        self._update_status_bar()
        keep = self.state.selection.state_id if self.state.selection and self.state.selection.family_id == family_id else None
        self._select_state(keep)
        if self.state.mode == "pipeline":
            self._load_pipeline()

    def _select_state(self, state_id: str | None) -> None:
        if self.projection is None:
            return
        states = self.projection.states
        if not states:
            return
        if state_id is None or state_id not in {state.state_id for state in states}:
            preferred = next((state for state in states if state.art_present), states[0])
            state_id = preferred.state_id
        self.state.selection = self.service.resolve_selection(self.state.family_id, state_id)
        state = next(state for state in states if state.state_id == state_id)
        self.query_one("#state-detail", StateDetail).show(self.projection, state)
        if self.state.mode == "review":
            self._load_review()

    def _load_pipeline(self) -> None:
        if not self.state.family_id:
            return
        try:
            self.pipeline = self.service.pipeline_report(self.state.family_id)
        except Exception as error:
            self._error(error)
            return
        self.query_one("#pipeline-panel", PipelinePanel).show(self.pipeline)

    def _load_review(self) -> None:
        selection = self.state.selection
        canvas = self.query_one("#review-canvas", PreviewCanvas)
        if selection is None:
            self.review_frames, self.review_meta = (), {}
            canvas.show_frame(_blank_frame(self.projection.canvas if self.projection else (32, 32)), "No state selected")
            return
        try:
            self.review_frames, self.review_meta = self.service.review_frames(
                selection.family_id, selection.state_id, selection.direction, selection.review_source,
            )
        except Exception as error:
            self.review_frames, self.review_meta = (), {}
            self._activity(f"Review unavailable: {error}", "WARN")
            canvas.show_frame(_blank_frame(self.projection.canvas if self.projection else (32, 32)), str(error))
            return
        self.state.review_frame = min(self.state.review_frame, max(0, len(self.review_frames) - 1))
        self._reset_review_clock()
        self._render_review()

    # ---- rendering -----------------------------------------------------

    def _update_status_bar(self) -> None:
        if self.projection is None:
            return
        mirror = "on" if self.projection.auto_mirror else "off"
        self.query_one("#status-bar", Static).update(
            f"[b]ASSET WORKBENCH[/b]  ·  {self.projection.family_id}  ·  {self.projection.kind}  ·  "
            f"{self.projection.canvas[0]}x{self.projection.canvas[1]}  ·  {self.projection.direction_policy}  ·  "
            f"mirror={mirror}  ·  {self.projection.completeness}"
        )

    def _other_review_source(self) -> str | None:
        selection = self.state.selection
        if selection is None:
            return None
        sources = self.service.available_review_sources(selection.family_id, selection.state_id, selection.direction)
        others = [source for source in sources if source != selection.review_source]
        return others[0] if others else None

    def _render_review(self) -> None:
        canvas = self.query_one("#review-canvas", PreviewCanvas)
        controls = self.query_one("#review-controls", PreviewControls)
        filmstrip = self.query_one("#review-filmstrip", PreviewFilmstrip)
        selection = self.state.selection
        if not self.review_frames or selection is None:
            controls.update("NO FRAMES")
            filmstrip.show_frames((), current=0)
            return
        index = self.state.review_frame
        frame = self.review_frames[index]
        label = selection.identity
        view = self.state.review_view
        if view != "single":
            other_source = self._other_review_source()
            other_frame = None
            if other_source is not None:
                try:
                    other_frames, _meta = self.service.review_frames(selection.family_id, selection.state_id, selection.direction, other_source)
                    if other_frames:
                        other_frame = other_frames[min(index, len(other_frames) - 1)]
                except Exception:
                    other_frame = None
            if other_frame is None:
                label = f"{label} · {view.upper()} unavailable (only one source)"
            elif view == "diff":
                frame, metrics = compare_frames(frame, other_frame)
                label = f"{label} · DIFF vs {other_source.upper()} ({metrics.changed_pixels}px changed)"
            elif view == "split":
                frame = _side_by_side(frame, other_frame)
                label = f"{label} · SPLIT vs {other_source.upper()}"
        canvas.show_frame(frame, label, self.state.review_zoom)
        filmstrip.show_frames(self.review_frames, current=index)
        controls.show(
            frame=index, frames=len(self.review_frames), fps=self.state.review_fps,
            playing=self.state.review_playing, loop=self.state.review_loop,
            source=selection.review_source, zoom=self.state.review_zoom, view=view,
        )

    # ---- mode switching -----------------------------------------------------

    def _set_mode(self, mode: str) -> None:
        self.state.mode = mode
        ids = {"family": "#family-mode", "review": "#review-mode", "pipeline": "#pipeline-mode"}
        for name, selector in ids.items():
            self.query_one(selector, Widget).set_class(name != mode, "hidden")
        if mode == "review":
            self._reset_review_clock()
            self._load_review()
        elif mode == "pipeline":
            self._load_pipeline()

    def action_mode_family(self) -> None:
        self._set_mode("family")

    def action_mode_review(self) -> None:
        self._set_mode("review")

    def action_mode_pipeline(self) -> None:
        self._set_mode("pipeline")

    def action_refresh(self) -> None:
        self.service.refresh()
        if self.state.family_id:
            self.query_one(FamilyTree).set_families(self.service.family_ids(), self.state.family_id)
            self._load_family(self.state.family_id)
        self._activity("Refreshed from live Asset V2 authority", "OK")

    # ---- review transport -----------------------------------------------------

    def action_review_toggle(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_playing = not self.state.review_playing
        self._reset_review_clock()
        self._render_review()

    def action_review_previous(self) -> None:
        if self.state.mode != "review" or not self.review_frames:
            return
        self.state.review_playing = False
        self.state.review_frame = max(0, self.state.review_frame - 1)
        self._reset_review_clock()
        self._render_review()

    def action_review_next(self) -> None:
        if self.state.mode != "review" or not self.review_frames:
            return
        self.state.review_playing = False
        last = len(self.review_frames) - 1
        target = 0 if self.state.review_loop and self.state.review_frame == last else min(last, self.state.review_frame + 1)
        self.state.review_frame = target
        self._reset_review_clock()
        self._render_review()

    def action_review_first(self) -> None:
        if self.state.mode != "review" or not self.review_frames:
            return
        self.state.review_playing = False
        self.state.review_frame = 0
        self._reset_review_clock()
        self._render_review()

    def action_review_last(self) -> None:
        if self.state.mode != "review" or not self.review_frames:
            return
        self.state.review_playing = False
        self.state.review_frame = len(self.review_frames) - 1
        self._reset_review_clock()
        self._render_review()

    def action_review_slower(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_fps = max(1.0, self.state.review_fps - 1.0)
        self._reset_review_clock()
        self._render_review()

    def action_review_faster(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_fps = min(30.0, self.state.review_fps + 1.0)
        self._reset_review_clock()
        self._render_review()

    def action_review_loop(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_loop = not self.state.review_loop
        self._render_review()

    def action_review_zoom(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_zoom = ZOOM_MODES[(ZOOM_MODES.index(self.state.review_zoom) + 1) % len(ZOOM_MODES)]
        self._render_review()

    def action_review_view(self) -> None:
        if self.state.mode != "review":
            return
        self.state.review_view = REVIEW_VIEWS[(REVIEW_VIEWS.index(self.state.review_view) + 1) % len(REVIEW_VIEWS)]
        self._render_review()

    def action_review_source(self) -> None:
        if self.state.mode != "review" or self.state.selection is None:
            return
        selection = self.state.selection
        sources = self.service.available_review_sources(selection.family_id, selection.state_id, selection.direction)
        if len(sources) < 2:
            self._activity("Only one review source is available for this state/direction.", "WARN")
            return
        current = sources.index(selection.review_source) if selection.review_source in sources else 0
        next_source = sources[(current + 1) % len(sources)]
        self.state.selection = AssetSelection(selection.family_id, selection.state_id, selection.direction, next_source)
        self._load_review()

    def _reset_review_clock(self) -> None:
        self._review_last_tick = time.monotonic()
        self._review_elapsed_sec = 0.0

    def _review_tick(self) -> None:
        now = time.monotonic()
        delta = max(0.0, now - self._review_last_tick)
        self._review_last_tick = now
        if self.state.mode != "review" or not self.state.review_playing or not self.review_frames:
            return
        self._review_elapsed_sec += delta
        while self.state.review_playing:
            due, self._review_elapsed_sec = _consume_frame_time(self._review_elapsed_sec, self.state.review_fps)
            if not due:
                break
            last = len(self.review_frames) - 1
            target = 0 if self.state.review_loop and self.state.review_frame == last else min(last, self.state.review_frame + 1)
            if target == self.state.review_frame and not self.state.review_loop:
                self.state.review_playing = False
            self.state.review_frame = target
            self._render_review()

    # ---- tree events -----------------------------------------------------

    def on_family_tree_family_selected(self, event: FamilyTree.FamilySelected) -> None:
        self._load_family(event.family_id)

    def on_family_tree_state_selected(self, event: FamilyTree.StateSelected) -> None:
        if event.family_id != self.state.family_id:
            self._load_family(event.family_id)
        self._select_state(event.state_id)

    # ---- activity/errors -----------------------------------------------------

    def _activity(self, message: str, severity: str = "INFO") -> None:
        self.state.add_activity(message)
        self.query_one("#activity-log", ActivityLog).add_message(message, severity)

    def _error(self, error: Exception) -> None:
        view = ErrorView.from_exception(error)
        self._activity(f"{view.title}: {view.message}", "ERROR")


def run_asset_workbench(*, family_id: str = "") -> int:
    AssetWorkbenchApp(family_id=family_id).run()
    return 0
