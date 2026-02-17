"""Deterministic tests for defense doctrine/allocation/readiness influence."""

from game.simulations.world_state.core import assaults
from game.simulations.world_state.core.repairs import start_repair
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState
from game.simulations.world_state.terminal.processor import process_command


def _state_rank(value: StructureState) -> int:
    order = {
        StructureState.OPERATIONAL: 0,
        StructureState.DAMAGED: 1,
        StructureState.OFFLINE: 2,
        StructureState.DESTROYED: 3,
    }
    return order[value]


def test_doctrine_changes_assault_budget_deterministically() -> None:
    balanced = GameState(seed=12)
    aggressive = GameState(seed=12)
    aggressive.set_defense_doctrine("AGGRESSIVE")

    assaults._start_assault(balanced, [balanced.sectors["COMMAND"]])
    assaults._start_assault(aggressive, [aggressive.sectors["COMMAND"]])

    assert aggressive.current_assault is not None
    assert balanced.current_assault is not None
    assert aggressive.current_assault.threat_budget > balanced.current_assault.threat_budget


def test_allocation_bias_shifts_damage_distribution() -> None:
    state = GameState(seed=7)
    state.set_defense_doctrine("COMMAND_FIRST")
    state.defense_allocation = {
        "PERIMETER": 0.6,
        "POWER": 1.0,
        "SENSORS": 1.0,
        "COMMAND": 1.4,
    }

    assaults._degrade_target_structures(state, {"COMMAND", "STORAGE"})

    command_state = state.structures["CC_CORE"].state
    storage_state = state.structures["ST_CORE"].state
    assert _state_rank(storage_state) >= _state_rank(command_state)


def test_readiness_reduces_effective_severity_roll() -> None:
    ready = GameState(seed=3)
    ready.time = 10
    ready.doctrine_last_changed_time = 0
    ready.set_defense_doctrine("BALANCED")

    stressed = GameState(seed=3)
    stressed.set_defense_doctrine("BALANCED")
    stressed.sectors["COMMAND"].damage = 1.6
    stressed.sectors["POWER"].damage = 1.6
    stressed.sectors["COMMS"].power = 0.2
    stressed.sectors["ARCHIVE"].power = 1.0
    stressed.structures["CC_CORE"].state = StructureState.DAMAGED
    start_repair(stressed, "CC_CORE", local=False)

    ready_readiness = ready.compute_readiness()
    stressed_readiness = stressed.compute_readiness()

    assaults._start_assault(ready, [ready.sectors["COMMAND"]])
    assaults._start_assault(stressed, [stressed.sectors["COMMAND"]])

    assert ready_readiness > stressed_readiness
    assert ready.current_assault is not None
    assert stressed.current_assault is not None
    assert ready.current_assault.threat_budget < stressed.current_assault.threat_budget


def test_terminal_commands_configure_defense_layer() -> None:
    state = GameState(seed=1)

    doctrine = process_command(state, "CONFIG DOCTRINE COMMAND_FIRST")
    allocation = process_command(state, "ALLOCATE DEFENSE COMMAND 40")
    status = process_command(state, "STATUS")

    assert doctrine.ok is True
    assert doctrine.text == "DEFENSE DOCTRINE SET: COMMAND_FIRST"
    assert allocation.ok is True
    assert allocation.text == "DEFENSE ALLOCATION UPDATED: COMMAND 40%"
    assert status.ok is True
    assert status.lines is not None
    assert "DEFENSE DOCTRINE: COMMAND_FIRST" in status.lines


def test_defense_configuration_requires_command_authority() -> None:
    state = GameState(seed=2)
    process_command(state, "DEPLOY NORTH")

    doctrine = process_command(state, "CONFIG DOCTRINE AGGRESSIVE")
    allocation = process_command(state, "ALLOCATE DEFENSE COMMAND 40")

    assert doctrine.ok is False
    assert doctrine.text == "COMMAND AUTHORITY REQUIRED."
    assert allocation.ok is False
    assert allocation.text == "COMMAND AUTHORITY REQUIRED."
