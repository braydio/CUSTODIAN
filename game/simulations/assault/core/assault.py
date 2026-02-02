from core.autopilot import run_autopilot
from core.morale import should_retreat


def resolve_assault(sectors):
    for tick in range(10):
        print(f"\n--- TICK {tick} ---")

        for sector in sectors:
            print(f"Sector: {sector.name}")
            for e in sector.enemies:
                status = "ALIVE" if e.alive else "DEAD"
                print(f" - {e.name}: HP={e.hp}, Morale={e.morale} [{status}]")

        for sector in sectors:
            run_autopilot(sector)

        for sector in sectors:
            for e in list(sector.enemies):
                if should_retreat(e):
                    print(f"{e.name} flees from {sector.name}")
                    sector.enemies.remove(e)
