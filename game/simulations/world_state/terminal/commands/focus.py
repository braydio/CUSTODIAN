"""FOCUS command handler."""

from game.simulations.world_state.core.config import SECTOR_DEFS
from game.simulations.world_state.core.state import GameState


def cmd_focus(state: GameState, sector_id: str) -> list[str]:
    """Set the focused sector by ID."""

    normalized = sector_id.strip().upper()
    sector_lookup = {}
    for sector in SECTOR_DEFS:
        sector_lookup[sector["id"]] = sector["name"]
        sector_lookup[sector["name"].upper()] = sector["name"]
        sector_lookup[sector["name"].split()[0].upper()] = sector["name"]

    if normalized not in sector_lookup:
        return ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]

    name = sector_lookup[normalized]
    sector_id = next(
        sector["id"] for sector in SECTOR_DEFS if sector["name"] == name
    )
    state.focused_sector = sector_id
    return [f"[FOCUS SET] {name}"]
