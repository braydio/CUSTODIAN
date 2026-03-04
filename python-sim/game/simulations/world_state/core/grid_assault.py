"""Deterministic grid-topology helpers for assault pressure shaping."""

from __future__ import annotations

from collections import deque

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import generate_perimeter_positions


def _expected_perimeter_positions(state: GameState, sector_name: str) -> set[tuple[int, int]]:
    grid = state.sector_grids.get(sector_name)
    if grid is None:
        return set()
    level = int(state.sector_fort_levels.get(sector_name, 0))
    return generate_perimeter_positions(level, grid.width, grid.height)


def perimeter_wall_coverage(state: GameState, sector_name: str) -> float:
    """Return [0,1] ratio of expected perimeter cells occupied by WALL structures."""

    expected = _expected_perimeter_positions(state, sector_name)
    if not expected:
        return 1.0

    grid = state.sector_grids[sector_name]
    present = 0
    for pos in expected:
        sid = grid.cells[pos].structure_id
        if sid is None:
            continue
        instance = state.structure_instances.get(sid)
        if instance is None:
            continue
        if instance.type == "WALL":
            present += 1
    return present / float(len(expected))


def perimeter_wall_continuity(state: GameState, sector_name: str) -> float:
    """Return [0,1] size of largest connected expected WALL cluster."""

    expected = _expected_perimeter_positions(state, sector_name)
    if not expected:
        return 1.0

    grid = state.sector_grids[sector_name]
    walls: set[tuple[int, int]] = set()
    for pos in expected:
        sid = grid.cells[pos].structure_id
        if sid is None:
            continue
        instance = state.structure_instances.get(sid)
        if instance is None:
            continue
        if instance.type == "WALL":
            walls.add(pos)

    if not walls:
        return 0.0

    visited: set[tuple[int, int]] = set()
    largest = 0
    for start in walls:
        if start in visited:
            continue
        q: deque[tuple[int, int]] = deque([start])
        visited.add(start)
        size = 0
        while q:
            x, y = q.popleft()
            size += 1
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                nxt = (nx, ny)
                if nxt not in walls or nxt in visited:
                    continue
                visited.add(nxt)
                q.append(nxt)
        largest = max(largest, size)

    return largest / float(len(expected))


def weakest_perimeter_segment(state: GameState, sector_name: str) -> float:
    """Return [0,1] coverage of the weakest perimeter edge segment."""

    expected = _expected_perimeter_positions(state, sector_name)
    if not expected:
        return 1.0

    grid = state.sector_grids[sector_name]
    max_x = grid.width - 1
    max_y = grid.height - 1
    edges = {
        "LEFT": {pos for pos in expected if pos[0] == 0},
        "RIGHT": {pos for pos in expected if pos[0] == max_x},
        "BOTTOM": {pos for pos in expected if pos[1] == 0},
        "TOP": {pos for pos in expected if pos[1] == max_y},
    }

    edge_scores: list[float] = []
    for positions in edges.values():
        if not positions:
            continue
        present = 0
        for pos in positions:
            sid = grid.cells[pos].structure_id
            if sid is None:
                continue
            instance = state.structure_instances.get(sid)
            if instance is not None and instance.type == "WALL":
                present += 1
        edge_scores.append(present / float(len(positions)))

    if not edge_scores:
        return 1.0
    return min(edge_scores)


def topology_damage_multiplier(state: GameState, sector_name: str) -> float:
    """Return a bounded assault pressure multiplier from perimeter topology.

    Intact, continuous perimeter walls reduce incoming pressure. Missing/fragmented
    perimeter walls increase pressure.
    """

    expected = _expected_perimeter_positions(state, sector_name)
    if not expected:
        return 1.0

    grid = state.sector_grids[sector_name]
    has_perimeter_walls = False
    for pos in expected:
        sid = grid.cells[pos].structure_id
        if sid is None:
            continue
        instance = state.structure_instances.get(sid)
        if instance is None:
            continue
        if instance.type == "WALL":
            has_perimeter_walls = True
            break
    if not has_perimeter_walls:
        # Preserve compatibility for pre-grid-fortification saves/tests where
        # numeric fortification exists but no perimeter wall instances are present.
        return 1.0

    coverage = perimeter_wall_coverage(state, sector_name)
    continuity = perimeter_wall_continuity(state, sector_name)
    weakest_segment = weakest_perimeter_segment(state, sector_name)
    score = (coverage * 0.45) + (continuity * 0.35) + (weakest_segment * 0.20)
    return max(0.85, min(1.15, 1.15 - (0.30 * score)))
