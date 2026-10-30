#!/usr/bin/env python3
"""Create a content-addressed, candidate-only receipt for the v2 Neutral Idle render."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image

DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
SOURCE_SHA = "40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3"
MASTER_SHA = "a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969"
OLD_RECEIPT_SHA = "1fd0b407d4ac1267b687cea024647ff7be7bf6bc8fe95b08dcc1b300aa13aee6"
ROOT_PIXEL = [64, 106]


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def canonical(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--proof-root", type=Path, required=True)
    parser.add_argument("--render-dir", type=Path, required=True)
    args = parser.parse_args()
    root = args.proof_root.resolve(strict=True)
    render_dir = args.render_dir.resolve(strict=True)
    motion_path = root / "retarget_fix_v1/motion/neutral_idle_motion.v2_rest_frame.json"
    trajectory_path = root / "retarget_fix_v1/motion/neutral_idle_root_trajectory.v1.json"
    mapping_path = root / "retarget_fix_v1/motion/neutral_idle_skeleton_mapping.v1.json"
    source_path = root / "inputs/Neutral Idle.fbx"
    master_path = root / "inputs/operator_run_mixamo_iter005_contact_ik.blend"
    policy_src = Path(__file__).with_name("contracts") / "mixamo_rest_frame_retarget_policy_v2.json"
    policy_dst = render_dir.parent / "inputs/mixamo_rest_frame_retarget_policy_v2.json"
    policy_dst.parent.mkdir(parents=True, exist_ok=True)
    if not policy_dst.exists():
        policy_dst.write_bytes(policy_src.read_bytes())
    policy_path = policy_dst.resolve(strict=True)
    for path, expected in ((source_path, SOURCE_SHA), (master_path, MASTER_SHA)):
        if sha(path) != expected:
            raise SystemExit(f"INPUT_HASH_MISMATCH:{path.name}")
    motion = json.loads(motion_path.read_text())
    prior_qa_path = root / "retarget_fix_v1/qa/retarget_fix_validation_report.v1.json"
    prior_qa = json.loads(prior_qa_path.read_text())
    anatomy = prior_qa["neutral_idle_full_cycle"]
    repeat_report_path = root / "retarget_fix_v1/awakening_preview_v1/qa/render_repeat_comparison.v1.json"
    repeat_report = json.loads(repeat_report_path.read_text()) if repeat_report_path.is_file() else None
    render_metadata_path = render_dir / "render_metadata.v1.json"
    render_metadata = json.loads(render_metadata_path.read_text())
    if motion["source"]["sha256"] != SOURCE_SHA or motion["loop"].get("terminal_pose_duplicate") is not True:
        raise SystemExit("MOTION_SOURCE_OR_LOOP_CONTRACT_MISMATCH")
    if len(motion["frames"]) != 264 or [x["source_frame"] for x in motion["frames"]] != list(range(1, 265)):
        raise SystemExit("MOTION_NOT_COMPLETE_SOURCE_RANGE")
    frames = motion["frames"][:-1]
    rendered_indices = [f["source_frame"] for f in frames]
    if rendered_indices != list(range(1, 264)):
        raise SystemExit("UNIQUE_LOOP_SAMPLE_RANGE_INVALID")

    qa_frames: dict[str, list[dict[str, Any]]] = {}
    receipt_directions: list[dict[str, Any]] = []
    boundary_touches: dict[str, int] = {}
    for direction in DIRECTIONS:
        rows = []
        receipt_rows = []
        touched = 0
        for source_frame in rendered_indices:
            path = render_dir / direction / f"{source_frame:04d}.png"
            if not path.is_file():
                raise SystemExit(f"FRAME_MISSING:{direction}:{source_frame}")
            raw_sha = sha(path)
            with Image.open(path) as image:
                if image.format != "PNG" or image.size != (128, 128):
                    raise SystemExit(f"FRAME_DIMENSION_OR_FORMAT:{direction}:{source_frame}")
                rgba = image.convert("RGBA")
                alpha = rgba.getchannel("A")
                bbox = alpha.getbbox()
                if bbox is None:
                    raise SystemExit(f"EMPTY_FRAME:{direction}:{source_frame}")
                if bbox[0] == 0 or bbox[1] == 0 or bbox[2] == 128 or bbox[3] == 128:
                    touched += 1
                pixel_sha = hashlib.sha256(rgba.tobytes()).hexdigest()
            rel = path.relative_to(root).as_posix()
            rows.append({"source_frame": source_frame, "path": rel, "sha256": raw_sha,
                         "width": 128, "height": 128, "channels": "RGBA"})
            receipt_rows.append({"source_frame": source_frame, "path": rel, "sha256": raw_sha,
                                 "width": 128, "height": 128, "channels": "RGBA",
                                 "pixel_sha256": pixel_sha})
        boundary_touches[direction] = touched
        qa_frames[direction] = rows
        receipt_directions.append({"direction": direction, "frames": receipt_rows})

    registration = render_metadata.get("registered_root_pixels", {})
    if any(
        not isinstance(registration.get(d), list)
        or len(registration[d]) != 2
        or any(abs(float(registration[d][i]) - ROOT_PIXEL[i]) > 0.001 for i in range(2))
        for d in DIRECTIONS
    ):
        raise SystemExit("ROOT_REGISTRATION_INVALID")
    if render_metadata.get("sample_count") != 263 or render_metadata.get("resolution") != [128, 128]:
        raise SystemExit("RENDER_SAMPLE_OR_RESOLUTION_INVALID")
    if render_metadata.get("motion_sha256") != motion.get("motion_sha256"):
        raise SystemExit("RENDER_MOTION_IDENTITY_MISMATCH")

    # Technical pass means complete, decodable, correctly registered outputs and
    # preserved inputs. Edge contacts remain explicit findings for review.
    motion_variation = any(
        motion["frames"][0]["bones"][bone] != motion["frames"][132]["bones"][bone]
        for bone in ("mixamorig:LeftHand", "mixamorig:RightHand", "mixamorig:LeftArm", "mixamorig:RightArm")
    )
    if not motion_variation:
        raise SystemExit("CORRECTED_HAND_ARM_MOTION_MISSING")
    qa = {
        "schema": "custodian.operator_neutral_idle_technical_qa.v1",
        "status": "pass",
        "candidate_state": "candidate_unapproved",
        "production_approval": False,
        "candidate_version": "neutral_idle_rest_frame_v2_awakening_128_v1",
        "source": {"fps": motion["source"]["fps"], "frame_start": 1, "frame_end": 264,
                   "rendered_frame_indices": rendered_indices, "loop_endpoint_duplicate": True,
                   "action_identity": motion["source"]["action"],
                   "source_skeleton_signature_sha256": motion["source"]["source_skeleton_signature_sha256"],
                   "source_sha256": SOURCE_SHA},
        "master_sha256": MASTER_SHA,
        "motion_sha256": motion["motion_sha256"],
        "motion_file_sha256": sha(motion_path),
        "root_trajectory_sha256": sha(trajectory_path),
        "mapping_sha256": sha(mapping_path),
        "retarget_policy_sha256": sha(policy_path),
        "render_metadata_sha256": sha(render_metadata_path),
        "render_contract": {"width": 128, "height": 128, "channels": "RGBA", "fps": 30,
                            "pixels_per_meter": 50, "root_pixel": ROOT_PIXEL,
                            "camera_elevation_degrees": 45, "fixed_scale": render_metadata["fixed_scale"],
                            "mirroring": False},
        "registered_root_pixels": registration,
        "frame_hashes": qa_frames,
        "findings": {
            "art_approval": "not_granted; requires human visual review",
            "diagnostic_128_edge_contacts_per_direction": boundary_touches,
            "right_southwest_edge_contact_requires_visual_assessment": boundary_touches["SW"] > 0,
            "preserved_hand_and_arm_motion_variation": True,
            "root_trajectory_separate_from_sprite_pose": True,
            "contact_and_ankle_placement_evidence": "retarget_fix_v1/qa/retarget_fix_validation_report.v1.json",
            "measured_anatomy": {
                "mean_ankle_spacing_over_target_leg_length": anatomy["corrected_target_mean_spacing_over_leg_length"],
                "mean_lateral_spacing_over_target_pelvis_width": anatomy["corrected_target_mean_lateral_spacing_over_pelvis_width"],
                "mean_elbow_angle_degrees": anatomy["corrected_mean_elbow_angle_deg"],
                "mean_knee_angle_degrees": anatomy["corrected_mean_knee_angle_deg"],
                "mean_shoulder_to_wrist_direction_error_degrees": {
                    side: anatomy["average_direction_error_deg"][side]["shoulder_to_wrist"]
                    for side in ("left", "right")
                },
                "minimum_mesh_height_m": anatomy["minimum_mesh_z_m"],
                "frames_below_ground": anatomy["frames_below_ground"],
            },
            "loop_seam": motion["loop"],
            "render_reproducibility": repeat_report,
            "render_determinism_note": "Candidate outputs are bound by per-file hashes; repeat-render comparisons are recorded separately and do not imply pixel determinism unless the decoded RGBA hashes match.",
        },
    }
    qa_dir = root / "retarget_fix_v1/awakening_preview_v1/qa"
    qa_dir.mkdir(parents=True, exist_ok=True)
    qa_path = qa_dir / "neutral_idle_technical_qa.v2.json"
    qa_path.write_bytes(canonical(qa))
    qa_sha = sha(qa_path)
    master_contract_path = root / "master_contract.v1.json"
    master_contract_sha = sha(master_contract_path)
    armature_identity = root / "inspection/identity/armature_identity.json"
    rest_pose = root / "inspection/identity/armature_rest_pose.json"
    skeleton = root / "inspection/identity/skeleton_signature.json"
    master_contract = json.loads(master_contract_path.read_text())
    contract_src = Path(__file__).with_name("contracts") / "full_body_8dir_128_v1.json"
    contract_path = render_dir.parent / "inputs/full_body_8dir_128_v1.json"
    if not contract_path.exists():
        contract_path.write_bytes(contract_src.read_bytes())
    if motion["target_rig"]["skeleton_signature_sha256"] != master_contract["armature"]["skeleton_signature_sha256"]:
        raise SystemExit("TARGET_SKELETON_SIGNATURE_MISMATCH")
    if sha(policy_path) != "98f01711fda8b296dd740686e03904963f84110b74ed2ddfb6668a80f63520a1":
        raise SystemExit("RETARGET_POLICY_HASH_MISMATCH")
    if master_contract.get("approval_state") != "experimental":
        raise SystemExit("EXPERIMENTAL_MASTER_STATE_UNEXPECTED")
    for texture in master_contract.get("textures", []):
        if sha(root / texture["path"]) != texture["sha256"]:
            raise SystemExit("MASTER_TEXTURE_HASH_MISMATCH:" + texture["path"])
    input_identity = {
        "schema": "custodian.operator_neutral_idle_corrected_input_identity.v1",
        "source_sha256": SOURCE_SHA, "master_sha256": MASTER_SHA,
        "motion_file_sha256": sha(motion_path), "motion_sha256": motion["motion_sha256"],
        "root_trajectory_sha256": sha(trajectory_path), "mapping_file_sha256": sha(mapping_path),
        "policy_sha256": sha(policy_path), "render_contract_sha256": sha(contract_path),
        "render_metadata_sha256": sha(render_metadata_path), "technical_qa_sha256": qa_sha,
        "repeat_render_report_sha256": sha(repeat_report_path) if repeat_report is not None else None,
    }
    identity_path = qa_dir / "candidate_input_identity.v1.json"
    identity_path.write_bytes(canonical(input_identity))
    job_id = "op3d-neutral-idle-v2-" + hashlib.sha256(canonical(input_identity)).hexdigest()[:24]
    deps = []
    dep_inputs = [
        ("fbx", source_path), ("blender_project", master_path), ("master_contract", master_contract_path),
        ("armature_identity", armature_identity), ("rest_pose", rest_pose), ("skeleton_signature", skeleton),
        ("retargeted_motion", motion_path), ("root_trajectory", trajectory_path),
        ("skeleton_mapping", mapping_path), ("retarget_policy", policy_path),
        ("rendering_contract", contract_path), ("rendering_metadata", render_metadata_path),
        ("candidate_input_identity", identity_path), ("technical_qa_report", qa_path),
        ("retarget_validation_report", prior_qa_path),
    ]
    if repeat_report is not None:
        dep_inputs.append(("repeat_render_report", repeat_report_path))
    for texture in master_contract.get("textures", []):
        dep_inputs.append(("texture", root / texture["path"]))
    for kind, path in dep_inputs:
        deps.append({"kind": kind, "path": path.resolve().relative_to(root).as_posix(),
                     "scope": "asset_root", "sha256": sha(path)})
    deps.extend({"kind": "rendered_frame", "path": row["path"], "scope": "asset_root", "sha256": row["sha256"]}
                for direction in receipt_directions for row in direction["frames"])
    receipt = {
        "schema": "custodian.operator_3d_animation_candidate_receipt.v1",
        "job_id": job_id, "batch_id": "operator_neutral_idle_corrected_retarget_preview_v1",
        "candidate_version": "neutral_idle_rest_frame_v2_awakening_128_v1",
        "animation_id": "neutral_idle", "candidate_state": "candidate_unapproved",
        "source": {"animation_id": "neutral_idle", "original_filename": "Neutral Idle.fbx",
                   "action_identity": motion["source"]["action"],
                   "source_skeleton_signature_sha256": motion["source"]["source_skeleton_signature_sha256"],
                   "fbx_sha256": SOURCE_SHA, "authored_fps": 30, "frame_start": 1, "frame_end": 264,
                   "duration_seconds": 264 / 30, "unique_loop_duration_seconds": 263 / 30,
                   "loop_classification": "loop", "impact_direction": None},
        "master": {"master_id": "experimental_iter005_baseline",
                   "blender_project_sha256": MASTER_SHA,
                   "contract_sha256": master_contract_sha,
                   "armature_identity_sha256": sha(armature_identity),
                   "rest_pose_sha256": sha(rest_pose),
                   "skeleton_signature_sha256": json.loads(skeleton.read_text())["signature_sha256"]},
        "rendering_contract": {"contract_id": "operator_full_body_8dir_128_v1",
                               "contract_sha256": sha(contract_path), "directions": list(DIRECTIONS),
                               "width": 128, "height": 128, "channels": "RGBA", "elevation_degrees": 45,
                               "pixels_per_meter": 50, "root_pixel": ROOT_PIXEL,
                               "mirroring": False, "scale_policy": "fixed_from_master"},
        "sampling": {"source_timing_preserved": True, "source_frame_indices": rendered_indices,
                     "loop_endpoint_policy": "omit_declared_duplicate_terminal",
                     "runtime_timing_authority": {"status": "unavailable", "sha256": None}},
        "root_motion": {"policy": "extract_to_metadata", "source_state": "present",
                        "original_trajectory_path": trajectory_path.resolve().relative_to(root).as_posix(),
                        "original_trajectory_sha256": sha(trajectory_path),
                        "pose_root_translation": "removed", "godot_application": "trajectory_once_separately"},
        "technical_qa": {"report_path": qa_path.resolve().relative_to(root).as_posix(), "report_sha256": qa_sha,
                         "state": "pass"},
        "production_approval": {"approved": False, "authority": "human_asset_review_and_separate_ingress"},
        "dependencies": deps,
        "directions": [{"direction": d["direction"], "frames": d["frames"]} for d in receipt_directions],
    }
    receipt_path = root / "retarget_fix_v1/awakening_preview_v1/candidates/neutral_idle_candidate_receipt.v2.json"
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    receipt_path.write_bytes(canonical(receipt))
    receipt_sha = sha(receipt_path)
    if receipt_sha == OLD_RECEIPT_SHA:
        raise SystemExit("CANDIDATE_RECEIPT_ID_REUSED")
    print(json.dumps({"ok": True, "job_id": job_id, "receipt_path": str(receipt_path),
                      "receipt_sha256": receipt_sha, "qa_path": str(qa_path), "qa_sha256": qa_sha,
                      "frames_per_direction": 263, "directions": list(DIRECTIONS),
                      "edge_contacts_per_direction": boundary_touches,
                      "candidate_state": "candidate_unapproved"}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
