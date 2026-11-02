#!/usr/bin/env python3
"""Attribute validation-run failures without changing their result or gate state.

Usage: python3 validation_failure_triage.py changed-report.json [--baseline baseline.json] --json

A baseline is evidence only when explicitly supplied and when it contains one
same-ID, same-tier result for the candidate test. Attribution never waives a
candidate failure, timeout, infrastructure error, or skipped tier.
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_validation import MANIFEST_PATH, owner_patterns, load_manifest  # noqa: E402

RESULT_SCHEMA = "custodian.validation.result.v1"
TRIAGE_SCHEMA = "custodian.validation.triage.v1"
ISSUE_STATUSES = {"failed", "timeout", "infrastructure_error", "skipped"}
BLOCKING_STATUSES = {"failed", "timeout", "infrastructure_error"}
CANDIDATE_NON_PASS_STATUSES = BLOCKING_STATUSES | {"skipped"}
TIER_ORDER = {name: index for index, name in enumerate(("unit", "actor", "integration", "moment", "boot"))}


class TriageInputError(ValueError):
    pass


def read_report(path: Path) -> tuple[dict[str, Any], str]:
    raw = path.read_bytes()
    try:
        value = json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise TriageInputError(f"{path}: invalid JSON: {exc}") from exc
    if not isinstance(value, dict) or value.get("schema") != RESULT_SCHEMA:
        raise TriageInputError(f"{path}: expected schema {RESULT_SCHEMA}")
    return value, hashlib.sha256(raw).hexdigest()


def _manifest_index(tests: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {str(test["id"]): test for test in tests}


def _manifest_owners(test: dict[str, Any] | None, changed_files: list[str]) -> dict[str, Any]:
    if test is None:
        return {"registered": [], "matched_changed_files": []}
    explicit = sorted({str(owner) for owner in test.get("owners", [])})
    patterns = owner_patterns(test)
    matched = []
    for changed in sorted(set(changed_files)):
        matches = sorted(pattern for pattern in patterns if fnmatch.fnmatchcase(changed, pattern))
        if matches:
            matched.append({"path": changed, "patterns": matches})
    return {"registered": explicit, "matched_changed_files": matched}


def _valid_baseline_record(report: dict[str, Any], baseline_sha: str | None) -> dict[str, Any]:
    if report is None:
        return {"provided": False, "sha256": None, "valid": False, "schema": None, "issues": ["no baseline supplied"]}
    tests = report.get("tests")
    issues = []
    if report.get("schema") != RESULT_SCHEMA:
        issues.append("baseline schema mismatch")
    if not isinstance(tests, list):
        issues.append("baseline tests must be an array")
    if not isinstance(report.get("passed"), bool):
        issues.append("baseline passed field must be boolean")
    if report.get("infrastructure_failure"):
        issues.append("baseline report contains a runner-level infrastructure failure")
    if report.get("baseline_read_error"):
        issues.append(str(report["baseline_read_error"]))
    return {
        "provided": True,
        "sha256": baseline_sha,
        "valid": not issues,
        "schema": report.get("schema"),
        "passed": report.get("passed") if isinstance(report.get("passed"), bool) else None,
        "selected_ids": sorted(str(item.get("id")) for item in tests if isinstance(item, dict) and item.get("id")) if isinstance(tests, list) else [],
        "issues": issues,
    }


def _baseline_match(item: dict[str, Any], baseline: dict[str, Any] | None, baseline_meta: dict[str, Any]) -> dict[str, Any]:
    candidate_id = item.get("id")
    if baseline is None:
        return {"status": "unavailable", "test_id": candidate_id, "tier": item.get("tier"), "result": None}
    if not baseline_meta["valid"]:
        return {"status": "invalid-baseline", "test_id": candidate_id, "tier": item.get("tier"), "result": None}
    if not candidate_id:
        return {"status": "runner-level-no-test-identity", "test_id": None, "tier": None, "result": None}
    records = [entry for entry in baseline.get("tests", []) if isinstance(entry, dict) and entry.get("id") == candidate_id]
    if len(records) != 1:
        status = "missing-test" if not records else "ambiguous-test"
        return {"status": status, "test_id": candidate_id, "tier": item.get("tier"), "result": None}
    entry = records[0]
    if entry.get("tier") != item.get("tier") or entry.get("status") not in {"passed", *ISSUE_STATUSES}:
        return {"status": "mismatched-test", "test_id": candidate_id, "tier": item.get("tier"), "result": None}
    return {
        "status": "matched", "test_id": candidate_id, "tier": item.get("tier"),
        "result": {"status": entry.get("status"), "exit_code": entry.get("exit_code")},
    }


def _classification(status: str, match: dict[str, Any]) -> str:
    # A skip is not an observed failure or a pass. Baseline state cannot convert it.
    if status == "skipped":
        return "unknown"
    if status not in BLOCKING_STATUSES or match.get("status") != "matched":
        return "unknown"
    baseline_status = match["result"]["status"]
    if baseline_status in BLOCKING_STATUSES:
        return "baseline-red"
    if baseline_status == "passed":
        return "candidate-only-red"
    return "unknown"


def _duration_evidence(item: dict[str, Any], manifest_test: dict[str, Any] | None) -> dict[str, Any]:
    duration_ms = item.get("duration_ms") if isinstance(item.get("duration_ms"), (int, float)) else None
    timeout = item.get("timeout_sec")
    if not isinstance(timeout, (int, float)) and manifest_test is not None:
        timeout = manifest_test.get("timeout_sec", 30)
    if not isinstance(timeout, (int, float)):
        timeout = None
    return {
        "duration_ms": duration_ms,
        "timeout_sec": timeout,
        "within_timeout": (duration_ms < timeout * 1000) if duration_ms is not None and timeout is not None else None,
    }


def _issue_record(item: dict[str, Any], manifest: dict[str, dict[str, Any]], candidate: dict[str, Any],
                  baseline: dict[str, Any] | None, baseline_meta: dict[str, Any]) -> dict[str, Any]:
    test_id = item.get("id")
    spec = manifest.get(str(test_id)) if test_id else None
    status = str(item.get("status", "infrastructure_error"))
    changed_files = candidate.get("changed_files", [])
    if not isinstance(changed_files, list):
        changed_files = []
    match = _baseline_match(item, baseline, baseline_meta)
    runner_level = not test_id
    failure_diagnostics = {
        "failures": item.get("failures", []),
        "warnings": item.get("warnings", []),
        "launch_error": item.get("launch_error"),
        "stdout_tail": item.get("stdout_tail", []),
        "stderr_tail": item.get("stderr_tail", []),
    }
    owners = _manifest_owners(spec, changed_files)
    return {
        "test_id": test_id,
        "tier": item.get("tier"),
        "status": status,
        "exit_code": item.get("exit_code"),
        "blocking": status in CANDIDATE_NON_PASS_STATUSES or runner_level,
        "selection_reasons": item.get("selection_reasons", []),
        "owners": owners,
        "manifest_rule": ({
            "id": spec.get("id"), "tier": spec.get("tier"), "type": spec.get("type"),
            "script": spec.get("script"), "timeout_sec": spec.get("timeout_sec", 30),
            "needs_import": spec.get("needs_import", False), "tags": sorted(spec.get("tags", [])),
            "matched_owner_patterns": sorted({pattern for match in owners["matched_changed_files"] for pattern in match["patterns"]}),
        } if spec is not None else None),
        "duration": _duration_evidence(item, spec),
        "skip": ({"reason": item.get("skip_reason"), "blocked_by_tier": item.get("blocked_by_tier")}
                 if status == "skipped" else None),
        "failure_diagnostics": failure_diagnostics,
        "baseline_match": match,
        "classification": "unknown" if runner_level else _classification(status, match),
        # This is intentionally always blocking for red results, regardless of attribution.
        "candidate_remains_blocking": status in CANDIDATE_NON_PASS_STATUSES or runner_level,
    }


def build_triage(candidate: dict[str, Any], candidate_sha: str,
                 baseline: dict[str, Any] | None = None, baseline_sha: str | None = None,
                 manifest_tests: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    if candidate.get("schema") != RESULT_SCHEMA:
        raise TriageInputError(f"candidate schema must be {RESULT_SCHEMA}")
    tests = candidate.get("tests", [])
    if not isinstance(tests, list):
        tests = []
    manifest = _manifest_index(manifest_tests if manifest_tests is not None else load_manifest())
    baseline_meta = _valid_baseline_record(baseline, baseline_sha)
    issues = []
    for item in tests:
        if isinstance(item, dict) and item.get("status") in ISSUE_STATUSES:
            issues.append(_issue_record(item, manifest, candidate, baseline, baseline_meta))
    if candidate.get("infrastructure_failure") or candidate.get("configuration_error"):
        runner_item = {
            "id": None, "tier": None, "status": "infrastructure_error", "exit_code": None,
            "duration_ms": None, "selection_reasons": ["runner-level"], "failures": [], "warnings": [],
            "launch_error": None, "stdout_tail": [], "stderr_tail": [],
        }
        issues.append(_issue_record(runner_item, manifest, candidate, baseline, baseline_meta))
        issues[-1]["failure_diagnostics"]["runner_error"] = {
            "infrastructure_failure": candidate.get("infrastructure_failure"),
            "configuration_error": candidate.get("configuration_error"),
            "message": candidate.get("message"),
            "import": candidate.get("import"),
            "error": candidate.get("error"),
        }
    coverage = candidate.get("coverage", {})
    if isinstance(coverage, dict) and coverage.get("complete") is False:
        issues.append({
            "test_id": None, "tier": None, "status": "coverage_error", "exit_code": None,
            "blocking": True, "selection_reasons": ["changed-file-coverage"],
            "owners": {"registered": [], "matched_changed_files": []},
            "duration": {"duration_ms": None, "timeout_sec": None, "within_timeout": None},
            "skip": None,
            "failure_diagnostics": {"uncovered_files": coverage.get("uncovered_files", [])},
            "baseline_match": {"status": "not-applicable", "test_id": None, "tier": None, "result": None},
            "classification": "unknown", "candidate_remains_blocking": True,
        })
    if candidate.get("passed") is False and not issues:
        issues.append({
            "test_id": None, "tier": None, "status": "runner-result-error", "exit_code": None,
            "blocking": True, "selection_reasons": ["canonical-runner-result"],
            "owners": {"registered": [], "matched_changed_files": []}, "manifest_rule": None,
            "duration": {"duration_ms": None, "timeout_sec": None, "within_timeout": None},
            "skip": None, "failure_diagnostics": {"message": "candidate report is red without a typed failing, skipped, infrastructure, or coverage result"},
            "baseline_match": {"status": "not-applicable", "test_id": None, "tier": None, "result": None},
            "classification": "unknown", "candidate_remains_blocking": True,
        })
    issues.sort(key=lambda issue: (TIER_ORDER.get(issue.get("tier"), -1), issue.get("test_id") or "", issue["status"]))
    counts = Counter(issue["status"] for issue in issues)
    report = {
        "schema": TRIAGE_SCHEMA,
        "manifest_provenance": {
            "path": MANIFEST_PATH.relative_to(MANIFEST_PATH.parents[3]).as_posix(),
            "sha256": hashlib.sha256(MANIFEST_PATH.read_bytes()).hexdigest(),
        },
        "candidate": {
            "sha256": candidate_sha,
            "schema": candidate.get("schema"),
            "passed": candidate.get("passed") if isinstance(candidate.get("passed"), bool) else None,
            "summary": candidate.get("summary"),
            "selected_ids": sorted(str(value) for value in candidate.get("selected", []) if isinstance(value, (str, int))),
            "changed_files": sorted(set(candidate.get("changed_files", []))) if isinstance(candidate.get("changed_files"), list) else [],
            "coverage_complete": coverage.get("complete") if isinstance(coverage, dict) else None,
        },
        "baseline": baseline_meta,
        "issues": issues,
        "summary": {
            "issue_count": len(issues),
            "status_counts": dict(sorted(counts.items())),
            "baseline_red_count": sum(i["classification"] == "baseline-red" for i in issues),
            "candidate_only_red_count": sum(i["classification"] == "candidate-only-red" for i in issues),
            "unknown_attribution_count": sum(i["classification"] == "unknown" for i in issues),
            "candidate_blocking_count": sum(bool(i["candidate_remains_blocking"]) for i in issues),
        },
        "triage_passed": candidate.get("passed") is True and not any(issue["candidate_remains_blocking"] for issue in issues),
    }
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path, help="canonical run_validation.py JSON result")
    parser.add_argument("--baseline", type=Path, help="explicit immutable baseline result JSON")
    parser.add_argument("--json", action="store_true", help="emit deterministic JSON (default output)")
    args = parser.parse_args(argv)
    try:
        candidate, candidate_sha = read_report(args.candidate)
        if args.baseline:
            try:
                baseline, baseline_sha = read_report(args.baseline)
            except (OSError, TriageInputError) as exc:
                try:
                    raw = args.baseline.read_bytes()
                    baseline_sha = hashlib.sha256(raw).hexdigest()
                except OSError:
                    baseline_sha = None
                baseline = {"schema": None, "tests": None, "baseline_read_error": str(exc)}
        else:
            baseline, baseline_sha = None, None
        result = build_triage(candidate, candidate_sha, baseline, baseline_sha)
        result["candidate"]["source"] = args.candidate.as_posix()
        result["baseline"]["source"] = args.baseline.as_posix() if args.baseline else None
    except (OSError, TriageInputError, json.JSONDecodeError) as exc:
        print(json.dumps({"schema": TRIAGE_SCHEMA, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False))
    # Attribution never turns a red candidate into a green command result.
    return 0 if result["triage_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
