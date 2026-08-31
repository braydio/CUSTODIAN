from __future__ import annotations

import json
import subprocess
from pathlib import Path

import animation_workbench as workbench
import animation_workbench_model as model

LUA = model.CUSTODIAN_ROOT / "tools/aseprite/operator_art_agent.lua"
LUA_LIB = model.CUSTODIAN_ROOT / "tools/aseprite/operator_art_agent_lib.lua"


class ArtAgentBridge:
    def __init__(self, *, aseprite: Path | None = None):
        self.aseprite = workbench.resolve_aseprite(aseprite, required=True)

    def execute(
        self,
        *,
        request_path: Path,
        response_path: Path,
        expected_request_id: str | None = None,
        expected_operation_key: str | None = None,
    ) -> dict:
        response_path.unlink(missing_ok=True)
        completed = subprocess.run(
            [
                str(self.aseprite),
                "-b",
                "--script-param",
                f"request={request_path.resolve()}",
                "--script-param",
                f"response={response_path.resolve()}",
                "--script-param",
                f"lib={LUA_LIB.resolve()}",
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
        from .models import RESPONSE_SCHEMA
        if payload.get("schema") != RESPONSE_SCHEMA:
            raise model.WorkbenchError("Aseprite Art Agent response schema mismatch")
        if expected_request_id is not None and payload.get("request_id") != expected_request_id:
            raise model.WorkbenchError("Aseprite Art Agent request ID mismatch")
        if expected_operation_key is not None and payload.get("operation_key") != expected_operation_key:
            raise model.WorkbenchError("Aseprite Art Agent operation key mismatch")
        if completed.returncode != 0 or not payload.get("ok"):
            raise model.WorkbenchError(
                payload.get("error") or "Aseprite Art Agent operation failed"
            )
        return payload
