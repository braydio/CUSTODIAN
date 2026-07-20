#!/usr/bin/env python3
"""
semantic_slice_gothic_tilesheet.py

Semantic extractor for gothic_tilesheet.png.

This script does two jobs:

1. Detect/crop separated assets from the source sheet.
2. Apply an explicit "semantic art director" catalog by visual order.

Why this exists:
- Pure CV can crop the assets.
- Pure CV cannot know if an object is "low cover", "wall cap", "ritual POI",
  "blocking ruin", "floor decal", "compound entrance", etc.
- Procgen needs semantic intent, not just bounding boxes.

Output:
  custodian/content/tiles/gothic/...
  custodian/content/walls/gothic/...
  custodian/content/doors/gothic/...
  custodian/content/props/gothic/...
  custodian/content/structures/gothic/...
  custodian/content/animations/gothic/banner_flap_10f.png
  custodian/content/tiles/gothic/gothic_tilesheet_manifest.game32.json

Requires:
  python3 -m pip install pillow numpy
"""

from __future__ import annotations

import argparse
import json
import math
import re
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from PIL import Image


# ---------------------------------------------------------------------
# Semantic art direction catalog
# ---------------------------------------------------------------------
# The detector sorts assets visually top-to-bottom, left-to-right.
# These row bands correspond to your current gothic tilesheet layout:
#
#   row 0-1   floors / ground / floor overlays
#   row 2-3   vertical wall slices / corners / wall caps
#   row 4     doors / gates / small wall props / chains
#   row 5     large buildings / landmarks / lamps / obelisks
#   row 6-8   trees / rubble / crates / fences / banners / machines / sandbags
#
# This table intentionally gives *semantic purpose* to groups of assets.
# After first run, inspect the generated contact sheet / manifest and tweak
# band ranges if needed.

SEMANTIC_BANDS: List[Dict[str, Any]] = [
    # -----------------------------------------------------------------
    # FLOORS / GROUND
    # -----------------------------------------------------------------
    {
        "name": "rough_dark_ground_tiles",
        "row_min": 0,
        "row_max": 0,
        "col_min": 0,
        "col_max": 5,
        "asset_type": "tiles",
        "semantic_role": "walkable_floor_variant",
        "name_prefix": "gothic_floor_dark_earth",
        "display_prefix": "Dark Earth Floor",
        "placement_layer": "ground",
        "procgen_use": [
            "outdoor_ground",
            "ruined_compound_floor",
            "forest_intrusion",
            "dirty_transition",
        ],
        "tags": ["floor", "walkable", "earth", "roots", "dirty", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 40,
        "indoor": False,
        "outdoor": True,
    },
    {
        "name": "stone_floor_tiles",
        "row_min": 0,
        "row_max": 0,
        "col_min": 6,
        "col_max": 15,
        "asset_type": "tiles",
        "semantic_role": "walkable_floor_variant",
        "name_prefix": "gothic_floor_broken_stone",
        "display_prefix": "Broken Stone Floor",
        "placement_layer": "ground",
        "procgen_use": [
            "compound_floor",
            "courtyard_floor",
            "interior_floor",
            "road_or_plaza",
        ],
        "tags": ["floor", "walkable", "stone", "broken", "compound", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 70,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "mud_and_gravel_floor_tiles",
        "row_min": 0,
        "row_max": 0,
        "col_min": 16,
        "col_max": 99,
        "asset_type": "tiles",
        "semantic_role": "walkable_floor_variant",
        "name_prefix": "gothic_floor_mud_gravel",
        "display_prefix": "Mud Gravel Floor",
        "placement_layer": "ground",
        "procgen_use": [
            "outdoor_ground",
            "edge_decay",
            "compound_exterior",
            "damaged_route",
        ],
        "tags": ["floor", "walkable", "mud", "gravel", "damaged", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 35,
        "indoor": False,
        "outdoor": True,
    },
    {
        "name": "technical_floor_and_decal_tiles",
        "row_min": 1,
        "row_max": 1,
        "col_min": 0,
        "col_max": 99,
        "asset_type": "tiles",
        "semantic_role": "floor_overlay_or_special_floor",
        "name_prefix": "gothic_floor_detail",
        "display_prefix": "Gothic Floor Detail",
        "placement_layer": "ground_detail",
        "procgen_use": [
            "floor_detail",
            "hazard_detail",
            "industrial_gothic_insert",
            "damaged_floor",
        ],
        "tags": ["floor", "overlay", "detail", "grate", "scorch", "drain", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 20,
        "indoor": True,
        "outdoor": True,
    },

    # -----------------------------------------------------------------
    # WALLS
    # -----------------------------------------------------------------
    {
        "name": "vertical_wall_slices",
        "row_min": 2,
        "row_max": 2,
        "col_min": 0,
        "col_max": 13,
        "asset_type": "walls",
        "semantic_role": "blocking_wall_vertical_slice",
        "name_prefix": "gothic_wall_vertical_slice",
        "display_prefix": "Vertical Wall Slice",
        "placement_layer": "wall",
        "procgen_use": [
            "compound_wall",
            "interior_partition",
            "height_variation",
            "wall_body",
        ],
        "tags": ["wall", "blocking", "vertical", "slice", "compound", "gothic"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "weight": 60,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "wall_caps_and_terminals",
        "row_min": 2,
        "row_max": 2,
        "col_min": 14,
        "col_max": 99,
        "asset_type": "walls",
        "semantic_role": "wall_cap_terminal_or_buttress",
        "name_prefix": "gothic_wall_cap_terminal",
        "display_prefix": "Wall Cap Terminal",
        "placement_layer": "wall",
        "procgen_use": [
            "wall_terminal",
            "wall_height_break",
            "wall_cap",
            "corner_dressing",
        ],
        "tags": ["wall", "cap", "terminal", "buttress", "blocking", "gothic"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "weight": 35,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "wall_corners_and_connectors",
        "row_min": 3,
        "row_max": 3,
        "col_min": 0,
        "col_max": 15,
        "asset_type": "walls",
        "semantic_role": "blocking_wall_corner_or_connector",
        "name_prefix": "gothic_wall_corner_connector",
        "display_prefix": "Wall Corner Connector",
        "placement_layer": "wall",
        "procgen_use": [
            "wall_corner",
            "compound_turn",
            "interior_turn",
            "wall_connector",
        ],
        "tags": ["wall", "corner", "connector", "blocking", "compound", "gothic"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "weight": 45,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "broken_wall_segments",
        "row_min": 3,
        "row_max": 3,
        "col_min": 16,
        "col_max": 99,
        "asset_type": "walls",
        "semantic_role": "damaged_wall_or_partial_cover",
        "name_prefix": "gothic_wall_broken_segment",
        "display_prefix": "Broken Wall Segment",
        "placement_layer": "wall",
        "procgen_use": [
            "ruined_wall",
            "partial_cover",
            "compound_decay",
            "breach_edge",
        ],
        "tags": ["wall", "broken", "ruin", "cover", "compound", "gothic"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "weight": 28,
        "indoor": True,
        "outdoor": True,
    },

    # -----------------------------------------------------------------
    # DOORS / GATES
    # -----------------------------------------------------------------
    {
        "name": "major_gates_and_archways",
        "row_min": 4,
        "row_max": 4,
        "col_min": 0,
        "col_max": 7,
        "asset_type": "doors",
        "semantic_role": "compound_entrance_gate",
        "name_prefix": "gothic_gate_archway",
        "display_prefix": "Gothic Gate Archway",
        "placement_layer": "door",
        "procgen_use": [
            "main_entrance",
            "compound_gate",
            "sector_threshold",
            "poi_gate",
        ],
        "tags": ["door", "gate", "archway", "entrance", "compound", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 12,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "small_doors_and_wall_inserts",
        "row_min": 4,
        "row_max": 4,
        "col_min": 8,
        "col_max": 13,
        "asset_type": "doors",
        "semantic_role": "small_door_or_wall_insert",
        "name_prefix": "gothic_small_door_insert",
        "display_prefix": "Small Gothic Door Insert",
        "placement_layer": "door",
        "procgen_use": [
            "secondary_entrance",
            "interior_door",
            "service_gate",
            "secret_threshold",
        ],
        "tags": ["door", "small_gate", "threshold", "compound", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 18,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "bollards_chains_and_posts",
        "row_min": 4,
        "row_max": 4,
        "col_min": 14,
        "col_max": 99,
        "asset_type": "props",
        "semantic_role": "boundary_marker_or_soft_barrier",
        "name_prefix": "gothic_boundary_marker",
        "display_prefix": "Boundary Marker",
        "placement_layer": "prop",
        "procgen_use": [
            "soft_boundary",
            "path_control",
            "courtyard_detail",
            "approach_marker",
        ],
        "tags": ["prop", "chain", "post", "bollard", "boundary", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 20,
        "indoor": False,
        "outdoor": True,
    },

    # -----------------------------------------------------------------
    # LANDMARKS / STRUCTURES
    # -----------------------------------------------------------------
    {
        "name": "large_building_landmarks",
        "row_min": 5,
        "row_max": 5,
        "col_min": 0,
        "col_max": 6,
        "asset_type": "structures",
        "semantic_role": "large_compound_landmark",
        "name_prefix": "gothic_landmark_building",
        "display_prefix": "Gothic Landmark Building",
        "placement_layer": "structure",
        "procgen_use": [
            "compound_core",
            "objective_room_exterior",
            "archive_node",
            "poi_anchor",
        ],
        "tags": ["structure", "landmark", "building", "objective", "blocking", "gothic"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 3,
        "weight": 4,
        "indoor": False,
        "outdoor": True,
    },
    {
        "name": "obelisks_lamps_and_focus_nodes",
        "row_min": 5,
        "row_max": 5,
        "col_min": 7,
        "col_max": 99,
        "asset_type": "props",
        "semantic_role": "vertical_poi_or_light_source",
        "name_prefix": "gothic_vertical_poi",
        "display_prefix": "Vertical Gothic POI",
        "placement_layer": "prop",
        "procgen_use": [
            "courtyard_focus",
            "light_source",
            "ritual_marker",
            "navigation_landmark",
        ],
        "tags": ["prop", "obelisk", "lamp", "poi", "light", "gothic"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "weight": 10,
        "indoor": True,
        "outdoor": True,
    },

    # -----------------------------------------------------------------
    # ORGANIC / RUIN PROPS
    # -----------------------------------------------------------------
    {
        "name": "dead_trees_and_roots",
        "row_min": 6,
        "row_max": 6,
        "col_min": 0,
        "col_max": 3,
        "asset_type": "props",
        "semantic_role": "organic_intrusion_blocker",
        "name_prefix": "gothic_dead_tree_roots",
        "display_prefix": "Dead Tree Roots",
        "placement_layer": "prop",
        "procgen_use": [
            "forest_intrusion",
            "outdoor_blocker",
            "compound_overgrowth",
            "silhouette_breakup",
        ],
        "tags": ["prop", "tree", "roots", "organic", "blocking", "gothic"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "weight": 14,
        "indoor": False,
        "outdoor": True,
    },
    {
        "name": "rubble_piles_and_ruins",
        "row_min": 6,
        "row_max": 6,
        "col_min": 4,
        "col_max": 99,
        "asset_type": "props",
        "semantic_role": "rubble_cover_or_ruin_storytelling",
        "name_prefix": "gothic_rubble_ruin",
        "display_prefix": "Rubble Ruin",
        "placement_layer": "prop",
        "procgen_use": [
            "cover",
            "ruined_compound",
            "blocked_route",
            "environmental_storytelling",
        ],
        "tags": ["prop", "rubble", "ruin", "cover", "damage", "gothic"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "weight": 24,
        "indoor": True,
        "outdoor": True,
    },

    # -----------------------------------------------------------------
    # STORAGE / LOW COVER / BARRIERS
    # -----------------------------------------------------------------
    {
        "name": "crates_and_barrels",
        "row_min": 7,
        "row_max": 7,
        "col_min": 0,
        "col_max": 4,
        "asset_type": "props",
        "semantic_role": "loot_cover_or_storage_prop",
        "name_prefix": "gothic_storage_crates_barrels",
        "display_prefix": "Storage Crates Barrels",
        "placement_layer": "prop",
        "procgen_use": [
            "loot_area",
            "storage_room",
            "cover",
            "compound_utility",
        ],
        "tags": ["prop", "crate", "barrel", "storage", "cover", "loot"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "weight": 24,
        "indoor": True,
        "outdoor": True,
    },
    {
        "name": "sandbags_fences_chains_banners_machines",
        "row_min": 7,
        "row_max": 8,
        "col_min": 5,
        "col_max": 99,
        "asset_type": "props",
        "semantic_role": "compound_dressing_or_barrier",
        "name_prefix": "gothic_compound_dressing",
        "display_prefix": "Compound Dressing",
        "placement_layer": "prop",
        "procgen_use": [
            "compound_dressing",
            "faction_dressing",
            "barrier",
            "cover",
            "machine_poi",
        ],
        "tags": ["prop", "barrier", "banner", "machine", "chain", "sandbag", "gothic"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "weight": 18,
        "indoor": True,
        "outdoor": True,
    },
]


# Optional exact semantic overrides after visual indexing.
# These apply after row/col band classification.
# Format:
#   visual_index: { metadata overrides }
#
# visual_index is the sorted detection index, starting at 1.
# Run once, inspect manifest/contact sheet, then add overrides here for exact naming.
EXACT_OVERRIDES: Dict[int, Dict[str, Any]] = {
    # Example:
    # 97: {
    #     "asset_type": "props",
    #     "semantic_role": "animated_hanging_banner",
    #     "name_prefix": "gothic_banner_torn_black",
    #     "display_prefix": "Torn Black Banner",
    #     "placement_layer": "prop_overlay",
    #     "blocks_movement": False,
    #     "blocks_sight": False,
    #     "cover_value": 0,
    #     "tags": ["banner", "animated", "faction_dressing", "gothic"],
    #     "procgen_use": ["wall_dressing", "faction_marker", "wind_animation"],
    # }
}


# ---------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------

@dataclass
class Asset:
    visual_index: int
    row_index: int
    col_index: int
    bbox: Tuple[int, int, int, int]
    width: int
    height: int
    area: int
    asset_id: str
    display_name: str
    asset_type: str
    semantic_role: str
    placement_layer: str
    output_path: str
    metadata: Dict[str, Any]


# ---------------------------------------------------------------------
# Image detection
# ---------------------------------------------------------------------

def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip("_")


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def background_mask(img: Image.Image, alpha_threshold: int = 8) -> np.ndarray:
    arr = np.array(img, dtype=np.uint8)
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]

    transparent = alpha <= alpha_threshold

    r = rgb[:, :, 0]
    g = rgb[:, :, 1]
    b = rgb[:, :, 2]
    maxc = rgb.max(axis=2)
    minc = rgb.min(axis=2)

    # Transparent checker or white preview background.
    near_white = (r > 220) & (g > 220) & (b > 220)
    light_gray_checker = (maxc > 175) & ((maxc - minc) < 18)

    return transparent | near_white | light_gray_checker


def remove_isolated_noise(fg: np.ndarray, min_neighbors: int = 1) -> np.ndarray:
    h, w = fg.shape
    padded = np.pad(fg, 1, mode="constant", constant_values=False)
    count = np.zeros_like(fg, dtype=np.uint8)

    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            count += padded[1 + dy : 1 + dy + h, 1 + dx : 1 + dx + w]

    return fg & (count >= min_neighbors)


def connected_components(mask: np.ndarray, min_area: int) -> List[Tuple[int, int, int, int, int]]:
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    comps: List[Tuple[int, int, int, int, int]] = []

    for y in range(h):
        for x in range(w):
            if seen[y, x] or not mask[y, x]:
                continue

            q = deque([(x, y)])
            seen[y, x] = True

            x0 = x1 = x
            y0 = y1 = y
            area = 0

            while q:
                px, py = q.popleft()
                area += 1
                x0 = min(x0, px)
                x1 = max(x1, px)
                y0 = min(y0, py)
                y1 = max(y1, py)

                for ny in range(py - 1, py + 2):
                    for nx in range(px - 1, px + 2):
                        if nx < 0 or nx >= w or ny < 0 or ny >= h:
                            continue
                        if seen[ny, nx] or not mask[ny, nx]:
                            continue
                        seen[ny, nx] = True
                        q.append((nx, ny))

            if area >= min_area:
                comps.append((x0, y0, x1, y1, area))

    return comps


def sort_into_rows(
    comps: List[Tuple[int, int, int, int, int]],
    row_gap: int = 20,
) -> List[Tuple[int, int, Tuple[int, int, int, int, int]]]:
    """
    Returns:
      [(row_index, col_index, comp), ...]

    Groups by component center Y using a tolerance.
    """
    comps_sorted = sorted(comps, key=lambda c: ((c[1] + c[3]) / 2, c[0]))

    rows: List[List[Tuple[int, int, int, int, int]]] = []
    row_centers: List[float] = []

    for comp in comps_sorted:
        cy = (comp[1] + comp[3]) / 2
        placed = False

        for i, center in enumerate(row_centers):
            if abs(cy - center) <= row_gap:
                rows[i].append(comp)
                row_centers[i] = (row_centers[i] * (len(rows[i]) - 1) + cy) / len(rows[i])
                placed = True
                break

        if not placed:
            rows.append([comp])
            row_centers.append(cy)

    output: List[Tuple[int, int, Tuple[int, int, int, int, int]]] = []
    for row_idx, row in enumerate(rows):
        row_sorted = sorted(row, key=lambda c: c[0])
        for col_idx, comp in enumerate(row_sorted):
            output.append((row_idx, col_idx, comp))

    return output


def pad_bbox(
    bbox: Tuple[int, int, int, int],
    pad: int,
    image_w: int,
    image_h: int,
) -> Tuple[int, int, int, int]:
    x0, y0, x1, y1 = bbox
    return (
        max(0, x0 - pad),
        max(0, y0 - pad),
        min(image_w - 1, x1 + pad),
        min(image_h - 1, y1 + pad),
    )


def crop_asset(
    img: Image.Image,
    bg: np.ndarray,
    bbox: Tuple[int, int, int, int],
) -> Image.Image:
    x0, y0, x1, y1 = bbox
    crop = img.crop((x0, y0, x1 + 1, y1 + 1)).convert("RGBA")
    arr = np.array(crop, dtype=np.uint8)
    local_bg = bg[y0 : y1 + 1, x0 : x1 + 1]
    arr[local_bg, 3] = 0
    return Image.fromarray(arr, mode="RGBA")


# ---------------------------------------------------------------------
# Semantic metadata
# ---------------------------------------------------------------------

def find_band(row_idx: int, col_idx: int) -> Dict[str, Any]:
    for band in SEMANTIC_BANDS:
        if (
            band["row_min"] <= row_idx <= band["row_max"]
            and band["col_min"] <= col_idx <= band["col_max"]
        ):
            return dict(band)

    return {
        "name": "uncategorized",
        "asset_type": "props",
        "semantic_role": "uncategorized_environment_asset",
        "name_prefix": "gothic_uncategorized_asset",
        "display_prefix": "Uncategorized Gothic Asset",
        "placement_layer": "prop",
        "procgen_use": ["manual_review"],
        "tags": ["manual_review", "gothic"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "weight": 1,
        "indoor": True,
        "outdoor": True,
    }


def apply_exact_override(visual_index: int, band: Dict[str, Any]) -> Dict[str, Any]:
    if visual_index not in EXACT_OVERRIDES:
        return band

    merged = dict(band)
    merged.update(EXACT_OVERRIDES[visual_index])
    return merged


def subtype_dir(asset_type: str, semantic_role: str) -> str:
    if asset_type == "tiles":
        if "floor" in semantic_role:
            return "floors"
        return "overlays"
    if asset_type == "walls":
        return semantic_role
    if asset_type == "doors":
        return semantic_role
    if asset_type == "structures":
        return semantic_role
    return semantic_role


def game32_metadata(
    *,
    asset_id: str,
    display_name: str,
    source_path: Path,
    output_path: Path,
    bbox: Tuple[int, int, int, int],
    row_idx: int,
    col_idx: int,
    visual_index: int,
    width: int,
    height: int,
    tile_size: int,
    band: Dict[str, Any],
) -> Dict[str, Any]:
    footprint_w = max(1, math.ceil(width / tile_size))
    footprint_h = max(1, math.ceil(height / tile_size))

    is_ground = band["placement_layer"] in {"ground", "ground_detail"}
    pivot = {"x": 0, "y": 0} if is_ground else {"x": width // 2, "y": height - 1}

    return {
        "schema": "game32.asset.v2",
        "id": asset_id,
        "display_name": display_name,
        "source": {
            "sheet": str(source_path),
            "visual_index": visual_index,
            "row_index": row_idx,
            "col_index": col_idx,
            "bbox_px": {
                "x": bbox[0],
                "y": bbox[1],
                "w": width,
                "h": height,
            },
        },
        "file": {
            "path": str(output_path),
            "pixel_size": {"w": width, "h": height},
        },
        "classification": {
            "asset_type": band["asset_type"],
            "semantic_role": band["semantic_role"],
            "placement_layer": band["placement_layer"],
            "tags": sorted(set(band["tags"])),
        },
        "placement": {
            "tile_size": tile_size,
            "footprint_tiles": {"w": footprint_w, "h": footprint_h},
            "origin_mode": "top_left" if is_ground else "bottom_center",
            "pivot_px": pivot,
            "snap": "tile" if band["asset_type"] in {"tiles", "walls", "doors"} else "tile_or_free",
            "allow_mirror_x": band["asset_type"] in {"props", "walls"},
            "allow_rotation": False,
            "y_sort": not is_ground,
        },
        "collision": {
            "blocks_movement": bool(band["blocks_movement"]),
            "blocks_sight": bool(band["blocks_sight"]),
            "cover_value": int(band["cover_value"]),
            "collision_shape": "footprint" if band["blocks_movement"] else "none",
        },
        "procgen": {
            "uses": list(band["procgen_use"]),
            "weight": int(band["weight"]),
            "can_spawn_indoor": bool(band["indoor"]),
            "can_spawn_outdoor": bool(band["outdoor"]),
            "supports_gothic_compound": True,
            "review_status": "semantic_band_assigned",
        },
    }


# ---------------------------------------------------------------------
# Banner animation
# ---------------------------------------------------------------------

def looks_like_banner(asset: Asset) -> bool:
    tags = set(asset.metadata["classification"]["tags"])
    role = asset.semantic_role
    return "banner" in tags or "banner" in role


def choose_banner_candidate(assets: List[Asset]) -> Optional[Asset]:
    candidates = [a for a in assets if looks_like_banner(a)]

    # If semantic bands did not isolate it, use a shape fallback.
    if not candidates:
        candidates = [
            a for a in assets
            if a.height >= 64 and a.width <= 64 and a.metadata["classification"]["asset_type"] == "props"
        ]

    if not candidates:
        return None

    candidates.sort(key=lambda a: (a.height / max(1, a.width), a.height), reverse=True)
    return candidates[0]


def make_banner_flap_sheet(
    banner_img: Image.Image,
    out_path: Path,
    frames: int = 10,
    amplitude: float = 4.0,
) -> Dict[str, Any]:
    src_img = banner_img.convert("RGBA")
    src = np.array(src_img, dtype=np.uint8)
    w, h = src_img.size

    frame_w = w + int(amplitude * 4) + 6
    frame_h = h
    sheet = Image.new("RGBA", (frame_w * frames, frame_h), (0, 0, 0, 0))

    for frame_idx in range(frames):
        phase = frame_idx / frames * math.tau
        frame = np.zeros((frame_h, frame_w, 4), dtype=np.uint8)

        for y in range(h):
            t = y / max(1, h - 1)

            # Pin top cloth more strongly; bottom flaps harder.
            lower_weight = t ** 1.45
            wave_a = math.sin(phase + t * math.tau * 1.1)
            wave_b = math.sin(phase * 1.7 + t * math.tau * 2.0) * 0.35
            dx = int(round((wave_a + wave_b) * amplitude * lower_weight))

            # Slight vertical lift at lower torn edge.
            dy = int(round(math.sin(phase + t * math.tau) * 1.0 * lower_weight))

            base_x = int(amplitude * 2) + 3 + dx
            target_y = min(max(0, y + dy), frame_h - 1)

            for x in range(w):
                px = src[y, x]
                if px[3] == 0:
                    continue
                tx = base_x + x
                if 0 <= tx < frame_w:
                    frame[target_y, tx] = px

        sheet.paste(Image.fromarray(frame, mode="RGBA"), (frame_idx * frame_w, 0))

    ensure_dir(out_path.parent)
    sheet.save(out_path)

    return {
        "schema": "game32.animation.v1",
        "id": "gothic_banner_flap_10f",
        "display_name": "Gothic Banner Flap 10 Frame",
        "path": str(out_path),
        "layout": "horizontal_strip",
        "frames": frames,
        "frame_size_px": {"w": frame_w, "h": frame_h},
        "fps": 8,
        "loop": True,
        "semantic_role": "ambient_banner_flap",
        "procgen": {
            "uses": ["wall_dressing", "faction_marker", "wind_animation", "compound_dressing"],
            "tags": ["animated", "banner", "gothic", "ambient", "faction_dressing"],
            "weight": 8,
        },
    }


# ---------------------------------------------------------------------
# Optional contact sheet
# ---------------------------------------------------------------------

def write_contact_sheet(assets: List[Asset], out_path: Path, thumb_size: int = 96) -> None:
    """
    Creates a review sheet with visual index numbers.
    This is for YOU, not runtime.
    """
    try:
        from PIL import ImageDraw, ImageFont
    except Exception:
        return

    cols = 8
    rows = math.ceil(len(assets) / cols)
    cell_w = thumb_size
    cell_h = thumb_size + 24

    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (20, 20, 20, 255))
    draw = ImageDraw.Draw(sheet)

    for i, asset in enumerate(assets):
        img = Image.open(asset.output_path).convert("RGBA")
        img.thumbnail((thumb_size - 8, thumb_size - 28), Image.Resampling.LANCZOS)

        x = (i % cols) * cell_w
        y = (i // cols) * cell_h

        px = x + (cell_w - img.width) // 2
        py = y + 4
        sheet.paste(img, (px, py), img)

        label = f"{asset.visual_index}: r{asset.row_index} c{asset.col_index}"
        draw.text((x + 4, y + thumb_size), label, fill=(255, 255, 255, 255))

    ensure_dir(out_path.parent)
    sheet.save(out_path)


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Path to ./gothic_tilesheet.png")
    parser.add_argument("--out", type=Path, default=Path("./custodian/content"))
    parser.add_argument("--tile-size", type=int, default=32)
    parser.add_argument("--min-area", type=int, default=24)
    parser.add_argument("--pad", type=int, default=1)
    parser.add_argument("--row-gap", type=int, default=22)
    parser.add_argument("--make-banner-animation", action="store_true")
    parser.add_argument("--write-contact-sheet", action="store_true", default=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    source_path = args.source
    content_root = args.out
    tile_size = args.tile_size

    if not source_path.exists():
        raise FileNotFoundError(f"Missing source sheet: {source_path}")

    img = load_rgba(source_path)
    image_w, image_h = img.size

    bg = background_mask(img)
    fg = remove_isolated_noise(~bg, min_neighbors=1)
    comps = connected_components(fg, min_area=args.min_area)
    indexed = sort_into_rows(comps, row_gap=args.row_gap)

    assets: List[Asset] = []
    semantic_counters: Dict[str, int] = defaultdict(int)

    print(f"[semantic-slice] source: {source_path}")
    print(f"[semantic-slice] image size: {image_w}x{image_h}")
    print(f"[semantic-slice] detected assets: {len(indexed)}")

    for visual_index, (row_idx, col_idx, comp) in enumerate(indexed, start=1):
        x0, y0, x1, y1, area = comp
        bbox = pad_bbox((x0, y0, x1, y1), args.pad, image_w, image_h)
        x0, y0, x1, y1 = bbox

        width = x1 - x0 + 1
        height = y1 - y0 + 1

        band = find_band(row_idx, col_idx)
        band = apply_exact_override(visual_index, band)

        semantic_key = f"{band['asset_type']}:{band['semantic_role']}:{band['name_prefix']}"
        semantic_counters[semantic_key] += 1
        seq = semantic_counters[semantic_key]

        asset_id = slugify(f"{band['name_prefix']}_{seq:02d}")
        display_name = f"{band['display_prefix']} {seq:02d}"

        role_dir = slugify(subtype_dir(band["asset_type"], band["semantic_role"]))
        out_dir = content_root / band["asset_type"] / "gothic" / role_dir
        out_path = out_dir / f"{asset_id}.png"

        meta = game32_metadata(
            asset_id=asset_id,
            display_name=display_name,
            source_path=source_path,
            output_path=out_path,
            bbox=bbox,
            row_idx=row_idx,
            col_idx=col_idx,
            visual_index=visual_index,
            width=width,
            height=height,
            tile_size=tile_size,
            band=band,
        )

        asset = Asset(
            visual_index=visual_index,
            row_index=row_idx,
            col_index=col_idx,
            bbox=bbox,
            width=width,
            height=height,
            area=area,
            asset_id=asset_id,
            display_name=display_name,
            asset_type=band["asset_type"],
            semantic_role=band["semantic_role"],
            placement_layer=band["placement_layer"],
            output_path=str(out_path),
            metadata=meta,
        )
        assets.append(asset)

        if not args.dry_run:
            ensure_dir(out_dir)
            crop = crop_asset(img, bg, bbox)
            crop.save(out_path)

            sidecar = out_path.with_suffix(".game32.json")
            sidecar.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    manifest = {
        "schema": "game32.semantic_tilesheet_manifest.v2",
        "source": str(source_path),
        "content_root": str(content_root),
        "tile_size": tile_size,
        "asset_count": len(assets),
        "art_direction": {
            "style": "gothic industrial ruin",
            "generator_target": "complex gothic compounds with vertical wall slices, varied floors, gates, cover, landmarks, and environmental storytelling",
            "classification_method": "connected_component_crop_plus_semantic_row_col_catalog",
            "manual_review_expected": True,
        },
        "assets": [a.metadata for a in assets],
    }

    manifest_path = content_root / "tiles" / "gothic" / "gothic_tilesheet_manifest.game32.json"

    if not args.dry_run:
        ensure_dir(manifest_path.parent)
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    if args.make_banner_animation:
        banner = choose_banner_candidate(assets)
        if banner:
            banner_img = Image.open(banner.output_path).convert("RGBA")
            anim_path = content_root / "animations" / "gothic" / "banner_flap_10f.png"
            anim_meta = make_banner_flap_sheet(banner_img, anim_path, frames=10)

            anim_meta["source_asset"] = {
                "id": banner.asset_id,
                "path": banner.output_path,
                "visual_index": banner.visual_index,
            }

            if not args.dry_run:
                anim_path.with_suffix(".game32.json").write_text(
                    json.dumps(anim_meta, indent=2),
                    encoding="utf-8",
                )

            print(f"[banner] selected asset #{banner.visual_index}: {banner.asset_id}")
            print(f"[banner] wrote: {anim_path}")
        else:
            print("[banner] no banner candidate found")

    if args.write_contact_sheet and not args.dry_run:
        contact_path = content_root / "tiles" / "gothic" / "_review_gothic_contact_sheet.png"
        write_contact_sheet(assets, contact_path)
        print(f"[review] contact sheet: {contact_path}")

    by_type: Dict[str, int] = defaultdict(int)
    by_role: Dict[str, int] = defaultdict(int)

    for a in assets:
        by_type[a.asset_type] += 1
        by_role[f"{a.asset_type}/{a.semantic_role}"] += 1

    print("\n[summary] by asset type")
    for k in sorted(by_type):
        print(f"  {k}: {by_type[k]}")

    print("\n[summary] by semantic role")
    for k in sorted(by_role):
        print(f"  {k}: {by_role[k]}")

    print(f"\n[manifest] {manifest_path}")
    print("[done] semantic extraction complete")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
