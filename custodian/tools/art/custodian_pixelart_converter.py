#!/usr/bin/env python3
"""
CUSTODIAN pixel-art downscaler / converter.

Designed for both:
    - single sprites / props / machines
    - animation spritesheets with fixed frame cells

The important spritesheet rule is:
    NEVER auto-fit every frame independently.

For sheets this tool:
    1. splits the source into fixed source cells
    2. measures all frame alpha bounds
    3. computes ONE shared union crop
    4. computes ONE shared scale and anchor placement
    5. processes every frame independently with that same geometry
    6. uses a shared palette for balanced/clustered sheet candidates
    7. reassembles the original frame layout exactly

That avoids animation "breathing", baseline drift, palette flicker, and pixels
bleeding across neighboring frames during resampling.

Single-image behavior:
    - trims transparent dead space
    - preserves aspect ratio
    - uses an aspect-matched high-resolution preparation canvas
    - produces three candidates: crisp / balanced / clustered
    - outputs binary alpha only: 0 or 255

Examples
--------
Single 96x96 actor/prop:
    python3 custodian_pixelart_converter.py input.png --size 96 --choose balanced

Horizontal 6-frame sheet, source frame count explicit:
    python3 custodian_pixelart_converter.py attack.png \
        --sheet --frames 6 --size 96 --anchor feet --choose balanced

Grid sheet, 4 columns x 2 rows:
    python3 custodian_pixelart_converter.py sheet.png \
        --sheet --grid 4x2 --size 96 --anchor feet --choose balanced

Explicit source-cell geometry:
    python3 custodian_pixelart_converter.py attack.png \
        --sheet --source-cell 768x768 --frames 6 --size 96 \
        --anchor feet --choose balanced

Already-pixel-art source:
    python3 custodian_pixelart_converter.py legacy_sheet.png \
        --sheet --frames 8 --size 96 --pixel-source --anchor feet \
        --choose crisp

Filename inference understands common CUSTODIAN tokens such as:
    enemy_grunt__alert_01__s__5f__96.png
    enemy_grunt__attack_01__e__6f__96x96.png

If --sheet is supplied and --frames/--grid/--source-cell are omitted, the tool
attempts to infer frame count from "__<N>f__" in the filename. In that case a
horizontal sheet is assumed.
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
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFont
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: Pillow.\n"
        "Install it with:\n"
        "    python3 -m pip install Pillow"
    ) from exc


# =============================================================================
# Candidate methods
# =============================================================================

METHODS = {
    "1": (
        "crisp",
        "Nearest-neighbor final reduction; strongest hard-pixel structure.",
    ),
    "2": (
        "balanced",
        "Area reduction plus controlled palette; recommended default.",
    ),
    "3": (
        "clustered",
        "Area reduction, stronger values, tighter palette, conservative cleanup.",
    ),
}

METHOD_ALIASES = {
    "1": "1",
    "crisp": "1",
    "nearest": "1",
    "2": "2",
    "balanced": "2",
    "area": "2",
    "3": "3",
    "clustered": "3",
    "bold": "3",
}

FRAME_COUNT_RE = re.compile(r"(?:^|__)\s*(\d+)f(?:__|$)", re.IGNORECASE)
SIZE_TOKEN_RE = re.compile(r"(?:^|__)(\d+)(?:x(\d+))?(?:__|$)", re.IGNORECASE)


# =============================================================================
# Data structures
# =============================================================================

@dataclass(frozen=True)
class SheetGeometry:
    columns: int
    rows: int
    frame_count: int
    source_cell: tuple[int, int]


@dataclass(frozen=True)
class SharedFrameTransform:
    """One transform shared by every source frame in a sheet."""

    union_bbox: tuple[int, int, int, int]
    prepared_cell_size: tuple[int, int]
    margin: int
    scale: float
    scaled_union_size: tuple[int, int]
    destination_offset: tuple[int, int]
    anchor: str
    fit: str = "contain"


# =============================================================================
# Parsing helpers
# =============================================================================

def parse_size(value: str) -> tuple[int, int]:
    """Parse N or WIDTHxHEIGHT."""
    normalized = value.lower().replace("×", "x")
    parts = normalized.split("x", 1)

    try:
        width = int(parts[0])
        height = int(parts[1]) if len(parts) == 2 else width
    except (TypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError(
            "size must be N or WIDTHxHEIGHT"
        ) from exc

    if width < 1 or height < 1:
        raise argparse.ArgumentTypeError("size dimensions must be positive")

    return width, height


def infer_frame_count_from_name(path: Path) -> int | None:
    match = FRAME_COUNT_RE.search(path.stem)
    if not match:
        return None
    value = int(match.group(1))
    return value if value > 0 else None


def infer_target_size_from_name(path: Path) -> tuple[int, int] | None:
    """
    Conservative filename size inference.

    This intentionally scans tokens and returns the LAST size-looking token,
    which matches CUSTODIAN naming where runtime size is normally near the end.
    """
    candidates: list[tuple[int, int]] = []
    for match in SIZE_TOKEN_RE.finditer(path.stem):
        width = int(match.group(1))
        height = int(match.group(2)) if match.group(2) else width
        if 8 <= width <= 2048 and 8 <= height <= 2048:
            candidates.append((width, height))
    return candidates[-1] if candidates else None


# =============================================================================
# Alpha helpers
# =============================================================================

def binary_alpha_mask(image: Image.Image, cutoff: int) -> Image.Image:
    return image.convert("RGBA").getchannel("A").point(
        lambda value: 255 if value >= cutoff else 0
    )


def clamp_alpha_binary(image: Image.Image, cutoff: int = 16) -> Image.Image:
    rgba = image.convert("RGBA")
    rgba.putalpha(binary_alpha_mask(rgba, cutoff))
    return rgba


def alpha_bbox(
    image: Image.Image,
    cutoff: int = 16,
) -> tuple[int, int, int, int] | None:
    return binary_alpha_mask(image, cutoff).getbbox()


def trim_transparent_border(
    image: Image.Image,
    cutoff: int = 16,
) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = alpha_bbox(rgba, cutoff)
    return rgba.crop(bbox) if bbox is not None else rgba.copy()


def union_bboxes(
    boxes: Iterable[tuple[int, int, int, int] | None],
    fallback_size: tuple[int, int],
) -> tuple[int, int, int, int]:
    valid = [box for box in boxes if box is not None]
    if not valid:
        return (0, 0, fallback_size[0], fallback_size[1])

    left = min(box[0] for box in valid)
    top = min(box[1] for box in valid)
    right = max(box[2] for box in valid)
    bottom = max(box[3] for box in valid)
    return (left, top, right, bottom)


def expand_bbox(
    bbox: tuple[int, int, int, int],
    padding: int,
    frame_size: tuple[int, int],
) -> tuple[int, int, int, int]:
    if padding <= 0:
        return bbox
    left, top, right, bottom = bbox
    width, height = frame_size
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(width, right + padding),
        min(height, bottom + padding),
    )


# =============================================================================
# Preparation canvas
# =============================================================================

def automatic_source_canvas(
    target_size: tuple[int, int],
    baseline: int = 768,
) -> tuple[int, int]:
    """
    Build a high-resolution preparation canvas with the same aspect ratio as
    the requested runtime frame.
    """
    target_w, target_h = target_size
    smaller_dimension = min(target_w, target_h)
    scale = max(1, math.ceil(baseline / smaller_dimension))
    return (target_w * scale, target_h * scale)


def automatic_margin(
    canvas_size: tuple[int, int],
    reference_margin: int = 32,
    reference_size: int = 768,
) -> int:
    smallest = min(canvas_size)
    return max(0, round(smallest * reference_margin / reference_size))


def choose_resample(name: str) -> int:
    if name == "nearest":
        return Image.Resampling.NEAREST
    if name == "box":
        return Image.Resampling.BOX
    return Image.Resampling.LANCZOS


def _fit_scale(
    usable_size: tuple[int, int],
    content_size: tuple[int, int],
    fit: str,
) -> float:
    """
    Resolve an aspect-preserving scale.

    contain:
        Entire source alpha bounds remain visible. This is the historical
        sprite/prop behavior and may leave transparent gutters.

    cover:
        Source fills the entire usable frame. Overflow is cropped according
        to the selected anchor. This is appropriate for seamless terrain
        tiles and other edge-to-edge art.
    """
    usable_w, usable_h = usable_size
    content_w, content_h = content_size

    if content_w < 1 or content_h < 1:
        return 1.0

    x_scale = usable_w / content_w
    y_scale = usable_h / content_h

    if fit == "contain":
        return min(x_scale, y_scale)
    if fit == "cover":
        return max(x_scale, y_scale)

    raise ValueError(f"Unsupported fit mode: {fit}")


def _alpha_composite_clipped(
    canvas: Image.Image,
    image: Image.Image,
    offset: tuple[int, int],
) -> None:
    """
    Alpha-composite an image even when its cover-fit placement extends beyond
    the canvas.

    Pillow's ordinary positive-offset path is not sufficient for deliberately
    cropped cover-fit art. This computes the visible source rectangle first.
    """
    x, y = offset

    source_left = max(0, -x)
    source_top = max(0, -y)
    source_right = min(image.width, canvas.width - x)
    source_bottom = min(image.height, canvas.height - y)

    if source_right <= source_left or source_bottom <= source_top:
        return

    visible = image.crop(
        (source_left, source_top, source_right, source_bottom)
    )

    destination = (
        max(0, x),
        max(0, y),
    )

    canvas.alpha_composite(visible, destination)


def _anchor_offset(
    canvas_size: tuple[int, int],
    scaled_size: tuple[int, int],
    margin: int,
    anchor: str,
) -> tuple[int, int]:
    """
    Place the shared union box inside the prepared frame.

    feet / bottom-center:
        centered horizontally, aligned to the usable bottom edge.

    center:
        centered both axes.

    top-center:
        centered horizontally, aligned to usable top edge.

    top-left / bottom-left / top-right / bottom-right are provided mostly for
    props and environment strips.
    """
    canvas_w, canvas_h = canvas_size
    scaled_w, scaled_h = scaled_size

    usable_left = margin
    usable_top = margin
    usable_right = canvas_w - margin
    usable_bottom = canvas_h - margin

    center_x = (canvas_w - scaled_w) // 2
    center_y = (canvas_h - scaled_h) // 2

    if anchor in {"feet", "bottom-center"}:
        return (center_x, usable_bottom - scaled_h)
    if anchor == "center":
        return (center_x, center_y)
    if anchor == "top-center":
        return (center_x, usable_top)
    if anchor == "top-left":
        return (usable_left, usable_top)
    if anchor == "top-right":
        return (usable_right - scaled_w, usable_top)
    if anchor == "bottom-left":
        return (usable_left, usable_bottom - scaled_h)
    if anchor == "bottom-right":
        return (usable_right - scaled_w, usable_bottom - scaled_h)

    raise ValueError(f"Unsupported anchor: {anchor}")


def fit_on_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    margin: int,
    alpha_cutoff: int,
    prepare_filter: str,
    binary_alpha_during_prepare: bool,
    fit: str = "contain",
    anchor: str = "center",
) -> Image.Image:
    """
    Single-image preparation path.

    contain preserves the entire trimmed silhouette.
    cover preserves aspect ratio but permits anchored cropping so terrain can
    reach the runtime cell boundaries.
    """
    image = trim_transparent_border(image, cutoff=alpha_cutoff)
    canvas_w, canvas_h = canvas_size
    usable_w = max(1, canvas_w - margin * 2)
    usable_h = max(1, canvas_h - margin * 2)

    if image.width < 1 or image.height < 1:
        return Image.new("RGBA", canvas_size, (0, 0, 0, 0))

    scale = _fit_scale(
        (usable_w, usable_h),
        (image.width, image.height),
        fit,
    )
    new_w = max(1, int(round(image.width * scale)))
    new_h = max(1, int(round(image.height * scale)))

    resized = image.resize((new_w, new_h), choose_resample(prepare_filter))
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    offset = _anchor_offset(canvas_size, (new_w, new_h), margin, anchor)
    _alpha_composite_clipped(canvas, resized, offset)

    if binary_alpha_during_prepare:
        canvas = clamp_alpha_binary(canvas, cutoff=alpha_cutoff)

    return canvas


def contain_fit_on_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    margin: int,
    alpha_cutoff: int,
    prepare_filter: str,
    binary_alpha_during_prepare: bool,
    anchor: str = "center",
) -> Image.Image:
    """Backward-compatible wrapper for the historical contain behavior."""
    return fit_on_canvas(
        image,
        canvas_size=canvas_size,
        margin=margin,
        alpha_cutoff=alpha_cutoff,
        prepare_filter=prepare_filter,
        binary_alpha_during_prepare=binary_alpha_during_prepare,
        fit="contain",
        anchor=anchor,
    )


# =============================================================================
# Sheet geometry / splitting
# =============================================================================

def resolve_sheet_geometry(
    source: Image.Image,
    source_path: Path,
    frames_arg: int | None,
    grid_arg: tuple[int, int] | None,
    source_cell_arg: tuple[int, int] | None,
) -> SheetGeometry:
    width, height = source.size

    inferred_frames = infer_frame_count_from_name(source_path)
    frame_count = frames_arg or inferred_frames

    if grid_arg is not None:
        columns, rows = grid_arg
        grid_count = columns * rows
        if frame_count is not None and frame_count > grid_count:
            raise SystemExit(
                f"--frames {frame_count} exceeds --grid capacity {grid_count}"
            )
        frame_count = frame_count or grid_count
    else:
        columns = frame_count or 0
        rows = 1

    if source_cell_arg is not None:
        cell_w, cell_h = source_cell_arg
        if width % cell_w != 0 or height % cell_h != 0:
            raise SystemExit(
                "Source image dimensions are not divisible by --source-cell: "
                f"image={width}x{height}, cell={cell_w}x{cell_h}"
            )
        inferred_columns = width // cell_w
        inferred_rows = height // cell_h

        if grid_arg is not None:
            if (inferred_columns, inferred_rows) != grid_arg:
                raise SystemExit(
                    "--grid and --source-cell disagree with source dimensions: "
                    f"grid={grid_arg[0]}x{grid_arg[1]}, inferred="
                    f"{inferred_columns}x{inferred_rows}"
                )
        else:
            columns, rows = inferred_columns, inferred_rows

        capacity = columns * rows
        frame_count = frame_count or capacity
        if frame_count > capacity:
            raise SystemExit(
                f"Resolved frame count {frame_count} exceeds source-cell capacity {capacity}"
            )

        return SheetGeometry(columns, rows, frame_count, (cell_w, cell_h))

    if grid_arg is not None:
        if width % columns != 0 or height % rows != 0:
            raise SystemExit(
                "Source dimensions are not divisible by --grid: "
                f"image={width}x{height}, grid={columns}x{rows}"
            )
        return SheetGeometry(
            columns,
            rows,
            frame_count or columns * rows,
            (width // columns, height // rows),
        )

    if frame_count is None:
        raise SystemExit(
            "Sheet mode needs --frames, --grid, --source-cell, or a filename "
            "containing a token such as '__6f__'."
        )

    if width % frame_count != 0:
        raise SystemExit(
            "Horizontal sheet inference failed because source width is not "
            f"divisible by frame count: width={width}, frames={frame_count}.\n"
            "Pass --grid or --source-cell if this is not a single-row sheet."
        )

    return SheetGeometry(
        columns=frame_count,
        rows=1,
        frame_count=frame_count,
        source_cell=(width // frame_count, height),
    )


def split_sheet_frames(
    source: Image.Image,
    geometry: SheetGeometry,
) -> list[Image.Image]:
    frames: list[Image.Image] = []
    cell_w, cell_h = geometry.source_cell

    for index in range(geometry.frame_count):
        col = index % geometry.columns
        row = index // geometry.columns
        if row >= geometry.rows:
            raise SystemExit(
                f"Frame {index} exceeds resolved grid {geometry.columns}x{geometry.rows}"
            )
        left = col * cell_w
        top = row * cell_h
        frame = source.crop((left, top, left + cell_w, top + cell_h)).convert("RGBA")
        frames.append(frame)

    return frames


def reassemble_sheet(
    frames: list[Image.Image],
    geometry: SheetGeometry,
    target_cell: tuple[int, int],
) -> Image.Image:
    target_w, target_h = target_cell
    sheet = Image.new(
        "RGBA",
        (geometry.columns * target_w, geometry.rows * target_h),
        (0, 0, 0, 0),
    )

    for index, frame in enumerate(frames):
        col = index % geometry.columns
        row = index // geometry.columns
        sheet.alpha_composite(frame, (col * target_w, row * target_h))

    return sheet


# =============================================================================
# Shared sheet preparation
# =============================================================================

def calculate_shared_frame_transform(
    frames: list[Image.Image],
    prepared_cell_size: tuple[int, int],
    margin: int,
    alpha_cutoff: int,
    anchor: str,
    union_padding: int,
    fit: str = "contain",
) -> SharedFrameTransform:
    if not frames:
        raise SystemExit("No frames were provided")

    frame_size = frames[0].size
    for frame in frames:
        if frame.size != frame_size:
            raise SystemExit("All sheet frames must share the same source-cell size")

    boxes = [alpha_bbox(frame, alpha_cutoff) for frame in frames]
    union = union_bboxes(boxes, frame_size)
    union = expand_bbox(union, union_padding, frame_size)

    left, top, right, bottom = union
    union_w = max(1, right - left)
    union_h = max(1, bottom - top)

    prepared_w, prepared_h = prepared_cell_size
    usable_w = max(1, prepared_w - margin * 2)
    usable_h = max(1, prepared_h - margin * 2)

    scale = _fit_scale(
        (usable_w, usable_h),
        (union_w, union_h),
        fit,
    )
    scaled_w = max(1, int(round(union_w * scale)))
    scaled_h = max(1, int(round(union_h * scale)))

    offset = _anchor_offset(
        prepared_cell_size,
        (scaled_w, scaled_h),
        margin,
        anchor,
    )

    return SharedFrameTransform(
        union_bbox=union,
        prepared_cell_size=prepared_cell_size,
        margin=margin,
        scale=scale,
        scaled_union_size=(scaled_w, scaled_h),
        destination_offset=offset,
        anchor=anchor,
        fit=fit,
    )


def prepare_sheet_frames(
    frames: list[Image.Image],
    transform: SharedFrameTransform,
    prepare_filter: str,
    alpha_cutoff: int,
    binary_alpha_during_prepare: bool,
) -> list[Image.Image]:
    """
    Apply exactly one shared crop / scale / anchor transform to all frames.

    This is the animation-stability core of the tool.
    """
    prepared: list[Image.Image] = []
    resample = choose_resample(prepare_filter)

    for frame in frames:
        cropped = frame.convert("RGBA").crop(transform.union_bbox)
        resized = cropped.resize(transform.scaled_union_size, resample)
        canvas = Image.new(
            "RGBA",
            transform.prepared_cell_size,
            (0, 0, 0, 0),
        )
        _alpha_composite_clipped(
            canvas,
            resized,
            transform.destination_offset,
        )

        if binary_alpha_during_prepare:
            canvas = clamp_alpha_binary(canvas, cutoff=alpha_cutoff)

        prepared.append(canvas)

    return prepared


# =============================================================================
# Shared palette quantization
# =============================================================================

def _opaque_rgb_sample(
    images: list[Image.Image],
    alpha_cutoff: int,
) -> Image.Image | None:
    colors: list[tuple[int, int, int]] = []

    for image in images:
        rgba = image.convert("RGBA")
        for r, g, b, a in rgba.getdata():
            if a >= alpha_cutoff:
                colors.append((r, g, b))

    if not colors:
        return None

    # A long 1-row sample is fine at 96px-era frame sizes and keeps palette
    # derivation exact across all frames.
    sample = Image.new("RGB", (len(colors), 1))
    sample.putdata(colors)
    return sample


def build_shared_palette(
    images: list[Image.Image],
    colors: int,
    alpha_cutoff: int,
) -> Image.Image | None:
    sample = _opaque_rgb_sample(images, alpha_cutoff)
    if sample is None:
        return None

    return sample.quantize(
        colors=max(2, min(colors, 256)),
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    )


def quantize_rgba_with_palette(
    image: Image.Image,
    palette: Image.Image | None,
    colors: int,
    alpha_cutoff: int,
) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = binary_alpha_mask(rgba, alpha_cutoff)

    rgb = Image.new("RGB", rgba.size, (0, 0, 0))
    rgb.paste(rgba.convert("RGB"), mask=alpha)

    if palette is None:
        quantized = rgb.quantize(
            colors=max(2, min(colors, 256)),
            method=Image.Quantize.MEDIANCUT,
            dither=Image.Dither.NONE,
        ).convert("RGB")
    else:
        quantized = rgb.quantize(
            palette=palette,
            dither=Image.Dither.NONE,
        ).convert("RGB")

    result = quantized.convert("RGBA")
    result.putalpha(alpha)
    return result


# =============================================================================
# Conservative clustered cleanup
# =============================================================================

def color_distance_sq(
    a: tuple[int, int, int, int],
    b: tuple[int, int, int, int],
) -> int:
    return (
        (a[0] - b[0]) ** 2
        + (a[1] - b[1]) ** 2
        + (a[2] - b[2]) ** 2
    )


def pixel_luminance(color: tuple[int, int, int, int]) -> float:
    return 0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2]


def clean_isolated_colors(
    image: Image.Image,
    max_color_distance: int = 80,
) -> Image.Image:
    source = image.convert("RGBA")
    pixels = source.load()
    output = source.copy()
    out_pixels = output.load()
    width, height = source.size
    max_distance_sq = max_color_distance * max_color_distance

    for y in range(height):
        for x in range(width):
            center = pixels[x, y]
            if center[3] == 0:
                continue

            counts: dict[tuple[int, int, int, int], int] = {}
            for neighbor_y in range(max(0, y - 1), min(height, y + 2)):
                for neighbor_x in range(max(0, x - 1), min(width, x + 2)):
                    color = pixels[neighbor_x, neighbor_y]
                    if color[3] == 0:
                        continue
                    counts[color] = counts.get(color, 0) + 1

            if not counts:
                continue

            replacement, replacement_count = max(
                counts.items(), key=lambda item: item[1]
            )
            center_count = counts.get(center, 0)

            if center_count != 1:
                continue
            if replacement_count < 5:
                continue
            if color_distance_sq(center, replacement) > max_distance_sq:
                continue

            if pixel_luminance(center) > pixel_luminance(replacement) + 55:
                continue

            out_pixels[x, y] = replacement

    return output


# =============================================================================
# Candidate creation
# =============================================================================

def make_single_candidates(
    prepared_source: Image.Image,
    target_size: tuple[int, int],
    colors: int,
    alpha_cutoff: int,
    crisp_colors: int | None = None,
) -> dict[str, Image.Image]:
    rgba = prepared_source.convert("RGBA")

    crisp = clamp_alpha_binary(
        rgba.resize(target_size, Image.Resampling.NEAREST),
        cutoff=alpha_cutoff,
    )
    if crisp_colors is not None:
        crisp = quantize_rgba_with_palette(
            crisp,
            build_shared_palette([crisp], crisp_colors, alpha_cutoff),
            crisp_colors,
            alpha_cutoff,
        )

    balanced_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    balanced_palette = build_shared_palette(
        [balanced_reduced], colors, alpha_cutoff
    )
    balanced = quantize_rgba_with_palette(
        balanced_reduced,
        balanced_palette,
        colors,
        alpha_cutoff,
    )

    clustered_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    clustered_reduced = ImageEnhance.Contrast(clustered_reduced).enhance(1.12)
    clustered_reduced = ImageEnhance.Color(clustered_reduced).enhance(1.08)
    clustered_colors = max(2, colors * 2 // 3)
    clustered_palette = build_shared_palette(
        [clustered_reduced], clustered_colors, alpha_cutoff
    )
    clustered = quantize_rgba_with_palette(
        clustered_reduced,
        clustered_palette,
        clustered_colors,
        alpha_cutoff,
    )
    clustered = clean_isolated_colors(clustered)
    clustered = clamp_alpha_binary(clustered, cutoff=alpha_cutoff)

    return {"1": crisp, "2": balanced, "3": clustered}


def make_sheet_candidates(
    prepared_frames: list[Image.Image],
    geometry: SheetGeometry,
    target_size: tuple[int, int],
    colors: int,
    alpha_cutoff: int,
    crisp_colors: int | None = None,
) -> tuple[dict[str, Image.Image], dict[str, list[Image.Image]]]:
    """
    Process each frame independently so resampling never crosses frame borders,
    while balanced/clustered use a shared animation palette to prevent flicker.
    """
    # Crisp ---------------------------------------------------------------
    crisp_frames = [
        clamp_alpha_binary(
            frame.resize(target_size, Image.Resampling.NEAREST),
            cutoff=alpha_cutoff,
        )
        for frame in prepared_frames
    ]
    if crisp_colors is not None:
        crisp_palette = build_shared_palette(
            crisp_frames,
            crisp_colors,
            alpha_cutoff,
        )
        crisp_frames = [
            quantize_rgba_with_palette(
                frame,
                crisp_palette,
                crisp_colors,
                alpha_cutoff,
            )
            for frame in crisp_frames
        ]

    # Balanced ------------------------------------------------------------
    balanced_reduced = [
        frame.resize(target_size, Image.Resampling.BOX)
        for frame in prepared_frames
    ]
    balanced_palette = build_shared_palette(
        balanced_reduced,
        colors,
        alpha_cutoff,
    )
    balanced_frames = [
        quantize_rgba_with_palette(
            frame,
            balanced_palette,
            colors,
            alpha_cutoff,
        )
        for frame in balanced_reduced
    ]

    # Clustered -----------------------------------------------------------
    clustered_reduced: list[Image.Image] = []
    for frame in prepared_frames:
        reduced = frame.resize(target_size, Image.Resampling.BOX)
        reduced = ImageEnhance.Contrast(reduced).enhance(1.12)
        reduced = ImageEnhance.Color(reduced).enhance(1.08)
        clustered_reduced.append(reduced)

    clustered_colors = max(2, colors * 2 // 3)
    clustered_palette = build_shared_palette(
        clustered_reduced,
        clustered_colors,
        alpha_cutoff,
    )
    clustered_frames = []
    for frame in clustered_reduced:
        quantized = quantize_rgba_with_palette(
            frame,
            clustered_palette,
            clustered_colors,
            alpha_cutoff,
        )
        quantized = clean_isolated_colors(quantized)
        quantized = clamp_alpha_binary(quantized, cutoff=alpha_cutoff)
        clustered_frames.append(quantized)

    frame_candidates = {
        "1": crisp_frames,
        "2": balanced_frames,
        "3": clustered_frames,
    }

    sheet_candidates = {
        key: reassemble_sheet(frames, geometry, target_size)
        for key, frames in frame_candidates.items()
    }

    return sheet_candidates, frame_candidates


# =============================================================================
# Preview
# =============================================================================

def checkerboard(
    size: tuple[int, int],
    cell: int = 12,
) -> Image.Image:
    board = Image.new("RGBA", size, (56, 58, 64, 255))
    draw = ImageDraw.Draw(board)
    light = (78, 81, 89, 255)

    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle(
                    (x, y, x + cell - 1, y + cell - 1),
                    fill=light,
                )

    return board


def load_preview_font() -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, 14)
    return ImageFont.load_default()


def build_comparison(
    candidates: dict[str, Image.Image],
    destination: Path,
    max_panel_width: int = 900,
    max_panel_height: int = 500,
) -> None:
    """Build a vertically stacked comparison that also works for wide sheets."""
    gap = 20
    label_height = 52
    font = load_preview_font()

    scaled_panels: list[tuple[str, Image.Image]] = []
    panel_width = 1
    total_height = gap

    for key in ("1", "2", "3"):
        image = candidates[key]
        scale = min(
            max_panel_width / max(1, image.width),
            max_panel_height / max(1, image.height),
        )
        # Prefer integer enlargement for pixel inspection; otherwise downscale.
        if scale >= 1.0:
            integer_scale = max(1, min(8, int(math.floor(scale))))
            preview_size = (
                image.width * integer_scale,
                image.height * integer_scale,
            )
        else:
            preview_size = (
                max(1, int(round(image.width * scale))),
                max(1, int(round(image.height * scale))),
            )

        preview = image.resize(preview_size, Image.Resampling.NEAREST)
        background = checkerboard(preview_size)
        background.alpha_composite(preview)
        scaled_panels.append((key, background))
        panel_width = max(panel_width, preview_size[0])
        total_height += label_height + preview_size[1] + gap

    canvas = Image.new(
        "RGBA",
        (panel_width + gap * 2, total_height),
        (28, 30, 35, 255),
    )
    draw = ImageDraw.Draw(canvas)

    y = gap
    for key, panel in scaled_panels:
        name, description = METHODS[key]
        draw.text(
            (gap, y),
            f"{key}. {name.upper()}",
            fill=(245, 246, 250),
            font=font,
        )
        draw.text(
            (gap, y + 22),
            description.split(";")[0],
            fill=(184, 188, 198),
            font=font,
        )
        y += label_height
        canvas.alpha_composite(panel, (gap, y))
        y += panel.height + gap

    canvas.convert("RGB").save(destination)


def show_comparison(path: Path) -> str:
    if sys.stdout.isatty() and shutil.which("chafa"):
        subprocess.run(
            ["chafa", "--format=symbols", "--size=120x40", str(path)],
            check=False,
        )
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
    print()
    print("Choose the output:")
    for key, (name, description) in METHODS.items():
        print(f"  {key}) {name:<10} {description}")

    while True:
        try:
            answer = input("Selection [1-3, q to cancel]: ").strip().lower()
        except EOFError as exc:
            raise SystemExit(
                "Interactive selection needs a terminal; pass --choose 1, 2, or 3."
            ) from exc

        if answer in METHOD_ALIASES:
            return METHOD_ALIASES[answer]
        if answer in {"q", "quit", "cancel"}:
            raise SystemExit("Cancelled; no output was written.")
        print("Enter 1, 2, or 3.")


# =============================================================================
# Diagnostics / validation
# =============================================================================

def binary_alpha_is_valid(image: Image.Image) -> bool:
    extrema = set(image.convert("RGBA").getchannel("A").getdata())
    return extrema.issubset({0, 255})


def tile_edge_contacts(
    image: Image.Image,
    cutoff: int,
) -> dict[str, bool]:
    """
    Report whether opaque art reaches each outer runtime-cell boundary.

    This tests contact, not full-edge coverage. Irregular cliff silhouettes may
    still contain deliberate alpha along portions of an edge.
    """
    bbox = alpha_bbox(image, cutoff)
    if bbox is None:
        return {
            "left": False,
            "right": False,
            "top": False,
            "bottom": False,
        }

    left, top, right, bottom = bbox
    return {
        "left": left == 0,
        "right": right == image.width,
        "top": top == 0,
        "bottom": bottom == image.height,
    }


def frame_bbox_report(
    frames: list[Image.Image],
    cutoff: int,
) -> list[str]:
    report: list[str] = []
    for index, frame in enumerate(frames):
        bbox = alpha_bbox(frame, cutoff)
        report.append(f"frame {index:02d}: {bbox}")
    return report


def write_sheet_manifest(
    destination: Path,
    geometry: SheetGeometry,
    target_size: tuple[int, int],
    transform: SharedFrameTransform,
    alpha_cutoff: int,
    prepare_filter: str,
    frame_bboxes: list[str],
) -> None:
    lines = [
        "CUSTODIAN pixel-art sheet conversion manifest",
        "",
        f"frames={geometry.frame_count}",
        f"grid={geometry.columns}x{geometry.rows}",
        f"source_cell={geometry.source_cell[0]}x{geometry.source_cell[1]}",
        f"target_cell={target_size[0]}x{target_size[1]}",
        f"output_sheet={geometry.columns * target_size[0]}x{geometry.rows * target_size[1]}",
        f"union_bbox={transform.union_bbox}",
        f"shared_scale={transform.scale:.8f}",
        f"prepared_cell={transform.prepared_cell_size[0]}x{transform.prepared_cell_size[1]}",
        f"prepared_margin={transform.margin}",
        f"anchor={transform.anchor}",
        f"fit={transform.fit}",
        f"destination_offset={transform.destination_offset}",
        f"alpha_cutoff={alpha_cutoff}",
        f"prepare_filter={prepare_filter}",
        "",
        "source frame alpha bounds:",
        *frame_bboxes,
        "",
    ]
    destination.write_text("\n".join(lines), encoding="utf-8")


# =============================================================================
# Output naming
# =============================================================================

def default_output(
    source: Path,
    size: tuple[int, int],
    sheet_mode: bool,
) -> Path:
    suffix = "_sheet" if sheet_mode else ""
    return source.with_name(
        f"{source.stem}_pixel_{size[0]}x{size[1]}{suffix}.png"
    )


# =============================================================================
# CLI
# =============================================================================

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate crisp, balanced, and clustered pixel-art candidates for "
            "single images or fixed-cell animation spritesheets."
        )
    )

    parser.add_argument("source", type=Path, help="Source Pillow-readable image.")
    parser.add_argument("output", type=Path, nargs="?", help="Final PNG path.")

    parser.add_argument(
        "--size",
        type=parse_size,
        default=None,
        metavar="N|WxH",
        help=(
            "Final runtime dimensions PER FRAME. Default: 96x96, or inferred "
            "from a filename size token when possible."
        ),
    )

    # Sheet controls ------------------------------------------------------
    parser.add_argument(
        "--sheet",
        action="store_true",
        help="Treat the source as a fixed-cell animation spritesheet.",
    )
    parser.add_argument(
        "--frames",
        type=int,
        default=None,
        metavar="N",
        help=(
            "Number of used frames. If omitted in --sheet mode, infer from "
            "a filename token such as '__6f__' when possible."
        ),
    )
    parser.add_argument(
        "--grid",
        type=parse_size,
        default=None,
        metavar="COLSxROWS",
        help="Source sheet frame grid. Example: --grid 4x2.",
    )
    parser.add_argument(
        "--source-cell",
        type=parse_size,
        default=None,
        metavar="WxH",
        help=(
            "Explicit source frame-cell size. Useful when the source grid is "
            "known independently of frame count."
        ),
    )
    parser.add_argument(
        "--anchor",
        choices=[
            "center",
            "feet",
            "bottom-center",
            "top-center",
            "top-left",
            "top-right",
            "bottom-left",
            "bottom-right",
        ],
        default=None,
        help=(
            "Shared placement anchor. Default: feet for sheets, center for "
            "single images. 'feet' is equivalent to bottom-center."
        ),
    )
    parser.add_argument(
        "--union-padding",
        type=int,
        default=0,
        metavar="PX",
        help=(
            "Expand the shared source-frame union bbox by this many source "
            "pixels. Default: 0. Useful when FX nearly touch the measured bounds."
        ),
    )

    # Preparation controls ----------------------------------------------
    parser.add_argument(
        "--source-canvas",
        type=parse_size,
        default=None,
        metavar="N|WxH",
        help=(
            "Override high-resolution preparation canvas PER FRAME. Default: "
            "automatic aspect-matched canvas. 96x96 => 768x768."
        ),
    )
    parser.add_argument(
        "--canvas-baseline",
        type=int,
        default=768,
        metavar="PX",
        help="Preparation resolution baseline for smaller target dimension.",
    )
    parser.add_argument(
        "--margin",
        type=int,
        default=None,
        help=(
            "Transparent preparation margin in high-res prepared-frame pixels. "
            "Default scales from 32px on a 768px smaller dimension."
        ),
    )
    parser.add_argument(
        "--fit",
        choices=["contain", "cover"],
        default=None,
        help=(
            "Aspect-preserving fit policy. contain keeps the entire silhouette "
            "and may leave transparent gutters. cover fills the usable frame "
            "and crops overflow according to --anchor. Default: contain, or "
            "cover when --tile is supplied."
        ),
    )
    parser.add_argument(
        "--tile",
        action="store_true",
        help=(
            "Terrain-tile preset: defaults to --margin 0, --fit cover, and "
            "--anchor center. Explicit --margin, --fit, or --anchor values "
            "override the preset. The selected output also receives left/right "
            "edge-contact diagnostics."
        ),
    )
    parser.add_argument(
        "--colors",
        type=int,
        default=None,
        help=(
            "Palette ceiling for every candidate, including crisp. Sheet mode "
            "derives one shared palette from all frames to prevent color flicker. "
            "When omitted, balanced/clustered use 24 while crisp preserves the "
            "legacy source palette."
        ),
    )
    parser.add_argument(
        "--alpha-cutoff",
        type=int,
        default=None,
        help=(
            "Final alpha cutoff. Default: 16 for square cells, 8 for rectangular cells."
        ),
    )
    parser.add_argument(
        "--prepare-filter",
        choices=["auto", "nearest", "box", "lanczos"],
        default="auto",
        help=(
            "Resampling while preparing source art. auto = Lanczos unless "
            "--pixel-source is supplied."
        ),
    )
    parser.add_argument(
        "--pixel-source",
        action="store_true",
        help=(
            "Source is already pixel art. Use nearest-neighbor preparation and "
            "preserve hard clusters."
        ),
    )
    parser.add_argument(
        "--legacy-prep-alpha",
        action="store_true",
        help=(
            "Force binary alpha during high-resolution preparation. Normally "
            "soft source alpha is preserved until final reduction for non-pixel sources."
        ),
    )

    # Selection / outputs ------------------------------------------------
    parser.add_argument(
        "--choose",
        choices=sorted(METHOD_ALIASES),
        help="Skip interactive selection and choose by number or name.",
    )
    parser.add_argument(
        "--keep-candidates",
        type=Path,
        metavar="DIR",
        help=(
            "Keep all candidate PNGs, comparison.png, prepared assets, and "
            "sheet manifest/debug files."
        ),
    )
    parser.add_argument(
        "--export-frames",
        type=Path,
        metavar="DIR",
        help=(
            "Sheet mode only: export selected runtime frames individually in "
            "addition to the reassembled sheet."
        ),
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace existing output file.",
    )

    return parser


# =============================================================================
# Main
# =============================================================================

def main() -> int:
    args = build_parser().parse_args()

    source_path = args.source.expanduser().resolve()
    if not source_path.is_file():
        raise SystemExit(f"Source image not found: {source_path}")

    if args.colors is not None and not 2 <= args.colors <= 256:
        raise SystemExit("--colors must be between 2 and 256")
    colors = args.colors if args.colors is not None else 24
    if args.canvas_baseline < 1:
        raise SystemExit("--canvas-baseline must be positive")
    if args.frames is not None and args.frames < 1:
        raise SystemExit("--frames must be positive")
    if args.union_padding < 0:
        raise SystemExit("--union-padding must be 0 or greater")

    try:
        with Image.open(source_path) as opened:
            source = opened.convert("RGBA")
    except (OSError, ValueError) as exc:
        raise SystemExit(f"Could not read source image: {exc}") from exc

    # Any sheet-specific geometry argument implicitly enables sheet mode.
    sheet_mode = bool(
        args.sheet
        or args.frames is not None
        or args.grid is not None
        or args.source_cell is not None
    )

    inferred_size = infer_target_size_from_name(source_path)
    target_size = args.size or inferred_size or (96, 96)
    target_w, target_h = target_size
    target_is_square = target_w == target_h

    source_canvas = (
        args.source_canvas
        if args.source_canvas is not None
        else automatic_source_canvas(target_size, baseline=args.canvas_baseline)
    )

    if args.margin is not None:
        if args.margin < 0:
            raise SystemExit("--margin must be 0 or greater")
        margin = args.margin
    else:
        # Sprites/props retain their historical breathing room.
        # Terrain tiles must be allowed to reach the runtime cell boundary.
        margin = 0 if args.tile else automatic_margin(source_canvas)

    fit_mode = args.fit or ("cover" if args.tile else "contain")

    alpha_cutoff = (
        args.alpha_cutoff
        if args.alpha_cutoff is not None
        else (16 if target_is_square else 8)
    )
    if not 0 <= alpha_cutoff <= 255:
        raise SystemExit("--alpha-cutoff must be between 0 and 255")

    if args.pixel_source:
        prepare_filter = "nearest"
    elif args.prepare_filter == "auto":
        prepare_filter = "lanczos"
    else:
        prepare_filter = args.prepare_filter

    # The old script made square targets binary during prep. That is useful for
    # legacy already-pixel inputs but harmful to anti-aliased concept art before
    # reduction. Keep it only for explicit pixel/legacy behavior.
    binary_alpha_during_prepare = bool(
        args.pixel_source or args.legacy_prep_alpha
    )

    anchor = args.anchor or (
        "center"
        if args.tile
        else ("feet" if sheet_mode else "center")
    )

    output_path = (
        args.output.expanduser().resolve()
        if args.output
        else default_output(source_path, target_size, sheet_mode)
    )
    if output_path.exists() and not args.force:
        raise SystemExit(
            f"Output already exists: {output_path}\nPass --force to replace it."
        )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    temporary = None
    if args.keep_candidates:
        candidate_dir = args.keep_candidates.expanduser().resolve()
        candidate_dir.mkdir(parents=True, exist_ok=True)
    else:
        temporary = tempfile.TemporaryDirectory(prefix="custodian-pixelart-")
        candidate_dir = Path(temporary.name)

    geometry: SheetGeometry | None = None
    frame_candidates: dict[str, list[Image.Image]] | None = None

    if sheet_mode:
        geometry = resolve_sheet_geometry(
            source,
            source_path,
            args.frames,
            args.grid,
            args.source_cell,
        )
        source_frames = split_sheet_frames(source, geometry)
        source_frame_bboxes = frame_bbox_report(source_frames, alpha_cutoff)

        transform = calculate_shared_frame_transform(
            source_frames,
            prepared_cell_size=source_canvas,
            margin=margin,
            alpha_cutoff=alpha_cutoff,
            anchor=anchor,
            union_padding=args.union_padding,
            fit=fit_mode,
        )

        prepared_frames = prepare_sheet_frames(
            source_frames,
            transform,
            prepare_filter=prepare_filter,
            alpha_cutoff=alpha_cutoff,
            binary_alpha_during_prepare=binary_alpha_during_prepare,
        )

        # Debug prepared sheet preserves exact source grid layout.
        prepared_sheet = reassemble_sheet(
            prepared_frames,
            geometry,
            source_canvas,
        )
        prepared_sheet.save(candidate_dir / "prepared_sheet.png")

        candidates, frame_candidates = make_sheet_candidates(
            prepared_frames,
            geometry,
            target_size,
            colors,
            alpha_cutoff,
            crisp_colors=args.colors,
        )

        write_sheet_manifest(
            candidate_dir / "sheet_manifest.txt",
            geometry,
            target_size,
            transform,
            alpha_cutoff,
            prepare_filter,
            source_frame_bboxes,
        )

    else:
        prepared_source = fit_on_canvas(
            source,
            canvas_size=source_canvas,
            margin=margin,
            alpha_cutoff=alpha_cutoff,
            prepare_filter=prepare_filter,
            binary_alpha_during_prepare=binary_alpha_during_prepare,
            fit=fit_mode,
            anchor=anchor,
        )
        prepared_source.save(candidate_dir / "prepared_source.png")
        candidates = make_single_candidates(
            prepared_source,
            target_size=target_size,
            colors=colors,
            alpha_cutoff=alpha_cutoff,
            crisp_colors=args.colors,
        )

    # Write all candidates before selection.
    for key, image in candidates.items():
        name = METHODS[key][0]
        image.save(candidate_dir / f"{key}_{name}.png")

    comparison_path = candidate_dir / "comparison.png"
    build_comparison(candidates, comparison_path)

    # Diagnostics ---------------------------------------------------------
    print()
    print("CUSTODIAN pixel-art conversion")
    print("==============================")
    print(f"source:             {source_path}")
    print(f"mode:               {'spritesheet' if sheet_mode else 'single image'}")
    print(f"target frame:       {target_w}x{target_h}")
    print(f"preparation frame:  {source_canvas[0]}x{source_canvas[1]}")
    print(f"preparation margin: {margin}px")
    print(f"preparation filter: {prepare_filter}")
    print(f"fit:                {fit_mode}")
    print(f"tile preset:        {'yes' if args.tile else 'no'}")
    print(f"anchor:             {anchor}")
    print(f"alpha cutoff:       {alpha_cutoff}")
    print(
        "prep alpha:         "
        + ("binary" if binary_alpha_during_prepare else "soft until final reduction")
    )
    print(
        "palette colors:     "
        + (str(args.colors) if args.colors is not None else "24 (crisp preserved)")
    )

    if sheet_mode and geometry is not None:
        print(f"frames:             {geometry.frame_count}")
        print(f"grid:               {geometry.columns}x{geometry.rows}")
        print(
            f"source cell:        {geometry.source_cell[0]}x{geometry.source_cell[1]}"
        )
        print(
            "output sheet:       "
            f"{geometry.columns * target_w}x{geometry.rows * target_h}"
        )
        print(f"shared union bbox:  {transform.union_bbox}")
        print(f"shared scale:       {transform.scale:.6f}")
        print(f"shared offset:      {transform.destination_offset}")
        print("shared palette:     yes (balanced + clustered)")

    for key, image in candidates.items():
        if not binary_alpha_is_valid(image):
            raise SystemExit(
                f"Internal error: candidate {METHODS[key][0]} contains non-binary alpha"
            )

    chosen = METHOD_ALIASES[args.choose] if args.choose else None

    if chosen is None:
        if not sys.stdin.isatty():
            raise SystemExit(
                "Interactive selection needs a terminal; pass --choose 1, 2, or 3."
            )
        display_mode = show_comparison(comparison_path)
        print()
        print(f"Comparison: {comparison_path} ({display_mode})")
        if sheet_mode:
            print(f"Prepared sheet: {candidate_dir / 'prepared_sheet.png'}")
            print(f"Manifest:       {candidate_dir / 'sheet_manifest.txt'}")
        else:
            print(f"Prepared source: {candidate_dir / 'prepared_source.png'}")
        chosen = choose_interactively()

    if args.tile:
        contacts = tile_edge_contacts(candidates[chosen], alpha_cutoff)
        missing_horizontal = [
            edge for edge in ("left", "right")
            if not contacts[edge]
        ]

        print()
        print("Tile edge contact:")
        print(
            "  "
            + ", ".join(
                f"{edge}={'yes' if contacts[edge] else 'NO'}"
                for edge in ("left", "right", "top", "bottom")
            )
        )

        if missing_horizontal:
            print(
                "  TILE EDGE WARNING: selected art does not reach "
                + " and ".join(missing_horizontal)
                + " runtime edge"
                + ("s" if len(missing_horizontal) > 1 else "")
                + "."
            )
            print(
                "  For a continuous body tile, inspect the source alpha bounds "
                "or use --fit cover. Intentional broken-edge tiles may ignore "
                "this warning."
            )

    selected_name = METHODS[chosen][0]
    candidates[chosen].save(output_path, format="PNG")

    if sheet_mode and geometry is not None:
        expected_size = (
            geometry.columns * target_w,
            geometry.rows * target_h,
        )
        if candidates[chosen].size != expected_size:
            raise SystemExit(
                "Internal error: assembled sheet dimensions are wrong: "
                f"got {candidates[chosen].size}, expected {expected_size}"
            )

        if args.export_frames is not None:
            assert frame_candidates is not None
            export_dir = args.export_frames.expanduser().resolve()
            export_dir.mkdir(parents=True, exist_ok=True)
            selected_frames = frame_candidates[chosen]
            digits = max(2, len(str(len(selected_frames))))
            for index, frame in enumerate(selected_frames, start=1):
                frame.save(
                    export_dir / f"{source_path.stem}__frame_{index:0{digits}d}.png"
                )

    print()
    print(f"Wrote {selected_name} conversion:")
    print(f"  {output_path}")

    if args.keep_candidates:
        print("Kept candidates / diagnostics:")
        print(f"  {candidate_dir}")

    if args.export_frames is not None and sheet_mode:
        print("Exported selected runtime frames:")
        print(f"  {args.export_frames.expanduser().resolve()}")

    if temporary is not None:
        temporary.cleanup()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
