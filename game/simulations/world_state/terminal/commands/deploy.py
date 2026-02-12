"""DEPLOY command handler."""

from game.simulations.world_state.core.config import (
    COMMAND_CENTER_LOCATION,
    DEPLOY_TICKS,
    FIELD_ACTION_MOVING,
    PLAYER_MODE_FIELD,
    TRANSIT_NODES,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.location import resolve_location_token


def cmd_deploy(state: GameState, destination: str) -> list[str]:
    if state.player_mode != "COMMAND":
        return ["ALREADY DEPLOYED."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    target = resolve_location_token(destination)
    if target not in TRANSIT_NODES:
        return ["INVALID DEPLOYMENT TARGET."]

    state.player_mode = PLAYER_MODE_FIELD
    state.field_action = FIELD_ACTION_MOVING
    state.player_location = COMMAND_CENTER_LOCATION
    state.active_task = {
        "type": "MOVE",
        "target": target,
        "ticks": DEPLOY_TICKS,
        "total": DEPLOY_TICKS,
    }
    return [f"DEPLOYING TO {target}."]
