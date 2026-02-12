"""WAIT command handler."""

from contextlib import redirect_stdout
from dataclasses import dataclass
import io

from game.simulations.world_state.core.config import (
    FIELD_ACTION_IDLE,
    FIELD_ACTION_MOVING,
    FIELD_ACTION_REPAIRING,
    PLAYER_MODE_COMMAND,
)
from game.simulations.world_state.core.repairs import tick_repairs
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


FIDELITY_ORDER = {"FULL": 0, "DEGRADED": 1, "FRAGMENTED": 2, "LOST": 3}


@dataclass
class WaitTickInfo:
    fidelity: str
    event_name: str | None
    event_sector: str | None
    repair_names: list[str]
    assault_started: bool
    assault_warning: bool
    assault_active: bool
    became_failed: bool
    warning_window: int


def _failure_lines(state: GameState) -> list[str]:
    reason = state.failure_reason or "SESSION FAILED."
    return [reason, "SESSION TERMINATED."]


def _fidelity_from_comms(state: GameState) -> str:
    comms = state.sectors.get("COMMS")
    status = comms.status_label() if comms else "STABLE"
    if status == "ALERT":
        return "DEGRADED"
    if status == "DAMAGED":
        return "FRAGMENTED"
    if status == "COMPROMISED":
        return "LOST"
    return "FULL"


def _latest_event(state: GameState, before_time: int) -> tuple[str | None, str | None]:
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

    return latest_name, latest_sector


def _format_event_line(event_name: str, fidelity: str) -> str | None:
    event_text = event_name.upper()
    if fidelity == "FULL":
        return f"[EVENT] {event_text} DETECTED"
    if fidelity == "DEGRADED":
        return f"[EVENT] {event_text} REPORTED"
    if fidelity == "FRAGMENTED":
        return "[EVENT] IRREGULAR SIGNALS DETECTED"
    return None


def _format_repair_line(repair_name: str, fidelity: str) -> str | None:
    if fidelity == "FULL":
        return f"[EVENT] REPAIR COMPLETE: {repair_name.upper()}"
    if fidelity == "DEGRADED":
        return f"[EVENT] REPAIR COMPLETE: {repair_name.upper()}"
    if fidelity == "FRAGMENTED":
        return "[EVENT] MAINTENANCE SIGNALS DETECTED"
    return None


def _format_warning_line(fidelity: str) -> str | None:
    if fidelity == "FULL":
        return "[WARNING] HOSTILE COORDINATION DETECTED"
    if fidelity == "DEGRADED":
        return "[WARNING] HOSTILE ACTIVITY REPORTED"
    if fidelity == "FRAGMENTED":
        return "[WARNING] STRUCTURAL STRESS INDICATED"
    return None


def _format_assault_line(fidelity: str) -> str | None:
    if fidelity == "FULL":
        return "[ASSAULT] THREAT ACTIVITY INCREASING"
    if fidelity == "DEGRADED":
        return "[ASSAULT] THREAT ACTIVITY APPEARS TO BE INCREASING"
    if fidelity == "FRAGMENTED":
        return "[ASSAULT] HOSTILE ACTIVITY POSSIBLE"
    return None


def _format_status_shift(fidelity: str) -> str | None:
    if fidelity == "FULL":
        return "[STATUS SHIFT] SYSTEM STABILITY DECLINING"
    if fidelity == "DEGRADED":
        return "[STATUS SHIFT] SYSTEM STABILITY APPEARS TO BE DECLINING"
    if fidelity == "FRAGMENTED":
        return "[STATUS SHIFT] INTERNAL CONDITIONS MAY BE WORSENING"
    return None


def _advance_tick(state: GameState) -> WaitTickInfo:
    before_time = state.time
    was_assault_active = state.in_major_assault or state.current_assault is not None
    previous_timer = state.assault_timer

    with redirect_stdout(io.StringIO()):
        became_failed = step_world(state)
        _tick_active_task(state)
        repair_lines = tick_repairs(state)
        if not state.active_repairs and state.field_action == FIELD_ACTION_REPAIRING:
            state.field_action = FIELD_ACTION_IDLE

    fidelity = _fidelity_from_comms(state)
    event_name, event_sector = _latest_event(state, before_time)
    repair_names = [line.replace("REPAIR COMPLETE: ", "") for line in repair_lines]

    assault_active = state.in_major_assault or state.current_assault is not None
    assault_started = (not was_assault_active) and assault_active

    warning_window = 6
    if fidelity in {"FRAGMENTED", "LOST"}:
        warning_window = 2

    current_timer = state.assault_timer
    assault_warning = (
        previous_timer is not None
        and current_timer is not None
        and previous_timer > warning_window
        and 0 < current_timer <= warning_window
    )

    return WaitTickInfo(
        fidelity=fidelity,
        event_name=event_name,
        event_sector=event_sector,
        repair_names=repair_names,
        assault_started=assault_started,
        assault_warning=assault_warning,
        assault_active=assault_active,
        became_failed=became_failed,
        warning_window=warning_window,
    )


def _tick_active_task(state: GameState) -> None:
    task = state.active_task
    if not task:
        return

    task["ticks"] -= 1
    if task["ticks"] > 0:
        return

    if task["type"] == "MOVE":
        state.player_location = task["target"]
        if task["target"] == "COMMAND":
            state.player_mode = PLAYER_MODE_COMMAND
    state.active_task = None
    if not state.active_repairs:
        state.field_action = FIELD_ACTION_IDLE
    elif state.field_action == FIELD_ACTION_MOVING:
        state.field_action = FIELD_ACTION_IDLE


def cmd_wait(state: GameState) -> list[str]:
    """Advance the world simulation by exactly one tick."""

    if state.is_failed:
        return _failure_lines(state)

    info = _advance_tick(state)
    lines = ["TIME ADVANCED."]

    if info.fidelity == "LOST":
        if info.became_failed:
            lines.extend(_failure_lines(state))
        return lines

    detail_lines: list[str] = []

    event_line = None
    if info.event_name:
        event_line = _format_event_line(info.event_name, info.fidelity)

    repair_line = None
    if not event_line and info.repair_names:
        repair_line = _format_repair_line(info.repair_names[0], info.fidelity)

    warning_line = None
    if not event_line and not repair_line and info.assault_warning:
        warning_line = _format_warning_line(info.fidelity)

    if event_line:
        detail_lines.append(event_line)
    elif repair_line:
        detail_lines.append(repair_line)
    elif warning_line:
        detail_lines.append(warning_line)

    assault_signal = info.assault_started or info.assault_warning
    if info.fidelity == "FRAGMENTED" and not info.assault_started:
        assault_signal = False

    interpretive_line = None
    if assault_signal:
        interpretive_line = _format_assault_line(info.fidelity)
    elif event_line or repair_line:
        interpretive_line = _format_status_shift(info.fidelity)

    if interpretive_line:
        detail_lines.append(interpretive_line)

    if detail_lines:
        lines.extend(detail_lines)

    if info.became_failed:
        lines.extend(_failure_lines(state))

    return lines


def cmd_wait_ticks(state: GameState, ticks: int) -> list[str]:
    """Advance the world simulation by multiple ticks."""

    if ticks <= 1:
        return cmd_wait(state)

    advanced = 0
    worst_fidelity = "FULL"
    any_event = False
    any_assault_signal = False
    assault_status_changed = False
    start_threat = state.ambient_threat
    previous_assault_state = state.assault_state()

    for _ in range(ticks):
        info = _advance_tick(state)
        advanced += 1

        if FIDELITY_ORDER[info.fidelity] > FIDELITY_ORDER[worst_fidelity]:
            worst_fidelity = info.fidelity

        if info.event_name or info.repair_names:
            any_event = True

        if info.assault_started or info.assault_warning:
            any_assault_signal = True

        current_assault_state = state.assault_state()
        if current_assault_state != previous_assault_state:
            assault_status_changed = True
        previous_assault_state = current_assault_state

        if info.became_failed:
            break

    lines = [f"TIME ADVANCED x{advanced}."]
    if worst_fidelity == "LOST":
        if state.is_failed:
            lines.extend(_failure_lines(state))
        return lines

    lines.append("")
    lines.append("[SUMMARY]")

    threat_delta = state.ambient_threat - start_threat
    threat_escalated = threat_delta >= 0.1

    summary_lines: list[str] = []
    if worst_fidelity == "FULL":
        if threat_escalated:
            summary_lines.append("- THREAT ESCALATED")
        if any_assault_signal:
            summary_lines.append("- HOSTILE COUNT INCREASED")
        if assault_status_changed:
            summary_lines.append("- ASSAULT STATUS CHANGED")
        if any_event and "SYSTEM STABILITY DECLINED" not in summary_lines:
            summary_lines.append("- SYSTEM STABILITY DECLINED")
    elif worst_fidelity == "DEGRADED":
        if any_event or threat_escalated:
            summary_lines.append("- SYSTEM STABILITY DECLINED")
        if any_assault_signal:
            summary_lines.append("- HOSTILE ACTIVITY INCREASED")
        if assault_status_changed:
            summary_lines.append("- ASSAULT STATUS SHIFTED")
    else:
        if any_event or any_assault_signal or threat_escalated:
            summary_lines.append("- CONDITIONS MAY HAVE WORSENED")
        else:
            summary_lines.append("- SIGNALS INCONCLUSIVE")

    if not summary_lines:
        summary_lines.append("- CONDITIONS UNCHANGED")

    lines.extend(summary_lines)

    if state.is_failed:
        lines.extend(_failure_lines(state))

    return lines
