from .structures import StructureState


REPAIR_TICKS = {
    StructureState.DAMAGED: 2,
    StructureState.OFFLINE: 4,
    StructureState.DESTROYED: 6,
}

REPAIR_COSTS = {
    StructureState.DAMAGED: 1,
    StructureState.OFFLINE: 2,
    StructureState.DESTROYED: 4,
}


def start_repair(state, structure_id: str) -> str:
    if not structure_id:
        return "REPAIR REQUIRES STRUCTURE ID."

    structure = state.structures.get(structure_id)
    if not structure:
        normalized = structure_id.strip().upper()
        for candidate in state.structures.values():
            if candidate.id.upper() == normalized:
                structure = candidate
                break
            if candidate.name.upper() == normalized:
                structure = candidate
                break
            if candidate.name.split()[0].upper() == normalized:
                structure = candidate
                break
    if not structure:
        return "UNKNOWN STRUCTURE."

    if structure.id in state.active_repairs:
        return "REPAIR ALREADY IN PROGRESS."

    if structure.state == StructureState.OPERATIONAL:
        return "STRUCTURE DOES NOT REQUIRE REPAIR."

    if state.in_major_assault and structure.state == StructureState.DESTROYED:
        return "RECONSTRUCTION NOT POSSIBLE DURING ASSAULT."

    cost = REPAIR_COSTS.get(structure.state, 0)
    if state.materials < cost:
        return "REPAIR FAILED: INSUFFICIENT MATERIALS."

    state.materials -= cost
    total_ticks = REPAIR_TICKS[structure.state]
    state.active_repairs[structure.id] = {
        "remaining": total_ticks,
        "total": total_ticks,
        "cost": cost,
    }
    return f"REPAIR STARTED: {structure.name} (COST: {cost} MATERIALS)"


def tick_repairs(state) -> list[str]:
    completed = []
    for sid, job in list(state.active_repairs.items()):
        job["remaining"] -= 1
        if job["remaining"] <= 0:
            completed.append(sid)

    lines = []
    for sid in completed:
        structure = state.structures.get(sid)
        if not structure:
            del state.active_repairs[sid]
            continue
        if structure.state == StructureState.DESTROYED:
            structure.state = StructureState.OFFLINE
        elif structure.state == StructureState.OFFLINE:
            structure.state = StructureState.DAMAGED
        elif structure.state == StructureState.DAMAGED:
            structure.state = StructureState.OPERATIONAL
        del state.active_repairs[sid]
        lines.append(f"REPAIR COMPLETE: {structure.name}")

    return lines
