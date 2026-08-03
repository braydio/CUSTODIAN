#!/usr/bin/env python3
from __future__ import annotations

import copy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/iteration"))
from run_moment import SCENARIO_ROOT, ScenarioError, load_scenarios, validate_scenario


def rejected(candidate: dict) -> bool:
    try:
        validate_scenario(candidate, require_scene=False)
    except ScenarioError:
        return True
    return False


def main() -> int:
    scenarios = load_scenarios()
    assert len(scenarios) == 7
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
    print("Moment Forge schema smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
