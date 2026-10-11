#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run_validation as runner


def main() -> int:
    tests = runner.load_manifest()
    patterns = runner.load_warning_patterns(test_ids={item["id"] for item in tests})
    expected_rollback_tests = {item["id"]: item.get("test_id") for item in patterns if item.get("test_id")}
    assert expected_rollback_tests == {
        "expected_generated_region_missing_spawn_rollback": "generated_region_route_lifecycle",
        "expected_generated_region_missing_spawn_rollback_manager": "generated_region_route_lifecycle",
        "expected_generated_region_missing_procgen_rollback": "generated_region_route_lifecycle",
        "expected_generated_region_missing_procgen_rollback_manager": "generated_region_route_lifecycle",
        "expected_hub_twin_missing_spawn_rollback": "hub_twin_solaria_route",
        "expected_hub_twin_missing_spawn_rollback_manager": "hub_twin_solaria_route",
        "expected_hub_twin_activation_rollback": "hub_twin_solaria_route",
    }
    excludes = runner.load_coverage_excludes()
    assert tests and len({item["id"] for item in tests}) == len(tests)
    selected = runner.select_tests(tests, files=["custodian/game/systems/combat/melee_target_resolver.gd"])
    assert [item["id"] for item in selected] == [
        "operator_melee_soft_targeting",
        "operator_runtime_path_audit",
        "operator_sword_cleaver",
        "operator_vigil_dagger",
        "melee_soft_target_spacing",
    ]
    assert [item["tier"] for item in selected] == ["unit", "unit", "actor", "actor", "moment"]
    assert runner.select_tests(tests, tag="ranged")
    import_truth = runner.select_tests(tests, tag="import_truth")
    assert [item["id"] for item in import_truth] == [
        "actor_relationship_contract", "generated_region_route_lifecycle", "vaultwing_runtime"
    ]
    assert all(item["needs_import"] for item in import_truth)
    assert [item["id"] for item in runner.select_tests(tests, test_id="operator_melee_soft_targeting")] == ["operator_melee_soft_targeting"]
    assert all(item["tier"] == "unit" for item in runner.select_tests(tests, tier="unit"))

    failed_sentinel = runner.RESULT_PREFIX + json.dumps({"passed": False, "failures": [{"message": "structured"}]})
    passed_sentinel = runner.RESULT_PREFIX + json.dumps({"passed": True, "failures": []})
    assert runner.parse_harness_result("noise\n" + failed_sentinel)["failures"][0]["message"] == "structured"
    assert runner.parse_harness_result("legacy output") is None

    fake = {"id": "fake", "type": "python", "script": __file__, "tier": "unit", "timeout_sec": 2,
            "selection_reasons": ["smoke"]}
    old_scratch = os.environ.get("CUSTODIAN_SCRATCH_DIR")
    with tempfile.TemporaryDirectory(prefix="validation-runner-scratch-") as scratch:
        os.environ["CUSTODIAN_SCRATCH_DIR"] = scratch
        expected_home = str(Path(scratch) / "godot-home")
        home_probe = runner.execute_test(
            fake, [], [sys.executable, "-c", "import os; print(os.environ['HOME'])"]
        )
        assert home_probe["status"] == "passed" and home_probe["stdout_tail"] == [expected_home]
        import_home_ok, import_home = runner._run_import(
            2, [sys.executable, "-c", "import os; print(os.environ['HOME'])"]
        )
        assert import_home_ok and import_home["stdout_tail"] == [expected_home]
        assert Path(expected_home).is_dir()
    if old_scratch is None:
        os.environ.pop("CUSTODIAN_SCRATCH_DIR", None)
    else:
        os.environ["CUSTODIAN_SCRATCH_DIR"] = old_scratch
    passed = runner.execute_test(fake, [], [sys.executable, "-c", f"print({passed_sentinel!r})"])
    assert passed["status"] == "passed" and passed["structured_result"] is not None
    structured_failure = runner.execute_test(fake, [], [sys.executable, "-c", f"print({failed_sentinel!r})"])
    assert structured_failure["status"] == "failed" and structured_failure["failures"][0]["message"] == "structured"
    malformed = runner.execute_test(fake, [], [sys.executable, "-c", f"print({(runner.RESULT_PREFIX + '{bad json')!r})"])
    assert malformed["status"] == "failed" and "malformed" in malformed["failures"][0]["message"]
    fatal = runner.execute_test(fake, [], [sys.executable, "-c", "import sys; print('ERROR: unexpected', file=sys.stderr)"])
    assert fatal["status"] == "failed" and fatal["warnings"][0]["classification"] == "fatal"
    for diagnostic in (
        "ERROR: Failed loading resource: res://broken.tscn",
        "SCRIPT ERROR: Parse Error: Cannot infer type",
        "Parse Error: invalid scene resource",
        "ERROR: GDExtension dynamic library not found",
    ):
        sentinel_command = (
            "import sys; print(" + repr(passed_sentinel) + "); print(" + repr(diagnostic) + ", file=sys.stderr)"
        )
        false_green = runner.execute_test(fake, [], [sys.executable, "-c", sentinel_command])
        assert false_green["status"] == "failed", (diagnostic, false_green)
    expected_line = (
        "ERROR: [LevelLoader] unable to enter generated_route_procgen_fixture: "
        "target spawn could not be resolved: MissingSpawn"
    )
    scoped_patterns = [item for item in patterns if item.get("test_id") == "generated_region_route_lifecycle"]
    expected = runner.classify_warnings(expected_line, scoped_patterns, "generated_region_route_lifecycle")
    assert expected[0]["classification"] == "expected_error"
    unrelated = runner.classify_warnings(expected_line, scoped_patterns, "another_smoke")
    assert unrelated[0]["classification"] == "fatal"
    near_match = runner.classify_warnings(expected_line + "Extra", scoped_patterns, "generated_region_route_lifecycle")
    assert near_match[0]["classification"] == "fatal"
    hub_line = (
        "ERROR: [LevelLoader] unable to enter hub_twin_solaria: "
        "target spawn could not be resolved: MissingCrownSpawn"
    )
    hub_patterns = [item for item in patterns if item.get("test_id") == "hub_twin_solaria_route"]
    assert runner.classify_warnings(hub_line, hub_patterns, "hub_twin_solaria_route")[0]["classification"] == "expected_error"
    assert runner.classify_warnings(hub_line, hub_patterns, "generated_region_route_lifecycle")[0]["classification"] == "fatal"
    known_exit = "ERROR: 2 resources still in use at exit (run with --verbose for details)."
    known_exit_result = runner.classify_warnings(known_exit, patterns)
    assert known_exit_result[0]["classification"] == "known_warning"
    assert runner.classify_warnings(known_exit + " extra", patterns)[0]["classification"] == "fatal"
    known_objectdb = "ERROR: 56 ObjectDB instances were leaked at exit (run with `--verbose` for details)."
    assert runner.classify_warnings(known_objectdb, patterns)[0]["classification"] == "known_warning"
    assert runner.classify_warnings(known_objectdb + " extra", patterns)[0]["classification"] == "fatal"
    warning_objectdb = known_objectdb.replace("ERROR:", "WARNING:")
    assert runner.classify_warnings(warning_objectdb, patterns)[0]["classification"] == "known_warning"
    import_fatal_ok, import_fatal = runner._run_import(
        2, [sys.executable, "-c", "import sys; print('ERROR: Failed loading resource: res://broken.tscn', file=sys.stderr)"]
    )
    assert not import_fatal_ok and import_fatal["status"] == "failed" and import_fatal["warnings"][0]["classification"] == "fatal"
    legacy = runner.execute_test(fake, [], [sys.executable, "-c", "print('legacy')"])
    assert legacy["status"] == "passed" and legacy["stdout_tail"] == ["legacy"]
    timed = dict(fake, timeout_sec=0.01)
    timeout = runner.execute_test(timed, [], [sys.executable, "-c", "import time; time.sleep(1)"])
    assert timeout["status"] == "timeout"
    launch_error = runner.execute_test(fake, [], ["/definitely/missing/custodian-command"])
    assert launch_error["status"] == "infrastructure_error"

    coverage = runner.changed_file_coverage([
        "custodian/game/systems/combat/melee_target_resolver.gd",
        "custodian/game/uncovered_runtime.gd",
        "design/review.md",
    ], tests, excludes)
    assert coverage["covered_files"] == ["custodian/game/systems/combat/melee_target_resolver.gd"]
    assert coverage["uncovered_files"] == ["custodian/game/uncovered_runtime.gd"]
    assert coverage["excluded_files"] == ["design/review.md"] and not coverage["complete"]

    tier_tests = [
        {"id": "unit_fail", "tier": "unit", "selection_reasons": []},
        {"id": "unit_sibling", "tier": "unit", "selection_reasons": []},
        {"id": "actor_skip", "tier": "actor", "selection_reasons": []},
    ]
    def fake_executor(test, _patterns):
        return {"id": test["id"], "tier": test["tier"], "status": "failed" if test["id"] == "unit_fail" else "passed"}
    tier_results = runner.execute_tiered(tier_tests, [], fake_executor)
    assert [item["status"] for item in tier_results] == ["failed", "passed", "skipped"]
    assert tier_results[-1]["blocked_by_tier"] == "unit"

    import_timeout_ok, import_timeout = runner._run_import(0.01, [sys.executable, "-c", "import time; time.sleep(1)"])
    assert not import_timeout_ok and import_timeout["status"] == "timeout"
    import_launch_ok, import_launch = runner._run_import(1, ["/definitely/missing/custodian-command"])
    assert not import_launch_ok and import_launch["status"] == "launch_error"

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        bad = root / "manifest.json"
        valid = {"id": "one", "type": "python", "tier": "unit", "script": "custodian/tools/validation/validation_runner_smoke.py"}
        invalid_sets = [
            [valid, dict(valid)],
            [dict(valid, type="wrong")],
            [dict(valid, tier="bogus")],
            [dict(valid, script="missing.py")],
        ]
        for invalid in invalid_sets:
            bad.write_text(json.dumps({"schema_version": 1, "tests": invalid}))
            try:
                runner.load_manifest(bad)
                raise AssertionError("invalid manifest accepted")
            except runner.ManifestError:
                pass

    payload = {"schema": "custodian.validation.result.v1", "passed": True, "coverage": coverage, "tests": [passed]}
    assert json.loads(json.dumps(payload))["schema"] == "custodian.validation.result.v1"
    print("validation_runner_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
