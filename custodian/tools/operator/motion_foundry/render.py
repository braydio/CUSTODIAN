"""Stable whole-canvas integer translation and candidate rendering."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

from PIL import Image

from .motion import interpolate
from .schema import canonical_json, sha256_bytes


def translated(image: Image.Image, offset: tuple[int, int]) -> Image.Image:
    dx, dy = offset
    shifted = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shifted.alpha_composite(image, (dx, dy))
    return shifted


def render_frames(rig: dict[str, Any], motion: dict[str, Any], parts: dict[str, Image.Image]) -> tuple[list[Image.Image], list[dict[str, Any]]]:
    frames, transforms = [], []
    for frame_index in range(motion["frame_count"]):
        canvas = Image.new("RGBA", rig["frame_size"], (0, 0, 0, 0))
        per_part = {}
        for part in rig["parts"]:
            offset = interpolate(motion["tracks"][part["id"]], frame_index) if part["id"] in motion["tracks"] else (0, 0)
            shifted = translated(parts[part["id"]], offset)
            canvas.alpha_composite(shifted)
            per_part[part["id"]] = list(offset)
        frames.append(canvas)
        transforms.append(per_part)
    return frames, transforms


def encode_strip(frames: list[Image.Image]) -> bytes:
    if not frames:
        raise ValueError("cannot encode empty frame list")
    width, height = frames[0].size
    strip = Image.new("RGBA", (width * len(frames), height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * width, 0))
    from io import BytesIO
    out = BytesIO()
    strip.save(out, format="PNG", optimize=False, compress_level=9)
    return out.getvalue()


def content_job_id(rig_sha: str, motion_sha: str, sources: dict[str, str]) -> str:
    return sha256_bytes(canonical_json({"rig": rig_sha, "motion": motion_sha, "sources": sources}))


def create_once(path: Path, data: bytes) -> None:
    """Write once, or accept exact existing bytes; never overwrite a collision."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.read_bytes() != data:
            raise ValueError(f"output collision refuses overwrite: {path}")
        return
    tmp = path.with_name(path.name + f".{os.getpid()}.tmp")
    try:
        with tmp.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            os.link(tmp, path)
        except FileExistsError:
            if path.read_bytes() != data:
                raise ValueError(f"output collision refuses overwrite: {path}")
    finally:
        tmp.unlink(missing_ok=True)


def canonical_document_sha(value: dict[str, Any]) -> str:
    return sha256_bytes(canonical_json(value))
