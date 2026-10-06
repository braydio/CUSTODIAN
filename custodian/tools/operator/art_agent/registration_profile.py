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
SUPPORTED_SCHEMAS = {"custodian.operator_art_profile.v1", "custodian.operator_art_profile.v2", "custodian.operator_art_profile.v3"}
LEGACY_PROFILE_ID = "legacy_96"
CANONICAL_PROFILE_ID = "operator_2_5d_128"


def _canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def _validate_registration(registration: dict[str, Any]) -> None:
    frame_size = registration.get("frame_size")
    if registration.get("status") != "accepted" or frame_size not in ([96, 96], [128, 128]):
        raise ValueError("Operator registration profile must be accepted 96x96 or 128x128 geometry")
    guide = registration.get("guide", {})
    for group in ("horizontal", "vertical", "points"):
        if not isinstance(guide.get(group), dict):
            raise ValueError(f"registration guide is missing {group}")
    width, height = frame_size
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


def available_profiles(value: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Profile registry view: v1/v2 files expose their single registration as legacy_96."""
    if value.get("schema") == "custodian.operator_art_profile.v3":
        return dict(value.get("profiles", {}))
    return {LEGACY_PROFILE_ID: {"registration": value.get("registration"), "measurements": value.get("measurements", {})}}


def load_profile(path: Path = PROFILE_PATH, profile_id: str | None = None, frame_size: list[int] | tuple[int, int] | None = None) -> dict[str, Any]:
    """Load one explicit profile.

    Selection order: ``profile_id``; else the profile whose frame size matches ``frame_size``;
    else the file's ``active_authoring_profile`` (new authoring); v1/v2 files only have legacy_96.
    ``sha256`` is the identity of the *effective* profile (carried into plans/receipts);
    ``file_sha256`` hashes the whole file.
    """
    raw = path.read_bytes()
    value = json.loads(raw)
    if value.get("schema") not in SUPPORTED_SCHEMAS:
        raise ValueError("unsupported Operator art profile schema")
    file_sha = hashlib.sha256(raw).hexdigest()
    registry = available_profiles(value)
    if profile_id is None and frame_size is not None:
        wanted = list(frame_size)
        for key, block in registry.items():
            reg = block.get("registration")
            if reg and reg.get("frame_size") == wanted:
                profile_id = key
                break
    profile_id = profile_id or value.get("active_authoring_profile") or LEGACY_PROFILE_ID
    if profile_id not in registry:
        raise ValueError(f"unknown Operator art profile: {profile_id}")
    registration = registry[profile_id].get("registration")
    reference = value.get("canonical_visual_reference")
    if value.get("schema") == "custodian.operator_art_profile.v3":
        effective = hashlib.sha256(_canonical_json({"id": profile_id, "profile": registry[profile_id], "reference": reference}).encode()).hexdigest()
    else:
        effective = file_sha  # v1/v2 identity is unchanged so existing plans/receipts keep matching
    result = {"profile": value, "sha256": effective, "file_sha256": file_sha, "profile_id": profile_id,
              "available_profiles": sorted(registry), "active_authoring_profile": value.get("active_authoring_profile", LEGACY_PROFILE_ID),
              "canonical_visual_reference": reference, "registration": registration}
    if registration is not None:
        _validate_registration(registration)
    return result


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
    loaded = profile or load_profile(frame_size=frame_size)
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


def profile_report(*, landmarks: list[dict[str, Any]], frames: list[dict[str, Any]], profile: dict[str, Any] | None = None, global_scale: float | None = None, clipping_safe_scale: float | None = None, plan: Any = None, registered_canvas: bool = False, frame_size: list[int] | None = None) -> dict[str, Any]:
    loaded = profile or load_profile(frame_size=frame_size)
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
        elif registered_canvas and frame_size == reg["frame_size"]:
            for name, point in frame_landmarks.items():
                transformed = [float(point["x"]), float(point["y"])]
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
    scale_observations = getattr(plan, "scale_observations", [])
    if registered_canvas and frame_size == reg["frame_size"]:
        by_frame = {frame: names for frame, names in points.items()}
        for frame_number, names in by_frame.items():
            for segment in reg.get("normalization", {}).get("scale_segments", []):
                a, b = names.get(segment["a"]), names.get(segment["b"])
                if a and b:
                    observed = math.hypot(a["x"] - b["x"], a["y"] - b["y"])
                    scale_observations.append({"frame": frame_number, "segment": f'{segment["a"]}:{segment["b"]}',
                                               "observed_length": observed, "target_length": segment["target_length"],
                                               "ratio": observed / segment["target_length"], "status": "advisory",
                                               "interpretation": "measurement only; no Source Session scale normalization applied"})
    return {
        "schema": "custodian.operator_art_registration_report.v1",
        "profile_sha256": loaded["sha256"], "profile_id": loaded.get("profile_id", LEGACY_PROFILE_ID),
        "target_anchor": reg["anchor"], "guide": reg["guide"],
        "anchor_context": {"coordinate": reg["anchor"], "coordinate_space": "profile_coordinates"},
        "global_scale": global_scale, "clipping_safe_scale": clipping_safe_scale,
        "scale_observations": scale_observations,
        "frame_size": frame_size,
        "coordinate_space": "registered_workbench_canvas" if registered_canvas else "source_cell_pixels",
        "source_session_scale_normalization_applied": bool(plan is not None),
        "residuals_are_advisory": True,
        "frames": result_frames,
    }
