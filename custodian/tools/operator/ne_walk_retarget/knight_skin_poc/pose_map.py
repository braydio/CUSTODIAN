#!/usr/bin/env python3
"""Numerically map the approved Knight NE traces onto the accepted Operator rig."""
from __future__ import annotations

import hashlib
import math
from pathlib import Path

import numpy as np

ANNOTATIONS_SHA = "a96b58383aaf38f3215c929e4411eb45e10e0e73bf031a93e25d31e2ce751f58"
DONOR_SHA = "20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba"
POSES = (1, 5, 7, 12, 15)
SIDES = ("near", "far")
LANDMARKS = ("pelvis", "hip_near", "knee_near", "ankle_near", "toe_near",
             "hip_far", "knee_far", "ankle_far", "toe_far")
NEUTRAL = {
    "near": {"hip": (63.0, 75.0), "knee": (65.0, 89.0),
             "ankle": (66.0, 100.0), "toe": (75.0, 104.0)},
    "far": {"hip": (53.0, 75.0), "knee": (52.0, 83.0),
            "ankle": (50.0, 88.0), "toe": (48.0, 91.0)},
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _point(value, label: str) -> np.ndarray:
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        raise ValueError(f"{label}: expected two-coordinate point")
    point = np.asarray(value, dtype=float)
    if not np.isfinite(point).all():
        raise ValueError(f"{label}: non-finite point")
    return point


def validate_annotations(data: dict, expected_sha: str | None = ANNOTATIONS_SHA) -> list[dict]:
    """Validate all 15 frames and stable anatomical identities before mapping."""
    if expected_sha is not None:
        encoded = data.get("_source_bytes")
        if encoded is not None and hashlib.sha256(encoded).hexdigest() != expected_sha:
            raise ValueError("annotation source SHA256 mismatch")
    frames = data.get("frames")
    if not isinstance(frames, list) or len(frames) != 15:
        raise ValueError("accepted donor must contain exactly 15 annotation frames")
    for index, frame in enumerate(frames, 1):
        if frame.get("frame") != index or frame.get("support") not in SIDES:
            raise ValueError(f"F{index:02d}: frame order or support identity invalid")
        marks = frame.get("landmarks")
        if not isinstance(marks, dict):
            raise ValueError(f"F{index:02d}: missing landmark mapping")
        for name in LANDMARKS:
            item = marks.get(name)
            if not isinstance(item, dict) or item.get("id") != f"f{index:02d}.{name}":
                raise ValueError(f"F{index:02d}: missing/flipped anatomical identity {name}")
            _point(item.get("xy"), f"F{index:02d}.{name}")
        if not frame.get("source_sha256"):
            raise ValueError(f"F{index:02d}: source frame hash missing")
    # The manually accepted near/far traces exchange horizontal ankle order at
    # the two documented crossovers. This catches side swaps without x-half rules.
    order = [float(f["landmarks"]["ankle_near"]["xy"][0] -
                   f["landmarks"]["ankle_far"]["xy"][0]) for f in frames]
    if not (order[1] * order[2] < 0 and order[6] * order[7] < 0):
        raise ValueError("donor near/far ankle identity does not cross at 2→3 and 7→8")
    return frames


def _unit(vector: np.ndarray, label: str) -> np.ndarray:
    length = float(np.linalg.norm(vector))
    if not math.isfinite(length) or length <= 1e-9:
        raise ValueError(f"{label}: zero-length or non-finite donor segment")
    return vector / length


def cycle_scale(frames: list[dict]) -> tuple[float, dict]:
    donor_totals, rig_totals = [], []
    for frame in frames:
        lm = frame["landmarks"]
        for side in SIDES:
            hip = _point(lm[f"hip_{side}"]["xy"], "hip")
            knee = _point(lm[f"knee_{side}"]["xy"], "knee")
            ankle = _point(lm[f"ankle_{side}"]["xy"], "ankle")
            donor_totals.append(float(np.linalg.norm(knee - hip) + np.linalg.norm(ankle - knee)))
    for side in SIDES:
        rig_totals.append(float(np.linalg.norm(np.subtract(NEUTRAL[side]["knee"], NEUTRAL[side]["hip"])) +
                                      np.linalg.norm(np.subtract(NEUTRAL[side]["ankle"], NEUTRAL[side]["knee"]))))
    donor_mean = float(np.mean(donor_totals))
    rig_mean = float(np.mean(rig_totals))
    if donor_mean <= 1e-9 or not math.isfinite(donor_mean):
        raise ValueError("invalid mean donor leg length")
    return rig_mean / donor_mean, {"donor_mean_thigh_shin": donor_mean,
                                   "rig_mean_thigh_shin": rig_mean}


def map_all(frames: list[dict]) -> tuple[list[dict], float, dict]:
    """Apply the specified one-cycle scale and preserve each traced side."""
    scale, scale_terms = cycle_scale(frames)
    pelvises = np.asarray([_point(f["landmarks"]["pelvis"]["xy"], "pelvis") for f in frames])
    mean_pelvis = np.mean(pelvises, axis=0)
    result = []
    for frame in frames:
        idx = frame["frame"]
        pelvis = _point(frame["landmarks"]["pelvis"]["xy"], f"F{idx:02d}.pelvis")
        pose = {"frame": idx, "support": frame["support"],
                "knight_pelvis": pelvis.tolist(), "mean_knight_pelvis": mean_pelvis.tolist(),
                "donor": {}, "raw": {}}
        for side in SIDES:
            lm = frame["landmarks"]
            donor = {k: _point(lm[f"{k}_{side}"]["xy"], f"F{idx:02d}.{k}_{side}")
                     for k in ("hip", "knee", "ankle", "toe")}
            pose["donor"][side] = {k: v.tolist() for k, v in donor.items()}
            hip = np.asarray(NEUTRAL[side]["hip"]) + scale * (pelvis - mean_pelvis)
            thigh_len = float(np.linalg.norm(np.subtract(NEUTRAL[side]["knee"], NEUTRAL[side]["hip"])))
            shin_len = float(np.linalg.norm(np.subtract(NEUTRAL[side]["ankle"], NEUTRAL[side]["knee"])))
            foot_len = float(np.linalg.norm(np.subtract(NEUTRAL[side]["toe"], NEUTRAL[side]["ankle"])))
            knee = hip + thigh_len * _unit(donor["knee"] - donor["hip"], f"F{idx:02d}.{side}.thigh")
            ankle = knee + shin_len * _unit(donor["ankle"] - donor["knee"], f"F{idx:02d}.{side}.shin")
            toe = ankle + foot_len * _unit(donor["toe"] - donor["ankle"], f"F{idx:02d}.{side}.foot")
            pose["raw"][side] = {"hip": hip.tolist(), "knee": knee.tolist(),
                                  "ankle": ankle.tolist(), "toe": toe.tolist(),
                                  "donor": {k: v.tolist() for k, v in donor.items()},
                                  "lengths": {"thigh": thigh_len, "shin": shin_len, "foot": foot_len}}
        result.append(pose)
    return result, scale, {**scale_terms, "mean_knight_pelvis": mean_pelvis.tolist()}


def translate_pose_to_contact(pose: dict, target: dict) -> dict:
    """Translate the entire pose once so its traced support toe meets target."""
    side = pose["support"]
    desired = np.asarray([float(target["x"]), float(target["y"])], dtype=float)
    toe = np.asarray(pose["raw"][side]["toe"], dtype=float)
    delta = desired - toe
    moved = {**pose, "target": desired.tolist(), "translation": delta.tolist(), "posed": {}}
    for which in SIDES:
        moved["posed"][which] = {k: (np.asarray(v, dtype=float) + delta).tolist()
                                  for k, v in pose["raw"][which].items() if k in ("hip", "knee", "ankle", "toe")}
    residual = np.asarray(moved["posed"][side]["toe"]) - desired
    moved["contact_geometry_residual"] = {"dx": float(residual[0]), "dy": float(residual[1]),
                                          "distance": float(np.linalg.norm(residual))}
    moved["root_delta"] = delta.tolist()
    return moved


def validate_support_authority(annotation_frame: dict, report_frame: dict) -> dict:
    if annotation_frame.get("support") not in SIDES:
        raise ValueError("annotation has invalid support identity")
    contact = report_frame.get("contact", {})
    if (report_frame.get("support") != annotation_frame["support"] or
            contact.get("side") != annotation_frame["support"] or not contact.get("applicable")):
        raise ValueError(f"F{annotation_frame.get('frame')}: support schedule differs from accepted report")
    target = contact.get("desired")
    if not isinstance(target, dict) or not all(k in target for k in ("x", "y")):
        raise ValueError(f"F{annotation_frame.get('frame')}: accepted report contact target missing")
    return target
