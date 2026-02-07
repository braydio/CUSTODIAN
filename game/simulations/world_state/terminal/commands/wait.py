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

    threat_line = "THREAT STABLE"
    if state.ambient_threat >= 3.5:
        threat_line = "THREAT ELEVATED"
    elif state.ambient_threat >= 1.5:
        threat_line = "THREAT RISING"

    if state.assault_timer is not None:
        if state.assault_timer <= 6:
            return f"[PRESSURE] ASSAULT IMMINENT; {threat_line}."
        if state.assault_timer <= 18:
            return f"[PRESSURE] ASSAULT BUILDING; {threat_line}."
        return f"[PRESSURE] ASSAULT TRACKED; {threat_line}."

    return f"[PRESSURE] {threat_line}."


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
        if state.last_assault_lines:
            lines.extend(state.last_assault_lines)
            state.last_assault_lines = []
        had_assault_transition = True

    if became_failed:
        lines.extend(_failure_lines(state))
        return lines

    if not has_event_update and not had_assault_transition:
        lines.append(_quiet_tick_line(state))

    current_timer = state.assault_timer
    warning_window = 6
    comms = state.sectors.get("COMMS")
    if comms and comms.damage >= 1.0:
        warning_window = 2
    if (
        previous_timer is not None
        and current_timer is not None
        and previous_timer > warning_window
        and 0 < current_timer <= warning_window
    ):
        lines.append("[WARNING] Hostile coordination detected.")

    return lines


def cmd_wait_ticks(state: GameState, ticks: int) -> list[str]:
    """Advance the world simulation by multiple ticks."""

    if ticks <= 1:
        return cmd_wait(state)

    advanced = 0
    notable_lines: list[str] = []
    last_pressure: str | None = None

    for _ in range(ticks):
        tick_lines = cmd_wait(state)
        advanced += 1

        if not tick_lines:
            if state.is_failed:
                break
            continue

        payload = tick_lines[1:] if tick_lines[0] == "TIME ADVANCED." else tick_lines

        if state.is_failed:
            notable_lines.extend(payload)
            break

        for line in payload:
            if line.startswith("[PRESSURE]"):
                last_pressure = line
            else:
                notable_lines.append(line)

        if state.is_failed:
            break

    lines = [f"TIME ADVANCED x{advanced}."]
    if notable_lines:
        lines.extend(notable_lines)
    elif last_pressure:
        lines.append(last_pressure)

    return lines
