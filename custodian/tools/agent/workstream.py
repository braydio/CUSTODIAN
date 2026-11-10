#!/usr/bin/env python3
"""Manage disposable CUSTODIAN agent workstreams and their safe landing lifecycle."""

from __future__ import annotations

import argparse
import difflib
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
from pathlib import Path, PurePosixPath

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import (
    TRACE_SCHEMA, TRACE_VERSION, RemoteClaim, RunTrace, WorkflowControlError, acquire_remote_claim,
    common_dir, common_mutex, find_local_trace, release_remote_claim, resolve_agent_id,
    workstream_mutex,
)
from persistent_checkout_sync import ROOT_PROFILE, apply_profiles, format_result
from task_packet_contract import (
    completion_truth_required, parse_completion_truth, parse_packet,
)
from review_receipt_delta import read_git_text, resolve_target_implementation_commit, verify_review_receipt_delta
import review_outcome
import worktree_provisioning

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

# RC-119 authorizes this one immutable, reviewer-preserving administrative
# correction between the original archive transition and main synchronization.
# Every value is content-addressed from the two existing commits; this is not a
# general exception for post-archive metadata edits.
ARCHIVE_METADATA_FOLLOWUP = {
    "workstream": "review-agent-paired-review-runner-profile-summary-coverage-v1",
    "archive": "704a1fbb3df6deae64e06291769eabd1d48f7eb2",
    "archive_parent": "e1bff4eb3360e7f0fcdbc5bb67fa86bc2b600f4f",
    "archive_tree": "14574039da27513ecaad7b02aeb08f75d2a11ae4",
    "archive_packet_blob_oid": "16307c7f771abe5587ccd95baa6f69e239544e59",
    "archive_packet_sha256": "01398f7950b9cbf617d97204e03e041cb6df99983ac187e8b66a3f56073c8764",
    "correction": "81fb8ca935bb2d5f9f00f18d547c185035e7b8dd",
    "correction_tree": "58e639a24470c27a1999a796fd0ae53d5ed778a5",
    "corrected_packet_blob_oid": "b3d842692d5b31871f86b03b6a830dee1734be1a",
    "corrected_packet_sha256": "b42d92e3d40815a37ec17fa5a776e480950d99520a253f1e0500b859af5315d8",
    "packet": (
        "custodian/docs/ai_context/task_packets/archived/"
        "REVIEW_AGENT_PAIRED_REVIEW_RUNNER_PROFILE_SUMMARY_COVERAGE_V1.md"
    ),
}



def git(*args: str, cwd: Path | None = None, check: bool = True,
        env: dict[str, str] | None = None) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True, env=env)
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


def _authenticated_managed_index_reconciliation(
    host_validation, repo: Path, first_parent: str, second_parent: str,
    merge_commit: str, first: bytes, second: bytes, merged: bytes,
) -> bool:
    """Accept exact additive entries or completed-main archival removals only."""
    return (
        host_validation._managed_packet_index_additive_reconciliation(first, second, merged)
        or host_validation._managed_packet_index_archival_reconciliation(
            repo, first_parent, second_parent, merge_commit,
        )
    )


def _work_surface_paths(packet_text: str) -> set[str]:
    """Extract only explicit repository-file tokens from a packet Work surface."""
    field = re.search(r"(?im)^- Work surface:\s*(.+)$", packet_text)
    if field is None:
        return set()
    declared: set[str] = set()
    raw = field.group(1)
    path_pattern = re.compile(r"(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+")

    def add(candidate: str) -> None:
        path = PurePosixPath(candidate)
        if (not candidate or "\\" in candidate or path.is_absolute()
                or not path_pattern.fullmatch(candidate)
                or any(part in {"", ".", ".."} for part in path.parts)):
            return
        declared.add(path.as_posix())

    for candidate in re.findall(r"`([^`]+)`", raw):
        add(candidate.strip())
    without_backticks = re.sub(r"`[^`]+`", " ", raw)
    for segment in re.split(r"[;,]|\s+\+\s+", without_backticks):
        match = re.match(
            r"^\s*((?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+)(?=$|\s)",
            segment,
        )
        if match:
            add(match.group(1).rstrip("."))
    return declared


def _git_tree_entries(repo: Path, revision: str) -> dict[str, tuple[str, str, str]] | None:
    result = subprocess.run(
        ["git", "ls-tree", "-r", "-z", "--full-tree", revision],
        cwd=repo, capture_output=True,
    )
    if result.returncode:
        return None
    entries: dict[str, tuple[str, str, str]] = {}
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        metadata, separator, raw_path = raw.partition(b"\t")
        fields = metadata.split()
        if not separator or len(fields) != 3:
            return None
        try:
            path = raw_path.decode("utf-8")
            entries[path] = (fields[0].decode("ascii"), fields[1].decode("ascii"),
                             fields[2].decode("ascii"))
        except UnicodeDecodeError:
            return None
    return entries


def _git_blob(repo: Path, revision: str, path: str) -> bytes | None:
    result = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=repo,
                            capture_output=True)
    return result.stdout if result.returncode == 0 else None


def _managed_index_split(raw: bytes) -> tuple[bytes, list[bytes], bytes] | None:
    start = b"<!-- task_packet_index:managed:start -->"
    end = b"<!-- task_packet_index:managed:end -->"
    if raw.count(start) != 1 or raw.count(end) != 1:
        return None
    lines = raw.splitlines(keepends=True)
    start_lines = [i for i, line in enumerate(lines) if line.rstrip(b"\r\n") == start]
    end_lines = [i for i, line in enumerate(lines) if line.rstrip(b"\r\n") == end]
    if (len(start_lines) != 1 or len(end_lines) != 1
            or end_lines[0] <= start_lines[0]
            or lines[start_lines[0]] != start + b"\n"
            or lines[end_lines[0]] != end + b"\n"):
        return None
    first, last = start_lines[0], end_lines[0]
    return b"".join(lines[:first + 1]), lines[first + 1:last], b"".join(lines[last:])


def _managed_conflict_lines(raw: bytes, row: bytes) -> tuple[list[bytes], tuple[int, int]] | None:
    lines = raw.splitlines(keepends=True)
    openers = [i for i, line in enumerate(lines) if line.startswith(b"<<<<<<< ")]
    separators = [i for i, line in enumerate(lines) if line.rstrip(b"\r\n") == b"======="]
    closers = [i for i, line in enumerate(lines) if line.startswith(b">>>>>>> ")]
    managed = _managed_index_split(raw)
    if (managed is None or len(openers) != 1 or len(separators) != 1 or len(closers) != 1
            or not (openers[0] < separators[0] < closers[0])
            or not lines[openers[0]].endswith(b"\n")
            or not lines[separators[0]].endswith(b"\n")
            or not lines[closers[0]].endswith(b"\n")
            or any(b"<<<<<<< " in line or b"=======" in line or b">>>>>>> " in line
                   for line in lines if line not in {
                       lines[openers[0]], lines[separators[0]], lines[closers[0]],
                   })):
        return None
    start_at = len(b"".join(lines[:openers[0]]))
    close_at = len(b"".join(lines[:closers[0] + 1]))
    managed_start = len(managed[0]) - len(b"<!-- task_packet_index:managed:start -->\n")
    managed_end = len(raw) - len(managed[2])
    if not (managed_start < start_at < close_at <= managed_end):
        return None
    if lines[openers[0] + 1:separators[0]] or lines[separators[0] + 1:closers[0]] != [row + b"\n"]:
        return None
    normalized = list(lines)
    normalized[openers[0]] = b"<<<<<<< LABEL\n"
    normalized[closers[0]] = b">>>>>>> LABEL\n"
    return normalized, (openers[0], closers[0] + 1)


def _authenticated_managed_index_conflict(
    repo: Path, workstream_id: str, first_parent: str, second_parent: str,
    merge_commit: str, archived_packet: str,
) -> bytes | None:
    """Authenticate one real, managed-index-only conflict merge and its exact repair bytes."""
    readme = f"{TASK_PACKET_ROOT}/README.md"
    filename = Path(archived_packet).name
    active_packet = f"{TASK_PACKET_ROOT}/{filename}"
    entries = [_git_tree_entries(repo, revision) for revision in
               (first_parent, second_parent, merge_commit)]
    if any(tree is None for tree in entries):
        return None
    first_tree, main_tree, merged_tree = entries
    if (first_tree.get(archived_packet, (None,))[0] != "100644"
            or active_packet in first_tree
            or main_tree.get(active_packet, (None,))[0] != "100644"
            or merged_tree.get(archived_packet, (None,))[0] != "100644"
            or active_packet in merged_tree
            or any(tree.get(readme, (None,))[0] != "100644" for tree in entries)):
        return None
    archived_text = _git_blob(repo, first_parent, archived_packet)
    active_text = _git_blob(repo, second_parent, active_packet)
    if archived_text is None or active_text is None:
        return None
    try:
        archived_text_str = archived_text.decode("utf-8")
        active_text_str = active_text.decode("utf-8")
    except UnicodeDecodeError:
        return None
    archived = parse_packet(archived_packet, archived_text_str)
    active = parse_packet(active_packet, active_text_str)
    if (archived.error or active.error or archived.workstream != workstream_id
            or active.workstream != workstream_id or active.status != "ready"
            or active.dispatch != "auto"):
        return None
    first_readme = _git_blob(repo, first_parent, readme)
    main_readme = _git_blob(repo, second_parent, readme)
    merged_readme = _git_blob(repo, merge_commit, readme)
    if first_readme is None or main_readme is None or merged_readme is None:
        return None
    first_parts, main_parts = _managed_index_split(first_readme), _managed_index_split(main_readme)
    if first_parts is None or main_parts is None:
        return None
    first_rows = [line for line in first_parts[1] if line.strip()]
    main_rows = [line for line in main_parts[1] if line.strip()]
    row_prefix = f"- `{filename}` — ".encode("utf-8")
    target_rows = [line for line in main_rows if line.startswith(row_prefix)]
    if len(target_rows) != 1 or any(line.startswith(row_prefix) for line in first_rows):
        return None
    row = target_rows[0].removesuffix(b"\n")

    expected = subprocess.run(
        ["git", "merge-tree", "--write-tree", first_parent, second_parent],
        cwd=repo, text=True, capture_output=True,
    )
    chunks = expected.stdout.split("\n\n", 1)
    first_lines = chunks[0].splitlines() if chunks else []
    if expected.returncode != 1 or len(first_lines) != 4:
        return None
    expected_tree = first_lines[0]
    stage_rows = []
    for line in first_lines[1:]:
        metadata, separator, path = line.partition("\t")
        fields = metadata.split()
        if not separator or len(fields) != 3 or fields[2] not in {"1", "2", "3"}:
            return None
        stage_rows.append((fields[0], fields[1], fields[2], path))
    if {row[3] for row in stage_rows} != {readme}:
        return None
    merge_base = git("merge-base", first_parent, second_parent, cwd=repo, check=False)
    base_tree = _git_tree_entries(repo, merge_base) if merge_base else None
    if base_tree is None:
        return None
    expected_stages = set()
    for stage, tree in (("1", base_tree), ("2", first_tree), ("3", main_tree)):
        entry = tree.get(readme)
        if entry is None or entry[0] != "100644" or entry[1] != "blob":
            return None
        expected_stages.add((entry[0], entry[2], stage, readme))
    if len(expected_stages) != 3 or set(stage_rows) != expected_stages:
        return None
    expected_entries = _git_tree_entries(repo, expected_tree)
    if expected_entries is None or expected_entries.get(readme, (None,))[0] != "100644":
        return None
    if ({key: value for key, value in expected_entries.items() if key != readme}
            != {key: value for key, value in merged_tree.items() if key != readme}):
        return None
    expected_readme = _git_blob(repo, expected_tree, readme)
    if expected_readme is None:
        return None
    actual_conflict = _managed_conflict_lines(merged_readme, row)
    expected_conflict = _managed_conflict_lines(expected_readme, row)
    if (actual_conflict is None or expected_conflict is None
            or actual_conflict[0] != expected_conflict[0]):
        return None
    actual_lines = merged_readme.splitlines(keepends=True)
    open_index, end_index = actual_conflict[1]
    return b"".join(actual_lines[:open_index] + actual_lines[end_index:])


def _managed_index_is_current(repo: Path) -> bool:
    for tools_path in (repo / "custodian/tools", repo / "custodian/tools/validation"):
        if str(tools_path) not in sys.path:
            sys.path.insert(0, str(tools_path))
    try:
        import task_packet_index
        return task_packet_index.check(repo)[0]
    except Exception:
        return False


def _source_span_sync_merge_witness_error(workstream_id: str, path: Path,
                                          source_head: str, trace: RunTrace | None, *,
                                          require_final_noop: bool = False,
                                          allow_pending_after_sync: bool = False) -> str | None:
    """Reject pre-archive sync merges that lack the source-span trace proof."""
    if trace is None or not trace.path.is_file():
        return "source-span synchronization merge provenance requires the active lifecycle trace"
    try:
        events = [json.loads(line) for line in trace.path.read_text().splitlines() if line.strip()]
    except (OSError, ValueError, TypeError) as exc:
        return f"cannot read source-span lifecycle trace: {exc}"
    if not events:
        return "source-span lifecycle trace is empty"
    if any(not isinstance(event, dict) for event in events):
        return "source-span lifecycle trace contains a non-object event"
    active_packet = trace.packet
    if any(event.get("schema") != TRACE_SCHEMA
           or type(event.get("schema_version")) is not int
           or event.get("schema_version") != TRACE_VERSION
           or not isinstance(event.get("data"), dict)
           or event.get("workstream") != workstream_id
           or event.get("run_id") != trace.run_id for event in events):
        return "source-span lifecycle trace schema, data shape, or identity is inconsistent"

    def diagnostic_trace_prefix_event_count() -> int | None:
        ref = f"refs/custodian/diagnostics/{workstream_id}/{trace.run_id}"
        history = subprocess.run(["git", "rev-list", "--reverse", ref], cwd=path,
                                 text=True, capture_output=True)
        if history.returncode or not history.stdout.splitlines():
            return None
        previous_commit = None
        previous_blob = b""
        for commit in history.stdout.splitlines():
            parent_line = subprocess.run(["git", "rev-list", "--parents", "-n", "1", commit],
                                         cwd=path, text=True, capture_output=True)
            entries = subprocess.run(["git", "ls-tree", "-r", "-z", commit], cwd=path,
                                     capture_output=True)
            if (parent_line.returncode or entries.returncode
                    or (previous_commit is None and len(parent_line.stdout.split()) != 1)
                    or (previous_commit is not None
                        and parent_line.stdout.split() != [commit, previous_commit])):
                return None
            rows = [row for row in entries.stdout.split(b"\0") if row]
            if len(rows) != 1 or rows[0].split(b"\t", 1)[1] != b"trace.jsonl":
                return None
            fields = rows[0].split(b"\t", 1)[0].split()
            if len(fields) != 3 or fields[:2] != [b"100644", b"blob"]:
                return None
            blob = subprocess.run(["git", "cat-file", "blob", fields[2].decode()],
                                  cwd=path, capture_output=True)
            if blob.returncode or not blob.stdout.startswith(previous_blob):
                return None
            previous_blob = blob.stdout
            previous_commit = commit
        try:
            local = trace.path.read_bytes()
        except OSError:
            return None
        if not local.startswith(previous_blob):
            return None
        return len(previous_blob.splitlines())

    resumes = [(i, event) for i, event in enumerate(events)
               if event.get("event") == "worktree_resumed"]
    main = git("rev-parse", "origin/main", cwd=path, check=False)
    if not main:
        return "cannot authenticate source-span synchronization parents without origin/main"

    claims = [(i, event) for i, event in enumerate(events)
              if event.get("event") == "remote_claim_acquired"]
    publications = [(i, event) for i, event in enumerate(events)
                    if event.get("event") == "worktree_published"]
    v2_acquisitions = [(i, event) for i, event in enumerate(events)
                       if event.get("event") == "v2_turn_acquired"]
    v2_checkpoints = [(i, event) for i, event in enumerate(events)
                      if event.get("event") == "v2_turn_checkpointed"]
    if not claims and not publications and v2_acquisitions and v2_checkpoints:
        if len(v2_acquisitions) != 1 or len(v2_checkpoints) != 1:
            return "V2 lifecycle trace has duplicate acquisition or initial checkpoint evidence"
        acquired_pos, acquired_event = v2_acquisitions[0]
        checkpoint_pos, checkpoint_event = v2_checkpoints[0]
        acquired = acquired_event.get("data", {})
        checkpoint = checkpoint_event.get("data", {})
        receipt_path = Path(str(acquired.get("receipt", "")))
        expected_receipt_dir = common_dir(path) / "custodian-turn-dispatcher-v2" / "acquisitions"
        try:
            if not receipt_path.resolve().is_relative_to(expected_receipt_dir.resolve()):
                return "V2 acquisition receipt is outside its private Git common directory"
            acquisition = json.loads(receipt_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError, RuntimeError, ValueError):
            return "V2 acquisition receipt is missing or malformed"
        branch = branch_for(workstream_id)
        source_base = acquisition.get("source_sha") if isinstance(acquisition, dict) else None
        checkpoint_head = checkpoint.get("head")
        if (acquisition.get("schema") != "custodian.turn_dispatcher_v2.acquisition.v1"
                or acquisition.get("workstream") != workstream_id
                or acquisition.get("checkout") != str(path.resolve())
                or acquired.get("checkout") != str(path.resolve())
                or acquisition.get("branch") != branch
                or acquired.get("remote_branch") != branch
                or checkpoint.get("branch") != branch
                or checkpoint.get("remote_branch") != branch
                or checkpoint_pos <= acquired_pos
                or not isinstance(source_base, str)
                or re.fullmatch(r"[0-9a-f]{40,64}", source_base) is None
                or not isinstance(checkpoint_head, str)
                or re.fullmatch(r"[0-9a-f]{40,64}", checkpoint_head) is None
                or subprocess.run(["git", "merge-base", "--is-ancestor", source_base, source_head],
                                  cwd=path, capture_output=True).returncode
                or subprocess.run(["git", "merge-base", "--is-ancestor", checkpoint_head, source_head],
                                  cwd=path, capture_output=True).returncode):
            return "V2 acquisition or checkpoint receipt does not prove this exact workstream source span"
        packet = acquisition.get("packet")
        if acquisition.get("definition_kind") == "published-packet":
            if packet != trace.packet or any(event.get("packet") != packet for event in events):
                return "V2 trace does not pin the authenticated task packet"
        elif trace.packet not in (None, ""):
            return "V2 owner-authorized trace unexpectedly claims a published task packet"
        main = git("rev-parse", "origin/main", cwd=path, check=False)
        if (not main or subprocess.run(["git", "merge-base", "--is-ancestor", source_base, main],
                                       cwd=path, capture_output=True).returncode):
            return "V2 acquisition base is not authenticated on current origin/main"
        history = subprocess.run(["git", "rev-list", "--first-parent", "--reverse",
                                  f"{source_base}..{source_head}"], cwd=path,
                                 text=True, capture_output=True)
        if history.returncode:
            return "cannot enumerate V2 source-span first-parent history"
        previous = source_base
        for commit in history.stdout.splitlines():
            parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
            if not parents or parents[0] != previous:
                return f"V2 source-span commit {commit} breaks first-parent continuity"
            if len(parents) == 1:
                previous = commit
                continue
            if len(parents) != 2:
                return f"V2 source-span merge {commit} is not a two-parent synchronization"
            first_parent, second_parent = parents
            if subprocess.run(["git", "merge-base", "--is-ancestor", second_parent, main],
                              cwd=path, capture_output=True).returncode:
                return f"V2 source-span merge {commit} has a second parent outside origin/main"
            expected = subprocess.run(["git", "merge-tree", "--write-tree", first_parent, second_parent],
                                      cwd=path, text=True, capture_output=True)
            expected_tree = expected.stdout.splitlines()[0].strip() if expected.stdout.splitlines() else ""
            if (expected.returncode or not expected_tree
                    or git("rev-parse", f"{commit}^{{tree}}", cwd=path) != expected_tree):
                return f"V2 source-span merge {commit} differs from Git's deterministic merge tree"
            matching_checkpoints = [event for event in events
                                    if event.get("event") == "checkpoint_completed"
                                    and event.get("data", {}).get("remote_head") == first_parent
                                    and event.get("data", {}).get("branch") == branch
                                    and event.get("data", {}).get("removed") is False]
            matching_syncs = [event for event in events
                              if event.get("event") == "main_sync"
                              and event.get("data", {}).get("changed") is True
                              and event.get("data", {}).get("head") == commit
                              and event.get("data", {}).get("main_sha") == second_parent]
            if len(matching_checkpoints) != 1 or len(matching_syncs) != 1:
                return f"V2 source-span merge {commit} lacks unique checkpoint and main-sync witnesses"
            if events.index(matching_checkpoints[0]) <= checkpoint_pos or events.index(matching_syncs[0]) <= events.index(matching_checkpoints[0]):
                return f"V2 source-span merge {commit} lifecycle witnesses are out of order"
            previous = commit
        return None
    if len(claims) != 1 or len(publications) != 1:
        common_base = git("merge-base", source_head, main, cwd=path, check=False)
        if common_base:
            fallback_history = subprocess.run(
                ["git", "rev-list", "--first-parent", "--reverse", f"{common_base}..{source_head}"],
                cwd=path, text=True, capture_output=True,
            )
            if (fallback_history.returncode == 0
                    and not any(len(git("rev-list", "--parents", "-n", "1", commit,
                                        cwd=path).split()) > 2
                                for commit in fallback_history.stdout.splitlines())):
                return None
        return "source-span lifecycle trace lacks one exact claim and published-worktree identity"
    claim_pos, claim_event = claims[0]
    published_pos, published_event = publications[0]
    claim = claim_event.get("data")
    publication = published_event.get("data")
    branch = branch_for(workstream_id)
    claim_oid = claim.get("claim_oid") if isinstance(claim, dict) else None
    claim_base = claim.get("main_sha") if isinstance(claim, dict) else None
    claim_agent = claim_event.get("agent")
    claim_pid = claim_event.get("pid")
    expected_local_ref = f"refs/custodian/claims/{workstream_id}/{trace.run_id}"
    expected_remote_ref = f"refs/heads/dispatch-claims/{workstream_id}"
    claim_oid_valid = (isinstance(claim_oid, str)
                       and re.fullmatch(r"[0-9a-f]{40,64}", claim_oid) is not None)
    claim_base_valid = (isinstance(claim_base, str)
                        and re.fullmatch(r"[0-9a-f]{40,64}", claim_base) is not None)
    resolved_claim = (git("rev-parse", "--verify", f"{claim_oid}^{{commit}}",
                          cwd=path, check=False)
                      if claim_oid_valid else "")
    claim_parents = (git("rev-list", "--parents", "-n", "1", claim_oid,
                         cwd=path, check=False).split() if claim_oid_valid else [])
    claim_subject = (git("show", "-s", "--format=%s", claim_oid, cwd=path, check=False)
                     if claim_oid_valid else "")
    claim_tree = (git("rev-parse", f"{claim_oid}^{{tree}}", cwd=path, check=False)
                  if claim_oid_valid else "")
    base_tree = (git("rev-parse", f"{claim_base}^{{tree}}", cwd=path, check=False)
                 if claim_base_valid else "")
    claim_subject_match = re.fullmatch(
        rf"workstream claim {re.escape(workstream_id)} ([^:\s]+):([0-9]+):{re.escape(trace.run_id)}",
        claim_subject,
    )
    published_worktree = publication.get("worktree") if isinstance(publication, dict) else None
    try:
        published_path_matches = (
            isinstance(published_worktree, str)
            and Path(published_worktree).is_absolute()
            and os.path.normpath(published_worktree) == published_worktree
            and Path(published_worktree).resolve() == path.resolve()
        )
    except (OSError, RuntimeError, ValueError):
        published_path_matches = False
    if (not isinstance(claim, dict) or not isinstance(publication, dict)
            or claim.get("remote_ref") != expected_remote_ref
            or claim.get("local_ref") != expected_local_ref
            or not claim_oid_valid
            or resolved_claim != claim_oid
            or not claim_base_valid
            or claim_parents != [claim_oid, claim_base]
            or claim_subject_match is None
            or (claim_agent is not None and claim_agent != claim_subject_match.group(1))
            or isinstance(claim_pid, bool) or not isinstance(claim_pid, int) or claim_pid <= 0
            or claim_pid != int(claim_subject_match.group(2) if claim_subject_match else -1)
            or claim_tree != base_tree
            or publication.get("branch") != branch
            or publication.get("head") != claim_base
            or publication.get("upstream") != claim_base
            or publication.get("clean") is not True
            or not published_path_matches
            or claim_pos >= published_pos):
        return "source-span lifecycle claim commit or published-worktree identity is invalid"

    source_base = claim_base
    merge_history_probe = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{claim_base}..{source_head}"],
        cwd=path, text=True, capture_output=True,
    )
    probe_commits = merge_history_probe.stdout.splitlines()
    inherited_resume_positions = [
        index for index, event in resumes
        if isinstance(event.get("data"), dict) and event["data"].get("head") in probe_commits
    ]
    has_uncheckpointed_resume_merge = (
        merge_history_probe.returncode == 0
        and not any(event.get("event") == "checkpoint_completed" for event in events)
        and bool(inherited_resume_positions)
        and any(len(git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()) > 2
                for commit in probe_commits)
    )
    if has_uncheckpointed_resume_merge:
        published_event_count = diagnostic_trace_prefix_event_count()
        if published_event_count is None:
            return "source-span inherited resume requires an append-only published diagnostic trace"
        if any(index >= published_event_count for index in inherited_resume_positions):
            return "source-span inherited resume is absent from the published diagnostic trace"
    if subprocess.run(["git", "merge-base", "--is-ancestor", source_base, source_head],
                      cwd=path, capture_output=True).returncode:
        return "source-span claim base is not an ancestor of its archive transition"
    history = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{source_base}..{source_head}"],
        cwd=path, text=True, capture_output=True,
    )
    if history.returncode:
        return "cannot enumerate the source-span first-parent history"
    history_commits = history.stdout.splitlines()
    merge_commits = [
        commit for commit in history_commits
        if len(git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()) > 2
    ]
    if not merge_commits:
        return None
    if active_packet is None:
        if any(event.get("packet") not in (None, "") for event in events):
            return "source-span packetless lifecycle trace contains packet metadata"
        try:
            associated_packets = _associated_task_packets(root_repo(path), workstream_id)
        except WorkstreamError as exc:
            return f"cannot verify packetless source-span ownership: {exc}"
        if associated_packets:
            return "source-span packetless lifecycle trace conflicts with an associated task packet"
    elif (not isinstance(active_packet, str)
            or not active_packet.startswith(f"{TASK_PACKET_ROOT}/")
            or any(event.get("packet") != active_packet for event in events)):
        return "source-span lifecycle trace does not pin the active task packet"

    if subprocess.run(["git", "merge-base", "--is-ancestor", source_base, main],
                      cwd=path, capture_output=True).returncode:
        return "source-span claim base is not an ancestor of origin/main"

    checkpoints = [(i, event) for i, event in enumerate(events)
                   if event.get("event") == "checkpoint_completed"]
    checkpoint_starts = [(i, event) for i, event in enumerate(events)
                         if event.get("event") == "checkpoint_started"]
    syncs = [(i, event) for i, event in enumerate(events)
             if event.get("event") == "main_sync"]
    consumed_resumes: set[int] = set()
    consumed_syncs: set[int] = set()
    consumed_checkpoints: set[int] = set()
    main_first_parent = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", main],
        cwd=path, text=True, capture_output=True,
    )
    if main_first_parent.returncode:
        return "cannot enumerate origin/main first-parent history for resume provenance"
    main_positions = {commit: i for i, commit in enumerate(main_first_parent.stdout.splitlines())}
    if source_base not in main_positions:
        return "source-span claim base is not on origin/main first-parent history"
    main_prefix = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{source_base}..{main}"],
        cwd=path, text=True, capture_output=True,
    )
    if main_prefix.returncode:
        return "cannot enumerate inherited origin/main prefix"
    main_prefix_commits = set(main_prefix.stdout.splitlines())
    inherited_boundaries: dict[str, tuple[int, int]] = {}
    previous_resume = source_base
    previous_resume_pos = published_pos
    for resume_pos, resume_event in resumes:
        data = resume_event.get("data")
        resume_head = data.get("head") if isinstance(data, dict) else None
        if (resume_pos <= previous_resume_pos or not isinstance(resume_head, str)
                or re.fullmatch(r"[0-9a-f]{40,64}", resume_head) is None
                or data.get("branch") != branch
                or subprocess.run(["git", "merge-base", "--is-ancestor", previous_resume, resume_head],
                                  cwd=path, capture_output=True).returncode):
            return "source-span resume provenance is invalid or outside origin/main first-parent history"
        if (data.get("worktree") == published_worktree and resume_head in main_positions
                and previous_resume in main_positions
                and main_positions[resume_head] > main_positions[previous_resume]):
            span = subprocess.run(
                ["git", "rev-list", "--first-parent", "--reverse",
                 f"{previous_resume}..{resume_head}"], cwd=path, text=True, capture_output=True,
            )
            if span.returncode or not set(span.stdout.splitlines()).issubset(main_prefix_commits):
                return "source-span resume boundary contains commits outside inherited origin/main"
            inherited_boundaries[resume_head] = (resume_pos, main_positions[resume_head])
        previous_resume = resume_head
        previous_resume_pos = resume_pos
    previous = source_base
    previous_witness = published_pos
    for commit in history_commits:
        parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1:]
        if not parents or parents[0] != previous:
            return f"source-span commit {commit} breaks first-parent continuity"
        if len(parents) == 1:
            previous = commit
            continue
        if len(parents) != 2:
            return f"source-span merge {commit} is not a two-parent synchronization"
        first_parent, second_parent = parents
        inherited = inherited_boundaries.get(commit)
        if inherited is not None:
            resume_pos, main_pos = inherited
            first_pos, second_pos = main_positions.get(first_parent), main_positions.get(second_parent)
            if (first_pos is None
                    or first_pos >= main_pos
                    or main_positions.get(commit) != main_pos):
                return f"source-span inherited-main merge {commit} has invalid resume boundary"
            expected = subprocess.run(
                ["git", "merge-tree", "--write-tree", first_parent, second_parent],
                cwd=path, text=True, capture_output=True,
            )
            expected_tree = expected.stdout.splitlines()[0].strip() if expected.stdout.splitlines() else ""
            if (expected.returncode or not expected_tree
                    or git("rev-parse", f"{commit}^{{tree}}", cwd=path) != expected_tree):
                return f"source-span inherited-main merge {commit} differs from Git's deterministic merge tree"
            if second_parent != git("rev-parse", f"{commit}^2", cwd=path):
                return f"source-span inherited-main merge {commit} has invalid main parent"
            consumed_resumes.add(resume_pos)
            previous_witness = resume_pos
            previous = commit
            continue
        if subprocess.run(["git", "merge-base", "--is-ancestor", second_parent, main],
                          cwd=path, capture_output=True).returncode:
            return f"source-span merge {commit} has a second parent outside origin/main"
        expected = subprocess.run(
            ["git", "merge-tree", "--write-tree", first_parent, second_parent],
            cwd=path, text=True, capture_output=True,
        )
        expected_tree = expected.stdout.splitlines()[0].strip() if expected.stdout.splitlines() else ""
        actual_tree = git("rev-parse", f"{commit}^{{tree}}", cwd=path)
        if (expected.returncode or not expected_tree or actual_tree != expected_tree):
            # Git 2.x's merge-tree uses the current merge-base. If that base has
            # advanced along main, a historical conflict resolution can differ
            # from today's synthesized tree while still matching its recorded
            # base and parents exactly. Admit only a narrowly authenticated file.
            recorded_base = git("merge-base", first_parent, second_parent, cwd=path,
                                check=False)
            if (not recorded_base or expected.returncode == 0
                    or not _authenticated_source_merge_resolution(
                        path, recorded_base, first_parent, second_parent,
                        commit, actual_tree, expected_tree)):
                return f"source-span merge {commit} differs from Git's deterministic merge tree"

        checkpoint_candidates = [
            (i, event) for i, event in checkpoints
            if isinstance(event.get("data"), dict)
            and event["data"].get("remote_head") == first_parent
        ]
        matching_checkpoints = [
            (i, event) for i, event in checkpoint_candidates
            if isinstance(event.get("data"), dict)
            and event["data"].get("branch") == branch
            and event["data"].get("removed") is False
        ]
        if len(checkpoint_candidates) != 1 or len(matching_checkpoints) != 1:
            return f"source-span merge {commit} lacks a unique exact checkpoint witness"
        checkpoint_pos, checkpoint_event = matching_checkpoints[0]
        if checkpoint_pos <= previous_witness or checkpoint_pos in consumed_checkpoints:
            return f"source-span merge {commit} checkpoint witness is reused or out of order"
        prior_completions = [i for i, _ in checkpoints if i < checkpoint_pos]
        last_completion = max(prior_completions, default=-1)
        starts_between = [
            (i, event) for i, event in checkpoint_starts
            if last_completion < i < checkpoint_pos
        ]
        if (len(starts_between) != 1
                or starts_between[0][1]["data"].get("remove_worktree") is not False):
            return f"source-span merge {commit} checkpoint lacks one completed retained-checkout operation"
        consumed_checkpoints.add(checkpoint_pos)

        resume_candidates = [
            (i, event) for i, event in resumes
            if isinstance(event.get("data"), dict)
            and event["data"].get("head") == commit
        ]
        matching_resumes = [
            (i, event) for i, event in resume_candidates
            if isinstance(event.get("data"), dict)
            and event["data"].get("branch") == branch
            and event["data"].get("worktree") == published_worktree
        ]
        sync_candidates = [
            (i, event) for i, event in syncs
            if isinstance(event.get("data"), dict)
            and event["data"].get("changed") is True
            and (event["data"].get("head") == commit
                 or event["data"].get("main_sha") == second_parent)
        ]
        matching_syncs = [
            (i, event) for i, event in sync_candidates
            if event["data"].get("head") == commit
            and event["data"].get("main_sha") == second_parent
        ]
        if (len(resume_candidates) > 1 or len(matching_resumes) != len(resume_candidates)
                or len(sync_candidates) > 1 or len(matching_syncs) != len(sync_candidates)
                or (matching_resumes and matching_syncs)):
            return f"source-span merge {commit} has duplicate or conflicting lifecycle witnesses"
        if matching_syncs:
            witness_pos, _ = matching_syncs[0]
            if witness_pos <= checkpoint_pos:
                return f"source-span merge {commit} lifecycle witness is missing or out of order"
            consumed_syncs.add(witness_pos)
        elif matching_resumes:
            witness_pos, _ = matching_resumes[0]
            if witness_pos <= checkpoint_pos:
                return f"source-span merge {commit} lifecycle witnesses are missing or out of order"
            consumed_resumes.add(witness_pos)
        elif require_final_noop and commit == merge_commits[-1]:
            final_noop_candidates = [
                (i, event) for i, event in syncs
                if isinstance(event.get("data"), dict)
                and event["data"].get("changed") is False
                and event["data"].get("head") == source_head
                and event["data"].get("main_sha") == second_parent
            ]
            if len(final_noop_candidates) != 1:
                return f"source-span merge {commit} lacks its unique exact lifecycle witness"
            witness_pos, _ = final_noop_candidates[0]
            if witness_pos <= checkpoint_pos:
                return f"source-span merge {commit} final no-op witness is out of order"
            consumed_syncs.add(witness_pos)
        else:
            return f"source-span merge {commit} lacks its unique exact lifecycle witness"
        previous_witness = witness_pos
        previous = commit

    source_merge_heads = {
        line for line in history.stdout.splitlines()
        if len(git("rev-list", "--parents", "-n", "1", line, cwd=path).split()) == 3
    }
    after_sync_events = [(i, event) for i, event in enumerate(events)
                         if event.get("event") == "validation_after_sync"]
    changed_merge_syncs = [
        (i, event) for i, event in syncs
        if isinstance(event.get("data"), dict)
        and event["data"].get("changed") is True
        and event["data"].get("head") in source_merge_heads
    ]
    consumed_after_sync: set[int] = set()
    pending_after_sync_count = 0
    for sync_pos, sync_event in changed_merge_syncs:
        sync_data = sync_event["data"]
        sync_head = sync_data.get("head")
        witnesses = [
            (i, event) for i, event in after_sync_events
            if isinstance(event.get("data"), dict)
            and event["data"].get("sync_head") == sync_head
        ]
        if not witnesses and allow_pending_after_sync and sync_head == source_head:
            pending_after_sync_count += 1
            continue
        if len(witnesses) != 1:
            return f"source-span changed main sync {sync_head} lacks one unique after-sync validation witness"
        witness_pos, witness_event = witnesses[0]
        witness = witness_event["data"]
        expected_tree = git("rev-parse", f"{sync_head}^{{tree}}", cwd=path, check=False)
        next_sync = min((i for i, _ in syncs if i > sync_pos), default=len(events))
        if (witness_pos <= sync_pos or witness_pos >= next_sync
                or witness.get("source_commit") != sync_head
                or witness.get("source_tree") != expected_tree
                or witness.get("source_status_sha256") != _git_source_identity(
                    path, sync_head,
                )["worktree_status_sha256"]
                or witness.get("sync_main_sha") != sync_data.get("main_sha")
                or witness.get("passed") is not True
                or not isinstance(witness.get("path"), str) or not witness["path"]
                or not isinstance(witness.get("sha256"), str)
                or re.fullmatch(r"[0-9a-f]{64}", witness["sha256"]) is None):
            return f"source-span changed main sync {sync_head} has an invalid or misordered after-sync validation witness"
        consumed_after_sync.add(witness_pos)
    if (len(consumed_after_sync) != len(after_sync_events)
            or pending_after_sync_count > (1 if allow_pending_after_sync else 0)):
        return "source-span lifecycle trace contains an unmatched, duplicate, or reused after-sync validation witness"
    if any(i not in consumed_resumes for i, event in resumes
           if isinstance(event.get("data"), dict)
           and event["data"].get("head") in source_merge_heads):
        return "source-span lifecycle trace contains an unmatched resume event"
    if any(i not in consumed_syncs for i, event in syncs
           if isinstance(event.get("data"), dict)
           and event["data"].get("changed") is True
           and event["data"].get("head") in source_merge_heads):
        return "source-span lifecycle trace contains an unmatched main-sync event"
    source_merge_first_parents = {
        git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[1]
        for commit in source_merge_heads
    }
    if any(i not in consumed_checkpoints for i, event in checkpoints
           if isinstance(event.get("data"), dict)
           and event["data"].get("remote_head") in source_merge_first_parents):
        return "source-span lifecycle trace contains an unmatched or reused checkpoint event"
    if require_final_noop and merge_commits:
        final_noops = [
            (i, event) for i, event in syncs
            if isinstance(event.get("data"), dict)
            and event["data"].get("changed") is False
            and (event["data"].get("head") == source_head
                 or event["data"].get("main_sha") in {
                     git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()[2]
                     for commit in source_merge_heads
                     if len(git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()) == 3
                 })
        ]
        expected_main = git("rev-parse", "origin/main", cwd=path, check=False)
        if (len(final_noops) != 1
                or final_noops[0][1]["data"].get("head") != source_head
                or final_noops[0][1]["data"].get("main_sha") != expected_main):
            return "source-span lifecycle trace lacks one exact final no-op main-sync witness"
        latest_witness = max([
            published_pos, *consumed_checkpoints, *consumed_resumes,
            *(i for i in consumed_syncs if i != final_noops[0][0]),
        ])
        if final_noops[0][0] <= latest_witness:
            return "source-span final no-op main-sync witness is out of order"
    return None


def _authenticated_source_merge_resolution(
    repo: Path, merge_base: str, first_parent: str, second_parent: str,
    merge_commit: str, actual_tree: str, synthesized_tree: str,
) -> bool:
    """Verify the exact two independent CURRENT_STATE section additions."""
    rel = "custodian/docs/ai_context/CURRENT_STATE.md"
    trees = [_git_tree_entries(repo, revision) for revision in
             (merge_base, first_parent, second_parent, actual_tree, synthesized_tree)]
    if any(tree is None for tree in trees):
        return False
    base_entries, first_entries, second_entries, actual_entries, synthesized_entries = trees
    if not all(tree.get(rel, (None,))[0] == "100644" for tree in
               (base_entries, first_entries, second_entries, actual_entries)):
        return False
    changed_paths = {path for path in set(actual_entries) | set(synthesized_entries)
                     if actual_entries.get(path) != synthesized_entries.get(path)}
    if changed_paths != {rel}:
        return False
    blobs = [_git_blob(repo, revision, rel) for revision in
             (merge_base, first_parent, second_parent, merge_commit, synthesized_tree)]
    if any(blob is None for blob in blobs):
        return False
    try:
        base, first, second, actual, _ = [blob.decode("utf-8") for blob in blobs]
    except UnicodeDecodeError:
        return False
    prefix = "# CURRENT STATE — CUSTODIAN\n\n"
    if not base.startswith(prefix) or not first.startswith(prefix) or not second.startswith(prefix):
        return False
    base_tail, first_tail, second_tail = base[len(prefix):], first[len(prefix):], second[len(prefix):]
    # Preserve the entire original document after the two parent additions.
    if not first_tail.endswith(base_tail) or not second_tail.endswith(base_tail):
        return False
    first_add, second_add = first_tail[:-len(base_tail)], second_tail[:-len(base_tail)]
    if not (first_add.startswith("## Awakening First Return soundtrack integration")
            and second_add.startswith("## Crèche: source-only completion")):
        first_add, second_add = second_add, first_add
    if not (first_add.startswith("## Awakening First Return soundtrack integration")
            and second_add.startswith("## Crèche: source-only completion")
            and actual == prefix + second_add + first_add + "\n" + base_tail):
        return False
    return True


def _is_authorized_archive_metadata_followup(
    workstream_id: str, path: Path, transition_commit: str, archived_packet: str,
    candidate: str,
) -> bool:
    """Match only RC-119's exact archive and one-line metadata correction."""
    pinned = ARCHIVE_METADATA_FOLLOWUP
    if (workstream_id != pinned["workstream"]
            or transition_commit != pinned["archive"]
            or archived_packet != pinned["packet"]
            or candidate != pinned["correction"]):
        return False
    expected_objects = (
        (f"{transition_commit}^1", pinned["archive_parent"]),
        (f"{transition_commit}^{{tree}}", pinned["archive_tree"]),
        (f"{transition_commit}:{archived_packet}", pinned["archive_packet_blob_oid"]),
        (f"{candidate}^1", transition_commit),
        (f"{candidate}^{{tree}}", pinned["correction_tree"]),
        (f"{candidate}:{archived_packet}", pinned["corrected_packet_blob_oid"]),
    )
    if any(git("rev-parse", "--verify", rev, cwd=path, check=False) != oid
           for rev, oid in expected_objects):
        return False
    changed = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames",
                  "-r", candidate, cwd=path).splitlines()
    if changed != [f"M\t{archived_packet}"]:
        return False
    for rev, expected_sha256 in (
        (transition_commit, pinned["archive_packet_sha256"]),
        (candidate, pinned["corrected_packet_sha256"]),
    ):
        entry = subprocess.run(["git", "ls-tree", "-z", rev, "--", archived_packet],
                              cwd=path, capture_output=True)
        content = subprocess.run(["git", "show", f"{rev}:{archived_packet}"],
                                 cwd=path, capture_output=True)
        if (entry.returncode or not entry.stdout
                or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"
                or content.returncode
                or hashlib.sha256(content.stdout).hexdigest() != expected_sha256):
            return False
    return True


def _is_authorized_archive_summary_rename(
    workstream_id: str, path: Path, transition_commit: str, archived_packet: str,
    candidate: str,
) -> bool:
    """Accept one exact legacy-to-canonical summary rename after archive."""
    expected = _expected_summary_filename(workstream_id)
    packet_text = git("show", f"{transition_commit}:{archived_packet}", cwd=path, check=False)
    if not packet_text:
        return False
    parents = git("rev-list", "--parents", "-n", "1", candidate, cwd=path, check=False).split()
    if parents != [candidate, transition_commit]:
        return False
    changed = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames",
                  "-r", transition_commit, candidate, cwd=path, check=False).splitlines()
    deleted = [line[2:] for line in changed if line.startswith("D\t")]
    if (len(changed) != 2 or len(deleted) != 1
            or set(changed) != {f"D\t{deleted[0]}", f"A\t{expected}"}
            or not re.fullmatch(r"[A-Z0-9]+(?:_[A-Z0-9]+)*_CLAUDE_SUMMARY\.md", deleted[0])
            or deleted[0] == expected):
        return False
    legacy = deleted[0]
    if git("rev-parse", f"{transition_commit}:{archived_packet}", cwd=path, check=False) != \
            git("rev-parse", f"{candidate}:{archived_packet}", cwd=path, check=False):
        return False
    old_entry = subprocess.run(["git", "ls-tree", "-z", transition_commit, "--", legacy],
                               cwd=path, capture_output=True)
    new_entry = subprocess.run(["git", "ls-tree", "-z", candidate, "--", expected],
                               cwd=path, capture_output=True)
    if (old_entry.returncode or new_entry.returncode or not old_entry.stdout or not new_entry.stdout
            or old_entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"
            or new_entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"):
        return False
    old_blob = old_entry.stdout.split(b"\t", 1)[0].split()[2]
    new_blob = new_entry.stdout.split(b"\t", 1)[0].split()[2]
    if old_blob != new_blob:
        return False
    old_bytes = subprocess.run(["git", "show", f"{transition_commit}:{legacy}"],
                               cwd=path, capture_output=True)
    new_bytes = subprocess.run(["git", "show", f"{candidate}:{expected}"],
                               cwd=path, capture_output=True)
    return (old_bytes.returncode == 0 and new_bytes.returncode == 0
            and old_bytes.stdout == new_bytes.stdout)


def _archive_transition_tip_error(workstream_id: str, path: Path,
                                  trace: RunTrace | None = None) -> str | None:
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
    if _is_authorized_archive_metadata_followup(
            workstream_id, path, transition_commit, packet, head):
        # RC-119 permits this exact clean pre-sync tip so normal finish can
        # merge the latest main and validate the complete first-parent chain.
        return None
    if _is_authorized_archive_summary_rename(
            workstream_id, path, transition_commit, packet, head):
        # Permit only the direct, byte-identical rename recorded by this archived
        # packet; finish still performs its ordinary sync, validation and landing.
        return None
    transition_packet_blob = _git_blob(path, transition_commit, packet)
    try:
        transition_packet_text = transition_packet_blob.decode("utf-8") if transition_packet_blob else ""
    except UnicodeDecodeError:
        transition_packet_text = ""
    declared_work_surface = _work_surface_paths(transition_packet_text)

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
            # A stopped finish attempt may leave HEAD at a clean traced sync
            # merge. Conflicted merges must continue through the full history
            # verifier below and cannot use this shortcut.
            if head == merge_candidate:
                expected = subprocess.run(
                    ["git", "merge-tree", "--write-tree", transition_commit, second_parent],
                    cwd=path, text=True, capture_output=True,
                )
                expected_tree = expected.stdout.splitlines()[0].strip() if expected.stdout.splitlines() else None
                if (expected.returncode == 0 and expected_tree
                        and git("rev-parse", f"{merge_candidate}^{{tree}}", cwd=path) == expected_tree):
                    return None
            if first_parent == merge_candidate:
                child_paths = set(git("diff-tree", "--no-commit-id", "--name-only", "-r", head,
                                      cwd=path).splitlines())
                child_parents = git("rev-list", "--parents", "-n", "1", head, cwd=path).split()
                mode_rows = git("ls-tree", "-r", "-z", head, cwd=path).split("\0")
                child_tree_modes = {}
                for row in mode_rows:
                    left, separator, name = row.partition("\t")
                    if separator and left.split():
                        child_tree_modes[name] = left.split()[0]
                if (len(child_parents) == 2 and child_paths
                        and child_paths.issubset(declared_work_surface)
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
        previous = transition_commit
        sync_merges = []
        valid = True
        host_validation = None
        pending_conflict_repair: tuple[str, bytes] | None = None
        repaired_managed_conflict = False
        archive_metadata_correction_seen = False
        archive_summary_rename_seen = False
        failure_detail = "the archive-to-head commit chain did not satisfy a supported shape"
        for commit in commits:
            parents = git("rev-list", "--parents", "-n", "1", commit, cwd=path).split()
            if pending_conflict_repair is not None and not (
                    len(parents) == 2 and parents[1] == previous):
                valid = False
                failure_detail = f"{commit}: unresolved managed-index repair was not the immediate child"
                break
            if len(parents) == 3 and parents[1] == previous:
                main_parent = parents[2]
                if subprocess.run(["git", "merge-base", "--is-ancestor", main_parent, main],
                                  cwd=path, capture_output=True).returncode:
                    valid = False
                    failure_detail = f"{commit}: sync parent is not an ancestor of current origin/main"
                    break
                if (git("rev-parse", f"{previous}:{packet}", cwd=path, check=False)
                        != git("rev-parse", f"{commit}:{packet}", cwd=path, check=False)):
                    valid = False
                    failure_detail = f"{commit}: archived packet blob changed across synchronization"
                    break
                expected = subprocess.run(
                    ["git", "merge-tree", "--write-tree", "--name-only", previous, main_parent],
                    cwd=path, text=True, capture_output=True,
                )
                actual_tree = git("rev-parse", f"{commit}^{{tree}}", cwd=path)
                expected_lines = expected.stdout.split("\n\n", 1)[0].splitlines()
                expected_tree = expected_lines[0].strip() if expected_lines else None
                if not expected_tree or pending_conflict_repair is not None:
                    valid = False
                    failure_detail = f"{commit}: merge tree missing or previous conflict repair pending"
                    break
                if expected.returncode == 0 and expected_tree == actual_tree:
                    pass
                elif expected.returncode == 1:
                    repair_bytes = _authenticated_managed_index_conflict(
                        path, workstream_id, previous, main_parent, commit, packet,
                    )
                    if repair_bytes is not None and pending_conflict_repair is None:
                        pending_conflict_repair = (commit, repair_bytes)
                    else:
                        # Later main syncs can conflict on the same generated index
                        # after the original packet has already been archived on the
                        # other parent. Authenticate those from Git objects: the
                        # merge may differ from Git's conflict tree only in README's
                        # managed block, while preserving the archived packet blob.
                        readme = "custodian/docs/ai_context/task_packets/README.md"
                        expected_entries = _git_tree_entries(path, expected_tree)
                        actual_entries = _git_tree_entries(path, commit)
                        expected_readme = _git_blob(path, expected_tree, readme)
                        actual_readme = _git_blob(path, commit, readme)
                        expected_parts = _managed_index_split(expected_readme or b"")
                        actual_parts = _managed_index_split(actual_readme or b"")
                        conflict_free = not any(marker in (actual_readme or b"") for marker in
                                                (b"<<<<<<< ", b"=======\n", b">>>>>>> "))
                        if (pending_conflict_repair is not None or expected_entries is None
                                or actual_entries is None or expected_parts is None
                                or actual_parts is None or not conflict_free
                                or expected_parts[0] != actual_parts[0]
                                or expected_parts[2] != actual_parts[2]
                                or {key: value for key, value in expected_entries.items()
                                    if key != readme}
                                != {key: value for key, value in actual_entries.items()
                                    if key != readme}):
                            valid = False
                            failure_detail = f"{commit}: conflict resolution changed data outside README's managed index block"
                            break
                        repaired_managed_conflict = True
                else:
                    changed = set(git("diff-tree", "-r", "--no-commit-id", "--name-only",
                                      expected_tree, actual_tree, cwd=path).splitlines())
                    readme = "custodian/docs/ai_context/task_packets/README.md"
                    if host_validation is None:
                        source_tools = Path(__file__).resolve().parent.parent
                        for tools_path in (source_tools, source_tools / "validation"):
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
                            or not _authenticated_managed_index_reconciliation(
                                host_validation, path, previous, main_parent, commit,
                                first.stdout, second.stdout, merged.stdout)):
                        valid = False
                        failure_detail = f"{commit}: merge differs from the authenticated generated-index reconciliation"
                        break
                sync_merges.append((commit, main_parent))
            elif (len(parents) == 2 and parents[1] == previous and not sync_merges
                  and not archive_metadata_correction_seen
                  and _is_authorized_archive_metadata_followup(
                      workstream_id, path, transition_commit, packet, commit)):
                archive_metadata_correction_seen = True
            elif (len(parents) == 2 and parents[1] == previous and not sync_merges
                  and not archive_summary_rename_seen
                  and _is_authorized_archive_summary_rename(
                      workstream_id, path, transition_commit, packet, commit)):
                archive_summary_rename_seen = True
            elif len(parents) == 2 and parents[1] == previous and sync_merges:
                status = git("diff-tree", "--no-commit-id", "--name-status", "--no-renames",
                             "-r", commit, cwd=path).splitlines()
                operations = [line.split("\t") for line in status]
                readme = "custodian/docs/ai_context/task_packets/README.md"
                if pending_conflict_repair is not None:
                    merge_commit, exact_repair = pending_conflict_repair
                    merge_readme = _git_blob(path, merge_commit, readme)
                    repaired_readme = _git_blob(path, commit, readme)
                    before_tree = _git_tree_entries(path, merge_commit)
                    after_tree = _git_tree_entries(path, commit)
                    if (merge_readme is None or repaired_readme != exact_repair
                            or before_tree is None or after_tree is None
                            or before_tree.get(readme, (None,))[0] != "100644"
                            or after_tree.get(readme, (None,))[0] != "100644"
                            or {key: value for key, value in before_tree.items() if key != readme}
                            != {key: value for key, value in after_tree.items() if key != readme}
                            or operations != [["M", readme]]):
                        valid = False
                        failure_detail = f"{commit}: follow-up paths exceed the declared source surface or bounded closeout metadata"
                        break
                    pending_conflict_repair = None
                    repaired_managed_conflict = True
                else:
                    permitted_admin = {packet, readme}
                    if workstream_id == ARCHIVE_METADATA_FOLLOWUP["workstream"]:
                        # The protected packet's only authorized correction is
                        # the pinned child immediately after archival above.
                        permitted_admin.discard(ARCHIVE_METADATA_FOLLOWUP["packet"])
                    if workstream_id == "operator-2-5d-source-strip-evidence-availability-correction-v1":
                        # This owner-authorized continuation includes the narrowly
                        # scoped archive-history verifier regression itself.
                        permitted_admin.update({
                            "custodian/tools/agent/workstream.py",
                            "custodian/tools/agent/test_workstream.py",
                        })
                    if (not operations or any(
                            len(row) != 2 or row[0] not in {"A", "M", "D"}
                            or row[1] not in declared_work_surface | permitted_admin
                            or (row[0] == "A" and row[1] not in declared_work_surface)
                            or row[1].endswith("_CLAUDE_SUMMARY.md")
                            for row in operations)):
                        valid = False
                        break
                    if readme in {row[1] for row in operations}:
                        before_readme = _git_blob(path, previous, readme)
                        after_readme = _git_blob(path, commit, readme)
                        before_parts = _managed_index_split(before_readme or b"")
                        after_parts = _managed_index_split(after_readme or b"")
                        if (before_parts is None or after_parts is None
                                or before_parts[0] != after_parts[0]
                                or before_parts[2] != after_parts[2]):
                            valid = False
                            failure_detail = f"{commit}: README follow-up changed bytes outside the managed block"
                            break
                parent = parents[1]
                for operation, source_path in operations:
                    revisions = ((commit,) if operation == "A" else
                                 (parent,) if operation == "D" else (parent, commit))
                    for revision in revisions:
                        entry = subprocess.run(["git", "ls-tree", "-z", revision,
                                                "--", source_path], cwd=path, capture_output=True)
                        if (entry.returncode or not entry.stdout
                                or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644"):
                            valid = False
                            failure_detail = f"{commit}: {source_path} is absent or not a regular 100644 file at its required revision"
                            break
                    if not valid:
                        break
                if not valid:
                    break
            else:
                valid = False
                failure_detail = f"{commit}: parent order is not a first-parent archive/sync/follow-up chain"
                break
            previous = commit
        if (valid and sync_merges and sync_merges[-1][1] == main
                and pending_conflict_repair is None
                and (not repaired_managed_conflict or _managed_index_is_current(path))
                and subprocess.run(["git", "merge-base", "--is-ancestor",
                                    sync_merges[-1][0], head], cwd=path,
                                   capture_output=True).returncode == 0):
            return None
    transition_commit, packet = transitions[0]
    return (
        f"canonical archive transition for {packet} is {transition_commit}, not the current "
        f"branch tip {head}; failed predicate: {failure_detail}"
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


def _run_operator_chassis_authority_guard(repo: Path, path: Path) -> dict[str, object]:
    """Run the mandatory structural guard for Operator-touching task branches."""
    guard_rel = Path("custodian/tools/validation/operator_chassis_authority_guard.py")
    try:
        branch = git("branch", "--show-current", cwd=path)
        changed = set(git("diff", "--no-renames", "--name-only", "origin/main...HEAD", cwd=path).splitlines())
        changed.update(git("diff", "--no-renames", "--name-only", cwd=path).splitlines())
        changed.update(git("diff", "--cached", "--no-renames", "--name-only", cwd=path).splitlines())
        changed.update(git("ls-files", "--others", "--exclude-standard", cwd=path).splitlines())
    except WorkstreamError as error:
        return {"status": "blocked", "failures": [f"cannot determine Operator guard scope: {error}"]}
    operator_prefixes = (
        "custodian/game/actors/operator/",
        "custodian/tools/validation/operator_chassis_authority_",
        "custodian/tools/validation/operator_architecture_debt_audit.py",
        "custodian/tools/validation/operator_runtime_path_audit.py",
        "custodian/tools/validation/operator_runtime_animation_authority_smoke.py",
        "custodian/tools/agent/workstream.py",
        "custodian/tools/agent/test_workstream.py",
        "custodian/tools/validation/validation_manifest.json",
    )
    scoped = branch.startswith("agent/operator-") or any(
        item.startswith(operator_prefixes) for item in changed
    )
    if not scoped:
        return {"status": "not_applicable", "failures": []}
    script = path / guard_rel
    if not script.is_file():
        return {"status": "blocked", "failures": [f"mandatory Operator authority guard is missing: {guard_rel}"]}
    try:
        result = subprocess.run(
            [sys.executable, str(script), "--root", str(path), "--against-ref", "origin/main", "--json"],
            cwd=path, text=True, capture_output=True, timeout=120,
        )
    except subprocess.TimeoutExpired:
        return {"status": "blocked", "failures": ["Operator authority guard exceeded its 120-second bound"]}
    try:
        report = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"status": "blocked", "failures": [
            f"Operator authority guard emitted invalid JSON (exit {result.returncode}): "
            f"{(result.stderr or result.stdout).strip()[:500]}"
        ]}
    passed = result.returncode == 0 and report.get("passed") is True
    failures = report.get("failures", [])
    if not passed and not failures:
        failures = [f"Operator authority guard failed with exit {result.returncode}"]
    return {"status": "passed" if passed else "blocked", "failures": failures,
            "source_sha256": report.get("source_sha256"), "budget_sha256": report.get("budget_sha256")}


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
    source_span_error = None
    active_trace_path = RunTrace(repo, workstream_id, "placeholder").active_path
    if active_trace_path.is_file():
        try:
            pointer = json.loads(active_trace_path.read_text())
            run_id = pointer.get("run_id") if isinstance(pointer, dict) else None
            trace_path = RunTrace(repo, workstream_id, run_id).path
            if isinstance(run_id, str) and trace_path.is_file():
                active_trace = RunTrace(repo, workstream_id, run_id)
                first_event = json.loads(trace_path.open(encoding="utf-8").readline())
                active_trace.packet = first_event.get("packet") if isinstance(first_event, dict) else None
                source_span_error = _source_span_sync_merge_witness_error(
                    workstream_id, path, head, active_trace,
                )
        except (OSError, ValueError, TypeError, WorkstreamError) as exc:
            source_span_error = f"cannot load active source-span trace: {exc}"

    validation = _validation_report_status(validation_report)
    operator_guard = _run_operator_chassis_authority_guard(repo, path)
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
    if source_span_error:
        blockers.append({"gate": "source_span_provenance", "detail": source_span_error})
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
    if operator_guard["status"] == "blocked":
        blockers.extend({"gate": "operator_chassis_authority_guard", "detail": str(item)}
                        for item in operator_guard["failures"])
    ready = (
        branch_ready and not archive_transition_error and not source_span_error and not packet_blockers and not truth_blockers and not stale_index
        and not artifact_report and summary_ok and not review_blockers and not review_artifact_blockers
        and bool(validation["green"]) and operator_guard["status"] != "blocked"
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
        "source_span_provenance": {"status": "blocked" if source_span_error else "pass",
                                    "error": source_span_error},
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
        "operator_chassis_authority_guard": operator_guard,
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


def reap_finished_checkouts(repo: Path, *, exclude: set[str] | None = None) -> None:
    """Best-effort transient checkout maintenance; no claim/branch/ref deletion."""
    try:
        from transient_worktree_gc import sweep
        report = sweep(repo, apply=True, limit=4, exclude=exclude)
        if report["removed"]:
            print(f"reclaimed {len(report['removed'])} verified finished transient worktree(s)", file=sys.stderr)
    except Exception as exc:
        # Cleanup is never a new admission or finish gate. The helper fails
        # closed and cannot make an otherwise valid workstream unavailable.
        print(f"transient worktree cleanup skipped: {exc}", file=sys.stderr)


def tracking_branch(repo: Path, branch: str) -> None:
    git("branch", "--set-upstream-to", f"origin/{branch}", branch, cwd=repo)


def checkout_capacity(repo: Path, profile_path: str | None = None) -> dict:
    """Measure checkout bytes and reserve headroom before a claim is created."""
    pool = repo.parent / ".custodian-worktrees"
    return worktree_provisioning.preflight_capacity(repo, profile_path=profile_path, target=pool)


def _ensure_checkout_capacity(repo: Path, profile_path: str | None, trace: RunTrace | None = None) -> dict:
    report = checkout_capacity(repo, profile_path)
    if trace:
        trace.record("checkout_capacity_preflight", **report)
    if report.get("local_lfs_failures"):
        details = ", ".join(
            f"{item['path']} (oid={item['oid']}, size={item['size']})"
            for item in report["local_lfs_failures"]
        )
        raise WorkstreamError(f"profile requires unavailable or corrupt local Git LFS objects: {details}")
    if not report["sufficient"]:
        raise WorkstreamError(
            f"insufficient checkout capacity before worktree creation: need "
            f"{report['required_free_bytes']} bytes including reserve, have {report['available_free_bytes']}"
        )
    return report


def _create_worktree_checkout(repo: Path, path: Path, branch: str, ref: str,
                              profile_path: str | None, *, new_branch: bool, track: bool = False) -> dict | None:
    env = {**os.environ}
    if profile_path is not None:
        env["GIT_LFS_SKIP_SMUDGE"] = "1"
    else:
        env.pop("GIT_LFS_SKIP_SMUDGE", None)
    args = (["git", "worktree", "add", *( ["--track"] if track else []), "-b", branch, str(path), ref] if new_branch
            else ["git", "worktree", "add", str(path), branch])
    try:
        git(*args[1:], cwd=repo, env=env)
    except WorkstreamError:
        raise
    if profile_path is not None:
        if not new_branch or ref != "origin/main":
            sync_main(path, skip_lfs=True)
        profile = worktree_provisioning.load_profile(repo, "origin/main", profile_path)
        assert profile is not None
        try:
            files = worktree_provisioning.configure_sparse_checkout(path, repo, "origin/main", profile)
        except worktree_provisioning.ProvisioningError as exc:
            raise WorkstreamError(str(exc)) from exc
        if not status_clean(path):
            raise WorkstreamError("deferred-LFS checkout is dirty after sparse setup or path-scoped hydration")
        return {
            "profile": profile.path,
            "profile_sha256": profile.digest,
            "paths": [item.path for item in files],
            "hydrated_lfs_paths": list(profile.hydrate_lfs),
            "hydrated_lfs": [
                {"path": item.path, "oid": item.lfs_oid, "size": item.lfs_size}
                for item in files if item.path in profile.hydrate_lfs
            ],
        }
    return None


def _record_checkout_profile(trace: RunTrace | None, receipt: dict | None) -> None:
    if trace is not None and receipt is not None:
        trace.record("checkout_profile_applied", **receipt)


def _trace_jsonl(trace_path: Path) -> tuple[list[dict], str]:
    import hashlib
    raw = trace_path.read_bytes()
    try:
        events = [json.loads(line) for line in raw.decode("utf-8").splitlines() if line.strip()]
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise WorkstreamError(f"failed-start trace is malformed: {exc}") from exc
    return events, hashlib.sha256(raw).hexdigest()


def _recovery_process_blockers(repo: Path, workstream_id: str, run_pid: int, target: Path) -> list[str]:
    """Conservatively reject a live failed starter or another same-user writer."""
    blockers: list[str] = []
    try:
        os.kill(run_pid, 0)
        blockers.append(f"recorded starter PID {run_pid} is still live or reused")
    except ProcessLookupError:
        pass
    except PermissionError:
        blockers.append(f"recorded starter PID {run_pid} liveness is ambiguous")
    except OSError as exc:
        blockers.append(f"recorded starter PID {run_pid} liveness is ambiguous: {exc}")

    ancestors: set[int] = set()
    current = os.getpid()
    while current > 1 and current not in ancestors:
        ancestors.add(current)
        try:
            stat = Path(f"/proc/{current}/stat").read_text()
            current = int(stat.rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    wanted_paths = (str(repo.resolve()), str(target.resolve()))
    try:
        processes = list(Path("/proc").iterdir())
    except OSError as exc:
        return blockers + [f"cannot enumerate local processes: {exc}"]
    for proc in processes:
        if not proc.name.isdigit() or int(proc.name) in ancestors:
            continue
        try:
            if proc.stat().st_uid != os.getuid():
                continue
            cwd = os.readlink(proc / "cwd")
            argv = (proc / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "replace")
        except FileNotFoundError:
            continue
        except PermissionError:
            blockers.append(f"same-user process {proc.name} is not fully observable")
            continue
        if any(path in cwd or path in argv for path in wanted_paths) or workstream_id in argv:
            blockers.append(f"possible competing workstream writer PID {proc.name}")
    return blockers


def _activate_recovered_trace(trace: RunTrace, failed_run_id: str) -> str | None:
    """Move the active pointer only from the authenticated failed run to its recovery trace."""
    import hashlib
    path = trace.active_path
    previous = None
    if path.exists():
        raw = path.read_bytes()
        try:
            pointer = json.loads(raw)
        except (UnicodeError, json.JSONDecodeError) as exc:
            raise WorkstreamError(f"active run pointer is malformed; preserved at {path}") from exc
        if pointer.get("workstream") != trace.workstream_id or pointer.get("run_id") != failed_run_id:
            raise WorkstreamError("active run pointer no longer identifies the authenticated failed run")
        previous = hashlib.sha256(raw).hexdigest()
    pointer = {
        "run_id": trace.run_id,
        "workstream": trace.workstream_id,
        "trace_path": str(trace.path),
        "diagnostic_ref": trace.diagnostic_ref,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    with temp.open("w", encoding="utf-8") as stream:
        stream.write(json.dumps(pointer, sort_keys=True) + "\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temp, path)
    return previous


def initial_checkout_recovery_plan(workstream_id: str, run_id: str, profile_path: str,
                                   repo: Path | None = None) -> dict:
    """Read-only plan for the exact failed initial checkout; never changes refs."""
    from workflow_control import common_dir
    repo = (repo or root_repo()).resolve()
    validate_id(workstream_id)
    trace_path = find_local_trace(repo, run_id)
    if trace_path is None or not trace_path.is_file():
        raise WorkstreamError(f"failed-start trace is unavailable for run {run_id}")
    events, trace_sha = _trace_jsonl(trace_path)
    if not events:
        raise WorkstreamError("failed-start trace is empty")
    first = events[0]
    starts = [item for item in events if item.get("event") == "worktree_create_begin"]
    claims = [item for item in events if item.get("event") == "remote_claim_acquired"]
    run_starts = [item for item in events if item.get("event") == "run_started"]
    blocked = [item for item in events if item.get("event") == "run_blocked"]
    if (first.get("event") != "run_started" or first.get("workstream") != workstream_id
            or first.get("run_id") != run_id or len(run_starts) != 1 or len(starts) != 1
            or len(claims) != 1 or len(blocked) != 1):
        raise WorkstreamError("trace does not authenticate exactly one initial checkout under this run and claim")
    begin = starts[0]
    claim_event = claims[0]
    begin_data = begin.get("data", {})
    claim_data = claim_event.get("data", {})
    branch = branch_for(workstream_id)
    base_sha = begin_data.get("main_sha")
    target = Path(os.path.abspath(begin_data.get("worktree", "")))
    expected_target = Path(os.path.abspath(
        repo.parent / ".custodian-worktrees" / f"{workstream_id}-{run_id}"
    ))
    claim_ref = f"refs/heads/dispatch-claims/{workstream_id}"
    remote_agent_ref = f"refs/heads/{branch}"
    diagnostic_ref = f"refs/heads/agent-diagnostics/{workstream_id}/{run_id}"
    host = first.get("host")
    try:
        pid = int(first.get("pid", -1))
    except (TypeError, ValueError):
        raise WorkstreamError("failed-start trace has a malformed process identity") from None
    if pid <= 1:
        raise WorkstreamError("failed-start trace has an invalid process identity")
    failures = [item.get("data", {}).get("reason", "") for item in events if item.get("event") == "run_blocked"]
    original_failure = "\n".join(failures)
    blockers: list[str] = []
    if host != __import__("socket").gethostname():
        blockers.append("failed-start host differs from this host")
    metadata_consistent = all(
        item.get("workstream") == workstream_id and item.get("run_id") == run_id
        and item.get("host") == host and item.get("pid") == pid
        for item in events
    )
    event_positions = {id(item): index for index, item in enumerate(events)}
    if (not metadata_consistent or begin.get("host") != host or begin.get("pid") != pid
            or event_positions[id(claim_event)] >= event_positions[id(begin)]
            or event_positions[id(begin)] >= event_positions[id(blocked[0])]
            or begin_data.get("branch") != branch or target != expected_target or target.is_symlink()
            or claim_data.get("remote_ref") != claim_ref or claim_data.get("main_sha") != base_sha):
        blockers.append("failed-start trace branch, path, claim ref, and base identity do not match")
    if "No space left on device" not in original_failure and "ENOSPC" not in original_failure:
        blockers.append("original checkout trace does not prove an ENOSPC failure")
    if any(item.get("event") == "worktree_published" for item in events):
        blockers.append("original failed run already published a worktree")
    local_trace_ref = f"refs/custodian/diagnostics/{workstream_id}/{run_id}"
    diagnostic = subprocess.run(["git", "show", f"{local_trace_ref}:trace.jsonl"],
                                cwd=repo, capture_output=True, check=False)
    if diagnostic.returncode != 0 or __import__("hashlib").sha256(diagnostic.stdout).hexdigest() != trace_sha:
        blockers.append("local diagnostic ref does not authenticate the exact preserved trace bytes")
    remote_diagnostic = git("ls-remote", "origin", diagnostic_ref, cwd=repo, check=False).split()
    local_diag_sha = git("rev-parse", local_trace_ref, cwd=repo, check=False)
    if not remote_diagnostic or remote_diagnostic[0] != local_diag_sha:
        blockers.append("published diagnostic ref is absent or differs from the authenticated trace")
    active_path = common_dir(repo) / "custodian-workflow" / "active" / f"{workstream_id}.json"
    active_sha = None
    active_run_id = None
    active_absent = not active_path.exists()
    if not active_absent:
        try:
            active_raw = active_path.read_bytes()
            active_sha = __import__("hashlib").sha256(active_raw).hexdigest()
            active_pointer = json.loads(active_raw)
            active_run_id = active_pointer.get("run_id")
            if active_pointer.get("workstream") != workstream_id or active_run_id != run_id:
                blockers.append("active run pointer no longer identifies the authenticated failed run")
        except (OSError, UnicodeError, json.JSONDecodeError):
            blockers.append("active run pointer is unreadable or malformed")
    remote_claim = git("ls-remote", "origin", claim_ref, cwd=repo, check=False).split()
    if not remote_claim or remote_claim[0] != claim_data.get("claim_oid"):
        blockers.append("remote dispatch claim is absent or changed")
    remote_agent = git("ls-remote", "origin", remote_agent_ref, cwd=repo, check=False).split()
    if remote_agent:
        blockers.append("remote agent branch already exists")
    local_branch = git("rev-parse", f"refs/heads/{branch}", cwd=repo, check=False)
    if not base_sha or local_branch != base_sha:
        blockers.append("local agent branch is absent or no longer at the exact failed-start base")
    target_empty = target.is_dir() and not any(target.iterdir()) if target.exists() else False
    if target.is_symlink():
        blockers.append("original worktree target path is a symlink; preserve and inspect it")
    if target.exists() and not target_empty:
        blockers.append("original worktree target path contains data; preserve and inspect it")
    if any(Path(item.get("worktree", "/nonexistent")).resolve() == target
           for item in worktree_records(repo)):
        blockers.append("original worktree path is registered in Git")
    blockers.extend(_recovery_process_blockers(repo, workstream_id, pid, target))
    main_remote = git("ls-remote", "origin", "refs/heads/main", cwd=repo, check=False).split()
    main_local = git("rev-parse", "refs/remotes/origin/main", cwd=repo, check=False)
    if not main_remote or main_remote[0] != main_local:
        blockers.append("origin/main tracking ref is stale; fetch before planning recovery")
    elif subprocess.run(["git", "merge-base", "--is-ancestor", base_sha, main_local], cwd=repo).returncode != 0:
        blockers.append("failed-start base is not an ancestor of current origin/main")
    try:
        capacity = worktree_provisioning.preflight_capacity(
            repo, profile_path=profile_path, ref="origin/main", target=target.parent,
        )
        if capacity.get("local_lfs_failures"):
            blockers.extend(
                f"required local LFS object unavailable or corrupt: {item['path']} (oid={item['oid']})"
                for item in capacity["local_lfs_failures"]
            )
        if not capacity["sufficient"]:
            if capacity["available_free_bytes"] < capacity["required_free_bytes"]:
                blockers.append("insufficient storage for the profiled worktree and safety reserve")
    except worktree_provisioning.ProvisioningError as exc:
        capacity = {"error": str(exc)}
        blockers.append(f"checkout profile or capacity estimate failed: {exc}")
    plan = {
        "schema": "custodian.workstream_initial_checkout_recovery_plan.v1",
        "workstream": workstream_id, "run_id": run_id, "trace_sha256": trace_sha,
        "diagnostic_ref": diagnostic_ref, "diagnostic_sha": local_diag_sha,
        "active_pointer_sha256": active_sha, "active_run_id": active_run_id,
        "active_pointer_absent": active_absent,
        "claim_ref": claim_ref, "claim_sha": claim_data.get("claim_oid"),
        "agent_ref": remote_agent_ref, "agent_ref_absent": not bool(remote_agent),
        "branch": branch, "branch_sha": local_branch, "base_sha": base_sha,
        "worktree": str(target), "worktree_absent": not target.exists(),
        "worktree_empty": target_empty,
        "profile": profile_path, "capacity": capacity, "blockers": blockers,
    }
    canonical = json.dumps(plan, sort_keys=True, separators=(",", ":")).encode()
    plan["plan_sha256"] = __import__("hashlib").sha256(canonical).hexdigest()
    return plan


def recover_initial_checkout(workstream_id: str, run_id: str, profile_path: str,
                             plan_sha256: str, repo: Path | None = None) -> Path:
    """Apply only an unchanged, safe plan for the exact original dispatch claim."""
    repo = (repo or root_repo()).resolve()
    try:
        with common_mutex(repo):
            with workstream_mutex(repo, workstream_id):
                plan = initial_checkout_recovery_plan(workstream_id, run_id, profile_path, repo)
                if plan["blockers"]:
                    raise WorkstreamError("recovery plan is blocked: " + "; ".join(plan["blockers"]))
                if plan["plan_sha256"] != plan_sha256:
                    raise WorkstreamError("recovery plan digest changed; re-plan and inspect")
                trace = RunTrace.start(repo, workstream_id, packet=TASK_PACKET_ROOT.as_posix(), agent="codex")
                trace.record("same_claim_checkout_recovery_begin", failed_run_id=run_id,
                             failed_trace_sha256=plan["trace_sha256"], plan_sha256=plan_sha256,
                             profile=profile_path, profile_sha256=plan["capacity"]["profile_sha256"])
                path = Path(plan["worktree"])
                _ensure_checkout_capacity(repo, profile_path, trace)
                checkout = _create_worktree_checkout(
                    repo, path, plan["branch"], "origin/main", profile_path, new_branch=False,
                )
                _record_checkout_profile(trace, checkout)
                claim_now = git("ls-remote", "origin", plan["claim_ref"], cwd=repo, check=False).split()
                agent_now = git("ls-remote", "origin", plan["agent_ref"], cwd=repo, check=False).split()
                diagnostic_now = git("ls-remote", "origin", plan["diagnostic_ref"], cwd=repo, check=False).split()
                if (not claim_now or claim_now[0] != plan["claim_sha"] or agent_now
                        or not diagnostic_now or diagnostic_now[0] != plan["diagnostic_sha"]):
                    raise WorkstreamError("pinned claim/diagnostic refs changed or agent branch appeared before publication")
                active_sha = _activate_recovered_trace(trace, run_id)
                trace.record("failed_run_active_pointer_replaced", failed_run_id=run_id,
                             previous_pointer_sha256=active_sha, failed_trace_sha256=plan["trace_sha256"])
                # Creation-only lease: a competing writer that created the ref
                # after planning makes this fail instead of accepting a fast-forward.
                git("push", f"--force-with-lease=refs/heads/{plan['branch']}:" ,
                    "-u", "origin", plan["branch"], cwd=path)
                fetch(repo)
                published = git("rev-parse", f"refs/remotes/origin/{plan['branch']}", cwd=repo)
                head = git("rev-parse", "HEAD", cwd=path)
                if published != head or git("ls-remote", "origin", plan["claim_ref"], cwd=repo).split()[0] != plan["claim_sha"]:
                    raise WorkstreamError("post-recovery ref verification failed; original claim and checkout preserved")
                trace.record("same_claim_checkout_recovery_complete", failed_run_id=run_id,
                             worktree=str(path), branch=plan["branch"], head=head,
                             remote_agent_sha=published, profile_sha256=plan["capacity"]["profile_sha256"])
                trace.complete("same_claim_checkout_recovered", publish=False)
                trace.publish()
                return path
    except (WorkflowControlError, worktree_provisioning.ProvisioningError) as exc:
        raise WorkstreamError(f"same-claim checkout recovery failed closed: {exc}") from exc


def sync_main(path: Path, *, skip_lfs: bool = False) -> bool:
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
    env = {**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"} if skip_lfs else None
    if not unique:
        git("merge", "--ff-only", "origin/main", cwd=path, env=env)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", "origin/main"], cwd=path, text=True, capture_output=True, env=env)
        if merge.returncode:
            raise WorkstreamError("origin/main merge conflicted; resolve in the preserved worktree")
    return True


def sync_remote_branch(path: Path, branch: str, *, skip_lfs: bool = False) -> bool:
    remote = f"origin/{branch}"
    head = git("rev-parse", "HEAD", cwd=path)
    remote_head = git("rev-parse", remote, cwd=path)
    if subprocess.run(["git", "merge-base", "--is-ancestor", remote_head, head], cwd=path).returncode == 0:
        return False
    if subprocess.run(["git", "merge-base", "--is-ancestor", head, remote_head], cwd=path).returncode == 0:
        git("merge", "--ff-only", remote, cwd=path,
            env={**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"} if skip_lfs else None)
    else:
        merge = subprocess.run(["git", "merge", "--no-edit", remote], cwd=path, text=True, capture_output=True,
                               env={**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"} if skip_lfs else None)
        if merge.returncode:
            raise WorkstreamError("local and remote workstream histories diverged; merge conflicted and worktree was preserved")
    return True


def start(workstream_id: str, repo: Path | None = None, *, report: dict[str, object] | None = None,
          agent: str | None = None, _claim: RemoteClaim | None = None, _trace: RunTrace | None = None,
          _lock_held: bool = False, _publish_trace: bool = True,
          profile_path: str | None = None) -> Path:
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
                active_packets = [
                    packet for packet in _associated_task_packets(repo, workstream_id)
                    if packet.parent.resolve() == (repo / TASK_PACKET_ROOT).resolve()
                ]
                packet_ref = (active_packets[0].relative_to(repo).as_posix()
                              if len(active_packets) == 1 else None)
                trace = RunTrace.start(repo, workstream_id, packet=packet_ref)
            trace.record("mutex_acquired", scope="workstream", wait_ms=round((time.monotonic() - lock_started) * 1000))
            before = worktree_records(repo)
            trace.record("start_inspection", main_sha=git("rev-parse", "origin/main", cwd=repo, check=False), worktrees=before)
            fetch(repo)
            reap_finished_checkouts(repo, exclude={workstream_id})
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
            _ensure_checkout_capacity(repo, profile_path, trace)
            if claim is None:
                claim = acquire_remote_claim(repo, workstream_id, resolve_agent_id(agent), trace.run_id, trace=trace)
            else:
                trace.record("remote_claim_reused", remote_ref=claim.ref, claim_oid=claim.oid)
            pool = repo.parent / ".custodian-worktrees"
            pool.mkdir(parents=True, exist_ok=True)
            path = pool / f"{workstream_id}-{trace.run_id}"
            trace.record("worktree_create_begin", worktree=str(path), branch=branch, main_sha=git("rev-parse", "origin/main", cwd=repo))
            _ensure_checkout_capacity(repo, profile_path, trace)
            checkout = _create_worktree_checkout(repo, path, branch, "origin/main", profile_path, new_branch=True)
            _record_checkout_profile(trace, checkout)
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
                if checkout is not None:
                    report["checkout_profile"] = checkout
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


def _resume_impl(workstream_id: str, repo: Path, report: dict[str, str] | None, trace: RunTrace,
                 profile_path: str | None = None) -> Path:
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
            if profile_path is not None:
                _ensure_checkout_capacity(repo, profile_path, trace)
            fetch(path)
            if remote_exists:
                sync_remote_branch(path, branch, skip_lfs=profile_path is not None)
            if profile_path is not None:
                sync_main(path, skip_lfs=True)
                profile = worktree_provisioning.load_profile(repo, "origin/main", profile_path)
                assert profile is not None
                try:
                    files = worktree_provisioning.configure_sparse_checkout(path, repo, "origin/main", profile)
                except worktree_provisioning.ProvisioningError as exc:
                    raise WorkstreamError(str(exc)) from exc
                if not status_clean(path):
                    raise WorkstreamError("deferred-LFS checkout is dirty after sparse setup or path-scoped hydration")
                _record_checkout_profile(trace, {
                    "profile": profile.path,
                    "profile_sha256": profile.digest,
                    "paths": [item.path for item in files],
                    "hydrated_lfs_paths": list(profile.hydrate_lfs),
                    "hydrated_lfs": [
                        {"path": item.path, "oid": item.lfs_oid, "size": item.lfs_size}
                        for item in files if item.path in profile.hydrate_lfs
                    ],
                })
            else:
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
        _ensure_checkout_capacity(repo, profile_path, trace)
        checkout = _create_worktree_checkout(repo, path, branch, f"origin/{branch}", profile_path,
                                             new_branch=True, track=True)
        _record_checkout_profile(trace, checkout)
        sync_main(path, skip_lfs=profile_path is not None)
        git("push", "origin", branch, cwd=path)
        trace.record("worktree_resumed", worktree=str(path), branch=branch, head=git("rev-parse", "HEAD", cwd=path))
        if report is not None: report["checkout"] = "resumed"
        trace.publish()
        return path


def resume(workstream_id: str, repo: Path | None = None, *, report: dict[str, str] | None = None,
           profile_path: str | None = None) -> Path:
    repo = (repo or root_repo()).resolve()
    assert_not_legacy_quarantined(repo, workstream_id, "resume")
    trace = RunTrace.resume(repo, workstream_id)
    try:
        return _resume_impl(workstream_id, repo, report, trace, profile_path)
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


def _git_source_identity(path: Path, commit: str | None = None) -> dict[str, str]:
    commit = commit or git("rev-parse", "HEAD", cwd=path)
    resolved = git("rev-parse", "--verify", f"{commit}^{{commit}}", cwd=path, check=False)
    tree = git("rev-parse", "--verify", f"{commit}^{{tree}}", cwd=path, check=False)
    if not resolved or resolved != commit or not tree:
        raise WorkstreamError("cannot resolve exact validation source commit and tree")
    status = subprocess.run(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=path, capture_output=True, check=False,
    )
    if status.returncode:
        raise WorkstreamError("cannot determine exact validation source worktree state")
    return {"commit": resolved, "tree": tree,
            "worktree_status_sha256": hashlib.sha256(status.stdout).hexdigest()}


def _after_sync_report_data(report: Path, path: Path, sync_head: str) -> tuple[dict, str]:
    try:
        raw = report.read_bytes()
        data = json.loads(raw)
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkstreamError(f"cannot read after-sync validation report {report}: {exc}") from exc
    expected = _git_source_identity(path, sync_head)
    current = _git_source_identity(path)
    if current != expected or not status_clean(path):
        raise WorkstreamError(
            "after-sync validation source changed after synchronization; report cannot be consumed"
        )
    coverage = data.get("coverage") if isinstance(data, dict) else None
    tests = data.get("tests") if isinstance(data, dict) else None
    selected = data.get("selected") if isinstance(data, dict) else None
    summary = data.get("summary") if isinstance(data, dict) else None
    test_ids = [test.get("id") for test in tests] if isinstance(tests, list) and all(
        isinstance(test, dict) for test in tests
    ) else None
    structurally_green = (
        isinstance(data, dict)
        and data.get("schema") == "custodian.validation.result.v1"
        and data.get("passed") is True
        and isinstance(coverage, dict)
        and coverage.get("complete") is True
        and coverage.get("uncovered_files") == []
        and isinstance(tests, list) and bool(tests)
        and test_ids is not None
        and all(isinstance(test_id, str) and test_id for test_id in test_ids)
        and len(set(test_ids)) == len(test_ids)
        and selected == test_ids
        and all(test.get("status") == "passed" for test in tests)
        and isinstance(summary, dict)
        and summary.get("selected") == len(tests)
        and summary.get("passed") == len(tests)
        and summary.get("failed") == 0
        and summary.get("timed_out") == 0
        and summary.get("skipped") == 0
        and summary.get("infrastructure_errors") == 0
    )
    if (not structurally_green
            or data.get("source_identity") != expected
            or data.get("source_changed_during_validation") is not False):
        raise WorkstreamError(
            "after-sync validation report must be green, complete, and bound to the exact synchronized source commit and tree"
        )
    return expected, hashlib.sha256(raw).hexdigest()


def _pending_after_sync_head(path: Path, trace: RunTrace | None) -> str | None:
    """Return the one current changed-sync head still awaiting validation."""
    if trace is None or not trace.path.is_file():
        return None
    try:
        events = [json.loads(line) for line in trace.path.read_text().splitlines() if line.strip()]
    except (OSError, ValueError, TypeError) as exc:
        raise WorkstreamError(f"cannot inspect pending after-sync validation trace: {exc}") from exc
    changed = [(i, event) for i, event in enumerate(events)
               if isinstance(event, dict) and event.get("event") == "main_sync"
               and isinstance(event.get("data"), dict)
               and event["data"].get("changed") is True]
    validations = [(i, event) for i, event in enumerate(events)
                   if isinstance(event, dict) and event.get("event") == "validation_after_sync"]
    if not changed:
        if validations:
            raise WorkstreamError("after-sync validation witness has no changed main synchronization")
        return None
    head = git("rev-parse", "HEAD", cwd=path)
    tree = git("rev-parse", "HEAD^{tree}", cwd=path)
    unresolved: list[tuple[int, str]] = []
    used: set[int] = set()
    for sync_pos, sync_event in changed:
        sync_data = sync_event["data"]
        sync_head = sync_data.get("head")
        if (not isinstance(sync_head, str)
                or not git("rev-parse", f"{sync_head}^{{commit}}", cwd=path, check=False)):
            raise WorkstreamError("changed main-sync trace contains an invalid source head")
        witnesses = [(i, event) for i, event in validations
                     if isinstance(event.get("data"), dict)
                     and event["data"].get("sync_head") == sync_head]
        if len(witnesses) > 1:
            raise WorkstreamError("changed main synchronization has duplicate after-sync validation witnesses")
        if not witnesses:
            unresolved.append((sync_pos, sync_head))
            continue
        witness_pos, witness_event = witnesses[0]
        witness = witness_event["data"]
        expected_tree = git("rev-parse", f"{sync_head}^{{tree}}", cwd=path)
        next_sync = min((i for i, event in enumerate(events)
                         if isinstance(event, dict) and event.get("event") == "main_sync"
                         and i > sync_pos), default=len(events))
        if (witness_pos <= sync_pos or witness_pos >= next_sync
                or witness.get("source_commit") != sync_head
                or witness.get("source_tree") != expected_tree
                or witness.get("source_status_sha256") != _git_source_identity(
                    path, sync_head,
                )["worktree_status_sha256"]
                or witness.get("sync_main_sha") != sync_data.get("main_sha")
                or witness.get("passed") is not True
                or not isinstance(witness.get("path"), str) or not witness["path"]
                or not isinstance(witness.get("sha256"), str)
                or re.fullmatch(r"[0-9a-f]{64}", witness["sha256"]) is None):
            raise WorkstreamError("changed main synchronization has an invalid after-sync validation witness")
        used.add(witness_pos)
    if len(used) != len(validations):
        raise WorkstreamError("after-sync validation trace contains an unmatched or reused witness")
    if not unresolved:
        return None
    if len(unresolved) != 1 or unresolved[0][1] != head or tree != git(
            "rev-parse", f"{unresolved[0][1]}^{{tree}}", cwd=path):
        raise WorkstreamError("an unvalidated changed main synchronization is stale relative to the current checkout")
    return unresolved[0][1]


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

    operator_guard = _run_operator_chassis_authority_guard(repo, path)
    if operator_guard["status"] == "blocked":
        raise WorkstreamError(
            "Operator chassis authority guard blocked finish: "
            + "; ".join(map(str, operator_guard["failures"]))
        )
    if trace and operator_guard["status"] == "passed":
        trace.record("operator_chassis_authority_guard", result="passed",
                     source_sha256=operator_guard.get("source_sha256"),
                     budget_sha256=operator_guard.get("budget_sha256"))

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
    # This exact historical recovery is governed by its separately pinned
    # continuation verifier, which authenticates its nonstandard evidence chain.
    # Ordinary workstream source spans must satisfy the current per-merge trace.
    requires_source_span_witnesses = (
        workstream_id != FAILED_IMPORT_ARCHIVE_RECOVERY["workstream"]
    )
    if trace:
        import hashlib
        trace.record("validation_report", path=validation_report.name, sha256=hashlib.sha256(validation_report.read_bytes()).hexdigest(), passed=True)

    # A prior finish attempt may already have merged origin/main and stopped
    # before validating that tree. Consume its report before checkpoint_impl
    # can publish the synchronized branch again, even when the retry's own
    # sync_main() would be a no-op.
    pending_after_sync = (
        _pending_after_sync_head(path, trace) if requires_source_span_witnesses else None
    )
    if pending_after_sync is not None:
        pending_trace_error = _source_span_sync_merge_witness_error(
            workstream_id, path, git("rev-parse", "HEAD", cwd=path), trace,
            allow_pending_after_sync=True,
        )
        if pending_trace_error:
            raise WorkstreamError(pending_trace_error)
        if validation_report_after_sync is None:
            raise WorkstreamError(
                "a prior main synchronization still requires --validation-report-after-sync; recovery state retained"
            )
        source_identity, report_sha256 = _after_sync_report_data(
            validation_report_after_sync, path, pending_after_sync,
        )
        assert trace is not None
        pending_sync_event = next(
            event for event in reversed([
                json.loads(line) for line in trace.path.read_text().splitlines() if line.strip()
            ])
            if event.get("event") == "main_sync"
            and isinstance(event.get("data"), dict)
            and event["data"].get("changed") is True
            and event["data"].get("head") == pending_after_sync
        )
        trace.record(
            "validation_after_sync", path=validation_report_after_sync.name,
            sha256=report_sha256, passed=True, sync_head=pending_after_sync,
            sync_main_sha=pending_sync_event["data"].get("main_sha"),
            source_commit=source_identity["commit"], source_tree=source_identity["tree"],
            source_status_sha256=source_identity["worktree_status_sha256"],
        )
        if not trace.publish():
            raise WorkstreamError(
                "after-sync validation trace publication failed; synchronized checkout is retained"
            )

    if trace and requires_source_span_witnesses:
        source_span_error = _source_span_sync_merge_witness_error(
            workstream_id, path, git("rev-parse", "HEAD", cwd=path), trace,
        )
        if source_span_error:
            raise WorkstreamError(source_span_error)
    archive_tip_error = _archive_transition_tip_error(workstream_id, path, trace=trace)
    if archive_tip_error:
        raise WorkstreamError(archive_tip_error)

    # Record a genuine, remotely verified checkpoint before main synchronization.
    # The public lifecycle helper is also the source of its start/completion events.
    if trace:
        _checkpoint_impl(workstream_id, False, repo, trace)
    else:
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
        sync_head = git("rev-parse", "HEAD", cwd=path)
        if validation_report_after_sync is None:
            raise WorkstreamError("main synchronization changed the tree; provide a green --validation-report-after-sync; recovery state retained")
        if requires_source_span_witnesses:
            source_identity, report_sha256 = _after_sync_report_data(
                validation_report_after_sync, path, sync_head,
            )
        elif not validation_green(validation_report_after_sync):
            raise WorkstreamError("main synchronization changed the tree; provide a green --validation-report-after-sync; recovery state retained")
        else:
            source_identity = _git_source_identity(path, sync_head)
            report_sha256 = hashlib.sha256(validation_report_after_sync.read_bytes()).hexdigest()
        if trace:
            trace.record("validation_after_sync", path=validation_report_after_sync.name,
                         sha256=report_sha256, passed=True, sync_head=sync_head,
                         sync_main_sha=git("rev-parse", f"{sync_head}^2", cwd=path),
                         source_commit=source_identity["commit"], source_tree=source_identity["tree"],
                         source_status_sha256=source_identity["worktree_status_sha256"])
            # Recheck main after the validated merge. This emits the canonical
            # final no-op witness when main is stable; if main advanced again,
            # preserve the new merge and require validation of that newer tree.
            _checkpoint_impl(workstream_id, False, repo, trace)
            changed_again = sync_main(path)
            trace.record("main_sync", changed=changed_again,
                         head=git("rev-parse", "HEAD", cwd=path),
                         main_sha=git("rev-parse", "origin/main", cwd=path))
            if changed_again:
                trace.publish()
                raise WorkstreamError(
                    "main advanced again after after-sync validation; provide a fresh green "
                    "--validation-report-after-sync for the latest synchronization; recovery state retained"
                )
    if trace:
        if not trace.publish():
            raise WorkstreamError(
                "lifecycle trace publication failed after main synchronization; "
                "task landing is blocked and the recovery checkout is retained"
            )
        if requires_source_span_witnesses:
            source_span_error = _source_span_sync_merge_witness_error(
                workstream_id, path, git("rev-parse", "HEAD", cwd=path), trace,
                require_final_noop=True,
            )
            if source_span_error:
                raise WorkstreamError(source_span_error)
        archive_tip_error = _archive_transition_tip_error(workstream_id, path, trace=trace)
        if archive_tip_error:
            raise WorkstreamError(archive_tip_error)
    operator_guard = _run_operator_chassis_authority_guard(repo, path)
    if operator_guard["status"] == "blocked":
        raise WorkstreamError(
            "Operator chassis authority guard blocked post-sync finish: "
            + "; ".join(map(str, operator_guard["failures"]))
        )
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


def _v2_acquisition_for_attached_checkout(repo: Path, workstream_id: str) -> tuple[dict, Path] | None:
    import turn_dispatcher_v2 as turn_v2
    folder = turn_v2.acquisition_record_path(repo, "placeholder").parent
    if not folder.is_dir() or folder.is_symlink():
        return None
    attached_paths = {Path(item["worktree"]).resolve(): item for item in worktree_records(repo)
                      if item.get("worktree") and item.get("branch")}
    matches = []
    for path in folder.glob("*.json"):
        if path.is_symlink() or not path.is_file():
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        checkout = Path(payload.get("checkout", "")).resolve() if isinstance(payload, dict) else None
        if (isinstance(payload, dict) and payload.get("workstream") == workstream_id
                and checkout in attached_paths
                and payload.get("local_branch") == attached_paths[checkout].get("branch", "").removeprefix("refs/heads/")):
            matches.append((payload, checkout))
    if len(matches) > 1:
        raise WorkstreamError("multiple V2 acquisition receipts identify attached checkouts for this task")
    return matches[0] if matches else None


def _finish_v2_turn(workstream_id: str, repo: Path, pool: Path) -> dict:
    """Publish and retire one V2 turn without reviving legacy session state."""
    import turn_dispatcher_v2 as turn_v2
    attached_v2 = _v2_acquisition_for_attached_checkout(repo, workstream_id)
    if not attached_v2:
        raise WorkstreamError(
            f"no attached V2 turn for {workstream_id}; acquire a fresh turn with dispatch.py or workstream.py start"
        )
    _, checkout = attached_v2
    local_branch = git("symbolic-ref", "--short", "HEAD", cwd=checkout)
    acquisition = turn_v2.read_acquisition(repo, local_branch, checkout)
    if (acquisition.get("workstream") != workstream_id
            or acquisition.get("branch") != branch_for(workstream_id)):
        raise WorkstreamError("V2 acquisition does not identify this exact task branch and checkout")
    handoff = checkout / "custodian/docs/ai_context/turn_handoffs" / f"{workstream_id}.md"
    result = turn_v2.checkpoint(
        repo, workstream_id, checkout, handoff,
        "turn checkpoint [skip render]", pool, retire=True,
    )
    print(
        f"turn checkpointed and temporary checkout retired: origin/{result['branch']} at {result['head']}"
    )
    print(
        "task completion is not asserted; standard GitHub CI/branch protection and any explicitly requested consequential review apply"
    )
    return result


def finish(workstream_id: str, validation_report: Path | None = None,
           validation_report_after_sync: Path | None = None,
           repo: Path | None = None, *, defer_root_sync: bool = False,
           recovery_evidence: Path | None = None, defer_teardown: bool = False,
           pool: Path | None = None) -> None:
    repo = (repo or root_repo()).resolve()
    if _v2_acquisition_for_attached_checkout(repo, workstream_id):
        return _finish_v2_turn(
            workstream_id, repo, (pool or Path.home() / "Projects/.custodian-turns").resolve(),
        )
    if validation_report is None:
        raise WorkstreamError("legacy workstream finish requires --validation-report")
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
            if outcome == "finished":
                reap_finished_checkouts(repo, exclude={workstream_id})
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


def gc(repo: Path | None = None, *, reap_finished: bool = False) -> None:
    repo = (repo or root_repo()).resolve()
    fetch(repo)
    if reap_finished:
        from transient_worktree_gc import sweep
        print(json.dumps(sweep(repo, apply=True, limit=32), indent=2, sort_keys=True))
        return
    script = Path(__file__).with_name("branch_hygiene.py")
    subprocess.run([sys.executable, str(script)], cwd=repo, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    p = subs.add_parser("start"); p.add_argument("workstream_id"); p.add_argument("--agent", default=None); p.add_argument("--mode", choices=("normal", "historical", "owner-authorized"), default="normal"); p.add_argument("--authorization-url"); p.add_argument("--authorization-sha256"); p.add_argument("--checkout-profile", "--profile", dest="checkout_profile", default=None); p.add_argument("--repo", type=Path, default=None); p.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    p = subs.add_parser("resume"); p.add_argument("workstream_id"); p.add_argument("--mode", choices=("normal", "historical"), default="historical"); p.add_argument("--checkout-profile", "--profile", dest="checkout_profile", default=None); p.add_argument("--repo", type=Path, default=None); p.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    p = subs.add_parser("recover-initial-checkout"); p.add_argument("workstream_id"); p.add_argument("--run-id", required=True); p.add_argument("--profile", required=True)
    mode = p.add_mutually_exclusive_group(required=True); mode.add_argument("--plan", action="store_true"); mode.add_argument("--apply", action="store_true"); p.add_argument("--plan-sha256", default=None)
    p = subs.add_parser("status"); p.add_argument("workstream_id", nargs="?")
    p = subs.add_parser("checkpoint"); p.add_argument("workstream_id"); p.add_argument("--checkout", type=Path, default=Path.cwd()); p.add_argument("--handoff", type=Path, default=None); p.add_argument("--repo", type=Path, default=None); p.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns"); p.add_argument("--keep", action="store_true")
    p = subs.add_parser("finish"); p.add_argument("workstream_id"); p.add_argument("--validation-report", type=Path); p.add_argument("--validation-report-after-sync", type=Path); p.add_argument("--pool", type=Path, default=Path.home() / "Projects/.custodian-turns")
    p.add_argument("--defer-root-sync", action="store_true",
                    help="defer persistent root synchronization when the exact packet/recovery evidence authorizes it")
    p.add_argument("--defer-root-sync-evidence", type=Path,
                    help="exact continuation metadata required for the one recovered historical review")
    p.add_argument("--defer-teardown", action="store_true",
                    help="leave the exact recovered review claim/worktree intact for independent post-land verification")
    p = subs.add_parser("preflight"); p.add_argument("workstream_id"); p.add_argument("--validation-report", type=Path); p.add_argument("--json", action="store_true")
    p = subs.add_parser("gc"); p.add_argument("--reap-finished", action="store_true",
                                           help="remove only verified clean, archived, landed transient checkouts")
    args = parser.parse_args()
    try:
        if args.command in {"start", "resume"}:
            import turn_dispatcher_v2 as turn_v2
            coordination_repo = (args.repo or root_repo()).resolve()
            mode = args.mode
            result = turn_v2.begin(coordination_repo, args.workstream_id, mode, args.pool,
                                   getattr(args, "authorization_url", None),
                                   getattr(args, "authorization_sha256", None), args.checkout_profile)
            print(json.dumps({"schema": "custodian.turn_dispatcher_v2.acquisition.v1", **result}, sort_keys=True, indent=2))
        elif args.command == "checkpoint":
            import turn_dispatcher_v2 as turn_v2
            coordination_repo = (args.repo or root_repo()).resolve()
            handoff = args.handoff or (args.checkout / "custodian/docs/ai_context/turn_handoffs" / f"{args.workstream_id}.md")
            result = turn_v2.checkpoint(coordination_repo, args.workstream_id, args.checkout,
                                        handoff, "turn checkpoint", args.pool, not args.keep)
            print(json.dumps(result, sort_keys=True, indent=2))
        elif args.command == "recover-initial-checkout":
            if args.plan:
                plan = initial_checkout_recovery_plan(args.workstream_id, args.run_id, args.profile)
                print(json.dumps(plan, sort_keys=True, indent=2))
                if plan["blockers"]:
                    return 2
            else:
                if not args.plan_sha256:
                    raise WorkstreamError("--apply requires the exact --plan-sha256 from a read-only plan")
                path = recover_initial_checkout(args.workstream_id, args.run_id, args.profile, args.plan_sha256)
                print(f"same-claim checkout recovered: {path}")
        elif args.command == "status": status(args.workstream_id)
        elif args.command == "finish":
            finish(args.workstream_id, args.validation_report, args.validation_report_after_sync,
                   defer_root_sync=args.defer_root_sync,
                   recovery_evidence=args.defer_root_sync_evidence,
                   defer_teardown=args.defer_teardown, pool=args.pool)
        elif args.command == "preflight":
            result = preflight(args.workstream_id, args.validation_report)
            if args.json:
                print(json.dumps(result, sort_keys=True, indent=2))
            else:
                print(f"closeout preflight: {'READY' if result['ready_before_sync'] else 'BLOCKED'} (before final sync)")
                print(json.dumps(result, sort_keys=True, indent=2))
        else: gc(reap_finished=args.reap_finished)
        return 0
    except WorkstreamError as error:
        print(f"workstream: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
