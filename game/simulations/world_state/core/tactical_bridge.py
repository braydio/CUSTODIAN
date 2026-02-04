from game.simulations.assault.core.assault import resolve_assault as resolve_tactical
from game.simulations.assault.core.defenses import Turret
from game.simulations.assault.core.enums import SectorType
from game.simulations.assault.core.sectors import Sector

def build_tactical_sectors(assault):
    sectors = []
    for sector_state in assault.target_sectors:
        sector_type = SectorType.PERIPHERAL
        if sector_state.name == "Command Center":
            sector_type = SectorType.COMMAND
        elif sector_state.name == "Goal Sector":
            sector_type = SectorType.GOAL
        sector = Sector(sector_state.name, sector_type)
        sector.defenses.append(Turret(damage=5))
        sectors.append(sector)
    return sectors


def resolve_tactical_assault(assault, on_tick):
    assault_sectors = build_tactical_sectors(assault)
    assault.duration_ticks = max(1, assault.duration_ticks)

    return resolve_tactical(
        assault_sectors,
        assault_instance=assault,
        max_ticks=assault.duration_ticks,
        on_tick=on_tick,
    )
