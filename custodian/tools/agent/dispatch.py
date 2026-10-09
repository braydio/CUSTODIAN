#!/usr/bin/env python3
"""Discover and claim CUSTODIAN task packets from fetched origin/main."""

from __future__ import annotations

import argparse
import contextlib
import importlib.util
import inspect
import io
import json
import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import (
    RunTrace, WorkflowControlError, acquire_remote_claim, common_mutex,
    release_remote_claim, resolve_agent_id, workstream_mutex,
)
from task_packet_contract import (
    BOUNDED_REVIEW_OVERRIDE, FIELDS, ID_RE, KINDS, PACKET_ROOT, PRIORITY,
    REVIEW_INTENTS, REVIEW_MODES, VALIDATION_SCRIPT_RE, Packet,
    _bounded_review_override_error, _header_field_with_continuations,
    _validation_script_references, parse_packet, review_cycle_exhausted,
    validate_packet_validation_references, validate_review_pairing,
    validate_queue_contract,
)


class DispatchError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise DispatchError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def _tree_paths(repo: Path, tree: str, prefix: str) -> list[str]:
    raw = git(repo, "ls-tree", "-r", "--name-only", tree, "--", prefix)
    return [
        p for p in raw.splitlines()
        if p.startswith(prefix + "/")
        and p.endswith(".md")
        and "/" not in p[len(prefix) + 1:]
        and p != f"{prefix}/README.md"
    ]


def _packets(repo: Path, tree: str = "origin/main") -> list[Packet]:
    paths = _tree_paths(repo, tree, PACKET_ROOT)
    return [parse_packet(path, git(repo, "show", f"{tree}:{path}")) for path in paths]


def _archived_packets(repo: Path, tree: str = "origin/main") -> list[Packet]:
    prefix = f"{PACKET_ROOT}/archived"
    paths = [p for p in git(repo, "ls-tree", "-r", "--name-only", tree, "--", prefix).splitlines() if p.endswith(".md")]
    return [parse_packet(p, git(repo, "show", f"{tree}:{p}")) for p in paths]


def _packet_texts(repo: Path, packets: list[Packet], tree: str = "origin/main") -> dict[str, str]:
    return {packet.path: git(repo, "show", f"{tree}:{packet.path}") for packet in packets}


def _claimed(repo: Path) -> set[str]:
    # Remote refs are claim authority. A successful dispatcher claim always has
    # either a temporary dispatch-claim ref during acquisition or a published
    # origin/agent/<id> branch after workstream.start(). Local-only worktrees are
    # recovery/residue surfaces and must not poison the global queue.
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/agent").splitlines()
    claimed = {ref.removeprefix("refs/remotes/origin/agent/") for ref in refs}
    claims, branches = _remote_claim_state(repo)
    claimed.update(claims & branches)
    return claimed


def _remote_claim_state(repo: Path) -> tuple[set[str], set[str]]:
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/dispatch-claims").splitlines()
    claims = {ref.removeprefix("refs/remotes/origin/dispatch-claims/") for ref in refs}
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/agent").splitlines()
    branches = {ref.removeprefix("refs/remotes/origin/agent/") for ref in refs}
    return claims, branches


def _decision(
    packet: Packet, packets: list[Packet], archived: list[Packet], claimed: set[str],
    *, auto_only: bool, pairing_errors: dict[str, str] | None = None,
    validation_errors: dict[str, str] | None = None,
    queue_errors: dict[str, str] | None = None,
) -> tuple[bool, str | None]:
    if packet.error:
        return False, f"invalid packet metadata: {packet.error}"
    if pairing_errors and packet.workstream in pairing_errors:
        return False, f"invalid review pairing: {pairing_errors[packet.workstream]}"
    if validation_errors and packet.workstream in validation_errors:
        return False, f"invalid validation references: {validation_errors[packet.workstream]}"
    if queue_errors and packet.workstream in queue_errors:
        return False, f"invalid queue contract: {queue_errors[packet.workstream]}"
    if packet.status != "ready":
        return False, f"status: {packet.status or 'missing'}"
    if auto_only and packet.dispatch != "auto":
        return False, "manual dispatch"
    if packet.workstream in claimed:
        return False, "already claimed"
    same_id = [p for p in packets if p.workstream == packet.workstream]
    if len(same_id) > 1:
        return False, f"duplicate Workstream identity: {packet.workstream}"
    complete = {p.workstream for p in archived if not p.error and p.status == "complete"}
    for dependency in packet.dependencies:
        if dependency not in complete:
            return False, f"dependency: {dependency}"
    by_id = {p.workstream: p for p in packets if p.workstream and not p.error}
    for holder in sorted(claimed):
        claimed_packet = next((p for p in packets if p.workstream == holder), None)
        if claimed_packet and claimed_packet.dispatch == "auto" and claimed_packet.error and "Locks" in claimed_packet.error:
            return False, f"lock: unknown held by {holder} (malformed lock declaration)"
    claimed_packet_locks = [(work_id, by_id[work_id].locks) for work_id in sorted(claimed) if work_id in by_id]
    for holder, locks in claimed_packet_locks:
        overlap = sorted(set(packet.locks) & set(locks))
        if overlap:
            return False, f"lock: {overlap[0]} held by {holder}"
    return True, None


def _fetch(repo: Path) -> None:
    git(repo, "fetch", "--prune", "origin")


def _git_common_dir(repo: Path) -> Path:
    common = Path(git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    return common


def _mutex(repo: Path, *, timeout_seconds: float = 0.0):
    return common_mutex(repo, timeout_seconds=timeout_seconds)


def _last_claim_path(repo: Path) -> Path:
    return _git_common_dir(repo) / "custodian-dispatch" / "last-claim.json"


def _write_last_claim_receipt(repo: Path, receipt: dict) -> None:
    """Persist the latest successful claim outside the worktree for stdout-loss recovery."""
    path = _last_claim_path(repo)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(receipt, indent=2) + "\n")
    os.replace(tmp, path)


def _attached_local_worktree(repo: Path, branch: str) -> str | None:
    for record in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        lines = record.splitlines()
        if lines and f"branch refs/heads/{branch}" in lines:
            return lines[0].removeprefix("worktree ")
    return None


def _start_workstream(module, workstream_id: str, repo: Path, claim=None, trace=None) -> tuple[Path, str | None]:
    """Call workstream.start(), passing a disposition side-channel only if supported.

    Test doubles that mock module.start with a plain (work_id, repo) callable must
    keep working unmodified, so the receiver capability is probed rather than assumed.
    """
    report: dict[str, str] = {}
    try:
        parameters = inspect.signature(module.start).parameters
        accepts_report = "report" in parameters
    except (TypeError, ValueError):
        accepts_report = False
    kwargs = {}
    if accepts_report:
        kwargs["report"] = report
    parameters = inspect.signature(module.start).parameters if accepts_report else {}
    if "_claim" in parameters:
        kwargs.update(_claim=claim, _trace=trace, _lock_held=True)
        if "_publish_trace" in parameters:
            kwargs["_publish_trace"] = False
    if kwargs:
        worktree = module.start(workstream_id, repo, **kwargs)
    else:
        worktree = module.start(workstream_id, repo)
    return Path(worktree), report.get("checkout")


def _load_workstream(repo: Path):
    script = repo / "custodian/tools/agent/workstream.py"
    spec = importlib.util.spec_from_file_location("custodian_workstream", script)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _coordination_repo(repo: Path) -> Path:
    """Resolve the attached main checkout used to create sibling task worktrees."""
    for record in git(repo, "worktree", "list", "--porcelain").split("\n\n"):
        lines = record.splitlines()
        if "branch refs/heads/main" in lines:
            return Path(lines[0].removeprefix("worktree ")).resolve()
    return repo


def _packet_label(packet: Packet) -> str:
    name = packet.workstream or packet.path
    if packet.kind == "review" and packet.review_target_workstream:
        return f"{name} (review of {packet.review_target_workstream})"
    if packet.kind == "correction":
        return f"{name} (correction)"
    return name


def _render_status(repo: Path, packets: list[Packet], archived: list[Packet], claimed: set[str]) -> str:
    groups: dict[str, list[str]] = {key: [] for key in (
        "READY", "CLAIMED", "DEPENDENCY/LOCK BLOCKED", "MANUAL READY",
        "PARKED DRAFT", "INVALID/RECOVERY",
    )}
    claims, branches = _remote_claim_state(repo)
    pairing_errors = validate_review_pairing(packets)
    validation_errors = validate_packet_validation_references(repo, packets, exclude_workstreams=claimed)
    packet_texts = _packet_texts(repo, packets)
    queue_errors = validate_queue_contract(packets, archived, packet_texts)
    for work_id in sorted(claims - branches):
        groups["INVALID/RECOVERY"].append(
            f"{work_id} — remote dispatch claim interrupted; recovery required. "
            f"Inspect refs/heads/dispatch-claims/{work_id}; after verifying no live claimant, "
            f"an operator may explicitly delete it with git push origin :refs/heads/dispatch-claims/{work_id}."
        )
    for packet in sorted(packets, key=lambda item: (PRIORITY.get(item.priority, 9), item.path)):
        name = _packet_label(packet)
        if packet.workstream in claims - branches:
            continue
        if packet.workstream in claimed:
            cleanup_note = " (remote claim cleanup pending)" if packet.workstream in claims else ""
            groups["CLAIMED"].append(f"{name}{cleanup_note} [{packet.path}]")
        elif packet.error:
            groups["INVALID/RECOVERY"].append(f"{name} — invalid packet metadata: {packet.error} [{packet.path}]")
        elif packet.workstream in queue_errors:
            groups["INVALID/RECOVERY"].append(f"{name} — {queue_errors[packet.workstream]} [{packet.path}]")
        elif packet.status == "draft" and packet.dispatch == "manual":
            parked_reason = (
                _header_field_with_continuations(packet_texts.get(packet.path, ""), "Refresh instruction")
                or _header_field_with_continuations(packet_texts.get(packet.path, ""), "Refresh reason")
            )
            if parked_reason and len(parked_reason) > 160:
                parked_reason = parked_reason[:157].rstrip() + "..."
            detail = f" — {parked_reason}" if parked_reason else " — refresh/human decision required"
            groups["PARKED DRAFT"].append(f"{name}{detail} [{packet.path}]")
        elif packet.status == "blocked":
            groups["DEPENDENCY/LOCK BLOCKED"].append(f"{name} — status: blocked [{packet.path}]")
        elif not packet.dispatch_declared and packet.status == "ready":
            groups["MANUAL READY"].append(f"{name} [{packet.path}]")
        elif packet.status != "ready":
            groups["INVALID/RECOVERY"].append(f"{name} — status: {packet.status or 'missing'} [{packet.path}]")
        elif packet.dispatch == "manual":
            ok, reason = _decision(
                packet, packets, archived, claimed, auto_only=False,
                pairing_errors=pairing_errors, validation_errors=validation_errors,
                queue_errors=queue_errors,
            )
            if ok:
                groups["MANUAL READY"].append(f"{name} [{packet.path}]")
            else:
                label = "DEPENDENCY/LOCK BLOCKED" if reason and (
                    reason.startswith("dependency:") or reason.startswith("lock:")
                ) else "INVALID/RECOVERY"
                groups[label].append(f"{name} — {reason} [{packet.path}]")
        else:
            ok, reason = _decision(
                packet, packets, archived, claimed, auto_only=True,
                pairing_errors=pairing_errors, validation_errors=validation_errors,
                queue_errors=queue_errors,
            )
            if ok:
                groups["READY"].append(f"{packet.priority} {name} [{packet.path}]")
            else:
                label = "DEPENDENCY/LOCK BLOCKED" if reason and (reason.startswith("dependency:") or reason.startswith("lock:")) else "INVALID/RECOVERY"
                groups[label].append(f"{name} — {reason} [{packet.path}]")
    for label in groups:
        if label == "READY":
            continue
        groups[label].sort()
    sections = []
    for label, values in groups.items():
        shown = values[:20]
        if len(values) > len(shown):
            shown.append(f"... {len(values) - len(shown)} more")
        sections.append(f"{label} ({len(values)})\n" + ("\n".join(shown) if shown else "(none)"))
    return "\n".join(sections)


def status(repo: Path, *, output=True) -> str:
    repo = _coordination_repo(repo)
    _fetch(repo)
    rendered = _render_status(repo, _packets(repo), _archived_packets(repo), _claimed(repo))
    if output:
        print(rendered)
    return rendered


def audit(repo: Path, *, as_json: bool = False) -> dict:
    """Return a deterministic full queue audit using the claim decision path.

    This is read-only except for fetching remote-tracking refs, matching
    `status`. `eligible_now` is computed by the same `_decision` used by an
    explicit named claim; `claim_next_eligible` additionally requires auto.
    """
    repo = _coordination_repo(repo)
    _fetch(repo)
    packets = _packets(repo)
    archived = _archived_packets(repo)
    claimed = _claimed(repo)
    texts = _packet_texts(repo, packets)
    pairing_errors = validate_review_pairing(packets)
    validation_errors = validate_packet_validation_references(repo, packets, exclude_workstreams=claimed)
    queue_errors = validate_queue_contract(packets, archived, texts)
    active_counts: dict[str, int] = {}
    for packet in packets:
        if packet.workstream:
            active_counts[packet.workstream] = active_counts.get(packet.workstream, 0) + 1

    rows = []
    class_counts: dict[str, int] = {}
    for packet in sorted(packets, key=lambda item: (item.workstream or "", item.path)):
        ok, decision_reason = _decision(
            packet, packets, archived, claimed, auto_only=False,
            pairing_errors=pairing_errors, validation_errors=validation_errors,
            queue_errors=queue_errors,
        )
        auto_ok, _ = _decision(
            packet, packets, archived, claimed, auto_only=True,
            pairing_errors=pairing_errors, validation_errors=validation_errors,
            queue_errors=queue_errors,
        )
        reasons = []
        for error_map, label in (
            (pairing_errors, "invalid review pairing"),
            (validation_errors, "invalid validation references"),
            (queue_errors, "invalid queue contract"),
        ):
            detail = error_map.get(packet.workstream)
            if detail:
                reasons.append(f"{label}: {detail}")
        if packet.error:
            reasons.append(f"invalid packet metadata: {packet.error}")
        if active_counts.get(packet.workstream, 0) > 1:
            reasons.append(f"duplicate active identity: {packet.workstream}")
        for dependency in packet.dependencies:
            complete_ids = {p.workstream for p in archived if not p.error and p.status == "complete"}
            if dependency not in complete_ids:
                reasons.append(f"dependency not archived complete: {dependency}")
        if packet.workstream in claimed:
            reasons.append("already claimed by published agent branch")
        if packet.status != "ready":
            reasons.append(f"status is {packet.status or 'missing'}")
        elif packet.dispatch == "manual":
            reasons.append("manual dispatch; named claim only")
        if not reasons and decision_reason:
            reasons.append(decision_reason)

        if packet.workstream in claimed:
            actual_class = "claimed"
        elif packet.error or packet.workstream in pairing_errors or packet.workstream in validation_errors or packet.workstream in queue_errors or active_counts.get(packet.workstream, 0) > 1:
            actual_class = "invalid_recovery"
        elif packet.status == "draft":
            actual_class = "parked_draft" if packet.dispatch == "manual" else "invalid_recovery"
        elif packet.status == "blocked":
            actual_class = "dependency_lock_blocked"
        elif not packet.dispatch_declared and packet.status == "ready":
            actual_class = "manual_ready"
        elif packet.status != "ready":
            actual_class = "invalid_recovery"
        elif decision_reason and (decision_reason.startswith("dependency:") or decision_reason.startswith("lock:")):
            actual_class = "dependency_lock_blocked"
        elif packet.dispatch == "manual" and ok:
            actual_class = "manual_ready"
        elif packet.dispatch == "auto" and auto_ok:
            actual_class = "ready_auto"
        elif packet.dispatch == "manual":
            actual_class = "invalid_recovery"
        else:
            actual_class = "invalid_recovery"
        class_counts[actual_class] = class_counts.get(actual_class, 0) + 1
        rows.append({
            "workstream": packet.workstream,
            "path": packet.path,
            "kind": packet.kind,
            "status": packet.status,
            "dispatch": packet.dispatch,
            "priority": packet.priority,
            "actual_class": actual_class,
            "eligible_now": ok,
            "claim_next_eligible": auto_ok,
            "reasons": sorted(set(reasons)),
            "dependencies": list(packet.dependencies),
            "paired_review_workstream": packet.paired_review_workstream,
            "review_target_workstream": packet.review_target_workstream,
            "claimed": packet.workstream in claimed,
            "recovery_disposition": None,
        })
    raw_active = len(packets)
    managed = sum(not p.error and p.workstream not in queue_errors and p.workstream not in pairing_errors and p.workstream not in validation_errors for p in packets)
    active_ids = {p.workstream for p in packets if p.workstream}
    archived_complete_ids = {p.workstream for p in archived if p.workstream and not p.error and p.status == "complete"}
    worktrees: dict[str, str] = {}
    current = None
    for line in git(repo, "worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            current = line.removeprefix("worktree ")
        elif line.startswith("branch refs/heads/agent/") and current:
            worktrees[line.removeprefix("branch refs/heads/")] = current
    remote_agent_refs = git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/remotes/origin/agent").splitlines()
    local_agent_refs = git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads/agent").splitlines()
    remote_by_id = {line.split(" ", 1)[0].removeprefix("origin/agent/"): line.split(" ", 1)[1] for line in remote_agent_refs}
    local_by_id = {line.split(" ", 1)[0].removeprefix("agent/"): line.split(" ", 1)[1] for line in local_agent_refs}
    claim_refs = git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/remotes/origin/dispatch-claims").splitlines()
    branch_audit = []
    for workstream in sorted(set(remote_by_id) | set(local_by_id)):
        head = remote_by_id.get(workstream) or local_by_id[workstream]
        branch = f"origin/agent/{workstream}" if workstream in remote_by_id else f"agent/{workstream}"
        attached = worktrees.get(f"agent/{workstream}")
        dirty = None
        if attached and Path(attached).is_dir():
            dirty = bool(git(Path(attached), "status", "--porcelain=v2", "--untracked-files=all"))
        counts = git(repo, "rev-list", "--left-right", "--count", f"origin/main...{branch}").split()
        behind, ahead = (int(counts[0]), int(counts[1])) if len(counts) == 2 else (None, None)
        disposition = "protected_attached" if attached else ("protected_unique_history" if ahead else "landed_unattached_candidate")
        if dirty:
            disposition = "protected_dirty_worktree"
        branch_audit.append({
            "workstream": workstream, "branch": branch, "head": head,
            "remote_branch_exists": workstream in remote_by_id,
            "local_branch_exists": workstream in local_by_id,
            "attached_worktree": attached, "dirty": dirty,
            "behind_main": behind, "ahead_of_main": ahead,
            "active_packet": workstream in active_ids,
            "archived_complete_packet": workstream in archived_complete_ids,
            "orphaned_identity": workstream not in active_ids and workstream not in archived_complete_ids,
            "recovery_disposition": disposition,
        })
    remote_claim_audit = []
    for ref in claim_refs:
        branch, head = ref.split(" ", 1)
        workstream = branch.removeprefix("origin/dispatch-claims/")
        has_branch = workstream in {item["workstream"] for item in branch_audit if item["remote_branch_exists"]}
        remote_claim_audit.append({
            "workstream": workstream, "ref": branch, "head": head,
            "agent_branch_exists": has_branch,
            "recovery_disposition": "canonical_branch_present_claim_residue" if has_branch else "protected_claim_without_agent_branch",
        })
    published_ids = {item["workstream"] for item in branch_audit if item["remote_branch_exists"]}
    interrupted_claims = [item for item in remote_claim_audit if not item["agent_branch_exists"]]
    if interrupted_claims:
        class_counts["invalid_recovery"] = class_counts.get("invalid_recovery", 0) + len(interrupted_claims)
    return {
        "schema": "custodian.task_packet_queue_audit.v1",
        "raw_active_markdown_count": raw_active,
        "managed_packet_count": managed,
        "claimable_auto_count": sum(row["claim_next_eligible"] for row in rows),
        "class_counts": dict(sorted(class_counts.items())),
        "remote_agent_branches": branch_audit,
        "remote_dispatch_claims": remote_claim_audit,
        "interrupted_dispatch_claim_count": len(interrupted_claims),
        "packets": rows,
    }


def audit_command(repo: Path, *, as_json: bool = False) -> int:
    result = audit(repo, as_json=as_json)
    if as_json:
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    print(f"ACTIVE RAW MARKDOWN: {result['raw_active_markdown_count']}")
    print(f"MANAGED PACKETS: {result['managed_packet_count']}")
    print(f"CLAIMABLE AUTO: {result['claimable_auto_count']}")
    for label, count in result["class_counts"].items():
        print(f"{label}: {count}")
    for row in result["packets"]:
        if row["actual_class"] in {"ready_auto", "manual_ready", "claimed", "invalid_recovery"}:
            reason = f" — {'; '.join(row['reasons'])}" if row["reasons"] else ""
            print(f"{row['actual_class']} {row['workstream'] or row['path']}{reason} [{row['path']}]")
    return 0


def claim(
    repo: Path,
    workstream_id: str | None,
    agent: str,
    auto_only: bool,
    *,
    lock_wait_seconds: float = 0.0,
) -> int:
    # Serialize assignment authority and canonical publication, but never the
    # best-effort diagnostic network push.
    repo = _coordination_repo(repo)
    trace = None
    receipt = None
    try:
        with _mutex(repo, timeout_seconds=lock_wait_seconds):
            try:
                _fetch(repo)
                packets = _packets(repo)
                archived = _archived_packets(repo)
                claimed = _claimed(repo)
                remote_claims, remote_branches = _remote_claim_state(repo)
                pairing_errors = validate_review_pairing(packets)
                validation_errors = validate_packet_validation_references(repo, packets, exclude_workstreams=claimed)
                queue_errors = validate_queue_contract(packets, archived, _packet_texts(repo, packets))
                ordered = sorted(packets, key=lambda p: (PRIORITY.get(p.priority, 9), p.path))
                candidates = [p for p in ordered if p.workstream == workstream_id] if workstream_id else ordered
                selected = None
                reasons: list[str] = []
                for packet in candidates:
                    ok, reason = _decision(
                        packet, packets, archived, claimed, auto_only=auto_only,
                        pairing_errors=pairing_errors, validation_errors=validation_errors,
                        queue_errors=queue_errors,
                    )
                    if ok:
                        selected = packet
                        break
                    if reason:
                        reasons.append(f"{packet.workstream or packet.path}: {reason}")
                if selected is None:
                    if workstream_id and not candidates:
                        raise DispatchError(
                            f"packet for workstream {workstream_id} does not exist on origin/main. "
                            "If the packet is only local or on an unmerged authoring branch, "
                            "first validate the implementation/review pair with "
                            "custodian/tools/agent/validate_task_packet_authoring.py, "
                            "promote only if authorized, update the managed index using "
                            "custodian/tools/agent/task_packet_index.py --write, "
                            "and land the scoped queue changes on origin/main. "
                            "Fetch and verify remote main before claiming; "
                            "never claim a draft/unpublished packet."
                        )
                    if workstream_id and workstream_id in claimed:
                        branch = f"agent/{workstream_id}"
                        attached = _attached_local_worktree(repo, branch)
                        raise DispatchError(
                            "ALREADY CLAIMED\n"
                            f"workstream: {workstream_id}\n"
                            f"branch: {branch}\n"
                            f"worktree: {attached or 'not attached locally'}"
                        )
                    if workstream_id:
                        raise DispatchError("claim blocked: " + (reasons[0] if reasons else "not eligible"))
                    print("NO ELIGIBLE AUTO TASK")
                    print(f"considered: {len(candidates)}; blocked: {len(reasons)}")
                    for reason in reasons[:20]:
                        print(f"- {reason}")
                    if len(reasons) > 20:
                        print(f"- ... {len(reasons) - 20} more")
                    return 0

                claim_ref = f"refs/heads/dispatch-claims/{selected.workstream}"
                if selected.workstream in remote_claims and selected.workstream not in remote_branches:
                    raise DispatchError(
                        f"remote dispatch claim for {selected.workstream} exists without its agent branch; "
                        f"recovery required. Inspect origin/{claim_ref} and only after verifying no live "
                        f"claimant explicitly remove it with git push origin :{claim_ref}"
                    )

                lock_started = time.monotonic()
                with workstream_mutex(repo, selected.workstream):
                    trace = RunTrace.start(repo, selected.workstream, packet=selected.path, agent=agent)
                    trace.record("mutex_acquired", scope="workstream", wait_ms=round((time.monotonic() - lock_started) * 1000))
                    _fetch(repo)
                    remote_claim = acquire_remote_claim(repo, selected.workstream, agent, trace.run_id, trace=trace)
                    module = _load_workstream(repo)
                    try:
                        with contextlib.redirect_stdout(io.StringIO()):
                            worktree, checkout = _start_workstream(module, selected.workstream, repo, remote_claim, trace)
                    except module.WorkstreamError as error:
                        raise DispatchError(f"workstream start blocked: {error}") from error

                # Verify the canonical branch/worktree and write the authoritative
                # receipt before releasing the shared mutex.
                expected_branch = f"agent/{selected.workstream}"
                if not worktree.is_dir():
                    raise DispatchError(
                        f"post-start verification failed: worktree does not exist at {worktree}; "
                        f"recovery claim retained at origin/{claim_ref} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]"
                    )
                actual_branch = git(worktree, "branch", "--show-current", check=False)
                if actual_branch != expected_branch:
                    raise DispatchError(
                        f"post-start verification failed: worktree {worktree} is on branch "
                        f"{actual_branch!r}, expected {expected_branch!r}; "
                        f"recovery claim retained at origin/{claim_ref} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]"
                    )
                _fetch(repo)
                published = subprocess.run(
                    ["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{expected_branch}"], cwd=repo
                ).returncode == 0
                if not published:
                    raise DispatchError(
                        f"workstream branch was not confirmed published; recovery claim retained at origin/{claim_ref} "
                        f"[run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]"
                    )
                claimed_after = _claimed(repo)
                if selected.workstream not in claimed_after:
                    raise DispatchError(
                        f"post-start verification failed: dispatcher claimed-state logic does not yet "
                        f"recognize {selected.workstream} as claimed; recovery claim retained at origin/{claim_ref} "
                        f"[run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]"
                    )
                release_remote_claim(repo, remote_claim, trace=trace)

                authoring_chat = (
                    selected.authoring_chat
                    or selected.refresh_planning_chat
                    or "not-recorded"
                )
                receipt = {
                    "schema": "custodian.dispatch.claim.v1", "result": "claimed",
                    "workstream": selected.workstream, "prior_status": selected.status,
                    "branch": expected_branch, "worktree": str(worktree), "packet": selected.path,
                    "checkout": checkout, "verified": True, "agent": agent,
                    "run_id": trace.run_id, "trace_ref": trace.diagnostic_ref,
                    "authoring_chat": authoring_chat,
                    "visual_review": selected.visual_review,
                    "visual_review_root": f"/CUSTODIAN/visual_review/{selected.workstream}/",
                    "visual_review_retention": "delete-after-review",
                }
                _write_last_claim_receipt(repo, receipt)
                trace.record("dispatch_receipt_written", packet=selected.path, branch=expected_branch, worktree=str(worktree))
                trace.complete("claimed", publish=False)
            except Exception as error:
                if trace is not None:
                    trace.finish_blocked(str(error), publish=False)
                raise
    except Exception:
        if trace is not None:
            trace.publish()
        raise

    assert receipt is not None and trace is not None
    print("CLAIMED")
    print(f"workstream: {receipt['workstream']}")
    print(f"branch: {receipt['branch']}")
    print(f"worktree: {receipt['worktree']}")
    print(f"packet: {receipt['packet']}")
    print(f"authoring chat: {receipt['authoring_chat']}")
    print(f"visual review: {receipt['visual_review']}")
    print(f"visual review root: {receipt['visual_review_root']}")
    print("visual review retention: delete-after-review unless the packet/user explicitly says retain")
    print("\nNEXT:")
    print(f"cd {receipt['worktree']}")
    print(f"Read AGENTS.md, custodian/AGENTS.md, then {receipt['packet']}.")
    print("Implement only this workstream and finish through workstream.py.")
    print(f"agent: {agent}")
    print("CUSTODIAN_DISPATCH_RESULT_JSON:" + json.dumps(receipt))
    trace.publish()
    return 0


def last_claim(repo: Path, *, as_json: bool) -> int:
    """Recover the last successful claim's identity after stdout loss.

    Read-only: refreshes remote-tracking refs to judge freshness but never
    mutates, re-claims, or recreates anything, even when the receipt is stale.
    """
    repo = _coordination_repo(repo)
    path = _last_claim_path(repo)
    if not path.is_file():
        if as_json:
            print(json.dumps({"schema": "custodian.dispatch.claim.v1", "result": "no-receipt"}))
        else:
            print("NO LAST CLAIM RECEIPT")
        return 1

    try:
        receipt = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise DispatchError(f"last-claim receipt is unreadable: {error}") from error

    _fetch(repo)
    branch = receipt.get("branch")
    worktree = receipt.get("worktree")
    stale_reasons: list[str] = []
    if worktree:
        worktree_path = Path(worktree)
        if not worktree_path.is_dir():
            stale_reasons.append("worktree path no longer exists locally")
        elif branch:
            actual_branch = git(worktree_path, "branch", "--show-current", check=False)
            if actual_branch != branch:
                stale_reasons.append(f"worktree is now on branch {actual_branch!r}, not {branch!r}")
    if branch:
        published = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo
        ).returncode == 0
        if not published:
            stale_reasons.append(f"remote {branch} no longer exists")

    freshness = "stale" if stale_reasons else "current"
    if as_json:
        output = dict(receipt)
        output["freshness"] = freshness
        output["freshness_reasons"] = stale_reasons
        print(json.dumps(output))
    else:
        print("LAST CLAIM")
        print(f"workstream: {receipt.get('workstream')}")
        print(f"branch: {branch}")
        print(f"worktree: {worktree}")
        print(f"packet: {receipt.get('packet')}")
        print(f"authoring chat: {receipt.get('authoring_chat', 'not-recorded')}")
        print(f"visual review: {receipt.get('visual_review', 'none')}")
        print(f"visual review root: {receipt.get('visual_review_root', '')}")
        print(f"checkout: {receipt.get('checkout')}")
        suffix = f" ({'; '.join(stale_reasons)})" if stale_reasons else ""
        print(f"freshness: {freshness}{suffix}")
        print("\nNEXT:")
        print(f"cd {worktree}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    subs.add_parser("status")
    p = subs.add_parser("audit"); p.add_argument("--json", action="store_true", dest="as_json")
    p = subs.add_parser("repair"); repair_mode = p.add_mutually_exclusive_group(required=True); repair_mode.add_argument("--plan", action="store_true"); repair_mode.add_argument("--apply", action="store_true"); p.add_argument("--archive-completed", action="store_true", help="also preview/apply legacy complete records with explicit non-empty Completed evidence"); p.add_argument("--json", action="store_true", dest="as_json")
    p = subs.add_parser("claim-next"); p.add_argument("--agent", default=None); p.add_argument("--lock-wait-seconds", type=float, default=0.0, help="bounded wait for the local assignment mutex (default: fail fast)")
    p = subs.add_parser("claim"); p.add_argument("workstream_id"); p.add_argument("--agent", default=None); p.add_argument("--lock-wait-seconds", type=float, default=0.0, help="bounded wait for the local assignment mutex (default: fail fast)")
    p = subs.add_parser("last-claim"); p.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args(argv)
    try:
        repo = Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        if args.command == "last-claim":
            return last_claim(repo, as_json=args.as_json)
        if args.command == "status":
            status(repo)
            return 0
        if args.command == "audit":
            return audit_command(repo, as_json=args.as_json)
        if args.command == "repair":
            import task_packet_repair
            try:
                actions = task_packet_repair.apply(repo) if args.apply else task_packet_repair.plan(repo)
                if args.archive_completed:
                    archive_actions = task_packet_repair.legacy_archive_apply(repo) if args.apply else task_packet_repair.legacy_archive_plan(repo)
                    actions.extend(archive_actions)
            except task_packet_repair.RepairError as error:
                print(f"dispatch: BLOCKED: {error}", file=sys.stderr)
                return 2
            if args.as_json:
                print(json.dumps({"schema": "custodian.task_packet_repair_plan.v1", "mode": "apply" if args.apply else "plan", "actions": actions}, indent=2, sort_keys=True))
            else:
                for item in actions:
                    label = "CHANGE" if item["changed"] == "true" else "NOOP"
                    print(f"{label} {item['workstream']} [{item['path']}]: {item['change']}")
                print(f"task_packet_repair: {'applied' if args.apply else 'plan only'}; {sum(item['changed'] == 'true' for item in actions)} file(s) changed")
            return 0
        agent = resolve_agent_id(args.agent)
        return claim(
            repo, getattr(args, "workstream_id", None), agent, args.command == "claim-next",
            lock_wait_seconds=args.lock_wait_seconds,
        )
    except (DispatchError, WorkflowControlError) as error:
        print(f"dispatch: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
