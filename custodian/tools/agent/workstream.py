#!/usr/bin/env python3
"""Manage disposable CUSTODIAN agent workstreams and their safe landing lifecycle."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
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
from persistent_checkout_sync import ROOT_PROFILE, apply_profiles, format_result
from task_packet_contract import (
    completion_truth_required, parse_completion_truth, parse_packet,
)
from review_receipt_delta import read_git_text, resolve_target_implementation_commit, verify_review_receipt_delta
import review_outcome

class WorkstreamError(RuntimeError):
    pass


ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
TASK_PACKET_ROOT = Path("custodian/docs/ai_context/task_packets")
TASK_PACKET_ARCHIVE = TASK_PACKET_ROOT / "archived"
ROOT_SYNC_DEFERRAL_SUPPORT = frozenset({
    "agent-paired-review-invalid-disposition-recovery-v1",
    "review-agent-paired-review-invalid-disposition-recovery-v1",
})
INVALID_DISPOSITION_REVIEW = "review-agent-paired-review-prevalidation-recovery-plan-v1"
INVALID_DISPOSITION_RUN_ID = "20261019T055243Z-1d73c6a01b1e"
INVALID_DISPOSITION_SHA256 = "6e6cc2d61796684baf23d5b74c7f1fc08091c13f509a8c00ceeb85f0d2933779"
INVALID_DISPOSITION_TARGET_PACKET = (
    "custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md"
)
INVALID_DISPOSITION_REVIEW_PACKET = (
    "custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md"
)
ADVANCED_HEAD_PASS_REVIEW = "review-agent-paired-review-exact-claim-parking-v1"



def git(*args: str, cwd: Path | None = None, check: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and p.returncode:
        raise WorkstreamError(f"git {' '.join(args)} failed: {(p.stderr or p.stdout).strip()}")
    return p.stdout.strip()


def validate_id(value: str) -> str:
    if not ID_PATTERN.fullmatch(value):
        raise WorkstreamError("workstream ID must be lowercase kebab-case")
    return value


def assert_not_legacy_quarantined(repo: Path, workstream_id: str, action: str) -> None:
    """Fence normal lifecycle actions for an administratively quarantined claim."""
    try:
        import legacy_claim_quarantine
        state = legacy_claim_quarantine.local_quarantine_state(repo, workstream_id)
    except Exception as exc:
        raise WorkstreamError(f"quarantine authority could not be verified; {action} is fenced: {exc}") from exc
    if state.get("state") == "legacy_quarantined" or state.get("record_sha"):
        raise WorkstreamError(
            f"{workstream_id} is legacy_quarantined; original claim and worktree are preserved, "
            f"automatic {action} is prohibited (record {state.get('record_sha') or 'invalid'})"
        )


def _is_quarantine_fence_error(error: BaseException) -> bool:
    message = str(error)
    return "is legacy_quarantined" in message or "quarantine authority could not be verified" in message


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


def _mount_table(path: Path = Path("/proc/self/mountinfo")) -> list[dict[str, str]]:
    """Read Linux mountinfo without shelling out or changing host state."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    mounts = []
    for line in lines:
        before, separator, after = line.partition(" - ")
        fields, filesystem = before.split(), after.split()
        if not separator or len(fields) < 5 or not filesystem:
            continue
        mountpoint = re.sub(r"\\([0-7]{3})", lambda match: chr(int(match.group(1), 8)), fields[4])
        mounts.append({"mount": mountpoint, "fstype": filesystem[0]})
    return mounts


def _filesystem_for(path: Path, mounts: list[dict[str, str]]) -> dict[str, str] | None:
    resolved = path.resolve()
    matches = []
    for mount in mounts:
        mountpoint = Path(mount["mount"]).resolve()
        try:
            resolved.relative_to(mountpoint)
        except ValueError:
            continue
        matches.append((len(mountpoint.parts), mount))
    return max(matches, default=(0, None), key=lambda item: item[0])[1]


def storage_report(
    repo: Path,
    *,
    records: list[dict[str, str]] | None = None,
    mounts: list[dict[str, str]] | None = None,
) -> dict[str, object]:
    """Describe RAM-backed scratch/worktrees and protected worktree state; never delete."""
    tools_dir = Path(__file__).resolve().parents[1]
    if str(tools_dir) not in sys.path and (tools_dir / "godot_project_lock.py").is_file():
        sys.path.insert(0, str(tools_dir))
    from godot_project_lock import scratch_root

    mount_entries = _mount_table() if mounts is None else mounts
    scratch = scratch_root(create=False)
    scratch_mount = _filesystem_for(scratch, mount_entries)
    usage_path = scratch
    while not usage_path.exists() and usage_path != usage_path.parent:
        usage_path = usage_path.parent
    scratch_stats = shutil.disk_usage(usage_path)
    scratch_record = {
        "path": str(scratch),
        "fstype": scratch_mount["fstype"] if scratch_mount else "unknown",
        "mount": scratch_mount["mount"] if scratch_mount else "unknown",
        "total_bytes": scratch_stats.total,
        "used_bytes": scratch_stats.used,
        "free_bytes": scratch_stats.free,
        "ram_backed": bool(scratch_mount and scratch_mount["fstype"] in {"tmpfs", "ramfs"}),
    }
    protected = []
    for record in records if records is not None else worktree_records(repo):
        path = Path(record.get("worktree", ""))
        mount = _filesystem_for(path, mount_entries)
        if not mount or mount["fstype"] not in {"tmpfs", "ramfs"}:
            continue
        branch = record.get("branch", "detached")
        dirty = path.exists() and not status_clean(path)
        upstream = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
            cwd=path if path.exists() else repo, capture_output=True, text=True, check=False,
        )
        ahead = None
        unpushed = upstream.returncode != 0
        if upstream.returncode == 0:
            counts = subprocess.run(
                ["git", "rev-list", "--left-right", "--count", f"{upstream.stdout.strip()}...HEAD"],
                cwd=path if path.exists() else repo, capture_output=True, text=True, check=False,
            )
            if counts.returncode == 0:
                parts = counts.stdout.split()
                ahead = int(parts[1]) if len(parts) == 2 else None
                unpushed = ahead is None or ahead > 0
        reasons = ["registered worktree"]
        if branch.startswith("refs/heads/agent/"):
            reasons.append("claimed workstream")
            workstream_id = branch.removeprefix("refs/heads/agent/")
            if any(
                _packet_status(packet.read_text()) == "blocked"
                for packet in _associated_task_packets(repo, workstream_id)
                if packet.parent == repo / TASK_PACKET_ROOT
            ):
                reasons.append("blocked packet")
        if dirty:
            reasons.append("dirty")
        if unpushed:
            reasons.append("unpushed or no upstream")
        protected.append({
            "path": str(path), "branch": branch, "mount": mount["mount"],
            "fstype": mount["fstype"], "dirty": dirty, "ahead": ahead,
            "unpushed": unpushed, "protected": True, "protected_reasons": reasons,
        })
    return {
        "scratch": scratch_record,
        "ram_backed_worktrees": protected,
        "deletions_performed": 0,
    }


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


def _paired_review_artifact_preflight_error(workstream_id: str, path: Path, review_packet: Path) -> str | None:
    packet_text = review_packet.read_text()
    if _packet_header_value(packet_text, "Kind") != "review" or _packet_header_value(packet_text, "Dispatch") != "auto":
        return None
    has_main = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", "refs/remotes/origin/main"], cwd=path,
    ).returncode == 0
    if not has_main:
        return "paired review artifact gate cannot inspect changed paths because cached origin/main is missing"
    outcome, outcome_error = review_outcome.parse_review_outcome(packet_text)
    if outcome_error:
        return f"paired review artifact gate rejects the Review Outcome: {outcome_error}"
    if outcome is not None and outcome["Outcome"] in review_outcome.NONPASSING:
        return _nonpassing_review_artifact_error(workstream_id, path, review_packet, packet_text, outcome)
    try:
        changed_paths = git("diff", "--name-only", "origin/main...HEAD", cwd=path).splitlines()
    except WorkstreamError as exc:
        return f"paired review artifact gate cannot inspect changed paths: {exc}"
    target_packet_path = _packet_header_value(packet_text, "Review target packet")
    if not target_packet_path or target_packet_path not in changed_paths:
        return "paired review artifact gate requires a committed change to the reviewed packet receipt"
    target_file = (path / target_packet_path).resolve()
    if not target_file.is_relative_to(path.resolve()) or not target_file.is_file():
        return "paired review artifact gate cannot resolve its archived review target packet"
    try:
        target_text = target_file.read_bytes().decode("utf-8")
    except (OSError, UnicodeDecodeError):
        return "paired review artifact gate cannot read the reviewed packet as exact UTF-8 bytes"
    receipt = re.search(r"(?ms)^## Independent Review\s*\n(.*?)(?=^## |\Z)", target_text)
    receipt_status = re.search(r"(?m)^\s*-\s*Status:\s*`(passed|findings|human_required)`\s*$", receipt.group(1)) if receipt else None
    if not receipt_status:
        return "paired review artifact gate requires a completed Independent Review receipt"
    receipt_heading = f"### Review Receipt: {workstream_id}"
    if target_text.count(receipt_heading) != 1:
        return "paired review artifact gate requires exactly one receipt for this review workstream"
    receipt_match = re.search(
        rf"(?ms)^## Independent Review\s*\n.*?^{re.escape(receipt_heading)}\s*\n(.*?)(?=^### |^## |\Z)",
        target_text,
    )
    reviewed_main_match = re.search(r"(?m)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$",
                                    receipt_match.group(1) if receipt_match else "")
    if not reviewed_main_match:
        return "paired review artifact gate requires the receipt's full pinned Reviewed main SHA"
    reviewed_main = reviewed_main_match.group(1)
    try:
        baseline_target = read_git_text(path, reviewed_main, target_packet_path)
    except ValueError:
        return "paired review artifact gate cannot load the receipt's pinned target baseline"
    target_commit, identity_error = resolve_target_implementation_commit(
        path, reviewed_main, target_packet_path,
        _packet_header_value(packet_text, "Review target workstream") or "", baseline_target,
    )
    if identity_error:
        return f"paired review artifact gate cannot identify the pinned implementation: {identity_error}"
    receipt_data, delta_error = verify_review_receipt_delta(
        baseline_target, target_text, review_workstream=workstream_id,
        target_workstream=_packet_header_value(packet_text, "Review target workstream") or "",
        reviewed_main=reviewed_main,
        target_implementation_commit=target_commit,
    )
    if delta_error:
        return f"paired review artifact gate rejects reviewed packet receipt delta: {delta_error}"
    reviewed_commit = receipt_data["Reviewed implementation commit"]
    if subprocess.run(["git", "cat-file", "-e", f"{reviewed_commit}^{{commit}}"], cwd=path,
                      text=True, capture_output=True).returncode:
        return "paired review artifact gate cannot resolve the reviewed implementation commit"
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, "HEAD"], cwd=path,
                      text=True, capture_output=True).returncode:
        return "paired review artifact gate's pinned reviewed main is not an ancestor of the review branch"
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_commit, "HEAD"], cwd=path,
                      text=True, capture_output=True).returncode:
        return "paired review artifact gate's reviewed implementation commit is not an ancestor of the review branch"
    artifact_contents = {
        changed: (path / changed).read_text()
        for changed in changed_paths
        if changed.startswith("custodian/docs/ai_context/task_packets/") and (path / changed).is_file()
    }
    return paired_review_artifact_scope_error(
        workstream_id, review_packet, packet_text, changed_paths,
        artifact_contents=artifact_contents,
    )


def _nonpassing_review_artifact_error(workstream_id: str, path: Path, review_packet: Path,
                                      packet_text: str, outcome: dict[str, str]) -> str | None:
    """Gate a findings/human_required review: evidence only, reviewed target never touched."""
    target_workstream = _packet_header_value(packet_text, "Review target workstream")
    target_packet_path = _packet_header_value(packet_text, "Review target packet")
    if not target_workstream or not target_packet_path:
        return f"paired review artifact gate requires Review target workstream/packet for {workstream_id}"
    try:
        changed_paths = git("diff", "--no-renames", "--name-only", "origin/main...HEAD", cwd=path).splitlines()
    except WorkstreamError as exc:
        return f"paired review artifact gate cannot inspect changed paths: {exc}"
    allowed = {
        f"custodian/docs/ai_context/task_packets/{review_packet.name}",
        f"custodian/docs/ai_context/task_packets/archived/{review_packet.name}",
        "custodian/docs/ai_context/task_packets/README.md",
        _expected_summary_filename(workstream_id),
    }
    outside = sorted(item for item in changed_paths if item.replace("\\", "/") not in allowed)
    if outside:
        return f"paired review artifact gate rejects a nonpassing review changing {outside[0]}"
    reviewed_main = outcome["Reviewed main"]
    try:
        baseline = read_git_text(path, reviewed_main, target_packet_path)
        current = (path / target_packet_path).read_bytes().decode("utf-8")
    except (ValueError, OSError, UnicodeDecodeError):
        return "paired review artifact gate cannot compare the reviewed packet with its pinned baseline"
    if current != baseline:
        return "paired review artifact gate rejects any change to the reviewed packet in a nonpassing review"
    commit, identity_error = resolve_target_implementation_commit(
        path, reviewed_main, target_packet_path, target_workstream, baseline,
    )
    if identity_error:
        return f"paired review artifact gate cannot identify the pinned implementation: {identity_error}"
    binding = review_outcome.outcome_identity_error(
        outcome, review_workstream=workstream_id, target_workstream=target_workstream,
        reviewed_main=reviewed_main, implementation_commit=commit,
        review_cycle=parse_packet(str(review_packet), packet_text).review_cycle,
    )
    if binding:
        return f"paired review artifact gate rejects the Review Outcome: {binding}"
    evidence = packet_text.split("## Review Outcome")[0]
    for finding in review_outcome.finding_ids(outcome):
        if not review_outcome.finding_evidenced(evidence, finding):
            return f"paired review artifact gate finds no written evidence for {finding} in the review packet"
    for revision in (reviewed_main, commit):
        if subprocess.run(["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=path,
                          text=True, capture_output=True).returncode:
            return "paired review artifact gate's pinned reviewed commit is not an ancestor of the review branch"
    return None


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
    if review_packet:
        scope_error = _paired_review_artifact_preflight_error(workstream_id, path, review_packet)
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
    _summary_backlink_preflight(workstream_id, path, packets)
    return packets


def _archive_transition_tip_error(workstream_id: str, path: Path) -> str | None:
    """Require a bounded archive boundary, allowing only authenticated sync/follow-up."""
    repo = root_repo(path)
    head = git("rev-parse", "HEAD", cwd=path)
    packets = _associated_task_packets(repo, workstream_id)
    archive_root = (repo / TASK_PACKET_ARCHIVE).resolve()
    if not any(packet.parent.resolve() == archive_root for packet in packets):
        return None
    if subprocess.run(["git", "show-ref", "--verify", "--quiet", "refs/remotes/origin/main"],
                      cwd=path).returncode == 0:
        main = git("rev-parse", "refs/remotes/origin/main", cwd=path)
    elif subprocess.run(["git", "show-ref", "--verify", "--quiet", "refs/heads/main"],
                        cwd=path).returncode == 0:
        # Small isolated Git fixtures may not create remote-tracking refs.
        main = git("rev-parse", "refs/heads/main", cwd=path)
    else:
        return "cannot verify archived packet transition without a main baseline"
    transitions: list[tuple[str, str]] = []
    commits = git("rev-list", "--first-parent", "--reverse", f"{main}..{head}", cwd=path).splitlines()
    for archived in packets:
        if archived.parent.resolve() != archive_root:
            continue
        archived_rel = archived.relative_to(repo).as_posix()
        active_rel = archived.relative_to(archive_root).as_posix()
        active_rel = f"{TASK_PACKET_ROOT.as_posix()}/{active_rel}"
        for commit in commits:
            parent = git("rev-parse", f"{commit}^1", cwd=path, check=False)
            if not parent:
                continue
            active_before = subprocess.run(
                ["git", "cat-file", "-e", f"{parent}:{active_rel}"], cwd=path,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            archive_before = subprocess.run(
                ["git", "cat-file", "-e", f"{parent}:{archived_rel}"], cwd=path,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            active_after = subprocess.run(
                ["git", "cat-file", "-e", f"{commit}:{active_rel}"], cwd=path,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            archive_after = subprocess.run(
                ["git", "cat-file", "-e", f"{commit}:{archived_rel}"], cwd=path,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            if active_before and not archive_before and not active_after and archive_after:
                transitions.append((commit, archived_rel))
    if not transitions:
        return None
    if len(transitions) != 1:
        transition_commit, packet = transitions[-1]
        return f"multiple canonical archive transitions found; latest is {transition_commit} ({packet})"
    transition_commit, packet = transitions[0]
    if transition_commit == head:
        return None

    # This one previously validated recovery has an exact, independently
    # authorized archive -> summary repair -> sync -> completion evidence ->
    # blocker note -> later-main sync history. Do not infer a changed main_sync
    # event from any merge: validate the Git objects and, when present, accept
    # only the truthful final no-op witness emitted by normal finish.
    recovery_error = _authorized_failed_import_archive_recovery_error(
        workstream_id, path, repo, head, main, transition_commit, packet,
    )
    if recovery_error is not None:
        return recovery_error
    if workstream_id == FAILED_IMPORT_ARCHIVE_RECOVERY["workstream"]:
        return None

    # workstream.py finish may already have synchronized main before validation
    # or landing stopped. Admit that state only when the immutable lifecycle trace
    # pins the exact archive-first merge and records the corresponding main SHA.
    first_parent = git("rev-parse", f"{head}^1", cwd=path, check=False)
    merge_candidate = head if first_parent == transition_commit else first_parent
    merge_parents = git("rev-list", "--parents", "-n", "1", merge_candidate, cwd=path,
                        check=False).split() if merge_candidate else []
    if len(merge_parents) == 3 and merge_parents[1] == transition_commit:
        second_parent = merge_parents[2]
        trace_prefix = f"refs/remotes/origin/agent-diagnostics/{workstream_id}/"
        refs = git("for-each-ref", "--format=%(refname)", trace_prefix, cwd=path,
                   check=False).splitlines()
        active_packet = packet.removeprefix(f"{TASK_PACKET_ARCHIVE}/")
        active_packet = f"{TASK_PACKET_ROOT}/{active_packet}"
        trace_matches = []
        for ref in refs:
            run_id = ref.rsplit("/", 1)[-1]
            blob = git("show", f"{ref}:trace.jsonl", cwd=path, check=False)
            if not blob:
                continue
            try:
                events = [json.loads(line) for line in blob.splitlines() if line.strip()]
            except (ValueError, TypeError):
                continue
            if (not events or any(event.get("schema") != "custodian.workflow_trace_event.v1"
                                  or event.get("workstream") != workstream_id
                                  or event.get("run_id") != run_id
                                  or event.get("packet") != active_packet for event in events)):
                continue
            claims = [event.get("data", {}) for event in events
                      if event.get("event") == "remote_claim_acquired"]
            publications = [event.get("data", {}) for event in events
                            if event.get("event") == "worktree_published"]
            syncs = [event.get("data", {}) for event in events
                     if event.get("event") == "main_sync"]
            blocked = [event for event in events if event.get("event") == "run_blocked"]
            landed = [event for event in events
                      if event.get("event") in {"landing_started", "landing_completed"}]
            if (len(claims) != 1 or len(publications) != 1 or len(syncs) != 1
                    or len(blocked) != 1 or events[-1].get("event") != "run_blocked" or landed):
                continue
            claim, publication, sync = claims[0], publications[0], syncs[0]
            event_order = [event.get("event") for event in events]
            if not (event_order.index("remote_claim_acquired")
                    < event_order.index("worktree_published")
                    < event_order.index("main_sync") < event_order.index("run_blocked")):
                continue
            if (claim.get("remote_ref") != f"refs/heads/dispatch-claims/{workstream_id}"
                    or not re.fullmatch(r"[0-9a-f]{40,64}", str(claim.get("claim_oid", "")))
                    or publication.get("branch") != branch_for(workstream_id)
                    or publication.get("clean") is not True
                    or publication.get("head") != claim.get("main_sha")
                    or publication.get("upstream") != claim.get("main_sha")
                    or not isinstance(claim.get("main_sha"), str)
                    or subprocess.run(["git", "merge-base", "--is-ancestor",
                                       claim["main_sha"], transition_commit], cwd=path,
                                      capture_output=True).returncode != 0
                    or sync.get("changed") is not True or sync.get("head") != merge_candidate
                    or sync.get("main_sha") != second_parent):
                continue
            trace_matches.append((ref, publication))
        if len(trace_matches) == 1:
            _, publication = trace_matches[0]
            # A stopped finish attempt leaves HEAD at the traced merge. One
            # direct child is permitted for the bounded producer correction,
            # and every changed path must be named by the archived task packet.
            if head == merge_candidate:
                return None
            if first_parent == merge_candidate:
                packet_text = (repo / packet).read_text()
                work_surface = re.search(r"(?im)^- Work surface:\s*(.+)$", packet_text)
                declared = set(re.findall(r"`([^`]+)`", work_surface.group(1))) if work_surface else set()
                child_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r", head,
                                      cwd=path).splitlines())
                child_parents = git("rev-list", "--parents", "-n", "1", head, cwd=path).split()
                mode_rows = git("ls-tree", "-r", "-z", head, cwd=path).split("\0")
                child_tree_modes = {}
                for row in mode_rows:
                    left, separator, name = row.partition("\t")
                    if separator and left.split():
                        child_tree_modes[name] = left.split()[0]
                if (len(child_parents) == 2 and child_paths and child_paths.issubset(declared)
                        and all(child_tree_modes.get(name) == "100644" for name in child_paths)):
                    return None

    # A prior merge may have stopped on an index conflict before finish could
    # append its main_sync event. After the operator resolves only the generated
    # managed index, the next finish verifies the complete archive-to-current-main
    # chain here; its normal sync_main call then records the factual no-op witness.
    history = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{transition_commit}..{head}"],
        cwd=path, text=True, capture_output=True,
    )
    commits = history.stdout.splitlines() if history.returncode == 0 else []
    if commits:
        packet_text = (repo / packet).read_text()
        work_surface = re.search(r"(?im)^- Work surface:\s*(.+)$", packet_text)
        declared = set(re.findall(r"`([^`]+)`", work_surface.group(1))) if work_surface else set()
        previous = transition_commit
        sync_merges = []
        valid = True
        host_validation = None
        for commit in commits:
            parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()
            if len(parents) == 3 and parents[1] == previous:
                main_parent = parents[2]
                if subprocess.run(["git", "merge-base", "--is-ancestor", main_parent, main],
                                  cwd=path, capture_output=True).returncode:
                    valid = False
                    break
                if (git("rev-parse", f"{previous}:{packet}", cwd=path, check=False)
                        != git("rev-parse", f"{commit}:{packet}", cwd=path, check=False)):
                    valid = False
                    break
                expected = subprocess.run(["git", "merge-tree", "--write-tree", previous, main_parent],
                                          cwd=path, text=True, capture_output=True)
                actual_tree = git("rev-parse", f"{commit}^{{tree}}", cwd=path)
                expected_tree = expected.stdout.splitlines()[0].strip() if expected.stdout.splitlines() else None
                if not expected_tree:
                    valid = False
                    break
                if expected.returncode or expected_tree != actual_tree:
                    changed = set(git("diff-tree", "-r", "--no-commit-id", "--name-only",
                                      expected_tree, actual_tree, cwd=path).splitlines())
                    readme = "custodian/docs/ai_context/task_packets/README.md"
                    if host_validation is None:
                        for tools_path in (repo / "custodian/tools",
                                           repo / "custodian/tools/validation"):
                            if str(tools_path) not in sys.path:
                                sys.path.insert(0, str(tools_path))
                        import paired_review_host_validation as host_validation
                    first = subprocess.run(["git", "show", f"{previous}:{readme}"], cwd=path,
                                           capture_output=True)
                    second = subprocess.run(["git", "show", f"{main_parent}:{readme}"], cwd=path,
                                            capture_output=True)
                    merged = subprocess.run(["git", "show", f"{commit}:{readme}"], cwd=path,
                                            capture_output=True)
                    if (changed != {readme} or first.returncode or second.returncode or merged.returncode
                            or not host_validation._managed_packet_index_additive_reconciliation(
                                first.stdout, second.stdout, merged.stdout)):
                        valid = False
                        break
                sync_merges.append((commit, main_parent))
            elif len(parents) == 2 and parents[1] == previous and sync_merges:
                status = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames",
                             "-r", commit, cwd=path).splitlines()
                operations = [line.split("\t") for line in status]
                if (not operations or any(len(row) != 2 or row[0] != "M"
                                           or row[1] not in declared for row in operations)):
                    valid = False
                    break
                parent = parents[1]
                for _, source_path in operations:
                    for revision in (parent, commit):
                        entry = subprocess.run(["git", "ls-tree", "-z", revision,
                                                "--", source_path], cwd=path, capture_output=True)
                        if (entry.returncode or not entry.stdout
                                or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"):
                            valid = False
                            break
                    if not valid:
                        break
                if not valid:
                    break
            else:
                valid = False
                break
            previous = commit
        if (valid and sync_merges and sync_merges[-1][1] == main
                and subprocess.run(["git", "merge-base", "--is-ancestor",
                                    sync_merges[-1][0], head], cwd=path,
                                   capture_output=True).returncode == 0):
            return None
    transition_commit, packet = transitions[0]
    return (
        f"canonical archive transition for {packet} is {transition_commit}, not the current "
        f"branch tip {head}; include source changes before archival or use a supported "
        "source-span record"
    )


FAILED_IMPORT_ARCHIVE_RECOVERY = {
    "workstream": "agent-paired-review-failed-host-validation-import-recovery-v1",
    "archive": "25229d8d3874608f7b8492df98bc3df4385a9d28",
    "summary_repair": "49772f31f4dfe28614b8be9c5c820f14e8872f6b",
    "first_sync": "dbcf8aec4eb09264b60bea9d26c99f235022efb5",
    "first_sync_test_runner_blob": "7e9051cac61dc56ddc63c013e546a439681fcabd",
    "post_sync_evidence": "a55c14e020d4986fb35baa75bde691c0c2e67e93",
    "blocker_note": "b7b245dbf113b7fc21a5c34a83aee0bd65d7ccc8",
    "final_sync": "d83319a3a9c211fe3947e4951bfaa06f1684bf05",
    "claim_base": "030dbe986c0ced4e8b1dc2c816f466c81146b5f2",
    "claim_oid": "5249f25988aa13cdf99372754509fb7b91eeef94",
    "trace_anchor": "173104f75f4380aa2c5eadf0e0c8ca2f2bd04855",
    "first_main": "e9e69fc2178b1a96e02240f4b0a86cdaf30581e7",
    "final_main": "8e4bca145658b825bb6dedeed595a3c53497a138",
    "run_id": "20261020T200652Z-2fd156ce23d0",
    "summary": "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md",
    "correction_commits": [
        "d68bd6e5c5b151ddd6aa38485ae9c2302a5fe993",
        "a3f7bfc4fbb7911b7dfe2a2982cff6de981f99a8",
        "819c9347a59f0029ce8d52ddcdcf6c58838ab2c0",
        "596dc6c1e9c949eb18940769e4232351ad9f1e60",
        "9c806d5dd592c14ce0e82ceeeff056bb284305e7",
    ],
    "authorized_main_advance": {
        "base": "8e4bca145658b825bb6dedeed595a3c53497a138",
        "head": "b5b1e5f2450f3f577a5df5c173c338e6da5187d1",
        "commits": [
            "0da9923e818645178a079eece3482216cd295ccc",
            "0ed185fd23946eeb8a6d5835c171000a65f75a68",
            "e1cfee4692a754a98a27d7fb3cf382dc55328bb8",
            "ae5e0d8719d028f8feba6f4250633c30dfe0f470",
            "bc79a4938577a9822f2d1c3c95ac701f5e8cb0d9",
            "b5b1e5f2450f3f577a5df5c173c338e6da5187d1",
        ],
        "commit_paths": [
            ["custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md"],
            ["custodian/docs/ai_context/task_packets/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"],
            ["custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"],
            ["design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md"],
            ["custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"],
            [
                "custodian/docs/ai_context/task_packets/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
                "custodian/docs/ai_context/task_packets/README.md",
                "custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
            ],
        ],
    },
}

FAILED_IMPORT_MAX_FOLLOWUP_CORRECTIONS = 3
FAILED_IMPORT_MAX_POST_SYNC_CORRECTIONS = 1


def _authorized_failed_import_archive_recovery_error(
    workstream_id: str, path: Path, repo: Path, head: str, main: str,
    transition_commit: str, archived_rel: str,
) -> str | None:
    """Authenticate the exact preserved failed-import finish history.

    The authenticated recovery chain permits up to three source/test
    corrections before one exact automatic merge of current origin/main, then
    at most one source/test correction. Path and file-mode checks below bind
    those commits to the active packet. All earlier history is pinned to
    immutable commits named by the published planning refresh.
    """
    if workstream_id != FAILED_IMPORT_ARCHIVE_RECOVERY["workstream"]:
        return None
    pinned = FAILED_IMPORT_ARCHIVE_RECOVERY
    if transition_commit != pinned["archive"]:
        return "failed-import archive recovery does not match the authorized archive commit"
    baseline_main = pinned["final_main"]
    if (main != baseline_main
            and not _failed_import_main_advance_is_authorized(path, pinned, main)):
        return "failed-import archive recovery main is not a descendant of its pinned baseline"
    active_rel = f"{TASK_PACKET_ROOT.as_posix()}/{Path(archived_rel).name}"
    protected_main_paths = {
        archived_rel,
        active_rel,
        pinned["summary"],
        "AGENTS.md",
        "custodian/AGENTS.md",
        "custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md",
        "custodian/tools/agent/workstream.py",
        "custodian/tools/agent/test_workstream.py",
        "custodian/tools/agent/paired_review_host_validation.py",
        "custodian/tools/agent/paired_review_runner.py",
        "custodian/tools/agent/test_paired_review_runner.py",
        "custodian/tools/agent/task_packet_index.py",
        "custodian/tools/validation/validation_manifest.json",
    }
    advanced_main_paths = set(git(
        "diff-tree", "-r", "--no-commit-id", "--name-only",
        baseline_main, main, cwd=path,
    ).splitlines())
    if advanced_main_paths.intersection(protected_main_paths):
        return "failed-import archive recovery main changed protected packet or validator paths"
    baseline_active = subprocess.run(
        ["git", "rev-parse", "--verify", f"{baseline_main}:{active_rel}"], cwd=path,
        capture_output=True, text=True,
    )
    current_active = subprocess.run(
        ["git", "rev-parse", "--verify", f"{main}:{active_rel}"], cwd=path,
        capture_output=True, text=True,
    )
    if (baseline_active.returncode or current_active.returncode
            or baseline_active.stdout != current_active.stdout):
        return "failed-import archive recovery active packet differs from its pinned authorization"

    commits = git("rev-list", "--first-parent", "--reverse",
                  f"{transition_commit}..{head}", cwd=path).splitlines()
    historical = [pinned[name] for name in (
        "summary_repair", "first_sync", "post_sync_evidence", "blocker_note", "final_sync",
    )]
    correction_history = pinned.get("correction_commits", [])
    expected_history = historical + correction_history
    if len(commits) <= len(expected_history):
        return "failed-import archive recovery history differs from its pinned lifecycle commits"
    if commits[:len(expected_history)] != expected_history:
        return "failed-import archive recovery history differs from its pinned lifecycle commits"
    post_history = commits[len(expected_history):]
    correction_base = correction_history[-1] if correction_history else pinned["final_sync"]
    suffix = _failed_import_recovery_suffix(path, post_history, correction_base, main)
    if suffix is None:
        return "failed-import recovery correction/sync suffix is outside its exact bounded history"
    post_corrections, sync_commit = suffix
    if not post_corrections and not sync_commit:
        return "failed-import archive recovery has no authorized source/test correction or sync"
    correction_commits = commits[len(historical):len(expected_history)] + post_corrections
    sync_tail = [sync_commit] if sync_commit else []
    for index, correction in enumerate(correction_history):
        expected_parent = pinned["final_sync"] if index == 0 else correction_history[index - 1]
        if git("rev-parse", f"{correction}^1", cwd=path, check=False) != expected_parent:
            return "pinned failed-import correction has unexpected parent order"
    if correction_commits:
        expected_parent = (pinned["final_sync"] if len(correction_commits) == 1
                           else correction_commits[-2])
        if sync_tail and subprocess.run(
            ["git", "merge-base", "--is-ancestor", sync_tail[0], correction_commits[-1]],
            cwd=path, capture_output=True,
        ).returncode == 0:
            expected_parent = sync_tail[0]
        if git("rev-parse", f"{correction_commits[-1]}^1", cwd=path, check=False) != expected_parent:
            return "failed-import correction is not a direct child of its pinned lifecycle predecessor"
    if sync_tail:
        sync_commit = sync_tail[0]
        parents = git("rev-list", "--parents", "-n", "1", sync_commit, cwd=path).split()[1:]
        if len(parents) != 2 or parents[1] != main or parents[0] not in {
            pinned["final_sync"], *correction_commits,
        }:
            return "failed-import post-recovery sync does not bind the exact correction and current main"
        automatic_tree = _automatic_merge_tree(path, sync_commit)
        actual_tree = git("rev-parse", f"{sync_commit}^{{tree}}", cwd=path)
        if automatic_tree is None or automatic_tree != actual_tree:
            return "failed-import post-recovery sync contains an unverified conflict resolution"

    expected_parents = {
        pinned["summary_repair"]: [pinned["archive"]],
        pinned["first_sync"]: [pinned["summary_repair"], pinned["first_main"]],
        pinned["post_sync_evidence"]: [pinned["first_sync"]],
        pinned["blocker_note"]: [pinned["post_sync_evidence"]],
        pinned["final_sync"]: [pinned["blocker_note"], pinned["final_main"]],
    }
    for commit, expected in expected_parents.items():
        actual = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
        if actual != expected:
            return f"pinned archive recovery commit has unexpected parent order: {commit}"

    summary_rel = pinned["summary"]
    summary_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r",
                            pinned["summary_repair"], cwd=path).splitlines())
    if summary_paths != {summary_rel} or not _summary_repair_is_authoring_chat_only(
        path, pinned["summary_repair"], summary_rel, archived_rel,
    ):
        return "pinned pre-sync summary repair is not limited to the exact authoring-chat backlink"

    evidence_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r",
                             pinned["post_sync_evidence"], cwd=path).splitlines())
    if (evidence_paths != {archived_rel}
            or not _post_sync_completion_evidence_is_bounded(path, pinned["post_sync_evidence"], archived_rel)):
        return "pinned post-sync completion evidence changed outside its bounded receipt field"
    blocker_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r",
                            pinned["blocker_note"], cwd=path).splitlines())
    if blocker_paths != {summary_rel}:
        return "pinned blocker note changed files outside the canonical closing summary"

    # The first sync carries four bounded conflict resolutions: additive managed
    # index entries, preservation of the already-archived packet, the authorized
    # timeout field, and its exact regression test output. The later merge
    # inserts the exact planning refresh from current main into that archive.
    if not _failed_import_first_sync_is_bounded(path, pinned, archived_rel):
        return "pinned first sync contains conflict resolution outside its exact authorized outputs"
    final_tree = _automatic_merge_tree(path, pinned["final_sync"])
    if final_tree is None:
        return "cannot reconstruct the pinned final sync merge tree"
    final_actual_tree = git("rev-parse", f"{pinned['final_sync']}^{{tree}}", cwd=path)
    differing = set(git("diff-tree", "-r", "--no-commit-id", "--name-only",
                        final_tree, final_actual_tree, cwd=path).splitlines())
    active_still_present = subprocess.run(
        ["git", "cat-file", "-e", f"{pinned['final_sync']}:{active_rel}"], cwd=path,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0
    automatic_active_delta_is_exact = False
    if differing == {archived_rel, active_rel}:
        first_parent = git("rev-parse", f"{pinned['final_sync']}^1", cwd=path)
        second_parent = git("rev-parse", f"{pinned['final_sync']}^2", cwd=path)
        first_has_active = subprocess.run(
            ["git", "cat-file", "-e", f"{first_parent}:{active_rel}"], cwd=path,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        ).returncode == 0
        second_has_active = subprocess.run(
            ["git", "cat-file", "-e", f"{second_parent}:{active_rel}"], cwd=path,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        ).returncode == 0
        automatic_active = subprocess.run(
            ["git", "ls-tree", "-z", final_tree, "--", active_rel], cwd=path,
            capture_output=True,
        ).stdout
        second_active = subprocess.run(
            ["git", "ls-tree", "-z", second_parent, "--", active_rel], cwd=path,
            capture_output=True,
        ).stdout
        automatic_active_delta_is_exact = (
            not first_has_active and second_has_active
            and automatic_active == second_active and bool(automatic_active)
        )
    if ((differing != {archived_rel} and not automatic_active_delta_is_exact)
            or active_still_present
            or not _reconciled_archive_packet_matches(path, pinned["final_sync"],
                                                      archived_rel, active_rel)):
        return "pinned final sync conflict is not the exact authorized packet refresh reconciliation"

    allowed = {"custodian/tools/agent/workstream.py", "custodian/tools/agent/test_workstream.py"}
    correction_coverage: set[str] = set()
    for correction in correction_commits:
        correction_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r",
                                   correction, cwd=path).splitlines())
        if (not correction_paths or not correction_paths.issubset(allowed)
                or not _commit_paths_are_regular_files(path, correction, correction_paths)):
            return "post-sync lifecycle correction is outside its two authorized regular source/test paths"
        correction_coverage.update(correction_paths)
    if correction_coverage != allowed:
        return "post-sync lifecycle correction does not cover both authorized source and test paths"
    active_blob = git("show", f"{main}:{active_rel}", cwd=path, check=False)
    if not active_blob:
        return "cannot verify correction authority from the active origin/main packet"
    work_surface = re.findall(r"(?m)^- Work surface:\s*(.*)$", active_blob)
    declared = set(re.findall(r"`([^`]+)`", work_surface[0])) if len(work_surface) == 1 else set()
    if not allowed.issubset(declared):
        return "active origin/main packet does not authorize the exact lifecycle correction paths"

    trace_ref = (f"refs/remotes/origin/agent-diagnostics/{workstream_id}/"
                 f"{pinned['run_id']}")
    raw_trace = git("show", f"{trace_ref}:trace.jsonl", cwd=path, check=False)
    try:
        events = [json.loads(line) for line in raw_trace.splitlines() if line.strip()]
    except (ValueError, TypeError):
        events = []
    trace_commit = git("rev-parse", trace_ref, cwd=path, check=False)
    if not events or not _failed_import_recovery_trace_is_authentic(
        events, workstream_id, pinned, active_rel, branch_for(workstream_id),
        str(path), head, main, trace_ref, trace_commit,
    ):
        return "original failed-import lifecycle trace does not authenticate this exact claim and landing history"
    return None


def _failed_import_recovery_suffix(
    path: Path, suffix: list[str], correction_base: str, main: str,
) -> tuple[list[str], str | None] | None:
    """Validate a bounded source/test correction chain and optional exact sync merge."""
    post_corrections = []
    sync_commit = None
    previous = correction_base
    before_sync_count = 0
    after_sync_count = 0
    for commit in suffix:
        parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
        if len(parents) == 2:
            if sync_commit or parents != [previous, main]:
                return None
            sync_commit = commit
            automatic_tree = _automatic_merge_tree(path, commit)
            if automatic_tree is None or automatic_tree != git(
                "rev-parse", f"{commit}^{{tree}}", cwd=path,
            ):
                return None
        elif parents == [previous]:
            post_corrections.append(commit)
            if sync_commit:
                after_sync_count += 1
                if after_sync_count > FAILED_IMPORT_MAX_POST_SYNC_CORRECTIONS:
                    return None
            else:
                before_sync_count += 1
                if before_sync_count > FAILED_IMPORT_MAX_FOLLOWUP_CORRECTIONS:
                    return None
        else:
            return None
        previous = commit

    return post_corrections, sync_commit


def _failed_import_main_advance_is_authorized(
    repo: Path, pinned: dict[str, object], current_main: str,
) -> bool:
    authorization = pinned.get("authorized_main_advance")
    if (not isinstance(authorization, dict)
            or authorization.get("base") != pinned.get("final_main")
            or current_main != authorization.get("head")):
        return False
    commits = authorization.get("commits")
    commit_paths = authorization.get("commit_paths")
    if (authorization.get("base") != pinned.get("final_main")
            or not isinstance(commits, list) or not commits
            or not isinstance(commit_paths, list) or len(commit_paths) != len(commits)):
        return False
    actual = git("rev-list", "--first-parent", "--reverse",
                 f"{pinned['final_main']}..{current_main}", cwd=repo).splitlines()
    if actual != commits:
        return False
    previous = str(pinned["final_main"])
    for commit, expected_paths in zip(commits, commit_paths):
        if (not isinstance(commit, str) or not isinstance(expected_paths, list)
                or not expected_paths or any(not isinstance(path, str) for path in expected_paths)
                or len(set(expected_paths)) != len(expected_paths)):
            return False
        parents = git("rev-list", "--parents", "-n", "1", commit, cwd=repo).split()[1:]
        actual_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r",
                               commit, cwd=repo).splitlines())
        mode = subprocess.run(
            ["git", "ls-tree", "-z", commit, "--", *expected_paths],
            cwd=repo, capture_output=True,
        )
        rows = [row for row in mode.stdout.split(b"\0") if row]
        regular_files = len(rows) == len(expected_paths) and all(
            row.split(b"\t", 1)[0].split()[0] == b"100644" for row in rows
        )
        if (parents != [previous] or actual_paths != set(expected_paths)
                or mode.returncode or not regular_files):
            return False
        previous = commit
    return True


def _automatic_merge_tree(path: Path, commit: str) -> str | None:
    parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
    if len(parents) != 2:
        return None
    result = subprocess.run(["git", "merge-tree", "--write-tree", *parents], cwd=path,
                            text=True, capture_output=True)
    first = result.stdout.splitlines()[0].strip() if result.stdout.splitlines() else ""
    return first if first and re.fullmatch(r"[0-9a-f]{40,64}", first) else None


def _failed_import_first_sync_is_bounded(path: Path, pinned: dict[str, str],
                                         archived_rel: str) -> bool:
    commit = pinned["first_sync"]
    automatic_tree = _automatic_merge_tree(path, commit)
    merged_tree = git("rev-parse", f"{commit}^{{tree}}", cwd=path)
    if automatic_tree == merged_tree:
        return True
    parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
    if len(parents) != 2:
        return False
    first_parent, second_parent = parents
    changed = set(git("diff-tree", "-r", "--no-commit-id", "--name-only",
                      automatic_tree, merged_tree, cwd=path).splitlines())
    readme = "custodian/docs/ai_context/task_packets/README.md"
    manifest = "custodian/tools/validation/validation_manifest.json"
    regression = "custodian/tools/agent/test_paired_review_runner.py"
    active_packet = f"{TASK_PACKET_ROOT.as_posix()}/{Path(archived_rel).name}"
    allowed = {readme, archived_rel, manifest, regression}
    if changed != allowed:
        return False

    for relative in allowed:
        entry = subprocess.run(["git", "ls-tree", "-z", commit, "--", relative],
                               cwd=path, capture_output=True)
        if (entry.returncode or not entry.stdout
                or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"):
            return False
    if subprocess.run(["git", "cat-file", "-e", f"{commit}:{active_packet}"], cwd=path,
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        return False

    base_readme = subprocess.run(["git", "show", f"{first_parent}:{readme}"], cwd=path,
                                 capture_output=True).stdout
    main_readme = subprocess.run(["git", "show", f"{second_parent}:{readme}"], cwd=path,
                                 capture_output=True).stdout
    merged_readme = subprocess.run(["git", "show", f"{commit}:{readme}"], cwd=path,
                                   capture_output=True).stdout
    if not all((base_readme, main_readme, merged_readme)):
        return False
    for tools_path in (Path(path) / "custodian/tools", Path(path) / "custodian/tools/agent"):
        if str(tools_path) not in sys.path:
            sys.path.insert(0, str(tools_path))
    try:
        import paired_review_host_validation as host_validation
    except ImportError:
        return False
    if not host_validation._managed_packet_index_additive_reconciliation(
        base_readme, main_readme, merged_readme,
    ):
        return False

    base_archive = subprocess.run(["git", "show", f"{first_parent}:{archived_rel}"], cwd=path,
                                  capture_output=True).stdout
    merged_archive = subprocess.run(["git", "show", f"{commit}:{archived_rel}"], cwd=path,
                                    capture_output=True).stdout
    if not base_archive or merged_archive != base_archive:
        return False
    if not _manifest_timeout_conflict_is_bounded(path, first_parent, second_parent,
                                                 commit, manifest):
        return False
    merged_regression = git("rev-parse", f"{commit}:{regression}", cwd=path, check=False)
    return merged_regression == pinned["first_sync_test_runner_blob"]


def _manifest_timeout_conflict_is_bounded(path: Path, first_parent: str,
                                          second_parent: str, merge_commit: str,
                                          manifest_path: str) -> bool:
    blobs = [subprocess.run(["git", "show", f"{revision}:{manifest_path}"], cwd=path,
                            capture_output=True) for revision in (first_parent, second_parent,
                                                                  merge_commit)]
    if any(result.returncode for result in blobs):
        return False
    branch_bytes, main_bytes, merged_bytes = (result.stdout for result in blobs)
    try:
        branch_doc, main_doc, merged_doc = (json.loads(raw) for raw in
                                            (branch_bytes, main_bytes, merged_bytes))
    except (ValueError, TypeError):
        return False

    def pair(document: dict) -> dict | None:
        matches = [item for item in document.get("tests", [])
                   if item.get("id") == "paired_review_runner_unit"]
        return matches[0] if len(matches) == 1 else None

    branch_pair, main_pair, merged_pair = map(pair, (branch_doc, main_doc, merged_doc))
    if not branch_pair or not main_pair or not merged_pair:
        return False
    if (branch_pair.get("timeout_sec") != 90
            or main_pair.get("timeout_sec") not in {30, 60}
            or merged_pair != branch_pair):
        return False
    branch_without_timeout = json.loads(branch_bytes)
    main_without_timeout = json.loads(main_bytes)
    pair(branch_without_timeout).pop("timeout_sec", None)
    pair(main_without_timeout).pop("timeout_sec", None)
    if branch_without_timeout != main_without_timeout:
        return False

    marker = b'"id": "paired_review_runner_unit"'
    start = main_bytes.find(marker)
    if start < 0 or main_bytes.find(marker, start + len(marker)) >= 0:
        return False
    end = main_bytes.find(b'"needs_import": false', start)
    if end < 0:
        return False
    match = re.search(rb'"timeout_sec": (?:30|60)', main_bytes[start:end])
    if match is None:
        return False
    expected = (main_bytes[:start + match.start()] + b'"timeout_sec": 90'
                + main_bytes[start + match.end():])
    return branch_bytes == expected and merged_bytes == branch_bytes


def _commit_paths_are_regular_files(path: Path, commit: str, expected: set[str]) -> bool:
    rows = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames", "-r",
               commit, cwd=path).splitlines()
    if {row.split("\t")[-1] for row in rows} != expected or any(
        row.split("\t", 1)[0] not in {"M", "A"} for row in rows
    ):
        return False
    for rel in expected:
        for revision in (f"{commit}^1", commit):
            entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", rel],
                                   cwd=path, capture_output=True)
            if (entry.returncode or not entry.stdout
                    or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"):
                return False
    return True


def _summary_repair_is_authoring_chat_only(path: Path, commit: str,
                                           summary_rel: str, archived_rel: str) -> bool:
    parent = git("rev-parse", f"{commit}^1", cwd=path)
    archived = git("show", f"{parent}:{archived_rel}", cwd=path, check=False)
    try:
        header = parse_packet(str(path / archived_rel), archived)
    except Exception:
        return False
    url = header.authoring_chat
    if not url or url in {"not-recorded", "n/a"}:
        return False
    diff = subprocess.run(["git", "diff", "--no-ext-diff", "--unified=0", parent, commit,
                           "--", summary_rel], cwd=path, text=True, capture_output=True)
    additions = [line[1:] for line in diff.stdout.splitlines()
                 if line.startswith("+") and not line.startswith("+++")]
    removals = [line[1:] for line in diff.stdout.splitlines()
                if line.startswith("-") and not line.startswith("---")]
    return (diff.returncode == 0
            and additions.count(f"Authoring chat: {url}") == 1
            and additions.count(f"- Authoring chat: {url}") == 1
            and additions.count("") == 1 and len(additions) == 3
            and removals == [f"- Authoring chat: `{url}`"]
            and _commit_paths_are_regular_files(path, commit, {summary_rel}))


def _post_sync_completion_evidence_is_bounded(path: Path, commit: str,
                                               archived_rel: str) -> bool:
    parent = git("rev-parse", f"{commit}^1", cwd=path)
    diff = subprocess.run(["git", "diff", "--no-ext-diff", "--unified=0", parent, commit,
                           "--", archived_rel], cwd=path, text=True, capture_output=True)
    additions = [line[1:] for line in diff.stdout.splitlines()
                 if line.startswith("+") and not line.startswith("+++")]
    removals = [line[1:] for line in diff.stdout.splitlines()
                if line.startswith("-") and not line.startswith("---")]
    removed_evidence = [line for line in removals if line.startswith("- Evidence: `")]
    added_evidence = [line for line in additions if line.startswith("- Evidence: `")]
    added_validation = [line for line in additions if line.startswith("- Post-sync validation: ")]
    if (diff.returncode != 0 or len(removals) != 1 or len(additions) != 2
            or len(removed_evidence) != 1 or len(added_evidence) != 1
            or len(added_validation) != 1):
        return False
    old_evidence, new_evidence = removed_evidence[0], added_evidence[0]
    validation = added_validation[0]
    merge_sha = git("rev-parse", f"{parent}", cwd=path)
    expected_validation = (
        f"- Post-sync validation: `After merge `{merge_sha}`, changed-file validation "
        "passed 43/43 with complete coverage and no timeouts; the manifest retained "
        "the authorized 90-second bound.`"
    )
    evidence_closeout = (
        (old_evidence.endswith("`.") and new_evidence == old_evidence[:-2] + ".`")
        or (old_evidence.endswith(".") and new_evidence == old_evidence + "`"))
    return (evidence_closeout
            and validation == expected_validation
            and _commit_paths_are_regular_files(path, commit, {archived_rel}))


def _reconciled_archive_packet_matches(path: Path, merge_commit: str,
                                       archived_rel: str, active_rel: str) -> bool:
    first_parent = git("rev-parse", f"{merge_commit}^1", cwd=path)
    second_parent = git("rev-parse", f"{merge_commit}^2", cwd=path)
    previous = git("show", f"{first_parent}:{archived_rel}", cwd=path, check=False)
    active = git("show", f"{second_parent}:{active_rel}", cwd=path, check=False)
    refresh = re.findall(
        r"(?ms)^## Planning Refresh: Exact archive-transition recovery \(2026-10-21\)\n.*?(?=^## Handoff\s*$)",
        active,
    )
    if len(refresh) != 1 or previous.count("## Next Handoff") != 1:
        return False
    handoff = "## Next Handoff"
    prefix, suffix = previous.split(handoff, 1)
    expected = prefix.rstrip() + "\n\n" + refresh[0].rstrip() + "\n\n" + handoff + suffix
    actual = git("show", f"{merge_commit}:{archived_rel}", cwd=path, check=False)
    entry = subprocess.run(["git", "ls-tree", "-z", merge_commit, "--", archived_rel],
                           cwd=path, capture_output=True)
    return (bool(actual) and actual == expected and entry.returncode == 0 and bool(entry.stdout)
            and entry.stdout.split(b"\t", 1)[0].split()[0] == b"100644")


def _failed_import_recovery_trace_is_authentic(
    events: list[dict], workstream_id: str, pinned: dict[str, str], active_packet: str,
    branch: str, worktree: str, head: str, main: str, trace_ref: str, trace_commit: str,
) -> bool:
    run_id = pinned["run_id"]
    if (not trace_commit or trace_commit != git("rev-parse", trace_ref, cwd=Path(worktree), check=False)
            or subprocess.run(["git", "merge-base", "--is-ancestor", pinned["trace_anchor"],
                               trace_commit], cwd=Path(worktree), capture_output=True).returncode != 0):
        return False
    anchor_blob = git("show", f"{pinned['trace_anchor']}:trace.jsonl",
                      cwd=Path(worktree), check=False)
    current_blob = git("show", f"{trace_ref}:trace.jsonl", cwd=Path(worktree), check=False)
    if not anchor_blob or not current_blob.startswith(anchor_blob):
        return False
    if any(event.get("schema") != "custodian.workflow_trace_event.v1"
           or event.get("workstream") != workstream_id or event.get("run_id") != run_id
           or event.get("packet") != active_packet for event in events):
        return False
    claims = [e.get("data", {}) for e in events if e.get("event") == "remote_claim_acquired"]
    published = [e.get("data", {}) for e in events if e.get("event") == "worktree_published"]
    validations = [e.get("data", {}) for e in events if e.get("event") == "validation_report"]
    if (len(claims) != 1 or len(published) != 1 or not validations
            or not any(e.get("passed") is True for e in validations)
            or any(e.get("event") in {"landing_started", "landing_completed"} for e in events)):
        return False
    claim, publication = claims[0], published[0]
    if (claim.get("remote_ref") != f"refs/heads/dispatch-claims/{workstream_id}"
            or claim.get("claim_oid") != pinned["claim_oid"]
            or claim.get("main_sha") != pinned["claim_base"]
            or publication.get("branch") != branch or publication.get("clean") is not True
            or publication.get("head") != pinned["claim_base"]
            or publication.get("upstream") != pinned["claim_base"]
            or publication.get("worktree") != worktree):
        return False
    syncs = [e.get("data", {}) for e in events if e.get("event") == "main_sync"]
    if not syncs:
        merges = git("rev-list", "--first-parent", "--merges",
                     f"{pinned['final_sync']}..{head}", cwd=Path(worktree)).splitlines()
        return not any(
            len(git("rev-list", "--parents", "-n", "1", commit,
                    cwd=Path(worktree), check=False).split()) == 3
            and git("rev-list", "--parents", "-n", "1", commit,
                    cwd=Path(worktree), check=False).split()[2] == main
            for commit in merges
        )
    if len(syncs) == 1 and syncs[0].get("changed") is False:
        parents = git("rev-list", "--parents", "-n", "1", head,
                      cwd=Path(worktree), check=False).split()[1:]
        return (syncs[0].get("head") == head
                and syncs[0].get("main_sha") in {main, pinned["final_main"]}
                and not (len(parents) == 2 and parents[1] == main))
    if len(syncs) not in {1, 2} or syncs[0].get("changed") is not True:
        return False
    changed_sync = syncs[0]
    sync_head = changed_sync.get("head")
    if (changed_sync.get("main_sha") != main or not sync_head
            or subprocess.run(["git", "merge-base", "--is-ancestor", sync_head, head],
                              cwd=Path(worktree), capture_output=True).returncode != 0
            or git("rev-parse", f"{sync_head}^2", cwd=Path(worktree), check=False) != main):
        return False
    if len(syncs) == 2 and (
        syncs[1].get("changed") is not False
        or syncs[1].get("head") != head
        or syncs[1].get("main_sha") != main
    ):
        return False
    after_sync = [e for e in events if e.get("event") == "validation_after_sync"]
    return (not after_sync or (len(after_sync) == 1
            and after_sync[0].get("data", {}).get("passed") is True
            and events.index(after_sync[0]) > max(
                index for index, event in enumerate(events) if event.get("event") == "main_sync"
            )))


def _summary_backlink_preflight(workstream_id: str, path: Path, packets: list[Path]) -> None:
    """Require the durable closing summary to preserve packet authoring-chat provenance."""
    summary = path / _expected_summary_filename(workstream_id)
    expected_urls: list[str] = []
    for packet in packets:
        header = parse_packet(str(packet), packet.read_text())
        chat = header.authoring_chat or header.refresh_planning_chat
        if chat and chat not in {"not-recorded", "n/a"} and chat not in expected_urls:
            expected_urls.append(chat)
    if not expected_urls:
        return
    if not summary.is_file():
        raise WorkstreamError(
            f"finish summary backlink gate requires {summary.name} before teardown"
        )
    summary_text = summary.read_text()
    missing = [url for url in expected_urls if f"Authoring chat: {url}" not in summary_text]
    if missing:
        raise WorkstreamError(
            "finish summary backlink gate requires exact Authoring chat provenance in "
            f"{summary.name}: " + ", ".join(missing)
        )


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


def _completion_truth_report(packet: Path, text: str) -> dict[str, object]:
    header = parse_packet(str(packet), text)
    required = completion_truth_required(header)
    truth = parse_completion_truth(text) if required else None
    return {
        "required": required,
        "present": truth is not None,
        "valid": (truth is not None and truth.error is None) if required else True,
        "all_yes": truth.all_yes if truth is not None else (not required),
        "error": truth.error if truth is not None else None,
    }


def _review_receipt_report(repo: Path, packet: Path, text: str) -> dict[str, object] | None:
    if _packet_header_value(text, "Kind") != "review":
        return None
    target_rel = _packet_header_value(text, "Review target packet")
    outcome, _ = review_outcome.parse_review_outcome(text)
    result: dict[str, object] = {
        "outcome": outcome["Outcome"] if outcome else None,
        "target_packet": target_rel,
        "target_exists": False,
        "receipt_present": False,
        "receipt_status": None,
        "reviewer_context": _packet_header_value(text, "Reviewer context"),
        "reviewer_provenance": _packet_header_value(text, "Reviewer provenance"),
        "receipt_reviewer_context": None,
        "receipt_reviewer_provenance": None,
        "provenance_complete": False,
        "provenance_matches_packet": False,
    }
    if not target_rel:
        return result
    target = (repo / target_rel).resolve()
    if not target.is_relative_to(repo.resolve()) or not target.is_file():
        return result
    result["target_exists"] = True
    target_text = target.read_text()
    receipt = re.search(r"(?ms)^## Independent Review\s*\n(.*?)(?=^## |\Z)", target_text)
    if not receipt:
        return result
    receipt_text = receipt.group(1)
    status = re.search(r"(?m)^\s*-\s*Status:\s*`?(passed|findings|human_required)`?\s*$", receipt_text)
    context = re.search(r"(?m)^\s*-\s*Reviewer context:\s*`?([^`\n]+?)`?\s*$", receipt_text)
    provenance = re.search(r"(?m)^\s*-\s*Reviewer provenance:\s*`?([^`\n]+?)`?\s*$", receipt_text)
    result.update({
        "receipt_present": status is not None,
        "receipt_status": status.group(1) if status else None,
        "receipt_reviewer_context": context.group(1).strip() if context else None,
        "receipt_reviewer_provenance": provenance.group(1).strip() if provenance else None,
        "provenance_complete": bool(context and provenance),
        "provenance_matches_packet": bool(
            context and provenance
            and context.group(1).strip() == _packet_header_value(text, "Reviewer context")
            and provenance.group(1).strip() == _packet_header_value(text, "Reviewer provenance")
        ),
    })
    return result


def _validation_report_status(report: Path | None) -> dict[str, object]:
    result: dict[str, object] = {
        "provided": report is not None,
        "path": str(report) if report is not None else None,
        "exists": False,
        "integrity": "not-provided",
        "green": False,
        "test_count": 0,
        "failed_tests": [],
    }
    if report is None:
        return result
    result["exists"] = report.is_file()
    try:
        data = json.loads(report.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        result.update({"integrity": "invalid", "error": str(exc)})
        return result
    result["exists"] = True
    if not isinstance(data, dict) or data.get("schema") != "custodian.validation.result.v1":
        result.update({"integrity": "invalid", "error": "unexpected validation schema"})
        return result
    tests = data.get("tests")
    if not isinstance(tests, list):
        result.update({"integrity": "invalid", "error": "tests must be a list"})
        return result
    malformed = [item for item in tests if not isinstance(item, dict) or not isinstance(item.get("status"), str)]
    if malformed:
        result.update({"integrity": "invalid", "error": "each test needs a status"})
        return result
    failed = [item.get("id", "<unknown>") for item in tests if item.get("status") != "passed"]
    green = _validation_data_green(data)
    result.update({
        "integrity": "valid",
        "green": green,
        "test_count": len(tests),
        "failed_tests": failed,
        "coverage_complete": data.get("coverage", {}).get("complete") if isinstance(data.get("coverage"), dict) else None,
    })
    return result


def closeout_preflight(
    workstream_id: str, path: Path, validation_report: Path | None = None,
) -> dict[str, object]:
    """Inspect finish readiness without fetching, locking, tracing, or changing Git state."""
    validate_id(workstream_id)
    path = path.resolve()
    repo = root_repo(path)
    expected_branch = branch_for(workstream_id)
    actual_branch = git("branch", "--show-current", cwd=path)
    clean = status_clean(path)
    head = git("rev-parse", "HEAD", cwd=path)

    packets = _associated_task_packets(repo, workstream_id)
    packet_reports: list[dict[str, object]] = []
    for packet in packets:
        text = packet.read_text()
        status = _packet_status(text)
        archived = packet.parent.resolve() == (repo / TASK_PACKET_ARCHIVE).resolve()
        truth = _completion_truth_report(packet, text)
        packet_reports.append({
            "path": packet.relative_to(repo).as_posix(),
            "location": "archived" if archived else "active",
            "status": status,
            "complete": bool(status and status.startswith("complete")),
            "completion_truth": truth,
            "review_receipt": _review_receipt_report(repo, packet, text),
        })
    packet_blockers = [
        item["path"] for item in packet_reports
        if item["location"] == "active" or not item["complete"]
    ]
    truth_blockers = [
        item["path"] for item in packet_reports
        if item["completion_truth"]["required"] and not item["completion_truth"]["all_yes"]
    ]
    stale_index = [
        item["path"] for item in packet_reports
        if item["location"] == "archived" and _active_packet_index_mentions(repo, Path(item["path"]).name)
    ]

    summary_name = _expected_summary_filename(workstream_id)
    summary_path = path / summary_name
    summary_exists = summary_path.is_file()
    summary_committed = subprocess.run(
        ["git", "cat-file", "-e", f"HEAD:{summary_name}"], cwd=path,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0
    expected_urls: list[str] = []
    for packet in packets:
        header = parse_packet(str(packet), packet.read_text())
        url = header.authoring_chat or header.refresh_planning_chat
        if url and url not in {"not-recorded", "n/a"} and url not in expected_urls:
            expected_urls.append(url)
    summary_text = summary_path.read_text() if summary_exists else ""
    missing_backlinks = [url for url in expected_urls if f"Authoring chat: {url}" not in summary_text]
    summary_ok = summary_committed and (not expected_urls or (summary_exists and not missing_backlinks))

    untracked = _untracked_run_artifacts(path)
    artifact_report = [{"path": item, "classification": _artifact_class(item)} for item in untracked]

    branch_remote = f"refs/remotes/origin/{expected_branch}"
    remote_exists = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", branch_remote], cwd=path,
    ).returncode == 0
    remote_head = git("rev-parse", branch_remote, cwd=path, check=False) if remote_exists else None
    ahead = behind = None
    if remote_exists:
        counts = git("rev-list", "--left-right", "--count", f"HEAD...{branch_remote}", cwd=path).split()
        ahead, behind = (int(counts[0]), int(counts[1])) if len(counts) == 2 else (None, None)
    main_exists = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", "refs/remotes/origin/main"], cwd=path,
    ).returncode == 0
    main_head = git("rev-parse", "origin/main", cwd=path, check=False) if main_exists else None
    main_is_ancestor = bool(main_exists) and subprocess.run(
        ["git", "merge-base", "--is-ancestor", "origin/main", "HEAD"], cwd=path,
    ).returncode == 0
    archive_transition_error = _archive_transition_tip_error(workstream_id, path)

    validation = _validation_report_status(validation_report)
    review_blockers = [
        item["path"] for item in packet_reports
        if item["review_receipt"] is not None and not item["review_receipt"]["receipt_present"]
        and item["review_receipt"].get("outcome") not in review_outcome.NONPASSING
    ]
    review_artifact_reports = []
    for packet in packets:
        if _packet_header_value(packet.read_text(), "Kind") != "review":
            continue
        error = _paired_review_artifact_preflight_error(workstream_id, path, packet)
        review_artifact_reports.append({
            "path": packet.relative_to(repo).as_posix(),
            "status": "pass" if error is None else "blocked",
            "error": error,
        })
    review_artifact_blockers = [item["path"] for item in review_artifact_reports if item["error"]]
    # Local commits ahead of the published branch are expected before finish
    # pushes them. A remote-only advance is drift because finish must reconcile it.
    branch_ready = actual_branch == expected_branch and clean and remote_exists and behind == 0
    blockers: list[dict[str, str]] = []
    if actual_branch != expected_branch:
        blockers.append({"gate": "branch", "detail": f"expected {expected_branch}, found {actual_branch or 'detached'}"})
    if not clean:
        blockers.append({"gate": "clean_worktree", "detail": "worktree has tracked changes"})
    if not remote_exists:
        blockers.append({"gate": "remote_branch", "detail": f"origin/{expected_branch} is not present in cached refs"})
    if behind:
        blockers.append({"gate": "branch_drift", "detail": f"local branch is {behind} commit(s) behind its published branch"})
    if archive_transition_error:
        blockers.append({"gate": "archive_transition_tip", "detail": archive_transition_error})
    blockers.extend({"gate": "task_packet", "detail": str(item)} for item in packet_blockers)
    blockers.extend({"gate": "completion_truth", "detail": str(item)} for item in truth_blockers)
    blockers.extend({"gate": "managed_index", "detail": str(item)} for item in stale_index)
    blockers.extend({"gate": "untracked_artifact", "detail": str(item["path"])} for item in artifact_report)
    if not summary_committed:
        blockers.append({"gate": "summary", "detail": f"{summary_name} is not committed at HEAD"})
    blockers.extend({"gate": "summary_backlink", "detail": url} for url in missing_backlinks)
    blockers.extend({"gate": "review_receipt", "detail": str(item)} for item in review_blockers)
    blockers.extend({"gate": "review_artifact_scope", "detail": str(item["error"])}
                    for item in review_artifact_reports if item["error"])
    if not validation["green"]:
        blockers.append({"gate": "validation", "detail": "report missing, invalid, or non-green"})
    ready = (
        branch_ready and not archive_transition_error and not packet_blockers and not truth_blockers and not stale_index
        and not artifact_report and summary_ok and not review_blockers and not review_artifact_blockers
        and bool(validation["green"])
    )
    return {
        "schema": "custodian.workstream.closeout_preflight.v1",
        "workstream_id": workstream_id,
        "ready_before_sync": ready,
        "blockers": blockers,
        "branch": {
            "expected": expected_branch,
            "actual": actual_branch,
            "head": head,
            "clean": clean,
            "remote_branch_exists": remote_exists,
            "remote_head": remote_head,
            "ahead_of_remote": ahead,
            "behind_remote": behind,
            "origin_main_head_cached": main_head,
            "origin_main_is_ancestor_of_head": main_is_ancestor,
            "drift": (actual_branch != expected_branch or not clean or not remote_exists or behind != 0),
            "unpublished_commits": ahead,
            "sync_required_against_cached_main": not main_is_ancestor,
        },
        "archive_transition": {
            "status": "blocked" if archive_transition_error else "pass",
            "error": archive_transition_error,
        },
        "packets": packet_reports,
        "packet_blockers": packet_blockers,
        "completion_truth_blockers": truth_blockers,
        "managed_index": {"path": (TASK_PACKET_ROOT / "README.md").as_posix(), "stale_archived_entries": stale_index},
        "untracked_artifacts": artifact_report,
        "summary": {
            "path": summary_name,
            "exists": summary_exists,
            "committed_at_head": summary_committed,
            "expected_authoring_chat_urls": expected_urls,
            "missing_authoring_chat_backlinks": missing_backlinks,
            "ready": summary_ok,
        },
        "review_receipt_blockers": review_blockers,
        "review_artifact_checks": review_artifact_reports,
        "review_provenance_warnings": [
            item["path"] for item in packet_reports
            if item["review_receipt"] is not None and item["review_receipt"]["receipt_present"]
            and (not item["review_receipt"]["provenance_complete"]
                 or not item["review_receipt"]["provenance_matches_packet"])
        ],
        "validation": validation,
        "post_sync": {
            "status": "unknown",
            "reason": "This read-only preflight does not fetch or synchronize; latest-main merge, after-sync validation, and race-safe landing are only knowable during finish.",
        },
    }


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
    if target_workstream.count("-review-corrections-") > 1:
        return f"paired review artifact gate rejects nested target lineage for {workstream_id}"
    target_cycle_match = re.fullmatch(r"(.+)-review-corrections-([1-9][0-9]*)", target_workstream)
    lineage_root = target_cycle_match.group(1) if target_cycle_match else target_workstream
    target_cycle = int(target_cycle_match.group(2)) if target_cycle_match else 0
    review_cycle_raw = _packet_header_value(packet_text, "Review cycle")
    max_cycles_raw = _packet_header_value(packet_text, "Max automatic review cycles")
    try:
        review_cycle = int(review_cycle_raw) if review_cycle_raw is not None else target_cycle
        max_cycles = int(max_cycles_raw) if max_cycles_raw is not None else 2
    except ValueError:
        return f"paired review artifact gate requires valid review cycle metadata for {workstream_id}"
    if review_cycle != target_cycle:
        return f"paired review artifact gate review cycle does not match target lineage for {workstream_id}"
    if review_cycle >= max_cycles:
        for path in changed_paths:
            normalized = path.replace("\\", "/")
            if normalized in allowed:
                continue
            return f"paired review artifact gate exceeds maximum correction cycle for {workstream_id}: {normalized}"
        return None
    next_correction = f"{lineage_root}-review-corrections-{review_cycle + 1}"
    correction_id = re.compile(rf"^{re.escape(next_correction)}$")
    paired_review_id = re.compile(rf"^review-{re.escape(next_correction)}$")
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
          _lock_held: bool = False, _publish_trace: bool = True) -> Path:
    repo = (repo or root_repo()).resolve()
    assert_not_legacy_quarantined(repo, workstream_id, "start")
    branch = branch_for(workstream_id)
    trace = _trace
    lock_started = time.monotonic()
    lock_context = nullcontext() if _lock_held else workstream_mutex(repo, workstream_id)
    claim = _claim
    try:
        with lock_context:
            # Recheck after acquiring the per-workstream mutex so a start that
            # raced a quarantine publication cannot resume from a stale prelock check.
            assert_not_legacy_quarantined(repo, workstream_id, "start")
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
            if _publish_trace:
                trace.publish()
            receipt = {"schema": "custodian.dispatch.claim.v1", "result": "started", "workstream": workstream_id,
                       "branch": branch, "worktree": str(path), "verified": True, "run_id": trace.run_id,
                       "trace_ref": trace.diagnostic_ref}
            if not _lock_held:
                print("CUSTODIAN_DISPATCH_RESULT_JSON:" + json.dumps(receipt, sort_keys=True))
            return path
    except (WorkstreamError, WorkflowControlError) as exc:
        if _is_quarantine_fence_error(exc):
            raise
        if trace is None:
            trace = RunTrace.start(repo, workstream_id)
        trace.finish_blocked(str(exc), publish=_publish_trace)
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def _resume_impl(workstream_id: str, repo: Path, report: dict[str, str] | None, trace: RunTrace) -> Path:
    """Explicitly resume an existing clean canonical workstream checkout."""
    with workstream_mutex(repo, workstream_id, trace=trace):
        # Quarantine may have landed after the public resume preflight.
        assert_not_legacy_quarantined(repo, workstream_id, "resume")
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
    assert_not_legacy_quarantined(repo, workstream_id, "resume")
    trace = RunTrace.resume(repo, workstream_id)
    try:
        return _resume_impl(workstream_id, repo, report, trace)
    except Exception as exc:
        if not _is_quarantine_fence_error(exc):
            trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def validation_green(report: Path) -> bool:
    try:
        data = json.loads(report.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkstreamError(f"cannot read validation report {report}: {exc}") from exc
    return _validation_data_green(data)


def _validation_data_green(data: object) -> bool:
    if not isinstance(data, dict) or data.get("schema") != "custodian.validation.result.v1" or not data.get("passed", False):
        return False
    coverage = data.get("coverage")
    if not isinstance(coverage, dict) or coverage.get("complete") is not True:
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
    assert_not_legacy_quarantined(repo, workstream_id, "checkpoint")
    trace = RunTrace.resume(repo, workstream_id)
    try:
        with workstream_mutex(repo, workstream_id, trace=trace):
            assert_not_legacy_quarantined(repo, workstream_id, "checkpoint")
            _checkpoint_impl(workstream_id, remove_worktree, repo, trace)
    except Exception as exc:
        if not _is_quarantine_fence_error(exc):
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


def _review_run_manifest(run_dir: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    continuation = run_dir / "continuation-01"
    for path in sorted(run_dir.rglob("*")):
        if path == continuation or continuation in path.parents:
            continue
        if path.is_symlink():
            raise WorkstreamError(f"refusing symlink in protected review run: {path}")
        if path.is_file():
            result[str(path.relative_to(run_dir))] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def _verify_root_sync_deferral(workstream_id: str, repo: Path,
                               recovery_evidence: Path | None) -> str:
    """Require packet authorization or the one verified recovered review run."""
    if workstream_id in ROOT_SYNC_DEFERRAL_SUPPORT:
        implementation_id = workstream_id.removeprefix("review-")
        packets = _associated_task_packets(repo, implementation_id)
        phrase = "Do not synchronize the root checkout; record synchronization pending."
        authorized = False
        for path in packets:
            packet = parse_packet(str(path), path.read_text(encoding="utf-8"))
            if packet.workstream == implementation_id and packet.task_overrides and phrase in packet.task_overrides:
                authorized = True
                break
        if not authorized:
            raise WorkstreamError("root synchronization deferral lacks the paired recovery packet authorization")
        if recovery_evidence is not None:
            raise WorkstreamError("support workstream root deferral does not accept historical recovery evidence")
        return "task_packet_authorized"

    if workstream_id != INVALID_DISPOSITION_REVIEW:
        raise WorkstreamError(f"root synchronization deferral is not authorized for {workstream_id}")
    if recovery_evidence is None:
        raise WorkstreamError("the recovered review root-sync deferral requires exact continuation evidence")
    if recovery_evidence.is_symlink():
        raise WorkstreamError("root-sync recovery evidence cannot be a symlink")
    common = Path(git("rev-parse", "--path-format=absolute", "--git-common-dir", cwd=repo)).resolve()
    expected_root = (common / "custodian-review-runs" / INVALID_DISPOSITION_REVIEW / INVALID_DISPOSITION_RUN_ID).resolve()
    expected_metadata = expected_root / "continuation-01" / "metadata.json"
    evidence_path = recovery_evidence.resolve()
    if evidence_path != expected_metadata or not evidence_path.is_file():
        raise WorkstreamError("root-sync recovery evidence is not the exact authorized continuation metadata")
    try:
        child = json.loads(evidence_path.read_text(encoding="utf-8"))
        original = json.loads((expected_root / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkstreamError("root-sync recovery evidence is missing or malformed") from exc
    recovery = child.get("invalid_disposition_recovery") if isinstance(child, dict) else None
    if (not isinstance(child, dict) or not isinstance(original, dict)
            or child.get("schema") != "custodian.paired_review_continuation.v1"
            or child.get("workstream") != INVALID_DISPOSITION_REVIEW
            or child.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or child.get("phase") != "coordinator_closeout"
            or original.get("schema") != "custodian.paired_review_run.v1"
            or original.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or original.get("workstream") != INVALID_DISPOSITION_REVIEW
            or original.get("run_dir") != str(expected_root)
            or original.get("phase") != "post_exit_recovery"
            or not isinstance(recovery, dict)
            or recovery.get("schema") != "custodian.paired_review_invalid_disposition_recovery.v1"
            or recovery.get("workstream") != INVALID_DISPOSITION_REVIEW
            or recovery.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or recovery.get("continuation") != "continuation-01"
            or recovery.get("original_disposition_sha256") != INVALID_DISPOSITION_SHA256
            or not re.fullmatch(r"[0-9a-f]{64}", str(recovery.get("repaired_disposition_sha256", "")))
            or not re.fullmatch(r"[0-9a-f]{64}", str(recovery.get("target_receipt_sha256", "")))
            or recovery.get("root_sync_pending") is not True
            or child.get("run_evidence_sha256") != _review_run_manifest(expected_root)):
        raise WorkstreamError("exact recovered review identity, preservation digest, or evidence manifest failed")
    worktree = Path(str(child.get("worktree", ""))).resolve()
    for relative, expected_sha in (
        (INVALID_DISPOSITION_REVIEW_PACKET, recovery["repaired_disposition_sha256"]),
        (INVALID_DISPOSITION_TARGET_PACKET, recovery["target_receipt_sha256"]),
    ):
        local_path = worktree / relative
        if local_path.is_file() and not local_path.is_symlink():
            raw = local_path.read_bytes()
        else:
            shown = subprocess.run(["git", "show", f"origin/main:{relative}"], cwd=repo,
                                   capture_output=True, check=False)
            if shown.returncode:
                raise WorkstreamError(f"recovered review artifact is absent from worktree and origin/main: {relative}")
            raw = shown.stdout
        if hashlib.sha256(raw).hexdigest() != expected_sha:
            raise WorkstreamError(f"recovered review artifact digest changed before closeout: {relative}")
    return "verified_invalid_disposition_recovery"


def _teardown_workstream(workstream_id: str, branch: str, repo: Path, path: Path, head: str,
                         *, defer_root_sync: bool = False) -> None:
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

    if defer_root_sync:
        print("persistent root synchronization pending: explicitly deferred by verified task authorization")
        print(f"finished {branch}; verified {head} reachable from origin/main; remote and local workstream removed")
        return

    _sync_persistent_main_checkout(admin_repo)
    print(f"finished {branch}; verified {head} reachable from origin/main; remote and local workstream removed")


def _sync_persistent_main_checkout(repo: Path) -> None:
    """Run the safe root synchronization independently of claim teardown."""
    main_root = next(
        (Path(item["worktree"]).resolve() for item in worktree_records(repo)
         if item.get("branch") == "refs/heads/main"),
        None,
    )
    if main_root is None:
        print("persistent root synchronization pending: no attached main checkout")
        return
    try:
        result = apply_profiles([ROOT_PROFILE], main_root)[0]
        print("persistent main checkout: " + format_result(result))
    except Exception as error:
        # Landing is complete; root sync remains pending with a safe, actionable reason.
        print(f"persistent root synchronization pending: {error}")


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


def _finish_impl(workstream_id: str, validation_report: Path, validation_report_after_sync: Path | None = None,
                 repo: Path | None = None, trace: RunTrace | None = None, *,
                 defer_root_sync: bool = False, recovery_evidence: Path | None = None,
                 defer_teardown: bool = False) -> str:
    repo = (repo or root_repo()).resolve()
    if defer_root_sync:
        deferral_kind = _verify_root_sync_deferral(workstream_id, repo, recovery_evidence)
        if trace:
            trace.record("root_sync_deferred", authorization=deferral_kind,
                         evidence=str(recovery_evidence) if recovery_evidence else None)
    elif recovery_evidence is not None:
        raise WorkstreamError("recovery evidence is only valid with --defer-root-sync")
    if defer_teardown and workstream_id not in {INVALID_DISPOSITION_REVIEW, ADVANCED_HEAD_PASS_REVIEW}:
        raise WorkstreamError("deferred teardown is limited to the two exact authorized review recoveries")
    if defer_teardown and workstream_id == INVALID_DISPOSITION_REVIEW and not defer_root_sync:
        raise WorkstreamError("invalid-disposition deferred teardown requires its verified root-sync deferral")
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

    archive_tip_error = _archive_transition_tip_error(workstream_id, path)
    if archive_tip_error:
        raise WorkstreamError(archive_tip_error)

    git("push", "-u", "origin", branch, cwd=path)
    fetch(path)

    if task_head_reachable_from_main(path):
        # ALREADY_LANDED: this exact task history is already on origin/main (a
        # prior finish attempt landed it but did not finish teardown, or it
        # merged in some other way). Skip sync/land entirely and go straight
        # to verified teardown; do not rewrite or remerge task history.
        head = git("rev-parse", "HEAD", cwd=path)
        if defer_teardown:
            _sync_persistent_main_checkout(repo)
            print(f"verified {head} reachable from origin/main; teardown pending independent receipt verification")
            if trace: trace.record("teardown_deferred", branch=branch, head=head)
            return "teardown_pending"
        if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
        _teardown_workstream(workstream_id, branch, repo, path, head, defer_root_sync=defer_root_sync)
        if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())
        return "finished"

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
        if defer_teardown:
            _sync_persistent_main_checkout(repo)
            print(f"verified {head} reachable from origin/main; teardown pending independent receipt verification")
            if trace: trace.record("teardown_deferred", branch=branch, head=head)
            return "teardown_pending"
        if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
        _teardown_workstream(workstream_id, branch, repo, path, head, defer_root_sync=defer_root_sync)
        if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())
        return "finished"

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
    if defer_teardown:
        _sync_persistent_main_checkout(repo)
        print(f"verified {head} reachable from origin/main; teardown pending independent receipt verification")
        if trace: trace.record("teardown_deferred", branch=branch, head=head)
        return "teardown_pending"
    if trace: trace.record("teardown_started", branch=branch, head=head, worktree=str(path))
    _teardown_workstream(workstream_id, branch, repo, path, head, defer_root_sync=defer_root_sync)
    if trace: trace.record("teardown_completed", branch=branch, head=head, worktree_removed=not path.exists())
    return "finished"


def finish(workstream_id: str, validation_report: Path, validation_report_after_sync: Path | None = None,
           repo: Path | None = None, *, defer_root_sync: bool = False,
           recovery_evidence: Path | None = None, defer_teardown: bool = False) -> None:
    repo = (repo or root_repo()).resolve()
    assert_not_legacy_quarantined(repo, workstream_id, "finish")
    trace = RunTrace.resume(repo, workstream_id)
    try:
        with workstream_mutex(repo, workstream_id, trace=trace):
            assert_not_legacy_quarantined(repo, workstream_id, "finish")
            trace.record("finish_started", validation_report=str(validation_report), after_sync_report=str(validation_report_after_sync) if validation_report_after_sync else None)
            outcome = _finish_impl(workstream_id, validation_report, validation_report_after_sync, repo, trace,
                                   defer_root_sync=defer_root_sync, recovery_evidence=recovery_evidence,
                                   defer_teardown=defer_teardown)
            trace.record("finish_completed", outcome=outcome)
            trace.complete(outcome, clear_active=True)
    except Exception as exc:
        if not _is_quarantine_fence_error(exc):
            trace.finish_blocked(str(exc))
        raise WorkstreamError(f"{exc} [run_id={trace.run_id}; trace_ref={trace.diagnostic_ref}]") from exc


def preflight(workstream_id: str, validation_report: Path | None = None, repo: Path | None = None) -> dict[str, object]:
    """Resolve an already-attached workstream and print a read-only readiness report."""
    repo = (repo or root_repo()).resolve()
    branch = branch_for(workstream_id)
    candidates = [Path(item["worktree"]).resolve() for item in worktree_records(repo)
                  if item.get("branch") == f"refs/heads/{branch}"]
    path = repo if git("branch", "--show-current", cwd=repo) == branch else (candidates[0] if candidates else None)
    if path is None:
        raise WorkstreamError(f"preflight found no attached worktree for {branch}; no state was changed")
    report = closeout_preflight(workstream_id, path, validation_report)
    return report


def status(workstream_id: str | None = None, repo: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    records = worktree_records(repo)
    for item in records:
        branch = item.get("branch", "detached")
        if workstream_id and branch != f"refs/heads/{branch_for(workstream_id)}":
            continue
        path = Path(item["worktree"])
        print(f"{branch}\t{'clean' if status_clean(path) else 'dirty'}\t{path}")
    report = storage_report(repo, records=records)
    scratch = report["scratch"]
    used = scratch["used_bytes"] / (1024 ** 3)
    total = scratch["total_bytes"] / (1024 ** 3)
    free = scratch["free_bytes"] / (1024 ** 3)
    print(
        "scratch\t%s\t%s (%s, %.2f/%.2f GiB used, %.2f GiB free)" % (
            scratch["fstype"], scratch["path"], scratch["mount"], used, total, free,
        )
    )
    for item in report["ram_backed_worktrees"]:
        print(
            "PROTECTED ram-backed worktree\t%s\t%s\t%s (%s)" % (
                item["branch"], item["path"], item["fstype"], ", ".join(item["protected_reasons"]),
            )
        )
    if not report["ram_backed_worktrees"]:
        print("RAM-backed worktrees\tnone")
    print("storage report is read-only; deletions performed: 0")
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
    p.add_argument("--defer-root-sync", action="store_true",
                    help="defer persistent root synchronization when the exact packet/recovery evidence authorizes it")
    p.add_argument("--defer-root-sync-evidence", type=Path,
                    help="exact continuation metadata required for the one recovered historical review")
    p.add_argument("--defer-teardown", action="store_true",
                    help="leave the exact recovered review claim/worktree intact for independent post-land verification")
    p = subs.add_parser("preflight"); p.add_argument("workstream_id"); p.add_argument("--validation-report", type=Path); p.add_argument("--json", action="store_true")
    subs.add_parser("gc")
    args = parser.parse_args()
    try:
        if args.command == "start": start(args.workstream_id, agent=args.agent)
        elif args.command == "resume": print(f"resumed worktree: {resume(args.workstream_id)}")
        elif args.command == "status": status(args.workstream_id)
        elif args.command == "checkpoint": checkpoint(args.workstream_id, args.remove_worktree)
        elif args.command == "finish":
            finish(args.workstream_id, args.validation_report, args.validation_report_after_sync,
                   defer_root_sync=args.defer_root_sync,
                   recovery_evidence=args.defer_root_sync_evidence,
                   defer_teardown=args.defer_teardown)
        elif args.command == "preflight":
            result = preflight(args.workstream_id, args.validation_report)
            if args.json:
                print(json.dumps(result, sort_keys=True, indent=2))
            else:
                print(f"closeout preflight: {'READY' if result['ready_before_sync'] else 'BLOCKED'} (before final sync)")
                print(json.dumps(result, sort_keys=True, indent=2))
        else: gc()
        return 0
    except WorkstreamError as error:
        print(f"workstream: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
