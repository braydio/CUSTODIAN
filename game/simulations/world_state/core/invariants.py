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

    for sector_name in state.sectors:
        fort_level = int(state.sector_fort_levels.get(sector_name, -1))
        if fort_level < POLICY_LEVEL_MIN or fort_level > POLICY_LEVEL_MAX:
            raise AssertionError("Fortification levels must stay in [0,4].")

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
