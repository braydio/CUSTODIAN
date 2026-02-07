"""WAIT command handler."""

from contextlib import redirect_stdout
import io

from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


def _latest_event_line(state: GameState, before_time: int) -> str | None:
    """Build an event line when any sector received a new event this tick."""

    latest_name = None
    latest_sector = None
    latest_time = before_time

    for sector in state.sectors.values():
        event_name = sector.last_event
        if not event_name:
            continue
        event_time = state.event_cooldowns.get((event_name, sector.name), -1)
        if event_time > latest_time:
            latest_time = event_time
            latest_name = event_name
            latest_sector = sector.name

    if latest_name is None or latest_sector is None:
        return None

    return f"[EVENT] {latest_name} in {latest_sector}."


def _failure_lines(state: GameState) -> list[str]:
    """Build terminal final lines for failure mode."""

    reason = state.failure_reason or "SESSION FAILED."
    return [reason, "SESSION TERMINATED."]


def _quiet_tick_line(state: GameState) -> str:
    """Build a concise pressure line for ticks without major transitions."""

    if state.in_major_assault or state.current_assault is not None:
        return "[PRESSURE] ASSAULT ACTIVE."

    if state.assault_timer is not None:
        if state.assault_timer <= 6:
            return "[PRESSURE] ASSAULT IMMINENT."
        if state.assault_timer <= 18:
            return "[PRESSURE] ASSAULT BUILDING."
        return "[PRESSURE] ASSAULT TRACKED."

    if state.ambient_threat >= 3.5:
        return "[PRESSURE] THREAT ELEVATED."
    if state.ambient_threat >= 1.5:
        return "[PRESSURE] THREAT RISING."
    return "[PRESSURE] PERIMETER STABLE."


def cmd_wait(state: GameState) -> list[str]:
    """Advance the world simulation by exactly one tick."""

    if state.is_failed:
        return _failure_lines(state)

    before_time = state.time
    was_assault_active = state.in_major_assault or state.current_assault is not None
    previous_timer = state.assault_timer

    with redirect_stdout(io.StringIO()):
        became_failed = step_world(state)

    lines = ["TIME ADVANCED."]

    event_line = _latest_event_line(state, before_time)
    has_event_update = event_line is not None
    if event_line is not None:
        lines.append(event_line)

    is_assault_active = state.in_major_assault or state.current_assault is not None
    had_assault_transition = False
    if not was_assault_active and is_assault_active:
        lines.append("=== MAJOR ASSAULT BEGINS ===")
        had_assault_transition = True
    elif was_assault_active and not is_assault_active:
        lines.append("=== ASSAULT REPULSED ===")
        had_assault_transition = True

    if became_failed:
        lines.extend(_failure_lines(state))
        return lines

    if not has_event_update and not had_assault_transition:
        lines.append(_quiet_tick_line(state))

    current_timer = state.assault_timer
    if (
        previous_timer is not None
        and current_timer is not None
        and previous_timer > 6
        and 0 < current_timer <= 6
    ):
        lines.append("[WARNING] Hostile coordination detected.")

    return lines
