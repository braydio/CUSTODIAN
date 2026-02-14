"""Tests for terminal command processing behavior."""

from game.simulations.world_state.core.config import (
    ARCHIVE_LOSS_LIMIT,
    COMMAND_CENTER_BREACH_DAMAGE,
)
from game.simulations.world_state.core.state import GameState, check_failure
from game.simulations.world_state.core.structures import StructureState
from game.simulations.world_state.terminal.commands.wait import WaitTickInfo
from game.simulations.world_state.terminal.processor import process_command


def _disable_wait_tick_pause(monkeypatch) -> None:
    monkeypatch.setattr("game.simulations.world_state.terminal.commands.wait.time.sleep", lambda *_: None)


def test_wait_advances_five_ticks(monkeypatch) -> None:
    """WAIT should advance one wait unit (5 ticks) and report advancement."""

    _disable_wait_tick_pause(monkeypatch)

    state = GameState()

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert state.time == 5
    assert result.text == "TIME ADVANCED."


def test_wait_nx_advances_units_of_five_ticks(monkeypatch) -> None:
    """WAIT NX should advance time by N wait units (5 ticks each)."""

    _disable_wait_tick_pause(monkeypatch)

    state = GameState()

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 0.4
        local_state.assault_timer = None
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT 5X")

    assert result.ok is True
    assert state.time == 25
    assert result.text == "TIME ADVANCED."
    assert result.lines is None


def test_wait_suppresses_repeated_event_blocks(monkeypatch) -> None:
    """Repeated tick signals should not be emitted back-to-back."""

    _disable_wait_tick_pause(monkeypatch)
    state = GameState()

    def _repeat_event(_state: GameState) -> WaitTickInfo:
        _state.time += 1
        return WaitTickInfo(
            fidelity="FULL",
            fidelity_lines=[],
            event_name="Comms Burst",
            event_sector="COMMS",
            repair_names=[],
            assault_started=False,
            assault_warning=False,
            assault_active=False,
            became_failed=False,
            warning_window=6,
        )

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait._advance_tick",
        _repeat_event,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines == [
        "[EVENT] COMMS BURST DETECTED",
        "[STATUS SHIFT] SYSTEM STABILITY DECLINING",
    ]


def test_status_does_not_mutate_state() -> None:
    """STATUS should report state without changing time."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert state.time == 0
    assert result.text == "TIME: 0"


def test_focus_sets_sector_without_advancing_time() -> None:
    """FOCUS should set a focused sector and not advance time."""

    state = GameState()

    result = process_command(state, "FOCUS POWER")

    assert result.ok is True
    assert result.text == "[FOCUS SET] POWER"
    assert state.time == 0
    assert state.focused_sector == "PW"
    assert state.hardened is False


def test_harden_sets_posture_without_advancing_time() -> None:
    """HARDEN should set hardened posture and clear focus."""

    state = GameState()
    process_command(state, "FOCUS POWER")

    result = process_command(state, "HARDEN")

    assert result.ok is True
    assert result.text == "[HARDENING SYSTEMS]"
    assert state.time == 0
    assert state.hardened is True
    assert state.focused_sector is None


def test_unknown_command_returns_locked_error_lines() -> None:
    """Unknown commands should return the locked error phrasing."""

    state = GameState()

    result = process_command(state, "nonesuch")

    assert result.ok is False
    assert result.text == "UNKNOWN COMMAND."
    assert result.lines == ["TYPE HELP FOR AVAILABLE COMMANDS."]


def test_failure_mode_locks_non_reset_commands(monkeypatch) -> None:
    """After failure, non-reset commands should be rejected."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    _disable_wait_tick_pause(monkeypatch)

    wait_result = process_command(state, "WAIT")
    status_result = process_command(state, "STATUS")

    assert wait_result.ok is True
    assert wait_result.lines[-2:] == ["COMMAND CENTER LOST", "SESSION TERMINATED."]
    assert status_result.ok is False
    assert status_result.text == "COMMAND CENTER LOST"
    assert status_result.lines == ["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]


def test_reset_command_restores_session_after_failure(monkeypatch) -> None:
    """RESET should clear failure mode and restore baseline state."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    _disable_wait_tick_pause(monkeypatch)
    process_command(state, "WAIT")

    result = process_command(state, "RESET")

    assert result.ok is True
    assert result.text == "SYSTEM REBOOTED."
    assert result.lines == ["SESSION READY."]
    assert state.is_failed is False
    assert state.failure_reason is None
    assert state.time == 0


def test_wait_quiet_tick_emits_pressure_line(monkeypatch) -> None:
    """WAIT should emit only the primary line when no event or signal occurs."""

    state = GameState()
    _disable_wait_tick_pause(monkeypatch)

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 1.8
        local_state.assault_timer = 17
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines is None


def test_wait_quiet_tick_pressure_line_has_no_empty_entries(monkeypatch) -> None:
    """WAIT quiet-tick fallback should emit only the primary line."""

    state = GameState()
    _disable_wait_tick_pause(monkeypatch)

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 0.4
        local_state.assault_timer = None
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is None


def test_archive_loss_triggers_failure(monkeypatch) -> None:
    """Archive loss threshold should trigger failure on the next tick."""

    state = GameState()
    state.archive_losses = ARCHIVE_LOSS_LIMIT
    _disable_wait_tick_pause(monkeypatch)

    def _failure_step(local_state: GameState) -> bool:
        local_state.time += 1
        return check_failure(local_state)

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _failure_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines == ["ARCHIVAL INTEGRITY LOST", "SESSION TERMINATED."]


def test_deploy_transitions_to_field_mode() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY NORTH")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_NORTH."
    assert state.player_mode == "FIELD"


def test_deploy_autoroutes_sector_when_fidelity_full() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_NORTH."
    assert state.player_mode == "FIELD"


def test_deploy_autoroutes_gateway_to_south_transit() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY GATEWAY")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_SOUTH."
    assert state.player_mode == "FIELD"


def test_deploy_degraded_returns_args_and_context() -> None:
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "INVALID DEPLOYMENT TARGET."
    assert result.lines == [
        "TRANSIT LOCK: USE DEPLOY NORTH OR DEPLOY SOUTH.",
        "UNRESOLVED ROUTE TOKEN: ARCHIVE.",
    ]


def test_wait_emits_fidelity_upgrade_event(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    state.sectors["COMMS"].power = 0.6
    state.fidelity = "DEGRADED"
    state.structures["CM_CORE"].state = StructureState.OPERATIONAL
    state.sectors["COMMS"].power = 1.0

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines is not None
    assert "[EVENT] SIGNAL CLARITY RESTORED" in result.lines


def test_deploy_fragmented_keeps_terse_invalid_target() -> None:
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    state.sectors["COMMS"].power = 0.5

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "INVALID DEPLOYMENT TARGET."


def test_move_from_transit_to_comms_is_valid() -> None:
    state = GameState()
    process_command(state, "DEPLOY NORTH")
    process_command(state, "WAIT 2X")

    result = process_command(state, "MOVE COMMS")

    assert result.ok is True
    assert result.text == "MOVING TO COMMS."


def test_focus_denied_in_field_mode() -> None:
    state = GameState()
    process_command(state, "DEPLOY NORTH")

    result = process_command(state, "FOCUS POWER")

    assert result.ok is False
    assert result.text == "COMMAND AUTHORITY REQUIRED."
