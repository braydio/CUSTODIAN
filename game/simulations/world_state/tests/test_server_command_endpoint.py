"""Tests for the world-state command API endpoint."""

import pytest

pytest.importorskip("flask")

from game.simulations.world_state import server


def test_command_endpoint_executes_status() -> None:
    """POST /command should return Phase 1 {ok, lines} payload."""

    client = server.app.test_client()
    response = client.post("/command", json={"raw": "status"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload["ok"] is True
    assert payload["lines"][0].startswith("TIME: ")


def test_command_endpoint_reports_unknown_command() -> None:
    """Unknown commands should return locked error lines."""

    client = server.app.test_client()
    response = client.post("/command", json={"raw": "nonesuch"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload == {
        "ok": False,
        "lines": ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."],
    }


def test_command_endpoint_requires_raw_string() -> None:
    """Invalid payloads should resolve to the unknown-command response."""

    client = server.app.test_client()
    response = client.post("/command", json={})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload == {
        "ok": False,
        "lines": ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."],
    }
