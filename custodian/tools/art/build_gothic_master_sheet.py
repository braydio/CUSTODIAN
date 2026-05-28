#!/usr/bin/env python3
"""Build a single composite gothic master sheet + initial manifest from all gothic assets.

Collects every gothic PNG across all 10 content sections, arranges them on a single
composited sheet grouped by section, and generates a manifest with source rects and
all auto-detectable metadata. The manifest is in game32.v2 shape with placeholder
values marked for review.

Usage:
    python3 tools/art/build_gothic_master_sheet.py
    python3 tools/art/build_gothic_master_sheet.py --max-width 6144 --padding 4

Output:
    content/tiles/gothic/gothic_master_sheet.png
    content/tiles/gothic/gothic_master_sheet.game32.json
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

CONTENT_ROOT = Path(__file__).resolve().parent.parent.parent / "content"
OUTPUT_SHEET = CONTENT_ROOT / "tiles" / "gothic" / "gothic_master_sheet.png"
OUTPUT_MANIFEST = OUTPUT_SHEET.with_suffix(".game32.json")

# ── Sections in display order ──────────────────────────────────────────────
# (label, content-relative path, display color for section header)
SECTIONS: list[tuple[str, str, tuple[int, int, int]]] = [
    ("tiles",              "tiles/gothic",                               (60, 80, 60)),
    ("tiles_interiors",    "tiles/interiors/gothic",                     (70, 75, 55)),
    ("walls",              "walls/gothic",                               (80, 60, 60)),
    ("doors",              "doors/gothic",                               (70, 65, 50)),
    ("structures",         "structures/gothic",                          (60, 65, 80)),
    ("props",              "props/gothic",                               (75, 70, 55)),
    ("roads",              "tiles/roads_paths/runtime/roads/gothic",     (65, 75, 70)),
    ("road_compound",      "tiles/roads_paths/runtime/gothic_compound",  (55, 70, 65)),
    ("animations",         "animations/gothic",                          (80, 75, 60)),
    ("rooms",              "procgen/special_rooms/gothic_compound",      (60, 60, 70)),
]

# ── Default layout parameters ──────────────────────────────────────────────
DEFAULT_MAX_WIDTH = 4096      # max sheet width in px
DEFAULT_PADDING = 4           # px gap between assets
DEFAULT_SECTION_GAP = 24      # px gap between section bands
SECTION_HEADER_HEIGHT = 28    # px for the colored section label bar

# ── Subtype classification hints from directory name ───────────────────────
# Map directory name → game32 metadata hints
SUBTYPE_HINTS: dict[str, dict[str, Any]] = {
    # Tiles
    "floors": {
        "asset_type": "tiles",
        "semantic_role": "walkable_floor_variant",
        "placement_layer": "ground",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["floor", "walkable"],
    },
    "floor_overlay": {
        "asset_type": "tiles",
        "semantic_role": "floor_overlay_or_special_floor",
        "placement_layer": "ground_detail",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["floor", "overlay"],
    },
    "decals": {
        "asset_type": "tiles",
        "semantic_role": "floor_overlay_or_decal",
        "placement_layer": "ground_detail",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["decal", "floor"],
    },
    "wall_tiles": {
        "asset_type": "tiles",
        "semantic_role": "wall_tile_or_panel",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "tile"],
    },
    "wall_tops_edges": {
        "asset_type": "tiles",
        "semantic_role": "wall_cap_top_or_edge",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "cap", "edge"],
    },
    "wall_vertical_slice": {
        "asset_type": "walls",
        "semantic_role": "blocking_wall_vertical_slice",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "blocking", "vertical", "slice"],
    },
    "wall_corner_or_end": {
        "asset_type": "walls",
        "semantic_role": "blocking_wall_corner_or_connector",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "corner", "connector"],
    },
    "wall_horizontal_or_cap": {
        "asset_type": "walls",
        "semantic_role": "wall_cap_terminal_or_buttress",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "cap", "horizontal"],
    },
    # Walls
    "blocking_wall_vertical_slice": {
        "asset_type": "walls",
        "semantic_role": "blocking_wall_vertical_slice",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "blocking", "vertical", "slice"],
    },
    "wall_cap_terminal_or_buttress": {
        "asset_type": "walls",
        "semantic_role": "wall_cap_terminal_or_buttress",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "cap", "terminal"],
    },
    "blocking_wall_corner_or_connector": {
        "asset_type": "walls",
        "semantic_role": "blocking_wall_corner_or_connector",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "corner", "connector"],
    },
    "damaged_wall_or_partial_cover": {
        "asset_type": "walls",
        "semantic_role": "damaged_wall_or_partial_cover",
        "placement_layer": "wall",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["wall", "broken", "ruin", "cover"],
    },
    # Doors
    "compound_entrance_gate": {
        "asset_type": "doors",
        "semantic_role": "compound_entrance_gate",
        "placement_layer": "door",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["door", "gate", "archway", "entrance"],
    },
    "small_door_or_wall_insert": {
        "asset_type": "doors",
        "semantic_role": "small_door_or_wall_insert",
        "placement_layer": "door",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["door", "small", "insert"],
    },
    # Structures
    "large_compound_landmark": {
        "asset_type": "structures",
        "semantic_role": "large_compound_landmark",
        "placement_layer": "structure",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 3,
        "indoor": False,
        "outdoor": True,
        "tags": ["structure", "landmark", "building", "blocking"],
    },
    "landmark_or_building": {
        "asset_type": "structures",
        "semantic_role": "large_compound_landmark",
        "placement_layer": "structure",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 3,
        "indoor": False,
        "outdoor": True,
        "tags": ["structure", "landmark", "building"],
    },
    "building_or_large_gate": {
        "asset_type": "structures",
        "semantic_role": "large_compound_landmark",
        "placement_layer": "structure",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 3,
        "indoor": False,
        "outdoor": True,
        "tags": ["structure", "building", "gate"],
    },
    # Props
    "banner_or_hanging_cloth": {
        "asset_type": "props",
        "semantic_role": "compound_dressing_or_barrier",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "banner", "dressing"],
    },
    "barriers": {
        "asset_type": "props",
        "semantic_role": "rubble_cover_or_ruin_storytelling",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "barrier", "cover"],
    },
    "compound_dressing_or_barrier": {
        "asset_type": "props",
        "semantic_role": "compound_dressing_or_barrier",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "barrier", "dressing"],
    },
    "doors_gates": {
        "asset_type": "props",
        "semantic_role": "boundary_marker_or_soft_barrier",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "door", "gate", "boundary"],
    },
    "environment_prop": {
        "asset_type": "props",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "environment"],
    },
    "large_environment_prop": {
        "asset_type": "props",
        "semantic_role": "vertical_poi_or_light_source",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "large", "environment"],
    },
    "lights_effects": {
        "asset_type": "props",
        "semantic_role": "vertical_poi_or_light_source",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "light", "effect"],
    },
    "loot_cover_or_storage_prop": {
        "asset_type": "props",
        "semantic_role": "loot_cover_or_storage_prop",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "crate", "storage", "cover", "loot"],
    },
    "misc": {
        "asset_type": "props",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "misc"],
    },
    "organic_intrusion_blocker": {
        "asset_type": "props",
        "semantic_role": "organic_intrusion_blocker",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
        "indoor": False,
        "outdoor": True,
        "tags": ["prop", "tree", "organic", "blocking"],
    },
    "rubble": {
        "asset_type": "props",
        "semantic_role": "rubble_cover_or_ruin_storytelling",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "rubble", "ruin", "cover"],
    },
    "rubble_cover_or_ruin_storytelling": {
        "asset_type": "props",
        "semantic_role": "rubble_cover_or_ruin_storytelling",
        "placement_layer": "prop",
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 2,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "rubble", "ruin", "cover"],
    },
    "uncategorized_environment_asset": {
        "asset_type": "props",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["prop", "uncategorized", "needs_review"],
    },
    "vegetation": {
        "asset_type": "props",
        "semantic_role": "organic_intrusion_blocker",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": False,
        "outdoor": True,
        "tags": ["prop", "vegetation", "organic"],
    },
    # Roads
    "pieces": {
        "asset_type": "tiles",
        "semantic_role": "road_piece",
        "placement_layer": "ground",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": False,
        "outdoor": True,
        "tags": ["road", "path"],
    },
    "overlays": {
        "asset_type": "tiles",
        "semantic_role": "road_overlay",
        "placement_layer": "ground_detail",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": False,
        "outdoor": True,
        "tags": ["road", "overlay"],
    },
    # Rooms
    "gothic_compound": {
        "asset_type": "rooms",
        "semantic_role": "preauthored_room_blueprint",
        "placement_layer": "room",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["room", "blueprint", "gothic_compound"],
    },
}


# ── Helpers ─────────────────────────────────────────────────────────────────

def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip("_")


def load_font(size: int) -> ImageFont.ImageFont:
    candidates = (
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
    )
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def natural_sort_key(text: str) -> list[object]:
    return [int(part) if part.isdigit() else part for part in re.split(r"(\d+)", text.lower())]


def parse_game32_name(stem: str) -> dict[str, Any]:
    """Extract metadata from game32 naming convention: foo__Nf__WWxHH or foo__Nf__SS"""
    meta: dict[str, Any] = {}
    match = re.search(r"__(\d+)f__(\d+)(?:x(\d+))?$", stem)
    if match:
        meta["frame_count"] = int(match.group(1))
        fw = int(match.group(2))
        fh = int(match.group(3)) if match.group(3) else fw
        meta["frame_size"] = {"w": fw, "h": fh}
    return meta


def get_subtype_hint(subtype_key: str) -> dict[str, Any]:
    """Get the best matching subtype hint for a directory path."""
    # Try exact match first
    if subtype_key in SUBTYPE_HINTS:
        return dict(SUBTYPE_HINTS[subtype_key])
    # Try the last component
    last = subtype_key.split("/")[-1]
    if last in SUBTYPE_HINTS:
        return dict(SUBTYPE_HINTS[last])
    return {
        "asset_type": "props",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "prop",
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "indoor": True,
        "outdoor": True,
        "tags": ["needs_review"],
    }


def derive_subtype(fpath: Path, content_root: Path, section_label: str) -> str:
    """Derive a subtype key from the relative path within a section."""
    try:
        rel = fpath.relative_to(content_root)
    except ValueError:
        return "unknown"
    parts = rel.parts
    # Find the section root in the path
    # Section roots are like: tiles/gothic, props/gothic, walls/gothic, etc.
    # After the section root, the next parts indicate subtype
    section_paths = {
        "tiles":            "tiles/gothic",
        "tiles_interiors":  "tiles/interiors/gothic",
        "walls":            "walls/gothic",
        "doors":            "doors/gothic",
        "structures":       "structures/gothic",
        "props":            "props/gothic",
        "roads":            "tiles/roads_paths/runtime/roads/gothic",
        "road_compound":    "tiles/roads_paths/runtime/gothic_compound",
        "animations":       "animations/gothic",
        "rooms":            "procgen/special_rooms/gothic_compound",
    }
    section_root = section_paths.get(section_label, "")
    if not section_root:
        return "unknown"
    root_parts = section_root.split("/")
    # Remove the content root prefix and section root prefix
    sub_parts = []
    in_sub = False
    for p in parts:
        if in_sub:
            sub_parts.append(p)
        elif root_parts and p == root_parts[0]:
            root_parts.pop(0)
            if not root_parts:
                in_sub = True
    # sub_parts now has the path components after the section root
    if not sub_parts:
        return section_label
    # The first meaningful subdirectory is the subtype
    for p in sub_parts:
        if p.endswith(".png"):
            continue
        return slugify(p)
    return section_label


# ── Collect assets ──────────────────────────────────────────────────────────

@dataclass
class Asset:
    section_label: str
    section_index: int
    subtype: str
    source_path: Path
    image: Image.Image
    width: int
    height: int
    filename_stem: str
    game32_hints: dict[str, Any]
    subtype_hint: dict[str, Any]
    # Set during layout
    sheet_x: int = 0
    sheet_y: int = 0
    sheet_row_height: int = 0


def collect_assets(content_root: Path, max_width: int) -> list[Asset]:
    assets: list[Asset] = []
    seen: set[str] = set()

    for section_index, (label, rel_path, _color) in enumerate(SECTIONS):
        base = content_root / rel_path
        if not base.exists():
            continue

        pngs = sorted(
            [f for f in base.rglob("*.png") if ".import" not in str(f)],
            key=lambda f: natural_sort_key(f.as_posix()),
        )

        for fpath in pngs:
            # Deduplicate by absolute path
            abs_path = str(fpath.resolve())
            if abs_path in seen:
                continue
            seen.add(abs_path)

            try:
                with Image.open(fpath) as opened:
                    img = opened.convert("RGBA")
            except OSError as exc:
                print(f"  [skip] Cannot open {fpath.relative_to(content_root)}: {exc}")
                continue

            stem = fpath.stem
            subtype = derive_subtype(fpath, content_root, label)
            game32_hints = parse_game32_name(stem)
            subtype_hint = get_subtype_hint(subtype)

            assets.append(Asset(
                section_label=label,
                section_index=section_index,
                subtype=subtype,
                source_path=fpath,
                image=img,
                width=img.width,
                height=img.height,
                filename_stem=stem,
                game32_hints=game32_hints,
                subtype_hint=subtype_hint,
            ))

    return assets


# ── Layout ──────────────────────────────────────────────────────────────────

def layout_section(
    section_assets: list[Asset],
    start_x: int,
    start_y: int,
    max_width: int,
    padding: int,
) -> tuple[int, int, int]:
    """Layout assets in a section band, left-to-right, wrapping rows.

    Returns (total_width, total_height, end_y).
    """
    if not section_assets:
        return start_x, start_y, start_y

    x = start_x
    y = start_y
    row_height = 0
    max_row_x = start_x

    for asset in section_assets:
        aw = asset.width
        ah = asset.height

        # Check if this asset fits on the current row; if not, wrap
        if x + aw > start_x + max_width and x > start_x:
            x = start_x
            y += row_height + padding
            row_height = 0

        asset.sheet_x = x
        asset.sheet_y = y

        # Track row height
        if ah > row_height:
            row_height = ah
        # Track max width for this section
        if x + aw > max_row_x:
            max_row_x = x + aw

        x += aw + padding

    # Calculate section dimensions
    section_w = max_row_x - start_x
    section_h = (y + row_height) - start_y
    end_y = y + row_height + padding

    return section_w, section_h, end_y


# ── Build sheet ─────────────────────────────────────────────────────────────

def build_sheet(
    assets: list[Asset],
    max_width: int,
    padding: int,
    section_gap: int,
    font: ImageFont.ImageFont,
) -> Image.Image:
    # Group assets by section, preserving order
    section_groups: list[tuple[str, tuple[int, int, int], list[Asset]]] = []
    for label, rel_path, color in SECTIONS:
        group = [a for a in assets if a.section_label == label]
        if group:
            section_groups.append((label, color, group))

    # First pass: layout each section to calculate total sheet height
    section_heights: list[int] = []
    total_height = 0

    for label, color, group in section_groups:
        _, sh, _ = layout_section(group, padding, 0, max_width - 2 * padding, padding)
        section_heights.append(sh)
        total_height += SECTION_HEADER_HEIGHT + section_gap + sh + section_gap

    sheet_height = total_height + padding * 2
    sheet = Image.new("RGBA", (max_width, sheet_height), (13, 15, 14, 255))
    draw = ImageDraw.Draw(sheet)

    # Second pass: actually place everything
    current_y = padding

    for (label, color, group), sh in zip(section_groups, section_heights):
        # Section header bar
        header_rect = (0, current_y, max_width, current_y + SECTION_HEADER_HEIGHT)
        draw.rectangle(header_rect, fill=(*color, 200))
        draw.text(
            (padding + 4, current_y + 6),
            f"{label}  ({len(group)} assets)",
            fill=(235, 238, 218, 255),
            font=font,
        )

        current_y += SECTION_HEADER_HEIGHT + section_gap

        # Layout and paste assets
        _, _, end_y = layout_section(group, padding, current_y, max_width - 2 * padding, padding)

        for asset in group:
            # Paste asset onto sheet
            sheet.alpha_composite(asset.image, (asset.sheet_x, asset.sheet_y))
            # Draw a subtle border
            draw.rectangle(
                (asset.sheet_x, asset.sheet_y, asset.sheet_x + asset.width - 1, asset.sheet_y + asset.height - 1),
                outline=(80, 85, 80, 180),
            )

        current_y = end_y + section_gap

    # Crop to actual used height
    actual_height = current_y
    sheet = sheet.crop((0, 0, max_width, actual_height))
    return sheet


# ── Generate manifest ──────────────────────────────────────────────────────

def generate_manifest(assets: list[Asset], sheet_path: Path, max_width: int, padding: int) -> dict[str, Any]:
    manifest_assets: list[dict[str, Any]] = []

    for idx, asset in enumerate(assets):
        try:
            rel_source = asset.source_path.relative_to(CONTENT_ROOT).as_posix()
        except ValueError:
            rel_source = str(asset.source_path)

        source_path_str = f"res://content/{rel_source}"

        # Generate a stable asset ID
        asset_id = slugify(f"gothic_{asset.section_label}_{asset.subtype}_{asset.filename_stem}")

        # Merge subtype hints with any game32 naming hints
        hint = dict(asset.subtype_hint)
        frame_info = dict(asset.game32_hints)

        # Classification
        classification = {
            "asset_type": hint.get("asset_type", "props"),
            "semantic_role": hint.get("semantic_role", "uncategorized_environment_asset"),
            "placement_layer": hint.get("placement_layer", "prop"),
            "tags": sorted(set(hint.get("tags", []))),
            "review_status": "needs_game32_enrichment",
        }

        # Placement — compute footprint from pixel size
        tile_size = 32
        footprint_w = max(1, math.ceil(asset.width / tile_size))
        footprint_h = max(1, math.ceil(asset.height / tile_size))
        is_ground = classification["placement_layer"] in {"ground", "ground_detail"}

        placement = {
            "tile_size": tile_size,
            "footprint_tiles": {"w": footprint_w, "h": footprint_h},
            "origin_mode": "top_left" if is_ground else "bottom_center",
            "snap": "tile",
            "allow_mirror_x": classification["asset_type"] in {"props", "walls"},
            "allow_rotation": False,
            "y_sort": not is_ground,
        }

        if frame_info.get("frame_size"):
            placement["frame_size_px"] = frame_info["frame_size"]
            placement["frame_count"] = frame_info["frame_count"]

        # Collision
        collision = {
            "blocks_movement": bool(hint.get("blocks_movement", False)),
            "blocks_sight": bool(hint.get("blocks_sight", False)),
            "cover_value": int(hint.get("cover_value", 0)),
            "review_status": "needs_game32_enrichment",
        }

        # Procgen (placeholder — needs human review)
        procgen = {
            "uses": ["needs_review"],
            "weight": 5,
            "can_spawn_indoor": bool(hint.get("indoor", True)),
            "can_spawn_outdoor": bool(hint.get("outdoor", True)),
            "review_status": "needs_game32_enrichment",
        }

        asset_entry = {
            "schema": "game32.asset.v2",
            "id": asset_id,
            "display_name": asset.filename_stem.replace("_", " ").title(),
            "source": {
                "master_sheet": str(sheet_path.relative_to(CONTENT_ROOT).as_posix()),
                "original_path": source_path_str,
                "section": asset.section_label,
                "subtype": asset.subtype,
                "source_rect_px": {
                    "x": asset.sheet_x,
                    "y": asset.sheet_y,
                    "w": asset.width,
                    "h": asset.height,
                },
            },
            "file": {
                "path": source_path_str,
                "pixel_size": {"w": asset.width, "h": asset.height},
            },
            "classification": classification,
            "placement": placement,
            "collision": collision,
            "procgen": procgen,
            "master_index": idx,
        }

        if frame_info.get("frame_count"):
            asset_entry["animation"] = {
                "frame_count": frame_info["frame_count"],
                "frame_size_px": frame_info["frame_size"],
                "layout": "horizontal_strip",
            }

        manifest_assets.append(asset_entry)

    # Section summary
    section_counts: dict[str, int] = defaultdict(int)
    for a in assets:
        section_counts[a.section_label] += 1

    manifest = {
        "schema": "game32.gothic_master_sheet.v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "master_sheet": str(sheet_path.relative_to(CONTENT_ROOT).as_posix()),
        "sheet_dimensions_px": {"w": max_width, "h": 0},  # filled after build
        "total_asset_count": len(assets),
        "section_count": len(section_counts),
        "sections": dict(section_counts),
        "asset_type_summary": dict(
            sorted(
                defaultdict(int, {
                    a.subtype_hint.get("asset_type", "unknown"): sum(
                        1 for x in assets if x.subtype_hint.get("asset_type") == a.subtype_hint.get("asset_type")
                    )
                }).items()
            )
        ),
        "review_status": "needs_game32_enrichment",
        "notes": "Master sheet manifest v1. All fields auto-derived from directory structure and filenames. Requires human review for classification, placement, collision, procgen accuracy.",
        "assets": manifest_assets,
    }

    return manifest


# ── CLI ─────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-width", type=int, default=DEFAULT_MAX_WIDTH,
                        help=f"Maximum sheet width in pixels (default: {DEFAULT_MAX_WIDTH})")
    parser.add_argument("--padding", type=int, default=DEFAULT_PADDING,
                        help=f"Padding between assets in pixels (default: {DEFAULT_PADDING})")
    parser.add_argument("--section-gap", type=int, default=DEFAULT_SECTION_GAP,
                        help=f"Vertical gap between sections (default: {DEFAULT_SECTION_GAP})")
    parser.add_argument("--dry-run", action="store_true",
                        help="Only print what would be collected and exit")
    parser.add_argument("--list-only", action="store_true",
                        help="Only list all collected asset paths and exit")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    content_root = CONTENT_ROOT
    max_width = args.max_width
    padding = args.padding
    section_gap = args.section_gap

    print(f"[gothic-master-sheet] Collecting assets from {content_root}...")
    assets = collect_assets(content_root, max_width)
    print(f"[gothic-master-sheet] Collected {len(assets)} gothic assets")

    if not assets:
        print("[gothic-master-sheet] No assets found.")
        return 1

    # Summary
    section_counts: dict[str, int] = defaultdict(int)
    for a in assets:
        section_counts[a.section_label] += 1
    print("\n[gothic-master-sheet] Section breakdown:")
    for label, _rel, _color in SECTIONS:
        count = section_counts.get(label, 0)
        if count > 0:
            print(f"  {label:20s}  {count:4d} assets")
    print(f"  {'TOTAL':20s}  {len(assets):4d} assets")

    if args.list_only:
        for a in assets:
            try:
                print(f"  {a.source_path.relative_to(content_root)}  ({a.width}x{a.height})")
            except ValueError:
                print(f"  {a.source_path}  ({a.width}x{a.height})")
        return 0

    if args.dry_run:
        return 0

    # Build sheet
    print(f"\n[gothic-master-sheet] Building sheet (max-width={max_width}, padding={padding})...")
    font = load_font(14)
    sheet = build_sheet(assets, max_width, padding, section_gap, font)

    # Save sheet
    OUTPUT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT_SHEET)
    print(f"[gothic-master-sheet] Wrote {OUTPUT_SHEET}  ({sheet.width}x{sheet.height})")

    # Generate manifest
    manifest = generate_manifest(assets, OUTPUT_SHEET, max_width, padding)
    manifest["sheet_dimensions_px"]["h"] = sheet.height

    OUTPUT_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"[gothic-master-sheet] Wrote {OUTPUT_MANIFEST}  ({len(manifest['assets'])} assets)")

    # Summary
    by_type: dict[str, int] = defaultdict(int)
    for a in manifest["assets"]:
        at = a["classification"]["asset_type"]
        by_type[at] += 1
    print("\n[gothic-master-sheet] Asset type summary:")
    for at, count in sorted(by_type.items()):
        print(f"  {at}: {count}")

    print(f"\n[gothic-master-sheet] Done. Sheet: {OUTPUT_SHEET.relative_to(content_root.parent)}")
    print(f"[gothic-master-sheet] Manifest: {OUTPUT_MANIFEST.relative_to(content_root.parent)}")
    print(f"[gothic-master-sheet] Review status: needs_game32_enrichment")
    return 0


if __name__ == "__main__":
    sys.exit(main())
