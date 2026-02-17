"""Policy-layer command handlers."""

from __future__ import annotations

from game.simulations.world_state.core.config import SECTOR_DEFS
from game.simulations.world_state.core.fabrication import is_valid_fabrication_category
from game.simulations.world_state.core.policies import (
    POLICY_LEVEL_MAX,
    POLICY_LEVEL_MIN,
    clamp_policy_level,
    parse_policy_level,
)
from game.simulations.world_state.core.state import GameState


SECTOR_ID_TO_NAME = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
SECTOR_NAME_TO_NAME = {sector["name"]: sector["name"] for sector in SECTOR_DEFS}


def _resolve_sector_name(token: str) -> str | None:
    normalized = token.strip().upper()
    if not normalized:
        return None
    return SECTOR_ID_TO_NAME.get(normalized) or SECTOR_NAME_TO_NAME.get(normalized)


def cmd_set_policy(state: GameState, policy_name: str, level_token: str) -> list[str]:
    level = parse_policy_level(level_token)
    if level is None:
        return [f"LEVEL MUST BE {POLICY_LEVEL_MIN}-{POLICY_LEVEL_MAX}."]

    key = policy_name.strip().upper()
    if key == "REPAIR":
        state.policies.repair_intensity = level
        return [f"REPAIR INTENSITY SET TO {level}."]
    if key == "DEFENSE":
        state.policies.defense_readiness = level
        return [f"DEFENSE READINESS SET TO {level}."]
    if key == "SURVEILLANCE":
        state.policies.surveillance_coverage = level
        return [f"SURVEILLANCE COVERAGE SET TO {level}."]
    return ["SET REQUIRES: REPAIR, DEFENSE, OR SURVEILLANCE."]


def cmd_set_fabrication(state: GameState, category: str, level_token: str) -> list[str]:
    level = parse_policy_level(level_token)
    if level is None:
        return [f"LEVEL MUST BE {POLICY_LEVEL_MIN}-{POLICY_LEVEL_MAX}."]

    normalized = category.strip().upper()
    if not is_valid_fabrication_category(normalized):
        return ["FAB CATEGORY MUST BE DEFENSE, DRONES, REPAIRS, OR ARCHIVE."]
    state.fab_allocation[normalized] = clamp_policy_level(level)
    return [f"FABRICATION {normalized} ALLOCATION SET TO {level}."]


def cmd_fortify(state: GameState, sector_token: str, level_token: str) -> list[str]:
    level = parse_policy_level(level_token)
    if level is None:
        return [f"LEVEL MUST BE {POLICY_LEVEL_MIN}-{POLICY_LEVEL_MAX}."]

    sector_name = _resolve_sector_name(sector_token)
    if not sector_name:
        return ["UNKNOWN SECTOR."]

    state.sector_fort_levels[sector_name] = clamp_policy_level(level)
    return [f"FORTIFICATION {sector_name} SET TO {level}."]

