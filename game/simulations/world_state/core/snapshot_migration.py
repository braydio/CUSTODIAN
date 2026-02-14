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

    return migrated

