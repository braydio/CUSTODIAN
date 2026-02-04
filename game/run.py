"""
Primary game entry point for CUSTODIAN.

This runs the world simulation loop.
All tactical combat is invoked indirectly.
"""

import os
import sys
from pathlib import Path

# Ensure repo root is on sys.path when running directly from any CWD.
REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from game.simulations.world_state.core.simulation import sandbox_world

if __name__ == "__main__":
    tick_delay = float(os.getenv("TICK_DELAY", "0.05"))
    ticks = int(os.getenv("TICKS", "300"))

    print("=== CUSTODIAN :: WORLD SIMULATION ===\n")
    sandbox_world(ticks=ticks, tick_delay=tick_delay)
