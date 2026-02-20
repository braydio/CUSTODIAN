import time

from .assaults import advance_assaults, maybe_spawn_assault, resolve_assault
from .events import maybe_trigger_event
from .fabrication import tick_fabrication
from .invariants import validate_state_invariants
from .power_load import compute_power_load
from .power import refresh_comms_fidelity
from .repairs import tick_repairs
from .state import GameState, advance_time, check_failure
from .wear import apply_wear


def step_world(state: GameState, tick_delay: float = 0.0) -> bool:
    """Advance the world simulation by a single tick.

    Args:
        state: Mutable simulation state to advance.
        tick_delay: Delay passed to assault resolution for pacing.

    Returns:
        True when this step transitions into a terminal failure state.
    """

    if state.is_failed:
        state.last_assault_lines = []
        state.last_structure_loss_lines = []
        state.last_repair_lines = []
        state.last_fabrication_lines = []
        state.last_after_action_lines = []
        state.last_fidelity_lines = []
        return False

    state.last_assault_lines = []
    state.last_structure_loss_lines = []
    state.last_after_action_lines = []
    advance_time(state)
    compute_power_load(state)
    maybe_trigger_event(state)

    if state.current_assault is not None:
        resolve_assault(state, tick_delay=tick_delay)
    else:
        advance_assaults(state)
        maybe_spawn_assault(state)

    state.last_repair_lines = tick_repairs(state)
    state.last_fabrication_lines = tick_fabrication(state)
    apply_wear(state)
    refresh_comms_fidelity(state, emit_event=True)
    validate_state_invariants(state)

    return check_failure(state)


def sandbox_world(
    ticks: int = 300,
    tick_delay: float = 0.05,
    seed: int | None = None,
    dev_mode: bool = False,
):
    """Run the autonomous world simulation loop."""
    state = GameState(seed=seed)
    state.dev_mode = dev_mode
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
