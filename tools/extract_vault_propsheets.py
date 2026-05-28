#!/usr/bin/env python3
"""
Extract CUSTODIAN vault propsheets into individual runtime assets and write game32 manifests.

Usage:
  cd ~/Projects/CUSTODIAN
  python tools/extract_vault_propsheets.py

Source sheets:
  custodian/props/gothic/vault_propsheet_01.png
  custodian/props/gothic/vault_propsheet_02.png
  custodian/props/gothic/vault_propsheet_03.png
  custodian/props/gothic/vault_propsheet_04.png
  custodian/props/gothic/vault_propsheet_05.png

Outputs:
  Individual .png files in kind-specific content directories.
  One .game32.json beside each .png.
  Aggregate manifest:
    custodian/content/props/gothic/vault_assets_manifest.game32.json
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPO_ROOT / "custodian" / "props" / "gothic"

AGGREGATE_MANIFEST = (
    REPO_ROOT / "custodian" / "content" / "props" / "gothic" / "vault_assets_manifest.game32.json"
)

TRANSPARENCY_TOLERANCE = 18
CROP_PADDING = 6


@dataclass(frozen=True)
class AssetSpec:
    sheet: str
    row: int
    col: int
    rows: int
    cols: int
    filename: str
    out_dir: str
    asset_type: str
    semantic_role: str
    placement_layer: str
    target_size: tuple[int, int]
    origin_mode: str
    y_sort: bool
    blocks_movement: bool
    blocks_sight: bool
    cover_value: int
    tags: list[str]


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def detect_bg_colors(img: Image.Image) -> set[tuple[int, int, int]]:
    """
    The generated sheets may have true alpha or a baked checkerboard.
    This samples corners to identify the baked transparency colors.
    """
    rgba = img.convert("RGBA")
    w, h = rgba.size

    samples: list[tuple[int, int, int]] = []
    sample_points = [
        (0, 0),
        (w - 1, 0),
        (0, h - 1),
        (w - 1, h - 1),
        (w // 2, 0),
        (0, h // 2),
        (w - 1, h // 2),
        (w // 2, h - 1),
    ]

    for x, y in sample_points:
        r, g, b, a = rgba.getpixel((x, y))
        if a > 0:
            samples.append((r, g, b))

    # Quantize similar checker colors.
    colors: set[tuple[int, int, int]] = set()
    for r, g, b in samples:
        colors.add((r, g, b))

    return colors


def color_distance_sq(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def remove_baked_checker_alpha(img: Image.Image) -> Image.Image:
    """
    Converts baked checkerboard background to alpha while preserving the asset.

    This is intentionally conservative:
    - true alpha remains alpha
    - near-white / near-light-gray corner-derived checker colors become transparent
    - dark object pixels are preserved
    """
    rgba = img.convert("RGBA")
    bg_colors = detect_bg_colors(rgba)
    if not bg_colors:
        return rgba

    tolerance_sq = TRANSPARENCY_TOLERANCE * TRANSPARENCY_TOLERANCE
    pix = rgba.load()
    w, h = rgba.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue

            rgb = (r, g, b)

            # Most generated checkerboards are very light. Avoid deleting highlights by
            # only considering light-ish pixels as possible background.
            is_light = r >= 185 and g >= 185 and b >= 185
            if not is_light:
                continue

            if any(color_distance_sq(rgb, bg) <= tolerance_sq for bg in bg_colors):
                pix[x, y] = (r, g, b, 0)

    return rgba


def crop_to_content(img: Image.Image, padding: int = CROP_PADDING) -> Image.Image:
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()

    if bbox is None:
        return rgba

    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(rgba.width, right + padding)
    bottom = min(rgba.height, bottom + padding)

    return rgba.crop((left, top, right, bottom))


def pad_to_target_bottom_center(img: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    target_w, target_h = target_size
    src = img.convert("RGBA")

    # If generated asset is too large for its intended runtime box, fit down.
    if src.width > target_w or src.height > target_h:
        scale = min(target_w / src.width, target_h / src.height)
        new_size = (max(1, int(src.width * scale)), max(1, int(src.height * scale)))
        src = src.resize(new_size, Image.Resampling.LANCZOS)

    out = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    x = (target_w - src.width) // 2
    y = target_h - src.height
    out.alpha_composite(src, (x, y))
    return out


def split_cell(sheet_img: Image.Image, rows: int, cols: int, row: int, col: int) -> Image.Image:
    w, h = sheet_img.size
    cell_w = w / cols
    cell_h = h / rows

    left = int(round(col * cell_w))
    top = int(round(row * cell_h))
    right = int(round((col + 1) * cell_w))
    bottom = int(round((row + 1) * cell_h))

    return sheet_img.crop((left, top, right, bottom))


def default_pivot(spec: AssetSpec) -> dict[str, int]:
    w, h = spec.target_size
    if spec.origin_mode == "center":
        return {"x": w // 2, "y": h // 2}
    return {"x": w // 2, "y": h - 1}


def default_footprint(spec: AssetSpec) -> dict[str, int]:
    w, h = spec.target_size

    # Keep footprints gameplay-sane rather than exact visual-size.
    if spec.semantic_role == "vault_floor_overlay":
        return {"w": max(1, round(w / 32)), "h": max(1, round(h / 32))}
    if spec.asset_type == "sprites":
        return {"w": 1, "h": 1}

    return {"w": max(1, round(w / 32)), "h": max(1, round(h / 32))}


def write_game32_manifest(spec: AssetSpec, out_path: Path) -> dict[str, Any]:
    asset_id = out_path.stem

    manifest = {
        "schema": "game32.asset.v2",
        "id": asset_id,
        "display_name": asset_id.replace("_", " ").title(),
        "source": {
            "master_sheet": rel(SOURCE_ROOT / spec.sheet),
            "sheet_cell": {
                "row": spec.row,
                "col": spec.col,
                "rows": spec.rows,
                "cols": spec.cols,
            },
        },
        "file": {
            "path": rel(out_path),
            "pixel_size": {
                "w": spec.target_size[0],
                "h": spec.target_size[1],
            },
        },
        "classification": {
            "asset_type": spec.asset_type,
            "semantic_role": spec.semantic_role,
            "placement_layer": spec.placement_layer,
            "tags": spec.tags,
        },
        "placement": {
            "tile_size": 32,
            "footprint_tiles": default_footprint(spec),
            "origin_mode": spec.origin_mode,
            "pivot_px": default_pivot(spec),
            "snap": "tile" if spec.placement_layer in {"wall", "door", "overlay"} else "tile_or_free",
            "allow_mirror_x": False,
            "allow_rotation": False,
            "y_sort": spec.y_sort,
        },
        "collision": {
            "blocks_movement": spec.blocks_movement,
            "blocks_sight": spec.blocks_sight,
            "cover_value": spec.cover_value,
            "collision_shape": "footprint" if spec.blocks_movement else "none",
        },
        "runtime": {
            "status": "extracted_from_source_sheet",
            "notes": "Generated extraction from vault propsheet source. Review collision and footprint before production placement.",
        },
    }

    manifest_path = out_path.with_suffix(".game32.json")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def spec(
    sheet: str,
    row: int,
    col: int,
    rows: int,
    cols: int,
    filename: str,
    out_dir: str,
    asset_type: str,
    semantic_role: str,
    placement_layer: str,
    target_size: tuple[int, int],
    origin_mode: str = "bottom_center",
    y_sort: bool = True,
    blocks_movement: bool = False,
    blocks_sight: bool = False,
    cover_value: int = 0,
    tags: list[str] | None = None,
) -> AssetSpec:
    base_tags = ["vault", "gothic"]
    if tags:
        base_tags.extend(tags)

    return AssetSpec(
        sheet=sheet,
        row=row,
        col=col,
        rows=rows,
        cols=cols,
        filename=filename,
        out_dir=out_dir,
        asset_type=asset_type,
        semantic_role=semantic_role,
        placement_layer=placement_layer,
        target_size=target_size,
        origin_mode=origin_mode,
        y_sort=y_sort,
        blocks_movement=blocks_movement,
        blocks_sight=blocks_sight,
        cover_value=cover_value,
        tags=base_tags,
    )


SPECS: list[AssetSpec] = [
    # ---------------------------------------------------------------------
    # vault_propsheet_01.png — stolen resource / loot bundles, 2x2
    # ---------------------------------------------------------------------
    spec(
        "vault_propsheet_01.png", 0, 0, 2, 2,
        "stolen_resource_bundle_01.png",
        "custodian/content/sprites/items/stolen_resources",
        "sprites", "stolen_resource_pickup_sprite", "item",
        (64, 64), "bottom_center", True, False, False, 0,
        ["item", "pickup", "stolen_resources", "bundle"],
    ),
    spec(
        "vault_propsheet_01.png", 0, 1, 2, 2,
        "stolen_resource_bundle_scrap_01.png",
        "custodian/content/sprites/items/stolen_resources",
        "sprites", "stolen_resource_pickup_sprite", "item",
        (64, 64), "bottom_center", True, False, False, 0,
        ["item", "pickup", "scrap", "stolen_resources", "bundle"],
    ),
    spec(
        "vault_propsheet_01.png", 1, 0, 2, 2,
        "stolen_resource_bundle_alloy_01.png",
        "custodian/content/sprites/items/stolen_resources",
        "sprites", "stolen_resource_pickup_sprite", "item",
        (64, 64), "bottom_center", True, False, False, 0,
        ["item", "pickup", "alloy", "stolen_resources", "bundle"],
    ),
    spec(
        "vault_propsheet_01.png", 1, 1, 2, 2,
        "stolen_resource_bundle_power_01.png",
        "custodian/content/sprites/items/stolen_resources",
        "sprites", "stolen_resource_pickup_sprite", "item",
        (64, 64), "bottom_center", True, False, False, 0,
        ["item", "pickup", "power_components", "stolen_resources", "bundle", "glow"],
    ),

    # ---------------------------------------------------------------------
    # vault_propsheet_02.png — vault dressing / resource displays, 3x2 with 5 populated
    # ---------------------------------------------------------------------
    spec(
        "vault_propsheet_02.png", 0, 0, 2, 3,
        "vault_resource_pile_scrap_01.png",
        "custodian/content/props/gothic/vault_dressing",
        "props", "vault_resource_display_prop", "prop",
        (96, 64), "bottom_center", True, False, False, 0,
        ["prop", "resource", "scrap", "dressing", "storage_room"],
    ),
    spec(
        "vault_propsheet_02.png", 0, 1, 2, 3,
        "vault_resource_pile_alloy_01.png",
        "custodian/content/props/gothic/vault_dressing",
        "props", "vault_resource_display_prop", "prop",
        (96, 64), "bottom_center", True, False, False, 0,
        ["prop", "resource", "alloy", "dressing", "storage_room"],
    ),
    spec(
        "vault_propsheet_02.png", 0, 2, 2, 3,
        "vault_resource_pile_power_components_01.png",
        "custodian/content/props/gothic/vault_dressing",
        "props", "vault_resource_display_prop", "prop",
        (128, 96), "bottom_center", True, False, False, 0,
        ["prop", "resource", "power_components", "dressing", "storage_room", "glow"],
    ),
    spec(
        "vault_propsheet_02.png", 1, 0, 2, 3,
        "vault_resource_crate_stack_01.png",
        "custodian/content/props/gothic/vault_dressing",
        "props", "vault_dressing", "prop",
        (128, 128), "bottom_center", True, True, False, 1,
        ["prop", "crate_stack", "storage", "dressing", "cover"],
    ),
    spec(
        "vault_propsheet_02.png", 1, 1, 2, 3,
        "vault_shelf_supplies_01.png",
        "custodian/content/props/gothic/vault_dressing",
        "props", "vault_dressing", "prop",
        (128, 128), "bottom_center", True, True, False, 1,
        ["prop", "shelf", "supplies", "storage", "dressing"],
    ),

    # ---------------------------------------------------------------------
    # vault_propsheet_03.png — storage containers, 5x2
    # ---------------------------------------------------------------------
    spec(
        "vault_propsheet_03.png", 0, 0, 2, 5,
        "vault_chest_small_01.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (160, 128), "bottom_center", True, True, False, 1,
        ["prop", "storage", "chest", "loot", "stealable", "closed"],
    ),
    spec(
        "vault_propsheet_03.png", 0, 1, 2, 5,
        "vault_chest_small_01_open.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (160, 128), "bottom_center", True, True, False, 1,
        ["prop", "storage", "chest", "loot", "stealable", "open", "full"],
    ),
    spec(
        "vault_propsheet_03.png", 0, 2, 2, 5,
        "vault_chest_small_01_empty.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (160, 128), "bottom_center", True, True, False, 1,
        ["prop", "storage", "chest", "loot", "stealable", "open", "empty"],
    ),
    spec(
        "vault_propsheet_03.png", 0, 3, 2, 5,
        "vault_chest_small_01_damaged.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (160, 128), "bottom_center", True, True, False, 1,
        ["prop", "storage", "chest", "damaged", "looted"],
    ),
    spec(
        "vault_propsheet_03.png", 0, 4, 2, 5,
        "vault_resource_crate_01.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (96, 96), "bottom_center", True, True, False, 1,
        ["prop", "storage", "crate", "stealable", "closed"],
    ),
    spec(
        "vault_propsheet_03.png", 1, 0, 2, 5,
        "vault_resource_crate_01_open.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (96, 96), "bottom_center", True, True, False, 1,
        ["prop", "storage", "crate", "stealable", "open", "full"],
    ),
    spec(
        "vault_propsheet_03.png", 1, 1, 2, 5,
        "vault_resource_crate_01_empty.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (96, 96), "bottom_center", True, True, False, 1,
        ["prop", "storage", "crate", "stealable", "open", "empty"],
    ),
    spec(
        "vault_propsheet_03.png", 1, 2, 2, 5,
        "vault_lockbox_01.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (64, 64), "bottom_center", True, True, False, 1,
        ["prop", "storage", "lockbox", "safe", "stealable", "closed"],
    ),
    spec(
        "vault_propsheet_03.png", 1, 3, 2, 5,
        "vault_lockbox_01_open.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (96, 64), "bottom_center", True, True, False, 1,
        ["prop", "storage", "lockbox", "safe", "stealable", "open", "full"],
    ),
    spec(
        "vault_propsheet_03.png", 1, 4, 2, 5,
        "vault_lockbox_01_empty.png",
        "custodian/content/props/gothic/vault_storage",
        "props", "vault_storage_prop", "prop",
        (96, 64), "bottom_center", True, True, False, 1,
        ["prop", "storage", "lockbox", "safe", "stealable", "open", "empty"],
    ),

    # ---------------------------------------------------------------------
    # vault_propsheet_04.png — doors/gates, 3x2 with 5 populated
    # ---------------------------------------------------------------------
    spec(
        "vault_propsheet_04.png", 0, 0, 2, 3,
        "vault_door_closed_01.png",
        "custodian/content/doors/gothic/vault",
        "doors", "vault_door", "door",
        (128, 128), "bottom_center", True, True, True, 3,
        ["door", "vault_door", "closed", "blocking"],
    ),
    spec(
        "vault_propsheet_04.png", 0, 1, 2, 3,
        "vault_door_open_01.png",
        "custodian/content/doors/gothic/vault",
        "doors", "vault_door", "door",
        (128, 128), "bottom_center", True, False, False, 0,
        ["door", "vault_door", "open", "passage"],
    ),
    spec(
        "vault_propsheet_04.png", 0, 2, 2, 3,
        "vault_gate_barred_01.png",
        "custodian/content/doors/gothic/vault",
        "doors", "vault_gate", "door",
        (128, 128), "bottom_center", True, True, True, 3,
        ["door", "gate", "barred", "closed", "blocking"],
    ),
    spec(
        "vault_propsheet_04.png", 1, 0, 2, 3,
        "vault_gate_broken_01.png",
        "custodian/content/doors/gothic/vault",
        "doors", "vault_gate", "door",
        (128, 128), "bottom_center", True, False, False, 1,
        ["door", "gate", "broken", "passage", "damaged"],
    ),
    spec(
        "vault_propsheet_04.png", 1, 1, 2, 3,
        "vault_door_lockplate_01.png",
        "custodian/content/doors/gothic/vault",
        "doors", "vault_lock_mechanism", "door",
        (64, 64), "center", False, False, False, 0,
        ["door", "lock", "lockplate", "mechanism", "overlay"],
    ),

    # ---------------------------------------------------------------------
    # vault_propsheet_05.png — wall connectors/corners, 4x2
    # ---------------------------------------------------------------------
    spec(
        "vault_propsheet_05.png", 0, 0, 2, 4,
        "vault_wall_corner_inner_ne_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_corner", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "corner", "inner", "ne", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 0, 1, 2, 4,
        "vault_wall_corner_inner_nw_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_corner", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "corner", "inner", "nw", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 0, 2, 2, 4,
        "vault_wall_corner_outer_ne_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_corner", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "corner", "outer", "ne", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 0, 3, 2, 4,
        "vault_wall_corner_outer_nw_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_corner", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "corner", "outer", "nw", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 1, 0, 2, 4,
        "vault_wall_end_left_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_end", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "endcap", "left", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 1, 1, 2, 4,
        "vault_wall_end_right_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_end", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "endcap", "right", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 1, 2, 2, 4,
        "vault_wall_pillar_01.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_pillar", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "pillar", "support", "blocking"],
    ),
    spec(
        "vault_propsheet_05.png", 1, 3, 2, 4,
        "vault_wall_pillar_02.png",
        "custodian/content/walls/gothic/vault",
        "walls", "vault_wall_pillar", "wall",
        (64, 96), "bottom_center", True, True, True, 3,
        ["wall", "pillar", "support", "blocking", "alternate"],
    ),
]


def extract_all() -> int:
    all_manifests: list[dict[str, Any]] = []
    missing_sheets: set[str] = set()

    sheet_cache: dict[str, Image.Image] = {}

    for item in SPECS:
        sheet_path = SOURCE_ROOT / item.sheet
        if not sheet_path.exists():
            missing_sheets.add(str(sheet_path))
            continue

        if item.sheet not in sheet_cache:
            sheet_cache[item.sheet] = Image.open(sheet_path).convert("RGBA")

        sheet_img = sheet_cache[item.sheet]

        cell = split_cell(sheet_img, item.rows, item.cols, item.row, item.col)
        cell = remove_baked_checker_alpha(cell)
        cell = crop_to_content(cell)
        final_img = pad_to_target_bottom_center(cell, item.target_size)

        out_dir = REPO_ROOT / item.out_dir
        out_dir.mkdir(parents=True, exist_ok=True)

        out_path = out_dir / item.filename
        final_img.save(out_path)

        manifest = write_game32_manifest(item, out_path)
        all_manifests.append(manifest)

        print(f"extracted {rel(out_path)}")

    if missing_sheets:
        print("\nMissing source sheets:", file=sys.stderr)
        for path in sorted(missing_sheets):
            print(f"  {path}", file=sys.stderr)
        print("\nNothing was extracted from missing sheets.", file=sys.stderr)

    AGGREGATE_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    AGGREGATE_MANIFEST.write_text(
        json.dumps(
            {
                "schema": "game32.asset_pack.v1",
                "id": "gothic_vault_asset_pack_v1",
                "display_name": "Gothic Vault Asset Pack V1",
                "source_root": rel(SOURCE_ROOT),
                "asset_count": len(all_manifests),
                "assets": [
                    {
                        "id": manifest["id"],
                        "path": manifest["file"]["path"],
                        "manifest": manifest["file"]["path"].replace(".png", ".game32.json"),
                        "asset_type": manifest["classification"]["asset_type"],
                        "semantic_role": manifest["classification"]["semantic_role"],
                        "placement_layer": manifest["classification"]["placement_layer"],
                        "tags": manifest["classification"]["tags"],
                    }
                    for manifest in all_manifests
                ],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"\nwrote aggregate manifest {rel(AGGREGATE_MANIFEST)}")
    print(f"extracted {len(all_manifests)} assets")

    return 0 if not missing_sheets else 1


if __name__ == "__main__":
    raise SystemExit(extract_all())
