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
    assert result.lines[0] == "TIME ADVANCED."


def test_status_does_not_mutate_state() -> None:
    """STATUS should report state without changing time."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert state.time == 0
    assert result.lines[0] == "TIME: 0"


def test_unknown_command_returns_locked_error_lines() -> None:
    """Unknown commands should return the locked error phrasing."""

    state = GameState()

    result = process_command(state, "nonesuch")

    assert result.ok is False
    assert result.lines == ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]


def test_failure_mode_locks_non_reset_commands() -> None:
    """After failure, non-reset commands should be rejected."""

    state = GameState()
    state.sectors["Command Center"].damage = COMMAND_CENTER_BREACH_DAMAGE

    wait_result = process_command(state, "WAIT")
    status_result = process_command(state, "STATUS")

    assert wait_result.ok is True
    assert wait_result.lines[-2:] == ["COMMAND CENTER BREACHED.", "SESSION TERMINATED."]
    assert status_result.ok is False
    assert status_result.lines == [
        "COMMAND CENTER BREACHED.",
        "REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED.",
    ]


def test_reset_command_restores_session_after_failure() -> None:
    """RESET should clear failure mode and restore baseline state."""

    state = GameState()
    state.sectors["Command Center"].damage = COMMAND_CENTER_BREACH_DAMAGE
    process_command(state, "WAIT")

    result = process_command(state, "RESET")

    assert result.ok is True
    assert result.lines == ["SYSTEM REBOOTED.", "SESSION READY."]
    assert state.is_failed is False
    assert state.failure_reason is None
    assert state.time == 0
