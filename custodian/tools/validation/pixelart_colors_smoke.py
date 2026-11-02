#!/usr/bin/env python3
"""Regression: explicit --colors must affect every pixelart candidate."""
from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[3]
CONVERTER = REPO / "custodian/tools/art/custodian_pixelart_converter.py"


def _opaque_color_count(path: Path) -> int:
    with Image.open(path) as opened:
        pixels = opened.convert("RGBA").get_flattened_data()
        return len({pixel[:3] for pixel in pixels if pixel[3]})


def _run(
    source: Path,
    output: Path,
    method: str,
    colors: int | None,
    *extra: str,
) -> None:
    command = [
        "python3", str(CONVERTER), str(source), str(output),
        "--size", "32", "--choose", method, "--force",
        *extra,
    ]
    if colors is not None:
        command += ["--colors", str(colors)]
    subprocess.run(command, check=True, capture_output=True, text=True)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="pixelart-colors-") as tmp:
        root = Path(tmp)
        source = root / "gradient.png"
        image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        pixels = image.load()
        for y in range(8, 120):
            for x in range(8, 120):
                pixels[x, y] = (x * 2, y * 2, (x + y) % 256, 255)
        image.save(source)

        crisp_default = root / "crisp_default.png"
        crisp_four = root / "crisp_four.png"
        crisp_sixteen = root / "crisp_sixteen.png"
        balanced_four = root / "balanced_four.png"
        clustered_four = root / "clustered_four.png"
        sheet_four = root / "sheet_four.png"
        _run(source, crisp_default, "crisp", None)
        _run(source, crisp_four, "crisp", 4)
        _run(source, crisp_sixteen, "crisp", 16)
        _run(source, balanced_four, "balanced", 4)
        _run(source, clustered_four, "clustered", 4)
        sheet_source = root / "sheet.png"
        Image.new("RGBA", (256, 128), (0, 0, 0, 0)).save(sheet_source)
        with Image.open(source) as opened:
            sheet = Image.open(sheet_source).convert("RGBA")
            sheet.alpha_composite(opened.convert("RGBA"), (0, 0))
            sheet.alpha_composite(opened.convert("RGBA").transpose(Image.Transpose.FLIP_LEFT_RIGHT), (128, 0))
            sheet.save(sheet_source)
        _run(sheet_source, sheet_four, "crisp", 4, "--sheet", "--frames", "2")

        assert _opaque_color_count(crisp_default) > 16
        assert _opaque_color_count(crisp_four) <= 4
        assert _opaque_color_count(crisp_sixteen) <= 16
        assert crisp_four.read_bytes() != crisp_sixteen.read_bytes()
        assert _opaque_color_count(balanced_four) <= 4
        assert _opaque_color_count(clustered_four) <= 4
        assert Image.open(sheet_four).size == (64, 32)
        assert _opaque_color_count(sheet_four) <= 4

    print("[PASS] pixelart --colors applies to crisp, balanced, and clustered")
    print("  omitted flag preserves legacy crisp palette behavior")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
