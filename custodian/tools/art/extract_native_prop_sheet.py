#!/usr/bin/env python3
"""
extract_native_prop_sheet.py

Extract variable-size sprites from a transparent packed master sheet WITHOUT
resizing them into a fixed grid.

Designed for CUSTODIAN's Meridian civic props master:
- source master: 1254x1254 RGBA
- transparent background
- irregular native-size sprites
- packed with clear alpha gutters
- many sprites are already close to gameplay scale

Default detection parameters are tuned against the current master:
    alpha > 10
    minimum component area = 100 px
    minimum component dimension = 8 px
    4-connected components
    3 px crop padding

The script:
1. Detects alpha-connected sprite bodies.
2. Rejects tiny detached noise components.
3. Preserves native sprite pixels exactly; NO resize/resample.
4. Crops each sprite with transparent padding from the original RGBA source.
5. Computes a suggested floor/contact anchor from the lowest opaque pixels.
6. Emits PNGs, JSON, CSV, source-space coordinate index, contact sheet,
   coverage mask, and extraction diagnostics.

Only Pillow is required.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import statistics
from collections import deque
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image, ImageDraw, ImageFont


@dataclass
class Component:
    raw_id: int
    area: int
    x0: int
    y0: int
    x1: int  # exclusive
    y1: int  # exclusive
    pixels: list[tuple[int, int]]

    @property
    def width(self) -> int:
        return self.x1 - self.x0

    @property
    def height(self) -> int:
        return self.y1 - self.y0

    @property
    def center_x(self) -> float:
        return (self.x0 + self.x1 - 1) / 2.0

    @property
    def center_y(self) -> float:
        return (self.y0 + self.y1 - 1) / 2.0


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=(
            "Extract irregular native-size sprites from a transparent packed "
            "master sheet without resizing."
        )
    )
    p.add_argument("source", type=Path, help="RGBA source master PNG")
    p.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output directory. Default: <source_dir>/<source_stem>__native_extract",
    )
    p.add_argument(
        "--detect-alpha",
        type=int,
        default=10,
        help="Detection mask uses alpha > N. Default: 10",
    )
    p.add_argument(
        "--min-area",
        type=int,
        default=100,
        help="Reject detected components smaller than this many pixels. Default: 100",
    )
    p.add_argument(
        "--min-dimension",
        type=int,
        default=8,
        help="Reject components narrower or shorter than this. Default: 8",
    )
    p.add_argument(
        "--padding",
        type=int,
        default=3,
        help="Transparent/source-context padding around each crop. Default: 3",
    )
    p.add_argument(
        "--connectivity",
        type=int,
        choices=(4, 8),
        default=4,
        help="Connected-component neighborhood. Default: 4",
    )
    p.add_argument(
        "--contact-band",
        type=float,
        default=0.06,
        help=(
            "Fraction of detected height used to estimate bottom contact anchor. "
            "Default: 0.06"
        ),
    )
    p.add_argument(
        "--thumb-box",
        type=int,
        default=144,
        help="Contact-sheet thumbnail box in pixels. Sprites are NOT rescaled in extraction. Default: 144",
    )
    p.add_argument(
        "--contact-cols",
        type=int,
        default=8,
        help="Contact-sheet columns. Default: 8",
    )
    p.add_argument(
        "--strip-low-alpha",
        type=int,
        default=0,
        help=(
            "OPTIONAL: set alpha <= N to zero in extracted copies only. "
            "0 disables. Keep 0 for the authoritative raw extraction."
        ),
    )
    return p.parse_args()


def find_font(size: int) -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
        "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    ]
    for candidate in candidates:
        p = Path(candidate)
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


def neighbor_offsets(connectivity: int) -> Sequence[tuple[int, int]]:
    if connectivity == 8:
        return (
            (-1, -1), (0, -1), (1, -1),
            (-1, 0),           (1, 0),
            (-1, 1),  (0, 1),  (1, 1),
        )
    return ((-1, 0), (1, 0), (0, -1), (0, 1))


def connected_components(
    alpha: bytes,
    width: int,
    height: int,
    detect_alpha: int,
    connectivity: int,
) -> list[Component]:
    """
    Pure-Python component extraction to avoid requiring OpenCV/SciPy.

    `alpha` is one byte per source pixel.
    A pixel participates when alpha > detect_alpha.
    """
    visited = bytearray(width * height)
    offsets = neighbor_offsets(connectivity)
    components: list[Component] = []
    raw_id = 0

    for y in range(height):
        row = y * width
        for x in range(width):
            idx = row + x
            if visited[idx]:
                continue
            visited[idx] = 1
            if alpha[idx] <= detect_alpha:
                continue

            raw_id += 1
            q: deque[tuple[int, int]] = deque([(x, y)])
            pixels: list[tuple[int, int]] = []
            x0 = x1 = x
            y0 = y1 = y

            while q:
                px, py = q.popleft()
                pixels.append((px, py))

                if px < x0:
                    x0 = px
                if px > x1:
                    x1 = px
                if py < y0:
                    y0 = py
                if py > y1:
                    y1 = py

                for dx, dy in offsets:
                    nx = px + dx
                    ny = py + dy
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue

                    nidx = ny * width + nx
                    if visited[nidx]:
                        continue
                    visited[nidx] = 1

                    if alpha[nidx] > detect_alpha:
                        q.append((nx, ny))

            components.append(
                Component(
                    raw_id=raw_id,
                    area=len(pixels),
                    x0=x0,
                    y0=y0,
                    x1=x1 + 1,
                    y1=y1 + 1,
                    pixels=pixels,
                )
            )

    return components


def component_is_valid(c: Component, min_area: int, min_dimension: int) -> bool:
    return (
        c.area >= min_area
        and c.width >= min_dimension
        and c.height >= min_dimension
    )


def padded_bbox(
    c: Component,
    width: int,
    height: int,
    padding: int,
) -> tuple[int, int, int, int]:
    return (
        max(0, c.x0 - padding),
        max(0, c.y0 - padding),
        min(width, c.x1 + padding),
        min(height, c.y1 + padding),
    )


def suggested_contact_anchor(
    c: Component,
    crop_bbox: tuple[int, int, int, int],
    band_fraction: float,
) -> tuple[float, float]:
    """
    Estimate the visual floor-contact point.

    We look only at the lowest band of the detected component, then take the
    median x of those opaque pixels. This is usually better than blind
    canvas-bottom-center for posts, benches, cabinets and irregular rubble.

    This remains metadata, not collision authority.
    """
    crop_x0, crop_y0, _, _ = crop_bbox

    band_rows = max(2, int(math.ceil(c.height * band_fraction)))
    cutoff = c.y1 - band_rows

    bottom_pixels = [(x, y) for x, y in c.pixels if y >= cutoff]
    if not bottom_pixels:
        bottom_pixels = c.pixels

    anchor_x_source = statistics.median(x for x, _ in bottom_pixels)
    anchor_y_source = max(y for _, y in bottom_pixels) + 1

    return (
        float(anchor_x_source - crop_x0),
        float(anchor_y_source - crop_y0),
    )


def size_class(width: int, height: int) -> str:
    """
    Purely geometric audit label. NOT a semantic classification.
    """
    if width <= 40 and height <= 40:
        return "tile_scale"
    if height >= 64 and height >= width * 1.35:
        return "tall_prop"
    if width >= 96 or height >= 96:
        return "large_prop"
    if width >= 56 or height >= 56:
        return "medium_prop"
    return "small_prop"


def sorting_key(c: Component) -> tuple[int, int, int]:
    """
    Approximate visual reading order without assuming a nonexistent grid.

    Quantizing center-y to 32px bands keeps nearby packed sprites broadly
    together while source x remains deterministic.
    """
    row_band = int(round(c.center_y / 32.0))
    return row_band, c.x0, c.y0


def strip_low_alpha(image: Image.Image, threshold: int) -> Image.Image:
    if threshold <= 0:
        return image

    out = image.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a <= threshold:
                pixels[x, y] = (0, 0, 0, 0)
    return out


def draw_source_index(
    source: Image.Image,
    records: list[dict],
    out_path: Path,
) -> None:
    out = source.copy()
    draw = ImageDraw.Draw(out)
    font = find_font(12)

    for r in records:
        x0, y0, x1, y1 = r["detected_bbox"]
        label = f'{r["id"]:03d}'
        draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(0, 255, 255, 220), width=1)

        box = draw.textbbox((0, 0), label, font=font)
        lw = box[2] - box[0]
        lh = box[3] - box[1]
        tx = x0
        ty = max(0, y0 - lh - 3)

        draw.rectangle(
            (tx, ty, tx + lw + 4, ty + lh + 3),
            fill=(0, 0, 0, 220),
        )
        draw.text((tx + 2, ty + 1), label, fill=(255, 255, 0, 255), font=font)

    out.save(out_path)


def checkerboard(width: int, height: int, cell: int = 12) -> Image.Image:
    out = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(out)
    a = (68, 68, 68, 255)
    b = (104, 104, 104, 255)
    for y in range(0, height, cell):
        for x in range(0, width, cell):
            draw.rectangle(
                (x, y, min(width - 1, x + cell - 1), min(height - 1, y + cell - 1)),
                fill=a if ((x // cell) + (y // cell)) % 2 == 0 else b,
            )
    return out


def draw_contact_sheet(
    extracted_dir: Path,
    records: list[dict],
    out_path: Path,
    thumb_box: int,
    cols: int,
) -> None:
    label_h = 34
    pad = 8
    cell_w = thumb_box + pad * 2
    cell_h = thumb_box + label_h + pad * 2
    rows = math.ceil(len(records) / cols)

    sheet = Image.new(
        "RGBA",
        (cell_w * cols, cell_h * rows),
        (20, 22, 24, 255),
    )
    draw = ImageDraw.Draw(sheet)
    font = find_font(11)

    for i, r in enumerate(records):
        col = i % cols
        row = i // cols
        sx = col * cell_w
        sy = row * cell_h

        sprite = Image.open(extracted_dir / r["filename"]).convert("RGBA")

        # Review sheet may downscale oversized sprites to fit; extraction itself
        # is never resized.
        preview = sprite.copy()
        if preview.width > thumb_box or preview.height > thumb_box:
            ratio = min(thumb_box / preview.width, thumb_box / preview.height)
            new_size = (
                max(1, int(round(preview.width * ratio))),
                max(1, int(round(preview.height * ratio))),
            )
            preview = preview.resize(new_size, Image.Resampling.NEAREST)

        bg = checkerboard(thumb_box, thumb_box)
        px = sx + pad + (thumb_box - preview.width) // 2
        py = sy + pad + (thumb_box - preview.height) // 2
        bg.alpha_composite(preview, (px - (sx + pad), py - (sy + pad)))
        sheet.alpha_composite(bg, (sx + pad, sy + pad))

        ax, ay = r["suggested_anchor_px"]
        # Show a source-anchor marker only when preview was not scaled.
        if sprite.size == preview.size:
            marker_x = sx + pad + (thumb_box - sprite.width) // 2 + int(round(ax))
            marker_y = sy + pad + (thumb_box - sprite.height) // 2 + int(round(ay))
            draw.line((marker_x - 3, marker_y, marker_x + 3, marker_y), fill=(0, 255, 255, 255))
            draw.line((marker_x, marker_y - 3, marker_x, marker_y + 3), fill=(0, 255, 255, 255))

        label = (
            f'{r["id"]:03d}  {r["native_content_size"][0]}x{r["native_content_size"][1]}  '
            f'{r["size_class"]}'
        )
        draw.text(
            (sx + pad, sy + pad + thumb_box + 5),
            label,
            fill=(235, 235, 235, 255),
            font=font,
        )

    sheet.save(out_path)


def make_coverage_mask(
    size: tuple[int, int],
    components: list[Component],
    out_path: Path,
) -> None:
    mask = Image.new("RGBA", size, (0, 0, 0, 255))
    pixels = mask.load()

    palette = (
        (0, 220, 255, 255),
        (255, 200, 0, 255),
        (190, 100, 255, 255),
        (120, 255, 120, 255),
    )

    for i, c in enumerate(components):
        color = palette[i % len(palette)]
        for x, y in c.pixels:
            pixels[x, y] = color

    mask.save(out_path)


def write_csv(records: list[dict], path: Path) -> None:
    fields = [
        "id",
        "filename",
        "raw_component_id",
        "area",
        "x0",
        "y0",
        "x1",
        "y1",
        "native_width",
        "native_height",
        "crop_width",
        "crop_height",
        "anchor_x",
        "anchor_y",
        "size_class",
        "occupancy",
    ]

    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()

        for r in records:
            x0, y0, x1, y1 = r["detected_bbox"]
            ax, ay = r["suggested_anchor_px"]
            writer.writerow(
                {
                    "id": r["id"],
                    "filename": r["filename"],
                    "raw_component_id": r["raw_component_id"],
                    "area": r["area"],
                    "x0": x0,
                    "y0": y0,
                    "x1": x1,
                    "y1": y1,
                    "native_width": r["native_content_size"][0],
                    "native_height": r["native_content_size"][1],
                    "crop_width": r["crop_size"][0],
                    "crop_height": r["crop_size"][1],
                    "anchor_x": ax,
                    "anchor_y": ay,
                    "size_class": r["size_class"],
                    "occupancy": r["occupancy"],
                }
            )


def main() -> None:
    args = parse_args()

    source_path = args.source.resolve()
    if not source_path.is_file():
        raise SystemExit(f"Missing source: {source_path}")

    source = Image.open(source_path).convert("RGBA")
    width, height = source.size

    out_dir = (
        args.out.resolve()
        if args.out is not None
        else source_path.parent / f"{source_path.stem}__native_extract"
    )
    extracted_dir = out_dir / "sprites"
    out_dir.mkdir(parents=True, exist_ok=True)
    extracted_dir.mkdir(parents=True, exist_ok=True)

    alpha_bytes = source.getchannel("A").tobytes()

    all_components = connected_components(
        alpha=alpha_bytes,
        width=width,
        height=height,
        detect_alpha=args.detect_alpha,
        connectivity=args.connectivity,
    )

    valid = [
        c
        for c in all_components
        if component_is_valid(c, args.min_area, args.min_dimension)
    ]
    rejected = [
        c
        for c in all_components
        if not component_is_valid(c, args.min_area, args.min_dimension)
    ]

    valid.sort(key=sorting_key)

    records: list[dict] = []

    for sprite_id, c in enumerate(valid, start=1):
        crop_box = padded_bbox(c, width, height, args.padding)
        crop = source.crop(crop_box)

        # Never mutate the authoritative extraction unless explicitly requested.
        crop_out = strip_low_alpha(crop, args.strip_low_alpha)

        filename = (
            f"sprite_{sprite_id:03d}"
            f"__native_{c.width}x{c.height}"
            f"__crop_{crop.width}x{crop.height}.png"
        )
        crop_out.save(extracted_dir / filename)

        anchor = suggested_contact_anchor(
            c,
            crop_bbox=crop_box,
            band_fraction=args.contact_band,
        )

        occupancy = c.area / float(c.width * c.height)

        records.append(
            {
                "id": sprite_id,
                "filename": filename,
                "raw_component_id": c.raw_id,
                "area": c.area,
                "detected_bbox": [c.x0, c.y0, c.x1, c.y1],
                "crop_bbox": list(crop_box),
                "native_content_size": [c.width, c.height],
                "crop_size": [crop.width, crop.height],
                "center_source_px": [c.center_x, c.center_y],
                "suggested_anchor_px": [anchor[0], anchor[1]],
                "anchor_semantics": "suggested_floor_contact_only_not_collision_authority",
                "size_class": size_class(c.width, c.height),
                "occupancy": round(occupancy, 6),
                "resized": False,
            }
        )

    rejected_records = [
        {
            "raw_component_id": c.raw_id,
            "area": c.area,
            "bbox": [c.x0, c.y0, c.x1, c.y1],
            "size": [c.width, c.height],
        }
        for c in rejected
    ]

    manifest = {
        "schema": "custodian.native_prop_sheet_extract.v1",
        "source": str(source_path),
        "source_size": [width, height],
        "source_mode": "RGBA",
        "authoritative_rule": (
            "Extracted sprites preserve native source pixels. "
            "No resizing/resampling is performed."
        ),
        "detection": {
            "alpha_rule": f"alpha > {args.detect_alpha}",
            "connectivity": args.connectivity,
            "min_area": args.min_area,
            "min_dimension": args.min_dimension,
            "padding": args.padding,
            "contact_band_fraction": args.contact_band,
            "strip_low_alpha": args.strip_low_alpha,
        },
        "component_counts": {
            "all_detected": len(all_components),
            "accepted": len(valid),
            "rejected": len(rejected),
        },
        "sprites": records,
        "rejected_components": rejected_records,
    }

    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    write_csv(records, out_dir / "manifest.csv")
    draw_source_index(source, records, out_dir / "source_index.png")
    draw_contact_sheet(
        extracted_dir,
        records,
        out_dir / "contact_sheet.png",
        args.thumb_box,
        args.contact_cols,
    )
    make_coverage_mask(
        source.size,
        valid,
        out_dir / "coverage_mask.png",
    )

    # Human-readable summary with a deliberate warning if count differs from the
    # tuned master-sheet expectation.
    summary_lines = [
        "CUSTODIAN native prop-sheet extraction",
        f"source: {source_path}",
        f"source size: {width}x{height}",
        "",
        f"all detected alpha components: {len(all_components)}",
        f"accepted native sprites: {len(valid)}",
        f"rejected tiny/noise components: {len(rejected)}",
        "",
        f"detection: alpha > {args.detect_alpha}",
        f"connectivity: {args.connectivity}",
        f"minimum area: {args.min_area}",
        f"minimum dimension: {args.min_dimension}",
        f"crop padding: {args.padding}",
        "",
        "NO SPRITES WERE RESIZED.",
        "Suggested anchors are presentation metadata only.",
        "",
    ]

    if source.size == (1254, 1254):
        summary_lines += [
            "Current Meridian master reference:",
            "  tuned expectation with default parameters: approximately 224 accepted sprites",
            f"  this run: {len(valid)} accepted sprites",
            "",
            (
                "If this differs substantially, inspect source_index.png and "
                "contact_sheet.png before changing thresholds."
            ),
        ]

    (out_dir / "README.txt").write_text(
        "\n".join(summary_lines) + "\n",
        encoding="utf-8",
    )

    print("\n".join(summary_lines))
    print()
    print(f"WROTE: {out_dir}")
    print(f"  sprites/:       {len(records)} PNGs")
    print(f"  manifest.json")
    print(f"  manifest.csv")
    print(f"  source_index.png")
    print(f"  contact_sheet.png")
    print(f"  coverage_mask.png")
    print(f"  README.txt")


if __name__ == "__main__":
    main()
