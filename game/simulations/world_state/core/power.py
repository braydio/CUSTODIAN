"""Power-performance helpers for world-state systems."""

from enum import Enum
from typing import TYPE_CHECKING

from .structures import StructureState

if TYPE_CHECKING:
    from .state import GameState
    from .structures import Structure


DEFAULT_MIN_POWER = 0.4
DEFAULT_STANDARD_POWER = 1.0


class PowerTier(Enum):
    OFFLINE = "OFFLINE"
    DEGRADED = "DEGRADED"
    NORMAL = "NORMAL"


FIDELITY_ORDER = ["LOST", "FRAGMENTED", "DEGRADED", "FULL"]


def _normalize_power_targets(min_power: float, standard_power: float) -> tuple[float, float]:
    min_value = max(0.0, float(min_power))
    standard_value = max(min_value, float(standard_power))
    if standard_value == 0.0:
        standard_value = 1.0
    return min_value, standard_value


def structure_integrity_modifier(state: StructureState) -> float:
    if state == StructureState.OPERATIONAL:
        return 1.0
    if state == StructureState.DAMAGED:
        return 0.75
    return 0.0


def classify_power_tier(
    allocated_power: float,
    *,
    min_power: float = DEFAULT_MIN_POWER,
    standard_power: float = DEFAULT_STANDARD_POWER,
) -> PowerTier:
    min_value, standard_value = _normalize_power_targets(min_power, standard_power)
    if allocated_power < min_value:
        return PowerTier.OFFLINE
    if allocated_power < standard_value:
        return PowerTier.DEGRADED
    return PowerTier.NORMAL


def power_efficiency(
    allocated_power: float,
    *,
    min_power: float = DEFAULT_MIN_POWER,
    standard_power: float = DEFAULT_STANDARD_POWER,
) -> float:
    min_value, standard_value = _normalize_power_targets(min_power, standard_power)
    if allocated_power < min_value:
        return 0.0
    return min(1.0, max(0.0, allocated_power / standard_value))


def structure_effective_output(state: "GameState", structure: "Structure") -> float:
    sector = state.sectors.get(structure.sector)
    allocated = sector.power if sector else 0.0
    efficiency = power_efficiency(
        allocated,
        min_power=structure.min_power,
        standard_power=structure.standard_power,
    )
    integrity = structure_integrity_modifier(structure.state)
    return max(0.0, min(1.0, efficiency * integrity))


def sector_power_modifier(
    sector_power: float,
    *,
    min_power: float = DEFAULT_MIN_POWER,
    standard_power: float = DEFAULT_STANDARD_POWER,
) -> float:
    tier = classify_power_tier(
        sector_power,
        min_power=min_power,
        standard_power=standard_power,
    )
    if tier == PowerTier.OFFLINE:
        return 0.0
    if tier == PowerTier.DEGRADED:
        return 0.5
    return 1.0


def _comms_sensor_fidelity(state: "GameState") -> str:
    comms = state.structures.get("CM_CORE")
    if not comms:
        return "FULL"
    effectiveness = structure_effective_output(state, comms)
    if effectiveness >= 0.9:
        return "FULL"
    if effectiveness >= 0.6:
        return "DEGRADED"
    if effectiveness >= 0.3:
        return "FRAGMENTED"
    return "LOST"


def worst_fidelity(*fidelity_levels: str) -> str:
    ranked = []
    for level in fidelity_levels:
        if level in FIDELITY_ORDER:
            ranked.append(FIDELITY_ORDER.index(level))
    if not ranked:
        return "FULL"
    return FIDELITY_ORDER[min(ranked)]


def comms_fidelity(state: "GameState") -> str:
    return refresh_comms_fidelity(state, emit_event=False)


def refresh_comms_fidelity(state: "GameState", *, emit_event: bool) -> str:
    old = getattr(state, "fidelity", "FULL")
    new = _comms_sensor_fidelity(state)
    state.fidelity = new
    if emit_event:
        state.last_fidelity_lines = []
        if new != old:
            direction = "UPGRADED" if FIDELITY_ORDER.index(new) > FIDELITY_ORDER.index(old) else "DEGRADED"
            state.last_fidelity_lines.append(
                f"[EVENT] INFORMATION FIDELITY {direction} TO {new}"
            )
    return new
