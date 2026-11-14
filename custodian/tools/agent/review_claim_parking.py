#!/usr/bin/env python3
"""Fenced parking for one explicitly authorized unresolved paired-review claim.

This is a bounded compatibility seam, not the general OR2 recovery supervisor.
It never changes the canonical agent branch, local review worktree, run files,
review packet, or review outcome. A separate append-only custom ref records
PARKED/ACTIVE execution-lock state; dispatch still treats the agent branch as
the claim identity.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from workflow_control import WorkflowControlError, common_dir, common_mutex, workstream_mutex


SCHEMA = "custodian.review_claim_parking.v1"
PLAN_SCHEMA = "custodian.review_claim_parking_plan.v1"
PARKING_REF_PREFIX = "refs/custodian/review-claim-parking"
PARKING_LOCK = "paired-review-source-provenance"
MAX_RUN_EVIDENCE_BYTES = 128 * 1024 * 1024
MAX_WORKTREE_INVENTORY_BYTES = 512 * 1024 * 1024
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


@dataclass(frozen=True)
class ParkingScope:
    workstream: str
    run_id: str
    claim_run_id: str
    target_workstream: str
    target_packet: str
    lock: str
    remote_branch_sha: str
    local_branch_sha: str


AUTHORIZED_SCOPE = ParkingScope(
    workstream="review-agent-paired-review-declared-doc-archive-gate-v1",
    run_id="20261019T104055Z-522c04f5260b",
    claim_run_id="20261019T104104Z-bf7933596f7f",
    target_workstream="agent-paired-review-declared-doc-archive-gate-v1",
    target_packet="custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md",
    lock=PARKING_LOCK,
    remote_branch_sha="f3a225c426a51736551b88c91ea2b786a69e8f5a",
    local_branch_sha="ad2009ca91a8afec457c8b21c202f1b10b7ca086",
)


class ParkingError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True, input_text: str | None = None,
        timeout: float = 20.0) -> str:
    try:
        result = subprocess.run(
            ["git", *args], cwd=repo, input=input_text, text=True,
            capture_output=True, timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ParkingError(f"git {' '.join(args)} could not be verified: {exc}") from exc
    if check and result.returncode:
        raise ParkingError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def _canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(path: Path, *, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ParkingError(f"{label} is missing or malformed: {exc}") from exc
    if not isinstance(value, dict):
        raise ParkingError(f"{label} must be a JSON object")
    return value


def run_directory(repo: Path, scope: ParkingScope = AUTHORIZED_SCOPE) -> Path:
    return common_dir(repo) / "custodian-review-runs" / scope.workstream / scope.run_id


def _authorized_scope(scope: ParkingScope) -> None:
    if scope != AUTHORIZED_SCOPE:
        raise ParkingError("parking is restricted to the exact code-authorized workstream and run")


def _safe_manifest(root: Path, manifest: Any) -> tuple[dict[str, str], str]:
    if not isinstance(manifest, dict) or not manifest:
        raise ParkingError("continuation does not contain the original run evidence manifest")
    normalized: dict[str, str] = {}
    for raw_path, expected in manifest.items():
        if not isinstance(raw_path, str) or not isinstance(expected, str) or not SHA256_RE.fullmatch(expected):
            raise ParkingError("original run evidence manifest contains an invalid entry")
        relative = Path(raw_path)
        if relative.is_absolute() or ".." in relative.parts or not relative.parts:
            raise ParkingError("original run evidence manifest contains an unsafe path")
        path = root / relative
        if not path.is_file() or path.is_symlink() or _sha256_file(path) != expected:
            raise ParkingError(f"original run evidence changed or is missing: {raw_path}")
        normalized[relative.as_posix()] = expected
    required = {"metadata.json", "claim-receipt.json", "validation.json", "coordinator-validation.json"}
    if not required.issubset(normalized):
        raise ParkingError("original run evidence manifest is incomplete")
    return normalized, _sha256_bytes(_canonical_bytes(normalized))


def _run_inventory(root: Path) -> tuple[dict[str, str], str, int]:
    inventory: dict[str, str] = {}
    total = 0
    try:
        paths = sorted(root.rglob("*"))
        for path in paths:
            if path.is_symlink():
                raise ParkingError(f"run evidence contains a symlink: {path.relative_to(root)}")
            if not path.is_file():
                continue
            size = path.stat().st_size
            total += size
            if total > MAX_RUN_EVIDENCE_BYTES:
                raise ParkingError("run evidence inventory exceeds the bounded hashing budget")
            inventory[path.relative_to(root).as_posix()] = _sha256_file(path)
    except OSError as exc:
        raise ParkingError(f"run evidence inventory could not be verified: {exc}") from exc
    if not inventory:
        raise ParkingError("run evidence inventory is empty")
    return inventory, _sha256_bytes(_canonical_bytes(inventory)), total


def _remote_sha(repo: Path, ref: str) -> str | None:
    result = subprocess.run(
        ["git", "ls-remote", "--refs", "origin", ref], cwd=repo,
        text=True, capture_output=True, timeout=20.0,
    )
    if result.returncode:
        raise ParkingError(f"origin could not verify {ref}: {(result.stderr or result.stdout).strip()}")
    rows = [line.split() for line in result.stdout.splitlines() if line.strip()]
    if not rows:
        return None
    if len(rows) != 1 or len(rows[0]) != 2 or rows[0][1] != ref or not SHA_RE.fullmatch(rows[0][0]):
        raise ParkingError(f"origin returned an ambiguous ref response for {ref}")
    return rows[0][0]


def _fetch_object(repo: Path, ref: str, expected_sha: str) -> None:
    if not SHA_RE.fullmatch(expected_sha):
        raise ParkingError("parking ref did not resolve to a commit SHA")
    fetch = subprocess.run(
        ["git", "fetch", "--no-tags", "--no-write-fetch-head", "origin", ref],
        cwd=repo, text=True, capture_output=True, timeout=30.0,
    )
    if fetch.returncode:
        raise ParkingError(f"parking record fetch failed: {(fetch.stderr or fetch.stdout).strip()}")
    git(repo, "cat-file", "-e", f"{expected_sha}^{{commit}}")


def parking_ref(scope: ParkingScope = AUTHORIZED_SCOPE) -> str:
    return f"{PARKING_REF_PREFIX}/{scope.workstream}"


def _record_from_commit(repo: Path, ref: str, sha: str) -> dict[str, Any]:
    _fetch_object(repo, ref, sha)
    try:
        raw = git(repo, "show", f"{sha}:parking.json")
        record = json.loads(raw)
    except (ParkingError, json.JSONDecodeError) as exc:
        raise ParkingError(f"parking ref does not contain canonical parking.json: {exc}") from exc
    if not isinstance(record, dict):
        raise ParkingError("parking.json must contain one JSON object")
    return record


def _record_parent(repo: Path, sha: str) -> list[str]:
    parents = git(repo, "show", "-s", "--format=%P", sha).split()
    if len(parents) != 1 or not SHA_RE.fullmatch(parents[0]):
        raise ParkingError("parking record must have exactly one fenced parent")
    return parents


def _validate_record_chain(repo: Path, scope: ParkingScope, branch_sha: str,
                           record_sha: str, record: dict[str, Any]) -> None:
    required = {
        "schema", "version", "state", "sequence", "transition_id", "workstream",
        "run_id", "claim_run_id", "target_workstream", "target_packet", "lock",
        "branch_ref", "remote_branch_sha", "local_branch_sha",
        "run_evidence_manifest_sha256", "run_inventory_sha256", "local_inventory_sha256",
        "local_only_commit_count", "local_file_count", "local_file_bytes",
        "worktree_status", "owner_attestation",
        "previous_record_sha", "created_utc",
    }
    if set(record) != required:
        raise ParkingError("parking record has missing or unexpected fields")
    if record.get("schema") != SCHEMA or type(record.get("version")) is not int or record.get("version") != 1:
        raise ParkingError("parking record schema/version is unsupported")
    if (record.get("workstream") != scope.workstream or record.get("run_id") != scope.run_id
            or record.get("claim_run_id") != scope.claim_run_id
            or record.get("target_workstream") != scope.target_workstream
            or record.get("target_packet") != scope.target_packet
            or record.get("lock") != scope.lock
            or record.get("branch_ref") != f"refs/heads/agent/{scope.workstream}"):
        raise ParkingError("parking record identity does not match the authorized claim")
    if (record.get("remote_branch_sha") != branch_sha
            or branch_sha != scope.remote_branch_sha
            or record.get("local_branch_sha") != scope.local_branch_sha):
        raise ParkingError("parking record branch SHA does not match the authorized claim")
    if (type(record.get("sequence")) is not int
            or type(record.get("local_only_commit_count")) is not int
            or record["local_only_commit_count"] < 1
            or type(record.get("local_file_count")) is not int
            or record["local_file_count"] < 0
            or type(record.get("local_file_bytes")) is not int
            or record["local_file_bytes"] < 0
            or record.get("worktree_status") != "clean"):
        raise ParkingError("parking record local inventory summary is invalid")
    for field in ("run_evidence_manifest_sha256", "run_inventory_sha256", "local_inventory_sha256"):
        if not isinstance(record.get(field), str) or not SHA256_RE.fullmatch(record[field]):
            raise ParkingError(f"parking record {field} is invalid")
    attestation = record.get("owner_attestation")
    if (not isinstance(attestation, dict)
            or set(attestation) != {"no_active_owner", "attested_by", "host", "source"}
            or attestation.get("no_active_owner") is not True
            or not isinstance(attestation.get("attested_by"), str)
            or not attestation["attested_by"].strip()
            or len(attestation["attested_by"]) > 120
            or not isinstance(attestation.get("host"), str)
            or not isinstance(attestation.get("source"), str)
            or not attestation["source"].strip()):
        raise ParkingError("parking record owner attestation is invalid")
    if (not isinstance(record.get("transition_id"), str) or not record["transition_id"].strip()
            or len(record["transition_id"]) > 100
            or not isinstance(record.get("created_utc"), str)
            or not re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ", record["created_utc"])):
        raise ParkingError("parking record transition identity/time is invalid")

    state = record.get("state")
    sequence = record.get("sequence")
    parent = _record_parent(repo, record_sha)[0]
    if sequence == 1 and state == "PARKED":
        if record.get("previous_record_sha") is not None or parent != branch_sha:
            raise ParkingError("first PARKED record is not fenced to the exact agent branch tip")
    elif sequence == 2 and state == "ACTIVE":
        previous = record.get("previous_record_sha")
        if not isinstance(previous, str) or not SHA_RE.fullmatch(previous) or parent != previous:
            raise ParkingError("ACTIVE record is not an append-only child of its PARKED record")
        prior = _record_from_commit(repo, parking_ref(scope), previous)
        if (prior.get("schema") != SCHEMA or prior.get("state") != "PARKED"
                or prior.get("sequence") != 1 or prior.get("previous_record_sha") is not None):
            raise ParkingError("ACTIVE record does not follow the one authorized PARKED transition")
        _validate_record_chain(repo, scope, branch_sha, previous, prior)
    else:
        raise ParkingError("parking record state/sequence is unsupported")


def read_remote_record(repo: Path, scope: ParkingScope = AUTHORIZED_SCOPE) -> dict[str, Any]:
    """Read the latest custom ref without changing local refs or FETCH_HEAD."""
    ref = parking_ref(scope)
    sha = _remote_sha(repo, ref)
    if sha is None:
        return {"state": "absent", "record_sha": None, "record": None, "reason": None}
    branch_ref = f"refs/heads/agent/{scope.workstream}"
    branch_sha = _remote_sha(repo, branch_ref)
    if branch_sha is None:
        return {"state": "invalid", "record_sha": sha, "record": None,
                "reason": "remote agent branch is absent"}
    try:
        record = _record_from_commit(repo, ref, sha)
        _validate_record_chain(repo, scope, branch_sha, sha, record)
        if _remote_sha(repo, ref) != sha or _remote_sha(repo, branch_ref) != branch_sha:
            raise ParkingError("parking/agent refs changed during read; retry from a fresh plan")
    except ParkingError as exc:
        return {"state": "invalid", "record_sha": sha, "record": None, "reason": str(exc)}
    return {"state": record["state"], "record_sha": sha, "record": record, "reason": None}


def _verify_target_packet(repo: Path, scope: ParkingScope) -> None:
    try:
        from task_packet_contract import parse_packet
    except ImportError as exc:
        raise ParkingError(f"task packet contract could not be loaded: {exc}") from exc
    text = git(repo, "show", f"origin/main:{scope.target_packet}")
    packet = parse_packet(scope.target_packet, text)
    if packet.error:
        raise ParkingError(f"target review packet is invalid: {packet.error}")
    if (packet.workstream != scope.workstream or packet.kind != "review"
            or packet.status != "ready" or packet.review_target_workstream != scope.target_workstream
            or tuple(packet.locks) != (scope.lock,)):
        raise ParkingError("target review packet no longer matches the exact authorized lock and identity")


def _verify_run_evidence(repo: Path, scope: ParkingScope) -> dict[str, Any]:
    root = run_directory(repo, scope)
    continuation_dir = root / "continuation-01"
    if (root.is_symlink() or not root.is_dir() or continuation_dir.is_symlink()
            or not continuation_dir.is_dir()):
        raise ParkingError("original run or continuation directory is missing, symlinked, or invalid")
    original = _read_json(root / "metadata.json", label="original run metadata")
    continuation = _read_json(continuation_dir / "metadata.json", label="continuation metadata")
    claim = _read_json(root / "claim-receipt.json", label="original claim receipt")
    if (original.get("run_id") != scope.run_id or original.get("workstream") != scope.workstream
            or original.get("phase") != "post_exit_recovery"
            or original.get("branch") != f"agent/{scope.workstream}"
            or original.get("reviewed_main") != scope.remote_branch_sha
            or original.get("outcome") is not None or original.get("finding_ids") is not None):
        raise ParkingError("original run metadata no longer proves the pinned unresolved review")
    if (continuation.get("run_id") != scope.run_id or continuation.get("workstream") != scope.workstream
            or continuation.get("target_workstream") != scope.target_workstream
            or continuation.get("phase") != "coordinator_closeout"
            or continuation.get("branch") != f"agent/{scope.workstream}"
            or continuation.get("worktree") != original.get("worktree")
            or continuation.get("reviewed_main") != scope.remote_branch_sha
            or continuation.get("implementation_commit") != scope.remote_branch_sha):
        raise ParkingError("continuation identity/state no longer matches the authorized review")
    if (claim.get("schema") != "custodian.dispatch.claim.v1" or claim.get("result") != "claimed"
            or claim.get("verified") is not True or claim.get("workstream") != scope.workstream
            or claim.get("run_id") != scope.claim_run_id
            or claim.get("branch") != f"agent/{scope.workstream}"
            or claim.get("worktree") != original.get("worktree")):
        raise ParkingError("original dispatch claim receipt does not match the exact run/worktree")
    manifest, manifest_sha = _safe_manifest(root, continuation.get("run_evidence_sha256"))
    inventory, inventory_sha, inventory_bytes = _run_inventory(root)
    return {
        "run_dir": str(root),
        "worktree": str(Path(str(original.get("worktree", ""))).resolve()),
        "run_evidence_manifest_sha256": manifest_sha,
        "run_evidence_file_count": len(manifest),
        "run_inventory_sha256": inventory_sha,
        "run_inventory_file_count": len(inventory),
        "run_inventory_bytes": inventory_bytes,
        "continuation_metadata_sha256": _sha256_file(root / "continuation-01" / "metadata.json"),
    }


def _worktree_registry(repo: Path) -> dict[str, str]:
    registry: dict[str, str] = {}
    current: str | None = None
    for line in git(repo, "worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            current = line.removeprefix("worktree ")
        elif line.startswith("branch refs/heads/agent/") and current:
            registry[line.removeprefix("branch refs/heads/")] = str(Path(current).resolve())
    return registry


def _worktree_file_inventory(root: Path) -> tuple[str, int, int]:
    """Hash every non-Git file, including ignored files, within a fixed budget."""
    entries: dict[str, dict[str, Any]] = {}
    total = 0
    try:
        for path in sorted(root.rglob("*")):
            relative = path.relative_to(root)
            if relative.parts and relative.parts[0] == ".git":
                continue
            if path.is_symlink():
                raise ParkingError(f"protected worktree contains a symlink: {relative.as_posix()}")
            if not path.is_file():
                continue
            before = path.stat()
            total += before.st_size
            if total > MAX_WORKTREE_INVENTORY_BYTES:
                raise ParkingError("protected worktree exceeds the bounded inventory hashing budget")
            digest = _sha256_file(path)
            after = path.stat()
            if ((before.st_size, before.st_mtime_ns, before.st_ino)
                    != (after.st_size, after.st_mtime_ns, after.st_ino)):
                raise ParkingError(f"protected worktree file changed during inventory: {relative.as_posix()}")
            entries[relative.as_posix()] = {
                "sha256": digest,
                "mode": before.st_mode & 0o777,
                "size": before.st_size,
            }
    except OSError as exc:
        raise ParkingError(f"protected worktree inventory could not be verified: {exc}") from exc
    return _sha256_bytes(_canonical_bytes(entries)), len(entries), total


def _verify_local_claim(repo: Path, scope: ParkingScope, expected_worktree: str) -> dict[str, Any]:
    branch = f"agent/{scope.workstream}"
    local_sha = git(repo, "rev-parse", "--verify", f"refs/heads/{branch}^{{commit}}")
    if local_sha != scope.local_branch_sha:
        raise ParkingError("local agent branch SHA changed from the authorized commit")
    worktree_path = Path(expected_worktree)
    registered = _worktree_registry(repo).get(branch)
    if registered != str(worktree_path.resolve()) or not worktree_path.is_dir():
        raise ParkingError("the exact protected review worktree is not attached at its recorded path")
    if git(worktree_path, "branch", "--show-current") != branch:
        raise ParkingError("the protected review worktree is on another branch")
    worktree_sha = git(worktree_path, "rev-parse", "HEAD")
    if worktree_sha != scope.local_branch_sha:
        raise ParkingError("the protected review worktree HEAD changed")
    status = git(worktree_path, "status", "--porcelain=v1", "--untracked-files=all")
    if status:
        raise ParkingError("the protected review worktree is dirty; exact preservation is not established")
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", scope.remote_branch_sha, scope.local_branch_sha],
        cwd=repo, capture_output=True,
    )
    if ancestry.returncode:
        raise ParkingError("the local review commit is not descended from the preserved remote branch")
    local_commits = git(repo, "rev-list", "--reverse", f"{scope.remote_branch_sha}..{scope.local_branch_sha}").splitlines()
    if not local_commits or local_commits[-1] != scope.local_branch_sha:
        raise ParkingError("the local-only review commit inventory is incomplete")
    file_inventory_sha, file_count, file_bytes = _worktree_file_inventory(worktree_path)
    inventory = {
        "branch": branch,
        "remote_branch_sha": scope.remote_branch_sha,
        "local_branch_sha": local_sha,
        "local_only_commit_shas": local_commits,
        "index_tree": git(worktree_path, "write-tree"),
        "status_porcelain": status,
        "worktree_path": str(worktree_path.resolve()),
        "worktree_files_sha256": file_inventory_sha,
        "worktree_file_count": file_count,
        "worktree_file_bytes": file_bytes,
    }
    return {
        "local_inventory_sha256": _sha256_bytes(_canonical_bytes(inventory)),
        "local_only_commit_count": len(local_commits),
        "local_file_count": file_count,
        "local_file_bytes": file_bytes,
        "worktree_status": "clean",
        "worktree": str(worktree_path.resolve()),
    }


def find_local_owner_processes(repo: Path, scope: ParkingScope, worktree: Path) -> tuple[list[dict[str, Any]], bool]:
    """Find same-user processes that visibly own the exact run/worktree.

    The run predates recorded PID/boot identity, so a clear local scan is not
    sufficient by itself: parking also requires an explicit operator
    attestation covering other hosts.
    """
    proc_root = Path("/proc")
    if not proc_root.is_dir():
        return [], False
    expected_path = str(worktree.resolve())
    tokens = (scope.run_id, scope.workstream, expected_path)
    matches: list[dict[str, Any]] = []
    complete = True
    current_uid = os.getuid() if hasattr(os, "getuid") else None
    for process in proc_root.iterdir():
        if not process.name.isdigit():
            continue
        try:
            if current_uid is not None and process.stat().st_uid != current_uid:
                continue
            cmdline = (process / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "replace")
            cwd = str((process / "cwd").resolve())
        except FileNotFoundError:
            continue
        except PermissionError:
            if current_uid is None or process.stat().st_uid == current_uid:
                complete = False
            continue
        if cwd == expected_path or any(token and token in cmdline for token in tokens):
            matches.append({"pid": int(process.name), "cwd_matches": cwd == expected_path,
                            "identity_token_matches": any(token and token in cmdline for token in tokens)})
    return matches, complete


def _build_plan(
    repo: Path,
    *,
    action: str,
    scope: ParkingScope,
    owner_absence_attested: bool,
    attested_by: str | None,
) -> dict[str, Any]:
    _authorized_scope(scope)
    if action not in {"park", "unpark"}:
        raise ParkingError("action must be park or unpark")
    blockers: list[str] = []
    run_state: dict[str, Any] = {}
    local_state: dict[str, Any] = {}
    record_state = {"state": "unavailable", "record_sha": None, "record": None, "reason": None}
    branch_ref = f"refs/heads/agent/{scope.workstream}"
    remote_branch_sha: str | None = None
    process_matches: list[dict[str, Any]] = []
    process_scan_complete = False
    try:
        record_state = read_remote_record(repo, scope)
    except ParkingError as exc:
        record_state = {"state": "invalid", "record_sha": None, "record": None, "reason": str(exc)}
        blockers.append(f"parking record state is unverifiable: {exc}")

    if action == "park":
        try:
            _verify_target_packet(repo, scope)
            run_state = _verify_run_evidence(repo, scope)
            remote_branch_sha = _remote_sha(repo, branch_ref)
            if remote_branch_sha != scope.remote_branch_sha:
                blockers.append("remote agent branch SHA changed from the authorized tip")
            local_state = _verify_local_claim(repo, scope, run_state.get("worktree", ""))
            process_matches, process_scan_complete = find_local_owner_processes(
                repo, scope, Path(str(run_state.get("worktree", ""))),
            )
            if process_matches:
                blockers.append("active local owner process is present")
            if not process_scan_complete:
                blockers.append("local owner process scan is incomplete")
        except (ParkingError, OSError) as exc:
            blockers.append(str(exc))
        if record_state["state"] != "absent":
            if record_state["state"] == "invalid":
                blockers.append(f"existing parking ref is invalid: {record_state.get('reason')}")
            elif record_state["state"] == "PARKED":
                blockers.append("claim is already parked")
            else:
                blockers.append("one-time parking transition already used")
        if not owner_absence_attested or not isinstance(attested_by, str) or not attested_by.strip():
            blockers.append("explicit owner-absence attestation is required")
        elif len(attested_by.strip()) > 120:
            blockers.append("attestor identity exceeds 120 characters")
    else:
        if record_state["state"] != "PARKED":
            blockers.append("only a verified PARKED claim can be unparked")
        else:
            record = record_state["record"] or {}
            remote_branch_sha = record.get("remote_branch_sha")
            run_state = {
                "run_evidence_manifest_sha256": record.get("run_evidence_manifest_sha256"),
                "run_inventory_sha256": record.get("run_inventory_sha256"),
                "run_inventory_file_count": None,
                "run_inventory_bytes": None,
                "continuation_metadata_sha256": None,
            }
            local_state = {
                "local_inventory_sha256": record.get("local_inventory_sha256"),
                "local_only_commit_count": record.get("local_only_commit_count"),
                "local_file_count": record.get("local_file_count"),
                "local_file_bytes": record.get("local_file_bytes"),
                "worktree_status": record.get("worktree_status", "unknown"),
            }

    prior_attestation = (record_state.get("record") or {}).get("owner_attestation", {})
    plan = {
        "schema": PLAN_SCHEMA,
        "action": action,
        "workstream": scope.workstream,
        "run_id": scope.run_id,
        "claim_run_id": scope.claim_run_id,
        "target_workstream": scope.target_workstream,
        "branch_ref": branch_ref,
        "remote_branch_sha": remote_branch_sha,
        "local_branch_sha": scope.local_branch_sha,
        "run_evidence_manifest_sha256": run_state.get("run_evidence_manifest_sha256"),
        "run_inventory_sha256": run_state.get("run_inventory_sha256"),
        "run_inventory_file_count": run_state.get("run_inventory_file_count"),
        "run_inventory_bytes": run_state.get("run_inventory_bytes"),
        "continuation_metadata_sha256": run_state.get("continuation_metadata_sha256"),
        "local_inventory_sha256": local_state.get("local_inventory_sha256"),
        "local_only_commit_count": local_state.get("local_only_commit_count"),
        "local_file_count": local_state.get("local_file_count"),
        "local_file_bytes": local_state.get("local_file_bytes"),
        "worktree_status": local_state.get("worktree_status", "unknown"),
        "local_process_scan": {
            "complete": process_scan_complete if action == "park" else None,
            "matching_pids": [item["pid"] for item in process_matches] if action == "park" else [],
            "cross_host_state": "unknown" if action == "park" else "not required to restore lock",
            "operator_attested_absent": bool(owner_absence_attested) if action == "park" else True,
            "attested_by": (attested_by.strip() if isinstance(attested_by, str) else None)
            if action == "park" else prior_attestation.get("attested_by"),
            "host": socket.gethostname() if action == "park" else prior_attestation.get("host"),
        },
        "current_parking_record": {
            "state": record_state.get("state"),
            "record_sha": record_state.get("record_sha"),
            "reason": record_state.get("reason"),
        },
        "blockers": sorted(set(blockers)),
    }
    plan["eligible"] = not plan["blockers"]
    plan["plan_sha256"] = _sha256_bytes(_canonical_bytes(plan))
    return plan


def build_plan(repo: Path, *, action: str = "park", scope: ParkingScope = AUTHORIZED_SCOPE,
               owner_absence_attested: bool = False, attested_by: str | None = None) -> dict[str, Any]:
    """Produce a read-only plan. An explicit human owner attestation is bound to its digest."""
    return _build_plan(
        repo.resolve(), action=action, scope=scope,
        owner_absence_attested=owner_absence_attested, attested_by=attested_by,
    )


def _record_from_plan(plan: dict[str, Any], *, scope: ParkingScope, action: str,
                      parent_sha: str, owner_absence_attested: bool,
                      attested_by: str | None,
                      previous_record: dict[str, Any] | None = None) -> dict[str, Any]:
    previous = parent_sha if action == "unpark" else None
    return {
        "schema": SCHEMA,
        "version": 1,
        "state": "PARKED" if action == "park" else "ACTIVE",
        "sequence": 1 if action == "park" else 2,
        "transition_id": f"{int(time.time())}-{os.getpid()}",
        "workstream": scope.workstream,
        "run_id": scope.run_id,
        "claim_run_id": scope.claim_run_id,
        "target_workstream": scope.target_workstream,
        "target_packet": scope.target_packet,
        "lock": scope.lock,
        "branch_ref": plan["branch_ref"],
        "remote_branch_sha": plan["remote_branch_sha"],
        "local_branch_sha": plan["local_branch_sha"],
        "run_evidence_manifest_sha256": plan["run_evidence_manifest_sha256"],
        "run_inventory_sha256": plan["run_inventory_sha256"],
        "local_inventory_sha256": plan["local_inventory_sha256"],
        "local_only_commit_count": plan["local_only_commit_count"],
        "local_file_count": plan["local_file_count"],
        "local_file_bytes": plan["local_file_bytes"],
        "worktree_status": plan["worktree_status"],
        "owner_attestation": {
            **(previous_record["owner_attestation"] if action == "unpark" and previous_record else {
                "no_active_owner": bool(owner_absence_attested),
                "attested_by": (attested_by or "").strip()[:120],
                "host": hashlib.sha256(socket.gethostname().encode("utf-8")).hexdigest()[:16],
                "source": "explicit operator attestation; local process scan recorded in plan",
            }),
        },
        "previous_record_sha": previous,
        "created_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }


def _create_record_commit(repo: Path, record: dict[str, Any], parent_sha: str) -> str:
    blob = git(repo, "hash-object", "-w", "--stdin", input_text=json.dumps(record, indent=2, sort_keys=True) + "\n")
    tree = git(repo, "mktree", input_text=f"100644 blob {blob}\tparking.json\n")
    return git(repo, "-c", "commit.gpgsign=false", "commit-tree", tree,
               "-p", parent_sha, "-m",
               f"review claim parking {record['state']} {record['workstream']} {record['run_id']}")


def _push_record(repo: Path, commit_sha: str, ref: str) -> None:
    result = subprocess.run(
        ["git", "push", "origin", f"{commit_sha}:{ref}"], cwd=repo,
        text=True, capture_output=True, timeout=30.0,
    )
    if result.returncode:
        raise ParkingError(
            "fenced parking ref update lost or failed; original claim branch is untouched: "
            + (result.stderr or result.stdout).strip()
        )
    if _remote_sha(repo, ref) != commit_sha:
        raise ParkingError("parking ref readback did not match the appended transition")


def apply_transition(
    repo: Path,
    *,
    action: str,
    scope: ParkingScope = AUTHORIZED_SCOPE,
    expected_plan_sha256: str,
    owner_absence_attested: bool = False,
    attested_by: str | None = None,
) -> dict[str, Any]:
    """Reverify a plan, then append one create-only/fast-forward custom-ref state."""
    repo = repo.resolve()
    if not SHA256_RE.fullmatch(expected_plan_sha256):
        raise ParkingError("an exact plan SHA-256 is required")
    try:
        with common_mutex(repo, timeout_seconds=0.0):
            with workstream_mutex(repo, scope.workstream):
                plan = _build_plan(
                    repo, action=action, scope=scope,
                    owner_absence_attested=owner_absence_attested, attested_by=attested_by,
                )
                if plan["plan_sha256"] != expected_plan_sha256:
                    raise ParkingError("live state changed since the inspected plan; create a fresh plan")
                if not plan["eligible"]:
                    raise ParkingError("parking transition is blocked: " + "; ".join(plan["blockers"]))
                ref = parking_ref(scope)
                state = read_remote_record(repo, scope)
                if action == "park":
                    if state["state"] != "absent":
                        raise ParkingError("parking is one-time and the remote parking ref already exists")
                    parent_sha = scope.remote_branch_sha
                else:
                    if state["state"] != "PARKED":
                        raise ParkingError("remote claim is not in a verified PARKED state")
                    parent_sha = str(state["record_sha"])
                record = _record_from_plan(
                    plan, scope=scope, action=action, parent_sha=parent_sha,
                    owner_absence_attested=owner_absence_attested, attested_by=attested_by,
                    previous_record=state.get("record"),
                )
                commit_sha = _create_record_commit(repo, record, parent_sha)
                _push_record(repo, commit_sha, ref)
                final = read_remote_record(repo, scope)
                expected_state = "PARKED" if action == "park" else "ACTIVE"
                if final["state"] != expected_state or final["record_sha"] != commit_sha:
                    raise ParkingError("remote parking state did not verify after compare-and-swap push")
                if _remote_sha(repo, f"refs/heads/agent/{scope.workstream}") != scope.remote_branch_sha:
                    raise ParkingError(
                        "parking record landed but the agent branch moved; dispatcher will keep the lock held"
                    )
                return {
                    "schema": SCHEMA,
                    "action": action,
                    "state": expected_state,
                    "workstream": scope.workstream,
                    "run_id": scope.run_id,
                    "remote_record_sha": commit_sha,
                    "agent_branch_sha": scope.remote_branch_sha,
                    "branch_unchanged": True,
                }
    except WorkflowControlError as exc:
        raise ParkingError(str(exc)) from exc


def dispatcher_parking_state(repo: Path, packet: Any, branch_sha: str) -> dict[str, Any]:
    """Return verified lock disposition for the one exact review identity."""
    scope = AUTHORIZED_SCOPE
    if (getattr(packet, "workstream", None) != scope.workstream
            or getattr(packet, "kind", None) != "review"
            or getattr(packet, "review_target_workstream", None) != scope.target_workstream
            or tuple(getattr(packet, "locks", ())) != (scope.lock,)
            or branch_sha != scope.remote_branch_sha):
        return {"state": "active", "record_sha": None, "lock_released": False,
                "reason": "claim or packet identity is not the exact authorized scope"}
    try:
        record_state = read_remote_record(repo, scope)
    except ParkingError as exc:
        return {"state": "invalid", "record_sha": None, "lock_released": False, "reason": str(exc)}
    if record_state["state"] == "PARKED":
        return {"state": "parked", "record_sha": record_state["record_sha"],
                "lock_released": True, "reason": None}
    if record_state["state"] == "invalid":
        return {"state": "invalid", "record_sha": record_state["record_sha"],
                "lock_released": False, "reason": record_state.get("reason")}
    if record_state["state"] == "ACTIVE":
        return {"state": "active", "record_sha": record_state["record_sha"],
                "lock_released": False, "reason": "claim was explicitly unparked"}
    return {"state": "none", "record_sha": None, "lock_released": False, "reason": None}


def _print_json(value: dict[str, Any]) -> None:
    print(json.dumps(value, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    plan_parser = subparsers.add_parser("plan", help="print a read-only exact-claim plan")
    plan_parser.add_argument("--action", choices=("park", "unpark"), default="park")
    plan_parser.add_argument("--repo", type=Path, default=Path.cwd())
    plan_parser.add_argument("--attested-by")
    plan_parser.add_argument("--attest-no-active-owner", action="store_true")
    plan_parser.add_argument("--json", action="store_true")
    for command in ("park", "unpark"):
        apply_parser = subparsers.add_parser(command, help=f"apply the exact planned {command} transition")
        apply_parser.add_argument("--repo", type=Path, default=Path.cwd())
        apply_parser.add_argument("--plan-sha256", required=True)
        if command == "park":
            apply_parser.add_argument("--attested-by", required=True)
            apply_parser.add_argument("--attest-no-active-owner", action="store_true", required=True)
    args = parser.parse_args(argv)
    repo = args.repo.resolve()
    try:
        if args.command == "plan":
            plan = build_plan(
                repo, action=args.action,
                owner_absence_attested=args.attest_no_active_owner,
                attested_by=args.attested_by,
            )
            _print_json(plan)
            return 0 if plan["eligible"] else 2
        result = apply_transition(
            repo, action=args.command, expected_plan_sha256=args.plan_sha256,
            owner_absence_attested=getattr(args, "attest_no_active_owner", False),
            attested_by=getattr(args, "attested_by", None),
        )
        _print_json(result)
        return 0
    except ParkingError as exc:
        print(f"review_claim_parking: BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
