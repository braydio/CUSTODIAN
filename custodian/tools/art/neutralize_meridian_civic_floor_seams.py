#!/usr/bin/env python3

from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]

SOURCE = (
    ROOT
    / "asset_drop/source_work/meridian_civic_floor"
    / "meridian_civic_floor_atlas__alpha_clean.png"
)

OUTPUT = (
    ROOT
    / "asset_drop/source_work/meridian_civic_floor"
    / "meridian_civic_floor_atlas__all_cells_seam_neutralized.png"
)

REVIEW = (
    ROOT
    / "asset_drop/source_work/meridian_civic_floor"
    / "meridian_civic_floor_atlas__all_cells_seam_neutralized_review.png"
)

CELL = 32
EDGE_WIDTH = 2

# A pixel must be dark enough AND significantly darker than the material just
# inside the tile before we consider it a baked outline.
EDGE_DARK_THRESHOLD = 72
MIN_BRIGHTNESS_DELTA = 16

# Target all atlas cells.
TARGET_CELLS = {(x, y) for y in range(16) for x in range(16)}


def brightness(pixel):
    r, g, b, _a = pixel
    return max(r, g, b)


def median_rgb(samples):
    if not samples:
        return None

    return (
        int(median(p[0] for p in samples)),
        int(median(p[1] for p in samples)),
        int(median(p[2] for p in samples)),
    )


def sample_vertical_inward(
    original,
    gx,
    gy,
    local_x,
    local_y,
    direction_x,
):
    """
    Sample three pixels moving inward horizontally.

    Examples:
      left edge x=0 samples local x=2,3,4
      left inner edge x=1 samples local x=3,4,5
      right edge x=31 samples local x=29,28,27
      right inner edge x=30 samples local x=28,27,26
    """
    samples = []

    start_distance = EDGE_WIDTH

    for distance in range(start_distance, start_distance + 3):
        sx = local_x + direction_x * distance
        sy = local_y

        if not (0 <= sx < CELL and 0 <= sy < CELL):
            continue

        pixel = original.getpixel((gx + sx, gy + sy))

        if pixel[3] > 0:
            samples.append(pixel)

    return samples


def sample_horizontal_inward(
    original,
    gx,
    gy,
    local_x,
    local_y,
    direction_y,
):
    """
    Sample three pixels moving inward vertically.

    Examples:
      top edge y=0 samples local y=2,3,4
      top inner edge y=1 samples local y=3,4,5
      bottom edge y=31 samples local y=29,28,27
      bottom inner edge y=30 samples local y=28,27,26
    """
    samples = []

    start_distance = EDGE_WIDTH

    for distance in range(start_distance, start_distance + 3):
        sx = local_x
        sy = local_y + direction_y * distance

        if not (0 <= sx < CELL and 0 <= sy < CELL):
            continue

        pixel = original.getpixel((gx + sx, gy + sy))

        if pixel[3] > 0:
            samples.append(pixel)

    return samples


def sample_corner(original, gx, gy, corner_x, corner_y):
    """
    Corners use a true inward 3x3 material sample instead of inheriting one
    particular horizontal/vertical edge result.
    """
    if corner_x == 0:
        xs = range(2, 5)
    else:
        xs = range(CELL - 5, CELL - 2)

    if corner_y == 0:
        ys = range(2, 5)
    else:
        ys = range(CELL - 5, CELL - 2)

    samples = []

    for ly in ys:
        for lx in xs:
            pixel = original.getpixel((gx + lx, gy + ly))
            if pixel[3] > 0:
                samples.append(pixel)

    return samples


def should_replace(pixel, replacement_rgb):
    if pixel[3] == 0:
        return False

    old_brightness = brightness(pixel)
    replacement_brightness = max(replacement_rgb)

    if old_brightness > EDGE_DARK_THRESHOLD:
        return False

    if replacement_brightness - old_brightness < MIN_BRIGHTNESS_DELTA:
        return False

    return True


def process_edge_pixel(
    original,
    result,
    gx,
    gy,
    lx,
    ly,
    samples,
):
    global_x = gx + lx
    global_y = gy + ly

    old = original.getpixel((global_x, global_y))
    replacement_rgb = median_rgb(samples)

    if replacement_rgb is None:
        return False

    if not should_replace(old, replacement_rgb):
        return False

    result.putpixel(
        (global_x, global_y),
        (
            replacement_rgb[0],
            replacement_rgb[1],
            replacement_rgb[2],
            old[3],  # preserve alpha exactly
        ),
    )

    return True


def count_dark_perimeter(image, cell_x, cell_y):
    gx = cell_x * CELL
    gy = cell_y * CELL

    positions = set()

    for i in range(CELL):
        for edge in range(EDGE_WIDTH):
            positions.add((gx + edge, gy + i))
            positions.add((gx + CELL - 1 - edge, gy + i))
            positions.add((gx + i, gy + edge))
            positions.add((gx + i, gy + CELL - 1 - edge))

    count = 0

    for position in positions:
        pixel = image.getpixel(position)

        if pixel[3] > 0 and brightness(pixel) <= EDGE_DARK_THRESHOLD:
            count += 1

    return count


def neutralize_cell(original, result, cell_x, cell_y):
    gx = cell_x * CELL
    gy = cell_y * CELL

    replacements = 0

    # --------------------------------------------------------------
    # LEFT / RIGHT EDGES
    # --------------------------------------------------------------
    for ly in range(EDGE_WIDTH, CELL - EDGE_WIDTH):

        # Left edge band: x=0,1
        for lx in range(EDGE_WIDTH):
            samples = sample_vertical_inward(
                original,
                gx,
                gy,
                lx,
                ly,
                +1,
            )

            if process_edge_pixel(
                original,
                result,
                gx,
                gy,
                lx,
                ly,
                samples,
            ):
                replacements += 1

        # Right edge band: x=30,31
        for lx in range(CELL - EDGE_WIDTH, CELL):
            samples = sample_vertical_inward(
                original,
                gx,
                gy,
                lx,
                ly,
                -1,
            )

            if process_edge_pixel(
                original,
                result,
                gx,
                gy,
                lx,
                ly,
                samples,
            ):
                replacements += 1

    # --------------------------------------------------------------
    # TOP / BOTTOM EDGES
    # --------------------------------------------------------------
    for lx in range(EDGE_WIDTH, CELL - EDGE_WIDTH):

        # Top edge band: y=0,1
        for ly in range(EDGE_WIDTH):
            samples = sample_horizontal_inward(
                original,
                gx,
                gy,
                lx,
                ly,
                +1,
            )

            if process_edge_pixel(
                original,
                result,
                gx,
                gy,
                lx,
                ly,
                samples,
            ):
                replacements += 1

        # Bottom edge band: y=30,31
        for ly in range(CELL - EDGE_WIDTH, CELL):
            samples = sample_horizontal_inward(
                original,
                gx,
                gy,
                lx,
                ly,
                -1,
            )

            if process_edge_pixel(
                original,
                result,
                gx,
                gy,
                lx,
                ly,
                samples,
            ):
                replacements += 1

    # --------------------------------------------------------------
    # CORNERS
    # --------------------------------------------------------------
    corners = [
        (0, 0),
        (CELL - 1, 0),
        (0, CELL - 1),
        (CELL - 1, CELL - 1),
    ]

    for lx, ly in corners:
        samples = sample_corner(
            original,
            gx,
            gy,
            lx,
            ly,
        )

        if process_edge_pixel(
            original,
            result,
            gx,
            gy,
            lx,
            ly,
            samples,
        ):
            replacements += 1

    # Second corner-pixel layer: (1,0), (0,1), (1,1), etc.
    corner_regions = [
        range(0, EDGE_WIDTH),
        range(CELL - EDGE_WIDTH, CELL),
    ]

    for xs in corner_regions:
        for ys in corner_regions:
            for lx in xs:
                for ly in ys:
                    if (lx, ly) in corners:
                        continue

                    samples = sample_corner(
                        original,
                        gx,
                        gy,
                        0 if lx < CELL // 2 else CELL - 1,
                        0 if ly < CELL // 2 else CELL - 1,
                    )

                    if process_edge_pixel(
                        original,
                        result,
                        gx,
                        gy,
                        lx,
                        ly,
                        samples,
                    ):
                        replacements += 1

    return replacements


def verify_alpha_unchanged(original, result):
    for cx, cy in TARGET_CELLS:
        left = cx * CELL
        top = cy * CELL

        for ly in range(CELL):
            for lx in range(CELL):
                position = (left + lx, top + ly)

                before_alpha = original.getpixel(position)[3]
                after_alpha = result.getpixel(position)[3]

                if before_alpha != after_alpha:
                    raise RuntimeError(
                        f"Alpha changed in cell {(cx, cy)} "
                        f"at local pixel {(lx, ly)}: "
                        f"{before_alpha} -> {after_alpha}"
                    )


def build_review(original, result):
    scale = 2

    before = original.resize(
        (original.width * scale, original.height * scale),
        Image.Resampling.NEAREST,
    )

    after = result.resize(
        (result.width * scale, result.height * scale),
        Image.Resampling.NEAREST,
    )

    gutter = 32
    header = 40

    review = Image.new(
        "RGBA",
        (
            before.width + after.width + gutter * 3,
            before.height + header + gutter * 2,
        ),
        (24, 24, 24, 255),
    )

    draw = ImageDraw.Draw(review)

    draw.text(
        (gutter, 12),
        "BEFORE",
        fill=(255, 255, 255, 255),
    )

    after_x = gutter * 2 + before.width

    draw.text(
        (after_x, 12),
        "AFTER - ALL CELLS SEAM NEUTRALIZED",
        fill=(255, 255, 255, 255),
    )

    review.alpha_composite(
        before,
        (gutter, header),
    )

    review.alpha_composite(
        after,
        (after_x, header),
    )

    return review


def main():
    if not SOURCE.exists():
        raise SystemExit(
            f"Missing source:\n{SOURCE}\n\n"
            "Run clean_meridian_civic_floor_atlas.py first."
        )

    original = Image.open(SOURCE).convert("RGBA")

    if original.size != (512, 512):
        raise SystemExit(f"Expected 512x512 atlas, got {original.size}")

    result = original.copy()

    dark_before = 0
    dark_after = 0
    replacements = 0

    per_cell_report = []

    for cx, cy in sorted(TARGET_CELLS, key=lambda p: (p[1], p[0])):

        before = count_dark_perimeter(
            original,
            cx,
            cy,
        )

        replaced = neutralize_cell(
            original,
            result,
            cx,
            cy,
        )

        after = count_dark_perimeter(
            result,
            cx,
            cy,
        )

        dark_before += before
        dark_after += after
        replacements += replaced

        per_cell_report.append(
            (
                cx,
                cy,
                before,
                after,
                replaced,
            )
        )

    verify_alpha_unchanged(
        original,
        result,
    )

    reduction = 1.0 - dark_after / dark_before if dark_before else 0.0

    OUTPUT.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    result.save(OUTPUT)

    review = build_review(
        original,
        result,
    )
    review.save(REVIEW)

    print()
    print("MERIDIAN CIVIC FLOOR SEAM NEUTRALIZATION")
    print("=" * 60)
    print(f"source:       {SOURCE}")
    print(f"output:       {OUTPUT}")
    print(f"review:       {REVIEW}")
    print()
    print(f"target cells: {len(TARGET_CELLS)}")
    print(f"replacements: {replacements}")
    print()
    print(f"dark perimeter pixels before: {dark_before}")
    print(f"dark perimeter pixels after:  {dark_after}")
    print(f"reduction:                    {reduction:.1%}")
    print()

    for cx, cy, before, after, replaced in per_cell_report:
        print(
            f"cell ({cx:2},{cy:2}) "
            f"dark {before:3} -> {after:3} "
            f"replaced={replaced:3}"
        )

    print()

    if reduction < 0.50:
        print(
            "WARNING: reduction below 50%. "
            "The source borders may be brighter than the configured threshold."
        )
    else:
        print("Seam cleanup produced a substantial border reduction.")

    print()
    print("IMPORTANT:")
    print("Review the PNG before Asset V2 ingest.")
    print("This script does NOT modify runtime assets.")


if __name__ == "__main__":
    main()
