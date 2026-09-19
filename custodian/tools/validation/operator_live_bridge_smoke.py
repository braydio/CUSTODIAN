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
        export_request = await controller.export_preview(workbench, 42)
        export_command = parse_message(await client.recv())
        expected_output = controller._live_preview_path(workbench)
        assert export_command.sequence == export_request
        assert export_command.type is MessageType.EXPORT_PREVIEW
        assert export_command.payload == {
            "document_path": str(workbench.resolve()),
            "output_path": str(expected_output),
            "revision": 42,
        }
        assert expected_output.parent == repo_root / ".ai/operator_animation_workbench/live"
        assert expected_output.name == controller._live_preview_path(workbench).name
        await client.send(envelope("controller-first", 4, "command.result", {
            "ok": True, "operation": "export_preview",
            "document_path": str(workbench.resolve()),
            "output_path": str(expected_output), "revision": 42,
            "frames": 8, "frame_width": 96, "frame_height": 96,
            "modified": True,
        }, cause=export_request))
        exported = await asyncio.wait_for(controller.next_event(), timeout=0.2)
        assert exported.operation == "export_preview" and exported.ok is True
        assert exported.revision == 42 and exported.frame_count == 8
        assert exported.frame_width == 96 and exported.frame_height == 96
        assert exported.output_path == str(expected_output) and not exported.user_originated
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
    export = parse_message(Message("bridge", 2, MessageType.EXPORT_PREVIEW, {
        "document_path": str(valid_workbench),
        "output_path": str(valid_preview), "revision": 42,
    }).to_dict())
    policy.validate_message_paths(export)
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
    invalid_exports = (
        {"output_path": str(valid_preview), "revision": 1},
        {"document_path": str(valid_workbench), "revision": 1},
        {"document_path": str(valid_workbench), "output_path": str(valid_preview)},
        {"document_path": str(valid_workbench), "output_path": str(valid_preview), "revision": -1},
        {"document_path": str(repo_root / "canonical.aseprite"), "output_path": str(valid_preview), "revision": 1},
        {"document_path": str(valid_workbench), "output_path": str(repo_root / "preview.png"), "revision": 1},
    )
    for payload in invalid_exports:
        try:
            message = parse_message(Message("bridge", 2, MessageType.EXPORT_PREVIEW, payload).to_dict())
            policy.validate_message_paths(message)
        except ProtocolError:
            pass
        else:
            raise AssertionError(f"unsafe export-preview payload accepted: {payload}")


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
    preview_source = (extension / "live_preview.lua").read_text()
    for capability in REQUIRED_CAPABILITIES:
        assert f'"{capability}"' in protocol_source
    for command in ("open_workbench", "select_frame", "export_preview", "save"):
        assert f'"command.{command}"' in protocol_source
    assert protocol_source.count('["command.select_frame"] = true') == 1
    assert protocol_source.count('["command.export_preview"] = true') == 1
    assert 'error = "unsupported in Packet 4"' in protocol_source
    assert 'Protocol.DEFAULT_URL = "ws://127.0.0.1:32147"' in protocol_source
    assert 'app.events:on("sitechange"' in main_source
    assert 'sprite.events:on("change"' in main_source
    assert 'sprite.events:on("filenamechange"' in main_source
    assert "minreconnectwait = 1.0" in main_source and "maxreconnectwait = 5.0" in main_source
    assert "app.frame = frame" in main_source and "app.layer =" not in main_source
    assert 'message.type == "command.select_frame"' in main_source
    assert 'message.type == "command.export_preview"' in main_source
    assert "manifest.layers" in preview_source and "strip:saveAs(output_path)" in preview_source
    for forbidden in (
        "os.execute", "io.popen", "app.open", "app.command.Save",
        "sprite:saveAs", "sprite:saveCopyAs",
    ):
        assert forbidden not in main_source and forbidden not in preview_source

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
assert(refusal:find('unsupported in Packet 4', 1, true))
assert(client.sequence == 2)
for index, commandType in ipairs({{"command.save"}}) do
  local deferred = protocol.decode_server_message(client,
    '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":' .. tostring(index + 2) .. ',"type":"' .. commandType .. '","cause":null,"payload":{{}}}}')
  assert(deferred ~= nil)
  assert(protocol.passive_response(client, deferred):find('unsupported in Packet 4', 1, true))
end
local selectFrame = protocol.decode_server_message(client,
  '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":4,"type":"command.select_frame","cause":null,"payload":{{"frame":5,"document_path":"/tmp/workbench.aseprite"}}}}')
assert(selectFrame ~= nil and protocol.passive_response(client, selectFrame) == nil)
local exportPreview = protocol.decode_server_message(client,
  '{{"schema":"custodian.operator_live_bridge.message.v1","session_id":"bridge-session","sequence":5,"type":"command.export_preview","cause":null,"payload":{{"document_path":"/tmp/workbench.aseprite","output_path":"/tmp/live.png","revision":1}}}}')
assert(exportPreview ~= nil and protocol.passive_response(client, exportPreview) == nil)
''')
            result = subprocess.run([aseprite, "-b", "--script", str(script)],
                                    capture_output=True, text=True, timeout=15)
            assert result.returncode == 0, result.stdout + result.stderr

            fixture = Path(temporary) / "workbench"
            fixture.mkdir()
            workbench = fixture / "workbench.aseprite"
            baseline = fixture / "baseline.aseprite"
            output = fixture / "live.png"
            canonical_sentinel = Path(temporary) / "canonical.png"
            runtime_sentinel = Path(temporary) / "runtime.png"
            canonical_sentinel.write_bytes(b"canonical-render-sentinel")
            runtime_sentinel.write_bytes(b"runtime-render-sentinel")
            production_before = (canonical_sentinel.read_bytes(), runtime_sentinel.read_bytes())
            (fixture / "workbench.json").write_text(json.dumps({
                "timeline": {"document_frames": 2},
                "canvas": {"width": 4, "height": 3},
                "layers": [
                    {"aseprite_layer_name": "lower_body"},
                    {"aseprite_layer_name": "upper_body"},
                ],
            }))
            render_script = Path(temporary) / "live_render_contract.lua"
            render_module = json.dumps(str(extension / "live_preview.lua"))
            render_script.write_text(f'''local live = dofile({render_module})
local sprite = Sprite(4, 3, ColorMode.RGB)
local lower = sprite.layers[1]
lower.name = "lower_body"
local upper = sprite:newLayer()
upper.name = "upper_body"
local reference = sprite:newLayer()
reference.name = "__REFERENCE_TEST"
sprite:newEmptyFrame()
local clear1 = Image(4, 3, ColorMode.RGB)
local clear2 = Image(4, 3, ColorMode.RGB)
local upper1 = Image(4, 3, ColorMode.RGB)
local upper2 = Image(4, 3, ColorMode.RGB)
local ref1 = Image(4, 3, ColorMode.RGB)
local ref2 = Image(4, 3, ColorMode.RGB)
upper1:drawPixel(0, 0, app.pixelColor.rgba(0, 255, 0, 255))
upper2:drawPixel(0, 0, app.pixelColor.rgba(0, 255, 0, 255))
ref1:drawPixel(3, 2, app.pixelColor.rgba(0, 0, 255, 255))
ref2:drawPixel(3, 2, app.pixelColor.rgba(0, 0, 255, 255))
sprite:newCel(lower, 1, clear1, Point(0, 0))
sprite:newCel(lower, 2, clear2, Point(0, 0))
sprite:newCel(upper, 1, upper1, Point(0, 0))
sprite:newCel(upper, 2, upper2, Point(0, 0))
sprite:newCel(reference, 1, ref1, Point(0, 0))
sprite:newCel(reference, 2, ref2, Point(0, 0))
sprite:saveAs({json.dumps(str(workbench))})
local source = assert(io.open({json.dumps(str(workbench))}, "rb"))
local bytes = source:read("*a")
source:close()
local copy = assert(io.open({json.dumps(str(baseline))}, "wb"))
copy:write(bytes)
copy:close()
local changed = lower:cel(2).image:clone()
changed:drawPixel(1, 1, app.pixelColor.rgba(255, 0, 0, 255))
app.transaction(function() lower:cel(2).image = changed end)
assert(sprite.isModified)
local modified_before = sprite.isModified
local manifest = live.read_json({json.dumps(str(fixture / 'workbench.json'))})
local result = live.render(sprite, manifest, {json.dumps(str(output))})
assert(result.frames == 2 and result.frame_width == 4 and result.frame_height == 3)
assert(sprite.isModified == modified_before)
''')
            rendered = subprocess.run(
                [aseprite, "-b", "--script", str(render_script)],
                capture_output=True, text=True, timeout=15,
            )
            assert rendered.returncode == 0, rendered.stdout + rendered.stderr
            assert output.exists() and workbench.read_bytes() == baseline.read_bytes()
            assert production_before == (canonical_sentinel.read_bytes(), runtime_sentinel.read_bytes())
            from PIL import Image
            with Image.open(output) as image:
                rgba = image.convert("RGBA")
                assert rgba.size == (8, 3)
                assert rgba.getpixel((5, 1)) == (255, 0, 0, 255)
                assert rgba.getpixel((3, 2))[3] == 0


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
    print("PASS operator_live_bridge_smoke: Packet 4 export contract, deterministic path confinement, immediate result projection, detached manifest-filtered unsaved Aseprite render, dirty/workbench preservation, reconnect, production immutability")


if __name__ == "__main__":
    main()
