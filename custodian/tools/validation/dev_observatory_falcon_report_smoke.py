#!/usr/bin/env python3
"""Focused report coverage for retained Falcon Punch diagnostics."""

from __future__ import annotations

import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
ANALYZER = ROOT / "custodian/tools/analysis/analyze_dev_observatory_session.py"


def _event(kind: str, data: dict) -> dict:
    return {"kind": kind, "data": data}


def main() -> None:
    spec = importlib.util.spec_from_file_location("observatory_analyzer", ANALYZER)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    attack_id = "123:falcon:7"
    common = {
        "attack_id": attack_id,
        "phase": "windup",
        "result": "pending",
        "tracking_locked": False,
        "tracking_lock_sec": 0.25,
        "locked_direction": {"x": 1.0, "y": 0.0},
        "lock_target_position": {"x": 112.0, "y": 0.0},
        "presentation_animation": "special_windup_e",
        "presentation_frame": 0,
        "expected_animation": "special_windup_e",
        "presentation_matches_phase": True,
        "launch_distance": 112.0,
        "target_distance_at_active_start": 40.0,
        "closest_approach": 28.0,
        "lateral_error": 3.0,
        "stop_short_distance": 28.0,
        "collision_obstructed": False,
        "player_dodge_phase": "neutral",
        "spatial_valid": True,
    }
    events = [_event("grunt_falcon_punch_windup", dict(common))]
    locked = dict(common, phase="windup", tracking_locked=True, presentation_frame=4)
    events.append(_event("grunt_falcon_punch_tracking_locked", locked))
    leap = dict(locked, phase="leap", presentation_animation="special_inflight_e", presentation_frame=0, expected_animation="special_inflight_e")
    events.append(_event("grunt_falcon_punch_leap", leap))
    events.append(_event("grunt_falcon_punch_hit_resolved", dict(leap, result="damaged")))
    events.append(_event("grunt_falcon_punch_impact_lock", dict(leap, phase="impact_lock", presentation_frame=3)))
    events.append(_event("grunt_falcon_punch_recovery", dict(leap, phase="recovery", presentation_animation="special_recovery_e", expected_animation="special_recovery_e")))
    events.append(_event("grunt_falcon_punch_finished", dict(leap, phase="recovery", result="damaged")))
    payload = {"schema": module.EXPECTED_SCHEMA, "session": {"event_count": len(events)}, "events": events}
    report = module.build_report(payload, Path("synthetic-falcon.json"), 10, 10)
    for expected in [
        "FALCON PUNCH DIAGNOSTICS",
        "tracking_locked",
        "special_windup_e",
        "special_inflight_e",
        "presentation matches phase",
        "closest approach",
        "lateral error",
        "VALID",
    ]:
        assert expected in report, f"missing Falcon report text: {expected}"

    desync = dict(leap, presentation_animation="special_windup_e", presentation_matches_phase=False)
    payload["events"] = events + [_event("grunt_falcon_punch_presentation_desync", desync)]
    payload["session"]["event_count"] = len(payload["events"])
    report = module.build_report(payload, Path("synthetic-falcon-desync.json"), 10, 10)
    for expected in ["PRESENTATION DESYNC", "special_windup_e", "special_inflight_e"]:
        assert expected in report, f"missing Falcon desync text: {expected}"

    print("dev_observatory_falcon_report_smoke: PASS")


if __name__ == "__main__":
    main()
