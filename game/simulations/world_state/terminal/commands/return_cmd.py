"""RETURN command handler."""

from game.simulations.world_state.core.config import (
    COMMAND_CENTER_LOCATION,
    FIELD_ACTION_MOVING,
    RETURN_TICKS,
)
from game.simulations.world_state.core.state import GameState


def cmd_return(state: GameState) -> list[str]:
    if not state.in_field_mode():
        return ["ALREADY IN COMMAND."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    state.field_action = FIELD_ACTION_MOVING
    state.active_task = {
        "type": "MOVE",
        "target": COMMAND_CENTER_LOCATION,
        "ticks": RETURN_TICKS,
        "total": RETURN_TICKS,
    }
    return ["RETURNING TO COMMAND CENTER."]
