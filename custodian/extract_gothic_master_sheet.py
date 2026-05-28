#!/usr/bin/env python3
"""
extract_gothic_master_sheet.py

Reads gothic_master_sheet.png, extracts individual assets, classifies them into
game domains, avoids duplicate PNG exports, and writes a detailed game32.json
manifest.

Usage:
  python extract_gothic_master_sheet.py gothic_master_sheet.png --out ./extracted_gothic

Recommended:
  python extract_gothic_master_sheet.py gothic_master_sheet.png --out . --tile-size 32 --merge-px 2 --min-area 12
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image

DOMAINS = {
    "tiles",
    "props",
    "sprites",
    "structures",
    "decals",
    "fx",
    "ui",
    "unknown",
}


@dataclass
class Component:
    x: int
    y: int
    w: int
    h: int
    area: int
    fill_ratio: float


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text)
    return text.strip("_")


def ensure_dirs(out_dir: Path) -> None:
    for d in DOMAINS:
        (out_dir / d).mkdir(parents=True, exist_ok=True)


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def luminance(rgb: np.ndarray) -> np.ndarray:
    return (
        0.2126 * rgb[..., 0].astype(np.float32)
        + 0.7152 * rgb[..., 1].astype(np.float32)
        + 0.0722 * rgb[..., 2].astype(np.float32)
    )


def make_foreground_mask(
    arr: np.ndarray,
    alpha_threshold: int,
    dark_bg_threshold: int,
    white_bg_threshold: int,
    min_color_delta: int,
) -> np.ndarray:
    """
    Works for mixed master sheets that may contain:
    - true alpha
    - black background
    - white preview panels
    - checkerboard transparency previews

    Keeps non-background pixels as foreground.
    """
    rgb = arr[..., :3]
    alpha = arr[..., 3]

    lum = luminance(rgb)
    maxc = rgb.max(axis=2).astype(np.int16)
    minc = rgb.min(axis=2).astype(np.int16)
    chroma = maxc - minc

    visible = alpha > alpha_threshold

    near_black_bg = (lum <= dark_bg_threshold) & (chroma <= min_color_delta)
    near_white_bg = lum >= white_bg_threshold

    # Common checkerboard preview backgrounds.
    near_checker_light = (
        (rgb[..., 0] >= 210) & (rgb[..., 1] >= 210) & (rgb[..., 2] >= 210)
    )
    near_checker_mid = (
        (rgb[..., 0] >= 150)
        & (rgb[..., 0] <= 205)
        & (rgb[..., 1] >= 150)
        & (rgb[..., 1] <= 205)
        & (rgb[..., 2] >= 150)
        & (rgb[..., 2] <= 205)
        & (chroma <= 18)
    )

    background_like = (
        near_black_bg | near_white_bg | near_checker_light | near_checker_mid
    )

    # Keep dark gothic pixels that are not flat background.
    # Armor/stone pixels often have slight chroma or brightness above pure bg.
    colored_dark_asset = (lum > 10) & (chroma > min_color_delta)
    bright_asset = lum > dark_bg_threshold

    foreground = visible & (~background_like | colored_dark_asset | bright_asset)

    return foreground


def binary_dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask.copy()

    out = mask.copy()
    h, w = mask.shape

    for _ in range(radius):
        src = out
        dst = src.copy()

        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue

                y0s = max(0, -dy)
                y1s = h - max(0, dy)
                x0s = max(0, -dx)
                x1s = w - max(0, dx)

                y0d = max(0, dy)
                y1d = h - max(0, -dy)
                x0d = max(0, dx)
                x1d = w - max(0, -dx)

                dst[y0d:y1d, x0d:x1d] |= src[y0s:y1s, x0s:x1s]

        out = dst

    return out


def connected_components(mask: np.ndarray, min_area: int) -> List[Component]:
    h, w = mask.shape
    visited = np.zeros((h, w), dtype=bool)
    components: List[Component] = []

    ys, xs = np.where(mask)

    for sy, sx in zip(ys.tolist(), xs.tolist()):
        if visited[sy, sx] or not mask[sy, sx]:
            continue

        q = deque([(sx, sy)])
        visited[sy, sx] = True

        minx = maxx = sx
        miny = maxy = sy
        area = 0

        while q:
            x, y = q.popleft()
            area += 1

            if x < minx:
                minx = x
            if x > maxx:
                maxx = x
            if y < miny:
                miny = y
            if y > maxy:
                maxy = y

            for nx, ny in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
                (x - 1, y - 1),
                (x + 1, y - 1),
                (x - 1, y + 1),
                (x + 1, y + 1),
            ):
                if nx < 0 or ny < 0 or nx >= w or ny >= h:
                    continue
                if visited[ny, nx] or not mask[ny, nx]:
                    continue
                visited[ny, nx] = True
                q.append((nx, ny))

        bw = maxx - minx + 1
        bh = maxy - miny + 1
        fill_ratio = area / float(max(1, bw * bh))

        if area >= min_area:
            components.append(Component(minx, miny, bw, bh, area, fill_ratio))

    components.sort(key=lambda c: (c.y, c.x))
    return components


def crop_with_alpha(
    img: Image.Image,
    mask: np.ndarray,
    comp: Component,
    pad: int,
) -> Tuple[Image.Image, Tuple[int, int, int, int]]:
    w_img, h_img = img.size

    x0 = max(0, comp.x - pad)
    y0 = max(0, comp.y - pad)
    x1 = min(w_img, comp.x + comp.w + pad)
    y1 = min(h_img, comp.y + comp.h + pad)

    crop = img.crop((x0, y0, x1, y1)).convert("RGBA")
    crop_arr = np.array(crop)

    local_mask = mask[y0:y1, x0:x1]
    crop_arr[..., 3] = np.where(local_mask, crop_arr[..., 3], 0).astype(np.uint8)

    trimmed = trim_transparent(Image.fromarray(crop_arr, "RGBA"))

    if trimmed is None:
        return Image.fromarray(crop_arr, "RGBA"), (x0, y0, x1 - x0, y1 - y0)

    trimmed_img, bbox = trimmed
    tx0, ty0, tx1, ty1 = bbox
    return trimmed_img, (x0 + tx0, y0 + ty0, tx1 - tx0, ty1 - ty0)


def trim_transparent(
    img: Image.Image,
) -> Optional[Tuple[Image.Image, Tuple[int, int, int, int]]]:
    arr = np.array(img)
    alpha = arr[..., 3]
    ys, xs = np.where(alpha > 0)

    if len(xs) == 0:
        return None

    x0 = int(xs.min())
    x1 = int(xs.max()) + 1
    y0 = int(ys.min())
    y1 = int(ys.max()) + 1

    return img.crop((x0, y0, x1, y1)), (x0, y0, x1, y1)


def normalized_hash(img: Image.Image) -> str:
    """
    Exact-ish duplicate detection after background removal and trimming.
    Keeps distinct variants, removes repeated identical assets.
    """
    trimmed = trim_transparent(img)
    if trimmed:
        img = trimmed[0]

    arr = np.array(img.convert("RGBA"))

    # Normalize fully transparent pixels so hidden RGB does not affect hash.
    arr[arr[..., 3] == 0] = [0, 0, 0, 0]

    return hashlib.sha256(arr.tobytes()).hexdigest()


def avg_color_and_brightness(
    img: Image.Image,
) -> Tuple[Tuple[int, int, int], float, float]:
    arr = np.array(img.convert("RGBA"))
    alpha = arr[..., 3] > 0

    if not np.any(alpha):
        return (0, 0, 0), 0.0, 0.0

    rgb = arr[..., :3][alpha]
    avg = rgb.mean(axis=0)
    lum = luminance(rgb.reshape((-1, 1, 3))).reshape(-1)
    chroma = (rgb.max(axis=1) - rgb.min(axis=1)).mean()

    return (int(avg[0]), int(avg[1]), int(avg[2])), float(lum.mean()), float(chroma)


def classify_asset(
    img: Image.Image,
    rect: Tuple[int, int, int, int],
    tile_size: int,
) -> Dict:
    x, y, w, h = rect
    aspect = w / max(1, h)
    area = w * h
    avg_rgb, avg_lum, avg_chroma = avg_color_and_brightness(img)

    footprint_w = max(1, math.ceil(w / tile_size))
    footprint_h = max(1, math.ceil(h / tile_size))

    tags = ["gothic"]
    semantic_role = "needs_review"
    placement_layer = "object"
    asset_type = "props"
    subtype = "misc"
    blocks_movement = True
    procgen_uses = ["needs_review"]

    squareish = 0.72 <= aspect <= 1.38
    tile_multipleish = (
        abs(w - tile_size) <= 4
        or abs(h - tile_size) <= 4
        or abs(w - 2 * tile_size) <= 6
        or abs(h - 2 * tile_size) <= 6
        or abs(w - 3 * tile_size) <= 8
        or abs(h - 3 * tile_size) <= 8
    )

    if avg_lum > 130 and avg_chroma < 35 and area < tile_size * tile_size * 8:
        asset_type = "fx"
        subtype = "glow"
        semantic_role = "visual_effect_or_light"
        placement_layer = "effects"
        tags += ["fx", "light"]
        blocks_movement = False
        procgen_uses = ["decoration", "lighting"]

    elif h > w * 1.25 and h >= tile_size and w <= tile_size * 3:
        asset_type = "sprites"
        subtype = "characters"
        semantic_role = "animated_character_or_actor"
        placement_layer = "actors"
        tags += ["sprite", "actor", "humanoid"]
        blocks_movement = True
        procgen_uses = ["enemy_spawn", "npc_spawn", "needs_review"]

    elif squareish and tile_multipleish and area <= (tile_size * tile_size * 12):
        asset_type = "tiles"
        subtype = "floors"
        semantic_role = "walkable_floor_variant"
        placement_layer = "ground"
        tags += ["tile", "floor", "walkable"]
        blocks_movement = False
        procgen_uses = ["floor_fill", "room_floor", "corridor_floor"]

    elif w >= tile_size * 3 or h >= tile_size * 3:
        asset_type = "structures"
        subtype = "architecture"
        semantic_role = "large_static_structure"
        placement_layer = "structure"
        tags += ["structure", "architecture"]
        blocks_movement = True
        procgen_uses = ["room_feature", "landmark", "needs_review"]

    elif h <= tile_size and w >= tile_size * 2:
        asset_type = "decals"
        subtype = "ground"
        semantic_role = "ground_decal_or_trim"
        placement_layer = "ground_overlay"
        tags += ["decal", "trim"]
        blocks_movement = False
        procgen_uses = ["detail_pass", "edge_trim"]

    elif area <= tile_size * tile_size:
        asset_type = "props"
        subtype = "small"
        semantic_role = "small_static_prop"
        placement_layer = "object"
        tags += ["prop", "small"]
        blocks_movement = False
        procgen_uses = ["clutter", "decoration"]

    else:
        asset_type = "props"
        subtype = "environment"
        semantic_role = "static_environment_prop"
        placement_layer = "object"
        tags += ["prop", "environment"]
        blocks_movement = True
        procgen_uses = ["decoration", "cover", "needs_review"]

    collision = {
        "blocks_movement": blocks_movement,
        "blocks_projectiles": bool(
            blocks_movement and asset_type in {"props", "structures"}
        ),
        "blocks_vision": bool(blocks_movement and asset_type in {"structures"}),
        "collision_shape": "aabb" if blocks_movement else "none",
        "collision_rect_px": (
            {
                "x": 0,
                "y": 0,
                "w": w,
                "h": h,
            }
            if blocks_movement
            else None
        ),
        "review_status": "heuristic_needs_review",
    }

    placement = {
        "footprint_tiles": {
            "w": footprint_w,
            "h": footprint_h,
        },
        "anchor": (
            "bottom_center"
            if asset_type in {"sprites", "props", "structures"}
            else "top_left"
        ),
        "placement_layer": placement_layer,
        "snap_to_grid": asset_type in {"tiles", "structures"},
        "tile_size_px": tile_size,
        "pivot_px": {
            "x": w // 2,
            "y": h - 1 if asset_type in {"sprites", "props", "structures"} else 0,
        },
    }

    procgen = {
        "uses": procgen_uses,
        "spawn_weight": 1.0,
        "can_rotate": False,
        "can_flip_x": asset_type in {"props", "decals"},
        "can_stack": asset_type in {"decals", "fx"},
        "biomes": ["gothic"],
        "rooms": ["needs_review"],
        "constraints": {
            "requires_floor": asset_type in {"props", "sprites", "fx"},
            "requires_wall": False,
            "avoid_overlap": asset_type not in {"tiles", "decals", "fx"},
        },
    }

    return {
        "asset_type": asset_type,
        "subtype": subtype,
        "semantic_role": semantic_role,
        "placement_layer": placement_layer,
        "tags": sorted(set(tags)),
        "placement": placement,
        "collision": collision,
        "procgen": procgen,
        "visual": {
            "average_rgb": {
                "r": avg_rgb[0],
                "g": avg_rgb[1],
                "b": avg_rgb[2],
            },
            "average_luminance": round(avg_lum, 3),
            "average_chroma": round(avg_chroma, 3),
        },
    }


def make_asset_id(domain: str, subtype: str, semantic_role: str, index: int) -> str:
    return slugify(f"gothic_{domain}_{subtype}_{semantic_role}_{index:04d}")


def save_asset(
    img: Image.Image,
    out_dir: Path,
    domain: str,
    subtype: str,
    asset_id: str,
) -> Path:
    target_dir = out_dir / domain / subtype
    target_dir.mkdir(parents=True, exist_ok=True)
    path = target_dir / f"{asset_id}.png"
    img.save(path)
    return path


def extract_assets(args: argparse.Namespace) -> None:
    source_path = Path(args.input)
    out_dir = Path(args.out)

    ensure_dirs(out_dir)

    img = load_rgba(source_path)
    arr = np.array(img)

    raw_mask = make_foreground_mask(
        arr,
        alpha_threshold=args.alpha_threshold,
        dark_bg_threshold=args.dark_bg_threshold,
        white_bg_threshold=args.white_bg_threshold,
        min_color_delta=args.min_color_delta,
    )

    grouped_mask = binary_dilate(raw_mask, args.merge_px)

    comps = connected_components(grouped_mask, args.min_area)

    seen_hashes: Dict[str, str] = {}
    assets = []
    counts_by_class: Dict[Tuple[str, str], int] = {}

    for comp in comps:
        crop, rect = crop_with_alpha(
            img=img,
            mask=raw_mask,
            comp=comp,
            pad=args.pad,
        )

        if crop.width < args.min_size or crop.height < args.min_size:
            continue

        hsh = normalized_hash(crop)

        classified = classify_asset(crop, rect, args.tile_size)
        domain = classified["asset_type"]
        subtype = classified["subtype"]

        key = (domain, subtype)
        counts_by_class[key] = counts_by_class.get(key, 0) + 1

        asset_id = make_asset_id(
            domain=domain,
            subtype=subtype,
            semantic_role=classified["semantic_role"],
            index=counts_by_class[key],
        )

        duplicate_of = seen_hashes.get(hsh)
        is_duplicate = duplicate_of is not None

        if is_duplicate:
            export_path = None
        else:
            export_path = save_asset(crop, out_dir, domain, subtype, asset_id)
            seen_hashes[hsh] = asset_id

        original_path = (
            f"res://content/{domain}/gothic/{subtype}/{asset_id}.png"
            if not is_duplicate
            else f"res://content/_duplicates/{duplicate_of}.png"
        )

        manifest_entry = {
            "schema": "game32.asset.v2",
            "id": asset_id,
            "source": {
                "master_sheet": str(source_path).replace("\\", "/"),
                "original_path": original_path,
                "section": domain,
                "subtype": subtype,
                "source_rect_px": {
                    "x": rect[0],
                    "y": rect[1],
                    "w": rect[2],
                    "h": rect[3],
                },
            },
            "file": {
                "exported": not is_duplicate,
                "path": str(export_path).replace("\\", "/") if export_path else None,
                "duplicate_of": duplicate_of,
                "sha256_normalized_rgba": hsh,
                "size_px": {
                    "w": crop.width,
                    "h": crop.height,
                },
            },
            "classification": {
                "asset_type": domain,
                "semantic_role": classified["semantic_role"],
                "placement_layer": classified["placement_layer"],
                "tags": classified["tags"],
                "review_status": "needs_game32_enrichment",
                "confidence": "heuristic",
            },
            "placement": classified["placement"],
            "collision": classified["collision"],
            "procgen": classified["procgen"],
            "visual": classified["visual"],
        }

        assets.append(manifest_entry)

    manifest = {
        "schema": "game32.manifest.v2",
        "source": {
            "master_sheet": str(source_path).replace("\\", "/"),
            "image_size_px": {
                "w": img.width,
                "h": img.height,
            },
        },
        "extraction": {
            "tile_size_px": args.tile_size,
            "merge_px": args.merge_px,
            "pad_px": args.pad,
            "min_area_px": args.min_area,
            "min_size_px": args.min_size,
            "alpha_threshold": args.alpha_threshold,
            "dark_bg_threshold": args.dark_bg_threshold,
            "white_bg_threshold": args.white_bg_threshold,
            "min_color_delta": args.min_color_delta,
            "dedupe": "normalized_rgba_sha256",
        },
        "summary": {
            "components_detected": len(comps),
            "assets_total_manifested": len(assets),
            "assets_exported_unique": sum(1 for a in assets if a["file"]["exported"]),
            "duplicates_skipped": sum(1 for a in assets if not a["file"]["exported"]),
        },
        "assets": assets,
    }

    manifest_path = out_dir / "game32.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"Done.")
    print(f"Source: {source_path}")
    print(f"Output: {out_dir}")
    print(f"Manifest: {manifest_path}")
    print(f"Components detected: {len(comps)}")
    print(f"Unique assets exported: {manifest['summary']['assets_exported_unique']}")
    print(f"Duplicates skipped: {manifest['summary']['duplicates_skipped']}")


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser()

    p.add_argument("input", help="Path to gothic_master_sheet.png")
    p.add_argument("--out", default="./gothic_extracted", help="Output directory")

    p.add_argument("--tile-size", type=int, default=32)
    p.add_argument("--merge-px", type=int, default=2)
    p.add_argument("--pad", type=int, default=1)
    p.add_argument("--min-area", type=int, default=12)
    p.add_argument("--min-size", type=int, default=3)

    p.add_argument("--alpha-threshold", type=int, default=0)
    p.add_argument("--dark-bg-threshold", type=int, default=10)
    p.add_argument("--white-bg-threshold", type=int, default=245)
    p.add_argument("--min-color-delta", type=int, default=6)

    return p


if __name__ == "__main__":
    parser = build_arg_parser()
    extract_assets(parser.parse_args())
