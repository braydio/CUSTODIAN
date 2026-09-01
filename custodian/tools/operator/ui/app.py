"""Textual application shell for the Operator Workbench."""
from __future__ import annotations

import asyncio
import shutil
import subprocess
from pathlib import Path

from textual.app import App
from textual.binding import Binding
from textual.widget import Widget
from textual.widgets import DataTable, Input, Static

from .dialogs import (
    ContextMismatchDialog, ErrorDialog, FrameAddDialog, FrameRemoveDialog,
    PublishDialog, RefreshDialog, ValidationDialog, WeaponContextDialog,
)
from .features import AnimationFeature
from .screens import MainScreen
from .service import WorkbenchService
from .state import AnimationSelection, ExistingContextView, WorkbenchUIState
from .widgets import (ActivityLog, AnimationDetail, AnimationTree, LayerTable,
                      PlanTable, PreviewCanvas, PreviewControls, TimelineTable,
                      WorkbenchStatusBar)
import animation_preview


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
    .mode-pane { height: 1fr; }
    #plan-table { height: 1fr; }
    #timeline-table { height: 12; }
    #timeline-canvas { height: 1fr; content-align: center middle; }
    #preview-canvas { height: 1fr; content-align: center middle; }
    #preview-controls { height: 3; content-align: center middle; background: #202734; }
    .pane-title { height: 1; padding: 0 1; text-style: bold; background: #202734; }
    .dialog { width: 72; max-height: 94%; margin: 1 4; padding: 1 2; border: thick #81a1c1; background: #202734; }
    .publish-dialog { width: 96; }
    .error-dialog { border: thick #bf616a; }
    .dialog-title { height: 2; text-align: center; text-style: bold; }
    .dialog-body { height: auto; max-height: 1fr; overflow-y: auto; }
    .dialog-buttons { height: 3; align-horizontal: right; margin-top: 1; }
    .dialog-buttons Button { margin-left: 1; }
    """
    BINDINGS = [
        ("q", "quit", "Quit"), Binding("slash", "search", "Search", priority=True), ("f5", "full_refresh", "Reload"),
        ("question_mark", "help", "Help"), ("e", "edit", "Edit"), ("a", "add_frame", "Add Frame"),
        ("x", "remove_frame", "Remove Frame"), ("p", "publish", "Publish"),
        ("r", "refresh_workbench", "Refresh"), ("w", "weapon_context", "Weapon"),
        ("v", "validate", "Validate"), ("j", "cursor_down", "Down"), ("k", "cursor_up", "Up"),
        Binding("1", "mode_plan", "Plan", priority=True), Binding("2", "mode_workbench", "Workbench", priority=True),
        Binding("3", "mode_preview", "Preview", priority=True), Binding("4", "mode_timeline", "Timeline", priority=True),
        ("space", "preview_toggle", "Play/Pause"), ("left", "preview_previous", "Previous frame"),
        ("right", "preview_next", "Next frame"), ("home", "preview_first", "First frame"),
        ("end", "preview_last", "Last frame"), ("left_square_bracket", "preview_slower", "Slower review"),
        ("right_square_bracket", "preview_faster", "Faster review"), ("l", "preview_loop", "Loop"),
        ("s", "preview_source", "Source"), ("ctrl+a", "timeline_add", "Add clip"),
        ("delete", "timeline_remove", "Remove clip"), ("ctrl+up", "timeline_up", "Move clip left"),
        ("ctrl+down", "timeline_down", "Move clip right"), ("ctrl+s", "timeline_save", "Save sequence"),
        ("ctrl+o", "timeline_load", "Load sequence"),
    ]

    def __init__(self, service: WorkbenchService | None = None, startup: AnimationSelection | None = None) -> None:
        super().__init__(); self.service = service or WorkbenchService(); self.state = WorkbenchUIState(selection=startup)
        self.features = {"animations": AnimationFeature(self.service)}; self.session_view = None
        self.main_screen: MainScreen | None = None
        self.preview_view = None
        self.timeline_frames = []
        self.sequence = animation_preview.ReviewSequence("review")

    def on_mount(self) -> None:
        self.main_screen = MainScreen()
        self.push_screen(self.main_screen)
        self.call_after_refresh(self.action_full_refresh)
        self.set_interval(1.0, self._watch_selected)
        self.set_interval(1.0 / 30.0, self._preview_tick)

    def _main_widget(self, selector, kind):
        if self.main_screen is None:
            raise RuntimeError("Operator Workbench MainScreen is not mounted")
        return self.main_screen.query_one(selector, kind)

    def _activity(self, message: str, severity: str = "INFO") -> None:
        event = self.state.add_activity(message, severity)
        self._main_widget("#activity-log", ActivityLog).add_event(event)

    async def _thread(self, function, *args): return await asyncio.to_thread(function, *args)

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
            branch, dirty = await self._thread(self._repo_status)
            aseprite = str(self.service.workbench.resolve_aseprite(self.service.aseprite) or "unavailable")
            self._main_widget("#workbench-status", WorkbenchStatusBar).set_status(branch, dirty, aseprite)
            if hasattr(self.service, "animation_plan"):
                self._main_widget("#plan-table", PlanTable).set_items(await self._thread(self.service.animation_plan))
            action_count = len({(row.selection.profile, row.selection.group, row.selection.action) for row in filtered})
            self._activity(f"browser refreshed: {len(filtered)} directional variants, {action_count} actions", "OK")
        except Exception as error: self._error(error)

    async def _load_session(self, selection: AnimationSelection) -> bool:
        try:
            session = await self._thread(self.service.session, selection); self.session_view = session
            self.state.selection = selection; self.state.watch_signature = self.service.watch_signature(selection)
            self._main_widget("#animation-detail", AnimationDetail).show_session(session)
            self._main_widget("#layer-table", LayerTable).show_session(session)
            layer_table = self._main_widget("#layer-table", LayerTable)
            self._main_widget("#layer-detail", Static).update(layer_table.selected_detail(0))
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
        if event.data_table.id != "plan-table": return
        item_id = str(event.row_key.value)
        item = next((row for row in self.service.animation_plan() if row["id"] == item_id), None)
        if item:
            direction = (item.get("covered_directions") or item["directions"])[0]
            self.state.selection = self.state.contextualize(AnimationSelection(item["profile"], item["group"], item["action"], direction))
            self._set_mode("workbench")
            self.run_worker(self._load_session(self.state.selection), group="session", exclusive=True)

    def on_preview_controls_scrubbed(self, event: PreviewControls.Scrubbed) -> None:
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames: self.state.preview_frame = round(event.ratio * (frames - 1)); self._render_preview()

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
    def action_full_refresh(self) -> None: self.run_worker(self._reload_browser(), group="browser", exclusive=True)

    def _set_mode(self, mode: str) -> None:
        self.state.mode = mode
        ids = {"plan": "#plan-mode", "workbench": "#workspace-row", "preview": "#preview-mode", "timeline": "#timeline-mode"}
        for name, selector in ids.items(): self._main_widget(selector, Widget).set_class(name != mode, "hidden")
        if mode == "preview": self.run_worker(self._load_preview(), group="preview-image", exclusive=True)
        if mode == "timeline":
            self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence)
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def action_mode_plan(self): self._set_mode("plan")
    def action_mode_workbench(self): self._set_mode("workbench")
    def action_mode_preview(self): self._set_mode("preview")
    def action_mode_timeline(self): self._set_mode("timeline")

    async def _load_preview(self) -> None:
        selection = self._require_selection()
        if not selection: return
        try:
            self.preview_view = await self._thread(self.service.preview, selection, self.state.preview_source)
            self.state.preview_frame = min(self.state.preview_frame, len(self.preview_view.frames) - 1)
            self._render_preview()
        except Exception as error: self._error(error)

    def _render_preview(self) -> None:
        if self.state.mode == "timeline":
            if not self.timeline_frames: return
            index = self.state.preview_frame; clip, source_frame, frame = self.timeline_frames[index]
            self._main_widget("#timeline-canvas", PreviewCanvas).show_frame(frame, f"CLIP {clip + 1} · SOURCE FRAME {source_frame + 1}")
            fps = self.sequence.clips[clip].review_fps
            self._main_widget("#timeline-controls", PreviewControls).show(frame=index, frames=len(self.timeline_frames), fps=fps, playing=self.state.preview_playing, loop=self.state.preview_loop, source=self.state.preview_source)
            return
        if not self.preview_view: return
        index = self.state.preview_frame
        self._main_widget("#preview-canvas", PreviewCanvas).show_frame(self.preview_view.frames[index], self.preview_view.identity.key)
        self._main_widget("#preview-controls", PreviewControls).show(frame=index, frames=len(self.preview_view.frames), fps=self.state.review_fps, playing=self.state.preview_playing, loop=self.state.preview_loop, source=self.state.preview_source)

    def action_preview_toggle(self):
        if self.state.mode not in ("preview", "timeline"): return
        self.state.preview_playing = not self.state.preview_playing; self._render_preview()
    def action_preview_previous(self):
        if self.preview_view or self.timeline_frames: self.state.preview_frame = max(0, self.state.preview_frame - 1); self._render_preview()
    def action_preview_next(self):
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames:
            last = frames - 1
            self.state.preview_frame = 0 if self.state.preview_loop and self.state.preview_frame == last else min(last, self.state.preview_frame + 1); self._render_preview()
    def action_preview_first(self): self.state.preview_frame = 0; self._render_preview()
    def action_preview_last(self):
        frames = len(self.timeline_frames) if self.state.mode == "timeline" else len(self.preview_view.frames) if self.preview_view else 0
        if frames: self.state.preview_frame = frames - 1; self._render_preview()
    def action_preview_slower(self): self.state.review_fps = max(1.0, self.state.review_fps - 1.0); self._render_preview()
    def action_preview_faster(self): self.state.review_fps = min(30.0, self.state.review_fps + 1.0); self._render_preview()
    def action_preview_loop(self): self.state.preview_loop = not self.state.preview_loop; self._render_preview()
    def action_preview_source(self):
        if self.state.mode not in ("preview", "timeline"): return
        sources = ("workbench", "canonical", "runtime")
        self.state.preview_source = sources[(sources.index(self.state.preview_source) + 1) % len(sources)]
        task = self._load_timeline() if self.state.mode == "timeline" else self._load_preview()
        self.run_worker(task, group="preview-image", exclusive=True)

    def action_timeline_add(self):
        selection = self._require_selection()
        if not selection: return
        self.sequence.clips.append(animation_preview.TimelineClip(selection.profile, selection.group, selection.action, selection.direction, self.state.review_fps))
        self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence)
        self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def _timeline_index(self) -> int:
        return self._main_widget("#timeline-table", TimelineTable).cursor_row

    def action_timeline_remove(self):
        index = self._timeline_index()
        if 0 <= index < len(self.sequence.clips): self.sequence.clips.pop(index); self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence); self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def _move_clip(self, delta: int):
        index = self._timeline_index(); target = index + delta
        if 0 <= index < len(self.sequence.clips) and 0 <= target < len(self.sequence.clips):
            self.sequence.clips[index], self.sequence.clips[target] = self.sequence.clips[target], self.sequence.clips[index]
            table = self._main_widget("#timeline-table", TimelineTable); table.set_sequence(self.sequence); table.move_cursor(row=target)
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)

    def action_timeline_up(self): self._move_clip(-1)
    def action_timeline_down(self): self._move_clip(1)
    def action_timeline_save(self):
        try: self._activity(f"sequence saved: {self.service.save_sequence(self.sequence)}", "OK")
        except Exception as error: self._error(error)

    def action_timeline_load(self):
        try:
            self.sequence = self.service.load_sequence(self.state.sequence_name)
            self._main_widget("#timeline-table", TimelineTable).set_sequence(self.sequence)
            self.run_worker(self._load_timeline(), group="timeline-image", exclusive=True)
            self._activity(f"sequence loaded: {self.sequence.name}", "OK")
        except Exception as error: self._error(error)

    def _preview_tick(self) -> None:
        if self.state.mode not in ("preview", "timeline") or not self.state.preview_playing: return
        counter = getattr(self, "_preview_tick_counter", 0) + 1
        self._preview_tick_counter = counter
        fps = self.state.review_fps
        if self.state.mode == "timeline" and self.timeline_frames:
            fps = self.sequence.clips[self.timeline_frames[self.state.preview_frame][0]].review_fps
        if counter % max(1, round(30.0 / fps)) == 0: self.action_preview_next()

    async def _load_timeline(self) -> None:
        try:
            self.timeline_frames = await self._thread(self.service.flatten_sequence, self.sequence, self.state.preview_source)
            self.state.preview_frame = min(self.state.preview_frame, max(0, len(self.timeline_frames) - 1))
            self._render_preview()
        except Exception as error: self._error(error)

    async def _watch_selected(self) -> None:
        selection = self.state.selection
        if not selection: return
        signature = self.service.watch_signature(selection)
        if signature != self.state.watch_signature:
            self.state.watch_signature = signature; self._activity("workbench changed", "OK"); await self._load_session(selection)
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
    def _accept_publish(self,full:bool|None)->None:
        if full is not None and self.state.selection:self.run_worker(self._mutate("PUBLISH",self.service.publish,self.state.selection,full),group="mutation")

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
