import os

from game.simulations.world_state.core.simulation import sandbox_world
from game.simulations.world_state.terminal.repl import run_repl


if __name__ == "__main__":
    mode = os.getenv("WORLD_STATE_MODE", "repl").strip().casefold()
    if mode in {"repl", "terminal", "phase1"}:
        run_repl()
    else:
        tick_delay = float(os.getenv("TICK_DELAY", "0.05"))
        ticks = int(os.getenv("TICKS", "300"))
        sandbox_world(ticks=ticks, tick_delay=tick_delay)
