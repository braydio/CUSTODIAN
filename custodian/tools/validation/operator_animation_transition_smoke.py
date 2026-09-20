#!/usr/bin/env python3
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from animation_transition import analyze_transition, legacy_handoff_metrics


def sprite(size=(96, 96), *, box=(40, 30, 56, 70), color=(255, 255, 255, 255)):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            image.putpixel((x, y), color)
    return image


base = sprite()
target = [base.copy(), base.copy(), base.copy()]
reference = [base.copy(), base.copy(), base.copy()]
target_bytes = tuple(image.tobytes() for image in target)
reference_bytes = tuple(image.tobytes() for image in reference)
analysis = analyze_transition(target, reference, tail=2, head=2)
assert analysis.target_frames == (2, 3)
assert analysis.reference_frames == (1, 2)
assert len(analysis.frames) == 4
assert analysis.metrics.visual_centroid_delta == (0.0, 0.0)
assert analysis.metrics.baseline_delta == 0
assert analysis.metrics.centroid_distance == 0.0
assert analysis.metrics.silhouette_iou == 1.0
assert analysis.metrics.changed_pixels == 0
assert analysis.metrics.diff_bbox is None
assert legacy_handoff_metrics(analysis.metrics) == {"alpha_bbox_delta": [0, 0, 0, 0], "visual_centroid_delta": [0.0, 0.0], "baseline_delta": 0}

shifted = sprite(box=(41, 30, 57, 70))
analysis = analyze_transition(target, [shifted, shifted.copy()], tail=1, head=1)
dx, dy = analysis.metrics.visual_centroid_delta
assert dx == 1.0 and dy == 0.0
assert analysis.metrics.centroid_distance == 1.0
assert 0.0 < analysis.metrics.silhouette_iou < 1.0
assert analysis.metrics.changed_pixels > 0

lower = sprite(box=(40, 32, 56, 72))
analysis = analyze_transition(target, [lower], tail=1, head=1)
assert analysis.metrics.baseline_delta == 2

wide = sprite(size=(128, 96), box=(56, 30, 72, 70))
analysis = analyze_transition([base], [wide], tail=1, head=1)
assert analysis.metrics.review_size == (128, 96)
assert analysis.metrics.visual_centroid_delta == (0.0, 0.0)
assert analysis.ghost.size == (128, 96)
assert analysis.diff.size == (128, 96)
assert tuple(image.tobytes() for image in target) == target_bytes
assert tuple(image.tobytes() for image in reference) == reference_bytes

for kwargs in ({"tail": 0}, {"tail": 4}, {"head": 0}, {"head": 4}):
    try:
        analyze_transition(target, reference, **kwargs)
    except ValueError:
        pass
    else:
        raise AssertionError("invalid transition window accepted")

print("operator_animation_transition_smoke ok")
