"""CONFIG DOCTRINE command handler."""

from game.simulations.world_state.core.defense import normalize_doctrine
from game.simulations.world_state.core.state import GameState


def cmd_config_doctrine(state: GameState, doctrine_name: str) -> list[str]:
    doctrine = normalize_doctrine(doctrine_name)
    if doctrine is None:
        return ["INVALID DOCTRINE.", "VALID: BALANCED, AGGRESSIVE, COMMAND_FIRST, INFRASTRUCTURE_FIRST, SENSOR_PRIORITY."]

    state.set_defense_doctrine(doctrine)
    readiness = state.compute_readiness()
    return [
        f"DEFENSE DOCTRINE SET: {state.defense_doctrine}",
        f"READINESS: {readiness:.2f}",
    ]

