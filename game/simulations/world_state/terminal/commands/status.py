"""STATUS command handler."""

from game.simulations.world_state.core.config import SECTORS
from game.simulations.world_state.core.state import GameState, SectorState


def _threat_bucket(ambient_threat: float) -> str:
    """Map ambient threat to a Phase 1 bucket."""

    if ambient_threat < 1.5:
        return "LOW"
    if ambient_threat < 3.0:
        return "ELEVATED"
    if ambient_threat < 5.0:
        return "HIGH"
    return "CRITICAL"


def _assault_status(state: GameState) -> str:
    """Return current assault phase label."""

    if state.in_major_assault or state.current_assault is not None:
        return "ACTIVE"
    if state.assault_timer is not None:
        return "PENDING"
    return "NONE"


def _sector_status(sector: SectorState) -> str:
    """Map sector metrics to one-word status label."""

    if sector.damage >= 2.0:
        return "COMPROMISED"
    if sector.damage >= 1.0 or sector.alertness >= 2.0:
        return "DAMAGED"
    if sector.alertness >= 0.8 or sector.occupied:
        return "ALERT"
    return "STABLE"


def cmd_status(state: GameState) -> list[str]:
    """Build the locked STATUS report output."""

    lines = [
        f"TIME: {state.time}",
        f"THREAT: {_threat_bucket(state.ambient_threat)}",
        f"ASSAULT: {_assault_status(state)}",
        "",
        "SECTORS:",
    ]
    for sector_name in SECTORS:
        sector = state.sectors[sector_name]
        lines.append(f"- {sector_name}: {_sector_status(sector)}")
    return lines
