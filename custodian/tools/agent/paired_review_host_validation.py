"""Coordinator-side validation evidence for restricted paired-review sessions."""
from __future__ import annotations

import hashlib
import json
import os
import socket
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable

from godot_project_lock import godot_home


class HostValidationError(RuntimeError):
    pass


def _git(worktree: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=worktree, text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or result.stdout.strip() or "git identity check failed")
    return result.stdout.strip()


def _git_paths(worktree: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", revision], cwd=worktree,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate validation source paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _write_exclusive(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            os.link(temporary, path)
        except FileExistsError as exc:
            raise HostValidationError(f"refusing to replace preexisting review evidence: {path.name}") from exc
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        if temporary is not None:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def probe_host_capabilities() -> dict[str, bool]:
    """Verify the coordinator can bind loopback and write the isolated Godot HOME."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
    except OSError as exc:
        raise HostValidationError(f"coordinator loopback socket preflight failed: {exc}") from exc
    home = godot_home()
    try:
        with tempfile.NamedTemporaryFile(prefix="paired-review-home-probe-", dir=home):
            pass
    except OSError as exc:
        raise HostValidationError(f"isolated Godot HOME is not writable: {exc}") from exc
    return {"loopback_bind": True, "godot_home_writable": True}


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _source_hashes(worktree: Path, paths: list[str]) -> dict[str, str]:
    values = {}
    for relative in paths:
        path = worktree / relative
        if not path.is_file():
            raise HostValidationError(f"implementation diff source is missing: {relative}")
        values[relative] = _sha256(path.read_bytes())
    return values


def _validate_report(report: dict, implementation_paths: list[str]) -> None:
    if report.get("schema") != "custodian.validation.result.v1":
        raise HostValidationError("host validation report has the wrong schema")
    coverage = report.get("coverage")
    tests = report.get("tests")
    selected = report.get("selected")
    if (report.get("passed") is not True or not isinstance(coverage, dict)
            or coverage.get("complete") is not True or coverage.get("uncovered_files")
            or not isinstance(tests, list) or not tests or not isinstance(selected, list) or not selected):
        raise HostValidationError("host validation report is failed, incomplete, or vacuous")
    test_ids = {item.get("id") for item in tests if isinstance(item, dict)}
    if (len(test_ids) != len(tests) or test_ids != set(selected)
            or any(item.get("status") != "passed" for item in tests)):
        raise HostValidationError("host validation tests do not exactly match the selected passing IDs")
    summary = report.get("summary")
    if (not isinstance(summary, dict) or summary.get("selected") != len(tests)
            or summary.get("passed") != len(tests)
            or any(summary.get(key) != 0 for key in ("failed", "timed_out", "skipped", "infrastructure_errors"))):
        raise HostValidationError("host validation summary does not verify all selected checks passed")
    reported_paths = set(report.get("changed_files") or [])
    if not set(implementation_paths).issubset(reported_paths):
        raise HostValidationError("host validation changed-file selection omits part of the implementation diff")
    covered = set(coverage.get("covered_files") or [])
    excluded = set(coverage.get("excluded_files") or [])
    if not set(implementation_paths).issubset(covered | excluded):
        raise HostValidationError("host validation coverage omits files from the implementation diff")
    code_paths = {path for path in implementation_paths
                  if Path(path).suffix.lower() in {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}}
    if not code_paths or not code_paths.issubset(covered):
        raise HostValidationError("host validation does not cover changed implementation source/test files")
    covered_by = coverage.get("covered_by")
    if not isinstance(covered_by, dict) or any(
        not (set(covered_by.get(path, [])) & set(selected)) for path in code_paths
    ):
        raise HostValidationError("host validation has no selected test owner for changed source/test files")


def run_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str, implementation_commit: str,
                               *, run_validation: Callable | None = None,
                               capability_probe: Callable[[], dict[str, bool]] = probe_host_capabilities) -> dict:
    """Run and pin the canonical changed-file suite before launching the reviewer.

    The exact implementation parent drives selection. Validation itself delegates to
    run_validation.py, which acquires the canonical Godot project lock and job budget.
    Evidence paths are create-only so retries cannot silently replace prior results.
    """
    worktree = Path(repo).resolve()
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    if report_path.exists() or metadata_path.exists():
        raise HostValidationError("coordinator validation evidence already exists; refusing to overwrite it")

    head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    if head != reviewed_main:
        raise HostValidationError("claimed review worktree HEAD differs from pinned reviewed main")
    if _git(worktree, "status", "--porcelain", "--untracked-files=all"):
        raise HostValidationError("claimed review worktree is dirty before host validation")
    implementation_commit = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(worktree, "rev-parse", "--verify", f"{implementation_commit}^1")
    if subprocess.run(["git", "merge-base", "--is-ancestor", parent, implementation_commit],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("implementation parent is not an ancestor of the pinned implementation")
    if subprocess.run(["git", "merge-base", "--is-ancestor", implementation_commit, reviewed_main],
                      cwd=worktree, capture_output=True).returncode:
        raise HostValidationError("pinned implementation is not an ancestor of reviewed main")

    implementation_paths = _git_paths(worktree, f"{parent}...{implementation_commit}")
    selected_source_paths = _git_paths(worktree, f"{parent}...{reviewed_main}")
    if not implementation_paths or not set(implementation_paths).issubset(selected_source_paths):
        raise HostValidationError("canonical changed-file selection does not include the implementation diff")
    code_paths = [path for path in implementation_paths
                  if Path(path).suffix.lower() in {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}]
    source_hashes = _source_hashes(worktree, code_paths)
    capabilities = capability_probe()

    command = [sys.executable, str(worktree / "custodian/tools/validation/run_validation.py"),
               "--changed", "--base", parent, "--json"]
    execute = run_validation or (lambda argv, cwd: subprocess.run(
        argv, cwd=cwd, text=True, capture_output=True, check=False,
    ))
    try:
        process = execute(command, worktree)
    except OSError as exc:
        raise HostValidationError(f"trusted coordinator could not launch canonical validation: {exc}") from exc
    raw_report = process.stdout.encode("utf-8")
    report_hash = _sha256(raw_report)
    # Keep even a failed structured report for diagnosis. A later retry gets a new run ID.
    _write_exclusive(report_path, raw_report)
    if process.stderr:
        _write_exclusive(run_dir / "coordinator-validation.stderr", process.stderr.encode("utf-8"))
    try:
        report = json.loads(raw_report)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        report = None
        parse_error = str(exc)
    else:
        parse_error = None

    current_head = _git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    current_status = _git(worktree, "status", "--porcelain", "--untracked-files=all")
    current_source_hashes = _source_hashes(worktree, code_paths)
    source_changed = current_head != head or bool(current_status) or current_source_hashes != source_hashes
    metadata = {
        "schema": "custodian.paired_review_host_validation.v1",
        "worktree": str(worktree),
        "reviewed_main": reviewed_main,
        "implementation_commit": implementation_commit,
        "implementation_parent": parent,
        "implementation_paths": implementation_paths,
        "code_paths": code_paths,
        "selected_source_paths": selected_source_paths,
        "source_sha256": source_hashes,
        "source_changed_during_validation": source_changed,
        "capabilities": capabilities,
        "command": command,
        "exit_code": process.returncode,
        "report_path": str(report_path),
        "report_sha256": report_hash,
        "report_parse_error": parse_error,
        "summary": report.get("summary") if isinstance(report, dict) else None,
        "selected": report.get("selected") if isinstance(report, dict) else None,
    }
    metadata_bytes = (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode("utf-8")
    _write_exclusive(metadata_path, metadata_bytes)
    metadata["metadata_sha256"] = _sha256(metadata_bytes)

    if source_changed:
        raise HostValidationError("reviewed worktree source changed during host validation")
    if process.returncode:
        raise HostValidationError(f"canonical host validation failed with exit code {process.returncode}")
    if not isinstance(report, dict):
        raise HostValidationError("canonical host validation did not return structured JSON")
    _validate_report(report, implementation_paths)
    return metadata


def verify_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str,
                                  implementation_commit: str, *, expected_report_sha256: str,
                                  expected_metadata_sha256: str) -> dict:
    """Recheck pinned host evidence after the restricted reviewer exits."""
    run_dir = Path(run_dir).resolve()
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    try:
        report_bytes = report_path.read_bytes()
        metadata_bytes = metadata_path.read_bytes()
        metadata = json.loads(metadata_bytes)
        report = json.loads(report_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise HostValidationError(f"coordinator validation evidence is missing or malformed: {exc}") from exc
    if _sha256(report_bytes) != expected_report_sha256:
        raise HostValidationError("coordinator validation report digest changed during reviewer execution")
    if _sha256(metadata_bytes) != expected_metadata_sha256:
        raise HostValidationError("coordinator validation provenance digest changed during reviewer execution")
    if (metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or metadata.get("report_sha256") != expected_report_sha256
            or metadata.get("source_changed_during_validation") is not False):
        raise HostValidationError("coordinator validation provenance does not match the pinned review identity")
    if _git(Path(repo), "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main:
        raise HostValidationError("reviewed worktree HEAD changed after host validation")
    if _source_hashes(Path(repo), metadata.get("code_paths") or []) != metadata.get("source_sha256"):
        raise HostValidationError("reviewed implementation source changed after host validation")
    _validate_report(report, metadata.get("implementation_paths") or [])
    return report
