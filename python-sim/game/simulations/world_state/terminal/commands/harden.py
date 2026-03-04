"""HARDEN command handler."""

from game.simulations.world_state.core.state import GameState


def cmd_harden(state: GameState) -> list[str]:
    """Harden systems to compress assault damage."""

    if state.current_assault or state.in_major_assault:
        return ["[HARDEN IGNORED] ASSAULT ACTIVE."]

    state.hardened = True
    state.focused_sector = None
    return ["[HARDENING SYSTEMS]"]
