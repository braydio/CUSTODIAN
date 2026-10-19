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
        branch_ready and not packet_blockers and not truth_blockers and not stale_index
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
            if _publish_trace:
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
        trace.finish_blocked(str(exc), publish=_publish_trace)
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

    # Root checkout sync is subordinate and never alters user state. Resolve
    # the persistent main identity from live worktree metadata, then use the
    # shared inspect/apply policy used by OPUI and the user-facing CLI.
    main_root = next(
        (Path(item["worktree"]).resolve() for item in worktree_records(admin_repo)
         if item.get("branch") == "refs/heads/main"),
        None,
    )
    if main_root is None:
        print("persistent root synchronization pending: no attached main checkout")
    else:
        try:
            result = apply_profiles([ROOT_PROFILE], main_root)[0]
            print("persistent main checkout: " + format_result(result))
        except Exception as error:
            # Task landing is complete; root sync is best-effort and remains
            # pending with an actionable reason if the safe helper cannot run.
            print(f"persistent root synchronization pending: {error}")
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
    if defer_teardown and (workstream_id != INVALID_DISPOSITION_REVIEW or not defer_root_sync):
        raise WorkstreamError("deferred teardown is limited to the exact recovered review with root sync deferred")
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
        if defer_teardown:
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
    trace = RunTrace.resume(repo, workstream_id)
    trace.record("finish_started", validation_report=str(validation_report), after_sync_report=str(validation_report_after_sync) if validation_report_after_sync else None)
    try:
        outcome = _finish_impl(workstream_id, validation_report, validation_report_after_sync, repo, trace,
                               defer_root_sync=defer_root_sync, recovery_evidence=recovery_evidence,
                               defer_teardown=defer_teardown)
        trace.record("finish_completed", outcome=outcome)
        trace.complete(outcome, clear_active=True)
    except Exception as exc:
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
