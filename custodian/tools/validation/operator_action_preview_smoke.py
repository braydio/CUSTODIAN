#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PREVIEW_TOOL = PROJECT_ROOT / "tools/pipelines/operator_action_preview.py"


def main() -> int:
    with TemporaryDirectory(prefix="operator-preview-smoke-") as temp:
        root = Path(temp)
        runtime_root = root / "runtime"
        out_dir = root / "review"
        for layer, color in (
            ("lower_body", (255, 0, 0, 255)),
            ("upper_body", (0, 255, 0, 160)),
            ("upper_fx", (0, 0, 255, 128)),
        ):
            write_strip(
                runtime_root
                / f"modules/new_operator/{layer}/actions/unarmed/block_loop_01/operator__modular_{layer}__unarmed__block_loop_01__e__5f__96.png",
                color,
            )

        result = subprocess.run(
            [
                sys.executable,
                str(PREVIEW_TOOL),
                "--runtime-root",
                str(runtime_root),
                "--output-dir",
                str(out_dir),
                "--loadout",
                "unarmed",
                "--action",
                "block_loop_01",
                "--directions",
                "e,n",
                "--include-fx",
                "--missing-placeholder",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr, file=sys.stderr)
            return result.returncode
        report_path = out_dir / "operator_preview__unarmed__block_loop_01__report.json"
        grid_path = out_dir / "operator_preview__unarmed__block_loop_01__grid.png"
        assert report_path.exists()
        assert grid_path.exists()
        payload = json.loads(report_path.read_text(encoding="utf-8"))
        assert len(payload["previews"]) == 2
        assert payload["previews"][0]["frames"] == 5
        assert payload["previews"][1]["missing_layers"]
    print("operator_action_preview_smoke passed")
    return 0


def write_strip(path: Path, color: tuple[int, int, int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (96 * 5, 96), color).save(path)


if __name__ == "__main__":
    raise SystemExit(main())
