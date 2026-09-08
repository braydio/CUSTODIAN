#!/usr/bin/env python3
"""
CUSTODIAN
Procgen Authored Depth Chunks
Asset Pipeline V2 normalization/preparation.

BOUNDARY:

    asset_drop/source_work/procgen_depth_chunks_v1/
                    |
                    v
            THIS SCRIPT
                    |
                    v
    asset_drop/production_prep/procgen_depth_chunks_v1/
                    |
                    v
              HUMAN REVIEW
                    |
                    v
    Codex stages approved derivatives into:
    asset_drop/inbox/<family>/
                    |
                    v
            Asset Pipeline V2

This script:

- NEVER modifies source masters
- NEVER writes directly into content/
- NEVER performs Asset Pipeline ingest
- preserves intentional graduated alpha
- resizes each source exactly once
- preserves source composition/aspect ratio
- creates V2 family-contract candidates
- creates Codex handoff metadata
- creates review contact sheets
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

ALPHA_CUTOFF = 16
MIN_TRANSPARENT_FRACTION = 0.005
MAX_ASPECT_ERROR = 0.03

REPO_ROOT = Path(__file__).resolve().parents[3]

DEFAULT_SOURCE_DIR = (
    REPO_ROOT / "custodian" / "asset_drop" / "source_work" / "procgen_depth_chunks_v1"
)

DEFAULT_PREP_DIR = (
    REPO_ROOT
    / "custodian"
    / "asset_drop"
    / "production_prep"
    / "procgen_depth_chunks_v1"
)


# ---------------------------------------------------------------------------
# Production contract
# ---------------------------------------------------------------------------

ASSETS: dict[str, dict[str, Any]] = {
    # -----------------------------------------------------------------------
    # Universal
    # -----------------------------------------------------------------------
    "depth_civic_foundation_breach_v1.png": {
        "family": "procgen_depth_universal",
        "state": "civic_foundation_breach_v1",
        "size": (896, 576),
        "size_class": "large",
        "required_biome": "",
        "weight": 3,
        "min_region_cells": 12,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 4,
        "footprint_cells": (28, 14),
        "chasm_core_rect": (6, 1, 16, 9),
        "tags": [
            "universal",
            "constructed_edge",
            "foundation",
            "civic",
            "large_void",
        ],
    },
    "depth_fractured_ravine_v1.png": {
        "family": "procgen_depth_universal",
        "state": "fractured_ravine_v1",
        "size": (896, 576),
        "size_class": "large",
        "required_biome": "",
        "weight": 4,
        "min_region_cells": 12,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 4,
        "footprint_cells": (28, 14),
        "chasm_core_rect": (6, 1, 16, 9),
        "tags": [
            "universal",
            "ravine",
            "natural",
            "structural_decay",
            "large_gap",
        ],
    },
    "depth_service_infrastructure_field_v1.png": {
        "family": "procgen_depth_universal",
        "state": "service_infrastructure_field_v1",
        "size": (640, 448),
        "size_class": "medium",
        "required_biome": "",
        "weight": 6,
        "min_region_cells": 8,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 3,
        "footprint_cells": (20, 11),
        "chasm_core_rect": (4, 1, 12, 7),
        "tags": [
            "universal",
            "infrastructure",
            "utility",
            "constructed",
            "service",
        ],
    },
    "depth_talus_and_rubble_shelf_v1.png": {
        "family": "procgen_depth_universal",
        "state": "talus_and_rubble_shelf_v1",
        "size": (640, 448),
        "size_class": "medium",
        "required_biome": "",
        "weight": 10,
        "min_region_cells": 8,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 3,
        "footprint_cells": (20, 11),
        "chasm_core_rect": (4, 1, 12, 7),
        "tags": [
            "universal",
            "neutral",
            "rubble",
            "talus",
            "fallback",
        ],
    },
    # -----------------------------------------------------------------------
    # Scrubland
    # -----------------------------------------------------------------------
    "depth_scrubland_dry_basin_v1.png": {
        "family": "procgen_depth_scrubland",
        "state": "dry_basin_v1",
        "size": (896, 576),
        "size_class": "large",
        "required_biome": "scrubland",
        "weight": 10,
        "min_region_cells": 12,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 4,
        "footprint_cells": (28, 14),
        "chasm_core_rect": (6, 1, 16, 9),
        "tags": [
            "scrubland",
            "basin",
            "large_void",
            "dry",
        ],
    },
    "depth_scrubland_wash_channel_v1.png": {
        "family": "procgen_depth_scrubland",
        "state": "wash_channel_v1",
        "size": (640, 448),
        "size_class": "medium",
        "required_biome": "scrubland",
        "weight": 7,
        "min_region_cells": 8,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 3,
        "footprint_cells": (20, 11),
        "chasm_core_rect": (4, 1, 12, 7),
        "tags": [
            "scrubland",
            "wash",
            "drainage",
            "erosion",
            "linear",
        ],
    },
    "depth_scrubland_service_scar_v1.png": {
        "family": "procgen_depth_scrubland",
        "state": "service_scar_v1",
        "size": (640, 448),
        "size_class": "medium",
        "required_biome": "scrubland",
        "weight": 5,
        "min_region_cells": 8,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 3,
        "footprint_cells": (20, 11),
        "chasm_core_rect": (4, 1, 12, 7),
        "tags": [
            "scrubland",
            "infrastructure",
            "service_scar",
            "reclaimed",
        ],
    },
    # -----------------------------------------------------------------------
    # Woodland
    # -----------------------------------------------------------------------
    "depth_woodland_canopy_basin_v1.png": {
        "family": "procgen_depth_woodland",
        "state": "canopy_basin_v1",
        "size": (896, 576),
        "size_class": "large",
        "required_biome": "woodland",
        "weight": 10,
        "min_region_cells": 12,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 4,
        "footprint_cells": (28, 14),
        "chasm_core_rect": (6, 1, 16, 9),
        "tags": [
            "woodland",
            "canopy",
            "basin",
            "large_void",
            "vegetation",
        ],
    },
    "depth_woodland_ravine_v1.png": {
        "family": "procgen_depth_woodland",
        "state": "ravine_v1",
        "size": (896, 576),
        "size_class": "large",
        "required_biome": "woodland",
        "weight": 4,
        "min_region_cells": 12,
        "allow_flip_h": True,
        "terrain_contact_edge": "north",
        "terrain_overlap_rows": 4,
        "footprint_cells": (28, 14),
        "chasm_core_rect": (6, 1, 16, 9),
        "tags": [
            "woodland",
            "ravine",
            "hero_depth",
            "water",
            "structural_decay",
        ],
    },
}


FAMILY_DOMAINS = {
    "procgen_depth_universal": "backgrounds/procgen/depth_chunks/universal",
    "procgen_depth_scrubland": "backgrounds/procgen/depth_chunks/scrubland",
    "procgen_depth_woodland": "backgrounds/procgen/depth_chunks/woodland",
}


# ---------------------------------------------------------------------------
# Basic utilities
# ---------------------------------------------------------------------------


def sha256(path: Path) -> str:
    h = hashlib.sha256()

    with path.open("rb") as handle:
        for block in iter(
            lambda: handle.read(1024 * 1024),
            b"",
        ):
            h.update(block)

    return h.hexdigest()


def relative(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def alpha_metrics(image: Image.Image) -> dict[str, Any]:
    alpha = image.getchannel("A")
    histogram = alpha.histogram()

    total = image.width * image.height

    transparent = sum(histogram[:250])

    alpha_min, alpha_max = alpha.getextrema()

    corners = [
        alpha.getpixel((0, 0)),
        alpha.getpixel((image.width - 1, 0)),
        alpha.getpixel((0, image.height - 1)),
        alpha.getpixel((image.width - 1, image.height - 1)),
    ]

    return {
        "alpha_min": int(alpha_min),
        "alpha_max": int(alpha_max),
        "transparent_fraction": transparent / max(total, 1),
        "corner_alpha": corners,
    }


def validate_source(
    path: Path,
    image: Image.Image,
    target_size: tuple[int, int],
) -> dict[str, Any]:
    metrics = alpha_metrics(image)

    if metrics["alpha_max"] <= 0:
        raise RuntimeError(f"{path.name}: image is fully transparent")

    if metrics["transparent_fraction"] < MIN_TRANSPARENT_FRACTION:
        raise RuntimeError(
            f"{path.name}: insufficient transparent area "
            f"({metrics['transparent_fraction']:.4%}); "
            "possible baked/opaque background"
        )

    source_ratio = image.width / image.height

    target_ratio = target_size[0] / target_size[1]

    aspect_error = abs(source_ratio - target_ratio) / target_ratio

    if aspect_error > MAX_ASPECT_ERROR:
        raise RuntimeError(
            f"{path.name}: source aspect "
            f"{source_ratio:.5f} differs too far from "
            f"target {target_ratio:.5f} "
            f"({aspect_error:.2%})"
        )

    metrics["source_aspect"] = source_ratio
    metrics["target_aspect"] = target_ratio
    metrics["aspect_error"] = aspect_error

    return metrics


# ---------------------------------------------------------------------------
# Alpha + resize
# ---------------------------------------------------------------------------


def clear_low_alpha(
    image: Image.Image,
) -> Image.Image:
    """
    Preserve intentional partial alpha.

    Only remove almost-invisible generator matte.
    """
    result = image.copy()

    alpha = result.getchannel("A")

    lut = [0 if value <= ALPHA_CUTOFF else value for value in range(256)]

    alpha = alpha.point(lut)

    result.putalpha(alpha)

    return result


def resize_to_canvas(
    image: Image.Image,
    target_size: tuple[int, int],
) -> Image.Image:
    """
    Preserve the entire authored composition.

    Do NOT trim to alpha bounds. These assets intentionally use their
    source canvas composition and terrain-contact edge.

    Preserve aspect ratio and letterbox by a pixel or two when necessary.
    """
    target_w, target_h = target_size

    source_w, source_h = image.size

    scale = min(
        target_w / source_w,
        target_h / source_h,
    )

    resized_w = max(
        1,
        round(source_w * scale),
    )

    resized_h = max(
        1,
        round(source_h * scale),
    )

    resized = image.resize(
        (resized_w, resized_h),
        Image.Resampling.LANCZOS,
    )

    resized = clear_low_alpha(resized)

    canvas = Image.new(
        "RGBA",
        target_size,
        (0, 0, 0, 0),
    )

    x = (target_w - resized_w) // 2
    y = (target_h - resized_h) // 2

    canvas.alpha_composite(
        resized,
        (x, y),
    )

    return canvas


# ---------------------------------------------------------------------------
# V2 family contract generation
# ---------------------------------------------------------------------------


def family_contract(
    family_id: str,
) -> dict[str, Any]:
    family_assets = [
        (filename, spec)
        for filename, spec in ASSETS.items()
        if spec["family"] == family_id
    ]

    max_width = max(spec["size"][0] for _, spec in family_assets)

    max_height = max(spec["size"][1] for _, spec in family_assets)

    states: dict[str, Any] = {}

    for _, spec in family_assets:
        width, height = spec["size"]

        states[spec["state"]] = {
            "required": True,
            "layer": "background",
            "action_group": "display",
            "variant": spec["state"],
            "layout": "copy",
            "frame_width": width,
            "frame_height": height,
        }

    return {
        "schema": "custodian.asset_family.v2",
        "id": family_id,
        "kind": "backdrop",
        "runtime": {
            "domain": FAMILY_DOMAINS[family_id],
            "owner": family_id,
            "template": "{domain}/{filename}",
            "filename_policy": "template",
            "filename_template": "{owner}_{variant}_{frame_size}.png",
        },
        "canvas": {
            "width": max_width,
            "height": max_height,
        },
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        # Codex fills this after wiring the existing macro
        # presentation consumer.
        "consumers": [],
    }


# ---------------------------------------------------------------------------
# Contact sheet
# ---------------------------------------------------------------------------


def checkerboard(
    size: tuple[int, int],
    cell: int = 16,
) -> Image.Image:
    width, height = size

    image = Image.new(
        "RGBA",
        size,
        (34, 34, 37, 255),
    )

    draw = ImageDraw.Draw(image)

    for y in range(0, height, cell):
        for x in range(0, width, cell):
            if (x // cell + y // cell) % 2 == 0:
                draw.rectangle(
                    [
                        x,
                        y,
                        min(width, x + cell),
                        min(height, y + cell),
                    ],
                    fill=(48, 48, 52, 255),
                )

    return image


def make_contact_sheet(
    outputs: list[tuple[str, Path]],
    destination: Path,
) -> None:
    columns = 3
    cell_w = 480
    cell_h = 360

    rows = math.ceil(len(outputs) / columns)

    sheet = checkerboard(
        (
            columns * cell_w,
            rows * cell_h,
        ),
        20,
    )

    draw = ImageDraw.Draw(sheet)

    for index, (
        state,
        path,
    ) in enumerate(outputs):

        image = load_rgba(path)

        preview = image.copy()

        preview.thumbnail(
            (
                cell_w - 30,
                cell_h - 58,
            ),
            Image.Resampling.LANCZOS,
        )

        col = index % columns
        row = index // columns

        origin_x = col * cell_w
        origin_y = row * cell_h

        x = origin_x + (cell_w - preview.width) // 2

        y = origin_y + 8

        sheet.alpha_composite(
            preview,
            (x, y),
        )

        draw.text(
            (
                origin_x + 10,
                origin_y + cell_h - 38,
            ),
            state,
            fill=(235, 235, 235, 255),
        )

        draw.text(
            (
                origin_x + 10,
                origin_y + cell_h - 20,
            ),
            f"{image.width}x{image.height}",
            fill=(170, 170, 175, 255),
        )

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    sheet.save(
        destination,
        compress_level=9,
    )


# ---------------------------------------------------------------------------
# Main preparation
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--source-dir",
        type=Path,
        default=DEFAULT_SOURCE_DIR,
    )

    parser.add_argument(
        "--prep-dir",
        type=Path,
        default=DEFAULT_PREP_DIR,
    )

    parser.add_argument(
        "--review",
        action="store_true",
        help="Open contact sheet in Aseprite.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate sources and report intended outputs without writing.",
    )

    args = parser.parse_args()

    source_dir = args.source_dir.resolve()
    prep_dir = args.prep_dir.resolve()

    families_dir = prep_dir / "families"
    contracts_dir = prep_dir / "contracts"
    review_dir = prep_dir / "review"

    missing = [filename for filename in ASSETS if not (source_dir / filename).exists()]

    if missing:
        raise RuntimeError("Missing source masters:\n  " + "\n  ".join(missing))

    report: dict[str, Any] = {
        "schema": "custodian.procgen_depth_chunk_normalization.v1",
        "source_root": relative(source_dir),
        "prep_root": relative(prep_dir),
        "alpha_cutoff": ALPHA_CUTOFF,
        "resampling": "Pillow LANCZOS, exactly once",
        "composition_policy": "preserve full source canvas; no alpha trim",
        "outputs": [],
    }

    handoff: dict[str, Any] = {
        "schema": "custodian.procgen_depth_chunk_v2_handoff.v1",
        "pipeline": "Asset Pipeline V2",
        "families": {},
        "stamp_profiles": {},
    }

    contact_outputs: list[tuple[str, Path]] = []

    print()
    print("CUSTODIAN Procgen Depth Chunk V2 Prep")
    print("====================================")
    print(f"Source: {source_dir}")
    print(f"Prep:   {prep_dir}")
    print()

    for filename, spec in ASSETS.items():
        source_path = source_dir / filename

        source = load_rgba(source_path)

        metrics = validate_source(
            source_path,
            source,
            spec["size"],
        )

        family = spec["family"]
        state = spec["state"]

        output_path = families_dir / family / f"{state}.png"

        print(
            f"{filename}: "
            f"{source.width}x{source.height} "
            f"-> {spec['size'][0]}x{spec['size'][1]}"
        )

        if not args.dry_run:
            output_path.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            normalized = resize_to_canvas(
                source,
                spec["size"],
            )

            normalized.save(
                output_path,
                compress_level=9,
            )

            output_hash = sha256(output_path)

            contact_outputs.append((state, output_path))
        else:
            output_hash = ""

        output_entry = {
            "source": relative(source_path),
            "source_size": [source.width, source.height],
            "target_size": list(spec["size"]),
            "family": family,
            "state": state,
            "prep_output": relative(output_path),
            "sha256": output_hash,
            **metrics,
        }

        report["outputs"].append(output_entry)

        family_entry = handoff["families"].setdefault(
            family,
            {
                "contract": f"contracts/" f"{family}.asset.json",
                "inbox": f"custodian/" f"asset_drop/" f"inbox/" f"{family}",
                "states": {},
            },
        )

        family_entry["states"][state] = {
            "prep_path": relative(output_path),
            "inbox_name": f"{state}.png",
            "target_size": list(spec["size"]),
            "sha256": output_hash,
        }

        handoff["stamp_profiles"][state] = {
            "family_id": family,
            "required_biome": spec["required_biome"],
            "size_class": spec["size_class"],
            "canvas_px": list(spec["size"]),
            "weight": spec["weight"],
            "min_region_cells": spec["min_region_cells"],
            "allow_flip_h": spec["allow_flip_h"],
            "depth_band": "BACK",
            "placement_domain": "CHASM",
            "allowed_region_kinds": ["depth_south_edge"],
            "terrain_contact_edge": spec["terrain_contact_edge"],
            "terrain_overlap_rows": spec["terrain_overlap_rows"],
            "pivot_px": [
                0,
                (spec["terrain_overlap_rows"] * 32),
            ],
            "footprint_size_cells": list(spec["footprint_cells"]),
            "chasm_core_rect": list(spec["chasm_core_rect"]),
            "claims_dressing_clearance": False,
            "tags": spec["tags"],
        }

    if args.dry_run:
        print()
        print("Dry-run complete. " "No files written.")
        return 0

    # -----------------------------------------------------------------------
    # Contracts
    # -----------------------------------------------------------------------

    contracts_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    for family in FAMILY_DOMAINS:
        contract_path = contracts_dir / f"{family}.asset.json"

        contract_path.write_text(
            json.dumps(
                family_contract(family),
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    # -----------------------------------------------------------------------
    # Reports
    # -----------------------------------------------------------------------

    prep_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    report_path = prep_dir / "normalization_report.json"

    handoff_path = prep_dir / "handoff.json"

    report_path.write_text(
        json.dumps(
            report,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    handoff_path.write_text(
        json.dumps(
            handoff,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    # -----------------------------------------------------------------------
    # Review
    # -----------------------------------------------------------------------

    contact_path = review_dir / "procgen_depth_chunks_v1_contact.png"

    make_contact_sheet(
        contact_outputs,
        contact_path,
    )

    print()
    print("Prep complete.")
    print()
    print(f"Handoff: {handoff_path}")
    print(f"Report:  {report_path}")
    print(f"Review:  {contact_path}")
    print()
    print("NO source masters modified.")
    print("NO runtime content written.")
    print("NO V2 ingest performed.")

    if args.review:
        try:
            subprocess.Popen(
                [
                    "aseprite",
                    str(contact_path),
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            print("Aseprite not found; " "contact sheet was still written.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
