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
    assert tests and len({item["id"] for item in tests}) == len(tests)
    selected = runner.select_tests(tests, files=["custodian/game/systems/combat/melee_target_resolver.gd"])
    assert [item["id"] for item in selected] == ["operator_melee_soft_targeting", "operator_melee_fast_chain", "operator_vigil_dagger", "melee_soft_target_spacing"]
    assert [item["tier"] for item in selected] == ["unit", "actor", "actor", "moment"]
    assert runner.select_tests(tests, tag="ranged")
    assert [item["id"] for item in runner.select_tests(tests, test_id="operator_melee_soft_targeting")] == ["operator_melee_soft_targeting"]
    assert all(item["tier"] == "unit" for item in runner.select_tests(tests, tier="unit"))

    sentinel = runner.RESULT_PREFIX + json.dumps({"passed": False, "failures": [{"message": "structured"}]})
    assert runner.parse_harness_result("noise\n" + sentinel)["failures"][0]["message"] == "structured"
    assert runner.parse_harness_result("legacy output") is None

    fake = {"id": "fake", "type": "python", "script": __file__, "tier": "unit", "timeout_sec": 2,
            "selection_reasons": ["smoke"]}
    passed = runner.execute_test(fake, [], [sys.executable, "-c", f"print({sentinel!r})"])
    assert passed["status"] == "passed" and passed["structured_result"] is not None
    legacy = runner.execute_test(fake, [], [sys.executable, "-c", "print('legacy')"])
    assert legacy["status"] == "passed" and legacy["stdout_tail"] == ["legacy"]
    timed = dict(fake, timeout_sec=0.01)
    timeout = runner.execute_test(timed, [], [sys.executable, "-c", "import time; time.sleep(1)"])
    assert timeout["status"] == "timeout"

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

    payload = {"schema": "custodian.validation.result.v1", "passed": True, "tests": [passed]}
    assert json.loads(json.dumps(payload))["schema"] == "custodian.validation.result.v1"
    print("validation_runner_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
