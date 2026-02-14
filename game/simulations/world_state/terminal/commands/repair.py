"""REPAIR command handler."""

import math

from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.repairs import start_repair
from game.simulations.world_state.core.config import FIELD_ACTION_REPAIRING
from game.simulations.world_state.core.state import GameState


def _fidelity_from_comms(state: GameState) -> str:
    return comms_fidelity(state)


def _repair_status_line(state: GameState, structure_id: str) -> str:
    fidelity = _fidelity_from_comms(state)
    job = state.active_repairs.get(structure_id, {})
    remaining = max(0, int(math.ceil(job.get("remaining", 0))))
    total = int(math.ceil(job.get("total", 0)))
    cost = job.get("cost", 0)
    structure = state.structures.get(structure_id)
    name = structure.name.upper() if structure else "UNKNOWN"
    if fidelity == "FULL":
        return (
            f"[REPAIR] IN PROGRESS: {name} "
            f"({total - remaining}/{total} TICKS, COST: {cost} MATERIALS)"
        )
    if fidelity == "DEGRADED":
        approx = _approximate_ticks(remaining)
        return f"[REPAIR] IN PROGRESS: {approx} (COST: {cost} MATERIALS)"
    if fidelity == "FRAGMENTED":
        return f"[EVENT] MAINTENANCE SIGNALS DETECTED (COST: {cost} MATERIALS)"
    return "REPAIR STATUS: NO SIGNAL."


def _approximate_ticks(remaining: int) -> str:
    if remaining <= 1:
        return "NEAR COMPLETE"
    if remaining <= 3:
        return "MID PROGRESS"
    return "EARLY STAGE"


def _resolve_structure_id(state: GameState, structure_id: str) -> str | None:
    if structure_id in state.structures:
        return structure_id
    normalized = structure_id.strip().upper()
    for candidate in state.structures.values():
        if candidate.id.upper() == normalized:
            return candidate.id
        if candidate.name.upper() == normalized:
            return candidate.id
        if candidate.name.split()[0].upper() == normalized:
            return candidate.id
    return None


def cmd_repair(state: GameState, structure_id: str) -> list[str]:
    """Start a repair task for a structure."""

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    resolved_id = _resolve_structure_id(state, structure_id)
    if resolved_id and resolved_id in state.active_repairs:
        return [_repair_status_line(state, resolved_id)]

    local = state.in_field_mode()
    if local:
        structure = state.structures.get(resolved_id) if resolved_id else None
        if not structure:
            return ["UNKNOWN STRUCTURE."]
        if structure.sector != state.player_location:
            return ["STRUCTURE NOT IN SECTOR."]

    result = start_repair(state, structure_id, local=local)
    if result.startswith("MANUAL REPAIR STARTED:"):
        state.field_action = FIELD_ACTION_REPAIRING
    return [result]
