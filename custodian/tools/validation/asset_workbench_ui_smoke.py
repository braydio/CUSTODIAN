#!/usr/bin/env python3
"""Focused read-model, browser lifecycle, and optional Textual UI smoke."""

from __future__ import annotations

import asyncio
import hashlib
import json
import subprocess
import sys
import tempfile
import types
from dataclasses import replace
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parents[3]
ASSET_TOOLS_DIR = Path(__file__).resolve().parents[1] / "assets"
if str(ASSET_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSET_TOOLS_DIR))

from asset_workbench import AssetSnapshot, AssetWorkbenchBrowser, AssetWorkbenchService
from asset_status import get_family_status


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def family_payload(family_id: str, *, states: dict | None = None) -> dict:
    return {
        "schema": "custodian.asset_family.v2",
        "id": family_id,
        "kind": "world_prop",
        "runtime": {"domain": "sprites/environment/props", "owner": family_id},
        "canvas": {"width": 32, "height": 24},
        "direction_policy": "4dir",
        "auto_mirror": True,
        "states": states or {
            "idle": {
                "required": True,
                "layer": "body",
                "action_group": "ambient",
                "variant": "idle",
                "animation": True,
                "fps": 8,
                "frames": 4,
                "required_directions": ["n", "e", "s", "w"],
            },
            "rest": {
                "recommended": True,
                "layer": "prop",
                "action_group": "posture",
                "variant": "rest",
                "animation": False,
                "frames": 1,
                "frame_width": 16,
                "frame_height": 12,
            },
        },
        "consumers": [{"type": "scene", "path": f"res://game/{family_id}.tscn"}],
    }


def tree_fingerprint(root: Path) -> dict[str, str]:
    rows = {}
    if not root.exists():
        return rows
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        rows[path.relative_to(root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return rows


class SequenceService:
    def __init__(self, *snapshots: AssetSnapshot) -> None:
        self.snapshots = list(snapshots)
        self.calls = 0
        self.successful_calls = 0
        self.fail = False

    def build_snapshot(self) -> AssetSnapshot:
        self.calls += 1
        if self.fail:
            raise RuntimeError("fixture discovery failure")
        snapshot = self.snapshots[min(self.successful_calls, len(self.snapshots) - 1)]
        self.successful_calls += 1
        return snapshot


def build_fixture_service(root: Path) -> AssetWorkbenchService:
    families_dir = root / "content/metadata/assets/families"
    families_dir.mkdir(parents=True)
    (families_dir / "family_alpha.asset.json").write_text(
        json.dumps(family_payload("family_alpha")), encoding="utf-8"
    )
    (families_dir / "family_beta.asset.json").write_text(
        json.dumps(family_payload("family_beta", states={
            "idle": {
                "required": True,
                "layer": "body",
                "action_group": "locomotion",
                "variant": "idle",
            }
        })), encoding="utf-8"
    )
    inbox = root / "asset_drop/inbox/family_alpha"
    inbox.mkdir(parents=True)
    (inbox / "idle.png").write_bytes(b"fixture source placeholder")
    return AssetWorkbenchService(project_dir=root, families_dir=families_dir)


def check_projection_and_immutability(root: Path) -> AssetSnapshot:
    service = build_fixture_service(root)
    before = tree_fingerprint(root)
    snapshot = service.build_snapshot()
    after = tree_fingerprint(root)
    check(before == after, "read-model construction mutated fixture repository files")
    check([family.family_id for family in snapshot.families] == ["family_alpha", "family_beta"], "families are not stable-sorted")

    alpha = snapshot.family("family_alpha")
    check(alpha is not None, "fixture family is missing")
    assert alpha is not None
    check(alpha.required_completeness == "0/1 required", "required completeness was not projected from status")
    check(alpha.inbox_exists and alpha.inbox_pending_filenames == ("idle.png",), "inbox/source-pending evidence is incorrect")
    check(alpha.direction_policy == "4dir" and alpha.allowed_directions == ("n", "e", "s", "w"), "direction policy was not projected")
    check(alpha.auto_mirror, "auto-mirror policy was lost")
    check(alpha.consumers[0][0] == ("path", "res://game/family_alpha.tscn"), "consumer projection is incorrect")
    idle = alpha.state("idle")
    rest = alpha.state("rest")
    check(idle is not None and idle.role == "required", "required state role was not projected")
    check(idle is not None and idle.source_pending and not idle.art_present, "missing art and staged-source states were conflated")
    check(idle is not None and idle.animation and idle.fps == 8 and idle.expected_frames == 4, "animation contract fields were lost")
    check(idle is not None and idle.required_directions == ("n", "e", "s", "w"), "required directions were lost")
    check(rest is not None and rest.role == "recommended" and not rest.animation, "recommended/static state role was not projected")
    check(rest is not None and (rest.frame_width, rest.frame_height) == (16, 12), "state-specific dimensions were not projected")
    check(rest is not None and rest.expected_frames == 1 and rest.fps is None, "absent FPS or declared frame count was fabricated")

    beta = snapshot.family("family_beta")
    check(beta is not None and not beta.inbox_exists, "missing inbox was not represented as a normal state")
    check(beta is not None and beta.state("idle") is not None and beta.state("idle").runtime_path is None, "missing runtime output was not represented")
    return snapshot


def check_browser_lifecycle(snapshot: AssetSnapshot) -> None:
    alpha = snapshot.family("family_alpha")
    assert alpha is not None
    alpha_without_rest = replace(alpha, states=(alpha.state("idle"),))
    alpha_only = AssetSnapshot((alpha_without_rest,))
    beta_only = AssetSnapshot((snapshot.families[1],))
    service = SequenceService(snapshot, snapshot, alpha_only, beta_only)
    browser = AssetWorkbenchBrowser(service)
    first = browser.refresh()
    check(first.accepted and browser.selected_family_id == "family_alpha", "initial refresh failed to choose stable first selection")
    check(browser.select_state("family_alpha", "rest"), "fixture state selection failed")

    calls = service.calls
    check(len(browser.visible_families("beta")) == 1, "family search failed")
    check([state.state_id for state in browser.visible_states(snapshot.families[0], "posture")] == ["rest"], "state search failed")
    browser.visible_families("")
    check(service.calls == calls, "search or clearing search rescanned asset authorities")

    service.fail = True
    failed = browser.refresh()
    check(not failed.accepted and browser.snapshot is snapshot, "failed refresh replaced the last accepted snapshot")
    check(browser.selected_family_id == "family_alpha" and browser.selected_state_id == "rest", "failed refresh changed semantic selection")
    check("previous view retained" in failed.message, "refresh failure is not visible to the user")

    service.fail = False
    preserved = browser.refresh()
    check(preserved.accepted and browser.selected_state_id == "rest", "successful refresh did not preserve semantic selection")
    removed_state = browser.refresh()
    check(removed_state.accepted and removed_state.fallback and browser.selected_state_id == "idle", "removed state did not receive deterministic fallback")
    check("was removed" in removed_state.message, "state fallback was silent")
    removed_family = browser.refresh()
    check(removed_family.accepted and removed_family.fallback and browser.selected_family_id == "family_beta", "removed family did not fall back deterministically")
    check("family_alpha" in removed_family.message, "family fallback message omitted removed selection")


def check_real_baby_opossum() -> None:
    family = AssetWorkbenchService().build_snapshot().family("ambient_baby_opossum")
    check(family is not None, "real Baby Opossum family is absent from registered Asset V2 families")
    assert family is not None
    check(len(family.states) == 50, f"Baby Opossum expected 50 states, found {len(family.states)}")
    check(len({state.action_group for state in family.states}) == 7, "Baby Opossum action groups were projected incorrectly")
    check({state.layer for state in family.states} == {"body", "barrel_prop"}, "Baby Opossum layers were projected incorrectly")
    check(family.direction_policy == "4dir" and family.allowed_directions == ("n", "e", "s", "w"), "Baby Opossum direction policy is incorrect")
    check(family.auto_mirror, "Baby Opossum mirroring policy was lost")
    check(all(isinstance(state.mirrored_directions, tuple) for state in family.states), "Baby Opossum mirror provenance projection is not stable")
    if family.runtime_outputs:
        check(any(state.authored_directions for state in family.states), "Baby Opossum runtime art lost authored-direction provenance")
        check(any(state.mirrored_directions for state in family.states), "Baby Opossum runtime art lost mirrored-direction provenance")
    else:
        print("INFO Baby Opossum runtime files unavailable; mirror provenance is covered by the isolated fixture")


def check_mirror_provenance_fixture(root: Path) -> None:
    families_dir = root / "content/metadata/assets/families"
    family_payload_data = family_payload("mirror_fixture", states={
        "idle": {
            "required": True,
            "layer": "body",
            "action_group": "ambient",
            "variant": "idle",
            "required_directions": ["n", "e", "s", "w"],
        }
    })
    families_dir.mkdir(parents=True)
    (families_dir / "mirror_fixture.asset.json").write_text(json.dumps(family_payload_data), encoding="utf-8")

    def status_with_mirror_provenance(family, project_dir):
        status = get_family_status(family, project_dir)
        status.states["idle"] = replace(
            status.states["idle"],
            authored_directions=("n", "s"),
            mirrored_directions=("e", "w"),
            art_present=True,
        )
        return status

    family = AssetWorkbenchService(
        project_dir=root,
        families_dir=families_dir,
        status_loader=status_with_mirror_provenance,
    ).build_snapshot().family("mirror_fixture")
    check(family is not None, "mirror provenance fixture did not load")
    assert family is not None
    state = family.state("idle")
    check(state is not None and state.authored_directions == ("n", "s"), "authored direction provenance was lost")
    check(state is not None and state.mirrored_directions == ("e", "w"), "mirrored direction provenance was lost")


async def check_textual_pilot(snapshot: AssetSnapshot) -> None:
    try:
        from textual.widgets import Input, Static, Tree
        from asset_workbench.app import AssetWorkbenchApp
    except ModuleNotFoundError as error:
        if error.name and error.name.startswith("textual"):
            print("SKIP Textual Pilot: optional Textual dependency is not installed")
            return
        raise

    service = SequenceService(snapshot, snapshot, snapshot)
    app = AssetWorkbenchApp(service=service)
    async with app.run_test(size=(120, 42)) as pilot:
        await pilot.pause()
        check(service.calls == 1, "UI did not load exactly one accepted snapshot at startup")
        check("family_alpha" in str(app.query_one("#detail", Static).render()), "UI did not render the selected family detail")
        app.browser.select_state("family_alpha", "rest")
        app._render_detail()
        app.query_one("#search", Input).value = "beta"
        await pilot.pause()
        check(service.calls == 1, "typing in UI search triggered repository discovery")
        check("family_beta" in " ".join(str(node.label) for node in app.query_one("#family-tree", Tree).root.children), "UI search did not update family navigation")
        check(browser_selection(app) == ("family_alpha", "rest"), "filtering search changed the semantic selection")
        app.query_one("#search", Input).value = ""
        await pilot.pause()
        check(service.calls == 1, "clearing UI search triggered repository discovery")
        check(browser_selection(app) == ("family_alpha", "rest"), "clearing search changed the semantic selection")
        service.fail = True
        await pilot.click("#refresh")
        await pilot.pause()
        check(browser_selection(app) == ("family_alpha", "rest"), "UI refresh failure changed selection")
        check("previous view retained" in str(app.query_one("#activity", Static).render()), "UI hid refresh failure status")


def browser_selection(app) -> tuple[str | None, str | None]:
    return app.browser.selected_family_id, app.browser.selected_state_id


def check_cli_lazy_dependency() -> None:
    script = str(ASSET_TOOLS_DIR / "asset.py")
    blocker = (
        "import importlib.abc,runpy,sys\n"
        "class BlockTextual(importlib.abc.MetaPathFinder):\n"
        " def find_spec(self, fullname, path=None, target=None):\n"
        "  if fullname == 'textual' or fullname.startswith('textual.'):\n"
        "   raise ModuleNotFoundError(\"blocked optional Textual dependency\", name=fullname)\n"
        "sys.meta_path.insert(0, BlockTextual())\n"
        "script=sys.argv[1]; sys.argv=[script, *sys.argv[2:]]\n"
        "runpy.run_path(script, run_name='__main__')\n"
    )
    result = subprocess.run(
        [sys.executable, "-c", blocker, script, "families", "--json"],
        cwd=REPO_DIR, capture_output=True, text=True, check=False,
    )
    check(result.returncode == 0, f"ordinary asset CLI requires optional Textual: {result.stderr or result.stdout}")
    payload = json.loads(result.stdout)
    check(isinstance(payload, (list, dict)), "existing Asset CLI JSON shape is not readable")
    refusal = subprocess.run(
        [sys.executable, "-c", blocker, script, "ui"],
        cwd=REPO_DIR, capture_output=True, text=True, check=False,
    )
    check(refusal.returncode == 2 and "optional requirements" in refusal.stdout, "missing Textual did not produce an explicit install refusal")

    import asset

    launched = []
    fake_ui = types.ModuleType("asset_workbench.app")
    fake_ui.run_app = lambda: launched.append(True)
    sys.modules["asset_workbench.app"] = fake_ui
    previous_argv = sys.argv
    try:
        sys.argv = [script, "ui"]
        check(asset.main() == 0 and launched == [True], "asset ui did not dispatch to the optional Workbench app")
    finally:
        sys.argv = previous_argv
        sys.modules.pop("asset_workbench.app", None)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="asset-workbench-ui-smoke-") as temp:
        snapshot = check_projection_and_immutability(Path(temp))
        check_browser_lifecycle(snapshot)
        asyncio.run(check_textual_pilot(snapshot))
    with tempfile.TemporaryDirectory(prefix="asset-workbench-mirror-smoke-") as temp:
        check_mirror_provenance_fixture(Path(temp))
    check_real_baby_opossum()
    check_cli_lazy_dependency()
    print("PASS asset workbench read model, browser refresh, Baby Opossum projection, and optional UI")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
