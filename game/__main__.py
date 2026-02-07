"""Unified entrypoint for the CUSTODIAN prototype."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from game.simulations.world_state.core.simulation import sandbox_world
from game.simulations.world_state.terminal.repl import run_repl


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _run_ui() -> None:
    """Launch the terminal UI server."""

    server_path = _repo_root() / "custodian-terminal" / "server.py"
    subprocess.run([sys.executable, str(server_path)], check=True)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m game",
        description="CUSTODIAN unified entrypoint.",
    )

    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--ui",
        action="store_true",
        help="Run the terminal UI server (default).",
    )
    mode_group.add_argument(
        "--sim",
        action="store_true",
        help="Run the autonomous world simulation loop.",
    )
    mode_group.add_argument(
        "--repl",
        action="store_true",
        help="Run the world-state terminal REPL.",
    )

    parser.add_argument(
        "--ticks",
        type=int,
        default=300,
        help="Number of ticks to run in sim mode.",
    )
    parser.add_argument(
        "--tick-delay",
        type=float,
        default=0.05,
        help="Delay between ticks in sim mode (seconds).",
    )

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv or sys.argv[1:])

    if args.repl:
        run_repl()
        return 0

    if args.sim:
        sandbox_world(ticks=args.ticks, tick_delay=args.tick_delay)
        return 0

    _run_ui()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
