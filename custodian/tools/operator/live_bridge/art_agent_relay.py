"""Narrow loopback relay for read-only live Art Agent operations."""
from __future__ import annotations

import asyncio
import json
from pathlib import Path
from typing import Any

from live_bridge.protocol import MessageType

RELAY_SCHEMA = "custodian.operator_art_agent.live_relay.v1"
DEFAULT_RELAY_HOST = "127.0.0.1"
DEFAULT_RELAY_PORT = 32148
REQUEST_SCHEMA = "custodian.operator_art_agent.request.v2"
CAPABILITY_SCHEMA = "custodian.operator_art_agent.capability.v1"
READ_TYPES = frozenset({"inspect", "render", "render_clean", "render_editor", "render_layer", "render_silhouette"})
MUTATION_TYPES = frozenset({"paint_pixels", "erase_pixels", "stroke", "copy_region", "move_region", "draft_shift_part", "draft_copy_part", "draft_replace_part", "draft_mirror_part", "discard_draft", "bake_draft", "clear_masked_region", "recolor_plan"})


class LiveArtAgentRelay:
    HOST = DEFAULT_RELAY_HOST

    def __init__(self, repo_root: Path, bridge, *, port: int = DEFAULT_RELAY_PORT) -> None:
        self.repo_root = Path(repo_root).resolve()
        self.bridge = bridge
        self.port = port
        self.art_root = (self.repo_root / ".ai/operator_art_agent").resolve()
        self.workspace_root = (self.repo_root / ".ai/operator_animation_workbench").resolve()
        self._server: asyncio.AbstractServer | None = None

    @property
    def available(self) -> bool:
        return self._server is not None

    async def start(self) -> None:
        if self._server is None:
            self._server = await asyncio.start_server(self._handle_client, self.HOST, self.port, limit=64 * 1024)

    async def stop(self) -> None:
        if self._server is not None:
            self._server.close()
            await self._server.wait_closed()
            self._server = None

    def _under(self, root: Path, raw: str | Path, label: str) -> Path:
        path = Path(raw).resolve()
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise ValueError(f"{label} outside authorized root") from exc
        return path

    def _validate_request(self, request_path: Path, response_path: Path) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
        request_path = self._under(self.art_root, request_path, "request")
        response_path = self._under(self.art_root, response_path, "response")
        if request_path.suffix != ".json" or response_path.suffix != ".json":
            raise ValueError("Art Agent relay paths must be JSON")
        request = json.loads(request_path.read_text())
        if request.get("schema") != REQUEST_SCHEMA:
            raise ValueError("unsupported Art Agent request schema")
        if request_path.parent.name != "requests" or response_path.parent.name != "responses" or request_path.parent.parent != response_path.parent.parent:
            raise ValueError("request and response must share an Art Agent session directory")
        session_root = request_path.parent.parent
        capability_path = self._under(session_root, request.get("capability", ""), "capability")
        capability = json.loads(capability_path.read_text())
        if capability.get("schema") != CAPABILITY_SCHEMA:
            raise ValueError("unsupported Art Agent capability schema")
        manifest_path = self._under(self.workspace_root, request.get("manifest", ""), "manifest")
        workbench_path = self._under(self.workspace_root, request.get("workbench", ""), "workbench")
        if request.get("session_id") != capability.get("session_id") or request.get("nonce") != capability.get("nonce"):
            raise ValueError("Art Agent capability mismatch")
        if request.get("manifest") != capability.get("workbench_manifest") or request.get("workbench") != capability.get("workbench"):
            raise ValueError("Art Agent capability path mismatch")
        manifest = json.loads(manifest_path.read_text())
        if manifest_path.parent != workbench_path.parent or manifest_path.name != "workbench.json" or workbench_path.name != "workbench.aseprite":
            raise ValueError("manifest and workbench must be sibling canonical files")
        if manifest.get("schema") != "custodian.operator_animation_workbench.v2":
            raise ValueError("unsupported Workbench manifest schema")
        if manifest.get("context", {}).get("fingerprint") != capability.get("context_fingerprint"):
            raise ValueError("WORKBENCH CONTEXT MISMATCH")
        if response_path.stem != request_path.stem:
            raise ValueError("response path must match request stem")
        request["_workbench_path"] = str(workbench_path)
        return request, capability, manifest

    async def execute(self, request_path: Path, response_path: Path) -> dict[str, Any]:
        request, capability, manifest = self._validate_request(request_path, response_path)
        state = self.bridge.server.state
        if state.active_document_path != request["_workbench_path"]:
            return {"schema": RELAY_SCHEMA, "status": "unavailable"}
        operation_type = request.get("operation", {}).get("type")
        if operation_type not in READ_TYPES and operation_type not in MUTATION_TYPES:
            raise ValueError(f"unsupported Art Agent operation: {operation_type}")
        if operation_type in MUTATION_TYPES:
            guard = request.get("live_guard") or {}
            expected_session = guard.get("client_session_id")
            expected_revision = guard.get("expected_revision")
            if expected_session not in (None, "") and expected_session != state.client_session_id:
                return {"schema": RELAY_SCHEMA, "status": "stale_live", "error": "live Art Agent client session changed; inspect/render before retrying"}
            if expected_revision is not None and expected_revision != state.document_revision:
                return {"schema": RELAY_SCHEMA, "status": "stale_live", "error": "live Art Agent revision changed; inspect/render before retrying"}
            allow_mutation = True
        else:
            allow_mutation = False
        result = await self.bridge.server.request_command(MessageType.ART_AGENT_EXECUTE, {
            "document_path": request["_workbench_path"], "revision": state.document_revision,
            "client_session_id": state.client_session_id,
            "allow_mutation": allow_mutation, "request": request, "capability": capability, "manifest": manifest,
        })
        if result.type is not MessageType.COMMAND_RESULT or result.payload.get("operation") != "art_agent_execute":
            raise ValueError("invalid Art Agent command result")
        response = result.payload.get("art_agent_response")
        if not isinstance(response, dict):
            raise ValueError("Art Agent response must be an object")
        payload = {"schema": RELAY_SCHEMA, "status": "executed", "transport": "live", "client_session_id": state.client_session_id, "revision_before": result.payload.get("revision_before", state.document_revision), "revision_after": result.payload.get("revision_after", state.document_revision), "response": response}
        if result.payload.get("ok") is False:
            payload["status"] = "unknown_live_outcome" if result.payload.get("outcome_known") is False else "live_error"
            payload["error"] = result.payload.get("error")
        return payload

    async def undo(self, request_path: Path, response_path: Path, *, operation_key: str, client_session_id: str, revision: int) -> dict[str, Any]:
        request, capability, manifest = self._validate_request(request_path, response_path)
        if request.get("operation_key") != operation_key:
            return {"schema": RELAY_SCHEMA, "status": "live_error", "error": "undo operation key does not match original request"}
        state = self.bridge.server.state
        if state.active_document_path != request["_workbench_path"]:
            return {"schema": RELAY_SCHEMA, "status": "unavailable"}
        if state.client_session_id != client_session_id or state.document_revision != revision:
            return {"schema": RELAY_SCHEMA, "status": "stale_live", "error": "live Art Agent revision changed; inspect/render before retrying"}
        result = await self.bridge.server.request_command(MessageType.ART_AGENT_UNDO, {"document_path": request["_workbench_path"], "revision": revision, "client_session_id": client_session_id, "operation_key": operation_key})
        if result.payload.get("ok") is False:
            return {"schema": RELAY_SCHEMA, "status": "live_error", "error": result.payload.get("error"), "client_session_id": client_session_id, "revision_before": revision, "revision_after": result.payload.get("revision_after", revision)}
        return {"schema": RELAY_SCHEMA, "status": "executed", "transport": "live", "client_session_id": client_session_id, "revision_before": result.payload.get("revision_before", revision), "revision_after": result.payload.get("revision_after", revision), "response": result.payload}

    async def _handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        try:
            raw = await reader.readline()
            if not raw or len(raw) > 64 * 1024:
                raise ValueError("invalid relay request")
            envelope = json.loads(raw)
            if envelope.get("schema") != RELAY_SCHEMA:
                raise ValueError("unsupported relay schema")
            if envelope.get("action", "execute") == "undo":
                result = await self.undo(Path(envelope["request_path"]), Path(envelope["response_path"]), operation_key=str(envelope.get("operation_key", "")), client_session_id=str(envelope.get("client_session_id", "")), revision=int(envelope.get("revision", -1)))
            else:
                result = await self.execute(Path(envelope["request_path"]), Path(envelope["response_path"]))
        except Exception as error:
            result = {"schema": RELAY_SCHEMA, "status": "error", "error": str(error)}
        writer.write((json.dumps(result, separators=(",", ":")) + "\n").encode())
        await writer.drain()
        writer.close()
        await writer.wait_closed()
