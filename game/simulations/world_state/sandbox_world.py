import os

from game.simulations.world_state.core.simulation import sandbox_world


if __name__ == "__main__":
    tick_delay = float(os.getenv("TICK_DELAY", "0.05"))
    ticks = int(os.getenv("TICKS", "300"))
    sandbox_world(ticks=ticks, tick_delay=tick_delay)
