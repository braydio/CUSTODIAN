"""RESET command handler."""

from game.simulations.world_state.core.state import GameState, reset_game_state


def cmd_reset(state: GameState) -> list[str]:
    """Reset the in-memory game state and confirm readiness."""

    reset_game_state(state)
    return ["SYSTEM REBOOTED.", "SESSION READY."]
