#!/usr/bin/env python3

from pathlib import Path
from PIL import Image
import shutil

SRC = Path("creche_recovery_alcove/wake.png")
BACKUP = Path("creche_recovery_alcove/wake.source_original.png")
OUT = Path("creche_recovery_alcove/wake.normalized.png")

FRAME_COUNT = 8
TARGET_FRAME = (192, 256)
TARGET_SHEET = (192 * FRAME_COUNT, 256)

ALPHA_THRESHOLD = 4
PADDING = 4


def bbox_alpha(img, threshold=4):
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a >= threshold else 0)
    return mask.getbbox()


def resize_alpha_safe(img, size):
    # Premultiplied alpha prevents dirty fringe colors.
    return (
        img.convert("RGBa")
        .resize(size, Image.Resampling.LANCZOS, reducing_gap=3.0)
        .convert("RGBA")
    )


def main():
    if not SRC.exists():
        raise SystemExit(f"missing: {SRC}")

    if not BACKUP.exists():
        shutil.copy2(SRC, BACKUP)
        print(f"backup: {BACKUP}")

    # Always normalize from untouched hi-res original once backup exists.
    source_path = BACKUP if BACKUP.exists() else SRC

    img = Image.open(source_path).convert("RGBA")

    if img.size != (2172, 724):
        raise SystemExit(
            f"unexpected source size: {img.size}, expected 2172x724"
        )

    w, h = img.size

    # The art is 8 visually-even frames across, but 2172 / 8 = 271.5.
    # Use deterministic fractional boundaries instead of demanding integer
    # source cell widths.
    boundaries = [
        round(i * w / FRAME_COUNT)
        for i in range(FRAME_COUNT + 1)
    ]

    raw_frames = []

    print("source boundaries:")

    for i in range(FRAME_COUNT):
        x0 = boundaries[i]
        x1 = boundaries[i + 1]

        frame = img.crop((x0, 0, x1, h))

        bbox = bbox_alpha(frame, ALPHA_THRESHOLD)

        if bbox is None:
            raise RuntimeError(f"frame {i + 1} is empty")

        # Make sure our fractional split didn't cut the actual sprite.
        alpha = frame.getchannel("A")

        left_max = max(
            alpha.getpixel((0, y))
            for y in range(frame.height)
        )

        right_max = max(
            alpha.getpixel((frame.width - 1, y))
            for y in range(frame.height)
        )

        if left_max > 8 or right_max > 8:
            raise RuntimeError(
                f"frame {i + 1}: visible art touches split boundary "
                f"(left={left_max}, right={right_max})"
            )

        raw_frames.append(frame)

        print(
            f"  {i+1}: x={x0}:{x1} "
            f"width={x1-x0} bbox={bbox}"
        )

    # ------------------------------------------------------------------
    # Establish ONE common crop for all frames.
    #
    # We do not independently trim/fit every frame. That would make the pod
    # breathe in size or drift during playback.
    # ------------------------------------------------------------------

    bboxes = [
        bbox_alpha(frame, ALPHA_THRESHOLD)
        for frame in raw_frames
    ]

    union_left = min(b[0] for b in bboxes)
    union_top = min(b[1] for b in bboxes)
    union_right = max(b[2] for b in bboxes)
    union_bottom = max(b[3] for b in bboxes)

    union_bbox = (
        union_left,
        union_top,
        union_right,
        union_bottom,
    )

    crop_w = union_right - union_left
    crop_h = union_bottom - union_top

    target_w, target_h = TARGET_FRAME

    available_w = target_w - PADDING * 2
    available_h = target_h - PADDING * 2

    scale = min(
        available_w / crop_w,
        available_h / crop_h,
    )

    resized_w = round(crop_w * scale)
    resized_h = round(crop_h * scale)

    print()
    print(f"common source crop: {union_bbox} -> {crop_w}x{crop_h}")
    print(f"common scale: {scale:.6f}")
    print(f"rendered sprite footprint: {resized_w}x{resized_h}")

    normalized = []

    for i, frame in enumerate(raw_frames):
        crop = frame.crop(union_bbox)

        resized = resize_alpha_safe(
            crop,
            (resized_w, resized_h),
        )

        cell = Image.new(
            "RGBA",
            TARGET_FRAME,
            (0, 0, 0, 0),
        )

        # Fixed registration for every frame.
        x = (target_w - resized_w) // 2
        y = target_h - PADDING - resized_h

        cell.alpha_composite(
            resized,
            (x, y),
        )

        normalized.append(cell)

    sheet = Image.new(
        "RGBA",
        TARGET_SHEET,
        (0, 0, 0, 0),
    )

    for i, frame in enumerate(normalized):
        sheet.alpha_composite(
            frame,
            (i * target_w, 0),
        )

    sheet.save(
        OUT,
        compress_level=9,
    )

    print()
    print(f"wrote: {OUT}")
    print(f"size: {sheet.size}")
    print()
    print("EXPECTED:")
    print("  1536x256")
    print("  8 frames")
    print("  192x256 each")


if __name__ == "__main__":
    main()
