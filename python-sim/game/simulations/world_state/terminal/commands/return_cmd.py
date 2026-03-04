"""RETURN command handler."""

from game.simulations.world_state.core.config import (
    COMMAND_CENTER_LOCATION,
    RETURN_TICKS,
)
from game.simulations.world_state.core.presence import start_move_task
from game.simulations.world_state.core.state import GameState


def cmd_return(state: GameState) -> list[str]:
    if not state.in_field_mode():
        return ["ALREADY IN COMMAND."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]
    if state.active_repairs:
        return ["ACTION IN PROGRESS."]

    start_move_task(state, COMMAND_CENTER_LOCATION, RETURN_TICKS)
    return ["RETURNING TO COMMAND CENTER."]
