#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run_validation as runner


def main() -> int:
    tests = runner.load_manifest()
    excludes = runner.load_coverage_excludes()
    assert tests and len({item["id"] for item in tests}) == len(tests)
    selected = runner.select_tests(tests, files=["custodian/game/systems/combat/melee_target_resolver.gd"])
    assert [item["id"] for item in selected] == ["operator_melee_soft_targeting", "operator_melee_fast_chain", "operator_vigil_dagger", "melee_soft_target_spacing"]
    assert [item["tier"] for item in selected] == ["unit", "actor", "actor", "moment"]
    assert runner.select_tests(tests, tag="ranged")
    assert [item["id"] for item in runner.select_tests(tests, test_id="operator_melee_soft_targeting")] == ["operator_melee_soft_targeting"]
    assert all(item["tier"] == "unit" for item in runner.select_tests(tests, tier="unit"))

    failed_sentinel = runner.RESULT_PREFIX + json.dumps({"passed": False, "failures": [{"message": "structured"}]})
    passed_sentinel = runner.RESULT_PREFIX + json.dumps({"passed": True, "failures": []})
    assert runner.parse_harness_result("noise\n" + failed_sentinel)["failures"][0]["message"] == "structured"
    assert runner.parse_harness_result("legacy output") is None

    fake = {"id": "fake", "type": "python", "script": __file__, "tier": "unit", "timeout_sec": 2,
            "selection_reasons": ["smoke"]}
    passed = runner.execute_test(fake, [], [sys.executable, "-c", f"print({passed_sentinel!r})"])
    assert passed["status"] == "passed" and passed["structured_result"] is not None
    structured_failure = runner.execute_test(fake, [], [sys.executable, "-c", f"print({failed_sentinel!r})"])
    assert structured_failure["status"] == "failed" and structured_failure["failures"][0]["message"] == "structured"
    malformed = runner.execute_test(fake, [], [sys.executable, "-c", f"print({(runner.RESULT_PREFIX + '{bad json')!r})"])
    assert malformed["status"] == "failed" and "malformed" in malformed["failures"][0]["message"]
    fatal = runner.execute_test(fake, [], [sys.executable, "-c", "import sys; print('ERROR: unexpected', file=sys.stderr)"])
    assert fatal["status"] == "failed" and fatal["warnings"][0]["classification"] == "fatal"
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
