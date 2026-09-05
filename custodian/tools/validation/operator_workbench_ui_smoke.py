#!/usr/bin/env python3
"""Non-mutating service and optional headless Textual smoke for Operator UI V1."""
from __future__ import annotations

import asyncio
import json
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

OPERATOR_ROOT = Path(__file__).resolve().parents[1] / "operator"
sys.path.insert(0, str(OPERATOR_ROOT))

from ui.service import WorkbenchService
from ui.state import AnimationRecord, AnimationSelection, ExistingContextView, LayerView, MigrationView, PublishView, SessionView


class FakeModel:
    class WorkbenchError(RuntimeError): pass

    def __init__(self, root: Path): self.root = root
    def source_index(self, _source, _weapon):
        key = lambda layer, frames: SimpleNamespace(layer=layer, frames=frames)
        return {
            ("operator", "lower_body", "unarmed", "locomotion", "run_01", "e"): (self.root / "lower.png", key("lower_body", 6)),
            ("operator", "upper_body", "unarmed", "locomotion", "run_01", "e"): (self.root / "upper.png", key("upper_body", 6)),
            ("operator", "lower_body", "unarmed", "locomotion", "run_01", "w"): (self.root / "lower_w.png", key("lower_body", 6)),
            ("operator", "upper_body", "unarmed", "locomotion", "run_01", "w"): (self.root / "upper_w.png", key("upper_body", 6)),
            ("operator", "full_body", "unarmed", "locomotion", "walk_01", "e"): (self.root / "walk.png", key("full_body", 5)),
            ("operator", "full_body", "unarmed", "defense", "guard_01", "e"): (self.root / "guard.png", key("full_body", 4)),
            ("operator", "weapon", "melee_1h", "attack", "critical_execution_01", "e"): (self.root / "critical.png", key("weapon", 8)),
            ("operator", "lower_body", "melee_1h", "posture", "idle_relaxed_01", "e"): (self.root / "idle.png", key("lower_body", 4)),
        }
    def build_plan(self, profile, action, direction, group, weapon, linked, **_kwargs):
        binding = lambda name, role="operator_layer", editable=True: {
            "binding_id": name, "aseprite_layer_name": name, "role": role,
            "editable": editable, "owner": weapon if name.startswith("weapon__") else "operator",
            "profile": linked if name.startswith("weapon__") else profile,
            "frames": 6, "frame_size": [96, 96],
            "source_contract": {"path": f"old/{name}__6f__96.png", "frames": 6},
            "workspace_contract": {"frames": 6},
            "publish_contract": {"path": f"new/{name}__7f__96.png", "frames": 7},
        }
        layers = [binding("lower_body"), binding("upper_body")]
        if weapon: layers.append(binding(f"weapon__{weapon}", "linked_weapon"))
        return {
            "identity": {"profile": profile, "group": group, "action": action, "direction": direction},
            "context": {"weapon_id": weapon, "linked_profile": linked, "presentation_mode": "authored_overlay" if weapon else ""},
            "timeline": {"source_clock_frames": 6, "workspace_clock_frames": 6, "document_frames": 6},
            "layers": layers, "references": [binding("full_body_reference", "reference", False)],
            "pending_migration": None,
        }
    def assert_context(self, data, plan):
        keys = ("weapon_id", "linked_profile", "presentation_mode")
        if any(data.get("context", {}).get(key, "") != plan.get("context", {}).get(key, "") for key in keys):
            raise self.WorkbenchError("WORKBENCH CONTEXT MISMATCH\nfixture")


class FakeWorkbench:
    DEFAULT_ROOT = Path("unused")
    def __init__(self): self.applied = 0; self.published = 0
    def workspace(self, root, identity): return Path(root) / identity["profile"] / identity["group"] / identity["action"] / identity["direction"]
    def resolve_aseprite(self, _value=None, _required=False): return Path("/bin/true")
    def load(self, path, upgrade=True): return json.loads(path.read_text())
    def state(self, _data, _path): return "CLEAN"
    def frame_migrate(self, *_args):
        operation, position, fill, dry_run = _args[3], _args[4], _args[5], _args[-1]
        if not dry_run: self.applied += 1
        return {"operation": operation, "position": {"after" if operation == "add" else "frame": position}, "fill": fill,
                "old_clock_frames": 6, "new_clock_frames": 7 if operation == "add" else 5,
                "affected_bindings": ["lower_body", "upper_body"],
                "excluded_bindings": [{"binding_id": "fx", "reason": "independent clock"}],
                "dependency_audit": {"level": "GREEN"}}
    def publish(self, manifest, _aseprite, _force, dry_run, _full, requested):
        if not dry_run: self.published += 1
        return ["new/lower_body__7f__96.png", "new/upper_body__7f__96.png"]
    def refresh(self, *args): return {}, Path(".")
    def _validation_commands(self, _data, full): return [[sys.executable, "-c", f"print('{'full' if full else 'standard'} validation')"]]


def fixture_service(root: Path):
    model, backend = FakeModel(root), FakeWorkbench()
    service = WorkbenchService(repo_root=root, source_root=root / "source", weapon_root=root / "weapons",
                               catalog_path=root / "catalog.json", workspace_root=root / "workspace",
                               model_api=model, workbench_api=backend)
    return service, backend


def pure_service_smoke() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        (root / "catalog.json").write_text(json.dumps({"weapons": {"vigil_pattern_dagger": {
            "animation_profile": "melee_1h_dagger", "presentation_mode": "authored_overlay"}}}))
        service, backend = fixture_service(root)
        records = service.browser_records()
        run = next(row for row in records if row.selection.action == "run_01")
        assert run.frames == 6 and run.layers == ("lower_body", "upper_body")
        assert len(service.filter_records(records, "locomotion")) == 3
        assert len(service.filter_records(records, "RUN_01")) == 2
        critical = next(row for row in records if row.selection.action == "critical_execution_01")
        assert critical.completeness == "PARTIAL" and critical.completeness_detail == "weapon only; no body presentation layer"
        session = service.session(run.selection)
        assert session.workbench_state == "ABSENT" and session.source_frames == 6
        assert session.workspace_display.startswith("workspace/")
        assert any(not layer.publishing and layer.layer == "full_body_reference" for layer in session.layers)
        vigil = AnimationSelection("melee_1h", "posture", "idle_relaxed_01", "e", "vigil_pattern_dagger", "melee_1h_dagger")
        vigil_session = service.session(vigil)
        assert any(layer.layer == "weapon__vigil_pattern_dagger" for layer in vigil_session.layers)
        assert service.known_weapons()[0]["presentation_mode"] == "authored_overlay"
        ws = service.workspace(run.selection); ws.mkdir(parents=True)
        plan = service._plan(run.selection)
        plan["pending_migration"] = backend.frame_migrate("", "", "", "add", 3, "duplicate-prev", "", "", "", "", "", "", True)
        plan["timeline"]["workspace_clock_frames"] = 7
        (ws / "workbench.json").write_text(json.dumps(plan)); (ws / "workbench.aseprite").write_bytes(b"fixture")
        pending = service.session(run.selection)
        assert pending.contract_state == "MIGRATION_PENDING" and pending.migration.audit == "GREEN"
        add = service.frame_preview(run.selection, "add", 3)
        remove = service.frame_preview(run.selection, "remove", 6)
        assert (add.old_frames, add.new_frames, add.affected) == (6, 7, ("lower_body", "upper_body"))
        assert remove.new_frames == 5 and backend.applied == 0
        error = service.project_error(FakeModel.WorkbenchError("WORKBENCH STALE\nsource changed"))
        assert error.title == "WORKBENCH STALE" and "source changed" in error.message

        existing_plan = service._plan(vigil)
        (ws / "workbench.json").write_text(json.dumps(existing_plan))
        inspected = service.existing_context(run.selection)
        assert inspected == ExistingContextView("vigil_pattern_dagger", "melee_1h_dagger", "authored_overlay", "")
        assert service.requested_context(run.selection).weapon_id == ""
        try: service.session(run.selection)
        except FakeModel.WorkbenchError as error: assert "CONTEXT MISMATCH" in str(error)
        else: raise AssertionError("strict context assertion was weakened")


class PilotService:
    def __init__(self):
        self.repo_root = Path.cwd(); self.aseprite = None; self.workbench = SimpleNamespace(resolve_aseprite=lambda *_: Path("/bin/true")); self.mutations = 0
        self.selection = AnimationSelection("unarmed", "locomotion", "run_01", "e")
        self.last_selection = None; self.preview_calls = 0; self.runtime_calls = 0
        self.migration = MigrationView("add", 3, "duplicate-prev", 6, 7, ("lower_body", "upper_body"), (("fx", "independent clock"),), "GREEN")
    def browser_records(self):
        return [
            AnimationRecord(self.selection, 6, ("lower_body", "upper_body")),
            AnimationRecord(AnimationSelection("unarmed", "locomotion", "run_01", "w"), 6, ("lower_body", "upper_body")),
            AnimationRecord(AnimationSelection("unarmed", "locomotion", "walk_01", "e"), 5, ("full_body",)),
            AnimationRecord(AnimationSelection("unarmed", "defense", "guard_01", "e"), 4, ("full_body",)),
        ]
    def filter_records(self, records, query): return WorkbenchService.filter_records(records, query)
    def session(self, selection):
        self.last_selection = selection
        return SessionView(selection, 6, 6, 6, "CLEAN", "NONE", "GREEN", Path("/tmp/workbench"), "/bin/true", (LayerView("lower_body", "operator_layer", "operator", "unarmed", 6, 6, 6, "96×96"),))
    def watch_signature(self, _selection): return (None, None)
    def frame_preview(self, _selection, operation, position, fill):
        if operation == "remove": return MigrationView("remove", position, fill, 6, 5, ("lower_body",), (), "GREEN")
        return self.migration
    def publish_preview(self, selection, _full): return PublishView(selection, 6, 7, ("old__6f__96.png",), ("new__7f__96.png",), self.migration, "GREEN")
    def project_error(self, error): return WorkbenchService.project_error(error)
    def transaction_state(self, _selection): return None
    def known_weapons(self): return []
    def preview(self, selection, source="runtime"):
        from PIL import Image
        import animation_preview
        self.preview_calls += 1
        frames = tuple(Image.new("RGBA", (96, 96), (20 + index, 30, 40, 180)) for index in range(6))
        identity = animation_preview.SemanticIdentity(selection.profile, selection.group, selection.action, selection.direction)
        return animation_preview.Preview(identity, source, frames, (96, 96), "fixture", ())
    def motion_event_markers(self, _selection): return ()
    def launch_motion_runtime(self, *_args, **_kwargs): self.runtime_calls += 1; return SimpleNamespace()


class ContextPilotService(PilotService):
    def __init__(self):
        super().__init__()
        self.existing = ExistingContextView("vigil_pattern_dagger", "melee_1h_dagger", "authored_overlay", "fixture")
        self.active_weapon = self.existing.weapon_id
        self.active_linked = self.existing.linked_profile
        self.refresh_calls = []
    def session(self, selection):
        self.last_selection = selection
        if (selection.weapon_id, selection.linked_profile) != (self.active_weapon, self.active_linked):
            raise FakeModel.WorkbenchError("WORKBENCH CONTEXT MISMATCH\nfixture")
        return super().session(selection)
    def existing_context(self, _selection): return self.existing
    def requested_context(self, selection):
        return ExistingContextView(selection.weapon_id, selection.linked_profile, "authored_overlay" if selection.weapon_id else "", "requested")
    def refresh(self, selection, discard=False):
        self.refresh_calls.append((selection, discard))
        self.mutations += 1
        self.active_weapon = selection.weapon_id
        self.active_linked = selection.linked_profile
        self.existing = self.requested_context(selection)
        return {}, Path(".")


async def textual_smoke() -> None:
    from PIL import Image
    from textual.app import App, ComposeResult
    from ui.app import OperatorWorkbenchApp
    from ui.dialogs import ContextMismatchDialog, FrameAddDialog, PublishDialog
    from ui.widgets import ActivityLog, AnimationDetail, AnimationTree, MotionCanvas, PreviewCanvas
    from textual.widgets import Static
    from textual_image.widget import AutoImage

    class RasterPilot(App):
        def compose(self) -> ComposeResult:
            yield PreviewCanvas("fixture", id="raster-canvas")

    raster_app = RasterPilot()
    async with raster_app.run_test(size=(80, 35)) as pilot:
        canvas = raster_app.query_one("#raster-canvas", PreviewCanvas)
        frame = Image.new("RGBA", (156, 96), (12, 34, 56, 0)); frame.putpixel((9, 8), (90, 80, 70, 123))
        canvas.show_frame(frame, "156 fixture", "1x"); await pilot.pause()
        assert canvas.source_frame is not frame and canvas.source_frame.size == (156, 96)
        assert canvas.rendered_image.size == (156, 96) and canvas.rendered_image.tobytes() == frame.tobytes()
        canvas.show_frame(frame, "156 fixture", "2x"); await pilot.pause()
        assert canvas.rendered_image.size == (312, 192)
        assert canvas.rendered_image.getpixel((18, 16)) == (90, 80, 70, 123)
        fallback = canvas.query_one(".preview-fallback", Static)
        assert canvas.low_fidelity_fallback and fallback.display
        assert "LOW-FIDELITY FALLBACK" in str(fallback.render())
        canvas.low_fidelity_fallback = False; canvas.renderer = "TGP"
        canvas.show_frame(frame, "primary fixture", "1x"); await pilot.pause()
        primary_input = canvas.query_one(".preview-raster", AutoImage).image
        assert isinstance(primary_input, Image.Image) and primary_input.mode == "RGBA"
        assert primary_input.size == (156, 96) and primary_input.tobytes() == frame.tobytes()
        square = Image.new("RGBA", (96, 96), (1, 2, 3, 77))
        canvas.show_frame(square, "96 fixture", "1x"); await pilot.pause()
        square_input = canvas.query_one(".preview-raster", AutoImage).image
        assert isinstance(square_input, Image.Image) and square_input.size == (96, 96)
        assert square_input.mode == "RGBA" and square_input.tobytes() == square.tobytes()

    service = PilotService(); app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.5)
        tree = app.screen.query_one("#animation-tree", AnimationTree)
        branches = [node.data for node in tree._walk_nodes() if isinstance(node.data, tuple)]
        assert branches.count(("unarmed",)) == 1
        assert branches.count(("unarmed", "locomotion")) == 1
        assert branches.count(("unarmed", "defense")) == 1
        assert branches.count(("unarmed", "locomotion", "run_01")) == 1
        assert branches.count(("unarmed", "locomotion", "walk_01")) == 1
        run_node = next(node for node in tree._walk_nodes() if node.data == ("unarmed", "locomotion", "run_01"))
        assert len(run_node.children) == 2
        selected_ancestry = [("unarmed",), ("unarmed", "locomotion"), ("unarmed", "locomotion", "run_01")]
        for key in selected_ancestry:
            assert next(node for node in tree._walk_nodes() if node.data == key).is_expanded
        assert not next(node for node in tree._walk_nodes() if node.data == ("unarmed", "defense")).is_expanded
        layer_table = app.screen.query_one("#layer-table")
        assert list(layer_table.columns.values())[0].label.plain == "LAYER"
        assert len(layer_table.columns) == 3
        assert layer_table.max_scroll_x == 0
        app.action_mode_plan(); await pilot.pause()
        assert app.state.mode == "plan" and not app.main_screen.query_one("#plan-mode").has_class("hidden")
        assert app.main_screen.query_one("#workspace-row").has_class("hidden")
        app.action_mode_workbench(); await pilot.pause()
        assert app.state.mode == "workbench" and not app.main_screen.query_one("#workspace-row").has_class("hidden")
        selected_identity = app.state.selection.identity
        app.set_focus(None)
        await pilot.press("5"); await pilot.pause(0.4)
        assert app.state.mode == "motion" and not app.main_screen.query_one("#motion-mode").has_class("hidden"), (app.state.mode, app.main_screen.query_one("#motion-mode").classes)
        assert all(app.main_screen.query_one(selector).has_class("hidden") for selector in ("#plan-mode", "#workspace-row", "#preview-mode", "#timeline-mode"))
        assert app.state.selection.identity == selected_identity
        motion_canvas = app.main_screen.query_one("#motion-canvas", MotionCanvas)
        assert motion_canvas.source_frame is not None and motion_canvas.source_frame.mode == "RGBA"
        motion_canvas.low_fidelity_fallback = False; motion_canvas.renderer = "TGP"; app._render_motion(); await pilot.pause()
        assert motion_canvas.query_one(".preview-raster", AutoImage).image.mode == "RGBA"
        preview_calls = service.preview_calls
        await pilot.press("s"); await pilot.pause(0.3)
        assert service.preview_calls > preview_calls
        mode = app.state.motion.mode; await pilot.press("m"); assert app.state.motion.mode != mode
        ground = app.state.motion.ground; await pilot.press("g"); await pilot.pause(0.2); assert app.state.motion.ground != ground
        curve = app.state.motion.curve; await pilot.press("c"); assert app.state.motion.curve != curve
        distance = app.state.motion.travel_px; await pilot.press("d"); assert app.state.motion.travel_px != distance
        travel = app.state.motion.travel_px; await pilot.press("shift+right"); assert app.state.motion.travel_px == travel + 16
        controls = app.main_screen.query_one("#motion-preview-controls")
        controls.post_message(controls.Scrubbed(0.75)); await pilot.pause()
        assert app.state.motion.elapsed_sec > 0 and app.state.preview_frame > 0
        before_mutations = service.mutations
        await pilot.press("enter"); assert service.runtime_calls == 1 and service.mutations == before_mutations
        await pilot.press("3"); await pilot.pause(0.3); await pilot.press("5"); await pilot.pause(0.3); await pilot.press("3"); await pilot.pause(0.3)
        assert app.state.selection.identity == selected_identity
        await pilot.press("2"); await pilot.pause()
        await pilot.press("slash"); await pilot.press("r", "u", "n", "underscore", "0", "1"); await pilot.pause()
        assert app.screen.query_one("#search").value == "run_01"
        assert "6f" in str(app.screen.query_one("#animation-detail", AnimationDetail).render())
        await pilot.press("escape"); app.screen.query_one("#animation-tree").focus()
        app.state.adopt_context("vigil_pattern_dagger", "melee_1h_dagger")
        await app.on_animation_tree_selected(SimpleNamespace(selection=AnimationSelection("unarmed", "locomotion", "walk_01", "e")))
        assert service.last_selection.weapon_id == "vigil_pattern_dagger"
        assert service.last_selection.linked_profile == "melee_1h_dagger"
        app.state.adopt_context("", "")
        await pilot.press("a"); await pilot.pause(0.3)
        assert isinstance(app.screen, FrameAddDialog) and "6" in str(app.screen.query_one("#frame-add-preview").render())
        await pilot.click("#cancel"); await pilot.pause(); assert service.mutations == 0
        await pilot.press("p"); await pilot.pause(0.3)
        assert isinstance(app.screen, PublishDialog) and "new__7f" in str(app.screen.query_one("#publish-preview").render())
        activity_log = app.main_screen.query_one("#activity-log", ActivityLog)
        activity_lines = len(activity_log.lines)
        app._activity("fixture while publish modal")
        await pilot.pause()
        assert app.state.activity[-1].message == "fixture while publish modal"
        assert len(activity_log.lines) > activity_lines
        await pilot.click("#cancel"); assert service.mutations == 0

    cancel_service = ContextPilotService()
    failing_app = OperatorWorkbenchApp(service=cancel_service, startup=cancel_service.selection)
    async with failing_app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.5)
        assert isinstance(failing_app.screen, ContextMismatchDialog)
        body = str(failing_app.screen.query_one("#context-mismatch-body", Static).render())
        assert "vigil_pattern_dagger" in body and "Requested:" in body and "Weapon: none" in body
        assert any(
            event.message == "WORKBENCH CONTEXT MISMATCH"
            for event in failing_app.state.activity
        )
        await pilot.click("#cancel"); await pilot.pause()
        assert cancel_service.mutations == 0 and cancel_service.active_weapon == "vigil_pattern_dagger"

    open_service = ContextPilotService(); open_app = OperatorWorkbenchApp(service=open_service, startup=open_service.selection)
    async with open_app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.5); assert isinstance(open_app.screen, ContextMismatchDialog)
        await pilot.click("#open-existing"); await pilot.pause(0.5)
        assert open_app.state.weapon_id == "vigil_pattern_dagger"
        assert open_app.state.linked_profile == "melee_1h_dagger"
        assert open_service.mutations == 0 and open_app.screen is open_app.main_screen

    refresh_service = ContextPilotService(); refresh_app = OperatorWorkbenchApp(service=refresh_service, startup=refresh_service.selection)
    async with refresh_app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.5); assert isinstance(refresh_app.screen, ContextMismatchDialog)
        await pilot.click("#recontextualize"); await pilot.pause(0.5)
        assert len(refresh_service.refresh_calls) == 1
        selection, discard = refresh_service.refresh_calls[0]
        assert selection.weapon_id == "" and selection.linked_profile == "" and discard is True
        assert refresh_app.screen is refresh_app.main_screen


def real_repo_read_only() -> None:
    with tempfile.TemporaryDirectory(prefix="operator_ui_readonly_") as raw:
        service = WorkbenchService(workspace_root=Path(raw) / "workspace")
        records = service.browser_records()
        run = next(row for row in records if row.selection == AnimationSelection("unarmed", "locomotion", "run_01", "e"))
        assert run.frames == 6 and set(run.layers) >= {"lower_body", "upper_body"}
        critical = next(row for row in records if row.selection == AnimationSelection("melee_1h", "attack", "critical_execution_01", "e"))
        assert critical.frames == 8 and critical.layers == ("weapon",) and critical.completeness == "PARTIAL"
        vigil = AnimationSelection("melee_1h", "posture", "idle_relaxed_01", "e", "vigil_pattern_dagger", "melee_1h_dagger")
        session = service.session(vigil)
        assert any(layer.layer == "weapon__vigil_pattern_dagger" for layer in session.layers)
        contacts = service.motion_event_markers(AnimationSelection("melee_1h", "attack", "fast_01", "e", "vigil_pattern_dagger", "melee_1h_dagger"))
        assert len(contacts) == 1 and contacts[0].kind == "CONTACT" and contacts[0].frame == 5


def main() -> None:
    pure_service_smoke()
    try:
        import textual  # noqa: F401
        import textual_image  # noqa: F401
    except ModuleNotFoundError: print("SKIP TEXTUAL PILOT: install custodian/tools/operator/ui/requirements.txt")
    else: asyncio.run(textual_smoke())
    real_repo_read_only()
    print("PASS operator_workbench_ui_smoke: service projections, dry-run safety, real discovery, optional Textual pilot")


if __name__ == "__main__": main()
