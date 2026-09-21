#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from live_bridge.art_agent_relay import LiveArtAgentRelay, RELAY_SCHEMA
from live_bridge.protocol import Message, MessageType


class State:
    active_document_path: str | None = None
    client_session_id = "client-a"
    document_revision = 4


class Server:
    def __init__(self):
        self.state = State()
        self.calls = []

    async def request_command(self, message_type, payload, **_kwargs):
        self.calls.append((message_type, payload))
        if message_type is MessageType.ART_AGENT_UNDO:
            return Message("bridge", 8, MessageType.COMMAND_RESULT, {
                "operation": "art_agent_undo",
                "ok": True,
                "revision_before": self.state.document_revision,
                "revision_after": self.state.document_revision + 1,
            }, cause=1)
        return Message("bridge", 8, MessageType.COMMAND_RESULT, {
            "operation": "art_agent_execute",
            "art_agent_response": {
                "schema": "custodian.operator_art_agent.response.v2",
                "request_id": payload["request"]["request_id"],
                "operation_key": payload["request"]["operation_key"],
                "ok": True, "changed": False, "operation": "inspect", "warnings": [],
            },
        }, cause=1)


class Bridge:
    def __init__(self): self.server = Server()


def main():
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        art = root / ".ai/operator_art_agent/p/g/a/e/session"
        workspace = root / ".ai/operator_animation_workbench/p/g/a/e"
        art.mkdir(parents=True)
        workspace.mkdir(parents=True)
        workbench = workspace / "workbench.aseprite"
        manifest_path = workspace / "workbench.json"
        capability_path = art / "capability.json"
        request_path = art / "requests/read_001.json"
        response_path = art / "responses/read_001.json"
        request_path.parent.mkdir(); response_path.parent.mkdir()
        workbench.write_bytes(b"fixture")
        manifest = {"schema": "custodian.operator_animation_workbench.v2", "context": {"fingerprint": "fp"}, "canvas": {"width": 8, "height": 8}, "layers": []}
        manifest_path.write_text(json.dumps(manifest))
        capability = {"schema": "custodian.operator_art_agent.capability.v1", "session_id": "s", "nonce": "n", "context_fingerprint": "fp", "workbench_manifest": str(manifest_path), "workbench": str(workbench), "capability_path": str(capability_path), "preview_root": str(workspace / "previews")}
        capability_path.write_text(json.dumps(capability))
        request = {"schema": "custodian.operator_art_agent.request.v2", "request_id": "read_001", "operation_key": "key", "session_id": "s", "nonce": "n", "capability": str(capability_path), "manifest": str(manifest_path), "workbench": str(workbench), "operation": {"type": "inspect"}}
        request_path.write_text(json.dumps(request))
        bridge = Bridge()
        bridge.server.state.active_document_path = str(workbench.resolve())
        relay = LiveArtAgentRelay(root, bridge, port=0)
        executed = asyncio.run(relay.execute(request_path, response_path))
        assert executed["schema"] == RELAY_SCHEMA and executed["status"] == "executed"
        assert bridge.server.calls[0][0] is MessageType.ART_AGENT_EXECUTE
        assert bridge.server.calls[0][1]["allow_mutation"] is False

        request["operation"] = {"type": "paint_pixels"}
        request_path.write_text(json.dumps(request))
        mutation = asyncio.run(relay.execute(request_path, response_path))
        assert mutation["status"] == "executed"
        assert bridge.server.calls[-1][1]["allow_mutation"] is True

        request["live_guard"] = {"client_session_id": "client-a", "expected_revision": 3}
        request_path.write_text(json.dumps(request))
        stale = asyncio.run(relay.execute(request_path, response_path))
        assert stale["status"] == "stale_live"
        assert bridge.server.calls[-1][1]["allow_mutation"] is True

        request["live_guard"] = {"client_session_id": "client-a", "expected_revision": 4}
        request["operation"] = {"type": "paint_pixels"}
        request_path.write_text(json.dumps(request))
        undone = asyncio.run(relay.undo(request_path, response_path, operation_key="key", client_session_id="client-a", revision=4))
        assert undone["status"] == "executed"
        assert bridge.server.calls[-1][0] is MessageType.ART_AGENT_UNDO

        bridge.server.state.active_document_path = str((workspace / "other.aseprite").resolve())
        request["operation"] = {"type": "inspect"}
        request_path.write_text(json.dumps(request))
        unavailable = asyncio.run(relay.execute(request_path, response_path))
        assert unavailable["status"] == "unavailable"
        assert len(bridge.server.calls) == 3
    print("operator_art_agent_live_relay_smoke ok")


if __name__ == "__main__":
    main()
