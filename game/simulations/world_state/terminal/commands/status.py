"""STATUS command handler."""

from game.simulations.world_state.core.config import ARCHIVE_LOSS_LIMIT, SECTOR_DEFS
from game.simulations.world_state.core.state import GameState


def cmd_status(state: GameState) -> list[str]:
    """Build the locked STATUS report output."""

    snapshot = state.snapshot()
    focus_lookup = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
    lines = [
        f"TIME: {snapshot['time']}",
        f"THREAT: {snapshot['threat']}",
        f"ASSAULT: {snapshot['assault']}",
    ]
    if state.hardened:
        lines.append("SYSTEM POSTURE: HARDENED")
    elif state.focused_sector:
        focused_name = focus_lookup.get(state.focused_sector, "UNKNOWN")
        lines.append(f"SYSTEM POSTURE: FOCUSED ({focused_name})")
    if state.archive_losses > 0:
        lines.append(f"ARCHIVE LOSSES: {state.archive_losses}/{ARCHIVE_LOSS_LIMIT}")
    lines.extend([
        "",
        "SECTORS:",
    ])
    for sector in snapshot["sectors"]:
        lines.append(f"- {sector['name']}: {sector['status']}")
    return lines
