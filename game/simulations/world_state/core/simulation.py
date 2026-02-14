import time

from .assaults import maybe_start_assault_timer, resolve_assault, tick_assault_timer
from .events import maybe_trigger_event
from .invariants import validate_state_invariants
from .power import refresh_comms_fidelity
from .repairs import tick_repairs
from .state import GameState, advance_time, check_failure


def step_world(state: GameState, tick_delay: float = 0.0) -> bool:
    """Advance the world simulation by a single tick.

    Args:
        state: Mutable simulation state to advance.
        tick_delay: Delay passed to assault resolution for pacing.

    Returns:
        True when this step transitions into a terminal failure state.
    """

    if state.is_failed:
        state.last_repair_lines = []
        state.last_fidelity_lines = []
        return False

    advance_time(state)
    maybe_trigger_event(state)

    if state.current_assault is None:
        maybe_start_assault_timer(state)
        tick_assault_timer(state)
    else:
        resolve_assault(state, tick_delay=tick_delay)

    state.last_repair_lines = tick_repairs(state)
    refresh_comms_fidelity(state, emit_event=True)
    validate_state_invariants(state)

    return check_failure(state)


def sandbox_world(ticks=300, tick_delay=0.05):
    """Run the autonomous world simulation loop."""
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
        step_world(state, tick_delay=tick_delay)

        if state.time % 25 == 0:
            print("\n[Snapshot]")
            print(state)
            print()

        time.sleep(tick_delay)

    print("\nSimulation ended.\n")
    print(state)

    return state
