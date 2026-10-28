"""Focused pure-contract tests; fixtures here are not claimed as FBX proof."""
from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parents[1] / "operator/animation_compiler"
sys.path.insert(0, str(MODULE_DIR))
from neutral_idle_proof_contract import blender_quaternion, sampled_frames, validate_mapping, validate_motion  # noqa: E402


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
