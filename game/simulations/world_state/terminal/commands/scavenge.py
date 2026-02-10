"""SCAVENGE command handler."""

from contextlib import redirect_stdout
import io
import random

from game.simulations.world_state.core.repairs import tick_repairs
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


SCAVENGE_TICKS = 3
SCAVENGE_MIN_GAIN = 1
SCAVENGE_MAX_GAIN = 3


def cmd_scavenge(state: GameState) -> list[str]:
    """Advance time and gain materials from a scavenge run."""

    if state.is_failed:
        reason = state.failure_reason or "SESSION FAILED."
        return [reason, "SESSION TERMINATED."]

    became_failed = False
    with redirect_stdout(io.StringIO()):
        for _ in range(SCAVENGE_TICKS):
            became_failed = step_world(state)
            tick_repairs(state)
            if became_failed:
                break

    if became_failed:
        reason = state.failure_reason or "SESSION FAILED."
        return [reason, "SESSION TERMINATED."]

    gained = random.randint(SCAVENGE_MIN_GAIN, SCAVENGE_MAX_GAIN)
    state.materials += gained

    return [
        "[SCAVENGE] OPERATION COMPLETE.",
        f"[RESOURCE GAIN] +{gained} MATERIALS",
    ]
