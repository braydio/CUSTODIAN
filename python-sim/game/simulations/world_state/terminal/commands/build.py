"""BUILD command handler for deterministic grid placement."""

from __future__ import annotations

from game.simulations.world_state.core.config import SECTOR_DEFS
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import STRUCTURE_TYPES


SECTOR_ID_TO_NAME = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
SECTOR_NAME_TO_NAME = {sector["name"]: sector["name"] for sector in SECTOR_DEFS}


def _resolve_sector_name(token: str) -> str | None:
    normalized = token.strip().upper()
    if not normalized:
        return None
    return SECTOR_ID_TO_NAME.get(normalized) or SECTOR_NAME_TO_NAME.get(normalized)


def cmd_build(state: GameState, structure_type: str, x_token: str, y_token: str) -> list[str]:
    if not state.in_command_mode():
        return ["COMMAND AUTHORITY REQUIRED."]

    sector = _resolve_sector_name(state.player_location)
    if not sector:
        return ["BUILD REQUIRES A VALID SECTOR CONTEXT."]

    stype = structure_type.strip().upper()
    profile = STRUCTURE_TYPES.get(stype)
    if profile is None:
        known = ", ".join(sorted(STRUCTURE_TYPES))
        return [f"UNKNOWN STRUCTURE TYPE: {stype}.", f"KNOWN TYPES: {known}"]

    try:
        x = int(x_token)
        y = int(y_token)
    except ValueError:
        return ["BUILD <TYPE> <X> <Y>"]

    grid = state.sector_grids[sector]
    if not grid.in_bounds(x, y):
        return [f"COORDINATES OUT OF BOUNDS: ({x},{y}). GRID {grid.width}x{grid.height}."]

    cell = grid.cells[(x, y)]
    if cell.structure_id is not None:
        return [f"CELL OCCUPIED: ({x},{y}) -> {cell.structure_id}."]

    cost = int(profile["cost"])
    if state.materials < cost:
        return [f"INSUFFICIENT MATERIALS: NEED {cost}, HAVE {state.materials}."]

    state.materials -= cost
    instance = state.place_structure_instance(stype, sector, x, y)

    return [
        (
            f"BUILD COMPLETE: {instance.id} {instance.type} "
            f"AT {sector} ({x},{y}) COST {cost}."
        )
    ]
