#!/usr/bin/env python3
"""Split approved South Fast 01 pixels into semantic modular layer strips.

The ownership masks below are hand-authored from the existing E/W convention:
upper_body owns the head, torso, shoulders, arms and hands; lower_body owns the
pelvis, legs and lower garment beginning at the established y=51 hip seam.
South-specific arm/hand polygons override that seam where a limb crosses it.
Pixels are transferred verbatim from the canonical full-body source; no
resampling, recoloring, synthesis, or alpha-derived ownership occurs.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "content/sprites/operator/source/animations/unarmed/attack/fast_01/operator__full_body__unarmed__attack__fast_01__s__6f__96.png"
OUTPUT_DIR = SOURCE.parent
LOWER_NAME = "operator__lower_body__unarmed__attack__fast_01__s__6f__96.png"
UPPER_NAME = "operator__upper_body__unarmed__attack__fast_01__s__6f__96.png"
FRAME_SIZE = 96
FRAME_COUNT = 6
HIP_SEAM_Y = 51

# Hand-traced South forearm/hand contours for pixels below the E/W hip seam.
# Coordinates are local to each 96x96 frame. Layer selection is geometric and
# authored here; source alpha is only consulted when copying source pixels.
UPPER_LIMB_POLYGONS: tuple[tuple[tuple[tuple[int, int], ...], ...], ...] = (
    (
        ((11, 46), (20, 43), (31, 44), (38, 49), (39, 56), (34, 63), (26, 70), (17, 72), (11, 66), (10, 57)),
        ((61, 46), (69, 43), (80, 44), (87, 49), (87, 58), (84, 66), (77, 72), (68, 70), (62, 63), (59, 56)),
    ),
    (
        ((7, 47), (18, 43), (31, 44), (39, 48), (41, 55), (35, 63), (26, 69), (15, 71), (8, 65), (6, 57)),
        ((64, 43), (75, 42), (86, 47), (89, 55), (86, 63), (79, 68), (71, 64), (65, 57)),
    ),
    (
        ((8, 47), (18, 43), (31, 44), (40, 48), (42, 55), (36, 62), (27, 68), (16, 70), (8, 65), (6, 57)),
        ((62, 42), (73, 40), (84, 44), (89, 51), (87, 59), (80, 64), (72, 60), (66, 54)),
    ),
    (
        ((3, 45), (14, 42), (28, 43), (40, 46), (46, 51), (44, 57), (36, 63), (25, 68), (13, 69), (5, 64), (2, 55)),
        ((63, 43), (74, 42), (85, 46), (89, 53), (86, 61), (79, 66), (70, 62), (64, 56)),
    ),
    (
        ((9, 46), (19, 43), (31, 44), (39, 48), (41, 55), (36, 62), (28, 68), (17, 70), (9, 65), (7, 56)),
        ((61, 45), (70, 42), (81, 44), (88, 50), (88, 58), (83, 65), (75, 69), (67, 64), (61, 57)),
    ),
    (
        ((11, 46), (20, 43), (31, 44), (38, 49), (39, 56), (34, 63), (26, 70), (17, 72), (11, 66), (10, 57)),
        ((61, 46), (69, 43), (80, 44), (87, 49), (87, 58), (84, 66), (77, 72), (68, 70), (62, 63), (59, 56)),
    ),
)


def _upper_limb_masks() -> list[Image.Image]:
    masks: list[Image.Image] = []
    for polygons in UPPER_LIMB_POLYGONS:
        mask = Image.new("1", (FRAME_SIZE, FRAME_SIZE), 0)
        draw = ImageDraw.Draw(mask)
        for polygon in polygons:
            draw.polygon(polygon, fill=1)
        masks.append(mask)
    return masks


def split(source: Image.Image) -> tuple[Image.Image, Image.Image]:
    if source.size != (FRAME_SIZE * FRAME_COUNT, FRAME_SIZE):
        raise ValueError(f"expected 576x96 six-frame strip, got {source.size}")
    if source.mode != "RGBA":
        raise ValueError(f"expected true RGBA source, got {source.mode}")

    lower = Image.new("RGBA", source.size, (0, 0, 0, 0))
    upper = Image.new("RGBA", source.size, (0, 0, 0, 0))
    upper_masks = _upper_limb_masks()

    source_pixels = source.load()
    lower_pixels = lower.load()
    upper_pixels = upper.load()
    for frame in range(FRAME_COUNT):
        x_offset = frame * FRAME_SIZE
        limb_mask = upper_masks[frame].load()
        for y in range(FRAME_SIZE):
            for x in range(FRAME_SIZE):
                pixel = source_pixels[x_offset + x, y]
                if pixel[3] == 0:
                    continue
                # The authored horizontal seam is only the default. Explicit
                # arm/hand regions remain upper-owned when they cross it.
                if y < HIP_SEAM_Y or limb_mask[x, y]:
                    upper_pixels[x_offset + x, y] = pixel
                else:
                    lower_pixels[x_offset + x, y] = pixel
    return lower, upper


def validate(source: Image.Image, lower: Image.Image, upper: Image.Image) -> None:
    if source.size != lower.size or source.size != upper.size:
        raise ValueError("layer geometry differs from approved source")
    composite = Image.alpha_composite(lower, upper)
    difference = ImageChops.difference(source, composite)
    if any(difference.tobytes()):
        raise ValueError(f"pixel-perfect composite mismatch at {difference.getbbox()}")
    if lower.getchannel("A").getbbox() is None or upper.getchannel("A").getbbox() is None:
        raise ValueError("both modular layers must contain authored pixels")
    if lower.getchannel("A").getextrema()[0] != 0 or upper.getchannel("A").getextrema()[0] != 0:
        raise ValueError("both modular layers must retain genuine transparency")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    lower_path = args.output_dir / LOWER_NAME
    upper_path = args.output_dir / UPPER_NAME
    if args.check_only:
        lower = Image.open(lower_path).convert("RGBA")
        upper = Image.open(upper_path).convert("RGBA")
    else:
        lower, upper = split(source)
    validate(source, lower, upper)
    if not args.check_only:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        lower.save(lower_path, format="PNG", optimize=False)
        upper.save(upper_path, format="PNG", optimize=False)
        # Reopen encoded PNGs and prove the actual deliverables, not only the
        # in-memory images, exactly composite to the canonical source.
        validate(source, Image.open(lower_path).convert("RGBA"), Image.open(upper_path).convert("RGBA"))
    print(f"PASS: {FRAME_COUNT} frames pixel-identical; wrote {lower_path.name} + {upper_path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
