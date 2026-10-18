#!/usr/bin/env python3
"""Fail-closed authoring runner for five real Knight-driven Custodian poses."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from knight_skin_poc.pose_map import (ANNOTATIONS_SHA, DONOR_SHA, POSES,
                                     map_all, sha256, translate_pose_to_contact,
                                     validate_support_authority,
                                     validate_annotations)
from knight_skin_poc.review import closeup_sheet, comparison_sheet, save_png, write_review_pixels
from knight_skin_poc.skin_renderer import (ensure_fresh_output, load_rig, render_pose,
    validate_expected_occlusion, validate_rig_and_neutral)

RIG_SHA = "b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5"
ORIGINAL_SHA = "0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149"
BASELINE_SHA = "e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a"
REPORT_SHA = "88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a"
REQUIRED_ARTIFACTS = (
    "custodian_knight_driven_poc_5f_640x128.png",
    "KNIGHT_SKIN_5POSE_COMPARISON.png",
    "KNIGHT_SKIN_CROSSOVER_CLOSEUPS.png",
    "KNIGHT_SKIN_POC_AUDIT.json",
    "REVIEW_PIXELS.json",
    "REVIEW_NOTES.md",
)


def require_hash(path: Path, expected: str, label: str) -> None:
    if not path.is_file():
        raise ValueError(f"{label} missing: {path}")
    actual = sha256(path)
    if actual != expected:
        raise ValueError(f"{label} SHA256 mismatch: {actual} != {expected}")


def load_inputs(args):
    bundle = args.donor_bundle
    donor_path = bundle / "reference" / "knight_ne_walk_reference_15f_128.png"
    manifest_path = bundle / "MANIFEST.json"
    annotations_path = args.annotations
    source_path = args.source_aseprite
    report_path = args.baseline.parent / "report.json"
    require_hash(donor_path, DONOR_SHA, "approved Knight NE donor")
    require_hash(annotations_path, ANNOTATIONS_SHA, "approved 15-frame annotation trace")
    require_hash(args.rig, RIG_SHA, "approved recovered Custodian rig")
    require_hash(source_path, ORIGINAL_SHA, "locked SINGLE_FRAME source")
    require_hash(args.baseline, BASELINE_SHA, "Iteration 004 baseline strip")
    require_hash(report_path, REPORT_SHA, "Iteration 004 report")
    if not manifest_path.is_file():
        raise ValueError(f"donor MANIFEST.json missing: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("source_sha256") != DONOR_SHA:
        raise ValueError("donor manifest source identity mismatch")
    if len(manifest.get("frames_metadata", [])) != 15:
        raise ValueError("donor manifest must register exactly 15 frame hashes")
    with Image.open(donor_path) as im:
        if im.mode != "RGBA" or im.size != (1920, 128):
            raise ValueError(f"approved donor must be 1920x128 RGBA, got {im.size}/{im.mode}")
        donor = np.asarray(im, dtype=np.uint8).copy()
    frames_meta = manifest["frames_metadata"]
    donor_frames = []
    for i, item in enumerate(frames_meta):
        frame = donor[:, i * 128:(i + 1) * 128].copy()
        if hashlib.sha256(frame.tobytes()).hexdigest() != item["sha256"]:
            # Manifest hashes the encoded source frame PNG, so verify the
            # extracted frame against its actual canonical frame file below.
            png_path = bundle / "reference" / "frames" / item["name"]
            require_hash(png_path, item["sha256"], f"donor F{i+1:02d}")
            with Image.open(png_path) as frame_im:
                if frame_im.mode != "RGBA" or frame_im.size != (128, 128):
                    raise ValueError(f"donor F{i+1:02d}: invalid registered frame")
                registered = np.asarray(frame_im, dtype=np.uint8)
            if not np.array_equal(frame, registered):
                raise ValueError(f"donor F{i+1:02d}: source strip differs from registered crop")
        donor_frames.append(frame)
    annotations_bytes = annotations_path.read_bytes()
    annotations = json.loads(annotations_bytes)
    annotations["_source_bytes"] = annotations_bytes
    frames = validate_annotations(annotations)
    for i, (frame, meta) in enumerate(zip(frames, frames_meta), 1):
        if frame["source_sha256"] != meta["sha256"]:
            raise ValueError(f"F{i:02d}: annotation and donor manifest hashes disagree")
    with Image.open(args.baseline) as im:
        if im.mode != "RGBA" or im.size != (1920, 128):
            raise ValueError("Iteration 004 baseline must be 1920x128 RGBA")
        baseline_strip = np.asarray(im, dtype=np.uint8).copy()
    report = json.loads(report_path.read_text(encoding="utf-8"))
    if not isinstance(report.get("frames"), list) or len(report["frames"]) != 15:
        raise ValueError("Iteration 004 report must contain 15 frame records")
    ensure_fresh_output(args.output)
    return {"donor": donor, "donor_frames": donor_frames, "manifest": manifest,
            "annotations": frames, "rig": load_rig(args.rig), "baseline": baseline_strip,
            "report": report, "hashes": {"donor": DONOR_SHA, "annotations": ANNOTATIONS_SHA,
                "rig": RIG_SHA, "locked_source": ORIGINAL_SHA,
                "baseline": BASELINE_SHA, "baseline_report": REPORT_SHA,
                "donor_manifest": sha256(manifest_path), "source_aseprite": sha256(source_path)}}


def _save_array(path: Path, data: np.ndarray) -> dict:
    image = Image.fromarray(data.astype(np.uint8), "RGBA")
    return save_png(path, image)


def _verify_output_contract(outdir: Path) -> None:
    files = tuple(sorted(p.name for p in outdir.iterdir() if p.is_file()))
    if files != tuple(sorted(REQUIRED_ARTIFACTS)):
        raise ValueError(f"review output artifact set mismatch: {files}")


def _verify_immutable_inputs(args, expected: dict) -> None:
    paths = ((args.donor_bundle / "reference" / "knight_ne_walk_reference_15f_128.png", DONOR_SHA),
             (args.annotations, ANNOTATIONS_SHA), (args.rig, RIG_SHA),
             (args.source_aseprite, ORIGINAL_SHA), (args.baseline, BASELINE_SHA),
             (args.baseline.parent / "report.json", REPORT_SHA))
    for path, digest in paths:
        require_hash(path, digest, f"immutable input after render ({path.name})")


def run(args) -> dict:
    inputs = load_inputs(args)  # All immutable-source checks precede output creation.
    rig_state = validate_rig_and_neutral(inputs["rig"])
    mapped, scale, scale_terms = map_all(inputs["annotations"])
    mapped_by_frame = {pose["frame"]: pose for pose in mapped}
    posed_by_frame, candidates, owners, baselines = {}, {}, {}, {}
    frame_reports = []
    for frame_no in POSES:
        ann = inputs["annotations"][frame_no - 1]
        accepted = inputs["report"]["frames"][frame_no - 1]
        target = validate_support_authority(ann, accepted)
        posed = translate_pose_to_contact(mapped_by_frame[frame_no], target)
        frame, owner, raster = render_pose(rig_state | {"rig": inputs["rig"]}, posed)
        repeat_frame, repeat_owner, repeat_raster = render_pose(rig_state | {"rig": inputs["rig"]}, posed)
        frame_digest = hashlib.sha256(frame.tobytes()).hexdigest()
        if (frame_digest != hashlib.sha256(repeat_frame.tobytes()).hexdigest() or
                not np.array_equal(owner, repeat_owner) or raster != repeat_raster):
            raise ValueError(f"F{frame_no:02d}: same-run raster SHA/owner report is nondeterministic")
        candidates[frame_no], owners[frame_no], baselines[frame_no] = frame, owner, inputs["baseline"][:, (frame_no-1)*128:frame_no*128].copy()
        posed_by_frame[frame_no] = posed
        raster_contact = raster["support_raster"]
        validate_expected_occlusion(frame_no, ann["support"],
            raster_contact["nearest_pixel_visible"], raster_contact["occluded_support_pixels"])
        if raster_contact["nearest_pixel_visible"]:
            dx, dy = raster_contact["nearest_pixel_delta"]
            if abs(dx) > 2 or abs(dy) > 1:
                raise ValueError(f"F{frame_no:02d}: support sole raster residual exceeds tolerance")
        elif raster_contact["occluded_support_pixels"] <= 0:
            raise ValueError(f"F{frame_no:02d}: hidden support lacks semantic occlusion proof")
        if frame_no in (5, 7, 12) and not raster["limb_linkage"]["near"]["boot_connected_to_shin"]:
            raise ValueError(f"F{frame_no:02d}: visible near boot is disconnected from shin")
        mapped_pelvis = np.asarray(mapped_by_frame[frame_no]["knight_pelvis"], dtype=float)
        mean_pelvis = np.asarray(mapped_by_frame[frame_no]["mean_knight_pelvis"], dtype=float)
        root_base = np.asarray([64.0, 106.0], dtype=float)
        projected_root = root_base + scale * (mapped_pelvis - mean_pelvis) + np.asarray(posed["translation"])
        frame_reports.append({"frame": frame_no, "support": ann["support"],
            "support_target": target, "support_geometry_residual": posed["contact_geometry_residual"],
            "whole_character_translation": posed["translation"],
            "projected_pelvis_and_root": {"knight_pelvis_raw": mapped_by_frame[frame_no]["knight_pelvis"],
                "knight_pelvis_mean": mapped_by_frame[frame_no]["mean_knight_pelvis"],
                "neutral_rig_root": root_base.tolist(), "cycle_scale": scale,
                "whole_pose_translation": posed["translation"], "projected_root": projected_root.tolist()},
            "pose": posed, "raster_qa": raster})

    _verify_immutable_inputs(args, inputs["hashes"])
    parent = args.output.parent
    parent.mkdir(parents=True, exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix=f".{args.output.name}.tmp-", dir=parent))
    try:
        strip = np.zeros((128, 640, 4), dtype=np.uint8)
        for i, frame_no in enumerate(POSES):
            strip[:, i*128:(i+1)*128] = candidates[frame_no]
        strip_info = _save_array(temp / REQUIRED_ARTIFACTS[0], strip)
        comp = comparison_sheet(inputs["donor_frames"], mapped_by_frame, candidates, owners, baselines)
        comp_info = save_png(temp / REQUIRED_ARTIFACTS[1], comp)
        closeups = closeup_sheet(candidates, owners)
        closeup_info = save_png(temp / REQUIRED_ARTIFACTS[2], closeups)
        review_pixel_info = write_review_pixels(temp / REQUIRED_ARTIFACTS[4], {
            REQUIRED_ARTIFACTS[1]: comp, REQUIRED_ARTIFACTS[2]: closeups})
        audit = {
            "schema": "operator_ne_knight_skin_poc_audit_v1",
            "workstream": "operator-2-5d-ne-walk-retargeting",
            "iteration": 9,
            "rendered_frames": list(POSES),
            "not_a_loop": True,
            "source_hashes": inputs["hashes"],
        "donor_frame_hashes": [f["source_sha256"] for f in inputs["annotations"]],
            "source_dimensions": {"knight_donor": [1920, 128], "rig": [128, 128],
                                  "baseline": [1920, 128]},
            "neutral_reassembly": {k: v for k, v in rig_state.items()
                                   if k not in ("palette", "full", "residual")},
            "cycle_scale": scale,
            "cycle_scale_terms": scale_terms,
            "all_15_donor_pose_maps": mapped,
            "five_rendered_pose_reports": frame_reports,
            "crossovers": {"near_far_identity_preserved": True,
                           "ankle_order_changes": ["2->3", "7->8"]},
            "support_schedule": [f["support"] for f in inputs["annotations"]],
            "color_provenance": "Custodian accepted-rig RGBA source layers only; no Knight pixels sampled for output",
            "art_accepted": False, "runtime_ready": False, "fps": None,
            "known_limitations": ["Upper body remains static because the accepted rig has no independent upper-body pose cels.",
                                  "Five sparse poses do not establish full-loop motion continuity or FPS."],
            "artifact_metadata": [strip_info, comp_info, closeup_info],
            "review_pixels_embedded": review_pixel_info,
        }
        commit = subprocess.run(["git", "-C", str(HERE.parents[4]), "rev-parse", "HEAD"],
                                check=True, capture_output=True, text=True).stdout.strip()
        audit["implementation_checkpoint"] = commit
        (temp / REQUIRED_ARTIFACTS[3]).write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
        notes = f"""# Knight-driven Custodian skin POC · Iteration 009

Review-only output: five individual poses F01/F05/F07/F12/F15. This is not a loop and has no FPS authority.

## Reproduction

```bash
python3 custodian/tools/operator/ne_walk_retarget/knight_skin_poc/run.py \\
  --donor-bundle \"$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1\" \\
  --rig \"$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite\" \\
  --baseline \"$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png\" \\
  --output \"$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_009_knight_driven_skin_poc_v1\"
```

Implementation checkpoint before this run: `{commit}`. Immutable input hashes are recorded in `KNIGHT_SKIN_POC_AUDIT.json`.

## Technical scope and known limit

The real approved Knight NE frames and traced 15-pose landmarks drive warped pixels from the accepted Custodian rig. The new skin uses Custodian source colors only. The upper body is held static because this rig has no independent upper-body pose cels; no arm sway was fabricated. `art_accepted=false`, `runtime_ready=false`, `fps=null`.

## Human review questions

1. Do F05/F07 show clear crossover identity and convincing NE-facing boots?
2. Does F12 preserve the Knight's leg excursion while the Custodian apron remains believable?
3. Do F15 and F01 plausibly belong to the same walk cycle as silhouettes, without treating this sparse proof as smooth playback?
"""
        (temp / REQUIRED_ARTIFACTS[5]).write_text(notes, encoding="utf-8")
        _verify_output_contract(temp)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temp.rename(args.output)
    except Exception:
        shutil.rmtree(temp, ignore_errors=True)
        raise
    result = {"output": str(args.output), "artifacts": list(REQUIRED_ARTIFACTS),
              "source_hashes": inputs["hashes"], "rendered_frames": list(POSES),
              "neutral_reassembly_changed_pixels": 0, "art_accepted": False,
              "runtime_ready": False, "fps": None}
    return result


def _parser():
    default_root = Path.home() / "Downloads/operator_ne_master_audit_implementation_v1"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--donor-bundle", type=Path, required=True)
    parser.add_argument("--rig", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--annotations", type=Path, default=HERE.parent / "annotations.json")
    parser.add_argument("--source-aseprite", type=Path, default=Path.home() / "Downloads/SINGLE_FRAME.aseprite")
    parser.add_argument("--output", type=Path, required=True)
    return parser


def main(argv=None) -> int:
    args = _parser().parse_args(argv)
    args.output = args.output.expanduser().resolve()
    try:
        result = run(args)
    except Exception as exc:
        print(f"FAIL CLOSED: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
