#!/usr/bin/env python3
"""Byte-exact composite check for South Fast 01 modular ownership layers."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "content/sprites/operator/source/animations/unarmed/attack/fast_01/operator__full_body__unarmed__attack__fast_01__s__6f__96.png"
LOWER = ROOT / "content/sprites/operator/source/animations/unarmed/attack/fast_01/operator__lower_body__unarmed__attack__fast_01__s__6f__96.png"
UPPER = ROOT / "content/sprites/operator/source/animations/unarmed/attack/fast_01/operator__upper_body__unarmed__attack__fast_01__s__6f__96.png"


def main() -> int:
    source = Image.open(SOURCE)
    lower = Image.open(LOWER)
    upper = Image.open(UPPER)
    expected = (576, 96)
    for label, image in (("source", source), ("lower", lower), ("upper", upper)):
        if image.size != expected or image.mode != "RGBA":
            raise AssertionError(f"{label} must be 576x96 true RGBA, got {image.size} {image.mode}")

    lower_alpha = lower.getchannel("A")
    upper_alpha = upper.getchannel("A")
    if lower_alpha.getextrema() != (0, 255) or upper_alpha.getextrema() != (0, 255):
        raise AssertionError("both modular layers must contain opaque pixels and real transparency")
    if ImageChops.multiply(lower_alpha, upper_alpha).getbbox() is not None:
        raise AssertionError("authored ownership layers unexpectedly overlap")

    composite = Image.alpha_composite(lower, upper)
    for frame in range(6):
        rect = (frame * 96, 0, (frame + 1) * 96, 96)
        expected_frame = source.crop(rect)
        actual_frame = composite.crop(rect)
        if expected_frame.tobytes() != actual_frame.tobytes():
            diff = ImageChops.difference(expected_frame, actual_frame)
            raise AssertionError(f"frame {frame} composite differs at {diff.getbbox()}")

    print("operator_fast01_south_decomposition_smoke: PASS (6/6 frames byte-identical)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
