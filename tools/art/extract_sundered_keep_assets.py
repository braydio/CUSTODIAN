#!/usr/bin/env python3
"""
Extract The Sundered Keep master sheets into runtime-ready domain assets
and write full Game32 metadata.

Expected master inputs:

  custodian/content/masters/sundered/
    great_hall_walls.png
    sundered_ramparts.png
    sundered_floor_tiles.png
    sundered_walls_gates.png

Outputs:

  custodian/content/tiles/sundered/floors/*.png
  custodian/content/tiles/sundered/walls/gothic_castle/*.png
  custodian/content/tiles/sundered/walls/great_hall/*.png
  custodian/content/tiles/sundered/walls/ramparts/*.png

  custodian/content/metadata/game32/sundered_keep.game32.json
  custodian/content/metadata/game32/sundered_keep.game32.gd
  custodian/content/masters/sundered/_sundered_keep_extraction_report.md

Requires:
  python -m pip install pillow
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import defaultdict, deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

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


def oriented(prefix: str, dirs: Iterable[str] = ("n", "e", "s", "w")) -> List[str]:
    return [f"{prefix}_{d}" for d in dirs]


def cornered(prefix: str) -> List[str]:
    return [f"{prefix}_{d}" for d in ("ne", "nw", "se", "sw")]


GOTHIC_WALL_NAMES = (
    oriented("gothic_castle_wall_straight")
    + cornered("gothic_castle_wall_inner_corner")
    + cornered("gothic_castle_wall_outer_corner")
    + oriented("gothic_castle_wall_endcap")
    + oriented("gothic_castle_wall_damaged")
    + oriented("gothic_castle_wall_breach")
    + oriented("gothic_castle_wall_window_tall")
    + oriented("gothic_castle_wall_arch")
)

GREAT_HALL_WALL_NAMES = (
    oriented("great_hall_wall_straight")
    + oriented("great_hall_wall_column")
    + oriented("great_hall_wall_banner")
    + oriented("great_hall_wall_broken_exterior")
)

RAMPART_NAMES = (
    oriented("rampart_parapet")
    + oriented("rampart_crenellation")
    + oriented("rampart_broken_gap")
)


@dataclass(frozen=True)
class SheetSpec:
    source_file: str
    rows: int
    cols: int
    names: List[str]
    domain_key: str
    domain_home_rel: str
    asset_class: str


SHEETS: List[SheetSpec] = [
    SheetSpec(
        source_file="sundered_floor_tiles.png",
        rows=3,
        cols=6,
        names=FLOOR_NAMES,
        domain_key="floors",
        domain_home_rel="content/tiles/sundered/floors",
        asset_class="floor_tile",
    ),
    SheetSpec(
        source_file="sundered_walls_gates.png",
        rows=8,
        cols=4,
        names=GOTHIC_WALL_NAMES,
        domain_key="gothic_castle_walls",
        domain_home_rel="content/tiles/sundered/walls/gothic_castle",
        asset_class="wall_module",
    ),
    SheetSpec(
        source_file="great_hall_walls.png",
        rows=4,
        cols=4,
        names=GREAT_HALL_WALL_NAMES,
        domain_key="great_hall_walls",
        domain_home_rel="content/tiles/sundered/walls/great_hall",
        asset_class="wall_module",
    ),
    SheetSpec(
        source_file="sundered_ramparts.png",
        rows=3,
        cols=4,
        names=RAMPART_NAMES,
        domain_key="ramparts",
        domain_home_rel="content/tiles/sundered/walls/ramparts",
        asset_class="rampart_module",
    ),
]


def die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
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
    rel = path.resolve().relative_to(custodian_root.resolve())
    return "res://" + rel.as_posix()


def looks_like_light_checker_bg(pixel: Tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= ALPHA_THRESHOLD:
        return True

    maxc = max(r, g, b)
    minc = min(r, g, b)

    # The generated files commonly have a baked white/light-gray checkerboard.
    # This predicate is intentionally conservative and only flood-fills from edges.
    if minc >= 224 and (maxc - minc) <= 22:
        return True
    if r >= 238 and g >= 238 and b >= 238:
        return True

    return False


def flood_transparentize_background(img: Image.Image) -> Image.Image:
    """
    Remove baked light checkerboard/background by flood filling only from the
    outer image edges. This avoids deleting pale marble pixels inside actual tiles.
    """
    img = img.convert("RGBA")
    w, h = img.size
    pix = img.load()
    visited = bytearray(w * h)
    q: deque[Tuple[int, int]] = deque()

    def idx(x: int, y: int) -> int:
        return y * w + x

    def push_if_bg(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h:
            return
        i = idx(x, y)
        if visited[i]:
            return
        if not looks_like_light_checker_bg(pix[x, y]):
            return
        visited[i] = 1
        q.append((x, y))

    for x in range(w):
        push_if_bg(x, 0)
        push_if_bg(x, h - 1)
    for y in range(h):
        push_if_bg(0, y)
        push_if_bg(w - 1, y)

    while q:
        x, y = q.popleft()
        r, g, b, _a = pix[x, y]
        pix[x, y] = (r, g, b, 0)

        push_if_bg(x + 1, y)
        push_if_bg(x - 1, y)
        push_if_bg(x, y + 1)
        push_if_bg(x, y - 1)

    return img


def alpha_projection(img: Image.Image, axis: str) -> List[int]:
    alpha = img.getchannel("A")
    w, h = img.size
    apix = alpha.load()

    if axis == "x":
        out = []
        for x in range(w):
            count = 0
            for y in range(h):
                if apix[x, y] > ALPHA_THRESHOLD:
                    count += 1
            out.append(count)
        return out

    if axis == "y":
        out = []
        for y in range(h):
            count = 0
            for x in range(w):
                if apix[x, y] > ALPHA_THRESHOLD:
                    count += 1
            out.append(count)
        return out

    raise ValueError(axis)


def initial_bands(proj: List[int], threshold: int) -> List[Tuple[int, int]]:
    bands: List[Tuple[int, int]] = []
    start: Optional[int] = None

    for i, v in enumerate(proj):
        if v >= threshold and start is None:
            start = i
        elif v < threshold and start is not None:
            bands.append((start, i))
            start = None

    if start is not None:
        bands.append((start, len(proj)))

    return bands


def merge_close_bands(
    bands: List[Tuple[int, int]],
    merge_gap_px: int,
) -> List[Tuple[int, int]]:
    if not bands:
        return bands

    merged = [bands[0]]
    for start, end in bands[1:]:
        prev_start, prev_end = merged[-1]
        gap = start - prev_end
        if gap <= merge_gap_px:
            merged[-1] = (prev_start, end)
        else:
            merged.append((start, end))
    return merged


def force_expected_band_count(
    bands: List[Tuple[int, int]],
    expected: int,
    global_start: int,
    global_end: int,
) -> List[Tuple[int, int]]:
    """
    If projection detection over/under-splits, coerce to the expected count.
    Over-split: merge nearest bands.
    Under-split: fall back to equal slots across global ink span.
    """
    bands = list(bands)

    if len(bands) == expected:
        return bands

    if len(bands) > expected:
        while len(bands) > expected:
            gaps = [(bands[i + 1][0] - bands[i][1], i) for i in range(len(bands) - 1)]
            _gap, i = min(gaps, key=lambda x: x[0])
            merged = (bands[i][0], bands[i + 1][1])
            bands = bands[:i] + [merged] + bands[i + 2 :]
        return bands

    # Under-split fallback.
    span = max(1, global_end - global_start)
    step = span / expected
    equal = []
    for i in range(expected):
        start = int(round(global_start + i * step))
        end = int(round(global_start + (i + 1) * step))
        equal.append((start, end))
    return equal


def find_axis_bands(img: Image.Image, axis: str, expected: int) -> List[Tuple[int, int]]:
    proj = alpha_projection(img, axis)
    max_proj = max(proj) if proj else 0
    if max_proj <= 0:
        die("No visible pixels after background removal.")

    threshold = max(1, int(max_proj * 0.025))
    bands = initial_bands(proj, threshold=threshold)

    # Allow holes inside sprites, but do not merge real grid gaps.
    bands = merge_close_bands(bands, merge_gap_px=18)

    ink_indices = [i for i, v in enumerate(proj) if v >= threshold]
    global_start = min(ink_indices)
    global_end = max(ink_indices) + 1

    return force_expected_band_count(bands, expected, global_start, global_end)


def bbox_for_alpha(img: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    return img.getchannel("A").getbbox()


def crop_with_padding(
    img: Image.Image,
    box: Tuple[int, int, int, int],
    pad: int,
) -> Tuple[Image.Image, Tuple[int, int, int, int]]:
    w, h = img.size
    x0, y0, x1, y1 = box
    padded = (
        max(0, x0 - pad),
        max(0, y0 - pad),
        min(w, x1 + pad),
        min(h, y1 + pad),
    )
    return img.crop(padded), padded


def mask_bbox_inside(
    img: Image.Image,
    cell_box: Tuple[int, int, int, int],
) -> Optional[Tuple[int, int, int, int]]:
    cell = img.crop(cell_box)
    local = bbox_for_alpha(cell)
    if not local:
        return None

    cx0, cy0, _cx1, _cy1 = cell_box
    lx0, ly0, lx1, ly1 = local
    return (cx0 + lx0, cy0 + ly0, cx0 + lx1, cy0 + ly1)


def infer_orientation(name: str) -> Optional[str]:
    suffix = name.rsplit("_", 1)[-1]
    if suffix in {"n", "e", "s", "w", "ne", "nw", "se", "sw"}:
        return suffix
    return None


def infer_variant_group(name: str) -> str:
    orientation = infer_orientation(name)
    if orientation:
        return name[: -(len(orientation) + 1)]
    if name.endswith("_01") or name.endswith("_02"):
        return name.rsplit("_", 1)[0]
    return name


def readable_description(name: str) -> str:
    n = name.replace("_", " ")

    if name == "ocean_void_01":
        return "Storm-dark haunted ocean void tile for cliffs, drops, and unreachable surrounding water."
    if "carpet_runner_vertical" in name:
        return "Vertical great-hall crimson carpet runner tile with gothic gold ornamentation."
    if "carpet_runner_horizontal" in name:
        return "Horizontal great-hall crimson carpet runner tile with gothic gold ornamentation."
    if "threshold" in name:
        return "Main gate threshold stone tile for entry transitions, portcullis bases, and gatehouse thresholds."
    if "flagstone" in name:
        return f"Main courtyard {n}; dark weathered gothic stone floor variant."
    if "marble_floor" in name:
        return f"Great hall {n}; ceremonial stone or marble floor variant."
    if "rampart_walkway" in name:
        return f"Rampart walkway {n}; exterior walkable stone tile for battlements."
    if "cliff_rock" in name:
        return f"Cliff rock {n}; jagged island rock surface for sheer ocean-side terrain."
    if "roof_slate" in name:
        return "Dark slate roof tile for rooftop floors and elevated keep surfaces."
    if "dungeon_stone" in name:
        return "Dungeon stone floor tile for lower keep prison or service rooms."
    if "undercroft" in name:
        return "Wet undercroft stone floor tile with damp shine and lower-level drainage feel."

    if "gothic_castle_wall" in name:
        return f"Exterior gothic castle wall module: {n}."
    if "great_hall_wall" in name:
        return f"Interior great hall wall module: {n}."
    if "rampart" in name:
        return f"Exterior rampart module: {n}."

    return f"Sundered Keep runtime asset: {n}."


def infer_game32(name: str, spec: SheetSpec) -> Dict[str, Any]:
    orientation = infer_orientation(name)
    tags = ["sundered_keep", spec.domain_key]
    walkable = False
    blocks_movement = True
    blocks_projectiles = True
    blocks_vision = True
    collision_profile = "solid_base_cell"
    cover_profile = "high"
    occluder = True
    z_layer = "architecture"
    z_index = 30
    y_sort = True
    pivot = "bottom_center"
    allowed_layers = ["architecture", "walls"]
    placement_rule = "snap_bottom_to_grid32"
    traversal = "blocked"

    if spec.asset_class == "floor_tile":
        walkable = True
        blocks_movement = False
        blocks_projectiles = False
        blocks_vision = False
        collision_profile = "none"
        cover_profile = "none"
        occluder = False
        z_layer = "ground"
        z_index = 0
        y_sort = False
        pivot = "top_left"
        allowed_layers = ["ground", "floor"]
        placement_rule = "snap_to_grid32"
        traversal = "walkable"

        if name == "ocean_void_01":
            walkable = False
            traversal = "void_blocked"
            tags += ["void", "ocean", "hazard", "non_walkable"]
        elif "wet" in name:
            tags += ["wet", "stone"]
        elif "mossy" in name:
            tags += ["moss", "stone"]
        elif "cracked" in name or "broken" in name:
            tags += ["damaged", "stone"]
        elif "carpet" in name:
            tags += ["interior", "carpet", "decorative"]
        elif "roof" in name:
            tags += ["roof", "slate", "elevated"]
        elif "cliff" in name:
            tags += ["cliff", "rock", "exterior"]
        else:
            tags += ["stone"]

    else:
        tags += ["wall", "vertical_sprite"]

        if "breach" in name or "arch" in name:
            walkable = True
            blocks_movement = False
            blocks_projectiles = False
            blocks_vision = False if "arch" in name else True
            collision_profile = "opening"
            cover_profile = "low_partial"
            traversal = "passage"
            tags += ["opening"]
        elif "broken_gap" in name:
            walkable = True
            blocks_movement = False
            blocks_projectiles = False
            blocks_vision = False
            collision_profile = "edge_gap"
            cover_profile = "none"
            traversal = "gap_or_fall_edge"
            tags += ["broken", "gap", "fall_risk"]
        elif "window_tall" in name:
            tags += ["window", "solid", "occluder"]
        elif "damaged" in name or "broken_exterior" in name:
            tags += ["damaged", "rubble", "solid"]
        elif "banner" in name:
            tags += ["banner", "interior", "decorative", "solid"]
        elif "column" in name:
            tags += ["column", "interior", "solid"]
        elif "crenellation" in name:
            tags += ["crenellation", "parapet", "solid"]
        elif "parapet" in name:
            tags += ["parapet", "edge", "solid"]
        else:
            tags += ["solid"]

    if orientation:
        tags.append(f"facing_{orientation}")

    return {
        "tile_size_px": TILE_SIZE,
        "logical_footprint_cells": [1, 1],
        "logical_footprint_px": [TILE_SIZE, TILE_SIZE],
        "orientation": orientation,
        "variant_group": infer_variant_group(name),
        "walkable": walkable,
        "blocks_movement": blocks_movement,
        "blocks_projectiles": blocks_projectiles,
        "blocks_vision": blocks_vision,
        "traversal": traversal,
        "collision": {
            "profile": collision_profile,
            "enabled": blocks_movement,
            "base_cell_rect_px": [0, 0, TILE_SIZE, TILE_SIZE],
            "shape": "rect",
            "applies_to": "logical_base_cell",
        },
        "navigation": {
            "cost": 1.0 if walkable else None,
            "can_pathfind": walkable,
            "avoidance": "normal" if walkable else "blocked",
        },
        "combat": {
            "cover_profile": cover_profile,
            "line_of_sight_profile": "occluding" if blocks_vision else "transparent",
            "projectile_profile": "blocking" if blocks_projectiles else "passable",
        },
        "render": {
            "z_layer": z_layer,
            "z_index": z_index,
            "y_sort": y_sort,
            "pivot": pivot,
            "placement_rule": placement_rule,
            "allowed_layers": allowed_layers,
            "shadow_policy": "baked_in_source",
            "occluder_recommended": occluder,
        },
        "tags": sorted(set(tags)),
    }


def build_asset_metadata(
    custodian_root: Path,
    spec: SheetSpec,
    source_path: Path,
    out_path: Path,
    name: str,
    index: int,
    row: int,
    col: int,
    source_size: Tuple[int, int],
    cell_box: Tuple[int, int, int, int],
    crop_box: Tuple[int, int, int, int],
    exported_size: Tuple[int, int],
) -> Dict[str, Any]:
    return {
        "id": f"sundered_keep/{spec.domain_key}/{name}",
        "name": name,
        "filename": f"{name}.png",
        "description": readable_description(name),
        "asset_class": spec.asset_class,
        "domain": spec.domain_key,
        "domain_home": rel_res_path(custodian_root, out_path.parent),
        "runtime_path": rel_res_path(custodian_root, out_path),
        "source": {
            "master_sheet": source_path.name,
            "master_sheet_path": rel_res_path(custodian_root, source_path),
            "master_sheet_size_px": list(source_size),
            "sheet_grid": {
                "rows": spec.rows,
                "cols": spec.cols,
                "row": row,
                "col": col,
                "index": index,
                "order": "reading_order_left_to_right_top_to_bottom",
            },
            "cell_box_px": list(cell_box),
            "crop_box_px": list(crop_box),
        },
        "image": {
            "exported_size_px": list(exported_size),
            "format": "png_rgba",
            "background": "transparent_after_edge_flood_cleanup",
        },
        "game32": infer_game32(name, spec),
    }


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def write_gd_manifest_stub(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        """# Generated by extract_sundered_keep_assets.py
# Load the full metadata JSON at MANIFEST_PATH.

extends RefCounted

const MANIFEST_PATH := "res://content/metadata/game32/sundered_keep.game32.json"

static func load_manifest() -> Dictionary:
\tvar file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
\tif file == null:
\t\tpush_error("Could not open Sundered Keep Game32 manifest: " + MANIFEST_PATH)
\t\treturn {}
\tvar parsed = JSON.parse_string(file.get_as_text())
\tif typeof(parsed) != TYPE_DICTIONARY:
\t\tpush_error("Invalid Sundered Keep Game32 manifest JSON: " + MANIFEST_PATH)
\t\treturn {}
\treturn parsed
""",
        encoding="utf-8",
    )


def find_custodian_root(arg_root: Optional[str]) -> Path:
    if arg_root:
        root = Path(arg_root).expanduser().resolve()
        if not (root / "content").exists():
            die(f"--custodian-root does not look like the Godot root: {root}")
        return root

    cwd = Path.cwd().resolve()
    candidates = [
        cwd,
        cwd / "custodian",
        cwd.parent / "custodian",
    ]

    for c in candidates:
        if (c / "content" / "masters" / "sundered").exists():
            return c

    die(
        "Could not auto-detect custodian root. Run from repo root or pass "
        "--custodian-root /home/braydenchaffee/Projects/CUSTODIAN/custodian"
    )


def doc_drift_check(custodian_root: Path, source_dir: Path) -> Dict[str, Any]:
    repo_root = custodian_root.parent if custodian_root.name == "custodian" else custodian_root

    required_paths = {
        "active_runtime_root": custodian_root,
        "active_runtime_docs": custodian_root / "docs",
        "active_ai_context": custodian_root / "docs" / "ai_context",
        "active_ai_context_current_state": custodian_root / "docs" / "ai_context" / "CURRENT_STATE.md",
        "godot_native_design_specs": repo_root / "design",
        "locked_master_doctrine": repo_root / "python-sim" / "design" / "MASTER_DESIGN_DOCTRINE.md",
        "sundered_master_source_dir": source_dir,
    }

    master_files = {
        spec.source_file: source_dir / spec.source_file
        for spec in SHEETS
    }

    checks = []
    for key, path in {**required_paths, **master_files}.items():
        checks.append(
            {
                "key": key,
                "path": str(path),
                "exists": path.exists(),
                "type": "dir" if path.exists() and path.is_dir() else "file",
            }
        )

    missing = [c for c in checks if not c["exists"]]

    recommendations = []
    if missing:
        recommendations.append(
            "Resolve missing path(s), or update AGENTS.md / active docs if the project layout intentionally changed."
        )

    if (custodian_root / "docs" / "ai_context").exists():
        recommendations.append(
            "After accepting these runtime assets, add a short note to custodian/docs/ai_context/CURRENT_STATE.md describing the new Sundered Keep tile domains and Game32 manifest path."
        )

    return {
        "checked_at_utc": utc_now(),
        "repo_root_guess": str(repo_root),
        "custodian_root": str(custodian_root),
        "checks": checks,
        "missing_count": len(missing),
        "status": "ok" if not missing else "drift_or_missing_paths_detected",
        "recommendations": recommendations,
    }


def write_report(
    report_path: Path,
    manifest_path: Path,
    domain_counts: Dict[str, int],
    doc_check: Dict[str, Any],
) -> None:
    lines = [
        "# Sundered Keep Asset Extraction Report",
        "",
        f"- Generated: `{utc_now()}`",
        f"- Manifest: `{manifest_path}`",
        "",
        "## Extracted Domains",
        "",
    ]

    for domain, count in sorted(domain_counts.items()):
        lines.append(f"- `{domain}`: {count} assets")

    lines += [
        "",
        "## Documentation Drift Check",
        "",
        f"- Status: `{doc_check['status']}`",
        f"- Missing count: `{doc_check['missing_count']}`",
        "",
        "### Checked Paths",
        "",
    ]

    for check in doc_check["checks"]:
        marker = "OK" if check["exists"] else "MISSING"
        lines.append(f"- `{marker}` `{check['key']}` → `{check['path']}`")

    lines += [
        "",
        "### Recommended Follow-Up",
        "",
    ]

    for rec in doc_check["recommendations"]:
        lines.append(f"- {rec}")

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def extract_sheet(
    custodian_root: Path,
    source_dir: Path,
    spec: SheetSpec,
    overwrite: bool,
    pad: int,
) -> List[Dict[str, Any]]:
    if len(spec.names) != spec.rows * spec.cols:
        die(
            f"Bad SheetSpec for {spec.source_file}: {len(spec.names)} names, "
            f"but grid is {spec.rows}x{spec.cols}"
        )

    source_path = source_dir / spec.source_file
    if not source_path.exists():
        die(f"Missing master sheet: {source_path}")

    out_dir = custodian_root / spec.domain_home_rel
    out_dir.mkdir(parents=True, exist_ok=True)

    raw = Image.open(source_path).convert("RGBA")
    cleaned = flood_transparentize_background(raw)

    x_bands = find_axis_bands(cleaned, axis="x", expected=spec.cols)
    y_bands = find_axis_bands(cleaned, axis="y", expected=spec.rows)

    source_size = cleaned.size
    assets: List[Dict[str, Any]] = []

    for index, name in enumerate(spec.names):
        row = index // spec.cols
        col = index % spec.cols

        x0, x1 = x_bands[col]
        y0, y1 = y_bands[row]
        cell_box = (x0, y0, x1, y1)

        bbox = mask_bbox_inside(cleaned, cell_box)
        if not bbox:
            die(
                f"Empty cell detected in {spec.source_file}, row={row}, col={col}, "
                f"name={name}. The sheet layout may not match the expected grid."
            )

        crop, crop_box = crop_with_padding(cleaned, bbox, pad=pad)

        out_path = out_dir / f"{name}.png"
        if out_path.exists() and not overwrite:
            die(f"Refusing to overwrite existing file without --overwrite: {out_path}")

        crop.save(out_path)

        meta = build_asset_metadata(
            custodian_root=custodian_root,
            spec=spec,
            source_path=source_path,
            out_path=out_path,
            name=name,
            index=index,
            row=row,
            col=col,
            source_size=source_size,
            cell_box=cell_box,
            crop_box=crop_box,
            exported_size=crop.size,
        )
        meta["image"]["sha256"] = sha256_file(out_path)
        assets.append(meta)

    return assets


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--custodian-root",
        default=None,
        help="Path to Godot project root, e.g. ~/Projects/CUSTODIAN/custodian",
    )
    parser.add_argument(
        "--source-dir",
        default=None,
        help="Override source dir. Default: <custodian-root>/content/masters/sundered",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing extracted runtime PNGs and manifests.",
    )
    parser.add_argument(
        "--pad",
        type=int,
        default=2,
        help="Transparent padding around each extracted asset.",
    )
    args = parser.parse_args()

    custodian_root = find_custodian_root(args.custodian_root)
    source_dir = (
        Path(args.source_dir).expanduser().resolve()
        if args.source_dir
        else custodian_root / "content" / "masters" / "sundered"
    )

    if not source_dir.exists():
        die(f"Missing source dir: {source_dir}")

    all_assets: List[Dict[str, Any]] = []
    source_sheets: Dict[str, Any] = {}

    for spec in SHEETS:
        source_path = source_dir / spec.source_file
        if source_path.exists():
            with Image.open(source_path) as im:
                source_sheets[spec.source_file] = {
                    "path": rel_res_path(custodian_root, source_path),
                    "size_px": list(im.size),
                    "sha256": sha256_file(source_path),
                    "grid": {"rows": spec.rows, "cols": spec.cols},
                    "domain": spec.domain_key,
                    "domain_home": "res://" + spec.domain_home_rel,
                }

        extracted = extract_sheet(
            custodian_root=custodian_root,
            source_dir=source_dir,
            spec=spec,
            overwrite=args.overwrite,
            pad=args.pad,
        )
        all_assets.extend(extracted)

    by_domain: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for asset in all_assets:
        by_domain[asset["domain"]].append(asset)

    doc_check = doc_drift_check(custodian_root, source_dir)

    manifest = {
        "schema": "custodian.game32.asset_manifest.v1",
        "name": "sundered_keep_game32_assets",
        "generated_at_utc": utc_now(),
        "generator": Path(__file__).name,
        "game32": {
            "tile_size_px": TILE_SIZE,
            "coordinate_system": "grid32_top_down_2_5d",
            "runtime": "Godot 4.x",
            "usage": {
                "floors": "snap top-left to grid cell",
                "walls": "snap logical base cell to grid; render sprite bottom-center with y-sort",
                "metadata_authority": "content/metadata/game32/sundered_keep.game32.json",
            },
        },
        "source": {
            "source_dir": rel_res_path(custodian_root, source_dir),
            "sheets": source_sheets,
        },
        "outputs": {
            "domains": {
                spec.domain_key: {
                    "asset_class": spec.asset_class,
                    "domain_home": "res://" + spec.domain_home_rel,
                    "count": len(by_domain.get(spec.domain_key, [])),
                }
                for spec in SHEETS
            }
        },
        "assets": all_assets,
        "doc_drift_check": doc_check,
    }

    manifest_path = custodian_root / "content" / "metadata" / "game32" / "sundered_keep.game32.json"
    gd_path = custodian_root / "content" / "metadata" / "game32" / "sundered_keep.game32.gd"

    if manifest_path.exists() and not args.overwrite:
        die(f"Refusing to overwrite existing manifest without --overwrite: {manifest_path}")

    write_json(manifest_path, manifest)
    write_gd_manifest_stub(gd_path)

    for spec in SHEETS:
        domain_assets = by_domain.get(spec.domain_key, [])
        domain_manifest = {
            "schema": "custodian.game32.domain_manifest.v1",
            "name": f"sundered_keep_{spec.domain_key}",
            "generated_at_utc": utc_now(),
            "domain": spec.domain_key,
            "asset_class": spec.asset_class,
            "domain_home": "res://" + spec.domain_home_rel,
            "count": len(domain_assets),
            "assets": domain_assets,
        }
        write_json(custodian_root / spec.domain_home_rel / "_manifest.game32.json", domain_manifest)

    domain_counts = {k: len(v) for k, v in by_domain.items()}
    report_path = source_dir / "_sundered_keep_extraction_report.md"
    write_report(report_path, manifest_path, domain_counts, doc_check)

    print("Sundered Keep extraction complete.")
    print(f"  Extracted assets: {len(all_assets)}")
    print(f"  Manifest: {manifest_path}")
    print(f"  GDScript loader stub: {gd_path}")
    print(f"  Report: {report_path}")

    if doc_check["missing_count"]:
        print("")
        print("Documentation/path drift warning:")
        for check in doc_check["checks"]:
            if not check["exists"]:
                print(f"  MISSING {check['key']}: {check['path']}")


if __name__ == "__main__":
    main()
