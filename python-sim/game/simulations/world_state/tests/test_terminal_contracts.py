"""Tests for terminal command contracts."""

from game.simulations.world_state.core.config import (
    COMMAND_BREACH_RECOVERY_TICKS,
    COMMAND_CENTER_BREACH_DAMAGE,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def test_help_output_matches_contract() -> None:
    """HELP should return the categorized command tree."""

    state = GameState()

    result = process_command(state, "HELP")

    assert result.ok is True
    assert result.text == "COMMAND TREE"
    assert result.lines == [
        "USE: HELP <TOPIC>",
        "TOPICS: CORE | MOVEMENT | SYSTEMS | GRID | POLICY | FABRICATION | ASSAULT | STATUS",
        "",
        "[CORE] STATUS | WAIT | HELP",
        "[MOVEMENT] DEPLOY | MOVE | RETURN",
        "[SYSTEMS] FOCUS | HARDEN | REPAIR | SCAVENGE",
        "[GRID] BUILD <TYPE> <X> <Y>",
        "[POLICY] SET | FORTIFY | POLICY | CONFIG | ALLOCATE | DRONE_REPAIR",
        "[FABRICATION] FAB ADD | QUEUE | CANCEL | PRIORITY",
        "[ASSAULT] SCAN | STABILIZE | SYNC | REROUTE | BOOST | DRONE | LOCKDOWN | PRIORITIZE",
        "[STATUS] STATUS | STATUS FULL | STATUS <FAB|POSTURE|ASSAULT|POLICY|SYSTEMS|RELAY|KNOWLEDGE>",
    ]


def test_tutorial_output_matches_contract() -> None:
    """TUTORIAL should return the tutorial index."""

    state = GameState()

    result = process_command(state, "TUTORIAL")

    assert result.ok is True
    assert result.text == "TUTORIAL INDEX"
    assert result.lines is not None
    assert result.lines[0] == "USE: TUTORIAL <TOPIC>"
    assert "TOPICS: CORE | MOVEMENT | SYSTEMS | GRID | POLICY | FABRICATION | ASSAULT | STATUS | RELAY | QUICKSTART" in result.lines


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

    result = process_command(state, "WAIT")
    for _ in range(COMMAND_BREACH_RECOVERY_TICKS + 6):
        if result.lines == ["COMMAND CENTER LOST", "SESSION TERMINATED."]:
            break
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
