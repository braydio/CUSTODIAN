"""ALLOCATE DEFENSE command handler."""

from game.simulations.world_state.core.defense import (
    ALLOCATION_KEYS,
    allocation_from_target_percent,
)
from game.simulations.world_state.core.state import GameState


SECTOR_TO_ALLOCATION = {
    "COMMAND": "COMMAND",
    "POWER": "POWER",
    "FABRICATION": "POWER",
    "COMMS": "SENSORS",
    "SENSORS": "SENSORS",
    "PERIMETER": "PERIMETER",
    "DEFENSE": "PERIMETER",
    "DEFENSE GRID": "PERIMETER",
    "HANGAR": "PERIMETER",
    "GATEWAY": "PERIMETER",
    "STORAGE": "PERIMETER",
    "ARCHIVE": "PERIMETER",
}


def _resolve_group(token: str) -> str | None:
    normalized = token.strip().upper()
    if not normalized:
        return None
    if normalized in ALLOCATION_KEYS:
        return normalized
    return SECTOR_TO_ALLOCATION.get(normalized)


def cmd_allocate_defense(state: GameState, group_token: str, percent_token: str) -> list[str]:
    group = _resolve_group(group_token)
    if group is None:
        return ["INVALID ALLOCATION TARGET."]

    try:
        percent = float(percent_token)
    except ValueError:
        return ["INVALID PERCENT VALUE."]

    weights = allocation_from_target_percent(group, percent)
    if weights is None:
        return ["ALLOCATION PERCENT MUST BE > 0 AND < 100."]

    state.defense_allocation = weights
    readiness = state.compute_readiness()
    return [
        f"DEFENSE ALLOCATION UPDATED: {group} {percent:.0f}%",
        f"READINESS: {readiness:.2f}",
    ]

