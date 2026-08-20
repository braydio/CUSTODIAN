"""Image inspection — physical property detection without semantic interpretation."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path

from PIL import Image


class FrameLayout(str, Enum):
    COPY = "copy"
    HORIZONTAL_STRIP = "horizontal_strip"
    GRID = "grid"
    AMBIGUOUS = "ambiguous"


@dataclass(frozen=True)
class AssetInspection:
    source_path: Path
    width: int
    height: int
    frame_width: int
    frame_height: int
    frame_count: int
    layout: FrameLayout


def inspect_png(path: Path, fw: int, fh: int) -> AssetInspection:
    """Inspect a PNG file and infer frame layout given expected frame dimensions.

    This answers "what physically exists?" — not "what does this art mean?"
    """
    with Image.open(path) as img:
        w, h = img.size

    if w == fw and h == fh:
        return AssetInspection(
            source_path=path,
            width=w,
            height=h,
            frame_width=fw,
            frame_height=fh,
            frame_count=1,
            layout=FrameLayout.COPY,
        )

    if h == fh and w > fw and w % fw == 0:
        frames = w // fw
        return AssetInspection(
            source_path=path,
            width=w,
            height=h,
            frame_width=fw,
            frame_height=fh,
            frame_count=frames,
            layout=FrameLayout.HORIZONTAL_STRIP,
        )

    return AssetInspection(
        source_path=path,
        width=w,
        height=h,
        frame_width=fw,
        frame_height=fh,
        frame_count=0,
        layout=FrameLayout.AMBIGUOUS,
    )
