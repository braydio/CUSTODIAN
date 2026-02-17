"""Policy-driven power load computation."""

from __future__ import annotations

from .policies import (
    DEFENSE_POWER_DRAW,
    REPAIR_POWER_MULT,
    SURVEILLANCE_POWER,
    FORTIFICATION_POWER,
)


def compute_power_load(state) -> float:
    policies = state.policies
    load = 1.0
    load += DEFENSE_POWER_DRAW[policies.defense_readiness]
    load += SURVEILLANCE_POWER[policies.surveillance_coverage]
    load += REPAIR_POWER_MULT[policies.repair_intensity]
    load += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())
    state.power_load = round(load, 3)
    return state.power_load


def brownout_event_weight_multiplier(state) -> int:
    overload = max(0.0, float(getattr(state, "power_load", 1.0)) - 3.5)
    return max(1, 1 + int(overload * 2.0))


def brownout_event_chance_bonus(state) -> float:
    overload = max(0.0, float(getattr(state, "power_load", 1.0)) - 4.0)
    return min(0.12, overload * 0.02)

