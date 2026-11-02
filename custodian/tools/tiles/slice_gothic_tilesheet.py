#!/usr/bin/env python3
"""
slice_gothic_tilesheet.py

Cuts separated assets out of gothic_tilesheet.png and writes:
  custodian/content/{asset_type}/gothic/*.png
  custodian/content/tiles/gothic/gothic_tilesheet_manifest.game32.json

Designed for a generated sheet with:
  - mostly transparent / checker / white background
  - separated floor tiles, wall slices, doors, buildings, props
  - variable-size props and structures
  - 32px game tile metadata

Requires:
  python3 -m pip install pillow numpy
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
from collections import deque, defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Tuple, Iterable, Optional

import numpy as np
from PIL import Image

RGBA = Tuple[int, int, int, int]


@dataclass
class Component:
    idx: int
    bbox: Tuple[int, int, int, int]  # x0, y0, x1, y1 inclusive
    width: int
    height: int
    area: int
    cx: float
    cy: float
    asset_type: str
    subtype: str
    name: str
    output_path: str
    game32: Dict


def slugify(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s or "asset"


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def rgba_image(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def estimate_background_mask(img: Image.Image, alpha_threshold: int = 12) -> np.ndarray:
    """
    Returns True where pixels should be treated as background.

    Handles:
      1. real alpha
      2. white/checker background
      3. near-white generated background
      4. faint gray checkerboard
    """
    arr = np.array(img, dtype=np.uint8)
    rgb = arr[:, :, :3].astype(np.int16)
    a = arr[:, :, 3]

    # Transparent pixels are background.
    transparent = a <= alpha_threshold

    # Near-white / checkerboard background.
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    near_white = (r > 220) & (g > 220) & (b > 220)

    # Common checkerboard gray/white values.
    light_gray = (
        (r > 185) & (g > 185) & (b > 185) & (np.abs(r - g) < 10) & (np.abs(g - b) < 10)
    )

    # Background often includes very low saturation neutral checker pixels.
    maxc = rgb.max(axis=2)
    minc = rgb.min(axis=2)
    low_sat_light = ((maxc - minc) < 16) & (maxc > 175)

    return transparent | near_white | light_gray | low_sat_light


def remove_small_noise(foreground: np.ndarray, min_neighbors: int = 2) -> np.ndarray:
    """
    Removes isolated 1px noise without erasing real thin gothic spikes/chains too aggressively.
    """
    h, w = foreground.shape
    padded = np.pad(foreground, 1, mode="constant", constant_values=False)
    neighbor_count = np.zeros_like(foreground, dtype=np.uint8)

    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            neighbor_count += padded[1 + dy : 1 + dy + h, 1 + dx : 1 + dx + w]

    keep = foreground & (neighbor_count >= min_neighbors)
    return keep


def connected_components(
    mask: np.ndarray, min_area: int = 24
) -> List[Tuple[int, int, int, int, int]]:
    """
    Connected components over foreground mask.

    Returns:
      list of (x0, y0, x1, y1, area)
    """
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    comps: List[Tuple[int, int, int, int, int]] = []

    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
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

                for nx in (px - 1, px, px + 1):
                    for ny in (py - 1, py, py + 1):
                        if nx == px and ny == py:
                            continue
                        if nx < 0 or nx >= w or ny < 0 or ny >= h:
                            continue
                        if seen[ny, nx] or not mask[ny, nx]:
                            continue
                        seen[ny, nx] = True
                        q.append((nx, ny))

            if area >= min_area:
                comps.append((x0, y0, x1, y1, area))

    return comps


def expand_bbox(
    bbox: Tuple[int, int, int, int],
    pad: int,
    img_w: int,
    img_h: int,
) -> Tuple[int, int, int, int]:
    x0, y0, x1, y1 = bbox
    return (
        max(0, x0 - pad),
        max(0, y0 - pad),
        min(img_w - 1, x1 + pad),
        min(img_h - 1, y1 + pad),
    )


def classify_asset(
    x0: int,
    y0: int,
    x1: int,
    y1: int,
    area: int,
    sheet_w: int,
    sheet_h: int,
    tile_size: int,
) -> Tuple[str, str]:
    """
    Heuristic classifier based on sheet layout and dimensions.

    This specific generated sheet appears organized roughly:
      top rows    = floors / ground / overlay tiles
      upper-mid   = wall slices, wall caps, corners
      mid         = doors, gates, large building facades
      lower-mid   = ruins, trees, rocks, machines, obelisks
      bottom      = crates, barrels, fences, chains, banners, sandbags
    """
    w = x1 - x0 + 1
    h = y1 - y0 + 1
    cy = (y0 + y1) / 2
    ratio = w / max(1, h)

    # Top two rows are mostly 32-ish floor/ground tiles.
    if cy < sheet_h * 0.18:
        if w <= tile_size * 1.8 and h <= tile_size * 1.8:
            return "tiles", "floor"
        return "tiles", "floor_overlay"

    # Tall narrow vertical wall slices.
    if h >= tile_size * 1.6 and w <= tile_size * 1.45 and cy < sheet_h * 0.55:
        return "tiles", "wall_vertical_slice"

    # Wall/corner/cap fragments.
    if cy < sheet_h * 0.50 and h >= tile_size * 1.0:
        if ratio > 1.6:
            return "tiles", "wall_horizontal_or_cap"
        return "tiles", "wall_corner_or_end"

    # Doors/gates are large mid-row arched pieces.
    if sheet_h * 0.33 <= cy <= sheet_h * 0.62 and h >= tile_size * 1.4:
        if w >= tile_size * 1.4 and h >= tile_size * 1.6:
            if w >= tile_size * 3 or h >= tile_size * 3:
                return "structures", "building_or_large_gate"
            return "doors", "door_or_gate"

    # Very large items below middle: buildings, fountains, trees.
    if w >= tile_size * 3 or h >= tile_size * 3:
        if cy < sheet_h * 0.75:
            return "structures", "landmark_or_building"
        return "props", "large_environment_prop"

    # Thin line-like assets near bottom: chains, fences, sandbags.
    if cy > sheet_h * 0.70 and ratio >= 2.2:
        if h <= tile_size * 1.2:
            return "props", "low_cover_or_chain"
        return "props", "fence_or_barrier"

    # Tall thin bottom/mid props: obelisk, lamps, banners, posts.
    if h >= tile_size * 1.8 and w <= tile_size * 1.6:
        # Black/torn banner is tall cloth-like.
        if cy > sheet_h * 0.55:
            return "props", "banner_or_hanging_cloth"
        return "props", "pillar_or_lamp"

    return "props", "environment_prop"


def game32_metadata(
    asset_type: str,
    subtype: str,
    w: int,
    h: int,
    tile_size: int,
) -> Dict:
    footprint_w = max(1, math.ceil(w / tile_size))
    footprint_h = max(1, math.ceil(h / tile_size))

    is_floor = subtype in {"floor", "floor_overlay"}
    is_wall = subtype.startswith("wall_")
    is_door = asset_type == "doors"
    is_structure = asset_type == "structures"
    is_prop = asset_type == "props"

    blocks_movement = bool(
        is_wall
        or is_structure
        or subtype
        in {
            "pillar_or_lamp",
            "fence_or_barrier",
            "large_environment_prop",
        }
    )

    blocks_sight = bool(
        is_wall
        or is_structure
        or subtype
        in {
            "pillar_or_lamp",
            "large_environment_prop",
        }
    )

    cover_value = 0
    if subtype in {"low_cover_or_chain", "fence_or_barrier"}:
        cover_value = 1
    if is_wall or is_structure:
        cover_value = 2

    placement_layer = "ground"
    if is_wall:
        placement_layer = "wall"
    elif is_door:
        placement_layer = "door"
    elif is_structure:
        placement_layer = "structure"
    elif is_prop:
        placement_layer = "prop"

    return {
        "schema": "game32.asset.v1",
        "tile_size": tile_size,
        "pixel_size": {"w": w, "h": h},
        "footprint_tiles": {"w": footprint_w, "h": footprint_h},
        "origin": {
            "mode": "bottom_center" if not is_floor else "top_left",
            "pivot_px": {"x": w // 2, "y": h - 1} if not is_floor else {"x": 0, "y": 0},
        },
        "placement": {
            "layer": placement_layer,
            "snap": "tile" if is_floor or is_wall or is_door else "free_or_tile",
            "allow_rotation": False,
            "allow_mirror_x": subtype not in {"door_or_gate", "building_or_large_gate"},
        },
        "collision": {
            "blocks_movement": blocks_movement,
            "blocks_sight": blocks_sight,
            "cover_value": cover_value,
            "hitbox": "footprint" if blocks_movement else "none",
        },
        "procgen": {
            "category": asset_type,
            "subtype": subtype,
            "tags": procgen_tags(asset_type, subtype),
            "weight": default_weight(asset_type, subtype),
            "can_spawn_indoor": can_spawn_indoor(asset_type, subtype),
            "can_spawn_outdoor": can_spawn_outdoor(asset_type, subtype),
            "supports_gothic_compound": True,
        },
        "render": {
            "y_sort": not is_floor,
            "casts_shadow": not is_floor,
            "occluder": blocks_sight,
        },
        "notes": detail_note(asset_type, subtype),
    }


def procgen_tags(asset_type: str, subtype: str) -> List[str]:
    tags = ["gothic", "compound", "dark_stone"]

    if subtype == "floor":
        tags += ["ground", "walkable", "variant_floor"]
    elif subtype == "floor_overlay":
        tags += ["ground_detail", "decal", "damage"]
    elif subtype.startswith("wall_"):
        tags += ["wall", "blocking", "vertical_slice"]
    elif asset_type == "doors":
        tags += ["entrance", "doorway", "gate"]
    elif asset_type == "structures":
        tags += ["landmark", "poi", "blocking"]
    elif "banner" in subtype:
        tags += ["banner", "animated_candidate", "faction_dressing"]
    elif "chain" in subtype:
        tags += ["chain", "barrier", "low_cover"]
    elif "fence" in subtype:
        tags += ["fence", "barrier", "cover"]
    elif "lamp" in subtype:
        tags += ["light_source", "prop"]
    else:
        tags += ["prop", "environment"]

    return sorted(set(tags))


def default_weight(asset_type: str, subtype: str) -> int:
    if subtype == "floor":
        return 80
    if subtype == "floor_overlay":
        return 25
    if subtype.startswith("wall_"):
        return 50
    if asset_type == "doors":
        return 18
    if asset_type == "structures":
        return 6
    if "large" in subtype:
        return 8
    return 20


def can_spawn_indoor(asset_type: str, subtype: str) -> bool:
    if subtype == "floor":
        return True
    if subtype == "floor_overlay":
        return True
    if asset_type in {"doors", "tiles"}:
        return True
    if subtype in {
        "environment_prop",
        "pillar_or_lamp",
        "banner_or_hanging_cloth",
        "low_cover_or_chain",
    }:
        return True
    return False


def can_spawn_outdoor(asset_type: str, subtype: str) -> bool:
    if asset_type in {"tiles", "doors", "structures", "props"}:
        return True
    return False


def detail_note(asset_type: str, subtype: str) -> str:
    notes = {
        "floor": "Walkable 32px ground tile or tile variant.",
        "floor_overlay": "Damage, grate, scorch, drain, or detail decal for floor variation.",
        "wall_vertical_slice": "Tall modular vertical wall slice for gothic compound perimeter/interior walls.",
        "wall_horizontal_or_cap": "Horizontal cap, parapet, or top-wall segment.",
        "wall_corner_or_end": "Corner, endcap, broken wall end, or connector segment.",
        "door_or_gate": "Entrance module for compound generation.",
        "building_or_large_gate": "Large gate, facade, or building entrance landmark.",
        "landmark_or_building": "Large POI structure; use sparingly as compound anchor.",
        "large_environment_prop": "Large prop such as tree, ruin, generator, altar, rubble, or machine.",
        "low_cover_or_chain": "Low obstacle, chain, sandbag, or cover strip.",
        "fence_or_barrier": "Fence or barrier prop for compound boundaries and chokepoints.",
        "banner_or_hanging_cloth": "Faction dressing / banner candidate; can be animated.",
        "pillar_or_lamp": "Narrow vertical prop, lamp, obelisk, or pillar.",
        "environment_prop": "General environmental detail prop.",
    }
    return notes.get(subtype, f"{asset_type}/{subtype} asset.")


def crop_with_alpha(
    source: Image.Image,
    bbox: Tuple[int, int, int, int],
    bg_mask: np.ndarray,
) -> Image.Image:
    """
    Crops a component and sets detected background pixels to alpha 0.
    """
    x0, y0, x1, y1 = bbox
    crop = source.crop((x0, y0, x1 + 1, y1 + 1)).convert("RGBA")
    arr = np.array(crop, dtype=np.uint8)

    local_bg = bg_mask[y0 : y1 + 1, x0 : x1 + 1]
    arr[local_bg, 3] = 0

    return Image.fromarray(arr, mode="RGBA")


def stable_sort_components(
    comps: List[Tuple[int, int, int, int, int]], row_tol: int = 20
) -> List[Tuple[int, int, int, int, int]]:
    """
    Sort components visually top-to-bottom, left-to-right, with rough row grouping.
    """

    def key(c):
        x0, y0, x1, y1, area = c
        cy = (y0 + y1) // 2
        row = cy // row_tol
        return (row, x0)

    return sorted(comps, key=key)


def create_banner_flap_spritesheet(
    banner_img: Image.Image,
    out_path: Path,
    frames: int = 10,
    amplitude: float = 4.0,
) -> None:
    """
    Creates a simple 10-frame cloth flap by shifting horizontal rows.
    Good enough as a first-pass runtime placeholder.
    """
    banner = banner_img.convert("RGBA")
    w, h = banner.size

    frame_w = w + int(amplitude * 4) + 4
    frame_h = h
    sheet = Image.new("RGBA", (frame_w * frames, frame_h), (0, 0, 0, 0))

    src = np.array(banner, dtype=np.uint8)

    for f in range(frames):
        phase = (f / frames) * math.tau
        frame = np.zeros((frame_h, frame_w, 4), dtype=np.uint8)

        for y in range(h):
            t = y / max(1, h - 1)
            # Pinned near the top, more movement toward the torn bottom.
            strength = t**1.35
            wave = math.sin(phase + t * math.tau * 1.25)
            dx = int(round(wave * amplitude * strength))
            base_x = int(amplitude * 2) + 2 + dx

            for x in range(w):
                px = src[y, x]
                if px[3] == 0:
                    continue
                tx = base_x + x
                if 0 <= tx < frame_w:
                    frame[y, tx] = px

        sheet.paste(Image.fromarray(frame, mode="RGBA"), (f * frame_w, 0))

    ensure_dir(out_path.parent)
    sheet.save(out_path)


def find_banner_candidate(components: List[Component]) -> Optional[Component]:
    candidates = [c for c in components if c.subtype == "banner_or_hanging_cloth"]
    if not candidates:
        return None

    # Prefer tall, narrow, lower-half black cloth. Largest tall narrow usually wins.
    candidates.sort(key=lambda c: (c.height / max(1, c.width), c.area), reverse=True)
    return candidates[0]


def write_manifest(
    manifest_path: Path, components: List[Component], source_path: Path, tile_size: int
) -> None:
    data = {
        "schema": "game32.tilesheet_manifest.v1",
        "source": str(source_path),
        "tile_size": tile_size,
        "asset_count": len(components),
        "asset_types": dict(
            sorted(
                defaultdict(
                    int,
                    {
                        k: sum(1 for c in components if c.asset_type == k)
                        for k in sorted(set(c.asset_type for c in components))
                    },
                ).items()
            )
        ),
        "assets": [
            {
                "id": c.name,
                "name": c.name,
                "asset_type": c.asset_type,
                "subtype": c.subtype,
                "source_bbox_px": {
                    "x": c.bbox[0],
                    "y": c.bbox[1],
                    "w": c.width,
                    "h": c.height,
                },
                "source_center_px": {
                    "x": round(c.cx, 2),
                    "y": round(c.cy, 2),
                },
                "path": c.output_path,
                "game32": c.game32,
            }
            for c in components
        ],
    }

    ensure_dir(manifest_path.parent)
    manifest_path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Path to gothic_tilesheet.png")
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("./custodian/content"),
        help="CUSTODIAN content root",
    )
    parser.add_argument("--tile-size", type=int, default=32)
    parser.add_argument("--min-area", type=int, default=24)
    parser.add_argument("--pad", type=int, default=1)
    parser.add_argument("--make-banner-animation", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    source_path: Path = args.source
    content_root: Path = args.out
    tile_size: int = args.tile_size

    if not source_path.exists():
        raise FileNotFoundError(f"Source image not found: {source_path}")

    img = rgba_image(source_path)
    sheet_w, sheet_h = img.size

    bg_mask = estimate_background_mask(img)
    foreground = ~bg_mask
    foreground = remove_small_noise(foreground, min_neighbors=1)

    raw_comps = connected_components(foreground, min_area=args.min_area)
    raw_comps = stable_sort_components(raw_comps)

    print(f"[slice] source: {source_path}")
    print(f"[slice] size: {sheet_w}x{sheet_h}")
    print(f"[slice] detected components: {len(raw_comps)}")

    counters: Dict[Tuple[str, str], int] = defaultdict(int)
    components: List[Component] = []

    for idx, raw in enumerate(raw_comps, start=1):
        x0, y0, x1, y1, area = raw
        bbox = expand_bbox((x0, y0, x1, y1), args.pad, sheet_w, sheet_h)
        x0, y0, x1, y1 = bbox

        w = x1 - x0 + 1
        h = y1 - y0 + 1
        cx = (x0 + x1) / 2
        cy = (y0 + y1) / 2

        asset_type, subtype = classify_asset(
            x0, y0, x1, y1, area, sheet_w, sheet_h, tile_size
        )
        counters[(asset_type, subtype)] += 1
        n = counters[(asset_type, subtype)]

        base_name = f"gothic_{subtype}_{n:03d}"
        base_name = slugify(base_name)

        if asset_type == "tiles":
            out_dir = content_root / "tiles" / "gothic" / subtype
        elif asset_type == "doors":
            out_dir = content_root / "doors" / "gothic" / subtype
        elif asset_type == "structures":
            out_dir = content_root / "structures" / "gothic" / subtype
        else:
            out_dir = content_root / "props" / "gothic" / subtype

        out_file = out_dir / f"{base_name}.png"
        rel_out = str(out_file)

        meta = game32_metadata(asset_type, subtype, w, h, tile_size)

        comp = Component(
            idx=idx,
            bbox=bbox,
            width=w,
            height=h,
            area=area,
            cx=cx,
            cy=cy,
            asset_type=asset_type,
            subtype=subtype,
            name=base_name,
            output_path=rel_out,
            game32=meta,
        )
        components.append(comp)

        if not args.dry_run:
            ensure_dir(out_dir)
            crop = crop_with_alpha(img, bbox, bg_mask)
            crop.save(out_file)

    manifest_path = (
        content_root / "tiles" / "gothic" / "gothic_tilesheet_manifest.game32.json"
    )

    if not args.dry_run:
        write_manifest(manifest_path, components, source_path, tile_size)

    if args.make_banner_animation:
        banner = find_banner_candidate(components)
        if banner:
            banner_path = Path(banner.output_path)
            anim_out = content_root / "animations" / "gothic" / "banner_flap_10f.png"

            if not args.dry_run:
                banner_img = Image.open(banner_path).convert("RGBA")
                create_banner_flap_spritesheet(banner_img, anim_out, frames=10)

            # Add sidecar metadata for the generated animation.
            anim_meta = {
                "schema": "game32.animation.v1",
                "source_asset": banner.name,
                "source_path": str(banner_path),
                "output_path": str(anim_out),
                "frames": 10,
                "layout": "horizontal_strip",
                "fps": 8,
                "loop": True,
                "intent": "Torn gothic banner flapping as ambient faction/compound dressing.",
                "game32": {
                    "tile_size": tile_size,
                    "placement": {
                        "layer": "prop_overlay",
                        "snap": "free_or_tile",
                        "origin": "top_center_or_wall_mount",
                    },
                    "procgen": {
                        "tags": [
                            "gothic",
                            "banner",
                            "animated",
                            "ambient",
                            "faction_dressing",
                        ],
                        "weight": 8,
                        "can_spawn_indoor": True,
                        "can_spawn_outdoor": True,
                    },
                },
            }

            if not args.dry_run:
                meta_path = anim_out.with_suffix(".game32.json")
                ensure_dir(meta_path.parent)
                meta_path.write_text(json.dumps(anim_meta, indent=2), encoding="utf-8")

            print(f"[banner] candidate: {banner.name}")
            print(f"[banner] animation: {anim_out}")
        else:
            print("[banner] no banner candidate found")

    print("\n[slice] output summary:")
    by_type: Dict[str, int] = defaultdict(int)
    by_subtype: Dict[str, int] = defaultdict(int)

    for c in components:
        by_type[c.asset_type] += 1
        by_subtype[f"{c.asset_type}/{c.subtype}"] += 1

    for k in sorted(by_type):
        print(f"  {k}: {by_type[k]}")

    print("\n[slice] subtype summary:")
    for k in sorted(by_subtype):
        print(f"  {k}: {by_subtype[k]}")

    print(f"\n[slice] manifest: {manifest_path}")
    print("[slice] done")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
