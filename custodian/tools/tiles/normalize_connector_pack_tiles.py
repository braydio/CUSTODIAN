#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from collections import deque
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

from PIL import Image, ImageFilter

CONNECTOR_TILES = [
    {
        "id": "terrain_connector_ground_32",
        "file": "terrain_connector_ground_32.png",
        "role": "connector_floor",
        "walkable": True,
        "region_type": "pre_terrain_required_connector",
        "zone": "authority_repair",
    },
    {
        "id": "terrain_connector_cracked_32",
        "file": "terrain_connector_cracked_32.png",
        "role": "connector_floor_variant",
        "walkable": True,
        "region_type": "pre_terrain_required_connector",
        "zone": "authority_repair",
    },
    {
        "id": "terrain_connector_gravel_32",
        "file": "terrain_connector_gravel_32.png",
        "role": "connector_floor_variant",
        "walkable": True,
        "region_type": "pre_terrain_required_connector",
        "zone": "authority_repair",
    },
    {
        "id": "terrain_connector_dust_32",
        "file": "terrain_connector_dust_32.png",
        "role": "connector_floor_variant",
        "walkable": True,
        "region_type": "pre_terrain_required_connector",
        "zone": "authority_repair",
    },
    {
        "id": "terrain_connector_edge_n_32",
        "file": "terrain_connector_edge_n_32.png",
        "role": "connector_edge",
        "edge": "north",
        "walkable": True,
    },
    {
        "id": "terrain_connector_edge_s_32",
        "file": "terrain_connector_edge_s_32.png",
        "role": "connector_edge",
        "edge": "south",
        "walkable": True,
    },
    {
        "id": "terrain_connector_edge_e_32",
        "file": "terrain_connector_edge_e_32.png",
        "role": "connector_edge",
        "edge": "east",
        "walkable": True,
    },
    {
        "id": "terrain_connector_edge_w_32",
        "file": "terrain_connector_edge_w_32.png",
        "role": "connector_edge",
        "edge": "west",
        "walkable": True,
    },
    {
        "id": "terrain_connector_outer_corner_ne_32",
        "file": "terrain_connector_outer_corner_ne_32.png",
        "role": "connector_outer_corner",
        "corner": "ne",
        "walkable": True,
    },
    {
        "id": "terrain_connector_outer_corner_nw_32",
        "file": "terrain_connector_outer_corner_nw_32.png",
        "role": "connector_outer_corner",
        "corner": "nw",
        "walkable": True,
    },
    {
        "id": "terrain_connector_outer_corner_se_32",
        "file": "terrain_connector_outer_corner_se_32.png",
        "role": "connector_outer_corner",
        "corner": "se",
        "walkable": True,
    },
    {
        "id": "terrain_connector_outer_corner_sw_32",
        "file": "terrain_connector_outer_corner_sw_32.png",
        "role": "connector_outer_corner",
        "corner": "sw",
        "walkable": True,
    },
    {
        "id": "terrain_connector_inner_corner_ne_32",
        "file": "terrain_connector_inner_corner_ne_32.png",
        "role": "connector_inner_corner",
        "corner": "ne",
        "walkable": True,
    },
    {
        "id": "terrain_connector_inner_corner_nw_32",
        "file": "terrain_connector_inner_corner_nw_32.png",
        "role": "connector_inner_corner",
        "corner": "nw",
        "walkable": True,
    },
    {
        "id": "terrain_connector_inner_corner_se_32",
        "file": "terrain_connector_inner_corner_se_32.png",
        "role": "connector_inner_corner",
        "corner": "se",
        "walkable": True,
    },
    {
        "id": "terrain_connector_inner_corner_sw_32",
        "file": "terrain_connector_inner_corner_sw_32.png",
        "role": "connector_inner_corner",
        "corner": "sw",
        "walkable": True,
    },
    {
        "id": "terrain_connector_centerline_32",
        "file": "terrain_connector_centerline_32.png",
        "role": "connector_centerline",
        "walkable": True,
    },
    {
        "id": "terrain_connector_broken_patch_32",
        "file": "terrain_connector_broken_patch_32.png",
        "role": "connector_damaged",
        "walkable": True,
    },
]


INDEX_RE = re.compile(
    r"manifest[-_]index[-_]?\(?(\d+)\)?|index[-_]?\(?(\d+)\)?", re.IGNORECASE
)


def parse_index(path: Path) -> int:
    match = INDEX_RE.search(path.stem)
    if not match:
        raise ValueError(f"Could not parse manifest index from filename: {path.name}")

    for group in match.groups():
        if group is not None:
            return int(group)

    raise ValueError(f"Could not parse manifest index from filename: {path.name}")


def ensure_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def edge_pixels(img: Image.Image) -> Iterable[Tuple[int, int, int, int]]:
    w, h = img.size
    px = img.load()
    for x in range(w):
        yield px[x, 0]
        yield px[x, h - 1]
    for y in range(h):
        yield px[0, y]
        yield px[w - 1, y]


def looks_like_baked_checker_rgb(rgb: Tuple[int, int, int]) -> bool:
    r, g, b = rgb
    avg = (r + g + b) / 3.0
    spread = max(r, g, b) - min(r, g, b)

    # Typical baked transparency checker is light, low-saturation gray/white.
    return avg >= 135 and spread <= 22


def color_close(
    a: Tuple[int, int, int], b: Tuple[int, int, int], tolerance: int
) -> bool:
    return (
        abs(a[0] - b[0]) <= tolerance
        and abs(a[1] - b[1]) <= tolerance
        and abs(a[2] - b[2]) <= tolerance
    )


def remove_border_connected_checkerboard(
    img: Image.Image, tolerance: int = 18
) -> Tuple[Image.Image, bool]:
    """
    If a saved image has baked checkerboard pixels instead of alpha, remove only
    border-connected light gray/white checker pixels. This avoids deleting detail
    inside the tile.
    """
    img = img.copy().convert("RGBA")
    w, h = img.size
    px = img.load()

    # If the image already has real alpha, don't invent background removal.
    alpha_values = [p[3] for p in edge_pixels(img)]
    if min(alpha_values) < 250:
        return img, False

    candidates: List[Tuple[int, int, int]] = []
    for rgba in edge_pixels(img):
        rgb = rgba[:3]
        if looks_like_baked_checker_rgb(rgb):
            if not any(color_close(rgb, c, tolerance) for c in candidates):
                candidates.append(rgb)
        if len(candidates) >= 8:
            break

    if not candidates:
        return img, False

    def is_bg(x: int, y: int) -> bool:
        rgba = px[x, y]
        if rgba[3] < 250:
            return True
        rgb = rgba[:3]
        return any(color_close(rgb, c, tolerance) for c in candidates)

    visited = set()
    queue: deque[Tuple[int, int]] = deque()

    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    removed = False
    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        key = (x, y)
        if key in visited:
            continue
        visited.add(key)
        if not is_bg(x, y):
            continue

        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)
        removed = True

        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    return img, removed


def alpha_bbox(img: Image.Image, threshold: int = 8) -> Tuple[int, int, int, int]:
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("Image has no non-transparent pixels after cleanup.")
    return bbox


def square_canvas_from_bbox(
    img: Image.Image,
    bbox: Tuple[int, int, int, int],
    padding_ratio: float,
) -> Image.Image:
    left, top, right, bottom = bbox
    content_w = right - left
    content_h = bottom - top
    side = max(content_w, content_h)
    padding = int(round(side * padding_ratio))
    side += padding * 2

    center_x = (left + right) / 2.0
    center_y = (top + bottom) / 2.0

    crop_left = int(round(center_x - side / 2.0))
    crop_top = int(round(center_y - side / 2.0))
    crop_right = crop_left + side
    crop_bottom = crop_top + side

    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))

    src_left = max(0, crop_left)
    src_top = max(0, crop_top)
    src_right = min(img.size[0], crop_right)
    src_bottom = min(img.size[1], crop_bottom)

    crop = img.crop((src_left, src_top, src_right, src_bottom))
    paste_x = src_left - crop_left
    paste_y = src_top - crop_top
    canvas.alpha_composite(crop, (paste_x, paste_y))
    return canvas


def resize_square(img: Image.Image, size: int, sharpen: bool = False) -> Image.Image:
    out = img.resize((size, size), Image.Resampling.LANCZOS)
    if sharpen:
        out = out.filter(ImageFilter.UnsharpMask(radius=0.6, percent=115, threshold=2))
    return out


def has_suspicious_checker_pixels(img: Image.Image) -> bool:
    """
    Simple sanity check for opaque light-gray checker remnants in corners/edges.
    """
    for rgba in edge_pixels(img):
        if rgba[3] > 240 and looks_like_baked_checker_rgb(rgba[:3]):
            return True
    return False


def write_manifest(
    manifest_path: Path, tiles: List[Dict], source_dir: Path, runtime_dir: Path
) -> None:
    manifest = {
        "id": "terrain_connector_pack",
        "version": 1,
        "source_type": "individual_ai_generated_tiles",
        "source_dir": "res://content/tiles/terrain/source/generated/connector/indexed_tiles/",
        "normalized_source_dir": "res://content/tiles/terrain/source/generated/connector/normalized_1024/",
        "preview_dir": "res://content/tiles/terrain/source/generated/connector/previews_256/",
        "runtime_dir": "res://content/tiles/terrain/runtime/connector/",
        "tile_size": 32,
        "background_policy": "transparent_or_checker_cleanup_applied",
        "role": "procgen_authority_repair_connector",
        "tiles": tiles,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Normalize individual connector pack PNGs into uniform source/previews/runtime 32x32 tiles."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="CUSTODIAN repo root. Default: current directory.",
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=None,
        help="Directory containing connector_pack_ai_source_manifest_index_(n).png files.",
    )
    parser.add_argument(
        "--normalized-size",
        type=int,
        default=1024,
        help="Uniform square source size to export. Default: 1024.",
    )
    parser.add_argument(
        "--preview-size",
        type=int,
        default=256,
        help="Preview size to export. Default: 256.",
    )
    parser.add_argument(
        "--runtime-size",
        type=int,
        default=32,
        help="Runtime tile size to export. Default: 32.",
    )
    parser.add_argument(
        "--padding-ratio",
        type=float,
        default=0.08,
        help="Transparent padding around trimmed content before square normalization. Default: 0.08.",
    )
    parser.add_argument(
        "--pattern",
        default="connector_pack_ai_source_manifest-index*.png",
        help="Input filename glob pattern.",
    )
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    custodian_root = repo_root / "custodian"

    input_dir = args.input_dir
    if input_dir is None:
        input_dir = (
            custodian_root
            / "content/tiles/terrain/source/generated/connector/indexed_tiles"
        )
    input_dir = input_dir.resolve()

    normalized_dir = (
        custodian_root
        / "content/tiles/terrain/source/generated/connector/normalized_1024"
    )
    preview_dir = (
        custodian_root / "content/tiles/terrain/source/generated/connector/previews_256"
    )
    runtime_dir = custodian_root / "content/tiles/terrain/runtime/connector"
    manifest_path = (
        custodian_root / "content/tiles/terrain/manifests/connector_pack.game32.json"
    )
    report_dir = repo_root / "reports/terrain_pack_ingest"
    report_path = report_dir / "connector_pack_normalize_report.md"

    for d in [normalized_dir, preview_dir, runtime_dir, report_dir]:
        d.mkdir(parents=True, exist_ok=True)

    files = sorted(input_dir.glob(args.pattern), key=parse_index)

    expected = len(CONNECTOR_TILES)
    if len(files) != expected:
        print(
            f"ERROR: Expected {expected} connector source tiles, found {len(files)} in {input_dir}"
        )
        for f in files:
            print(f"  found index={parse_index(f)} file={f.name}")
        return 2

    report_lines = [
        "# Connector Pack Normalize Report",
        "",
        f"- input_dir: `{input_dir}`",
        f"- normalized_dir: `{normalized_dir}`",
        f"- preview_dir: `{preview_dir}`",
        f"- runtime_dir: `{runtime_dir}`",
        f"- normalized_size: `{args.normalized_size}`",
        f"- preview_size: `{args.preview_size}`",
        f"- runtime_size: `{args.runtime_size}`",
        "",
        "| index | source | tile_id | bbox | checker_cleanup | runtime | warnings |",
        "|---:|---|---|---|---|---|---|",
    ]

    manifest_tiles: List[Dict] = []
    failures: List[str] = []

    for path, tile_def in zip(files, CONNECTOR_TILES):
        index = parse_index(path)
        tile_id = tile_def["id"]

        try:
            img = ensure_rgba(path)
            cleaned, checker_cleanup = remove_border_connected_checkerboard(img)
            bbox = alpha_bbox(cleaned)
            square = square_canvas_from_bbox(cleaned, bbox, args.padding_ratio)

            normalized = resize_square(square, args.normalized_size, sharpen=False)
            preview = resize_square(square, args.preview_size, sharpen=True)
            runtime = resize_square(square, args.runtime_size, sharpen=True)

            normalized_path = normalized_dir / tile_def["file"].replace(
                "_32.png", "_1024.png"
            )
            preview_path = preview_dir / tile_def["file"].replace("_32.png", "_256.png")
            runtime_path = runtime_dir / tile_def["file"]

            normalized.save(normalized_path)
            preview.save(preview_path)
            runtime.save(runtime_path)

            warnings: List[str] = []
            if has_suspicious_checker_pixels(runtime):
                warnings.append("possible checker remnants on runtime edge")
            if square.size[0] < 64 or square.size[1] < 64:
                warnings.append("very small source crop")
            if runtime.size != (args.runtime_size, args.runtime_size):
                warnings.append("bad runtime size")
                failures.append(f"{tile_id}: runtime size is {runtime.size}")

            manifest_entry = dict(tile_def)
            manifest_entry["source_index"] = index
            manifest_entry["source_file"] = path.name
            manifest_entry["normalized_source_file"] = normalized_path.name
            manifest_entry["preview_file"] = preview_path.name
            manifest_tiles.append(manifest_entry)

            report_lines.append(
                f"| {index} | `{path.name}` | `{tile_id}` | `{bbox}` | "
                f"{'yes' if checker_cleanup else 'no'} | `{runtime_path.relative_to(repo_root)}` | "
                f"{'; '.join(warnings) if warnings else ''} |"
            )

            print(f"[ok] index={index:02d} -> {tile_id}")

        except Exception as exc:
            failures.append(f"{path.name}: {exc}")
            report_lines.append(
                f"| {index} | `{path.name}` | `{tile_id}` | n/a | n/a | n/a | ERROR: {exc} |"
            )
            print(f"[error] {path.name}: {exc}")

    write_manifest(manifest_path, manifest_tiles, normalized_dir, runtime_dir)
    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

    print()
    print(f"Wrote manifest: {manifest_path}")
    print(f"Wrote report:   {report_path}")

    if failures:
        print()
        print("FAILURES:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print()
    print("connector pack normalization complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
