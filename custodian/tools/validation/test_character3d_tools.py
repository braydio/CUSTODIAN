"""Unit tests for the repository-owned character 3D tooling.

Dependency-free (unittest). Run from the repository root:
  python3 -I -m unittest custodian/tools/validation/test_character3d_tools.py -v

Covers: contract validation (accept and reject), the Pursuit Frame stager's placement and
clearance rules, the Operator stager's path parameterisation, pipeline command planning, input
hash verification, and consistency between the contracts and any staged manifest.
"""
import copy
import hashlib
import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[3]
TOOLS = REPO / "custodian/tools/character3d"
CONTRACTS = TOOLS / "contracts"


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_contract = _load("validate_contract", TOOLS / "validate_contract.py")
pipeline = _load("pipeline", TOOLS / "pipeline.py")
pf_stage = _load("pursuit_frame_stage", TOOLS / "stage/pursuit_frame_stage.py")


def _good_pursuit_contract() -> dict:
    return json.loads((CONTRACTS / "pursuit_frame.v1.json").read_text())


class ContractValidationTests(unittest.TestCase):
    def test_shipped_contracts_are_valid(self):
        schema = validate_contract.load_schema()
        for name in ("pursuit_frame.v1.json", "operator.v1.json"):
            contract = json.loads((CONTRACTS / name).read_text())
            self.assertEqual(validate_contract.validate(contract, schema), [], name)

    def test_missing_required_key_is_rejected(self):
        contract = _good_pursuit_contract()
        del contract["registration"]
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("missing required key 'registration'" in e for e in errors), errors)

    def test_mirroring_is_rejected(self):
        contract = _good_pursuit_contract()
        contract["directions"]["mirroring"] = True
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("mirroring" in e and "must equal" in e for e in errors), errors)

    def test_direction_order_is_enforced(self):
        contract = _good_pursuit_contract()
        contract["directions"]["order"] = ["S", "E", "SE", "NE", "N", "NW", "W", "SW"]
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("order" in e for e in errors), errors)

    def test_malformed_hash_is_rejected(self):
        contract = _good_pursuit_contract()
        contract["source"]["master"]["sha256"] = "XYZ"
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("sha256" in e and "does not match" in e for e in errors), errors)

    def test_unknown_key_is_rejected(self):
        contract = _good_pursuit_contract()
        contract["surprise"] = 1
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("unexpected key 'surprise'" in e for e in errors), errors)

    def test_status_enum_is_enforced(self):
        contract = _good_pursuit_contract()
        contract["status"] = "promoted"
        errors = validate_contract.validate(contract, validate_contract.load_schema())
        self.assertTrue(any("must be one of" in e for e in errors), errors)

    def test_unimplemented_schema_keyword_fails_loudly(self):
        with self.assertRaises(ValueError):
            validate_contract.validate({}, {"anyOf": [{"type": "object"}]})

    def test_excluded_motion_may_have_null_hash(self):
        contract = _good_pursuit_contract()
        self.assertIsNone(contract["source"]["motions"]["minstrel_static_mesh"]["sha256"])
        self.assertEqual(validate_contract.validate(contract, validate_contract.load_schema()), [])


class PursuitStageTests(unittest.TestCase):
    def _frame(self, size, blocks):
        arr = np.zeros((size[1], size[0], 4), dtype=np.uint8)
        for (x0, y0, x1, y1) in blocks:
            arr[y0:y1, x0:x1] = (200, 100, 50, 255)
        return Image.fromarray(arr, "RGBA")

    def test_place_is_pixel_exact_and_shifts_root(self):
        src = self._frame((256, 256), [(120, 200, 136, 212)])
        cls = {"width": 256, "height": 256, "root": [128, 180]}
        out = np.array(pf_stage.place(src, [128, 212], cls))
        # source root (128,212) moves to class root (128,180): content shifts up by 32 px
        block = np.argwhere(np.array(src)[:, :, 3] > 0)
        moved = np.argwhere(out[:, :, 3] > 0)
        self.assertEqual(moved.min(axis=0)[0], block.min(axis=0)[0] - 32)
        self.assertEqual(int(out[:, :, 3].sum()), int(np.array(src)[:, :, 3].sum()))

    def test_clearance_rejects_content_touching_the_edge(self):
        inside = self._frame((256, 256), [(100, 100, 150, 150)])
        touching = self._frame((256, 256), [(0, 100, 20, 150)])
        self.assertTrue(pf_stage.clearance_ok(inside))
        self.assertFalse(pf_stage.clearance_ok(touching))

    def test_choose_class_prefers_standard_and_falls_back_to_extended(self):
        small = [self._frame((256, 256), [(120, 80, 136, 200)])]
        tall = [self._frame((256, 256), [(120, 30, 136, 220)])]
        self.assertEqual(pf_stage.choose_class(small, [128, 212])["id"], "standard_256x256")
        # Content hangs 236 px below a root at y=20: below every class's bottom margin (max 104 px).
        self.assertIsNone(pf_stage.choose_class(
            [self._frame((256, 256), [(120, 0, 136, 256)])], [128, 20]))

    def test_crop_and_pad_keep_every_visible_pixel(self):
        src = self._frame((256, 256), [(0, 0, 256, 60)])
        cls = {"width": 256, "height": 320, "root": [128, 216]}
        placed = np.array(pf_stage.place(src, [128, 212], cls))
        self.assertEqual(int(placed[:, :, 3].sum()), int(np.array(src)[:, :, 3].sum()))


class OperatorStageTests(unittest.TestCase):
    def test_no_machine_specific_paths_remain(self):
        text = (TOOLS / "stage/operator_stage.py").read_text()
        self.assertIsNone(re.search(r"/home/|Projects/CUSTODIAN", text))

    def test_paths_are_required_arguments(self):
        operator_stage = _load("operator_stage", TOOLS / "stage/operator_stage.py")
        with self.assertRaises(SystemExit):
            operator_stage.main([])


class PipelinePlanningTests(unittest.TestCase):
    def setUp(self):
        self.contract = _good_pursuit_contract()
        self.workspace = Path("/tmp/example-workspace")

    def test_render_plan_uses_object_root_mode_and_contract_density(self):
        cmds = pipeline.commands_for("render", self.contract, self.workspace, None)
        self.assertEqual(len(cmds), 11)
        label, argv, _ = cmds[0]
        self.assertIn("--root-mode", argv)
        self.assertEqual(argv[argv.index("--root-mode") + 1], "object")
        self.assertEqual(argv[argv.index("--ppm") + 1], "80")

    def test_clean_plan_covers_each_source_canvas_once(self):
        cmds = pipeline.commands_for("clean", self.contract, self.workspace, None)
        self.assertEqual(sorted(label for label, _, _ in cmds), ["c256", "c512"])

    def test_unknown_character_cannot_reuse_another_stager(self):
        contract = copy.deepcopy(self.contract)
        contract["character_id"] = "new_character"
        with self.assertRaises(SystemExit):
            pipeline.commands_for("stage", contract, self.workspace, None)

    def test_operator_stage_requires_explicit_batch(self):
        contract = json.loads((CONTRACTS / "operator.v1.json").read_text())
        with self.assertRaises(SystemExit):
            pipeline.commands_for("stage", contract, self.workspace, None, batch=None)

    def test_verify_inputs_detects_mismatch_and_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "inputs/animations").mkdir(parents=True)
            (root / "inputs/character_master.glb").write_bytes(b"master")
            contract = copy.deepcopy(self.contract)
            contract["source"]["master"]["sha256"] = hashlib.sha256(b"master").hexdigest()
            lines = pipeline.verify_inputs(contract, root)
            self.assertTrue(lines[0].startswith("OK"), lines[0])
            self.assertTrue(any(line.startswith("MISSING") for line in lines))
            (root / "inputs/animations/running.glb").write_bytes(b"not the recorded bytes")
            lines = pipeline.verify_inputs(contract, root)
            self.assertTrue(any(line.startswith("MISMATCH") and "running" in line for line in lines), lines)


class StagedConsistencyTests(unittest.TestCase):
    """Skipped unless the staging step has been run in this checkout (custodian/.ai is gitignored)."""

    def test_pursuit_contract_matches_staged_manifest(self):
        manifest = REPO / "custodian/.ai/pursuit_frame_3d_preview/manifest.json"
        if not manifest.is_file():
            self.skipTest("run pipeline.py stage for pursuit_frame first")
        staged = json.loads(manifest.read_text())
        contract = _good_pursuit_contract()
        for action, spec in contract["actions"].items():
            self.assertEqual(spec["viewport"], staged["actions"][action]["viewport"], action)
            self.assertEqual(spec["frame_count"], staged["actions"][action]["frame_count"], action)


if __name__ == "__main__":
    unittest.main()
