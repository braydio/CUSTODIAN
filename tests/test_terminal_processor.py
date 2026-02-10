"""Tests for terminal command processing."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState
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


def test_process_command_focus_sets_sector() -> None:
    """FOCUS should set focused sector without advancing time."""

    state = GameState()

    result = process_command(state, "FOCUS POWER")

    assert result.ok is True
    assert result.text == "[FOCUS SET] POWER"
    assert state.time == 0
    assert state.focused_sector == "PW"
    assert state.hardened is False


def test_process_command_harden_sets_posture() -> None:
    """HARDEN should set hardened posture without advancing time."""

    state = GameState()
    process_command(state, "FOCUS POWER")

    result = process_command(state, "HARDEN")

    assert result.ok is True
    assert result.text == "[HARDENING SYSTEMS]"
    assert state.time == 0
    assert state.hardened is True
    assert state.focused_sector is None


def test_process_command_wait_nx_steps_world(monkeypatch) -> None:
    """WAIT NX should advance N ticks and summarize output."""

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

    result = process_command(state, "WAIT 10X")

    assert result.ok is True
    assert state.time == 10
    assert result.text == "TIME ADVANCED x10."
    assert result.lines == ["", "[SUMMARY]", "- THREAT ESCALATED"]


def test_process_command_scavenge_advances_time_and_materials(monkeypatch) -> None:
    """SCAVENGE should advance time and grant materials."""

    state = GameState()
    state.materials = 0

    def _step(local_state: GameState) -> bool:
        local_state.time += 1
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.scavenge.step_world",
        _step,
    )
    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.scavenge.random.randint",
        lambda _min, _max: 2,
    )

    result = process_command(state, "SCAVENGE")

    assert result.ok is True
    assert state.time == 3
    assert state.materials == 2
    assert result.text == "[SCAVENGE] OPERATION COMPLETE."
    assert result.lines == ["[RESOURCE GAIN] +2 MATERIALS"]


def test_repair_reissue_reports_status() -> None:
    """REPAIR issued during active repair should return a status line."""

    state = GameState()
    structure = state.structures["CC_CORE"]
    structure.state = StructureState.DAMAGED
    state.materials = 3

    start = process_command(state, "REPAIR CC_CORE")
    status = process_command(state, "REPAIR CC_CORE")

    assert start.ok is True
    assert status.ok is True
    assert status.text.startswith("[REPAIR] IN PROGRESS:")
