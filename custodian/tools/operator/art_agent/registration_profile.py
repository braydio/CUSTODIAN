from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from statistics import median
from typing import Any

from PIL import Image, ImageDraw

import animation_workbench_model as model
from . import landmarks

PROFILE_PATH = model.CUSTODIAN_ROOT / "content/data/operator/authoring/operator_art_profile.json"
SUPPORTED_SCHEMAS = {"custodian.operator_art_profile.v1", "custodian.operator_art_profile.v2"}


def load_profile(path: Path = PROFILE_PATH) -> dict[str, Any]:
    raw = path.read_bytes()
    value = json.loads(raw)
    if value.get("schema") not in SUPPORTED_SCHEMAS:
        raise ValueError("unsupported Operator art profile schema")
    registration = value.get("registration")
    if registration is None:
        return {"profile": value, "sha256": hashlib.sha256(raw).hexdigest(), "registration": None}
    if registration.get("status") != "accepted" or registration.get("frame_size") != [96, 96]:
        raise ValueError("Operator registration profile must be accepted 96x96 geometry")
    guide = registration.get("guide", {})
    for group in ("horizontal", "vertical", "points"):
        if not isinstance(guide.get(group), dict):
            raise ValueError(f"registration guide is missing {group}")
    width, height = registration["frame_size"]
    for key, point in guide["points"].items():
        if not isinstance(point, list) or len(point) != 2 or not all(isinstance(v, int) for v in point):
            raise ValueError(f"invalid registration guide point: {key}")
        if not 0 <= point[0] < width or not 0 <= point[1] < height:
            raise ValueError(f"registration guide point is out of range: {key}")
    anchor = registration.get("anchor")
    if not isinstance(anchor, list) or len(anchor) != 2 or not all(isinstance(v, int) for v in anchor):
        raise ValueError("invalid registration anchor")
    if not 0 <= anchor[0] < width or not 0 <= anchor[1] < height:
        raise ValueError("registration anchor is out of range")
    for key, y in guide["horizontal"].items():
        if not isinstance(y, int) or not 0 <= y < height:
            raise ValueError(f"registration horizontal rail is out of range: {key}")
    for key, x in guide["vertical"].items():
        if not isinstance(x, int) or not 0 <= x < width:
            raise ValueError(f"registration vertical rail is out of range: {key}")
    if registration.get("ground_y") != guide["horizontal"].get("ground"):
        raise ValueError("registration ground does not match the profile guide")
    norm = registration.get("normalization", {})
    if not 0 < norm.get("source_landmark_min_confidence", 0) <= 1:
        raise ValueError("invalid minimum landmark confidence")
    if norm.get("auto_frame_translation") is not False or not 0 <= norm.get("frame_translation_limit", -1) <= 12:
        raise ValueError("invalid profile frame-translation policy")
    for segment in norm.get("scale_segments", []):
        if segment.get("a") not in landmarks.LANDMARK_NAMES or segment.get("b") not in landmarks.LANDMARK_NAMES:
            raise ValueError("scale segment references unknown semantic landmark")
        if segment.get("target_length", 0) <= 0 or segment.get("weight", 0) <= 0:
            raise ValueError("scale segment lengths and weights must be positive")
    return {"profile": value, "sha256": hashlib.sha256(raw).hexdigest(), "registration": registration}


def weighted_median(observations: list[dict[str, Any]]) -> float:
    observations = [item for item in observations if item.get("accepted", True)]
    if not observations:
        raise ValueError("PROFILE_LANDMARKS_INSUFFICIENT")
    ordered = sorted(observations, key=lambda item: (item["ratio"], item["frame"], item["segment"]))
    total = sum(item["weight"] for item in ordered)
    halfway, running = total / 2, 0.0
    for item in ordered:
        running += item["weight"]
        if running >= halfway:
            return float(item["ratio"])
    return float(ordered[-1]["ratio"])


def render_overlay(*, output: Path, frame_size: tuple[int, int] = (96, 96), profile: dict[str, Any] | None = None, landmarks: list[dict[str, Any]] | None = None) -> str:
    loaded = profile or load_profile()
    registration = loaded.get("registration")
    if registration is None:
        raise ValueError("profile has no accepted registration geometry")
    width, height = frame_size
    if [width, height] != registration["frame_size"]:
        raise ValueError("registration overlay frame size must match profile")
    image = Image.new("RGBA", frame_size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    guide = registration["guide"]
    for y in guide["horizontal"].values():
        for x in range(0, width, 8):
            draw.line((x, y, min(x + 3, width - 1), y), fill=(72, 235, 190, 170))
    for x in guide["vertical"].values():
        for y in range(0, height, 8):
            draw.line((x, y, x, min(y + 3, height - 1)), fill=(80, 190, 255, 170))
    for x, y in guide["points"].values():
        draw.line((x - 2, y, x + 2, y), fill=(255, 225, 95, 230))
        draw.line((x, y - 2, x, y + 2), fill=(255, 225, 95, 230))
    for point in landmarks or []:
        if point.get("status", "CURRENT") != "CURRENT":
            continue
        actual = (int(point["x"]), int(point["y"]))
        target = guide["points"].get(point["name"])
        if target:
            draw.line((actual[0], actual[1], target[0], target[1]), fill=(255, 90, 100, 220), width=1)
        draw.ellipse((actual[0] - 2, actual[1] - 2, actual[0] + 2, actual[1] + 2), outline=(255, 90, 100, 255))
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    return str(output.resolve())


def profile_report(*, landmarks: list[dict[str, Any]], frames: list[dict[str, Any]], profile: dict[str, Any] | None = None, global_scale: float | None = None, clipping_safe_scale: float | None = None, plan: Any = None) -> dict[str, Any]:
    loaded = profile or load_profile()
    reg = loaded.get("registration")
    if reg is None:
        raise ValueError("profile has no accepted registration geometry")
    points = {item["frame"]: {} for item in landmarks}
    for item in landmarks:
        if item.get("status", "CURRENT") == "CURRENT":
            points.setdefault(item["frame"], {})[item["name"]] = item
    result_frames = []
    for index, frame in enumerate(frames, 1):
        frame_landmarks = points.get(index, {})
        projected, residuals = {}, {}
        if plan is not None:
            union = plan.shared_union_bbox
            prepared_per_target = plan.prepared_width / plan.target_width
            for name, point in frame_landmarks.items():
                transformed = [((point["x"] - union[0]) * plan.global_scale + plan.destination_x) / prepared_per_target,
                               ((point["y"] - union[1]) * plan.global_scale + plan.destination_y) / prepared_per_target]
                projected[name] = transformed
                target = reg["guide"]["points"].get(name)
                if target is not None:
                    residuals[name] = [transformed[0] - target[0], transformed[1] - target[1]]
        result_frames.append({
            "frame": index, "alpha_bbox": frame.get("alpha_bbox"),
            "baseline_y": frame.get("bottom_y", frame.get("baseline_y")),
            "landmarks": {name: {"x": point["x"], "y": point["y"], "confidence": point["confidence"]} for name, point in frame_landmarks.items()},
            "transformed_landmarks": projected, "advisory_residuals": residuals,
        })
    return {
        "schema": "custodian.operator_art_registration_report.v1",
        "profile_sha256": loaded["sha256"],
        "target_anchor": reg["anchor"], "guide": reg["guide"],
        "global_scale": global_scale, "clipping_safe_scale": clipping_safe_scale,
        "scale_observations": getattr(plan, "scale_observations", []),
        "frames": result_frames,
    }
