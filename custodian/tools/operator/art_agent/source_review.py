from __future__ import annotations

from PIL import Image


def normalized_frame_metrics(frame: Image.Image) -> dict:
    alpha = frame.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return {"bbox": None, "baseline_y": None, "center_x": None, "height": 0, "width": 0}
    left, top, right, bottom = bbox
    pixels = alpha.load()
    occupied = [(x, y) for y in range(frame.height) for x in range(frame.width) if pixels[x, y]]
    return {
        "bbox": [left, top, right, bottom],
        "baseline_y": bottom - 1,
        "center_x": sum(x for x, _y in occupied) / len(occupied),
        "height": bottom - top,
        "width": right - left,
    }


def review_normalization(*, frames: list[Image.Image]) -> dict:
    metrics = [normalized_frame_metrics(frame) for frame in frames]
    baselines = [item["baseline_y"] for item in metrics if item["baseline_y"] is not None]
    findings: list[dict] = []
    if not baselines:
        findings.append({"severity": "major", "issue": "normalized animation contains no visible pixels"})
    elif max(baselines) - min(baselines) > 4:
        findings.append({"severity": "review", "issue": "large baseline spread", "range": [min(baselines), max(baselines)]})
    clipped = []
    for index, item in enumerate(metrics):
        bbox = item["bbox"]
        if bbox and (bbox[0] == 0 or bbox[1] == 0 or bbox[2] == frames[index].width or bbox[3] == frames[index].height):
            clipped.append(index + 1)
    if clipped:
        findings.append({"severity": "major", "issue": "normalized silhouette touches frame edge", "frames": clipped})
    return {"status": "NEEDS_REVIEW" if findings else "PASS", "metrics": metrics, "findings": findings}
