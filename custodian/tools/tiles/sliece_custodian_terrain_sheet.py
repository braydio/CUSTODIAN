#!/usr/bin/env python3
"""
Slice the annotated CUSTODIAN terrain reference sheet into individual terrain tiles
and emit a manifest with gameplay metadata.

This script intentionally DOES NOT use OCR. The tile IDs are mapped by the known
visual order of the sheet. That is much safer than trying to read tiny generated
labels from the image.

Expected source:
- Annotated 1536x1024 terrain sheet.
- Tile cards arranged in section rows.
- Each card contains label area, tile preview, and small metadata footer.

Outputs:
- raw_preview_tiles/<tile_id>.png       exact preview crop from the sheet
- tiles_32/<tile_id>.png                normalized square tile for Godot
- terrain_tiles_32_atlas.png            clean atlas, no labels
- terrain_tiles_manifest.json           tile metadata and source rects
- debug_extraction_overlay.png          crop verification overlay

Notes:
- The source image is an annotated chart, not a clean production atlas.
- To avoid dropping pixels, the default normalization mode stretches the full
  preview crop into a square. Use --resize-mode crop only if you want centered
  square crops and accept losing edge pixels.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw


# ---------------------------------------------------------------------------
# Tile metadata
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TileSpec:
    id: str
    label: str
    category: str
    movement: str
    elevation: int
    flags: list[str]
    biome: str
    description: str

    @property
    def blocks_movement(self) -> bool:
        return self.movement == "blocked"

    @property
    def blocks_vision(self) -> bool:
        return self.movement == "blocked" or "blocks_vision" in self.flags

    @property
    def navigation_cost(self) -> float:
        if self.movement == "blocked":
            return 9999.0
        if self.movement == "water":
            return 3.0
        if self.movement == "slow":
            return 1.8
        return 1.0


def t(
    id_: str,
    label: str,
    category: str,
    movement: str = "walkable",
    elevation: int = 0,
    flags: list[str] | None = None,
    biome: str = "neutral",
    description: str = "",
) -> TileSpec:
    return TileSpec(
        id=id_,
        label=label,
        category=category,
        movement=movement,
        elevation=elevation,
        flags=flags or [],
        biome=biome,
        description=description or label,
    )


TILE_SPECS: list[TileSpec] = [
    # -----------------------------------------------------------------------
    # Row 1
    # -----------------------------------------------------------------------
    t("grass_01", "GRASS 01", "ground_grasslands", "walkable", 0, ["cover", "stealth"], "grasslands", "Short green grass with small texture variation."),
    t("grass_02", "GRASS 02", "ground_grasslands", "walkable", 0, ["cover"], "grasslands", "Patchy grass with stones and bare soil."),
    t("grass_03", "GRASS 03", "ground_grasslands", "walkable", 0, ["cover", "stealth"], "grasslands", "Dense mossy grass with darker clumps."),
    t("flower_patch", "FLOWER PATCH", "ground_grasslands", "walkable", 0, ["flavor", "stealth"], "grasslands", "Readable flower patch for visual variety."),
    t("tall_grass", "TALL GRASS", "ground_grasslands", "walkable", 0, ["cover", "stealth"], "grasslands", "Tall grass that can imply concealment."),

    t("dirt", "DIRT", "ground_rocky_dirt", "slow", 0, [], "dirt", "Plain dirt ground."),
    t("rocky_dirt", "ROCKY DIRT", "ground_rocky_dirt", "slow", 0, [], "dirt", "Dirt with scattered rocks."),
    t("gravel", "GRAVEL", "ground_rocky_dirt", "slow", 0, [], "rocky", "Loose gravel ground."),
    t("stone_floor", "STONE FLOOR", "ground_rocky_dirt", "walkable", 0, ["manmade"], "stone", "Walkable stone floor tile."),
    t("cracked_earth", "CRACKED EARTH", "ground_rocky_dirt", "slow", 0, [], "dirt", "Dry cracked earth."),

    t("scorched_dirt", "SCORCHED DIRT", "ground_scorched_ash", "walkable", 0, ["hazard_theme"], "scorched", "Blackened dirt."),
    t("ash", "ASH", "ground_scorched_ash", "walkable", 0, ["hazard_theme"], "scorched", "Ashy ground."),
    t("burned_rock", "BURNED ROCK", "ground_scorched_ash", "slow", 0, ["hazard_theme"], "scorched", "Burned rocky ground."),
    t("lava_crust", "LAVA CRUST", "ground_scorched_ash", "slow", 0, ["hazard", "heat"], "lava", "Crusted lava ground, slow and dangerous-looking."),
    t("cracked_lava", "CRACKED LAVA", "ground_scorched_ash", "slow", 0, ["hazard", "heat"], "lava", "Cracked lava crust."),

    t("snow", "SNOW", "snow_ice", "walkable", 0, ["cold"], "snow", "Snow ground."),
    t("snow_drifts", "SNOW DRIFTS", "snow_ice", "slow", 0, ["cold"], "snow", "Deep snow drifts."),
    t("ice", "ICE", "snow_ice", "slow", 0, ["cold", "slippery"], "ice", "Ice ground."),
    t("frozen_ground", "FROZEN GROUND", "snow_ice", "slow", 0, ["cold"], "ice", "Frozen cracked ground."),
    t("packed_snow", "PACKED SNOW", "snow_ice", "walkable", 0, ["cold"], "snow", "Packed snow path."),

    # -----------------------------------------------------------------------
    # Row 2
    # -----------------------------------------------------------------------
    t("cliff_top", "CLIFF TOP", "elevation_cliffs_north", "walkable", 1, ["elevation"], "grasslands", "Top surface of a raised cliff."),
    t("cliff_edge_n", "CLIFF EDGE N", "elevation_cliffs_north", "blocked", 1, ["ledge", "blocks_vision"], "grasslands", "North-facing cliff edge."),
    t("cliff_edge_ne", "CLIFF EDGE NE", "elevation_cliffs_north", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Northeast cliff edge."),
    t("cliff_edge_nw", "CLIFF EDGE NW", "elevation_cliffs_north", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Northwest cliff edge."),
    t("cliff_corner_ne", "CLIFF CORNER NE", "elevation_cliffs_north", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Northeast cliff corner."),
    t("cliff_corner_nw", "CLIFF CORNER NW", "elevation_cliffs_north", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Northwest cliff corner."),

    t("cliff_edge_s", "CLIFF EDGE S", "elevation_cliffs_south", "blocked", 1, ["ledge", "blocks_vision"], "grasslands", "South-facing cliff edge."),
    t("cliff_edge_se", "CLIFF EDGE SE", "elevation_cliffs_south", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Southeast cliff edge."),
    t("cliff_edge_sw", "CLIFF EDGE SW", "elevation_cliffs_south", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Southwest cliff edge."),
    t("cliff_corner_se", "CLIFF CORNER SE", "elevation_cliffs_south", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Southeast cliff corner."),
    t("cliff_corner_sw", "CLIFF CORNER SW", "elevation_cliffs_south", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Southwest cliff corner."),
    t("cliff_inner_corner", "CLIFF INNER CORNER", "elevation_cliffs_south", "blocked", 1, ["ledge", "inner_corner", "blocks_vision"], "grasslands", "Inner cliff corner."),

    t("plateau_top", "PLATEAU TOP", "elevation_plateaus", "walkable", 1, ["elevation"], "grasslands", "Raised plateau top."),
    t("plateau_edge", "PLATEAU EDGE", "elevation_plateaus", "blocked", 1, ["ledge", "blocks_vision"], "grasslands", "Raised plateau edge."),
    t("plateau_corner", "PLATEAU CORNER", "elevation_plateaus", "blocked", 1, ["ledge", "corner", "blocks_vision"], "grasslands", "Raised plateau corner."),
    t("plateau_inner_corner", "PLATEAU INNER CORNER", "elevation_plateaus", "blocked", 1, ["ledge", "inner_corner", "blocks_vision"], "grasslands", "Raised plateau inner corner."),
    t("low_raise", "LOW RAISE", "elevation_plateaus", "walkable", 1, ["elevation"], "grasslands", "Low raised terrain."),

    # -----------------------------------------------------------------------
    # Row 3
    # -----------------------------------------------------------------------
    t("ramp_n", "RAMP N", "slopes_ramps", "walkable", 1, ["ramp", "direction_n"], "grasslands", "North ramp transition."),
    t("ramp_s", "RAMP S", "slopes_ramps", "walkable", 1, ["ramp", "direction_s"], "grasslands", "South ramp transition."),
    t("ramp_e", "RAMP E", "slopes_ramps", "walkable", 1, ["ramp", "direction_e"], "grasslands", "East ramp transition."),
    t("ramp_w", "RAMP W", "slopes_ramps", "walkable", 1, ["ramp", "direction_w"], "grasslands", "West ramp transition."),
    t("ramp_ne", "RAMP NE", "slopes_ramps", "walkable", 1, ["ramp", "direction_ne"], "grasslands", "Northeast diagonal ramp transition."),
    t("ramp_nw", "RAMP NW", "slopes_ramps", "walkable", 1, ["ramp", "direction_nw"], "grasslands", "Northwest diagonal ramp transition."),

    t("stairs_n", "STAIRS N", "stairs", "walkable", 1, ["stair", "direction_n"], "stone", "North stair transition."),
    t("stairs_s", "STAIRS S", "stairs", "walkable", 1, ["stair", "direction_s"], "stone", "South stair transition."),
    t("stairs_e", "STAIRS E", "stairs", "walkable", 1, ["stair", "direction_e"], "stone", "East stair transition."),
    t("stairs_w", "STAIRS W", "stairs", "walkable", 1, ["stair", "direction_w"], "stone", "West stair transition."),

    t("bridge", "BRIDGE", "special_elevation", "walkable", 1, ["bridge"], "wood", "Bridge or elevated crossing."),
    t("overhang", "OVERHANG", "special_elevation", "blocked", 1, ["overhang", "blocks_vision"], "grasslands", "Overhanging elevated terrain."),
    t("ledge", "LEDGE", "special_elevation", "blocked", 1, ["ledge", "blocks_vision"], "grasslands", "Tactical ledge tile."),
    t("terrace_step", "TERRACE STEP", "special_elevation", "walkable", 1, ["stair", "terrace"], "grasslands", "Terraced step."),
    t("elevator_pad", "ELEVATOR PAD", "special_elevation", "walkable", 0, ["gate", "transition", "manmade"], "industrial", "Elevator or lift pad."),

    t("water_shallow", "WATER SHALLOW", "water", "water", -1, ["swimmable"], "water", "Shallow water."),
    t("water_deep", "WATER DEEP", "water", "water", -1, ["deep_water"], "water", "Deep water."),
    t("waves", "WAVES", "water", "water", -1, ["deep_water"], "water", "Wavy water surface."),
    t("river", "RIVER", "water", "water", -1, ["current"], "water", "River tile."),
    t("waterfall", "WATERFALL", "water", "water", -1, ["waterfall", "blocks_vision"], "water", "Waterfall or vertical water drop."),

    # -----------------------------------------------------------------------
    # Row 4
    # -----------------------------------------------------------------------
    t("boulder_small", "BOULDER SMALL", "obstacles_natural", "blocked", 0, ["cover", "resource_possible"], "rocky", "Small blocking boulder."),
    t("boulder_large", "BOULDER LARGE", "obstacles_natural", "blocked", 0, ["cover", "blocks_vision", "resource_possible"], "rocky", "Large blocking boulder."),
    t("rock_outcrop", "ROCK OUTCROP", "obstacles_natural", "blocked", 0, ["cover", "blocks_vision", "resource_possible"], "rocky", "Rock outcrop obstacle."),
    t("fallen_log", "FALLEN LOG", "obstacles_natural", "blocked", 0, ["cover", "resource_possible"], "forest", "Fallen log obstacle."),
    t("tree_stump", "TREE STUMP", "obstacles_natural", "blocked", 0, ["cover", "resource_possible"], "forest", "Tree stump obstacle."),
    t("dead_tree", "DEAD TREE", "obstacles_natural", "blocked", 0, ["cover", "blocks_vision", "resource_possible"], "forest", "Dead tree obstacle."),

    t("tree_oak", "TREE OAK", "vegetation", "blocked", 0, ["cover", "blocks_vision", "resource_possible"], "forest", "Oak tree prop tile."),
    t("tree_pine", "TREE PINE", "vegetation", "blocked", 0, ["cover", "blocks_vision", "resource_possible"], "forest", "Pine tree prop tile."),
    t("bush", "BUSH", "vegetation", "slow", 0, ["cover", "stealth"], "forest", "Bush tile."),
    t("shrub_cluster", "SHRUB CLUSTER", "vegetation", "slow", 0, ["cover", "stealth"], "forest", "Clustered shrubs."),
    t("cactus", "CACTUS", "vegetation", "blocked", 0, ["hazard", "cover"], "desert", "Cactus obstacle."),
    t("flowers", "FLOWERS", "vegetation", "walkable", 0, ["flavor"], "grasslands", "Flower vegetation flavor."),

    t("mud", "MUD", "swamp_mud", "slow", -1, [], "swamp", "Mud tile."),
    t("swamp", "SWAMP", "swamp_mud", "slow", -1, ["waterlogged"], "swamp", "Swamp tile."),
    t("mossy_ground", "MOSSY GROUND", "swamp_mud", "slow", -1, ["stealth"], "swamp", "Mossy wet ground."),
    t("bog", "BOG", "swamp_mud", "slow", -1, ["waterlogged"], "swamp", "Bog tile."),
    t("lily_pads", "LILY PADS", "swamp_mud", "water", -1, ["waterlogged"], "swamp", "Lily pad water tile."),

    t("sand", "SAND", "beach_sand", "walkable", 0, [], "beach", "Sand tile."),
    t("wet_sand", "WET SAND", "beach_sand", "walkable", 0, [], "beach", "Wet sand tile."),
    t("sand_with_rocks", "SAND WITH ROCKS", "beach_sand", "walkable", 0, [], "beach", "Sand with rocks."),
    t("beach_grass", "BEACH GRASS", "beach_sand", "walkable", 0, ["flavor"], "beach", "Beach grass."),
    t("coral_shells", "CORAL / SHELLS", "beach_sand", "walkable", 0, ["flavor"], "beach", "Coral and shells."),

    # -----------------------------------------------------------------------
    # Row 5
    # -----------------------------------------------------------------------
    t("barren_dirt", "BARREN DIRT", "barren_wasteland", "walkable", 0, [], "wasteland", "Barren dirt."),
    t("wasteland", "WASTELAND", "barren_wasteland", "walkable", 0, [], "wasteland", "Wasteland ground."),
    t("cracked_wasteland", "CRACKED WASTELAND", "barren_wasteland", "walkable", 0, [], "wasteland", "Cracked wasteland ground."),
    t("dry_shrub", "DRY SHRUB", "barren_wasteland", "walkable", 0, ["flavor"], "wasteland", "Dry shrub tile."),
    t("bone_pile", "BONE PILE", "barren_wasteland", "walkable", 0, ["flavor"], "wasteland", "Bone pile flavor tile."),
    t("skeleton", "SKELETON", "barren_wasteland", "walkable", 0, ["flavor"], "wasteland", "Skeleton flavor tile."),

    t("mountain", "MOUNTAIN", "blocking_terrain", "blocked", 2, ["blocks_vision", "terrain_blocker"], "mountain", "Impassable mountain."),
    t("high_mountain", "HIGH MOUNTAIN", "blocking_terrain", "blocked", 2, ["blocks_vision", "terrain_blocker"], "mountain", "High impassable mountain."),
    t("ocean_deep", "OCEAN DEEP", "blocking_terrain", "blocked", -2, ["deep_water", "terrain_blocker"], "ocean", "Deep ocean blocker."),
    t("lava", "LAVA", "blocking_terrain", "blocked", 2, ["hazard", "heat", "terrain_blocker"], "lava", "Lava blocker."),
    t("impassable_cliff", "IMPASSABLE CLIFF", "blocking_terrain", "blocked", 2, ["ledge", "blocks_vision", "terrain_blocker"], "mountain", "Impassable cliff wall."),
    t("void_chasm", "VOID / CHASM", "blocking_terrain", "blocked", -2, ["chasm", "terrain_blocker"], "void", "Void or chasm blocker."),

    t("ruined_wall", "RUINED WALL", "manmade_flavor", "blocked", 0, ["cover", "destructible", "manmade"], "ruins", "Ruined wall obstacle."),
    t("ruined_pillar", "RUINED PILLAR", "manmade_flavor", "blocked", 0, ["cover", "destructible", "manmade"], "ruins", "Ruined pillar obstacle."),
    t("crate", "CRATE", "manmade_flavor", "blocked", 0, ["cover", "destructible", "manmade"], "ruins", "Crate obstacle."),
    t("barrel", "BARREL", "manmade_flavor", "blocked", 0, ["cover", "destructible", "manmade"], "ruins", "Barrel obstacle."),
    t("broken_cart", "BROKEN CART", "manmade_flavor", "blocked", 0, ["cover", "destructible", "manmade"], "ruins", "Broken cart obstacle."),
    t("campfire_ext", "CAMPFIRE EXT", "manmade_flavor", "walkable", 0, ["flavor", "light"], "ruins", "Extinguished or low campfire flavor tile."),
]


# Section layout uses approximate section bounds from the annotated sheet.
# The script snaps the section/card boundaries to the nearest dark separator lines.
@dataclass(frozen=True)
class SectionLayout:
    name: str
    x0: int
    x1: int
    y0: int
    y1: int
    count: int


SECTION_LAYOUTS: list[SectionLayout] = [
    # row 1
    SectionLayout("ground_grasslands", 8, 421, 38, 170, 5),
    SectionLayout("ground_rocky_dirt", 423, 858, 38, 170, 5),
    SectionLayout("ground_scorched_ash", 860, 1242, 38, 170, 5),
    SectionLayout("snow_ice", 1244, 1528, 38, 170, 5),

    # row 2
    SectionLayout("elevation_cliffs_north", 8, 590, 203, 342, 6),
    SectionLayout("elevation_cliffs_south", 591, 1107, 203, 342, 6),
    SectionLayout("elevation_plateaus", 1109, 1528, 203, 342, 5),

    # row 3
    SectionLayout("slopes_ramps", 8, 488, 377, 510, 6),
    SectionLayout("stairs", 489, 746, 377, 510, 4),
    SectionLayout("special_elevation", 747, 1107, 377, 510, 5),
    SectionLayout("water", 1109, 1528, 377, 510, 5),

    # row 4
    SectionLayout("obstacles_natural", 8, 466, 545, 679, 6),
    SectionLayout("vegetation", 467, 862, 545, 679, 6),
    SectionLayout("swamp_mud", 864, 1173, 545, 679, 5),
    SectionLayout("beach_sand", 1175, 1528, 545, 679, 5),

    # row 5
    SectionLayout("barren_wasteland", 8, 478, 713, 846, 6),
    SectionLayout("blocking_terrain", 480, 1096, 713, 846, 6),
    SectionLayout("manmade_flavor", 1098, 1528, 713, 846, 6),
]


# These constants isolate the preview image inside each labeled card.
# They are deliberately exposed as CLI arguments too.
DEFAULT_LEFT_PAD = 6
DEFAULT_RIGHT_PAD = 5
DEFAULT_LABEL_HEIGHT = 22
DEFAULT_FOOTER_HEIGHT = 20


# ---------------------------------------------------------------------------
# Detection helpers
# ---------------------------------------------------------------------------

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def brightness_array(img: Image.Image) -> np.ndarray:
    arr = np.asarray(img.convert("RGB"), dtype=np.float32)
    return arr.mean(axis=2)


def snap_x_to_separator(gray: np.ndarray, x_guess: int, y0: int, y1: int, window: int = 12) -> int:
    h, w = gray.shape
    lo = max(0, x_guess - window)
    hi = min(w - 1, x_guess + window)
    if hi <= lo:
        return x_guess

    crop = gray[max(0, y0):min(h, y1), lo:hi + 1]
    if crop.size == 0:
        return x_guess

    # A real separator is dark through most of the card height.
    dark_ratio = (crop < 45).mean(axis=0)
    best = int(np.argmax(dark_ratio))
    return lo + best


def snap_y_to_separator(gray: np.ndarray, y_guess: int, x0: int, x1: int, window: int = 10) -> int:
    h, w = gray.shape
    lo = max(0, y_guess - window)
    hi = min(h - 1, y_guess + window)
    if hi <= lo:
        return y_guess

    crop = gray[lo:hi + 1, max(0, x0):min(w, x1)]
    if crop.size == 0:
        return y_guess

    dark_ratio = (crop < 45).mean(axis=1)
    best = int(np.argmax(dark_ratio))
    return lo + best


def compute_cell_boundaries(
    gray: np.ndarray,
    section: SectionLayout,
    snap_window: int,
) -> tuple[int, int, list[int]]:
    y0 = snap_y_to_separator(gray, section.y0, section.x0, section.x1)
    y1 = snap_y_to_separator(gray, section.y1, section.x0, section.x1)

    expected = [
        round(section.x0 + (section.x1 - section.x0) * i / section.count)
        for i in range(section.count + 1)
    ]

    snapped = [
        snap_x_to_separator(gray, x, y0, y1, snap_window)
        for x in expected
    ]

    # Enforce monotonicity. If snapping got weird, fall back to expected split.
    for i in range(1, len(snapped)):
        if snapped[i] <= snapped[i - 1] + 20:
            snapped = expected
            break

    return y0, y1, snapped


def normalize_tile(
    crop: Image.Image,
    tile_size: int,
    resize_mode: str,
    resample: Image.Resampling,
) -> Image.Image:
    if resize_mode == "none":
        return crop.copy()

    if resize_mode == "stretch":
        return crop.resize((tile_size, tile_size), resample)

    if resize_mode == "crop":
        side = min(crop.width, crop.height)
        left = (crop.width - side) // 2
        top = (crop.height - side) // 2
        square = crop.crop((left, top, left + side, top + side))
        return square.resize((tile_size, tile_size), resample)

    if resize_mode == "contain":
        result = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
        ratio = min(tile_size / crop.width, tile_size / crop.height)
        nw = max(1, round(crop.width * ratio))
        nh = max(1, round(crop.height * ratio))
        resized = crop.resize((nw, nh), resample)
        result.alpha_composite(resized, ((tile_size - nw) // 2, (tile_size - nh) // 2))
        return result

    raise ValueError(f"Unknown resize mode: {resize_mode}")


def build_atlas(tile_paths: list[Path], cols: int, tile_size: int, out_path: Path) -> None:
    rows = math.ceil(len(tile_paths) / cols)
    atlas = Image.new("RGBA", (cols * tile_size, rows * tile_size), (0, 0, 0, 0))

    for idx, path in enumerate(tile_paths):
        tile = Image.open(path).convert("RGBA")
        if tile.size != (tile_size, tile_size):
            tile = tile.resize((tile_size, tile_size), Image.Resampling.NEAREST)
        x = (idx % cols) * tile_size
        y = (idx // cols) * tile_size
        atlas.alpha_composite(tile, (x, y))

    atlas.save(out_path)


# ---------------------------------------------------------------------------
# Main slicing
# ---------------------------------------------------------------------------

def slice_sheet(args: argparse.Namespace) -> dict[str, Any]:
    source = Path(args.source).expanduser().resolve()
    out_dir = Path(args.out).expanduser().resolve()

    raw_dir = out_dir / "raw_preview_tiles"
    tile_dir = out_dir / f"tiles_{args.tile_size}"
    raw_dir.mkdir(parents=True, exist_ok=True)
    tile_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(source).convert("RGBA")
    rgb = img.convert("RGB")
    gray = brightness_array(rgb)

    expected_count = sum(section.count for section in SECTION_LAYOUTS)
    if expected_count != len(TILE_SPECS):
        raise RuntimeError(
            f"Internal mapping mismatch: layouts expect {expected_count}, "
            f"but TILE_SPECS has {len(TILE_SPECS)}."
        )

    if args.strict and img.size != (1536, 1024):
        raise RuntimeError(
            f"Strict mode expected source size 1536x1024, got {img.size}. "
            f"Rerun without --strict or update SECTION_LAYOUTS."
        )

    resample = Image.Resampling.NEAREST if args.resample == "nearest" else Image.Resampling.LANCZOS

    overlay = img.copy()
    draw = ImageDraw.Draw(overlay)

    manifest_tiles: list[dict[str, Any]] = []
    normalized_paths: list[Path] = []

    spec_index = 0

    for section in SECTION_LAYOUTS:
        y0, y1, boundaries = compute_cell_boundaries(gray, section, args.snap_window)

        if args.debug_print:
            print(f"{section.name}: y=({y0},{y1}) x_bounds={boundaries}")

        for i in range(section.count):
            spec = TILE_SPECS[spec_index]
            spec_index += 1

            left = boundaries[i]
            right = boundaries[i + 1]

            # Preview rect inside the labeled card.
            x0 = left + args.left_pad
            x1 = right - args.right_pad
            crop_y0 = y0 + args.label_height
            crop_y1 = y1 - args.footer_height

            if x1 <= x0 or crop_y1 <= crop_y0:
                raise RuntimeError(f"Invalid crop for {spec.id}: {(x0, crop_y0, x1, crop_y1)}")

            # Clamp to image.
            x0 = max(0, min(img.width, x0))
            x1 = max(0, min(img.width, x1))
            crop_y0 = max(0, min(img.height, crop_y0))
            crop_y1 = max(0, min(img.height, crop_y1))

            raw_crop = img.crop((x0, crop_y0, x1, crop_y1))
            raw_path = raw_dir / f"{spec.id}.png"
            raw_crop.save(raw_path)

            normalized = normalize_tile(raw_crop, args.tile_size, args.resize_mode, resample)
            tile_path = tile_dir / f"{spec.id}.png"
            normalized.save(tile_path)
            normalized_paths.append(tile_path)

            draw.rectangle((x0, crop_y0, x1 - 1, crop_y1 - 1), outline=(255, 0, 255, 255), width=2)
            draw.text((x0 + 2, crop_y0 + 2), str(spec_index), fill=(255, 255, 0, 255))

            tile_entry = {
                **asdict(spec),
                "blocks_movement": spec.blocks_movement,
                "blocks_vision": spec.blocks_vision,
                "navigation_cost": spec.navigation_cost,
                "source_rect": {
                    "x": x0,
                    "y": crop_y0,
                    "w": x1 - x0,
                    "h": crop_y1 - crop_y0,
                },
                "raw_preview_path": str(raw_path.relative_to(out_dir)),
                "tile_path": str(tile_path.relative_to(out_dir)),
                "atlas_index": spec_index - 1,
                "atlas_coord": {
                    "x": (spec_index - 1) % args.atlas_cols,
                    "y": (spec_index - 1) // args.atlas_cols,
                },
            }
            manifest_tiles.append(tile_entry)

    if spec_index != len(TILE_SPECS):
        raise RuntimeError(f"Only mapped {spec_index} specs out of {len(TILE_SPECS)}.")

    atlas_path = out_dir / f"terrain_tiles_{args.tile_size}_atlas.png"
    build_atlas(normalized_paths, args.atlas_cols, args.tile_size, atlas_path)

    overlay_path = out_dir / "debug_extraction_overlay.png"
    overlay.save(overlay_path)

    manifest = {
        "schema": "custodian.terrain_tiles_manifest.v1",
        "source_image": str(source),
        "source_sha256": sha256_file(source),
        "source_size": {"w": img.width, "h": img.height},
        "generated_tile_size": args.tile_size,
        "resize_mode": args.resize_mode,
        "resample": args.resample,
        "atlas": {
            "path": atlas_path.name,
            "cols": args.atlas_cols,
            "tile_size": args.tile_size,
        },
        "extraction": {
            "left_pad": args.left_pad,
            "right_pad": args.right_pad,
            "label_height": args.label_height,
            "footer_height": args.footer_height,
            "snap_window": args.snap_window,
            "section_layouts": [asdict(s) for s in SECTION_LAYOUTS],
            "debug_overlay": overlay_path.name,
        },
        "tiles": manifest_tiles,
    }

    manifest_path = out_dir / "terrain_tiles_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    if args.strict:
        assert len(manifest_tiles) == 97, f"Expected 97 tiles, got {len(manifest_tiles)}"
        ids = [t["id"] for t in manifest_tiles]
        assert len(ids) == len(set(ids)), "Duplicate tile IDs found"
        for tile in manifest_tiles:
            rect = tile["source_rect"]
            if rect["w"] < 32 or rect["h"] < 32:
                raise RuntimeError(f"Suspiciously small crop for {tile['id']}: {rect}")

    return {
        "out_dir": str(out_dir),
        "manifest": str(manifest_path),
        "atlas": str(atlas_path),
        "overlay": str(overlay_path),
        "count": len(manifest_tiles),
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Slice CUSTODIAN terrain reference sheet into tiles + manifest.")
    parser.add_argument("--source", required=True, help="Source terrain sheet PNG.")
    parser.add_argument("--out", required=True, help="Output directory.")
    parser.add_argument("--tile-size", type=int, default=32, help="Normalized tile size. Default: 32.")
    parser.add_argument("--atlas-cols", type=int, default=16, help="Columns in generated atlas. Default: 16.")

    parser.add_argument(
        "--resize-mode",
        choices=["stretch", "crop", "contain", "none"],
        default="stretch",
        help=(
            "How to normalize preview crops. "
            "stretch keeps all pixels but may distort; "
            "crop preserves aspect but cuts edges; "
            "contain letterboxes; none saves raw crop dimensions."
        ),
    )
    parser.add_argument(
        "--resample",
        choices=["nearest", "lanczos"],
        default="nearest",
        help="Resampling filter for normalized tiles. Use nearest for pixel art.",
    )

    parser.add_argument("--left-pad", type=int, default=DEFAULT_LEFT_PAD)
    parser.add_argument("--right-pad", type=int, default=DEFAULT_RIGHT_PAD)
    parser.add_argument("--label-height", type=int, default=DEFAULT_LABEL_HEIGHT)
    parser.add_argument("--footer-height", type=int, default=DEFAULT_FOOTER_HEIGHT)
    parser.add_argument("--snap-window", type=int, default=12, help="Pixels to search around section boundaries.")
    parser.add_argument("--strict", action="store_true", help="Fail if source size/count looks wrong.")
    parser.add_argument("--debug-print", action="store_true", help="Print snapped section boundaries.")

    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    result = slice_sheet(args)

    print("Terrain sheet extraction complete.")
    print(f"  tiles:    {result['count']}")
    print(f"  out:      {result['out_dir']}")
    print(f"  manifest: {result['manifest']}")
    print(f"  atlas:    {result['atlas']}")
    print(f"  overlay:  {result['overlay']}")
    print()
    print("Open debug_extraction_overlay.png and verify every magenta box contains only tile art.")
    print("If crop boxes are off by 1-2 px, adjust --left-pad/--right-pad/--label-height/--footer-height.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
