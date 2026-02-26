"""Tests for deterministic grid substrate and BUILD command."""

from game.simulations.world_state.core.config import GRID_HEIGHT, GRID_WIDTH, SECTORS
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import generate_perimeter_positions
from game.simulations.world_state.terminal.processor import process_command


def test_grid_created_for_each_sector() -> None:
    state = GameState()
    assert set(state.sector_grids) == set(SECTORS)
    for grid in state.sector_grids.values():
        assert grid.width == GRID_WIDTH
        assert grid.height == GRID_HEIGHT
        assert len(grid.cells) == GRID_WIDTH * GRID_HEIGHT


def test_build_succeeds_in_empty_cell() -> None:
    state = GameState()
    state.materials = 100
    result = process_command(state, "BUILD WALL 3 4")
    assert result.ok is True
    assert result.text.startswith("BUILD COMPLETE: S1 WALL AT COMMAND (3,4) COST 5.")
    assert state.structure_instances["S1"].position == (3, 4)
    assert state.sector_grids["COMMAND"].cells[(3, 4)].structure_id == "S1"


def test_build_rejects_out_of_bounds() -> None:
    state = GameState()
    result = process_command(state, "BUILD WALL 99 2")
    assert result.ok is True
    assert result.text.startswith("COORDINATES OUT OF BOUNDS:")
    assert not state.structure_instances


def test_build_rejects_occupied_cell() -> None:
    state = GameState()
    state.materials = 100
    process_command(state, "BUILD WALL 1 1")
    result = process_command(state, "BUILD TURRET 1 1")
    assert result.ok is True
    assert result.text.startswith("CELL OCCUPIED:")
    assert len(state.structure_instances) == 1


def test_build_deducts_materials() -> None:
    state = GameState()
    state.materials = 100
    starting = state.materials
    process_command(state, "BUILD WALL 0 0")
    assert state.materials == starting - 5


def test_snapshot_reload_preserves_grid_and_instances() -> None:
    state = GameState(seed=11)
    state.materials = 100
    process_command(state, "BUILD WALL 2 2")
    process_command(state, "BUILD TURRET 3 2")
    snapshot = state.snapshot()
    restored = GameState.from_snapshot(snapshot)

    assert restored.next_structure_id == state.next_structure_id
    assert restored.structure_instances.keys() == state.structure_instances.keys()
    assert restored.sector_grids["COMMAND"].cells[(2, 2)].structure_id == "S1"
    assert restored.sector_grids["COMMAND"].cells[(3, 2)].structure_id == "S2"
    assert restored.structure_instances["S1"].type == "WALL"
    assert restored.structure_instances["S2"].type == "TURRET"


def test_deterministic_id_generation() -> None:
    state = GameState()
    state.materials = 100
    process_command(state, "BUILD WALL 0 0")
    process_command(state, "BUILD WALL 0 1")
    process_command(state, "BUILD WALL 0 2")
    assert sorted(state.structure_instances.keys()) == ["S1", "S2", "S3"]
    assert state.next_structure_id == 4


def test_help_includes_grid_topic_and_build() -> None:
    state = GameState()
    result = process_command(state, "HELP")
    assert result.ok is True
    assert result.lines is not None
    assert "TOPICS: CORE | MOVEMENT | SYSTEMS | GRID | POLICY | FABRICATION | ASSAULT | STATUS" in result.lines
    assert "[GRID] BUILD <TYPE> <X> <Y>" in result.lines


def test_generate_perimeter_positions_is_deterministic_and_bounded() -> None:
    level_four = generate_perimeter_positions(4, GRID_WIDTH, GRID_HEIGHT)
    repeat = generate_perimeter_positions(4, GRID_WIDTH, GRID_HEIGHT)
    assert level_four == repeat
    assert all(0 <= x < GRID_WIDTH and 0 <= y < GRID_HEIGHT for x, y in level_four)
    assert len(level_four) > 0
