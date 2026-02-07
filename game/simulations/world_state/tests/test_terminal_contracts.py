"""Tests for locked terminal command contracts."""

from game.simulations.world_state.core.config import COMMAND_CENTER_BREACH_DAMAGE
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_help_output_matches_locked_contract() -> None:
    """HELP should return exactly the locked command list."""

    state = GameState()

    result = process_command(state, "HELP")

    assert result.ok is True
    assert result.text == "AVAILABLE COMMANDS:"
    assert result.lines == [
        "- STATUS   View current situation",
        "- WAIT     Advance time",
        "- WAIT 10X Advance time by ten ticks",
        "- FOCUS    Reallocate attention to a sector",
        "- HELP     Show this list",
    ]


def test_status_output_contains_locked_sections() -> None:
    """STATUS output should provide required headers and sector rows."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert result.text.startswith("TIME: ")
    assert result.lines[0].startswith("THREAT: ")
    assert result.lines[1].startswith("ASSAULT: ")
    assert result.lines[3] == "SECTORS:"
    assert result.lines[4].startswith("- COMMAND: ")


def test_wait_failure_lines_are_explicit_and_final() -> None:
    """WAIT should return final failure lines when COMMAND is breached."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines == ["COMMAND BREACHED.", "SESSION TERMINATED."]


def test_reboot_alias_is_accepted_in_failure_mode() -> None:
    """REBOOT should be accepted as a failure recovery command."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    process_command(state, "WAIT")

    result = process_command(state, "REBOOT")

    assert result.ok is True
    assert result.text == "SYSTEM REBOOTED."
    assert result.lines == ["SESSION READY."]
