#!/usr/bin/env python3
"""In-process fake-client smoke for the Operator Live Bridge foundation."""
from __future__ import annotations

import asyncio
import hashlib
import json
from pathlib import Path
import sys
import tempfile
from uuid import uuid4

OPERATOR_ROOT = Path(__file__).resolve().parents[1] / "operator"
sys.path.insert(0, str(OPERATOR_ROOT))

from live_bridge.protocol import (  # noqa: E402
    MESSAGE_SCHEMA, BridgePathPolicy, Message, MessageType, ProtocolError,
    REQUIRED_CAPABILITIES, parse_message,
)
from live_bridge.server import LiveBridgeServer  # noqa: E402
from live_bridge.state import ConnectionState  # noqa: E402


def envelope(session: str, sequence: int, kind: str, payload: dict, cause: int | None = None) -> str:
    return json.dumps({
        "schema": MESSAGE_SCHEMA, "session_id": session, "sequence": sequence,
        "type": kind, "cause": cause, "payload": payload,
    })


def hello(session: str, sequence: int = 1, capabilities: list[str] | None = None) -> str:
    return envelope(session, sequence, "client.hello", {
        "aseprite_version": "test-version",
        "api_version": "test-api",
        "capabilities": sorted(REQUIRED_CAPABILITIES if capabilities is None else capabilities),
        "editor_state": {"frame": 2, "layer": "upper_body", "modified": False, "revision": 7},
    })


async def wait_for(predicate, label: str) -> None:
    for _ in range(100):
        if predicate():
            return
        await asyncio.sleep(0.01)
    raise AssertionError(f"timed out waiting for {label}")


async def rejected(uri: str, first_message: str) -> None:
    from websockets.asyncio.client import connect
    from websockets.exceptions import ConnectionClosed

    async with connect(uri) as client:
        await client.send(first_message)
        try:
            await client.recv()
        except ConnectionClosed as exc:
            assert exc.code == 1008, exc
        else:
            raise AssertionError("invalid client was not rejected")


async def exercise_server(repo_root: Path) -> None:
    from websockets.asyncio.client import connect

    canonical = repo_root / "custodian/content/sprites/operator/source/animations/canonical.png"
    canonical.parent.mkdir(parents=True)
    canonical.write_bytes(b"canonical-operator-sentinel")
    before = hashlib.sha256(canonical.read_bytes()).hexdigest()

    server = LiveBridgeServer(repo_root, port=0)
    await server.start()
    assert server.listening_port and server.HOST == "127.0.0.1"
    uri = f"ws://127.0.0.1:{server.listening_port}"

    bad_schema = json.loads(hello("bad-schema"))
    bad_schema["schema"] = "custodian.operator_live_bridge.message.v999"
    await rejected(uri, json.dumps(bad_schema))
    await rejected(uri, hello("missing-capability", capabilities=["websocket"]))

    first_session = uuid4().hex
    async with connect(uri) as client:
        await client.send(hello(first_session))
        response = parse_message(await client.recv())
        assert response.type is MessageType.SERVER_HELLO and response.cause == 1
        assert server.state.connection is ConnectionState.CONNECTED
        assert server.state.aseprite_version == "test-version"
        assert server.state.api_version == "test-api"
        assert server.state.active_frame == 2 and server.state.document_revision == 7

        await client.send(envelope(first_session, 2, "editor.state", {
            "document_path": ".ai/operator_animation_workbench/melee/walk/e/workbench.aseprite",
            "sprite_id": "sprite-1", "frame": 4, "layer": "lower_body",
            "modified": True, "revision": 8,
        }))
        await wait_for(lambda: server.state.active_frame == 4, "editor.state")
        assert server.state.active_layer == "lower_body" and server.state.document_modified is True

        await client.send(envelope(first_session, 3, "document.changed", {"modified": True}))
        await wait_for(lambda: server.state.document_revision == 9, "implicit revision")
        await client.send(envelope(first_session, 4, "document.changed", {"revision": 12, "modified": True}))
        await wait_for(lambda: server.state.document_revision == 12, "explicit revision")

        request = await server.send_command(MessageType.SELECT_FRAME, {"frame": 5})
        command = parse_message(await client.recv())
        assert command.sequence == request and command.type is MessageType.SELECT_FRAME
        assert request in server.state.pending_commands
        await client.send(envelope(first_session, 5, "editor.site_changed", {"frame": 5}, cause=request))
        await wait_for(lambda: server.state.last_acknowledged_command == request, "causal event")
        assert server.state.last_event_user_originated is False
        await client.send(envelope(first_session, 6, "command.result", {"ok": True}, cause=request))
        await wait_for(lambda: server.state.last_received_sequence == 6, "causal result")
        assert server.state.last_event_user_originated is False
        await client.send(envelope(first_session, 7, "editor.site_changed", {"frame": 6}))
        await wait_for(lambda: server.state.last_received_sequence == 7, "user event")
        assert server.state.last_event_user_originated is True

    await wait_for(lambda: server.state.connection is ConnectionState.DISCONNECTED, "disconnect")
    assert server.state.active_frame == 4 and server.state.document_revision == 12

    second_session = uuid4().hex
    async with connect(uri) as client:
        await client.send(hello(second_session))
        await client.recv()
        assert server.state.connection is ConnectionState.CONNECTED
        assert server.state.client_session_id == second_session
    await server.stop()
    assert server.listening_port is None and server.state.connection is ConnectionState.DISCONNECTED
    assert hashlib.sha256(canonical.read_bytes()).hexdigest() == before


def path_policy_smoke(repo_root: Path) -> None:
    policy = BridgePathPolicy(repo_root)
    valid_workbench = policy.validate_workbench(
        ".ai/operator_animation_workbench/unarmed/locomotion/walk_01/e/workbench.aseprite"
    )
    valid_preview = policy.validate_preview(
        ".ai/operator_animation_workbench/live/revision_83.png"
    )
    assert valid_workbench.suffix == ".aseprite" and valid_preview.suffix == ".png"
    invalid = [
        (policy.validate_workbench, "custodian/content/sprites/operator/source/canonical.aseprite"),
        (policy.validate_workbench, ".ai/operator_animation_workbench/../../escape.aseprite"),
        (policy.validate_preview, ".ai/operator_animation_workbench/not-live/preview.png"),
        (policy.validate_preview, ".ai/operator_animation_workbench/live/preview.aseprite"),
    ]
    for validator, path in invalid:
        try:
            validator(path)
        except ProtocolError:
            pass
        else:
            raise AssertionError(f"unsafe path accepted: {path}")


def main() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        repo_root = Path(temporary)
        path_policy_smoke(repo_root)
        asyncio.run(exercise_server(repo_root))
    print("PASS operator_live_bridge_smoke: loopback lifecycle, protocol, state, causality, reconnect, path confinement, production immutability")


if __name__ == "__main__":
    main()
