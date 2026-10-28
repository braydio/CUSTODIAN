#!/usr/bin/env python3
"""Focused contract and dry-run tests; synthetic bytes are not real animation proof."""
from __future__ import annotations

import copy
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
COMPILER_DIR = REPO / "custodian/tools/operator/animation_compiler"
sys.path.insert(0, str(COMPILER_DIR))
import cli as compiler  # noqa: E402

RENDER_PATH = COMPILER_DIR / "contracts/full_body_8dir_128_v1.json"
RETARGET_PATH = COMPILER_DIR / "contracts/retarget_policy_v1.json"
DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def fixture(frame_count: int = 12, *, action: str = "idle_test") -> tuple[tempfile.TemporaryDirectory, Path, dict]:
    temp = tempfile.TemporaryDirectory(prefix="operator-3d-compiler-fixture-")
    root = Path(temp.name)
    (root / "neutral_idle.fbx").write_bytes(b"synthetic test fixture bytes; not an FBX")
    (root / "master.blend").write_bytes(b"synthetic test fixture bytes; not a Blender file")
    (root / "albedo.texture").write_bytes(b"synthetic texture dependency bytes")
    (root / "retarget_policy.json").write_bytes(RETARGET_PATH.read_bytes())
    source_hash = compiler.digest_file(root / "neutral_idle.fbx")
    model_hash = compiler.digest_file(root / "master.blend")
    texture_hash = compiler.digest_file(root / "albedo.texture")
    policy_hash = compiler.digest_file(root / "retarget_policy.json")
    render_hash = compiler.digest_file(RENDER_PATH)
    skeleton_hash = sha(b"synthetic armature signature")
    rest_hash = sha(b"synthetic rest pose")
    identity_hash = sha(b"synthetic armature identity")
    mesh_hash = sha(b"synthetic mesh")
    material_hash = sha(b"synthetic material")
    master_id = "experimental_fixture_master"
    master = {
        "schema": "custodian.operator_3d_master.v1",
        "master_id": master_id,
        "approval_state": "experimental",
        "blender": {"project_path": "master.blend", "project_sha256": model_hash},
        "armature": {"object_name": "FixtureRig", "identity_sha256": identity_hash,
                     "rest_pose_sha256": rest_hash, "skeleton_signature_sha256": skeleton_hash},
        "mesh_materials": [{"mesh_id": "fixture_body", "mesh_sha256": mesh_hash,
                             "material_ids": [{"id": "fixture_material", "sha256": material_hash}]}],
        "textures": [{"path": "albedo.texture", "sha256": texture_hash}],
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0",
                             "config_path": "retarget_policy.json", "config_sha256": policy_hash},
        "camera_registration": {"contract_id": "operator_full_body_8dir_128_v1",
                                 "profile_sha256": render_hash, "elevation_degrees": 45,
                                 "pixels_per_meter": 50, "root_pixel": [64, 106],
                                 "scale_policy": "fixed_from_master", "direction_policy": "independent_no_mirroring"},
    }
    master_path = root / "master_contract.json"
    write_json(master_path, master)
    master_hash = compiler.digest_file(master_path)
    end = frame_count
    fps = 30.0
    duration = frame_count / fps
    proof = {
        "schema": "custodian.operator_fbx_inspection_proof.v1",
        "proof_id": "synthetic-test-proof",
        "evidence_kind": "synthetic_test",
        "inspector_version": "fixture-only",
        "source": {"sha256": source_hash, "importer": "synthetic-test-only", "importer_version": "0",
                   "import_settings_sha256": sha(b"fixture import settings")},
        "master": {"master_id": master_id, "contract_sha256": master_hash,
                   "blender_project_sha256": model_hash, "armature_identity_sha256": identity_hash,
                   "rest_pose_sha256": rest_hash, "skeleton_signature_sha256": skeleton_hash,
                   "mesh_materials_sha256": compiler.digest_bytes(compiler.canonical_bytes(master["mesh_materials"]))},
        "skeleton": {"identity": "SyntheticMixamoRig", "signature_sha256": skeleton_hash},
        "action": {"identity": "Idle", "fps": fps, "frame_start": 1, "frame_end": end,
                   "duration_seconds": duration, "loop_endpoint_duplicate": False},
        "root_motion": {"source_state": "present", "trajectory_sha256": sha(b"synthetic source trajectory samples")},
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0",
                             "config_sha256": compiler.digest_file(RETARGET_PATH)},
        "compatibility": {"result": "compatible", "target_skeleton_signature_sha256": skeleton_hash},
    }
    write_json(root / "inspection.json", proof)
    write_json(root / "runtime_timing.json", {
        "schema": "custodian.operator_runtime_timing_authority.v1",
        "authority_id": "fixture-explicit-runtime-timing",
        "semantic": {"profile": "unarmed", "group": "posture", "action": action},
        "source_sha256": source_hash,
        "master_contract_sha256": master_hash,
        "fps": fps, "loop": True,
    })
    runtime_hash = compiler.digest_file(root / "runtime_timing.json")
    manifest = {
        "schema": "custodian.operator_3d_animation_batch.v1",
        "batch_id": "fixture_batch_001",
        "master_reference": {"availability": "available", "master_id": master_id,
                              "contract_path": "master_contract.json", "contract_sha256": master_hash},
        "rendering_contract": {
            "contract_id": "operator_full_body_8dir_128_v1",
            "contract_path": "custodian/tools/operator/animation_compiler/contracts/full_body_8dir_128_v1.json",
            "contract_sha256": render_hash, "profile_sha256": render_hash,
            "directions": DIRECTIONS, "width": 128, "height": 128, "channels": "RGBA",
            "elevation_degrees": 45, "pixels_per_meter": 50, "root_pixel": [64, 106],
            "scale_policy": "fixed_from_master", "registration_policy": "fixed_root_all_frames",
            "mirroring": False, "diagnostic_size_px": None, "candidate_state": "candidate_unapproved",
        },
        "retarget_policy": {"policy_id": "mixamo_humanoid_conservative", "version": "1.0",
                            "config_path": "custodian/tools/operator/animation_compiler/contracts/retarget_policy_v1.json",
                            "config_sha256": compiler.digest_file(RETARGET_PATH)},
        "output_root": "candidate_output/fixture_batch_001",
        "animations": [{
            "animation_id": "neutral_idle",
            "source": {"availability": "available", "original_filename": "neutral_idle.fbx",
                       "relative_path": "neutral_idle.fbx", "sha256": source_hash,
                       "import_metadata": {"importer": "synthetic-test-only", "importer_version": "0",
                                           "settings_sha256": sha(b"fixture import settings")}},
            "semantic": {"profile": "unarmed", "group": "posture", "action": action, "output_layer": "full_body"},
            "output_path": f"unarmed/posture/{action}/full_body",
            "source_action": {"identity": "Idle", "inspection_proof_path": "inspection.json",
                              "inspection_proof_sha256": compiler.digest_file(root / "inspection.json")},
            "source_skeleton": {"identity": "SyntheticMixamoRig", "signature_sha256": skeleton_hash,
                                "compatibility_proof_id": "synthetic-test-proof"},
            "authored_timing": {"availability": "available", "duration_seconds": duration, "fps": fps,
                                 "frame_start": 1, "frame_end": end},
            "playback": {"classification": "loop", "character_local_impact_direction": None},
            "root_motion": {"source_state": "present", "policy": "extract_to_metadata",
                            "source_trajectory_sha256": sha(b"synthetic source trajectory samples"),
                            "trajectory_retention": "preserve_original_separately",
                            "pose_root_translation": "removed", "godot_application": "trajectory_once_separately"},
            "foot_contact": {"policy": "not_assessed", "evidence_path": None, "evidence_sha256": None},
            "sampling": {"mode": "source_frame_stride", "stride": 1,
                         "loop_endpoint_policy": "include_authored_terminal"},
            "runtime_timing_authority": {"status": "approved", "authority_id": "fixture-explicit-runtime-timing",
                                          "authority_path": "runtime_timing.json", "authority_sha256": runtime_hash,
                                          "fps": fps, "loop": True},
        }],
    }
    manifest_path = root / "batch.json"
    write_json(manifest_path, manifest)
    return temp, manifest_path, manifest


class Operator3DAnimationCompilerTests(unittest.TestCase):
    def setUp(self):
        self.temp, self.manifest_path, self.manifest = fixture()
        self.root = self.manifest_path.parent

    def tearDown(self):
        self.temp.cleanup()

    def validate(self, manifest=None):
        value = manifest or self.manifest
        return compiler._validate_batch(value, self.root, REPO, allow_test_fixtures=True)

    def test_valid_manifest_uses_explicit_synthetic_inspection_fixture(self):
        report = self.validate()
        self.assertTrue(report["valid"], report["errors"])
        self.assertIn("MASTER_EXPERIMENTAL", {item["code"] for item in report["warnings"]})
        proof = json.loads((self.root / "inspection.json").read_text())
        self.assertEqual("synthetic_test", proof["evidence_kind"])

    def test_example_batch_marks_real_inputs_unavailable_without_hashes(self):
        sample_path = COMPILER_DIR / "examples/operator_mixamo_batch_v1.json"
        sample = json.loads(sample_path.read_text())
        self.assertEqual(8, len(sample["animations"]))
        for animation in sample["animations"]:
            self.assertEqual("unavailable", animation["source"]["availability"])
            self.assertIsNone(animation["source"]["sha256"])
            self.assertIsNone(animation["source"]["original_filename"])
        report = compiler._validate_batch(sample, sample_path.parent, REPO)
        codes = {item["code"] for item in report["errors"]}
        self.assertIn("SOURCE_UNAVAILABLE", codes)
        self.assertIn("MASTER_UNAVAILABLE", codes)
        self.assertIn("RUNTIME_TIMING_AUTHORITY_MISSING", codes)

    def test_missing_fbx_is_reported(self):
        (self.root / "neutral_idle.fbx").unlink()
        report = self.validate()
        self.assertIn("SOURCE_MISSING", {item["code"] for item in report["errors"]})

    def test_changed_source_hash_is_reported(self):
        (self.root / "neutral_idle.fbx").write_bytes(b"changed source")
        report = self.validate()
        self.assertIn("SOURCE_HASH_MISMATCH", {item["code"] for item in report["errors"]})

    def test_duplicate_semantic_output_identity_is_rejected(self):
        value = copy.deepcopy(self.manifest)
        duplicate = copy.deepcopy(value["animations"][0])
        duplicate["animation_id"] = "neutral_idle_duplicate"
        duplicate["output_path"] = "unarmed/posture/duplicate/full_body"
        value["animations"].append(duplicate)
        self.assertIn("DUPLICATE_SEMANTIC_OUTPUT", {item["code"] for item in self.validate(value)["errors"]})

    def test_incompatible_skeleton_proof_is_rejected(self):
        proof_path = self.root / "inspection.json"
        proof = json.loads(proof_path.read_text())
        proof["compatibility"]["result"] = "incompatible"
        write_json(proof_path, proof)
        self.manifest["animations"][0]["source_action"]["inspection_proof_sha256"] = compiler.digest_file(proof_path)
        report = self.validate()
        self.assertIn("SKELETON_INCOMPATIBLE", {item["code"] for item in report["errors"]})

    def test_master_model_hash_change_is_reported(self):
        (self.root / "master.blend").write_bytes(b"changed model bytes")
        report = self.validate()
        self.assertIn("MASTER_MODEL_HASH_MISMATCH", {item["code"] for item in report["errors"]})

    def test_unknown_root_motion_policy_is_rejected(self):
        value = copy.deepcopy(self.manifest)
        value["animations"][0]["root_motion"]["policy"] = "guess_from_fbx"
        findings = compiler.schema_findings(value, compiler.BATCH_SCHEMA)
        self.assertTrue(any(item["code"] == "SCHEMA_ENUM" and ".root_motion.policy" in item["path"] for item in findings))

    def test_long_source_ranges_are_not_limited_to_120_frames(self):
        for frame_count in (264, 299):
            timing = self.manifest["animations"][0]["authored_timing"]
            timing["frame_end"] = frame_count
            timing["duration_seconds"] = frame_count / timing["fps"]
            self.assertEqual(frame_count, compiler._sample_count(self.manifest["animations"][0]))
        timing = self.manifest["animations"][0]["authored_timing"]
        timing["frame_end"] = 299
        timing["duration_seconds"] = 299 / timing["fps"]
        proof = json.loads((self.root / "inspection.json").read_text())
        proof["action"]["frame_end"] = 299
        proof["action"]["duration_seconds"] = 299 / timing["fps"]
        write_json(self.root / "inspection.json", proof)
        self.manifest["animations"][0]["source_action"]["inspection_proof_sha256"] = compiler.digest_file(self.root / "inspection.json")
        report = self.validate()
        self.assertTrue(report["valid"], report["errors"])

    def test_job_and_plan_ids_are_deterministic(self):
        first = compiler._build_plan(self.manifest, self.manifest_path, self.root, REPO)
        second = compiler._build_plan(self.manifest, self.manifest_path, self.root, REPO)
        self.assertEqual(first["plan_id"], second["plan_id"])
        self.assertEqual([j["job_id"] for j in first["jobs"]], [j["job_id"] for j in second["jobs"]])
        self.assertEqual(96, first["estimate"]["directional_frame_renders_total"])

    def test_missing_runtime_timing_authority_is_not_inferred_from_source(self):
        runtime = self.manifest["animations"][0]["runtime_timing_authority"]
        runtime.update({"status": "unavailable", "authority_id": None, "authority_path": None,
                        "authority_sha256": None, "fps": None, "loop": None})
        report = self.validate()
        self.assertIn("RUNTIME_TIMING_AUTHORITY_MISSING", {item["code"] for item in report["errors"]})
        self.assertEqual(30.0, self.manifest["animations"][0]["authored_timing"]["fps"])
        self.assertIsNone(runtime["fps"])

    def test_distinct_semantics_cannot_collide_on_output_path(self):
        value = copy.deepcopy(self.manifest)
        duplicate = copy.deepcopy(value["animations"][0])
        duplicate["animation_id"] = "another_semantic"
        duplicate["semantic"]["action"] = "idle_other"
        duplicate["output_path"] = value["animations"][0]["output_path"]
        value["animations"].append(duplicate)
        self.assertIn("OUTPUT_PATH_COLLISION", {item["code"] for item in self.validate(value)["errors"]})

    def test_normalized_output_path_aliases_collide(self):
        value = copy.deepcopy(self.manifest)
        duplicate = copy.deepcopy(value["animations"][0])
        duplicate["animation_id"] = "another_semantic"
        duplicate["semantic"]["action"] = "idle_other"
        duplicate["output_path"] = "unarmed//posture/idle_test/full_body"
        value["animations"].append(duplicate)
        self.assertIn("OUTPUT_PATH_COLLISION", {item["code"] for item in self.validate(value)["errors"]})

    def test_loop_endpoint_can_be_omitted_only_with_inspector_proof(self):
        self.manifest["animations"][0]["sampling"]["loop_endpoint_policy"] = "omit_declared_duplicate_terminal"
        report = self.validate()
        self.assertIn("LOOP_ENDPOINT_NOT_PROVEN_DUPLICATE", {item["code"] for item in report["errors"]})
        proof_path = self.root / "inspection.json"
        proof = json.loads(proof_path.read_text())
        proof["action"]["loop_endpoint_duplicate"] = True
        write_json(proof_path, proof)
        self.manifest["animations"][0]["source_action"]["inspection_proof_sha256"] = compiler.digest_file(proof_path)
        self.assertTrue(self.validate()["valid"])
        self.assertEqual(11, compiler._sample_count(self.manifest["animations"][0]))

    def test_symlink_escape_is_rejected(self):
        outside = self.root.parent / "outside.fbx"
        outside.write_bytes(b"outside")
        try:
            (self.root / "escape.fbx").symlink_to(outside)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        value = copy.deepcopy(self.manifest)
        value["animations"][0]["source"]["relative_path"] = "escape.fbx"
        value["animations"][0]["source"]["original_filename"] = "escape.fbx"
        value["animations"][0]["source"]["sha256"] = compiler.digest_file(outside)
        self.assertIn("PATH_TRAVERSAL", {item["code"] for item in self.validate(value)["errors"]})

    def test_plan_command_does_not_mutate_source_master_or_manifest(self):
        protected = [self.manifest_path, self.root / "neutral_idle.fbx", self.root / "master.blend",
                     self.root / "master_contract.json", self.root / "inspection.json"]
        before = {path: path.read_bytes() for path in protected}
        output_dir = self.root / "candidate_output"
        result = subprocess.run([sys.executable, str(COMPILER_DIR / "cli.py"), "plan", str(self.manifest_path),
                                 "--asset-root", str(self.root)], cwd=REPO, capture_output=True, text=True)
        self.assertEqual(0, result.returncode, result.stderr)
        json.loads(result.stdout)
        self.assertEqual(before, {path: path.read_bytes() for path in protected})
        self.assertFalse(output_dir.exists())

    def test_check_reports_source_drift_without_mutation(self):
        plan = compiler._build_plan(self.manifest, self.manifest_path, self.root, REPO)
        plan_path = self.root / "saved_plan.json"
        write_json(plan_path, plan)
        result, status = compiler.command_check(type("Args", (), {"artifact": plan_path, "manifest": self.manifest_path,
            "asset_root": self.root, "repo_root": REPO})())
        self.assertEqual(0, status)
        self.assertFalse(result["stale"])
        (self.root / "neutral_idle.fbx").write_bytes(b"changed after planning")
        result, status = compiler.command_check(type("Args", (), {"artifact": plan_path, "manifest": self.manifest_path,
            "asset_root": self.root, "repo_root": REPO})())
        self.assertEqual(compiler.EXIT_STALE, status)
        self.assertTrue(result["stale"])
        self.assertIn("DEPENDENCIES_CHANGED", {item["code"] for item in result["changes"]})

    def test_check_cli_reports_current_then_stale_plan(self):
        plan_result = subprocess.run([sys.executable, str(COMPILER_DIR / "cli.py"), "plan", str(self.manifest_path),
                                      "--asset-root", str(self.root)], cwd=REPO, capture_output=True, text=True)
        self.assertEqual(0, plan_result.returncode, plan_result.stderr)
        plan_path = self.root / "cli_plan.json"
        plan_path.write_text(plan_result.stdout, encoding="utf-8")
        command = [sys.executable, str(COMPILER_DIR / "cli.py"), "check", str(plan_path), str(self.manifest_path),
                   "--asset-root", str(self.root)]
        current = subprocess.run(command, cwd=REPO, capture_output=True, text=True)
        self.assertEqual(0, current.returncode, current.stderr)
        self.assertFalse(json.loads(current.stdout)["stale"])
        (self.root / "master.blend").write_bytes(b"model changed after plan")
        stale = subprocess.run(command, cwd=REPO, capture_output=True, text=True)
        self.assertEqual(compiler.EXIT_STALE, stale.returncode)
        self.assertTrue(json.loads(stale.stdout)["stale"])

    def test_check_candidate_receipt_verifies_manifest_and_output_hashes(self):
        plan = compiler._build_plan(self.manifest, self.manifest_path, self.root, REPO)
        job = plan["jobs"][0]
        animation = self.manifest["animations"][0]
        source = animation["source"]
        master = json.loads((self.root / "master_contract.json").read_text())
        trajectory_path = self.root / "trajectory.json"
        trajectory_path.write_bytes(b"synthetic source trajectory samples")
        output_root = job["output_path"]
        direction_entries = []
        for direction in DIRECTIONS:
            frames = []
            for frame_index in range(1, 13):
                relative = f"{output_root}/{direction}/frame_{frame_index:04d}.png"
                frame_path = self.root / relative
                frame_path.parent.mkdir(parents=True, exist_ok=True)
                frame_path.write_bytes(f"synthetic pixel fixture {direction} {frame_index}".encode())
                frames.append({"source_frame": frame_index, "path": relative,
                               "sha256": compiler.digest_file(frame_path), "width": 128, "height": 128, "channels": "RGBA"})
            direction_entries.append({"direction": direction, "frames": frames})
        qa_path = self.root / "qa.json"
        qa_path.write_text('{"fixture_only":true}\n')
        authority_sha = animation["runtime_timing_authority"]["authority_sha256"]
        retarget_path = COMPILER_DIR / "contracts/retarget_policy_v1.json"
        receipt = {
            "schema": "custodian.operator_3d_animation_candidate_receipt.v1",
            "candidate_state": "candidate_unapproved",
            "input_manifest_sha256": plan["input_manifest_sha256"],
            "plan_id": plan["plan_id"], "batch_id": self.manifest["batch_id"], "job_id": job["job_id"],
            "output_path": job["output_path"],
            "master": {"master_id": master["master_id"], "contract_sha256": self.manifest["master_reference"]["contract_sha256"],
                       "blender_project_sha256": master["blender"]["project_sha256"],
                       "armature_identity_sha256": master["armature"]["identity_sha256"],
                       "rest_pose_sha256": master["armature"]["rest_pose_sha256"],
                       "skeleton_signature_sha256": master["armature"]["skeleton_signature_sha256"]},
            "source": {"animation_id": animation["animation_id"], "original_filename": source["original_filename"],
                       "fbx_sha256": source["sha256"], "inspection_proof_sha256": animation["source_action"]["inspection_proof_sha256"],
                       "authored_fps": 30.0, "frame_start": 1, "frame_end": 12, "duration_seconds": 0.4},
            "dependencies": [
                {"kind": "fbx", "path": source["relative_path"], "sha256": source["sha256"], "scope": "asset_root"},
                {"kind": "master_contract", "path": "master_contract.json", "sha256": self.manifest["master_reference"]["contract_sha256"], "scope": "asset_root"},
                {"kind": "blender_project", "path": master["blender"]["project_path"], "sha256": master["blender"]["project_sha256"], "scope": "asset_root"},
                {"kind": "retarget_policy", "path": str(retarget_path.relative_to(REPO)), "sha256": compiler.digest_file(retarget_path), "scope": "repository"},
            ],
            "rendering_contract": {"contract_id": self.manifest["rendering_contract"]["contract_id"],
                                   "contract_sha256": self.manifest["rendering_contract"]["contract_sha256"],
                                   "directions": DIRECTIONS, "width": 128, "height": 128, "channels": "RGBA",
                                   "elevation_degrees": 45, "pixels_per_meter": 50, "root_pixel": [64, 106],
                                   "scale_policy": "fixed_from_master", "mirroring": False},
            "sampling": {"sampled_frame_indices": list(range(1, 13)), "loop_endpoint_policy": "include_authored_terminal",
                         "source_timing_preserved": True,
                         "runtime_timing_authority": {"status": "approved", "sha256": authority_sha}},
            "root_motion": {"policy": "extract_to_metadata", "source_state": "present",
                            "original_trajectory_path": "trajectory.json", "original_trajectory_sha256": compiler.digest_file(trajectory_path),
                            "pose_root_translation": "removed", "godot_application": "trajectory_once_separately"},
            "directions": direction_entries, "diagnostics": [],
            "technical_qa": {"state": "pass", "report_path": "qa.json", "report_sha256": compiler.digest_file(qa_path)},
            "production_approval": {"approved": False, "authority": "human_asset_review_and_separate_ingress"},
        }
        receipt_path = self.root / "candidate_receipt.json"
        write_json(receipt_path, receipt)
        args = type("Args", (), {"artifact": receipt_path, "manifest": self.manifest_path,
                                  "asset_root": self.root, "repo_root": REPO})()
        current, status = compiler.command_check(args)
        self.assertEqual(compiler.EXIT_OK, status, current)
        self.assertFalse(current["stale"])
        changed_frame = self.root / direction_entries[0]["frames"][0]["path"]
        changed_frame.write_bytes(b"changed candidate output")
        current, status = compiler.command_check(args)
        self.assertEqual(compiler.EXIT_STALE, status)
        self.assertIn("CANDIDATE_OUTPUT_HASH_MISMATCH", {item["code"] for item in current["changes"]})

    def test_cli_rejects_synthetic_fixture_proof_as_real_evidence(self):
        result = subprocess.run([sys.executable, str(COMPILER_DIR / "cli.py"), "validate", str(self.manifest_path),
                                 "--asset-root", str(self.root)], cwd=REPO, capture_output=True, text=True)
        self.assertEqual(compiler.EXIT_INVALID, result.returncode)
        report = json.loads(result.stdout)
        self.assertIn("INSPECTION_PROOF_NOT_AUTHORITATIVE", {item["code"] for item in report["errors"]})

    def test_output_contract_documents_full_body_candidate_only_and_eight_views(self):
        candidate_schema = json.loads((COMPILER_DIR / "schemas/candidate_receipt.v1.schema.json").read_text())
        required = set(candidate_schema["required"])
        self.assertTrue({"root_motion", "directions", "diagnostics", "production_approval"}.issubset(required))
        rendering = json.loads(RENDER_PATH.read_text())
        self.assertEqual(DIRECTIONS, rendering["directions"])
        self.assertEqual("full_body_only", rendering["body_policy"])
        self.assertEqual("candidate_unapproved", rendering["approval_state"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
