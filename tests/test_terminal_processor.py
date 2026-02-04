"""Tests for terminal command processing."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.parser import ParsedCommand
from game.simulations.world_state.terminal.processor import process_command


def test_process_command_unknown() -> None:
    state = GameState()
    parsed = ParsedCommand(raw="unknown", verb="unknown", args=[], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is False
    assert "unknown" in result.message.casefold()


def test_process_command_write_denied() -> None:
    state = GameState()
    state.player_location = "Fuel Depot"
    parsed = ParsedCommand(raw="advance 1", verb="advance", args=["1"], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is False
    assert "command center" in result.message.casefold()


def test_process_command_read_ok() -> None:
    state = GameState()
    parsed = ParsedCommand(raw="status", verb="status", args=[], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is True
    assert "time=" in result.message.casefold()
    assert "location=command center" in result.message.casefold()
