"""Explicit Workbench-owned timing decisions for 2.5D animation leaves.

The record is evidence of a deliberate UI decision, not a general-purpose
approval flag. Current review re-derives its identity and all bound inputs.
"""
from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path
from datetime import datetime
from typing import Any

GENERATION = "operator_2_5d_128"
SCHEMA = "custodian.operator_2_5d_timing_decision.v1"


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(Path(path).read_bytes())


def atomic_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def decision_path(receipt_root: Path, selection: Any) -> Path:
    identity = (selection.profile, selection.group, selection.action, selection.direction)
    if any(not isinstance(part, str) or not part or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for c in part)
           for part in identity):
        raise ValueError("unsafe 2.5D timing decision identity")
    return Path(receipt_root) / selection.profile / selection.group / selection.action / f"{selection.direction}.timing.json"


def parameter_digest(*, fps: float, loop: bool, durations: list[float]) -> str:
    return sha256_bytes(canonical_json({"fps": fps, "loop": loop, "durations": durations}))


def validate_parameters(*, fps: float, loop: bool, durations: list[float], physical: dict[str, Any]) -> dict[str, Any]:
    fps = float(fps)
    durations = [float(value) for value in durations]
    frame_count = int(physical["frames"])
    physical_durations = [float(value) for value in physical["durations"]]
    if not math.isfinite(fps) or fps <= 0 or fps > 120:
        raise ValueError("FPS must be a finite positive value no greater than 120")
    if not isinstance(loop, bool):
        raise ValueError("loop must be explicitly selected")
    if len(durations) != frame_count or len(physical_durations) != frame_count:
        raise ValueError("one explicit duration multiplier is required for each saved frame")
    if any(not math.isfinite(value) or value <= 0 or value > 100 for value in durations):
        raise ValueError("duration multipliers must be finite positive values no greater than 100")
    expected_ms = [value / fps * 1000.0 for value in durations]
    physical_ms = [value * 1000.0 for value in physical_durations]
    if any(abs(expected - actual) > 0.001 for expected, actual in zip(expected_ms, physical_ms)):
        raise ValueError("approved FPS and multipliers must match the saved Aseprite frame durations")
    return {"fps": fps, "loop": loop, "durations": durations,
            "frame_durations_ms": physical_ms}


def current_decision(*, path: Path, selection: Any, manifest_path: Path,
                     document_path: Path, physical: dict[str, Any], plan_path: Path,
                     profile_sha256: str, reference_sha256: str) -> dict[str, Any] | None:
    """Return a decision only when every bound input still matches."""
    try:
        record = json.loads(Path(path).read_text(encoding="utf-8"))
        digest = record.pop("record_sha256", "")
        if record.get("schema") != SCHEMA or not digest or digest != sha256_bytes(canonical_json(record)):
            return None
        timeline = json.loads(Path(manifest_path).read_text(encoding="utf-8")).get("timeline", {})
        if (int(physical.get("width", 0)) != 128 or int(physical.get("height", 0)) != 128
                or int(physical.get("frames", 0)) < 1
                or int(timeline.get("workspace_clock_frames", -1)) != int(physical["frames"])
                or int(timeline.get("document_frames", -1)) != int(physical["frames"])
                or timeline.get("clock_owner") != "full_body"):
            return None
        approved = validate_parameters(fps=record["parameters"]["fps"], loop=record["parameters"]["loop"],
                                       durations=record["parameters"]["durations"], physical=physical)
        if (record.get("authoring_identity") != selection.authoring_identity
                or record.get("action") != "workbench_explicit_timing_confirmation"
                or record.get("provenance", {}).get("kind") != "workbench_explicit_user"
                or record.get("provenance", {}).get("control") != "timing-preview-confirm"
                or set(record.get("parameters", {})) != {"fps", "loop", "durations"}):
            return None
        try:
            datetime.fromisoformat(str(record["provenance"]["confirmed_utc"]))
        except (KeyError, ValueError, TypeError):
            return None
        expected_bindings = {
            "manifest_sha256": sha256_file(manifest_path),
            "document_sha256": sha256_file(document_path),
            "plan_sha256": sha256_file(plan_path),
            "profile_sha256": profile_sha256,
            "reference_sha256": reference_sha256,
            "physical": {"frames": int(physical["frames"]), "width": int(physical["width"]),
                         "height": int(physical["height"]), "durations": [float(v) for v in physical["durations"]]},
        }
        if record.get("bindings") != expected_bindings:
            return None
        if record.get("parameter_sha256") != parameter_digest(**{
                "fps": approved["fps"], "loop": approved["loop"], "durations": approved["durations"]}):
            return None
        if (timeline.get("timing_authority") is not True or timeline.get("fps") != approved["fps"]
                or timeline.get("loop") is not approved["loop"]
                or timeline.get("durations") != approved["durations"]
                or timeline.get("frame_durations_ms") != approved["frame_durations_ms"]):
            return None
        record["record_sha256"] = digest
        return record
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
        return None
