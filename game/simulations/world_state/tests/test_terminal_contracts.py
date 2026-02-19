"""Tests for terminal command contracts."""

from game.simulations.world_state.core.config import (
    COMMAND_BREACH_RECOVERY_TICKS,
    COMMAND_CENTER_BREACH_DAMAGE,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_help_output_matches_contract() -> None:
    """HELP should return the documented command list."""

    state = GameState()

    result = process_command(state, "HELP")

    assert result.ok is True
    assert result.text == "AVAILABLE COMMANDS:"
    assert result.lines == [
        "- STATUS   View current situation",
        "- STATUS FULL  Show extended diagnostics",
        "- WAIT     Advance time (1 tick)",
        "- WAIT NX  Advance time by N x 1 tick",
        "- WAIT UNTIL <COND>  Advance until ASSAULT/APPROACH/REPAIR_DONE",
        "- DEPLOY   Leave command via transit",
        "- MOVE     Traverse transit and sectors",
        "- RETURN   Return to command center",
        "- FOCUS    Reallocate attention to a sector",
        "- HARDEN   Reinforce systems against impact",
        "- REPAIR   Begin structure repair",
        "- REPAIR <ID> FULL  Force sector stabilization",
        "- SET <POLICY> <0-4>  Set REPAIR/DEFENSE/SURVEILLANCE",
        "- SET FAB <CAT> <0-4>  Set FAB DEFENSE/DRONES/REPAIRS/ARCHIVE",
        "- FORTIFY <SECTOR> <0-4>  Set sector fortification level",
        "- SCAVENGE Recover materials",
        "- SCAVENGE NX  Run N scavenge cycles",
        "- CONFIG   Set defense doctrine",
        "- ALLOCATE Set defense allocation bias",
        "- HELP     Show this list",
    ]


def test_status_output_contains_locked_sections() -> None:
    """STATUS output should provide required headers and sector rows."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert result.text.startswith("TIME: ")
    assert "THREAT:" in result.text
    assert "ASSAULT:" in result.text
    assert result.lines is not None
    assert "SECTORS:" in result.lines
    assert any("COMMAND" in line for line in result.lines)


def test_wait_failure_lines_are_explicit_and_final() -> None:
    """WAIT should fail only after the breach recovery window is exhausted."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE

    for _ in range(COMMAND_BREACH_RECOVERY_TICKS + 2):
        result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines == ["COMMAND CENTER LOST", "SESSION TERMINATED."]


def test_reboot_alias_is_accepted_in_failure_mode() -> None:
    """REBOOT should be accepted as a failure recovery command."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    for _ in range(COMMAND_BREACH_RECOVERY_TICKS + 2):
        process_command(state, "WAIT")

    result = process_command(state, "REBOOT")

    assert result.ok is True
    assert result.text == "SYSTEM REBOOTED."
    assert result.lines == ["SESSION READY."]
