#!/usr/bin/env python3
"""
Extract runtime production candidate assets from:

  custodian/content/masters/sundered_keep/causeway_tiles_master.png
  custodian/content/masters/sundered_keep/causeway_walls_master.png

Outputs normalized 32x32-grid runtime PNGs plus detailed game32 metadata.

The source masters are labeled presentation sheets, not raw atlases, so this script
uses exact pixel crop rectangles for each displayed asset, then resizes each crop
to its intended runtime footprint:

  1x1 => 32x32
  1x2 => 32x64
  2x3 => 64x96
  4x4 => 128x128
  6x6 => 192x192
  etc.

Default output:

  custodian/content/tiles/sundered_keep/causeway_runtime/
    ocean/
    cliffs/
    causeway_floor/
    causeway_edges/
    keep_walls/
    gatehouse/
    props/
    reports/
      causeway_runtime.game32.json
      extraction_contact_sheet.png
      crop_overlay_tiles.png
      crop_overlay_walls.png

Run:

  python tools/extract_causeway_master_tilesheets.py --clean --debug
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

from PIL import Image, ImageDraw, ImageEnhance, ImageFont


ROOT = Path("custodian")
DEFAULT_TILES_MASTER = ROOT / "content/masters/sundered_keep/causeway_tiles_master.png"
DEFAULT_WALLS_MASTER = ROOT / "content/masters/sundered_keep/causeway_walls_master.png"
DEFAULT_OUT = ROOT / "content/tiles/sundered_keep/causeway_runtime"

TILE_SIZE = 32
EXPECTED_MASTER_SIZE = (1448, 1086)


Domain = Literal[
    "ocean",
    "cliffs",
    "causeway_floor",
    "causeway_edges",
    "keep_walls",
    "gatehouse",
    "props",
]

Collision = Literal["none", "solid", "water", "edge", "partial"]
Anchor = Literal["top_left", "center", "bottom_center", "bottom_left", "bottom_right"]


@dataclass(frozen=True)
class CropSpec:
    source: Literal["tiles", "walls"]
    asset_id: str
    rect: tuple[int, int, int, int]       # source x, y, w, h
    cells: tuple[int, int]                # runtime footprint in 32x32 cells
    domain: Domain
    kind: str
    layer: str
    collision: Collision = "none"
    anchor: Anchor = "top_left"
    tags: tuple[str, ...] = field(default_factory=tuple)
    notes: str = ""


# ---------------------------------------------------------------------------
# Exact crop specs for causeway_tiles_master.png
# ---------------------------------------------------------------------------

TILE_SPECS: list[CropSpec] = [
    # Ocean & water row
    CropSpec("tiles", "ocean_dark_water_01", (22, 94, 158, 158), (2, 2), "ocean", "water_base", "TerrainBase", "water", tags=("water", "repeatable")),
    CropSpec("tiles", "ocean_dark_water_02", (198, 94, 160, 158), (2, 2), "ocean", "water_base_variant", "TerrainBase", "water", tags=("water", "repeatable", "variant")),
    CropSpec("tiles", "ocean_current_streak_01", (376, 94, 160, 158), (2, 2), "ocean", "current_streak", "TerrainBase", "water", tags=("water", "overlay", "variant")),
    CropSpec("tiles", "ocean_foam_open_01", (560, 94, 162, 158), (2, 2), "ocean", "foam_open", "TerrainOverlay", "none", tags=("water", "foam")),
    CropSpec("tiles", "ocean_foam_edge_left_01", (746, 94, 202, 158), (2, 2), "ocean", "foam_edge_left", "TerrainOverlay", "none", tags=("water", "foam", "edge")),
    CropSpec("tiles", "ocean_foam_edge_right_01", (966, 94, 198, 158), (2, 2), "ocean", "foam_edge_right", "TerrainOverlay", "none", tags=("water", "foam", "edge")),
    CropSpec("tiles", "ocean_foam_edge_bottom_01", (1182, 94, 196, 158), (2, 2), "ocean", "foam_edge_bottom", "TerrainOverlay", "none", tags=("water", "foam", "edge")),

    # Cliffs & rocks
    CropSpec("tiles", "cliff_face_dark_01", (22, 314, 154, 142), (1, 1), "cliffs", "cliff_face", "TerrainEdges", "solid", tags=("cliff", "face")),
    CropSpec("tiles", "cliff_face_dark_02", (198, 314, 160, 142), (1, 1), "cliffs", "cliff_face", "TerrainEdges", "solid", tags=("cliff", "face", "variant")),
    CropSpec("tiles", "cliff_face_wet_01", (378, 314, 160, 142), (1, 1), "cliffs", "cliff_face_wet", "TerrainEdges", "solid", tags=("cliff", "wet", "variant")),
    CropSpec("tiles", "cliff_rock_cluster_01", (566, 314, 154, 142), (2, 2), "cliffs", "rock_cluster", "PropsBlocking", "solid", "bottom_center", tags=("cliff", "rocks", "cluster")),
    CropSpec("tiles", "cliff_rock_cluster_02", (746, 314, 156, 142), (2, 2), "cliffs", "rock_cluster", "PropsBlocking", "solid", "bottom_center", tags=("cliff", "rocks", "cluster", "variant")),
    CropSpec("tiles", "cliff_top_mossy_edge_01", (928, 314, 186, 142), (2, 1), "cliffs", "cliff_top_mossy_edge", "TerrainEdges", "edge", tags=("cliff", "top", "mossy")),
    CropSpec("tiles", "cliff_top_mossy_edge_02", (1130, 314, 198, 142), (2, 1), "cliffs", "cliff_top_mossy_edge", "TerrainEdges", "edge", tags=("cliff", "top", "mossy", "variant")),

    # Causeway floor tiles
    CropSpec("tiles", "causeway_floor_center_01", (22, 519, 158, 126), (1, 1), "causeway_floor", "floor_center", "FloorDetail", tags=("floor", "causeway", "repeatable")),
    CropSpec("tiles", "causeway_floor_center_02", (210, 519, 158, 126), (1, 1), "causeway_floor", "floor_center", "FloorDetail", tags=("floor", "causeway", "repeatable", "variant")),
    CropSpec("tiles", "causeway_floor_center_03", (398, 519, 158, 126), (1, 1), "causeway_floor", "floor_center", "FloorDetail", tags=("floor", "causeway", "repeatable", "variant")),
    CropSpec("tiles", "causeway_floor_cracked_01", (586, 519, 158, 126), (1, 1), "causeway_floor", "floor_cracked", "FloorDetail", tags=("floor", "causeway", "cracked", "variant")),
    CropSpec("tiles", "causeway_floor_mossy_01", (774, 519, 158, 126), (1, 1), "causeway_floor", "floor_mossy", "FloorDetail", tags=("floor", "causeway", "mossy", "variant")),
    CropSpec("tiles", "causeway_floor_puddle_01", (964, 519, 158, 126), (1, 1), "causeway_floor", "floor_puddle", "FloorDetail", tags=("floor", "causeway", "puddle", "variant")),
    CropSpec("tiles", "causeway_floor_puddle_02", (1150, 519, 154, 126), (1, 1), "causeway_floor", "floor_puddle", "FloorDetail", tags=("floor", "causeway", "puddle", "variant")),
    CropSpec("tiles", "causeway_floor_grate_01", (22, 676, 142, 110), (1, 1), "causeway_floor", "floor_grate_square", "FloorDetail", tags=("floor", "causeway", "grate")),
    CropSpec("tiles", "causeway_floor_grate_02", (192, 676, 142, 110), (1, 1), "causeway_floor", "floor_grate_round", "FloorDetail", tags=("floor", "causeway", "grate")),

    # Causeway edges
    CropSpec("tiles", "causeway_edge_left_vertical_01", (588, 710, 44, 85), (1, 2), "causeway_edges", "edge_left_vertical", "TerrainEdges", "edge", tags=("edge", "causeway", "vertical")),
    CropSpec("tiles", "causeway_edge_right_vertical_01", (722, 710, 44, 85), (1, 2), "causeway_edges", "edge_right_vertical", "TerrainEdges", "edge", tags=("edge", "causeway", "vertical")),
    CropSpec("tiles", "causeway_edge_top_horizontal_01", (852, 730, 218, 55), (3, 1), "causeway_edges", "edge_top_horizontal", "TerrainEdges", "edge", tags=("edge", "causeway", "horizontal")),
    CropSpec("tiles", "causeway_edge_bottom_horizontal_01", (1106, 730, 252, 55), (3, 1), "causeway_edges", "edge_bottom_horizontal", "TerrainEdges", "edge", tags=("edge", "causeway", "horizontal")),

    # Parapets and posts
    CropSpec("tiles", "causeway_parapet_post_01", (32, 868, 92, 96), (1, 1), "causeway_edges", "parapet_post", "PropsBlocking", "solid", "center", tags=("post", "causeway", "parapet")),
    CropSpec("tiles", "causeway_parapet_post_02", (160, 868, 92, 96), (1, 1), "causeway_edges", "parapet_post", "PropsBlocking", "solid", "center", tags=("post", "causeway", "parapet", "variant")),

    # Corners
    CropSpec("tiles", "causeway_corner_block_nw_01", (318, 866, 102, 100), (2, 2), "causeway_edges", "corner_nw", "TerrainEdges", "solid", tags=("corner", "causeway", "nw")),
    CropSpec("tiles", "causeway_corner_block_ne_01", (444, 866, 102, 100), (2, 2), "causeway_edges", "corner_ne", "TerrainEdges", "solid", tags=("corner", "causeway", "ne")),
    CropSpec("tiles", "causeway_corner_block_sw_01", (570, 866, 102, 100), (2, 2), "causeway_edges", "corner_sw", "TerrainEdges", "solid", tags=("corner", "causeway", "sw")),
    CropSpec("tiles", "causeway_corner_block_se_01", (696, 866, 102, 100), (2, 2), "causeway_edges", "corner_se", "TerrainEdges", "solid", tags=("corner", "causeway", "se")),

    # Diagonal walls
    CropSpec("tiles", "causeway_diagonal_wall_nw_01", (884, 866, 104, 100), (2, 2), "causeway_edges", "diagonal_wall_nw", "TerrainEdges", "solid", tags=("diagonal", "wall", "causeway", "nw")),
    CropSpec("tiles", "causeway_diagonal_wall_ne_01", (1002, 866, 104, 100), (2, 2), "causeway_edges", "diagonal_wall_ne", "TerrainEdges", "solid", tags=("diagonal", "wall", "causeway", "ne")),
    CropSpec("tiles", "causeway_diagonal_wall_sw_01", (1150, 866, 104, 100), (2, 2), "causeway_edges", "diagonal_wall_sw", "TerrainEdges", "solid", tags=("diagonal", "wall", "causeway", "sw")),
    CropSpec("tiles", "causeway_diagonal_wall_se_01", (1266, 866, 104, 100), (2, 2), "causeway_edges", "diagonal_wall_se", "TerrainEdges", "solid", tags=("diagonal", "wall", "causeway", "se")),
]


# ---------------------------------------------------------------------------
# Exact crop specs for causeway_walls_master.png
# ---------------------------------------------------------------------------

WALL_SPECS: list[CropSpec] = [
    # Top row wall modules
    CropSpec("walls", "keep_wall_face_01", (30, 66, 186, 174), (4, 4), "keep_walls", "wall_face", "WallsHigh", "solid", tags=("keep", "wall", "face")),
    CropSpec("walls", "keep_wall_face_02", (260, 66, 186, 174), (4, 4), "keep_walls", "wall_face", "WallsHigh", "solid", tags=("keep", "wall", "face", "variant")),
    CropSpec("walls", "keep_wall_top_crenellation_01", (505, 116, 184, 94), (4, 2), "keep_walls", "top_crenellation", "WallsHigh", "solid", tags=("keep", "wall", "crenellation")),
    CropSpec("walls", "keep_wall_top_crenellation_02", (770, 116, 186, 94), (4, 2), "keep_walls", "top_crenellation", "WallsHigh", "solid", tags=("keep", "wall", "crenellation", "variant")),
    CropSpec("walls", "keep_buttress_vertical_left_01", (1044, 66, 100, 174), (2, 4), "keep_walls", "vertical_buttress_left", "WallsHigh", "solid", "bottom_center", tags=("keep", "buttress", "vertical")),
    CropSpec("walls", "keep_buttress_vertical_right_01", (1256, 66, 100, 174), (2, 4), "keep_walls", "vertical_buttress_right", "WallsHigh", "solid", "bottom_center", tags=("keep", "buttress", "vertical")),

    # Gatehouse row
    CropSpec("walls", "gatehouse_main_portcullis_01", (44, 310, 292, 192), (6, 6), "gatehouse", "main_portcullis", "WallsHigh", "solid", "bottom_center", tags=("gatehouse", "portcullis", "macro")),
    CropSpec("walls", "gatehouse_steps_front_01", (404, 326, 266, 174), (6, 3), "gatehouse", "steps_front", "Traversal", "none", tags=("gatehouse", "stairs", "walkable")),
    CropSpec("walls", "gothic_side_door_left_01", (720, 340, 122, 160), (2, 3), "gatehouse", "side_door_left", "WallsHigh", "solid", "bottom_center", tags=("door", "gothic", "left")),
    CropSpec("walls", "gothic_side_door_right_01", (878, 340, 122, 160), (2, 3), "gatehouse", "side_door_right", "WallsHigh", "solid", "bottom_center", tags=("door", "gothic", "right")),
    CropSpec("walls", "gatehouse_roof_peak_01", (1032, 326, 292, 174), (6, 3), "gatehouse", "roof_peak", "WallsHigh", "solid", "bottom_center", tags=("gatehouse", "roof", "macro")),

    # Bastions and guard posts
    CropSpec("walls", "side_bastion_left_01", (50, 565, 178, 160), (4, 4), "gatehouse", "side_bastion_left", "WallsHigh", "solid", "bottom_center", tags=("bastion", "left", "macro")),
    CropSpec("walls", "side_bastion_right_01", (284, 565, 178, 160), (4, 4), "gatehouse", "side_bastion_right", "WallsHigh", "solid", "bottom_center", tags=("bastion", "right", "macro")),
    CropSpec("walls", "lower_guard_post_left_01", (502, 570, 126, 160), (3, 4), "gatehouse", "lower_guard_post_left", "WallsHigh", "solid", "bottom_center", tags=("guard_post", "left")),
    CropSpec("walls", "lower_guard_post_right_01", (674, 570, 126, 160), (3, 4), "gatehouse", "lower_guard_post_right", "WallsHigh", "solid", "bottom_center", tags=("guard_post", "right")),

    # Small wall-adjacent props
    CropSpec("walls", "brazier_lit_01", (846, 604, 84, 96), (1, 1), "props", "brazier_lit", "PropsStatic", "partial", "center", tags=("brazier", "lit", "fire")),
    CropSpec("walls", "brazier_lit_02", (980, 604, 84, 96), (1, 1), "props", "brazier_lit", "PropsStatic", "partial", "center", tags=("brazier", "lit", "fire", "variant")),
    CropSpec("walls", "gate_sconce_left_01", (1136, 580, 78, 130), (1, 2), "props", "gate_sconce_left", "PropsStatic", "partial", "bottom_center", tags=("sconce", "fire", "left")),
    CropSpec("walls", "gate_sconce_right_01", (1260, 580, 78, 130), (1, 2), "props", "gate_sconce_right", "PropsStatic", "partial", "bottom_center", tags=("sconce", "fire", "right")),

    # Bottom props row
    CropSpec("walls", "banner_red_vertical_01", (88, 798, 68, 188), (1, 4), "props", "banner_red_vertical", "PropsStatic", "none", "bottom_center", tags=("banner", "red", "vertical")),
    CropSpec("walls", "banner_red_vertical_02", (306, 798, 68, 188), (1, 4), "props", "banner_red_vertical", "PropsStatic", "none", "bottom_center", tags=("banner", "red", "vertical", "variant")),
    CropSpec("walls", "banner_red_small_01", (496, 846, 86, 128), (1, 2), "props", "banner_red_small", "PropsStatic", "none", "bottom_center", tags=("banner", "red", "small")),
    CropSpec("walls", "shield_wall_crest_01", (666, 846, 92, 120), (1, 1), "props", "shield_wall_crest", "PropsStatic", "none", "center", tags=("shield", "crest", "wall")),
    CropSpec("walls", "chain_or_black_post_01", (848, 808, 70, 176), (1, 3), "props", "chain_or_black_post", "PropsStatic", "partial", "bottom_center", tags=("chain", "post", "vertical")),
]


ALL_SPECS = TILE_SPECS + WALL_SPECS


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract Sundered Keep causeway master sheets into runtime assets.")
    parser.add_argument("--tiles-master", type=Path, default=DEFAULT_TILES_MASTER)
    parser.add_argument("--walls-master", type=Path, default=DEFAULT_WALLS_MASTER)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--clean", action="store_true", help="Delete output directory before extracting.")
    parser.add_argument("--debug", action="store_true", help="Write crop overlays.")
    parser.add_argument(
        "--resample",
        choices=("nearest", "box", "lanczos"),
        default="lanczos",
        help="Resize filter. Use lanczos for generated masters; nearest for true pixel-perfect atlases.",
    )
    parser.add_argument(
        "--sharpen",
        action="store_true",
        default=True,
        help="Apply mild sharpening after resize when not using nearest.",
    )
    parser.add_argument(
        "--no-sharpen",
        action="store_false",
        dest="sharpen",
        help="Disable post-resize sharpening.",
    )
    return parser.parse_args()


def get_resample(name: str) -> Image.Resampling:
    if name == "nearest":
        return Image.Resampling.NEAREST
    if name == "box":
        return Image.Resampling.BOX
    return Image.Resampling.LANCZOS


def ensure_dirs(out: Path, clean: bool) -> dict[str, Path]:
    if clean and out.exists():
        shutil.rmtree(out)

    dirs = {
        "root": out,
        "ocean": out / "ocean",
        "cliffs": out / "cliffs",
        "causeway_floor": out / "causeway_floor",
        "causeway_edges": out / "causeway_edges",
        "keep_walls": out / "keep_walls",
        "gatehouse": out / "gatehouse",
        "props": out / "props",
        "reports": out / "reports",
        "debug": out / "_debug",
    }

    for path in dirs.values():
        path.mkdir(parents=True, exist_ok=True)

    return dirs


def load_master(path: Path, expected_name: str) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Missing {expected_name}: {path}")

    img = Image.open(path).convert("RGBA")
    if img.size != EXPECTED_MASTER_SIZE:
        print(f"WARNING: {expected_name} size is {img.size}, expected {EXPECTED_MASTER_SIZE}. Crop rects may need tuning.")
    return img


def runtime_size(spec: CropSpec) -> tuple[int, int]:
    return spec.cells[0] * TILE_SIZE, spec.cells[1] * TILE_SIZE


def crop_and_resize(master: Image.Image, spec: CropSpec, resample: Image.Resampling, sharpen: bool) -> Image.Image:
    x, y, w, h = spec.rect
    crop = master.crop((x, y, x + w, y + h)).convert("RGBA")

    out_w, out_h = runtime_size(spec)
    resized = crop.resize((out_w, out_h), resample=resample)

    if sharpen and resample != Image.Resampling.NEAREST:
        resized = ImageEnhance.Sharpness(resized).enhance(1.25)
        resized = ImageEnhance.Contrast(resized).enhance(1.03)

    return resized.convert("RGBA")


def collision_shape(spec: CropSpec) -> dict:
    w, h = runtime_size(spec)

    if spec.collision == "none":
        return {"type": "none"}

    if spec.collision == "water":
        return {
            "type": "rect",
            "size_px": [w, h],
            "offset_px": [0, 0],
            "layers": ["water_void", "terrain_blocker"],
        }

    if spec.collision == "edge":
        return {
            "type": "rect",
            "size_px": [w, h],
            "offset_px": [0, 0],
            "layers": ["terrain_blocker"],
        }

    if spec.collision == "partial":
        return {
            "type": "rect",
            "size_px": [max(8, int(w * 0.65)), max(8, int(h * 0.65))],
            "offset_px": [int(w * 0.175), int(h * 0.25)],
            "layers": ["prop_blocker"],
        }

    return {
        "type": "rect",
        "size_px": [w, h],
        "offset_px": [0, 0],
        "layers": ["solid"],
    }


def render_policy(spec: CropSpec) -> dict:
    if spec.domain in ("ocean", "causeway_floor"):
        z = -20
        y_sort = False
    elif spec.domain in ("cliffs", "causeway_edges"):
        z = -10
        y_sort = False
    elif spec.domain in ("keep_walls", "gatehouse"):
        z = 20
        y_sort = True
    else:
        z = 10
        y_sort = True

    return {
        "recommended_layer": spec.layer,
        "z_index_hint": z,
        "y_sort": y_sort,
        "anchor": spec.anchor,
        "texture_filter": "nearest",
        "pixel_snap": True,
    }


def make_manifest_record(spec: CropSpec, png_path: Path, out_root: Path) -> dict:
    out_w, out_h = runtime_size(spec)
    rel_texture = str(png_path.relative_to(out_root)).replace("\\", "/")

    return {
        "id": spec.asset_id,
        "texture": rel_texture,
        "source_master": spec.source,
        "source_rect_px": list(spec.rect),
        "domain": spec.domain,
        "kind": spec.kind,
        "tags": list(spec.tags),
        "tile_size": TILE_SIZE,
        "runtime_size_px": [out_w, out_h],
        "footprint_tiles": list(spec.cells),
        "collision": spec.collision,
        "collision_shape": collision_shape(spec),
        "render": render_policy(spec),
        "game32": {
            "schema": "game32.asset.v1",
            "frame_count": 1,
            "frame_size_px": [out_w, out_h],
            "grid_px": TILE_SIZE,
            "atlas": False,
            "runtime_canvas_multiple_of_32": out_w % 32 == 0 and out_h % 32 == 0,
            "repeatable": "repeatable" in spec.tags,
            "variant": "variant" in spec.tags,
        },
        "notes": spec.notes,
    }


def write_debug_overlay(master: Image.Image, specs: list[CropSpec], out_path: Path, title: str) -> None:
    img = master.convert("RGBA")
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    colors = {
        "ocean": (70, 140, 255, 255),
        "cliffs": (120, 200, 140, 255),
        "causeway_floor": (80, 240, 120, 255),
        "causeway_edges": (120, 190, 255, 255),
        "keep_walls": (255, 180, 70, 255),
        "gatehouse": (255, 120, 70, 255),
        "props": (255, 90, 220, 255),
    }

    draw.rectangle((8, 8, 8 + len(title) * 8 + 12, 30), fill=(0, 0, 0, 180))
    draw.text((14, 13), title, fill=(255, 255, 255, 255), font=font)

    for idx, spec in enumerate(specs, start=1):
        x, y, w, h = spec.rect
        color = colors.get(spec.domain, (255, 255, 255, 255))
        draw.rectangle((x, y, x + w, y + h), outline=color, width=3)
        label = f"{idx}:{spec.asset_id}"
        label_w = max(80, len(label) * 6 + 8)
        label_y = max(0, y - 12)
        draw.rectangle((x, label_y, x + label_w, label_y + 12), fill=(0, 0, 0, 190))
        draw.text((x + 2, label_y + 1), label, fill=color, font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def make_contact_sheet(records: list[dict], out_root: Path, out_path: Path) -> None:
    thumb = 128
    pad = 12
    label_h = 42
    cols = 5
    rows = math.ceil(len(records) / cols)

    sheet_w = cols * (thumb + pad) + pad
    sheet_h = rows * (thumb + label_h + pad) + pad

    sheet = Image.new("RGBA", (sheet_w, sheet_h), (18, 18, 20, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for i, record in enumerate(records):
        col = i % cols
        row = i // cols
        x = pad + col * (thumb + pad)
        y = pad + row * (thumb + label_h + pad)

        src = Image.open(out_root / record["texture"]).convert("RGBA")
        scale = min(thumb / src.width, thumb / src.height)
        scaled = src.resize(
            (max(1, int(src.width * scale)), max(1, int(src.height * scale))),
            Image.Resampling.NEAREST,
        )

        bg = Image.new("RGBA", (thumb, thumb), (34, 34, 38, 255))
        bg.alpha_composite(scaled, ((thumb - scaled.width) // 2, (thumb - scaled.height) // 2))
        sheet.alpha_composite(bg, (x, y))

        draw.rectangle((x, y, x + thumb, y + thumb), outline=(90, 90, 96, 255))

        asset_id = record["id"]
        label = asset_id if len(asset_id) <= 26 else asset_id[:25] + "…"
        draw.text((x, y + thumb + 4), label, fill=(235, 235, 235, 255), font=font)
        draw.text(
            (x, y + thumb + 17),
            f'{record["domain"]} {record["runtime_size_px"][0]}x{record["runtime_size_px"][1]}',
            fill=(170, 170, 178, 255),
            font=font,
        )
        draw.text(
            (x, y + thumb + 30),
            f'{record["source_master"]}:{record["source_rect_px"]}',
            fill=(130, 130, 138, 255),
            font=font,
        )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def write_report(records: list[dict], out_root: Path, tiles_master: Path, walls_master: Path) -> None:
    by_domain: dict[str, list[dict]] = {}
    for record in records:
        by_domain.setdefault(record["domain"], []).append(record)

    lines = [
        "# Sundered Keep Causeway Runtime Extraction",
        "",
        f"- Tiles master: `{tiles_master}`",
        f"- Walls master: `{walls_master}`",
        f"- Asset count: {len(records)}",
        f"- Tile size: {TILE_SIZE}",
        "",
        "## Domains",
        "",
    ]

    for domain in sorted(by_domain):
        lines.append(f"### {domain}")
        lines.append("")
        for record in by_domain[domain]:
            lines.append(
                f"- `{record['id']}` — {record['kind']} — "
                f"{record['runtime_size_px'][0]}x{record['runtime_size_px'][1]} — "
                f"source `{record['source_master']}` rect `{record['source_rect_px']}`"
            )
        lines.append("")

    lines.extend([
        "## Notes",
        "",
        "- These assets were extracted from labeled master sheets, not from a raw atlas.",
        "- Crops are exact for the generated 1448x1086 masters.",
        "- If either master is regenerated, rerun with `--debug` and retune crop rects.",
        "- Large architecture pieces are macro stamps and should not be treated as repeatable 32x32 tiles.",
        "",
    ])

    (out_root / "reports" / "extraction_report.md").write_text("\n".join(lines), encoding="utf-8")


def write_reconstruct_plan(out_root: Path) -> None:
    plan = {
        "schema": "custodian.sundered_keep.causeway_runtime_reconstruct_plan.v1",
        "tile_size": 32,
        "map_size_tiles": [44, 54],
        "coordinate_system": "tile_xy_top_left",
        "layers": [
            "TerrainBase",
            "TerrainOverlay",
            "FloorDetail",
            "TerrainEdges",
            "Traversal",
            "WallsHigh",
            "PropsStatic",
            "PropsBlocking",
        ],
        "ops": [
            {"op": "fill_rect", "asset": "ocean_dark_water_01", "rect": [0, 0, 44, 54], "layer": "TerrainBase"},
            {"op": "scatter_rect", "asset": "ocean_dark_water_02", "rect": [0, 0, 44, 54], "density": 0.18, "layer": "TerrainBase"},
            {"op": "scatter_rect", "asset": "ocean_current_streak_01", "rect": [0, 0, 44, 54], "density": 0.07, "layer": "TerrainOverlay"},

            {"op": "fill_rect", "asset": "causeway_floor_center_01", "rect": [19, 14, 6, 32], "layer": "FloorDetail"},
            {"op": "scatter_rect", "asset": "causeway_floor_center_02", "rect": [19, 14, 6, 32], "density": 0.20, "layer": "FloorDetail"},
            {"op": "scatter_rect", "asset": "causeway_floor_center_03", "rect": [19, 14, 6, 32], "density": 0.15, "layer": "FloorDetail"},
            {"op": "scatter_rect", "asset": "causeway_floor_cracked_01", "rect": [19, 14, 6, 32], "density": 0.10, "layer": "FloorDetail"},
            {"op": "scatter_rect", "asset": "causeway_floor_mossy_01", "rect": [19, 14, 6, 32], "density": 0.08, "layer": "FloorDetail"},
            {"op": "scatter_rect", "asset": "causeway_floor_puddle_01", "rect": [19, 20, 6, 22], "density": 0.05, "layer": "FloorDetail"},

            {"op": "repeat_vertical", "asset": "causeway_edge_left_vertical_01", "tile": [18, 15], "count": 14, "step": [0, 2], "layer": "TerrainEdges"},
            {"op": "repeat_vertical", "asset": "causeway_edge_right_vertical_01", "tile": [25, 15], "count": 14, "step": [0, 2], "layer": "TerrainEdges"},
            {"op": "place", "asset": "causeway_corner_block_nw_01", "tile": [17, 13], "layer": "TerrainEdges"},
            {"op": "place", "asset": "causeway_corner_block_ne_01", "tile": [25, 13], "layer": "TerrainEdges"},
            {"op": "place", "asset": "causeway_corner_block_sw_01", "tile": [17, 44], "layer": "TerrainEdges"},
            {"op": "place", "asset": "causeway_corner_block_se_01", "tile": [25, 44], "layer": "TerrainEdges"},

            {"op": "place", "asset": "gatehouse_steps_front_01", "tile": [16, 10], "layer": "Traversal"},
            {"op": "place", "asset": "gatehouse_main_portcullis_01", "tile": [13, 2], "layer": "WallsHigh"},
            {"op": "place", "asset": "gothic_side_door_left_01", "tile": [10, 5], "layer": "WallsHigh"},
            {"op": "place", "asset": "gothic_side_door_right_01", "tile": [31, 5], "layer": "WallsHigh"},
            {"op": "place", "asset": "side_bastion_left_01", "tile": [9, 18], "layer": "WallsHigh"},
            {"op": "place", "asset": "side_bastion_right_01", "tile": [31, 18], "layer": "WallsHigh"},
            {"op": "place", "asset": "lower_guard_post_left_01", "tile": [13, 32], "layer": "WallsHigh"},
            {"op": "place", "asset": "lower_guard_post_right_01", "tile": [28, 32], "layer": "WallsHigh"},

            {"op": "place", "asset": "brazier_lit_01", "tile": [17, 18], "layer": "PropsStatic"},
            {"op": "place", "asset": "brazier_lit_02", "tile": [26, 18], "layer": "PropsStatic"},
            {"op": "place", "asset": "gate_sconce_left_01", "tile": [14, 10], "layer": "PropsStatic"},
            {"op": "place", "asset": "gate_sconce_right_01", "tile": [29, 10], "layer": "PropsStatic"},
        ],
    }

    (out_root / "reports" / "causeway_reconstruct_plan.json").write_text(
        json.dumps(plan, indent=2),
        encoding="utf-8",
    )


def main() -> int:
    args = parse_args()

    tiles_master = args.tiles_master.expanduser()
    walls_master = args.walls_master.expanduser()
    out_root = args.out.expanduser()

    dirs = ensure_dirs(out_root, clean=args.clean)

    masters = {
        "tiles": load_master(tiles_master, "tiles master"),
        "walls": load_master(walls_master, "walls master"),
    }

    resample = get_resample(args.resample)

    records: list[dict] = []

    for spec in ALL_SPECS:
        img = crop_and_resize(masters[spec.source], spec, resample, args.sharpen)
        png_path = dirs[spec.domain] / f"{spec.asset_id}.png"
        img.save(png_path)
        records.append(make_manifest_record(spec, png_path, out_root))

    manifest = {
        "schema": "custodian.game32.sundered_keep.causeway_runtime.v1",
        "tile_size": TILE_SIZE,
        "source_masters": {
            "tiles": str(tiles_master),
            "walls": str(walls_master),
        },
        "output_root": str(out_root),
        "asset_count": len(records),
        "domains": sorted({record["domain"] for record in records}),
        "assets": records,
    }

    manifest_path = dirs["reports"] / "causeway_runtime.game32.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    make_contact_sheet(records, out_root, dirs["reports"] / "extraction_contact_sheet.png")
    write_report(records, out_root, tiles_master, walls_master)
    write_reconstruct_plan(out_root)

    if args.debug:
        write_debug_overlay(masters["tiles"], TILE_SPECS, dirs["reports"] / "crop_overlay_tiles.png", "causeway_tiles_master crops")
        write_debug_overlay(masters["walls"], WALL_SPECS, dirs["reports"] / "crop_overlay_walls.png", "causeway_walls_master crops")

    print(f"wrote assets:   {len(records)}")
    print(f"output root:    {out_root}")
    print(f"manifest:       {manifest_path}")
    print(f"contact sheet:  {dirs['reports'] / 'extraction_contact_sheet.png'}")
    print(f"reconstruct:    {dirs['reports'] / 'causeway_reconstruct_plan.json'}")

    if args.debug:
        print(f"tiles overlay:  {dirs['reports'] / 'crop_overlay_tiles.png'}")
        print(f"walls overlay:  {dirs['reports'] / 'crop_overlay_walls.png'}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
