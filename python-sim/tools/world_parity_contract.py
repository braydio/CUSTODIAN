"""Shared, intentionally narrow Python-to-Godot parity projection v2."""
from __future__ import annotations
import hashlib
import json
from typing import Any
from game.simulations.world_state.core.policies import clamp_policy_level, FAB_CATEGORIES

FIXTURE_SCHEMA = "custodian.python_sim.godot_port_parity.v2"
COMMANDS_SCHEMA = "custodian.simulation_commands.v2"

def normalize(value: Any) -> Any:
    if isinstance(value, dict): return {str(k): normalize(value[k]) for k in sorted(value, key=str)}
    if isinstance(value, (list, tuple)): return [normalize(v) for v in value]
    if isinstance(value, float):
        rounded = round(value, 6)
        return int(rounded) if rounded.is_integer() else rounded
    return value

def encode(value: Any) -> str:
    return json.dumps(normalize(value), sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def sha256(value: Any) -> str:
    return hashlib.sha256(encode(value).encode("utf-8")).hexdigest()

def projection(state) -> dict[str, Any]:
    return normalize({
        "schema_version": 2, "seed": state.seed, "world_tick": state.time,
        "resources": {"materials": state.materials}, "inventory": dict(state.inventory),
        "stocks": {"repair_drones": state.repair_drone_stock, "turret_ammo": state.turret_ammo_stock},
        "policies": {"repair_intensity": state.policies.repair_intensity, "defense_readiness": state.policies.defense_readiness, "surveillance_coverage": state.policies.surveillance_coverage, "fabrication_allocation": dict(state.fab_allocation), "sector_fortification": {k.replace("DEFENSE GRID", "DEFENSE_GRID"): v for k, v in state.sector_fort_levels.items()}, "transit_fortification": dict(state.transit_fort_levels)},
        "power_load": state.power_load,
        "logistics": {"throughput": state.logistics_throughput, "load": state.logistics_load, "pressure": state.logistics_pressure, "multiplier": state.logistics_multiplier},
    })

def apply_command(state, command: dict[str, Any]) -> None:
    kind, payload = command["kind"], command.get("payload", {})
    if kind == "set_policy":
        for key in ("repair_intensity", "defense_readiness", "surveillance_coverage"):
            if key in payload: setattr(state.policies, key, clamp_policy_level(payload[key]))
    elif kind == "set_fabrication_allocation":
        category = str(payload["category"]).upper()
        if category not in FAB_CATEGORIES: raise ValueError(f"unknown fabrication category: {category}")
        state.fab_allocation[category] = clamp_policy_level(payload["level"])
    elif kind == "set_sector_fortification":
        sector = str(payload["sector_id"]).replace("DEFENSE_GRID", "DEFENSE GRID")
        if sector not in state.sector_fort_levels: raise ValueError(f"unknown sector: {sector}")
        state.sector_fort_levels[sector] = clamp_policy_level(payload["level"])
    elif kind == "set_transit_fortification":
        transit = str(payload["transit_id"])
        if transit not in state.transit_fort_levels: raise ValueError(f"unknown transit: {transit}")
        state.transit_fort_levels[transit] = clamp_policy_level(payload["level"])
    elif kind == "add_materials": state.materials += max(0, int(payload["amount"]))
    elif kind == "spend_materials":
        amount = int(payload["amount"])
        if amount < 0 or state.materials < amount: raise ValueError("insufficient materials")
        state.materials -= amount
    else: raise ValueError(f"unsupported parity command: {kind}")
