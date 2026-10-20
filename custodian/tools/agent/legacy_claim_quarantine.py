#!/usr/bin/env python3
"""Preserve legacy claim identity while fencing an explicitly quarantined run.

The quarantine ref is separate from agent and dispatch-claim refs. It never
deletes or edits those refs, worktrees, or reviewer evidence. A current,
checksummed record may release only the execution lock; the original identity
continues to block a duplicate claim and cannot satisfy review dependencies.
"""

from __future__ import annotations

import argparse
from contextlib import ExitStack
import hashlib
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tarfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import WorkflowControlError, common_dir, common_mutex, workstream_mutex

SCHEMA = "custodian.legacy_quarantine.v1"
PLAN_SCHEMA = "custodian.legacy_quarantine_plan.v1"
GENERATION = "execution-reset-v1-20261020"
REF_PREFIX = "refs/custodian/legacy-quarantined"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class QuarantineError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True, timeout: int = 60,
        input_text: str | None = None) -> str:
    try:
        result = subprocess.run(["git", *args], cwd=repo, input=input_text,
                                text=True, capture_output=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise QuarantineError(f"git {' '.join(args)} could not be verified: {exc}") from exc
    if check and result.returncode:
        raise QuarantineError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def quarantine_ref(workstream: str) -> str:
    if not ID_RE.fullmatch(workstream):
        raise QuarantineError("workstream must be lowercase kebab-case")
    return f"{REF_PREFIX}/{workstream}"


def coordination_root(repo: Path) -> Path:
    root = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    for record in git(root, "worktree", "list", "--porcelain").split("\n\n"):
        lines = record.splitlines()
        if lines and "branch refs/heads/main" in lines:
            return Path(lines[0].removeprefix("worktree ")).resolve()
    return root


def _remote_sha(repo: Path, ref: str) -> str | None:
    result = subprocess.run(["git", "ls-remote", "--refs", "origin", ref], cwd=repo,
                            text=True, capture_output=True, timeout=20)
    if result.returncode:
        raise QuarantineError(f"origin could not verify {ref}: {(result.stderr or result.stdout).strip()}")
    rows = [line.split() for line in result.stdout.splitlines() if line.strip()]
    if not rows:
        return None
    if len(rows) != 1 or len(rows[0]) != 2 or rows[0][1] != ref or not SHA_RE.fullmatch(rows[0][0]):
        raise QuarantineError(f"origin returned an ambiguous ref response for {ref}")
    return rows[0][0]


def _manifest_ref_sha(manifest: dict[str, Any], ref: str) -> str | None:
    return next((sha for name, sha in manifest.get("refs", []) if name == ref), None)


def _worktrees(repo: Path) -> dict[str, Path]:
    result: dict[str, Path] = {}
    current: dict[str, str] = {}
    for line in git(repo, "worktree", "list", "--porcelain").splitlines() + [""]:
        if not line:
            if current.get("branch", "").startswith("refs/heads/agent/"):
                result[current["branch"].removeprefix("refs/heads/agent/")] = Path(current["worktree"]).resolve()
            current = {}
        else:
            key, _, value = line.partition(" ")
            current[key] = value
    return result


def _worktree_inventory(worktree: Path | None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if worktree is None or not worktree.is_dir():
        return rows
    for base, directories, files in os.walk(worktree, topdown=True, followlinks=False):
        directories[:] = sorted(d for d in directories if d != ".git")
        for name in sorted(directories + files):
            path = Path(base) / name
            relative = path.relative_to(worktree).as_posix()
            info = path.lstat()
            if path.is_symlink():
                rows.append({"path": relative, "kind": "symlink", "target": os.readlink(path), "mode": info.st_mode})
            elif path.is_file():
                rows.append({"path": relative, "kind": "file", "size": info.st_size,
                             "mode": info.st_mode, "sha256": sha256_file(path)})
            elif path.is_dir():
                rows.append({"path": relative, "kind": "directory", "mode": info.st_mode})
            else:
                rows.append({"path": relative, "kind": "other", "size": info.st_size, "mode": info.st_mode})
    return rows


def _tree_inventory(root: Path | None) -> list[dict[str, Any]]:
    if root is None or not root.is_dir():
        return []
    rows: list[dict[str, Any]] = []
    for base, directories, files in os.walk(root, topdown=True, followlinks=False):
        directories.sort()
        for name in sorted(directories + files):
            path = Path(base) / name
            info = path.lstat()
            row: dict[str, Any] = {"path": path.relative_to(root).as_posix(), "mode": info.st_mode}
            if path.is_symlink():
                row.update(kind="symlink", target=os.readlink(path))
            elif path.is_file():
                row.update(kind="file", size=info.st_size, sha256=sha256_file(path))
            elif path.is_dir():
                row["kind"] = "directory"
            else:
                row.update(kind="other", size=info.st_size)
            rows.append(row)
    return rows


def _owner_state(repo: Path, workstream: str, run_id: str | None) -> dict[str, Any]:
    if not run_id:
        return {"state": "unknown", "host": None, "pid": None, "run_id": run_id,
                "reason": "no pinned run identity"}
    path = common_dir(repo) / "custodian-workflow" / "traces" / workstream / f"{run_id}.jsonl"
    try:
        first = json.loads(path.read_text(encoding="utf-8").splitlines()[0])
        host, pid = first.get("host"), first.get("pid")
        timestamp = first.get("timestamp_utc")
        if first.get("workstream") != workstream or first.get("run_id") != run_id:
            raise ValueError("trace identity mismatch")
    except (OSError, IndexError, json.JSONDecodeError, TypeError):
        return {"state": "unknown", "host": None, "pid": None, "run_id": run_id,
                "reason": "pinned run trace unavailable"}
    except ValueError:
        return {"state": "unknown", "host": host, "pid": pid, "run_id": run_id,
                "reason": "pinned run trace identity mismatch"}
    trace_sha = sha256_file(path)
    if not isinstance(pid, int) or host != socket.gethostname():
        return {"state": "unknown", "host": host, "pid": pid, "run_id": run_id, "trace_sha256": trace_sha,
                "reason": "owner host/process cannot be observed here"}
    proc = Path(f"/proc/{pid}")
    if not proc.exists():
        return {"state": "exited_verified", "host": host, "pid": pid, "run_id": run_id,
                "trace_sha256": trace_sha, "trace_timestamp": timestamp,
                "reason": "same-host pinned process ID is absent"}
    try:
        argv = proc.joinpath("cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")[:1000]
    except OSError:
        argv = "unreadable"
    return {"state": "active_or_pid_ambiguous", "host": host, "pid": pid, "run_id": run_id,
            "trace_sha256": trace_sha, "argv": argv,
            "trace_timestamp": timestamp, "reason": "pinned process ID still exists; do not infer inactivity"}


def _verify_run_binding(repo: Path, workstream: str, run_id: str, claim_sha: str | None,
                        branch_sha: str | None, local_branch_sha: str | None,
                        worktree: Path | None) -> str:
    """Tie the selected owner trace to the exact preserved claim and checkout."""
    path = common_dir(repo) / "custodian-workflow" / "traces" / workstream / f"{run_id}.jsonl"
    try:
        events = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    except (OSError, json.JSONDecodeError) as exc:
        raise QuarantineError(f"pinned run trace cannot be parsed: {exc}") from exc
    if not events or any(event.get("workstream") != workstream or event.get("run_id") != run_id for event in events):
        raise QuarantineError("pinned run trace contains a mismatched identity")
    claim_events = [event.get("data", {}) for event in events if event.get("event") == "remote_claim_acquired"]
    if (len(claim_events) != 1
            or claim_events[0].get("remote_ref") != f"refs/heads/dispatch-claims/{workstream}"):
        raise QuarantineError("pinned run trace does not uniquely prove the original claim identity")
    acquired_claim_sha = claim_events[0].get("claim_oid")
    if not isinstance(acquired_claim_sha, str) or not SHA_RE.fullmatch(acquired_claim_sha):
        raise QuarantineError("pinned run trace has no valid original claim commit")
    if claim_sha is not None and claim_sha != acquired_claim_sha:
        raise QuarantineError("pinned run trace does not match the current exact remote claim")
    if git(repo, "cat-file", "-t", acquired_claim_sha, check=False) != "commit":
        raise QuarantineError("original claim commit is unavailable for preservation")
    if worktree is not None:
        publications = [event.get("data", {}) for event in events if event.get("event") == "worktree_published"]
        expected_head = branch_sha or local_branch_sha
        if (len(publications) != 1 or publications[0].get("branch") != f"agent/{workstream}"
                or publications[0].get("worktree") != str(worktree)
                or publications[0].get("head") != expected_head
                or publications[0].get("upstream") != expected_head):
            raise QuarantineError(
                "pinned run trace does not uniquely prove the exact worktree and branch head "
                f"(published={publications!r}, expected_path={str(worktree)!r}, expected_head={expected_head!r})"
            )
    return acquired_claim_sha


def _build_plan(repo: Path, workstream: str, run_id: str | None, snapshot_manifest: Path,
                manifest: dict[str, Any]) -> dict[str, Any]:
    if not ID_RE.fullmatch(workstream):
        raise QuarantineError("workstream must be lowercase kebab-case")
    repo = coordination_root(repo)
    _fetch_quarantine_refs(repo)
    claim_ref = f"refs/heads/dispatch-claims/{workstream}"
    branch_ref = f"refs/heads/agent/{workstream}"
    claim_sha = _remote_sha(repo, claim_ref)
    branch_sha = _remote_sha(repo, branch_ref)
    local_branch_sha = git(repo, "rev-parse", "--verify", f"refs/heads/agent/{workstream}", check=False) or None
    claim_tracking = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/dispatch-claims/{workstream}", check=False) or None
    branch_tracking = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/agent/{workstream}", check=False) or None
    if not claim_sha and not branch_sha and not local_branch_sha:
        raise QuarantineError("no exact remote claim, remote branch, or local branch exists")
    if ((claim_sha is not None and claim_sha != claim_tracking)
            or (branch_sha is not None and branch_sha != branch_tracking)):
        raise QuarantineError("present remote refs do not match their fetched tracking refs; fetch and re-plan")
    worktree = _worktrees(repo).get(workstream)
    paths = _worktree_inventory(worktree)
    saved = manifest.get("workstreams", {}).get(workstream)
    if not isinstance(saved, dict):
        raise QuarantineError("verified backup manifest does not cover this workstream")
    saved_claim_tracking = saved.get(
        "claim_tracking_sha", _manifest_ref_sha(manifest, f"refs/remotes/origin/dispatch-claims/{workstream}")
    )
    saved_branch_tracking = saved.get(
        "branch_tracking_sha", _manifest_ref_sha(manifest, f"refs/remotes/origin/agent/{workstream}")
    )
    if (saved.get("claim_sha") != claim_sha or saved.get("branch_sha") != branch_sha
            or saved_claim_tracking != claim_tracking or saved_branch_tracking != branch_tracking
            or saved.get("local_branch_sha") != local_branch_sha):
        raise QuarantineError("backup manifest refs do not match the current exact owner")
    if saved.get("worktree_path") != (str(worktree) if worktree else None):
        raise QuarantineError("worktree path changed since the verified backup")
    if saved.get("worktree_inventory_sha256") != sha256_bytes(canonical(paths)):
        raise QuarantineError("worktree status/content inventory changed since the verified backup")
    owner = _owner_state(repo, workstream, run_id)
    acquired_claim_sha = None
    if run_id:
        acquired_claim_sha = _verify_run_binding(
            repo, workstream, run_id, claim_sha, branch_sha, local_branch_sha, worktree
        )
    evidence_root = common_dir(repo) / "custodian-review-runs" / workstream
    evidence_inventory = _tree_inventory(evidence_root)
    trace_root = common_dir(repo) / "custodian-workflow" / "traces" / workstream
    trace_inventory = _tree_inventory(trace_root)
    if saved.get("review_evidence_inventory_sha256") != sha256_bytes(canonical(evidence_inventory)):
        raise QuarantineError("review evidence changed since the verified backup")
    if saved.get("workflow_trace_inventory_sha256") != sha256_bytes(canonical(trace_inventory)):
        raise QuarantineError("workflow trace evidence changed since the verified backup")
    previous = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/{quarantine_ref(workstream)}", check=False) or None
    payload = {
        "schema": PLAN_SCHEMA, "generation": GENERATION, "workstream": workstream,
        "run_id": run_id, "claim_ref": claim_ref, "claim_sha": claim_sha,
        "claim_acquired_sha": acquired_claim_sha,
        "branch_ref": branch_ref, "branch_sha": branch_sha,
        "local_branch_sha": local_branch_sha, "worktree_path": str(worktree) if worktree else None,
        "worktree_inventory_sha256": sha256_bytes(canonical(paths)),
        "review_evidence_inventory_sha256": sha256_bytes(canonical(evidence_inventory)),
        "workflow_trace_inventory_sha256": sha256_bytes(canonical(trace_inventory)),
        "backup_manifest": str(snapshot_manifest.resolve()),
        "backup_manifest_sha256": sha256_file(snapshot_manifest),
        "owner": owner, "previous_record_sha": previous,
        "lock_released": owner.get("state") == "exited_verified",
    }
    payload["plan_sha256"] = sha256_bytes(canonical(payload))
    return payload


def build_plan(repo: Path, workstream: str, run_id: str | None, snapshot_manifest: Path) -> dict[str, Any]:
    repo = coordination_root(repo)
    manifest = verify_snapshot(snapshot_manifest)
    return _build_plan(repo, workstream, run_id, snapshot_manifest, manifest)


def build_batch_plan(repo: Path, targets: dict[str, str | None], snapshot_manifest: Path) -> dict[str, Any]:
    repo = coordination_root(repo)
    manifest = verify_snapshot(snapshot_manifest)
    plans = [_build_plan(repo, workstream, run_id, snapshot_manifest, manifest)
             for workstream, run_id in sorted(targets.items())]
    payload: dict[str, Any] = {
        "schema": "custodian.legacy_quarantine_batch_plan.v1", "generation": GENERATION,
        "backup_manifest": str(snapshot_manifest.resolve()),
        "backup_manifest_sha256": sha256_file(snapshot_manifest), "items": plans,
    }
    payload["plan_sha256"] = sha256_bytes(canonical(payload))
    return payload


def _fetch_quarantine_refs(repo: Path) -> None:
    listing = subprocess.run(["git", "ls-remote", "--refs", "origin", f"{REF_PREFIX}/*"],
                             cwd=repo, text=True, capture_output=True, timeout=20)
    if listing.returncode:
        raise QuarantineError(f"origin could not verify quarantine refs: {(listing.stderr or listing.stdout).strip()}")
    if not listing.stdout.strip():
        return
    result = subprocess.run(
        ["git", "fetch", "origin", f"+{REF_PREFIX}/*:refs/remotes/origin/{REF_PREFIX.removeprefix('refs/') }/*"],
        cwd=repo, text=True, capture_output=True, timeout=30,
    )
    if result.returncode and "couldn't find remote ref" not in (result.stderr or "").lower():
        raise QuarantineError(f"could not fetch quarantine records: {(result.stderr or result.stdout).strip()}")


def fetch_records(repo: Path) -> None:
    """Fetch append-only quarantine records into remote-tracking refs."""
    _fetch_quarantine_refs(coordination_root(repo))


def quarantined_identities(repo: Path) -> set[str]:
    fetch_records(repo)
    prefix = f"refs/remotes/origin/{REF_PREFIX.removeprefix('refs/')}/"
    refs = git(repo, "for-each-ref", "--format=%(refname)", prefix).splitlines()
    return {ref.removeprefix(prefix) for ref in refs}


def _load_record(repo: Path, ref: str) -> tuple[str, dict[str, Any]] | None:
    sha = git(repo, "rev-parse", "--verify", ref, check=False)
    if not sha:
        return None
    try:
        value = json.loads(git(repo, "show", f"{sha}:quarantine.json"))
    except (QuarantineError, json.JSONDecodeError) as exc:
        return sha, {"state": "invalid", "reason": str(exc)}
    return sha, value if isinstance(value, dict) else {"state": "invalid", "reason": "record is not an object"}


def dispatcher_state(repo: Path, workstream: str, claim_sha: str | None = None,
                     branch_sha: str | None = None) -> dict[str, Any]:
    """Return verified quarantine state; every ambiguity keeps the lock held."""
    ref = f"refs/remotes/origin/{quarantine_ref(workstream).removeprefix('refs/') }"
    found = _load_record(repo, ref)
    if found is None:
        return {"state": "absent", "lock_released": False, "record_sha": None}
    record_sha, record = found
    expected = {
        "schema": SCHEMA, "generation": GENERATION, "state": "legacy_quarantined",
        "workstream": workstream, "claim_sha": claim_sha, "branch_sha": branch_sha,
    }
    if any(record.get(key) != value for key, value in expected.items()):
        return {"state": "invalid", "lock_released": False, "record_sha": record_sha,
                "reason": "record identity, refs, or generation mismatch"}
    parents = git(repo, "show", "-s", "--format=%P", record_sha).split()
    expected_parents = list(dict.fromkeys(
        sha for sha in (record.get("claim_sha"), record.get("branch_sha"), record.get("local_branch_sha"),
                        record.get("claim_acquired_sha")) if sha
    ))
    if len(parents) != len(expected_parents) or set(parents) != set(expected_parents):
        return {"state": "invalid", "lock_released": False, "record_sha": record_sha,
                "reason": "record ancestry does not bind the exact original refs"}
    if not SHA256_RE.fullmatch(str(record.get("backup_manifest_sha256", ""))):
        return {"state": "invalid", "lock_released": False, "record_sha": record_sha,
                "reason": "backup manifest digest is invalid"}
    if record.get("lock_released") is not True:
        return {"state": "legacy_quarantined", "lock_released": False, "record_sha": record_sha,
                "reason": record.get("owner", {}).get("reason", "owner remains unresolved")}
    owner = record.get("owner", {})
    if owner.get("state") != "exited_verified" or owner.get("host") != socket.gethostname():
        return {"state": "invalid", "lock_released": False, "record_sha": record_sha,
                "reason": "lock release lacks same-host process-exit evidence"}
    live_owner = _owner_state(repo, workstream, owner.get("run_id"))
    if (live_owner.get("state") != "exited_verified" or live_owner.get("pid") != owner.get("pid")
            or live_owner.get("host") != owner.get("host")
            or live_owner.get("trace_sha256") != owner.get("trace_sha256")):
        return {"state": "invalid", "lock_released": False, "record_sha": record_sha,
                "reason": "pinned process-exit proof no longer verifies on this host"}
    return {"state": "legacy_quarantined", "lock_released": True, "record_sha": record_sha,
            "reason": "exact claim preserved; execution owner verified exited"}


def local_quarantine_state(repo: Path, workstream: str) -> dict[str, Any]:
    _fetch_quarantine_refs(repo)
    claim_sha = _remote_sha(repo, f"refs/heads/dispatch-claims/{workstream}")
    branch_sha = _remote_sha(repo, f"refs/heads/agent/{workstream}")
    return dispatcher_state(repo, workstream, claim_sha, branch_sha)


def _record_commit(repo: Path, plan: dict[str, Any]) -> str:
    claim_sha, branch_sha = plan.get("claim_sha"), plan.get("branch_sha")
    parents = list(dict.fromkeys(
        sha for sha in (claim_sha, branch_sha, plan.get("local_branch_sha"), plan.get("claim_acquired_sha")) if sha
    ))
    record = {
        "schema": SCHEMA, "version": 1, "generation": GENERATION,
        "state": "legacy_quarantined", "workstream": plan["workstream"],
        "run_id": plan.get("run_id"), "claim_ref": plan["claim_ref"], "claim_sha": claim_sha,
        "claim_acquired_sha": plan.get("claim_acquired_sha"),
        "branch_ref": plan["branch_ref"], "branch_sha": branch_sha,
        "local_branch_sha": plan.get("local_branch_sha"), "worktree_path": plan.get("worktree_path"),
        "worktree_inventory_sha256": plan["worktree_inventory_sha256"],
        "review_evidence_inventory_sha256": plan["review_evidence_inventory_sha256"],
        "workflow_trace_inventory_sha256": plan["workflow_trace_inventory_sha256"],
        "backup_manifest_sha256": plan["backup_manifest_sha256"],
        "owner": plan["owner"], "lock_released": plan["lock_released"],
        "created_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    blob = git(repo, "hash-object", "-w", "--stdin", input_text=canonical(record).decode())
    tree = git(repo, "mktree", input_text=f"100644 blob {blob}\tquarantine.json\n")
    argv = ["commit-tree", tree]
    for parent in parents:
        argv += ["-p", parent]
    return git(repo, *argv, "-m", f"legacy quarantine {plan['workstream']}")


def apply_batch_plan(repo: Path, plan: dict[str, Any], expected_digest: str) -> dict[str, str]:
    repo = coordination_root(repo)
    try:
        # Serialize the owner recheck and atomic ref publication against all
        # local dispatch/start critical sections and direct per-workstream resumes.
        with common_mutex(repo):
            with ExitStack() as locks:
                for item in sorted(plan.get("items", []), key=lambda value: value.get("workstream", "")):
                    locks.enter_context(workstream_mutex(repo, item["workstream"]))
                return _apply_batch_plan_unlocked(repo, plan, expected_digest)
    except WorkflowControlError as exc:
        raise QuarantineError(f"local dispatcher ownership is active; quarantine not applied: {exc}") from exc


def _apply_batch_plan_unlocked(repo: Path, plan: dict[str, Any], expected_digest: str) -> dict[str, str]:
    repo = coordination_root(repo)
    if plan.get("plan_sha256") != expected_digest:
        raise QuarantineError("plan digest mismatch")
    if plan.get("schema") != "custodian.legacy_quarantine_batch_plan.v1" or plan.get("generation") != GENERATION:
        raise QuarantineError("unsupported or stale quarantine batch plan")
    targets = {item["workstream"]: item.get("run_id") for item in plan.get("items", [])}
    fresh = build_batch_plan(repo, targets, Path(plan["backup_manifest"]))
    if fresh != plan:
        raise QuarantineError("owner, refs, worktree, evidence, or plan changed; create a fresh plan")
    if not fresh.get("items"):
        raise QuarantineError("empty quarantine batch is prohibited")
    for item in fresh["items"]:
        if item["owner"].get("state") == "active_or_pid_ambiguous":
            raise QuarantineError(f"active or PID-ambiguous owner cannot be quarantined: {item['workstream']}")
        if item.get("previous_record_sha"):
            raise QuarantineError(f"workstream already has a quarantine record: {item['workstream']}")
    commits: dict[str, str] = {}
    local_refs: list[str] = []
    for item in fresh["items"]:
        workstream = item["workstream"]
        commit = _record_commit(repo, item)
        ref = quarantine_ref(workstream)
        git(repo, "update-ref", ref, commit)
        local_refs.append(ref)
        commits[workstream] = commit
    push_args = ["push", "--atomic", "origin"]
    for item in fresh["items"]:
        if item.get("claim_sha"):
            push_args.append(f"{item['claim_sha']}:{item['claim_ref']}")
        if item.get("branch_sha"):
            push_args.append(f"{item['branch_sha']}:{item['branch_ref']}")
        push_args.append(f"{commits[item['workstream']]}:{quarantine_ref(item['workstream'])}")
    result = subprocess.run(["git", *push_args], cwd=repo, text=True, capture_output=True, timeout=60)
    if result.returncode:
        for ref in local_refs:
            git(repo, "update-ref", "-d", ref, check=False)
        raise QuarantineError(f"atomic quarantine publication failed; original refs remain untouched: {(result.stderr or result.stdout).strip()}")
    _fetch_quarantine_refs(repo)
    for item in fresh["items"]:
        state = dispatcher_state(repo, item["workstream"], item.get("claim_sha"), item.get("branch_sha"))
        if state.get("record_sha") != commits[item["workstream"]] or state.get("state") != "legacy_quarantined":
            raise QuarantineError(f"published quarantine failed independent readback for {item['workstream']}: {state}")
    return commits


def apply_plan(repo: Path, plan: dict[str, Any], expected_digest: str) -> str:
    """Compatibility wrapper for applying a single exact-owner plan."""
    if plan.get("schema") == "custodian.legacy_quarantine_batch_plan.v1":
        commits = apply_batch_plan(repo, plan, expected_digest)
        return commits[plan["items"][0]["workstream"]]
    batch = {
        "schema": "custodian.legacy_quarantine_batch_plan.v1", "generation": plan["generation"],
        "backup_manifest": plan["backup_manifest"], "backup_manifest_sha256": plan["backup_manifest_sha256"],
        "items": [plan],
    }
    batch["plan_sha256"] = sha256_bytes(canonical(batch))
    return apply_batch_plan(repo, batch, batch["plan_sha256"])[plan["workstream"]]


def snapshot(repo: Path, workstreams: list[str], destination: Path) -> dict[str, Any]:
    repo = coordination_root(repo)
    destination = destination.expanduser().resolve()
    git(repo, "fetch", "origin")
    _fetch_quarantine_refs(repo)
    if destination.exists() and (not destination.is_dir() or any(destination.iterdir())):
        raise QuarantineError(f"snapshot destination is not an empty directory: {destination}")
    destination.mkdir(parents=True, exist_ok=True)
    paths = _worktrees(repo)
    manifest: dict[str, Any] = {
        "schema": "custodian.execution_reset_backup.v1", "created_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repository": str(repo), "generation": GENERATION,
        "main_sha": git(repo, "rev-parse", "origin/main"),
        "local_head": git(repo, "rev-parse", "HEAD"),
        "refs": [line.split(" ", 1) for line in git(repo, "for-each-ref", "--format=%(refname) %(objectname)").splitlines()],
        "workstreams": {}, "files": {},
    }
    bundle = destination / "all-refs.bundle"
    result = subprocess.run(["git", "bundle", "create", str(bundle), "--all"], cwd=repo, text=True, capture_output=True, timeout=300)
    if result.returncode:
        raise QuarantineError(f"all-ref Git bundle failed: {(result.stderr or result.stdout).strip()}")
    verify = subprocess.run(["git", "bundle", "verify", str(bundle)], cwd=repo, text=True, capture_output=True, timeout=120)
    if verify.returncode:
        raise QuarantineError(f"Git bundle verification failed: {(verify.stderr or verify.stdout).strip()}")
    manifest["files"][bundle.name] = {"sha256": sha256_file(bundle), "size": bundle.stat().st_size}
    lfs_objects = common_dir(repo) / "lfs" / "objects"
    if lfs_objects.is_dir():
        lfs_archive = destination / "git-lfs-objects.tar"
        with tarfile.open(lfs_archive, "w", format=tarfile.PAX_FORMAT) as tar:
            tar.add(lfs_objects, arcname="objects", recursive=True)
        manifest["files"][lfs_archive.name] = {"sha256": sha256_file(lfs_archive), "size": lfs_archive.stat().st_size}
    for workstream in sorted(set(workstreams)):
        if not ID_RE.fullmatch(workstream):
            raise QuarantineError(f"invalid workstream ID: {workstream}")
        claim_ref = f"refs/heads/dispatch-claims/{workstream}"
        branch_ref = f"refs/heads/agent/{workstream}"
        claim_sha, branch_sha = _remote_sha(repo, claim_ref), _remote_sha(repo, branch_ref)
        claim_tracking = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/dispatch-claims/{workstream}", check=False) or None
        branch_tracking = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/agent/{workstream}", check=False) or None
        if ((claim_sha is not None and claim_sha != claim_tracking)
                or (branch_sha is not None and branch_sha != branch_tracking)):
            raise QuarantineError(f"present remote refs differ from remote-tracking refs for {workstream}")
        local_sha = git(repo, "rev-parse", "--verify", f"refs/heads/agent/{workstream}", check=False) or None
        worktree = paths.get(workstream)
        inventory = _worktree_inventory(worktree)
        before_digest = sha256_bytes(canonical(inventory))
        row = {"claim_sha": claim_sha, "branch_sha": branch_sha, "claim_tracking_sha": claim_tracking,
               "branch_tracking_sha": branch_tracking, "local_branch_sha": local_sha,
               "worktree_path": str(worktree) if worktree else None,
               "worktree_inventory_sha256": sha256_bytes(canonical(inventory)), "worktree_inventory": inventory}
        evidence_root = common_dir(repo) / "custodian-review-runs" / workstream
        trace_root = common_dir(repo) / "custodian-workflow" / "traces" / workstream
        row["review_evidence_inventory_sha256"] = sha256_bytes(canonical(_tree_inventory(evidence_root)))
        row["workflow_trace_inventory_sha256"] = sha256_bytes(canonical(_tree_inventory(trace_root)))
        manifest["workstreams"][workstream] = row
        if worktree and worktree.is_dir():
            archive = destination / f"worktree-{workstream}.tar"
            with tarfile.open(archive, "w", format=tarfile.PAX_FORMAT) as tar:
                for child in sorted(worktree.iterdir()):
                    if child.name == ".git":
                        continue
                    tar.add(child, arcname=child.name, recursive=True)
            after_digest = sha256_bytes(canonical(_worktree_inventory(worktree)))
            if before_digest != after_digest:
                raise QuarantineError(f"worktree changed while being backed up: {workstream}")
            manifest["files"][archive.name] = {"sha256": sha256_file(archive), "size": archive.stat().st_size}
        evidence_root = common_dir(repo) / "custodian-review-runs" / workstream
        if evidence_root.is_dir():
            evidence_digest = sha256_bytes(canonical(_tree_inventory(evidence_root)))
            archive = destination / f"review-evidence-{workstream}.tar"
            with tarfile.open(archive, "w", format=tarfile.PAX_FORMAT) as tar:
                tar.add(evidence_root, arcname=workstream, recursive=True)
            if evidence_digest != sha256_bytes(canonical(_tree_inventory(evidence_root))):
                raise QuarantineError(f"review evidence changed while being backed up: {workstream}")
            manifest["files"][archive.name] = {"sha256": sha256_file(archive), "size": archive.stat().st_size}
        trace_root = common_dir(repo) / "custodian-workflow" / "traces" / workstream
        if trace_root.is_dir():
            trace_digest = sha256_bytes(canonical(_tree_inventory(trace_root)))
            archive = destination / f"workflow-traces-{workstream}.tar"
            with tarfile.open(archive, "w", format=tarfile.PAX_FORMAT) as tar:
                tar.add(trace_root, arcname=workstream, recursive=True)
            if trace_digest != sha256_bytes(canonical(_tree_inventory(trace_root))):
                raise QuarantineError(f"workflow trace changed while being backed up: {workstream}")
            manifest["files"][archive.name] = {"sha256": sha256_file(archive), "size": archive.stat().st_size}
    git(repo, "fetch", "origin")
    ending_refs = [line.split(" ", 1) for line in git(repo, "for-each-ref", "--format=%(refname) %(objectname)").splitlines()]
    if ending_refs != manifest["refs"] or git(repo, "rev-parse", "origin/main") != manifest["main_sha"]:
        raise QuarantineError("repository refs changed while the backup was being created; preserve artifacts and take a fresh snapshot")
    manifest_path = destination / "manifest.json"
    manifest_path.write_bytes(canonical(manifest) + b"\n")
    manifest["manifest_sha256"] = sha256_bytes(canonical(manifest))
    manifest_path.write_bytes(canonical(manifest) + b"\n")
    return {"path": str(manifest_path), "manifest_sha256": sha256_file(manifest_path), "workstreams": len(manifest["workstreams"]), "files": len(manifest["files"])}


def verify_snapshot(path: Path) -> dict[str, Any]:
    try:
        if path.is_symlink():
            raise QuarantineError("backup manifest must not be a symlink")
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise QuarantineError(f"backup manifest missing or malformed: {exc}") from exc
    if not isinstance(manifest, dict) or manifest.get("schema") != "custodian.execution_reset_backup.v1":
        raise QuarantineError("unsupported backup manifest")
    expected_self_hash = manifest.get("manifest_sha256")
    unhashed = dict(manifest)
    unhashed.pop("manifest_sha256", None)
    if expected_self_hash != sha256_bytes(canonical(unhashed)):
        raise QuarantineError("backup manifest self-checksum is invalid")
    for name, entry in manifest.get("files", {}).items():
        file = path.parent / name
        if not file.is_file() or file.is_symlink() or sha256_file(file) != entry.get("sha256") or file.stat().st_size != entry.get("size"):
            raise QuarantineError(f"backup artifact missing or changed: {name}")
    bundle = path.parent / "all-refs.bundle"
    result = subprocess.run(["git", "bundle", "verify", str(bundle)], text=True, capture_output=True, timeout=120)
    if result.returncode:
        raise QuarantineError(f"backup Git bundle cannot be verified: {(result.stderr or result.stdout).strip()}")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    snap = sub.add_parser("snapshot", help="copy all refs, target worktrees, and run evidence")
    snap.add_argument("--repo", type=Path, default=Path.cwd())
    snap.add_argument("--workstream", action="append", required=True)
    snap.add_argument("--destination", type=Path, required=True)
    verify = sub.add_parser("verify-snapshot", help="verify backup manifest, payload hashes, and Git bundle")
    verify.add_argument("manifest", type=Path)
    batch_plan = sub.add_parser("plan-batch", help="plan one atomic quarantine for exact workstream=run-id targets")
    batch_plan.add_argument("--target", action="append", required=True, metavar="WORKSTREAM=RUN_ID")
    batch_plan.add_argument("--snapshot-manifest", type=Path, required=True)
    batch_plan.add_argument("--repo", type=Path, default=Path.cwd())
    batch_plan.add_argument("--output", type=Path, required=True)
    batch_apply = sub.add_parser("apply-batch", help="apply a previously emitted exact batch plan")
    batch_apply.add_argument("plan", type=Path)
    batch_apply.add_argument("--plan-sha256", required=True)
    batch_apply.add_argument("--repo", type=Path, default=Path.cwd())
    for name in ("plan", "apply"):
        item = sub.add_parser(name)
        item.add_argument("workstream")
        item.add_argument("--run-id")
        item.add_argument("--snapshot-manifest", type=Path, required=True)
        item.add_argument("--repo", type=Path, default=Path.cwd())
        if name == "apply":
            item.add_argument("--plan-sha256", required=True)
    args = parser.parse_args()
    try:
        if args.command == "snapshot":
            output = snapshot(args.repo, args.workstream, args.destination)
        elif args.command == "verify-snapshot":
            value = verify_snapshot(args.manifest)
            output = {"verified": True, "manifest_sha256": sha256_file(args.manifest), "workstreams": len(value.get("workstreams", {}))}
        elif args.command == "plan-batch":
            targets: dict[str, str | None] = {}
            for raw in args.target:
                workstream, separator, run_id = raw.partition("=")
                if not separator or not workstream or workstream in targets:
                    raise QuarantineError("each --target must be a unique WORKSTREAM=RUN_ID pair")
                targets[workstream] = run_id or None
            output = build_batch_plan(args.repo, targets, args.snapshot_manifest)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_bytes(canonical(output) + b"\n")
            output = {"path": str(args.output.resolve()), "plan_sha256": output["plan_sha256"],
                      "targets": list(targets)}
        elif args.command == "apply-batch":
            if args.plan.is_symlink():
                raise QuarantineError("batch plan must not be a symlink")
            plan = json.loads(args.plan.read_text(encoding="utf-8"))
            commits = apply_batch_plan(args.repo, plan, args.plan_sha256)
            output = {"state": "legacy_quarantined", "records": commits,
                      "claim_identities_preserved": True, "atomic": True}
        elif args.command == "plan":
            output = build_plan(args.repo, args.workstream, args.run_id, args.snapshot_manifest)
        else:
            fresh = build_plan(args.repo, args.workstream, args.run_id, args.snapshot_manifest)
            commit = apply_plan(args.repo, fresh, args.plan_sha256)
            output = {"state": "legacy_quarantined", "workstream": args.workstream, "record_sha": commit,
                      "lock_released": fresh["lock_released"], "claim_identity_preserved": True}
    except QuarantineError as exc:
        print(f"legacy_claim_quarantine: ERROR: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
