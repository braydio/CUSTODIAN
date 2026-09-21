from __future__ import annotations

import json
import socket
import subprocess
from pathlib import Path

import animation_workbench as workbench
import animation_workbench_model as model

LUA = model.CUSTODIAN_ROOT / "tools/aseprite/operator_art_agent.lua"
LUA_LIB = model.CUSTODIAN_ROOT / "tools/aseprite/operator_art_agent_lib.lua"
OPS = model.CUSTODIAN_ROOT / "tools/aseprite/operator_live_bridge/art_agent_ops.lua"


class LiveArtAgentError(model.WorkbenchError):
    pass


class LiveArtAgentStale(LiveArtAgentError):
    pass


class LiveArtAgentKnownFailure(LiveArtAgentError):
    pass


class LiveArtAgentUnknownOutcome(LiveArtAgentError):
    pass


class ArtAgentLiveRelayClient:
    def __init__(self, *, host: str = "127.0.0.1", port: int = 32148, timeout: float = 0.5):
        self.host, self.port, self.timeout = host, port, timeout

    def execute(self, *, request_path: Path, response_path: Path) -> dict:
        payload = {"schema": "custodian.operator_art_agent.live_relay.v1", "request_path": str(Path(request_path).resolve()), "response_path": str(Path(response_path).resolve())}
        with socket.create_connection((self.host, self.port), timeout=self.timeout) as stream:
            stream.settimeout(self.timeout)
            stream.sendall((json.dumps(payload, separators=(",", ":")) + "\n").encode())
            received = b""
            while not received.endswith(b"\n"):
                chunk = stream.recv(65536)
                if not chunk: break
                received += chunk
                if len(received) > 2_000_000: raise RuntimeError("live Art Agent relay response too large")
        if not received: raise ConnectionError("live Art Agent relay returned no response")
        return json.loads(received.decode())

    def undo(self, *, request_path: Path, response_path: Path, operation_key: str, client_session_id: str, revision: int) -> dict:
        payload = {"schema": "custodian.operator_art_agent.live_relay.v1", "action": "undo", "request_path": str(Path(request_path).resolve()), "response_path": str(Path(response_path).resolve()), "operation_key": operation_key, "client_session_id": client_session_id, "revision": revision}
        with socket.create_connection((self.host, self.port), timeout=self.timeout) as stream:
            stream.settimeout(self.timeout); stream.sendall((json.dumps(payload, separators=(",", ":")) + "\n").encode()); received=b""
            while not received.endswith(b"\n"):
                chunk=stream.recv(65536)
                if not chunk: break
                received += chunk
                if len(received)>2_000_000: raise RuntimeError("live Art Agent relay response too large")
        if not received: raise ConnectionError("live Art Agent relay returned no response")
        return json.loads(received.decode())


class ArtAgentBridge:
    def __init__(self, *, aseprite: Path | None = None, relay_factory=ArtAgentLiveRelayClient):
        self.aseprite = workbench.resolve_aseprite(aseprite, required=False)
        self.relay_factory = relay_factory

    def execute(
        self,
        *,
        request_path: Path,
        response_path: Path,
        expected_request_id: str | None = None,
        expected_operation_key: str | None = None,
    ) -> dict:
        response_path.unlink(missing_ok=True)
        try:
            relay_factory = getattr(self, "relay_factory", ArtAgentLiveRelayClient)
            relay = relay_factory().execute(request_path=request_path, response_path=response_path)
        except (OSError, TimeoutError, ConnectionError) as error:
            operation_type = json.loads(request_path.read_text()).get("operation", {}).get("type")
            if operation_type in {"paint_pixels", "erase_pixels", "stroke", "copy_region", "move_region", "draft_shift_part", "draft_copy_part", "draft_replace_part", "draft_mirror_part", "discard_draft", "bake_draft", "clear_masked_region", "recolor_plan"} and self._bridge_endpoint_active():
                raise LiveArtAgentError("Operator Workbench live bridge is active but Art Agent relay is unavailable; refusing headless mutation collision") from error
            relay = None
        if relay is not None:
            status = relay.get("status")
            if status == "mutation_refused":
                raise LiveArtAgentError(relay.get("error") or "matching live Aseprite workbench refuses Art Agent mutation")
            if status == "stale_live":
                raise LiveArtAgentStale(relay.get("error") or "LIVE WORKBENCH CHANGED SINCE ART AGENT OBSERVATION; inspect/render current live state before retrying")
            if status == "live_error":
                raise LiveArtAgentKnownFailure(relay.get("error") or "live Art Agent operation failed")
            if status == "unknown_live_outcome":
                raise LiveArtAgentUnknownOutcome(relay.get("error") or "live Art Agent operation outcome is unknown")
            if status == "executed":
                payload = relay.get("response")
                if not isinstance(payload, dict): raise model.WorkbenchError("live Art Agent response must be an object")
                payload = dict(payload)
                payload["_transport"] = "live"
                payload["_live_client_session_id"] = relay.get("client_session_id")
                payload["_live_revision_before"] = relay.get("revision_before")
                payload["_live_revision_after"] = relay.get("revision_after")
                response_path.write_text(json.dumps(payload, indent=2) + "\n")
                return self._validate_response(payload, expected_request_id, expected_operation_key)
            if status not in ("unavailable",):
                raise model.WorkbenchError(relay.get("error") or "live Art Agent relay failed")
        aseprite = self.aseprite or workbench.resolve_aseprite(None, required=True)
        completed = subprocess.run(
            [
                str(aseprite),
                "-b",
                "--script-param",
                f"request={request_path.resolve()}",
                "--script-param",
                f"response={response_path.resolve()}",
                "--script-param",
                f"lib={LUA_LIB.resolve()}",
                "--script-param",
                f"ops={OPS.resolve()}",
                "--script",
                str(LUA),
            ],
            text=True,
            capture_output=True,
        )
        if not response_path.exists():
            detail = (completed.stderr or completed.stdout).strip()
            raise model.WorkbenchError(
                "Aseprite Art Agent returned no response"
                + (f": {detail}" if detail else "")
            )
        payload = json.loads(response_path.read_text())
        payload = dict(payload)
        payload.setdefault("_transport", "headless")
        return self._validate_response(payload, expected_request_id, expected_operation_key, completed=completed)

    def undo_live(self, *, request_path: Path, response_path: Path, operation_key: str, client_session_id: str, revision: int) -> dict:
        relay_factory = getattr(self, "relay_factory", ArtAgentLiveRelayClient)
        try:
            result = relay_factory().undo(request_path=request_path, response_path=response_path, operation_key=operation_key, client_session_id=client_session_id, revision=revision)
        except (OSError, TimeoutError, ConnectionError) as error:
            raise LiveArtAgentError("live Art Agent undo relay unavailable") from error
        status = result.get("status")
        if status == "stale_live": raise LiveArtAgentStale(result.get("error") or "live Art Agent revision changed")
        if status == "unknown_live_outcome": raise LiveArtAgentUnknownOutcome(result.get("error") or "live Art Agent undo outcome is unknown")
        if status != "executed": raise LiveArtAgentKnownFailure(result.get("error") or "live Art Agent undo failed")
        return result

    @staticmethod
    def _bridge_endpoint_active(host: str = "127.0.0.1", port: int = 32147) -> bool:
        try:
            with socket.create_connection((host, port), timeout=0.1):
                return True
        except OSError:
            return False

    @staticmethod
    def _validate_response(payload, expected_request_id, expected_operation_key, *, completed=None) -> dict:
        from .models import RESPONSE_SCHEMA
        if payload.get("schema") != RESPONSE_SCHEMA:
            raise model.WorkbenchError("Aseprite Art Agent response schema mismatch")
        if expected_request_id is not None and payload.get("request_id") != expected_request_id:
            raise model.WorkbenchError("Aseprite Art Agent request ID mismatch")
        if expected_operation_key is not None and payload.get("operation_key") != expected_operation_key:
            raise model.WorkbenchError("Aseprite Art Agent operation key mismatch")
        if completed is not None and (completed.returncode != 0 or not payload.get("ok")):
            raise model.WorkbenchError(payload.get("error") or "Aseprite Art Agent operation failed")
        if not payload.get("ok"):
            raise model.WorkbenchError(
                payload.get("error") or "Aseprite Art Agent operation failed"
            )
        return payload
