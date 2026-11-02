"""Deterministic fortification-to-perimeter wall mapping utilities."""

from __future__ import annotations

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import generate_perimeter_positions


PERIMETER_WALL_SUBTYPE = "PERIMETER"


def apply_sector_fortification_layout(state: GameState, sector_name: str, level: int) -> None:
    """Apply deterministic perimeter-wall layout for a sector fortification level."""

    grid = state.sector_grids.get(sector_name)
    if grid is None:
        return

    desired_positions = generate_perimeter_positions(level, grid.width, grid.height)
    desired = set(desired_positions)

    perimeter_ids: list[str] = []
    for sid, instance in state.structure_instances.items():
        if instance.sector != sector_name:
            continue
        if instance.type != "WALL" or instance.subtype != PERIMETER_WALL_SUBTYPE:
            continue
        perimeter_ids.append(sid)
    perimeter_ids.sort()

    for sid in perimeter_ids:
        instance = state.structure_instances.get(sid)
        if instance is None:
            continue
        if instance.position in desired:
            continue
        state.remove_structure_instance(sid)

    for x, y in sorted(desired):
        cell = grid.cells[(x, y)]
        existing_id = cell.structure_id
        if existing_id is not None:
            existing = state.structure_instances.get(existing_id)
            if (
                existing is not None
                and existing.type == "WALL"
                and existing.subtype == PERIMETER_WALL_SUBTYPE
            ):
                continue
            # Do not override non-perimeter occupancy.
            continue
        state.place_structure_instance(
            "WALL",
            sector_name,
            x,
            y,
            subtype=PERIMETER_WALL_SUBTYPE,
        )


def erode_perimeter_walls(state: GameState, sector_name: str, steps: int = 1) -> int:
    """Remove deterministic perimeter wall instances to represent breach erosion."""

    candidates: list[tuple[tuple[int, int], str]] = []
    for sid, instance in state.structure_instances.items():
        if instance.sector != sector_name:
            continue
        if instance.type != "WALL" or instance.subtype != PERIMETER_WALL_SUBTYPE:
            continue
        candidates.append((instance.position, sid))
    if not candidates:
        return 0

    candidates.sort()
    removed = 0
    for _, sid in candidates[: max(0, int(steps))]:
        if state.remove_structure_instance(sid):
            removed += 1
    return removed
