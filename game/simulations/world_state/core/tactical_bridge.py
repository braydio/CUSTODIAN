from game.simulations.assault.core.assault import resolve_assault as resolve_tactical
from game.simulations.assault.core.defenses import Turret
from game.simulations.assault.core.enums import SectorType
from game.simulations.assault.core.sectors import Sector
from game.simulations.world_state.core.defense import (
    defense_bias_for_sector,
    doctrine_dps_multiplier,
)
from game.simulations.world_state.core.power import structure_effective_output


def _defense_effective_output(state) -> float:
    if state is None:
        return 1.0
    structure = state.structures.get("DF_CORE")
    if not structure:
        return 1.0
    return structure_effective_output(state, structure)


def build_tactical_sectors(assault, state=None):
    sectors = []
    output = _defense_effective_output(state)
    doctrine = "BALANCED" if state is None else state.defense_doctrine
    for sector_state in assault.target_sectors:
        sector_type = SectorType.PERIPHERAL
        if sector_state.name == "COMMAND":
            sector_type = SectorType.COMMAND
        elif sector_state.name == "ARCHIVE":
            sector_type = SectorType.GOAL
        sector = Sector(sector_state.name, sector_type)
        sector_output = output * doctrine_dps_multiplier(doctrine)
        if state is not None:
            sector_output *= max(
                0.75,
                min(1.25, defense_bias_for_sector(state.defense_allocation, sector_state.name)),
            )
        sector.defenses.append(Turret(damage=5, effective_output=sector_output))
        sectors.append(sector)
    return sectors


def resolve_tactical_assault(assault, on_tick, state=None):
    assault_sectors = build_tactical_sectors(assault, state=state)
    assault.duration_ticks = max(1, assault.duration_ticks)

    return resolve_tactical(
        assault_sectors,
        assault_instance=assault,
        max_ticks=assault.duration_ticks,
        on_tick=on_tick,
    )
