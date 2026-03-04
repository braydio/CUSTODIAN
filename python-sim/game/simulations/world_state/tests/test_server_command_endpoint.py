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


def test_procgen_report_requires_dev_mode() -> None:
    client = server.app.test_client()
    server.command_state.dev_mode = False

    response = client.get("/procgen_report")

    assert response.status_code == 403
    assert response.get_json() == {"ok": False, "error": "DEV MODE REQUIRED"}


def test_procgen_report_returns_fingerprint_in_dev_mode() -> None:
    client = server.app.test_client()
    server.command_state.dev_mode = True

    response = client.get("/procgen_report")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["ok"] is True
    report = payload["procgen_report"]
    assert "fingerprint_hash" in report
    assert len(report["fingerprint_hash"]) == 16
    assert any(item["name"] == "doctrine_profile_id" for item in report["components"])
