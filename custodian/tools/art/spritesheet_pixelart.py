#!/usr/bin/env python3
"""
Pixel-art downscaler / converter.

Designed for both:
    - traditional square assets such as 96x96 actors/props
    - irregular or rectangular assets such as machines, fabricators,
      terminals, large props, weapons, and environmental objects

Key behavior:
    - trims transparent dead space
    - preserves source aspect ratio
    - automatically creates a preparation canvas matching TARGET aspect ratio
    - preserves the proven 768x768 preparation canvas for 96x96 targets
    - produces three conversion candidates:
        1. crisp
        2. balanced
        3. clustered
    - outputs binary alpha only: 0 or 255
    - supports already-pixel-art sources via --pixel-source
"""

from __future__ import annotations

import argparse
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFont
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: Pillow.\n"
        "Install it with:\n"
        "    python3 -m pip install Pillow"
    ) from exc


# =============================================================================
# Conversion methods
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
        "Area reduction, stronger values, tighter palette, and conservative cleanup.",
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


# =============================================================================
# Parsing helpers
# =============================================================================

def parse_size(value: str) -> tuple[int, int]:
    """
    Parse:
        96
        96x96
        156x96
        192x128
    """
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
        raise argparse.ArgumentTypeError(
            "size dimensions must be positive"
        )

    return width, height


# =============================================================================
# Alpha helpers
# =============================================================================

def clamp_alpha_binary(
    image: Image.Image,
    cutoff: int = 16,
) -> Image.Image:
    """
    Force alpha to:
        0   transparent
        255 opaque
    """
    rgba = image.convert("RGBA")

    alpha = rgba.getchannel("A").point(
        lambda value:
            255 if value >= cutoff else 0
    )

    rgba.putalpha(alpha)

    return rgba


def trim_transparent_border(
    image: Image.Image,
    cutoff: int = 16,
) -> Image.Image:
    """
    Remove empty transparent space around an asset.

    The cutoff is only used to determine the bounding box.
    It does NOT necessarily alter source alpha.
    """
    rgba = image.convert("RGBA")

    alpha_mask = rgba.getchannel("A").point(
        lambda value:
            255 if value >= cutoff else 0
    )

    bbox = alpha_mask.getbbox()

    if bbox is None:
        return rgba.copy()

    return rgba.crop(bbox)


# =============================================================================
# Preparation canvas
# =============================================================================

def automatic_source_canvas(
    target_size: tuple[int, int],
    baseline: int = 768,
) -> tuple[int, int]:
    """
    Build a high-resolution preparation canvas with EXACTLY the same
    aspect ratio as the requested runtime frame.

    The smaller target dimension is scaled to approximately `baseline`.

    Examples with baseline=768:

        96x96
            scale = 8
            canvas = 768x768

        156x96
            scale = 8
            canvas = 1248x768

        192x128
            scale = 6
            canvas = 1152x768

        64x128
            scale = 12
            canvas = 768x1536

    This preserves the old 96x96 -> 768x768 workflow exactly.
    """
    target_w, target_h = target_size

    smaller_dimension = min(
        target_w,
        target_h,
    )

    scale = max(
        1,
        math.ceil(
            baseline / smaller_dimension
        ),
    )

    return (
        target_w * scale,
        target_h * scale,
    )


def automatic_margin(
    canvas_size: tuple[int, int],
    reference_margin: int = 32,
    reference_size: int = 768,
) -> int:
    """
    Scale margin proportionally.

    A canvas whose smaller dimension is 768px receives the familiar
    32px margin.
    """
    smallest = min(canvas_size)

    return max(
        0,
        round(
            smallest
            * reference_margin
            / reference_size
        ),
    )


def contain_fit_on_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    margin: int,
    alpha_cutoff: int,
    prepare_filter: str,
    binary_alpha_during_prepare: bool,
) -> Image.Image:
    """
    Trim source and proportionally contain it inside a transparent canvas.

    Crucially:
        canvas aspect ratio should already match target aspect ratio.

    This means a wide machine does not lose half its effective pixel budget
    by being funneled through a square preparation canvas.
    """
    image = trim_transparent_border(
        image,
        cutoff=alpha_cutoff,
    )

    canvas_w, canvas_h = canvas_size

    usable_w = max(
        1,
        canvas_w - margin * 2,
    )

    usable_h = max(
        1,
        canvas_h - margin * 2,
    )

    if image.width < 1 or image.height < 1:
        return Image.new(
            "RGBA",
            canvas_size,
            (0, 0, 0, 0),
        )

    scale = min(
        usable_w / image.width,
        usable_h / image.height,
    )

    new_w = max(
        1,
        int(round(image.width * scale)),
    )

    new_h = max(
        1,
        int(round(image.height * scale)),
    )

    if prepare_filter == "nearest":
        resample = Image.Resampling.NEAREST
    elif prepare_filter == "box":
        resample = Image.Resampling.BOX
    else:
        resample = Image.Resampling.LANCZOS

    resized = image.resize(
        (new_w, new_h),
        resample,
    )

    canvas = Image.new(
        "RGBA",
        canvas_size,
        (0, 0, 0, 0),
    )

    offset_x = (
        canvas_w - new_w
    ) // 2

    offset_y = (
        canvas_h - new_h
    ) // 2

    canvas.alpha_composite(
        resized,
        (
            offset_x,
            offset_y,
        ),
    )

    if binary_alpha_during_prepare:
        canvas = clamp_alpha_binary(
            canvas,
            cutoff=alpha_cutoff,
        )

    return canvas


# =============================================================================
# Quantization
# =============================================================================

def quantize_rgba(
    image: Image.Image,
    colors: int,
    alpha_cutoff: int,
) -> Image.Image:
    """
    Quantize RGB without dithering while producing binary alpha.
    """
    rgba = image.convert("RGBA")

    alpha = rgba.getchannel("A").point(
        lambda value:
            255 if value >= alpha_cutoff else 0
    )

    rgb = Image.new(
        "RGB",
        rgba.size,
        (0, 0, 0),
    )

    rgb.paste(
        rgba.convert("RGB"),
        mask=alpha,
    )

    quantized = rgb.quantize(
        colors=max(
            2,
            min(colors, 256),
        ),
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")

    result = quantized.convert("RGBA")

    result.putalpha(alpha)

    return result


# =============================================================================
# Safer clustered cleanup
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


def pixel_luminance(
    color: tuple[int, int, int, int],
) -> float:
    return (
        0.2126 * color[0]
        + 0.7152 * color[1]
        + 0.0722 * color[2]
    )


def clean_isolated_colors(
    image: Image.Image,
    max_color_distance: int = 80,
) -> Image.Image:
    """
    Conservative 3x3 isolated-color cleanup.

    Unlike the older cleanup pass, this avoids casually deleting:
        - tiny indicator lights
        - antenna tips
        - single-pixel highlights
        - glowing controls
        - small machine details

    A pixel is only replaced when:
        - it occurs once locally
        - a neighboring color strongly dominates
        - the replacement color is reasonably similar
        - the center pixel is not an obvious bright accent
    """
    source = image.convert("RGBA")

    pixels = source.load()

    output = source.copy()
    out_pixels = output.load()

    width, height = source.size

    max_distance_sq = (
        max_color_distance
        * max_color_distance
    )

    for y in range(height):
        for x in range(width):

            center = pixels[x, y]

            if center[3] == 0:
                continue

            counts: dict[
                tuple[int, int, int, int],
                int,
            ] = {}

            for neighbor_y in range(
                max(0, y - 1),
                min(height, y + 2),
            ):
                for neighbor_x in range(
                    max(0, x - 1),
                    min(width, x + 2),
                ):

                    color = pixels[
                        neighbor_x,
                        neighbor_y,
                    ]

                    if color[3] == 0:
                        continue

                    counts[color] = (
                        counts.get(color, 0)
                        + 1
                    )

            if not counts:
                continue

            replacement, replacement_count = max(
                counts.items(),
                key=lambda item: item[1],
            )

            center_count = counts.get(
                center,
                0,
            )

            # Must actually be isolated.
            if center_count != 1:
                continue

            # Require a strong local consensus.
            if replacement_count < 5:
                continue

            # Do not erase radically different intentional accent colors.
            distance = color_distance_sq(
                center,
                replacement,
            )

            if distance > max_distance_sq:
                continue

            # Protect bright single-pixel glints / lights.
            center_luma = pixel_luminance(center)
            replacement_luma = pixel_luminance(
                replacement
            )

            if (
                center_luma
                > replacement_luma + 55
            ):
                continue

            out_pixels[x, y] = replacement

    return output


# =============================================================================
# Candidate creation
# =============================================================================

def make_candidates(
    prepared_source: Image.Image,
    target_size: tuple[int, int],
    colors: int,
    alpha_cutoff: int,
) -> dict[str, Image.Image]:
    """
    Produce all three conversion candidates.
    """
    rgba = prepared_source.convert("RGBA")

    # -------------------------------------------------------------------------
    # 1. Crisp
    # -------------------------------------------------------------------------
    crisp = rgba.resize(
        target_size,
        Image.Resampling.NEAREST,
    )

    crisp = clamp_alpha_binary(
        crisp,
        cutoff=alpha_cutoff,
    )

    # -------------------------------------------------------------------------
    # 2. Balanced
    # -------------------------------------------------------------------------
    balanced_reduced = rgba.resize(
        target_size,
        Image.Resampling.BOX,
    )

    balanced = quantize_rgba(
        balanced_reduced,
        colors,
        alpha_cutoff=alpha_cutoff,
    )

    # -------------------------------------------------------------------------
    # 3. Clustered
    # -------------------------------------------------------------------------
    clustered_reduced = rgba.resize(
        target_size,
        Image.Resampling.BOX,
    )

    clustered_reduced = (
        ImageEnhance.Contrast(
            clustered_reduced
        ).enhance(1.12)
    )

    clustered_reduced = (
        ImageEnhance.Color(
            clustered_reduced
        ).enhance(1.08)
    )

    clustered = quantize_rgba(
        clustered_reduced,
        max(
            8,
            colors * 2 // 3,
        ),
        alpha_cutoff=alpha_cutoff,
    )

    clustered = clean_isolated_colors(
        clustered
    )

    clustered = clamp_alpha_binary(
        clustered,
        cutoff=alpha_cutoff,
    )

    return {
        "1": crisp,
        "2": balanced,
        "3": clustered,
    }


# =============================================================================
# Checkerboard / preview
# =============================================================================

def checkerboard(
    size: tuple[int, int],
    cell: int = 12,
) -> Image.Image:
    board = Image.new(
        "RGBA",
        size,
        (56, 58, 64, 255),
    )

    draw = ImageDraw.Draw(board)

    light = (
        78,
        81,
        89,
        255,
    )

    for y in range(
        0,
        size[1],
        cell,
    ):
        for x in range(
            0,
            size[0],
            cell,
        ):

            if (
                x // cell
                + y // cell
            ) % 2:

                draw.rectangle(
                    (
                        x,
                        y,
                        x + cell - 1,
                        y + cell - 1,
                    ),
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
            return ImageFont.truetype(
                candidate,
                14,
            )

    return ImageFont.load_default()


def build_comparison(
    candidates: dict[str, Image.Image],
    destination: Path,
) -> None:
    """
    Build one side-by-side inspection image.
    """
    max_dimension = max(
        candidates["1"].size
    )

    preview_scale = max(
        1,
        min(
            8,
            512 // max_dimension,
        ),
    )

    preview_size = tuple(
        dimension * preview_scale
        for dimension
        in candidates["1"].size
    )

    gap = 24
    label_height = 64

    panel_width = preview_size[0]

    canvas = Image.new(
        "RGBA",
        (
            gap * 4
            + panel_width * 3,
            gap * 2
            + label_height
            + preview_size[1],
        ),
        (
            28,
            30,
            35,
            255,
        ),
    )

    draw = ImageDraw.Draw(canvas)
    font = load_preview_font()

    for index, key in enumerate(
        (
            "1",
            "2",
            "3",
        )
    ):
        name, description = METHODS[key]

        x = (
            gap
            + index
            * (
                panel_width
                + gap
            )
        )

        draw.text(
            (
                x,
                gap,
            ),
            f"{key}. {name.upper()}",
            fill=(
                245,
                246,
                250,
            ),
            font=font,
        )

        draw.text(
            (
                x,
                gap + 24,
            ),
            description.split(";")[0],
            fill=(
                184,
                188,
                198,
            ),
            font=font,
        )

        preview = candidates[key].resize(
            preview_size,
            Image.Resampling.NEAREST,
        )

        background = checkerboard(
            preview_size
        )

        background.alpha_composite(
            preview
        )

        canvas.alpha_composite(
            background,
            (
                x,
                gap + label_height,
            ),
        )

    canvas.convert("RGB").save(
        destination
    )


# =============================================================================
# Preview / selection
# =============================================================================

def show_comparison(
    path: Path,
) -> str:
    if (
        sys.stdout.isatty()
        and shutil.which("chafa")
    ):
        subprocess.run(
            [
                "chafa",
                "--format=symbols",
                "--size=120x40",
                str(path),
            ],
            check=False,
        )

        return "terminal preview"

    if (
        os.environ.get("DISPLAY")
        or os.environ.get("WAYLAND_DISPLAY")
    ):
        if shutil.which("xdg-open"):

            subprocess.Popen(
                [
                    "xdg-open",
                    str(path),
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )

            return "desktop viewer"

    return "file only"


def choose_interactively() -> str:
    print()
    print("Choose the output:")

    for key, (
        name,
        description,
    ) in METHODS.items():

        print(
            f"  {key}) "
            f"{name:<10} "
            f"{description}"
        )

    while True:
        try:
            answer = input(
                "Selection [1-3, q to cancel]: "
            ).strip().lower()

        except EOFError as exc:
            raise SystemExit(
                "Interactive selection needs a terminal; "
                "pass --choose 1, 2, or 3."
            ) from exc

        if answer in METHOD_ALIASES:
            return METHOD_ALIASES[
                answer
            ]

        if answer in {
            "q",
            "quit",
            "cancel",
        }:
            raise SystemExit(
                "Cancelled; no output was written."
            )

        print(
            "Enter 1, 2, or 3."
        )


# =============================================================================
# Output naming
# =============================================================================

def default_output(
    source: Path,
    size: tuple[int, int],
) -> Path:
    return source.with_name(
        f"{source.stem}"
        f"_pixel_"
        f"{size[0]}x{size[1]}"
        f".png"
    )


# =============================================================================
# CLI
# =============================================================================

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate crisp, balanced, and clustered pixel-art candidates. "
            "Supports both square and irregular/rectangular runtime assets."
        )
    )

    parser.add_argument(
        "source",
        type=Path,
        help=(
            "Source PNG or other Pillow-readable image."
        ),
    )

    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help=(
            "Final PNG path."
        ),
    )

    parser.add_argument(
        "--size",
        type=parse_size,
        default=(96, 96),
        metavar="N|WxH",
        help=(
            "Final runtime dimensions. "
            "Default: 96x96."
        ),
    )

    parser.add_argument(
        "--source-canvas",
        type=parse_size,
        default=None,
        metavar="N|WxH",
        help=(
            "Override preparation canvas. "
            "Default: automatic aspect-matched canvas. "
            "96x96 therefore still uses 768x768."
        ),
    )

    parser.add_argument(
        "--canvas-baseline",
        type=int,
        default=768,
        metavar="PX",
        help=(
            "Approximate preparation resolution for the smaller "
            "target dimension. Default: 768."
        ),
    )

    parser.add_argument(
        "--margin",
        type=int,
        default=None,
        help=(
            "Transparent preparation margin in pixels. "
            "Default: automatically scaled from the traditional "
            "32px-on-768px margin."
        ),
    )

    parser.add_argument(
        "--colors",
        type=int,
        default=24,
        help=(
            "Balanced-method palette size. "
            "Default: 24."
        ),
    )

    parser.add_argument(
        "--alpha-cutoff",
        type=int,
        default=None,
        help=(
            "Final alpha cutoff. "
            "Default: 16 for square assets, 8 for rectangular assets."
        ),
    )

    parser.add_argument(
        "--prepare-filter",
        choices=[
            "auto",
            "nearest",
            "box",
            "lanczos",
        ],
        default="auto",
        help=(
            "Resampling used while fitting source into preparation canvas. "
            "auto = Lanczos unless --pixel-source is supplied."
        ),
    )

    parser.add_argument(
        "--pixel-source",
        action="store_true",
        help=(
            "Source is already pixel art. "
            "Use nearest-neighbor preparation and preserve hard pixel clusters."
        ),
    )

    parser.add_argument(
        "--legacy-prep-alpha",
        action="store_true",
        help=(
            "Force binary alpha during the high-resolution preparation stage. "
            "This recreates the older pipeline behavior for non-square assets."
        ),
    )

    parser.add_argument(
        "--choose",
        choices=sorted(
            METHOD_ALIASES
        ),
        help=(
            "Skip interactive selection and choose method "
            "by number or name."
        ),
    )

    parser.add_argument(
        "--keep-candidates",
        type=Path,
        metavar="DIR",
        help=(
            "Keep all candidate PNGs, comparison.png, "
            "and prepared_source.png."
        ),
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help=(
            "Replace existing output file."
        ),
    )

    return parser


# =============================================================================
# Main
# =============================================================================

def main() -> int:
    args = build_parser().parse_args()

    # -------------------------------------------------------------------------
    # Validate source
    # -------------------------------------------------------------------------

    source_path = (
        args.source
        .expanduser()
        .resolve()
    )

    if not source_path.is_file():
        raise SystemExit(
            f"Source image not found: {source_path}"
        )

    if not (
        2
        <= args.colors
        <= 256
    ):
        raise SystemExit(
            "--colors must be between 2 and 256"
        )

    if args.canvas_baseline < 1:
        raise SystemExit(
            "--canvas-baseline must be positive"
        )

    # -------------------------------------------------------------------------
    # Target geometry
    # -------------------------------------------------------------------------

    target_w, target_h = args.size

    target_is_square = (
        target_w == target_h
    )

    # -------------------------------------------------------------------------
    # Source preparation canvas
    # -------------------------------------------------------------------------

    if args.source_canvas is not None:
        source_canvas = (
            args.source_canvas
        )

    else:
        source_canvas = (
            automatic_source_canvas(
                args.size,
                baseline=args.canvas_baseline,
            )
        )

    # -------------------------------------------------------------------------
    # Margin
    # -------------------------------------------------------------------------

    if args.margin is not None:

        if args.margin < 0:
            raise SystemExit(
                "--margin must be 0 or greater"
            )

        margin = args.margin

    else:

        margin = automatic_margin(
            source_canvas
        )

    # -------------------------------------------------------------------------
    # Alpha threshold
    # -------------------------------------------------------------------------

    if args.alpha_cutoff is not None:
        alpha_cutoff = (
            args.alpha_cutoff
        )

    else:
        # Preserve old square behavior.
        #
        # More forgiving default for irregular silhouettes.
        alpha_cutoff = (
            16
            if target_is_square
            else 8
        )

    if not (
        0
        <= alpha_cutoff
        <= 255
    ):
        raise SystemExit(
            "--alpha-cutoff must be between 0 and 255"
        )

    # -------------------------------------------------------------------------
    # Preparation filter
    # -------------------------------------------------------------------------

    if args.pixel_source:
        prepare_filter = "nearest"

    elif (
        args.prepare_filter
        == "auto"
    ):
        prepare_filter = "lanczos"

    else:
        prepare_filter = (
            args.prepare_filter
        )

    # -------------------------------------------------------------------------
    # Preparation-alpha behavior
    # -------------------------------------------------------------------------

    # Existing square pipeline keeps its old behavior.
    #
    # Rectangular assets preserve soft alpha during high-res preparation,
    # then receive binary final alpha after reduction.
    binary_alpha_during_prepare = (
        target_is_square
        or args.legacy_prep_alpha
        or args.pixel_source
    )

    # -------------------------------------------------------------------------
    # Output
    # -------------------------------------------------------------------------

    output_path = (
        args.output
        .expanduser()
        .resolve()
        if args.output
        else default_output(
            source_path,
            args.size,
        )
    )

    if (
        output_path.exists()
        and not args.force
    ):
        raise SystemExit(
            f"Output already exists: {output_path}\n"
            "Pass --force to replace it."
        )

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    # -------------------------------------------------------------------------
    # Read source
    # -------------------------------------------------------------------------

    try:
        with Image.open(
            source_path
        ) as opened:

            source = opened.convert(
                "RGBA"
            )

    except (
        OSError,
        ValueError,
    ) as exc:
        raise SystemExit(
            f"Could not read source image: {exc}"
        ) from exc

    # -------------------------------------------------------------------------
    # Prepare
    # -------------------------------------------------------------------------

    prepared_source = (
        contain_fit_on_canvas(
            source,
            canvas_size=source_canvas,
            margin=margin,
            alpha_cutoff=alpha_cutoff,
            prepare_filter=prepare_filter,
            binary_alpha_during_prepare=(
                binary_alpha_during_prepare
            ),
        )
    )

    # -------------------------------------------------------------------------
    # Candidates
    # -------------------------------------------------------------------------

    candidates = make_candidates(
        prepared_source,
        target_size=args.size,
        colors=args.colors,
        alpha_cutoff=alpha_cutoff,
    )

    # -------------------------------------------------------------------------
    # Working directory
    # -------------------------------------------------------------------------

    temporary = None

    if args.keep_candidates:

        candidate_dir = (
            args.keep_candidates
            .expanduser()
            .resolve()
        )

        candidate_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

    else:

        temporary = (
            tempfile.TemporaryDirectory(
                prefix="custodian-pixelart-"
            )
        )

        candidate_dir = Path(
            temporary.name
        )

    # -------------------------------------------------------------------------
    # Write candidates
    # -------------------------------------------------------------------------

    prepared_source.save(
        candidate_dir
        / "prepared_source.png"
    )

    for key, image in candidates.items():

        name = METHODS[key][0]

        image.save(
            candidate_dir
            / f"{key}_{name}.png"
        )

    comparison_path = (
        candidate_dir
        / "comparison.png"
    )

    build_comparison(
        candidates,
        comparison_path,
    )

    # -------------------------------------------------------------------------
    # Print geometry diagnostics
    # -------------------------------------------------------------------------

    print()
    print("Pixel-art conversion")
    print("====================")
    print(
        f"source:             {source_path}"
    )
    print(
        f"target:             {target_w}x{target_h}"
    )
    print(
        f"preparation canvas: "
        f"{source_canvas[0]}x{source_canvas[1]}"
    )
    print(
        f"preparation margin: {margin}px"
    )
    print(
        f"preparation filter: {prepare_filter}"
    )
    print(
        f"alpha cutoff:       {alpha_cutoff}"
    )
    print(
        "prep alpha:         "
        + (
            "binary"
            if binary_alpha_during_prepare
            else "soft until final reduction"
        )
    )
    print(
        f"palette colors:      {args.colors}"
    )

    # -------------------------------------------------------------------------
    # Selection
    # -------------------------------------------------------------------------

    chosen = (
        METHOD_ALIASES[
            args.choose
        ]
        if args.choose
        else None
    )

    if chosen is None:

        if not sys.stdin.isatty():
            raise SystemExit(
                "Interactive selection needs a terminal; "
                "pass --choose 1, 2, or 3."
            )

        display_mode = show_comparison(
            comparison_path
        )

        print()
        print(
            f"Prepared source: "
            f"{candidate_dir / 'prepared_source.png'}"
        )

        print(
            f"Comparison: "
            f"{comparison_path} "
            f"({display_mode})"
        )

        chosen = choose_interactively()

    # -------------------------------------------------------------------------
    # Save final
    # -------------------------------------------------------------------------

    selected_name = METHODS[
        chosen
    ][0]

    candidates[
        chosen
    ].save(
        output_path,
        format="PNG",
    )

    print()
    print(
        f"Wrote {selected_name} conversion:"
    )
    print(
        f"  {output_path}"
    )

    if args.keep_candidates:
        print(
            f"Kept candidates:"
        )
        print(
            f"  {candidate_dir}"
        )

    if temporary is not None:
        temporary.cleanup()

    return 0


if __name__ == "__main__":
    raise SystemExit(
        main()
    )
