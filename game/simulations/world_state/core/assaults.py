import random
import time

from .assault_instance import AssaultInstance
from .tactical_bridge import resolve_tactical_assault
from ..assault_outcome import AssaultOutcome

from .config import (
    ASSAULT_ALERTNESS_PER_TICK,
    ASSAULT_DAMAGE_PER_TICK,
    ASSAULT_DURATION_MAX,
    ASSAULT_DURATION_MIN,
    ASSAULT_THREAT_PER_TICK,
    ASSAULT_TIMER_BASE_MAX,
    ASSAULT_TIMER_BASE_MIN,
    ASSAULT_TIMER_MIN,
    ASSAULT_TIMER_WEAK_DAMAGE_MULT,
)

def maybe_start_assault_timer(state):
    if state.assault_timer is None and not state.in_major_assault:
        base = random.randint(ASSAULT_TIMER_BASE_MIN, ASSAULT_TIMER_BASE_MAX)
        weak = sum(sector.damage for sector in state.weakest_sectors())
        state.assault_timer = max(
            ASSAULT_TIMER_MIN, int(base - weak * ASSAULT_TIMER_WEAK_DAMAGE_MULT)
        )


def tick_assault_timer(state):
    if state.assault_timer is None:
        return
    state.assault_timer -= 1
    if 0 < state.assault_timer <= 6:
        print("[Warning] Hostile coordination detected.")
    if state.assault_timer <= 0:
        start_assault(state)


def start_assault(state):
    state.in_major_assault = True
    state.assault_timer = None
    state.assault_count += 1

    targets = state.weakest_sectors(3)

    assault = AssaultInstance(
        faction_profile=state.faction_profile,
        target_sectors=targets,
        threat_budget=100,  # fixed for now, matches your tutorial spec
        start_time=state.time,
    )

    state.current_assault = assault

    print("\n=== MAJOR ASSAULT BEGINS ===")
    print(assault)
    print()


def resolve_assault(state, tick_delay=0.05):
    assault = state.current_assault
    duration = random.randint(ASSAULT_DURATION_MIN, ASSAULT_DURATION_MAX)
    assault.duration_ticks = duration

    def on_tick(sectors, tick):
        assault.tick()
        for sector in sectors:
            if not sector.has_hostiles():
                continue
            world_sector = next(
                (s for s in assault.target_sectors if s.name == sector.name), None
            )
            if world_sector is None:
                continue
            print(f"[Assault] Fighting in {world_sector.name}")
            world_sector.damage += ASSAULT_DAMAGE_PER_TICK
            world_sector.alertness += ASSAULT_ALERTNESS_PER_TICK
            state.ambient_threat += ASSAULT_THREAT_PER_TICK

        time.sleep(tick_delay)

    summary = resolve_tactical_assault(assault, on_tick)

    assault.resolved = True
    state.current_assault = None
    state.in_major_assault = False

    outcome = AssaultOutcome(
        threat_budget=assault.threat_budget,
        duration=summary["duration"],
        spawned=summary["spawned"],
        killed=summary["killed"],
        retreated=summary["retreated"],
        remaining=summary["remaining"],
    )

    # Post-assault consequences (semantic, not tick-based)
    for sector in assault.target_sectors:
        if outcome.penetration == "none":
            sector.alertness *= 0.85
        elif outcome.penetration == "partial":
            sector.damage += 0.3
            sector.alertness += 0.5
        elif outcome.penetration == "severe":
            sector.damage += 0.8
            sector.alertness += 1.2

    if outcome.intensity == "high":
        state.ambient_threat += 0.5
    elif outcome.intensity == "medium":
        state.ambient_threat += 0.2

    print(outcome)
    print("\n=== ASSAULT REPULSED ===\n")
    return outcome
