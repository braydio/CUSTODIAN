"""Tests for deterministic fortification perimeter-wall mapping."""

from game.simulations.world_state.core.grid_fortification import PERIMETER_WALL_SUBTYPE
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import generate_perimeter_positions
from game.simulations.world_state.terminal.processor import process_command


def _sector_walls(state: GameState, sector: str, subtype: str | None = None) -> list[tuple[str, tuple[int, int]]]:
    rows: list[tuple[str, tuple[int, int]]] = []
    for sid, instance in state.structure_instances.items():
        if instance.sector != sector or instance.type != "WALL":
            continue
        if subtype is not None and instance.subtype != subtype:
            continue
        rows.append((sid, instance.position))
    rows.sort(key=lambda item: item[0])
    return rows


def test_fortify_places_perimeter_walls_for_sector() -> None:
    state = GameState(seed=2)
    result = process_command(state, "FORTIFY PW 1")
    assert result.ok is True
    assert result.text == "FORTIFICATION POWER SET TO 1."

    positions = {pos for _, pos in _sector_walls(state, "POWER", PERIMETER_WALL_SUBTYPE)}
    expected = generate_perimeter_positions(1, 12, 12)
    assert positions == expected


def test_fortify_replaces_old_perimeter_layout_when_level_changes() -> None:
    state = GameState(seed=3)
    process_command(state, "FORTIFY PW 1")
    process_command(state, "FORTIFY PW 2")
    positions = {pos for _, pos in _sector_walls(state, "POWER", PERIMETER_WALL_SUBTYPE)}
    expected = generate_perimeter_positions(2, 12, 12)
    assert positions == expected


def test_fortify_does_not_override_non_perimeter_occupancy() -> None:
    state = GameState(seed=4)
    state.place_structure_instance("TURRET", "POWER", 0, 0)
    process_command(state, "FORTIFY PW 1")

    cell = state.sector_grids["POWER"].cells[(0, 0)]
    assert cell.structure_id is not None
    assert state.structure_instances[cell.structure_id].type == "TURRET"

    perimeter_positions = {pos for _, pos in _sector_walls(state, "POWER", PERIMETER_WALL_SUBTYPE)}
    assert (0, 0) not in perimeter_positions


def test_fortify_does_not_remove_manual_walls() -> None:
    state = GameState(seed=5)
    manual = state.place_structure_instance("WALL", "POWER", 5, 5)
    assert manual.subtype is None

    process_command(state, "FORTIFY PW 2")
    process_command(state, "FORTIFY PW 0")

    assert manual.id in state.structure_instances
    assert state.structure_instances[manual.id].position == (5, 5)
    assert _sector_walls(state, "POWER", PERIMETER_WALL_SUBTYPE) == []


def test_fortify_wall_generation_is_deterministic_for_same_commands() -> None:
    left = GameState(seed=9)
    right = GameState(seed=9)

    for state in (left, right):
        process_command(state, "FORTIFY PW 3")
        process_command(state, "FORTIFY PW 1")
        process_command(state, "FORTIFY PW 4")

    left_rows = _sector_walls(left, "POWER", PERIMETER_WALL_SUBTYPE)
    right_rows = _sector_walls(right, "POWER", PERIMETER_WALL_SUBTYPE)
    assert left_rows == right_rows


def test_status_full_surfaces_perimeter_topology_for_fortified_sectors() -> None:
    state = GameState(seed=13)
    process_command(state, "FORTIFY PW 2")

    status = process_command(state, "STATUS FULL")
    assert status.ok is True
    assert status.lines is not None
    assert "- PERIMETER TOPOLOGY:" in status.lines
    assert any(line.strip().startswith("POWER: COV ") for line in status.lines)
    assert any("WEAK " in line for line in status.lines)
