#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/iteration"))
from changed_file_router import load_rules, suggest_scenarios
from run_moment import load_scenarios


def main() -> int:
    scenarios = load_scenarios()
    routes = load_rules()
    combat = suggest_scenarios(
        scenarios.values(),
        ["custodian/content/audio/sfx/combat/hit_light_body_02.wav"],
        routes,
    )
    assert combat and combat[0]["score"] > 0
    assert "combat/light_hit_grunt" in {item["id"] for item in combat}
    vista = suggest_scenarios(
        scenarios.values(),
        ["custodian/content/backgrounds/sundered_keep/approach/light/new.png"],
        routes,
    )
    assert "vista/sundered_keep_first_reveal" in {item["id"] for item in vista}
    print("Moment Forge changed-router smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
