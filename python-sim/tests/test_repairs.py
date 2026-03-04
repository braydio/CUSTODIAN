from game.simulations.world_state.core.repairs import (
    cancel_repair_for_structure,
    regress_repairs_in_sectors,
    start_repair,
    tick_repairs,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import Structure, StructureState


def test_structure_repair_progression() -> None:
    state = GameState()
    structure = Structure("T1", "Test Turret", "DEFENSE GRID")
    structure.state = StructureState.DAMAGED
    state.structures[structure.id] = structure

    result = start_repair(state, "T1")
    assert result == "REMOTE REPAIR QUEUED: Test Turret (COST: 2 MATERIALS)"

    tick_repairs(state)
    tick_repairs(state)
    tick_repairs(state)
    tick_repairs(state)

    assert structure.state == StructureState.OPERATIONAL


def test_repair_requires_materials() -> None:
    state = GameState()
    state.materials = 0
    structure = Structure("T2", "Test Relay", "POWER")
    structure.state = StructureState.DAMAGED
    state.structures[structure.id] = structure

    result = start_repair(state, "T2")

    assert result == "REPAIR FAILED: INSUFFICIENT MATERIALS."
    assert state.active_repairs == {}
    assert structure.state == StructureState.DAMAGED


def test_remote_repair_for_offline_is_denied() -> None:
    state = GameState()
    structure = Structure("T3", "Test Node", "POWER")
    structure.state = StructureState.OFFLINE
    state.structures[structure.id] = structure

    result = start_repair(state, "T3")

    assert result == "REMOTE REPAIR NOT POSSIBLE. PHYSICAL INTERVENTION REQUIRED."


def test_repair_speed_slows_when_sector_power_is_degraded() -> None:
    state = GameState()
    structure = Structure("T4", "Test Turret", "DEFENSE GRID")
    structure.state = StructureState.DAMAGED
    state.structures[structure.id] = structure
    state.sectors["DEFENSE GRID"].power = 0.6

    result = start_repair(state, "T4")

    assert result == "REMOTE REPAIR QUEUED: Test Turret (COST: 2 MATERIALS)"
    for _ in range(4):
        tick_repairs(state)
    assert structure.state == StructureState.DAMAGED

    for _ in range(4):
        tick_repairs(state)
    assert structure.state == StructureState.OPERATIONAL


def test_reconstruction_requires_power_and_drones() -> None:
    state = GameState()
    state.player_mode = "FIELD"
    state.player_location = "POWER"
    structure = Structure("T5", "Test Relay", "POWER")
    structure.state = StructureState.DESTROYED
    state.structures[structure.id] = structure

    state.sectors["POWER"].power = 0.2
    result = start_repair(state, "T5", local=True)
    assert result == "REPAIR FAILED: MINIMUM SECTOR POWER REQUIRED."

    state.sectors["POWER"].power = 1.0
    state.sectors["FABRICATION"].power = 0.2
    result = start_repair(state, "T5", local=True)
    assert result == "REPAIR FAILED: MECHANIC DRONES OFFLINE."

    state.sectors["FABRICATION"].power = 1.0
    result = start_repair(state, "T5", local=True)
    assert result == "MANUAL REPAIR STARTED: Test Relay (COST: 4 MATERIALS)"


def test_repair_regression_and_cancellation_refund() -> None:
    state = GameState()
    structure = Structure("T6", "Test Node", "DEFENSE GRID")
    structure.state = StructureState.DAMAGED
    state.structures[structure.id] = structure

    result = start_repair(state, "T6")
    assert result == "REMOTE REPAIR QUEUED: Test Node (COST: 2 MATERIALS)"

    tick_repairs(state)
    remaining = state.active_repairs["T6"]["remaining"]
    regress_repairs_in_sectors(state, {"DEFENSE GRID"})
    assert state.active_repairs["T6"]["remaining"] == remaining + 1.0

    materials_before = state.materials
    refund = cancel_repair_for_structure(state, "T6")
    assert refund == 1
    assert state.materials == materials_before + 1
    assert "T6" not in state.active_repairs
