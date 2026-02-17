"""Defense doctrine, allocation, and readiness helpers."""

from __future__ import annotations

from game.simulations.assault.core.enums import DefenseDoctrine
from .policies import DEFENSE_MULT


ALLOCATION_KEYS = ("PERIMETER", "POWER", "SENSORS", "COMMAND")
DEFAULT_DEFENSE_ALLOCATION = {key: 1.0 for key in ALLOCATION_KEYS}
SECTOR_ALLOCATION_GROUP = {
    "COMMAND": "COMMAND",
    "POWER": "POWER",
    "FABRICATION": "POWER",
    "COMMS": "SENSORS",
}


def normalize_doctrine(value: str) -> str | None:
    token = value.strip().upper()
    if not token:
        return None
    if token in DefenseDoctrine.__members__:
        return token
    return None


def doctrine_dps_multiplier(doctrine: str) -> float:
    if doctrine == DefenseDoctrine.AGGRESSIVE.name:
        return 1.2
    if doctrine == DefenseDoctrine.SENSOR_PRIORITY.name:
        return 0.9
    return 1.0


def doctrine_threat_multiplier(doctrine: str) -> float:
    if doctrine == DefenseDoctrine.AGGRESSIVE.name:
        return 1.05
    if doctrine == DefenseDoctrine.COMMAND_FIRST.name:
        return 0.98
    if doctrine == DefenseDoctrine.SENSOR_PRIORITY.name:
        return 0.95
    return 1.0


def doctrine_sector_priority_multiplier(doctrine: str, sector_name: str) -> float:
    if doctrine == DefenseDoctrine.COMMAND_FIRST.name:
        return 1.5 if sector_name == "COMMAND" else 0.8
    if doctrine == DefenseDoctrine.INFRASTRUCTURE_FIRST.name:
        if sector_name in {"POWER", "COMMS", "FABRICATION"}:
            return 1.35
        if sector_name in {"GATEWAY", "HANGAR", "DEFENSE GRID"}:
            return 0.85
    if doctrine == DefenseDoctrine.SENSOR_PRIORITY.name:
        if sector_name == "COMMS":
            return 1.45
    return 1.0


def allocation_group_for_sector(sector_name: str) -> str:
    return SECTOR_ALLOCATION_GROUP.get(sector_name, "PERIMETER")


def defense_bias_for_sector(allocation: dict[str, float], sector_name: str) -> float:
    group = allocation_group_for_sector(sector_name)
    return max(0.1, float(allocation.get(group, 1.0)))


def normalize_allocation_weights(raw: dict[str, float]) -> dict[str, float]:
    values = {}
    for key in ALLOCATION_KEYS:
        values[key] = max(0.1, float(raw.get(key, 1.0)))
    mean = sum(values.values()) / len(ALLOCATION_KEYS)
    if mean <= 0.0:
        return dict(DEFAULT_DEFENSE_ALLOCATION)
    return {key: round(value / mean, 4) for key, value in values.items()}


def allocation_from_target_percent(group: str, percent: float) -> dict[str, float] | None:
    key = group.strip().upper()
    if key not in ALLOCATION_KEYS:
        return None
    if percent <= 0.0 or percent >= 100.0:
        return None

    share = percent / 100.0
    remaining = (1.0 - share) / (len(ALLOCATION_KEYS) - 1)
    shares = {name: remaining for name in ALLOCATION_KEYS}
    shares[key] = share
    weights = {name: shares[name] * len(ALLOCATION_KEYS) for name in ALLOCATION_KEYS}
    return normalize_allocation_weights(weights)


def compute_readiness(state) -> float:
    sector_health = []
    for sector in state.sectors.values():
        health = 1.0 - max(0.0, min(2.0, float(sector.damage))) / 2.0
        sector_health.append(health)
    integrity_score = sum(sector_health) / len(sector_health) if sector_health else 0.0

    structure_count = max(1, len(state.structures))
    repair_completion_factor = 1.0 - (len(state.active_repairs) / structure_count)
    repair_completion_factor = max(0.0, min(1.0, repair_completion_factor))

    powers = [max(0.0, float(sector.power)) for sector in state.sectors.values()]
    mean_power = sum(powers) / len(powers) if powers else 0.0
    imbalance = 0.0
    if powers:
        imbalance = sum(abs(value - mean_power) for value in powers) / len(powers)
    power_stability_factor = max(0.0, min(1.0, 1.0 - imbalance))

    changed_tick = getattr(state, "doctrine_last_changed_time", 0)
    doctrine_stability_factor = 1.0 if (state.time - changed_tick) >= 3 else 0.9

    readiness = (
        integrity_score
        * repair_completion_factor
        * power_stability_factor
        * doctrine_stability_factor
    )
    readiness *= DEFENSE_MULT[state.policies.defense_readiness]
    readiness = max(0.0, min(1.0, readiness))
    state.readiness_cache = {"time": state.time, "value": readiness}
    return readiness
