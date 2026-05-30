#!/usr/bin/env python3
"""
Extract only The Sundered Keep floor tiles from:

  custodian/content/masters/sundered/sundered_floor_tiles.png

Writes runtime-ready 32x32 PNGs to:

  custodian/content/tiles/sundered_keep/floors/

Writes metadata to:

  custodian/content/tiles/sundered_keep/floors/_manifest.game32.json
  custodian/content/metadata/game32/sundered_keep_floor_tiles.game32.json

Requires:
  python -m pip install pillow
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image

TILE_SIZE = 32
ALPHA_THRESHOLD = 8

FLOOR_NAMES = [
    "main_courtyard_flagstone_01",
    "main_courtyard_flagstone_02",
    "main_courtyard_flagstone_cracked_01",
    "main_courtyard_flagstone_wet_01",
    "main_courtyard_flagstone_mossy_01",
    "main_gate_threshold_stone_01",
    "great_hall_marble_floor_01",
    "great_hall_marble_floor_cracked_01",
    "great_hall_carpet_runner_vertical_01",
    "great_hall_carpet_runner_horizontal_01",
    "rampart_walkway_floor_01",
    "rampart_walkway_broken_01",
    "cliff_rock_floor_01",
    "cliff_rock_floor_cracked_01",
    "roof_slate_dark_01",
    "dungeon_stone_floor_01",
    "undercroft_wet_stone_floor_01",
    "ocean_void_01",
]


@dataclass(frozen=True)
class FloorTileSpec:
    name: str
    row: int
    col: int


FLOOR_SPECS: List[FloorTileSpec] = [
    FloorTileSpec(name=name, row=i // 6, col=i % 6)
    for i, name in enumerate(FLOOR_NAMES)
]


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def rel_res_path(custodian_root: Path, path: Path) -> str:
    return "res://" + path.resolve().relative_to(custodian_root.resolve()).as_posix()


def find_custodian_root(arg_root: Optional[str]) -> Path:
    if arg_root:
        root = Path(arg_root).expanduser().resolve()
        if not (root / "content").exists():
            die(f"--custodian-root does not look like the Godot root: {root}")
        return root

    cwd = Path.cwd().resolve()
    candidates = [
        cwd / "custodian",
        cwd,
        cwd.parent / "custodian",
    ]

    for candidate in candidates:
        if (candidate / "content").exists():
            return candidate

    die("Could not detect custodian root. Pass --custodian-root ./custodian")


def is_edge_background_pixel(
    pixel: Tuple[int, int, int, int], bg_min: int, bg_delta: int
) -> bool:
    r, g, b, a = pixel

    if a <= ALPHA_THRESHOLD:
        return True

    maxc = max(r, g, b)
    minc = min(r, g, b)

    # Removes baked white/light-gray/checker backgrounds only when connected to image/cell edge.
    if minc >= bg_min and (maxc - minc) <= bg_delta:
        return True

    return False


def flood_remove_edge_background(
    img: Image.Image, bg_min: int, bg_delta: int
) -> Image.Image:
    """
    Make only edge-connected white/light background transparent.
    This avoids deleting pale marble inside actual floor tiles.
    """
    img = img.convert("RGBA")
    w, h = img.size
    pix = img.load()

    visited = bytearray(w * h)
    q: deque[Tuple[int, int]] = deque()

    def idx(x: int, y: int) -> int:
        return y * w + x

    def push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h:
            return

        i = idx(x, y)
        if visited[i]:
            return

        if not is_edge_background_pixel(pix[x, y], bg_min=bg_min, bg_delta=bg_delta):
            return

        visited[i] = 1
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)

    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while q:
        x, y = q.popleft()
        r, g, b, _a = pix[x, y]
        pix[x, y] = (r, g, b, 0)

        push(x + 1, y)
        push(x - 1, y)
        push(x, y + 1)
        push(x, y - 1)

    return img


def alpha_projection(img: Image.Image, axis: str) -> List[int]:
    alpha = img.getchannel("A")
    w, h = img.size
    apix = alpha.load()

    if axis == "x":
        return [
            sum(1 for y in range(h) if apix[x, y] > ALPHA_THRESHOLD) for x in range(w)
        ]

    if axis == "y":
        return [
            sum(1 for x in range(w) if apix[x, y] > ALPHA_THRESHOLD) for y in range(h)
        ]

    raise ValueError(axis)


def bands_from_projection(proj: List[int], threshold: int) -> List[Tuple[int, int]]:
    bands: List[Tuple[int, int]] = []
    start: Optional[int] = None

    for i, value in enumerate(proj):
        if value >= threshold and start is None:
            start = i
        elif value < threshold and start is not None:
            bands.append((start, i))
            start = None

    if start is not None:
        bands.append((start, len(proj)))

    return bands


def merge_close_bands(
    bands: List[Tuple[int, int]], max_gap: int
) -> List[Tuple[int, int]]:
    if not bands:
        return bands

    merged = [bands[0]]

    for start, end in bands[1:]:
        prev_start, prev_end = merged[-1]
        gap = start - prev_end

        if gap <= max_gap:
            merged[-1] = (prev_start, end)
        else:
            merged.append((start, end))

    return merged


def coerce_band_count(
    bands: List[Tuple[int, int]],
    expected: int,
    global_start: int,
    global_end: int,
) -> List[Tuple[int, int]]:
    bands = list(bands)

    if len(bands) == expected:
        return bands

    if len(bands) > expected:
        while len(bands) > expected:
            gaps = [(bands[i + 1][0] - bands[i][1], i) for i in range(len(bands) - 1)]
            _gap, i = min(gaps, key=lambda t: t[0])
            bands = bands[:i] + [(bands[i][0], bands[i + 1][1])] + bands[i + 2 :]
        return bands

    # Fallback: equal slicing across detected ink span.
    span = max(1, global_end - global_start)
    step = span / expected

    return [
        (
            int(round(global_start + i * step)),
            int(round(global_start + (i + 1) * step)),
        )
        for i in range(expected)
    ]


def find_axis_bands(
    img: Image.Image, axis: str, expected: int
) -> List[Tuple[int, int]]:
    proj = alpha_projection(img, axis)
    max_proj = max(proj) if proj else 0

    if max_proj <= 0:
        die("No visible pixels after background cleanup.")

    threshold = max(1, int(max_proj * 0.025))
    raw_bands = bands_from_projection(proj, threshold=threshold)
    merged = merge_close_bands(raw_bands, max_gap=18)

    ink_indices = [i for i, value in enumerate(proj) if value >= threshold]
    global_start = min(ink_indices)
    global_end = max(ink_indices) + 1

    return coerce_band_count(
        merged,
        expected=expected,
        global_start=global_start,
        global_end=global_end,
    )


def alpha_bbox(img: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    return img.getchannel("A").getbbox()


def crop_cell_to_ink(
    sheet: Image.Image,
    cell_box: Tuple[int, int, int, int],
    pad: int,
) -> Tuple[Image.Image, Tuple[int, int, int, int]]:
    cell = sheet.crop(cell_box)
    bbox = alpha_bbox(cell)

    if bbox is None:
        raise ValueError(f"Empty cell: {cell_box}")

    cx0, cy0, _cx1, _cy1 = cell_box
    lx0, ly0, lx1, ly1 = bbox

    source_box = (
        max(cell_box[0], cx0 + lx0 - pad),
        max(cell_box[1], cy0 + ly0 - pad),
        min(cell_box[2], cx0 + lx1 + pad),
        min(cell_box[3], cy0 + ly1 + pad),
    )

    return sheet.crop(source_box), source_box


def paste_fit_32(src: Image.Image, resample: str) -> Tuple[Image.Image, Dict[str, Any]]:
    """
    Fit the extracted tile art into a 32x32 transparent runtime canvas.
    """
    src = src.convert("RGBA")
    bbox = alpha_bbox(src)

    if bbox is None:
        return Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0)), {
            "scale": 1.0,
            "paste_xy": [0, 0],
            "trimmed_source_box": None,
        }

    trimmed = src.crop(bbox)
    tw, th = trimmed.size

    scale = min(TILE_SIZE / max(1, tw), TILE_SIZE / max(1, th))
    new_w = max(1, min(TILE_SIZE, int(round(tw * scale))))
    new_h = max(1, min(TILE_SIZE, int(round(th * scale))))

    if resample == "nearest":
        resample_filter = Image.Resampling.NEAREST
    else:
        resample_filter = Image.Resampling.LANCZOS

    resized = trimmed.resize((new_w, new_h), resample=resample_filter)

    out = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
    px = (TILE_SIZE - new_w) // 2
    py = (TILE_SIZE - new_h) // 2
    out.alpha_composite(resized, (px, py))

    return out, {
        "scale": scale,
        "paste_xy": [px, py],
        "trimmed_source_box": list(bbox),
        "resized_px": [new_w, new_h],
    }


def tile_tags(name: str) -> List[str]:
    tags = ["sundered_keep", "floor_tile", "grid32"]

    if "flagstone" in name:
        tags += ["courtyard", "flagstone", "stone"]
    if "cracked" in name or "broken" in name:
        tags += ["damaged"]
    if "wet" in name:
        tags += ["wet"]
    if "mossy" in name:
        tags += ["moss"]
    if "threshold" in name:
        tags += ["gatehouse", "threshold", "transition"]
    if "marble" in name:
        tags += ["great_hall", "marble", "interior"]
    if "carpet" in name:
        tags += ["great_hall", "carpet", "decorative"]
    if "rampart" in name:
        tags += ["rampart", "exterior", "walkway"]
    if "cliff" in name:
        tags += ["cliff", "rock", "exterior"]
    if "roof" in name:
        tags += ["roof", "slate", "elevated"]
    if "dungeon" in name:
        tags += ["dungeon", "interior"]
    if "undercroft" in name:
        tags += ["undercroft", "wet", "interior"]
    if "ocean_void" in name:
        tags += ["ocean", "void", "blocked", "hazard"]

    return sorted(set(tags))


def tile_description(name: str) -> str:
    descriptions = {
        "main_courtyard_flagstone_01": "Primary worn gothic courtyard flagstone floor tile.",
        "main_courtyard_flagstone_02": "Alternate worn gothic courtyard flagstone floor tile.",
        "main_courtyard_flagstone_cracked_01": "Cracked courtyard flagstone tile for damaged exterior keep surfaces.",
        "main_courtyard_flagstone_wet_01": "Wet dark courtyard flagstone tile for rain, sea spray, and damp exterior zones.",
        "main_courtyard_flagstone_mossy_01": "Mossy courtyard flagstone tile for overgrown keep edges.",
        "main_gate_threshold_stone_01": "Heavy threshold stone tile for main gate and portcullis entry transitions.",
        "great_hall_marble_floor_01": "Ceremonial great hall marble floor tile.",
        "great_hall_marble_floor_cracked_01": "Cracked ceremonial marble floor tile for ruined great hall sections.",
        "great_hall_carpet_runner_vertical_01": "Vertical crimson-and-gold great hall carpet runner tile.",
        "great_hall_carpet_runner_horizontal_01": "Horizontal crimson-and-gold great hall carpet runner tile.",
        "rampart_walkway_floor_01": "Exterior rampart walkway floor tile.",
        "rampart_walkway_broken_01": "Broken exterior rampart walkway tile.",
        "cliff_rock_floor_01": "Jagged cliff rock ground tile.",
        "cliff_rock_floor_cracked_01": "Cracked jagged cliff rock ground tile.",
        "roof_slate_dark_01": "Dark slate roof tile for elevated keep surfaces.",
        "dungeon_stone_floor_01": "Dark dungeon stone floor tile.",
        "undercroft_wet_stone_floor_01": "Wet undercroft stone floor tile.",
        "ocean_void_01": "Dark ocean void tile for unreachable water or drop-edge zones.",
    }

    return descriptions.get(name, name.replace("_", " "))


def game32_for_tile(name: str) -> Dict[str, Any]:
    is_ocean_void = name == "ocean_void_01"

    return {
        "tile_size_px": 32,
        "runtime_canvas_px": [32, 32],
        "logical_footprint_cells": [1, 1],
        "logical_footprint_px": [32, 32],
        "anchor": "top_left",
        "pivot": "top_left",
        "placement_rule": "snap_to_grid32",
        "z_layer": "ground",
        "z_index": 0,
        "y_sort": False,
        "walkable": not is_ocean_void,
        "blocks_movement": is_ocean_void,
        "blocks_projectiles": False,
        "blocks_vision": False,
        "traversal": "void_blocked" if is_ocean_void else "walkable",
        "collision": {
            "enabled": is_ocean_void,
            "profile": "void_blocker" if is_ocean_void else "none",
            "shape": "rect" if is_ocean_void else "none",
            "rect_px": [0, 0, 32, 32] if is_ocean_void else None,
        },
        "navigation": {
            "can_pathfind": not is_ocean_void,
            "cost": None if is_ocean_void else 1.0,
            "avoidance": "blocked" if is_ocean_void else "normal",
        },
        "combat": {
            "cover_profile": "none",
            "line_of_sight_profile": "transparent",
            "projectile_profile": "passable",
        },
        "render": {
            "allowed_layers": ["ground", "floor"],
            "import_filter": "nearest_or_disabled_in_godot",
            "mipmaps": False,
        },
        "tags": tile_tags(name),
    }


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )


def doc_drift_check(custodian_root: Path) -> Dict[str, Any]:
    repo_root = (
        custodian_root.parent if custodian_root.name == "custodian" else custodian_root
    )

    checks = [
        ("custodian_root", custodian_root),
        ("content_dir", custodian_root / "content"),
        ("active_runtime_docs", custodian_root / "docs"),
        ("active_ai_context", custodian_root / "docs" / "ai_context"),
        (
            "current_state_doc",
            custodian_root / "docs" / "ai_context" / "CURRENT_STATE.md",
        ),
        ("repo_design_dir", repo_root / "design"),
        ("agents_md", repo_root / "AGENTS.md"),
    ]

    rows = [
        {
            "key": key,
            "path": str(path),
            "exists": path.exists(),
            "type": "dir" if path.exists() and path.is_dir() else "file",
        }
        for key, path in checks
    ]

    missing = [row for row in rows if not row["exists"]]

    return {
        "checked_at_utc": utc_now(),
        "status": "ok" if not missing else "missing_or_drift_detected",
        "missing_count": len(missing),
        "checks": rows,
        "recommendation": (
            "If these floor tiles are accepted into runtime, add a short note to "
            "custodian/docs/ai_context/CURRENT_STATE.md with the new floor tile "
            "domain path and metadata manifest path."
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--custodian-root",
        default=None,
        help="Godot project root. Default: auto-detect ./custodian",
    )
    parser.add_argument(
        "--source",
        default=None,
        help="Source sheet. Default: <custodian-root>/content/masters/sundered/sundered_floor_tiles.png",
    )
    parser.add_argument(
        "--out-dir",
        default=None,
        help="Output dir. Default: <custodian-root>/content/tiles/sundered_keep/floors",
    )
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument(
        "--pad",
        type=int,
        default=2,
        help="Padding around detected source art before fitting to 32x32.",
    )
    parser.add_argument(
        "--bg-min",
        type=int,
        default=215,
        help="Minimum RGB channel value treated as edge-connected light background.",
    )
    parser.add_argument(
        "--bg-delta",
        type=int,
        default=45,
        help="Max RGB channel spread treated as neutral light background.",
    )
    parser.add_argument(
        "--resample",
        choices=["lanczos", "nearest"],
        default="lanczos",
        help="Downscale filter. lanczos is better for generated high-res sheets; nearest is stricter pixel-art.",
    )
    args = parser.parse_args()

    custodian_root = find_custodian_root(args.custodian_root)

    source = (
        Path(args.source).expanduser().resolve()
        if args.source
        else custodian_root
        / "content"
        / "masters"
        / "sundered"
        / "sundered_floor_tiles.png"
    )

    out_dir = (
        Path(args.out_dir).expanduser().resolve()
        if args.out_dir
        else custodian_root / "content" / "tiles" / "sundered_keep" / "floors"
    )

    if not source.exists():
        die(f"Missing source sheet: {source}")

    if out_dir.exists() and not args.overwrite:
        existing_pngs = list(out_dir.glob("*.png"))
        if existing_pngs:
            die(f"Output dir already has PNGs. Use --overwrite: {out_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)

    raw = Image.open(source).convert("RGBA")
    cleaned = flood_remove_edge_background(
        raw, bg_min=args.bg_min, bg_delta=args.bg_delta
    )

    x_bands = find_axis_bands(cleaned, axis="x", expected=6)
    y_bands = find_axis_bands(cleaned, axis="y", expected=3)

    assets: List[Dict[str, Any]] = []

    for index, spec in enumerate(FLOOR_SPECS):
        cell_box = (
            x_bands[spec.col][0],
            y_bands[spec.row][0],
            x_bands[spec.col][1],
            y_bands[spec.row][1],
        )

        try:
            source_crop, crop_box = crop_cell_to_ink(cleaned, cell_box, pad=args.pad)
        except ValueError as exc:
            die(f"{exc} for {spec.name}")

        runtime_img, fit_info = paste_fit_32(source_crop, resample=args.resample)

        out_path = out_dir / f"{spec.name}.png"
        if out_path.exists() and not args.overwrite:
            die(f"Refusing to overwrite: {out_path}")

        runtime_img.save(out_path)

        asset_meta = {
            "id": f"sundered_keep/floors/{spec.name}",
            "name": spec.name,
            "filename": out_path.name,
            "description": tile_description(spec.name),
            "asset_class": "floor_tile",
            "domain": "floors",
            "runtime_path": rel_res_path(custodian_root, out_path),
            "source": {
                "master_sheet": source.name,
                "master_sheet_path": rel_res_path(custodian_root, source),
                "master_sheet_size_px": list(raw.size),
                "sheet_grid": {
                    "rows": 3,
                    "cols": 6,
                    "row": spec.row,
                    "col": spec.col,
                    "index": index,
                    "order": "reading_order_left_to_right_top_to_bottom",
                },
                "detected_cell_box_px": list(cell_box),
                "crop_box_px": list(crop_box),
            },
            "image": {
                "runtime_canvas_px": [32, 32],
                "format": "png_rgba",
                "sha256": sha256_file(out_path),
                "fit": fit_info,
                "background": "transparent",
            },
            "game32": game32_for_tile(spec.name),
        }

        assets.append(asset_meta)
        print(f"wrote: {out_path}")

    domain_manifest = {
        "schema": "custodian.game32.domain_manifest.v1",
        "name": "sundered_keep_floor_tiles",
        "generated_at_utc": utc_now(),
        "domain": "floors",
        "asset_class": "floor_tile",
        "source_sheet": rel_res_path(custodian_root, source),
        "domain_home": rel_res_path(custodian_root, out_dir),
        "count": len(assets),
        "assets": assets,
    }

    full_manifest = {
        "schema": "custodian.game32.asset_manifest.v1",
        "name": "sundered_keep_floor_tiles",
        "generated_at_utc": utc_now(),
        "generator": Path(__file__).name,
        "game32": {
            "tile_size_px": 32,
            "coordinate_system": "grid32_top_down_2_5d",
            "runtime": "Godot 4.x",
            "usage": {
                "floors": "snap top-left to 32x32 grid cell",
                "metadata_authority": "content/metadata/game32/sundered_keep_floor_tiles.game32.json",
            },
        },
        "source": {
            "sheet": {
                "path": rel_res_path(custodian_root, source),
                "size_px": list(raw.size),
                "sha256": sha256_file(source),
                "grid": {"rows": 3, "cols": 6},
            }
        },
        "outputs": {
            "domain_home": rel_res_path(custodian_root, out_dir),
            "count": len(assets),
        },
        "assets": assets,
        "doc_drift_check": doc_drift_check(custodian_root),
    }

    write_json(out_dir / "_manifest.game32.json", domain_manifest)

    manifest_path = (
        custodian_root
        / "content"
        / "metadata"
        / "game32"
        / "sundered_keep_floor_tiles.game32.json"
    )
    write_json(manifest_path, full_manifest)

    report_path = out_dir / "_extraction_report.md"
    report_path.write_text(
        "\n".join(
            [
                "# Sundered Keep Floor Tile Extraction Report",
                "",
                f"- Generated: `{utc_now()}`",
                f"- Source: `{source}`",
                f"- Output: `{out_dir}`",
                f"- Extracted: `{len(assets)}` floor tiles",
                f"- Manifest: `{manifest_path}`",
                "",
                "## Follow-up",
                "",
                "- Verify the 32x32 outputs visually in Aseprite.",
                "- In Godot import settings, disable filter/mipmaps for these PNGs.",
                "- If the source sheet layout changes, rerun with `--overwrite`.",
                "- If pale checker/white remains, rerun with lower `--bg-min`, e.g. `--bg-min 190 --bg-delta 70`.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    print()
    print("Done.")
    print(f"Extracted floor tiles: {len(assets)}")
    print(f"Output dir: {out_dir}")
    print(f"Domain manifest: {out_dir / '_manifest.game32.json'}")
    print(f"Full manifest: {manifest_path}")
    print(f"Report: {report_path}")


if __name__ == "__main__":
    main()
