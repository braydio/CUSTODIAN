"""Infrastructure policy state and policy lookup tables."""

from __future__ import annotations

from dataclasses import dataclass


POLICY_LEVEL_MIN = 0
POLICY_LEVEL_MAX = 4

# Policy lookup tables (index by policy level 0-4).
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]

DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]

DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]

FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0.0, 0.05, 0.1, 0.15, 0.25]

FAB_CATEGORIES = ("DEFENSE", "DRONES", "REPAIRS", "ARCHIVE")


@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2


def default_fabrication_allocation() -> dict[str, int]:
    return {name: 2 for name in FAB_CATEGORIES}


def clamp_policy_level(level: int) -> int:
    return max(POLICY_LEVEL_MIN, min(POLICY_LEVEL_MAX, int(level)))


def parse_policy_level(token: str) -> int | None:
    if not str(token).strip().isdigit():
        return None
    value = int(token)
    if value < POLICY_LEVEL_MIN or value > POLICY_LEVEL_MAX:
        return None
    return value


def render_slider(level: int) -> str:
    """Render a compact textual bar from a 0-4 level."""

    value = clamp_policy_level(level)
    filled = "#" * value
    empty = "." * (POLICY_LEVEL_MAX + 1 - value)
    return f"{filled}{empty} ({value}/{POLICY_LEVEL_MAX})"

