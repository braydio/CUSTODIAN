"""SCAVENGE command handler."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands.wait import cmd_wait


SCAVENGE_TICKS = 3
SCAVENGE_MIN_GAIN = 1
SCAVENGE_MAX_GAIN = 3


def cmd_scavenge(state: GameState) -> list[str]:
    """Advance time and gain materials from a scavenge run."""

    if state.is_failed:
        reason = state.failure_reason or "SESSION FAILED."
        return [reason, "SESSION TERMINATED."]

    scavenge_lines: list[str] = []
    last_detail: list[str] | None = None

    for _ in range(SCAVENGE_TICKS):
        before_signature = _state_signature(state)
        tick_lines = cmd_wait(state)
        after_signature = _state_signature(state)

        if state.is_failed:
            reason = state.failure_reason or "SESSION FAILED."
            return [reason, "SESSION TERMINATED."]

        detail = tick_lines[1:] if tick_lines and tick_lines[0] == "TIME ADVANCED." else []
        no_effect = before_signature == after_signature

        if detail:
            if detail == last_detail and no_effect:
                continue
            scavenge_lines.extend(detail)
            last_detail = detail

    gained = state.rng.randint(SCAVENGE_MIN_GAIN, SCAVENGE_MAX_GAIN)
    state.materials += gained

    lines = ["[SCAVENGE] OPERATION COMPLETE."]
    if scavenge_lines:
        lines.extend(scavenge_lines)
    lines.append(f"[RESOURCE GAIN] +{gained} MATERIALS")
    return lines


def _state_signature(state: GameState) -> tuple:
    sector_signature = tuple(
        (
            sector.name,
            round(sector.damage, 3),
            round(sector.alertness, 3),
            round(sector.power, 3),
            sector.occupied,
        )
        for sector in state.sectors.values()
    )
    structure_signature = tuple(
        (structure.id, structure.state.value)
        for structure in state.structures.values()
    )
    return (
        round(state.ambient_threat, 3),
        state.assault_timer,
        state.in_major_assault,
        state.current_assault is not None,
        state.archive_losses,
        sector_signature,
        structure_signature,
    )
