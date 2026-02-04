"""Tests for terminal command processing."""

from game.simulations.world_state.terminal import commands
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.parser import ParsedCommand
from game.simulations.world_state.terminal.processor import process_command


def test_process_command_unknown() -> None:
    state = GameState()
    parsed = ParsedCommand(raw="unknown", verb="unknown", args=[], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is False
    assert "unknown" in result.text.casefold()


def test_process_command_write_denied() -> None:
    state = GameState()
    # Move operator out of the Command Center
    state.player_location = "Fuel Depot"

    parsed = ParsedCommand(raw="wait 1", verb="wait", args=["1"], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is False
    assert "command center" in result.text.casefold()


def test_process_command_read_ok() -> None:
    state = GameState()
    parsed = ParsedCommand(raw="status", verb="status", args=[], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is True
    assert "time=" in result.text.casefold()
    assert "location=command center" in result.text.casefold()


def test_process_command_wait_steps_world(monkeypatch) -> None:
    state = GameState()
    calls = {"count": 0}

    def step_stub(*args, **kwargs):
        calls["count"] += 1

    monkeypatch.setattr(commands, "step_world", step_stub)

    parsed = ParsedCommand(raw="wait 3", verb="wait", args=["3"], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is True
    assert calls["count"] == 3
    assert "waited" in result.text.casefold()


def test_process_command_go_sets_location() -> None:
    state = GameState()
    parsed = ParsedCommand(raw="go service", verb="go", args=["service"], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is True
    assert state.player_location == "Service Tunnels"
