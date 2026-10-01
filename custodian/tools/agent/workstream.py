#!/usr/bin/env python3
"""Manage disposable CUSTODIAN agent workstreams and their safe landing lifecycle."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from contextlib import nullcontext
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import (
    RemoteClaim, RunTrace, WorkflowControlError, acquire_remote_claim,
    release_remote_claim, resolve_agent_id, workstream_mutex,
)
from task_packet_contract import (
    completion_truth_required, parse_completion_truth, parse_packet,
)

class WorkstreamError(RuntimeError):
    pass


ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
TASK_PACKET_ROOT = Path("custodian/docs/ai_context/task_packets")
TASK_PACKET_ARCHIVE = TASK_PACKET_ROOT / "archived"



def git(*args: str, cwd: Path | None = None, check: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and p.returncode:
        raise WorkstreamError(f"git {' '.join(args)} failed: {(p.stderr or p.stdout).strip()}")
    return p.stdout.strip()


def validate_id(value: str) -> str:
    if not ID_PATTERN.fullmatch(value):
        raise WorkstreamError("workstream ID must be lowercase kebab-case")
    return value


def root_repo(cwd: Path | None = None) -> Path:
    return Path(git("rev-parse", "--show-toplevel", cwd=cwd)).resolve()


def branch_for(workstream_id: str) -> str:
    return f"agent/{validate_id(workstream_id)}"


def worktree_records(repo: Path) -> list[dict[str, str]]:
    raw = git("worktree", "list", "--porcelain", cwd=repo)
    records: list[dict[str, str]] = []
    current: dict[str, str] = {}
    for line in raw.splitlines() + [""]:
        if not line:
            if current:
                records.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        current[key] = value
    return records


def status_clean(path: Path) -> bool:
    return not git("status", "--porcelain", "--untracked-files=all", cwd=path)


def _packet_status(text: str) -> str | None:
    for line in text.splitlines():
        match = re.match(r"^\s*-\s*Status:\s*`?([^`]*)`?\s*$", line, re.IGNORECASE)
        if match:
            return match.group(1).strip().lower()
    return None


def _packet_declares_workstream(text: str, workstream_id: str) -> bool:
    pattern = rf"^\s*-\s*Workstream:\s*`?{re.escape(workstream_id)}`?\s*$"
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


def _packet_filename_key(packet: Path) -> str:
    return packet.stem.lower().replace("_", "-")


def _active_packet_index_mentions(repo: Path, packet_name: str) -> bool:
    index = repo / TASK_PACKET_ROOT / "README.md"
    if not index.exists():
        return False
    active = False
    for line in index.read_text().splitlines():
        if line.startswith("## "):
            active = False
        if line.startswith("### "):
            heading = line[4:].strip().lower()
            active = heading in {"in progress", "recently complete (awaiting archive)"}
            continue
        if active and packet_name in line:
            return True
    return False


def _associated_task_packets(repo: Path, workstream_id: str) -> list[Path]:
    packets: list[Path] = []
    seen: set[Path] = set()
    expected_name = workstream_id.upper().replace("-", "_") + ".md"
    roots = (repo / TASK_PACKET_ROOT, repo / TASK_PACKET_ARCHIVE)
    for root in roots:
        if not root.exists():
            continue
        for packet in root.glob("*.md"):
            if packet.name == "README.md":
                continue
            try:
                text = packet.read_text()
            except OSError as exc:
                raise WorkstreamError(f"cannot inspect task packet {packet}: {exc}") from exc
            associated = (
                packet.name == expected_name
                or _packet_filename_key(packet) == workstream_id
                or _packet_declares_workstream(text, workstream_id)
            )
            if associated and packet not in seen:
                packets.append(packet)
                seen.add(packet)
    return packets


def _untracked_run_artifacts(path: Path) -> list[str]:
    raw = git("status", "--porcelain=v1", "-z", "--untracked-files=all", cwd=path)
    return [entry[3:] for entry in raw.split("\0") if entry.startswith("?? ")]


def _artifact_class(path: str) -> str:
    normalized = path.replace("\\", "/")
    name = Path(normalized).name
    if normalized.startswith("custodian/docs/ai_context/task_packets/"):
        return "task-packet"
    if name.endswith("_CLAUDE_SUMMARY.md"):
        return "closing-summary"
    if normalized.startswith("custodian/asset_drop/source_work/") or normalized.startswith("custodian/asset_drop/inbox/"):
        return "asset-v2-source"
    if normalized.startswith("reports/") or normalized.startswith("custodian/reports/"):
        return "review-evidence"
    if (
        "__pycache__/" in normalized
        or ".pytest_cache/" in normalized
        or name == ".DS_Store"
        or name.endswith((".pyc", ".tmp", ".log", ".cache"))
    ):
        return "disposable-candidate"
    return "unclassified"


def artifact_preflight(workstream_id: str, path: Path) -> list[Path]:
    """Fail closed before teardown when run artifacts are not durably resolved."""
    repo = root_repo(path)
    untracked = _untracked_run_artifacts(path)
    if untracked:
        details = ", ".join(f"{_artifact_class(item)}:{item}" for item in untracked[:12])
        if len(untracked) > 12:
            details += f", +{len(untracked) - 12} more"
        raise WorkstreamError(
            "finish artifact gate found untracked run artifacts; commit durable artifacts "
            f"or explicitly remove disposable ones before teardown: {details}"
        )

    packets = _associated_task_packets(repo, workstream_id)
    review_packet = next((packet for packet in packets if _packet_header_value(packet.read_text(), "Kind") == "review"), None)
    if review_packet and _packet_header_value(review_packet.read_text(), "Dispatch") == "auto":
        changed_paths = git("diff", "--name-only", "origin/main...HEAD", cwd=path).splitlines()
        target_packet_path = _packet_header_value(review_packet.read_text(), "Review target packet")
        if not target_packet_path or target_packet_path not in changed_paths:
            raise WorkstreamError("paired review artifact gate requires a committed change to the reviewed packet receipt")
        target_file = (path / target_packet_path).resolve()
        if not target_file.is_relative_to(path.resolve()) or not target_file.is_file():
            raise WorkstreamError("paired review artifact gate cannot resolve its archived review target packet")
        target_text = target_file.read_text()
        receipt = re.search(r"(?ms)^## Independent Review\s*\n(.*?)(?=^## |\Z)", target_text)
        receipt_status = re.search(r"(?m)^\s*-\s*Status:\s*`(passed|findings|human_required)`\s*$", receipt.group(1)) if receipt else None
        if not receipt_status:
            raise WorkstreamError("paired review artifact gate requires a completed Independent Review receipt")
        artifact_contents = {
            changed: (path / changed).read_text()
            for changed in changed_paths
            if changed.startswith("custodian/docs/ai_context/task_packets/") and (path / changed).is_file()
        }
        scope_error = paired_review_artifact_scope_error(
            workstream_id, review_packet, review_packet.read_text(), changed_paths,
            artifact_contents=artifact_contents,
        )
        if scope_error:
            raise WorkstreamError(scope_error)
    active_root = (repo / TASK_PACKET_ROOT).resolve()
    archive_root = (repo / TASK_PACKET_ARCHIVE).resolve()
    active_packets: list[tuple[Path, str | None]] = []
    archived_packets: list[tuple[Path, str | None]] = []
    for packet in packets:
        status = _packet_status(packet.read_text())
        parent = packet.parent.resolve()
        if parent == active_root:
            active_packets.append((packet, status))
        elif parent == archive_root:
            archived_packets.append((packet, status))

    if active_packets:
        rendered = ", ".join(
            f"{packet.relative_to(repo)} (status={status or 'missing'})"
            for packet, status in active_packets
        )
        raise WorkstreamError(
            "finish artifact gate requires associated task packets to be complete and moved "
            f"to task_packets/archived before teardown: {rendered}"
        )

    incomplete = [
        (packet, status)
        for packet, status in archived_packets
        if status is None or not status.startswith("complete")
    ]
    if incomplete:
        rendered = ", ".join(
            f"{packet.relative_to(repo)} (status={status or 'missing'})"
            for packet, status in incomplete
        )
        raise WorkstreamError(f"archived task packet is not complete: {rendered}")

    stale_index = [
        packet for packet, _ in archived_packets
        if _active_packet_index_mentions(repo, packet.name)
    ]
    if stale_index:
        rendered = ", ".join(str(packet.relative_to(repo)) for packet in stale_index)
        raise WorkstreamError(
            "archived task packet is still listed as active/recently-complete in "
            f"task_packets/README.md: {rendered}"
        )
    return packets


def _completion_truth_preflight(packets: list[Path]) -> None:
    """Fail closed before teardown when a current V2 implementation/correction
    packet claims Status: complete without a truthful ## Completion Truth
    receipt. Review packets verify someone else's claim rather than making
    one, and legacy (non-V2) packets are never retroactively covered; both
    are exempted by task_packet_contract.completion_truth_required. Called
    again (with freshly re-read packet text) after main sync so a packet
    whose bytes changed during landing is re-checked rather than trusted
    from before the sync.
    """
    for packet in packets:
        text = packet.read_text()
        header = parse_packet(str(packet), text)
        if not completion_truth_required(header):
            continue
        truth = parse_completion_truth(text)
        if truth is None:
            raise WorkstreamError(
                f"finish completion-truth gate requires a ## Completion Truth receipt in {packet.name}"
            )
        if truth.error:
            raise WorkstreamError(
                f"finish completion-truth gate found a malformed ## Completion Truth receipt in {packet.name}: {truth.error}"
            )
        if not truth.all_yes:
            raise WorkstreamError(
                "finish completion-truth gate requires Goal satisfied, Completion boundary satisfied, "
                f"and Acceptance satisfied to all be yes in {packet.name}"
            )


def _packet_header_value(text: str, field: str) -> str | None:
    for line in text.splitlines():
        match = re.match(rf"^\s*-\s*{re.escape(field)}:\s*(.*?)\s*$", line)
        if match:
            return match.group(1).strip().strip("`").strip()
        if line.startswith("## "):
            break
    return None


def paired_review_artifact_scope_error(
    workstream_id: str, packet: Path, packet_text: str, changed_paths: list[str],
    artifact_contents: dict[str, str] | None = None,
) -> str | None:
    """Enforce the bounded file surface authorized by an auto paired-review packet."""
    if _packet_header_value(packet_text, "Kind") != "review":
        return None
    target_workstream = _packet_header_value(packet_text, "Review target workstream")
    target_packet = _packet_header_value(packet_text, "Review target packet")
    if not target_workstream or not target_packet:
        return f"paired review artifact gate requires Review target workstream/packet for {workstream_id}"

    summary = _expected_summary_filename(workstream_id)
    allowed = {
        target_packet,
        f"custodian/docs/ai_context/task_packets/{packet.name}",
        f"custodian/docs/ai_context/task_packets/archived/{packet.name}",
        "custodian/docs/ai_context/task_packets/README.md",
        summary,
    }
    correction_id = re.compile(rf"^{re.escape(target_workstream)}-review-corrections-[1-9][0-9]*$")
    paired_review_id = re.compile(rf"^review-{re.escape(target_workstream)}-review-corrections-[1-9][0-9]*$")
    correction_workstreams: set[str] = set()
    paired_review_workstreams: set[str] = set()
    artifact_contents = artifact_contents or {}
    for path in changed_paths:
        normalized = path.replace("\\", "/")
        if normalized in allowed:
            continue
        if not normalized.startswith("custodian/docs/ai_context/task_packets/"):
            return f"paired review artifact gate rejects unauthorized change: {normalized}"
        if Path(normalized).parent.as_posix() != "custodian/docs/ai_context/task_packets":
            return f"paired review artifact gate rejects unauthorized change: {normalized}"
        stem = Path(normalized).stem
        workstream = stem.lower().replace("_", "-")
        is_correction = correction_id.fullmatch(workstream)
        is_paired_review = paired_review_id.fullmatch(workstream)
        if not (is_correction or is_paired_review):
            return f"paired review artifact gate rejects unauthorized change: {normalized}"
        if is_correction:
            correction_workstreams.add(workstream)
            content = artifact_contents.get(normalized, "")
            findings = re.search(r"(?m)^\s*-\s*Findings addressed:\s*`?([^`\n]+)", content)
            ids = [item.strip() for item in findings.group(1).split(",")] if findings else []
            if not ids or any(not re.fullmatch(r"R(?:0|[1-9][0-9]*)-(?:0[1-9]|[1-9][0-9]*)", item) for item in ids):
                return f"paired review artifact gate requires stable Findings addressed IDs in {normalized}"
        else:
            paired_review_workstreams.add(workstream.removeprefix("review-"))
    if correction_workstreams != paired_review_workstreams:
        return "paired review artifact gate requires each correction packet to have its paired re-review packet"
    return None


def fetch(repo: Path) -> None:
    git("fetch", "--prune", "origin", cwd=repo)
    git("worktree", "prune", cwd=repo)


def tracking_branch(repo: Path, branch: str) -> None:
    git("branch", "--set-upstream-to", f"origin/{branch}", branch, cwd=repo)


def sync_main(path: Path) -> bool:
    """Merge latest origin/main into a published workstream without rewriting it."""
    head = git("rev-parse", "HEAD", cwd=path)
    main = git("rev-parse", "origin/main", cwd=path)
    ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", main, head], cwd=path)
    if ancestor.returncode == 0:
        return False
    if ancestor.returncode != 1:
        raise WorkstreamError("could not compare workstream with origin/main")
    # If workstream is behind and has no unique commits, this is a fast-forward.
    unique = git("rev-list", "origin/main..HEAD", cwd=path).splitlines()
    if not unique:
        git("merge", "--ff-only", "origin/main", cwd=path)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", "origin/main"], cwd=path, text=True, capture_output=True)
        if merge.returncode:
            raise WorkstreamError("origin/main merge conflicted; resolve in the preserved worktree")
    return True


def sync_remote_branch(path: Path, branch: str) -> bool:
    remote = f"origin/{branch}"
    head = git("rev-parse", "HEAD", cwd=path)
    remote_head = git("rev-parse", remote, cwd=path)
    if subprocess.run(["git", "merge-base", "--is-ancestor", remote_head, head], cwd=path).returncode == 0:
        return False
    if subprocess.run(["git", "merge-base", "--is-ancestor", head, remote_head], cwd=path).returncode == 0:
        git("merge", "--ff-only", remote, cwd=path)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", remote], cwd=path, text=True, capture_output=True)
        if merge.returncode:
            raise WorkstreamError("local and remote workstream histories diverged; merge conflicted and worktree was preserved")
    return True


def start(workstream_id: str, repo: Path | None = None, *, report: dict[str, str] | None = None,
          agent: str | None = None, _claim: RemoteClaim | None = None, _trace: RunTrace | None = None,
          _lock_held: bool = False) -> Path:
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    trace = _trace
    lock_started = time.monotonic()
    lock_context = nullcontext() if _lock_held else workstream_mutex(repo, workstream_id)
    claim = _claim
    try:
        with lock_context:
            if trace is None:
                trace = RunTrace.start(repo, workstream_id)
            trace.record("mutex_acquired", scope="workstream", wait_ms=round((time.monotonic() - lock_started) * 1000))
            before = worktree_records(repo)
            trace.record("start_inspection", main_sha=git("rev-parse", "origin/main", cwd=repo, check=False), worktrees=before)
            fetch(repo)
            trace.record("remote_fetched", main_sha=git("rev-parse", "origin/main", cwd=repo), branch_ref=branch,
                         remote_branch_present=subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo).returncode == 0)
            records = worktree_records(repo)
            attached = [r for r in records if r.get("branch") == f"refs/heads/{branch}"]
            remote_exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo).returncode == 0
            local_exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], cwd=repo).returncode == 0
            if remote_exists or attached or local_exists:
                location = attached[0].get("worktree") if attached else "not attached"
                if attached and not status_clean(Path(location)):
                    raise WorkstreamError(f"branch is attached to a dirty worktree; preserved at {location}; use explicit resume after inspecting it")
                if attached and not remote_exists:
                    unique = git("rev-list", "origin/main..HEAD", cwd=Path(location)).splitlines()
                    if unique:
                        raise WorkstreamError(f"local-only attached worktree for {branch} has unique commits; explicit recovery required at {location}")
                raise WorkstreamError(f"{branch} already exists or is attached ({location}); use explicit workstream.py resume after inspecting ownership; ordinary start will not adopt it")
            if claim is None:
                claim = acquire_remote_claim(repo, workstream_id, resolve_agent_id(agent), trace.run_id, trace=trace)
            else:
                trace.record("remote_claim_reused", remote_ref=claim.ref, claim_oid=claim.oid)
            pool = repo.parent / ".custodian-worktrees"
            pool.mkdir(parents=True, exist_ok=True)
            path = pool / f"{workstream_id}-{trace.run_id}"
            trace.record("worktree_create_begin", worktree=str(path), branch=branch, main_sha=git("rev-parse", "origin/main", cwd=repo))
            git("worktree", "add", "-b", branch, str(path), "origin/main", cwd=repo)
            git("push", "-u", "origin", branch, cwd=path)
            fetch(repo)
            if not path.is_dir() or git("branch", "--show-current", cwd=path) != branch or subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo).returncode != 0:
                raise WorkstreamError(f"workstream post-create verification failed; recovery claim retained at origin/{claim.ref}")
            trace.record("worktree_published", worktree=str(path), branch=branch, head=git("rev-parse", "HEAD", cwd=path), upstream=git("rev-parse", f"origin/{branch}", cwd=path), clean=status_clean(path))
            trace.record("worktree_after", worktrees=worktree_records(repo))
            if _lock_held:
                trace.record("agent_branch_published_claim_held", remote_ref=claim.ref)
            elif not release_remote_claim(repo, claim, trace=trace):
                trace.record("claim_cleanup_pending", remote_ref=claim.ref)
            if report is not None:
                report["checkout"] = "created"
            trace.record("start_completed", disposition="created", worktree=str(path), branch=branch)
            trace.publish()
            receipt = {"schema": "custodian.dispatch.claim.v1", "result": "started", "workstream": workstream_id,
                       "branch": branch, "worktree": str(path), "verified": True, "run_id": trace.run_id,
                       "trace_ref": trace.diagnostic_ref}
            if not _lock_held:
                print("CUSTODIAN_DISPATCH_RESULT_JSON:" + json.dumps(receipt, sort_keys=True))
            return path
    except (WorkstreamError, WorkflowControlError) as exc:
        if trace is None:
            trace = RunTrace.start(repo, workstream_id)
        trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def _resume_impl(workstream_id: str, repo: Path, report: dict[str, str] | None, trace: RunTrace) -> Path:
    """Explicitly resume an existing clean canonical workstream checkout."""
    with workstream_mutex(repo, workstream_id, trace=trace):
        fetch(repo)
        branch = branch_for(workstream_id)
        attached = [r for r in worktree_records(repo) if r.get("branch") == f"refs/heads/{branch}"]
        remote_exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo).returncode == 0
        if attached:
            path = Path(attached[0]["worktree"]).resolve()
            if path == repo or not status_clean(path):
                raise WorkstreamError(f"resume requires a clean non-coordination checkout; preserved at {path} [run_id={trace.run_id}]")
            fetch(path)
            if remote_exists:
                sync_remote_branch(path, branch)
            sync_main(path)
            trace.record("worktree_resumed", worktree=str(path), branch=branch, head=git("rev-parse", "HEAD", cwd=path))
            if report is not None: report["checkout"] = "resumed"
            trace.publish()
            return path
        if not remote_exists:
            raise WorkstreamError(f"resume found no attached checkout or origin/{branch}; inspect recovery state [run_id={trace.run_id}]")
        pool = repo.parent / ".custodian-worktrees"
        pool.mkdir(parents=True, exist_ok=True)
        path = pool / f"{workstream_id}-{trace.run_id}"
        git("worktree", "add", "--track", "-b", branch, str(path), f"origin/{branch}", cwd=repo)
        sync_main(path)
        git("push", "origin", branch, cwd=path)
        trace.record("worktree_resumed", worktree=str(path), branch=branch, head=git("rev-parse", "HEAD", cwd=path))
        if report is not None: report["checkout"] = "resumed"
        trace.publish()
        return path


def resume(workstream_id: str, repo: Path | None = None, *, report: dict[str, str] | None = None) -> Path:
    repo = (repo or root_repo()).resolve()
    trace = RunTrace.resume(repo, workstream_id)
    try:
        return _resume_impl(workstream_id, repo, report, trace)
    except Exception as exc:
        trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def validation_green(report: Path) -> bool:
    try:
        data = json.loads(report.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkstreamError(f"cannot read validation report {report}: {exc}") from exc
    if data.get("schema") != "custodian.validation.result.v1" or not data.get("passed", False):
        return False
    tests = data.get("tests", [])
    return bool(tests) and all(isinstance(test, dict) and test.get("status") == "passed" for test in tests)


def find_worktree(repo: Path, branch: str) -> Path:
    for item in worktree_records(repo):
        if item.get("branch") == f"refs/heads/{branch}":
            return Path(item["worktree"]).resolve()
    raise WorkstreamError(f"no attached worktree found for {branch}")


def administrative_worktree(repo: Path, excluded: Path) -> Path:
    candidates = [
        (Path(item["worktree"]).resolve(), item.get("branch", ""))
        for item in worktree_records(repo)
        if Path(item["worktree"]).resolve() != excluded
        and Path(item["worktree"]).resolve().is_dir()
    ]
    main = next((path for path, branch in candidates if branch == "refs/heads/main"), None)
    if main is not None:
        return main
    if candidates:
        return candidates[0][0]
    raise WorkstreamError("cannot find a surviving worktree for safe task teardown")


def _checkpoint_impl(workstream_id: str, remove_worktree: bool, repo: Path, trace: RunTrace) -> None:
    trace.record("checkpoint_started", remove_worktree=remove_worktree)
    branch = branch_for(workstream_id)
    path = find_worktree(repo, branch)
    if git("branch", "--show-current", cwd=path) != branch:
        raise WorkstreamError("worktree is not on the requested workstream branch")
    git("push", "-u", "origin", branch, cwd=path)
    fetch(repo)
    local = git("rev-parse", "HEAD", cwd=path)
    remote = git("rev-parse", f"origin/{branch}", cwd=repo)
    if local != remote:
        raise WorkstreamError("remote checkpoint verification failed; worktree retained")
    if remove_worktree:
        if not status_clean(path):
            raise WorkstreamError("cannot remove a dirty checkpoint worktree; dirty work is preserved")
        git("worktree", "remove", str(path), cwd=repo)
    trace.record("checkpoint_completed", branch=branch, remote_head=remote, removed=remove_worktree)
    trace.publish()
    print(f"checkpoint retained: origin/{branch} at {remote}; workstream remains active")


def checkpoint(workstream_id: str, remove_worktree: bool = False, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    trace = RunTrace.resume(repo, workstream_id)
    try:
        _checkpoint_impl(workstream_id, remove_worktree, repo, trace)
    except Exception as exc:
        trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def _expected_summary_filename(workstream_id: str) -> str:
    return f"{workstream_id.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"


def _alternate_summary_filenames(repo: Path, workstream_id: str) -> list[str]:
    """Explicitly documented alternate summary names from the associated packet body.

    Covers a legitimate summary name that does not exactly match the workstream-ID
    transform, without weakening the default: the packet itself must spell it out.
    """
    names: list[str] = []
    for packet in _associated_task_packets(repo, workstream_id):
        for match in re.finditer(r"\b([A-Z0-9]+(?:_[A-Z0-9]+)*_CLAUDE_SUMMARY\.md)\b", packet.read_text()):
            if match.group(1) not in names:
                names.append(match.group(1))
    return names


def closing_summary_committed_for_workstream(workstream_id: str, path: Path) -> str:
    """Prove a closing summary is durably committed at HEAD.

    Independent of any diff against ``origin/main``: that diff goes empty once
    HEAD is already an ancestor of ``origin/main`` (the merge-base becomes HEAD
    itself), which previously made an already-landed task's real, committed
    summary look missing. Returns the proven filename, or raises.
    """
    repo = root_repo(path)
    candidates = [_expected_summary_filename(workstream_id)]
    candidates += [name for name in _alternate_summary_filenames(repo, workstream_id) if name not in candidates]
    for name in candidates:
        if subprocess.run(["git", "cat-file", "-e", f"HEAD:{name}"], cwd=path).returncode == 0:
            return name
    raise WorkstreamError(
        "required task closing summary is not committed at HEAD; expected one of: "
        + ", ".join(candidates)
    )


def task_head_reachable_from_main(path: Path, remote_ref: str = "origin/main") -> bool:
    return subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", remote_ref], cwd=path).returncode == 0


def _teardown_workstream(workstream_id: str, branch: str, repo: Path, path: Path, head: str) -> None:
    admin_repo = administrative_worktree(repo, path)
    # Tolerate a remote branch already deleted by an earlier, interrupted finish
    # attempt; any other push failure is a real blocker, not idempotence.
    delete = subprocess.run(["git", "push", "origin", "--delete", branch], cwd=path, text=True, capture_output=True)
    if delete.returncode and "remote ref does not exist" not in (delete.stderr or ""):
        raise WorkstreamError(f"failed to delete remote branch {branch}: {(delete.stderr or delete.stdout).strip()}")
    git("worktree", "remove", str(path), cwd=admin_repo)
    # The local main branch may intentionally lag origin/main in the coordination
    # checkout. Reachability was proven by the caller against freshly fetched origin/main.
    git("branch", "-D", branch, cwd=admin_repo)
    git("worktree", "prune", cwd=admin_repo)
    git("fetch", "--prune", "origin", cwd=admin_repo)

    # Root checkout sync is subordinate and never alters user state.
    for item in worktree_records(admin_repo):
        root_path = Path(item["worktree"]).resolve()
        if root_path == path:
            continue
        if git("branch", "--show-current", cwd=root_path, check=False) != "main":
            continue
        if status_clean(root_path):
            git("pull", "--ff-only", "origin", "main", cwd=root_path)
            print(f"persistent main checkout synchronized: {root_path}")
        else:
            print(f"persistent root synchronization pending (dirty): {root_path}")
        break
    print(f"finished {branch}; verified {head} reachable from origin/main; remote and local workstream removed")


def _finish_without_attached_worktree(workstream_id: str, branch: str, repo: Path, trace: RunTrace | None = None) -> None:
    """No attached worktree for this workstream: either genuinely already
    finished (report success, do not encourage recreating anything) or an
    unverifiable/bogus state (fail closed for investigation)."""
    remote_exists = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{branch}"], cwd=repo
    ).returncode == 0
    if remote_exists:
        raise WorkstreamError(
            f"no attached worktree found for {branch}, but its remote branch still exists; "
            "recovery required rather than recreating the worktree"
        )
    summary_names = [_expected_summary_filename(workstream_id)] + _alternate_summary_filenames(repo, workstream_id)
    summary_landed = any(
        subprocess.run(["git", "cat-file", "-e", f"origin/main:{name}"], cwd=repo).returncode == 0
        for name in summary_names
    )
    if summary_landed:
        if trace:
            trace.record("finish_already_completed", branch=branch)
            trace.publish()
        print(
            f"already finished: no attached worktree or remote branch for {branch}; "
            "its closing summary is present on origin/main"
        )
        return
    raise WorkstreamError(
        f"no attached worktree or remote branch found for {branch}, and no closing summary is "
        "present on origin/main to confirm it already finished; investigate before recreating anything"
    )


def _finish_impl(workstream_id: str, validation_report: Path, validation_report_after_sync: Path | None = None, repo: Path | None = None, trace: RunTrace | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    fetch(repo)
    try:
        path = find_worktree(repo, branch)
    except WorkstreamError:
        _finish_without_attached_worktree(workstream_id, branch, repo, trace)
        return
    if git("branch", "--show-current", cwd=path) != branch:
        raise WorkstreamError("finish must run for its matching agent/<workstream-id> branch")

    # PREPARED: artifacts, cleanliness, a durably committed summary, and green
    # validation are required regardless of whether this task already landed.
    packets = artifact_preflight(workstream_id, path)
    if trace: trace.record("artifact_preflight", result="passed", worktree=str(path))
    _completion_truth_preflight(packets)
    if trace: trace.record("completion_truth_preflight", result="passed", worktree=str(path))
    if not status_clean(path):
        raise WorkstreamError("finish requires a clean worktree and committed task files")
    closing_summary_committed_for_workstream(workstream_id, path)
    if not validation_green(validation_report):
        raise WorkstreamError("focused validation report is not green")
    if trace:
        import hashlib
        trace.record("validation_report", path=validation_report.name, sha256=hashlib.sha256(validation_report.read_bytes()).hexdigest(), passed=True)

    git("push", "-u", "origin", branch, cwd=path)
    fetch(path)

    if task_head_reachable_from_main(path):
        # ALREADY_LANDED: this exact task history is already on origin/main (a
        # prior finish attempt landed it but did not finish teardown, or it
        # merged in some other way). Skip sync/land entirely and go straight
        # to verified teardown; do not rewrite or remerge task history.
        head = git("rev-parse", "HEAD", cwd=path)
        if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
        _teardown_workstream(workstream_id, branch, repo, path, head)
        if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())
        return

    # SYNC_REQUIRED -> READY_TO_LAND
    changed = sync_main(path)
    if trace: trace.record("main_sync", changed=changed, head=git("rev-parse", "HEAD", cwd=path), main_sha=git("rev-parse", "origin/main", cwd=path))
    if changed:
        if validation_report_after_sync is None or not validation_green(validation_report_after_sync):
            raise WorkstreamError("main synchronization changed the tree; provide a green --validation-report-after-sync; recovery state retained")
        if trace:
            import hashlib
            trace.record("validation_after_sync", path=validation_report_after_sync.name,
                         sha256=hashlib.sha256(validation_report_after_sync.read_bytes()).hexdigest(), passed=True)
    packets = artifact_preflight(workstream_id, path)
    _completion_truth_preflight(packets)
    if not status_clean(path):
        raise WorkstreamError("main synchronization left the worktree dirty; recovery state retained")
    git("push", "origin", branch, cwd=path)

    if task_head_reachable_from_main(path):
        # Synchronization itself (a fast-forward merge, or a concurrent landing
        # of this exact history) already made HEAD reachable from main.
        head = git("rev-parse", "HEAD", cwd=path)
        if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
        _teardown_workstream(workstream_id, branch, repo, path, head)
        if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())
        return

    # LANDED: hand off to the sole active landing authority. Never duplicate
    # its serialized rebase/push logic here.
    landing_env = os.environ.copy()
    landing_env["CUSTODIAN_WORKSTREAM_FINISH"] = "1"
    landed = subprocess.run(
        [sys.executable, str(Path(__file__).with_name("land_main.py"))],
        cwd=path,
        env=landing_env,
        text=True,
        capture_output=True,
    )
    if landed.returncode:
        raise WorkstreamError(f"land_main blocked; workstream preserved: {(landed.stderr or landed.stdout).strip()}")
    fetch(path)
    head = git("rev-parse", "HEAD", cwd=path)
    if not task_head_reachable_from_main(path):
        raise WorkstreamError("landing did not verify as reachable from origin/main; recovery branch retained")

    # READY_TO_TEARDOWN -> FINISHED
    if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
    _teardown_workstream(workstream_id, branch, repo, path, head)
    if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())


def finish(workstream_id: str, validation_report: Path, validation_report_after_sync: Path | None = None, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    trace = RunTrace.resume(repo, workstream_id)
    trace.record("finish_started", validation_report=str(validation_report), after_sync_report=str(validation_report_after_sync) if validation_report_after_sync else None)
    try:
        _finish_impl(workstream_id, validation_report, validation_report_after_sync, repo, trace)
        trace.record("finish_completed", outcome="finished")
        trace.complete("finished", clear_active=True)
    except Exception as exc:
        trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def status(workstream_id: str | None = None, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    for item in worktree_records(repo):
        branch = item.get("branch", "detached")
        if workstream_id and branch != f"refs/heads/{branch_for(workstream_id)}":
            continue
        path = Path(item["worktree"])
        print(f"{branch}\t{'clean' if status_clean(path) else 'dirty'}\t{path}")
    if workstream_id:
        branch = branch_for(workstream_id)
        print(f"remote {branch}: {'present' if subprocess.run(['git','show-ref','--verify','--quiet',f'refs/remotes/origin/{branch}'],cwd=repo).returncode == 0 else 'absent'}")


def gc(repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    script = Path(__file__).with_name("branch_hygiene.py")
    subprocess.run([sys.executable, str(script)], cwd=repo, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    p = subs.add_parser("start"); p.add_argument("workstream_id"); p.add_argument("--agent", default=None)
    p = subs.add_parser("resume"); p.add_argument("workstream_id")
    p = subs.add_parser("status"); p.add_argument("workstream_id", nargs="?")
    p = subs.add_parser("checkpoint"); p.add_argument("workstream_id"); p.add_argument("--remove-worktree", action="store_true")
    p = subs.add_parser("finish"); p.add_argument("workstream_id"); p.add_argument("--validation-report", type=Path, required=True); p.add_argument("--validation-report-after-sync", type=Path)
    subs.add_parser("gc")
    args = parser.parse_args()
    try:
        if args.command == "start": start(args.workstream_id, agent=args.agent)
        elif args.command == "resume": print(f"resumed worktree: {resume(args.workstream_id)}")
        elif args.command == "status": status(args.workstream_id)
        elif args.command == "checkpoint": checkpoint(args.workstream_id, args.remove_worktree)
        elif args.command == "finish": finish(args.workstream_id, args.validation_report, args.validation_report_after_sync)
        else: gc()
        return 0
    except WorkstreamError as error:
        print(f"workstream: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
