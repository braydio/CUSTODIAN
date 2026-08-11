#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/iteration"))
from run_moment import SCENARIO_ROOT, SUPPORTED_ASSERTIONS, ScenarioError, load_scenarios, validate_scenario


def rejected(candidate: dict) -> bool:
    try:
        validate_scenario(candidate, require_scene=False)
    except ScenarioError:
        return True
    return False


def main() -> int:
    scenarios = load_scenarios()
    assert len(scenarios) >= 7
    assert "traversal/ash_bell_lift_exterior_descent" in scenarios
    sample = copy.deepcopy(next(iter(scenarios.values())))
    sample.pop("_source_path", None)
    duplicate_tick = copy.deepcopy(sample)
    duplicate_tick["timeline"].insert(1, {
        "tick": duplicate_tick["timeline"][0]["tick"],
        "action": "capture_marker",
        "name": "same_tick_is_legal",
    })
    validate_scenario(duplicate_tick, require_scene=False)
    malformed = copy.deepcopy(sample)
    malformed["id"] = "../unsafe"
    assert rejected(malformed)
    missing_scene = copy.deepcopy(sample)
    missing_scene["scene"] = "res://missing_scene.tscn"
    assert rejected(missing_scene) is False
    for path in SCENARIO_ROOT.rglob("*.json"):
        validate_scenario(__import__("json").loads(path.read_text()), path)
    schema = json.loads((ROOT / "custodian/tools/iteration/moment_schema.json").read_text())
    schema_assertions = set(schema["properties"]["assertions"]["items"]["properties"]["type"]["enum"])
    assert schema_assertions == SUPPORTED_ASSERTIONS
    roles = list(sample["setup"]["roles"])
    role_a = roles[0]
    role_b = roles[1] if len(roles) > 1 else roles[0]
    for assertion in [
        {"type": "event_exactly_once", "event": "hit"},
        {"type": "event_absent", "event": "whiff"},
        {"type": "event_field_compare", "event": "hit", "field": "data.valid", "op": "eq", "value": True},
        {"type": "event_same_field", "events": ["hit", "received"], "field": "data.attack_id"},
        {"type": "event_between_ticks", "event": "hit", "start_tick": 1, "end_tick": 2, "count_op": "eq", "count": 1},
        {"type": "role_distance_compare", "role_a": role_a, "role_b": role_b, "op": "lte", "value": 64.0},
    ]:
        candidate = copy.deepcopy(sample)
        candidate["assertions"] = [assertion]
        validate_scenario(candidate, require_scene=False)
    for assertion in [
        {"type": "event_exactly_once", "event": "hit", "where": []},
        {"type": "event_exactly_once", "event": "hit", "where": {"data.attack_id": "$last"}},
        {"type": "event_field_compare", "event": "hit", "field": "data.valid", "select": "middle", "value": True},
        {"type": "event_field_compare", "event": "hit", "field": "data.valid", "op": "approximately", "value": True},
        {"type": "event_between_ticks", "event": "hit", "start_tick": 2, "end_tick": 1, "count": 1},
        {"type": "event_between_ticks", "event": "hit", "start_tick": 0, "end_tick": sample["duration_ticks"], "count": 1},
        {"type": "role_distance_compare", "role_a": role_a, "role_b": "missing_role", "op": "lte", "value": 64.0},
    ]:
        candidate = copy.deepcopy(sample)
        candidate["assertions"] = [assertion]
        assert rejected(candidate), assertion
    print("Moment Forge schema smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
