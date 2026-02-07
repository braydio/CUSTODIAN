"""Tests for terminal command processing behavior."""

from game.simulations.world_state.core.config import COMMAND_CENTER_BREACH_DAMAGE
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_wait_advances_exactly_one_tick() -> None:
    """WAIT should increment time by one and report advancement."""

    state = GameState()

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert state.time == 1
    assert result.text == "TIME ADVANCED."


def test_status_does_not_mutate_state() -> None:
    """STATUS should report state without changing time."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert state.time == 0
    assert result.text == "TIME: 0"


def test_unknown_command_returns_locked_error_lines() -> None:
    """Unknown commands should return the locked error phrasing."""

    state = GameState()

    result = process_command(state, "nonesuch")

    assert result.ok is False
    assert result.text == "UNKNOWN COMMAND."
    assert result.lines == ["TYPE HELP FOR AVAILABLE COMMANDS."]


def test_failure_mode_locks_non_reset_commands() -> None:
    """After failure, non-reset commands should be rejected."""

    state = GameState()
    state.sectors["Command Center"].damage = COMMAND_CENTER_BREACH_DAMAGE

    wait_result = process_command(state, "WAIT")
    status_result = process_command(state, "STATUS")

    assert wait_result.ok is True
    assert wait_result.lines[-2:] == ["COMMAND CENTER BREACHED.", "SESSION TERMINATED."]
    assert status_result.ok is False
    assert status_result.text == "COMMAND CENTER BREACHED."
    assert status_result.lines == ["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]


def test_reset_command_restores_session_after_failure() -> None:
    """RESET should clear failure mode and restore baseline state."""

    state = GameState()
    state.sectors["Command Center"].damage = COMMAND_CENTER_BREACH_DAMAGE
    process_command(state, "WAIT")

    result = process_command(state, "RESET")

    assert result.ok is True
    assert result.text == "SYSTEM REBOOTED."
    assert result.lines == ["SESSION READY."]
    assert state.is_failed is False
    assert state.failure_reason is None
    assert state.time == 0


def test_wait_quiet_tick_emits_pressure_line(monkeypatch) -> None:
    """WAIT should emit a concise pressure line when no event or assault transition occurs."""

    state = GameState()

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
    assert result.lines is not None
    assert len(result.lines) == 1
    assert result.lines[0] == "[PRESSURE] ASSAULT BUILDING."
    assert len(result.lines[0]) <= 40


def test_wait_quiet_tick_pressure_line_has_no_empty_entries(monkeypatch) -> None:
    """WAIT quiet-tick fallback detail should be non-empty and terse."""

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

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines == ["[PRESSURE] PERIMETER STABLE."]
    assert all(line.strip() for line in result.lines)
