"""Offline contract checks for the Broken Warrant material correction."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import surface_contract  # noqa: E402


class MaterialPatchContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.palette = json.loads((HERE / "material_palette.json").read_text())[
            "materials"
        ]

    def test_canisters_use_distinct_bounded_emission(self):
        spec = self.palette["emission_canister"]
        self.assertEqual(spec["hex"], "#F07323")
        self.assertEqual(spec["emission_strength"], 0.65)
        self.assertEqual(spec["metallic"], 0.15)
        self.assertEqual(spec["roughness"], 0.30)
        for index in range(3):
            self.assertEqual(
                surface_contract.material_for_part(f"Tank_{index}_amber_glass"),
                "emission_canister",
            )
        self.assertEqual(
            surface_contract.material_for_part("Mask_vertical_amber_eye"),
            "emission_amber",
        )
        self.assertEqual(
            surface_contract.material_for_part("Core_amber_emitter"),
            "emission_amber",
        )

    def test_fabric_noise_values_match_pixel_detail_contract(self):
        expected = {
            "fabric_offwhite": (1.5, 12, 0.038, 0.008, 0.001),
            "fabric_burgundy": (1.7, 14, 0.045, 0.010, 0.0015),
            "fabric_charcoal": (1.7, 14, 0.045, 0.010, 0.0015),
        }
        fields = (
            "noise_scale", "micro_scale", "color_variation",
            "bump_strength", "bump_distance",
        )
        for material, values in expected.items():
            self.assertEqual(tuple(self.palette[material][key] for key in fields), values)

    def test_both_emission_mask_branches_include_both_classes(self):
        renderer = (HERE / "render_pixel_proof.py").read_text()
        expression = 'semantic in {"emission_amber", "emission_canister"} else black'
        self.assertEqual(renderer.count(expression), 2)

    def test_validator_enforces_exact_opaque_canister_assignment(self):
        validator = (HERE / "validate_materials.py").read_text()
        for required in (
            '"exactly_three_separate_canister_materials"',
            '"bounded_canister_emission_strength"',
            'canister_names = {f"Tank_{i}_amber_glass" for i in range(3)}',
            'float(canister_shader.inputs["Alpha"].default_value) - 1.0',
        ):
            self.assertIn(required, validator)


if __name__ == "__main__":
    unittest.main()
