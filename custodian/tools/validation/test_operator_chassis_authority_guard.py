#!/usr/bin/env python3
"""Positive and negative controls for the Operator chassis guard."""

from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("operator_chassis_authority_guard.py")
SPEC = importlib.util.spec_from_file_location("operator_chassis_authority_guard", SCRIPT)
guard = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(guard)


class GDScriptInventoryTests(unittest.TestCase):
    def test_multiline_typed_field_accessor_and_nested_local_are_distinguished(self):
        source = '''extends CharacterBody2D
@export
var nested: Dictionary[StringName, Array[Vector2]] = {
    &"key": [Vector2.ZERO], # nested fake var injected
}
var display_value: int:
    set(value):
        _display_value = value
var _display_value := 0
func apply(
    delta: float,
    config: Dictionary[StringName, Array[int]],
) -> void:
    var nested_local := {"fake_field": config.get(&"x", [1])}
    if self.display_value > 0:
        self.display_value = nested_local.size()
'''
        inventory = guard.parse_gdscript(source)
        self.assertEqual(set(inventory["fields"]), {"nested", "display_value", "_display_value"})
        self.assertEqual(set(inventory["methods"]), {"apply"})
        self.assertEqual(inventory["methods"]["apply"]["params"], ["config", "delta"])
        self.assertEqual(inventory["methods"]["apply"]["writes"], ["display_value"])
        self.assertEqual(inventory["methods"]["apply"]["branches"], 1)
        self.assertEqual(inventory["fields"]["_display_value"]["writers"], ["display_value.set"])

    def test_comments_strings_and_hash_bait_do_not_create_declarations_or_motors(self):
        source = '''extends CharacterBody2D
# func fake(): target.move_and_slide()
const bait = "func invented(): enemy.move_and_slide()"
func _advance_movement() -> void:
    var text = "# var injected = 1"
    move_and_slide()
'''
        inventory = guard.parse_gdscript(source)
        self.assertEqual(set(inventory["methods"]), {"_advance_movement"})
        self.assertEqual(set(inventory["fields"]), {"bait"})
        self.assertEqual(guard.detect_foreign_motors({"custodian/game/actors/operator/operator.gd": source}, []), [])

    def test_positive_delegation_with_nested_field_reads_is_not_misclassified_as_state(self):
        source = '''extends Node
var _controller: Dictionary = {"nested": {"state": 1}}
func update_controller(delta: float) -> void:
    _controller.get("nested", {}).get("state", 0)
'''
        inventory = guard.parse_gdscript(source)
        self.assertEqual(inventory["methods"]["update_controller"]["writes"], [])
        self.assertEqual(inventory["fields"]["_controller"]["domain"], "delegation_reference")

    def test_nested_field_alias_mutation_is_attributed_to_the_original_field(self):
        source = '''extends Node
var _state: Array[int] = []
func mutate() -> void:
    var entries = self._state
    entries.append(1)
'''
        inventory = guard.parse_gdscript(source)
        self.assertEqual(inventory["methods"]["mutate"]["writes"], ["_state"])

    def test_existing_migration_debt_measurement_reuses_path_and_animation_predicates(self):
        source_root = SCRIPT.resolve().parents[3]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative in (
                "custodian/tools/validation/operator_runtime_path_audit.py",
                "custodian/tools/validation/operator_runtime_animation_authority_smoke.py",
                "custodian/tools/pipelines/operator_asset_schema.py",
            ):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source_root / relative, target)
            source = root / "custodian/game/world/fixture.gd"
            source.parent.mkdir(parents=True)
            source.write_text(
                'var icon = "legacy_' 'attack" # res://content/sprites/operator/runtime/animations/old.png\n'
            )
            measured = guard.measure_existing_migration_debt(root)
            self.assertEqual(len(measured["legacy_path_lines"]), 1)
            self.assertEqual(measured["legacy_runtime_paths"], [])


class BudgetEnforcementTests(unittest.TestCase):
    def setUp(self):
        self.source = '''extends CharacterBody2D
var health := 5
func apply_damage(amount: int) -> void:
    health -= amount
'''
        self.baseline = guard.parse_gdscript(self.source)
        self.budget = guard.make_budget(self.baseline)

    def test_new_melee_weapon_or_recovery_field_is_rejected_without_approval(self):
        for field in ("melee_chain_step", "current_magazine", "recovery_timer"):
            with self.subTest(field=field):
                changed = self.source.replace("func apply_damage", f"var {field} := 0\nfunc apply_damage")
                violations = guard.compare_inventory(guard.parse_gdscript(changed), self.budget)
                self.assertTrue(any(f"unregistered top-level field: {field}" in item for item in violations))

    def test_new_stateful_method_and_unregistered_facade_are_rejected(self):
        changed = self.source + "\nfunc restore() -> void:\n    health = 5\n"
        violations = guard.compare_inventory(guard.parse_gdscript(changed), self.budget)
        self.assertTrue(any("unregistered top-level method/facade: restore" in item for item in violations))

    def test_existing_stateful_method_growth_and_new_write_are_rejected(self):
        grown = self.source.replace("    health -= amount", "    if amount > 0:\n        health -= amount")
        violations = guard.compare_inventory(guard.parse_gdscript(grown), self.budget)
        self.assertTrue(any("method body grew" in item or "decision branches grew" in item for item in violations))
        redirected = self.source.replace("    health -= amount", "    health = amount\n    health -= amount")
        violations = guard.compare_inventory(guard.parse_gdscript(redirected), self.budget)
        self.assertTrue(any("method body grew" in item for item in violations))
        same_size_change = self.source.replace("health -= amount", "health += amount")
        changed_inventory = guard.parse_gdscript(same_size_change)
        violations = guard.compare_inventory(changed_inventory, self.budget)
        self.assertTrue(any("fingerprint differs from the sealed budget" in item
                            for item in violations))
        rebased = json.loads(json.dumps(self.budget))
        rebased["method_inventory"]["apply_damage"]["code_fingerprint"] = \
            changed_inventory["methods"]["apply_damage"]["fingerprint"]
        rebased["approval_records"]["apply_damage"] = {
            "owner": "F6", "consumer": "survivability controller", "reason": "bounded extraction",
            "scope": "apply_damage mutation", "expires_after": "F6 lands",
            "approval_reference": "reviewed F6 task packet",
        }
        self.assertEqual(guard._policy_violations(rebased, self.budget), [])
        self.assertFalse(guard.compare_inventory(changed_inventory, rebased))

    def test_budget_increase_and_rebaseline_are_rejected_against_main(self):
        old = json.loads(json.dumps(self.budget))
        changed = json.loads(json.dumps(old))
        changed["limits"]["top_level_fields"] += 1
        self.assertTrue(any("increased relative to base" in item
                            for item in guard._policy_violations(changed, old)))
        changed = json.loads(json.dumps(old))
        changed["method_inventory"]["apply_damage"]["max_code_lines"] += 1
        self.assertTrue(any("method ceiling increased" in item
                            for item in guard._policy_violations(changed, old)))
        changed = json.loads(json.dumps(old))
        changed["approval_records"]["new_field"] = {"approved": True}
        changed["field_inventory"]["new_field"] = {"owner": "melee"}
        self.assertTrue(any("unapproved field_inventory addition" in item
                            for item in guard._policy_violations(changed, old)))
        changed = json.loads(json.dumps(old))
        changed["legacy_exceptions"].append({"path": "operator.gd", "call": "target.move_and_slide()"})
        self.assertTrue(any("legacy movement exception added" in item
                            for item in guard._policy_violations(changed, old)))
        changed = json.loads(json.dumps(old))
        changed["existing_migration_debt"]["legacy_path_lines"].append(
            {"path": "game/actors/operator/operator.gd", "line_sha256": "f" * 64}
        )
        self.assertTrue(any("existing migration debt baseline increased" in item
                            for item in guard._policy_violations(changed, old)))

    def test_budget_and_inventory_can_only_shrink_without_approval(self):
        reduced = json.loads(json.dumps(self.budget))
        reduced["limits"]["top_level_fields"] -= 1
        reduced["limits"]["top_level_functions"] -= 1
        reduced["field_inventory"].pop("health")
        reduced["method_inventory"].pop("apply_damage")
        reduced_source = "extends CharacterBody2D\n"
        self.assertEqual(guard._policy_violations(reduced, self.budget), [])
        self.assertEqual(guard.compare_inventory(guard.parse_gdscript(reduced_source), reduced), [])

    def test_qualified_and_aliased_foreign_motor_calls_fail_but_exact_f2_debt_is_allowed(self):
        path = "custodian/game/actors/operator/operator.gd"
        legacy = '''extends CharacterBody2D
func _advance_movement():
    move_and_slide()
func _apply_melee_hitbox_tick(enemy):
    enemy.move_and_slide()
'''
        exception = [{"path": path, "function": "_apply_melee_hitbox_tick", "receiver": "enemy",
                      "call": "enemy.move_and_slide()"}]
        self.assertEqual(guard.detect_foreign_motors({path: legacy}, exception), [])
        bad = legacy + '''
func move_other(target):
    var body = target
    body.move_and_slide()
    target.move_and_slide()
'''
        findings = guard.detect_foreign_motors({path: bad}, exception)
        self.assertEqual(len(findings), 2)
        self.assertTrue(all("foreign or misplaced" in item for item in findings))
        duplicate = legacy.replace(
            "    enemy.move_and_slide()", "    enemy.move_and_slide()\n    enemy.move_and_slide()"
        )
        findings = guard.detect_foreign_motors({path: duplicate}, exception)
        self.assertTrue(any("must occur exactly once, found 2" in item for item in findings))
        findings = guard.detect_foreign_motors({path: legacy}, [])
        self.assertTrue(any("foreign or misplaced enemy.move_and_slide()" in item for item in findings))

    def test_only_explicit_bounded_approval_records_can_extend_policy(self):
        self.assertFalse(guard._valid_approval({"approved": True}))
        self.assertTrue(guard._valid_approval({
            "owner": "F2", "consumer": "melee controller", "reason": "bounded migration",
            "scope": "one named method", "expires_after": "F2 lands",
            "approval_reference": "reviewed task packet",
        }))


class GateWiringTests(unittest.TestCase):
    def test_repository_registers_mandatory_guard_test_and_finish_hooks(self):
        root = SCRIPT.resolve().parents[3]
        self.assertEqual(guard._verify_integration(root), [])
        self.assertEqual(guard._verify_manifest(root), [])

    def test_disabled_finish_hooks_and_selective_manifest_removal_are_rejected(self):
        root = SCRIPT.resolve().parents[3]
        source = (root / guard.WORKSTREAM_REL).read_text()
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            (fixture / guard.WORKSTREAM_REL).parent.mkdir(parents=True)
            (fixture / guard.WORKSTREAM_REL).write_text(source.replace(
                "_run_operator_chassis_authority_guard(repo, path)", "operator_guard_bypassed()"))
            self.assertTrue(guard._verify_integration(fixture))

            manifest = fixture / guard.MANIFEST_REL
            manifest.parent.mkdir(parents=True)
            data = json.loads((root / guard.MANIFEST_REL).read_text())
            data["tests"] = [test for test in data["tests"] if test.get("id") != guard.GUARD_TEST_ID]
            manifest.write_text(json.dumps(data))
            self.assertTrue(guard._verify_manifest(fixture))


if __name__ == "__main__":
    unittest.main(verbosity=2)
