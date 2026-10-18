#!/usr/bin/env python3
"""Build authentic, compact pixel comparisons for the five-pose skin POC."""
from __future__ import annotations

import base64
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .pose_map import POSES
from .skin_renderer import DRAW_ORDER

SCALE = 2
OWNER_COLORS = {
    1: (130, 170, 255, 105),  # unchanged upper-body residual
    2: (255, 80, 60, 150), 3: (255, 120, 70, 150), 4: (255, 170, 70, 150),
    5: (220, 80, 250, 150), 6: (235, 90, 230, 150), 7: (255, 60, 190, 150),
    8: (255, 210, 60, 150), 9: (255, 225, 80, 150), 10: (245, 235, 120, 150),
}


def _font():
    try:
        return ImageFont.truetype("DejaVuSans.ttf", 10)
    except OSError:
        return ImageFont.load_default()


def _rgba(array: np.ndarray) -> Image.Image:
    return Image.fromarray(np.asarray(array, dtype=np.uint8), "RGBA")


def _knight_landmark_overlay(frame: np.ndarray, mapped: dict) -> Image.Image:
    image = _rgba(frame)
    draw = ImageDraw.Draw(image, "RGBA")
    for side, color in (("near", (255, 64, 64, 255)), ("far", (64, 220, 255, 255))):
        names = ("hip", "knee", "ankle", "toe")
        coords = [tuple(map(float, mapped["donor"][side][k])) for k in names]
        draw.line(coords, fill=color, width=1)
        for x, y in coords:
            draw.ellipse((x-1.4, y-1.4, x+1.4, y+1.4), fill=color)
    px, py = mapped["knight_pelvis"]
    draw.ellipse((px-2, py-2, px+2, py+2), fill=(255, 255, 60, 255))
    return image


def _owner_overlay(candidate: np.ndarray, owner: np.ndarray) -> Image.Image:
    image = _rgba(candidate)
    overlay = np.zeros_like(candidate)
    for code, color in OWNER_COLORS.items():
        overlay[owner == code] = color
    return Image.alpha_composite(image, _rgba(overlay))


def comparison_sheet(donor_frames: list[np.ndarray], mapped: dict[int, dict],
                     candidates: dict[int, np.ndarray], owners: dict[int, np.ndarray],
                     baselines: dict[int, np.ndarray]) -> Image.Image:
    font = _font()
    cell_w, cell_h, label_h = 128 * SCALE, 128 * SCALE, 22
    out = Image.new("RGBA", (4 * cell_w, len(POSES) * (cell_h + label_h)), (24, 25, 31, 255))
    draw = ImageDraw.Draw(out)
    labels = ("Knight NE + traced joints", "Semantic owner overlay", "Knight-driven Custodian", "Iteration 004 baseline")
    for row, frame_num in enumerate(POSES):
        top = row * (cell_h + label_h) + label_h
        for col, label in enumerate(labels):
            draw.text((col * cell_w + 3, row * (cell_h + label_h) + 4),
                      f"F{frame_num:02d} · {label}", fill=(245, 245, 245, 255), font=font)
        pieces = (
            _knight_landmark_overlay(donor_frames[frame_num - 1], mapped[frame_num]),
            _owner_overlay(candidates[frame_num], owners[frame_num]),
            _rgba(candidates[frame_num]), _rgba(baselines[frame_num]))
        for col, piece in enumerate(pieces):
            out.alpha_composite(piece.resize((cell_w, cell_h), Image.Resampling.NEAREST),
                                (col * cell_w, top))
    return out


def closeup_sheet(candidates: dict[int, np.ndarray], owners: dict[int, np.ndarray]) -> Image.Image:
    font = _font()
    # Distal/lower-body crop is native-resolution and nearest-neighbor enlarged.
    crop_box = (40, 68, 101, 113)
    crop_w, crop_h = (crop_box[2] - crop_box[0]) * 4, (crop_box[3] - crop_box[1]) * 4
    cell_h = crop_h + 21
    out = Image.new("RGBA", (3 * crop_w, 3 * cell_h + 2 * (176 * 3 + 22)), (28, 28, 34, 255))
    draw = ImageDraw.Draw(out)
    near_id, far_id = DRAW_ORDER.index("foot_near_visible") + 2, DRAW_ORDER.index("foot_far_visible") + 2
    # F05/F07/F12: show actual pixels, with semantic near/far identity overlay.
    for row, frame_num in enumerate((5, 7, 12)):
        image = _rgba(candidates[frame_num])
        mask = owners[frame_num]
        overlay = np.zeros_like(candidates[frame_num])
        overlay[mask == near_id] = (255, 65, 65, 110)
        overlay[mask == far_id] = (60, 215, 255, 110)
        panel = Image.alpha_composite(image, _rgba(overlay)).crop(crop_box)
        top = row * cell_h
        draw.text((4, top + 2), f"F{frame_num:02d} · red near / cyan far · 4×", fill="white", font=font)
        out.alpha_composite(panel.resize((crop_w, crop_h), Image.Resampling.NEAREST), (0, top + 20))
    # F15/F01 full silhouettes at 3x keep the seam comparison legible.
    sil_box = (39, 18, 97, 111)
    sil_w, sil_h = (sil_box[2] - sil_box[0]) * 3, (sil_box[3] - sil_box[1]) * 3
    base_y = 3 * cell_h
    for col, frame_num in enumerate((15, 1)):
        panel = _rgba(candidates[frame_num]).crop(sil_box)
        left = col * sil_w
        draw.text((left + 3, base_y + 3), f"F{frame_num:02d} silhouette · 3×", fill="white", font=font)
        out.alpha_composite(panel.resize((sil_w, sil_h), Image.Resampling.NEAREST), (left, base_y + 20))
    return out.crop((0, 0, 3 * crop_w, base_y + 20 + sil_h))


def write_review_pixels(path: Path, images: dict[str, Image.Image]) -> dict:
    data = {}
    for name, image in images.items():
        buf = io.BytesIO()
        image.save(buf, format="PNG", optimize=False)
        payload = buf.getvalue()
        data[name] = {"mime_type": "image/png", "width": image.width, "height": image.height,
                      "sha256": hashlib.sha256(payload).hexdigest(),
                      "base64": base64.b64encode(payload).decode("ascii")}
    path.write_text(json.dumps({"schema": "operator_ne_knight_skin_review_pixels_v1",
                                "images": data}, indent=2) + "\n", encoding="utf-8")
    return {name: {k: v for k, v in item.items() if k != "base64"} for name, item in data.items()}


def save_png(path: Path, image: Image.Image) -> dict:
    image.save(path, format="PNG", optimize=False)
    payload = path.read_bytes()
    return {"path": path.name, "width": image.width, "height": image.height,
            "sha256": hashlib.sha256(payload).hexdigest(), "bytes": len(payload)}
