"""Assault micro-tactical command handlers."""

from __future__ import annotations

from game.simulations.world_state.core.state import GameState


def _require_active_assault(state: GameState) -> str | None:
    if state.current_assault is None or not state.in_major_assault:
        return "TACTICAL COMMAND REQUIRES ACTIVE ASSAULT."
    return None


def cmd_reroute_power(state: GameState, sector_token: str) -> list[str]:
    err = _require_active_assault(state)
    if err:
        return [err]
    token = sector_token.strip().upper()
    sector = state.sectors.get(token)
    if sector is None:
        return ["UNKNOWN SECTOR."]
    if sector.power < 1.5:
        sector.power = min(2.0, sector.power + 0.25)
    state.assault_tactical_effects[f"REROUTE:{sector.name}"] = {"remaining": 2}
    return [f"POWER REROUTED TO {sector.name} (2 TICKS)."]


def cmd_boost_defense(state: GameState, sector_token: str) -> list[str]:
    err = _require_active_assault(state)
    if err:
        return [err]
    token = sector_token.strip().upper()
    sector = state.sectors.get(token)
    if sector is None:
        return ["UNKNOWN SECTOR."]
    state.assault_tactical_effects[f"BOOST:{sector.name}"] = {"remaining": 2}
    return [f"DEFENSE BOOSTED AT {sector.name} (2 TICKS)."]


def cmd_deploy_drone(state: GameState, sector_token: str) -> list[str]:
    err = _require_active_assault(state)
    if err:
        return [err]
    if state.repair_drone_stock <= 0:
        return ["NO REPAIR DRONES AVAILABLE."]
    token = sector_token.strip().upper()
    sector = state.sectors.get(token)
    if sector is None:
        return ["UNKNOWN SECTOR."]
    state.repair_drone_stock -= 1
    state.assault_tactical_effects[f"DRONE:{sector.name}"] = {"remaining": 3}
    return [f"REPAIR DRONE DEPLOYED TO {sector.name}."]


def cmd_lockdown(state: GameState, sector_token: str) -> list[str]:
    err = _require_active_assault(state)
    if err:
        return [err]
    token = sector_token.strip().upper()
    sector = state.sectors.get(token)
    if sector is None:
        return ["UNKNOWN SECTOR."]
    state.assault_tactical_effects[f"LOCKDOWN:{sector.name}"] = {"remaining": 2}
    return [f"LOCKDOWN ACTIVE IN {sector.name} (2 TICKS)."]


def cmd_prioritize_repair(state: GameState, sector_token: str) -> list[str]:
    err = _require_active_assault(state)
    if err:
        return [err]
    token = sector_token.strip().upper()
    sector = state.sectors.get(token)
    if sector is None:
        return ["UNKNOWN SECTOR."]
    state.assault_tactical_effects[f"REPAIR:{sector.name}"] = {"remaining": 3}
    return [f"REPAIR PRIORITY SET: {sector.name} (3 TICKS)."]

