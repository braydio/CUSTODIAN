import time

from .assaults import maybe_start_assault_timer, resolve_assault, tick_assault_timer
from .events import maybe_trigger_event
from .state import GameState, advance_time


def sandbox_world(ticks=300, tick_delay=0.05):
    state = GameState()
    print("World simulation started.\n")
    profile = state.faction_profile
    print(
        "Hostile profile: "
        f"{profile['label']} | Ideology: {profile['ideology']} | "
        f"Tech: {profile['tech_expression']}"
    )
    print(
        "Doctrine: "
        f"{profile['doctrine']} | Aggression: {profile['aggression']} | "
        f"Signature: {profile['signature']}"
    )
    print(f"Primary target: {profile['target_priority']}\n")

    for _ in range(ticks):
        advance_time(state)
        maybe_trigger_event(state)

        if state.current_assault is None:
            maybe_start_assault_timer(state)
            tick_assault_timer(state)
        else:
            resolve_assault(state, tick_delay=tick_delay)

        if state.time % 25 == 0:
            print("\n[Snapshot]")
            print(state)
            print()

        time.sleep(tick_delay)

    print("\nSimulation ended.\n")
    print(state)

    return state
