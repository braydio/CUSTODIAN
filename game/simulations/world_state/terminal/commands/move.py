"""MOVE command handler."""

from game.simulations.world_state.core.config import (
    FIELD_ACTION_MOVING,
    MOVE_TICKS,
    TRAVEL_GRAPH,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.location import resolve_location_token


def cmd_move(state: GameState, destination: str) -> list[str]:
    if not state.in_field_mode():
        return ["COMMAND AUTHORITY REQUIRED."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    target = resolve_location_token(destination)
    if not target:
        return ["INVALID ROUTE."]

    here = state.player_location
    valid_targets = TRAVEL_GRAPH.get(here, [])
    if target not in valid_targets:
        return ["INVALID ROUTE."]

    state.field_action = FIELD_ACTION_MOVING
    state.active_task = {
        "type": "MOVE",
        "target": target,
        "ticks": MOVE_TICKS,
        "total": MOVE_TICKS,
    }
    return [f"MOVING TO {target}."]
