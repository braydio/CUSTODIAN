"""Policy-driven passive wear between assaults."""

from __future__ import annotations

from .policies import FORTIFICATION_MULT, WEAR_RATE


def apply_wear(state) -> None:
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector_name, sector in state.sectors.items():
        fort_level = int(state.sector_fort_levels.get(sector_name, 0))
        fort_mult = FORTIFICATION_MULT[fort_level]
        mitigation = 1.0 / max(1.0, fort_mult)
        sector.damage += 0.0025 * wear_factor * mitigation

