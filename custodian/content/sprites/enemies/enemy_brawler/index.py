#!/usr/bin/env python3
"""
CUSTODIAN sprite-template part indexer.

Takes a generated sprite breakdown sheet and exports each separated body part
as a canonical-size PNG plus index.json.

Example:
  python3 custodian/tools/sprite_pipeline/index_grunt_template_parts.py \
    --input custodian/content/dev/in_progress/grunt_template_sheet.png \
    --out-dir custodian/assets/sprites/enemies/grunt/template_parts \
    --prefix grunt_template

Requires:
  python3 -m pip install pillow
"""

from __future__ import annotations

import argparse
import json
import math
from collections import deque
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

from PIL import Image, ImageDraw, ImageFont

RGBA = Tuple[int, int, int, int]
Box = Tuple[int, int, int, int]  # x, y, w, h


CANONICAL_SIZES: Dict[str, Tuple[int, int]] = {
    # Whole-body templates.
    "full_body_front": (64, 64),
    "full_body_back": (64, 64),
    "full_body_side_left": (64, 64),
    "full_body_side_right": (64, 64),
    # Modular animation cutout parts.
    "head_front": (32, 32),
    "head_back": (32, 32),
    "head_side": (32, 32),
    "torso_front": (48, 48),
    "torso_back": (48, 48),
    "torso_side": (48, 48),
    "pelvis": (32, 32),
    "belt": (48, 24),
    "shoulder_pad": (24, 24),
    "upper_arm": (24, 32),
    "forearm": (24, 32),
    "hand": (16, 16),
    "thigh": (24, 32),
    "shin": (24, 32),
    "boot": (24, 24),
    "armor_module": (24, 24),
    # Fallbacks.
    "limb_vertical": (24, 40),
    "small_part": (24, 24),
    "medium_part": (32, 32),
    "large_part": (48, 48),
    "unknown": (32, 32),
}


@dataclass
class PieceRecord:
    id: str
    role: str
    file: str
    source_bbox: Dict[str, int]
    source_size: Dict[str, int]
    canonical_size: Dict[str, int]
    scale: float
    pasted_at: Dict[str, int]
    anchor_px: Dict[str, int]
    notes: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input", required=True, help="Input sprite breakdown sheet PNG."
    )
    parser.add_argument(
        "--out-dir", required=True, help="Output directory for indexed parts."
    )
    parser.add_argument("--prefix", default="grunt_template", help="Filename prefix.")
    parser.add_argument(
        "--min-area",
        type=int,
        default=80,
        help="Ignore components smaller than this many pixels.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=12,
        help="Alpha threshold for solid pixels.",
    )
    parser.add_argument(
        "--dilate",
        type=int,
        default=2,
        help="Temporary mask dilation radius for grouping tiny separated pixels.",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=2,
        help="Extra crop padding around detected piece bbox.",
    )
    parser.add_argument(
        "--save-raw", action="store_true", help="Also save unscaled cropped pieces."
    )
    parser.add_argument(
        "--no-checker-removal",
        action="store_true",
        help="Disable light checkerboard background flood removal.",
    )
    parser.add_argument(
        "--allow-upscale",
        action="store_true",
        help="Allow small pieces to be scaled up to canonical size.",
    )
    return parser.parse_args()


def is_light_checker_bg(pixel: RGBA) -> bool:
    r, g, b, a = pixel
    if a <= 8:
        return True

    # Generated sheets often bake a white/light-gray checkerboard.
    maxc = max(r, g, b)
    minc = min(r, g, b)
    neutral = (maxc - minc) <= 18
    bright = maxc >= 205
    return neutral and bright


def remove_border_connected_checkerboard(img: Image.Image) -> Image.Image:
    """
    Converts border-connected light checkerboard/white/gray background pixels to alpha 0.
    This is safer than globally deleting white/gray pixels because armor highlights inside
    the sprite are not border-connected.
    """
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    visited = bytearray(w * h)
    q: deque[Tuple[int, int]] = deque()

    def push_if_bg(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        if is_light_checker_bg(px[x, y]):
            visited[idx] = 1
            q.append((x, y))

    for x in range(w):
        push_if_bg(x, 0)
        push_if_bg(x, h - 1)
    for y in range(h):
        push_if_bg(0, y)
        push_if_bg(w - 1, y)

    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                push_if_bg(nx, ny)

    for y in range(h):
        for x in range(w):
            if visited[y * w + x]:
                r, g, b, _a = px[x, y]
                px[x, y] = (r, g, b, 0)

    return img


def build_mask(img: Image.Image, alpha_threshold: int) -> bytearray:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    mask = bytearray(w * h)

    for y in range(h):
        row = y * w
        for x in range(w):
            if px[x, y][3] > alpha_threshold:
                mask[row + x] = 1

    return mask


def dilate_mask(mask: bytearray, w: int, h: int, radius: int) -> bytearray:
    if radius <= 0:
        return mask

    out = bytearray(mask)

    solid_points: List[Tuple[int, int]] = []
    for y in range(h):
        row = y * w
        for x in range(w):
            if mask[row + x]:
                solid_points.append((x, y))

    r2 = radius * radius
    offsets = [
        (dx, dy)
        for dy in range(-radius, radius + 1)
        for dx in range(-radius, radius + 1)
        if dx * dx + dy * dy <= r2
    ]

    for x, y in solid_points:
        for dx, dy in offsets:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                out[ny * w + nx] = 1

    return out


def connected_components(mask: bytearray, w: int, h: int, min_area: int) -> List[Box]:
    visited = bytearray(w * h)
    boxes: List[Box] = []

    for y in range(h):
        for x in range(w):
            start = y * w + x
            if visited[start] or not mask[start]:
                continue

            q: deque[Tuple[int, int]] = deque([(x, y)])
            visited[start] = 1

            minx = maxx = x
            miny = maxy = y
            area = 0

            while q:
                cx, cy = q.popleft()
                area += 1

                if cx < minx:
                    minx = cx
                if cx > maxx:
                    maxx = cx
                if cy < miny:
                    miny = cy
                if cy > maxy:
                    maxy = cy

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        idx = ny * w + nx
                        if not visited[idx] and mask[idx]:
                            visited[idx] = 1
                            q.append((nx, ny))

            bw = maxx - minx + 1
            bh = maxy - miny + 1

            if area >= min_area:
                boxes.append((minx, miny, bw, bh))

    return boxes


def expand_box(box: Box, pad: int, image_w: int, image_h: int) -> Box:
    x, y, w, h = box
    x0 = max(0, x - pad)
    y0 = max(0, y - pad)
    x1 = min(image_w, x + w + pad)
    y1 = min(image_h, y + h + pad)
    return (x0, y0, x1 - x0, y1 - y0)


def classify_piece(
    box: Box, image_size: Tuple[int, int], index_in_sorted: int, sorted_boxes: List[Box]
) -> str:
    """
    Heuristic classifier for the generated grunt template sheet.

    This will not be perfect, but the index.json preserves the original bbox so you can
    rename/reclassify any piece after export without losing traceability.
    """
    x, y, w, h = box
    img_w, img_h = image_size
    cx = x + w / 2
    cy = y + h / 2
    aspect = w / max(1, h)
    area = w * h

    # Top-row large turnaround sprites.
    top_large = [b for b in sorted_boxes if b[1] < img_h * 0.42 and b[3] > img_h * 0.20]
    top_large_sorted = sorted(top_large, key=lambda b: b[0])
    for i, b in enumerate(top_large_sorted):
        if b == box:
            return [
                "full_body_front",
                "full_body_back",
                "full_body_side_left",
                "full_body_side_right",
            ][min(i, 3)]

    # Heads live under the top row and are roughly square/small.
    if cy < img_h * 0.58 and 0.65 <= aspect <= 1.35 and area < img_w * img_h * 0.012:
        # Guess front/back/side by horizontal position.
        if cx < img_w * 0.22:
            return "head_front"
        if cx < img_w * 0.34:
            return "head_back"
        return "head_side"

    # Big torso chunks.
    if h > img_h * 0.11 and w > img_w * 0.055 and cy < img_h * 0.72:
        if cx < img_w * 0.23:
            return "torso_front"
        if cx < img_w * 0.39:
            return "torso_back"
        return "torso_side"

    # Belts/pelvis are wide and relatively short.
    if aspect >= 1.55 and h < img_h * 0.10:
        return "belt"

    if 0.75 <= aspect <= 1.35 and h < img_h * 0.11 and cy > img_h * 0.55:
        if area > img_w * img_h * 0.004:
            return "pelvis"
        return "armor_module"

    # Small armor caps.
    if h < img_h * 0.095 and w < img_w * 0.075 and cy < img_h * 0.78:
        return "shoulder_pad"

    # Hands are tiny and usually near lower-left or near arm clusters.
    if w < img_w * 0.045 and h < img_h * 0.075:
        return "hand"

    # Tall limb pieces.
    if h > w * 1.35:
        if cy > img_h * 0.69:
            # Lower half: legs/shins/boots.
            if h > img_h * 0.14:
                return "shin"
            return "boot"
        # Upper/middle: arms/forearms.
        if cx > img_w * 0.50:
            return "forearm"
        return "upper_arm"

    # Boot-ish: low and squat.
    if cy > img_h * 0.78 and aspect >= 0.85:
        return "boot"

    if area < img_w * img_h * 0.004:
        return "small_part"
    if area < img_w * img_h * 0.012:
        return "medium_part"
    return "large_part"


def resize_into_canvas(
    crop: Image.Image,
    target_size: Tuple[int, int],
    allow_upscale: bool,
) -> Tuple[Image.Image, float, Tuple[int, int]]:
    crop = crop.convert("RGBA")
    tw, th = target_size
    cw, ch = crop.size

    if cw <= 0 or ch <= 0:
        return Image.new("RGBA", target_size, (0, 0, 0, 0)), 1.0, (0, 0)

    scale = min(tw / cw, th / ch)

    if not allow_upscale:
        scale = min(scale, 1.0)

    new_w = max(1, int(round(cw * scale)))
    new_h = max(1, int(round(ch * scale)))

    resized = crop.resize((new_w, new_h), Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    paste_x = (tw - new_w) // 2
    paste_y = (th - new_h) // 2
    canvas.alpha_composite(resized, (paste_x, paste_y))

    return canvas, scale, (paste_x, paste_y)


def make_contact_sheet(
    records: List[PieceRecord], out_dir: Path, thumb_scale: int = 3
) -> None:
    if not records:
        return

    thumbs: List[Tuple[PieceRecord, Image.Image]] = []
    for rec in records:
        img = Image.open(out_dir / rec.file).convert("RGBA")
        tw, th = img.size
        thumb = img.resize(
            (tw * thumb_scale, th * thumb_scale), Image.Resampling.NEAREST
        )
        thumbs.append((rec, thumb))

    cell_w = 220
    cell_h = 180
    cols = 4
    rows = math.ceil(len(thumbs) / cols)

    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(sheet)

    for i, (rec, thumb) in enumerate(thumbs):
        col = i % cols
        row = i // cols
        x0 = col * cell_w
        y0 = row * cell_h

        draw.rectangle(
            (x0, y0, x0 + cell_w - 1, y0 + cell_h - 1), outline=(70, 70, 70, 255)
        )

        px = x0 + (cell_w - thumb.size[0]) // 2
        py = y0 + 12
        sheet.alpha_composite(thumb, (px, py))

        draw.text((x0 + 8, y0 + cell_h - 42), rec.id, fill=(230, 230, 230, 255))
        draw.text((x0 + 8, y0 + cell_h - 24), rec.role, fill=(170, 190, 170, 255))

    sheet.save(out_dir / "index_contact_sheet.png")


def main() -> None:
    args = parse_args()

    input_path = Path(args.input)
    out_dir = Path(args.out_dir)
    raw_dir = out_dir / "_raw"

    out_dir.mkdir(parents=True, exist_ok=True)
    if args.save_raw:
        raw_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(input_path).convert("RGBA")

    if not args.no_checker_removal:
        img = remove_border_connected_checkerboard(img)

    w, h = img.size
    alpha_mask = build_mask(img, args.alpha_threshold)
    seg_mask = dilate_mask(alpha_mask, w, h, args.dilate)

    boxes = connected_components(seg_mask, w, h, args.min_area)
    boxes = [expand_box(b, args.padding, w, h) for b in boxes]

    # Sort top-to-bottom, then left-to-right.
    boxes = sorted(boxes, key=lambda b: (b[1], b[0]))

    records: List[PieceRecord] = []
    role_counts: Dict[str, int] = {}

    for i, box in enumerate(boxes):
        x, y, bw, bh = box
        crop = img.crop((x, y, x + bw, y + bh))

        role = classify_piece(box, (w, h), i, boxes)
        role_counts[role] = role_counts.get(role, 0) + 1

        role_index = role_counts[role]
        piece_id = f"{args.prefix}_{role}_{role_index:02d}"
        filename = f"{piece_id}.png"

        target_size = CANONICAL_SIZES.get(role, CANONICAL_SIZES["unknown"])
        canonical, scale, pasted_at = resize_into_canvas(
            crop, target_size, args.allow_upscale
        )

        canonical.save(out_dir / filename)

        if args.save_raw:
            crop.save(raw_dir / f"{piece_id}_raw.png")

        rec = PieceRecord(
            id=piece_id,
            role=role,
            file=filename,
            source_bbox={"x": x, "y": y, "w": bw, "h": bh},
            source_size={"w": bw, "h": bh},
            canonical_size={"w": target_size[0], "h": target_size[1]},
            scale=round(scale, 6),
            pasted_at={"x": pasted_at[0], "y": pasted_at[1]},
            anchor_px={
                # Default animation anchor: bottom-center of canonical canvas.
                # You can override this per part later in Godot/import tooling.
                "x": target_size[0] // 2,
                "y": target_size[1] - 1,
            },
            notes="Auto-classified from source sheet. Verify role/name before wiring runtime animation.",
        )
        records.append(rec)

    manifest = {
        "asset": "CUSTODIAN enemy grunt modular template parts",
        "source": str(input_path),
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "output_dir": str(out_dir),
        "background_cleanup": {
            "checker_removal": not args.no_checker_removal,
            "alpha_threshold": args.alpha_threshold,
            "dilate": args.dilate,
            "min_area": args.min_area,
            "padding": args.padding,
        },
        "canonical_sizes": {
            k: {"w": v[0], "h": v[1]} for k, v in CANONICAL_SIZES.items()
        },
        "piece_count": len(records),
        "pieces": [asdict(r) for r in records],
    }

    with open(out_dir / "index.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    make_contact_sheet(records, out_dir)

    print(f"Exported {len(records)} pieces")
    print(f"Output: {out_dir}")
    print(f"Index:  {out_dir / 'index.json'}")
    print(f"Preview:{out_dir / 'index_contact_sheet.png'}")


if __name__ == "__main__":
    main()
