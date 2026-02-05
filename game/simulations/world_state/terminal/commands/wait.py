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


def cmd_wait(state: GameState) -> list[str]:
    """Advance the world simulation by exactly one tick."""

    before_time = state.time
    was_assault_active = state.in_major_assault or state.current_assault is not None
    previous_timer = state.assault_timer

    with redirect_stdout(io.StringIO()):
        step_world(state)

    lines = ["TIME ADVANCED."]

    event_line = _latest_event_line(state, before_time)
    if event_line is not None:
        lines.append(event_line)

    is_assault_active = state.in_major_assault or state.current_assault is not None
    if not was_assault_active and is_assault_active:
        lines.append("=== MAJOR ASSAULT BEGINS ===")
    elif was_assault_active and not is_assault_active:
        lines.append("=== ASSAULT REPULSED ===")

    current_timer = state.assault_timer
    if (
        previous_timer is not None
        and current_timer is not None
        and previous_timer > 6
        and 0 < current_timer <= 6
    ):
        lines.append("[WARNING] Hostile coordination detected.")

    return lines
