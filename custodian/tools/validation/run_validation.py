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
import sys
import time
from pathlib import Path
from typing import Any

VALIDATION_DIR = Path(__file__).resolve().parent
CUSTODIAN_DIR = VALIDATION_DIR.parents[1]
REPO_ROOT = CUSTODIAN_DIR.parent
ITERATION_DIR = CUSTODIAN_DIR / "tools" / "iteration"
sys.path.insert(0, str(ITERATION_DIR))
from changed_file_router import changed_files  # noqa: E402

MANIFEST_PATH = VALIDATION_DIR / "validation_manifest.json"
WARNINGS_PATH = VALIDATION_DIR / "known_headless_warnings.json"
TIERS = ("unit", "actor", "integration", "moment", "boot")
TYPES = {"godot_script", "python", "moment"}
RESULT_PREFIX = "CUSTODIAN_TEST_RESULT_JSON:"
EXIT_CONFIG, EXIT_PREFLIGHT, EXIT_FAILED, EXIT_TIMEOUT = 2, 3, 4, 5
TAIL_LINES = 40


class ManifestError(ValueError):
    pass


def load_manifest(path: Path = MANIFEST_PATH) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
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


def select_tests(tests: list[dict[str, Any]], *, files: list[str] | None = None,
                 tag: str | None = None, test_id: str | None = None,
                 tier: str | None = None, max_tier: str | None = None) -> list[dict[str, Any]]:
    selected = []
    for test in tests:
        reasons: list[str] = []
        if files is not None:
            matched = sorted({path for path in files if any(fnmatch.fnmatchcase(path, owner) for owner in test.get("owners", []))})
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


def load_warning_patterns(path: Path = WARNINGS_PATH) -> list[dict[str, str]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema_version") != 1:
        raise ManifestError("unsupported headless warning registry")
    return [dict(item) for item in payload.get("patterns", [])]


def classify_warnings(stderr: str, patterns: list[dict[str, str]]) -> list[dict[str, str]]:
    output = []
    for line in stderr.splitlines():
        if "WARNING:" not in line and "ERROR:" not in line:
            continue
        known = next((item for item in patterns if re.search(item["pattern"], line)), None)
        output.append({
            "classification": "known_warning" if known else ("fatal" if "ERROR:" in line else "new_warning"),
            "pattern_id": known["id"] if known else "",
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
    env["HOME"] = "/tmp/custodian-godot-home"
    started = time.monotonic()
    timed_out = False
    process = subprocess.Popen(resolved_command, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, start_new_session=True)
    try:
        stdout, stderr = process.communicate(timeout=float(test.get("timeout_sec", 30)))
        exit_code = process.returncode
    except subprocess.TimeoutExpired as error:
        timed_out = True
        os.killpg(process.pid, signal.SIGKILL)
        remaining_stdout, remaining_stderr = process.communicate()
        exit_code = None
        prefix_stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or "")
        prefix_stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        stdout = prefix_stdout + remaining_stdout
        stderr = prefix_stderr + remaining_stderr
    harness = parse_harness_result(stdout)
    status = "timeout" if timed_out else ("passed" if exit_code == 0 else "failed")
    return {
        "id": test["id"], "tier": test["tier"], "status": status, "exit_code": exit_code,
        "duration_ms": round((time.monotonic() - started) * 1000),
        "timeout_sec": test.get("timeout_sec") if timed_out else None,
        "selection_reasons": test.get("selection_reasons", []),
        "failures": harness.get("failures", []) if harness else [],
        "structured_result": harness,
        "warnings": classify_warnings(stderr, patterns),
        "stdout_tail": [] if harness and status == "passed" else _tail(stdout),
        "stderr_tail": _tail(stderr),
    }


def _run_import() -> tuple[bool, dict[str, Any]]:
    env = os.environ.copy(); env["HOME"] = "/tmp/custodian-godot-home"
    completed = subprocess.run(["godot", "--headless", "--path", str(CUSTODIAN_DIR), "--import", "--quit"],
                               cwd=REPO_ROOT, env=env, capture_output=True, text=True, check=False)
    return completed.returncode == 0, {"exit_code": completed.returncode, "stdout_tail": _tail(completed.stdout), "stderr_tail": _tail(completed.stderr)}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changed", action="store_true")
    parser.add_argument("--base")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--tag")
    parser.add_argument("--test")
    parser.add_argument("--tier", choices=TIERS)
    parser.add_argument("--max-tier", choices=TIERS)
    parser.add_argument("--list", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        tests = load_manifest(); patterns = load_warning_patterns()
    except (OSError, json.JSONDecodeError, ManifestError) as error:
        print(json.dumps({"schema": "custodian.validation.result.v1", "passed": False, "configuration_error": str(error)}))
        return EXIT_CONFIG
    if args.list:
        print(json.dumps(tests, indent=2) if args.json else "\n".join(f"{t['tier']:11} {t['id']}" for t in tests))
        return 0
    files = changed_files(args.base, REPO_ROOT) if args.changed else None
    selected = select_tests(tests, files=files, tag=args.tag, test_id=args.test, tier=args.tier, max_tier=args.max_tier)
    if not any([args.changed, args.tag, args.test, args.tier]):
        print("select tests with --changed, --tag, --test, or --tier", file=sys.stderr)
        return EXIT_CONFIG
    if args.test and not selected:
        payload = {"schema": "custodian.validation.result.v1", "passed": False, "configuration_error": f"unknown test id: {args.test}"}
        print(json.dumps(payload) if args.json else payload["configuration_error"])
        return EXIT_CONFIG
    if any(bool(test.get("needs_import")) for test in selected):
        ok, import_result = _run_import()
        if not ok:
            print(json.dumps({"schema":"custodian.validation.result.v1","passed":False,"infrastructure_failure":"import","import":import_result}))
            return EXIT_PREFLIGHT
    results = [execute_test(test, patterns) for test in selected]
    payload = {
        "schema": "custodian.validation.result.v1", "passed": all(item["status"] == "passed" for item in results),
        "changed_files": files or [], "selected": [item["id"] for item in selected], "tests": results,
        "summary": {"selected": len(results), "passed": sum(r["status"] == "passed" for r in results),
                    "failed": sum(r["status"] == "failed" for r in results), "timed_out": sum(r["status"] == "timeout" for r in results)},
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
        print(f"\n{len(results)} selected\n{payload['summary']['passed']} passed\n{payload['summary']['failed']} failed")
    if payload["summary"]["timed_out"]:
        return EXIT_TIMEOUT
    if payload["summary"]["failed"]:
        return EXIT_FAILED
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
