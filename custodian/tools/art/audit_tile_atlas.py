#!/usr/bin/env python3

import argparse
import csv
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def parse_args():
    parser = argparse.ArgumentParser(
        description="Audit, coordinate-index, and alpha-clean a 32px tile atlas."
    )
    parser.add_argument(
        "atlas",
        type=Path,
        help="Path to the source atlas PNG",
    )
    parser.add_argument(
        "--cell",
        type=int,
        default=32,
        help="Cell size in pixels (default: 32)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Optional output directory (default: same directory as atlas)",
    )
    parser.add_argument(
        "--flood-threshold",
        type=int,
        default=30,
        help="Near-black threshold for border-connected cleanup flood (default: 30)",
    )
    parser.add_argument(
        "--halo-threshold",
        type=int,
        default=48,
        help="Near-black threshold for one-pixel halo cleanup (default: 48)",
    )
    parser.add_argument(
        "--font-size",
        type=int,
        default=10,
        help="Coordinate label font size (default: 10)",
    )
    parser.add_argument(
        "--no-clean",
        action="store_true",
        help="Skip cleanup pass; still emit coords and audit outputs",
    )
    return parser.parse_args()


def load_font(size: int):
    candidates = [
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
        "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def checkerboard(width: int, height: int, block: int = 16):
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    a = (160, 160, 160, 255)
    b = (210, 210, 210, 255)
    for y in range(0, height, block):
        for x in range(0, width, block):
            color = a if ((x // block) + (y // block)) % 2 == 0 else b
            draw.rectangle([x, y, x + block - 1, y + block - 1], fill=color)
    return img


def dark(pixel, threshold: int) -> bool:
    r, g, b, a = pixel
    return a > 0 and max(r, g, b) <= threshold


def neighbors4(x, y):
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1


def make_coords_overlay(image: Image.Image, cell: int, font) -> Image.Image:
    out = image.copy()
    draw = ImageDraw.Draw(out)

    cols = out.width // cell
    rows = out.height // cell

    for cy in range(rows):
        for cx in range(cols):
            left = cx * cell
            top = cy * cell
            right = left + cell - 1
            bottom = top + cell - 1

            draw.rectangle(
                [left, top, right, bottom],
                outline=(255, 0, 0, 160),
                width=1,
            )

            label = f"{cx},{cy}"
            tx = left + 2
            ty = top + 2

            bbox = draw.textbbox((tx, ty), label, font=font)
            draw.rectangle(
                [bbox[0] - 1, bbox[1] - 1, bbox[2] + 1, bbox[3] + 1],
                fill=(0, 0, 0, 180),
            )
            draw.text((tx, ty), label, fill=(255, 255, 0, 255), font=font)

    return out


def audit_cells(image: Image.Image, cell: int, flood_threshold: int):
    cols = image.width // cell
    rows = image.height // cell
    px = image.load()

    cell_rows = []
    total_pixels = image.width * image.height
    total_transparent = 0
    total_dark = 0
    total_border_dark = 0

    for cy in range(rows):
        for cx in range(cols):
            left = cx * cell
            top = cy * cell
            right = left + cell
            bottom = top + cell

            transparent = 0
            dark_count = 0
            border_dark = 0
            border_transparent = 0
            opaque = 0

            for y in range(top, bottom):
                for x in range(left, right):
                    r, g, b, a = px[x, y]
                    if a == 0:
                        transparent += 1
                    else:
                        opaque += 1
                    if dark((r, g, b, a), flood_threshold):
                        dark_count += 1
                    if x == left or x == right - 1 or y == top or y == bottom - 1:
                        if dark((r, g, b, a), flood_threshold):
                            border_dark += 1
                        if a == 0:
                            border_transparent += 1

            total_transparent += transparent
            total_dark += dark_count
            total_border_dark += border_dark

            cell_rows.append(
                {
                    "x": cx,
                    "y": cy,
                    "index": cy * cols + cx,
                    "left": left,
                    "top": top,
                    "right_exclusive": right,
                    "bottom_exclusive": bottom,
                    "pixels": cell * cell,
                    "opaque_pixels": opaque,
                    "transparent_pixels": transparent,
                    "transparent_pct": round((transparent / (cell * cell)) * 100, 4),
                    "dark_pixels": dark_count,
                    "dark_pct": round((dark_count / (cell * cell)) * 100, 4),
                    "border_dark_pixels": border_dark,
                    "border_transparent_pixels": border_transparent,
                }
            )

    summary = {
        "width": image.width,
        "height": image.height,
        "cell_size": cell,
        "cols": cols,
        "rows": rows,
        "total_pixels": total_pixels,
        "transparent_pixels": total_transparent,
        "transparent_pct": round((total_transparent / total_pixels) * 100, 4),
        "dark_pixels": total_dark,
        "dark_pct": round((total_dark / total_pixels) * 100, 4),
        "border_dark_pixels": total_border_dark,
    }

    return summary, cell_rows


def alpha_clean(
    image: Image.Image, cell: int, flood_threshold: int, halo_threshold: int
):
    cleaned = image.copy().convert("RGBA")
    pixels = cleaned.load()

    cols = cleaned.width // cell
    rows = cleaned.height // cell

    total_removed_flood = 0
    total_removed_halo = 0

    for cy in range(rows):
        for cx in range(cols):
            left = cx * cell
            top = cy * cell
            right = left + cell
            bottom = top + cell

            queue = deque()
            visited = set()
            remove = set()

            for x in range(left, right):
                queue.append((x, top))
                queue.append((x, bottom - 1))
            for y in range(top, bottom):
                queue.append((left, y))
                queue.append((right - 1, y))

            while queue:
                x, y = queue.popleft()

                if (x, y) in visited:
                    continue
                visited.add((x, y))

                if not (left <= x < right and top <= y < bottom):
                    continue

                if not dark(pixels[x, y], flood_threshold):
                    continue

                remove.add((x, y))

                for nx, ny in neighbors4(x, y):
                    if (
                        left <= nx < right
                        and top <= ny < bottom
                        and (nx, ny) not in visited
                    ):
                        queue.append((nx, ny))

            for x, y in remove:
                pixels[x, y] = (0, 0, 0, 0)
            total_removed_flood += len(remove)

            halo = set()
            for y in range(top, bottom):
                for x in range(left, right):
                    if pixels[x, y][3] == 0:
                        continue
                    if not dark(pixels[x, y], halo_threshold):
                        continue

                    touching_alpha = False
                    for nx, ny in neighbors4(x, y):
                        if not (left <= nx < right and top <= ny < bottom):
                            touching_alpha = True
                            break
                        if pixels[nx, ny][3] == 0:
                            touching_alpha = True
                            break

                    if touching_alpha:
                        halo.add((x, y))

            for x, y in halo:
                pixels[x, y] = (0, 0, 0, 0)
            total_removed_halo += len(halo)

    stats = {
        "removed_flood_pixels": total_removed_flood,
        "removed_halo_pixels": total_removed_halo,
        "removed_total_pixels": total_removed_flood + total_removed_halo,
    }
    return cleaned, stats


def composite_over_checker(image: Image.Image):
    bg = checkerboard(image.width, image.height, block=16)
    out = bg.copy()
    out.alpha_composite(image)
    return out


def make_contact_sheet(
    original: Image.Image, coords: Image.Image, cleaned_review: Image.Image
):
    gap = 16
    label_h = 24
    panel_w = original.width
    panel_h = original.height

    width = panel_w * 3 + gap * 4
    height = panel_h + gap * 2 + label_h

    sheet = Image.new("RGBA", (width, height), (24, 24, 24, 255))
    draw = ImageDraw.Draw(sheet)
    font = load_font(14)

    panels = [
        ("original", original),
        ("coords", coords),
        ("clean_review", cleaned_review),
    ]

    x = gap
    y = gap + label_h
    for label, panel in panels:
        draw.text((x, gap), label, fill=(255, 255, 255, 255), font=font)
        sheet.paste(panel, (x, y), panel)
        x += panel_w + gap

    return sheet


def write_csv(path: Path, rows):
    fieldnames = [
        "x",
        "y",
        "index",
        "left",
        "top",
        "right_exclusive",
        "bottom_exclusive",
        "pixels",
        "opaque_pixels",
        "transparent_pixels",
        "transparent_pct",
        "dark_pixels",
        "dark_pct",
        "border_dark_pixels",
        "border_transparent_pixels",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def main():
    args = parse_args()

    atlas_path = args.atlas.resolve()
    if not atlas_path.is_file():
        raise SystemExit(f"Missing atlas: {atlas_path}")

    out_dir = (
        args.output_dir.resolve() if args.output_dir else atlas_path.parent.resolve()
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    image = Image.open(atlas_path).convert("RGBA")

    if image.width % args.cell != 0 or image.height % args.cell != 0:
        raise SystemExit(
            f"Atlas dimensions {image.width}x{image.height} are not divisible by cell size {args.cell}"
        )

    font = load_font(args.font_size)

    stem = atlas_path.stem

    coords_path = out_dir / f"{stem}__coords.png"
    audit_json_path = out_dir / f"{stem}__audit.json"
    audit_csv_path = out_dir / f"{stem}__cells.csv"
    clean_path = out_dir / f"{stem}__alpha_clean.png"
    clean_review_path = out_dir / f"{stem}__alpha_clean_review.png"
    sheet_path = out_dir / f"{stem}__audit_sheet.png"

    coords_image = make_coords_overlay(image, args.cell, font)
    coords_image.save(coords_path)

    summary, rows = audit_cells(image, args.cell, args.flood_threshold)
    write_csv(audit_csv_path, rows)

    clean_stats = None
    cleaned_image = image.copy()
    if not args.no_clean:
        cleaned_image, clean_stats = alpha_clean(
            image=image,
            cell=args.cell,
            flood_threshold=args.flood_threshold,
            halo_threshold=args.halo_threshold,
        )
        cleaned_image.save(clean_path)

    clean_review = composite_over_checker(cleaned_image)
    clean_review.save(clean_review_path)

    sheet = make_contact_sheet(
        original=composite_over_checker(image),
        coords=coords_image,
        cleaned_review=clean_review,
    )
    sheet.save(sheet_path)

    payload = {
        "source": str(atlas_path),
        "outputs": {
            "coords_png": str(coords_path),
            "audit_json": str(audit_json_path),
            "audit_csv": str(audit_csv_path),
            "alpha_clean_png": None if args.no_clean else str(clean_path),
            "alpha_clean_review_png": str(clean_review_path),
            "audit_sheet_png": str(sheet_path),
        },
        "summary": summary,
        "cleanup": {
            "enabled": not args.no_clean,
            "flood_threshold": args.flood_threshold,
            "halo_threshold": args.halo_threshold,
            "stats": clean_stats,
        },
        "cells": rows,
    }

    with audit_json_path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)

    print()
    print("ATLAS AUDIT COMPLETE")
    print(f"source:             {atlas_path}")
    print(f"coords:             {coords_path}")
    print(f"audit json:         {audit_json_path}")
    print(f"audit csv:          {audit_csv_path}")
    if not args.no_clean:
        print(f"alpha clean:        {clean_path}")
    print(f"alpha clean review: {clean_review_path}")
    print(f"audit sheet:        {sheet_path}")
    print()
    print(
        f"grid: {summary['cols']} cols x {summary['rows']} rows | "
        f"cell={summary['cell_size']} | size={summary['width']}x{summary['height']}"
    )
    print(
        f"transparent_pixels={summary['transparent_pixels']} "
        f"({summary['transparent_pct']}%)"
    )
    if clean_stats is not None:
        print(
            f"cleanup_removed={clean_stats['removed_total_pixels']} "
            f"(flood={clean_stats['removed_flood_pixels']}, "
            f"halo={clean_stats['removed_halo_pixels']})"
        )


if __name__ == "__main__":
    main()
