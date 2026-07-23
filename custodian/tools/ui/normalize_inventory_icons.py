#!/usr/bin/env python3
"""Normalize existing inventory icons onto canonical 128px runtime canvases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_ROOT = PROJECT_ROOT / "content" / "ui" / "inventory"
RUNTIME_ROOT = INVENTORY_ROOT / "runtime" / "icons"
SOURCE_ROOTS = (
    INVENTORY_ROOT / "icons",
    INVENTORY_ROOT / "icons" / "resources",
)
CANVAS_SIZE = 128
VISIBLE_LONG_EDGE = 96
MIN_VISIBLE_EDGE = 88
MAX_VISIBLE_EDGE = 104


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Crop alpha bounds and repad existing inventory icons to canonical 128x128 runtime PNGs."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write normalized PNGs. Without this flag, report the planned outputs only.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate existing canonical runtime icons without writing.",
    )
    args = parser.parse_args()

    if args.check:
        return check_runtime_icons()

    sources = discover_sources()
    if not sources:
        print("no readable inventory icon sources found")
        return 1
    for item_id, source in sorted(sources.items()):
        output = RUNTIME_ROOT / f"icon_{item_id}.png"
        if not args.apply:
            print(f"[dry-run] {source.relative_to(PROJECT_ROOT)} -> {output.relative_to(PROJECT_ROOT)}")
            continue
        normalized = normalize_icon(source)
        if normalized is None:
            print(f"skip empty/invalid alpha: {source.relative_to(PROJECT_ROOT)}")
            continue
        output.parent.mkdir(parents=True, exist_ok=True)
        normalized.save(output, format="PNG", optimize=False)
        print(f"wrote {output.relative_to(PROJECT_ROOT)}")
    return 0


def discover_sources() -> dict[str, Path]:
    sources: dict[str, Path] = {}
    for source_root in SOURCE_ROOTS:
        if not source_root.exists():
            continue
        for path in sorted(source_root.glob("icon_*.png")):
            try:
                with Image.open(path) as image:
                    image.convert("RGBA")
            except Exception:
                continue
            sources[path.stem.removeprefix("icon_")] = path
    if "placeholder" in sources:
        sources.setdefault("unknown", sources["placeholder"])
    return sources


def normalize_icon(path: Path) -> Image.Image | None:
    with Image.open(path) as source_image:
        image = source_image.convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        return None
    cropped = image.crop(bounds)
    longest = max(cropped.size)
    scale = VISIBLE_LONG_EDGE / float(longest)
    target_size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = cropped.resize(target_size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    destination = (
        (CANVAS_SIZE - resized.width) // 2,
        (CANVAS_SIZE - resized.height) // 2,
    )
    canvas.alpha_composite(resized, destination)
    return canvas


def check_runtime_icons() -> int:
    failures: list[str] = []
    paths = sorted(RUNTIME_ROOT.glob("icon_*.png"))
    if not paths:
        failures.append("no canonical runtime icons found")
    for path in paths:
        try:
            with Image.open(path) as source_image:
                image = source_image.convert("RGBA")
        except Exception as exc:
            failures.append(f"{path.name}: unreadable ({exc})")
            continue
        if image.size != (CANVAS_SIZE, CANVAS_SIZE):
            failures.append(f"{path.name}: canvas is {image.size}, expected 128x128")
            continue
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            failures.append(f"{path.name}: alpha is empty")
            continue
        visible_long_edge = max(bounds[2] - bounds[0], bounds[3] - bounds[1])
        if not MIN_VISIBLE_EDGE <= visible_long_edge <= MAX_VISIBLE_EDGE:
            failures.append(
                f"{path.name}: visible long edge {visible_long_edge}px is outside {MIN_VISIBLE_EDGE}-{MAX_VISIBLE_EDGE}px"
            )
    if failures:
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print(f"inventory icon normalization check passed ({len(paths)} canonical icons)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
