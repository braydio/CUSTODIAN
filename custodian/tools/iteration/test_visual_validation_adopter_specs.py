"""Validate reusable direct-adopter specs against current Moment Forge DSL."""

from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

ITERATION_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ITERATION_DIR))
from run_moment import SUPPORTED_ASSERTIONS, load_scenarios, validate_scenario  # noqa: E402

SPEC_DIR = ITERATION_DIR / "adopter_specs"
EXPECTED_SPECS = {
    "twin_crown_forensics",
    "solarium_i_acquisition",
    "operator_mobile_guard",
    "vaultwing_bonding_closure",
}
PROBE_FIELDS = {
    "visible", "effective_visible", "modulate", "self_modulate", "effective_alpha",
    "z_index", "z_as_relative", "effective_z_index", "global_bounds", "screen_bounds",
    "texture_size", "animation", "frame", "frame_progress", "collision_shape_count",
    "navigation_node_count", "movement_direction", "aim_direction",
    "movement_aim_directions_diverge", "guard_break_movement_locked", "route_review_state_hash",
    "passage_node_count", "stale_resolve_completion_count",
}


def _expand_scenario(spec: dict, base: dict) -> dict:
    scenario = copy.deepcopy(base)
    scenario.pop("_source_path", None)
    scenario_id = f"validation/adopter_spec_{spec['id']}"
    scenario["id"] = scenario_id
    scenario["description"] = f"Schema-bound validation example for {spec['id']} adopter spec."
    stage_ticks = {state: 10 + index * 10 for index, state in enumerate(spec["sequence"])}
    stage_ticks.update({state: 10 + index * 10 for index, state in enumerate(spec.get("states", []))})
    scenario["duration_ticks"] = max(stage_ticks.values(), default=10) + 10
    scenario["capture"]["start_tick"] = 0
    scenario["capture"]["end_tick"] = scenario["duration_ticks"] - 1
    spacing = max(1, scenario["duration_ticks"] // 6)
    scenario["capture"]["contact_sheet_ticks"] = [index * spacing for index in range(6)]
    scenario["setup"]["roles"] = {
        role: {"node_path": "."} for role in spec["roles"]
    }
    scenario["timeline"] = [
        {"tick": tick, "action": "capture_marker", "name": state}
        for state, tick in stage_ticks.items()
    ]
    scenario["probes"] = []
    for probe in spec.get("probes", []):
        expanded = {
            key: value
            for key, value in probe.items()
            if key in {"id", "role", "fields", "required", "snapshot"}
        }
        expanded["ticks"] = [stage_ticks[state] for state in spec.get("sequence", spec.get("states", []))]
        scenario["probes"].append(expanded)

    by_id = {probe["id"] for probe in scenario["probes"]}
    assertions = []
    for template in spec.get("assertion_templates", []):
        raw = {key: value for key, value in template.items() if key not in {"state", "states", "each_state"}}
        if raw.get("type") not in SUPPORTED_ASSERTIONS:
            continue  # Asset V2 contract assertions are checked by the dedicated Vaultwing contract below.
        if template.get("each_state"):
            for state in spec.get("sequence", []):
                assertions.append({**raw, "tick": stage_ticks[state]})
        elif "state" in template:
            assertions.append({**raw, "tick": stage_ticks[template["state"]]})
        elif "states" in template:
            points = template["states"]
            probe = raw.pop("probe", None)
            if probe:
                raw["points"] = [{"probe": probe, "tick": stage_ticks[state]} for state in points]
            else:
                raise AssertionError(f"sequence assertion has no probe in {spec['id']}")
            assertions.append(raw)
        else:
            assertions.append(raw)
    for assertion in assertions:
        if assertion["type"] == "probe_compare" and assertion["probe"] not in by_id:
            raise AssertionError(f"unknown probe {assertion['probe']} in {spec['id']}")
        if assertion["type"] == "probe_sequence_equal":
            if any(point["probe"] not in by_id for point in assertion["points"]):
                raise AssertionError(f"unknown sequence probe in {spec['id']}")
    scenario["assertions"] = assertions
    scenario["stable_fingerprint"]["probes"] = [probe["id"] for probe in scenario["probes"]]
    scenario["tags"] = ["validation", "visual_validation", spec["id"]]
    return scenario


class AdopterSpecTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.specs = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(SPEC_DIR.glob("*.json"))]
        cls.base_scenario = load_scenarios()["traversal/awakening_late_seams_v1"]

    def test_all_four_specs_use_the_current_probe_and_assertion_contract(self) -> None:
        self.assertEqual({spec["id"] for spec in self.specs}, EXPECTED_SPECS)
        for spec in self.specs:
            with self.subTest(adopter=spec["id"]):
                self.assertEqual(spec["schema"], "custodian.moment_forge_adopter_spec.v1")
                roles = set(spec.get("roles", {}))
                probe_ids = set()
                for probe in spec.get("probes", []):
                    self.assertIn(probe["role"], roles)
                    probe_ids.add(probe["id"])
                    for field in probe["fields"]:
                        self.assertIn(field, PROBE_FIELDS)
                for assertion in spec.get("assertion_templates", []):
                    if assertion["type"] in SUPPORTED_ASSERTIONS:
                        self.assertIn(assertion.get("probe"), probe_ids)
                if spec["id"] != "vaultwing_bonding_closure":
                    scenario = _expand_scenario(spec, self.base_scenario)
                    validate_scenario(scenario, require_scene=False)

    def test_vaultwing_spec_matches_asset_v2_runtime_closure(self) -> None:
        spec = next(item for item in self.specs if item["id"] == "vaultwing_bonding_closure")
        contract = spec["asset_contract"]
        self.assertEqual(len(spec["states"]) * len(spec["directions"]), contract["runtime_strip_count"])
        self.assertEqual(contract["frames_per_strip"] * contract["frame_size"][0], contract["strip_size"][0])
        self.assertEqual(contract["frame_size"][1], contract["strip_size"][1])
        self.assertEqual({item["metric"] for item in spec["probe_templates"]}, {"alpha_bounds", "matte_void", "roi_diff"})
        self.assertTrue(contract["alpha_required"])


if __name__ == "__main__":
    unittest.main()
