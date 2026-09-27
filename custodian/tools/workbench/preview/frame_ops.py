"""Pure PIL frame slicing, scaling, and diffing — no Operator/Asset V2 semantics.

Extracted from ``custodian/tools/operator/animation_preview.py``. This module
must stay free of any Operator or Asset Pipeline V2 identity/authority
concepts; it only knows about PIL images, frame strips, and pixels.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Literal

from PIL import Image

ZoomMode = Literal["auto", "1x", "2x", "3x", "fit"]


def split_strip(path: Path, frames: int, frame_size: tuple[int, int]) -> list[Image.Image]:
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
    width, height = frame_size
    if image.size != (width * frames, height):
        raise ValueError(f"strip contract mismatch: {path} is {image.size}, expected {(width * frames, height)}")
    return [image.crop((index * width, 0, (index + 1) * width, height)) for index in range(frames)]


def split_image(image: Image.Image, frame_size: tuple[int, int]) -> list[Image.Image]:
    """Split an RGBA strip using its real rectangular frame contract."""
    width, height = frame_size
    count = max(1, image.width // width)
    return [image.convert("RGBA").crop((index * width, 0, (index + 1) * width, height)) for index in range(count)]


def scale_preview_frame(frame: Image.Image, zoom: ZoomMode | int) -> Image.Image:
    """Scale review pixels only by exact integer nearest-neighbor replication."""
    rgba = frame.convert("RGBA")
    if zoom in ("auto", "fit", "1x", 1):
        return rgba.copy()
    scale = int(str(zoom).removesuffix("x"))
    if scale not in (2, 3):
        raise ValueError(f"unsupported integer preview zoom: {zoom}")
    return rgba.resize((rgba.width * scale, rgba.height * scale), Image.Resampling.NEAREST)


@dataclass(frozen=True)
class FrameDiffMetrics:
    changed_pixels: int
    bbox: tuple[int, int, int, int] | None
    left_size: tuple[int, int]
    right_size: tuple[int, int]
    left_present: bool = True
    right_present: bool = True

    @property
    def equal(self) -> bool:
        return self.changed_pixels == 0 and self.left_size == self.right_size and self.left_present and self.right_present


def compare_frames(
    left: Image.Image | None,
    right: Image.Image | None,
    *,
    left_size: tuple[int, int] | None = None,
    right_size: tuple[int, int] | None = None,
) -> tuple[Image.Image, FrameDiffMetrics]:
    left_present, right_present = left is not None, right is not None
    if left is not None:
        left = left.convert("RGBA")
        left_size = left.size
    if right is not None:
        right = right.convert("RGBA")
        right_size = right.size
    left_size, right_size = left_size or (0, 0), right_size or (0, 0)
    width, height = max(1, left_size[0], right_size[0]), max(1, left_size[1], right_size[1])
    lhs = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    rhs = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    if left is not None:
        lhs.alpha_composite(left, (0, 0))
    if right is not None:
        rhs.alpha_composite(right, (0, 0))
    diff = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    changed = 0
    min_x, min_y, max_x, max_y = width, height, -1, -1
    lp, rp, out = lhs.load(), rhs.load(), diff.load()
    for y in range(height):
        for x in range(width):
            a, b = lp[x, y], rp[x, y]
            if a == b:
                continue
            changed += 1
            min_x, min_y, max_x, max_y = min(min_x, x), min(min_y, y), max(max_x, x), max(max_y, y)
            delta = tuple(abs(a[c] - b[c]) for c in range(4))
            out[x, y] = (max(48, delta[0]), max(48, delta[1]), max(48, delta[2]), 255)
    bbox = None if not changed else (min_x, min_y, max_x + 1, max_y + 1)
    return diff, FrameDiffMetrics(changed, bbox, left_size, right_size, left_present, right_present)
