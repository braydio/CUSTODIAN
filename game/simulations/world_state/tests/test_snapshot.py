"""Tests for world-state snapshot contract."""

from game.simulations.world_state.core.state import GameState


def test_snapshot_shape_and_defaults() -> None:
    """Snapshot should include canonical fields and sector statuses."""

    state = GameState()
    snapshot = state.snapshot()

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

    sectors = snapshot["sectors"]
    assert len(sectors) > 0
    assert all("id" in sector for sector in sectors)
    assert all("name" in sector for sector in sectors)
    assert all("status" in sector for sector in sectors)
    assert all(sector["status"] == "STABLE" for sector in sectors)
