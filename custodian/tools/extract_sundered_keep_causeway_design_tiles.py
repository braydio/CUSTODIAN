#!/usr/bin/env python3
"""
Extract runtime-ready tile/prototype assets from the Sundered Keep causeway
entrance design image.

This version is tuned from the debug overlay review. It extracts more atomic,
reconstructable pieces instead of broad contextual crops.

Primary outputs:

  custodian/content/tiles/sundered_keep/causeway_design_extract/
    floors/
    edges/
    walls/
    props/
    water/
    stairs/
    overlays/
    reports/
      sundered_keep_causeway_design_extract.game32.json
      causeway_reconstruct_plan.json
      extraction_contact_sheet.png
      extraction_report.md
    _debug/
      crop_overlay.png

The generated assets are source-derived prototype/runtime slices. They are meant
to make the causeway reconstructable in CUSTODIAN, then be manually cleaned or
re-authored if any composite-shadow/artifact remains.

Usage:

  python tools/extract_sundered_keep_causeway_design_tiles.py \\
    --src custodian/content/masters/sundered_keep/causeway_design_master_hd.png \\
    --out custodian/content/tiles/sundered_keep/causeway_design_extract \\
    --clean \\
    --debug

If the source path differs, pass --src explicitly.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable, Literal

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

# =============================================================================
# Data model
# =============================================================================

Domain = Literal["floors", "edges", "walls", "props", "water", "stairs", "overlays"]
Anchor = Literal[
    "top_left",
    "center",
    "bottom_center",
    "bottom_left",
    "bottom_right",
    "tile_center",
]
CollisionKind = Literal[
    "none",
    "solid",
    "edge_blocker",
    "partial",
    "water_blocker",
]


@dataclass(frozen=True)
class CropSpec:
    """
    x/y/w/h are source-image pixel coordinates.

    out_size is the target runtime canvas in pixels. Use:
      32x32 for floor tiles and small props
      32x64 or 64x32 for directional edges / posts
      64x64 for corners / medium props
      96x32 for horizontal wall runs / stairs
      96x64 or 96x96 for wall chunks / towers
    """

    asset_id: str
    rect: tuple[int, int, int, int]
    out_size: tuple[int, int]
    domain: Domain
    kind: str
    layer: str
    anchor: Anchor = "top_left"
    collision: CollisionKind = "none"
    tags: tuple[str, ...] = field(default_factory=tuple)
    tilemap_role: str = ""
    notes: str = ""


@dataclass(frozen=True)
class Placement:
    """
    Starter reconstruction placement.

    tile is logical 32x32 tile position in the reconstruction plan, not source px.
    """

    op: str
    asset: str
    tile: tuple[int, int] | None = None
    rect: tuple[int, int, int, int] | None = None
    count: int | None = None
    step: tuple[int, int] | None = None
    layer: str = ""
    note: str = ""


# =============================================================================
# Tuned crop set
# =============================================================================

# Source dimensions in the generated image/debug: 1448 x 1086.
# These rects are deliberately smaller/more atomic than the first pass.
#
# Tune workflow:
#   1. run --debug
#   2. open _debug/crop_overlay.png
#   3. adjust rects by a few pixels if needed
#   4. rerun
#
# The asset names are meant to be usable directly in a SunderedKeep asset map.
CROPS: list[CropSpec] = [
    # -------------------------------------------------------------------------
    # Water base / water details
    # -------------------------------------------------------------------------
    CropSpec(
        "sundered_water_dark_01",
        (88, 460, 48, 48),
        (32, 32),
        "water",
        "water_base",
        "TerrainBase",
        collision="water_blocker",
        tags=("water", "void", "repeatable"),
        tilemap_role="base_fill",
        notes="Dark water base; cropped tighter than previous pass.",
    ),
    CropSpec(
        "sundered_water_dark_ripple_01",
        (1114, 613, 48, 48),
        (32, 32),
        "water",
        "water_variant",
        "TerrainBase",
        collision="water_blocker",
        tags=("water", "void", "ripple", "repeatable"),
        tilemap_role="base_variant",
        notes="Subtle water variant for scatter.",
    ),
    CropSpec(
        "sundered_water_marker_post_01",
        (88, 400, 28, 44),
        (32, 64),
        "props",
        "water_marker_post",
        "PropsStatic",
        anchor="bottom_center",
        collision="none",
        tags=("water", "marker", "post"),
        tilemap_role="water_detail",
        notes="Small square marker/post emerging from water.",
    ),

    # -------------------------------------------------------------------------
    # Causeway center walkable floor tiles
    # -------------------------------------------------------------------------
    CropSpec(
        "causeway_floor_center_01",
        (690, 535, 34, 34),
        (32, 32),
        "floors",
        "floor_center",
        "FloorDetail",
        tags=("causeway", "floor", "walkable", "repeatable"),
        tilemap_role="walkable_center",
        notes="Primary central causeway slab.",
    ),
    CropSpec(
        "causeway_floor_center_worn_01",
        (690, 637, 34, 34),
        (32, 32),
        "floors",
        "floor_center",
        "FloorDetail",
        tags=("causeway", "floor", "walkable", "variant"),
        tilemap_role="walkable_center_variant",
        notes="Worn center floor variation.",
    ),
    CropSpec(
        "causeway_floor_center_dark_01",
        (724, 703, 34, 34),
        (32, 32),
        "floors",
        "floor_center",
        "FloorDetail",
        tags=("causeway", "floor", "walkable", "damp", "variant"),
        tilemap_role="walkable_center_variant",
        notes="Darker damp floor variation.",
    ),
    CropSpec(
        "causeway_floor_cracked_01",
        (690, 789, 34, 34),
        (32, 32),
        "floors",
        "floor_center",
        "FloorDetail",
        tags=("causeway", "floor", "walkable", "cracked", "variant"),
        tilemap_role="walkable_center_variant",
        notes="Cracked causeway floor variation.",
    ),
    CropSpec(
        "causeway_floor_threshold_01",
        (690, 349, 34, 34),
        (32, 32),
        "floors",
        "threshold_floor",
        "FloorDetail",
        tags=("causeway", "threshold", "floor", "walkable"),
        tilemap_role="threshold",
        notes="Threshold slab directly below the gatehouse stairs.",
    ),

    # -------------------------------------------------------------------------
    # Causeway vertical side edge strips
    # -------------------------------------------------------------------------
    CropSpec(
        "causeway_edge_w_01",
        (618, 526, 26, 70),
        (32, 64),
        "edges",
        "edge_w",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("causeway", "edge", "west", "vertical", "repeatable"),
        tilemap_role="left_edge",
        notes="West vertical causeway trim, cropped narrow to avoid center floor.",
    ),
    CropSpec(
        "causeway_edge_e_01",
        (806, 526, 26, 70),
        (32, 64),
        "edges",
        "edge_e",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("causeway", "edge", "east", "vertical", "repeatable"),
        tilemap_role="right_edge",
        notes="East vertical causeway trim, cropped narrow to avoid center floor.",
    ),
    CropSpec(
        "causeway_edge_w_broken_01",
        (586, 702, 36, 70),
        (32, 64),
        "edges",
        "edge_w_broken",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("causeway", "edge", "west", "broken"),
        tilemap_role="left_edge_broken",
        notes="Broken west side edge / transition.",
    ),
    CropSpec(
        "causeway_edge_e_broken_01",
        (826, 702, 36, 70),
        (32, 64),
        "edges",
        "edge_e_broken",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("causeway", "edge", "east", "broken"),
        tilemap_role="right_edge_broken",
        notes="Broken east side edge / transition.",
    ),
    CropSpec(
        "causeway_parapet_post_01",
        (598, 472, 30, 34),
        (32, 32),
        "props",
        "post",
        "PropsBlocking",
        anchor="bottom_center",
        collision="solid",
        tags=("causeway", "post", "parapet", "blocker"),
        tilemap_role="edge_post",
        notes="Small square parapet post.",
    ),

    # -------------------------------------------------------------------------
    # Causeway side buttresses / masonry projections
    # -------------------------------------------------------------------------
    CropSpec(
        "causeway_buttress_w_01",
        (586, 500, 56, 88),
        (64, 96),
        "walls",
        "buttress_w",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("causeway", "buttress", "west", "wall", "blocker"),
        tilemap_role="side_buttress",
        notes="West stacked stone buttress; tighter than debug crop.",
    ),
    CropSpec(
        "causeway_buttress_e_01",
        (806, 500, 56, 88),
        (64, 96),
        "walls",
        "buttress_e",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("causeway", "buttress", "east", "wall", "blocker"),
        tilemap_role="side_buttress",
        notes="East stacked stone buttress; tighter than debug crop.",
    ),
    CropSpec(
        "causeway_buttress_w_low_01",
        (586, 724, 54, 76),
        (64, 64),
        "walls",
        "buttress_w_low",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("causeway", "buttress", "west", "low"),
        tilemap_role="side_buttress_low",
        notes="Lower/broken west buttress block.",
    ),
    CropSpec(
        "causeway_buttress_e_low_01",
        (810, 724, 54, 76),
        (64, 64),
        "walls",
        "buttress_e_low",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("causeway", "buttress", "east", "low"),
        tilemap_role="side_buttress_low",
        notes="Lower/broken east buttress block.",
    ),

    # -------------------------------------------------------------------------
    # Outer landing floors / edges / corners
    # -------------------------------------------------------------------------
    CropSpec(
        "outer_landing_floor_center_01",
        (650, 981, 34, 34),
        (32, 32),
        "floors",
        "landing_floor",
        "FloorDetail",
        tags=("outer_landing", "floor", "walkable"),
        tilemap_role="landing_floor",
        notes="Primary outer landing floor.",
    ),
    CropSpec(
        "outer_landing_floor_dark_01",
        (690, 981, 34, 34),
        (32, 32),
        "floors",
        "landing_floor_variant",
        "FloorDetail",
        tags=("outer_landing", "floor", "walkable", "variant"),
        tilemap_role="landing_floor_variant",
        notes="Dark landing floor variation.",
    ),
    CropSpec(
        "outer_landing_floor_trim_01",
        (702, 918, 34, 34),
        (32, 32),
        "floors",
        "landing_trim_floor",
        "FloorDetail",
        tags=("outer_landing", "floor", "trim"),
        tilemap_role="landing_trim",
        notes="Trimmed tile near mooring ring/landing edge.",
    ),
    CropSpec(
        "outer_landing_edge_n_01",
        (650, 882, 94, 30),
        (96, 32),
        "edges",
        "edge_n",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("outer_landing", "edge", "north", "horizontal"),
        tilemap_role="landing_north_edge",
        notes="North/upper edge of lower landing.",
    ),
    CropSpec(
        "outer_landing_edge_w_01",
        (486, 906, 30, 88),
        (32, 96),
        "edges",
        "edge_w",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("outer_landing", "edge", "west", "vertical"),
        tilemap_role="landing_west_edge",
        notes="West vertical edge of lower landing.",
    ),
    CropSpec(
        "outer_landing_edge_e_01",
        (930, 906, 30, 88),
        (32, 96),
        "edges",
        "edge_e",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("outer_landing", "edge", "east", "vertical"),
        tilemap_role="landing_east_edge",
        notes="East vertical edge of lower landing.",
    ),
    CropSpec(
        "outer_landing_corner_nw_01",
        (490, 882, 76, 72),
        (64, 64),
        "edges",
        "corner_nw",
        "TerrainEdges",
        collision="solid",
        tags=("outer_landing", "corner", "northwest"),
        tilemap_role="landing_corner",
        notes="Northwest outer landing corner, reduced from previous broad crop.",
    ),
    CropSpec(
        "outer_landing_corner_ne_01",
        (880, 882, 76, 72),
        (64, 64),
        "edges",
        "corner_ne",
        "TerrainEdges",
        collision="solid",
        tags=("outer_landing", "corner", "northeast"),
        tilemap_role="landing_corner",
        notes="Northeast outer landing corner, reduced from previous broad crop.",
    ),
    CropSpec(
        "outer_landing_side_tower_w_01",
        (508, 914, 68, 92),
        (64, 96),
        "walls",
        "side_tower_w",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("outer_landing", "tower", "west", "wall"),
        tilemap_role="landing_side_tower",
        notes="West lower landing side tower/core structure.",
    ),
    CropSpec(
        "outer_landing_side_tower_e_01",
        (870, 914, 68, 92),
        (64, 96),
        "walls",
        "side_tower_e",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("outer_landing", "tower", "east", "wall"),
        tilemap_role="landing_side_tower",
        notes="East lower landing side tower/core structure.",
    ),

    # -------------------------------------------------------------------------
    # Mooring / landing props
    # -------------------------------------------------------------------------
    CropSpec(
        "mooring_bollards_w_01",
        (438, 935, 34, 98),
        (32, 96),
        "props",
        "bollards_w",
        "PropsStatic",
        anchor="bottom_center",
        collision="partial",
        tags=("mooring", "bollards", "west"),
        tilemap_role="landing_side_prop",
        notes="West vertical row of mooring bollards.",
    ),
    CropSpec(
        "mooring_bollards_e_01",
        (976, 935, 34, 98),
        (32, 96),
        "props",
        "bollards_e",
        "PropsStatic",
        anchor="bottom_center",
        collision="partial",
        tags=("mooring", "bollards", "east"),
        tilemap_role="landing_side_prop",
        notes="East vertical row of mooring bollards.",
    ),
    CropSpec(
        "mooring_ring_w_01",
        (618, 918, 44, 32),
        (32, 32),
        "props",
        "mooring_ring",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("mooring", "ring", "west"),
        tilemap_role="landing_detail",
        notes="West ring/chain detail.",
    ),
    CropSpec(
        "mooring_ring_e_01",
        (786, 918, 44, 32),
        (32, 32),
        "props",
        "mooring_ring",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("mooring", "ring", "east"),
        tilemap_role="landing_detail",
        notes="East ring/chain detail.",
    ),
    CropSpec(
        "landing_grate_01",
        (522, 998, 56, 56),
        (64, 64),
        "props",
        "grate",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("landing", "grate", "metal"),
        tilemap_role="floor_prop",
        notes="Square metal grate/hatch in landing.",
    ),
    CropSpec(
        "landing_grate_alt_01",
        (884, 998, 56, 56),
        (64, 64),
        "props",
        "grate",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("landing", "grate", "metal", "alt"),
        tilemap_role="floor_prop",
        notes="Alternate grate/hatch on east landing.",
    ),

    # -------------------------------------------------------------------------
    # Gatehouse threshold / stairs / entry
    # -------------------------------------------------------------------------
    CropSpec(
        "gatehouse_steps_n_01",
        (642, 306, 130, 38),
        (96, 32),
        "stairs",
        "stairs_n",
        "Traversal",
        collision="none",
        tags=("gatehouse", "stairs", "north", "walkable"),
        tilemap_role="stairs",
        notes="Horizontal stair run at the top of causeway.",
    ),
    CropSpec(
        "gatehouse_entry_floor_01",
        (690, 259, 34, 34),
        (32, 32),
        "floors",
        "gatehouse_entry_floor",
        "FloorDetail",
        tags=("gatehouse", "entry", "floor", "walkable"),
        tilemap_role="gatehouse_entry",
        notes="Floor tile just above the stairs.",
    ),
    CropSpec(
        "gatehouse_threshold_floor_01",
        (690, 349, 34, 34),
        (32, 32),
        "floors",
        "gatehouse_threshold_floor",
        "FloorDetail",
        tags=("gatehouse", "threshold", "floor", "walkable"),
        tilemap_role="gatehouse_threshold",
        notes="Floor tile below stairs/gatehouse threshold.",
    ),
    CropSpec(
        "forecourt_floor_center_01",
        (704, 178, 34, 34),
        (32, 32),
        "floors",
        "forecourt_floor",
        "FloorDetail",
        tags=("forecourt", "floor", "walkable"),
        tilemap_role="forecourt_floor",
        notes="Upper forecourt floor center.",
    ),
    CropSpec(
        "forecourt_floor_variant_01",
        (758, 178, 34, 34),
        (32, 32),
        "floors",
        "forecourt_floor_variant",
        "FloorDetail",
        tags=("forecourt", "floor", "walkable", "variant"),
        tilemap_role="forecourt_floor_variant",
        notes="Upper forecourt floor variation.",
    ),

    # -------------------------------------------------------------------------
    # Gatehouse side wall / pillar units
    # -------------------------------------------------------------------------
    CropSpec(
        "gatehouse_side_pillar_w_01",
        (520, 294, 76, 112),
        (96, 96),
        "walls",
        "pillar_w",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "pillar", "west", "wall", "blocker"),
        tilemap_role="gatehouse_flank",
        notes="West gatehouse side pillar/tower, tighter crop.",
    ),
    CropSpec(
        "gatehouse_side_pillar_e_01",
        (852, 294, 76, 112),
        (96, 96),
        "walls",
        "pillar_e",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "pillar", "east", "wall", "blocker"),
        tilemap_role="gatehouse_flank",
        notes="East gatehouse side pillar/tower, tighter crop.",
    ),
    CropSpec(
        "gatehouse_wall_face_01",
        (522, 250, 114, 74),
        (96, 64),
        "walls",
        "wall_face",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "wall", "face", "horizontal"),
        tilemap_role="gatehouse_wall_face",
        notes="West dark gatehouse wall face.",
    ),
    CropSpec(
        "gatehouse_wall_face_alt_01",
        (812, 250, 114, 74),
        (96, 64),
        "walls",
        "wall_face_alt",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "wall", "face", "horizontal", "alt"),
        tilemap_role="gatehouse_wall_face",
        notes="East dark gatehouse wall face.",
    ),
    CropSpec(
        "gatehouse_wall_socket_01",
        (596, 334, 38, 64),
        (32, 64),
        "walls",
        "wall_socket",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "wall", "socket", "vertical"),
        tilemap_role="gatehouse_socket",
        notes="Narrow vertical masonry/socket detail.",
    ),
    CropSpec(
        "gatehouse_wall_socket_e_01",
        (812, 334, 38, 64),
        (32, 64),
        "walls",
        "wall_socket_e",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("gatehouse", "wall", "socket", "vertical", "east"),
        tilemap_role="gatehouse_socket",
        notes="Narrow east vertical masonry/socket detail.",
    ),

    # -------------------------------------------------------------------------
    # Upper rampart / battlement extraction
    # -------------------------------------------------------------------------
    CropSpec(
        "rampart_corner_chunk_01",
        (70, 78, 92, 92),
        (96, 96),
        "walls",
        "rampart_corner",
        "WallsHigh",
        anchor="bottom_center",
        collision="solid",
        tags=("rampart", "corner", "wall"),
        tilemap_role="rampart_corner",
        notes="Upper-left rampart corner chunk.",
    ),
    CropSpec(
        "rampart_crenellation_s_01",
        (174, 134, 126, 30),
        (96, 32),
        "walls",
        "crenellation_s",
        "WallsHigh",
        anchor="bottom_left",
        collision="solid",
        tags=("rampart", "crenellation", "south", "horizontal"),
        tilemap_role="rampart_cap",
        notes="Horizontal crenellation cap row.",
    ),
    CropSpec(
        "rampart_wall_horizontal_01",
        (214, 250, 126, 68),
        (96, 64),
        "walls",
        "wall_horizontal",
        "WallsHigh",
        anchor="bottom_left",
        collision="solid",
        tags=("rampart", "wall", "horizontal"),
        tilemap_role="rampart_wall_face",
        notes="Horizontal wall-face segment below battlements.",
    ),
    CropSpec(
        "rampart_trim_underwall_01",
        (180, 318, 126, 34),
        (96, 32),
        "edges",
        "underwall_trim",
        "TerrainEdges",
        collision="edge_blocker",
        tags=("rampart", "trim", "horizontal"),
        tilemap_role="rampart_underwall_trim",
        notes="Thin under-wall trim line above water.",
    ),

    # -------------------------------------------------------------------------
    # Props / debris / grate
    # -------------------------------------------------------------------------
    CropSpec(
        "gothic_torch_post_01",
        (586, 176, 32, 72),
        (32, 64),
        "props",
        "torch_post",
        "PropsStatic",
        anchor="bottom_center",
        collision="partial",
        tags=("forecourt", "torch", "post"),
        tilemap_role="forecourt_prop",
        notes="Tall torch/post-like object in upper forecourt.",
    ),
    CropSpec(
        "gothic_torch_post_alt_01",
        (850, 176, 32, 72),
        (32, 64),
        "props",
        "torch_post",
        "PropsStatic",
        anchor="bottom_center",
        collision="partial",
        tags=("forecourt", "torch", "post", "alt"),
        tilemap_role="forecourt_prop",
        notes="Alternate torch/post-like object.",
    ),
    CropSpec(
        "rubble_pile_01",
        (230, 174, 70, 58),
        (64, 64),
        "props",
        "rubble",
        "PropsBlocking",
        anchor="bottom_center",
        collision="solid",
        tags=("rubble", "debris", "blocker"),
        tilemap_role="debris",
        notes="Rubble/debris pile.",
    ),
    CropSpec(
        "rubble_pile_alt_01",
        (1050, 174, 70, 58),
        (64, 64),
        "props",
        "rubble",
        "PropsBlocking",
        anchor="bottom_center",
        collision="solid",
        tags=("rubble", "debris", "blocker", "alt"),
        tilemap_role="debris",
        notes="Alternate rubble/debris pile.",
    ),
    CropSpec(
        "metal_grate_floor_01",
        (1018, 96, 96, 96),
        (96, 96),
        "props",
        "metal_grate_floor",
        "PropsStatic",
        anchor="top_left",
        collision="none",
        tags=("metal", "grate", "floor", "large"),
        tilemap_role="large_floor_prop",
        notes="Large metal grate / roof-like floor detail.",
    ),

    # -------------------------------------------------------------------------
    # Small architectural detail tiles for variety
    # -------------------------------------------------------------------------
    CropSpec(
        "small_square_stone_detail_01",
        (626, 468, 26, 26),
        (32, 32),
        "props",
        "small_stone_detail",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("detail", "stone", "square"),
        tilemap_role="decal_prop",
        notes="Small square detail from causeway side trim.",
    ),
    CropSpec(
        "small_square_stone_detail_02",
        (804, 468, 26, 26),
        (32, 32),
        "props",
        "small_stone_detail",
        "PropsStatic",
        anchor="center",
        collision="none",
        tags=("detail", "stone", "square", "alt"),
        tilemap_role="decal_prop",
        notes="Alternate small square detail.",
    ),
]


# =============================================================================
# Reconstruction plan
# =============================================================================

RECONSTRUCTION_OPS: list[Placement] = [
    Placement(
        "fill_rect",
        "sundered_water_dark_01",
        rect=(0, 0, 40, 48),
        layer="TerrainBase",
        note="Base dark water/void.",
    ),
    Placement(
        "scatter_rect",
        "sundered_water_dark_ripple_01",
        rect=(0, 0, 40, 48),
        layer="TerrainBase",
        note="Sparse water variation.",
    ),

    # Outer landing
    Placement("fill_rect", "outer_landing_floor_center_01", rect=(11, 38, 18, 7), layer="FloorDetail"),
    Placement("scatter_rect", "outer_landing_floor_dark_01", rect=(11, 38, 18, 7), layer="FloorDetail"),
    Placement("repeat_horizontal", "outer_landing_edge_n_01", tile=(11, 37), count=6, step=(3, 0), layer="TerrainEdges"),
    Placement("place", "outer_landing_corner_nw_01", tile=(9, 37), layer="TerrainEdges"),
    Placement("place", "outer_landing_corner_ne_01", tile=(29, 37), layer="TerrainEdges"),
    Placement("place", "outer_landing_side_tower_w_01", tile=(10, 40), layer="WallsHigh"),
    Placement("place", "outer_landing_side_tower_e_01", tile=(28, 40), layer="WallsHigh"),
    Placement("place", "outer_landing_edge_w_01", tile=(10, 40), layer="TerrainEdges"),
    Placement("place", "outer_landing_edge_e_01", tile=(30, 40), layer="TerrainEdges"),
    Placement("place", "mooring_bollards_w_01", tile=(8, 40), layer="PropsStatic"),
    Placement("place", "mooring_bollards_e_01", tile=(31, 40), layer="PropsStatic"),
    Placement("place", "mooring_ring_w_01", tile=(17, 38), layer="PropsStatic"),
    Placement("place", "mooring_ring_e_01", tile=(22, 38), layer="PropsStatic"),
    Placement("place", "landing_grate_01", tile=(12, 42), layer="PropsStatic"),
    Placement("place", "landing_grate_alt_01", tile=(26, 42), layer="PropsStatic"),

    # Central causeway
    Placement("fill_rect", "causeway_floor_center_01", rect=(18, 12, 4, 27), layer="FloorDetail"),
    Placement("scatter_rect", "causeway_floor_center_worn_01", rect=(18, 12, 4, 27), layer="FloorDetail"),
    Placement("scatter_rect", "causeway_floor_center_dark_01", rect=(18, 12, 4, 27), layer="FloorDetail"),
    Placement("scatter_rect", "causeway_floor_cracked_01", rect=(18, 12, 4, 27), layer="FloorDetail"),
    Placement("repeat_vertical", "causeway_edge_w_01", tile=(17, 13), count=12, step=(0, 2), layer="TerrainEdges"),
    Placement("repeat_vertical", "causeway_edge_e_01", tile=(22, 13), count=12, step=(0, 2), layer="TerrainEdges"),
    Placement("place", "causeway_buttress_w_01", tile=(15, 15), layer="WallsHigh"),
    Placement("place", "causeway_buttress_e_01", tile=(23, 15), layer="WallsHigh"),
    Placement("place", "causeway_buttress_w_low_01", tile=(15, 24), layer="WallsHigh"),
    Placement("place", "causeway_buttress_e_low_01", tile=(23, 24), layer="WallsHigh"),
    Placement("place", "causeway_edge_w_broken_01", tile=(17, 28), layer="TerrainEdges"),
    Placement("place", "causeway_edge_e_broken_01", tile=(22, 28), layer="TerrainEdges"),

    # Gatehouse threshold
    Placement("fill_rect", "gatehouse_threshold_floor_01", rect=(16, 10, 8, 3), layer="FloorDetail"),
    Placement("place", "gatehouse_steps_n_01", tile=(17, 9), layer="Traversal"),
    Placement("fill_rect", "gatehouse_entry_floor_01", rect=(16, 6, 8, 4), layer="FloorDetail"),
    Placement("scatter_rect", "forecourt_floor_center_01", rect=(7, 2, 26, 7), layer="FloorDetail"),
    Placement("scatter_rect", "forecourt_floor_variant_01", rect=(7, 2, 26, 7), layer="FloorDetail"),
    Placement("place", "gatehouse_side_pillar_w_01", tile=(13, 8), layer="WallsHigh"),
    Placement("place", "gatehouse_side_pillar_e_01", tile=(25, 8), layer="WallsHigh"),
    Placement("place", "gatehouse_wall_face_01", tile=(12, 5), layer="WallsHigh"),
    Placement("place", "gatehouse_wall_face_alt_01", tile=(25, 5), layer="WallsHigh"),
    Placement("place", "gatehouse_wall_socket_01", tile=(16, 8), layer="WallsHigh"),
    Placement("place", "gatehouse_wall_socket_e_01", tile=(23, 8), layer="WallsHigh"),

    # Upper rampart / wall
    Placement("repeat_horizontal", "rampart_crenellation_s_01", tile=(2, 4), count=12, step=(3, 0), layer="WallsHigh"),
    Placement("repeat_horizontal", "rampart_wall_horizontal_01", tile=(2, 7), count=12, step=(3, 0), layer="WallsHigh"),
    Placement("repeat_horizontal", "rampart_trim_underwall_01", tile=(2, 10), count=12, step=(3, 0), layer="TerrainEdges"),
    Placement("place", "rampart_corner_chunk_01", tile=(0, 3), layer="WallsHigh"),

    # Details
    Placement("place", "gothic_torch_post_01", tile=(16, 5), layer="PropsStatic"),
    Placement("place", "gothic_torch_post_alt_01", tile=(24, 5), layer="PropsStatic"),
    Placement("place", "rubble_pile_01", tile=(7, 6), layer="PropsBlocking"),
    Placement("place", "rubble_pile_alt_01", tile=(30, 6), layer="PropsBlocking"),
    Placement("place", "metal_grate_floor_01", tile=(30, 2), layer="PropsStatic"),

    # Water markers, mirrored-ish scatter
    Placement("place", "sundered_water_marker_post_01", tile=(2, 17), layer="PropsStatic"),
    Placement("place", "sundered_water_marker_post_01", tile=(5, 23), layer="PropsStatic"),
    Placement("place", "sundered_water_marker_post_01", tile=(34, 17), layer="PropsStatic"),
    Placement("place", "sundered_water_marker_post_01", tile=(31, 25), layer="PropsStatic"),
]


# =============================================================================
# CLI / filesystem
# =============================================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract a detailed game32 Sundered Keep causeway asset set from a composite mockup."
    )
    parser.add_argument(
        "--src",
        type=Path,
        required=True,
        help="Source causeway design image.",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("custodian/content/tiles/sundered_keep/causeway_design_extract"),
        help="Output directory.",
    )
    parser.add_argument(
        "--manifest-name",
        default="sundered_keep_causeway_design_extract.game32.json",
        help="Manifest filename under reports/.",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Delete output dir before writing.",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Write debug crop overlay.",
    )
    parser.add_argument(
        "--resample",
        choices=("nearest", "box", "lanczos"),
        default="lanczos",
        help="Resize filter. Use lanczos for generated mockups, nearest for true pixel sheets.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=0,
        help="If >0, make pixels with alpha <= threshold transparent.",
    )
    return parser.parse_args()


def ensure_dirs(out_root: Path, clean: bool) -> dict[str, Path]:
    if clean and out_root.exists():
        shutil.rmtree(out_root)

    dirs = {
        "root": out_root,
        "floors": out_root / "floors",
        "edges": out_root / "edges",
        "walls": out_root / "walls",
        "props": out_root / "props",
        "water": out_root / "water",
        "stairs": out_root / "stairs",
        "overlays": out_root / "overlays",
        "reports": out_root / "reports",
        "debug": out_root / "_debug",
    }

    for path in dirs.values():
        path.mkdir(parents=True, exist_ok=True)

    return dirs


def get_resample(name: str) -> Image.Resampling:
    if name == "nearest":
        return Image.Resampling.NEAREST
    if name == "box":
        return Image.Resampling.BOX
    return Image.Resampling.LANCZOS


# =============================================================================
# Image processing
# =============================================================================

def crop_source(src: Image.Image, spec: CropSpec) -> Image.Image:
    x, y, w, h = spec.rect
    return src.crop((x, y, x + w, y + h)).convert("RGBA")


def normalize_crop(
    crop: Image.Image,
    out_size: tuple[int, int],
    resample: Image.Resampling,
) -> Image.Image:
    img = crop.resize(out_size, resample=resample)

    # Generated composites often blur slightly during downscale. Mild sharpen helps.
    if resample != Image.Resampling.NEAREST:
        img = ImageEnhance.Sharpness(img).enhance(1.35)
        img = ImageEnhance.Contrast(img).enhance(1.04)

    return img.convert("RGBA")


def alpha_cleanup(img: Image.Image, threshold: int) -> Image.Image:
    if threshold <= 0:
        return img

    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a <= threshold:
                px[x, y] = (r, g, b, 0)
    return img


def write_debug_overlay(src: Image.Image, crops: list[CropSpec], out_path: Path) -> None:
    img = src.convert("RGBA")
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    domain_colors = {
        "floors": (60, 230, 120, 255),
        "edges": (100, 180, 255, 255),
        "walls": (255, 170, 60, 255),
        "props": (255, 70, 215, 255),
        "water": (70, 140, 255, 255),
        "stairs": (230, 230, 70, 255),
        "overlays": (190, 120, 255, 255),
    }

    for index, spec in enumerate(crops, 1):
        x, y, w, h = spec.rect
        color = domain_colors.get(spec.domain, (255, 255, 255, 255))
        draw.rectangle((x, y, x + w, y + h), outline=color, width=3)

        label = f"{index}:{spec.asset_id}"
        text_w = max(80, len(label) * 6 + 8)
        label_y = max(0, y - 12)
        draw.rectangle((x, label_y, x + text_w, label_y + 12), fill=(0, 0, 0, 185))
        draw.text((x + 2, label_y + 1), label, fill=color, font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def make_contact_sheet(records: list[dict], out_root: Path, out_path: Path) -> None:
    thumb = 96
    pad = 10
    label_h = 34
    cols = 6
    rows = math.ceil(len(records) / cols)

    sheet_w = cols * (thumb + pad) + pad
    sheet_h = rows * (thumb + label_h + pad) + pad
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (20, 20, 24, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for i, record in enumerate(records):
        col = i % cols
        row = i // cols
        x = pad + col * (thumb + pad)
        y = pad + row * (thumb + label_h + pad)

        img_path = out_root / record["texture"]
        asset = Image.open(img_path).convert("RGBA")
        scale = min(thumb / asset.width, thumb / asset.height)
        resized = asset.resize(
            (max(1, int(asset.width * scale)), max(1, int(asset.height * scale))),
            Image.Resampling.NEAREST,
        )

        bg = Image.new("RGBA", (thumb, thumb), (38, 38, 44, 255))
        bg.alpha_composite(
            resized,
            ((thumb - resized.width) // 2, (thumb - resized.height) // 2),
        )
        sheet.alpha_composite(bg, (x, y))
        draw.rectangle((x, y, x + thumb, y + thumb), outline=(100, 100, 110, 255))

        label = record["id"]
        if len(label) > 22:
            label = label[:21] + "…"
        draw.text((x, y + thumb + 4), label, fill=(230, 230, 230, 255), font=font)
        draw.text(
            (x, y + thumb + 16),
            f'{record["domain"]} {record["runtime_size_px"][0]}x{record["runtime_size_px"][1]}',
            fill=(170, 170, 180, 255),
            font=font,
        )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


# =============================================================================
# Manifest helpers
# =============================================================================

def rel(path: Path, root: Path) -> str:
    return str(path.relative_to(root)).replace("\\", "/")


def collision_shape_for(spec: CropSpec) -> dict:
    w, h = spec.out_size

    if spec.collision == "none":
        return {
            "type": "none",
        }

    if spec.collision == "water_blocker":
        return {
            "type": "rect",
            "size_px": [w, h],
            "offset_px": [0, 0],
            "layers": ["terrain_blocker", "water_void"],
        }

    if spec.collision == "edge_blocker":
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


def render_policy_for(spec: CropSpec) -> dict:
    w, h = spec.out_size

    if spec.domain in ("floors", "water"):
        z = -20
        y_sort = False
    elif spec.domain in ("edges", "stairs"):
        z = -10
        y_sort = False
    elif spec.domain == "walls":
        z = 20
        y_sort = True
    else:
        z = 10
        y_sort = True

    return {
        "recommended_layer": spec.layer,
        "z_index_hint": z,
        "y_sort": y_sort,
        "texture_filter": "nearest",
        "pixel_snap": True,
        "anchor": spec.anchor,
        "origin_policy": "tile_top_left" if spec.anchor == "top_left" else "anchor_to_tile",
        "size_class": f"{w}x{h}",
    }


def make_manifest_record(spec: CropSpec, png_path: Path, out_root: Path) -> dict:
    w, h = spec.out_size
    source_x, source_y, source_w, source_h = spec.rect

    return {
        "id": spec.asset_id,
        "texture": rel(png_path, out_root),
        "domain": spec.domain,
        "kind": spec.kind,
        "tags": list(spec.tags),
        "tilemap_role": spec.tilemap_role,
        "tile_size": 32,
        "source_rect_px": [source_x, source_y, source_w, source_h],
        "runtime_size_px": [w, h],
        "footprint_tiles": [max(1, math.ceil(w / 32)), max(1, math.ceil(h / 32))],
        "collision": spec.collision,
        "collision_shape": collision_shape_for(spec),
        "render": render_policy_for(spec),
        "game32": {
            "schema": "game32.asset.v1",
            "grid_px": 32,
            "frame_count": 1,
            "frame_size_px": [w, h],
            "atlas": False,
            "can_repeat": "repeatable" in spec.tags,
            "can_scatter": "variant" in spec.tags or spec.kind in {"rubble", "water_variant"},
            "runtime_canvas_multiple_of_32": (w % 32 == 0 and h % 32 == 0),
        },
        "notes": spec.notes,
    }


def make_reconstruction_plan(records: list[dict]) -> dict:
    asset_ids = {record["id"] for record in records}

    ops = []
    for placement in RECONSTRUCTION_OPS:
        if placement.asset not in asset_ids:
            continue

        item = {
            "op": placement.op,
            "asset": placement.asset,
            "layer": placement.layer,
        }
        if placement.tile is not None:
            item["tile"] = list(placement.tile)
        if placement.rect is not None:
            item["rect"] = list(placement.rect)
        if placement.count is not None:
            item["count"] = placement.count
        if placement.step is not None:
            item["step"] = list(placement.step)
        if placement.note:
            item["note"] = placement.note

        ops.append(item)

    return {
        "schema": "custodian.sundered_keep.causeway_reconstruction_plan.v2",
        "tile_size": 32,
        "map_size_tiles": [40, 48],
        "coordinate_system": "tile_xy_top_left",
        "design_intent": {
            "primary_route": "outer landing -> central causeway -> gatehouse threshold -> forecourt",
            "readability_rule": "Keep central 4-tile lane mostly walkable and visually distinct.",
            "blocker_rule": "Use buttresses, edges, water, and walls as collision boundaries.",
        },
        "layers": [
            "TerrainBase",
            "FloorDetail",
            "TerrainEdges",
            "Traversal",
            "WallsHigh",
            "PropsStatic",
            "PropsBlocking",
            "WorldUI",
        ],
        "ops": ops,
    }


def write_report(out_root: Path, records: list[dict], src_path: Path) -> None:
    lines = [
        "# Sundered Keep Causeway Design Extract",
        "",
        f"- Source: `{src_path}`",
        f"- Asset count: {len(records)}",
        "- Tile size: 32",
        "",
        "## Domains",
        "",
    ]

    by_domain: dict[str, list[dict]] = {}
    for record in records:
        by_domain.setdefault(record["domain"], []).append(record)

    for domain, items in sorted(by_domain.items()):
        lines.append(f"### {domain}")
        lines.append("")
        for item in items:
            lines.append(
                f"- `{item['id']}` — {item['kind']} — "
                f"{item['runtime_size_px'][0]}x{item['runtime_size_px'][1]} — "
                f"layer `{item['render']['recommended_layer']}` — collision `{item['collision']}`"
            )
        lines.append("")

    lines.extend([
        "## Notes",
        "",
        "- Crops are representative prototype slices from a composite mockup.",
        "- The generated PNGs should be treated as runtime candidates, not final hand-authored source of truth.",
        "- Use `_debug/crop_overlay.png` to tune source rects.",
        "- Use `reports/extraction_contact_sheet.png` to quickly review outputs.",
        "- Use `reports/causeway_reconstruct_plan.json` as a starter map-building recipe.",
        "",
    ])

    (out_root / "reports" / "extraction_report.md").write_text(
        "\n".join(lines),
        encoding="utf-8",
    )


# =============================================================================
# Main
# =============================================================================

def main() -> int:
    args = parse_args()

    src_path = args.src.expanduser().resolve()
    out_root = args.out.expanduser().resolve()

    if not src_path.exists():
        print(f"ERROR: source image does not exist: {src_path}")
        return 2

    src = Image.open(src_path).convert("RGBA")
    dirs = ensure_dirs(out_root, clean=args.clean)
    resample = get_resample(args.resample)

    records: list[dict] = []

    for spec in CROPS:
        crop = crop_source(src, spec)
        normalized = normalize_crop(crop, spec.out_size, resample)
        normalized = alpha_cleanup(normalized, args.alpha_threshold)

        domain_dir = dirs[spec.domain]
        png_path = domain_dir / f"{spec.asset_id}.png"
        normalized.save(png_path)

        records.append(make_manifest_record(spec, png_path, out_root))

    manifest = {
        "schema": "custodian.game32.sundered_keep.causeway_design_extract.v2",
        "source_image": str(src_path),
        "source_image_size_px": [src.width, src.height],
        "output_root": str(out_root),
        "tile_size": 32,
        "asset_count": len(records),
        "domains": sorted({record["domain"] for record in records}),
        "usage": {
            "primary_runtime_target": "Sundered Keep causeway entrance / gatehouse approach",
            "recommended_integration": [
                "Register textures in the Sundered Keep asset table or JSON level asset registry.",
                "Use floors/water as tileable base assets.",
                "Use edges/walls/props as placed sprites or layered tilemap assets.",
                "Use causeway_reconstruct_plan.json as a starter layout recipe.",
            ],
        },
        "assets": records,
    }

    manifest_path = dirs["reports"] / args.manifest_name
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    reconstruct_plan = make_reconstruction_plan(records)
    reconstruct_path = dirs["reports"] / "causeway_reconstruct_plan.json"
    reconstruct_path.write_text(json.dumps(reconstruct_plan, indent=2), encoding="utf-8")

    contact_path = dirs["reports"] / "extraction_contact_sheet.png"
    make_contact_sheet(records, out_root, contact_path)

    write_report(out_root, records, src_path)

    if args.debug:
        write_debug_overlay(src, CROPS, dirs["debug"] / "crop_overlay.png")

    print(f"source:        {src_path}")
    print(f"source size:   {src.width}x{src.height}")
    print(f"output root:   {out_root}")
    print(f"assets:        {len(records)}")
    print(f"manifest:      {manifest_path}")
    print(f"reconstruct:   {reconstruct_path}")
    print(f"contact sheet: {contact_path}")

    if args.debug:
        print(f"debug overlay: {dirs['debug'] / 'crop_overlay.png'}")

    print()
    print("Next:")
    print("  1. Open _debug/crop_overlay.png and reports/extraction_contact_sheet.png.")
    print("  2. Adjust CROPS rects if any crop still includes too much neighboring context.")
    print("  3. Register the manifest assets in SunderedKeepMap / level JSON.")
    print("  4. Use causeway_reconstruct_plan.json as the first reconstruction pass.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
