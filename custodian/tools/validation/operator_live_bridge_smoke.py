#!/usr/bin/env python3
"""In-process fake-client smoke for the Operator Live Bridge foundation."""
from __future__ import annotations

import asyncio
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
from uuid import uuid4

OPERATOR_ROOT = Path(__file__).resolve().parents[1] / "operator"
sys.path.insert(0, str(OPERATOR_ROOT))

from live_bridge.protocol import (  # noqa: E402
    MESSAGE_SCHEMA, BridgePathPolicy, Message, MessageType, ProtocolError,
    REQUIRED_CAPABILITIES, parse_message,
)
from live_bridge.server import DEFAULT_HOST, DEFAULT_PORT, LiveBridgeServer  # noqa: E402
from live_bridge.state import ConnectionState  # noqa: E402
from ui.live_bridge_controller import (  # noqa: E402
    LiveBridgeController, LiveBridgeUIStatus,
)


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
    runtime = repo_root / "custodian/content/sprites/operator/runtime/animations/runtime.png"
    canonical.parent.mkdir(parents=True)
    runtime.parent.mkdir(parents=True)
    canonical.write_bytes(b"canonical-operator-sentinel")
    runtime.write_bytes(b"runtime-operator-sentinel")
    before = {
        path: hashlib.sha256(path.read_bytes()).hexdigest()
        for path in (canonical, runtime)
    }

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

        workbench = repo_root / ".ai/operator_animation_workbench/melee/walk/e/workbench.aseprite"
        request = await server.send_command(MessageType.SELECT_FRAME, {
            "frame": 5, "document_path": str(workbench),
        })
        command = parse_message(await client.recv())
        assert command.sequence == request and command.type is MessageType.SELECT_FRAME
        assert request in server.state.pending_commands
        await client.send(envelope(first_session, 5, "editor.site_changed", {"frame": 5}, cause=request))
        await wait_for(lambda: server.state.last_acknowledged_command == request, "causal event")
        assert server.state.last_event_user_originated is False
        await client.send(envelope(first_session, 6, "command.result", {"ok": True}, cause=request))
        await wait_for(lambda: server.state.last_received_sequence == 6, "causal result")
        assert server.state.last_event_user_originated is False
        await client.send(envelope(first_session, 7, "editor.site_changed", {
            "has_document": True, "frame": 6, "layer": "weapon",
            "layer_id": "12345678-1234-1234-1234-123456789abc",
        }))
        await wait_for(lambda: server.state.last_received_sequence == 7, "user event")
        assert server.state.last_event_user_originated is True
        assert server.state.active_frame == 6 and server.state.active_layer == "weapon"
        assert server.state.active_layer_id == "12345678-1234-1234-1234-123456789abc"

        await client.send(envelope(first_session, 8, "editor.site_changed", {
            "has_document": False, "revision": 12,
        }))
        await wait_for(lambda: server.state.last_received_sequence == 8, "closed document")
        assert server.state.active_document_path is None and server.state.active_frame is None

    await wait_for(lambda: server.state.connection is ConnectionState.DISCONNECTED, "disconnect")
    assert server.state.active_frame is None and server.state.document_revision == 12

    second_session = uuid4().hex
    async with connect(uri) as client:
        await client.send(hello(second_session))
        await client.recv()
        assert server.state.connection is ConnectionState.CONNECTED
        assert server.state.client_session_id == second_session
    await server.stop()
    assert server.listening_port is None and server.state.connection is ConnectionState.DISCONNECTED
    assert all(hashlib.sha256(path.read_bytes()).hexdigest() == digest for path, digest in before.items())


async def controller_lifecycle_smoke(repo_root: Path) -> None:
    from websockets.asyncio.client import connect

    controller = LiveBridgeController(repo_root, port=0)
    assert controller.snapshot().status is LiveBridgeUIStatus.STOPPED
    await controller.start()
    waiting = controller.snapshot()
    assert waiting.status is LiveBridgeUIStatus.WAITING
    assert waiting.host == "127.0.0.1" and controller.server.listening_port
    uri = f"ws://127.0.0.1:{controller.server.listening_port}"

    async with connect(uri) as client:
        await client.send(hello("controller-first"))
        await client.recv()
        hello_event = await asyncio.wait_for(controller.next_event(), timeout=0.2)
        assert hello_event.user_originated and hello_event.frame == 2
        await wait_for(
            lambda: controller.snapshot().status is LiveBridgeUIStatus.CONNECTED,
            "controller connected",
        )
        workbench = repo_root / ".ai/operator_animation_workbench/live/frame-test/workbench.aseprite"
        request = await controller.select_frame(workbench, 6)
        command = parse_message(await client.recv())
        assert command.sequence == request and command.payload == {
            "frame": 7, "document_path": str(workbench.resolve()),
        }
        await client.send(envelope("controller-first", 2, "editor.site_changed", {
            "document_path": str(workbench.resolve()), "frame": 7,
        }, cause=request))
        causal = await asyncio.wait_for(controller.next_event(), timeout=0.2)
        assert not causal.user_originated and causal.cause == request
        await client.send(envelope("controller-first", 3, "editor.site_changed", {
            "document_path": str(workbench.resolve()), "frame": 4,
        }))
        human = await asyncio.wait_for(controller.next_event(), timeout=0.2)
        assert human.user_originated and human.frame == 4 and human.cause is None
    await wait_for(
        lambda: controller.snapshot().status is LiveBridgeUIStatus.WAITING,
        "controller disconnected",
    )

    async with connect(uri) as client:
        await client.send(hello("controller-second"))
        await client.recv()
        await wait_for(
            lambda: controller.snapshot().status is LiveBridgeUIStatus.CONNECTED,
            "controller reconnected",
        )
    await controller.stop()
    assert controller.snapshot().status is LiveBridgeUIStatus.STOPPED
    assert controller.server.listening_port is None


async def controller_failure_smoke(repo_root: Path) -> None:
    class MissingDependencyServer(LiveBridgeServer):
        async def start(self) -> None:
            raise RuntimeError("optional websockets dependency unavailable")

    missing = LiveBridgeController(repo_root, server_factory=MissingDependencyServer)
    await missing.start()
    assert missing.snapshot().status is LiveBridgeUIStatus.UNAVAILABLE
    assert "dependency unavailable" in (missing.snapshot().error or "")
    await missing.stop()

    occupied = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    occupied.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    occupied.bind(("127.0.0.1", 0))
    occupied.listen(1)
    port = occupied.getsockname()[1]
    try:
        conflict = LiveBridgeController(repo_root, port=port)
        await conflict.start()
        snapshot = conflict.snapshot()
        assert snapshot.status is LiveBridgeUIStatus.UNAVAILABLE
        assert snapshot.port == port and conflict.server.listening_port is None
        await conflict.stop()
    finally:
        occupied.close()


def path_policy_smoke(repo_root: Path) -> None:
    policy = BridgePathPolicy(repo_root)
    valid_workbench = policy.validate_workbench(
        ".ai/operator_animation_workbench/unarmed/locomotion/walk_01/e/workbench.aseprite"
    )
    valid_preview = policy.validate_preview(
        ".ai/operator_animation_workbench/live/revision_83.png"
    )
    assert valid_workbench.suffix == ".aseprite" and valid_preview.suffix == ".png"
    select = parse_message(Message("bridge", 1, MessageType.SELECT_FRAME, {
        "frame": 1, "document_path": str(valid_workbench),
    }).to_dict())
    policy.validate_message_paths(select)
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
    for payload in (
        {"frame": 1},
        {"frame": 1, "document_path": "custodian/content/sprites/operator/source/canonical.aseprite"},
    ):
        try:
            message = parse_message(Message("bridge", 1, MessageType.SELECT_FRAME, payload).to_dict())
            policy.validate_message_paths(message)
        except ProtocolError:
            pass
        else:
            raise AssertionError(f"unsafe select-frame payload accepted: {payload}")


def stable_endpoint_smoke(repo_root: Path) -> None:
    server = LiveBridgeServer(repo_root)
    assert server.HOST == DEFAULT_HOST == "127.0.0.1"
    assert server.port == DEFAULT_PORT == 32147
    assert LiveBridgeServer(repo_root, port=0).port == 0


def aseprite_extension_smoke() -> None:
    extension = Path(__file__).resolve().parents[1] / "aseprite/operator_live_bridge"
    manifest = json.loads((extension / "package.json").read_text())
    assert manifest["name"] == "custodian-operator-live-bridge"
    assert manifest["contributes"]["scripts"] == [{"path": "./main.lua"}]

    protocol_source = (extension / "protocol.lua").read_text()
    main_source = (extension / "main.lua").read_text()
    for capability in REQUIRED_CAPABILITIES:
        assert f'"{capability}"' in protocol_source
    for command in ("open_workbench", "select_frame", "export_preview", "save"):
        assert f'"command.{command}"' in protocol_source
    assert protocol_source.count('["command.select_frame"] = true') == 1
    assert 'error = "unsupported in Packet 3B"' in protocol_source
    assert 'Protocol.DEFAULT_URL = "ws://127.0.0.1:32147"' in protocol_source
    assert 'app.events:on("sitechange"' in main_source
    assert 'sprite.events:on("change"' in main_source
    assert 'sprite.events:on("filenamechange"' in main_source
    assert "minreconnectwait = 1.0" in main_source and "maxreconnectwait = 5.0" in main_source
    assert "app.frame = frame" in main_source and "app.layer =" not in main_source
    assert 'message.type == "command.select_frame"' in main_source
    for forbidden in ("os.execute", "io.popen", "app.open", "app.command.Save"):
        assert forbidden not in main_source

    aseprite = shutil.which("aseprite")
    if aseprite:
        with tempfile.TemporaryDirectory() as temporary:
            script = Path(temporary) / "protocol_contract.lua"
            protocol_path = json.dumps(str(extension / "protocol.lua"))
            main_path = json.dumps(str(extension / "main.lua"))
            script.write_text(f'''local protocol = dofile({protocol_path})
assert(loadfile({main_path}))
local client = protocol.new_client("client-session")
local hello = protocol.encode_message(client, "client.hello", {{ ok=true }}, nil)
assert(hello:find('"cause":null', 1, true))
assert(client.sequence == 1)
local serverHello, err = protocol.decode_server_message(client,
  '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":1,"type":"server.hello","cause":1,"payload":{{"accepted":true}}}}')
assert(serverHello ~= nil and err == nil)
local command = protocol.decode_server_message(client,
  '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":2,"type":"command.open_workbench","cause":null,"payload":{{"path":"x"}}}}')
assert(command ~= nil)
local refusal = protocol.passive_response(client, command)
assert(refusal:find('unsupported in Packet 3B', 1, true))
assert(client.sequence == 2)
for index, commandType in ipairs({{"command.export_preview", "command.save"}}) do
  local deferred = protocol.decode_server_message(client,
    '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":' .. tostring(index + 2) .. ',"type":"' .. commandType .. '","cause":null,"payload":{{}}}}')
  assert(deferred ~= nil)
  assert(protocol.passive_response(client, deferred):find('unsupported in Packet 3B', 1, true))
end
local selectFrame = protocol.decode_server_message(client,
  '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":5,"type":"command.select_frame","cause":null,"payload":{{"frame":5,"document_path":"/tmp/workbench.aseprite"}}}}')
assert(selectFrame ~= nil and protocol.passive_response(client, selectFrame) == nil)
''')
            result = subprocess.run([aseprite, "-b", "--script", str(script)],
                                    capture_output=True, text=True, timeout=15)
            assert result.returncode == 0, result.stdout + result.stderr


def installer_smoke() -> None:
    installer = Path(__file__).resolve().parents[1] / "aseprite/install_operator_live_bridge.sh"
    with tempfile.TemporaryDirectory() as temporary:
        env = os.environ.copy()
        env["XDG_CONFIG_HOME"] = temporary
        subprocess.run([str(installer)], check=True, capture_output=True, text=True, env=env)
        target = Path(temporary) / "aseprite/extensions/custodian-operator-live-bridge"
        assert target.is_symlink()
        assert target.resolve() == installer.parent.joinpath("operator_live_bridge").resolve()
        subprocess.run([str(installer)], check=True, capture_output=True, text=True, env=env)


def main() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        repo_root = Path(temporary)
        path_policy_smoke(repo_root)
        stable_endpoint_smoke(repo_root)
        asyncio.run(exercise_server(repo_root))
        asyncio.run(controller_lifecycle_smoke(repo_root))
        asyncio.run(controller_failure_smoke(repo_root))
    aseprite_extension_smoke()
    installer_smoke()
    print("PASS operator_live_bridge_smoke: stable/ephemeral endpoint, lifecycle, select-frame conversion/path confinement, immediate causal/user event projection, Aseprite Packet 3B command contract, reconnect, install symlink, production immutability")


if __name__ == "__main__":
    main()
