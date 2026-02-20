"""WAIT command handler."""

from contextlib import redirect_stdout
from dataclasses import dataclass
import io
import time

from game.simulations.world_state.core.config import (
    FIELD_ACTION_IDLE,
    FIELD_ACTION_REPAIRING,
    WAIT_UNTIL_MAX_TICKS,
)
from game.simulations.world_state.core.detection import warning_delay_ticks
from game.simulations.world_state.core.presence import tick_presence
from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


WAIT_TICKS_PER_UNIT = 5
WAIT_TICK_DELAY_SECONDS = 0.5


@dataclass
class WaitTickInfo:
    fidelity: str
    fidelity_lines: list[str]
    debug_lines: list[str]
    event_name: str | None
    event_sector: str | None
    repair_names: list[str]
    fabrication_lines: list[str]
    assault_started: bool
    assault_warning: bool
    assault_active: bool
    became_failed: bool
    warning_window: int
    assault_lines: list[str]
    structure_loss_lines: list[str]
    stability_declining: bool


def _failure_lines(state: GameState) -> list[str]:
    reason = state.failure_reason or "SESSION FAILED."
    return [reason, "SESSION TERMINATED."]


def _fidelity_from_comms(state: GameState) -> str:
    return comms_fidelity(state)


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
    before_threat = state.ambient_threat
    before_damage = sum(sector.damage for sector in state.sectors.values())
    was_assault_active = state.in_major_assault or state.current_assault is not None
    previous_timer = state.assault_timer

    captured = io.StringIO()
    with redirect_stdout(captured):
        became_failed = step_world(state)
        tick_presence(state)
        repair_lines = state.last_repair_lines
        fabrication_lines = list(state.last_fabrication_lines)
        fidelity_lines = state.last_fidelity_lines
        if not state.active_repairs and state.field_action == FIELD_ACTION_REPAIRING:
            state.field_action = FIELD_ACTION_IDLE
    debug_lines: list[str] = []
    if state.dev_mode and state.dev_trace:
        for line in captured.getvalue().splitlines():
            cleaned = line.strip()
            if cleaned.startswith("{") and "'tick':" in cleaned:
                debug_lines.append(f"[DEBUG] {cleaned}")

    fidelity = _fidelity_from_comms(state)
    structure_loss_lines = _consume_structure_loss_lines(state, fidelity)
    event_name, event_sector = _latest_event(state, before_time)
    repair_names = [line.replace("REPAIR COMPLETE: ", "") for line in repair_lines]
    assault_lines = list(state.last_assault_lines)

    assault_active = state.in_major_assault or state.current_assault is not None
    assault_started = (not was_assault_active) and assault_active
    if not assault_active:
        state.field_assault_warning_pending = 0

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
    pending_seeded = False
    if assault_started and state.in_field_mode():
        state.field_assault_warning_pending = warning_delay_ticks(state)
        pending_seeded = state.field_assault_warning_pending > 0
        assault_started = False
        assault_warning = False
    if state.field_assault_warning_pending > 0 and not pending_seeded:
        state.field_assault_warning_pending -= 1
        if state.field_assault_warning_pending == 0 and assault_active and not pending_seeded:
            assault_warning = True

    after_threat = state.ambient_threat
    after_damage = sum(sector.damage for sector in state.sectors.values())
    stability_declining = (
        after_threat > before_threat + 0.02
        or after_damage > before_damage + 0.05
    )

    return WaitTickInfo(
        fidelity=fidelity,
        fidelity_lines=fidelity_lines,
        debug_lines=debug_lines,
        event_name=event_name,
        event_sector=event_sector,
        repair_names=repair_names,
        fabrication_lines=fabrication_lines,
        assault_started=assault_started,
        assault_warning=assault_warning,
        assault_active=assault_active,
        became_failed=became_failed,
        warning_window=warning_window,
        assault_lines=assault_lines,
        structure_loss_lines=structure_loss_lines,
        stability_declining=stability_declining,
    )


def _consume_structure_loss_lines(state: GameState, fidelity: str) -> list[str]:
    pending = sorted(
        sid for sid in state.pending_structure_losses if sid not in state.detected_structure_losses
    )
    if not pending:
        return []
    if fidelity == "LOST":
        return []

    surfaced = set(pending)
    lines: list[str] = []
    if fidelity == "FULL":
        lines.extend(f"[EVENT] STRUCTURE LOST: {sid}" for sid in pending)
        lines.extend(state.last_structure_loss_lines)
    elif fidelity == "DEGRADED":
        sectors: list[str] = []
        for sid in pending:
            structure = state.structures.get(sid)
            sector_name = structure.sector if structure else "UNKNOWN"
            if sector_name not in sectors:
                sectors.append(sector_name)
        lines.extend(f"[EVENT] INFRASTRUCTURE LOSS REPORTED: {name}" for name in sectors)
        if state.last_structure_loss_lines:
            lines.append("[WARNING] SYSTEM CAPABILITY REDUCED.")
    else:
        lines.append("[EVENT] STRUCTURAL LOSS SIGNAL DETECTED")
        if state.last_structure_loss_lines:
            lines.append("[WARNING] INTERNAL CONDITIONS DEGRADED.")

    state.detected_structure_losses.update(surfaced)
    state.pending_structure_losses.difference_update(surfaced)
    return lines


def cmd_wait(state: GameState) -> list[str]:
    """Advance the world simulation by one wait unit."""

    return cmd_wait_ticks(state, 1)


def cmd_wait_ticks(state: GameState, ticks: int) -> list[str]:
    """Advance the world simulation by N wait units."""

    if ticks <= 0:
        return ["TIME ADVANCED."]
    if state.is_failed:
        return _failure_lines(state)

    lines = ["TIME ADVANCED."]
    detail_lines: list[str] = []
    last_detail_line = lines[0]
    last_signal_line: str | None = None
    total_ticks = ticks * WAIT_TICKS_PER_UNIT
    if state.current_assault is not None or state.in_major_assault:
        total_ticks = ticks

    for index in range(total_ticks):
        info = _advance_tick(state)
        tick_lines = _detail_lines_for_tick(info, state)
        signal_line = tick_lines[0] if tick_lines else None
        suppress_tick_lines = (
            signal_line is not None
            and signal_line == last_signal_line
            and not info.became_failed
        )
        if not suppress_tick_lines and signal_line is not None:
            last_signal_line = signal_line

        if suppress_tick_lines:
            if index < total_ticks - 1:
                time.sleep(WAIT_TICK_DELAY_SECONDS)
            continue

        for line in tick_lines:
            if line == last_detail_line:
                continue
            detail_lines.append(line)
            last_detail_line = line

        if info.became_failed:
            break

        if index < total_ticks - 1:
            time.sleep(WAIT_TICK_DELAY_SECONDS)

    if detail_lines:
        lines.extend(detail_lines)

    return lines


def cmd_wait_until(state: GameState, condition: str) -> list[str]:
    """Advance until a named condition is met or a safety cap is reached."""

    if state.is_failed:
        return _failure_lines(state)

    token = condition.strip().upper()
    if token not in {"ASSAULT", "APPROACH", "REPAIR_DONE"}:
        return ["WAIT UNTIL REQUIRES: ASSAULT, APPROACH, OR REPAIR_DONE."]

    lines = [f"TIME ADVANCED UNTIL {token}."]
    detail_lines: list[str] = []
    last_detail_line = lines[0]
    last_signal_line: str | None = None
    condition_met = False

    for _ in range(WAIT_UNTIL_MAX_TICKS):
        info = _advance_tick(state)
        tick_lines = _detail_lines_for_tick(info, state)
        signal_line = tick_lines[0] if tick_lines else None
        suppress_tick_lines = (
            signal_line is not None
            and signal_line == last_signal_line
            and not info.became_failed
        )
        if not suppress_tick_lines and signal_line is not None:
            last_signal_line = signal_line

        if not suppress_tick_lines:
            for line in tick_lines:
                if line == last_detail_line:
                    continue
                detail_lines.append(line)
                last_detail_line = line

        if token == "ASSAULT":
            condition_met = info.assault_active or info.assault_started
        elif token == "APPROACH":
            condition_met = bool(state.assaults)
        else:
            condition_met = bool(info.repair_names)

        if info.became_failed or condition_met:
            break

    if detail_lines:
        lines.extend(detail_lines)
    if not condition_met and not state.is_failed:
        lines.append("CONDITION NOT MET BEFORE SAFETY LIMIT.")
    return lines


def _detail_lines_for_tick(info: WaitTickInfo, state: GameState) -> list[str]:
    if info.fidelity == "LOST":
        if info.fidelity_lines:
            lines = list(info.debug_lines) + list(info.fidelity_lines)
            if info.became_failed:
                lines.extend(_failure_lines(state))
            return lines
        if info.became_failed:
            return list(info.debug_lines) + _failure_lines(state)
        return list(info.debug_lines)

    tick_lines: list[str] = list(info.debug_lines)
    if info.fidelity_lines:
        tick_lines.extend(info.fidelity_lines)
    if info.structure_loss_lines:
        tick_lines.extend(info.structure_loss_lines)
    if info.assault_lines:
        tick_lines.extend(info.assault_lines)
    if info.fabrication_lines:
        tick_lines.extend(info.fabrication_lines)

    event_line = None
    if info.event_name and not info.fidelity_lines:
        event_line = _format_event_line(info.event_name, info.fidelity)

    repair_line = None
    if not event_line and info.repair_names:
        repair_line = _format_repair_line(info.repair_names[0], info.fidelity)

    warning_line = None
    if not event_line and not repair_line and info.assault_warning:
        warning_line = _format_warning_line(info.fidelity)

    if event_line:
        tick_lines.append(event_line)
    elif repair_line:
        tick_lines.append(repair_line)
    elif warning_line:
        tick_lines.append(warning_line)

    assault_signal = info.assault_started or info.assault_warning
    if info.fidelity == "FRAGMENTED" and not info.assault_started:
        assault_signal = False

    interpretive_line = None
    if assault_signal:
        interpretive_line = _format_assault_line(info.fidelity)
    elif (
        info.stability_declining
        and (event_line or repair_line or info.fidelity_lines or info.structure_loss_lines)
    ):
        interpretive_line = _format_status_shift(info.fidelity)

    if interpretive_line:
        tick_lines.append(interpretive_line)

    if info.became_failed:
        tick_lines.extend(_failure_lines(state))

    return tick_lines
