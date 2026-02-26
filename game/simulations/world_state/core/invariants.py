"""Centralized runtime invariants for world-state sessions."""

from __future__ import annotations

from .config import (
    COMMAND_CENTER_LOCATION,
    FIELD_ACTION_IDLE,
    FIELD_ACTION_MOVING,
    FIELD_ACTION_REPAIRING,
    FIELD_ACTION_STABILIZING,
)
from .defense import ALLOCATION_KEYS, normalize_doctrine
from .policies import FAB_CATEGORIES, POLICY_LEVEL_MAX, POLICY_LEVEL_MIN
from .relays import RELAY_STATUSES
from .structures import STRUCTURE_TYPES
from .tasks import task_type


def validate_state_invariants(state) -> None:
    if state.active_task and len(state.active_repairs) > 0:
        raise AssertionError("Active task and repair cannot run simultaneously.")

    if len(state.active_repairs) > 1:
        raise AssertionError("Phase A supports at most one active repair.")

    if state.active_task:
        active_type = task_type(state.active_task)
        if active_type == "MOVE" and state.field_action != FIELD_ACTION_MOVING:
            raise AssertionError("field_action mismatch for active movement task.")
        if active_type == "RELAY" and state.field_action != FIELD_ACTION_STABILIZING:
            raise AssertionError("field_action mismatch for active relay task.")

    if state.active_repairs and state.field_action not in {
        FIELD_ACTION_REPAIRING,
        FIELD_ACTION_IDLE,
        FIELD_ACTION_STABILIZING,
    }:
        raise AssertionError("field_action mismatch for active repair.")

    if state.in_command_mode() and state.player_location != COMMAND_CENTER_LOCATION:
        raise AssertionError("COMMAND mode must be located at COMMAND.")

    if normalize_doctrine(state.defense_doctrine) is None:
        raise AssertionError("Invalid defense_doctrine value.")

    allocation_values = [float(state.defense_allocation.get(key, 0.0)) for key in ALLOCATION_KEYS]
    if any(value <= 0.0 for value in allocation_values):
        raise AssertionError("Defense allocation weights must be positive.")
    allocation_mean = sum(allocation_values) / len(ALLOCATION_KEYS)
    if abs(allocation_mean - 1.0) > 0.05:
        raise AssertionError("Defense allocation weights must normalize to mean 1.0.")

    policy_values = (
        int(state.policies.repair_intensity),
        int(state.policies.defense_readiness),
        int(state.policies.surveillance_coverage),
    )
    if any(value < POLICY_LEVEL_MIN or value > POLICY_LEVEL_MAX for value in policy_values):
        raise AssertionError("Policy levels must stay in [0,4].")

    for category in FAB_CATEGORIES:
        level = int(state.fab_allocation.get(category, -1))
        if level < POLICY_LEVEL_MIN or level > POLICY_LEVEL_MAX:
            raise AssertionError("Fabrication allocation levels must stay in [0,4].")
        if float(state.ambient_fab_progress.get(category, -1.0)) < 0.0:
            raise AssertionError("Ambient fabrication progress must be non-negative.")

    for sector_name in state.sectors:
        fort_level = int(state.sector_fort_levels.get(sector_name, -1))
        if fort_level < POLICY_LEVEL_MIN or fort_level > POLICY_LEVEL_MAX:
            raise AssertionError("Fortification levels must stay in [0,4].")
    for node in ("T_NORTH", "T_SOUTH"):
        fort_level = int(state.transit_fort_levels.get(node, -1))
        if fort_level < POLICY_LEVEL_MIN or fort_level > POLICY_LEVEL_MAX:
            raise AssertionError("Transit fortification levels must stay in [0,4].")

    for key in ("SCRAP", "COMPONENTS", "ASSEMBLIES", "MODULES"):
        if int(state.inventory.get(key, -1)) < 0:
            raise AssertionError("Inventory values must be non-negative.")

    if int(state.repair_drone_stock) < 0 or int(state.turret_ammo_stock) < 0:
        raise AssertionError("Stock values must be non-negative.")

    if int(state.relay_packets_pending) < 0:
        raise AssertionError("Relay packet count must be non-negative.")
    for relay in state.relay_nodes.values():
        status = str(relay.get("status", "UNKNOWN")).upper()
        if status not in RELAY_STATUSES:
            raise AssertionError("Relay status must be a known value.")

    if float(state.logistics_throughput) <= 0.0:
        raise AssertionError("Logistics throughput must be positive.")
    if float(state.logistics_load) < 0.0:
        raise AssertionError("Logistics load must be non-negative.")
    if float(state.logistics_multiplier) <= 0.0:
        raise AssertionError("Logistics multiplier must be positive.")
    if str(getattr(state, "drone_perimeter_repair_policy", "AUTO")).upper() not in {"AUTO", "OFF"}:
        raise AssertionError("drone_perimeter_repair_policy must be AUTO or OFF.")

    max_instance_id = 0
    seen_positions: set[tuple[str, tuple[int, int]]] = set()
    for sid, instance in state.structure_instances.items():
        if not instance.id or instance.id != sid:
            raise AssertionError("Structure-instance id mapping mismatch.")
        if instance.sector not in state.sector_grids:
            raise AssertionError("Structure instance references unknown sector grid.")
        if instance.type not in STRUCTURE_TYPES:
            raise AssertionError("Structure instance type must exist in registry.")
        if instance.hp < 0 or instance.hp > instance.max_hp:
            raise AssertionError("Structure instance HP must be bounded by max_hp.")

        grid = state.sector_grids[instance.sector]
        x, y = instance.position
        if not grid.in_bounds(x, y):
            raise AssertionError("Structure instance out of grid bounds.")
        key = (instance.sector, instance.position)
        if key in seen_positions:
            raise AssertionError("Duplicate structure instance grid position detected.")
        seen_positions.add(key)

        cell = grid.cells[(x, y)]
        if cell.structure_id != sid:
            raise AssertionError("Grid cell id does not match structure instance.")
        if cell.blocked != bool(STRUCTURE_TYPES[instance.type].get("blocks", False)):
            raise AssertionError("Grid blocked flag does not match structure type.")

        if sid.startswith("S") and sid[1:].isdigit():
            max_instance_id = max(max_instance_id, int(sid[1:]))

    for sector_name, grid in state.sector_grids.items():
        if sector_name not in state.sectors:
            raise AssertionError("Grid exists for unknown sector.")
        for (x, y), cell in grid.cells.items():
            if not grid.in_bounds(x, y):
                raise AssertionError("Grid cell key is out of bounds.")
            if cell.structure_id is None:
                continue
            instance = state.structure_instances.get(cell.structure_id)
            if instance is None:
                raise AssertionError("Grid references missing structure instance.")
            if instance.sector != sector_name or instance.position != (x, y):
                raise AssertionError("Grid/instance sector-position mismatch.")

    if int(state.next_structure_id) <= max_instance_id:
        raise AssertionError("next_structure_id must be greater than all allocated IDs.")
