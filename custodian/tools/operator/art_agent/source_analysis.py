from __future__ import annotations

from PIL import Image

from .source_models import FrameSourceAnalysis


def extract_frames(
    image: Image.Image, *, columns: int, rows: int, frame_count: int
) -> list[Image.Image]:
    if columns < 1 or rows < 1 or columns * rows < frame_count:
        raise ValueError("grid cannot contain requested frame count")
    if image.width % columns or image.height % rows:
        raise ValueError("source dimensions are not divisible by the requested grid")
    cell_width, cell_height = image.width // columns, image.height // rows
    return [
        image.crop(
            (
                (index % columns) * cell_width,
                (index // columns) * cell_height,
                (index % columns + 1) * cell_width,
                (index // columns + 1) * cell_height,
            )
        ).convert("RGBA")
        for index in range(frame_count)
    ]


def analyze_frame(
    frame: Image.Image, *, frame_number: int, alpha_cutoff: int = 16
) -> FrameSourceAnalysis:
    alpha = frame.convert("RGBA").getchannel("A")
    binary = alpha.point(lambda value: 255 if value >= alpha_cutoff else 0)
    bbox = binary.getbbox()
    if bbox is None:
        return FrameSourceAnalysis(
            frame_number, None, 0, 0, None, None, None, None,
            False, False, False, False, 0,
        )
    left, top, right, bottom = bbox
    pixels = binary.load()
    occupied = [
        (x, y)
        for y in range(frame.height)
        for x in range(frame.width)
        if pixels[x, y]
    ]
    count = len(occupied)
    return FrameSourceAnalysis(
        frame=frame_number,
        alpha_bbox=[left, top, right, bottom],
        occupied_width=right - left,
        occupied_height=bottom - top,
        bottom_y=bottom - 1,
        top_y=top,
        centroid_x=sum(x for x, _y in occupied) / count,
        centroid_y=sum(y for _x, y in occupied) / count,
        touches_left=left == 0,
        touches_right=right == frame.width,
        touches_top=top == 0,
        touches_bottom=bottom == frame.height,
        opaque_pixels=count,
    )


def union_bbox(analyses: list[FrameSourceAnalysis]) -> list[int]:
    valid = [item.alpha_bbox for item in analyses if item.alpha_bbox is not None]
    if not valid:
        raise ValueError("source animation contains no visible pixels")
    return [
        min(box[0] for box in valid),
        min(box[1] for box in valid),
        max(box[2] for box in valid),
        max(box[3] for box in valid),
    ]
