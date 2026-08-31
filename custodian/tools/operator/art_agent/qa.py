from __future__ import annotations

from typing import Any


def _normalize_required(required_landmarks: list[str] | dict[str, list[str]] | None) -> tuple[list[str], list[str]]:
    if not required_landmarks:
        return [], []
    if isinstance(required_landmarks, dict):
        return list(required_landmarks.get("each_frame", [])), list(required_landmarks.get("when_visible", []))
    return list(required_landmarks), []


def _current_by_frame(landmarks: list[dict[str, Any]] | None) -> dict[int, set[str]]:
    result: dict[int, set[str]] = {}
    for item in landmarks or []:
        if item.get("status", "CURRENT") != "CURRENT":
            continue
        result.setdefault(item["frame"], set()).add(item["name"])
    return result


def run_qa(
    metrics: dict[str, Any],
    *,
    required_landmarks: list[str] | dict[str, list[str]] | None = None,
    landmarks: list[dict[str, Any]] | None = None,
    critiques: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    findings: list[dict[str, Any]] = []
    frame_count = len(metrics.get("frames", []))
    each_frame, when_visible = _normalize_required(required_landmarks)
    by_frame = _current_by_frame(landmarks)
    tracked_anywhere = {name for names in by_frame.values() for name in names}
    for frame in range(1, frame_count + 1):
        present = by_frame.get(frame, set())
        for name in each_frame:
            if name not in present:
                findings.append({"severity": "major", "class": "anatomy", "issue": "missing required landmark", "frame": frame, "landmark": name})
        for name in when_visible:
            if name in tracked_anywhere and name not in present:
                findings.append({"severity": "major", "class": "anatomy", "issue": "missing required landmark", "frame": frame, "landmark": name})
    if any(frame["semi_transparent_pixels"] for frame in metrics.get("frames", [])):
        findings.append({"severity": "advisory", "class": "pixel_art", "issue": "semi-transparent pixels present"})
    if metrics.get("duplicate_adjacent_frames"):
        findings.append({"severity": "advisory", "class": "animation", "issue": "adjacent duplicate frames", "details": metrics["duplicate_adjacent_frames"]})
    if any(item.get("severity") in {"major", "critical"} for item in critiques or []):
        findings.append({"severity": "major", "class": "review", "issue": "unresolved major critique"})
    status = (
        "RED" if any(item["severity"] == "critical" for item in findings)
        else "NEEDS_HUMAN_REVIEW" if any(item["severity"] == "major" for item in findings)
        else "YELLOW" if findings
        else "GREEN"
    )
    return {"schema": "custodian.operator_art_qa.v1", "status": status, "publish_authorized": False, "findings": findings}
