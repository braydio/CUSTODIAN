"""REPAIR command handler."""

from game.simulations.world_state.core.repairs import start_repair
from game.simulations.world_state.core.state import GameState


def _fidelity_from_comms(state: GameState) -> str:
    comms = state.sectors.get("COMMS")
    status = comms.status_label() if comms else "STABLE"
    if status == "ALERT":
        return "DEGRADED"
    if status == "DAMAGED":
        return "FRAGMENTED"
    if status == "COMPROMISED":
        return "LOST"
    return "FULL"


def _repair_status_line(state: GameState, structure_id: str) -> str:
    fidelity = _fidelity_from_comms(state)
    job = state.active_repairs.get(structure_id, {})
    remaining = job.get("remaining", 0)
    total = job.get("total", 0)
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

    resolved_id = _resolve_structure_id(state, structure_id)
    if resolved_id and resolved_id in state.active_repairs:
        return [_repair_status_line(state, resolved_id)]

    result = start_repair(state, structure_id)
    return [result]
