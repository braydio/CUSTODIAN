"""Tests for world-state snapshot contract."""

from game.simulations.world_state.core.state import GameState


def test_snapshot_shape_and_defaults() -> None:
    """Snapshot should include canonical fields and sector statuses."""

    state = GameState()
    snapshot = state.snapshot()

    assert snapshot["snapshot_version"] == 7
    assert snapshot["time"] == 0
    assert snapshot["threat"] == "LOW"
    assert snapshot["assault"] == "NONE"
    assert snapshot["failed"] is False
    assert snapshot["focused_sector"] is None
    assert snapshot["hardened"] is False
    assert snapshot["archive_losses"] == 0
    assert snapshot["archive_limit"] > 0
    assert snapshot["player_mode"] == "COMMAND"
    assert snapshot["player_location"] == "COMMAND"
    assert snapshot["field_action"] == "IDLE"
    assert snapshot["active_task"] is None
    assert snapshot["dev_mode"] is False
    assert snapshot["transit_fort_levels"] == {"T_NORTH": 0, "T_SOUTH": 0}
    assert snapshot["relays"]["dormancy_pressure"] == 0
    assert snapshot["relays"]["benefits"] == {}
    assert "run_fingerprint" in snapshot
    fp = snapshot["run_fingerprint"]
    assert fp["schema_version"] == 1
    assert fp["seed"] == state.seed
    assert fp["text_seed"] == state.text_seed
    assert fp["topology_profile_id"] == snapshot["topology_profile"]["profile_id"]
    assert fp["economy_profile_id"] == "BASELINE_STATIC"
    assert len(fp["event_catalog_hash"]) == 16
    assert len(fp["faction_profile_hash"]) == 16
    assert len(fp["fingerprint_hash"]) == 16
    assert "topology_profile" in snapshot
    assert "profile_id" in snapshot["topology_profile"]
    assert "summary" in snapshot["topology_profile"]
    assert "event_context" in snapshot
    assert snapshot["event_context"]["recent_events"] == []

    sectors = snapshot["sectors"]
    assert len(sectors) > 0
    assert all("id" in sector for sector in sectors)
    assert all("name" in sector for sector in sectors)
    assert all("status" in sector for sector in sectors)
    assert all(sector["status"] == "STABLE" for sector in sectors)


def test_run_fingerprint_ignores_runtime_counters() -> None:
    state = GameState(seed=777)
    before = state.snapshot()["run_fingerprint"]
    state.time = 99
    state.materials += 5
    state.ambient_threat = 3.2
    after = state.snapshot()["run_fingerprint"]
    assert before == after
