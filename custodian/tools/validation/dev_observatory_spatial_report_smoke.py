#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ANALYZER = ROOT / "tools" / "analysis" / "analyze_dev_observatory_session.py"


def main() -> int:
    spec = importlib.util.spec_from_file_location("observatory_analyzer", ANALYZER)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    events = [
        {"kind": "incoming_hit_result", "data": {"attack_id": "normal:1", "result": "damaged", "applied_damage": 4.0, "spatial_valid": True}},
        {"kind": "marine_dash_hit_resolved", "data": {"attack_id": "marine:7", "enemy": "Marine", "attack_type": "marine_dash", "contact_model": "directional_lane", "attacker_position": [10, 20], "target_position": [30, 20], "contact_position": [30, 20], "separation_px": 20.0, "forward_distance_px": 20.0, "allowed_forward_px": 28.0, "lateral_distance_px": 0.0, "allowed_lateral_px": 16.0, "contact_utilization_ratio": 0.714, "spatial_valid": True}},
        {"kind": "incoming_hit_result", "data": {"attack_id": "marine:7", "enemy": "Marine", "attack_type": "marine_dash", "result": "damaged", "applied_damage": 30.45, "target_health_before": 30.45, "target_health_after": 0.0, "lethal": True, "player_dodge_phase": "recovery", "dodge_classification": "recovery_hit", "spatial_valid": True}},
        {"kind": "player_death", "data": {"lethal_attack_context": {"attack_id": "marine:7", "enemy": "Marine", "attack_type": "marine_dash", "damage_attempted": 30.45, "applied_damage": 30.45, "target_health_before": 30.45, "target_health_after": 0.0, "player_dodge_phase": "recovery", "dodge_classification": "recovery_hit", "spatial_valid": True}}},
        {"kind": "incoming_hit_result", "data": {"attack_id": "bad:1", "enemy": "Synthetic", "result": "damaged", "applied_damage": 2.0, "spatial_valid": False}},
        {"kind": "incoming_hit_result", "data": {"attack_id": "bogus-range:1", "enemy": "Grunt", "attack_type": "melee", "contact_model": "radial_arc", "result": "damaged", "applied_damage": 5.0, "separation_px": 159.939, "nominal_range_px": 184.0, "base_contact_range_px": 184.0, "allowed_range_px": 221.6, "melee_range_grace_multiplier": 1.15, "melee_range_grace_px": 10.0, "contact_range_source": "falcon_launch_band", "spatial_valid": True}},
        {"kind": "incoming_hit_result", "data": {"enemy": "Legacy", "result": "damaged", "applied_damage": 1.0}},
    ]
    payload = {
        "schema": module.EXPECTED_SCHEMA,
        "session": {"event_count": len(events), "warning_count": 0},
        "scene": {"name": "SpatialSmoke"},
        "metadata": {}, "counters": {}, "gauges": {}, "events": events, "warnings": [],
    }
    report = module.build_report(payload, Path("synthetic-spatial.json"), 10, 10)
    for expected in ["LETHAL HIT DIAGNOSTIC", "SUSPICIOUS HITS", "marine_dash", "30.45", "recovery_hit", "VALID", "VIOLATION", "UNKNOWN", "bogus-range:1", "range_sanity=SUSPICIOUS"]:
        assert expected in report, f"missing analyzer output: {expected}"
    print("dev_observatory_spatial_report_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
