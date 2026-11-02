from __future__ import annotations

from dataclasses import dataclass
from math import hypot
from typing import Sequence

from PIL import Image

from animation_preview import FrameDiffMetrics, compare_frames


@dataclass(frozen=True)
class TransitionBoundaryMetrics:
    alpha_bbox_delta: tuple[int, int, int, int] | None
    visual_centroid_delta: tuple[float, float] | None
    baseline_delta: int | None
    centroid_distance: float | None
    alpha_overlap_pixels: int
    alpha_union_pixels: int
    silhouette_iou: float | None
    changed_pixels: int
    diff_bbox: tuple[int, int, int, int] | None
    review_size: tuple[int, int]


@dataclass(frozen=True)
class TransitionAnalysis:
    frames: tuple[Image.Image, ...]
    target_frames: tuple[int, ...]
    reference_frames: tuple[int, ...]
    target_boundary: Image.Image
    reference_boundary: Image.Image
    diff: Image.Image
    ghost: Image.Image
    diff_metrics: FrameDiffMetrics
    metrics: TransitionBoundaryMetrics

    @property
    def boundary_index(self) -> int:
        return len(self.target_frames) - 1


def _normalize_frame(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    if rgba.size == size:
        return rgba.copy()
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(rgba, ((size[0] - rgba.width) // 2, (size[1] - rgba.height) // 2))
    return canvas


def normalize_transition_frames(target: Sequence[Image.Image], reference: Sequence[Image.Image], *, tail: int = 2, head: int = 2) -> tuple[tuple[Image.Image, ...], tuple[int, ...], tuple[int, ...]]:
    if not target:
        raise ValueError("transition target has no frames")
    if not reference:
        raise ValueError("transition reference has no frames")
    if not 1 <= tail <= min(4, len(target)):
        raise ValueError("transition target tail outside contract")
    if not 1 <= head <= min(4, len(reference)):
        raise ValueError("transition reference head outside contract")
    selected = list(target[-tail:]) + list(reference[:head])
    size = (max(frame.width for frame in selected), max(frame.height for frame in selected))
    return (tuple(_normalize_frame(frame, size) for frame in selected), tuple(range(len(target) - tail + 1, len(target) + 1)), tuple(range(1, head + 1)))


def _frame_geometry(image: Image.Image) -> dict[str, object]:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    occupied = {(x, y) for y in range(rgba.height) for x in range(rgba.width) if rgba.getpixel((x, y))[3] > 0}
    if occupied:
        centroid = (sum(x for x, _ in occupied) / len(occupied), sum(y for _, y in occupied) / len(occupied))
        baseline = max(y for _, y in occupied)
    else:
        centroid = None
        baseline = None
    return {"bbox": bbox, "centroid": centroid, "baseline": baseline, "occupied": occupied}


def _tuple_delta(before, after):
    if before is None or after is None:
        return None
    return tuple(after[index] - before[index] for index in range(len(before)))


def make_transition_ghost(target: Image.Image, reference: Image.Image) -> Image.Image:
    if target.size != reference.size:
        raise ValueError("ghost frames must share one review canvas")
    ghost = Image.new("RGBA", target.size, (0, 0, 0, 0))
    before = target.convert("RGBA").copy()
    after = reference.convert("RGBA").copy()
    before.putalpha(before.getchannel("A").point(lambda value: round(value * 0.40)))
    after.putalpha(after.getchannel("A").point(lambda value: round(value * 0.65)))
    ghost.alpha_composite(before)
    ghost.alpha_composite(after)
    return ghost


def analyze_transition(target: Sequence[Image.Image], reference: Sequence[Image.Image], *, tail: int = 2, head: int = 2) -> TransitionAnalysis:
    frames, target_numbers, reference_numbers = normalize_transition_frames(target, reference, tail=tail, head=head)
    boundary_index = len(target_numbers) - 1
    target_boundary = frames[boundary_index]
    reference_boundary = frames[boundary_index + 1]
    target_geometry = _frame_geometry(target_boundary)
    reference_geometry = _frame_geometry(reference_boundary)
    bbox_delta = _tuple_delta(target_geometry["bbox"], reference_geometry["bbox"])
    centroid_delta = _tuple_delta(target_geometry["centroid"], reference_geometry["centroid"])
    target_baseline = target_geometry["baseline"]
    reference_baseline = reference_geometry["baseline"]
    baseline_delta = None if target_baseline is None or reference_baseline is None else int(reference_baseline - target_baseline)
    centroid_distance = None if centroid_delta is None else hypot(*centroid_delta)
    target_alpha = target_geometry["occupied"]
    reference_alpha = reference_geometry["occupied"]
    intersection = len(target_alpha & reference_alpha)
    union = len(target_alpha | reference_alpha)
    silhouette_iou = None if union == 0 else intersection / union
    diff, diff_metrics = compare_frames(target_boundary, reference_boundary)
    metrics = TransitionBoundaryMetrics(
        alpha_bbox_delta=tuple(int(value) for value in bbox_delta) if bbox_delta is not None else None,
        visual_centroid_delta=tuple(float(value) for value in centroid_delta) if centroid_delta is not None else None,
        baseline_delta=baseline_delta,
        centroid_distance=centroid_distance,
        alpha_overlap_pixels=intersection,
        alpha_union_pixels=union,
        silhouette_iou=silhouette_iou,
        changed_pixels=diff_metrics.changed_pixels,
        diff_bbox=diff_metrics.bbox,
        review_size=target_boundary.size,
    )
    return TransitionAnalysis(frames, target_numbers, reference_numbers, target_boundary, reference_boundary, diff, make_transition_ghost(target_boundary, reference_boundary), diff_metrics, metrics)


def legacy_handoff_metrics(metrics: TransitionBoundaryMetrics) -> dict[str, object]:
    return {"alpha_bbox_delta": list(metrics.alpha_bbox_delta) if metrics.alpha_bbox_delta is not None else None, "visual_centroid_delta": list(metrics.visual_centroid_delta) if metrics.visual_centroid_delta is not None else None, "baseline_delta": metrics.baseline_delta}
