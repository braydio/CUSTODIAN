from game.simulations.world_state.core.repairs import start_repair, tick_repairs
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import Structure, StructureState


def test_structure_repair_progression() -> None:
    state = GameState()
    structure = Structure("T1", "Test Turret", "DEFENSE GRID")
    structure.state = StructureState.DAMAGED
    state.structures[structure.id] = structure

    result = start_repair(state, "T1")
    assert result == "REPAIR STARTED: Test Turret"

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
