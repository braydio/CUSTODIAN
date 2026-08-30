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
from ui.state import AnimationRecord, AnimationSelection, LayerView, MigrationView, PublishView, SessionView


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
    def assert_context(self, _data, _plan): return None


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


class PilotService:
    def __init__(self):
        self.repo_root = Path.cwd(); self.aseprite = None; self.workbench = SimpleNamespace(resolve_aseprite=lambda *_: Path("/bin/true")); self.mutations = 0
        self.selection = AnimationSelection("unarmed", "locomotion", "run_01", "e")
        self.migration = MigrationView("add", 3, "duplicate-prev", 6, 7, ("lower_body", "upper_body"), (("fx", "independent clock"),), "GREEN")
    def browser_records(self):
        return [
            AnimationRecord(self.selection, 6, ("lower_body", "upper_body")),
            AnimationRecord(AnimationSelection("unarmed", "locomotion", "run_01", "w"), 6, ("lower_body", "upper_body")),
            AnimationRecord(AnimationSelection("unarmed", "locomotion", "walk_01", "e"), 5, ("full_body",)),
            AnimationRecord(AnimationSelection("unarmed", "defense", "guard_01", "e"), 4, ("full_body",)),
        ]
    def filter_records(self, records, query): return WorkbenchService.filter_records(records, query)
    def session(self, selection): return SessionView(selection, 6, 6, 6, "CLEAN", "NONE", "GREEN", Path("/tmp/workbench"), "/bin/true", (LayerView("lower_body", "operator_layer", "operator", "unarmed", 6, 6, 6, "96×96"),))
    def watch_signature(self, _selection): return (None, None)
    def frame_preview(self, _selection, operation, position, fill):
        if operation == "remove": return MigrationView("remove", position, fill, 6, 5, ("lower_body",), (), "GREEN")
        return self.migration
    def publish_preview(self, selection, _full): return PublishView(selection, 6, 7, ("old__6f__96.png",), ("new__7f__96.png",), self.migration, "GREEN")
    def project_error(self, error): return WorkbenchService.project_error(error)
    def transaction_state(self, _selection): return None
    def known_weapons(self): return []


class FailingPilotService(PilotService):
    def session(self, _selection):
        raise FakeModel.WorkbenchError(
            "WORKBENCH CONTEXT MISMATCH\nfixture"
        )


async def textual_smoke() -> None:
    from ui.app import OperatorWorkbenchApp
    from ui.dialogs import ErrorDialog, FrameAddDialog, PublishDialog
    from ui.widgets import ActivityLog, AnimationDetail, AnimationTree
    from textual.widgets import Static
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
        await pilot.press("slash"); await pilot.press("r", "u", "n", "underscore", "0", "1"); await pilot.pause()
        assert app.screen.query_one("#search").value == "run_01"
        assert "6f" in str(app.screen.query_one("#animation-detail", AnimationDetail).render())
        await pilot.press("escape"); app.screen.query_one("#animation-tree").focus()
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

    failing_service = FailingPilotService()
    failing_app = OperatorWorkbenchApp(
        service=failing_service,
        startup=failing_service.selection,
    )
    async with failing_app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.5)
        assert isinstance(failing_app.screen, ErrorDialog)
        assert "WORKBENCH CONTEXT MISMATCH" in failing_app.screen.error_message
        assert "fixture" in failing_app.screen.error_message
        assert "WORKBENCH CONTEXT MISMATCH" in str(
            failing_app.screen.query_one(".dialog-body", Static).render()
        )
        assert any(
            event.message == "WORKBENCH CONTEXT MISMATCH"
            for event in failing_app.state.activity
        )
        assert not any(
            event.message == f"selected {failing_service.selection.identity}"
            for event in failing_app.state.activity
        )

        original_dialog = failing_app.screen
        failing_app._error(
            FakeModel.WorkbenchError("WORKBENCH CONTEXT MISMATCH\nsecond fixture")
        )
        await pilot.pause()
        assert failing_app.screen is original_dialog
        assert failing_app.screen.error_message == (
            "WORKBENCH CONTEXT MISMATCH\nfixture"
        )

        await pilot.click("#close")
        await pilot.pause()
        assert failing_app.screen is failing_app.main_screen
        assert failing_app.main_screen.query_one("#activity-log", ActivityLog)

        selected_events = len([
            event for event in failing_app.state.activity
            if event.message == f"selected {failing_service.selection.identity}"
        ])
        await failing_app.on_animation_tree_selected(
            SimpleNamespace(selection=failing_service.selection)
        )
        await pilot.pause()
        assert isinstance(failing_app.screen, ErrorDialog)
        assert len([
            event for event in failing_app.state.activity
            if event.message == f"selected {failing_service.selection.identity}"
        ]) == selected_events
        await pilot.click("#close")
        await pilot.pause()

        tree = failing_app.main_screen.query_one("#animation-tree", AnimationTree)
        tree.focus()
        await pilot.press("down")
        assert failing_app.screen is failing_app.main_screen


def real_repo_read_only() -> None:
    service = WorkbenchService()
    records = service.browser_records()
    run = next(row for row in records if row.selection == AnimationSelection("unarmed", "locomotion", "run_01", "e"))
    assert run.frames == 6 and set(run.layers) >= {"lower_body", "upper_body"}
    critical = next(row for row in records if row.selection == AnimationSelection("melee_1h", "attack", "critical_execution_01", "e"))
    assert critical.frames == 8 and critical.layers == ("weapon",) and critical.completeness == "PARTIAL"
    vigil = AnimationSelection("melee_1h", "posture", "idle_relaxed_01", "e", "vigil_pattern_dagger", "melee_1h_dagger")
    session = service.session(vigil)
    assert any(layer.layer == "weapon__vigil_pattern_dagger" for layer in session.layers)


def main() -> None:
    pure_service_smoke()
    try: import textual  # noqa: F401
    except ModuleNotFoundError: print("SKIP TEXTUAL PILOT: install custodian/tools/operator/ui/requirements.txt")
    else: asyncio.run(textual_smoke())
    real_repo_read_only()
    print("PASS operator_workbench_ui_smoke: service projections, dry-run safety, real discovery, optional Textual pilot")


if __name__ == "__main__": main()
