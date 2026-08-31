from __future__ import annotations

import json
import subprocess
from pathlib import Path

import animation_workbench as workbench
import animation_workbench_model as model

LUA = model.CUSTODIAN_ROOT / "tools/aseprite/operator_art_agent.lua"


class ArtAgentBridge:
    def __init__(self, *, aseprite: Path | None = None):
        self.aseprite = workbench.resolve_aseprite(aseprite, required=True)

    def execute(self, *, request_path: Path, response_path: Path) -> dict:
        response_path.unlink(missing_ok=True)
        completed = subprocess.run(
            [
                str(self.aseprite),
                "-b",
                "--script-param",
                f"request={request_path.resolve()}",
                "--script-param",
                f"response={response_path.resolve()}",
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
        if completed.returncode != 0 or not payload.get("ok"):
            raise model.WorkbenchError(
                payload.get("error") or "Aseprite Art Agent operation failed"
            )
        return payload
