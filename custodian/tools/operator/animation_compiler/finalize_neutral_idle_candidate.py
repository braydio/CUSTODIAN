"""Build compact QA, loops, contact sheet, and a compiler-compatible receipt."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw
from PIL import ImageChops
from neutral_idle_proof_contract import sampled_frames, validate_motion

DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha_file(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def rel(root, path):
    return path.resolve().relative_to(root.resolve()).as_posix()


def add_dep(deps, root, kind, path, scope="asset_root", repo_root=None):
    path_root = root if scope == "asset_root" else repo_root
    deps.append({"kind": kind, "path": rel(path_root, path), "sha256": sha_file(path), "scope": scope})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--proof-root", type=Path, required=True)
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--repeat-root", type=Path, required=True)
    parser.add_argument("--repeat-motion", type=Path, required=True)
    args = parser.parse_args()
    root, repo = args.proof_root.resolve(), args.repo_root.resolve()
    manifest_path = root / "neutral_idle_batch.v1.json"
    manifest = json.loads(manifest_path.read_text())
    source = manifest["animations"][0]
    motion_path = root / "motion/neutral_idle_motion.v1.json"
    trajectory_path = root / "motion/neutral_idle_root_trajectory.v1.json"
    mapping_path = root / "motion/neutral_idle_skeleton_mapping.v1.json"
    motion = json.loads(motion_path.read_text())
    validate_motion(motion)
    repeat_motion_path = args.repeat_motion.resolve()
    motion_repeat = {"candidate_sha256": sha_file(motion_path),
                     "repeat_sha256": sha_file(repeat_motion_path),
                     "byte_identical": sha_file(motion_path) == sha_file(repeat_motion_path)}
    if not motion_repeat["byte_identical"]:
        raise RuntimeError("RETARGETED_MOTION_REPEAT_MISMATCH")
    frames_expected = sampled_frames(motion["source"]["frame_start"], motion["source"]["frame_end"],
                                     motion["loop"]["terminal_pose_duplicate"])
    candidate_dir = root / "candidate/neutral_idle/unarmed/posture/neutral_idle/full_body"
    metadata_path = candidate_dir / "render_metadata.v1.json"
    metadata = json.loads(metadata_path.read_text())
    qa = {"schema": "custodian.operator_neutral_idle_technical_qa.v1", "candidate_state": "candidate_unapproved",
          "source": {"sha256": source["source"]["sha256"], "action": source["source_action"]["identity"],
                     "fps": source["authored_timing"]["fps"], "source_frames": [1, 264],
                     "source_frame_count": 264, "rendered_frame_indices": frames_expected,
                     "loop_endpoint_duplicate": motion["loop"]["terminal_pose_duplicate"]},
          "render_contract": {"directions": DIRECTIONS, "dimensions": [128, 128, "RGBA"],
             "elevation_degrees": 45, "pixels_per_meter": 50, "root_pixel": [64, 106],
             "scale_policy": "one_rest_pose_scale_fixed_for_all_frames_and_directions",
             "fixed_scale": metadata["fixed_scale"], "mirroring": False, "full_body": True},
          "registered_root_pixels": metadata["registered_root_pixels"], "directions": [], "status": "pass",
          "production_approval": False, "motion_reproducibility": motion_repeat}
    frame_index = {}
    for direction in DIRECTIONS:
        records = []
        alpha_bounds = []
        opaque = []
        for frame in frames_expected:
            path = candidate_dir / direction / f"{frame:04d}.png"
            if not path.is_file():
                raise RuntimeError(f"FRAME_MISSING:{direction}:{frame}")
            with Image.open(path) as image:
                if image.size != (128, 128) or image.mode != "RGBA":
                    raise RuntimeError(f"FRAME_FORMAT_INVALID:{direction}:{frame}")
                alpha = image.getchannel("A")
                bounds = alpha.getbbox()
                if bounds is None:
                    raise RuntimeError(f"FRAME_EMPTY:{direction}:{frame}")
                count = sum(alpha.histogram()[1:])
                alpha_bounds.append(list(bounds))
                opaque.append(count)
            item = {"source_frame": frame, "path": rel(root, path), "sha256": sha_file(path),
                    "width": 128, "height": 128, "channels": "RGBA"}
            records.append(item)
            frame_index[(direction, frame)] = path
        x_centers = [(b[0] + b[2]) / 2 for b in alpha_bounds]
        y_bottoms = [b[3] - 1 for b in alpha_bounds]
        qa["directions"].append({"direction": direction, "frame_count": len(records),
            "alpha_pixel_count_min_max": [min(opaque), max(opaque)],
            "silhouette_bounds_xyxy_min": [min(b[i] for b in alpha_bounds) for i in range(4)],
            "silhouette_bounds_xyxy_max": [max(b[i] for b in alpha_bounds) for i in range(4)],
            "silhouette_center_x_range_px": [min(x_centers), max(x_centers)],
            "silhouette_bottom_y_range_px": [min(y_bottoms), max(y_bottoms)]})
        qa.setdefault("_frames", {})[direction] = records
    root_pixels = metadata["registered_root_pixels"]
    if set(root_pixels) != set(DIRECTIONS) or any(abs(p[0] - 64) > 0.1 or abs(p[1] - 106) > 0.1 for p in root_pixels.values()):
        qa["status"] = "fail"
        qa["registration_failure"] = "projected canonical root coordinate is outside 0.1 pixel tolerance"
    for direction in qa["directions"]:
        if direction["frame_count"] != len(frames_expected):
            qa["status"] = "fail"
    repeat_root = args.repeat_root.resolve()
    repeat_results = []
    for direction in DIRECTIONS:
        for frame in (frames_expected[0], frames_expected[len(frames_expected) // 2], frames_expected[-1]):
            original = frame_index[(direction, frame)]
            repeat = repeat_root / direction / f"{frame:04d}.png"
            if not repeat.is_file():
                raise RuntimeError(f"REPEAT_RENDER_MISSING:{direction}:{frame}")
            with Image.open(original) as left, Image.open(repeat) as right:
                if left.size != right.size or left.mode != right.mode:
                    raise RuntimeError(f"REPEAT_RENDER_FORMAT_MISMATCH:{direction}:{frame}")
                pixel_equal = ImageChops.difference(left.convert("RGBA"), right.convert("RGBA")).getbbox() is None
                repeat_results.append({"direction": direction, "source_frame": frame,
                    "candidate_sha256": sha_file(original), "repeat_sha256": sha_file(repeat),
                    "candidate_pixel_sha256": sha_bytes(left.convert("RGBA").tobytes()),
                    "repeat_pixel_sha256": sha_bytes(right.convert("RGBA").tobytes()),
                    "byte_identical": sha_file(original) == sha_file(repeat), "pixel_identical": pixel_equal,
                    "repeat_path": rel(root, repeat)})
    qa["reproducibility"] = {"sample_count": len(repeat_results),
        "byte_identical_count": sum(item["byte_identical"] for item in repeat_results),
        "pixel_identical_count": sum(item["pixel_identical"] for item in repeat_results),
        "bounded_nondeterminism": "PNG encoded bytes differ while decoded RGBA pixels match" if any(not item["byte_identical"] and item["pixel_identical"] for item in repeat_results) else "none",
        "samples": repeat_results}
    review_dir = root / "review"
    loops_dir = review_dir / "loops"
    loops_dir.mkdir(parents=True, exist_ok=True)
    gif_paths = []
    for direction in DIRECTIONS:
        images = [Image.open(frame_index[(direction, frame)]).convert("RGBA") for frame in frames_expected]
        gif_path = loops_dir / f"neutral_idle_{direction}.gif"
        images[0].save(gif_path, save_all=True, append_images=images[1:], duration=1000 / 30,
                       loop=0, disposal=2, optimize=True)
        for image in images:
            image.close()
        gif_paths.append(gif_path)
    selected = [frames_expected[0], frames_expected[len(frames_expected) // 4],
                frames_expected[len(frames_expected) // 2], frames_expected[(3 * len(frames_expected)) // 4],
                frames_expected[-1]]
    label_h = 20
    sheet = Image.new("RGBA", (8 * 128, len(selected) * (128 + label_h)), (35, 38, 43, 255))
    draw = ImageDraw.Draw(sheet)
    for row, frame in enumerate(selected):
        for col, direction in enumerate(DIRECTIONS):
            tile = Image.open(frame_index[(direction, frame)]).convert("RGBA")
            sheet.alpha_composite(tile, (col * 128, row * (128 + label_h) + label_h))
            tile.close()
            draw.text((col * 128 + 4, row * (128 + label_h) + 3), f"{direction} / {frame:04d}", fill="white")
    contact_path = review_dir / "neutral_idle_eight_direction_contact_sheet.png"
    sheet.save(contact_path)
    qa["review_samples"] = selected
    qa_path = root / "qa/neutral_idle_technical_qa.v1.json"
    qa_path.parent.mkdir(parents=True, exist_ok=True)
    qa_public = {key: value for key, value in qa.items() if key != "_frames"}
    # Add exact output hashes, without loading all frames into memory at once.
    qa_public["frame_hashes"] = {direction: [{"source_frame": item["source_frame"], "path": item["path"], "sha256": item["sha256"]}
                                             for item in qa["_frames"][direction]] for direction in DIRECTIONS}
    qa_bytes = json.dumps(qa_public, sort_keys=True, indent=2).encode() + b"\n"
    qa_path.write_bytes(qa_bytes)
    plan_path = root / "qa/neutral_idle_plan.v1.json"
    subprocess.run(["python3", str(repo / "custodian/tools/operator/animation_compiler/cli.py"), "plan",
                    str(manifest_path), "--candidate-only", "--asset-root", str(root), "--repo-root", str(repo)],
                   check=True, stdout=plan_path.open("wb"))
    plan = json.loads(plan_path.read_text())
    plan_id = plan["plan_id"]
    master = json.loads((root / "master_contract.v1.json").read_text())
    proof_path = root / source["source_action"]["inspection_proof_path"]
    direction_receipts = [{"direction": direction, "frames": qa["_frames"][direction]} for direction in DIRECTIONS]
    receipt = {"schema": "custodian.operator_3d_animation_candidate_receipt.v1",
        "candidate_state": "candidate_unapproved", "input_manifest_sha256": sha_file(manifest_path),
        "plan_id": plan_id, "batch_id": manifest["batch_id"], "job_id": plan["jobs"][0]["job_id"],
        "output_path": plan["jobs"][0]["output_path"],
        "master": {"master_id": master["master_id"], "contract_sha256": sha_file(root / "master_contract.v1.json"),
                   "blender_project_sha256": master["blender"]["project_sha256"],
                   "armature_identity_sha256": master["armature"]["identity_sha256"],
                   "rest_pose_sha256": master["armature"]["rest_pose_sha256"],
                   "skeleton_signature_sha256": master["armature"]["skeleton_signature_sha256"]},
        "source": {"animation_id": "neutral_idle", "original_filename": source["source"]["original_filename"],
                   "fbx_sha256": source["source"]["sha256"], "inspection_proof_sha256": sha_file(proof_path),
                   "authored_fps": source["authored_timing"]["fps"], "frame_start": 1, "frame_end": 264,
                   "duration_seconds": source["authored_timing"]["duration_seconds"]},
        "rendering_contract": {"contract_id": "operator_full_body_8dir_128_v1",
            "contract_sha256": manifest["rendering_contract"]["contract_sha256"], "directions": DIRECTIONS,
            "width": 128, "height": 128, "channels": "RGBA", "elevation_degrees": 45,
            "pixels_per_meter": 50, "root_pixel": [64, 106], "scale_policy": "fixed_from_master", "mirroring": False},
        "sampling": {"sampled_frame_indices": frames_expected,
            "loop_endpoint_policy": source["sampling"]["loop_endpoint_policy"], "source_timing_preserved": True,
            "runtime_timing_authority": {"status": "unavailable", "sha256": None}},
        "root_motion": {"policy": "extract_to_metadata", "source_state": "present",
            "original_trajectory_path": rel(root, trajectory_path), "original_trajectory_sha256": sha_file(trajectory_path),
            "pose_root_translation": "removed", "godot_application": "trajectory_once_separately"},
        "directions": direction_receipts,
        "diagnostics": [],
        "technical_qa": {"state": qa_public["status"], "report_path": rel(root, qa_path), "report_sha256": sha_file(qa_path)},
        "production_approval": {"approved": False, "authority": "human_asset_review_and_separate_ingress"},
        "dependencies": []}
    deps = receipt["dependencies"]
    add_dep(deps, root, "fbx", root / "inputs/Neutral Idle.fbx")
    add_dep(deps, root, "blender_project", root / "inputs/operator_run_mixamo_iter005_contact_ik.blend")
    add_dep(deps, root, "inspection_proof", proof_path)
    add_dep(deps, root, "blender_inventory", root / "inspection/blender_inventory.v1.json")
    add_dep(deps, root, "master_contract", root / "master_contract.v1.json")
    add_dep(deps, root, "armature", root / "inspection/identity/armature_identity.json")
    add_dep(deps, root, "armature", root / "inspection/identity/armature_rest_pose.json")
    add_dep(deps, root, "armature", root / "inspection/identity/skeleton_signature.json")
    add_dep(deps, root, "mesh", root / "inspection/identity/mesh_identity.json")
    add_dep(deps, root, "material", root / "inspection/identity/material_identity.json")
    for texture in master["textures"]:
        add_dep(deps, root, "texture", root / texture["path"])
    add_dep(deps, root, "retarget_policy", root / "policies/retarget_policy_v1.json")
    add_dep(deps, root, "retarget_policy", repo / "custodian/tools/operator/animation_compiler/contracts/retarget_policy_v1.json", "repository", repo)
    add_dep(deps, root, "retarget_policy", repo / "custodian/tools/operator/animation_compiler/contracts/neutral_idle_mapping_policy_v1.json", "repository", repo)
    add_dep(deps, root, "rendering_contract", repo / "custodian/tools/operator/animation_compiler/contracts/full_body_8dir_128_v1.json", "repository", repo)
    add_dep(deps, root, "retargeted_motion", motion_path)
    add_dep(deps, root, "retargeted_motion", repeat_motion_path)
    add_dep(deps, root, "root_trajectory", trajectory_path)
    add_dep(deps, root, "skeleton_mapping", mapping_path)
    add_dep(deps, root, "rendering_metadata", metadata_path)
    add_dep(deps, root, "technical_qa_report", qa_path)
    add_dep(deps, root, "diagnostic_render", contact_path)
    for gif_path in gif_paths:
        add_dep(deps, root, "diagnostic_render", gif_path)
    for item in repeat_results:
        add_dep(deps, root, "diagnostic_render", root / item["repeat_path"])
    for direction in DIRECTIONS:
        for item in qa["_frames"][direction]:
            deps.append({"kind": "candidate_frame", "path": item["path"], "sha256": item["sha256"], "scope": "asset_root"})
    receipt_path = root / "candidate/neutral_idle_candidate_receipt.v1.json"
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    receipt_path.write_bytes(json.dumps(receipt, sort_keys=True, indent=2).encode() + b"\n")
    print(json.dumps({"candidate_state": receipt["candidate_state"], "technical_qa": qa_public["status"],
        "receipt": str(receipt_path), "receipt_sha256": sha_file(receipt_path), "contact_sheet": str(contact_path),
        "gif_previews": [str(path) for path in gif_paths], "frame_count_per_direction": len(frames_expected),
        "root_projection": metadata["registered_root_pixels"]}, sort_keys=True))


if __name__ == "__main__":
    main()
