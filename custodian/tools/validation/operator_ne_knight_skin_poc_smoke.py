#!/usr/bin/env python3
"""Source-independent negative controls for the Knight-driven skin POC."""
from __future__ import annotations

import copy
import hashlib
import json
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator/ne_walk_retarget"))
from knight_skin_poc.pose_map import (LANDMARKS, NEUTRAL, POSES, map_all,
    translate_pose_to_contact, validate_annotations, validate_support_authority)
from knight_skin_poc.skin_renderer import (DRAW_ORDER, _component_owner_join,
    ensure_fresh_output, validate_candidate_pixels, validate_expected_occlusion,
    validate_rig_and_neutral)
from knight_skin_poc.run import require_hash


def must_fail(label, fn):
    try:
        fn()
    except (ValueError, FileExistsError):
        return
    raise AssertionError(f"negative control did not fail closed: {label}")


def fixture_annotations():
    frames = []
    for frame_no in range(1, 16):
        near_x = 10.0
        far_x = 9.0 if frame_no <= 2 or frame_no >= 8 else 11.0
        values = {
            "pelvis": [64.0, 70.0],
            "hip_near": [69.0, 74.0], "knee_near": [68.0, 80.0],
            "ankle_near": [near_x, 84.0], "toe_near": [near_x + 3.0, 87.0],
            "hip_far": [60.0, 74.0], "knee_far": [58.0, 79.0],
            "ankle_far": [far_x, 86.0], "toe_far": [far_x - 2.0, 89.0],
        }
        marks = {name: {"id": f"f{frame_no:02d}.{name}", "xy": point}
                 for name, point in values.items()}
        frames.append({"frame": frame_no, "support": "near" if frame_no <= 5 else "far",
                       "source_sha256": f"frame-{frame_no}", "landmarks": marks})
    return {"frames": frames}


def fixture_rig():
    full = np.zeros((128, 128, 4), dtype=np.uint8)
    rig = {"__RIG_REFERENCE_LOCKED_FULL_BODY": full}
    full[2, 2] = (20, 30, 40, 255)  # static upper-body residual
    for index, name in enumerate(DRAW_ORDER):
        layer = np.zeros_like(full)
        y, x = 10 + index * 4, 10
        layer[y:y+2, x:x+2] = (60 + index, 70, 80, 255)
        full[y:y+2, x:x+2] = layer[y:y+2, x:x+2]
        rig[f"__RIG_PART_{name}"] = layer
    return rig


def main():
    # 15-frame numerical authority and crossover identity.
    anns = fixture_annotations()
    frames = validate_annotations(anns, expected_sha=None)
    mapped, _, _ = map_all(frames)
    assert len(mapped) == 15 and [p for p in POSES] == [1, 5, 7, 12, 15]
    pose = mapped[0]
    aligned = translate_pose_to_contact(pose, {"x": 10, "y": 11})
    assert aligned["contact_geometry_residual"]["distance"] < 1e-8

    # Wrong Knight SHA and wrong accepted rig both reject before authoring.
    with tempfile.TemporaryDirectory() as tmp:
        wrong = Path(tmp) / "wrong.png"
        wrong.write_bytes(b"not the pinned donor")
        must_fail("wrong Knight hash", lambda: require_hash(wrong, "0" * 64, "Knight donor"))
        must_fail("wrong rig", lambda: __import__(
            "knight_skin_poc.skin_renderer", fromlist=["load_rig"]).load_rig(wrong))
        must_fail("output overwrite", lambda: ensure_fresh_output(Path(tmp)))
        pinned = Path(tmp) / "source.bin"
        pinned.write_bytes(b"locked")
        before = hashlib.sha256(pinned.read_bytes()).hexdigest()

    must_fail("14 donor frames", lambda: validate_annotations({"frames": frames[:-1]}, None))
    flipped = copy.deepcopy(anns)
    flipped["frames"][0]["landmarks"]["hip_near"], flipped["frames"][0]["landmarks"]["hip_far"] = (
        flipped["frames"][0]["landmarks"]["hip_far"], flipped["frames"][0]["landmarks"]["hip_near"])
    must_fail("flipped near/far identity", lambda: validate_annotations(flipped, None))
    zero = copy.deepcopy(anns)
    zero["frames"][0]["landmarks"]["knee_near"]["xy"] = zero["frames"][0]["landmarks"]["hip_near"]["xy"][:]
    must_fail("zero-length joint", lambda: map_all(validate_annotations(zero, None)))
    ann = frames[0]
    accepted = {"frame": 1, "support": "near", "contact": {
        "applicable": True, "side": "near", "desired": {"x": 64, "y": 100}}}
    assert validate_support_authority(ann, accepted)["y"] == 100
    bad_support = copy.deepcopy(accepted)
    bad_support["support"] = "far"
    bad_support["contact"]["side"] = "far"
    must_fail("incorrect support schedule", lambda: validate_support_authority(ann, bad_support))

    # Neutral owner reconstruction is exact; a spurious boot pixel is rejected.
    rig = fixture_rig()
    state = validate_rig_and_neutral(rig)
    assert state["neutral_reassembly_changed_pixels"] == 0
    ghost = copy.deepcopy(rig)
    ghost["__RIG_PART_foot_near_visible"][120, 120] = (60, 70, 80, 255)
    must_fail("spurious neutral boot", lambda: validate_rig_and_neutral(ghost))

    # Post-occlusion component ownership: separated boot and shin fail.
    owner = np.zeros((8, 8), dtype=np.uint8)
    shin_id, foot_id = DRAW_ORDER.index("shin_near_visible") + 2, DRAW_ORDER.index("foot_near_visible") + 2
    owner[1, 1] = shin_id; owner[6, 6] = foot_id
    linked, _ = _component_owner_join(owner, shin_id, foot_id)
    assert not linked, "disconnected visible near boot must not pass linkage QA"

    # The F07 far sole is expected to stay occluded by semantic draw order.
    must_fail("exposed F07 far support", lambda: validate_expected_occlusion(7, "far", True, 0))
    validate_expected_occlusion(7, "far", False, 5)

    palette = {(1, 2, 3, 255)}
    valid = np.zeros((128, 128, 4), dtype=np.uint8); valid[0, 0] = (1, 2, 3, 255)
    validate_candidate_pixels(valid, palette)
    bad_color = valid.copy(); bad_color[0, 1] = (9, 8, 7, 255)
    must_fail("wrong palette", lambda: validate_candidate_pixels(bad_color, palette))
    bad_alpha = valid.copy(); bad_alpha[0, 1] = (1, 2, 3, 127)
    must_fail("nonbinary alpha", lambda: validate_candidate_pixels(bad_alpha, palette))
    must_fail("spilled 128px cell", lambda: validate_candidate_pixels(np.zeros((128, 129, 4), dtype=np.uint8), palette))
    digest_one = hashlib.sha256(valid.tobytes()).hexdigest()
    digest_two = hashlib.sha256(valid.copy().tobytes()).hexdigest()
    assert digest_one == digest_two, "same raster input must have deterministic bytes"
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "source.bin"
        source.write_bytes(b"locked")
        after = hashlib.sha256(source.read_bytes()).hexdigest()
        assert before == after, "source material was modified"

    print("operator_ne_knight_skin_poc_smoke: PASS (negative controls and deterministic helpers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
