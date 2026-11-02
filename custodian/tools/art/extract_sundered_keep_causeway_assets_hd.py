#!/usr/bin/env python3
"""
extract_sundered_keep_causeway_assets_hd.py

Extracts one representative instance of each useful tile/prop asset from the
Sundered Keep causeway entrance reference image.

Designed for:
  ~/Projects/CUSTODIAN/custodian/content/tiles/sundered_keep/causeway_entrance/

The source image is treated as a 50 x 37 logical reference grid.
Each logical source cell is normalized to a 32px runtime tile.

Outputs:
  - individual PNG assets in logical subdirectories
  - manifest JSON with source crop + runtime size metadata
  - reconstruction blueprint JSON
  - preview atlas PNG

Usage:
  python extract_sundered_keep_causeway_assets.py \
    --source /path/to/causeway_reference.png \
    --out ~/Projects/CUSTODIAN/custodian/content/tiles/sundered_keep/causeway_entrance

For your uploaded image in this chat:
  python extract_sundered_keep_causeway_assets.py \
    --source /mnt/data/bd7cff92-2e6b-4155-861d-0ec30a2abbda.png \
    --out ~/Projects/CUSTODIAN/custodian/content/tiles/sundered_keep/causeway_entrance
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


RUNTIME_TILE = 32

# The generated reference image is 1448 x 1086.
# Its visible grid is approximately 50 columns by 37 rows.
SOURCE_GRID_COLS = 50
SOURCE_GRID_ROWS = 37


@dataclass(frozen=True)
class AssetDef:
    name: str
    category: str
    source_cells: tuple[float, float, float, float]  # col, row, width, height
    target_size: tuple[int, int]
    kind: str
    notes: str = ""
    collision: str = "none"
    z_hint: str = "ground"


# ---------------------------------------------------------------------
# Asset extraction map
# ---------------------------------------------------------------------
# Coordinates are in logical source-grid cells, not pixels.
#
# A 1x1 crop becomes 32x32.
# A 2x1 crop becomes 64x32.
# A 3x3 crop becomes 96x96.
#
# These are intentionally representative instances, not every repeated
# occurrence in the full image.
# ---------------------------------------------------------------------

ASSETS: list[AssetDef] = [
    # ------------------------------------------------------------
    # Ocean / water
    # ------------------------------------------------------------
    AssetDef(
        "ocean_dark_water_01",
        "water",
        (3, 24, 1, 1),
        (32, 32),
        "tile",
        "Base dark sea tile.",
    ),
    AssetDef(
        "ocean_dark_water_02",
        "water",
        (42, 27, 1, 1),
        (32, 32),
        "tile",
        "Alternate dark sea tile with slightly different current texture.",
    ),
    AssetDef(
        "ocean_current_streak_01",
        "water",
        (34, 25, 2, 1),
        (64, 32),
        "decal_tile",
        "Long pale current streak over dark water.",
    ),
    AssetDef(
        "ocean_foam_open_01",
        "water",
        (6, 15, 2, 1),
        (64, 32),
        "decal_tile",
        "Foam streak sitting in open water.",
    ),
    AssetDef(
        "ocean_foam_edge_left_01",
        "water_edges",
        (13, 15, 2, 2),
        (64, 64),
        "edge_tile",
        "Foam where water meets the left cliff/causeway rocks.",
    ),
    AssetDef(
        "ocean_foam_edge_right_01",
        "water_edges",
        (34, 15, 2, 2),
        (64, 64),
        "edge_tile",
        "Foam where water meets the right cliff/causeway rocks.",
    ),
    AssetDef(
        "ocean_foam_edge_bottom_left_01",
        "water_edges",
        (15, 30, 2, 2),
        (64, 64),
        "edge_tile",
        "Lower causeway edge foam, useful near bridge supports.",
    ),
    AssetDef(
        "ocean_foam_edge_bottom_right_01",
        "water_edges",
        (32, 30, 2, 2),
        (64, 64),
        "edge_tile",
        "Lower right causeway edge foam.",
    ),

    # ------------------------------------------------------------
    # Cliff / rocks
    # ------------------------------------------------------------
    AssetDef(
        "cliff_face_dark_01",
        "cliffs",
        (10, 10, 1, 1),
        (32, 32),
        "tile",
        "Dark vertical cliff face / rock wall tile.",
        collision="solid",
    ),
    AssetDef(
        "cliff_face_dark_02",
        "cliffs",
        (13, 12, 1, 1),
        (32, 32),
        "tile",
        "Alternate dark cliff face.",
        collision="solid",
    ),
    AssetDef(
        "cliff_face_wet_01",
        "cliffs",
        (15, 20, 1, 1),
        (32, 32),
        "tile",
        "Wet cliff face near causeway edge.",
        collision="solid",
    ),
    AssetDef(
        "cliff_rock_cluster_01",
        "cliffs",
        (12, 17, 2, 2),
        (64, 64),
        "macro_tile",
        "Jagged rock cluster for cliff side variation.",
        collision="solid",
    ),
    AssetDef(
        "cliff_rock_cluster_02",
        "cliffs",
        (34, 12, 2, 2),
        (64, 64),
        "macro_tile",
        "Right-side jagged rock cluster.",
        collision="solid",
    ),
    AssetDef(
        "cliff_top_mossy_edge_01",
        "cliff_edges",
        (1, 8, 2, 1),
        (64, 32),
        "edge_tile",
        "Mossy top edge where keep wall meets lower rock face.",
        collision="solid",
    ),
    AssetDef(
        "cliff_top_mossy_edge_02",
        "cliff_edges",
        (39, 8, 2, 1),
        (64, 32),
        "edge_tile",
        "Alternate mossy top cliff/wall transition.",
        collision="solid",
    ),

    # ------------------------------------------------------------
    # Causeway floor
    # ------------------------------------------------------------
    AssetDef(
        "causeway_floor_center_01",
        "causeway_floor",
        (24, 18, 1, 1),
        (32, 32),
        "tile",
        "Main large stone floor tile.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_center_02",
        "causeway_floor",
        (22, 28, 1, 1),
        (32, 32),
        "tile",
        "Alternate floor tile.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_center_03",
        "causeway_floor",
        (26, 30, 1, 1),
        (32, 32),
        "tile",
        "Alternate lower bridge floor.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_cracked_01",
        "causeway_floor",
        (24, 20, 1, 1),
        (32, 32),
        "tile",
        "Cracked walkway stone.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_mossy_01",
        "causeway_floor",
        (25, 16, 1, 1),
        (32, 32),
        "tile",
        "Moss-stained walkway stone.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_puddle_01",
        "causeway_floor",
        (25, 11, 2, 1),
        (64, 32),
        "decal_tile",
        "Dark puddle / wet stone decal.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_puddle_02",
        "causeway_floor",
        (24, 33, 1, 1),
        (32, 32),
        "decal_tile",
        "Small puddle / dark wet patch.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_grate_01",
        "causeway_floor",
        (17, 10, 1, 1),
        (32, 32),
        "decal_tile",
        "Iron floor grate.",
        collision="walkable",
    ),
    AssetDef(
        "causeway_floor_grate_02",
        "causeway_floor",
        (29, 14, 1, 1),
        (32, 32),
        "decal_tile",
        "Alternate iron floor grate.",
        collision="walkable",
    ),

    # ------------------------------------------------------------
    # Causeway border / parapet / curb
    # ------------------------------------------------------------
    AssetDef(
        "causeway_edge_left_vertical_01",
        "causeway_edges",
        (19, 24, 1, 2),
        (32, 64),
        "edge_tile",
        "Left vertical curb/parapet edge.",
        collision="solid",
    ),
    AssetDef(
        "causeway_edge_right_vertical_01",
        "causeway_edges",
        (30, 24, 1, 2),
        (32, 64),
        "edge_tile",
        "Right vertical curb/parapet edge.",
        collision="solid",
    ),
    AssetDef(
        "causeway_edge_top_horizontal_01",
        "causeway_edges",
        (21, 9, 3, 1),
        (96, 32),
        "edge_tile",
        "Horizontal threshold curb near gate landing.",
        collision="solid",
    ),
    AssetDef(
        "causeway_edge_bottom_horizontal_01",
        "causeway_edges",
        (20, 35, 3, 1),
        (96, 32),
        "edge_tile",
        "Lower bridge curb cap.",
        collision="solid",
    ),
    AssetDef(
        "causeway_parapet_post_01",
        "causeway_edges",
        (19, 22, 1, 1),
        (32, 32),
        "corner_or_post",
        "Square stone parapet post.",
        collision="solid",
    ),
    AssetDef(
        "causeway_parapet_post_02",
        "causeway_edges",
        (30, 22, 1, 1),
        (32, 32),
        "corner_or_post",
        "Alternate square parapet post.",
        collision="solid",
    ),
    AssetDef(
        "causeway_corner_block_left_01",
        "causeway_edges",
        (17, 19, 2, 2),
        (64, 64),
        "corner_tile",
        "Angled left-side causeway corner/buttress block.",
        collision="solid",
    ),
    AssetDef(
        "causeway_corner_block_right_01",
        "causeway_edges",
        (31, 19, 2, 2),
        (64, 64),
        "corner_tile",
        "Angled right-side causeway corner/buttress block.",
        collision="solid",
    ),
    AssetDef(
        "causeway_diagonal_wall_left_01",
        "causeway_edges",
        (17, 12, 2, 2),
        (64, 64),
        "diagonal_edge",
        "Diagonal wall edge for upper-left bend.",
        collision="solid",
    ),
    AssetDef(
        "causeway_diagonal_wall_right_01",
        "causeway_edges",
        (31, 12, 2, 2),
        (64, 64),
        "diagonal_edge",
        "Diagonal wall edge for upper-right bend.",
        collision="solid",
    ),

    # ------------------------------------------------------------
    # Gatehouse / keep wall modules
    # ------------------------------------------------------------
    AssetDef(
        "keep_wall_face_01",
        "keep_walls",
        (1, 5, 2, 3),
        (64, 96),
        "wall_module",
        "Dark keep wall face, 2x3 runtime tiles.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "keep_wall_face_02",
        "keep_walls",
        (36, 5, 2, 3),
        (64, 96),
        "wall_module",
        "Alternate keep wall face.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "keep_wall_top_crenelation_01",
        "keep_walls",
        (1, 2, 2, 1),
        (64, 32),
        "wall_cap",
        "Crenelated top wall cap.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "keep_wall_top_crenelation_02",
        "keep_walls",
        (41, 2, 2, 1),
        (64, 32),
        "wall_cap",
        "Alternate crenelated wall cap.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "keep_buttress_vertical_01",
        "keep_walls",
        (15, 4, 2, 5),
        (64, 160),
        "buttress",
        "Tall gatehouse buttress / vertical support.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "keep_buttress_vertical_02",
        "keep_walls",
        (33, 4, 2, 5),
        (64, 160),
        "buttress",
        "Right tall gatehouse buttress.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "gatehouse_main_portcullis_01",
        "gatehouse",
        (22, 3, 6, 5),
        (192, 160),
        "gate",
        "Main arched gatehouse with portcullis.",
        collision="door_or_gate",
        z_hint="wall",
    ),
    AssetDef(
        "gatehouse_steps_front_01",
        "gatehouse",
        (21, 9, 7, 1),
        (224, 32),
        "stairs",
        "Wide front gate steps / threshold.",
        collision="walkable",
    ),
    AssetDef(
        "gothic_side_door_left_01",
        "gatehouse",
        (16, 5, 2, 3),
        (64, 96),
        "door",
        "Left arched side door.",
        collision="door_or_wall",
        z_hint="wall",
    ),
    AssetDef(
        "gothic_side_door_right_01",
        "gatehouse",
        (29, 5, 2, 3),
        (64, 96),
        "door",
        "Right arched side door.",
        collision="door_or_wall",
        z_hint="wall",
    ),
    AssetDef(
        "gatehouse_roof_peak_01",
        "gatehouse",
        (22, 0, 6, 3),
        (192, 96),
        "roof_or_upper_wall",
        "Upper triangular gatehouse roof/stone peak.",
        collision="solid",
        z_hint="roof",
    ),

    # ------------------------------------------------------------
    # Bastions / side platforms
    # ------------------------------------------------------------
    AssetDef(
        "side_bastion_left_01",
        "bastions",
        (16, 19, 5, 5),
        (160, 160),
        "macro_structure",
        "Left side defense platform / bastion.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "side_bastion_right_01",
        "bastions",
        (29, 19, 5, 5),
        (160, 160),
        "macro_structure",
        "Right side defense platform / bastion.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "lower_guard_post_left_01",
        "bastions",
        (17, 30, 3, 4),
        (96, 128),
        "macro_structure",
        "Lower left guard post / bridge support.",
        collision="solid",
        z_hint="wall",
    ),
    AssetDef(
        "lower_guard_post_right_01",
        "bastions",
        (30, 30, 3, 4),
        (96, 128),
        "macro_structure",
        "Lower right guard post / bridge support.",
        collision="solid",
        z_hint="wall",
    ),

    # ------------------------------------------------------------
    # Props / decals
    # ------------------------------------------------------------
    AssetDef(
        "brazier_lit_01",
        "props",
        (21, 22, 1, 1),
        (32, 32),
        "prop",
        "Small lit brazier / fire bowl.",
        collision="soft_block",
        z_hint="prop",
    ),
    AssetDef(
        "brazier_lit_02",
        "props",
        (28, 22, 1, 1),
        (32, 32),
        "prop",
        "Alternate lit brazier.",
        collision="soft_block",
        z_hint="prop",
    ),
    AssetDef(
        "gate_sconce_left_01",
        "props",
        (21, 6, 1, 1),
        (32, 32),
        "prop",
        "Gate-side flame sconce.",
        collision="none",
        z_hint="prop",
    ),
    AssetDef(
        "gate_sconce_right_01",
        "props",
        (28, 6, 1, 1),
        (32, 32),
        "prop",
        "Right gate-side flame sconce.",
        collision="none",
        z_hint="prop",
    ),
    AssetDef(
        "banner_red_vertical_01",
        "props",
        (18, 5, 1, 3),
        (32, 96),
        "hanging_banner",
        "Long red vertical banner.",
        collision="none",
        z_hint="wall_decal",
    ),
    AssetDef(
        "banner_red_vertical_02",
        "props",
        (32, 5, 1, 3),
        (32, 96),
        "hanging_banner",
        "Alternate long red vertical banner.",
        collision="none",
        z_hint="wall_decal",
    ),
    AssetDef(
        "banner_red_small_01",
        "props",
        (18, 21, 1, 2),
        (32, 64),
        "hanging_banner",
        "Small red banner in side platform.",
        collision="none",
        z_hint="wall_decal",
    ),
    AssetDef(
        "shield_wall_crest_01",
        "props",
        (44, 4, 1, 1),
        (32, 32),
        "wall_decal",
        "Wall-mounted shield crest.",
        collision="none",
        z_hint="wall_decal",
    ),
    AssetDef(
        "chain_or_black_post_01",
        "props",
        (20, 7, 1, 3),
        (32, 96),
        "vertical_prop",
        "Dark chain/post near gate approach.",
        collision="soft_block",
        z_hint="prop",
    ),
]


# ---------------------------------------------------------------------
# Rebuild blueprint
# ---------------------------------------------------------------------
# This is intentionally abstract. It gives your generator/editor enough
# information to stamp the extracted assets back into a similar layout.
# ---------------------------------------------------------------------

RECONSTRUCTION_BLUEPRINT: dict[str, Any] = {
    "name": "sundered_keep_causeway_entrance_reference_rebuild",
    "runtime_tile_px": 32,
    "suggested_map_size_tiles": [50, 37],
    "coordinate_system": "tile_xy_top_left",
    "layers": [
        {
            "name": "water_base",
            "z_index": 0,
            "ops": [
                {
                    "op": "fill_rect",
                    "asset": "ocean_dark_water_01",
                    "rect": [0, 10, 50, 27],
                },
                {
                    "op": "scatter",
                    "assets": [
                        "ocean_dark_water_01",
                        "ocean_dark_water_02",
                        "ocean_current_streak_01",
                    ],
                    "rect": [0, 10, 50, 27],
                    "density": 0.12,
                },
            ],
        },
        {
            "name": "cliffs_and_foam",
            "z_index": 5,
            "ops": [
                {
                    "op": "stamp_rect",
                    "asset": "cliff_face_dark_01",
                    "rect": [10, 9, 7, 28],
                },
                {
                    "op": "stamp_rect",
                    "asset": "cliff_face_dark_02",
                    "rect": [33, 9, 7, 28],
                },
                {
                    "op": "stamp",
                    "asset": "cliff_rock_cluster_01",
                    "xy": [12, 16],
                },
                {
                    "op": "stamp",
                    "asset": "cliff_rock_cluster_02",
                    "xy": [34, 15],
                },
                {
                    "op": "stamp",
                    "asset": "ocean_foam_edge_left_01",
                    "xy": [13, 15],
                },
                {
                    "op": "stamp",
                    "asset": "ocean_foam_edge_right_01",
                    "xy": [34, 15],
                },
                {
                    "op": "stamp",
                    "asset": "ocean_foam_edge_bottom_left_01",
                    "xy": [15, 30],
                },
                {
                    "op": "stamp",
                    "asset": "ocean_foam_edge_bottom_right_01",
                    "xy": [32, 30],
                },
            ],
        },
        {
            "name": "causeway_floor",
            "z_index": 10,
            "ops": [
                {
                    "op": "fill_rect",
                    "asset": "causeway_floor_center_01",
                    "rect": [20, 10, 10, 27],
                },
                {
                    "op": "scatter",
                    "assets": [
                        "causeway_floor_center_02",
                        "causeway_floor_center_03",
                        "causeway_floor_cracked_01",
                        "causeway_floor_mossy_01",
                        "causeway_floor_puddle_02",
                    ],
                    "rect": [20, 10, 10, 27],
                    "density": 0.28,
                },
                {
                    "op": "stamp",
                    "asset": "causeway_floor_puddle_01",
                    "xy": [25, 11],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_floor_grate_01",
                    "xy": [17, 10],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_floor_grate_02",
                    "xy": [29, 14],
                },
            ],
        },
        {
            "name": "causeway_edges",
            "z_index": 20,
            "ops": [
                {
                    "op": "stamp_column",
                    "asset": "causeway_edge_left_vertical_01",
                    "xy": [19, 12],
                    "count": 12,
                    "step": [0, 2],
                },
                {
                    "op": "stamp_column",
                    "asset": "causeway_edge_right_vertical_01",
                    "xy": [30, 12],
                    "count": 12,
                    "step": [0, 2],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_diagonal_wall_left_01",
                    "xy": [17, 12],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_diagonal_wall_right_01",
                    "xy": [31, 12],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_corner_block_left_01",
                    "xy": [17, 19],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_corner_block_right_01",
                    "xy": [31, 19],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_parapet_post_01",
                    "xy": [19, 22],
                },
                {
                    "op": "stamp",
                    "asset": "causeway_parapet_post_02",
                    "xy": [30, 22],
                },
            ],
        },
        {
            "name": "gatehouse_and_walls",
            "z_index": 40,
            "ops": [
                {
                    "op": "stamp",
                    "asset": "gatehouse_main_portcullis_01",
                    "xy": [22, 3],
                },
                {
                    "op": "stamp",
                    "asset": "gatehouse_roof_peak_01",
                    "xy": [22, 0],
                },
                {
                    "op": "stamp",
                    "asset": "gatehouse_steps_front_01",
                    "xy": [21, 9],
                },
                {
                    "op": "stamp",
                    "asset": "gothic_side_door_left_01",
                    "xy": [16, 5],
                },
                {
                    "op": "stamp",
                    "asset": "gothic_side_door_right_01",
                    "xy": [29, 5],
                },
                {
                    "op": "stamp",
                    "asset": "keep_buttress_vertical_01",
                    "xy": [15, 4],
                },
                {
                    "op": "stamp",
                    "asset": "keep_buttress_vertical_02",
                    "xy": [33, 4],
                },
                {
                    "op": "stamp_rect",
                    "asset": "keep_wall_face_01",
                    "rect": [0, 4, 15, 6],
                },
                {
                    "op": "stamp_rect",
                    "asset": "keep_wall_face_02",
                    "rect": [35, 4, 15, 6],
                },
            ],
        },
        {
            "name": "bastions",
            "z_index": 50,
            "ops": [
                {
                    "op": "stamp",
                    "asset": "side_bastion_left_01",
                    "xy": [16, 19],
                },
                {
                    "op": "stamp",
                    "asset": "side_bastion_right_01",
                    "xy": [29, 19],
                },
                {
                    "op": "stamp",
                    "asset": "lower_guard_post_left_01",
                    "xy": [17, 30],
                },
                {
                    "op": "stamp",
                    "asset": "lower_guard_post_right_01",
                    "xy": [30, 30],
                },
            ],
        },
        {
            "name": "props",
            "z_index": 70,
            "ops": [
                {
                    "op": "stamp",
                    "asset": "brazier_lit_01",
                    "xy": [21, 22],
                },
                {
                    "op": "stamp",
                    "asset": "brazier_lit_02",
                    "xy": [28, 22],
                },
                {
                    "op": "stamp",
                    "asset": "gate_sconce_left_01",
                    "xy": [21, 6],
                },
                {
                    "op": "stamp",
                    "asset": "gate_sconce_right_01",
                    "xy": [28, 6],
                },
                {
                    "op": "stamp",
                    "asset": "banner_red_vertical_01",
                    "xy": [18, 5],
                },
                {
                    "op": "stamp",
                    "asset": "banner_red_vertical_02",
                    "xy": [32, 5],
                },
                {
                    "op": "stamp",
                    "asset": "banner_red_small_01",
                    "xy": [18, 21],
                },
                {
                    "op": "stamp",
                    "asset": "shield_wall_crest_01",
                    "xy": [44, 4],
                },
            ],
        },
    ],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract Sundered Keep causeway entrance assets from a reference image."
    )

    parser.add_argument(
        "--source",
        required=True,
        type=Path,
        help="Source causeway reference image.",
    )

    parser.add_argument(
        "--out",
        required=True,
        type=Path,
        help="Output directory for extracted assets.",
    )

    parser.add_argument(
        "--cols",
        type=int,
        default=SOURCE_GRID_COLS,
        help=f"Logical source grid columns. Default: {SOURCE_GRID_COLS}",
    )

    parser.add_argument(
        "--rows",
        type=int,
        default=SOURCE_GRID_ROWS,
        help=f"Logical source grid rows. Default: {SOURCE_GRID_ROWS}",
    )

    parser.add_argument(
        "--tile",
        type=int,
        default=RUNTIME_TILE,
        help=f"Runtime tile size. Default: {RUNTIME_TILE}",
    )

    parser.add_argument(
        "--no-degrid",
        action="store_true",
        help="Do not attempt to remove the visible grid overlay from the source image.",
    )

    parser.add_argument(
        "--grid-thickness",
        type=int,
        default=1,
        help="Approximate source grid-line thickness in pixels for degrid pass.",
    )

    parser.add_argument(
        "--resample",
        choices=["nearest", "box", "bilinear", "bicubic", "lanczos"],
        default="lanczos",
        help="Resize filter. Use lanczos for this generated mockup, nearest for true pixel art.",
    )

    parser.add_argument(
        "--write-debug-grid",
        action="store_true",
        help="Write a numbered source-grid debug image.",
    )

    return parser.parse_args()


def get_resample_filter(name: str) -> Image.Resampling:
    lookup = {
        "nearest": Image.Resampling.NEAREST,
        "box": Image.Resampling.BOX,
        "bilinear": Image.Resampling.BILINEAR,
        "bicubic": Image.Resampling.BICUBIC,
        "lanczos": Image.Resampling.LANCZOS,
    }
    return lookup[name]


def ensure_rgba(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        return img.convert("RGBA")
    return img


def degrid_image(
    img: Image.Image,
    cols: int,
    rows: int,
    thickness: int = 1,
) -> Image.Image:
    """
    Simple grid-overlay cleanup.

    The reference image has visible grid lines. This pass replaces pixels near
    logical grid lines with nearby neighbor averages. It is intentionally simple:
    good enough for seed assets, not a substitute for Aseprite cleanup.
    """

    img = ensure_rgba(img)
    px = img.load()
    width, height = img.size

    def sample_safe(x: int, y: int) -> tuple[int, int, int, int]:
        x = max(0, min(width - 1, x))
        y = max(0, min(height - 1, y))
        return px[x, y]

    # Vertical logical grid lines.
    for c in range(cols + 1):
        x = round(c * width / cols)
        for ox in range(-thickness, thickness + 1):
            xx = x + ox
            if xx < 0 or xx >= width:
                continue

            for y in range(height):
                left = sample_safe(xx - thickness - 2, y)
                right = sample_safe(xx + thickness + 2, y)
                px[xx, y] = tuple((left[i] + right[i]) // 2 for i in range(4))

    # Horizontal logical grid lines.
    for r in range(rows + 1):
        y = round(r * height / rows)
        for oy in range(-thickness, thickness + 1):
            yy = y + oy
            if yy < 0 or yy >= height:
                continue

            for x in range(width):
                up = sample_safe(x, yy - thickness - 2)
                down = sample_safe(x, yy + thickness + 2)
                px[x, yy] = tuple((up[i] + down[i]) // 2 for i in range(4))

    return img


def cell_box_to_px(
    source_cells: tuple[float, float, float, float],
    image_size: tuple[int, int],
    cols: int,
    rows: int,
) -> tuple[int, int, int, int]:
    col, row, cell_w, cell_h = source_cells
    width, height = image_size

    x0 = round((col / cols) * width)
    y0 = round((row / rows) * height)
    x1 = round(((col + cell_w) / cols) * width)
    y1 = round(((row + cell_h) / rows) * height)

    x0 = max(0, min(width - 1, x0))
    y0 = max(0, min(height - 1, y0))
    x1 = max(x0 + 1, min(width, x1))
    y1 = max(y0 + 1, min(height, y1))

    return x0, y0, x1, y1


def crop_asset(
    img: Image.Image,
    asset: AssetDef,
    cols: int,
    rows: int,
    resample: Image.Resampling,
) -> tuple[Image.Image, tuple[int, int, int, int]]:
    crop_box = cell_box_to_px(asset.source_cells, img.size, cols, rows)
    crop = img.crop(crop_box)
    resized = crop.resize(asset.target_size, resample=resample)
    return resized, crop_box


def write_debug_grid(
    source: Image.Image,
    out_path: Path,
    cols: int,
    rows: int,
) -> None:
    img = source.convert("RGBA")
    draw = ImageDraw.Draw(img)
    width, height = img.size

    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 14)
    except Exception:
        font = ImageFont.load_default()

    for c in range(cols + 1):
        x = round(c * width / cols)
        color = (255, 0, 0, 255) if c % 5 == 0 else (255, 230, 0, 170)
        line_w = 2 if c % 5 == 0 else 1
        draw.line([(x, 0), (x, height)], fill=color, width=line_w)
        if c % 5 == 0 and c < cols:
            draw.text((x + 2, 2), str(c), fill=(255, 255, 255, 255), font=font)

    for r in range(rows + 1):
        y = round(r * height / rows)
        color = (255, 0, 0, 255) if r % 5 == 0 else (255, 230, 0, 170)
        line_w = 2 if r % 5 == 0 else 1
        draw.line([(0, y), (width, y)], fill=color, width=line_w)
        if r % 5 == 0 and r < rows:
            draw.text((2, y + 2), str(r), fill=(255, 255, 255, 255), font=font)

    img.save(out_path)


def make_preview_atlas(
    extracted: list[dict[str, Any]],
    out_path: Path,
    padding: int = 8,
    cell: int = 128,
) -> None:
    """
    Writes a simple visual atlas of all extracted assets.
    """

    if not extracted:
        return

    thumbs: list[tuple[dict[str, Any], Image.Image]] = []
    for item in extracted:
        img = Image.open(item["output_path"]).convert("RGBA")
        thumb = Image.new("RGBA", (cell, cell), (20, 20, 20, 255))

        scale = min((cell - padding * 2) / img.width, (cell - padding * 2) / img.height)
        nw = max(1, int(img.width * scale))
        nh = max(1, int(img.height * scale))
        small = img.resize((nw, nh), resample=Image.Resampling.LANCZOS)

        ox = (cell - nw) // 2
        oy = (cell - nh) // 2
        thumb.alpha_composite(small, (ox, oy))
        thumbs.append((item, thumb))

    cols = 5
    label_h = 42
    rows = math.ceil(len(thumbs) / cols)

    atlas_w = cols * cell
    atlas_h = rows * (cell + label_h)

    atlas = Image.new("RGBA", (atlas_w, atlas_h), (10, 10, 10, 255))
    draw = ImageDraw.Draw(atlas)

    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 11)
    except Exception:
        font = ImageFont.load_default()

    for i, (item, thumb) in enumerate(thumbs):
        col = i % cols
        row = i // cols

        x = col * cell
        y = row * (cell + label_h)

        atlas.alpha_composite(thumb, (x, y))

        label = item["name"]
        if len(label) > 22:
            label = label[:21] + "…"

        draw.text(
            (x + 4, y + cell + 3),
            label,
            fill=(230, 230, 230, 255),
            font=font,
        )

        draw.text(
            (x + 4, y + cell + 19),
            f'{item["target_size"][0]}x{item["target_size"][1]} {item["category"]}',
            fill=(150, 150, 150, 255),
            font=font,
        )

    atlas.save(out_path)


def main() -> None:
    args = parse_args()

    source_path: Path = args.source.expanduser().resolve()
    out_root: Path = args.out.expanduser().resolve()

    if not source_path.exists():
        raise FileNotFoundError(f"Source image not found: {source_path}")

    out_root.mkdir(parents=True, exist_ok=True)

    manifest_path = out_root / "sundered_keep_causeway_assets_manifest.json"
    blueprint_path = out_root / "sundered_keep_causeway_reconstruction_blueprint.json"
    atlas_path = out_root / "sundered_keep_causeway_extracted_asset_preview.png"
    debug_grid_path = out_root / "source_grid_debug_50x37.png"

    raw_source = ensure_rgba(Image.open(source_path))

    if args.write_debug_grid:
        write_debug_grid(raw_source, debug_grid_path, args.cols, args.rows)

    source = raw_source
    if not args.no_degrid:
        source = degrid_image(
            raw_source.copy(),
            cols=args.cols,
            rows=args.rows,
            thickness=args.grid_thickness,
        )

    resample = get_resample_filter(args.resample)

    extracted_items: list[dict[str, Any]] = []

    for asset in ASSETS:
        asset_img, crop_box = crop_asset(
            source,
            asset,
            cols=args.cols,
            rows=args.rows,
            resample=resample,
        )

        category_dir = out_root / asset.category
        category_dir.mkdir(parents=True, exist_ok=True)

        output_path = category_dir / f"{asset.name}.png"
        asset_img.save(output_path)

        item = {
            "name": asset.name,
            "category": asset.category,
            "kind": asset.kind,
            "output_path": str(output_path),
            "relative_path": str(output_path.relative_to(out_root)),
            "source_image": str(source_path),
            "source_cells": list(asset.source_cells),
            "source_px_crop": list(crop_box),
            "target_size": list(asset.target_size),
            "runtime_tile_px": args.tile,
            "runtime_tile_footprint": [
                max(1, asset.target_size[0] // args.tile),
                max(1, asset.target_size[1] // args.tile),
            ],
            "collision": asset.collision,
            "z_hint": asset.z_hint,
            "notes": asset.notes,
        }

        extracted_items.append(item)

    manifest = {
        "name": "sundered_keep_causeway_entrance_extracted_assets",
        "source_image": str(source_path),
        "output_root": str(out_root),
        "source_image_size": list(raw_source.size),
        "source_grid": {
            "cols": args.cols,
            "rows": args.rows,
            "cell_px_approx": [
                raw_source.size[0] / args.cols,
                raw_source.size[1] / args.rows,
            ],
        },
        "runtime_tile_px": args.tile,
        "degrid_applied": not args.no_degrid,
        "resample": args.resample,
        "asset_count": len(extracted_items),
        "assets": extracted_items,
    }

    with manifest_path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    blueprint = dict(RECONSTRUCTION_BLUEPRINT)
    blueprint["asset_manifest"] = str(manifest_path)
    blueprint["output_root"] = str(out_root)

    with blueprint_path.open("w", encoding="utf-8") as f:
        json.dump(blueprint, f, indent=2)

    make_preview_atlas(extracted_items, atlas_path)

    print("Extracted causeway entrance assets.")
    print(f"Source:      {source_path}")
    print(f"Output root: {out_root}")
    print(f"Assets:      {len(extracted_items)}")
    print(f"Manifest:    {manifest_path}")
    print(f"Blueprint:   {blueprint_path}")
    print(f"Preview:     {atlas_path}")

    if args.write_debug_grid:
        print(f"Debug grid:  {debug_grid_path}")


if __name__ == "__main__":
    main()
