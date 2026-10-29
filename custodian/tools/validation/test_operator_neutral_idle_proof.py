"""Focused pure-contract tests; fixtures here are not claimed as FBX proof."""
from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parents[1] / "operator/animation_compiler"
sys.path.insert(0, str(MODULE_DIR))
from neutral_idle_proof_contract import blender_quaternion, sampled_frames, validate_mapping, validate_motion  # noqa: E402
from retarget_calibration import (calibrated_target_world_xyzw, multiply_xyzw, source_ground_contact_indices,
                                  stable_contact_frame_indices)  # noqa: E402
from finalize_neutral_idle_candidate import decoded_rgba_equal  # noqa: E402
from PIL import Image  # noqa: E402


def motion_fixture():
    names = ["mixamorig:Hips", "mixamorig:Spine"]
    identity = {"location": [0, 0, 0], "rotation_xyzw": [0, 0, 0, 1], "scale": [1, 1, 1]}
    return {"schema": "custodian.operator_retargeted_motion.v1",
        "source": {"frame_start": 1, "frame_end": 2, "frame_count": 2},
        "target_rig": {"bone_names": names},
        "root_motion": {"policy": "extract_to_metadata", "sprite_pose_root_translation": "removed",
                         "godot_application": "metadata_only_never_apply"},
        "frames": [{"source_frame": frame, "bones": {name: copy.deepcopy(identity) for name in names}}
                   for frame in (1, 2)]}


class NeutralIdleProofContractTests(unittest.TestCase):
    def test_stable_contact_uses_both_endpoints_of_stable_steps(self):
        self.assertEqual({0, 1, 2}, stable_contact_frame_indices([(0, 0, 0), (0, 0, 0.001), (0, 0, 0.003)]))
        self.assertEqual(set(), stable_contact_frame_indices([(0, 0, 0), (0, 0, 0.006)]))
        self.assertEqual({0, 2}, source_ground_contact_indices({0, 1, 2}, [0.01, 0.08, 0.04]))

    def test_fixed_reference_maps_reference_to_target_rest(self):
        source_reference = (0.0, 0.0, 0.7071067812, 0.7071067812)
        target_rest = (0.5, 0.5, 0.5, 0.5)
        mapped = calibrated_target_world_xyzw(source_reference, source_reference, target_rest)
        self.assertAlmostEqual(1.0, abs(sum(a*b for a, b in zip(mapped, target_rest))), places=7)

    def test_fixed_reference_preserves_source_world_delta(self):
        source_reference = (0.0, 0.0, 0.7071067812, 0.7071067812)
        target_rest = (0.5, 0.5, 0.5, 0.5)
        source_delta = (0.0, 0.3826834324, 0.0, 0.9238795325)
        source_pose = multiply_xyzw(source_delta, source_reference)
        mapped = calibrated_target_world_xyzw(source_pose, source_reference, target_rest)
        expected = multiply_xyzw(source_delta, target_rest)
        self.assertAlmostEqual(1.0, abs(sum(a*b for a, b in zip(mapped, expected))), places=7)

    def test_exact_decoded_rgba_comparison_detects_rgb_changes_with_identical_alpha(self):
        left = Image.new("RGBA", (2, 1), (12, 34, 56, 0))
        right = Image.new("RGBA", (2, 1), (210, 34, 56, 0))
        self.assertFalse(decoded_rgba_equal(left, right))
        self.assertTrue(decoded_rgba_equal(left, left.copy()))

    def test_long_authored_range_and_duplicate_loop_endpoint(self):
        self.assertEqual(263, len(sampled_frames(1, 264, True)))
        self.assertEqual(264, len(sampled_frames(1, 264, False)))
        self.assertEqual(300, len(sampled_frames(1, 300, False)))

    def test_mapping_partitions_direct_inherited_and_ignored_bones(self):
        common = [f"bone_{index}" for index in range(20)]
        validate_mapping(common + ["finger"], common + ["extra"], common, ["extra"], ["finger"],
                         allowed_inherited=["extra"], allowed_unmapped_source=["finger"])
        with self.assertRaisesRegex(ValueError, "OVERLAP|PARTITION"):
            validate_mapping(common + ["finger"], common + ["extra"], common + ["extra"], ["extra"], ["finger"])
        with self.assertRaisesRegex(ValueError, "UNAPPROVED_SOURCE_GAP"):
            validate_mapping(common + ["finger", "toe"], common + ["extra"], common, ["extra"], ["finger", "toe"],
                             allowed_inherited=["extra"], allowed_unmapped_source=["finger"])

    def test_motion_contract_separates_root_trajectory_and_model_dependencies(self):
        validate_motion(motion_fixture())
        invalid = motion_fixture()
        invalid["master_sha256"] = "a" * 64
        with self.assertRaisesRegex(ValueError, "MODEL_DEPENDENCY"):
            validate_motion(invalid)
        invalid = motion_fixture()
        invalid["frames"][0]["bones"]["mixamorig:Hips"]["location"] = [0, 0, 0.1]
        with self.assertRaisesRegex(ValueError, "ROOT_MOTION_PRESENT"):
            validate_motion(invalid)

    def test_action_source_frame_range_is_not_truncated(self):
        value = motion_fixture()
        value["source"].update({"frame_start": 1, "frame_end": 264, "frame_count": 264})
        value["frames"] = [{"source_frame": frame, "bones": {
            name: {"location": [0, 0, 0], "rotation_xyzw": [0, 0, 0, 1], "scale": [1, 1, 1]}
            for name in value["target_rig"]["bone_names"]}} for frame in range(1, 265)]
        validate_motion(value)

    def test_blender_quaternion_uses_wxyz_component_order(self):
        self.assertEqual((1.0, 0.0, 0.0, 0.0), blender_quaternion([0.0, 0.0, 0.0, 1.0]))


if __name__ == "__main__":
    unittest.main()
