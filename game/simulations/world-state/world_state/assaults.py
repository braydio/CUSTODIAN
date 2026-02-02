import random
import time

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
    print("\n=== MAJOR ASSAULT BEGINS ===\n")


def resolve_assault(state, tick_delay=0.05):
    duration = random.randint(ASSAULT_DURATION_MIN, ASSAULT_DURATION_MAX)
    targets = state.weakest_sectors(3)

    for _ in range(duration):
        target = random.choice(targets)
        print(f"[Assault] Fighting in {target.name}")
        target.damage += ASSAULT_DAMAGE_PER_TICK
        target.alertness += ASSAULT_ALERTNESS_PER_TICK
        state.ambient_threat += ASSAULT_THREAT_PER_TICK
        time.sleep(tick_delay)

    print("\n=== ASSAULT REPULSED ===\n")
    state.in_major_assault = False
