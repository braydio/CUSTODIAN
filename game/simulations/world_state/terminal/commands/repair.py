"""REPAIR command handler."""

from game.simulations.world_state.core.repairs import start_repair
from game.simulations.world_state.core.state import GameState


def cmd_repair(state: GameState, structure_id: str) -> list[str]:
    """Start a repair task for a structure."""

    result = start_repair(state, structure_id)
    return [result]
