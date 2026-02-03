from .autopilot import run_autopilot
from .morale import should_retreat


def resolve_assault(sectors, assault_instance=None, max_ticks=10, on_tick=None):
    duration = max_ticks
    if assault_instance is not None:
        duration = getattr(assault_instance, "duration_ticks", max_ticks)

    summary = {
        "duration": duration,
        "spawned": 0,
        "killed": 0,
        "retreated": 0,
        "remaining": 0,
    }

    sector_lookup = {sector.name: sector for sector in sectors}

    for tick in range(duration):
        print(f"\n--- TICK {tick} ---")

        if assault_instance is not None:
            spawned = assault_instance.spawn_at_tick(tick, sector_lookup)
            summary["spawned"] += spawned

        for sector in sectors:
            print(f"Sector: {sector.name}")
            for e in sector.enemies:
                status = "ALIVE" if e.alive else "DEAD"
                print(f" - {e.name}: HP={e.hp}, Morale={e.morale} [{status}]")

        for sector in sectors:
            run_autopilot(sector)

        for sector in sectors:
            for e in list(sector.enemies):
                if not e.alive:
                    summary["killed"] += 1
                    sector.enemies.remove(e)
                    continue
                if should_retreat(e):
                    summary["retreated"] += 1
                    print(f"{e.name} flees from {sector.name}")
                    sector.enemies.remove(e)

        if on_tick is not None:
            on_tick(sectors, tick)

    summary["remaining"] = sum(len(sector.enemies) for sector in sectors)
    return summary
