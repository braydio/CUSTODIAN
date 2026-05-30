#!/usr/bin/env python3
"""
Extract Sundered Keep master sheets into CUSTODIAN runtime assets and game32 metadata.

Default project layout expected:
  ~/Projects/CUSTODIAN/custodian/
    content/masters/sundered_keep/*.png       # source sheets
    content/runtime/sundered_keep/...         # generated runtime assets + metadata

Install deps:
  python -m pip install pillow numpy

Typical run from anywhere:
  python extract_sundered_keep_game32.py

If your doors sheet has a different name because the prompt duplicated cliffs_oceans.png:
  python extract_sundered_keep_game32.py --doors-sheet doors_traversal.png

Dry run:
  python extract_sundered_keep_game32.py --dry-run
"""
from __future__ import annotations

import argparse
import dataclasses
import datetime as _dt
import hashlib
import json
import math
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
except ImportError as exc:
    print("Missing dependency. Install with: python -m pip install pillow numpy", file=sys.stderr)
    raise

BASE_TILE_PX = 32
SCHEMA = "game32.asset.v1"
MANIFEST_SCHEMA = "game32.manifest.v1"

# ---------------------------------------------------------------------------
# Asset sheet specs. Order matters: extraction assigns bboxes in this order.
# ---------------------------------------------------------------------------

TERRAIN_ASSETS = [
    "cliff_edge_n.png",
    "cliff_edge_e.png",
    "cliff_edge_s.png",
    "cliff_edge_w.png",
    "cliff_inner_corner_ne.png",
    "cliff_inner_corner_nw.png",
    "cliff_inner_corner_se.png",
    "cliff_inner_corner_sw.png",
    "cliff_outer_corner_ne.png",
    "cliff_outer_corner_nw.png",
    "cliff_outer_corner_se.png",
    "cliff_outer_corner_sw.png",
    "cliff_face_slice_01.png",
    "cliff_face_slice_wet_01.png",
    "cliff_face_slice_mossy_01.png",
    "ocean_foam_edge_n.png",
    "ocean_foam_edge_e.png",
    "ocean_foam_edge_s.png",
    "ocean_foam_edge_w.png",
    "ocean_dark_water_01.png",
]

DOOR_TRAVERSAL_ASSETS = [
    "main_gate_portcullis_closed.png",
    "main_gate_portcullis_open.png",
    "gothic_double_door_closed_n.png",
    "gothic_double_door_open_n.png",
    "gothic_double_door_closed_s.png",
    "gothic_double_door_open_s.png",
    "stone_stairs_up_n.png",
    "stone_stairs_up_e.png",
    "stone_stairs_up_s.png",
    "stone_stairs_up_w.png",
    "stone_stairs_down_n.png",
    "stone_stairs_down_s.png",
    "floor_hatch_closed_01.png",
    "floor_hatch_open_01.png",
]

PROPS_TABLES_CRATES_ASSETS = [
    "prop_courtyard_fountain_broken_01.png",
    "prop_gothic_statue_broken_01.png",
    "prop_gothic_statue_intact_01.png",
    "prop_broken_cart_01.png",
    "prop_crate_stack_wet_01.png",
    "prop_barrel_wet_01.png",
    "prop_fallen_masonry_01.png",
    "prop_low_garden_wall_01.png",
    "prop_gate_winch_01.png",
    "prop_portcullis_chain_01.png",
    "prop_gate_barricade_01.png",
    "prop_torch_wall_gothic_01.png",
    "prop_banquet_table_long_01.png",
    "prop_banquet_table_broken_01.png",
]

PROPS_CASKETS_MISC_ASSETS = [
    "prop_great_hall_column_01.png",
    "prop_fallen_chandelier_01.png",
    "prop_throne_ruined_01.png",
    "prop_brazier_iron_01.png",
    "prop_banner_torn_large_01.png",
    "prop_gargoyle_perch_01.png",
    "prop_lightning_rod_01.png",
    "prop_rope_bridge_anchor_01.png",
    "prop_sea_spray_rock_01.png",
    "prop_broken_spire_chunk_01.png",
    "prop_bookshelf_tall_01.png",
    "prop_chapel_pew_01.png",
    "prop_sarcophagus_01.png",
    "prop_telescope_broken_01.png",
]

@dataclasses.dataclass(frozen=True)
class SheetSpec:
    key: str
    candidates: Tuple[str, ...]
    assets: Tuple[str, ...]
    default_domain: str
    required: bool = True

SHEET_SPECS: Tuple[SheetSpec, ...] = (
    SheetSpec(
        key="terrain_cliffs_ocean",
        candidates=(
            "cliffs_oceans.png",
            "cliff_ocean.png",
            "cliff_and_ocean_terrain_tiles.png",
        ),
        assets=tuple(TERRAIN_ASSETS),
        default_domain="terrain",
    ),
    SheetSpec(
        key="doors_traversal",
        candidates=(
            "doors_traversal.png",
            "doors_gates_stairs.png",
            "doors_stairs_hatches.png",
            "gates_stairs_doors.png",
            "sundered_doors_traversal.png",
            "medieval_dungeon_gate_and_stair_assets.png",
        ),
        assets=tuple(DOOR_TRAVERSAL_ASSETS),
        default_domain="doors_traversal",
    ),
    SheetSpec(
        key="props_tables_crates",
        candidates=(
            "tables_crates_props.png",
            "gothic_fantasy_ruin_prop_sheet.png",
        ),
        assets=tuple(PROPS_TABLES_CRATES_ASSETS),
        default_domain="props",
    ),
    SheetSpec(
        key="props_caskets_misc",
        candidates=(
            "props_caskets_misc.png",
            "caskets_misc_props.png",
            "gothic_fantasy_game_asset_collection.png",
        ),
        assets=tuple(PROPS_CASKETS_MISC_ASSETS),
        default_domain="props",
    ),
)

# ---------------------------------------------------------------------------
# Per-asset runtime policy. Canvas sizes are multiples of 32 and preserve a
# predictable runtime footprint. These are intentionally editable knobs.
# ---------------------------------------------------------------------------

@dataclasses.dataclass(frozen=True)
class RuntimePolicy:
    domain: str
    subdir: str
    kind: str
    subkind: str
    canvas_tiles: Tuple[int, int]
    footprint_tiles: Tuple[int, int]
    anchor: str = "bottom_center"
    y_sort: bool = True
    draw_order: str = "prop"
    walkable: bool = False
    blocks_movement: bool = True
    blocks_projectiles: bool = True
    collision_kind: str = "rect_footprint"
    traversal: Optional[str] = None
    interactable: bool = False
    tags: Tuple[str, ...] = ()


def policy_for(filename: str, sheet_domain: str) -> RuntimePolicy:
    stem = Path(filename).stem

    if stem.startswith("ocean_dark_water"):
        return RuntimePolicy(
            domain="terrain", subdir="terrain/ocean", kind="terrain", subkind="ocean_water",
            canvas_tiles=(1, 1), footprint_tiles=(1, 1), anchor="center", y_sort=False,
            draw_order="terrain_floor", walkable=False, blocks_movement=True,
            blocks_projectiles=False, collision_kind="tile", tags=("ocean", "hazard", "water", "sundered_keep"),
        )
    if stem.startswith("ocean_foam_edge"):
        direction = stem.rsplit("_", 1)[-1]
        return RuntimePolicy(
            domain="terrain", subdir="terrain/ocean", kind="terrain", subkind="ocean_foam_edge",
            canvas_tiles=(1, 1), footprint_tiles=(1, 1), anchor="center", y_sort=False,
            draw_order="terrain_overlay", walkable=False, blocks_movement=True,
            blocks_projectiles=False, collision_kind="tile", tags=("ocean", "foam", f"dir_{direction}", "sundered_keep"),
        )
    if stem.startswith("cliff_"):
        if "face_slice" in stem:
            subkind = "cliff_face_slice"
            tags = ("cliff", "vertical_face", "drop", "sundered_keep")
        elif "inner_corner" in stem:
            subkind = "cliff_inner_corner"
            tags = ("cliff", "corner", "inner_corner", "drop", "sundered_keep")
        elif "outer_corner" in stem:
            subkind = "cliff_outer_corner"
            tags = ("cliff", "corner", "outer_corner", "drop", "sundered_keep")
        else:
            subkind = "cliff_edge"
            tags = ("cliff", "edge", "drop", "sundered_keep")
        return RuntimePolicy(
            domain="terrain", subdir="terrain/cliffs", kind="terrain", subkind=subkind,
            canvas_tiles=(2, 3), footprint_tiles=(2, 1), anchor="bottom_center",
            y_sort=True, draw_order="terrain_wall", walkable=False,
            blocks_movement=True, blocks_projectiles=True, collision_kind="terrain_drop",
            tags=tags,
        )

    if stem.startswith("main_gate_portcullis"):
        is_open = stem.endswith("_open")
        return RuntimePolicy(
            domain="doors_traversal", subdir="doors_traversal/gates", kind="door", subkind="main_gate_portcullis",
            canvas_tiles=(4, 4), footprint_tiles=(4, 1), anchor="bottom_center",
            draw_order="architecture", walkable=is_open, blocks_movement=not is_open,
            blocks_projectiles=not is_open, collision_kind="gate_threshold",
            traversal="gate_open" if is_open else None, interactable=True,
            tags=("gate", "portcullis", "open" if is_open else "closed", "sundered_keep"),
        )
    if stem.startswith("gothic_double_door"):
        is_open = "_open_" in stem
        facing = stem.rsplit("_", 1)[-1]
        return RuntimePolicy(
            domain="doors_traversal", subdir="doors_traversal/doors", kind="door", subkind="gothic_double_door",
            canvas_tiles=(3, 4), footprint_tiles=(3, 1), anchor="bottom_center",
            draw_order="architecture", walkable=is_open, blocks_movement=not is_open,
            blocks_projectiles=not is_open, collision_kind="door_threshold",
            traversal="door_open" if is_open else None, interactable=True,
            tags=("door", "gothic", f"facing_{facing}", "open" if is_open else "closed", "sundered_keep"),
        )
    if stem.startswith("stone_stairs"):
        direction = stem.rsplit("_", 1)[-1]
        stair_dir = "up" if "stairs_up" in stem else "down"
        return RuntimePolicy(
            domain="doors_traversal", subdir="doors_traversal/stairs", kind="traversal", subkind=f"stone_stairs_{stair_dir}",
            canvas_tiles=(2, 2), footprint_tiles=(2, 2), anchor="bottom_center",
            draw_order="traversal", walkable=True, blocks_movement=False,
            blocks_projectiles=False, collision_kind="none", traversal=f"stairs_{stair_dir}",
            interactable=False, tags=("stairs", stair_dir, f"dir_{direction}", "sundered_keep"),
        )
    if stem.startswith("floor_hatch"):
        is_open = stem.endswith("open_01")
        return RuntimePolicy(
            domain="doors_traversal", subdir="doors_traversal/hatches", kind="traversal", subkind="floor_hatch",
            canvas_tiles=(2, 2), footprint_tiles=(2, 2), anchor="center",
            draw_order="traversal", walkable=True, blocks_movement=False,
            blocks_projectiles=False, collision_kind="none", traversal="hatch_down" if is_open else None,
            interactable=True, tags=("hatch", "open" if is_open else "closed", "sundered_keep"),
        )

    # Props: specific footprint/canvas overrides.
    prop_sizes: Dict[str, Tuple[Tuple[int, int], Tuple[int, int], str, bool, Tuple[str, ...]]] = {
        "prop_courtyard_fountain_broken_01": ((3, 3), (3, 3), "prop_large", True, ("courtyard", "fountain", "broken")),
        "prop_gothic_statue_broken_01": ((2, 3), (1, 1), "prop_tall", True, ("statue", "broken")),
        "prop_gothic_statue_intact_01": ((2, 3), (1, 1), "prop_tall", True, ("statue", "intact")),
        "prop_broken_cart_01": ((3, 2), (3, 2), "prop_medium", True, ("cart", "broken")),
        "prop_crate_stack_wet_01": ((3, 2), (2, 2), "prop_storage", True, ("crate", "storage", "wet")),
        "prop_barrel_wet_01": ((1, 2), (1, 1), "prop_storage", True, ("barrel", "wet")),
        "prop_fallen_masonry_01": ((3, 2), (3, 2), "prop_rubble", True, ("masonry", "rubble")),
        "prop_low_garden_wall_01": ((3, 1), (3, 1), "prop_wall_low", True, ("garden_wall", "cover_low")),
        "prop_gate_winch_01": ((2, 2), (2, 2), "prop_mechanical", True, ("winch", "gate")),
        "prop_portcullis_chain_01": ((1, 3), (1, 1), "prop_hanging", False, ("chain", "portcullis")),
        "prop_gate_barricade_01": ((3, 2), (3, 1), "prop_barrier", True, ("barricade", "gate", "cover")),
        "prop_torch_wall_gothic_01": ((1, 2), (1, 1), "prop_light", False, ("torch", "light", "wall")),
        "prop_banquet_table_long_01": ((5, 3), (5, 2), "prop_table", True, ("table", "banquet", "great_hall")),
        "prop_banquet_table_broken_01": ((5, 3), (5, 2), "prop_table", True, ("table", "broken", "great_hall")),
        "prop_great_hall_column_01": ((1, 3), (1, 1), "prop_column", True, ("column", "great_hall")),
        "prop_fallen_chandelier_01": ((3, 2), (3, 2), "prop_debris", True, ("chandelier", "fallen", "debris")),
        "prop_throne_ruined_01": ((2, 3), (2, 2), "prop_throne", True, ("throne", "ruined")),
        "prop_brazier_iron_01": ((2, 2), (1, 1), "prop_light", True, ("brazier", "fire", "light")),
        "prop_banner_torn_large_01": ((2, 3), (1, 1), "prop_hanging", False, ("banner", "torn", "decor")),
        "prop_gargoyle_perch_01": ((2, 3), (1, 1), "prop_statue", True, ("gargoyle", "perch")),
        "prop_lightning_rod_01": ((1, 3), (1, 1), "prop_rooftop", True, ("lightning_rod", "rooftop")),
        "prop_rope_bridge_anchor_01": ((2, 2), (2, 2), "prop_anchor", True, ("rope_bridge", "anchor")),
        "prop_sea_spray_rock_01": ((3, 2), (3, 2), "prop_rock", True, ("sea_spray", "rock", "coastal")),
        "prop_broken_spire_chunk_01": ((2, 3), (2, 2), "prop_rubble", True, ("spire", "broken", "rubble")),
        "prop_bookshelf_tall_01": ((2, 3), (1, 1), "prop_furniture", True, ("bookshelf", "library")),
        "prop_chapel_pew_01": ((3, 2), (3, 1), "prop_furniture", True, ("chapel", "pew")),
        "prop_sarcophagus_01": ((4, 2), (4, 2), "prop_tomb", True, ("sarcophagus", "tomb", "chapel")),
        "prop_telescope_broken_01": ((3, 2), (2, 2), "prop_observatory", True, ("telescope", "broken", "observatory")),
    }
    if stem in prop_sizes:
        canvas_tiles, footprint_tiles, subkind, solid, tags = prop_sizes[stem]
    else:
        canvas_tiles, footprint_tiles, subkind, solid, tags = ((2, 2), (1, 1), "prop", True, ())
    return RuntimePolicy(
        domain="props", subdir=f"props/{subkind}", kind="prop", subkind=subkind,
        canvas_tiles=canvas_tiles, footprint_tiles=footprint_tiles, anchor="bottom_center",
        y_sort=True, draw_order="prop", walkable=not solid, blocks_movement=solid,
        blocks_projectiles=solid, collision_kind="rect_footprint" if solid else "none",
        interactable=False, tags=tuple(tags) + ("sundered_keep",),
    )

# ---------------------------------------------------------------------------
# Geometry / extraction helpers
# ---------------------------------------------------------------------------

@dataclasses.dataclass
class Component:
    x1: int
    y1: int
    x2: int
    y2: int
    area: int

    @property
    def w(self) -> int:
        return self.x2 - self.x1

    @property
    def h(self) -> int:
        return self.y2 - self.y1

    @property
    def cx(self) -> float:
        return (self.x1 + self.x2) / 2.0

    @property
    def cy(self) -> float:
        return (self.y1 + self.y2) / 2.0

    def as_xywh(self) -> List[int]:
        return [int(self.x1), int(self.y1), int(self.w), int(self.h)]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def odd_filter_size(radius: int) -> int:
    radius = max(1, int(radius))
    size = radius * 2 + 1
    if size % 2 == 0:
        size += 1
    return size


def dilate_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask.astype(bool)
    img = Image.fromarray((mask.astype(np.uint8) * 255), mode="L")
    img = img.filter(ImageFilter.MaxFilter(odd_filter_size(radius)))
    return np.asarray(img) > 0


def erode_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask.astype(bool)
    img = Image.fromarray((mask.astype(np.uint8) * 255), mode="L")
    img = img.filter(ImageFilter.MinFilter(odd_filter_size(radius)))
    return np.asarray(img) > 0


def remove_checkerboard_background(img: Image.Image, bg_tolerance: int = 24) -> Tuple[Image.Image, np.ndarray, List[List[int]]]:
    """Return RGBA image with detected checkerboard/background made transparent."""
    rgba_img = img.convert("RGBA")
    arr = np.asarray(rgba_img).copy()
    alpha = arr[..., 3]

    # If true transparency exists, trust it.
    transparent_ratio = float(np.mean(alpha < 220))
    if transparent_ratio > 0.03:
        fg = alpha > 20
        arr[~fg, 3] = 0
        return Image.fromarray(arr, mode="RGBA"), fg, []

    rgb = arr[..., :3].astype(np.int16)
    h, w = alpha.shape

    # Quantize to suppress tiny antialias variations, then find the dominant
    # high-luminance, low-saturation checkerboard colors.
    q = ((rgb // 8) * 8).astype(np.uint8)
    flat = q.reshape((-1, 3))
    colors, counts = np.unique(flat, axis=0, return_counts=True)
    order = np.argsort(-counts)

    bg_candidates: List[np.ndarray] = []
    for idx in order[:120]:
        c = colors[idx].astype(np.int16)
        lum = float(np.mean(c))
        sat = int(max(c) - min(c))
        # Generated sheets use light/gray checkerboard; this avoids eating
        # darker stone while still removing white/gray background squares.
        if lum >= 168 and sat <= 18:
            bg_candidates.append(c)
        if len(bg_candidates) >= 10:
            break

    # Border fallback. The background should dominate all image borders.
    if not bg_candidates:
        border = np.concatenate([q[0, :, :], q[-1, :, :], q[:, 0, :], q[:, -1, :]], axis=0)
        bcolors, bcounts = np.unique(border, axis=0, return_counts=True)
        border_order = np.argsort(-bcounts)
        for idx in border_order[:8]:
            c = bcolors[idx].astype(np.int16)
            if float(np.mean(c)) >= 150 and int(max(c) - min(c)) <= 30:
                bg_candidates.append(c)

    # Last-resort candidates for common checkerboard palettes.
    if not bg_candidates:
        bg_candidates = [np.array([248, 248, 248], dtype=np.int16), np.array([224, 224, 224], dtype=np.int16)]

    bg = np.zeros((h, w), dtype=bool)
    for c in bg_candidates:
        dist = np.max(np.abs(rgb - c.reshape((1, 1, 3))), axis=2)
        bg |= dist <= bg_tolerance

    fg = ~bg
    # Smooth single-pixel background/foreground flecks without destroying small highlights.
    fg = dilate_mask(erode_mask(fg, 1), 1)
    arr[~fg, 3] = 0
    return Image.fromarray(arr, mode="RGBA"), fg, [c.astype(int).tolist() for c in bg_candidates]


class DSU:
    def __init__(self) -> None:
        self.parent: List[int] = []
        self.rank: List[int] = []

    def add(self) -> int:
        idx = len(self.parent)
        self.parent.append(idx)
        self.rank.append(0)
        return idx

    def find(self, x: int) -> int:
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a: int, b: int) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return
        if self.rank[ra] < self.rank[rb]:
            self.parent[ra] = rb
        elif self.rank[ra] > self.rank[rb]:
            self.parent[rb] = ra
        else:
            self.parent[rb] = ra
            self.rank[ra] += 1


def connected_components_rle(mask: np.ndarray, min_area: int = 96) -> List[Component]:
    """Connected components via row-runs. Much faster than pixel BFS in pure Python."""
    h, _w = mask.shape
    dsu = DSU()
    runs: List[Tuple[int, int, int, int]] = []  # y, x1, x2 inclusive, id
    prev_runs: List[Tuple[int, int, int, int]] = []

    for y in range(h):
        xs = np.flatnonzero(mask[y])
        curr_runs: List[Tuple[int, int, int, int]] = []
        if xs.size:
            splits = np.where(np.diff(xs) > 1)[0] + 1
            parts = np.split(xs, splits)
            for part in parts:
                x1 = int(part[0])
                x2 = int(part[-1])
                rid = dsu.add()
                curr_runs.append((y, x1, x2, rid))
                runs.append((y, x1, x2, rid))

            # Connect overlapping/adjacent runs from previous row.
            p = 0
            for _y, x1, x2, rid in curr_runs:
                while p < len(prev_runs) and prev_runs[p][2] < x1 - 1:
                    p += 1
                q = p
                while q < len(prev_runs) and prev_runs[q][1] <= x2 + 1:
                    dsu.union(rid, prev_runs[q][3])
                    q += 1
        prev_runs = curr_runs

    stats: Dict[int, List[int]] = {}
    # root -> [x1, y1, x2_excl, y2_excl, area]
    for y, x1, x2, rid in runs:
        root = dsu.find(rid)
        area = x2 - x1 + 1
        if root not in stats:
            stats[root] = [x1, y, x2 + 1, y + 1, area]
        else:
            s = stats[root]
            s[0] = min(s[0], x1)
            s[1] = min(s[1], y)
            s[2] = max(s[2], x2 + 1)
            s[3] = max(s[3], y + 1)
            s[4] += area

    comps = [Component(*s) for s in stats.values() if s[4] >= min_area]
    return comps


def sort_components_reading_order(components: Sequence[Component]) -> List[Component]:
    if not components:
        return []
    heights = np.array([c.h for c in components], dtype=float)
    median_h = float(np.median(heights))
    row_tol = max(50.0, min(150.0, median_h * 0.72))

    rows: List[List[Component]] = []
    row_centers: List[float] = []
    for comp in sorted(components, key=lambda c: c.cy):
        if not rows:
            rows.append([comp])
            row_centers.append(comp.cy)
            continue
        # Assign to nearest existing row center if close enough.
        distances = [abs(comp.cy - cy) for cy in row_centers]
        nearest_idx = int(np.argmin(distances))
        if distances[nearest_idx] <= row_tol:
            rows[nearest_idx].append(comp)
            row_centers[nearest_idx] = float(np.mean([c.cy for c in rows[nearest_idx]]))
        else:
            rows.append([comp])
            row_centers.append(comp.cy)

    order = np.argsort(row_centers)
    sorted_components: List[Component] = []
    for idx in order:
        sorted_components.extend(sorted(rows[int(idx)], key=lambda c: c.cx))
    return sorted_components


def content_bbox_from_mask(mask: np.ndarray, bbox: Component, pad: int, image_size: Tuple[int, int]) -> Component:
    sub = mask[bbox.y1:bbox.y2, bbox.x1:bbox.x2]
    ys, xs = np.nonzero(sub)
    w, h = image_size
    if len(xs) == 0 or len(ys) == 0:
        return bbox
    x1 = max(0, bbox.x1 + int(xs.min()) - pad)
    y1 = max(0, bbox.y1 + int(ys.min()) - pad)
    x2 = min(w, bbox.x1 + int(xs.max()) + 1 + pad)
    y2 = min(h, bbox.y1 + int(ys.max()) + 1 + pad)
    return Component(x1, y1, x2, y2, int(len(xs)))


def fit_to_runtime_canvas(src: Image.Image, target_px: Tuple[int, int], anchor: str, inner_padding_px: int) -> Tuple[Image.Image, Dict[str, Any]]:
    src = src.convert("RGBA")
    src_arr = np.asarray(src)
    alpha = src_arr[..., 3]
    ys, xs = np.nonzero(alpha > 0)
    if len(xs) == 0 or len(ys) == 0:
        trimmed = src
        content_bbox_src = [0, 0, src.width, src.height]
    else:
        x1, x2 = int(xs.min()), int(xs.max()) + 1
        y1, y2 = int(ys.min()), int(ys.max()) + 1
        trimmed = src.crop((x1, y1, x2, y2))
        content_bbox_src = [x1, y1, x2 - x1, y2 - y1]

    target_w, target_h = target_px
    fit_w = max(1, target_w - 2 * inner_padding_px)
    fit_h = max(1, target_h - 2 * inner_padding_px)
    scale = min(fit_w / max(1, trimmed.width), fit_h / max(1, trimmed.height))
    # Never upscale more than 1.0 by default; generated images are oversized.
    scale = min(scale, 1.0)
    new_w = max(1, int(round(trimmed.width * scale)))
    new_h = max(1, int(round(trimmed.height * scale)))
    resized = trimmed.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    if anchor == "center":
        paste_x = (target_w - new_w) // 2
        paste_y = (target_h - new_h) // 2
        pivot = [target_w // 2, target_h // 2]
    elif anchor == "top_left":
        paste_x = inner_padding_px
        paste_y = inner_padding_px
        pivot = [0, 0]
    else:  # bottom_center
        paste_x = (target_w - new_w) // 2
        paste_y = target_h - inner_padding_px - new_h
        pivot = [target_w // 2, target_h - inner_padding_px]
    canvas.alpha_composite(resized, (paste_x, paste_y))

    # Runtime content bbox after paste.
    c_alpha = np.asarray(canvas)[..., 3]
    cys, cxs = np.nonzero(c_alpha > 0)
    if len(cxs) == 0 or len(cys) == 0:
        content_bbox_runtime = [0, 0, 0, 0]
    else:
        rx1, rx2 = int(cxs.min()), int(cxs.max()) + 1
        ry1, ry2 = int(cys.min()), int(cys.max()) + 1
        content_bbox_runtime = [rx1, ry1, rx2 - rx1, ry2 - ry1]

    return canvas, {
        "source_content_bbox_px": content_bbox_src,
        "runtime_content_bbox_px": content_bbox_runtime,
        "scale_from_source_crop": scale,
        "paste_offset_px": [paste_x, paste_y],
        "pivot_px": pivot,
        "pivot_normalized": [round(pivot[0] / target_w, 4), round(pivot[1] / target_h, 4)],
    }


def footprint_cells(w_tiles: int, h_tiles: int) -> List[Dict[str, int]]:
    return [{"x": x, "y": y} for y in range(h_tiles) for x in range(w_tiles)]


def direction_from_name(stem: str) -> Optional[str]:
    for suffix in ("_ne", "_nw", "_se", "_sw", "_n", "_e", "_s", "_w"):
        if stem.endswith(suffix):
            return suffix[1:]
    return None


def state_from_name(stem: str) -> Optional[str]:
    if "_closed" in stem:
        return "closed"
    if "_open" in stem:
        return "open"
    if "broken" in stem or "ruined" in stem:
        return "broken"
    if "intact" in stem:
        return "intact"
    return None


def build_metadata(
    *,
    asset_filename: str,
    sheet_spec: SheetSpec,
    sheet_path: Path,
    source_hash: str,
    sheet_index: int,
    sheet_bbox: Component,
    source_crop_bbox: Component,
    runtime_path: Path,
    metadata_path: Path,
    godot_root: Path,
    policy: RuntimePolicy,
    norm_info: Dict[str, Any],
    bg_candidates: List[List[int]],
    extraction_args: argparse.Namespace,
) -> Dict[str, Any]:
    stem = Path(asset_filename).stem
    canvas_px = [policy.canvas_tiles[0] * BASE_TILE_PX, policy.canvas_tiles[1] * BASE_TILE_PX]
    footprint = footprint_cells(policy.footprint_tiles[0], policy.footprint_tiles[1])
    runtime_rel = runtime_path.relative_to(godot_root).as_posix()
    metadata_rel = metadata_path.relative_to(godot_root).as_posix()

    return {
        "schema": SCHEMA,
        "asset_id": f"sundered_keep/{stem}",
        "name": stem,
        "filename": asset_filename,
        "set": "sundered_keep",
        "theme": "renaissance_gothic_castle_oceanscape_haunted_temporally_adrift",
        "created_utc": _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat(),
        "source": {
            "sheet_key": sheet_spec.key,
            "sheet_file": sheet_path.name,
            "sheet_path": str(sheet_path.expanduser()),
            "sheet_sha256": source_hash,
            "sheet_asset_index": sheet_index,
            "sheet_bbox_px": sheet_bbox.as_xywh(),
            "source_crop_bbox_px": source_crop_bbox.as_xywh(),
            "detected_background_colors_rgb": bg_candidates,
            "extraction_method": {
                "background": "alpha_or_checkerboard_dominant_color_removal",
                "component_join_radius_px": extraction_args.join_radius,
                "crop_padding_px": extraction_args.crop_padding,
                "min_component_area_px": extraction_args.min_component_area,
            },
        },
        "runtime": {
            "base_tile_px": BASE_TILE_PX,
            "path": f"res://{runtime_rel}",
            "metadata_path": f"res://{metadata_rel}",
            "domain": policy.domain,
            "kind": policy.kind,
            "subkind": policy.subkind,
            "canvas_px": canvas_px,
            "canvas_tiles": list(policy.canvas_tiles),
            "content_bbox_px": norm_info["runtime_content_bbox_px"],
            "scale_from_source_crop": norm_info["scale_from_source_crop"],
            "paste_offset_px": norm_info["paste_offset_px"],
            "anchor": policy.anchor,
            "pivot_px": norm_info["pivot_px"],
            "pivot_normalized": norm_info["pivot_normalized"],
            "y_sort": policy.y_sort,
            "draw_order": policy.draw_order,
            "godot_import_hints": {
                "filter": False,
                "mipmaps": False,
                "repeat": False,
                "compress_mode": "lossless",
                "pixel_snap": True,
            },
        },
        "gameplay": {
            "walkable": policy.walkable,
            "interactable": policy.interactable,
            "traversal": policy.traversal,
            "direction": direction_from_name(stem),
            "state": state_from_name(stem),
            "tags": list(policy.tags),
        },
        "collision": {
            "kind": policy.collision_kind,
            "blocks_movement": policy.blocks_movement,
            "blocks_projectiles": policy.blocks_projectiles,
            "footprint_tiles_wh": list(policy.footprint_tiles),
            "footprint_cells": footprint,
            "origin_tile": {"x": 0, "y": 0, "anchor": policy.anchor},
        },
        "editor": {
            "display_name": stem.replace("_", " ").title(),
            "notes": "Generated from Sundered Keep master sheet; adjust footprint/collision after in-editor placement review if needed.",
        },
    }

# ---------------------------------------------------------------------------
# Sheet resolution, docs check, output helpers
# ---------------------------------------------------------------------------


def find_godot_root(arg_root: Optional[str]) -> Path:
    if arg_root:
        root = Path(arg_root).expanduser().resolve()
    elif os.environ.get("CUSTODIAN_GODOT_ROOT"):
        root = Path(os.environ["CUSTODIAN_GODOT_ROOT"]).expanduser().resolve()
    else:
        cwd = Path.cwd().resolve()
        candidates = [cwd] + list(cwd.parents) + [Path("~/Projects/CUSTODIAN/custodian").expanduser()]
        root = None  # type: ignore[assignment]
        for c in candidates:
            if (c / "project.godot").exists() or (c / "content").exists() and c.name == "custodian":
                root = c
                break
        if root is None:
            root = Path("~/Projects/CUSTODIAN/custodian").expanduser().resolve()
    return root


def resolve_sheet_path(masters_dir: Path, spec: SheetSpec, explicit: Optional[str] = None, used: Optional[set] = None) -> Optional[Path]:
    used = used or set()
    candidates = [explicit] if explicit else list(spec.candidates)
    for name in candidates:
        if not name:
            continue
        path = (masters_dir / name).expanduser()
        if path.exists() and path.resolve() not in used:
            return path.resolve()
    return None


def write_json(path: Path, obj: Any, dry_run: bool) -> None:
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def rel_res_path(path: Path, godot_root: Path) -> str:
    return "res://" + path.relative_to(godot_root).as_posix()


def safe_remove_previous_outputs(out_dir: Path, dry_run: bool) -> None:
    # Only remove files generated by this script under the sundered_keep runtime dir.
    if not out_dir.exists() or dry_run:
        return
    for p in out_dir.rglob("*"):
        if p.is_file() and (p.suffix.lower() in {".json", ".png", ".gd", ".md"}):
            marker_ok = False
            if p.suffix.lower() == ".json":
                try:
                    txt = p.read_text(encoding="utf-8", errors="ignore")[:500]
                    marker_ok = "game32" in txt or "sundered_keep" in txt
                except Exception:
                    marker_ok = False
            elif p.name in {"sundered_keep_game32_assets.gd", "_extraction_review.png", "_doc_drift_review.md"}:
                marker_ok = True
            # Runtime PNGs live in controlled generated folders; keep this conservative.
            if p.suffix.lower() == ".png" and "content/runtime/sundered_keep" in p.as_posix():
                marker_ok = True
            if marker_ok:
                p.unlink()


def create_review_overlay(sheet_img: Image.Image, comps: Sequence[Component], out_path: Path, dry_run: bool) -> None:
    if dry_run:
        return
    overlay = sheet_img.convert("RGBA")
    draw = ImageDraw.Draw(overlay)
    for idx, c in enumerate(comps):
        draw.rectangle((c.x1, c.y1, c.x2 - 1, c.y2 - 1), outline=(255, 64, 64, 255), width=3)
        draw.text((c.x1 + 4, c.y1 + 4), str(idx), fill=(255, 255, 0, 255))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    overlay.save(out_path)


def generate_gd_registry(assets: List[Dict[str, Any]], godot_root: Path, out_path: Path, dry_run: bool) -> None:
    lines = [
        "# Generated by extract_sundered_keep_game32.py. Do not hand-edit generated entries.",
        "extends RefCounted",
        "",
        f"const BASE_TILE_PX := {BASE_TILE_PX}",
        'const SET_ID := "sundered_keep"',
        "const ASSETS := {",
    ]
    for asset in assets:
        name = asset["name"]
        runtime_path = asset["runtime"]["path"]
        meta_path = asset["runtime"]["metadata_path"]
        kind = asset["runtime"]["kind"]
        subkind = asset["runtime"]["subkind"]
        walkable = "true" if asset["gameplay"]["walkable"] else "false"
        blocks = "true" if asset["collision"]["blocks_movement"] else "false"
        lines.append(f'\t"{name}": {{')
        lines.append(f'\t\t"texture": "{runtime_path}",')
        lines.append(f'\t\t"metadata": "{meta_path}",')
        lines.append(f'\t\t"kind": "{kind}",')
        lines.append(f'\t\t"subkind": "{subkind}",')
        lines.append(f'\t\t"walkable": {walkable},')
        lines.append(f'\t\t"blocks_movement": {blocks},')
        lines.append("\t},")
    lines.append("}")
    lines.append("")
    if not dry_run:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text("\n".join(lines), encoding="utf-8")


def doc_drift_check(project_root: Path, godot_root: Path, out_dir: Path, generated_count: int, dry_run: bool) -> Dict[str, Any]:
    repo_root = godot_root.parent if godot_root.name == "custodian" else project_root
    agents = repo_root / "AGENTS.md"
    current_state = godot_root / "docs" / "ai_context" / "CURRENT_STATE.md"
    context_doc = godot_root / "docs" / "ai_context" / "CONTEXT.md"
    file_index = godot_root / "docs" / "ai_context" / "FILE_INDEX.md"

    checks: List[Dict[str, Any]] = []
    def check_file(path: Path, label: str) -> str:
        exists = path.exists()
        checks.append({"label": label, "path": str(path), "exists": exists})
        return path.read_text(encoding="utf-8", errors="ignore") if exists else ""

    agents_txt = check_file(agents, "repo_guidance")
    current_txt = check_file(current_state, "active_ai_context_current_state")
    context_txt = check_file(context_doc, "active_ai_context_context")
    file_index_txt = check_file(file_index, "active_ai_context_file_index")

    drift: List[str] = []
    if agents.exists() and "Active gameplay/runtime code: `custodian/`" not in agents_txt:
        drift.append("AGENTS.md exists, but expected active runtime wording was not found. Verify repo guidance before wiring these assets.")
    if current_state.exists() and "sundered_keep" not in current_txt.lower() and "sundered keep" not in current_txt.lower():
        drift.append("CURRENT_STATE.md does not appear to mention the generated Sundered Keep runtime asset set.")
    if file_index.exists() and "content/runtime/sundered_keep" not in file_index_txt:
        drift.append("FILE_INDEX.md does not appear to list content/runtime/sundered_keep outputs.")
    if context_doc.exists() and "masters/sundered_keep" not in context_txt and "sundered_keep" not in context_txt.lower():
        drift.append("CONTEXT.md may not mention the Sundered Keep master/runtime asset workflow.")

    report = {
        "checked_at_utc": _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat(),
        "generated_asset_count": generated_count,
        "checks": checks,
        "potential_drift": drift,
        "recommended_action": (
            "Add a short note to custodian/docs/ai_context/CURRENT_STATE.md and FILE_INDEX.md that "
            "Sundered Keep masters live under content/masters/sundered_keep and generated runtime slices/metadata live under "
            "content/runtime/sundered_keep. This is an asset-pipeline update, not a gameplay behavior change."
        ),
    }

    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
        md = [
            "# Sundered Keep game32 extraction: documentation drift review",
            "",
            f"Generated assets: `{generated_count}`",
            "",
            "## Checks",
        ]
        for c in checks:
            status = "OK" if c["exists"] else "MISSING"
            md.append(f"- `{status}` — {c['label']}: `{c['path']}`")
        md.extend(["", "## Potential drift"])
        if drift:
            md.extend([f"- {d}" for d in drift])
        else:
            md.append("- No obvious documentation drift detected from lightweight path/content checks.")
        md.extend(["", "## Recommended action", report["recommended_action"], ""])
        (out_dir / "_doc_drift_review.md").write_text("\n".join(md), encoding="utf-8")
        write_json(out_dir / "_doc_drift_review.json", report, dry_run=False)
    return report

# ---------------------------------------------------------------------------
# Main extraction path
# ---------------------------------------------------------------------------


def extract_sheet(
    *,
    spec: SheetSpec,
    sheet_path: Path,
    godot_root: Path,
    out_root: Path,
    review_dir: Path,
    args: argparse.Namespace,
) -> List[Dict[str, Any]]:
    print(f"[sheet] {spec.key}: {sheet_path}")
    raw = Image.open(sheet_path)
    de_bg, fg_mask, bg_candidates = remove_checkerboard_background(raw, bg_tolerance=args.bg_tolerance)

    seg_mask = dilate_mask(fg_mask, args.join_radius)
    comps = connected_components_rle(seg_mask, min_area=args.min_component_area)
    comps = sort_components_reading_order(comps)

    create_review_overlay(raw, comps, review_dir / f"{spec.key}_detected_bboxes.png", args.dry_run)

    expected = len(spec.assets)
    if len(comps) != expected:
        msg = (
            f"Detected {len(comps)} components for {sheet_path.name}, expected {expected}.\n"
            f"Review overlay: {review_dir / (spec.key + '_detected_bboxes.png')}\n"
            "Try adjusting --join-radius, --min-component-area, or pass the correct sheet filename."
        )
        if args.allow_count_mismatch:
            print(f"[warn] {msg}")
            if len(comps) < expected:
                print(f"[warn] Too few components; only first {len(comps)} assets will be written.")
        else:
            raise RuntimeError(msg)

    source_hash = sha256_file(sheet_path)
    assets_written: List[Dict[str, Any]] = []
    count = min(len(comps), expected)
    de_bg_arr = np.asarray(de_bg)
    clean_img = Image.fromarray(de_bg_arr, mode="RGBA")

    for i in range(count):
        asset_name = spec.assets[i]
        policy = policy_for(asset_name, spec.default_domain)
        sheet_bbox = comps[i]
        crop_bbox = content_bbox_from_mask(fg_mask, sheet_bbox, args.crop_padding, clean_img.size)
        crop = clean_img.crop((crop_bbox.x1, crop_bbox.y1, crop_bbox.x2, crop_bbox.y2))

        target_px = (policy.canvas_tiles[0] * BASE_TILE_PX, policy.canvas_tiles[1] * BASE_TILE_PX)
        runtime_img, norm_info = fit_to_runtime_canvas(crop, target_px, policy.anchor, args.inner_padding)

        runtime_dir = out_root / policy.subdir
        runtime_path = runtime_dir / asset_name
        metadata_path = runtime_path.with_suffix(".game32.json")

        metadata = build_metadata(
            asset_filename=asset_name,
            sheet_spec=spec,
            sheet_path=sheet_path,
            source_hash=source_hash,
            sheet_index=i,
            sheet_bbox=sheet_bbox,
            source_crop_bbox=crop_bbox,
            runtime_path=runtime_path,
            metadata_path=metadata_path,
            godot_root=godot_root,
            policy=policy,
            norm_info=norm_info,
            bg_candidates=bg_candidates,
            extraction_args=args,
        )

        if args.dry_run:
            print(f"  [dry] {i:02d} {asset_name} -> {rel_res_path(runtime_path, godot_root)} {target_px}")
        else:
            runtime_dir.mkdir(parents=True, exist_ok=True)
            runtime_img.save(runtime_path)
            write_json(metadata_path, metadata, dry_run=False)
            print(f"  [ok] {i:02d} {asset_name} -> {rel_res_path(runtime_path, godot_root)}")
        assets_written.append(metadata)

    return assets_written


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract Sundered Keep generated sheets into game32 runtime assets.")
    parser.add_argument("--godot-root", default=None, help="Path to Godot project root, default ~/Projects/CUSTODIAN/custodian or cwd autodetect.")
    parser.add_argument("--masters-dir", default=None, help="Master sheet directory. Default: <godot-root>/content/masters/sundered_keep")
    parser.add_argument("--out-dir", default=None, help="Output runtime directory. Default: <godot-root>/content/runtime/sundered_keep")
    parser.add_argument("--terrain-sheet", default=None, help="Explicit terrain cliffs/ocean sheet filename or path.")
    parser.add_argument("--doors-sheet", default=None, help="Explicit doors/traversal sheet filename or path.")
    parser.add_argument("--tables-crates-sheet", default=None, help="Explicit first props sheet filename or path.")
    parser.add_argument("--caskets-misc-sheet", default=None, help="Explicit second props sheet filename or path.")
    parser.add_argument("--join-radius", type=int, default=18, help="Dilation radius used to join detached debris into one asset bbox.")
    parser.add_argument("--crop-padding", type=int, default=8, help="Transparent pixels retained around extracted source crop before normalization.")
    parser.add_argument("--inner-padding", type=int, default=2, help="Transparent pixels retained inside runtime canvas after scaling.")
    parser.add_argument("--bg-tolerance", type=int, default=24, help="RGB tolerance for checkerboard removal.")
    parser.add_argument("--min-component-area", type=int, default=900, help="Minimum component area after join/dilation.")
    parser.add_argument("--allow-count-mismatch", action="store_true", help="Write what was detected instead of failing on count mismatch.")
    parser.add_argument("--clean", action="store_true", help="Remove previous generated files under output dir before writing.")
    parser.add_argument("--dry-run", action="store_true", help="Print actions and write nothing.")
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    godot_root = find_godot_root(args.godot_root)
    masters_dir = Path(args.masters_dir).expanduser().resolve() if args.masters_dir else (godot_root / "content" / "masters" / "sundered_keep").resolve()
    out_root = Path(args.out_dir).expanduser().resolve() if args.out_dir else (godot_root / "content" / "runtime" / "sundered_keep").resolve()
    review_dir = out_root / "_extraction_review"

    print(f"[root] godot_root={godot_root}")
    print(f"[root] masters_dir={masters_dir}")
    print(f"[root] out_dir={out_root}")

    if not masters_dir.exists():
        print(f"[error] masters dir not found: {masters_dir}", file=sys.stderr)
        return 2
    if args.clean:
        print(f"[clean] {out_root}")
        safe_remove_previous_outputs(out_root, args.dry_run)

    explicit_by_key = {
        "terrain_cliffs_ocean": args.terrain_sheet,
        "doors_traversal": args.doors_sheet,
        "props_tables_crates": args.tables_crates_sheet,
        "props_caskets_misc": args.caskets_misc_sheet,
    }

    used_paths: set = set()
    resolved: List[Tuple[SheetSpec, Path]] = []
    for spec in SHEET_SPECS:
        explicit = explicit_by_key.get(spec.key)
        if explicit:
            p = Path(explicit).expanduser()
            if not p.is_absolute():
                p = masters_dir / p
            p = p.resolve()
            if not p.exists():
                raise FileNotFoundError(f"Explicit sheet for {spec.key} not found: {p}")
            path = p
        else:
            path = resolve_sheet_path(masters_dir, spec, used=used_paths)
        if path is None:
            candidate_list = ", ".join(spec.candidates)
            raise FileNotFoundError(
                f"Could not find required sheet for {spec.key}. Looked for: {candidate_list}. "
                f"Use --{spec.key.replace('_', '-')}-sheet or rename the source sheet."
            )
        if path in used_paths:
            raise RuntimeError(f"Sheet path reused for multiple specs, likely from duplicate filename typo: {path}")
        used_paths.add(path)
        resolved.append((spec, path))

    all_assets: List[Dict[str, Any]] = []
    try:
        for spec, sheet_path in resolved:
            all_assets.extend(
                extract_sheet(
                    spec=spec,
                    sheet_path=sheet_path,
                    godot_root=godot_root,
                    out_root=out_root,
                    review_dir=review_dir,
                    args=args,
                )
            )
    except Exception as exc:
        print(f"[error] {exc}", file=sys.stderr)
        return 1

    manifest = {
        "schema": MANIFEST_SCHEMA,
        "set": "sundered_keep",
        "base_tile_px": BASE_TILE_PX,
        "generated_at_utc": _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat(),
        "godot_root": str(godot_root),
        "masters_dir": str(masters_dir),
        "out_dir": str(out_root),
        "asset_count": len(all_assets),
        "sheets": [
            {
                "key": spec.key,
                "path": str(path),
                "filename": path.name,
                "expected_asset_count": len(spec.assets),
                "sha256": sha256_file(path),
            }
            for spec, path in resolved
        ],
        "assets": all_assets,
    }

    manifest_path = out_root / "game32_manifest.json"
    registry_path = out_root / "sundered_keep_game32_assets.gd"
    write_json(manifest_path, manifest, args.dry_run)
    generate_gd_registry(all_assets, godot_root, registry_path, args.dry_run)
    drift_report = doc_drift_check(godot_root.parent, godot_root, out_root, len(all_assets), args.dry_run)

    print(f"[done] assets={len(all_assets)}")
    if not args.dry_run:
        print(f"[done] manifest={rel_res_path(manifest_path, godot_root)}")
        print(f"[done] registry={rel_res_path(registry_path, godot_root)}")
        print(f"[done] review_dir={rel_res_path(review_dir, godot_root)}")
        if drift_report.get("potential_drift"):
            print("[docs] potential documentation drift found; see _doc_drift_review.md")
        else:
            print("[docs] no obvious documentation drift found")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
