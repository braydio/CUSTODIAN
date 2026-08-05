#!/usr/bin/env python3
"""Export structured Python world-state golden masters for the Godot port.

This tool is an offline oracle. Godot never imports or launches this module.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


def export(seed: int, ticks: list[int], output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    state = GameState(seed=seed)
    wanted = set(ticks)
    if 0 in wanted:
        _write(output / f"seed_{seed:06d}_initial.json", state)
    for tick in range(1, max(ticks) + 1):
        step_world(state, tick_delay=0.0)
        if tick in wanted:
            _write(output / f"seed_{seed:06d}_tick_{tick:03d}.json", state)


def _write(path: Path, state: GameState) -> None:
    snapshot = state.snapshot()
    payload = {
        "fixture_schema": "custodian.python_sim.world_parity.v1",
        "seed": int(state.seed),
        "tick": int(state.time),
        "fingerprint": snapshot.get("run_fingerprint", state.procgen_report()),
        "state": snapshot,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, action="append", default=None)
    parser.add_argument("--ticks", type=int, nargs="+", default=[0, 10, 100])
    parser.add_argument("--output", type=Path, default=ROOT.parent / "custodian/tools/validation/fixtures/world_simulation")
    args = parser.parse_args()
    for seed in (args.seed or [1, 2]):
        export(seed, sorted(set(args.ticks)), args.output)
    (args.output / "command_sequences.json").write_text(json.dumps({"schema": "custodian.python_sim.world_commands.v1", "commands": [{"kind": "set_policy", "payload": {"repair_intensity": 3, "defense_readiness": 2}}, {"kind": "damage_structure", "payload": {"structure_id": "COMMAND_CORE", "amount": 7}}]}, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
