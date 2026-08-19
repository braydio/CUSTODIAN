#!/usr/bin/env python3
"""Validate checked-in deterministic migration fixtures without an external oracle."""

from __future__ import annotations

import json
import re
from pathlib import Path


FIXTURES = Path(__file__).resolve().parent / "fixtures" / "world_simulation"
EXPECTED = {(seed, tick) for seed in (1, 2) for tick in (0, 1, 10, 100)}
NAME = re.compile(r"seed_(\d{6})_tick_(\d{3})\.json$")


def main() -> int:
    found: set[tuple[int, int]] = set()
    failures: list[str] = []
    for path in sorted(FIXTURES.glob("*.json")):
        match = NAME.fullmatch(path.name)
        if match is None:
            failures.append(f"unexpected fixture name: {path.name}")
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            failures.append(f"invalid JSON {path.name}: {error}")
            continue
        seed, tick = int(match.group(1)), int(match.group(2))
        found.add((seed, tick))
        if payload.get("fixture_schema") != "custodian.python_sim.godot_port_parity.v2":
            failures.append(f"unexpected schema: {path.name}")
        if payload.get("checkpoint_world_tick") != tick:
            failures.append(f"checkpoint mismatch: {path.name}")
        projection = payload.get("projection")
        if not isinstance(projection, dict) or projection.get("seed") != seed:
            failures.append(f"projection seed mismatch: {path.name}")
    if found != EXPECTED:
        failures.append(f"fixture coverage mismatch: expected {sorted(EXPECTED)}, found {sorted(found)}")
    if failures:
        print("World simulation fixture validation failed:")
        print("\n".join(failures))
        return 1
    print("world simulation fixture validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
