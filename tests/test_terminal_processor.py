"""Tests for terminal command processing."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_process_command_unknown() -> None:
    """Unknown commands should use locked error lines."""

    state = GameState()

    result = process_command(state, "unknown")

    assert result.ok is False
    assert result.text == "UNKNOWN COMMAND."
    assert result.lines == ["TYPE HELP FOR AVAILABLE COMMANDS."]


def test_process_command_status() -> None:
    """STATUS should execute and return a time line."""

    state = GameState()

    result = process_command(state, "status")

    assert result.ok is True
    assert result.text.startswith("TIME: ")


def test_process_command_wait_steps_world() -> None:
    """WAIT should advance one tick and report time advanced."""

    state = GameState()

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert state.time == 1
    assert result.text == "TIME ADVANCED."
