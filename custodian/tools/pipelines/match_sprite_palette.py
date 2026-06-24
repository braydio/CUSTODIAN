#!/usr/bin/env python3
from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image


def srgb_to_linear(c: float) -> float:
    c = c / 255.0
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def rgb_to_xyz(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    r, g, b = [srgb_to_linear(v) for v in rgb]

    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
    return x, y, z


def xyz_to_lab(xyz: tuple[float, float, float]) -> tuple[float, float, float]:
    x, y, z = xyz

    # D65 white point
    xr = x / 0.95047
    yr = y / 1.00000
    zr = z / 1.08883

    def f(t: float) -> float:
        if t > 0.008856:
            return t ** (1.0 / 3.0)
        return (7.787 * t) + (16.0 / 116.0)

    fx, fy, fz = f(xr), f(yr), f(zr)
    l = (116.0 * fy) - 16.0
    a = 500.0 * (fx - fy)
    b = 200.0 * (fy - fz)
    return l, a, b


def rgb_to_lab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    return xyz_to_lab(rgb_to_xyz(rgb))


def lab_distance(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    return math.sqrt(
        (a[0] - b[0]) ** 2 +
        (a[1] - b[1]) ** 2 +
        (a[2] - b[2]) ** 2
    )


def extract_palette(path: Path, alpha_threshold: int, max_colors: int) -> list[tuple[int, int, int]]:
    image = Image.open(path).convert("RGBA")
    counts: dict[tuple[int, int, int], int] = {}

    for r, g, b, a in image.getdata():
        if a <= alpha_threshold:
            continue
        rgb = (r, g, b)
        counts[rgb] = counts.get(rgb, 0) + 1

    if not counts:
        raise RuntimeError(f"{path}: no non-transparent pixels found")

    # Most common colors first. For pixel art, this is usually good enough.
    palette = [rgb for rgb, _ in sorted(counts.items(), key=lambda item: item[1], reverse=True)]

    if max_colors > 0:
        palette = palette[:max_colors]

    return palette


def blend_rgb(
    source: tuple[int, int, int],
    target: tuple[int, int, int],
    strength: float,
) -> tuple[int, int, int]:
    strength = max(0.0, min(1.0, strength))
    return tuple(
        int(round(source[i] * (1.0 - strength) + target[i] * strength))
        for i in range(3)
    )


def build_lab_palette(palette: list[tuple[int, int, int]]) -> list[tuple[tuple[int, int, int], tuple[float, float, float]]]:
    return [(rgb, rgb_to_lab(rgb)) for rgb in palette]


def nearest_palette_color(
    rgb: tuple[int, int, int],
    lab_palette: list[tuple[tuple[int, int, int], tuple[float, float, float]]],
) -> tuple[int, int, int]:
    lab = rgb_to_lab(rgb)
    best_rgb = lab_palette[0][0]
    best_distance = float("inf")

    for candidate_rgb, candidate_lab in lab_palette:
        distance = lab_distance(lab, candidate_lab)
        if distance < best_distance:
            best_distance = distance
            best_rgb = candidate_rgb

    return best_rgb


def match_palette(
    reference: Path,
    target: Path,
    output: Path,
    alpha_threshold: int,
    max_colors: int,
    strength: float,
) -> None:
    palette = extract_palette(reference, alpha_threshold, max_colors)
    lab_palette = build_lab_palette(palette)

    image = Image.open(target).convert("RGBA")
    out = Image.new("RGBA", image.size)

    changed = 0
    total = 0

    pixels = []
    for r, g, b, a in image.getdata():
        if a <= alpha_threshold:
            pixels.append((r, g, b, a))
            continue

        total += 1
        source_rgb = (r, g, b)
        matched_rgb = nearest_palette_color(source_rgb, lab_palette)
        corrected_rgb = blend_rgb(source_rgb, matched_rgb, strength)

        if corrected_rgb != source_rgb:
            changed += 1

        pixels.append((*corrected_rgb, a))

    out.putdata(pixels)
    output.parent.mkdir(parents=True, exist_ok=True)
    out.save(output)

    print(f"reference: {reference}")
    print(f"target:    {target}")
    print(f"output:    {output}")
    print(f"palette colors used: {len(palette)}")
    print(f"changed non-transparent pixels: {changed}/{total}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Match one sprite sheet's palette to another.")
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--alpha-threshold", type=int, default=0)
    parser.add_argument("--max-colors", type=int, default=64)
    parser.add_argument(
        "--strength",
        type=float,
        default=0.65,
        help="0 keeps original target colors, 1 hard-remaps to reference palette.",
    )
    args = parser.parse_args()

    match_palette(
        reference=args.reference,
        target=args.target,
        output=args.output,
        alpha_threshold=args.alpha_threshold,
        max_colors=args.max_colors,
        strength=args.strength,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
