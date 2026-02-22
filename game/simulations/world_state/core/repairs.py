import math

from .config import (
    FULL_RESTORE_MATERIAL_COST,
    SECTOR_ALERTNESS_RECOVERY_DRONE,
    SECTOR_ALERTNESS_RECOVERY_LOCAL,
    SECTOR_ALERTNESS_RECOVERY_REMOTE,
    SECTOR_DAMAGE_RECOVERY_DRONE,
    SECTOR_DAMAGE_RECOVERY_LOCAL,
    SECTOR_DAMAGE_RECOVERY_REMOTE,
    SECTOR_RECOVERY_WINDOW_TICKS,
)
from .policies import REPAIR_MATERIAL_MULT, REPAIR_SPEED
from .power import sector_power_modifier, structure_effective_output
from .structures import StructureState


REMOTE_REPAIR_TICKS = {
    StructureState.DAMAGED: 4,
}

LOCAL_REPAIR_TICKS = {
    StructureState.DAMAGED: 2,
    StructureState.OFFLINE: 4,
    StructureState.DESTROYED: 6,
}

LOCAL_REPAIR_COSTS = {
    StructureState.DAMAGED: 1,
    StructureState.OFFLINE: 2,
    StructureState.DESTROYED: 4,
}

REMOTE_REPAIR_COSTS = {
    StructureState.DAMAGED: 2,
}


ASSAULT_REPAIR_PENALTY = 0.75
BASE_REPAIR_SPEED = 1.0
REPAIR_REGRESSION_PER_ASSAULT = 1.0


def _resolve_structure(state, structure_id: str):
    structure = state.structures.get(structure_id)
    if structure:
        return structure
    normalized = structure_id.strip().upper()
    for candidate in state.structures.values():
        if candidate.id.upper() == normalized:
            return candidate
        if candidate.name.upper() == normalized:
            return candidate
        if candidate.name.split()[0].upper() == normalized:
            return candidate
    return None


def _mechanic_drone_effective_output(state) -> float:
    drones = state.structures.get("FB_TOOLS")
    if not drones:
        return 1.0
    return structure_effective_output(state, drones)


def _repair_speed(state, structure) -> float:
    sector = state.sectors.get(structure.sector)
    if sector is None:
        return 0.0

    speed = BASE_REPAIR_SPEED
    speed *= _mechanic_drone_effective_output(state)
    speed *= REPAIR_SPEED[state.policies.repair_intensity]
    speed *= sector_power_modifier(
        sector.power,
        min_power=structure.min_power,
        standard_power=structure.standard_power,
    )
    if state.in_major_assault:
        speed *= ASSAULT_REPAIR_PENALTY
        if state.repair_drone_stock <= 0:
            speed *= 0.75
        if f"REPAIR:{structure.sector}" in state.assault_tactical_effects:
            speed *= 1.35
    speed *= max(0.25, float(getattr(state, "repair_throughput_mult", 1.0)))
    return speed


def _has_drone_focus(state) -> bool:
    if state.focused_sector != "FB":
        return False
    drones = state.structures.get("FB_TOOLS")
    if not drones:
        return False
    return structure_effective_output(state, drones) > 0.0


def _start_sector_recovery_window(state, sector_name: str, *, local: bool) -> str:
    mode = "REMOTE"
    if local:
        damage_rate = SECTOR_DAMAGE_RECOVERY_LOCAL
        alertness_rate = SECTOR_ALERTNESS_RECOVERY_LOCAL
        mode = "LOCAL"
    elif _has_drone_focus(state):
        damage_rate = SECTOR_DAMAGE_RECOVERY_DRONE
        alertness_rate = SECTOR_ALERTNESS_RECOVERY_DRONE
        mode = "DRONE"
    else:
        damage_rate = SECTOR_DAMAGE_RECOVERY_REMOTE
        alertness_rate = SECTOR_ALERTNESS_RECOVERY_REMOTE

    mode_rank = {"REMOTE": 0, "DRONE": 1, "LOCAL": 2}
    existing = state.sector_recovery_windows.get(sector_name)
    if existing:
        existing["remaining"] = max(existing.get("remaining", 0.0), float(SECTOR_RECOVERY_WINDOW_TICKS))
        existing["damage_rate"] = max(existing.get("damage_rate", 0.0), damage_rate)
        existing["alertness_rate"] = max(existing.get("alertness_rate", 0.0), alertness_rate)
        existing_mode = str(existing.get("mode", "REMOTE")).upper()
        if mode_rank.get(mode, 0) >= mode_rank.get(existing_mode, 0):
            existing["mode"] = mode
        return str(existing.get("mode", mode))

    state.sector_recovery_windows[sector_name] = {
        "remaining": float(SECTOR_RECOVERY_WINDOW_TICKS),
        "damage_rate": float(damage_rate),
        "alertness_rate": float(alertness_rate),
        "mode": mode,
    }
    return mode


def start_repair(state, structure_id: str, *, local: bool = False) -> str:
    if not structure_id:
        return "REPAIR REQUIRES STRUCTURE ID."

    structure = _resolve_structure(state, structure_id)
    if not structure:
        return "UNKNOWN STRUCTURE."

    if state.active_task:
        return "ACTION IN PROGRESS."

    if state.active_repairs:
        return "ACTION IN PROGRESS."

    if structure.id in state.active_repairs:
        return "REPAIR ALREADY IN PROGRESS."

    if structure.state == StructureState.OPERATIONAL:
        return "STRUCTURE DOES NOT REQUIRE REPAIR."

    if state.in_major_assault and structure.state == StructureState.DESTROYED:
        return "RECONSTRUCTION NOT POSSIBLE DURING ASSAULT."

    repair_ticks = LOCAL_REPAIR_TICKS if local else REMOTE_REPAIR_TICKS
    repair_costs = LOCAL_REPAIR_COSTS if local else REMOTE_REPAIR_COSTS

    if structure.state not in repair_ticks:
        if local:
            return "STRUCTURE NOT IN SECTOR."
        return "REMOTE REPAIR NOT POSSIBLE. PHYSICAL INTERVENTION REQUIRED."

    if local and structure.state == StructureState.DESTROYED:
        sector = state.sectors.get(structure.sector)
        if not sector:
            return "REPAIR FAILED: SECTOR POWER UNAVAILABLE."
        if sector_power_modifier(
            sector.power,
            min_power=structure.min_power,
            standard_power=structure.standard_power,
        ) == 0.0:
            return "REPAIR FAILED: MINIMUM SECTOR POWER REQUIRED."
        if _mechanic_drone_effective_output(state) <= 0.0:
            return "REPAIR FAILED: MECHANIC DRONES OFFLINE."

    base_cost = repair_costs.get(structure.state, 0)
    cost = int(math.ceil(base_cost * REPAIR_MATERIAL_MULT[state.policies.repair_intensity]))
    if not local:
        discount = int(state.relay_benefits.get("remote_repair_discount", 0))
        if discount > 0:
            cost = max(1, cost - discount)
    if state.materials < cost:
        return "REPAIR FAILED: INSUFFICIENT MATERIALS."

    state.materials -= cost
    total_ticks = repair_ticks[structure.state]
    state.active_repairs[structure.id] = {
        "remaining": float(total_ticks),
        "total": float(total_ticks),
        "cost": cost,
        "local": local,
    }
    if local:
        return f"MANUAL REPAIR STARTED: {structure.name} (COST: {cost} MATERIALS)"
    return f"REMOTE REPAIR QUEUED: {structure.name} (COST: {cost} MATERIALS)"


def start_full_restore(state, structure_id: str, *, local: bool = False) -> str:
    if not structure_id:
        return "REPAIR REQUIRES STRUCTURE ID."

    structure = _resolve_structure(state, structure_id)
    if not structure:
        return "UNKNOWN STRUCTURE."

    if state.active_task or state.active_repairs:
        return "ACTION IN PROGRESS."

    if structure.state != StructureState.OPERATIONAL:
        return "STRUCTURE NOT YET OPERATIONAL. COMPLETE REPAIRS FIRST."

    sector = state.sectors.get(structure.sector)
    if sector is None:
        return "UNKNOWN SECTOR."

    if sector.damage < 1.0 and sector.alertness < 0.8:
        return "SECTOR ALREADY STABLE."

    if state.materials < FULL_RESTORE_MATERIAL_COST:
        return "FULL RESTORE FAILED: INSUFFICIENT MATERIALS."

    state.materials -= FULL_RESTORE_MATERIAL_COST
    sector.damage = min(sector.damage, 0.79)
    sector.alertness = min(sector.alertness, 0.79)
    mode = _start_sector_recovery_window(state, structure.sector, local=local)
    return (
        f"FULL RESTORE COMPLETE: {structure.sector} "
        f"({mode}, COST: {FULL_RESTORE_MATERIAL_COST} MATERIALS)"
    )


def tick_repairs(state) -> list[str]:
    completed = []
    for sid, job in list(state.active_repairs.items()):
        structure = state.structures.get(sid)
        if not structure:
            completed.append(sid)
            continue
        speed = _repair_speed(state, structure)
        if speed <= 0.0:
            continue
        job["remaining"] -= speed
        if job["remaining"] <= 0:
            completed.append(sid)

    lines = []
    for sid in completed:
        structure = state.structures.get(sid)
        job = state.active_repairs.get(sid, {})
        if not structure:
            del state.active_repairs[sid]
            continue
        if structure.state == StructureState.DESTROYED:
            structure.state = StructureState.OFFLINE
        elif structure.state == StructureState.OFFLINE:
            structure.state = StructureState.DAMAGED
        elif structure.state == StructureState.DAMAGED:
            structure.state = StructureState.OPERATIONAL
        _start_sector_recovery_window(state, structure.sector, local=bool(job.get("local", False)))
        del state.active_repairs[sid]
        lines.append(f"REPAIR COMPLETE: {structure.name}")

    return lines


def regress_repairs_in_sectors(state, sectors: set[str], amount: float = REPAIR_REGRESSION_PER_ASSAULT) -> None:
    if amount <= 0.0:
        return
    for sid, job in state.active_repairs.items():
        structure = state.structures.get(sid)
        if not structure or structure.sector not in sectors:
            continue
        job["remaining"] += amount


def cancel_repair_for_structure(state, structure_id: str) -> int:
    job = state.active_repairs.pop(structure_id, None)
    if not job:
        return 0
    refund = int(math.ceil(job.get("cost", 0) * 0.5))
    state.materials += refund
    return refund
