#!/usr/bin/env python3
"""
Batch color-match enemy grunt body sprite sheets against a reference PNG.

Default behavior:

    reference:
        ./source_color.png

    targets:
        ./enemy_grunt__body*.png

    outputs:
        ./color_matched/<original filename>

The script preserves:
    - image dimensions
    - transparency
    - filenames
    - sprite-sheet/frame layout

It performs a statistical RGB color transfer similar to the original
Aseprite/Lua script:
    1. Measure target RGB mean/std.
    2. Measure reference RGB mean/std.
    3. Normalize target channels.
    4. Map them into the reference distribution.
    5. Blend toward the mapped color.
    6. Apply small art-direction corrections.
    7. Preserve original alpha.

Requires:
    python3 -m pip install Pillow
"""

from __future__ import annotations

import argparse
import math
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

# =============================================================================
# Defaults
# =============================================================================

DEFAULT_REFERENCE = "source_color.png"
DEFAULT_PATTERN = "enemy_grunt__body*.png"
DEFAULT_OUTPUT_DIR = "color_matched"

DEFAULT_MATCH_STRENGTH = 0.90

# Preserve the tuning from your Lua version.
DEFAULT_EXTRA_DARKEN = 1.00
DEFAULT_EXTRA_COOL_R = 0.97
DEFAULT_EXTRA_COOL_G = 0.98
DEFAULT_EXTRA_COOL_B = 1.02

DEFAULT_SATURATION_MULT = 0.97

DEFAULT_MIN_ALPHA = 8
DEFAULT_SAMPLE_STEP = 2


# =============================================================================
# Statistics
# =============================================================================


@dataclass(frozen=True)
class ChannelStats:
    mean_r: float
    mean_g: float
    mean_b: float

    std_r: float
    std_g: float
    std_b: float

    samples: int


def clamp(
    value: float,
    minimum: float = 0.0,
    maximum: float = 255.0,
) -> float:
    return max(
        minimum,
        min(maximum, value),
    )


def luminance(
    r: float,
    g: float,
    b: float,
) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def adjust_saturation(
    r: float,
    g: float,
    b: float,
    multiplier: float,
) -> tuple[float, float, float]:
    """
    Scale RGB distance from luminance.

        1.0 = unchanged
        <1  = desaturate
        >1  = saturate
    """
    lum = luminance(
        r,
        g,
        b,
    )

    return (
        lum + (r - lum) * multiplier,
        lum + (g - lum) * multiplier,
        lum + (b - lum) * multiplier,
    )


def collect_stats(
    image: Image.Image,
    min_alpha: int,
    sample_step: int,
) -> ChannelStats:
    """
    Calculate per-channel RGB mean and standard deviation from visible pixels.
    """
    rgba = image.convert("RGBA")

    width, height = rgba.size
    pixels = rgba.load()

    count = 0

    sum_r = 0.0
    sum_g = 0.0
    sum_b = 0.0

    sum_r2 = 0.0
    sum_g2 = 0.0
    sum_b2 = 0.0

    for y in range(
        0,
        height,
        sample_step,
    ):
        for x in range(
            0,
            width,
            sample_step,
        ):
            r, g, b, a = pixels[x, y]

            if a < min_alpha:
                continue

            count += 1

            sum_r += r
            sum_g += g
            sum_b += b

            sum_r2 += r * r
            sum_g2 += g * g
            sum_b2 += b * b

    if count == 0:
        raise ValueError("Image contains no visible pixels above the alpha threshold.")

    mean_r = sum_r / count
    mean_g = sum_g / count
    mean_b = sum_b / count

    # Same protection as your Lua script.
    # Never allow stddev to approach zero.
    std_r = math.sqrt(
        max(
            (sum_r2 / count) - mean_r * mean_r,
            1.0,
        )
    )

    std_g = math.sqrt(
        max(
            (sum_g2 / count) - mean_g * mean_g,
            1.0,
        )
    )

    std_b = math.sqrt(
        max(
            (sum_b2 / count) - mean_b * mean_b,
            1.0,
        )
    )

    return ChannelStats(
        mean_r=mean_r,
        mean_g=mean_g,
        mean_b=mean_b,
        std_r=std_r,
        std_g=std_g,
        std_b=std_b,
        samples=count,
    )


# =============================================================================
# Color transfer
# =============================================================================


def recolor_image(
    source: Image.Image,
    target_stats: ChannelStats,
    reference_stats: ChannelStats,
    *,
    match_strength: float,
    extra_darken: float,
    cool_r: float,
    cool_g: float,
    cool_b: float,
    saturation_mult: float,
    min_alpha: int,
) -> Image.Image:
    """
    Apply statistical color transfer while preserving alpha.
    """
    source = source.convert("RGBA")

    output = source.copy()

    src_pixels = source.load()
    out_pixels = output.load()

    width, height = source.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = src_pixels[x, y]

            if a < min_alpha:
                # Keep transparent / nearly transparent pixels unchanged.
                out_pixels[x, y] = (
                    r,
                    g,
                    b,
                    a,
                )
                continue

            # -------------------------------------------------------------
            # Statistical transfer:
            #
            # target standardized -> reference distribution
            # -------------------------------------------------------------

            matched_r = (
                (r - target_stats.mean_r) / target_stats.std_r
            ) * reference_stats.std_r + reference_stats.mean_r

            matched_g = (
                (g - target_stats.mean_g) / target_stats.std_g
            ) * reference_stats.std_g + reference_stats.mean_g

            matched_b = (
                (b - target_stats.mean_b) / target_stats.std_b
            ) * reference_stats.std_b + reference_stats.mean_b

            # -------------------------------------------------------------
            # Blend original toward the transferred result.
            # -------------------------------------------------------------

            nr = r + (matched_r - r) * match_strength

            ng = g + (matched_g - g) * match_strength

            nb = b + (matched_b - b) * match_strength

            # -------------------------------------------------------------
            # Existing art-direction correction from Lua script.
            # -------------------------------------------------------------

            nr *= cool_r * extra_darken

            ng *= cool_g * extra_darken

            nb *= cool_b * extra_darken

            # -------------------------------------------------------------
            # Saturation adjustment.
            # -------------------------------------------------------------

            nr, ng, nb = adjust_saturation(
                nr,
                ng,
                nb,
                saturation_mult,
            )

            out_pixels[x, y] = (
                round(clamp(nr)),
                round(clamp(ng)),
                round(clamp(nb)),
                a,
            )

    return output


# =============================================================================
# Processing
# =============================================================================


def process_file(
    source_path: Path,
    output_path: Path,
    reference_stats: ChannelStats,
    args: argparse.Namespace,
) -> None:
    with Image.open(source_path) as opened:
        source = opened.convert("RGBA")

    target_stats = collect_stats(
        source,
        min_alpha=args.min_alpha,
        sample_step=args.sample_step,
    )

    result = recolor_image(
        source,
        target_stats,
        reference_stats,
        match_strength=args.match_strength,
        extra_darken=args.extra_darken,
        cool_r=args.cool_r,
        cool_g=args.cool_g,
        cool_b=args.cool_b,
        saturation_mult=args.saturation,
        min_alpha=args.min_alpha,
    )

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    result.save(
        output_path,
        format="PNG",
    )


# =============================================================================
# CLI
# =============================================================================


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Batch color-match enemy_grunt__body PNG sprite sheets "
            "against source_color.png."
        )
    )

    parser.add_argument(
        "--reference",
        default=DEFAULT_REFERENCE,
        help=(
            "Reference PNG in the current directory. " f"Default: {DEFAULT_REFERENCE}"
        ),
    )

    parser.add_argument(
        "--pattern",
        default=DEFAULT_PATTERN,
        help=("Glob used to select target PNGs. " f"Default: {DEFAULT_PATTERN!r}"),
    )

    parser.add_argument(
        "--output-dir",
        default=DEFAULT_OUTPUT_DIR,
        help=(
            "Output directory when not using --in-place. "
            f"Default: {DEFAULT_OUTPUT_DIR}"
        ),
    )

    parser.add_argument(
        "--in-place",
        action="store_true",
        help=(
            "Overwrite matching source PNGs instead of writing "
            "to the output directory."
        ),
    )

    parser.add_argument(
        "--backup",
        action="store_true",
        help=(
            "When used with --in-place, create <filename>.bak.png "
            "before overwriting."
        ),
    )

    parser.add_argument(
        "--match-strength",
        type=float,
        default=DEFAULT_MATCH_STRENGTH,
        help=(
            "How strongly each target is moved toward the reference. "
            "0.0 = unchanged; 1.0 = full statistical match. "
            f"Default: {DEFAULT_MATCH_STRENGTH}"
        ),
    )

    parser.add_argument(
        "--extra-darken",
        type=float,
        default=DEFAULT_EXTRA_DARKEN,
        help=f"Brightness multiplier. Default: {DEFAULT_EXTRA_DARKEN}",
    )

    parser.add_argument(
        "--cool-r",
        type=float,
        default=DEFAULT_EXTRA_COOL_R,
        help=f"Red multiplier. Default: {DEFAULT_EXTRA_COOL_R}",
    )

    parser.add_argument(
        "--cool-g",
        type=float,
        default=DEFAULT_EXTRA_COOL_G,
        help=f"Green multiplier. Default: {DEFAULT_EXTRA_COOL_G}",
    )

    parser.add_argument(
        "--cool-b",
        type=float,
        default=DEFAULT_EXTRA_COOL_B,
        help=f"Blue multiplier. Default: {DEFAULT_EXTRA_COOL_B}",
    )

    parser.add_argument(
        "--saturation",
        type=float,
        default=DEFAULT_SATURATION_MULT,
        help=("Saturation multiplier. " f"Default: {DEFAULT_SATURATION_MULT}"),
    )

    parser.add_argument(
        "--min-alpha",
        type=int,
        default=DEFAULT_MIN_ALPHA,
        help=(
            "Pixels below this alpha are ignored for matching. "
            f"Default: {DEFAULT_MIN_ALPHA}"
        ),
    )

    parser.add_argument(
        "--sample-step",
        type=int,
        default=DEFAULT_SAMPLE_STEP,
        help=(
            "Sample every Nth pixel when calculating statistics. "
            f"Default: {DEFAULT_SAMPLE_STEP}"
        ),
    )

    return parser


# =============================================================================
# Main
# =============================================================================


def main() -> int:
    args = build_parser().parse_args()

    cwd = Path.cwd()

    # -------------------------------------------------------------------------
    # Validate arguments
    # -------------------------------------------------------------------------

    if not 0.0 <= args.match_strength <= 1.0:
        raise SystemExit("--match-strength must be between 0.0 and 1.0")

    if not 0 <= args.min_alpha <= 255:
        raise SystemExit("--min-alpha must be between 0 and 255")

    if args.sample_step < 1:
        raise SystemExit("--sample-step must be at least 1")

    # -------------------------------------------------------------------------
    # Reference
    # -------------------------------------------------------------------------

    reference_path = cwd / args.reference

    if not reference_path.is_file():
        raise SystemExit(f"Reference not found:\n" f"  {reference_path}")

    print()
    print("Enemy Grunt Batch Color Match")
    print("=============================")
    print(f"cwd:       {cwd}")
    print(f"reference: {reference_path.name}")
    print(f"pattern:   {args.pattern}")

    with Image.open(reference_path) as opened:
        reference = opened.convert("RGBA")

    reference_stats = collect_stats(
        reference,
        min_alpha=args.min_alpha,
        sample_step=args.sample_step,
    )

    print(
        "reference RGB mean: "
        f"{reference_stats.mean_r:.2f}, "
        f"{reference_stats.mean_g:.2f}, "
        f"{reference_stats.mean_b:.2f}"
    )

    print(
        "reference RGB std:  "
        f"{reference_stats.std_r:.2f}, "
        f"{reference_stats.std_g:.2f}, "
        f"{reference_stats.std_b:.2f}"
    )

    # -------------------------------------------------------------------------
    # Targets
    # -------------------------------------------------------------------------

    targets = sorted(
        path
        for path in cwd.glob(args.pattern)
        if (
            path.is_file()
            and path.suffix.lower() == ".png"
            and path.resolve() != reference_path.resolve()
        )
    )

    if not targets:
        raise SystemExit(f"No files found matching:\n" f"  {args.pattern}")

    print(f"targets:   {len(targets)}")

    if args.in_place:
        print("output:    IN PLACE")

        if not args.backup:
            print("warning:   originals will be overwritten")

    else:
        output_dir = cwd / args.output_dir

        output_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        print(f"output:    {output_dir}")

    print()

    # -------------------------------------------------------------------------
    # Batch
    # -------------------------------------------------------------------------

    processed = 0
    failed = 0

    for index, source_path in enumerate(
        targets,
        start=1,
    ):
        print(f"[{index:02d}/{len(targets):02d}] " f"{source_path.name}")

        if args.in_place:
            output_path = source_path

            if args.backup:
                backup_path = source_path.with_name(f"{source_path.stem}.bak.png")

                if not backup_path.exists():
                    shutil.copy2(
                        source_path,
                        backup_path,
                    )

                    print(f"         backup -> {backup_path.name}")

        else:
            output_path = cwd / args.output_dir / source_path.name

        try:
            process_file(
                source_path,
                output_path,
                reference_stats,
                args,
            )

        except Exception as exc:
            failed += 1

            print(f"         ERROR: {exc}")

            continue

        processed += 1

        if args.in_place:
            print("         matched -> overwritten")
        else:
            print(f"         matched -> " f"{output_path.relative_to(cwd)}")

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------

    print()
    print("Done")
    print("====")
    print(f"processed: {processed}")
    print(f"failed:    {failed}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
