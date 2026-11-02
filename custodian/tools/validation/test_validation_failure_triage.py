#!/usr/bin/env python3
"""Anti-vacuity checks for validation failure attribution."""
from __future__ import annotations

import hashlib
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import validation_failure_triage as triage

MANIFEST = [
    {"id": "alpha", "tier": "unit", "type": "python", "script": "custodian/tools/validation/alpha.py",
     "timeout_sec": 20, "owners": ["custodian/game/alpha.gd", "custodian/tools/validation/alpha.py"]},
    {"id": "beta", "tier": "integration", "type": "godot_script", "script": "res://tools/validation/beta.gd",
     "timeout_sec": 45, "owners": ["custodian/game/beta.gd"]},
    {"id": "gamma", "tier": "actor", "type": "python", "script": "custodian/tools/validation/gamma.py",
     "timeout_sec": 30, "owners": ["custodian/game/gamma.gd"]},
]


def result_item(test_id: str, tier: str, status: str, **kwargs):
    return {"id": test_id, "tier": tier, "status": status, "exit_code": 1 if status == "failed" else None,
            "duration_ms": 1200, "timeout_sec": 30 if status == "timeout" else None,
            "selection_reasons": ["owner:custodian/game/" + test_id + ".gd"], "failures": [],
            "warnings": [], "stdout_tail": [], "stderr_tail": [], **kwargs}


def report(items, *, passed=False, changed=None):
    return {"schema": triage.RESULT_SCHEMA, "passed": passed, "changed_files": changed or [],
            "coverage": {"complete": True, "uncovered_files": []}, "selected": [x["id"] for x in items if x.get("id")],
            "tests": items, "summary": {"selected": len(items)}}


def build(candidate, baseline=None):
    return triage.build_triage(candidate, "a" * 64, baseline, "b" * 64 if baseline is not None else None, MANIFEST)


class ValidationFailureTriageTests(unittest.TestCase):
    def test_h5_stealth_and_npa_shapes_preserve_every_red_and_skip_id(self):
        fixtures = {
            "h5": [result_item("alpha", "unit", "failed"), result_item("beta", "integration", "failed"),
                   result_item("gamma", "actor", "timeout"), result_item("delta", "moment", "skipped", skip_reason="lower_tier_failed", blocked_by_tier="integration")],
            "stealth": [result_item(f"fail-{n}", "actor", "failed") for n in range(3)] +
                        [result_item(f"skip-{n}", "integration", "skipped", skip_reason="lower_tier_failed", blocked_by_tier="actor") for n in range(16)],
            "npa7": [result_item("world_transition_handoff", "integration", "failed"),
                     result_item("awakening_late_seams_v1", "moment", "skipped", skip_reason="lower_tier_failed", blocked_by_tier="integration")],
        }
        for name, items in fixtures.items():
            with self.subTest(name=name):
                out = build(report(items))
                self.assertEqual({issue["test_id"] for issue in out["issues"]}, {item["id"] for item in items})
                self.assertEqual(out["summary"]["issue_count"], len(items))

    def test_baseline_red_remains_red_and_is_never_waived(self):
        candidate = report([result_item("alpha", "unit", "failed")])
        baseline = report([result_item("alpha", "unit", "failed")])
        out = build(candidate, baseline)
        issue = out["issues"][0]
        self.assertEqual(issue["classification"], "baseline-red")
        self.assertTrue(issue["candidate_remains_blocking"])
        self.assertFalse(out["candidate"]["passed"])

    def test_baseline_green_flags_candidate_only_red(self):
        candidate = report([result_item("beta", "integration", "failed")])
        baseline = report([result_item("beta", "integration", "passed")], passed=True)
        issue = build(candidate, baseline)["issues"][0]
        self.assertEqual(issue["classification"], "candidate-only-red")
        self.assertTrue(issue["candidate_remains_blocking"])

    def test_missing_invalid_wrong_tier_and_duplicate_baselines_are_unknown(self):
        candidate = report([result_item("alpha", "unit", "failed")])
        self.assertEqual(build(candidate)["issues"][0]["classification"], "unknown")
        invalid = {"schema": "wrong", "tests": []}
        self.assertEqual(build(candidate, invalid)["issues"][0]["classification"], "unknown")
        wrong_tier = report([result_item("alpha", "actor", "passed")], passed=True)
        self.assertEqual(build(candidate, wrong_tier)["issues"][0]["classification"], "unknown")
        duplicate = report([result_item("alpha", "unit", "passed"), result_item("alpha", "unit", "failed")])
        self.assertEqual(build(candidate, duplicate)["issues"][0]["classification"], "unknown")

    def test_import_error_timeout_and_fatal_diagnostics_never_become_passes(self):
        import_failure = {"schema": triage.RESULT_SCHEMA, "passed": False, "infrastructure_failure": "import",
                          "message": "editor import failed", "import": {"status": "timeout"}}
        baseline = report([], passed=True)
        runner_issue = build(import_failure, baseline)["issues"][0]
        self.assertEqual(runner_issue["status"], "infrastructure_error")
        self.assertTrue(runner_issue["candidate_remains_blocking"])
        self.assertEqual(runner_issue["classification"], "unknown")

        timed = result_item("gamma", "actor", "timeout", timeout_sec=30)
        fatal = result_item("alpha", "unit", "failed", warnings=[{"classification": "fatal", "line": "ERROR: fail"}])
        out = build(report([timed, fatal]), report([result_item("gamma", "actor", "passed"), result_item("alpha", "unit", "passed")], passed=True))
        self.assertTrue(all(item["candidate_remains_blocking"] for item in out["issues"]))
        self.assertEqual({item["classification"] for item in out["issues"]}, {"candidate-only-red"})
        issues = {item["test_id"]: item for item in out["issues"]}
        self.assertEqual(issues["gamma"]["duration"]["timeout_sec"], 30)
        self.assertEqual(issues["alpha"]["failure_diagnostics"]["warnings"][0]["classification"], "fatal")

    def test_manifest_owners_and_skip_blocker_are_attributed(self):
        item = result_item("beta", "integration", "skipped", skip_reason="lower_tier_failed", blocked_by_tier="actor")
        candidate = report([item], changed=["custodian/game/beta.gd"])
        issue = build(candidate)["issues"][0]
        self.assertEqual(issue["owners"]["registered"], ["custodian/game/beta.gd"])
        self.assertEqual(issue["owners"]["matched_changed_files"], [{"path": "custodian/game/beta.gd", "patterns": ["custodian/game/beta.gd"]}])
        self.assertEqual(issue["skip"], {"reason": "lower_tier_failed", "blocked_by_tier": "actor"})

    def test_baseline_digest_and_output_are_deterministic(self):
        candidate = report([result_item("alpha", "unit", "failed")])
        baseline_payload = report([result_item("alpha", "unit", "passed")], passed=True)
        with tempfile.TemporaryDirectory() as temp:
            baseline_path = Path(temp) / "baseline.json"
            baseline_path.write_text(json.dumps(baseline_payload, sort_keys=True))
            decoded, digest = triage.read_report(baseline_path)
            self.assertEqual(digest, hashlib.sha256(baseline_path.read_bytes()).hexdigest())
        first = triage.build_triage(candidate, "a" * 64, decoded, digest, MANIFEST)
        second = triage.build_triage(candidate, "a" * 64, decoded, digest, MANIFEST)
        self.assertEqual(first, second)
        self.assertEqual(first["baseline"]["sha256"], digest)

    def test_runner_import_and_coverage_failures_are_preserved(self):
        candidate = {"schema": triage.RESULT_SCHEMA, "passed": False, "coverage": {"complete": False, "uncovered_files": ["x.py"]}, "tests": []}
        out = build(candidate)
        self.assertEqual({item["status"] for item in out["issues"]}, {"coverage_error"})
        self.assertFalse(out["candidate"]["passed"])

    def test_missing_explicit_baseline_file_stays_unknown(self):
        candidate = report([result_item("alpha", "unit", "failed")])
        with tempfile.TemporaryDirectory() as temp:
            candidate_path = Path(temp) / "candidate.json"
            candidate_path.write_text(json.dumps(candidate))
            missing_baseline = Path(temp) / "missing-baseline.json"
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                exit_code = triage.main([str(candidate_path), "--baseline", str(missing_baseline), "--json"])
            self.assertEqual(exit_code, 1)  # the red candidate remains red
            output = json.loads(stdout.getvalue())
            self.assertFalse(output["baseline"]["valid"])
            self.assertEqual(output["issues"][0]["classification"], "unknown")

    def test_skip_cannot_become_a_green_triage_result(self):
        candidate = report([result_item("beta", "integration", "skipped", skip_reason="lower_tier_failed",
                                        blocked_by_tier="actor")], passed=True)
        out = build(candidate)
        self.assertTrue(out["candidate"]["passed"])  # preserve the source report verbatim
        self.assertFalse(out["triage_passed"])
        self.assertTrue(out["issues"][0]["candidate_remains_blocking"])


if __name__ == "__main__":
    unittest.main()
