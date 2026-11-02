"""Objective pixel, contact, palette, loop and candidate QA."""
from __future__ import annotations

from collections import Counter
from typing import Any

from PIL import Image, ImageChops


def alpha_metrics(image: Image.Image) -> dict[str, Any]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return {"alpha_bbox": None, "alpha_centroid": None, "opaque_pixels": 0}
    pixels = [(x, y) for y in range(image.height) for x in range(image.width) if alpha.getpixel((x, y)) > 0]
    return {"alpha_bbox": list(bbox),
            "alpha_centroid": [sum(p[0] for p in pixels) / len(pixels), sum(p[1] for p in pixels) / len(pixels)],
            "opaque_pixels": len(pixels)}


def run_qa(frames: list[Image.Image], rig: dict[str, Any], motion: dict[str, Any], transforms: list[dict[str, Any]], source_images: dict[str, Image.Image]) -> dict[str, Any]:
    hard: list[str] = []
    source_palette = set().union(*(set(im.getdata()) for im in source_images.values()))
    frame_metrics = []
    for index, frame in enumerate(frames):
        colors = set(frame.getdata())
        if not colors <= source_palette | {(0, 0, 0, 0)}:
            hard.append(f"frame {index}: palette expansion")
        bounds = frame.getchannel("A").getbbox()
        if bounds and (bounds[0] < 0 or bounds[1] < 0 or bounds[2] > frame.width or bounds[3] > frame.height):
            hard.append(f"frame {index}: clipping")
        frame_metrics.append(alpha_metrics(frame))
        for part in rig["parts"]:
            offset = transforms[index][part["id"]]
            box = source_images[part["id"]].getchannel("A").getbbox()
            if box:
                x0, y0, x1, y1 = box
                if x0 + offset[0] < 0 or y0 + offset[1] < 0 or x1 + offset[0] > frame.width or y1 + offset[1] > frame.height:
                    hard.append(f"frame {index}: part clipping for {part['id']}")
    for contact in motion["contacts"]:
        part = contact["part"]
        for frame_index in contact["frames"]:
            offset = transforms[frame_index][part]
            pivot = next(p["pivot"] for p in rig["parts"] if p["id"] == part)
            if (pivot[0] + offset[0], pivot[1] + offset[1]) != tuple(contact["point"]):
                hard.append(f"frame {frame_index}: contact residual for {part}")
    if motion["loop"] and transforms and transforms[0] != transforms[-1]:
        hard.append("loop seam transform mismatch")
    return {"frame_metrics": frame_metrics, "palette_rgba": [list(v) for v in sorted(source_palette)],
            "hard_failures": hard, "warnings": [], "publication_authorized": False,
            "status": "failed" if hard else "candidate"}


def images_equal(a: Image.Image, b: Image.Image) -> bool:
    return ImageChops.difference(a, b).getbbox() is None
