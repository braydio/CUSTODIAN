#!/usr/bin/env python3
"""
Convert a spritesheet to pixel art frame-by-frame, then reassemble it.

Filename convention:
    operator__modular_upper_body__run_01__e__8f__96.png
                                                   ^^  target frame size 96x96
                                               ^^      8 frames

Also accepts e.g. __8f__96x128.
"""

from __future__ import annotations

import argparse
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFont
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: Pillow. Install it with: python3 -m pip install Pillow"
    ) from exc


METHODS = {
    "1": ("crisp", "Nearest-neighbor reduction; best for enlarged pixel art."),
    "2": ("balanced", "Box/area reduction plus a controlled palette."),
    "3": (
        "clustered",
        "Area reduction, stronger values, fewer colors, and noise cleanup.",
    ),
}

METHOD_ALIASES = {
    "1": "1", "crisp": "1", "nearest": "1",
    "2": "2", "balanced": "2", "area": "2",
    "3": "3", "clustered": "3", "bold": "3",
}

SPRITESHEET_SUFFIX_RE = re.compile(
    r"__(?P<frames>\d+)f__(?P<size>\d+(?:x\d+)?)$",
    re.IGNORECASE,
)


def parse_size(value: str) -> tuple[int, int]:
    normalized = value.lower().replace("×", "x")
    parts = normalized.split("x", 1)
    try:
        width = int(parts[0])
        height = int(parts[1]) if len(parts) == 2 else width
    except (TypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError("size must be N or WIDTHxHEIGHT") from exc
    if width < 1 or height < 1:
        raise argparse.ArgumentTypeError("size dimensions must be positive")
    return width, height


def parse_filename_metadata(path: Path) -> tuple[int, tuple[int, int]]:
    match = SPRITESHEET_SUFFIX_RE.search(path.stem)
    if not match:
        raise ValueError(
            "Filename must end in '__<frames>f__<size>', e.g. "
            "'operator__run__8f__96.png'. Use --frames and --size to override."
        )
    frame_count = int(match.group("frames"))
    target_size = parse_size(match.group("size"))
    if frame_count < 1:
        raise ValueError("Frame count must be at least 1.")
    return frame_count, target_size


def clamp_alpha_binary(image: Image.Image, cutoff: int = 16) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda v: 255 if v >= cutoff else 0)
    rgba.putalpha(alpha)
    return rgba


def union_alpha_bbox(
    frames: list[Image.Image], alpha_cutoff: int = 16
) -> tuple[int, int, int, int]:
    """One shared trim box for all frames, preventing animation jitter."""
    if not frames:
        raise ValueError("No frames supplied.")
    size = frames[0].size
    union = Image.new("L", size, 0)
    for frame in frames:
        if frame.size != size:
            raise ValueError("All source frame cells must have identical dimensions.")
        alpha = frame.convert("RGBA").getchannel("A").point(
            lambda v: 255 if v >= alpha_cutoff else 0
        )
        union = ImageChops.lighter(union, alpha)
    return union.getbbox() or (0, 0, size[0], size[1])


def prepare_frames_on_shared_canvas(
    frames: list[Image.Image],
    canvas_size: tuple[int, int],
    margin: int = 32,
    alpha_cutoff: int = 16,
) -> list[Image.Image]:
    """Crop, scale, and position every frame identically."""
    if not frames:
        return []

    bbox = union_alpha_bbox(frames, alpha_cutoff)
    bbox_w = max(1, bbox[2] - bbox[0])
    bbox_h = max(1, bbox[3] - bbox[1])
    canvas_w, canvas_h = canvas_size
    usable_w = max(1, canvas_w - margin * 2)
    usable_h = max(1, canvas_h - margin * 2)

    scale = min(usable_w / bbox_w, usable_h / bbox_h)
    new_w = max(1, round(bbox_w * scale))
    new_h = max(1, round(bbox_h * scale))
    offset_x = (canvas_w - new_w) // 2
    offset_y = (canvas_h - new_h) // 2

    prepared = []
    for frame in frames:
        cropped = frame.convert("RGBA").crop(bbox)
        resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        canvas.alpha_composite(resized, (offset_x, offset_y))
        prepared.append(clamp_alpha_binary(canvas, alpha_cutoff))
    return prepared


def quantize_rgba(image: Image.Image, colors: int, alpha_cutoff: int) -> Image.Image:
    rgba = clamp_alpha_binary(image.convert("RGBA"), alpha_cutoff)
    alpha = rgba.getchannel("A")
    rgb = Image.new("RGB", rgba.size, (0, 0, 0))
    rgb.paste(rgba.convert("RGB"), mask=alpha)
    quantized = rgb.quantize(
        colors=max(2, min(colors, 256)),
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    result = quantized.convert("RGBA")
    result.putalpha(alpha)
    return clamp_alpha_binary(result, alpha_cutoff)


def clean_isolated_colors(image: Image.Image) -> Image.Image:
    source = image.convert("RGBA")
    pixels = source.load()
    output = source.copy()
    out_pixels = output.load()
    width, height = source.size

    for y in range(height):
        for x in range(width):
            center = pixels[x, y]
            if center[3] == 0:
                continue
            counts = {}
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    color = pixels[nx, ny]
                    if color[3] == 0:
                        continue
                    counts[color] = counts.get(color, 0) + 1
            replacement, count = max(counts.items(), key=lambda item: item[1])
            if counts.get(center, 0) == 1 and count >= 4:
                out_pixels[x, y] = replacement
    return output


def make_candidates(
    source: Image.Image,
    target_size: tuple[int, int],
    colors: int,
    alpha_cutoff: int,
) -> dict[str, Image.Image]:
    rgba = source.convert("RGBA")

    crisp = rgba.resize(target_size, Image.Resampling.NEAREST)
    crisp = clamp_alpha_binary(crisp, alpha_cutoff)

    balanced_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    balanced = quantize_rgba(balanced_reduced, colors, alpha_cutoff)

    clustered_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    clustered_reduced = ImageEnhance.Contrast(clustered_reduced).enhance(1.12)
    clustered_reduced = ImageEnhance.Color(clustered_reduced).enhance(1.08)
    clustered = quantize_rgba(
        clustered_reduced, max(8, colors * 2 // 3), alpha_cutoff
    )
    clustered = clean_isolated_colors(clustered)
    clustered = clamp_alpha_binary(clustered, alpha_cutoff)

    return {"1": crisp, "2": balanced, "3": clustered}


def infer_source_grid(
    sheet_size: tuple[int, int],
    frame_count: int,
    target_size: tuple[int, int],
) -> tuple[int, int]:
    """Infer a uniform COLS x ROWS grid from dimensions and frame aspect."""
    sheet_w, sheet_h = sheet_size
    target_aspect = target_size[0] / target_size[1]
    candidates = []

    for rows in range(1, frame_count + 1):
        cols = math.ceil(frame_count / rows)
        if sheet_w % cols or sheet_h % rows:
            continue
        cell_w = sheet_w // cols
        cell_h = sheet_h // rows
        aspect_error = abs(math.log((cell_w / cell_h) / target_aspect))
        empty_cells = cols * rows - frame_count
        score = aspect_error + empty_cells * 0.15 + rows * 0.0001
        candidates.append((score, cols, rows))

    if not candidates:
        raise ValueError(
            f"Could not infer a regular grid for {frame_count} frames from "
            f"{sheet_w}x{sheet_h}. Pass --grid COLSxROWS explicitly."
        )

    candidates.sort()
    _, cols, rows = candidates[0]
    return cols, rows


def validate_grid(
    sheet_size: tuple[int, int], frame_count: int, grid: tuple[int, int]
) -> tuple[int, int]:
    cols, rows = grid
    sheet_w, sheet_h = sheet_size
    if cols < 1 or rows < 1:
        raise ValueError("Grid dimensions must be positive.")
    if cols * rows < frame_count:
        raise ValueError(
            f"Grid {cols}x{rows} has {cols * rows} cells, "
            f"but {frame_count} frames were requested."
        )
    if sheet_w % cols or sheet_h % rows:
        raise ValueError(
            f"Source size {sheet_w}x{sheet_h} is not evenly divisible by "
            f"grid {cols}x{rows}."
        )
    return cols, rows


def split_spritesheet(
    sheet: Image.Image, frame_count: int, grid: tuple[int, int]
) -> list[Image.Image]:
    cols, rows = validate_grid(sheet.size, frame_count, grid)
    cell_w = sheet.width // cols
    cell_h = sheet.height // rows
    frames = []
    for index in range(frame_count):
        row, col = divmod(index, cols)
        left = col * cell_w
        top = row * cell_h
        frames.append(
            sheet.crop((left, top, left + cell_w, top + cell_h)).convert("RGBA")
        )
    return frames


def assemble_spritesheet(
    frames: list[Image.Image],
    grid: tuple[int, int],
    frame_size: tuple[int, int],
) -> Image.Image:
    cols, rows = grid
    frame_w, frame_h = frame_size
    output = Image.new("RGBA", (cols * frame_w, rows * frame_h), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        row, col = divmod(index, cols)
        output.alpha_composite(frame.convert("RGBA"), (col * frame_w, row * frame_h))
    return output


def process_all_frames(
    source_frames: list[Image.Image],
    target_size: tuple[int, int],
    source_canvas: tuple[int, int],
    margin: int,
    colors: int,
    alpha_cutoff: int,
) -> tuple[list[Image.Image], dict[str, list[Image.Image]]]:
    prepared_frames = prepare_frames_on_shared_canvas(
        source_frames, source_canvas, margin, alpha_cutoff
    )
    by_method = {"1": [], "2": [], "3": []}
    for prepared in prepared_frames:
        candidates = make_candidates(prepared, target_size, colors, alpha_cutoff)
        for key in by_method:
            by_method[key].append(candidates[key])
    return prepared_frames, by_method


def checkerboard(size: tuple[int, int], cell: int = 12) -> Image.Image:
    board = Image.new("RGBA", size, (56, 58, 64, 255))
    draw = ImageDraw.Draw(board)
    light = (78, 81, 89, 255)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=light)
    return board


def build_comparison(candidate_sheets: dict[str, Image.Image], destination: Path) -> None:
    sheet = candidate_sheets["1"]
    preview_scale = max(1, min(4, 1400 // max(1, sheet.width)))
    preview_size = (sheet.width * preview_scale, sheet.height * preview_scale)
    gap, label_height = 24, 52
    panel_height = label_height + preview_size[1]
    canvas = Image.new(
        "RGBA",
        (preview_size[0] + gap * 2, panel_height * 3 + gap * 4),
        (28, 30, 35, 255),
    )
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()

    for index, key in enumerate(("1", "2", "3")):
        name, description = METHODS[key]
        y = gap + index * (panel_height + gap)
        draw.text((gap, y), f"{key}. {name.upper()}", fill=(245, 246, 250), font=font)
        draw.text((gap, y + 20), description.split(";")[0], fill=(184, 188, 198), font=font)
        preview = candidate_sheets[key].resize(preview_size, Image.Resampling.NEAREST)
        background = checkerboard(preview_size)
        background.alpha_composite(preview)
        canvas.alpha_composite(background, (gap, y + label_height))

    canvas.convert("RGB").save(destination)


def show_comparison(path: Path) -> str:
    if sys.stdout.isatty() and shutil.which("chafa"):
        subprocess.run(["chafa", "--format=symbols", "--size=120x40", str(path)], check=False)
        return "terminal preview"
    if os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"):
        if shutil.which("xdg-open"):
            subprocess.Popen(
                ["xdg-open", str(path)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return "desktop viewer"
    return "file only"


def choose_interactively() -> str:
    print("\nChoose the output:")
    for key, (name, description) in METHODS.items():
        print(f"  {key}) {name:<9} {description}")
    while True:
        try:
            answer = input("Selection [1-3, q to cancel]: ").strip().lower()
        except EOFError as exc:
            raise SystemExit("Interactive selection needs a terminal; pass --choose 1, 2, or 3.") from exc
        if answer in METHOD_ALIASES:
            return METHOD_ALIASES[answer]
        if answer in {"q", "quit", "cancel"}:
            raise SystemExit("Cancelled; no output was written.")
        print("Enter 1, 2, or 3.")


def default_output(source: Path, frame_count: int, size: tuple[int, int]) -> Path:
    return source.with_name(
        f"{source.stem}_pixel_{frame_count}f_{size[0]}x{size[1]}.png"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Process a regular spritesheet frame-by-frame, parsing frame count "
            "and target cell size from '__8f__96' filename metadata."
        )
    )
    parser.add_argument("source", type=Path, help="Source spritesheet")
    parser.add_argument("output", type=Path, nargs="?", help="Final spritesheet PNG path")
    parser.add_argument("--frames", type=int, help="Override parsed frame count")
    parser.add_argument("--size", type=parse_size, metavar="N|WxH", help="Override parsed target frame size")
    parser.add_argument(
        "--grid", type=parse_size, metavar="COLSxROWS",
        help="Source layout; otherwise auto-detected"
    )
    parser.add_argument(
        "--source-canvas", type=parse_size, default=(768, 768), metavar="N|WxH",
        help="Per-frame working canvas before downscaling (default: 768x768)"
    )
    parser.add_argument("--margin", type=int, default=32, help="Working-canvas padding (default: 32)")
    parser.add_argument("--colors", type=int, default=24, help="Balanced palette size (default: 24)")
    parser.add_argument("--alpha-cutoff", type=int, default=16, help="Binary-alpha threshold (default: 16)")
    parser.add_argument("--choose", choices=sorted(METHOD_ALIASES), help="Select method without prompt")
    parser.add_argument(
        "--keep-candidates", type=Path, metavar="DIR",
        help="Keep all candidate sheets and individual processed frames"
    )
    parser.add_argument("--force", action="store_true", help="Replace an existing output file")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    source_path = args.source.expanduser().resolve()
    if not source_path.is_file():
        raise SystemExit(f"Source image not found: {source_path}")

    parsed_frames = parsed_size = None
    try:
        parsed_frames, parsed_size = parse_filename_metadata(source_path)
    except ValueError as exc:
        if args.frames is None or args.size is None:
            raise SystemExit(str(exc)) from exc

    frame_count = args.frames if args.frames is not None else parsed_frames
    target_size = args.size if args.size is not None else parsed_size
    assert frame_count is not None and target_size is not None

    if frame_count < 1:
        raise SystemExit("--frames must be at least 1")
    if not 2 <= args.colors <= 256:
        raise SystemExit("--colors must be between 2 and 256")
    if not 0 <= args.alpha_cutoff <= 255:
        raise SystemExit("--alpha-cutoff must be between 0 and 255")
    if args.margin < 0:
        raise SystemExit("--margin must be 0 or greater")
    if args.margin * 2 >= min(args.source_canvas):
        raise SystemExit("--margin is too large for --source-canvas")

    try:
        with Image.open(source_path) as opened:
            sheet = opened.convert("RGBA")
    except (OSError, ValueError) as exc:
        raise SystemExit(f"Could not read source image: {exc}") from exc

    try:
        grid = (
            validate_grid(sheet.size, frame_count, args.grid)
            if args.grid
            else infer_source_grid(sheet.size, frame_count, target_size)
        )
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc

    cols, rows = grid
    source_cell_size = (sheet.width // cols, sheet.height // rows)

    output_path = (
        args.output.expanduser().resolve()
        if args.output
        else default_output(source_path, frame_count, target_size)
    )
    if output_path.exists() and not args.force:
        raise SystemExit(f"Output already exists: {output_path}\nPass --force to replace it.")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    source_frames = split_spritesheet(sheet, frame_count, grid)
    prepared_frames, frames_by_method = process_all_frames(
        source_frames,
        target_size,
        args.source_canvas,
        args.margin,
        args.colors,
        args.alpha_cutoff,
    )

    candidate_sheets = {
        key: assemble_spritesheet(frames, grid, target_size)
        for key, frames in frames_by_method.items()
    }

    temporary = None
    if args.keep_candidates:
        candidate_dir = args.keep_candidates.expanduser().resolve()
        candidate_dir.mkdir(parents=True, exist_ok=True)
    else:
        temporary = tempfile.TemporaryDirectory(prefix="custodian-spritesheet-")
        candidate_dir = Path(temporary.name)

    prepared_sheet = assemble_spritesheet(prepared_frames, grid, args.source_canvas)
    prepared_sheet.save(candidate_dir / "prepared_spritesheet.png")

    for key, method_sheet in candidate_sheets.items():
        name = METHODS[key][0]
        method_sheet.save(candidate_dir / f"{key}_{name}_spritesheet.png")
        if args.keep_candidates:
            frame_dir = candidate_dir / f"{key}_{name}_frames"
            frame_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(frames_by_method[key]):
                frame.save(frame_dir / f"frame_{index:03d}.png")

    comparison_path = candidate_dir / "comparison.png"
    build_comparison(candidate_sheets, comparison_path)

    chosen = METHOD_ALIASES[args.choose] if args.choose else None
    if chosen is None:
        if not sys.stdin.isatty():
            raise SystemExit("Interactive selection needs a terminal; pass --choose 1, 2, or 3.")
        display_mode = show_comparison(comparison_path)
        print(f"Parsed: {frame_count} frames @ {target_size[0]}x{target_size[1]}")
        print(
            f"Detected source layout: {cols}x{rows} cells "
            f"({source_cell_size[0]}x{source_cell_size[1]} each)"
        )
        print(f"Comparison: {comparison_path} ({display_mode})")
        chosen = choose_interactively()

    selected_name = METHODS[chosen][0]
    candidate_sheets[chosen].save(output_path, format="PNG")

    print(f"Wrote {selected_name} spritesheet: {output_path}")
    print(f"Frames: {frame_count}")
    print(f"Grid: {cols}x{rows}")
    print(f"Output cell: {target_size[0]}x{target_size[1]}")
    print(f"Output sheet: {cols * target_size[0]}x{rows * target_size[1]}")
    if args.keep_candidates:
        print(f"Kept candidates: {candidate_dir}")

    if temporary is not None:
        temporary.cleanup()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
