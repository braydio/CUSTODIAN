#!/usr/bin/env python3
"""
audit_transparent_runtime_assets.py

Scans PNG assets and reports files whose canvas contains large transparent padding.
Useful for finding Godot TileSet/runtime assets that have huge empty atlas regions.

Outputs:
  - CSV report
  - optional JSON report
  - terminal summary of suspicious assets

Example:
  python tools/audit_transparent_runtime_assets.py \
    --root ~/Projects/CUSTODIAN/custodian/content \
    --runtime-only \
    --csv ~/Projects/CUSTODIAN/custodian/reports/transparent_padding_report.csv \
    --json ~/Projects/CUSTODIAN/custodian/reports/transparent_padding_report.json
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Optional

try:
    from PIL import Image
except ImportError:
    print("Missing dependency: Pillow", file=sys.stderr)
    print("Install with: python -m pip install pillow", file=sys.stderr)
    raise


DIM_RE = re.compile(r"(?P<w>\d{2,5})x(?P<h>\d{2,5})", re.IGNORECASE)
FRAME_HINT_RE = re.compile(
    r"__(?P<frames>\d+)f__(?P<size>\d+)(?:\.png)?$", re.IGNORECASE
)


@dataclass
class AssetAudit:
    path: str
    filename: str

    canvas_w: int
    canvas_h: int
    canvas_area: int
    canvas_tiles_w: float
    canvas_tiles_h: float
    canvas_multiple_of_tile: bool

    visible_left: Optional[int]
    visible_top: Optional[int]
    visible_right_exclusive: Optional[int]
    visible_bottom_exclusive: Optional[int]
    visible_w: int
    visible_h: int
    visible_bbox_area: int
    visible_tiles_w_ceil: int
    visible_tiles_h_ceil: int

    transparent_pixel_count: int
    transparent_pixel_pct: float
    bbox_empty_pct: float

    margin_left: int
    margin_top: int
    margin_right: int
    margin_bottom: int
    max_margin_px: int
    max_margin_tiles: float

    parsed_dim_hint: str
    parsed_frame_hint: str

    suggested_trim_canvas_w: int
    suggested_trim_canvas_h: int
    suggested_trim_tiles_w: int
    suggested_trim_tiles_h: int

    issues: str
    suspicious: bool


def parse_dim_hint(path: Path) -> str:
    """
    Parses filename dimension hints like:
      asset_96x128.png
      wall_piece__128x160.png
    """
    match = DIM_RE.search(path.name)
    if not match:
        return ""
    return f"{match.group('w')}x{match.group('h')}"


def parse_frame_hint(path: Path) -> str:
    """
    Parses animation-style suffixes like:
      operator__modular_lower_body__run_01__ne__5f__96.png
    This is not necessarily canvas dimensions, but it is useful context.
    """
    match = FRAME_HINT_RE.search(path.name)
    if not match:
        return ""
    return f"{match.group('frames')}f__{match.group('size')}"


def ceil_to_tile(value: int, tile_size: int) -> int:
    if value <= 0:
        return 0
    return int(math.ceil(value / tile_size) * tile_size)


def is_runtime_path(path: Path) -> bool:
    parts = {p.lower() for p in path.parts}
    return "runtime" in parts


def audit_png(
    path: Path,
    root: Path,
    tile_size: int,
    alpha_threshold: int,
    min_bbox_empty_pct: float,
    min_transparent_pct: float,
    min_margin_px: int,
) -> AssetAudit:
    with Image.open(path) as img:
        img = img.convert("RGBA")
        w, h = img.size
        alpha = img.getchannel("A")

        # Pixels with alpha <= threshold count as transparent.
        alpha_values = alpha.getdata()
        total = w * h
        transparent_count = sum(1 for a in alpha_values if a <= alpha_threshold)
        transparent_pct = transparent_count / total if total else 0.0

        # PIL getbbox on alpha gives bounding box of non-zero pixels.
        # For custom thresholding, convert alpha to binary mask.
        mask = alpha.point(lambda a: 255 if a > alpha_threshold else 0)
        bbox = mask.getbbox()

    issues: list[str] = []

    if bbox is None:
        visible_left = visible_top = visible_right = visible_bottom = None
        visible_w = visible_h = visible_bbox_area = 0
        margin_left = margin_top = margin_right = margin_bottom = 0
        bbox_empty_pct = 1.0
        issues.append("FULLY_TRANSPARENT")
    else:
        left, top, right, bottom = bbox
        visible_left = left
        visible_top = top
        visible_right = right
        visible_bottom = bottom

        visible_w = right - left
        visible_h = bottom - top
        visible_bbox_area = visible_w * visible_h

        margin_left = left
        margin_top = top
        margin_right = w - right
        margin_bottom = h - bottom

        bbox_empty_pct = 1.0 - (visible_bbox_area / total) if total else 0.0

    max_margin = max(margin_left, margin_top, margin_right, margin_bottom)

    canvas_multiple = w % tile_size == 0 and h % tile_size == 0
    if not canvas_multiple:
        issues.append("CANVAS_NOT_MULTIPLE_OF_TILE")

    if bbox_empty_pct >= min_bbox_empty_pct:
        issues.append("LARGE_BBOX_EMPTY_AREA")

    if transparent_pct >= min_transparent_pct:
        issues.append("HIGH_TRANSPARENT_PIXEL_RATIO")

    if max_margin >= min_margin_px:
        issues.append("LARGE_TRANSPARENT_MARGIN")

    # Suggested normalized canvas based on visible bbox, rounded up to tile grid.
    # This does not rewrite the file; it just reports a sane target.
    suggested_w = ceil_to_tile(visible_w, tile_size)
    suggested_h = ceil_to_tile(visible_h, tile_size)
    suggested_tiles_w = suggested_w // tile_size if suggested_w else 0
    suggested_tiles_h = suggested_h // tile_size if suggested_h else 0

    visible_tiles_w_ceil = math.ceil(visible_w / tile_size) if visible_w else 0
    visible_tiles_h_ceil = math.ceil(visible_h / tile_size) if visible_h else 0

    rel_path = path.relative_to(root) if path.is_relative_to(root) else path

    return AssetAudit(
        path=str(rel_path),
        filename=path.name,
        canvas_w=w,
        canvas_h=h,
        canvas_area=total,
        canvas_tiles_w=round(w / tile_size, 3),
        canvas_tiles_h=round(h / tile_size, 3),
        canvas_multiple_of_tile=canvas_multiple,
        visible_left=visible_left,
        visible_top=visible_top,
        visible_right_exclusive=visible_right,
        visible_bottom_exclusive=visible_bottom,
        visible_w=visible_w,
        visible_h=visible_h,
        visible_bbox_area=visible_bbox_area,
        visible_tiles_w_ceil=visible_tiles_w_ceil,
        visible_tiles_h_ceil=visible_tiles_h_ceil,
        transparent_pixel_count=transparent_count,
        transparent_pixel_pct=round(transparent_pct, 4),
        bbox_empty_pct=round(bbox_empty_pct, 4),
        margin_left=margin_left,
        margin_top=margin_top,
        margin_right=margin_right,
        margin_bottom=margin_bottom,
        max_margin_px=max_margin,
        max_margin_tiles=round(max_margin / tile_size, 3),
        parsed_dim_hint=parse_dim_hint(path),
        parsed_frame_hint=parse_frame_hint(path),
        suggested_trim_canvas_w=suggested_w,
        suggested_trim_canvas_h=suggested_h,
        suggested_trim_tiles_w=suggested_tiles_w,
        suggested_trim_tiles_h=suggested_tiles_h,
        issues=";".join(issues),
        suspicious=bool(issues),
    )


def write_csv(rows: list[AssetAudit], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f, fieldnames=list(asdict(rows[0]).keys()) if rows else []
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(asdict(row))


def write_json(rows: list[AssetAudit], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as f:
        json.dump([asdict(r) for r in rows], f, indent=2)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit PNG runtime assets for excessive transparent padding."
    )

    parser.add_argument(
        "--root",
        type=Path,
        default=Path.cwd(),
        help="Root folder to scan. Default: current directory.",
    )
    parser.add_argument(
        "--runtime-only",
        action="store_true",
        help="Only scan paths containing a /runtime/ directory segment.",
    )
    parser.add_argument(
        "--tile-size",
        type=int,
        default=32,
        help="Tile size used for tile-grid calculations. Default: 32.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=0,
        help="Alpha <= this value counts as transparent. Default: 0.",
    )
    parser.add_argument(
        "--min-bbox-empty-pct",
        type=float,
        default=0.45,
        help="Flag if empty area outside visible bounding box is at least this ratio. Default: 0.45.",
    )
    parser.add_argument(
        "--min-transparent-pct",
        type=float,
        default=0.65,
        help="Flag if transparent pixels are at least this ratio. Default: 0.65.",
    )
    parser.add_argument(
        "--min-margin-px",
        type=int,
        default=32,
        help="Flag if any transparent margin is at least this many pixels. Default: 32.",
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=Path("transparent_padding_report.csv"),
        help="CSV output path.",
    )
    parser.add_argument(
        "--json",
        type=Path,
        default=None,
        help="Optional JSON output path.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Print all scanned assets instead of only suspicious ones.",
    )

    args = parser.parse_args()

    root = args.root.expanduser().resolve()

    if not root.exists():
        print(f"Root does not exist: {root}", file=sys.stderr)
        return 1

    pngs = sorted(root.rglob("*.png"))

    if args.runtime_only:
        pngs = [p for p in pngs if is_runtime_path(p)]

    rows: list[AssetAudit] = []

    for png in pngs:
        try:
            rows.append(
                audit_png(
                    path=png,
                    root=root,
                    tile_size=args.tile_size,
                    alpha_threshold=args.alpha_threshold,
                    min_bbox_empty_pct=args.min_bbox_empty_pct,
                    min_transparent_pct=args.min_transparent_pct,
                    min_margin_px=args.min_margin_px,
                )
            )
        except Exception as exc:
            print(f"ERROR reading {png}: {exc}", file=sys.stderr)

    if not rows:
        print("No PNGs found.")
        return 0

    # Sort suspicious assets to top, then worst bbox empty percentage, then max margin.
    rows.sort(
        key=lambda r: (
            not r.suspicious,
            -r.bbox_empty_pct,
            -r.max_margin_px,
            r.path,
        )
    )

    write_csv(rows, args.csv.expanduser().resolve())

    if args.json:
        write_json(rows, args.json.expanduser().resolve())

    suspicious = [r for r in rows if r.suspicious]

    print()
    print(f"Scanned PNGs:      {len(rows)}")
    print(f"Suspicious assets: {len(suspicious)}")
    print(f"CSV report:        {args.csv.expanduser().resolve()}")
    if args.json:
        print(f"JSON report:       {args.json.expanduser().resolve()}")
    print()

    display_rows = rows if args.all else suspicious

    for r in display_rows[:80]:
        print(
            f"{r.path}\n"
            f"  canvas={r.canvas_w}x{r.canvas_h} "
            f"({r.canvas_tiles_w}x{r.canvas_tiles_h} tiles), "
            f"visible={r.visible_w}x{r.visible_h} "
            f"({r.visible_tiles_w_ceil}x{r.visible_tiles_h_ceil} tiles), "
            f"bbox_empty={r.bbox_empty_pct:.0%}, "
            f"transparent={r.transparent_pixel_pct:.0%}\n"
            f"  margins L/T/R/B={r.margin_left}/{r.margin_top}/{r.margin_right}/{r.margin_bottom}px, "
            f"suggest_trim_canvas={r.suggested_trim_canvas_w}x{r.suggested_trim_canvas_h}, "
            f"issues={r.issues or 'OK'}"
        )

        if r.parsed_dim_hint or r.parsed_frame_hint:
            print(
                f"  parsed hints: dim={r.parsed_dim_hint or '-'} "
                f"frame={r.parsed_frame_hint or '-'}"
            )

        print()

    if len(display_rows) > 80:
        print(f"... {len(display_rows) - 80} more rows in the CSV report.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
