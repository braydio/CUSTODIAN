"""MOVE command handler."""

from game.simulations.world_state.core.config import (
    MOVE_TICKS,
    TRAVEL_GRAPH,
)
from game.simulations.world_state.core.presence import start_move_task
from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.location import resolve_location_token


def cmd_move(state: GameState, destination: str) -> list[str]:
    if not state.in_field_mode():
        return ["COMMAND AUTHORITY REQUIRED."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]
    if state.active_repairs:
        return ["ACTION IN PROGRESS."]

    target = resolve_location_token(destination)
    if not target:
        return ["INVALID ROUTE."]

    here = state.player_location
    valid_targets = TRAVEL_GRAPH.get(here, [])
    if target not in valid_targets:
        return ["INVALID ROUTE."]

    start_move_task(state, target, MOVE_TICKS)
    lines = [f"MOVING TO {target}."]
    if target in {"T_NORTH", "T_SOUTH"}:
        lines.append(_transit_signal_tag(comms_fidelity(state), target))
    return lines


def _transit_signal_tag(fidelity: str, transit: str) -> str:
    lane = "NORTH" if transit == "T_NORTH" else "SOUTH"
    if fidelity == "FULL":
        return f"[TRANSIT] {lane} LANE: POWER HUM"
    if fidelity == "DEGRADED":
        return f"[TRANSIT] {lane} LANE: THERMAL NOISE"
    if fidelity == "FRAGMENTED":
        return f"[TRANSIT] {lane} LANE: SIGNAL IRREGULAR"
    return "[TRANSIT] NO SIGNAL."
