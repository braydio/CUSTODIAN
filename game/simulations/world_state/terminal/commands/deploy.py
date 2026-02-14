"""DEPLOY command handler."""

from game.simulations.world_state.core.config import (
    COMMAND_CENTER_LOCATION,
    DEPLOY_TICKS,
    FIELD_ACTION_MOVING,
    PLAYER_MODE_FIELD,
    TRAVEL_GRAPH,
    TRANSIT_NODES,
)
from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.location import resolve_location_token


def _shortest_path(start: str, goal: str) -> list[str] | None:
    if start == goal:
        return [start]
    frontier: list[tuple[str, list[str]]] = [(start, [start])]
    visited = {start}
    while frontier:
        node, path = frontier.pop(0)
        for neighbor in TRAVEL_GRAPH.get(node, []):
            if neighbor in visited:
                continue
            next_path = path + [neighbor]
            if neighbor == goal:
                return next_path
            visited.add(neighbor)
            frontier.append((neighbor, next_path))
    return None


def _start_deploy_task(state: GameState, target: str) -> list[str]:
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


def cmd_deploy(state: GameState, destination: str) -> list[str]:
    if state.player_mode != "COMMAND":
        return ["ALREADY DEPLOYED."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    fidelity = comms_fidelity(state)
    if not destination or not destination.strip():
        if fidelity in {"FULL", "DEGRADED"}:
            return [
                "DEPLOY REQUIRES TARGET ARGUMENT.",
                "USAGE: DEPLOY <NORTH|SOUTH|SECTOR>.",
                "CONTEXT: FROM COMMAND, PRIMARY TRANSIT NODES ARE NORTH AND SOUTH.",
            ]
        if fidelity == "FRAGMENTED":
            return ["DEPLOY REQUIRES TRANSIT TARGET."]
        return ["NO SIGNAL."]

    target = resolve_location_token(destination)
    if fidelity == "FULL" and target and target not in TRANSIT_NODES:
        path = _shortest_path(COMMAND_CENTER_LOCATION, target)
        if path and len(path) >= 2:
            return _start_deploy_task(state, path[1])

    if target not in TRANSIT_NODES:
        if fidelity == "DEGRADED":
            return [
                "INVALID DEPLOYMENT TARGET.",
                "REQUIRES: DEPLOY NORTH OR DEPLOY SOUTH.",
                f"CONTEXT: RECEIVED TARGET={destination.strip().upper()}.",
            ]
        if fidelity == "LOST":
            return ["NO SIGNAL."]
        return ["INVALID DEPLOYMENT TARGET."]

    return _start_deploy_task(state, target)
