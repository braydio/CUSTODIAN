#!/usr/bin/env python3
"""Generate deterministic offline Python fixtures for the Godot port."""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0, str(ROOT))
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState
from tools.world_parity_contract import FIXTURE_SCHEMA, COMMANDS_SCHEMA, apply_command, projection, sha256

DEFAULT_COMMANDS = [
    {"at_world_tick": 0, "sequence": 1, "kind": "set_policy", "payload": {"repair_intensity": 3, "defense_readiness": 2, "surveillance_coverage": 2}},
    *[{"at_world_tick": 0, "sequence": index + 2, "kind": "set_fabrication_allocation", "payload": {"category": category, "level": 0}} for index, category in enumerate(("DEFENSE", "DRONES", "REPAIRS", "ARCHIVE"))],
]

def export(seed: int, checkpoints: list[int], output: Path, commands: list[dict] | None = None) -> list[Path]:
    output.mkdir(parents=True, exist_ok=True); commands = commands or DEFAULT_COMMANDS; state = GameState(seed=seed); paths=[]
    by_tick: dict[int, list[dict]] = {}
    for command in sorted(commands, key=lambda c: int(c["sequence"])): by_tick.setdefault(int(command["at_world_tick"]), []).append(command)
    for tick in range(0, max(checkpoints) + 1):
        for command in by_tick.get(tick, []): apply_command(state, command)
        if tick in checkpoints:
            port_projection = projection(state)
            payload = {"fixture_schema": FIXTURE_SCHEMA, "seed": seed, "checkpoint_world_tick": tick, "commands_schema": COMMANDS_SCHEMA, "commands": commands, "projection": port_projection, "projection_sha256": sha256(port_projection)}
            path = output / f"seed_{seed:06d}_tick_{tick:03d}.json"; path.write_text(json.dumps(payload, indent=2, sort_keys=True)+"\n", encoding="utf-8"); paths.append(path)
        if tick < max(checkpoints): step_world(state, tick_delay=0.0)
    return paths

def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("--seed", type=int, action="append"); parser.add_argument("--ticks", type=int, nargs="+", default=[0,1,10,100]); parser.add_argument("--output", type=Path, default=ROOT.parent/"custodian/tools/validation/fixtures/world_simulation"); args=parser.parse_args()
    for stale in args.output.glob("*.json") if args.output.exists() else []: stale.unlink()
    for seed in args.seed or [1,2]: export(seed, sorted(set(args.ticks)), args.output)
    return 0
if __name__ == "__main__": raise SystemExit(main())
