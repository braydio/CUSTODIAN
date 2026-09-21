#!/usr/bin/env python3
"""Prepare reviewed full-body Source Session strips for the modular Fists chain.

This is intentionally narrow: it applies the reviewed waist ownership seam,
extracts the one retained Fast 04 flare, mirrors cells independently for W,
and proves lower+upper reconstruct the cleaned body byte-for-byte.
"""
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


FRAME_COUNTS = {"fast_01": 6, "fast_02": 6, "fast_03": 7, "fast_04": 8}
WAIST_SEAM_Y = 58


def _components(frame: Image.Image) -> list[set[tuple[int, int]]]:
    alpha = frame.getchannel("A")
    remaining = {
        (x, y)
        for y in range(frame.height)
        for x in range(frame.width)
        if alpha.getpixel((x, y)) > 0
    }
    result: list[set[tuple[int, int]]] = []
    while remaining:
        seed = remaining.pop()
        queue: deque[tuple[int, int]] = deque((seed,))
        component = {seed}
        while queue:
            x, y = queue.popleft()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    neighbor = (x + dx, y + dy)
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        component.add(neighbor)
                        queue.append(neighbor)
        result.append(component)
    return sorted(result, key=len, reverse=True)


def _horizontal_frames(sheet: Image.Image, count: int) -> list[Image.Image]:
    if sheet.size != (count * 96, 96):
        raise ValueError(f"expected {count * 96}x96 reviewed strip, got {sheet.size}")
    return [sheet.crop((index * 96, 0, (index + 1) * 96, 96)) for index in range(count)]


def _sheet(frames: list[Image.Image]) -> Image.Image:
    result = Image.new("RGBA", (len(frames) * 96, 96), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        result.alpha_composite(frame, (index * 96, 0))
    return result


def _binary_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = list(rgba.getdata())
    rgba.putdata([(r, g, b, 255 if a else 0) for r, g, b, a in pixels])
    return rgba


def prepare(action: str, source: Path, output: Path) -> dict[str, Path]:
    count = FRAME_COUNTS[action]
    with Image.open(source) as opened:
        frames = [_binary_alpha(frame) for frame in _horizontal_frames(opened.convert("RGBA"), count)]

    body_frames: list[Image.Image] = []
    fx_frames: list[Image.Image] = []
    for frame_number, frame in enumerate(frames, start=1):
        body = frame.copy()
        fx = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        if action == "fast_04":
            for component in _components(frame)[1:]:
                if frame_number == 7 and len(component) >= 16:
                    for point in component:
                        fx.putpixel(point, frame.getpixel(point))
                for point in component:
                    body.putpixel(point, (0, 0, 0, 0))
        body_frames.append(body)
        fx_frames.append(fx)

    lower_frames: list[Image.Image] = []
    upper_frames: list[Image.Image] = []
    for body in body_frames:
        lower = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        upper = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        lower.alpha_composite(body.crop((0, WAIST_SEAM_Y, 96, 96)), (0, WAIST_SEAM_Y))
        upper.alpha_composite(body.crop((0, 0, 96, WAIST_SEAM_Y)), (0, 0))
        recomposed = Image.alpha_composite(lower, upper)
        if recomposed.tobytes() != body.tobytes():
            raise AssertionError(f"{action} modular split failed exact reconstruction")
        lower_frames.append(lower)
        upper_frames.append(upper)

    output.mkdir(parents=True, exist_ok=True)
    results: dict[str, Path] = {}
    for layer, layer_frames in (("lower_body", lower_frames), ("upper_body", upper_frames)):
        east = output / f"operator__{layer}__unarmed__attack__{action}__e__{count}f__96.png"
        west = output / f"operator__{layer}__unarmed__attack__{action}__w__{count}f__96.png"
        _sheet(layer_frames).save(east)
        _sheet([frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in layer_frames]).save(west)
        results[f"{layer}_e"] = east
        results[f"{layer}_w"] = west

    if action == "fast_04" and any(frame.getbbox() for frame in fx_frames):
        east = output / f"operator__fx__unarmed__attack__{action}__e__{count}f__96.png"
        west = output / f"operator__fx__unarmed__attack__{action}__w__{count}f__96.png"
        _sheet(fx_frames).save(east)
        _sheet([frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in fx_frames]).save(west)
        results["fx_e"] = east
        results["fx_w"] = west

    cleaned = output / f"{action}_e_cleaned_full_body_reference.png"
    _sheet(body_frames).save(cleaned)
    results["reference"] = cleaned
    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fast-01", type=Path, required=True)
    parser.add_argument("--fast-02", type=Path, required=True)
    parser.add_argument("--fast-03", type=Path, required=True)
    parser.add_argument("--fast-04", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    for action in FRAME_COUNTS:
        results = prepare(action, getattr(args, action.replace("_", "_")), args.output)
        print(action)
        for label, path in sorted(results.items()):
            print(f"  {label}: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
