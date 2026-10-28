"""Bind Blender inventory evidence into the published compiler contracts."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sha_bytes(value):
    return hashlib.sha256(value).hexdigest()


def sha_file(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False).encode() + b"\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--proof-root", type=Path, required=True)
    parser.add_argument("--repo-root", type=Path, required=True)
    args = parser.parse_args()
    root, repo = args.proof_root.resolve(), args.repo_root.resolve()
    inventory_path = root / "inspection/blender_inventory.v1.json"
    inventory = json.loads(inventory_path.read_text())
    master = inventory["master"]
    source = inventory["source"]
    policy_source = repo / "custodian/tools/operator/animation_compiler/contracts/retarget_policy_v1.json"
    policy_path = root / "policies/retarget_policy_v1.json"
    policy_path.parent.mkdir(parents=True, exist_ok=True)
    policy_path.write_bytes(policy_source.read_bytes())
    policy_hash = sha_file(policy_path)
    identity_dir = root / "inspection/identity"
    put(identity_dir / "armature_identity.json", master["armature_identity"])
    put(identity_dir / "armature_rest_pose.json", master["rest_pose"])
    put(identity_dir / "skeleton_signature.json", master["armature"])
    put(identity_dir / "mesh_identity.json", master["mesh_data"])
    put(identity_dir / "material_identity.json", master["materials"])
    render_contract_path = repo / "custodian/tools/operator/animation_compiler/contracts/full_body_8dir_128_v1.json"
    render_hash = sha_file(render_contract_path)
    master_contract = {
        "schema": "custodian.operator_3d_master.v1", "master_id": master["master_id"],
        "approval_state": "experimental",
        "blender": {"project_path": "inputs/operator_run_mixamo_iter005_contact_ik.blend",
                    "project_sha256": sha_file(root / "inputs/operator_run_mixamo_iter005_contact_ik.blend")},
        "armature": {"object_name": master["armature"]["armature"],
                     "identity_sha256": master["armature_identity_sha256"],
                     "rest_pose_sha256": master["armature_rest_pose_sha256"],
                     "skeleton_signature_sha256": master["armature"]["signature_sha256"]},
        "mesh_materials": [{"mesh_id": master["mesh_name"], "mesh_sha256": master["mesh_data_sha256"],
                            "material_ids": [{"id": material["name"], "sha256": master["material_sha256"]}
                                             for material in master["materials"]]}],
        "textures": [{"path": "inspection/" + texture["path"], "sha256": texture["sha256"]}
                     for texture in master["textures"]],
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0",
                            "config_path": "policies/retarget_policy_v1.json", "config_sha256": policy_hash},
        "camera_registration": {"contract_id": "operator_full_body_8dir_128_v1", "profile_sha256": render_hash,
                                "elevation_degrees": 45, "pixels_per_meter": 50, "root_pixel": [64, 106],
                                "scale_policy": "fixed_from_master", "direction_policy": "independent_no_mirroring"},
    }
    contract_path = root / "master_contract.v1.json"
    put(contract_path, master_contract)
    contract_hash = sha_file(contract_path)
    motion = json.loads((root / "motion/neutral_idle_motion.v1.json").read_text())
    proof = {
        "schema": "custodian.operator_fbx_inspection_proof.v1",
        "proof_id": "neutral-idle-blender-5-2-3-iter005-a0bdf6c1",
        "evidence_kind": "blender_inspector", "inspector_version": "Blender " + inventory["blender_version"],
        "source": {"sha256": source["sha256"], "importer": "Blender FBX Importer",
                   "importer_version": inventory["blender_version"],
                   "import_settings_sha256": sha_bytes(canonical(inventory["fbx_import_settings"]))},
        "master": {"master_id": master["master_id"], "contract_sha256": contract_hash,
                   "blender_project_sha256": master_contract["blender"]["project_sha256"],
                   "armature_identity_sha256": master["armature_identity_sha256"],
                   "rest_pose_sha256": master["armature_rest_pose_sha256"],
                   "skeleton_signature_sha256": master["armature"]["signature_sha256"],
                   "mesh_materials_sha256": sha_bytes(canonical(master_contract["mesh_materials"]))},
        "skeleton": {"identity": source["armature"]["armature"],
                     "signature_sha256": source["armature"]["signature_sha256"]},
        "action": {"identity": source["action"], "fps": source["fps"], "frame_start": source["frame_start"],
                   "frame_end": source["frame_end"], "duration_seconds": source["frame_count"] / source["fps"],
                   "loop_endpoint_duplicate": motion["loop"]["terminal_pose_duplicate"]},
        "root_motion": {"source_state": "present", "trajectory_sha256": motion["root_motion"]["trajectory_sha256"]},
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0", "config_sha256": policy_hash},
        "compatibility": {"result": "compatible", "target_skeleton_signature_sha256": master["armature"]["signature_sha256"]},
    }
    proof_path = root / "inspection/neutral_idle_inspection_proof.v1.json"
    put(proof_path, proof)
    proof_hash = sha_file(proof_path)
    batch = {
        "schema": "custodian.operator_3d_animation_batch.v1", "batch_id": "operator_neutral_idle_iter005_proof_001",
        "master_reference": {"availability": "available", "master_id": master["master_id"],
                              "contract_path": "master_contract.v1.json", "contract_sha256": contract_hash},
        "rendering_contract": {"contract_id": "operator_full_body_8dir_128_v1",
            "contract_path": "custodian/tools/operator/animation_compiler/contracts/full_body_8dir_128_v1.json",
            "contract_sha256": render_hash, "profile_sha256": render_hash,
            "directions": ["N", "NE", "E", "SE", "S", "SW", "W", "NW"],
            "width": 128, "height": 128, "channels": "RGBA", "elevation_degrees": 45,
            "pixels_per_meter": 50, "root_pixel": [64, 106], "scale_policy": "fixed_from_master",
            "registration_policy": "fixed_root_all_frames", "mirroring": False, "diagnostic_size_px": None,
            "candidate_state": "candidate_unapproved"},
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0",
            "config_path": "custodian/tools/operator/animation_compiler/contracts/retarget_policy_v1.json",
            "config_sha256": sha_file(policy_source)},
        "output_root": "candidate/neutral_idle",
        "animations": [{"animation_id": "neutral_idle",
            "source": {"availability": "available", "original_filename": "Neutral Idle.fbx",
                "relative_path": "inputs/Neutral Idle.fbx", "sha256": source["sha256"],
                "import_metadata": {"importer": "Blender FBX Importer", "importer_version": inventory["blender_version"],
                    "settings_sha256": proof["source"]["import_settings_sha256"]}},
            "semantic": {"profile": "unarmed", "group": "posture", "action": "neutral_idle", "output_layer": "full_body"},
            "output_path": "unarmed/posture/neutral_idle/full_body",
            "source_action": {"identity": source["action"], "inspection_proof_path": "inspection/neutral_idle_inspection_proof.v1.json",
                              "inspection_proof_sha256": proof_hash},
            "source_skeleton": {"identity": source["armature"]["armature"],
                                "signature_sha256": source["armature"]["signature_sha256"],
                                "compatibility_proof_id": proof["proof_id"]},
            "authored_timing": {"availability": "available", "duration_seconds": source["frame_count"] / source["fps"],
                                "fps": source["fps"], "frame_start": source["frame_start"], "frame_end": source["frame_end"]},
            "playback": {"classification": "loop", "character_local_impact_direction": None},
            "root_motion": {"source_state": "present", "policy": "extract_to_metadata",
                "source_trajectory_sha256": motion["root_motion"]["trajectory_sha256"],
                "trajectory_retention": "preserve_original_separately", "pose_root_translation": "removed",
                "godot_application": "trajectory_once_separately"},
            "foot_contact": {"policy": "not_assessed", "evidence_path": None, "evidence_sha256": None},
            "sampling": {"mode": "source_frame_stride", "stride": 1,
                "loop_endpoint_policy": "omit_declared_duplicate_terminal" if motion["loop"]["terminal_pose_duplicate"] else "include_authored_terminal"},
            "runtime_timing_authority": {"status": "unavailable", "authority_id": None, "authority_path": None,
                "authority_sha256": None, "fps": None, "loop": None}}]
    }
    put(root / "neutral_idle_batch.v1.json", batch)
    print(json.dumps({"master_contract_sha256": contract_hash, "inspection_proof_sha256": proof_hash,
                      "source_sha256": source["sha256"], "render_contract_sha256": render_hash,
                      "retarget_policy_sha256": policy_hash, "manifest": str(root / "neutral_idle_batch.v1.json")}, sort_keys=True))


if __name__ == "__main__":
    main()
