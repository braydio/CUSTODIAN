"""Tests for the world-state command API endpoint."""

import pytest

pytest.importorskip("flask")

from game.simulations.world_state import server


def test_command_endpoint_executes_status_with_command_key() -> None:
    """POST /command should return canonical {ok, text, lines?} payload."""

    client = server.app.test_client()
    response = client.post("/command", json={"command": "status"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload["ok"] is True
    assert payload["text"].startswith("TIME: ")
    assert payload["lines"][0].startswith("TIME: ")


def test_command_endpoint_accepts_raw_as_fallback() -> None:
    """POST /command should accept legacy raw key for compatibility."""

    client = server.app.test_client()
    response = client.post("/command", json={"raw": "status"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload["ok"] is True
    assert payload["text"].startswith("TIME: ")


def test_command_endpoint_reports_unknown_command() -> None:
    """Unknown commands should return locked error text and detail line."""

    client = server.app.test_client()
    response = client.post("/command", json={"command": "nonesuch"})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload == {
        "ok": False,
        "text": "UNKNOWN COMMAND.",
        "lines": ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."],
    }


def test_command_endpoint_requires_command_string() -> None:
    """Invalid payloads should resolve to the unknown-command response."""

    client = server.app.test_client()
    response = client.post("/command", json={})

    assert response.status_code == 200

    payload = response.get_json()
    assert payload == {
        "ok": False,
        "text": "UNKNOWN COMMAND.",
        "lines": ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."],
    }
