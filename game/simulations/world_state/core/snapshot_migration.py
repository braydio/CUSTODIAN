"""Snapshot version migration helpers."""

from __future__ import annotations


def migrate_snapshot(snapshot: dict) -> dict:
    version = int(snapshot.get("snapshot_version", 1))
    migrated = dict(snapshot)

    if version < 2:
        migrated.setdefault("player_mode", "COMMAND")
        migrated.setdefault("field_action", "IDLE")
        migrated.setdefault("active_task", None)
        migrated["snapshot_version"] = 2

    migrated.setdefault("transit_fort_levels", {"T_NORTH": 0, "T_SOUTH": 0})

    if version < 3:
        migrated.setdefault("next_structure_id", 1)
        migrated.setdefault("sector_grids", None)
        migrated.setdefault("structure_instances", {})
        migrated["snapshot_version"] = 3

    if version < 4:
        migrated.setdefault("drone_perimeter_repair_policy", "AUTO")
        migrated["snapshot_version"] = 4

    if version < 5:
        migrated.setdefault("run_fingerprint", None)
        migrated["snapshot_version"] = 5

    relays = migrated.get("relays")
    if not isinstance(relays, dict):
        migrated["relays"] = {
            "nodes": {},
            "packets_pending": 0,
            "knowledge_index": {"RELAY_RECOVERY": 0},
            "last_sync_time": None,
            "benefits": {},
            "dormancy_pressure": 0,
        }
    else:
        relays.setdefault("nodes", {})
        relays.setdefault("packets_pending", 0)
        relays.setdefault("knowledge_index", {"RELAY_RECOVERY": 0})
        relays.setdefault("last_sync_time", None)
        relays.setdefault("benefits", {})
        relays.setdefault("dormancy_pressure", 0)

    return migrated
