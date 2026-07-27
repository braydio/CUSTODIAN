#!/usr/bin/env python3
"""Focused smoke test for the source-art to pixel-art converter."""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw


REPO_ROOT = Path(__file__).resolve().parents[3]
TOOL = REPO_ROOT / "custodian/tools/art/source_to_pixel_art.py"


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="custodian-pixelart-smoke-") as temp:
        work = Path(temp)
        source_path = work / "source.png"
        source = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
        draw = ImageDraw.Draw(source)
        for y in range(48, 336):
            shade = 40 + (y - 48) * 180 // 287
            draw.line((48, y, 335, y), fill=(shade, 80, 240 - shade // 2, 255))
        draw.ellipse((108, 84, 276, 252), outline=(245, 230, 160, 255), width=13)
        draw.rectangle((176, 176, 207, 271), fill=(255, 250, 220, 255))
        source.save(source_path)

        outputs: list[Path] = []
        for choice in ("1", "2", "3"):
            output = work / f"choice_{choice}.png"
            command = [
                sys.executable,
                str(TOOL),
                str(source_path),
                str(output),
                "--size",
                "96",
                "--colors",
                "24",
                "--choose",
                choice,
            ]
            completed = subprocess.run(command, capture_output=True, text=True)
            if completed.returncode != 0:
                raise AssertionError(
                    f"choice {choice} failed:\n{completed.stdout}\n{completed.stderr}"
                )
            with Image.open(output) as result:
                if result.size != (96, 96):
                    raise AssertionError(f"choice {choice} has size {result.size}")
                if result.mode != "RGBA":
                    raise AssertionError(f"choice {choice} has mode {result.mode}")
            outputs.append(output)

        payloads = {path.read_bytes() for path in outputs}
        if len(payloads) != 3:
            raise AssertionError("the three conversion methods produced duplicate files")

        kept = work / "candidates"
        selected = work / "kept_choice.png"
        subprocess.run(
            [
                sys.executable,
                str(TOOL),
                str(source_path),
                str(selected),
                "--choose",
                "balanced",
                "--keep-candidates",
                str(kept),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        expected = {
            "1_crisp.png",
            "2_balanced.png",
            "3_clustered.png",
            "comparison.png",
        }
        if {path.name for path in kept.iterdir()} != expected:
            raise AssertionError("candidate review files did not match the contract")

    print("source_to_pixel_art_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
