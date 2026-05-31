#!/usr/bin/env python3
"""
extract_return_mooring_game32.py

Extracts the Sundered Keep return mooring tilesheet into runtime PNGs and
game32 sidecar metadata.

Expected visual sheet order:

Row 1:
  return_mooring_floor_center_01
  return_mooring_floor_ring_n
  return_mooring_floor_ring_e
  return_mooring_floor_ring_s
  return_mooring_floor_ring_w

Row 2:
  return_mooring_floor_corner_ne
  return_mooring_floor_corner_nw
  return_mooring_floor_corner_se
  return_mooring_floor_corner_sw

Row 3:
  return_mooring_glow_overlay_01
  return_mooring_active_overlay_01
  return_mooring_prompt_marker_01

Row 4:
  prop_return_beacon_01
  prop_return_console_ruined_01
"""

from __future__ import annotations

import argparse
import json
import shutil
from collections import deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image

TILE_SIZE = 32


@dataclass(frozen=True)
class AssetSpec:
    asset_id: str
    target_size: tuple[int, int]
    domain: str
    output_subdir: str
    layer: str
    walkable: bool
    blocks_movement: bool
    blocks_projectile: bool
    fit_mode: str = "fill"  # fill | contain
    anchor: str = "top_left"  # top_left | bottom_center
    interactable: bool = False
    non_blocking_overlay: bool = False
    animated_optional: bool = False
    cover_type: str = ""
    notes: str = ""


ASSETS: list[AssetSpec] = [
    # Row 1: floor center/rings
    AssetSpec(
        "return_mooring_floor_center_01",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
        interactable=True,
        notes="Center interaction tile for return-to-main-map mooring.",
    ),
    AssetSpec(
        "return_mooring_floor_ring_n",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_ring_e",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_ring_s",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_ring_w",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    # Row 2: corners
    AssetSpec(
        "return_mooring_floor_corner_ne",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_corner_nw",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_corner_se",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    AssetSpec(
        "return_mooring_floor_corner_sw",
        (32, 32),
        "return_mooring_floor",
        "custodian/content/tiles/sundered_keep/return_mooring/floors",
        "FloorDetail",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
    ),
    # Row 3: overlays
    AssetSpec(
        "return_mooring_glow_overlay_01",
        (32, 32),
        "return_mooring_overlay",
        "custodian/content/tiles/sundered_keep/return_mooring/overlays",
        "Overlays",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
        fit_mode="contain",
        non_blocking_overlay=True,
        notes="Idle powered glow overlay. Non-blocking.",
    ),
    AssetSpec(
        "return_mooring_active_overlay_01",
        (32, 32),
        "return_mooring_overlay",
        "custodian/content/tiles/sundered_keep/return_mooring/overlays",
        "Effects",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
        fit_mode="contain",
        non_blocking_overlay=True,
        animated_optional=True,
        notes="Active/pulsing return overlay. Non-blocking.",
    ),
    AssetSpec(
        "return_mooring_prompt_marker_01",
        (32, 32),
        "return_mooring_overlay",
        "custodian/content/tiles/sundered_keep/return_mooring/overlays",
        "WorldUI",
        walkable=True,
        blocks_movement=False,
        blocks_projectile=False,
        fit_mode="contain",
        non_blocking_overlay=True,
        notes="Subtle world prompt marker shown near interaction range.",
    ),
    # Row 4: props
    AssetSpec(
        "prop_return_beacon_01",
        (32, 64),
        "return_mooring_prop",
        "custodian/content/props/sundered_keep/return_mooring",
        "PropsBlocking",
        walkable=False,
        blocks_movement=True,
        blocks_projectile=False,
        fit_mode="contain",
        anchor="bottom_center",
        notes="Tall return beacon. Small blocker, bottom-center anchored.",
    ),
    AssetSpec(
        "prop_return_console_ruined_01",
        (64, 32),
        "return_mooring_prop",
        "custodian/content/props/sundered_keep/return_mooring",
        "PropsBlocking",
        walkable=False,
        blocks_movement=True,
        blocks_projectile=False,
        fit_mode="contain",
        anchor="bottom_center",
        interactable=True,
        cover_type="low",
        notes="Ruined low return console. Optional interactable/low cover.",
    ),
]


EXPECTED_ROW_COUNTS = [5, 4, 3, 2]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def res_path(project_root: Path, disk_path: Path) -> str:
    custodian_root = project_root / "custodian"
    rel = disk_path.relative_to(custodian_root)
    return "res://" + rel.as_posix()


def is_checker_or_blank(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return True

    mx = max(r, g, b)
    mn = min(r, g, b)

    # DALL-E/editor preview checkerboards are usually light, low-saturation grays.
    if mx >= 205 and (mx - mn) <= 34:
        return True

    # Slightly warmer near-white background.
    if r >= 210 and g >= 210 and b >= 210:
        return True

    return False


def remove_sheet_background(img: Image.Image) -> Image.Image:
    """
    Removes border-connected light checkerboard/blank background from the full sheet.
    Then also removes any remaining light checkerboard pixels globally.
    """
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size

    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))

        r, g, b, a = px[x, y]
        if not is_checker_or_blank(r, g, b, a):
            continue

        px[x, y] = (r, g, b, 0)

        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                q.append((nx, ny))

    # Remove remaining checkerboard pixels that may be trapped inside rings/glow.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_checker_or_blank(r, g, b, a):
                px[x, y] = (r, g, b, 0)

    return rgba


def alpha_mask(img: Image.Image) -> list[list[bool]]:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    return [[px[x, y][3] > 10 for x in range(w)] for y in range(h)]


def close_bool_runs(values: list[bool], max_gap: int) -> list[bool]:
    values = values[:]
    n = len(values)
    i = 0
    while i < n:
        if values[i]:
            i += 1
            continue

        start = i
        while i < n and not values[i]:
            i += 1
        end = i

        left = start > 0 and values[start - 1]
        right = end < n and values[end]
        if left and right and (end - start) <= max_gap:
            for j in range(start, end):
                values[j] = True

    return values


def bool_bands(values: list[bool], min_width: int = 1) -> list[tuple[int, int]]:
    bands: list[tuple[int, int]] = []
    i = 0
    n = len(values)

    while i < n:
        while i < n and not values[i]:
            i += 1
        if i >= n:
            break

        start = i
        while i < n and values[i]:
            i += 1
        end = i

        if end - start >= min_width:
            bands.append((start, end))

    return bands


def force_count_bands(
    bands: list[tuple[int, int]],
    expected: int,
    min_gap_for_split: int = 16,
) -> list[tuple[int, int]]:
    """
    If too many bands are detected, merge nearest neighbors until expected count.
    If too few are detected, leave them and let validation fail.
    """
    bands = bands[:]

    while len(bands) > expected:
        best_i = 0
        best_gap = 10**9
        for i in range(len(bands) - 1):
            gap = bands[i + 1][0] - bands[i][1]
            if gap < best_gap:
                best_gap = gap
                best_i = i

        a = bands[best_i]
        b = bands[best_i + 1]
        bands[best_i : best_i + 2] = [(a[0], b[1])]

    return bands


def detect_asset_boxes(cleaned: Image.Image) -> list[tuple[int, int, int, int]]:
    """
    Detects boxes by row/column projection after background removal.
    Expects row counts [5,4,3,2].
    """
    mask = alpha_mask(cleaned)
    w, h = cleaned.size

    row_counts = [sum(1 for x in range(w) if mask[y][x]) for y in range(h)]
    row_has = [c > 3 for c in row_counts]
    row_has = close_bool_runs(row_has, max_gap=18)
    row_bands = bool_bands(row_has, min_width=8)

    # Keep only substantial rows.
    row_bands = [
        (y0, y1)
        for y0, y1 in row_bands
        if sum(row_counts[y] for y in range(y0, y1)) > 80
    ]

    if len(row_bands) != len(EXPECTED_ROW_COUNTS):
        raise RuntimeError(
            f"Expected {len(EXPECTED_ROW_COUNTS)} asset rows, detected {len(row_bands)}: {row_bands}. "
            "Use --debug to inspect detection, or provide a cleaner master sheet."
        )

    boxes: list[tuple[int, int, int, int]] = []

    for row_index, ((y0, y1), expected_cols) in enumerate(
        zip(row_bands, EXPECTED_ROW_COUNTS)
    ):
        col_counts = []
        for x in range(w):
            count = 0
            for y in range(y0, y1):
                if mask[y][x]:
                    count += 1
            col_counts.append(count)

        col_has = [c > 2 for c in col_counts]

        # Close small internal gaps in the same asset, but not the big gutters.
        col_has = close_bool_runs(col_has, max_gap=24)
        col_bands = bool_bands(col_has, min_width=4)

        col_bands = [
            (x0, x1)
            for x0, x1 in col_bands
            if sum(col_counts[x] for x in range(x0, x1)) > 50
        ]

        col_bands = force_count_bands(col_bands, expected_cols)

        if len(col_bands) != expected_cols:
            raise RuntimeError(
                f"Row {row_index + 1}: expected {expected_cols} assets, detected {len(col_bands)}: {col_bands}"
            )

        for x0, x1 in col_bands:
            # Refine box by actual alpha within row/col band.
            xs: list[int] = []
            ys: list[int] = []
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    if mask[yy][xx]:
                        xs.append(xx)
                        ys.append(yy)

            if not xs or not ys:
                continue

            pad = 3
            rx0 = max(0, min(xs) - pad)
            ry0 = max(0, min(ys) - pad)
            rx1 = min(w, max(xs) + pad + 1)
            ry1 = min(h, max(ys) + pad + 1)
            boxes.append((rx0, ry0, rx1, ry1))

    if len(boxes) != len(ASSETS):
        raise RuntimeError(
            f"Expected {len(ASSETS)} assets, detected {len(boxes)} boxes."
        )

    return boxes


def crop_to_content(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if bbox is None:
        return rgba
    return rgba.crop(bbox)


def normalize_asset(crop: Image.Image, spec: AssetSpec) -> Image.Image:
    crop = crop.convert("RGBA")

    # Remove any remaining checkerboard pixels inside this crop.
    px = crop.load()
    w, h = crop.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_checker_or_blank(r, g, b, a):
                px[x, y] = (r, g, b, 0)

    crop = crop_to_content(crop)

    target_w, target_h = spec.target_size

    if spec.fit_mode == "fill":
        # Floors should fill their tile exactly.
        return crop.resize((target_w, target_h), Image.Resampling.LANCZOS)

    # contain
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    src_w, src_h = crop.size
    if src_w <= 0 or src_h <= 0:
        return canvas

    scale = min(target_w / src_w, target_h / src_h)
    new_w = max(1, int(round(src_w * scale)))
    new_h = max(1, int(round(src_h * scale)))

    resized = crop.resize((new_w, new_h), Image.Resampling.LANCZOS)

    if spec.anchor == "bottom_center":
        x = (target_w - new_w) // 2
        y = target_h - new_h
    else:
        x = (target_w - new_w) // 2
        y = (target_h - new_h) // 2

    canvas.alpha_composite(resized, (x, y))
    return canvas


def build_sidecar(
    project_root: Path,
    spec: AssetSpec,
    output_png: Path,
    sheet_path: Path,
    crop_box: tuple[int, int, int, int],
) -> dict[str, Any]:
    width, height = spec.target_size

    sidecar: dict[str, Any] = {
        "schema": "custodian.game32.asset.v1",
        "id": spec.asset_id,
        "name": spec.asset_id,
        "set": "sundered_keep",
        "domain": spec.domain,
        "asset_class": "prop" if spec.domain.endswith("_prop") else "tile",
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/extract_return_mooring_game32.py",
        "source": {
            "sheet_path": res_path(project_root, sheet_path),
            "crop_box_px": list(crop_box),
        },
        "runtime_path": res_path(project_root, output_png),
        "size_px": [width, height],
        "tile_size_px": TILE_SIZE,
        "anchor": spec.anchor,
        "layer": spec.layer,
        "gameplay": {
            "walkable": spec.walkable,
            "blocks_movement": spec.blocks_movement,
            "blocks_projectile": spec.blocks_projectile,
            "interactable": spec.interactable,
            "non_blocking_overlay": spec.non_blocking_overlay,
            "animated_optional": spec.animated_optional,
        },
        "import": {
            "filter": "nearest",
            "mipmaps": False,
            "repeat": False,
        },
        "notes": spec.notes,
    }

    if spec.blocks_movement:
        sidecar["collision"] = {
            "collision_cell_px": [TILE_SIZE, TILE_SIZE],
            "shape": "rect",
            "anchor": spec.anchor,
        }

    if spec.cover_type:
        sidecar["gameplay"]["cover_type"] = spec.cover_type

    if spec.asset_id == "return_mooring_floor_center_01":
        sidecar["interaction"] = {
            "kind": "return_to_main_map",
            "prompt": "Return to main map",
            "input_action": "interact",
        }

    return sidecar


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def build_domain_manifests(
    project_root: Path, written: list[tuple[AssetSpec, Path, Path]]
) -> None:
    by_dir: dict[Path, list[tuple[AssetSpec, Path, Path]]] = {}

    for spec, png_path, json_path in written:
        by_dir.setdefault(png_path.parent, []).append((spec, png_path, json_path))

    for out_dir, items in sorted(by_dir.items()):
        manifest_path = out_dir / "_manifest.game32.json"

        manifest = {
            "schema": "custodian.game32.domain_manifest.v1",
            "set": "sundered_keep",
            "domain": out_dir.name,
            "base_path": res_path(project_root, out_dir),
            "generated_at_utc": utc_now(),
            "generator": "custodian/tools/art/extract_return_mooring_game32.py",
            "asset_count": len(items),
            "assets": [
                {
                    "id": spec.asset_id,
                    "runtime_path": res_path(project_root, png_path),
                    "metadata_path": res_path(project_root, json_path),
                    "size_px": list(spec.target_size),
                    "layer": spec.layer,
                    "walkable": spec.walkable,
                    "blocks_movement": spec.blocks_movement,
                    "interactable": spec.interactable,
                }
                for spec, png_path, json_path in items
            ],
        }

        write_json(manifest_path, manifest)
        print(f"Wrote manifest: {manifest_path}")


def build_module_manifest(
    project_root: Path, written: list[tuple[AssetSpec, Path, Path]]
) -> None:
    runtime_dir = (
        project_root / "custodian/content/runtime/sundered_keep/return_mooring"
    )
    runtime_dir.mkdir(parents=True, exist_ok=True)

    assets_by_id = {
        spec.asset_id: {
            "runtime_path": res_path(project_root, png_path),
            "metadata_path": res_path(project_root, json_path),
            "size_px": list(spec.target_size),
            "domain": spec.domain,
            "layer": spec.layer,
            "walkable": spec.walkable,
            "blocks_movement": spec.blocks_movement,
            "interactable": spec.interactable,
        }
        for spec, png_path, json_path in written
    }

    module = {
        "schema": "custodian.game32.return_mooring_module.v1",
        "module_id": "return_mooring_3x3_01",
        "set": "sundered_keep",
        "module_kind": "return_interaction",
        "tile_size_px": TILE_SIZE,
        "footprint_tiles": [5, 5],
        "interaction_tile": [2, 2],
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/extract_return_mooring_game32.py",
        "layout_3x3": [
            [
                "return_mooring_floor_corner_nw",
                "return_mooring_floor_ring_n",
                "return_mooring_floor_corner_ne",
            ],
            [
                "return_mooring_floor_ring_w",
                "return_mooring_floor_center_01",
                "return_mooring_floor_ring_e",
            ],
            [
                "return_mooring_floor_corner_sw",
                "return_mooring_floor_ring_s",
                "return_mooring_floor_corner_se",
            ],
        ],
        "overlays": [
            "return_mooring_glow_overlay_01",
            "return_mooring_active_overlay_01",
            "return_mooring_prompt_marker_01",
        ],
        "props": [
            "prop_return_beacon_01",
            "prop_return_console_ruined_01",
        ],
        "assets": assets_by_id,
        "recommended_layers": [
            "TerrainBase",
            "FloorDetail",
            "PropsBlocking",
            "Overlays",
            "Effects",
            "WorldUI",
        ],
        "placement_notes": [
            "Place near the Sundered Keep entrance, preferably in a side alcove.",
            "Do not place directly on the player spawn tile.",
            "Use the center tile as the interaction target.",
            "Beacon should be side-mounted as a landmark/small blocker.",
            "Console may be low cover or optional interactable flavor.",
        ],
    }

    write_json(runtime_dir / "return_mooring_module.game32.json", module)

    metadata_dir = project_root / "custodian/content/metadata/game32"
    metadata_dir.mkdir(parents=True, exist_ok=True)
    write_json(metadata_dir / "return_mooring.game32.json", module)

    print(f"Wrote module manifest: {runtime_dir / 'return_mooring_module.game32.json'}")
    print(f"Wrote metadata authority: {metadata_dir / 'return_mooring.game32.json'}")


def write_doc_drift_review(
    project_root: Path, written: list[tuple[AssetSpec, Path, Path]]
) -> None:
    review_path = (
        project_root
        / "custodian/content/runtime/sundered_keep/return_mooring/_doc_drift_review.json"
    )

    missing = []
    for _spec, png_path, json_path in written:
        if not png_path.exists():
            missing.append(str(png_path))
        if not json_path.exists():
            missing.append(str(json_path))

    review = {
        "schema": "custodian.doc_drift_review.v1",
        "subject": "sundered_keep_return_mooring",
        "generated_at_utc": utc_now(),
        "status": "ok" if not missing else "missing_outputs",
        "missing_count": len(missing),
        "missing": missing,
        "runtime_outputs": {
            "tiles": "custodian/content/tiles/sundered_keep/return_mooring/",
            "props": "custodian/content/props/sundered_keep/return_mooring/",
            "module_manifest": "custodian/content/runtime/sundered_keep/return_mooring/return_mooring_module.game32.json",
            "metadata_authority": "custodian/content/metadata/game32/return_mooring.game32.json",
        },
        "recommended_doc_updates": [
            "custodian/docs/ai_context/CURRENT_STATE.md",
            "custodian/docs/ai_context/FILE_INDEX.md",
        ],
        "note": (
            "If this return mooring is accepted into active Sundered Keep runtime, "
            "document the new module and its runtime paths in the AI context docs."
        ),
    }

    write_json(review_path, review)
    print(f"Wrote doc drift review: {review_path}")


def maybe_update_sundered_manifest(project_root: Path) -> None:
    manifest_path = (
        project_root / "custodian/content/sundered_keep_manifest.game32.json"
    )
    if not manifest_path.exists():
        print(f"Skipped top-level manifest update; not found: {manifest_path}")
        return

    data = json.loads(manifest_path.read_text())
    sections = data.setdefault("sections", {})

    sections["return_mooring"] = {
        "kind": "return_interaction_module",
        "count": len(ASSETS),
        "base_path": "res://content/runtime/sundered_keep/return_mooring",
        "manifest": "res://content/runtime/sundered_keep/return_mooring/return_mooring_module.game32.json",
        "tiles_path": "res://content/tiles/sundered_keep/return_mooring",
        "props_path": "res://content/props/sundered_keep/return_mooring",
    }

    data["generated_at_utc"] = utc_now()
    data["total_asset_count"] = int(data.get("total_asset_count", 0))

    # Avoid double-counting on repeated runs.
    section_counts = []
    for info in sections.values():
        try:
            section_counts.append(int(info.get("count", 0)))
        except Exception:
            pass
    if section_counts:
        data["total_asset_count"] = sum(section_counts)

    write_json(manifest_path, data)
    print(f"Updated top-level Sundered Keep manifest: {manifest_path}")


def write_debug_boxes(
    project_root: Path, cleaned: Image.Image, boxes: list[tuple[int, int, int, int]]
) -> None:
    try:
        from PIL import ImageDraw
    except Exception:
        return

    debug_dir = project_root / ".ai"
    debug_dir.mkdir(parents=True, exist_ok=True)

    img = cleaned.copy()
    draw = ImageDraw.Draw(img)

    for index, box in enumerate(boxes):
        x0, y0, x1, y1 = box
        draw.rectangle(box, outline=(255, 0, 0, 255), width=4)
        draw.text((x0 + 4, y0 + 4), str(index), fill=(255, 255, 0, 255))

    out = debug_dir / "return_mooring_extract_boxes.png"
    img.save(out)
    print(f"Wrote debug boxes: {out}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        default=".",
        help="Project root containing custodian/. Default: current directory.",
    )
    parser.add_argument(
        "--sheet",
        required=True,
        help="Path to generated return mooring master sheet.",
    )
    parser.add_argument(
        "--update-sundered-manifest",
        action="store_true",
        help="Update custodian/content/sundered_keep_manifest.game32.json with return_mooring section.",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Write .ai/return_mooring_extract_boxes.png with detected crop boxes.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Detect and report boxes without writing output files.",
    )

    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    sheet_path = Path(args.sheet)
    if not sheet_path.is_absolute():
        sheet_path = project_root / sheet_path
    sheet_path = sheet_path.resolve()

    if not (project_root / "custodian").exists():
        raise SystemExit(f"Project root must contain custodian/: {project_root}")

    if not sheet_path.exists():
        raise SystemExit(f"Sheet not found: {sheet_path}")

    # Keep a source copy under masters if the input came from elsewhere.
    canonical_master = (
        project_root
        / "custodian/content/masters/sundered_keep/return_mooring_tilesheet.png"
    )
    canonical_master.parent.mkdir(parents=True, exist_ok=True)

    if sheet_path != canonical_master:
        shutil.copy2(sheet_path, canonical_master)
        print(f"Copied sheet to canonical master: {canonical_master}")
        sheet_path = canonical_master

    source = Image.open(sheet_path).convert("RGBA")
    cleaned = remove_sheet_background(source)
    boxes = detect_asset_boxes(cleaned)

    if args.debug:
        write_debug_boxes(project_root, cleaned, boxes)

    print("Detected asset boxes:")
    for spec, box in zip(ASSETS, boxes):
        print(f"  {spec.asset_id}: {box} -> {spec.target_size}")

    if args.dry_run:
        print("Dry run complete; no files written.")
        return

    written: list[tuple[AssetSpec, Path, Path]] = []

    for spec, box in zip(ASSETS, boxes):
        out_dir = project_root / spec.output_subdir
        out_dir.mkdir(parents=True, exist_ok=True)

        crop = cleaned.crop(box)
        normalized = normalize_asset(crop, spec)

        png_path = out_dir / f"{spec.asset_id}.png"
        json_path = out_dir / f"{spec.asset_id}.game32.json"

        normalized.save(png_path)

        sidecar = build_sidecar(
            project_root=project_root,
            spec=spec,
            output_png=png_path,
            sheet_path=sheet_path,
            crop_box=box,
        )
        write_json(json_path, sidecar)

        written.append((spec, png_path, json_path))
        print(f"Wrote {png_path}")
        print(f"Wrote {json_path}")

    build_domain_manifests(project_root, written)
    build_module_manifest(project_root, written)
    write_doc_drift_review(project_root, written)

    if args.update_sundered_manifest:
        maybe_update_sundered_manifest(project_root)

    print("\nDone.")
    print("Next suggested checks:")
    print(
        "  find custodian/content/tiles/sundered_keep/return_mooring -maxdepth 3 -type f | sort"
    )
    print(
        "  find custodian/content/props/sundered_keep/return_mooring -maxdepth 2 -type f | sort"
    )
    print(
        "  cd custodian && godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd"
    )


if __name__ == "__main__":
    main()
