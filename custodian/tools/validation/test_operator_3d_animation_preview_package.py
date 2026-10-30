from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from custodian.tools.operator.animation_compiler.preview_package import (
	DIRECTIONS,
	PackageError,
	build_package,
	validate_candidate,
)


def _sha(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


class PreviewPackageTests(unittest.TestCase):
	def setUp(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		self.proof = self.root / "proof"
		self.project = self.root / "custodian"
		self.proof.mkdir()
		(self.project / "content").mkdir(parents=True)
		(self.project / "project.godot").write_text("config_version=5\n")
		(self.project / "content" / "canonical.marker").write_text("preserve\n")
		(self.proof / "inputs").mkdir()
		(self.proof / "inputs" / "source.fbx").write_bytes(b"synthetic FBX bytes; not animation proof")
		(self.proof / "inputs" / "master.blend").write_bytes(b"synthetic Blender bytes; not model proof")
		(self.proof / "qa").mkdir()
		(self.proof / "candidate").mkdir()
		self.receipt_path = self.proof / "candidate" / "receipt.json"
		self.qa_path = self.proof / "qa" / "qa.json"
		self._write_fixture(frame_count=3)

	def tearDown(self) -> None:
		self.temp.cleanup()

	def _write_fixture(self, frame_count: int) -> None:
		frame_end = frame_count + 1
		frame_indices = list(range(1, frame_end))
		root_frames = self.proof / "render"
		qa_hashes: dict[str, list[dict[str, object]]] = {}
		direction_rows: list[dict[str, object]] = []
		for direction_index, direction in enumerate(DIRECTIONS):
			rows: list[dict[str, object]] = []
			qa_rows: list[dict[str, object]] = []
			for frame_index in frame_indices:
				path = root_frames / direction / f"{frame_index:04d}.png"
				path.parent.mkdir(parents=True, exist_ok=True)
				color = (direction_index * 19 % 256, frame_index % 256, 120, 255)
				Image.new("RGBA", (128, 128), color).save(path)
				file_sha = _sha(path.read_bytes())
				with Image.open(path) as image:
					pixel_sha = _sha(image.convert("RGBA").tobytes())
				row = {
					"path": path.relative_to(self.proof).as_posix(),
					"sha256": file_sha,
					"source_frame": frame_index,
					"width": 128,
					"height": 128,
					"channels": "RGBA",
				}
				rows.append(row)
				qa_rows.append({"path": row["path"], "sha256": file_sha, "source_frame": frame_index})
			qa_hashes[direction] = qa_rows
			direction_rows.append({"direction": direction, "frames": rows})
		qa = {
			"schema": "custodian.operator_neutral_idle_technical_qa.v1",
			"status": "pass",
			"candidate_state": "candidate_unapproved",
			"production_approval": False,
			"source": {
				"fps": 30,
				"loop_endpoint_duplicate": True,
				"rendered_frame_indices": frame_indices,
			},
			"frame_hashes": qa_hashes,
			"render_contract": {"root_pixel": [64, 106]},
			"registered_root_pixels": {direction: [64.0, 106.0] for direction in DIRECTIONS},
		}
		self.qa_path.write_text(json.dumps(qa, sort_keys=True))
		source_hash = _sha((self.proof / "inputs" / "source.fbx").read_bytes())
		master_hash = _sha((self.proof / "inputs" / "master.blend").read_bytes())
		qa_hash = _sha(self.qa_path.read_bytes())
		dependencies = [
			{"kind": "fbx", "path": "inputs/source.fbx", "sha256": source_hash},
			{"kind": "blender_project", "path": "inputs/master.blend", "sha256": master_hash},
			{"kind": "technical_qa_report", "path": "qa/qa.json", "sha256": qa_hash},
		]
		receipt = {
			"schema": "custodian.operator_3d_animation_candidate_receipt.v1",
			"job_id": "fixture-job-001",
			"candidate_version": "fixture-neutral-idle-v2",
			"candidate_state": "candidate_unapproved",
			"production_approval": {"approved": False},
			"source": {
				"animation_id": "neutral_idle_fixture",
				"original_filename": "source.fbx",
				"fbx_sha256": source_hash,
				"authored_fps": 30,
				"frame_start": 1,
				"frame_end": frame_end,
			},
			"master": {"blender_project_sha256": master_hash},
			"dependencies": dependencies,
			"technical_qa": {"report_path": "qa/qa.json", "report_sha256": qa_hash, "state": "pass"},
			"rendering_contract": {
				"contract_id": "operator_full_body_8dir_128_v1",
				"directions": list(DIRECTIONS),
				"width": 128,
				"height": 128,
				"channels": "RGBA",
				"mirroring": False,
				"scale_policy": "fixed_from_master",
			},
			"sampling": {
				"source_timing_preserved": True,
				"loop_endpoint_policy": "omit_declared_duplicate_terminal",
			},
			"directions": direction_rows,
		}
		self.receipt_path.write_text(json.dumps(receipt, sort_keys=True))

	def test_valid_candidate_builds_hash_bound_ignored_package(self) -> None:
		result = build_package(self.proof, self.project, Path("candidate/receipt.json"), run_import=False)
		package = self.project / ".ai" / "operator_3d_animation_preview" / result["package_path"].split("/")[-1]
		request = json.loads((package / "request.json").read_text())
		self.assertTrue((self.project / ".ai").is_dir())
		self.assertEqual(request["candidate_state"], "candidate_unapproved")
		self.assertFalse(request["production_approval"])
		self.assertFalse(request["timing_authority_granted"])
		self.assertEqual(request["candidate_version"], "fixture-neutral-idle-v2")
		self.assertEqual(request["source"]["authored_fps"], 30)
		self.assertEqual([item["direction"] for item in request["directions"]], list(DIRECTIONS))
		self.assertEqual((self.project / "content" / "canonical.marker").read_text(), "preserve\n")
		self.assertEqual(len(list((self.project / ".ai").rglob("*.png"))), 24)

	def test_awakening_smoke_selection_is_recorded_in_preview_request(self) -> None:
		result = build_package(
			self.proof,
			self.project,
			Path("candidate/receipt.json"),
			run_import=False,
			smoke_script="res://tools/validation/operator_3d_animation_preview_awakening_smoke.gd",
		)
		package = self.project / ".ai" / "operator_3d_animation_preview" / result["package_path"].split("/")[-1]
		request = json.loads((package / "request.json").read_text())
		self.assertEqual(request["preview_scene"], "res://scenes/debug/operator_3d_animation_preview_awakening.tscn")

	def test_repeat_package_is_deterministic_and_reuses_exact_output(self) -> None:
		first = build_package(self.proof, self.project, Path("candidate/receipt.json"), run_import=False)
		second = build_package(self.proof, self.project, Path("candidate/receipt.json"), run_import=False)
		self.assertEqual(first["request_sha256"], second["request_sha256"])
		self.assertEqual(first["package_path"], second["package_path"])

	def test_long_source_range_over_two_hundred_frames_is_supported(self) -> None:
		self._write_fixture(frame_count=263)
		receipt, qa, source, _master = validate_candidate(self.proof, Path("candidate/receipt.json"))
		self.assertEqual(source["frame_end"] - source["frame_start"], 263)
		self.assertEqual(len(qa["source"]["rendered_frame_indices"]), 263)
		self.assertEqual(receipt["candidate_state"], "candidate_unapproved")

	def test_missing_frame_is_rejected(self) -> None:
		(self.proof / "render" / "N" / "0002.png").unlink()
		with self.assertRaisesRegex(PackageError, "missing"):
			validate_candidate(self.proof, Path("candidate/receipt.json"))

	def test_changed_frame_hash_is_rejected(self) -> None:
		path = self.proof / "render" / "N" / "0001.png"
		path.write_bytes(path.read_bytes() + b"changed")
		with self.assertRaisesRegex(PackageError, "bytes differ"):
			validate_candidate(self.proof, Path("candidate/receipt.json"))

	def test_path_traversal_is_rejected(self) -> None:
		data = json.loads(self.receipt_path.read_text())
		data["directions"][0]["frames"][0]["path"] = "../outside.png"
		self.receipt_path.write_text(json.dumps(data))
		with self.assertRaisesRegex(PackageError, "unsafe relative path"):
			validate_candidate(self.proof, Path("candidate/receipt.json"))

	def test_duplicate_direction_is_rejected(self) -> None:
		data = json.loads(self.receipt_path.read_text())
		data["directions"][1]["direction"] = "N"
		self.receipt_path.write_text(json.dumps(data))
		with self.assertRaisesRegex(PackageError, "exactly eight"):
			validate_candidate(self.proof, Path("candidate/receipt.json"))

	def test_approved_or_timing_authority_receipt_is_rejected(self) -> None:
		data = json.loads(self.receipt_path.read_text())
		data["production_approval"]["approved"] = True
		self.receipt_path.write_text(json.dumps(data))
		with self.assertRaisesRegex(PackageError, "unapproved"):
			validate_candidate(self.proof, Path("candidate/receipt.json"))


if __name__ == "__main__":
	unittest.main()
