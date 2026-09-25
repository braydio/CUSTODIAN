"""Textual application shell for the Operator Workbench."""
from __future__ import annotations

import asyncio
from functools import partial
import shutil
import subprocess
import time
from pathlib import Path

from textual.app import App
from textual.binding import Binding
from textual.widget import Widget
from textual.widgets import DataTable, Input, Static, TextArea

from .dialogs import (
    CanvasMigrationDialog, CanvasResizeDialog, ContextMismatchDialog, ErrorDialog, FrameAddDialog, FrameRemoveDialog,
    PublishDialog, RefreshDialog, ValidationDialog, WeaponContextDialog,
)
from .features import AnimationFeature
from .live_bridge_controller import LiveBridgeController, LiveBridgeEvent, LiveBridgeUIStatus
from live_bridge.protocol import MessageType
from .screens import MainScreen
from .service import WorkbenchService
from .state import AnimationSelection, ExistingContextView, WorkbenchUIState
from .widgets import (ActivityLog, AnimationDetail, AnimationTree, ContextKeyBar, LayerTable,
                      MotionCanvas, MotionControls, MotionMetrics, PlanTable,
                      PreviewCanvas, PreviewControls, PreviewFilmstrip, TimelineTable, WorkbenchStatusBar)
import animation_preview
import animation_motion_preview
import animation_transition

LIVE_PREVIEW_DEBOUNCE_SEC = 0.15
TIMELINE_LOOP_PRESETS = (1, 2, 3, 4, 6, 8)


class OperatorWorkbenchApp(App):
    TITLE = "Operator Workbench"
    CSS = """
    Screen { background: #11151c; color: #d8dee9; }
    #workbench-status { height: 3; padding: 1 2; background: #202734; color: #eceff4; }
    #search { height: 3; margin: 0 1; }
    .hidden { display: none; }
    #workspace-row { height: 1fr; }
    #navigation-pane { width: 25%; min-width: 20; border: solid #4c566a; }
    #detail-pane { width: 35%; border: solid #4c566a; padding: 1 2; }
    #layers-pane { width: 40%; min-width: 28; border: solid #4c566a; }
    #animation-tree { height: 1fr; }
    #layer-table { height: 1fr; }
    #layer-detail { height: 4; padding: 0 1; background: #181e28; }
    #activity-pane { height: 10; border: solid #4c566a; }
    #activity-log { height: 1fr; padding: 0 1; }
    #context-key-bar { height: 1; padding: 0 1; background: #202734; color: #d8dee9; }
    .mode-pane { height: 1fr; }
    #plan-table { height: 1fr; }
    #timeline-table { height: 12; }
    #timeline-canvas { height: 1fr; content-align: center middle; }
    #preview-canvas { height: 1fr; content-align: center middle; }
    #preview-examiner-row { height: 1fr; }
    #preview-compare-canvas { width: 1fr; height: 1fr; }
    #preview-diff-metrics { height: 2; padding: 0 1; text-align: center; background: #181e28; }
    #preview-filmstrip { height: 7; }
    #preview-controls { height: 3; content-align: center middle; background: #202734; }
    #motion-workspace { height: 1fr; }
    #motion-canvas { width: 1fr; height: 1fr; content-align: center middle; }
    #motion-inspector { width: 28; min-width: 22; border: solid #4c566a; }
    #motion-controls { height: 7; padding: 0 1; }
    #motion-metrics { height: 1fr; padding: 0 1; }
    #motion-preview-controls { height: 3; content-align: center middle; background: #202734; }
    .pane-title { height: 1; padding: 0 1; text-style: bold; background: #202734; }
    .dialog { width: 72; max-height: 94%; margin: 1 4; padding: 1 2; border: thick #81a1c1; background: #202734; }
    .publish-dialog { width: 78; max-height: 100%; margin: 0 1; padding: 0 1; }
    #publish-summary { height: 4; }
    .publish-section-title { height: 1; margin-top: 1; }
    .publish-table { height: auto; max-height: 5; overflow: hidden; }
    .publish-dialog Checkbox { height: 1; }
    #mirror-consequence { height: 2; padding-left: 4; color: #d8dee9; }
    #publish-preflight { height: 1; margin-top: 1; }
    #publish-details { height: 1fr; min-height: 15; overflow-y: auto; border: solid #4c566a; padding: 0 1; }
    #publish-button-spacer { width: 1fr; }
    .publish-buttons { align-horizontal: left; }
    .error-dialog { border: thick #bf616a; }
    .dialog-title { height: 2; text-align: center; text-style: bold; }
    .dialog-body { height: auto; max-height: 1fr; overflow-y: auto; }
    .dialog-buttons { height: 3; align-horizontal: right; margin-top: 1; }
    .dialog-buttons Button { margin-left: 1; }
    """
    # show=False everywhere: bindings stay live, but no Footer/future widget
    # can dump the full application-wide binding set again. Per-mode hints
    # live in ContextKeyBar instead (see widgets/context_key_bar.py).
    BINDINGS = [
        Binding("q", "quit", "Quit", show=False), Binding("slash", "search", "Search", priority=True, show=False),
        Binding("f5", "full_refresh", "Reload", show=False),
        Binding("question_mark", "help", "Help", show=False), Binding("e", "edit", "Edit", show=False),
        Binding("a", "add_frame", "Add Frame", show=False),
        Binding("x", "remove_frame", "Remove Frame", show=False), Binding("p", "publish", "Publish", show=False),
        Binding("r", "refresh_workbench", "Refresh", show=False), Binding("w", "weapon_context", "Weapon", show=False),
        Binding("v", "validate", "Validate", show=False), Binding("j", "cursor_down", "Down", show=False),
        Binding("k", "cursor_up", "Up", show=False),
        Binding("1", "mode_plan", "Plan", priority=True, show=False), Binding("2", "mode_workbench", "Workbench", priority=True, show=False),
        Binding("3", "mode_preview", "Preview", priority=True, show=False), Binding("4", "mode_timeline", "Timeline", priority=True, show=False),
        Binding("5", "mode_motion", "Motion", priority=True, show=False),
        Binding("space", "preview_toggle", "Play/Pause", show=False), Binding("left", "preview_previous", "Previous frame", show=False),
        Binding("right", "preview_next", "Next frame", show=False), Binding("home", "preview_first", "First frame", show=False),
        Binding("end", "preview_last", "Last frame", show=False), Binding("left_square_bracket", "preview_slower", "Slower review", show=False),
        Binding("right_square_bracket", "preview_faster", "Faster review", show=False), Binding("l", "preview_loop", "Loop", show=False),
        Binding("s", "preview_source", "Source", show=False), Binding("ctrl+a", "timeline_add", "Add clip", priority=True, show=False),
        Binding("shift+d", "preview_examiner_mode", "Preview examiner", show=False),
        Binding("shift+s", "preview_compare_source", "Compare source", show=False),
        Binding("t", "transition_target", "Transition target", show=False),
        Binding("shift+t", "transition_view", "Transition view", show=False),
        Binding("z", "preview_zoom", "Zoom", show=False),
        Binding("i", "timeline_trim_in_forward", "Trim in +", show=False), Binding("shift+i", "timeline_trim_in_backward", "Trim in -", show=False),
        Binding("o", "timeline_trim_out_backward", "Trim out -", show=False), Binding("shift+o", "timeline_trim_out_forward", "Trim out +", show=False),
        Binding("shift+l", "timeline_clip_loops", "Clip loops", show=False),
        Binding("delete", "timeline_remove", "Remove clip", show=False), Binding("ctrl+up", "timeline_up", "Move clip left", priority=True, show=False),
        Binding("ctrl+down", "timeline_down", "Move clip right", priority=True, show=False), Binding("ctrl+s", "timeline_save", "Save sequence", priority=True, show=False),
        Binding("ctrl+o", "timeline_load", "Load sequence", priority=True, show=False),
        Binding("y", "copy_spritesheet", "Copy spritesheet", show=False),
        Binding("shift+y", "cycle_copy_mode", "Copy mode", show=False),
        Binding("shift+u", "toggle_superseded", "Superseded", show=False),
        Binding("m", "motion_mode", "Motion mode", show=False), Binding("h", "motion_heading", "Motion heading", show=False),
        Binding("g", "motion_ground", "Motion ground", show=False), Binding("c", "motion_curve", "Motion curve", show=False),
        Binding("d", "motion_distance", "Motion distance", show=False), Binding("shift+l", "motion_loop_cycles", "Motion loop span", show=False),
        Binding("shift+left", "motion_travel_less", "Travel -16", show=False), Binding("shift+right", "motion_travel_more", "Travel +16", show=False),
        Binding("ctrl+left", "motion_travel_less_large", "Travel -32", priority=True, show=False), Binding("ctrl+right", "motion_travel_more_large", "Travel +32", priority=True, show=False),
        Binding("ctrl+r", "context_ctrl_r", "Context action", priority=True, show=False), Binding("enter", "motion_runtime", "Runtime check", show=False),
    ]

    def __init__(
        self, service: WorkbenchService | None = None,
        startup: AnimationSelection | None = None,
        live_bridge: LiveBridgeController | None = None,
    ) -> None:
        super().__init__(); self.service = service or WorkbenchService(); self.state = WorkbenchUIState(selection=startup)
        self.live_bridge = live_bridge or LiveBridgeController(self.service.repo_root)
        self._last_live_snapshot = self.live_bridge.snapshot()
        self._status_branch = "unknown"
        self._status_dirty = False
        self._status_aseprite = "unavailable"
        self.features = {"animations": AnimationFeature(self.service)}; self.session_view = None
        self.main_screen: MainScreen | None = None
        self.preview_view = None
        self.preview_compare_view = None
        self.preview_comparisons = ()
        self.transition_candidates = ()
        self.transition_target_view = None
        self.transition_analysis = None
        self.timeline_frames = []
        self._timeline_pending_focus = None
        self.sequence = animation_preview.ReviewSequence("review")
        self.motion_renderer = None
        self.motion_markers = ()
        self._motion_last_tick = time.monotonic()
        self._preview_last_tick = time.monotonic()
        self._preview_elapsed_sec = 0.0

    def on_mount(self) -> None:
        self.main_screen = MainScreen()
        self.push_screen(self.main_screen)
        self.call_after_refresh(self.action_full_refresh)
        self.run_worker(
            self._start_live_bridge(), group="live-bridge", exclusive=True,
            exit_on_error=False,
        )
        self.run_worker(
            self._consume_live_bridge_events(), group="live-bridge-events",
            exclusive=True, exit_on_error=False,
        )
        self.set_interval(0.5, self._refresh_live_bridge_status)
        self.set_interval(1.0, self._watch_selected)
        self.set_interval(1.0 / 30.0, self._preview_tick)

    async def on_unmount(self) -> None:
        await self.live_bridge.stop()

    async def _start_live_bridge(self) -> None:
        await self.live_bridge.start()
        self._refresh_live_bridge_status()

    def _selected_live_workbench_path(self) -> Path | None:
        if self.session_view is None:
            return None
        return (self.session_view.workspace_path / "workbench.aseprite").resolve()

    def _live_document_matches_selection(self, document_path: str | None = None) -> bool:
        expected = self._selected_live_workbench_path()
        if expected is None:
            return False
        actual = document_path or self.live_bridge.server.state.active_document_path
        if not actual:
            return False
        try:
            return Path(actual).resolve() == expected
        except OSError:
            return False

    async def _consume_live_bridge_events(self) -> None:
        while True:
            event = await self.live_bridge.next_event()
            if event.message_type in (MessageType.CLIENT_HELLO, MessageType.EDITOR_SITE_CHANGED):
                if self._live_document_matches_selection(event.document_path):
                    table = self._main_widget("#layer-table", LayerTable)
                    if event.layer is not None:
                        table.select_live_layer(event.layer)
            if event.message_type is MessageType.LAYER_STATE_CHANGED:
                if (
                    self._live_document_matches_selection(event.document_path)
                    and event.layer is not None
                    and event.visible is not None
                ):
                    self._main_widget("#layer-table", LayerTable).set_live_visibility(
                        event.layer, event.visible
                    )
                continue
            if event.message_type is MessageType.DOCUMENT_CHANGED:
                if (
                    self.state.mode == "preview"
                    and self.state.preview_source == "workbench"
                    and event.revision is not None
                    and self._live_document_matches_selection(event.document_path)
                ):
                    self.run_worker(
                        self._debounced_live_preview(event.revision),
                        group="live-preview-export", exclusive=True,
                        exit_on_error=False,
                    )
                continue
            if event.message_type is MessageType.COMMAND_RESULT:
                if event.operation == "export_preview":
                    await self._apply_live_preview(event)
                continue
            if event.message_type not in (
                MessageType.CLIENT_HELLO, MessageType.EDITOR_SITE_CHANGED,
            ):
                continue
            if not event.user_originated or self.state.mode not in ("workbench", "preview"):
                continue
            if not self._live_document_matches_selection(event.document_path):
                continue
            if event.frame is None or self.session_view is None:
                continue
            frame_index = event.frame - 1
            if frame_index < 0 or frame_index >= self.session_view.document_frames:
                continue
            self.state.preview_frame = frame_index
            if self.state.mode == "preview":
                self.state.preview_playing = False
                self._reset_preview_clock()
                if self.preview_view is not None:
                    self._render_preview()

    async def _debounced_live_preview(self, revision: int) -> None:
        await asyncio.sleep(LIVE_PREVIEW_DEBOUNCE_SEC)
        if (
            self.state.mode != "preview"
            or self.state.preview_source != "workbench"
            or not self._live_document_matches_selection()
            or revision != self.live_bridge.server.state.document_revision
        ):
            return
        workbench = self._selected_live_workbench_path()
        if workbench is None:
            return
        try:
            await self.live_bridge.export_preview(workbench, revision)
        except (ConnectionError, ValueError):
            return

    async def _apply_live_preview(self, event: LiveBridgeEvent) -> None:
        if not event.ok:
            return
        if (
            self.state.mode != "preview"
            or self.state.preview_source != "workbench"
            or not self._live_document_matches_selection(event.document_path)
            or event.revision is None
            or event.revision != self.live_bridge.server.state.document_revision
            or event.output_path is None
            or event.frame_count is None
            or event.frame_width is None
            or event.frame_height is None
        ):
            return
        workbench = self._selected_live_workbench_path()
        if workbench is None:
            return
        expected_output = self.live_bridge._live_preview_path(workbench)
        try:
            if Path(event.output_path).resolve() != expected_output:
                return
        except OSError:
            return
        selection = self.state.selection
        if selection is None:
            return
        try:
            loader = partial(
                self.service.live_preview, selection, expected_output,
                frames=event.frame_count,
                frame_size=(event.frame_width, event.frame_height),
            )
            live = await self._thread(loader)
        except Exception:
            return
        if event.revision != self.live_bridge.server.state.document_revision:
            return
        self.preview_view = live
        self.state.preview_frame = min(self.state.preview_frame, len(live.frames) - 1)
        if self.state.preview_examiner_mode != "single":
            if self.state.preview_examiner_mode == "transition" and self.transition_target_view is not None:
                self.transition_analysis = animation_transition.analyze_transition(
                    self.preview_view.frames, self.transition_target_view.frames, tail=2, head=2,
                )
            else:
                await self._load_preview_comparison()
                self._rebuild_preview_comparison()
        self._render_preview()

    def _update_status_bar(self) -> None:
        self._main_widget("#workbench-status", WorkbenchStatusBar).set_status(
            self._status_branch, self._status_dirty, self._status_aseprite,
            self.live_bridge.snapshot().status.value,
        )

    def _refresh_live_bridge_status(self) -> None:
        snapshot = self.live_bridge.snapshot()
        previous = self._last_live_snapshot
        if snapshot == previous:
            return
        self._last_live_snapshot = snapshot
        self._update_status_bar()
        if snapshot.status is LiveBridgeUIStatus.WAITING:
            if previous.status is LiveBridgeUIStatus.CONNECTED:
                self._activity("Aseprite Live Bridge disconnected", "WARN")
            elif previous.status in (LiveBridgeUIStatus.STARTING, LiveBridgeUIStatus.STOPPED):
                self._activity(f"Live Bridge listening on {snapshot.host}:{snapshot.port}", "OK")
        elif snapshot.status is LiveBridgeUIStatus.CONNECTED:
            self._activity("Aseprite Live Bridge connected", "OK")
        elif snapshot.status is LiveBridgeUIStatus.UNAVAILABLE:
            self._activity(f"Live Bridge unavailable: {snapshot.error or 'unknown error'}", "WARN")

    def _main_widget(self, selector, kind):
        if self.main_screen is None:
            raise RuntimeError("Operator Workbench MainScreen is not mounted")
        return self.main_screen.query_one(selector, kind)

    def _activity(self, message: str, severity: str = "INFO") -> None:
        event = self.state.add_activity(message, severity)
        self._main_widget("#activity-log", ActivityLog).add_event(event)

    async def _thread(self, function, *args, **kwargs): return await asyncio.to_thread(function, *args, **kwargs)

    def _error(self, error: Exception) -> None:
        projected = self.service.project_error(error); self._activity(projected.message.splitlines()[0], "ERROR")
        if isinstance(self.screen, ErrorDialog):
            return
        self.push_screen(ErrorDialog(projected.title, projected.message))

    def _repo_status(self) -> tuple[str, bool]:
        try:
            branch = subprocess.run(["git", "branch", "--show-current"], cwd=self.service.repo_root, text=True, capture_output=True, check=True).stdout.strip() or "detached"
            dirty = bool(subprocess.run(["git", "status", "--porcelain"], cwd=self.service.repo_root, text=True, capture_output=True, check=True).stdout)
            return branch, dirty
        except (OSError, subprocess.CalledProcessError): return "unknown", False

    async def _reload_browser(self) -> None:
        try:
            records = await self._thread(self.features["animations"].refresh)
            query = self.state.search_filter
            filtered = self.service.filter_records(records, query)
            tree = self._main_widget("#animation-tree", AnimationTree); tree.set_records(filtered)
            if self.state.selection and not self.state.selection.group:
                requested = self.state.selection
                matches = [row.selection for row in filtered if (
                    row.selection.profile, row.selection.action, row.selection.direction
                ) == (requested.profile, requested.action, requested.direction)]
                if len(matches) == 1:
                    resolved = matches[0]
                    self.state.selection = AnimationSelection(
                        resolved.profile, resolved.group, resolved.action, resolved.direction,
                        requested.weapon_id, requested.linked_profile,
                    )
            if self.state.selection and tree.select_identity(self.state.selection): await self._load_session(self.state.selection)
            elif filtered:
                self.state.selection = self.state.contextualize(filtered[0].selection)
                tree.select_identity(self.state.selection)
                await self._load_session(self.state.selection)
            self._status_branch, self._status_dirty = await self._thread(self._repo_status)
            self._status_aseprite = str(self.service.workbench.resolve_aseprite(self.service.aseprite) or "unavailable")
            self._update_status_bar()
            if hasattr(self.service, "animation_plan"):
                self._main_widget("#plan-table", PlanTable).set_items(await self._thread(self.service.animation_plan))
            action_count = len({(row.selection.profile, row.selection.group, row.selection.action) for row in filtered})
            self._activity(f"browser refreshed: {len(filtered)} directional variants, {action_count} actions", "OK")
        except Exception as error: self._error(error)

    async def _load_session(self, selection: AnimationSelection) -> bool:
        try:
            changed = self.state.selection is None or self.state.selection.identity != selection.identity
            session = await self._thread(self.service.session, selection); self.session_view = session
            self.state.selection = selection; self.state.watch_signature = self.service.watch_signature(selection)
            if changed:
                self.preview_compare_view = None
                self.preview_comparisons = ()
                self.transition_candidates = ()
                self.transition_target_view = None
                self.transition_analysis = None
                self.state.transition_target_identity = ""
                self.state.motion.elapsed_sec = 0.0
                self.state.motion.playing = False
                self.state.motion.heading = selection.direction
            self._main_widget("#animation-detail", AnimationDetail).show_session(session)
            self._main_widget("#layer-table", LayerTable).show_session(session)
            layer_table = self._main_widget("#layer-table", LayerTable)
            layer_table.clear_live_state()
            if self._live_document_matches_selection():
                for layer, visible in self.live_bridge.server.state.layer_visibility.items():
                    layer_table.set_live_visibility(layer, visible)
                if self.live_bridge.server.state.active_layer:
                    layer_table.select_live_layer(str(self.live_bridge.server.state.active_layer))
            self._main_widget("#layer-detail", Static).update(layer_table.selected_detail(0))
            if changed and self.state.mode == "motion":
                await self._load_motion_preview()
            return True
        except Exception as error:
            projected = self.service.project_error(error)
            if projected.title == "WORKBENCH CONTEXT MISMATCH":
                existing = self.service.existing_context(selection)
                if existing is not None:
                    requested = self.service.requested_context(selection)
                    self._activity(projected.title, "ERROR")
                    if not isinstance(self.screen, ContextMismatchDialog):
                        self.push_screen(
                            ContextMismatchDialog(existing, requested),
                            lambda result: self._accept_context_mismatch(result, selection, existing),
                        )
                    return False
            self._error(error)
            return False

    def _accept_context_mismatch(
        self, result: str | None, requested: AnimationSelection,
        existing: ExistingContextView,
    ) -> None:
        if result == "open-existing":
            self.state.adopt_context(existing.weapon_id, existing.linked_profile)
            adopted = self.state.contextualize(requested)
            self.run_worker(self._load_session(adopted), group="session", exclusive=True)
        elif result == "recontextualize":
            self.state.adopt_context(requested.weapon_id, requested.linked_profile)
            self.state.selection = requested
            self.run_worker(
                self._mutate("RECONTEXTUALIZE", self.service.refresh, requested, True),
                group="mutation", exclusive=True,
            )

    def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted) -> None:
        if event.data_table.id != "layer-table": return
        table = event.data_table
        self._main_widget("#layer-detail", Static).update(table.selected_detail(event.cursor_row))

    def on_data_table_row_selected(self, event: DataTable.RowSelected) -> None:
        if event.data_table.id == "timeline-table":
            self._jump_timeline_clip(event.cursor_row)
            return
        if event.data_table.id == "layer-table":
            if self.state.mode != "workbench" or not self._live_document_matches_selection():
                return
            layer = event.data_table.layer_name_at(event.cursor_row)
            workbench = self._selected_live_workbench_path()
            if layer and workbench:
                self.run_worker(
                    self._send_live_layer_focus(workbench, layer),
                    group="live-layer-focus", exclusive=True, exit_on_error=False,
                )
            return
        if event.data_table.id != "plan-table": return
        item_id = str(event.row_key.value)
        item = next((row for row in self.service.animation_plan() if row["id"] == item_id), None)
        if item:
            direction = (item.get("covered_directions") or item["directions"])[0]
            self.state.selection = self.state.contextualize(AnimationSelection(item["profile"], item["group"], item["action"], direction))
            self._set_mode("workbench")
            self.run_worker(self._load_session(self.state.selection), group="session", exclusive=True)

    def on_preview_controls_scrubbed(self, event: PreviewControls.Scrubbed) -> None:
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition":
            return
        if self.state.mode == "motion" and self.preview_view:
            duration = len(self.preview_view.frames) / self.state.review_fps
            span = duration * self.state.motion.loop_cycles if self.state.motion.loop else duration
            target = event.ratio * span
            if self.state.motion.loop and event.ratio >= 1.0:
                target = max(0.0, span - 0.000001)
            self.state.motion.elapsed_sec = target
            self.state.motion.playing = False
            self._render_motion()
            return
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames:
            self.state.preview_playing = False
            target = round(event.ratio * (frames - 1))
            if self.state.mode == "preview": self._set_preview_frame(target, sync_live=True)
            else: self.state.preview_frame = target; self._reset_preview_clock(); self._render_preview()

    async def on_animation_tree_selected(self, event: AnimationTree.Selected) -> None:
        selection = self.state.contextualize(event.selection)
        if await self._load_session(selection):
            self._activity(f"selected {selection.identity}")

    async def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id != "search": return
        self.state.search_filter = event.value
        records = self.features["animations"].build_navigation(event.value)
        self._main_widget("#animation-tree", AnimationTree).set_records(records)

    def action_search(self) -> None:
        search = self._main_widget("#search", Input); search.remove_class("hidden"); search.focus()

    def action_cursor_down(self) -> None: self._main_widget("#animation-tree", AnimationTree).action_cursor_down()
    def action_cursor_up(self) -> None: self._main_widget("#animation-tree", AnimationTree).action_cursor_up()
    def action_cycle_copy_mode(self) -> None:
        modes = ("body", "fx", "body_fx")
        self.state.copy_mode = modes[(modes.index(self.state.copy_mode) + 1) % len(modes)]
        self._main_widget("#context-key-bar", ContextKeyBar).set_mode(self.state.mode, self.state.copy_mode, self.state.show_superseded)
        label = self.state.copy_mode.upper().replace("_", " + ")
        self._activity(f"Copy mode: {label}")
        self.notify(f"Copy mode: {label}", severity="information", timeout=2.5)

    def action_toggle_superseded(self) -> None:
        self.state.show_superseded = self.service.toggle_superseded()
        self.run_worker(self._reload_browser(), group="browser", exclusive=True)

    def action_copy_spritesheet(self) -> None:
        if self.state.selection is None:
            self._activity("No animation selected", "WARN"); return
        self.run_worker(self._copy_spritesheet(), group="clipboard", exclusive=True, exit_on_error=False)

    async def _copy_spritesheet(self) -> None:
        try:
            live_path = live_frames = live_size = None
            workbench = self._selected_live_workbench_path()
            if workbench is not None and self._live_document_matches_selection() and self.live_bridge.snapshot().status is LiveBridgeUIStatus.CONNECTED:
                export = await self.live_bridge.request_preview_export(
                    workbench, self.live_bridge.server.state.document_revision, self.state.copy_mode,
                )
                live_path = Path(export["output_path"])
                live_frames = int(export["frames"])
                live_size = (int(export["frame_width"]), int(export["frame_height"]))
            result = await self._thread(self.service.copy_spritesheet, self.state.selection, mode=self.state.copy_mode, live_path=live_path, live_frames=live_frames, live_frame_size=live_size)
            width, height = result["size"]
            message = f"Copied {result['mode'].upper().replace('_', '+')} · {result['source'].upper()} · {result['identity']} · {result['frames']}f · {width}×{height}"
            self._activity(message, "OK")
            self.notify(message, severity="information", timeout=4.0)
        except Exception as error:
            self.notify(f"Copy failed: {error}", severity="error", timeout=5.0)
            self._error(error)
    def action_full_refresh(self) -> None: self.run_worker(self._reload_browser(), group="browser", exclusive=True)

    def _set_mode(self, mode: str) -> None:
        self.state.mode = mode
        self._reset_preview_clock()
        ids = {"plan": "#plan-mode", "workbench": "#workspace-row", "preview": "#preview-mode", "timeline": "#timeline-mode", "motion": "#motion-mode"}
        for name, selector in ids.items(): self._main_widget(selector, Widget).set_class(name != mode, "hidden")
        self._main_widget("#context-key-bar", ContextKeyBar).set_mode(mode, self.state.copy_mode, self.state.show_superseded)
        if mode == "preview": self.run_worker(self._load_preview(), group="preview-image", exclusive=True)
        if mode == "timeline":
            self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence)
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)
        if mode == "motion":
            self._motion_last_tick = time.monotonic()
            self.run_worker(self._load_motion_preview(), group="motion-image", exclusive=True)

    def action_mode_plan(self): self._set_mode("plan")
    def action_mode_workbench(self): self._set_mode("workbench")
    def action_mode_preview(self): self._set_mode("preview")
    def action_mode_timeline(self): self._set_mode("timeline")
    def action_mode_motion(self): self._set_mode("motion")

    async def _load_preview(self) -> None:
        selection = self._require_selection()
        if not selection: return
        try:
            if self.state.preview_source == "workbench" and self._live_document_matches_selection():
                workbench = self._selected_live_workbench_path()
                if workbench is not None:
                    try:
                        await self.live_bridge.export_preview(
                            workbench, self.live_bridge.server.state.document_revision,
                        )
                        return
                    except (ConnectionError, ValueError):
                        pass
            self.preview_view = await self._thread(self.service.preview, selection, self.state.preview_source)
            self.state.preview_frame = min(self.state.preview_frame, len(self.preview_view.frames) - 1)
            self._reset_preview_clock()
            if self.state.preview_examiner_mode == "transition":
                await self._load_transition_examiner()
            else:
                await self._load_preview_comparison()
            self._render_preview()
        except Exception as error: self._error(error)

    def _normalized_compare_source(self) -> str:
        sources = ("workbench", "canonical", "runtime")
        requested = self.state.preview_compare_source
        primary = self.preview_view.source if self.preview_view is not None else self.state.preview_source
        if primary == "live" and requested in sources:
            return requested
        start = sources.index(requested) if requested in sources else -1
        for offset in range(1, len(sources) + 1):
            candidate = sources[(start + offset) % len(sources)]
            if candidate != primary:
                return candidate
        return "workbench"

    async def _load_preview_comparison(self, *, force: bool = False) -> None:
        if self.state.mode != "preview" or self.state.preview_examiner_mode == "single" or self.preview_view is None:
            self.preview_compare_view = None; self.preview_comparisons = (); return
        selection = self.state.selection
        if selection is None: return
        source = self._normalized_compare_source()
        if not force and self.preview_compare_view is not None and self.preview_compare_view.source == source and self.preview_compare_view.identity == self.preview_view.identity:
            self._rebuild_preview_comparison(); return
        try:
            self.preview_compare_view = await self._thread(self.service.preview, selection, source)
            self.state.preview_compare_source = source
            self._rebuild_preview_comparison()
        except Exception as error:
            self._activity(f"Preview comparison unavailable: {error}", "WARN")

    def _transition_target(self) -> AnimationSelection | None:
        if not self.transition_candidates:
            return None
        requested = self.state.transition_target_identity
        for candidate in self.transition_candidates:
            if candidate.identity == requested:
                return candidate
        target = self.transition_candidates[0]
        self.state.transition_target_identity = target.identity
        return target

    async def _load_transition_examiner(self) -> None:
        if self.state.mode != "preview" or self.state.preview_examiner_mode != "transition" or self.preview_view is None or self.state.selection is None:
            return
        try:
            self.transition_candidates = await self._thread(self.service.transition_candidates, self.state.selection)
            target = self._transition_target()
            if target is None:
                self.transition_target_view = None; self.transition_analysis = None
                self._activity("No compatible transition target", "WARN")
                self._render_preview(); return
            self.transition_target_view = await self._thread(self.service.transition_preview, target, self.preview_view.source)
            self.transition_analysis = await self._thread(partial(
                animation_transition.analyze_transition,
                self.preview_view.frames, self.transition_target_view.frames, tail=2, head=2,
            ))
            self.state.preview_playing = False
            self._render_preview()
        except Exception as error:
            self.transition_target_view = None; self.transition_analysis = None
            self._activity(f"Transition Examiner unavailable: {error}", "WARN")
            self._render_preview()

    def _rebuild_preview_comparison(self) -> None:
        if self.preview_view is None or self.preview_compare_view is None:
            self.preview_comparisons = (); return
        self.preview_comparisons = animation_preview.compare_previews(self.preview_view, self.preview_compare_view)

    def _preview_frame_or_blank(self, preview, index: int, fallback_size: tuple[int, int]):
        if preview is not None and 0 <= index < len(preview.frames): return preview.frames[index]
        return animation_preview.Image.new("RGBA", fallback_size, (0, 0, 0, 0))

    def _motion_selection(self) -> AnimationSelection | None:
        base = self.state.selection
        if base is None:
            return None
        direction = self.state.motion.heading or base.direction
        return AnimationSelection(
            base.profile, base.group, base.action, direction,
            base.weapon_id, base.linked_profile,
        )

    async def _load_motion_preview(self) -> None:
        selection = self._motion_selection()
        if not selection: return
        try:
            self.preview_view = await self._thread(self.service.preview, selection, self.state.preview_source)
            self.motion_markers = await self._thread(self.service.motion_event_markers, selection)
            self.motion_renderer = await self._thread(
                animation_motion_preview.MotionPreviewRenderer, self.service.repo_root,
                self.preview_view.frames, self.state.motion.ground, self.motion_markers,
            )
            self._render_motion()
        except Exception as error: self._error(error)

    def _motion_config(self):
        if not self.preview_view: return None
        motion = self.state.motion
        return animation_motion_preview.MotionConfig(
            self.preview_view.identity, self.state.review_fps, motion.travel_px,
            motion.curve, self.preview_view.identity.direction,
            animation_motion_preview.CANVAS_SIZE, motion.ground, motion.mode,
            len(self.preview_view.frames), motion.loop_cycles,
        )

    def _render_motion(self) -> None:
        config = self._motion_config()
        if config is None or self.motion_renderer is None: return
        motion = self.state.motion
        rendered = self.motion_renderer.render(
            config, motion.elapsed_sec, loop=motion.loop, show_grid=motion.show_grid,
            show_start_ghost=motion.show_start_ghost,
            show_contact_markers=motion.show_contact_markers,
        )
        self.state.preview_frame = rendered.sample.frame_index
        self._main_widget("#motion-canvas", MotionCanvas).show_frame(rendered.image, self.preview_view.identity.key, self.state.preview_zoom)
        self._main_widget("#motion-controls", MotionControls).show(
            mode=motion.mode, heading=self.preview_view.identity.direction,
            ground=motion.ground, curve=motion.curve, travel_px=motion.travel_px,
            fps=self.state.review_fps, loop=motion.loop, loop_cycles=motion.loop_cycles,
        )
        self._main_widget("#motion-metrics", MotionMetrics).show(
            rendered.sample, len(self.preview_view.frames), rendered.warnings,
            bool(self.motion_markers), loop=motion.loop, loop_cycles=motion.loop_cycles,
        )
        self._main_widget("#motion-preview-controls", PreviewControls).show(
            frame=rendered.sample.frame_index, frames=len(self.preview_view.frames),
            fps=self.state.review_fps, playing=motion.playing, loop=motion.loop,
            source=self.state.preview_source, zoom=self.state.preview_zoom,
        )

    def _render_preview(self) -> None:
        if self.state.mode == "timeline":
            if not self.timeline_frames: return
            index = self.state.preview_frame; clip, source_frame, frame = self.timeline_frames[index]
            self._main_widget("#timeline-table", TimelineTable).select_clip(clip)
            timeline_clip = self.sequence.clips[clip]
            label = f"CLIP {clip + 1} · {timeline_clip.identity.key} · SOURCE FRAME {source_frame + 1}"
            self._main_widget("#timeline-canvas", PreviewCanvas).show_frame(frame, label, self.state.preview_zoom)
            fps = self.sequence.clips[clip].review_fps
            self._main_widget("#timeline-controls", PreviewControls).show(frame=index, frames=len(self.timeline_frames), fps=fps, playing=self.state.preview_playing, loop=self.state.preview_loop, source=self.state.preview_source, zoom=self.state.preview_zoom)
            return
        if not self.preview_view: return
        primary = self.preview_view
        index = min(self.state.preview_frame, len(primary.frames) - 1)
        self.state.preview_frame = index
        canvas = self._main_widget("#preview-canvas", PreviewCanvas)
        compare_canvas = self._main_widget("#preview-compare-canvas", PreviewCanvas)
        metrics_widget = self._main_widget("#preview-diff-metrics", Static)
        filmstrip = self._main_widget("#preview-filmstrip", PreviewFilmstrip)
        mode = self.state.preview_examiner_mode
        if mode == "transition":
            self._render_transition_examiner(canvas, compare_canvas, metrics_widget, filmstrip)
            return
        primary_label = animation_preview.preview_source_label(primary.source)
        changed = ()
        if mode == "single" or self.preview_compare_view is None:
            compare_canvas.add_class("hidden")
            canvas.show_frame(primary.frames[index], f"{primary.identity.key} · {primary_label}", self.state.preview_zoom)
            metrics_widget.update(f"{primary_label} · {len(primary.frames)} frames · {primary.frame_size[0]}×{primary.frame_size[1]}")
        else:
            secondary = self.preview_compare_view
            secondary_label = animation_preview.preview_source_label(secondary.source)
            if not self.preview_comparisons: self._rebuild_preview_comparison()
            comparison = self.preview_comparisons[index] if index < len(self.preview_comparisons) else None
            if comparison is None: return
            if mode == "split":
                compare_canvas.remove_class("hidden")
                canvas.show_frame(primary.frames[index], primary_label, self.state.preview_zoom)
                compare_canvas.show_frame(self._preview_frame_or_blank(secondary, index, secondary.frame_size), secondary_label, self.state.preview_zoom)
            else:
                compare_canvas.add_class("hidden")
                canvas.show_frame(comparison.diff, f"DIFF {primary_label} ↔ {secondary_label}", self.state.preview_zoom)
            m = comparison.metrics
            pixels = "MATCH" if m.changed_pixels == 0 else f"{m.changed_pixels} PX CHANGED"
            bbox = "none" if m.bbox is None else f"{m.bbox[0]},{m.bbox[1]}–{m.bbox[2]},{m.bbox[3]}"
            metrics_widget.update(f"{primary_label} ↔ {secondary_label} · {pixels} · BBOX {bbox} · FRAMES {len(primary.frames)}/{len(secondary.frames)} · CANVAS {primary.frame_size[0]}×{primary.frame_size[1]}/{secondary.frame_size[0]}×{secondary.frame_size[1]}")
            changed = tuple(not row.metrics.equal for row in self.preview_comparisons)
        filmstrip.show_frames(tuple(primary.frames), current=index, changed=changed)
        compare_source = animation_preview.preview_source_label(self.preview_compare_view.source) if self.preview_compare_view else None
        self._main_widget("#preview-controls", PreviewControls).show(frame=index, frames=len(primary.frames), fps=self.state.review_fps, playing=self.state.preview_playing, loop=self.state.preview_loop, source=primary_label, zoom=self.state.preview_zoom, view=mode, compare_source=compare_source)

    def _render_transition_examiner(self, canvas, compare_canvas, metrics_widget, filmstrip) -> None:
        primary = self.preview_view; target = self.transition_target_view; analysis = self.transition_analysis
        if primary is None or target is None or analysis is None:
            compare_canvas.add_class("hidden")
            metrics_widget.update("TRANSITION · no compatible target loaded")
            if primary is not None:
                filmstrip.show_frames(tuple(primary.frames), current=0)
            return
        from_label = animation_preview.preview_source_label(primary.source)
        to_label = animation_preview.preview_source_label(target.source)
        view = self.state.transition_view
        if view == "split":
            compare_canvas.remove_class("hidden")
            canvas.show_frame(analysis.target_boundary, f"FROM · {primary.identity.key} · {from_label}", self.state.preview_zoom)
            compare_canvas.show_frame(analysis.reference_boundary, f"TO · {target.identity.key} · {to_label}", self.state.preview_zoom)
        else:
            compare_canvas.add_class("hidden")
            image = analysis.ghost if view == "ghost" else analysis.diff
            label = "GHOST" if view == "ghost" else "DIFF"
            canvas.show_frame(image, f"{label} · {primary.identity.key} → {target.identity.key}", self.state.preview_zoom)
        metrics = analysis.metrics
        centroid = "n/a" if metrics.visual_centroid_delta is None else f"{metrics.visual_centroid_delta[0]:+.1f},{metrics.visual_centroid_delta[1]:+.1f}"
        distance = "n/a" if metrics.centroid_distance is None else f"{metrics.centroid_distance:.2f}px"
        baseline = "n/a" if metrics.baseline_delta is None else f"{metrics.baseline_delta:+d}px"
        iou = "n/a" if metrics.silhouette_iou is None else f"{metrics.silhouette_iou:.3f}"
        metrics_widget.update(f"FROM {primary.identity.key} → TO {target.identity.key} · CENTROID Δ {centroid} ({distance}) · BASELINE Δ {baseline} · IOU {iou} · {metrics.changed_pixels} PX CHANGED")
        filmstrip.show_frames(analysis.frames, current=analysis.boundary_index, divider_after=analysis.boundary_index)
        self._main_widget("#preview-controls", PreviewControls).show(frame=analysis.boundary_index, frames=len(analysis.frames), fps=self.state.review_fps, playing=False, loop=False, source=from_label, zoom=self.state.preview_zoom, view="transition", compare_source=to_label)

    def action_preview_examiner_mode(self) -> None:
        if self.state.mode != "preview": return
        modes = ("single", "split", "diff", "transition")
        self.state.preview_examiner_mode = modes[(modes.index(self.state.preview_examiner_mode) + 1) % len(modes)]
        if self.state.preview_examiner_mode == "single":
            self.preview_compare_view = None; self.preview_comparisons = (); self.transition_target_view = None; self.transition_analysis = None; self._render_preview(); return
        if self.state.preview_examiner_mode == "transition":
            self.preview_compare_view = None; self.preview_comparisons = ()
            self.run_worker(self._load_transition_examiner(), group="transition-examiner", exclusive=True, exit_on_error=False); return
        self.transition_target_view = None; self.transition_analysis = None
        self.run_worker(self._load_preview_comparison(), group="preview-comparison", exclusive=True, exit_on_error=False)

    def action_preview_compare_source(self) -> None:
        if self.state.mode != "preview" or self.state.preview_examiner_mode in ("single", "transition"): return
        sources = ("workbench", "canonical", "runtime")
        current = sources.index(self.state.preview_compare_source) if self.state.preview_compare_source in sources else -1
        primary = self.preview_view.source if self.preview_view else ""
        for offset in range(1, len(sources) + 1):
            candidate = sources[(current + offset) % len(sources)]
            if primary == "live" or candidate != primary:
                self.state.preview_compare_source = candidate; break
        self.preview_compare_view = None; self.preview_comparisons = ()
        self.run_worker(self._load_preview_comparison(force=True), group="preview-comparison", exclusive=True, exit_on_error=False)

    def on_preview_filmstrip_selected(self, event: PreviewFilmstrip.Selected) -> None:
        if self.state.preview_examiner_mode == "transition":
            return
        if self.state.mode == "preview" and self.preview_view is not None:
            self.state.preview_playing = False
            self._set_preview_frame(event.index, sync_live=True)

    async def _send_live_layer_focus(self, workbench: Path, layer: str) -> None:
        try:
            await self.live_bridge.select_layer(workbench, layer)
        except (ConnectionError, ValueError):
            return

    async def _set_live_layer_visibility(self, workbench: Path, layer: str, visible: bool) -> None:
        try:
            await self.live_bridge.set_layer_visibility(workbench, layer, visible)
        except (ConnectionError, ValueError):
            return

    def action_layer_visibility(self) -> None:
        if self.state.mode != "workbench" or not self._live_document_matches_selection():
            return
        table = self._main_widget("#layer-table", LayerTable)
        layer = table.selected_layer_name()
        if not layer:
            return
        current = self.live_bridge.server.state.layer_visibility.get(layer)
        workbench = self._selected_live_workbench_path()
        if current is None or workbench is None:
            return
        self.run_worker(
            self._set_live_layer_visibility(workbench, layer, not current),
            group="live-layer-visibility", exclusive=True, exit_on_error=False,
        )

    def _set_preview_frame(self, frame_index: int, *, sync_live: bool) -> None:
        if self.preview_view is None:
            return
        last = len(self.preview_view.frames) - 1
        frame_index = max(0, min(last, frame_index))
        self.state.preview_frame = frame_index
        self._reset_preview_clock()
        self._render_preview()
        if sync_live and self.state.mode == "preview" and self._live_document_matches_selection():
            workbench = self._selected_live_workbench_path()
            if workbench is not None:
                self.run_worker(
                    self._send_live_frame(workbench, frame_index),
                    group="live-frame-command", exclusive=True, exit_on_error=False,
                )

    async def _send_live_frame(self, workbench: Path, frame_index: int) -> None:
        try:
            await self.live_bridge.select_frame(workbench, frame_index)
        except (ConnectionError, ValueError):
            return

    def action_preview_toggle(self):
        if self.state.mode == "workbench":
            self.action_layer_visibility()
            return
        if self.state.mode == "motion":
            self.state.motion.playing = not self.state.motion.playing
            self._motion_last_tick = time.monotonic(); self._render_motion(); return
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition":
            return
        if self.state.mode not in ("preview", "timeline"): return
        self.state.preview_playing = not self.state.preview_playing; self._reset_preview_clock(); self._render_preview()
    def action_preview_previous(self):
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition": return
        if self.state.mode == "motion" and self.preview_view:
            self.state.motion.playing = False
            frame = max(0, self.state.preview_frame - 1)
            self.state.motion.elapsed_sec = frame / self.state.review_fps
            self._render_motion(); return
        if self.state.mode == "preview" and self.preview_view:
            self.state.preview_playing = False
            self._set_preview_frame(self.state.preview_frame - 1, sync_live=True); return
        if self.timeline_frames: self.state.preview_frame = max(0, self.state.preview_frame - 1); self._reset_preview_clock(); self._render_preview()
    def action_preview_next(self):
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition": return
        if self.state.mode == "motion" and self.preview_view:
            self.state.motion.playing = False
            frame = min(len(self.preview_view.frames) - 1, self.state.preview_frame + 1)
            self.state.motion.elapsed_sec = frame / self.state.review_fps
            self._render_motion(); return
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames:
            last = frames - 1
            target = 0 if self.state.preview_loop and self.state.preview_frame == last else min(last, self.state.preview_frame + 1)
            if self.state.mode == "preview":
                self.state.preview_playing = False
                self._set_preview_frame(target, sync_live=True)
            else: self.state.preview_frame = target; self._render_preview()
    def action_preview_first(self):
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition": return
        if self.state.mode == "motion": self.state.motion.elapsed_sec = 0.0; self.state.motion.playing = False; self._render_motion(); return
        if self.state.mode == "preview":
            self.state.preview_playing = False
            self._set_preview_frame(0, sync_live=True); return
        self.state.preview_frame = 0; self._reset_preview_clock(); self._render_preview()
    def action_preview_last(self):
        if self.state.mode == "preview" and self.state.preview_examiner_mode == "transition": return
        if self.state.mode == "motion" and self.preview_view:
            self.state.motion.elapsed_sec = len(self.preview_view.frames) / self.state.review_fps
            self.state.motion.playing = False; self._render_motion(); return
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames:
            if self.state.mode == "preview":
                self.state.preview_playing = False
                self._set_preview_frame(frames - 1, sync_live=True)
            else: self.state.preview_frame = frames - 1; self._reset_preview_clock(); self._render_preview()
    def _adjust_timeline_clip_fps(self, delta: float) -> None:
        index = self._timeline_index()
        if not 0 <= index < len(self.sequence.clips): return
        self.sequence.clips[index].review_fps = min(30.0, max(1.0, self.sequence.clips[index].review_fps + delta))
        table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.select_clip(index)
        self._reset_preview_clock(); self._render_preview()

    def action_preview_slower(self):
        if self.state.mode == "timeline": self._adjust_timeline_clip_fps(-1.0); return
        self.state.review_fps = max(1.0, self.state.review_fps - 1.0); self._reset_preview_clock(); self._render_motion() if self.state.mode == "motion" else self._render_preview()

    def action_preview_faster(self):
        if self.state.mode == "timeline": self._adjust_timeline_clip_fps(1.0); return
        self.state.review_fps = min(30.0, self.state.review_fps + 1.0); self._reset_preview_clock(); self._render_motion() if self.state.mode == "motion" else self._render_preview()
    def action_preview_loop(self):
        if self.state.mode == "motion": self.state.motion.loop = not self.state.motion.loop; self._render_motion(); return
        self.state.preview_loop = not self.state.preview_loop; self._render_preview()
    def action_preview_source(self):
        if self.state.mode not in ("preview", "timeline", "motion"): return
        if self.state.mode == "timeline" and self.timeline_frames:
            clip, source_frame, _frame = self.timeline_frames[self.state.preview_frame]
            self._timeline_pending_focus = (clip, source_frame)
        sources = ("workbench", "canonical", "runtime")
        self.state.preview_source = sources[(sources.index(self.state.preview_source) + 1) % len(sources)]
        self.preview_compare_view = None
        self.preview_comparisons = ()
        self.transition_target_view = None
        self.transition_analysis = None
        self._reset_preview_clock()
        task = self._load_timeline() if self.state.mode == "timeline" else self._load_motion_preview() if self.state.mode == "motion" else self._load_preview()
        self.run_worker(task, group="preview-image", exclusive=True)

    def action_transition_target(self) -> None:
        if self.state.mode != "preview" or self.state.preview_examiner_mode != "transition" or not self.transition_candidates:
            return
        current = self.state.transition_target_identity
        index = next((i for i, candidate in enumerate(self.transition_candidates) if candidate.identity == current), -1)
        target = self.transition_candidates[(index + 1) % len(self.transition_candidates)]
        self.state.transition_target_identity = target.identity
        self.transition_target_view = None; self.transition_analysis = None
        self.run_worker(self._load_transition_examiner(), group="transition-examiner", exclusive=True, exit_on_error=False)

    def action_transition_view(self) -> None:
        if self.state.mode != "preview" or self.state.preview_examiner_mode != "transition":
            return
        views = ("split", "ghost", "diff")
        self.state.transition_view = views[(views.index(self.state.transition_view) + 1) % len(views)]
        self._render_preview()

    def action_preview_zoom(self):
        if self.state.mode not in ("preview", "timeline", "motion"): return
        modes = ("auto", "1x", "2x", "3x", "fit")
        self.state.preview_zoom = modes[(modes.index(self.state.preview_zoom) + 1) % len(modes)]
        self._render_motion() if self.state.mode == "motion" else self._render_preview()

    def action_motion_mode(self):
        if self.state.mode != "motion": return
        self.state.motion.mode = "world" if self.state.motion.mode == "treadmill" else "treadmill"; self._render_motion()
    def action_motion_heading(self):
        if self.state.mode != "motion": return
        base = self.state.selection
        if base is None: return
        available = set(self.service.available_directions(base))
        cardinal = [direction for direction in animation_motion_preview.CARDINAL_DIRECTIONS if direction in available]
        if not cardinal:
            self._activity(f"No cardinal variants available for {base.profile}/{base.group}/{base.action}", "WARN")
            return
        motion = self.state.motion
        current = motion.heading or base.direction
        motion.heading = cardinal[(cardinal.index(current) + 1) % len(cardinal)] if current in cardinal else cardinal[0]
        motion.elapsed_sec = 0.0
        motion.playing = False
        self._activity(f"MOTION HEADING {motion.heading.upper()}", "OK")
        self.run_worker(self._load_motion_preview(), group="motion-image", exclusive=True)
    def action_motion_ground(self):
        if self.state.mode != "motion": return
        grounds = animation_motion_preview.ground_ids()
        if not grounds: return
        current = self.state.motion.ground
        index = grounds.index(current) if current in grounds else -1
        self.state.motion.ground = grounds[(index + 1) % len(grounds)]
        self.run_worker(self._load_motion_preview(), group="motion-image", exclusive=True)
    def action_motion_curve(self):
        if self.state.mode != "motion": return
        curves = animation_motion_preview.CURVES; current = self.state.motion.curve
        self.state.motion.curve = curves[(curves.index(current) + 1) % len(curves)]; self._render_motion()
    def action_motion_distance(self):
        if self.state.mode != "motion": return
        values = animation_motion_preview.DISTANCE_PRESETS
        current = min(range(len(values)), key=lambda index: abs(values[index] - self.state.motion.travel_px))
        self.state.motion.travel_px = values[(current + 1) % len(values)]; self._render_motion()
    def action_motion_loop_cycles(self):
        if self.state.mode != "motion": return
        values = animation_motion_preview.LOOP_CYCLE_PRESETS
        motion = self.state.motion
        current = min(range(len(values)), key=lambda index: abs(values[index] - motion.loop_cycles))
        motion.loop_cycles = values[(current + 1) % len(values)]
        if self.preview_view:
            duration = len(self.preview_view.frames) / self.state.review_fps
            span = duration * motion.loop_cycles
            if span > 0: motion.elapsed_sec %= span
        self._activity(f"MOTION LOOP SPAN {motion.loop_cycles} cycles", "OK")
        self._render_motion()
    def _adjust_motion_travel(self, delta: float):
        if self.state.mode != "motion": return
        self.state.motion.travel_px = min(512.0, max(0.0, self.state.motion.travel_px + delta)); self._render_motion()
    def action_motion_travel_less(self):
        if self.state.mode != "motion": return
        self._adjust_motion_travel(-16.0)
    def action_motion_travel_more(self):
        if self.state.mode != "motion": return
        self._adjust_motion_travel(16.0)
    def action_motion_travel_less_large(self):
        if self._route_text_entry_shortcut("ctrl+left") or self.state.mode != "motion": return
        self._adjust_motion_travel(-32.0)
    def action_motion_travel_more_large(self):
        if self._route_text_entry_shortcut("ctrl+right") or self.state.mode != "motion": return
        self._adjust_motion_travel(32.0)
    def action_motion_reset(self):
        if self.state.mode != "motion": return
        from .state import MotionLabState
        self.state.motion = MotionLabState(); self._motion_last_tick = time.monotonic()
        self.run_worker(self._load_motion_preview(), group="motion-image", exclusive=True)

    def action_context_ctrl_r(self) -> None:
        if self._route_text_entry_shortcut("ctrl+r"):
            return
        if self.state.mode == "workbench":
            self.action_resize_canvas()
            return
        if self.state.mode == "motion":
            self.action_motion_reset()
    def action_motion_runtime(self):
        if self.state.mode != "motion": return
        selection = self._motion_selection()
        if not selection: return
        motion = self.state.motion
        try:
            self.service.launch_motion_runtime(
                selection, fps=self.state.review_fps, travel_px=motion.travel_px,
                curve=motion.curve, ground=motion.ground, mode=motion.mode,
                loop=motion.loop, loop_cycles=motion.loop_cycles,
            )
            motion.runtime_request_serial += 1
            self._activity("RUNTIME MOTION CHECK launched", "OK")
            self._activity(f"{selection.identity} · {motion.travel_px:.0f}px/cycle · {motion.loop_cycles} cycles · {self.state.review_fps:g}fps · {motion.curve.upper()}")
        except Exception as error: self._error(error)

    def _route_text_entry_shortcut(self, key: str) -> bool:
        """Keep native text-editing behavior when an app shortcut has priority."""
        focused = self.focused
        if isinstance(focused, Input):
            if key == "ctrl+r":
                return True
            action = {
                "ctrl+a": "home",
                "ctrl+left": "cursor_left_word",
                "ctrl+right": "cursor_right_word",
            }.get(key)
        elif isinstance(focused, TextArea):
            if key == "ctrl+r":
                return True
            action = {
                "ctrl+a": "cursor_line_start",
                "ctrl+left": "cursor_word_left",
                "ctrl+right": "cursor_word_right",
            }.get(key)
        else:
            return False
        if action:
            # These native Textual edit actions are synchronous widget methods.
            # Invoke them directly so the priority app binding doesn't swallow
            # normal text navigation while avoiding a second key dispatch.
            getattr(focused, f"action_{action}")()
        # These mode shortcuts have no native text-entry mapping. Consume them
        # while editing instead of allowing the app-level action to run.
        return True

    def action_timeline_add(self):
        if self._route_text_entry_shortcut("ctrl+a") or self.state.mode != "timeline": return
        selection = self._require_selection()
        if not selection: return
        self.sequence.clips.append(animation_preview.TimelineClip(selection.profile, selection.group, selection.action, selection.direction, self.state.review_fps))
        index = len(self.sequence.clips) - 1
        self._timeline_pending_focus = (index, 0)
        table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.select_clip(index)
        self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def _timeline_index(self) -> int:
        return self._main_widget("#timeline-table", TimelineTable).selected_clip_index()

    def _timeline_current_source_frame(self, clip_index: int) -> int | None:
        if not self.timeline_frames or not 0 <= self.state.preview_frame < len(self.timeline_frames): return None
        current_clip, source_frame, _frame = self.timeline_frames[self.state.preview_frame]
        return source_frame if current_clip == clip_index else None

    def _jump_timeline_clip(self, clip_index: int, source_frame: int | None = None) -> None:
        if self.state.mode != "timeline" or not self.timeline_frames: return
        matches = [i for i, (candidate, source, _frame) in enumerate(self.timeline_frames) if candidate == clip_index and (source_frame is None or source == source_frame)]
        if not matches and source_frame is not None:
            matches = [i for i, (candidate, _source, _frame) in enumerate(self.timeline_frames) if candidate == clip_index]
        if matches:
            self.state.preview_playing = False; self.state.preview_frame = matches[0]; self._reset_preview_clock(); self._render_preview()

    def action_timeline_remove(self):
        if self.state.mode != "timeline": return
        index = self._timeline_index()
        if 0 <= index < len(self.sequence.clips):
            self.sequence.clips.pop(index)
            if self.sequence.clips:
                self._timeline_pending_focus = (min(index, len(self.sequence.clips) - 1), None)
            else:
                self.state.preview_frame = 0; self.state.preview_playing = False
            table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence)
            if self.sequence.clips: table.select_clip(min(index, len(self.sequence.clips) - 1))
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def _move_clip(self, delta: int):
        if self.state.mode != "timeline": return
        index = self._timeline_index(); target = index + delta
        if 0 <= index < len(self.sequence.clips) and 0 <= target < len(self.sequence.clips):
            source_frame = self._timeline_current_source_frame(index)
            self.sequence.clips[index], self.sequence.clips[target] = self.sequence.clips[target], self.sequence.clips[index]
            self._timeline_pending_focus = (target, source_frame)
            table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.select_clip(target)
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def action_timeline_up(self):
        if self._route_text_entry_shortcut("ctrl+up") or self.state.mode != "timeline": return
        self._move_clip(-1)
    def action_timeline_down(self):
        if self._route_text_entry_shortcut("ctrl+down") or self.state.mode != "timeline": return
        self._move_clip(1)
    def action_timeline_save(self):
        if self._route_text_entry_shortcut("ctrl+s") or self.state.mode != "timeline": return
        try: self._activity(f"sequence saved: {self.service.save_sequence(self.sequence)}", "OK")
        except Exception as error: self._error(error)

    def action_timeline_load(self):
        if self._route_text_entry_shortcut("ctrl+o") or self.state.mode != "timeline": return
        try:
            self.sequence = self.service.load_sequence(self.state.sequence_name)
            self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence)
            self._timeline_pending_focus = (0, None) if self.sequence.clips else None
            if not self.sequence.clips: self.state.preview_frame = 0; self.state.preview_playing = False
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)
            self._activity(f"sequence loaded: {self.sequence.name}", "OK")
        except Exception as error: self._error(error)

    def action_timeline_clip_loops(self) -> None:
        if self.state.mode != "timeline":
            self.action_motion_loop_cycles()
            return
        index = self._timeline_index()
        if not 0 <= index < len(self.sequence.clips): return
        clip = self.sequence.clips[index]
        current = TIMELINE_LOOP_PRESETS.index(clip.loops) if clip.loops in TIMELINE_LOOP_PRESETS else -1
        clip.loops = TIMELINE_LOOP_PRESETS[(current + 1) % len(TIMELINE_LOOP_PRESETS)]
        self._timeline_pending_focus = (index, self._timeline_current_source_frame(index))
        table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.select_clip(index)
        self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def _adjust_timeline_trim(self, *, edge: str, delta: int) -> None:
        if self.state.mode != "timeline": return
        index = self._timeline_index()
        if not 0 <= index < len(self.sequence.clips): return
        clip = self.sequence.clips[index]
        try:
            frame_count = self.service.timeline_clip_frame_count(clip)
            source_frame = self._timeline_current_source_frame(index)
            animation_preview.adjust_clip_trim(clip, frame_count, edge=edge, delta=delta)
        except (ValueError, getattr(self.service.model, "WorkbenchError", RuntimeError)) as error:
            self._activity(f"Timeline trim unavailable: {error}", "WARN"); return
        self._timeline_pending_focus = (index, source_frame)
        table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.select_clip(index)
        self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def action_timeline_trim_in_forward(self): self._adjust_timeline_trim(edge="start", delta=1)
    def action_timeline_trim_in_backward(self): self._adjust_timeline_trim(edge="start", delta=-1)
    def action_timeline_trim_out_backward(self): self._adjust_timeline_trim(edge="end", delta=-1)
    def action_timeline_trim_out_forward(self): self._adjust_timeline_trim(edge="end", delta=1)

    def _reset_preview_clock(self) -> None:
        self._preview_last_tick = time.monotonic()
        self._preview_elapsed_sec = 0.0

    def _preview_tick(self) -> None:
        if self.state.mode == "motion":
            now = time.monotonic()
            delta = now - self._motion_last_tick
            self._motion_last_tick = now
            if not self.state.motion.playing or not self.preview_view: return
            motion = self.state.motion
            duration = len(self.preview_view.frames) / self.state.review_fps
            motion.elapsed_sec += delta * motion.playback_rate
            if motion.loop:
                span = duration * max(1, motion.loop_cycles)
                if motion.elapsed_sec >= span: motion.elapsed_sec %= span
            elif motion.elapsed_sec >= duration:
                motion.elapsed_sec = duration
                motion.playing = False
            self._render_motion(); return
        now = time.monotonic()
        delta = max(0.0, now - self._preview_last_tick)
        self._preview_last_tick = now
        if self.state.mode not in ("preview", "timeline") or not self.state.preview_playing: return
        self._preview_elapsed_sec += delta
        while self.state.preview_playing:
            fps = self.state.review_fps
            if self.state.mode == "timeline" and self.timeline_frames:
                clip_index = self.timeline_frames[self.state.preview_frame][0]
                fps = self.sequence.clips[clip_index].review_fps
            due, self._preview_elapsed_sec = animation_preview.consume_frame_time(
                self._preview_elapsed_sec, fps,
            )
            if not due:
                break
            frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
            if not frames:
                break
            last = frames - 1
            target = 0 if self.state.preview_loop and self.state.preview_frame == last else min(last, self.state.preview_frame + 1)
            if target == self.state.preview_frame and not self.state.preview_loop:
                self.state.preview_playing = False
            if self.state.mode == "preview": self._set_preview_frame(target, sync_live=False)
            else: self.state.preview_frame = target; self._render_preview()

    async def _load_timeline(self) -> None:
        try:
            self.timeline_frames = await self._thread(self.service.flatten_sequence, self.sequence, self.state.preview_source)
            pending = self._timeline_pending_focus; self._timeline_pending_focus = None
            if pending is not None:
                clip_index, source_frame = pending
                matches = [i for i, (candidate, source, _frame) in enumerate(self.timeline_frames) if candidate == clip_index and (source_frame is None or source == source_frame)]
                if not matches and source_frame is not None:
                    matches = [i for i, (candidate, _source, _frame) in enumerate(self.timeline_frames) if candidate == clip_index]
                if matches: self.state.preview_frame = matches[0]
            self.state.preview_frame = min(self.state.preview_frame, max(0, len(self.timeline_frames) - 1))
            self._reset_preview_clock()
            self._render_preview()
        except Exception as error: self._error(error)

    async def _watch_selected(self) -> None:
        selection = self.state.selection
        if not selection: return
        signature = self.service.watch_signature(selection)
        if signature != self.state.watch_signature:
            self.state.watch_signature = signature
            if self.preview_compare_view is not None and self.preview_compare_view.source == "workbench":
                self.preview_compare_view = None
                self.preview_comparisons = ()
            self._activity("workbench changed", "OK"); await self._load_session(selection)
            if self.state.mode == "preview":
                if self.state.preview_examiner_mode == "transition":
                    await self._load_transition_examiner()
                elif self.state.preview_examiner_mode != "single":
                    await self._load_preview_comparison(force=True)
                self._render_preview()
        process = self.state.aseprite_process
        if process is not None and process.poll() is not None:
            self.state.aseprite_process = None; self._activity("Aseprite closed")
        if self.state.active_operation:
            tx = self.service.transaction_state(selection)
            if tx and getattr(self, "_last_tx_state", "") != tx[0]:
                self._last_tx_state = tx[0]; severity = "ERROR" if tx[0] in ("ROLLED_BACK", "RECOVERY_REQUIRED") else "OK"
                self._activity(tx[0].replace("_", " "), severity)
                if tx[0] == "RECOVERY_REQUIRED": self.push_screen(ErrorDialog("RECOVERY_REQUIRED", f"RECOVERY_REQUIRED\n{tx[1]}"))

    def _require_selection(self) -> AnimationSelection | None:
        if not self.state.selection: self._error(RuntimeError("Select an animation first")); return None
        return self.state.selection

    def _guard(self, operation: str) -> bool:
        if self.state.active_operation:
            selection = self.state.selection.identity if self.state.selection else ""
            self._error(RuntimeError(f"Operator Workbench operation already running:\n{self.state.active_operation} {selection}")); return False
        self.state.active_operation = operation; return True

    async def _mutate(self, operation: str, function, *args) -> None:
        if not self._guard(operation): return
        selection = self.state.selection
        self._activity(f"{operation.lower()} started")
        try:
            result = await self._thread(function, *args)
            if operation == "EDIT": self.state.aseprite_process = result; self._activity("ASEPRITE OPEN", "OK")
            else: self._activity(f"{operation.lower()} complete", "OK")
            if operation == "PUBLISH" and selection:
                transaction = self.service.transaction_state(selection)
                if transaction:
                    severity = "ERROR" if transaction[0] in ("ROLLED_BACK", "RECOVERY_REQUIRED") else "OK"
                    self._activity(transaction[0].replace("_", " "), severity)
            if selection: await self._load_session(selection)
            if operation == "PUBLISH": await self._reload_browser()
        except Exception as error: self._error(error)
        finally: self.state.active_operation = ""

    def action_edit(self) -> None:
        selection=self._require_selection()
        if selection:self.run_worker(self._mutate("EDIT",self.service.edit,selection),group="mutation")

    async def _prepare_add(self) -> None:
        selection=self._require_selection()
        if not selection:return
        try:
            current=self.session_view.workspace_frames if self.session_view else 1; position=max(1,current//2)
            preview=await self._thread(self.service.frame_preview,selection,"add",position,"duplicate-prev")
            self.push_screen(FrameAddDialog(preview),self._accept_frame)
        except Exception as error:self._error(error)
    def action_add_frame(self)->None:
        if self._guard_preview(): self.run_worker(self._prepare_add(),group="preview",exclusive=True)

    async def _prepare_remove(self)->None:
        selection=self._require_selection()
        if not selection:return
        try:
            current=self.session_view.workspace_frames if self.session_view else 1;position=max(1,current)
            preview=await self._thread(self.service.frame_preview,selection,"remove",position,"duplicate-prev")
            self.push_screen(FrameRemoveDialog(preview),self._accept_frame)
        except Exception as error:self._error(error)
    def action_remove_frame(self)->None:
        if self._guard_preview(): self.run_worker(self._prepare_remove(),group="preview",exclusive=True)

    def action_resize_canvas(self) -> None:
        if self.state.mode != "workbench" or not self._guard_preview(): return
        selection=self._require_selection()
        if selection and self.session_view:
            self.push_screen(CanvasResizeDialog(self.session_view.document_canvas), self._accept_canvas_options)

    def _accept_canvas_options(self, options: dict | None) -> None:
        if options and self.state.selection:
            self.run_worker(self._review_canvas_migration(self.state.selection, options), group="preview", exclusive=True)

    async def _review_canvas_migration(self, selection: AnimationSelection, options: dict) -> None:
        try:
            preview=await self._thread(self.service.canvas_preview, selection, options["width"], options["height"], options["scope"])
            self.push_screen(CanvasMigrationDialog(preview), lambda accepted: self._accept_canvas_migration(accepted, options))
        except Exception as error: self._error(error)

    def _accept_canvas_migration(self, accepted: bool | None, options: dict) -> None:
        if not accepted or not self.state.selection: return
        active=self.live_bridge.server.state.active_document_path
        try:
            expected=self._selected_live_workbench_path()
            if (expected is not None
                    and self.live_bridge.snapshot().status is LiveBridgeUIStatus.CONNECTED):
                self.service.require_saved_live_document_for_migration(active, expected, self.live_bridge.server.state.document_modified)
        except Exception as error:
            self._error(error)
            return
        self.run_worker(self._mutate("CANVAS MIGRATION", self.service.canvas_apply, self.state.selection, options["width"], options["height"], options["scope"]), group="mutation")

    def _accept_frame(self,result:dict|None)->None:
        selection=self.state.selection
        if result and selection:self.run_worker(self._mutate("FRAME MIGRATION",self.service.frame_apply,selection,result["operation"],result["position"],result["fill"]),group="mutation")

    async def _prepare_publish(self)->None:
        selection=self._require_selection()
        if not selection:return
        try:
            preview=await self._thread(self.service.publish_preview,selection,False)
            process=self.state.aseprite_process;opened=process is not None and process.poll() is None
            self.push_screen(PublishDialog(preview,opened),self._accept_publish)
        except Exception as error:self._error(error)
    def action_publish(self)->None:
        if self._guard_preview(): self.run_worker(self._prepare_publish(),group="preview",exclusive=True)
    def _accept_publish(self,options:tuple[bool,bool]|None)->None:
        if options is not None and self.state.selection:self.run_worker(self._mutate("PUBLISH",self.service.publish,self.state.selection,*options),group="mutation")

    def action_refresh_workbench(self)->None:
        if not self._guard_preview(): return
        selection=self._require_selection()
        if not selection:return
        if self.session_view and (self.session_view.workbench_state!="CLEAN" or self.session_view.migration):
            self.push_screen(RefreshDialog(),lambda discard:self._accept_refresh(discard))
        else:self.run_worker(self._mutate("REFRESH",self.service.refresh,selection,False),group="mutation")
    def _accept_refresh(self,discard:bool|None)->None:
        if discard and self.state.selection:self.run_worker(self._mutate("REFRESH",self.service.refresh,self.state.selection,True),group="mutation")

    def action_weapon_context(self)->None:
        selection=self._require_selection()
        if selection:self.push_screen(WeaponContextDialog(self.service.known_weapons(),selection.weapon_id),self._accept_weapon)
    def _accept_weapon(self,weapon_id:str|None)->None:
        old=self.state.selection
        if weapon_id is None or not old:return
        linked=next((x["animation_profile"] for x in self.service.known_weapons() if x["weapon_id"]==weapon_id),"")
        self.state.adopt_context(weapon_id, linked)
        self.state.selection=self.state.contextualize(old)
        self.run_worker(self._load_session(self.state.selection),group="session",exclusive=True)

    def action_validate(self)->None:
        if self._guard_preview() and self._require_selection():self.push_screen(ValidationDialog(),self._accept_validation)

    def _guard_preview(self)->bool:
        if not self.state.active_operation:return True
        selection=self.state.selection.identity if self.state.selection else ""
        self._error(RuntimeError(f"Operator Workbench operation already running:\n{self.state.active_operation} {selection}"));return False
    def _accept_validation(self,full:bool|None)->None:
        if full is not None and self.state.selection:self.run_worker(self._run_validation(full),group="mutation")
    async def _run_validation(self,full:bool)->None:
        if not self._guard("VALIDATION"):return
        try:
            for line in await self._thread(self.service.validate,self.state.selection,full):self._activity(line)
            self._activity("validation complete","OK")
        except Exception as error:self._error(error)
        finally:self.state.active_operation=""


def run_operator_workbench(*, profile: str = "", group: str = "", action: str = "", direction: str = "", weapon: str = "", linked_profile: str = "") -> int:
    startup = AnimationSelection(profile, group, action, direction, weapon, linked_profile) if all((profile, action, direction)) else None
    OperatorWorkbenchApp(startup=startup).run()
    return 0
