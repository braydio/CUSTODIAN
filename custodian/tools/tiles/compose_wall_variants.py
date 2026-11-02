#!/usr/bin/env python3
"""Compose deterministic wall-run variants from extracted wall parts."""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path
from typing import Any

from PIL import Image


DEFAULT_MAX_WIDTH = 1024
DEFAULT_PADDING = 8


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--parts-json", "--parts", dest="parts_json", required=True, type=Path, help="wall_parts.json.")
    parser.add_argument("--atlas", required=True, type=Path, help="Packed atlas PNG.")
    parser.add_argument("--out", required=True, type=Path, help="Output composed variant sheet.")
    parser.add_argument("--count", type=int, default=32, help="Number of variants to compose.")
    parser.add_argument("--seed", type=int, default=1234, help="Deterministic RNG seed.")
    parser.add_argument("--max-width", type=int, default=DEFAULT_MAX_WIDTH, help="Maximum output row width.")
    parser.add_argument("--padding", type=int, default=DEFAULT_PADDING, help="Transparent spacing between variants.")
    return parser.parse_args()


def load_parts(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return {"schema": "legacy-list"}, data
    return data, list(data.get("parts", []))


def crop_part(atlas: Image.Image, part: dict[str, Any]) -> Image.Image:
    x, y, width, height = part["atlas_rect"]
    return atlas.crop((x, y, x + width, y + height))


def by_kind(parts: list[dict[str, Any]], *kinds: str) -> list[dict[str, Any]]:
    wanted = set(kinds)
    return [part for part in parts if part.get("kind") in wanted]


def by_tag_or_kind(parts: list[dict[str, Any]], text: str) -> list[dict[str, Any]]:
    return [
        part
        for part in parts
        if text in part.get("kind", "") or any(text in tag for tag in part.get("tags", []))
    ]


def choose(rng: random.Random, pool: list[dict[str, Any]], fallback: list[dict[str, Any]]) -> dict[str, Any]:
    source = pool or fallback
    if not source:
        raise ValueError("No compatible wall parts are available for composition.")
    return rng.choice(source)


def compose_run(atlas: Image.Image, parts: list[dict[str, Any]]) -> Image.Image:
    images = [crop_part(atlas, part) for part in parts]
    total_width = sum(image.size[0] for image in images)
    max_height = max(image.size[1] for image in images)
    output = Image.new("RGBA", (total_width, max_height), (0, 0, 0, 0))

    x = 0
    for image in images:
        y = max_height - image.size[1]
        output.alpha_composite(image, (x, y))
        x += image.size[0]
    return output


def build_variant_parts(rng: random.Random, pools: dict[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    all_parts = pools["all"]
    long_parts = pools["long"]
    medium_parts = pools["medium"]
    short_parts = pools["short"]
    cap_parts = pools["caps"]
    damaged_parts = pools["damaged"]
    moss_parts = pools["moss"]
    rubble_parts = pools["rubble"]
    middle_parts = medium_parts + short_parts + long_parts

    template = rng.randrange(6)
    if template == 0 and long_parts:
        return [choose(rng, long_parts, all_parts)]

    if template == 1:
        return [
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
            choose(rng, medium_parts, middle_parts + all_parts),
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
        ]

    if template == 2:
        count = rng.randint(2, 4)
        return [
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
            *[choose(rng, short_parts + medium_parts, middle_parts + all_parts) for _ in range(count)],
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
        ]

    if template == 3:
        accent = choose(rng, damaged_parts, middle_parts + all_parts)
        return [
            choose(rng, medium_parts, middle_parts + all_parts),
            accent,
            choose(rng, medium_parts + short_parts, middle_parts + all_parts),
        ]

    if template == 4:
        accent = choose(rng, moss_parts, middle_parts + all_parts)
        return [
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
            choose(rng, medium_parts + short_parts, middle_parts + all_parts),
            accent,
            choose(rng, cap_parts, short_parts + medium_parts + all_parts),
        ]

    accent = choose(rng, rubble_parts, damaged_parts + middle_parts + all_parts)
    return [
        choose(rng, cap_parts, short_parts + medium_parts + all_parts),
        choose(rng, short_parts + medium_parts, middle_parts + all_parts),
        accent,
    ]


def pack_variants(variants: list[Image.Image], max_width: int, padding: int) -> Image.Image:
    rows: list[list[Image.Image]] = []
    current: list[Image.Image] = []
    current_width = 0

    for variant in variants:
        next_width = variant.size[0] if not current else current_width + padding + variant.size[0]
        if current and next_width > max_width:
            rows.append(current)
            current = []
            current_width = 0
        current.append(variant)
        current_width = variant.size[0] if current_width == 0 else current_width + padding + variant.size[0]

    if current:
        rows.append(current)

    row_widths = [sum(image.size[0] for image in row) + padding * (len(row) - 1) for row in rows]
    row_heights = [max(image.size[1] for image in row) for row in rows]
    output_width = max(1, min(max_width, max(row_widths) if row_widths else max_width))
    output_height = max(1, sum(row_heights) + padding * max(0, len(rows) - 1))
    output = Image.new("RGBA", (output_width, output_height), (0, 0, 0, 0))

    y = 0
    for row, row_height in zip(rows, row_heights):
        x = 0
        for image in row:
            output.alpha_composite(image, (x, y + row_height - image.size[1]))
            x += image.size[0] + padding
        y += row_height + padding
    return output


def main() -> None:
    args = parse_args()
    metadata, parts = load_parts(args.parts_json)
    atlas = Image.open(args.atlas).convert("RGBA")
    rng = random.Random(args.seed)

    if not parts:
        raise SystemExit(f"No parts found in {args.parts_json}")

    pools = {
        "all": parts,
        "long": by_kind(parts, "long_straight"),
        "medium": by_kind(parts, "medium_straight"),
        "short": by_kind(parts, "short_straight"),
        "caps": by_kind(parts, "vertical_end_or_pillar", "corner_or_block", "short_straight"),
        "damaged": by_tag_or_kind(parts, "damage") + by_tag_or_kind(parts, "damaged"),
        "moss": by_tag_or_kind(parts, "moss"),
        "rubble": by_tag_or_kind(parts, "rubble"),
    }

    variants = [compose_run(atlas, build_variant_parts(rng, pools)) for _ in range(args.count)]
    sheet = pack_variants(variants, args.max_width, args.padding)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out)

    print(f"Loaded {len(parts)} parts from {args.parts_json}")
    print(f"Source metadata schema: {metadata.get('schema', 'unknown')}")
    print(f"Wrote {len(variants)} variants to {args.out}")


if __name__ == "__main__":
    main()

