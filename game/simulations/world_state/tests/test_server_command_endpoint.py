"""Tests for the world-state command API endpoint."""

import pytest

pytest.importorskip("flask")

from game.simulations.world_state import server


def test_command_endpoint_executes_command() -> None:
    """POST /command returns a CommandResult payload."""

    client = server.app.test_client()
    response = client.post("/command", json={"command": "status"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload["ok"] is True
    assert "Time=" in payload["text"]


def test_command_endpoint_reports_unknown_command() -> None:
    """Unknown commands return ok=False without optional fields."""

    client = server.app.test_client()
    response = client.post("/command", json={"command": "nonesuch"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload == {"ok": False, "text": "Unknown command. Use 'help'."}


def test_command_endpoint_requires_command() -> None:
    """Missing command payload returns a 400 with ok=False."""

    client = server.app.test_client()
    response = client.post("/command", json={})

    assert response.status_code == 400

    payload = response.get_json()
    assert payload == {"ok": False, "text": "Command required."}
