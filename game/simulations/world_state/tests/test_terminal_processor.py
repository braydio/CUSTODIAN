"""Tests for terminal command processing behavior."""

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
