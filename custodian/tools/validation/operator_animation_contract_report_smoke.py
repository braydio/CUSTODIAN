#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
REPORT_TOOL = PROJECT_ROOT / "tools/validation/operator_animation_contract_report.py"


def main() -> int:
    with TemporaryDirectory(prefix="operator-contract-smoke-") as temp:
        root = Path(temp)
        source_root = root / "source"
        runtime_root = root / "runtime"
        source_root.mkdir()
        (runtime_root / "modules/new_operator/lower_body/locomotion/idle_01").mkdir(parents=True)
        (runtime_root / "modules/new_operator/upper_body/locomotion/idle_01").mkdir(parents=True)

        write_strip(
            runtime_root / "modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__s__5f__96.png",
            96,
            5,
        )
        write_strip(
            runtime_root / "modules/new_operator/upper_body/locomotion/idle_01/operator__modular_upper_body__unarmed__idle_01__s__5f__96.png",
            96,
            5,
        )
        write_strip(
            source_root / "operator__modular_upper_body__unarmed__idle_01__q__5f__96.png",
            96,
            5,
        )

        contract = root / "contract.json"
        contract.write_text(
            json.dumps(
                {
                    "schema": "custodian.operator_animation_contract.v1",
                    "owner": "operator",
                    "frame_size": 96,
                    "directions": ["s"],
                    "groups": [
                        {
                            "id": "smoke_required",
                            "required": True,
                            "entries": [
                                {
                                    "layer": "lower_body",
                                    "loadout": "unarmed",
                                    "action": "idle_01",
                                    "directions": ["s"],
                                    "frames": 5,
                                },
                                {
                                    "layer": "upper_body",
                                    "loadout": "unarmed",
                                    "action": "idle_01",
                                    "directions": ["s"],
                                    "frames": 5,
                                },
                            ],
                        }
                    ],
                },
                indent=2,
            ),
            encoding="utf-8",
        )

        result = subprocess.run(
            [
                sys.executable,
                str(REPORT_TOOL),
                "--contract",
                str(contract),
                "--source-root",
                str(source_root),
                "--runtime-root",
                str(runtime_root),
                "--json",
                "--strict",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr, file=sys.stderr)
            return result.returncode
        payload = json.loads(result.stdout)
        assert payload["summary"]["ok_required"] == 2
        assert payload["summary"]["missing_required"] == 0
        assert payload["summary"]["suspicious_assets"] >= 1
    print("operator_animation_contract_report_smoke passed")
    return 0


def write_strip(path: Path, frame_size: int, frames: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (frame_size * frames, frame_size), (255, 0, 0, 255)).save(path)


if __name__ == "__main__":
    raise SystemExit(main())
