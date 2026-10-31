#!/usr/bin/env python3
"""Manifest-driven, machine-readable CUSTODIAN validation runner."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import signal
import subprocess
from contextlib import nullcontext
import sys
import time
from pathlib import Path
from pathlib import PurePosixPath
from typing import Any

VALIDATION_DIR = Path(__file__).resolve().parent
CUSTODIAN_DIR = VALIDATION_DIR.parents[1]
REPO_ROOT = CUSTODIAN_DIR.parent

sys.path.insert(0, str(CUSTODIAN_DIR / "tools"))
from godot_project_lock import (  # noqa: E402
    GodotJobBudget, GodotProjectBusy, GodotProjectLock, godot_home,
    inherited_godot_lock_fds,
)
sys.path.insert(0, str(CUSTODIAN_DIR / "tools" / "pipelines"))
from godot_import_preflight import preflight_detail  # noqa: E402
ITERATION_DIR = CUSTODIAN_DIR / "tools" / "iteration"
sys.path.insert(0, str(ITERATION_DIR))
from changed_file_router import changed_files  # noqa: E402

MANIFEST_PATH = VALIDATION_DIR / "validation_manifest.json"
WARNINGS_PATH = VALIDATION_DIR / "known_headless_warnings.json"
TIERS = ("unit", "actor", "integration", "moment", "boot")
TYPES = {"godot_script", "python", "moment"}
RESULT_PREFIX = "CUSTODIAN_TEST_RESULT_JSON:"
EXIT_CONFIG, EXIT_PREFLIGHT, EXIT_FAILED, EXIT_TIMEOUT, EXIT_COVERAGE = 2, 3, 4, 5, 6
EXIT_LOCK = 7
TAIL_LINES = 40
IMPORT_TIMEOUT_SEC = 120
FATAL_DIAGNOSTICS = (
    re.compile(r"\bERROR:"),
    re.compile(r"\bSCRIPT ERROR:"),
    re.compile(r"\bParse Error:"),
    re.compile(r"Failed (?:to load|loading) resource", re.IGNORECASE),
    re.compile(r"GDExtension.*(?:not found|failed|could not be loaded)", re.IGNORECASE),
)
HARD_FATAL_DIAGNOSTICS = FATAL_DIAGNOSTICS[1:]


class ManifestError(ValueError):
    pass


def owner_patterns(test: dict[str, Any]) -> list[str]:
    patterns = [str(value) for value in test.get("owners", [])]
    script = str(test.get("script", ""))
    if script.startswith("res://"):
        patterns.append("custodian/" + script.removeprefix("res://"))
    elif script:
        patterns.append(script)
    if test.get("type") == "moment":
        patterns.append(f"custodian/tools/iteration/scenarios/{test['scenario']}.json")
    return patterns


def load_manifest(path: Path = MANIFEST_PATH) -> list[dict[str, Any]]:
    payload = load_manifest_payload(path)
    if payload.get("schema_version") != 1 or not isinstance(payload.get("tests"), list):
        raise ManifestError("unsupported validation manifest")
    ids: set[str] = set()
    tests: list[dict[str, Any]] = []
    for raw in payload["tests"]:
        test = dict(raw)
        test_id = str(test.get("id", ""))
        if not test_id or test_id in ids:
            raise ManifestError(f"missing or duplicate test id: {test_id}")
        if test.get("type") not in TYPES:
            raise ManifestError(f"{test_id}: invalid test type")
        if test.get("tier") not in TIERS:
            raise ManifestError(f"{test_id}: invalid tier")
        if test["type"] in {"godot_script", "python"}:
            script = str(test.get("script", ""))
            resolved = CUSTODIAN_DIR / script.removeprefix("res://") if script.startswith("res://") else REPO_ROOT / script
            if not resolved.is_file():
                raise ManifestError(f"{test_id}: missing script {script}")
        if test["type"] == "moment" and not test.get("scenario"):
            raise ManifestError(f"{test_id}: missing scenario")
        ids.add(test_id)
        tests.append(test)
    return tests


def load_manifest_payload(path: Path = MANIFEST_PATH) -> dict[str, Any]:
    payload = parse_manifest_json(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ManifestError("validation manifest must be an object")
    return payload


def parse_manifest_json(contents: str) -> Any:
    def unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise ManifestError(f"ambiguous duplicate manifest key: {key}")
            result[key] = value
        return result
    return json.loads(contents, object_pairs_hook=unique_object)


def manifest_change_selection(tests: list[dict[str, Any]], *, base_payload: dict[str, Any],
                              current_payload: dict[str, Any]) -> tuple[set[str], bool]:
    """Return changed test IDs and whether the manifest itself changed.

    Global configuration and removals are intentionally rejected: they need an
    explicit broad validation decision rather than being hidden by routing.
    """
    if base_payload == current_payload:
        return set(), False
    base_global = {key: value for key, value in base_payload.items() if key != "tests"}
    current_global = {key: value for key, value in current_payload.items() if key != "tests"}
    if base_global != current_global:
        raise ManifestError("global validation manifest configuration changed; broad validation required")

    def indexed(payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
        raw = payload.get("tests")
        if not isinstance(raw, list):
            raise ManifestError("validation manifest tests must be an array")
        result: dict[str, dict[str, Any]] = {}
        for item in raw:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"]:
                raise ManifestError("ambiguous validation manifest test definition")
            if item["id"] in result:
                raise ManifestError(f"ambiguous duplicate validation test id: {item['id']}")
            result[item["id"]] = item
        return result

    before, after = indexed(base_payload), indexed(current_payload)
    removed = sorted(before.keys() - after.keys())
    if removed:
        raise ManifestError("validation test definitions removed; broad validation required: " + ", ".join(removed))
    changed = {test_id for test_id, definition in after.items() if before.get(test_id) != definition}
    return changed, True


def base_manifest_payload(base: str | None, repo_root: Path = REPO_ROOT) -> dict[str, Any]:
    if not base:
        result = subprocess.run(["git", "show", f"HEAD:{MANIFEST_PATH.relative_to(REPO_ROOT).as_posix()}"],
                                cwd=repo_root, capture_output=True, text=True)
        if result.returncode:
            raise ManifestError("cannot load base validation manifest from HEAD")
        try:
            payload = parse_manifest_json(result.stdout)
        except json.JSONDecodeError as error:
            raise ManifestError(f"malformed base validation manifest: {error}") from error
        if not isinstance(payload, dict):
            raise ManifestError("base validation manifest must be an object")
        return payload
    merge = subprocess.run(["git", "merge-base", base, "HEAD"], cwd=repo_root, capture_output=True, text=True)
    if merge.returncode or len(merge.stdout.splitlines()) != 1:
        raise ManifestError("ambiguous or unavailable base for validation manifest comparison")
    result = subprocess.run(["git", "show", f"{merge.stdout.strip()}:{MANIFEST_PATH.relative_to(REPO_ROOT).as_posix()}"],
                            cwd=repo_root, capture_output=True, text=True)
    if result.returncode:
        raise ManifestError("cannot load base validation manifest")
    try:
        payload = parse_manifest_json(result.stdout)
    except json.JSONDecodeError as error:
        raise ManifestError(f"malformed base validation manifest: {error}") from error
    if not isinstance(payload, dict):
        raise ManifestError("base validation manifest must be an object")
    return payload


def select_changed_tests(tests: list[dict[str, Any]], files: list[str], *, manifest_ids: set[str] = frozenset(),
                         manifest_changed: bool = False) -> list[dict[str, Any]]:
    source_files = [path for path in files if path != MANIFEST_PATH.relative_to(REPO_ROOT).as_posix()]
    selected = {item["id"]: item for item in select_tests(tests, files=source_files)}
    by_id = {item["id"]: item for item in tests}
    if manifest_changed:
        for test_id in manifest_ids:
            if test_id not in by_id:
                raise ManifestError(f"changed test definition is not loadable: {test_id}")
            selected[test_id] = dict(by_id[test_id], selection_reasons=[f"manifest_definition:{test_id}"])
        for test in tests:
            if "validation" in test.get("tags", []) and test["id"] in {"validation_runner", "validation_manifest_diff_selection"}:
                selected.setdefault(test["id"], dict(test, selection_reasons=["manifest_self_check"]))
    return sorted(selected.values(), key=lambda item: (TIERS.index(item["tier"]), item["id"]))


def load_coverage_excludes(path: Path = MANIFEST_PATH) -> list[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    values = payload.get("coverage_excludes", [])
    if not isinstance(values, list) or any(not isinstance(value, str) for value in values):
        raise ManifestError("coverage_excludes must be an array of globs")
    return values


def changed_file_coverage(files: list[str], tests: list[dict[str, Any]], excludes: list[str]) -> dict[str, Any]:
    excluded = sorted(path for path in files if any(fnmatch.fnmatchcase(path, pattern) for pattern in excludes))
    candidates = [path for path in files if path not in excluded]
    covered_by: dict[str, list[str]] = {}
    for path in candidates:
        owners = sorted(test["id"] for test in tests if any(
            fnmatch.fnmatchcase(path, pattern) for pattern in owner_patterns(test)
        ))
        if owners:
            covered_by[path] = owners
    covered = sorted(covered_by)
    uncovered = sorted(set(candidates).difference(covered))
    return {
        "covered_files": covered,
        "uncovered_files": uncovered,
        "excluded_files": excluded,
        "covered_by": covered_by,
        "complete": not uncovered,
    }


def exact_changed_paths(raw_paths: list[str]) -> list[str]:
    """Validate and normalize an explicitly authenticated changed-file inventory."""
    files = []
    for raw_path in raw_paths:
        path = PurePosixPath(raw_path)
        if (not raw_path or path.is_absolute() or "\\" in raw_path
                or any(part in {"", ".", ".."} for part in raw_path.split("/"))
                or path.as_posix() != raw_path):
            raise ValueError(f"invalid repository-relative --changed-path: {raw_path!r}")
        files.append(raw_path)
    if len(files) != len(set(files)):
        raise ValueError("--changed-path values must be unique")
    return sorted(files)


def select_tests(tests: list[dict[str, Any]], *, files: list[str] | None = None,
                 tag: str | None = None, test_id: str | None = None,
                 tier: str | None = None, max_tier: str | None = None) -> list[dict[str, Any]]:
    selected = []
    for test in tests:
        reasons: list[str] = []
        if files is not None:
            matched = sorted({path for path in files if any(fnmatch.fnmatchcase(path, owner) for owner in owner_patterns(test))})
            if not matched:
                continue
            reasons.extend(f"owner:{path}" for path in matched)
        if tag and tag not in test.get("tags", []):
            continue
        if test_id and test["id"] != test_id:
            continue
        if tier and test["tier"] != tier:
            continue
        if max_tier and TIERS.index(test["tier"]) > TIERS.index(max_tier):
            continue
        item = dict(test)
        item["selection_reasons"] = reasons or ["explicit_filter"]
        selected.append(item)
    return sorted(selected, key=lambda item: (TIERS.index(item["tier"]), item["id"]))


def parse_harness_result(stdout: str) -> dict[str, Any] | None:
    for line in reversed(stdout.splitlines()):
        if line.startswith(RESULT_PREFIX):
            try:
                return json.loads(line[len(RESULT_PREFIX):])
            except json.JSONDecodeError:
                return None
    return None


def _tail(text: str) -> list[str]:
    return text.splitlines()[-TAIL_LINES:]


def load_warning_patterns(path: Path = WARNINGS_PATH, test_ids: set[str] | None = None) -> list[dict[str, str]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema_version") != 1:
        raise ManifestError("unsupported headless warning registry")
    raw_patterns = payload.get("patterns", [])
    if not isinstance(raw_patterns, list):
        raise ManifestError("headless warning patterns must be an array")
    patterns: list[dict[str, str]] = []
    ids: set[str] = set()
    for raw in raw_patterns:
        if not isinstance(raw, dict):
            raise ManifestError("headless warning pattern must be an object")
        item = dict(raw)
        pattern_id = item.get("id")
        expression = item.get("pattern")
        owner = item.get("test_id")
        if not isinstance(pattern_id, str) or not pattern_id or pattern_id in ids:
            raise ManifestError("headless warning pattern ids must be unique non-empty strings")
        if not isinstance(expression, str) or not expression:
            raise ManifestError(f"{pattern_id}: warning pattern must be a non-empty regex")
        try:
            re.compile(expression)
        except re.error as error:
            raise ManifestError(f"{pattern_id}: invalid warning regex: {error}") from error
        if owner is not None and (not isinstance(owner, str) or not owner):
            raise ManifestError(f"{pattern_id}: test_id must be a non-empty string")
        if owner is not None and test_ids is not None and owner not in test_ids:
            raise ManifestError(f"{pattern_id}: expected error references unknown test {owner}")
        ids.add(pattern_id)
        patterns.append(item)
    return patterns


def classify_warnings(stderr: str, patterns: list[dict[str, str]], test_id: str | None = None) -> list[dict[str, str]]:
    output = []
    for line in stderr.splitlines():
        fatal = any(marker.search(line) for marker in FATAL_DIAGNOSTICS)
        hard_fatal = any(marker.search(line) for marker in HARD_FATAL_DIAGNOSTICS)
        if not fatal and "WARNING:" not in line:
            continue
        matching = [item for item in patterns if re.search(item["pattern"], line)]
        expected = next((item for item in matching if item.get("test_id") == test_id and test_id is not None), None)
        known = next((item for item in matching if not item.get("test_id")), None)
        output.append({
            "classification": "expected_error" if expected else (
                "fatal" if hard_fatal or (fatal and not known) else ("known_warning" if known else "new_warning")
            ),
            "pattern_id": expected["id"] if expected else (known["id"] if known else ""),
            "line": line,
        })
    return output


def command_for(test: dict[str, Any]) -> tuple[list[str], Path]:
    if test["type"] == "godot_script":
        return ["godot", "--headless", "--path", ".", "--script", test["script"]], CUSTODIAN_DIR
    if test["type"] == "python":
        return [sys.executable, str(REPO_ROOT / test["script"])], REPO_ROOT
    if test["type"] == "moment":
        return [sys.executable, str(ITERATION_DIR / "run_moment.py"), test["scenario"], "--capture-mode", "none"], REPO_ROOT
    raise ManifestError(f"unsupported executable type: {test['type']}")


def execute_test(test: dict[str, Any], patterns: list[dict[str, str]], command: list[str] | None = None) -> dict[str, Any]:
    resolved_command, cwd = command_for(test) if command is None else (command, REPO_ROOT)
    env = os.environ.copy()
    env["HOME"] = str(godot_home())
    started = time.monotonic()
    timed_out = False
    try:
        process = subprocess.Popen(resolved_command, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, start_new_session=True,
                                   pass_fds=inherited_godot_lock_fds())
    except OSError as error:
        return {
            "id": test["id"], "tier": test["tier"], "status": "infrastructure_error", "exit_code": None,
            "duration_ms": round((time.monotonic() - started) * 1000), "timeout_sec": None,
            "selection_reasons": test.get("selection_reasons", []), "failures": [], "structured_result": None,
            "warnings": [], "stdout_tail": [], "stderr_tail": [], "launch_error": str(error),
        }
    try:
        stdout, stderr = process.communicate(timeout=float(test.get("timeout_sec", 30)))
        exit_code = process.returncode
    except subprocess.TimeoutExpired as error:
        timed_out = True
        os.killpg(process.pid, signal.SIGKILL)
        remaining_stdout, remaining_stderr = process.communicate()
        exit_code = None
        stdout = remaining_stdout
        stderr = remaining_stderr
    harness = parse_harness_result(stdout)
    sentinel_seen = any(line.startswith(RESULT_PREFIX) for line in stdout.splitlines())
    malformed_sentinel = sentinel_seen and harness is None
    warnings = classify_warnings(stderr, patterns, str(test.get("id", "")))
    structured_failed = harness is not None and not bool(harness.get("passed", False))
    fatal_stderr = any(item["classification"] == "fatal" for item in warnings)
    status = "timeout" if timed_out else (
        "failed" if exit_code != 0 or structured_failed or malformed_sentinel or fatal_stderr else "passed"
    )
    failures = harness.get("failures", []) if harness else []
    if malformed_sentinel:
        failures = [{"message": "malformed structured test result sentinel", "evidence": {}}]
    return {
        "id": test["id"], "tier": test["tier"], "status": status, "exit_code": exit_code,
        "duration_ms": round((time.monotonic() - started) * 1000),
        "timeout_sec": test.get("timeout_sec") if timed_out else None,
        "selection_reasons": test.get("selection_reasons", []),
        "failures": failures,
        "structured_result": harness,
        "warnings": warnings,
        "stdout_tail": [] if harness and status == "passed" else _tail(stdout),
        "stderr_tail": _tail(stderr),
    }


def _run_import(timeout_sec: float = IMPORT_TIMEOUT_SEC, command: list[str] | None = None,
                patterns: list[dict[str, str]] | None = None) -> tuple[bool, dict[str, Any]]:
    env = os.environ.copy(); env["HOME"] = str(godot_home())
    resolved = command or ["godot", "--headless", "--path", str(CUSTODIAN_DIR), "--import", "--quit"]
    try:
        process = subprocess.Popen(resolved, cwd=REPO_ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, start_new_session=True,
                                   pass_fds=inherited_godot_lock_fds())
        try:
            stdout, stderr = process.communicate(timeout=timeout_sec)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate()
            return False, {"status": "timeout", "timeout_sec": timeout_sec, "exit_code": None,
                           "stdout_tail": _tail(stdout), "stderr_tail": _tail(stderr)}
    except OSError as error:
        return False, {"status": "launch_error", "exit_code": None, "error": str(error),
                       "stdout_tail": [], "stderr_tail": []}
    warnings = classify_warnings(stderr, patterns if patterns is not None else load_warning_patterns())
    fatal_diagnostics = any(item["classification"] == "fatal" for item in warnings)
    ok = process.returncode == 0 and not fatal_diagnostics
    return ok, {"status": "passed" if ok else "failed", "exit_code": process.returncode,
                "warnings": warnings, "stdout_tail": _tail(stdout), "stderr_tail": _tail(stderr)}


def execute_tiered(selected: list[dict[str, Any]], patterns: list[dict[str, str]],
                   executor: Any = execute_test) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    blocked_by = ""
    for tier in TIERS:
        tier_tests = [test for test in selected if test["tier"] == tier]
        if blocked_by:
            results.extend({
                "id": test["id"], "tier": tier, "status": "skipped", "exit_code": None, "duration_ms": 0,
                "timeout_sec": None, "selection_reasons": test.get("selection_reasons", []), "failures": [],
                "structured_result": None, "warnings": [], "stdout_tail": [], "stderr_tail": [],
                "skip_reason": "lower_tier_failed", "blocked_by_tier": blocked_by,
            } for test in tier_tests)
            continue
        tier_results = [executor(test, patterns) for test in tier_tests]
        results.extend(tier_results)
        if any(result["status"] in {"failed", "timeout", "infrastructure_error"} for result in tier_results):
            blocked_by = tier
    return results


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changed", action="store_true")
    parser.add_argument(
        "--changed-path", action="append", default=None,
        help="use this exact repository-relative changed-file inventory (repeatable)",
    )
    parser.add_argument("--base")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--tag")
    parser.add_argument("--test")
    parser.add_argument("--tier", choices=TIERS)
    parser.add_argument("--max-tier", choices=TIERS)
    parser.add_argument("--list", action="store_true")
    parser.add_argument(
        "--no-godot-lock", action="store_true",
        help="skip the machine-wide Godot project lock (debugging a stuck lock only)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        tests = load_manifest(); patterns = load_warning_patterns(test_ids={test["id"] for test in tests}); coverage_excludes = load_coverage_excludes()
    except (OSError, json.JSONDecodeError, ManifestError) as error:
        print(json.dumps({"schema": "custodian.validation.result.v1", "passed": False, "configuration_error": str(error)}))
        return EXIT_CONFIG
    if args.list:
        print(json.dumps(tests, indent=2) if args.json else "\n".join(f"{t['tier']:11} {t['id']}" for t in tests))
        return 0
    if args.changed_path is not None and not args.changed:
        parser.error("--changed-path requires --changed")
    if args.changed_path is not None:
        try:
            files = exact_changed_paths(args.changed_path)
        except ValueError as error:
            parser.error(str(error))
    else:
        files = changed_files(args.base, REPO_ROOT) if args.changed else None
    manifest_ids: set[str] = set()
    manifest_changed = False
    if files is not None and MANIFEST_PATH.relative_to(REPO_ROOT).as_posix() in files:
        try:
            manifest_ids, manifest_changed = manifest_change_selection(
                tests, base_payload=base_manifest_payload(args.base), current_payload=load_manifest_payload()
            )
        except (OSError, ManifestError) as error:
            print(json.dumps({"schema": "custodian.validation.result.v1", "passed": False,
                              "configuration_error": str(error)}))
            return EXIT_CONFIG
    coverage = changed_file_coverage(files, tests, coverage_excludes) if files is not None else {
        "covered_files": [], "uncovered_files": [], "excluded_files": [], "covered_by": {}, "complete": True,
    }
    if files is not None and not any([args.tag, args.test, args.tier]):
        selected = select_changed_tests(tests, files, manifest_ids=manifest_ids, manifest_changed=manifest_changed)
        if args.max_tier:
            selected = [item for item in selected if TIERS.index(item["tier"]) <= TIERS.index(args.max_tier)]
    else:
        selected = select_tests(tests, files=files, tag=args.tag, test_id=args.test, tier=args.tier, max_tier=args.max_tier)
    if not any([args.changed, args.tag, args.test, args.tier]):
        print("select tests with --changed, --tag, --test, or --tier", file=sys.stderr)
        return EXIT_CONFIG
    if args.test and not selected:
        payload = {"schema": "custodian.validation.result.v1", "passed": False, "configuration_error": f"unknown test id: {args.test}"}
        print(json.dumps(payload) if args.json else payload["configuration_error"])
        return EXIT_CONFIG
    # The import step and the tests that load its output are one critical
    # section: a second process importing the same project mid-run does not fail
    # cleanly, it stalls the import until it times out.
    lock = nullcontext() if args.no_godot_lock else GodotProjectLock(
        CUSTODIAN_DIR, "run_validation (%d checks)" % len(selected)
    )
    try:
        with lock, GodotJobBudget("run_validation (%d checks)" % len(selected)):
            if any(bool(test.get("needs_import")) for test in selected):
                preflight_failure = preflight_detail(CUSTODIAN_DIR)
                if preflight_failure:
                    result = {
                        "schema": "custodian.validation.result.v1",
                        "passed": False,
                        "infrastructure_failure": "import_preflight",
                        "message": preflight_failure,
                    }
                    print(json.dumps(result) if args.json else preflight_failure)
                    return EXIT_PREFLIGHT
                ok, import_result = _run_import(patterns=patterns)
                if not ok:
                    print(json.dumps({"schema":"custodian.validation.result.v1","passed":False,"infrastructure_failure":"import","import":import_result}))
                    return EXIT_PREFLIGHT
            results = execute_tiered(selected, patterns)
    except (GodotProjectBusy, ValueError, RuntimeError) as error:
        print(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": False,
            "infrastructure_failure": "godot_project_busy", "error": str(error),
        }))
        return EXIT_LOCK
    payload = {
        "schema": "custodian.validation.result.v1",
        "passed": bool(coverage["complete"]) and all(item["status"] == "passed" for item in results),
        "changed_files": files or [], "coverage": coverage,
        "selected": [item["id"] for item in selected], "tests": results,
        "summary": {"selected": len(results), "passed": sum(r["status"] == "passed" for r in results),
                    "failed": sum(r["status"] == "failed" for r in results), "timed_out": sum(r["status"] == "timeout" for r in results),
                    "skipped": sum(r["status"] == "skipped" for r in results),
                    "infrastructure_errors": sum(r["status"] == "infrastructure_error" for r in results)},
    }
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print("CUSTODIAN VALIDATION\n")
        for result in results:
            print(f"{result['status'].upper():7} {result['tier']}/{result['id']}  {result['duration_ms']} ms")
            for warning in result["warnings"]:
                if warning["classification"] != "known_warning":
                    print(f"  {warning['classification'].upper()}: {warning['line']}")
        if not coverage["complete"]:
            print("\nCOVERAGE GAP")
            for path in coverage["uncovered_files"]:
                print(f"  {path}")
        print(f"\n{len(results)} selected\n{payload['summary']['passed']} passed\n{payload['summary']['failed']} failed")
    if payload["summary"]["infrastructure_errors"]:
        return EXIT_PREFLIGHT
    if payload["summary"]["timed_out"]:
        return EXIT_TIMEOUT
    if payload["summary"]["failed"]:
        return EXIT_FAILED
    if not coverage["complete"]:
        return EXIT_COVERAGE
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
