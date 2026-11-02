#!/usr/bin/env python3
"""Interactively classify tile cells from a terrain sheet.

The script crops one grid cell at a time, previews it in the terminal when
possible, prompts for procgen-relevant metadata, and writes a JSON mapping.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


TERRAIN_CHOICES = {
    "f": "floor",
    "g": "ground_detail",
    "t": "terrain_wall_top",
    "s": "terrain_wall_side",
    "c": "terrain_corner",
    "p": "pillar_or_peak",
    "r": "ramp_or_slope",
    "d": "decor_only",
    "v": "void_or_empty",
    "u": "unknown",
}

SOCKET_CHOICES = {
    "o": "open",
    "b": "blocked",
    "c": "cliff",
    "w": "wall",
    "e": "edge",
    "n": "none",
    "u": "unknown",
}

COLLISION_CHOICES = {
    "n": "none",
    "f": "full",
    "t": "top_edge",
    "b": "bottom_edge",
    "l": "left_edge",
    "r": "right_edge",
    "p": "partial",
    "u": "unknown",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Preview and classify each tile cell in a terrain sheet. "
            "Requires ImageMagick 'magick' for cell crops."
        ),
        epilog=(
            "During classification, use 'stamp 96x128' for pixel-sized chunks "
            "or 'stamp 3x4' / 'stamp 3cx4c' for cell-sized chunks."
        ),
    )
    parser.add_argument("image", type=Path, help="Source PNG to classify.")
    parser.add_argument(
        "-o",
        "--out",
        type=Path,
        default=None,
        help="Output JSON path. Defaults beside the image as <stem>.mapping.json.",
    )
    parser.add_argument("--tile-size", type=int, default=32, help="Cell size in pixels.")
    parser.add_argument("--cols", type=int, default=None, help="Limit columns to classify.")
    parser.add_argument("--rows", type=int, default=None, help="Limit rows to classify.")
    parser.add_argument("--start-col", type=int, default=0, help="First column to classify.")
    parser.add_argument("--start-row", type=int, default=0, help="First row to classify.")
    parser.add_argument(
        "--scale",
        type=int,
        default=10,
        help="Preview scale multiplier for cropped cell images.",
    )
    parser.add_argument(
        "--context-cells",
        type=int,
        default=2,
        help="Number of surrounding cells to include in a context preview.",
    )
    parser.add_argument(
        "--no-preview",
        action="store_true",
        help="Do not attempt terminal image previews.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Re-prompt cells already present in the output JSON.",
    )
    return parser.parse_args()


def require_tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"Required tool not found: {name}")
    return path


def run_text(cmd: list[str]) -> str:
    result = subprocess.run(cmd, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def get_image_size(image: Path) -> tuple[int, int]:
    magick = require_tool("magick")
    output = run_text([magick, "identify", "-format", "%w %h", str(image)])
    width, height = output.split()
    return int(width), int(height)


def load_mapping(out_path: Path, image: Path, tile_size: int, width: int, height: int) -> dict[str, Any]:
    if out_path.exists():
        with out_path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    else:
        data = {}

    data.setdefault("source_image", str(image))
    data.setdefault("tile_size", tile_size)
    data.setdefault("image_size", [width, height])
    data.setdefault("schema", "custodian_terrain_cell_mapping_v1")
    data.setdefault("cells", {})
    data.setdefault("stamps", {})
    return data


def save_mapping(out_path: Path, data: dict[str, Any]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = out_path.with_suffix(out_path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")
    tmp_path.replace(out_path)


def crop_cell(
    image: Path,
    out_path: Path,
    col: int,
    row: int,
    tile_size: int,
    scale: int,
    opaque_bounds: list[int] | None = None,
) -> None:
    crop_region(
        image,
        out_path,
        col * tile_size,
        row * tile_size,
        tile_size,
        tile_size,
        scale,
        opaque_bounds,
    )


def crop_region(
    image: Path,
    out_path: Path,
    x: int,
    y: int,
    width: int,
    height: int,
    scale: int,
    opaque_bounds: list[int] | None = None,
) -> None:
    magick = require_tool("magick")
    scale = max(1, scale)
    cmd = [
        magick,
        str(image),
        "-crop",
        f"{width}x{height}+{x}+{y}",
        "+repage",
        "-filter",
        "point",
        "-resize",
        f"{width * scale}x{height * scale}",
        "-stroke",
        "red",
        "-strokewidth",
        "4",
        "-fill",
        "none",
        "-draw",
        f"rectangle 0,0 {width * scale - 1},{height * scale - 1}",
    ]
    if opaque_bounds is not None:
        bounds_x, bounds_y, bounds_width, bounds_height = opaque_bounds
        cmd.extend(
            [
                "-stroke",
                "lime",
                "-strokewidth",
                "3",
                "-fill",
                "none",
                "-draw",
                (
                    f"rectangle {bounds_x * scale},{bounds_y * scale} "
                    f"{(bounds_x + bounds_width) * scale - 1},{(bounds_y + bounds_height) * scale - 1}"
                ),
            ]
        )
    cmd.append(str(out_path))
    subprocess.run(cmd, check=True)


def alpha_bounds(image: Path, x: int, y: int, width: int, height: int) -> list[int] | None:
    magick = require_tool("magick")
    output = run_text(
        [
            magick,
            str(image),
            "-crop",
            f"{width}x{height}+{x}+{y}",
            "+repage",
            "-alpha",
            "extract",
            "-threshold",
            "0",
            "-format",
            "%@",
            "info:",
        ]
    )
    match = re.fullmatch(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)", output)
    if match is None:
        return None
    bounds_width = int(match.group(1))
    bounds_height = int(match.group(2))
    bounds_x = int(match.group(3))
    bounds_y = int(match.group(4))
    if bounds_width <= 0 or bounds_height <= 0:
        return None
    return [bounds_x, bounds_y, bounds_width, bounds_height]


def format_rect(rect: list[int] | None) -> str:
    if rect is None:
        return "none"
    return f"{rect[0]},{rect[1]},{rect[2]},{rect[3]}"


def parse_rect(raw: str) -> list[int] | None:
    text = raw.strip().lower()
    if text in {"none", "n", "null"}:
        return None
    parts = re.split(r"[\s,]+", text)
    if len(parts) == 1:
        match = re.fullmatch(r"(\d+)x(\d+)", parts[0])
        if match is None:
            raise ValueError
        return [0, 0, int(match.group(1)), int(match.group(2))]
    if len(parts) == 2:
        return [0, 0, int(parts[0]), int(parts[1])]
    if len(parts) == 4:
        return [int(part) for part in parts]
    raise ValueError


def prompt_rect(label: str, default: list[int] | None) -> list[int] | None:
    while True:
        raw = input(f"{label} x,y,w,h default {format_rect(default)}: ").strip()
        if raw == "":
            return default
        try:
            return parse_rect(raw)
        except ValueError:
            print("Enter 'x,y,w,h', 'w,h', 'WxH', or 'none'.")


def prompt_offset(label: str, default: list[int]) -> list[int]:
    while True:
        raw = input(f"{label} x,y default {default[0]},{default[1]}: ").strip()
        if raw == "":
            return default
        parts = re.split(r"[\s,]+", raw)
        if len(parts) == 2:
            try:
                return [int(parts[0]), int(parts[1])]
            except ValueError:
                pass
        print("Enter 'x,y'.")


def describe_alpha_bounds(bounds: list[int] | None) -> None:
    if bounds is None:
        print("opaque bounds: none detected")
        return
    print(f"opaque bounds: x={bounds[0]} y={bounds[1]} w={bounds[2]} h={bounds[3]}")


def crop_context(
    image: Path,
    out_path: Path,
    focus_x: int,
    focus_y: int,
    focus_width: int,
    focus_height: int,
    image_width: int,
    image_height: int,
    tile_size: int,
    context_cells: int,
    scale: int,
    opaque_bounds: list[int] | None = None,
) -> None:
    magick = require_tool("magick")
    margin = max(0, context_cells) * tile_size
    x = max(0, focus_x - margin)
    y = max(0, focus_y - margin)
    right = min(image_width, focus_x + focus_width + margin)
    bottom = min(image_height, focus_y + focus_height + margin)
    width = right - x
    height = bottom - y
    scale = max(1, scale)
    outline_x = (focus_x - x) * scale
    outline_y = (focus_y - y) * scale
    outline_right = outline_x + focus_width * scale - 1
    outline_bottom = outline_y + focus_height * scale - 1
    cmd = [
        magick,
        str(image),
        "-crop",
        f"{width}x{height}+{x}+{y}",
        "+repage",
        "-filter",
        "point",
        "-resize",
        f"{width * scale}x{height * scale}",
        "-stroke",
        "red",
        "-strokewidth",
        "4",
        "-fill",
        "none",
        "-draw",
        f"rectangle {outline_x},{outline_y} {outline_right},{outline_bottom}",
    ]
    if opaque_bounds is not None:
        bounds_x, bounds_y, bounds_width, bounds_height = opaque_bounds
        opaque_x = (focus_x - x + bounds_x) * scale
        opaque_y = (focus_y - y + bounds_y) * scale
        cmd.extend(
            [
                "-stroke",
                "lime",
                "-strokewidth",
                "3",
                "-fill",
                "none",
                "-draw",
                (
                    f"rectangle {opaque_x},{opaque_y} "
                    f"{opaque_x + bounds_width * scale - 1},{opaque_y + bounds_height * scale - 1}"
                ),
            ]
        )
    cmd.append(str(out_path))
    subprocess.run(
        cmd,
        check=True,
    )


def preview_image(path: Path, disabled: bool) -> None:
    if disabled:
        print(f"preview: {path}")
        return

    kitten = shutil.which("kitten")
    if kitten is not None:
        subprocess.run([kitten, "icat", str(path)], check=False)
        return

    chafa = shutil.which("chafa")
    if chafa is not None:
        subprocess.run([chafa, "-f", "symbols", str(path)], check=False)
        return

    print(f"preview: {path}")


def prompt_choice(label: str, choices: dict[str, str], default: str) -> str:
    choice_text = " ".join(f"{key}={value}" for key, value in choices.items())
    while True:
        raw = input(f"{label} [{choice_text}] default {default}: ").strip().lower()
        if raw == "":
            return choices[default]
        if raw in choices:
            return choices[raw]
        if raw in choices.values():
            return raw
        print("Unrecognized choice.")


def prompt_bool(label: str, default: bool) -> bool:
    default_text = "y" if default else "n"
    while True:
        raw = input(f"{label} [y/n] default {default_text}: ").strip().lower()
        if raw == "":
            return default
        if raw in {"y", "yes", "true", "1"}:
            return True
        if raw in {"n", "no", "false", "0"}:
            return False
        print("Enter y or n.")


def prompt_int(label: str, default: int) -> int:
    while True:
        raw = input(f"{label} default {default}: ").strip()
        if raw == "":
            return default
        try:
            return int(raw)
        except ValueError:
            print("Enter an integer.")


def prompt_tags() -> list[str]:
    raw = input("tags comma-separated (optional): ").strip()
    if raw == "":
        return []
    return [part.strip() for part in raw.split(",") if part.strip()]


def parse_stamp_size(raw: str, tile_size: int) -> tuple[int, int, int, int] | None:
    text = raw.strip().lower()
    match = re.fullmatch(
        r"(?:stamp\s+)?(\d+)\s*(px|p|cells|cell|c)?\s*x\s*(\d+)\s*(px|p|cells|cell|c)?",
        text,
    )
    if match is None:
        return None

    first = int(match.group(1))
    first_unit = match.group(2)
    second = int(match.group(3))
    second_unit = match.group(4)
    unit = first_unit or second_unit

    # Human shorthand: small bare dimensions are cell counts, larger bare
    # dimensions are pixels. Explicit px/cells suffixes always win.
    if unit in {"cells", "cell", "c"} or (unit is None and first <= 16 and second <= 16):
        width_cells = first
        height_cells = second
    else:
        width_cells = max(1, (first + tile_size - 1) // tile_size)
        height_cells = max(1, (second + tile_size - 1) // tile_size)

    return width_cells, height_cells, width_cells * tile_size, height_cells * tile_size


def prompt_metadata(
    col: int,
    row: int,
    source_width: int,
    source_height: int,
    terrain_type: str,
    tile_size: int,
    kind: str,
    opaque_bounds_px: list[int] | None,
) -> dict[str, Any]:
    walkable_default = terrain_type in {"floor", "ground_detail", "decor_only"}
    collision_default = "n" if walkable_default else "f"
    describe_alpha_bounds(opaque_bounds_px)
    visual_rect_px = prompt_rect("visual_rect_px", opaque_bounds_px)
    placement_offset_px = prompt_offset("placement_offset_px", [0, 0]) if kind == "stamp" else [0, 0]
    collision = prompt_choice("collision", COLLISION_CHOICES, collision_default)
    collision_rect_default = None if collision == "none" else visual_rect_px
    collision_rect_px = prompt_rect("collision_rect_px", collision_rect_default)
    entry = {
        "coord": [col, row],
        "source_rect": [col * tile_size, row * tile_size, source_width, source_height],
        "opaque_bounds_px": opaque_bounds_px,
        "visual_rect_px": visual_rect_px,
        "placement_offset_px": placement_offset_px,
        "terrain_type": terrain_type,
        "walkable": prompt_bool("walkable", walkable_default),
        "collision": collision,
        "collision_rect_px": collision_rect_px,
        "sockets": {
            "north": prompt_choice("north_socket", SOCKET_CHOICES, "u"),
            "east": prompt_choice("east_socket", SOCKET_CHOICES, "u"),
            "south": prompt_choice("south_socket", SOCKET_CHOICES, "u"),
            "west": prompt_choice("west_socket", SOCKET_CHOICES, "u"),
        },
        "weight": prompt_int("selection weight", 1),
        "tags": prompt_tags(),
        "notes": input("notes (optional): ").strip(),
    }
    if kind == "stamp":
        entry["size_cells"] = [source_width // tile_size, source_height // tile_size]
    return entry


def classify_cell(col: int, row: int, tile_size: int, opaque_bounds_px: list[int] | None) -> dict[str, Any] | str:
    print("Commands: enter metadata, 'skip', 'back', 'quit', 'copy x,y', or 'stamp 96x128'.")
    first = input("action or terrain type shortcut: ").strip().lower()
    if first == "skip":
        return "skip"
    if first in {"back", "b"}:
        return "back"
    if first in {"quit", "q"}:
        return "quit"
    if first.startswith("copy "):
        return first
    if first.startswith("stamp "):
        parsed = parse_stamp_size(first, tile_size)
        if parsed is None:
            print("Stamp format is 'stamp 96x128', 'stamp 3x4', or 'stamp 3cx4c'.")
            return "retry"
        width_cells, height_cells, _width_px, _height_px = parsed
        return f"stamp {width_cells}x{height_cells}"

    if first in TERRAIN_CHOICES:
        terrain_type = TERRAIN_CHOICES[first]
    elif first in TERRAIN_CHOICES.values():
        terrain_type = first
    elif first == "":
        terrain_type = prompt_choice("terrain_type", TERRAIN_CHOICES, "u")
    else:
        print("Unknown terrain shortcut; using interactive choice.")
        terrain_type = prompt_choice("terrain_type", TERRAIN_CHOICES, "u")

    return prompt_metadata(col, row, tile_size, tile_size, terrain_type, tile_size, "cell", opaque_bounds_px)


def classify_stamp(
    col: int,
    row: int,
    width_cells: int,
    height_cells: int,
    tile_size: int,
    opaque_bounds_px: list[int] | None,
) -> dict[str, Any] | str:
    print(f"Stamp origin={col},{row} size={width_cells}x{height_cells} cells ({width_cells * tile_size}x{height_cells * tile_size}px)")
    first = input("terrain type shortcut for whole stamp, 'back', 'quit', or 'skip': ").strip().lower()
    if first == "skip":
        return "skip"
    if first in {"back", "b"}:
        return "back"
    if first in {"quit", "q"}:
        return "quit"

    if first in TERRAIN_CHOICES:
        terrain_type = TERRAIN_CHOICES[first]
    elif first in TERRAIN_CHOICES.values():
        terrain_type = first
    elif first == "":
        terrain_type = prompt_choice("terrain_type", TERRAIN_CHOICES, "t")
    else:
        print("Unknown terrain shortcut; using interactive choice.")
        terrain_type = prompt_choice("terrain_type", TERRAIN_CHOICES, "t")

    return prompt_metadata(
        col,
        row,
        width_cells * tile_size,
        height_cells * tile_size,
        terrain_type,
        tile_size,
        "stamp",
        opaque_bounds_px,
    )


def stamp_id_for(col: int, row: int, width_cells: int, height_cells: int) -> str:
    return f"{col},{row}:{width_cells}x{height_cells}"


def mark_stamp_cells(data: dict[str, Any], stamp_id: str, stamp: dict[str, Any], tile_size: int) -> None:
    origin_col, origin_row = stamp["coord"]
    width_cells, height_cells = stamp["size_cells"]
    for row in range(origin_row, origin_row + height_cells):
        for col in range(origin_col, origin_col + width_cells):
            key = f"{col},{row}"
            data["cells"][key] = {
                "coord": [col, row],
                "source_rect": [col * tile_size, row * tile_size, tile_size, tile_size],
                "terrain_type": "stamp_origin" if [col, row] == stamp["coord"] else "stamp_member",
                "stamp_owner": stamp_id,
                "walkable": stamp["walkable"],
                "collision": stamp["collision"],
                "sockets": {},
                "weight": 0,
                "tags": [],
                "notes": "",
            }


def copy_entry(data: dict[str, Any], source_key: str, col: int, row: int, tile_size: int) -> dict[str, Any] | None:
    source = data["cells"].get(source_key)
    if source is None:
        print(f"No classified cell exists at {source_key}.")
        return None
    copied = json.loads(json.dumps(source))
    copied["coord"] = [col, row]
    copied["source_rect"] = [col * tile_size, row * tile_size, tile_size, tile_size]
    return copied


def main() -> int:
    args = parse_args()
    image = args.image
    if not image.exists():
        print(f"Image not found: {image}", file=sys.stderr)
        return 2

    width, height = get_image_size(image)
    tile_size = args.tile_size
    grid_cols = width // tile_size
    grid_rows = height // tile_size
    max_cols = min(grid_cols, args.cols if args.cols is not None else grid_cols)
    max_rows = min(grid_rows, args.rows if args.rows is not None else grid_rows)
    out_path = args.out or image.with_name(f"{image.stem}.mapping.json")
    data = load_mapping(out_path, image, tile_size, width, height)

    print(f"image: {image}")
    print(f"grid: {grid_cols} cols x {grid_rows} rows at {tile_size}px")
    print(f"output: {out_path}")
    print(f"preview: scale={args.scale} context_cells={args.context_cells}")

    positions: list[tuple[int, int]] = []
    for row in range(args.start_row, max_rows):
        for col in range(args.start_col if row == args.start_row else 0, max_cols):
            positions.append((col, row))

    index = 0
    with tempfile.TemporaryDirectory(prefix="custodian_tile_cells_") as tmp_dir:
        tmp_path = Path(tmp_dir) / "cell.png"
        context_path = Path(tmp_dir) / "context.png"
        while index < len(positions):
            col, row = positions[index]
            key = f"{col},{row}"
            if not args.overwrite and key in data["cells"]:
                index += 1
                continue

            cell_bounds = alpha_bounds(image, col * tile_size, row * tile_size, tile_size, tile_size)
            crop_cell(image, tmp_path, col, row, tile_size, args.scale, cell_bounds)
            crop_context(
                image,
                context_path,
                col * tile_size,
                row * tile_size,
                tile_size,
                tile_size,
                width,
                height,
                tile_size,
                args.context_cells,
                args.scale,
                cell_bounds,
            )
            print("\n" + "=" * 72)
            print(f"cell {key} atlas_col={col} atlas_row={row} rect=({col * tile_size},{row * tile_size},{tile_size},{tile_size})")
            describe_alpha_bounds(cell_bounds)
            print("context preview: red outline is current cell; green outline is opaque pixels")
            preview_image(context_path, args.no_preview)
            print("isolated cell preview:")
            preview_image(tmp_path, args.no_preview)
            result = classify_cell(col, row, tile_size, cell_bounds)

            if result == "quit":
                save_mapping(out_path, data)
                print(f"saved: {out_path}")
                return 0
            if result == "back":
                index = max(0, index - 1)
                continue
            if result == "retry":
                continue
            if result == "skip":
                data["cells"][key] = {
                    "coord": [col, row],
                    "source_rect": [col * tile_size, row * tile_size, tile_size, tile_size],
                    "opaque_bounds_px": cell_bounds,
                    "visual_rect_px": cell_bounds,
                    "placement_offset_px": [0, 0],
                    "terrain_type": "skipped",
                    "walkable": False,
                    "collision": "unknown",
                    "collision_rect_px": None,
                    "sockets": {},
                    "weight": 0,
                    "tags": [],
                    "notes": "",
                }
            elif isinstance(result, str) and result.startswith("copy "):
                copied = copy_entry(data, result.removeprefix("copy ").strip(), col, row, tile_size)
                if copied is None:
                    continue
                data["cells"][key] = copied
            elif isinstance(result, str) and result.startswith("stamp "):
                parsed = parse_stamp_size(result, tile_size)
                if parsed is None:
                    print("Invalid stamp command.")
                    continue
                width_cells, height_cells, width_px, height_px = parsed
                if col + width_cells > grid_cols or row + height_cells > grid_rows:
                    print(
                        f"Stamp {width_cells}x{height_cells} exceeds image grid "
                        f"from origin {key}; choose a smaller size."
                    )
                    continue

                stamp_bounds = alpha_bounds(image, col * tile_size, row * tile_size, width_px, height_px)
                crop_region(
                    image,
                    tmp_path,
                    col * tile_size,
                    row * tile_size,
                    width_px,
                    height_px,
                    args.scale,
                    stamp_bounds,
                )
                crop_context(
                    image,
                    context_path,
                    col * tile_size,
                    row * tile_size,
                    width_px,
                    height_px,
                    width,
                    height,
                    tile_size,
                    args.context_cells,
                    args.scale,
                    stamp_bounds,
                )
                print("\n" + "-" * 72)
                print(f"stamp preview {key} rect=({col * tile_size},{row * tile_size},{width_px},{height_px}) cells={width_cells}x{height_cells}")
                describe_alpha_bounds(stamp_bounds)
                print("stamp context preview: red outline is whole stamp; green outline is opaque pixels")
                preview_image(context_path, args.no_preview)
                print("isolated stamp preview:")
                preview_image(tmp_path, args.no_preview)
                stamp_result = classify_stamp(col, row, width_cells, height_cells, tile_size, stamp_bounds)
                if stamp_result == "quit":
                    save_mapping(out_path, data)
                    print(f"saved: {out_path}")
                    return 0
                if stamp_result == "back":
                    continue
                if stamp_result == "skip":
                    index += 1
                    continue
                stamp_id = stamp_id_for(col, row, width_cells, height_cells)
                stamp_result["id"] = stamp_id
                stamp_result["kind"] = "terrain_stamp"
                data["stamps"][stamp_id] = stamp_result
                mark_stamp_cells(data, stamp_id, stamp_result, tile_size)
                save_mapping(out_path, data)
                print(f"saved stamp {stamp_id}")
                index += width_cells
                continue
            else:
                data["cells"][key] = result

            save_mapping(out_path, data)
            print(f"saved cell {key}")
            index += 1

    save_mapping(out_path, data)
    print(f"complete: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
