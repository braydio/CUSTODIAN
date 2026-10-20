"""Focused Python tests for fail-closed source part and rig mapping."""
from __future__ import annotations

import csv
import unittest
from pathlib import Path

from surface_contract import (
    EXPECTED_BONE_NAMES,
    EXPECTED_BONES,
    EXPECTED_MESHES,
    EXPECTED_TRIANGLES,
    SOURCE_BONE_ALIASES,
    assigned_bone,
    material_for_part,
    split_source_name,
)


REPO = Path(__file__).resolve().parents[4]
DEFAULT_INVENTORY = (
    REPO / "custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d"
    / "proof/surface_mesh_inventory.csv"
)


class SurfaceContractTests(unittest.TestCase):
    def test_inventory_has_complete_intentional_material_and_bone_mapping(self):
        self.assertTrue(DEFAULT_INVENTORY.is_file(), f"missing census: {DEFAULT_INVENTORY}")
        with DEFAULT_INVENTORY.open(newline="") as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), EXPECTED_MESHES)
        self.assertEqual(sum(int(row["triangles"]) for row in rows), EXPECTED_TRIANGLES)
        unknown = []
        unresolved_bones = []
        materials = set()
        for row in rows:
            part, source_bone = split_source_name(row["mesh"])
            material = material_for_part(part)
            if material is None:
                unknown.append(part)
            else:
                materials.add(material)
            if assigned_bone(source_bone) not in EXPECTED_BONE_NAMES:
                unresolved_bones.append((part, source_bone))
        self.assertEqual(unknown, [])
        self.assertEqual(unresolved_bones, [])
        self.assertEqual(EXPECTED_BONES, len(EXPECTED_BONE_NAMES))
        self.assertEqual(materials, {
            "armor_graphite", "mask_nearblack", "metal_bronze", "fabric_offwhite",
            "fabric_burgundy", "fabric_charcoal", "soft_underarmor", "leather_dark",
            "cable_ochre", "emblem_ivory", "emission_amber", "emission_canister",
        })

    def test_identity_and_energy_materials_remain_distinct(self):
        self.assertEqual(material_for_part("Hood_tent_shell"), "fabric_offwhite")
        self.assertEqual(material_for_part("Hood_maroon_inner_cord_seg00"), "fabric_burgundy")
        self.assertEqual(material_for_part("Apron_central_dark"), "fabric_charcoal")
        self.assertEqual(material_for_part("Mask_faceplate"), "mask_nearblack")
        self.assertEqual(material_for_part("Mask_vertical_amber_eye"), "emission_amber")
        self.assertEqual(material_for_part("Tank_0_amber_glass"), "emission_canister")
        self.assertEqual(material_for_part("Tank_1_amber_glass"), "emission_canister")
        self.assertEqual(material_for_part("Tank_2_amber_glass"), "emission_canister")
        self.assertEqual(material_for_part("R_Cannon_brass_cage_0_seg00"), "metal_bronze")

    def test_hand_and_foot_meshes_fold_into_15_bone_hierarchy(self):
        self.assertEqual(assigned_bone("Hand.L"), "Forearm.L")
        self.assertEqual(assigned_bone("Foot.R"), "LowerLeg.R")
        self.assertEqual(assigned_bone("Foot.L"), "LowerLeg.L")
        self.assertEqual(set(SOURCE_BONE_ALIASES), {"Hand.L", "Foot.R", "Foot.L"})

    def test_unknown_names_fail_closed(self):
        self.assertIsNone(material_for_part("Mystery_photo_fragment"))
        with self.assertRaises(ValueError):
            split_source_name("unrecognized_mesh")


if __name__ == "__main__":
    unittest.main()
