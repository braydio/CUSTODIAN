from __future__ import annotations

from typing import Any

CRITICAL = "critical"
MAJOR = "major"
ADVISORY = "advisory"


def _normalize_required(required_landmarks: list[str] | dict[str, list[str]] | None) -> tuple[list[str], list[str]]:
    if not required_landmarks:
        return [], []
    if isinstance(required_landmarks, dict):
        return list(required_landmarks.get("each_frame", [])), list(required_landmarks.get("when_visible", []))
    return list(required_landmarks), []


def _current_by_frame(landmarks: list[dict[str, Any]] | None) -> dict[int, dict[str, dict[str, Any]]]:
    result: dict[int, dict[str, dict[str, Any]]] = {}
    for item in landmarks or []:
        if item.get("status", "CURRENT") != "CURRENT":
            continue
        result.setdefault(item["frame"], {})[item["name"]] = item
    return result


def _finding(severity: str, klass: str, issue: str, **extra: Any) -> dict[str, Any]:
    value = {"severity": severity, "class": klass, "issue": issue}
    value.update({key: item for key, item in extra.items() if item is not None})
    return value


def _landmark_class(name: str) -> str:
    return "weapon" if name.startswith("weapon_") else "anatomy"


def _point(entries: dict[str, dict[str, Any]], name: str) -> tuple[float, float] | None:
    item = entries.get(name)
    if item is None or "x" not in item or "y" not in item:
        return None
    return item["x"], item["y"]


def _median(values: list[float]) -> float:
    ordered = sorted(values)
    mid = len(ordered) // 2
    return ordered[mid] if len(ordered) % 2 else (ordered[mid - 1] + ordered[mid]) / 2


def _structural_findings(
    metrics: dict[str, Any],
    expected_frame_count: int | None,
    masks: list[dict[str, Any]] | None,
) -> list[dict[str, Any]]:
    findings = []
    frame_count = len(metrics.get("frames", []))
    if expected_frame_count is not None and frame_count != expected_frame_count:
        findings.append(_finding(CRITICAL, "structural", "frame count does not match animation contract", expected=expected_frame_count, actual=frame_count))
    for mask in masks or []:
        if not mask.get("spans"):
            findings.append(_finding(CRITICAL, "structural", "invalid mask: no spans", mask_id=mask.get("mask_id")))
    return findings


def _required_landmark_findings(each_frame: list[str], when_visible: list[str], by_frame: dict, frame_count: int) -> list[dict[str, Any]]:
    findings = []
    tracked_anywhere = {name for entries in by_frame.values() for name in entries}
    for frame in range(1, frame_count + 1):
        present = by_frame.get(frame, {})
        for name in each_frame:
            if name not in present:
                findings.append(_finding(MAJOR, _landmark_class(name), "missing required landmark", frame=frame, landmark=name))
        for name in when_visible:
            if name in tracked_anywhere and name not in present:
                findings.append(_finding(MAJOR, _landmark_class(name), "missing required landmark", frame=frame, landmark=name))
    return findings


def _near_far_ordering_findings(by_frame: dict) -> list[dict[str, Any]]:
    findings = []
    for part in ("knee", "ankle", "toe"):
        near_name, far_name = f"{part}_near", f"{part}_far"
        signs: dict[int, bool] = {}
        for frame, entries in by_frame.items():
            near_point, far_point = _point(entries, near_name), _point(entries, far_name)
            if near_point is None or far_point is None:
                continue
            delta = near_point[0] - far_point[0]
            if delta != 0:
                signs[frame] = delta > 0
        if len(signs) < 2:
            continue
        majority = sum(signs.values()) >= len(signs) / 2
        for frame, sign in signs.items():
            if sign != majority:
                findings.append(_finding(ADVISORY, "anatomy", f"{near_name}/{far_name} ordering inconsistent with the rest of the animation", frame=frame))
    return findings


def _limb_length_findings(by_frame: dict) -> list[dict[str, Any]]:
    findings = []
    for start, end, label in (
        ("hip_center", "knee_near", "hip-to-knee"),
        ("knee_near", "toe_near", "knee-to-toe"),
        ("head_center", "hip_center", "head-to-hip"),
    ):
        lengths: dict[int, float] = {}
        for frame, entries in by_frame.items():
            a, b = _point(entries, start), _point(entries, end)
            if a is None or b is None:
                continue
            lengths[frame] = ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5
        if len(lengths) < 2:
            continue
        median = _median(list(lengths.values()))
        if median <= 0:
            continue
        for frame, length in lengths.items():
            if abs(length - median) > 0.4 * median:
                findings.append(_finding(ADVISORY, "anatomy", f"{label} distance drifts from the animation's median", frame=frame, length=length, median=median))
    return findings


def _anatomy_findings(metrics: dict[str, Any], each_frame: list[str], when_visible: list[str], by_frame: dict) -> list[dict[str, Any]]:
    frame_count = len(metrics.get("frames", []))
    findings = _required_landmark_findings(each_frame, when_visible, by_frame, frame_count)
    findings += _near_far_ordering_findings(by_frame)
    findings += _limb_length_findings(by_frame)
    return findings


def _pixel_art_findings(metrics: dict[str, Any]) -> list[dict[str, Any]]:
    findings = []
    frames = metrics.get("frames", [])
    if any(frame["semi_transparent_pixels"] for frame in frames):
        findings.append(_finding(ADVISORY, "pixel_art", "semi-transparent pixels present"))
    isolated_frames = [index + 1 for index, frame in enumerate(frames) if frame.get("single_pixel_components")]
    if isolated_frames:
        findings.append(_finding(ADVISORY, "pixel_art", "isolated single-pixel components present", frames=isolated_frames))
    palette_sizes = [frame.get("palette_size", 0) for frame in frames]
    if len(palette_sizes) >= 2:
        median = _median(palette_sizes)
        spikes = [index + 1 for index, size in enumerate(palette_sizes) if median and size > median * 2]
        if spikes:
            findings.append(_finding(ADVISORY, "pixel_art", "palette size spikes relative to the rest of the animation", frames=spikes))
    return findings


def _one_frame_jump_findings(name: str, points: list[list[float]], klass: str) -> list[dict[str, Any]]:
    findings = []
    if len(points) < 3:
        return findings
    ordered = sorted(points, key=lambda item: item[0])
    deltas = []
    for previous, current in zip(ordered, ordered[1:]):
        dx, dy = current[1] - previous[1], current[2] - previous[2]
        deltas.append((current[0], (dx * dx + dy * dy) ** 0.5))
    median = _median([value for _, value in deltas])
    if median <= 0:
        return findings
    for frame, magnitude in deltas:
        if magnitude > median * 3 and magnitude - median > 2:
            findings.append(_finding(ADVISORY, klass, f"{name} moves unexpectedly between adjacent frames", frame=frame, step=magnitude, median_step=median))
    return findings


def _registration_findings(metrics: dict[str, Any]) -> list[dict[str, Any]]:
    findings = []
    trajectories = metrics.get("trajectories") or {}
    for name in ("hip_center", "head_center"):
        if name in trajectories:
            findings += _one_frame_jump_findings(name, trajectories[name], "registration")
    baseline_points = [
        [index + 1, 0, frame["baseline_y"]]
        for index, frame in enumerate(metrics.get("frames", []))
        if frame.get("baseline_y") is not None
    ]
    findings += _one_frame_jump_findings("baseline_y", baseline_points, "registration")
    return findings


def _animation_findings(metrics: dict[str, Any]) -> list[dict[str, Any]]:
    findings = []
    if metrics.get("duplicate_adjacent_frames"):
        findings.append(_finding(ADVISORY, "animation", "adjacent duplicate frames", details=metrics["duplicate_adjacent_frames"]))
    trajectories = metrics.get("trajectories") or {}
    for name in ("toe_near", "toe_far", "ankle_near", "ankle_far"):
        if name in trajectories:
            findings += _one_frame_jump_findings(name, trajectories[name], "animation")
    for name, seam in (metrics.get("loop_seam_metrics") or {}).items():
        if seam.get("normalized_seam_ratio", 0) > 3:
            findings.append(_finding(ADVISORY, "animation", f"{name} loop seam displacement is large relative to its internal motion", trajectory=name, **seam))
    for label in ("width", "height"):
        series = [frame[label] for frame in metrics.get("frames", []) if frame.get(label)]
        if len(series) < 2:
            continue
        median = _median(series)
        if median and max(series) > median * 1.5:
            findings.append(_finding(ADVISORY, "animation", f"body {label} spikes relative to the animation's median", median=median, max=max(series)))
    return findings


def _weapon_findings(by_frame: dict) -> list[dict[str, Any]]:
    findings = []
    lengths: dict[int, float] = {}
    for frame, entries in by_frame.items():
        grip, tip = _point(entries, "weapon_grip"), _point(entries, "weapon_tip")
        if grip is None or tip is None:
            continue
        lengths[frame] = ((grip[0] - tip[0]) ** 2 + (grip[1] - tip[1]) ** 2) ** 0.5
    if len(lengths) < 2:
        return findings
    median = _median(list(lengths.values()))
    if median <= 0:
        return findings
    for frame, length in lengths.items():
        if abs(length - median) > 0.3 * median:
            findings.append(_finding(ADVISORY, "weapon", "grip-to-tip length drifts from the animation's median", frame=frame, length=length, median=median))
    return findings


def _semantic_findings(
    landmarks: list[dict[str, Any]] | None,
    masks: list[dict[str, Any]] | None,
    drafts: list[dict[str, Any]] | None,
    critiques: list[dict[str, Any]] | None,
) -> list[dict[str, Any]]:
    findings = []
    for item in landmarks or []:
        if item.get("status") == "STALE":
            findings.append(_finding(MAJOR, "semantic", "stale landmark", frame=item.get("frame"), landmark=item.get("name")))
    for mask in masks or []:
        if mask.get("status") == "STALE":
            findings.append(_finding(MAJOR, "semantic", "stale mask", mask_id=mask.get("mask_id")))
    for draft in drafts or []:
        if draft.get("status") == "STALE":
            findings.append(_finding(MAJOR, "semantic", "stale draft", draft_id=draft.get("draft_id")))
        if draft.get("needs_gap_repair"):
            findings.append(_finding(MAJOR, "semantic", "unresolved gap repair", draft_id=draft.get("draft_id")))
        if draft.get("advisory_note"):
            findings.append(_finding(ADVISORY, "semantic", draft["advisory_note"], draft_id=draft.get("draft_id")))
    if any(item.get("severity") in {MAJOR, CRITICAL} for item in critiques or []):
        findings.append(_finding(MAJOR, "semantic", "unresolved major critique"))
    return findings


def run_qa(
    metrics: dict[str, Any],
    *,
    required_landmarks: list[str] | dict[str, list[str]] | None = None,
    landmarks: list[dict[str, Any]] | None = None,
    critiques: list[dict[str, Any]] | None = None,
    masks: list[dict[str, Any]] | None = None,
    drafts: list[dict[str, Any]] | None = None,
    profile: dict[str, Any] | None = None,
    expected_frame_count: int | None = None,
    palette_findings: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    each_frame, when_visible = _normalize_required(required_landmarks)
    by_frame = _current_by_frame(landmarks)

    findings: list[dict[str, Any]] = []
    findings += _structural_findings(metrics, expected_frame_count, masks)
    findings += _registration_findings(metrics)
    findings += _anatomy_findings(metrics, each_frame, when_visible, by_frame)
    findings += _pixel_art_findings(metrics)
    findings += _animation_findings(metrics)
    findings += _weapon_findings(by_frame)
    findings += _semantic_findings(landmarks, masks, drafts, critiques)
    findings += [
        _finding(item.get("severity", ADVISORY), "palette", item["issue"], **{k:v for k,v in item.items() if k not in {"severity","issue","class"}})
        for item in (palette_findings or [])
    ]

    status = (
        "RED" if any(item["severity"] == CRITICAL for item in findings)
        else "NEEDS_HUMAN_REVIEW" if any(item["severity"] == MAJOR for item in findings)
        else "YELLOW" if findings
        else "GREEN"
    )
    return {"schema": "custodian.operator_art_qa.v2", "status": status, "publish_authorized": False, "findings": findings}
