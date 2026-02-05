"""Tests for locked terminal command contracts."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_help_output_matches_locked_contract() -> None:
    """HELP should return exactly the locked command list."""

    state = GameState()

    result = process_command(state, "HELP")

    assert result.ok is True
    assert result.lines == [
        "AVAILABLE COMMANDS:",
        "- STATUS   View current situation",
        "- WAIT     Advance time",
        "- HELP     Show this list",
    ]


def test_status_output_contains_locked_sections() -> None:
    """STATUS output should provide required headers and sector rows."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert result.lines[0].startswith("TIME: ")
    assert result.lines[1].startswith("THREAT: ")
    assert result.lines[2].startswith("ASSAULT: ")
    assert result.lines[4] == "SECTORS:"
    assert result.lines[5].startswith("- Command Center: ")
