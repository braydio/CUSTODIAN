"""Deterministic drone repair routing for perimeter-wall recovery."""

from __future__ import annotations

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import generate_perimeter_positions


EDGE_ORDER = ("BOTTOM", "LEFT", "RIGHT", "TOP")


def _edge_positions(width: int, height: int, positions: set[tuple[int, int]]) -> dict[str, set[tuple[int, int]]]:
    max_x = width - 1
    max_y = height - 1
    return {
        "LEFT": {pos for pos in positions if pos[0] == 0},
        "RIGHT": {pos for pos in positions if pos[0] == max_x},
        "BOTTOM": {pos for pos in positions if pos[1] == 0},
        "TOP": {pos for pos in positions if pos[1] == max_y},
    }


def _missing_perimeter_positions(state: GameState, sector_name: str) -> list[tuple[int, int]]:
    grid = state.sector_grids.get(sector_name)
    if grid is None:
        return []
    level = int(state.sector_fort_levels.get(sector_name, 0))
    expected = generate_perimeter_positions(level, grid.width, grid.height)
    if not expected:
        return []

    edge_map = _edge_positions(grid.width, grid.height, expected)
    edge_scores: list[tuple[float, str]] = []
    for edge_name, edge_cells in edge_map.items():
        if not edge_cells:
            continue
        present = 0
        for pos in edge_cells:
            sid = grid.cells[pos].structure_id
            if sid is None:
                continue
            instance = state.structure_instances.get(sid)
            if instance is not None and instance.type == "WALL":
                present += 1
        edge_scores.append((present / float(len(edge_cells)), edge_name))
    edge_scores.sort(key=lambda item: (item[0], EDGE_ORDER.index(item[1])))

    ordered_missing: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for _, edge_name in edge_scores:
        candidates = sorted(edge_map[edge_name])
        for pos in candidates:
            if pos in seen:
                continue
            seen.add(pos)
            sid = grid.cells[pos].structure_id
            if sid is None:
                ordered_missing.append(pos)
                continue
            instance = state.structure_instances.get(sid)
            if instance is not None and instance.type == "WALL":
                continue
            # Occupied by non-wall structure; not repairable by perimeter drones.
    return ordered_missing


def route_drone_perimeter_repairs(state: GameState) -> list[str]:
    """Perform at most one deterministic perimeter wall repair for the tick."""

    if str(getattr(state, "drone_perimeter_repair_policy", "AUTO")).upper() != "AUTO":
        return []
    if int(state.repair_drone_stock) <= 0:
        return []

    sectors = sorted(
        [name for name, level in state.sector_fort_levels.items() if int(level) > 0]
    )
    for sector_name in sectors:
        missing = _missing_perimeter_positions(state, sector_name)
        if not missing:
            continue
        x, y = missing[0]
        state.place_structure_instance("WALL", sector_name, x, y, subtype="PERIMETER")
        state.repair_drone_stock -= 1
        return [f"DRONE REPAIR: PERIMETER WALL RESTORED {sector_name} ({x},{y})"]
    return []


def perimeter_repair_backlog(state: GameState) -> dict[str, int]:
    """Return repairable missing perimeter-wall counts by sector."""

    backlog: dict[str, int] = {}
    sectors = sorted(
        [name for name, level in state.sector_fort_levels.items() if int(level) > 0]
    )
    for sector_name in sectors:
        missing = _missing_perimeter_positions(state, sector_name)
        if missing:
            backlog[sector_name] = len(missing)
    return backlog
