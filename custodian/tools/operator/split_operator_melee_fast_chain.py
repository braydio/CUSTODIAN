#!/usr/bin/env python3

from pathlib import Path

from PIL import Image, ImageChops


FRAME_WIDTH = 156
FRAME_HEIGHT = 96
FRAME_COUNT = 22

SOURCE = Path(
    "custodian/content/sprites/operator/new_operator/modular/chain_attack/"
    "operator__full_body_source__melee_1h__chain_attack_01__e__22f__156x96.png"
)
OUTPUT_DIR = Path(
    "custodian/content/sprites/operator/runtime/body/melee_1h"
)
SLICES = (
    ("operator__body__melee__fast_01__e__7f__156x96.png", 0, 7),
    ("operator__body__melee__fast_02__e__7f__156x96.png", 7, 14),
    ("operator__body__melee__fast_03__e__8f__156x96.png", 14, 22),
)


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    expected_size = (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT)
    if image.size != expected_size:
        raise ValueError(
            f"Expected {expected_size}, received {image.size}. "
            "Do not use a downscaled overview."
        )

    first = image.crop((0, 0, FRAME_WIDTH * 7, FRAME_HEIGHT))
    second = image.crop(
        (FRAME_WIDTH * 7, 0, FRAME_WIDTH * 14, FRAME_HEIGHT)
    )
    if ImageChops.difference(first, second).getbbox() is None:
        raise ValueError(
            "Fast 01 and Fast 02 source ranges are identical; "
            "verify the source tags before runtime wiring."
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for filename, start_frame, end_frame in SLICES:
        output = image.crop(
            (
                start_frame * FRAME_WIDTH,
                0,
                end_frame * FRAME_WIDTH,
                FRAME_HEIGHT,
            )
        )
        expected_width = (end_frame - start_frame) * FRAME_WIDTH
        if output.size != (expected_width, FRAME_HEIGHT):
            raise RuntimeError(f"Bad slice size for {filename}: {output.size}")
        output_path = OUTPUT_DIR / filename
        output.save(output_path)
        print(f"Wrote {output_path}: {output.size}")


if __name__ == "__main__":
    main()
