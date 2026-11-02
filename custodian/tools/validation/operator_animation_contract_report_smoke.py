#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory


PROJECT_ROOT = Path(__file__).resolve().parents[2]
REPORT_TOOL = PROJECT_ROOT / "tools/validation/operator_animation_contract_report.py"


def main() -> int:
    with TemporaryDirectory(prefix="operator-contract-smoke-") as temp:
        root = Path(temp)
        contract = root / "contract.json"
        catalog = root / "catalog.json"
        contract.write_text(json.dumps({
            "schema": "custodian.operator_animation_contract.v2",
            "directions": ["s"],
            "groups": [{"id": "smoke", "required": True, "entries": [
                {"animation_profile": "unarmed", "action_group": "locomotion", "action": "idle_01", "layer": "lower_body", "directions": ["s"], "frames": 5, "frame_size": [96, 96]},
                {"animation_profile": "unarmed", "action_group": "locomotion", "action": "idle_01", "layer": "upper_body", "directions": ["s"], "frames": 5, "frame_size": [96, 96]},
            ]}],
        }), encoding="utf-8")
        catalog.write_text(json.dumps({
            "schema": "custodian.operator_animation_catalog.v2",
            "animations": {"unarmed/locomotion/idle_01/s": {"layers": {
                "lower_body": {"path": "res://lower.png", "frames": 5, "frame_size": [96, 96]},
                "upper_body": {"path": "res://upper.png", "frames": 5, "frame_size": [96, 96]},
            }}}, "weapons": {},
        }), encoding="utf-8")
        result = subprocess.run([sys.executable, str(REPORT_TOOL), "--contract", str(contract), "--catalog", str(catalog), "--json", "--strict"], capture_output=True, text=True)
        if result.returncode:
            print(result.stderr, file=sys.stderr)
            return result.returncode
        payload = json.loads(result.stdout)
        assert payload["summary"]["present"] == 2
        assert payload["summary"]["missing_required"] == 0
    print("operator_animation_contract_report_smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
