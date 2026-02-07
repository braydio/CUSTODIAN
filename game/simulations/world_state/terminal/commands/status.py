"""STATUS command handler."""

from game.simulations.world_state.core.state import GameState


def cmd_status(state: GameState) -> list[str]:
    """Build the locked STATUS report output."""

    snapshot = state.snapshot()
    lines = [
        f"TIME: {snapshot['time']}",
        f"THREAT: {snapshot['threat']}",
        f"ASSAULT: {snapshot['assault']}",
        "",
        "SECTORS:",
    ]
    for sector in snapshot["sectors"]:
        lines.append(f"- {sector['name']}: {sector['status']}")
    return lines
