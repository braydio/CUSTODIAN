#!/usr/bin/env python3
"""Asset Workbench (Slice 1) smoke test — FAMILY, REVIEW, PIPELINE projections.

Exercises ``custodian/tools/assets/ui`` against the live Asset Pipeline V2
authorities (``asset_contract``, ``asset_status``, ``asset_plan``,
``asset_doctor``, ``asset_catalog``) with ``ambient_baby_opossum`` as the
primary real-repository acceptance fixture. Read-only: this test must never
write to the catalog, contracts, or content directories.

Textual itself is optional in this environment (see
``custodian/tools/assets/ui/requirements.txt``); the projection/service layer
under test has no Textual dependency, so it is exercised unconditionally.
Only the final Textual-pilot check is skipped, not failed, when the optional
dependency is absent.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

CUSTODIAN = Path(__file__).resolve().parents[2]
ASSETS_DIR = CUSTODIAN / "tools/assets"
TOOLS_DIR = ASSETS_DIR.parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))
if str(TOOLS_DIR) not in sys.path:
    sys.path.append(str(TOOLS_DIR))

FIXTURE_FAMILY = "ambient_baby_opossum"
CATALOG_PATH = CUSTODIAN / "content/metadata/assets/generated/asset_catalog.generated.json"


def _hash(path: Path) -> str | None:
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def main() -> int:
    failures: list[str] = []

    from ui.service import AssetWorkbenchService
    from ui.state import AssetSelection, DirectionCoverage

    catalog_before = _hash(CATALOG_PATH)
    service = AssetWorkbenchService(CUSTODIAN)

    # 1. family discovery
    family_ids = service.family_ids()
    if FIXTURE_FAMILY not in family_ids:
        failures.append(f"family discovery: {FIXTURE_FAMILY!r} not found among {len(family_ids)} families")
        # Nothing else in this file can run meaningfully without the fixture.
        _report(failures)
        return 1 if failures else 0

    contract = service.families()[FIXTURE_FAMILY]

    # 2. Baby Opossum family projection
    projection = service.family_projection(FIXTURE_FAMILY)
    if (projection.canvas != (contract.frame_width, contract.frame_height)
            or projection.direction_policy != contract.direction_policy
            or projection.auto_mirror != contract.auto_mirror
            or projection.kind != contract.kind):
        failures.append(f"family projection does not mirror the contract: {projection}")
    total_projected_states = sum(len(states) for _, states in projection.groups)
    if total_projected_states != len(contract.states):
        failures.append(f"family projection dropped or invented states: {total_projected_states} != {len(contract.states)}")

    # 3. grouping by action_group
    expected_groups = {state.action_group for state in contract.states.values()}
    projected_groups = {name for name, _ in projection.groups}
    if projected_groups != expected_groups:
        failures.append(f"action_group grouping mismatch: {projected_groups} != {expected_groups}")

    # 4. required/recommended/optional projection
    by_id = {state.state_id: state for _, states in projection.groups for state in states}
    for state_id, contract_state in contract.states.items():
        expected_tier = "required" if contract_state.required else "recommended" if contract_state.recommended else "optional"
        if by_id[state_id].tier != expected_tier:
            failures.append(f"{state_id}: tier {by_id[state_id].tier!r} != contract tier {expected_tier!r}")

    # 5. authored vs mirrored direction coverage — must be disjoint and cover the full policy
    for state in by_id.values():
        directions_seen = {item.direction for item in state.directions}
        if directions_seen != set(contract.allowed_directions):
            failures.append(f"{state.state_id}: direction coverage {sorted(directions_seen)} != policy {sorted(contract.allowed_directions)}")
        if set(state.authored_directions) & set(state.mirrored_directions):
            failures.append(f"{state.state_id}: a direction is reported as both authored and mirrored")
    has_mirrored = any(state.mirrored_directions for state in by_id.values())
    if contract.auto_mirror and not has_mirrored:
        failures.append("auto_mirror is on but no state shows a mirrored direction — mirroring visibility is broken")

    # 6. missing-state visibility — states with no art must still appear, not be filtered out
    zero_art_states = [state for state in by_id.values() if not state.art_present]
    if not zero_art_states:
        failures.append("expected at least one currently-absent state in the live fixture; missing-state visibility can't be proven")
    for state in zero_art_states:
        if state.state_id not in by_id:
            failures.append(f"{state.state_id}: missing state was filtered out of the projection")
        if state.missing_directions != contract.allowed_directions and state.authored_directions:
            failures.append(f"{state.state_id}: reported as absent but has authored directions {state.authored_directions}")

    # 7. runtime preview frame slicing
    authored_state = next((state for state in by_id.values() if state.authored_directions), None)
    if authored_state is None:
        failures.append("no state with an authored direction; cannot verify runtime frame slicing")
    else:
        direction = authored_state.authored_directions[0]
        try:
            frames, meta = service.review_frames(FIXTURE_FAMILY, authored_state.state_id, direction, "runtime")
            if len(frames) != meta["frames"]:
                failures.append(f"{authored_state.state_id}/{direction}: sliced {len(frames)} frames but catalog declares {meta['frames']}")
            if frames and frames[0].size != tuple(meta["frame_size"]):
                failures.append(f"{authored_state.state_id}/{direction}: frame size {frames[0].size} != catalog {meta['frame_size']}")
        except Exception as error:
            failures.append(f"runtime frame slicing raised: {error}")

    # 8. read-only review behavior — the catalog file must be byte-identical after every read above
    catalog_after = _hash(CATALOG_PATH)
    if catalog_before != catalog_after:
        failures.append("asset_catalog.generated.json changed after read-only Workbench calls")
    service_source = (ASSETS_DIR / "ui/service.py").read_text(encoding="utf-8")
    for forbidden in ("save_catalog(", "asset_transaction", "stage_asset(", "update_catalog_entry("):
        if forbidden in service_source:
            failures.append(f"ui/service.py references a mutation primitive: {forbidden!r}")

    # 9. pipeline status/plan/doctor projection
    report = service.pipeline_report(FIXTURE_FAMILY)
    if not isinstance(report.plan_can_apply, bool):
        failures.append("pipeline report plan_can_apply is not a bool")
    if not isinstance(report.plan_operation_counts, dict):
        failures.append("pipeline report plan_operation_counts is not a dict")
    for issue in (*report.doctor_family_issues, *report.doctor_global_issues):
        if issue.severity not in ("error", "warning"):
            failures.append(f"doctor issue has unexpected severity: {issue.severity!r}")

    # CLI wiring: `asset ui <family>` must dispatch (or, absent the optional
    # Textual dependency, fail with the documented, actionable message).
    asset_py = ASSETS_DIR / "asset.py"
    try:
        import textual  # noqa: F401
        textual_available = True
    except ModuleNotFoundError:
        textual_available = False
    if not textual_available:
        # Only safe to invoke non-interactively when Textual is absent: with
        # it installed, this command opens an interactive TUI and would hang
        # the subprocess with no attached terminal.
        completed = subprocess.run(
            [sys.executable, str(asset_py), "ui", FIXTURE_FAMILY], cwd=CUSTODIAN,
            capture_output=True, text=True, check=False, timeout=20,
        )
        if completed.returncode != 2 or "requirements.txt" not in completed.stdout + completed.stderr:
            failures.append(f"asset ui without Textual installed should exit 2 with an install hint; got rc={completed.returncode}, out={completed.stdout!r} err={completed.stderr!r}")
    unknown = subprocess.run(
        [sys.executable, str(asset_py), "ui", "does_not_exist_family"], cwd=CUSTODIAN,
        capture_output=True, text=True, check=False, timeout=20,
    )
    if unknown.returncode != 2:
        failures.append(f"asset ui <unknown family> should exit 2; got rc={unknown.returncode}")

    # 10. optional headless Textual pilot
    if textual_available:
        try:
            from ui.app import AssetWorkbenchApp
            import asyncio

            async def _pilot_check() -> None:
                app = AssetWorkbenchApp(service=AssetWorkbenchService(CUSTODIAN), family_id=FIXTURE_FAMILY)
                async with app.run_test() as pilot:
                    await pilot.pause()
                    if app.projection is None or app.projection.family_id != FIXTURE_FAMILY:
                        failures.append("Textual pilot: FAMILY mode did not load the fixture family")
                    await pilot.press("2")
                    await pilot.pause()
                    if app.state.mode != "review":
                        failures.append("Textual pilot: mode switch to REVIEW did not register")
                    await pilot.press("3")
                    await pilot.pause()
                    if app.pipeline is None:
                        failures.append("Textual pilot: PIPELINE mode did not load a report")

            asyncio.run(_pilot_check())
        except Exception as error:
            failures.append(f"Textual pilot raised: {error}")
        note = "Textual pilot: ran"
    else:
        note = "Textual pilot: skipped (optional dependency not installed)"

    print(f"asset_workbench_ui_smoke: {FIXTURE_FAMILY} — {total_projected_states} states, {len(projected_groups)} groups. {note}")
    print("CUSTODIAN_TEST_RESULT_JSON:" + json.dumps({
        "schema": "custodian.headless_test.result.v1",
        "test": "asset_workbench_ui_smoke",
        "passed": not failures,
        "failure_count": len(failures),
        "failures": failures,
    }, sort_keys=True))
    if failures:
        print(f"asset_workbench_ui_smoke: FAIL ({len(failures)})")
        for message in failures:
            print(f"  - {message}")
        return 1
    print("asset_workbench_ui_smoke: PASS")
    return 0


def _report(failures: list[str]) -> None:
    print("CUSTODIAN_TEST_RESULT_JSON:" + json.dumps({
        "schema": "custodian.headless_test.result.v1",
        "test": "asset_workbench_ui_smoke",
        "passed": not failures,
        "failure_count": len(failures),
        "failures": failures,
    }, sort_keys=True))
    for message in failures:
        print(f"  - {message}")


if __name__ == "__main__":
    raise SystemExit(main())
