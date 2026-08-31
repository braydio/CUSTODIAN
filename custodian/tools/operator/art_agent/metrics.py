from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any

from PIL import Image

TRAJECTORY_NAMES = (
    "head_center", "hip_center", "knee_near", "knee_far", "ankle_near", "ankle_far",
    "toe_near", "toe_far", "weapon_grip", "weapon_tip", "cloak_tip_near", "cloak_tip_far",
)


def _occupied(image: Image.Image) -> list[tuple[int, int, tuple[int, int, int, int]]]:
    pixels = list(image.getdata())
    return [(index % image.width, index // image.width, pixel) for index, pixel in enumerate(pixels) if pixel[3]]


def _isolated_pixels(occupied: list[tuple[int, int, tuple[int, int, int, int]]]) -> list[list[int]]:
    points = {(x, y) for x, y, _ in occupied}
    isolated = [
        [x, y] for x, y in points
        if not any((x + dx, y + dy) in points for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)))
    ]
    isolated.sort()
    return isolated


def frame_metrics(path: Path) -> dict[str, Any]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        occupied = _occupied(image)
        opaque = sum(pixel[3] == 255 for _, _, pixel in occupied)
        semi = sum(0 < pixel[3] < 255 for _, _, pixel in occupied)
        centroid = (
            [sum(x for x, _, _ in occupied) / len(occupied), sum(y for _, y, _ in occupied) / len(occupied)]
            if occupied else None
        )
        width = 0 if not bbox else bbox[2] - bbox[0]
        height = 0 if not bbox else bbox[3] - bbox[1]
        lowest_y = max((y for _, y, _ in occupied), default=None)
        isolated = _isolated_pixels(occupied)
        return {
            "size": [image.width, image.height],
            "alpha_bbox": list(bbox) if bbox else None,
            "opaque_pixels": opaque,
            "semi_transparent_pixels": semi,
            "visual_centroid": centroid,
            "lowest_occupied_y": lowest_y,
            "highest_occupied_y": min((y for _, y, _ in occupied), default=None),
            "width": width,
            "height": height,
            "palette_size": len({pixel for _, _, pixel in occupied}),
            "pixel_sha": hashlib.sha256(image.tobytes()).hexdigest(),
            "baseline_y": lowest_y,
            "alpha_area": width * height,
            "isolated_opaque_pixels": isolated,
            "single_pixel_components": len(isolated),
        }


def _loop_seam_metrics(points: list[list[int]]) -> dict[str, Any] | None:
    if len(points) < 3:
        return None
    ordered = sorted(points, key=lambda item: item[0])
    steps = [
        ((current[1] - previous[1]) ** 2 + (current[2] - previous[2]) ** 2) ** 0.5
        for previous, current in zip(ordered, ordered[1:])
    ]
    seam = ((ordered[0][1] - ordered[-1][1]) ** 2 + (ordered[0][2] - ordered[-1][2]) ** 2) ** 0.5
    sorted_steps = sorted(steps)
    mid = len(sorted_steps) // 2
    median_step = sorted_steps[mid] if len(sorted_steps) % 2 else (sorted_steps[mid - 1] + sorted_steps[mid]) / 2
    return {
        "loop_seam_displacement": seam,
        "median_internal_step": median_step,
        "max_internal_step": max(steps),
        "normalized_seam_ratio": seam / max(median_step, 1.0),
    }


def _mask_summary(mask: dict[str, Any]) -> dict[str, Any] | None:
    spans = mask.get("spans") or []
    if not spans:
        return None
    xs = [x for span in spans for x in (span["x0"], span["x1"])]
    ys = [span["y"] for span in spans]
    span_pixel_count = sum(span["x1"] - span["x0"] + 1 for span in spans)
    return {
        "mask_id": mask.get("mask_id"),
        "part": mask.get("part"),
        "frame": mask.get("frame"),
        "layer": mask.get("layer"),
        "bbox": mask.get("bounds"),
        "centroid": [sum(xs) / len(xs), sum(ys) / len(ys)],
        "span_pixel_count": span_pixel_count,
    }


def animation_metrics(
    paths: list[Path],
    landmarks: list[dict[str, Any]] | None = None,
    *,
    masks: list[dict[str, Any]] | None = None,
    layer_frame_paths: dict[str, list[Path]] | None = None,
) -> dict[str, Any]:
    frames = [frame_metrics(path) for path in paths]
    hashes = [item["pixel_sha"] for item in frames]
    duplicate = [i + 1 for i in range(1, len(hashes)) if hashes[i] == hashes[i - 1]]

    trajectories: dict[str, list[list[int]]] = {}
    for point in landmarks or []:
        trajectories.setdefault(point["name"], []).append([point["frame"], point["x"], point["y"]])
    for points in trajectories.values():
        points.sort(key=lambda item: item[0])

    for index, frame in enumerate(frames, 1):
        frame["landmarks"] = {
            name: [item[1], item[2]]
            for name, points in trajectories.items()
            for item in points
            if item[0] == index
        }

    loop_seam_metrics = {}
    for name in TRAJECTORY_NAMES:
        points = trajectories.get(name)
        if not points:
            continue
        seam = _loop_seam_metrics(points)
        if seam is not None:
            loop_seam_metrics[name] = seam

    layer_shas = {
        layer: [frame_metrics(path)["pixel_sha"] for path in layer_paths]
        for layer, layer_paths in (layer_frame_paths or {}).items()
    }

    mask_summaries = [item for item in (_mask_summary(mask) for mask in masks or []) if item is not None]

    return {
        "schema": "custodian.operator_art_metrics.v2",
        "frames": frames,
        "duplicate_adjacent_frames": duplicate,
        "trajectories": trajectories,
        "loop_seam_metrics": loop_seam_metrics,
        "layer_shas": layer_shas,
        "masks": mask_summaries,
    }
