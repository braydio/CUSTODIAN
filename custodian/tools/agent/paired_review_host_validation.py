"""Coordinator-side validation evidence for restricted paired-review sessions."""
from __future__ import annotations

import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable

from godot_project_lock import godot_home
import review_outcome
from review_receipt_delta import read_git_text, resolve_target_implementation_commit, verify_review_receipt_delta
from task_packet_contract import PACKET_ROOT, header_field, parse_packet
from task_packet_index import MANAGED_BLOCK_END, MANAGED_BLOCK_START


class HostValidationError(RuntimeError):
    pass


_IMPLEMENTATION_SUFFIXES = {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}
_REPOSITORY_MARKDOWN_PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_./-])((?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+\.md)(?![A-Za-z0-9_./-])"
)
_WORK_SURFACE_BRACE_PATH_RE = re.compile(
    r"custodian/([A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*)/"
    r"\{([A-Za-z_][A-Za-z0-9_]*(?:,[A-Za-z_][A-Za-z0-9_]*)+)\}"
    r"(\.[A-Za-z0-9]+)"
)

_GRUNT_SCOPE_ATTESTATION_PATH = (
    "custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json"
)
_GRUNT_SCOPE_SOURCE_WORKSTREAM = "grunt-candidate-raster-workflow-v1"
_GRUNT_SCOPE_SOURCE_ARCHIVE = "e29847bb2dc409ad994ac59ee3e8bb4db637142e"
_GRUNT_SCOPE_SOURCE_PACKET = (
    f"{PACKET_ROOT}/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"
)
_GRUNT_SCOPE_SOURCE_PACKET_BLOB = "73dc311261f396b1636d117730fdffb18be9965e"
_GRUNT_SCOPE_CORRECTION_WORKSTREAM = "agent-grunt-raster-review-scope-attestation-v1"
_GRUNT_SCOPE_CORRECTION_PACKET = (
    f"{PACKET_ROOT}/archived/AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md"
)
_GRUNT_SCOPE_REVIEW_WORKSTREAM = "review-agent-grunt-raster-review-scope-attestation-v1"
_GRUNT_SCOPE_REVIEW_PACKET = (
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md"
)
_GRUNT_SCOPE_MARKDOWN_FILES = {
    "custodian/docs/ai_context/CURRENT_STATE.md": "1a9368fa1d293570c968fd486972d69f73a1a687",
    "custodian/docs/ai_context/FILE_INDEX.md": "4a7f88cc00689dd55ab080230e2c43b58cf6e0c5",
    "custodian/tools/iteration/raster_pipeline/README.md": "364f0b366c6c7f25d893ca3957c05238278c0fb7",
}
_GRUNT_SCOPE_CODE_FILES = {
    "custodian/tools/iteration/raster_pipeline/__init__.py": "bd5b6ae6d224c86909372b1710d51efe7c3a289a",
    "custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json": "4e2ecb1b333c1d95d5b3b468dbcd9b7b7162a9ae",
    "custodian/tools/validation/validation_manifest.json": "f99d1deec38aac1757838bd52bee102740597808",
}
_GRUNT_SCOPE_FILES = {**_GRUNT_SCOPE_MARKDOWN_FILES, **_GRUNT_SCOPE_CODE_FILES}

_RESET_FOLLOWUP_WORKSTREAM = "agent-execution-reset-v1"
_RESET_FOLLOWUP_RUN_ID = "20261020T135839Z-db96534ed3a7"
_RESET_FOLLOWUP_BASE = "b5a46e82913455cb341c84811fd9be66b78ed138"
_RESET_FOLLOWUP_CLAIM_OID = "599c97403c67d53d60f3c394d09c756ff2b79c2d"
_RESET_FOLLOWUP_ARCHIVE = "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0"
_RESET_FOLLOWUP_MERGE = "f43f3e6ec32a95ebbdc1e98f39f790d275411992"
_RESET_FOLLOWUP_MERGE_MAIN = "134e4c2913fbb88ea25fd5395ff6dc059e26f05f"
_RESET_FOLLOWUP_HEAD = "f635c33d8bb209d9cbc4fafb4aff88af27084867"
_RESET_FOLLOWUP_PATHS = {
    "custodian/tools/agent/test_workstream.py",
    "custodian/docs/ai_context/task_packets/archived/AGENT_EXECUTION_RESET_V1.md",
    "AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md",
}
_RESET_ARCHIVE_PATHS = {
    "AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md",
    f"{PACKET_ROOT}/AGENT_EXECUTION_RESET_V1.md",
    f"{PACKET_ROOT}/AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/README.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md",
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md",
    f"{PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md",
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md",
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md",
}
_BLENDER_SOURCE_WORKSTREAM = "operator-motion-foundry-blender-2d-rig-v1"
_BLENDER_SOURCE_ARCHIVE = "a6604a80be32c9078336ae48de6c4e43ec6815c7"
_BLENDER_SOURCE_ROOT = (
    "custodian/asset_drop/source_work/operator/motion_foundry/"
    "operator_south_visible_surface_v1/blender/"
)
_BLENDER_SOURCE_PATH = _BLENDER_SOURCE_ROOT + "operator_south_cutout_rig_v1.blend"
_BLENDER_RECEIPT_PATH = _BLENDER_SOURCE_ROOT + "rig_build_receipt.json"
_BLENDER_SOURCE_OID = "b13a70b4c26da0b76f5b04d66902d93e7e03fc1394398c3135759305b9fb656f"


def _managed_packet_index_additive_reconciliation(first_parent: bytes,
                                                  second_parent: bytes,
                                                  merged: bytes) -> bool:
    """Accept only additive managed-index entries copied from prior main."""
    start = MANAGED_BLOCK_START.encode("ascii")
    end = MANAGED_BLOCK_END.encode("ascii")

    def split(value: bytes) -> tuple[bytes, bytes, bytes] | None:
        if value.count(start) != 1 or value.count(end) != 1:
            return None
        start_at = value.find(start)
        end_at = value.find(end)
        if end_at <= start_at or value.find(start, start_at + len(start)) >= 0:
            return None
        block_end = end_at + len(end)
        prefix = value[:start_at]
        block = value[start_at:block_end]
        suffix = value[block_end:]
        if not block.startswith(start + b"\n") or not block.endswith(b"\n" + end):
            return None
        return prefix, block, suffix

    original = split(first_parent)
    prior_main = split(second_parent)
    reconciled = split(merged)
    if original is None or prior_main is None or reconciled is None:
        return False
    if original[0] != reconciled[0] or original[2] != reconciled[2]:
        return False

    def entries(block: bytes) -> list[bytes]:
        return block[len(start) + 1:-(len(end) + 1)].split(b"\n")

    original_entries = entries(original[1])
    prior_entries = entries(prior_main[1])
    merged_entries = entries(reconciled[1])
    if (len(set(original_entries)) != len(original_entries)
            or len(set(prior_entries)) != len(prior_entries)
            or len(set(merged_entries)) != len(merged_entries)
            or not set(original_entries).issubset(merged_entries)
            or not set(merged_entries).issubset(prior_entries)):
        return False
    # Keep the original order and require added entries to retain their order
    # from the recorded prior-main managed block. The merge may omit other
    # second-parent additions because this is an additive reconciliation, not
    # an instruction to copy the entire current index.
    original_iter = iter(merged_entries)
    if not all(any(value == candidate for candidate in original_iter)
               for value in original_entries):
        return False
    added = [entry for entry in merged_entries if entry not in set(original_entries)]
    prior_added = [entry for entry in prior_entries if entry not in set(original_entries)]
    prior_iter = iter(prior_added)
    return all(any(value == candidate for candidate in prior_iter) for value in added)


def _expand_braced_work_surface_paths(work_surface: str) -> set[str]:
    """Expand bounded file alternatives in backtick paths, never as globs."""
    expanded: set[str] = set()
    for token in re.findall(r"`([^`]+)`", work_surface):
        if "{" not in token and "}" not in token:
            continue
        if not token.startswith("custodian/"):
            if "custodian/" in token:
                raise HostValidationError("braced Work surface path must be repository-relative")
            continue
        match = _WORK_SURFACE_BRACE_PATH_RE.fullmatch(token)
        if match is None:
            raise HostValidationError("malformed braced Work surface path")
        directory, raw_names, suffix = match.groups()
        names = raw_names.split(",")
        if (not 2 <= len(names) <= 32 or len(set(names)) != len(names)
                or suffix.lower() not in _IMPLEMENTATION_SUFFIXES):
            raise HostValidationError("braced Work surface path is unbounded or unsupported")
        expanded.update(f"custodian/{directory}/{name}{suffix}" for name in names)
    return expanded


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


def _verify_reset_archive_merge_followup(
    repo: Path, target_workstream: str, target_packet_path: str,
    source_base: str, landing_commit: str, trace_landing: str,
    trace_main_sync_sha: str | None, trace_ref: str, run_id: str,
    events: list[dict], claim_record: dict, landing_record: dict,
) -> dict:
    """Authenticate the one known archive -> sync merge -> bounded follow-up history."""
    if (target_workstream != _RESET_FOLLOWUP_WORKSTREAM
            or target_packet_path != f"{PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md"
            or source_base != _RESET_FOLLOWUP_BASE
            or landing_commit != _RESET_FOLLOWUP_ARCHIVE
            or trace_landing != _RESET_FOLLOWUP_HEAD
            or trace_ref != f"refs/remotes/origin/agent-diagnostics/{_RESET_FOLLOWUP_WORKSTREAM}/{_RESET_FOLLOWUP_RUN_ID}"
            or run_id != _RESET_FOLLOWUP_RUN_ID
            or claim_record.get("ref") != trace_ref
            or claim_record.get("run_id") != run_id
            or landing_record.get("ref") != trace_ref
            or landing_record.get("run_id") != run_id
            or claim_record.get("base") != _RESET_FOLLOWUP_BASE
            or claim_record.get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or landing_record.get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or claim_record.get("worktree") != landing_record.get("path")
            or trace_main_sync_sha != _RESET_FOLLOWUP_MERGE_MAIN):
        raise HostValidationError("reset post-merge source span does not match its pinned run and claim identity")

    claim_events = [event for event in events if event.get("event") == "remote_claim_acquired"]
    publish_events = [event for event in events if event.get("event") == "worktree_published"]
    sync_events = [event for event in events if event.get("event") == "main_sync"]
    if (len(claim_events) != 1 or claim_events[0]["data"].get("claim_oid") != _RESET_FOLLOWUP_CLAIM_OID
            or claim_events[0]["data"].get("main_sha") != _RESET_FOLLOWUP_BASE
            or len(publish_events) != 1
            or publish_events[0]["data"].get("branch") != f"agent/{_RESET_FOLLOWUP_WORKSTREAM}"
            or publish_events[0]["data"].get("head") != _RESET_FOLLOWUP_BASE
            or publish_events[0]["data"].get("clean") is not True
            or publish_events[0]["data"].get("worktree") != landing_record.get("path")
            or len(sync_events) != 1
            or sync_events[0]["data"] != {
                "changed": False, "head": _RESET_FOLLOWUP_HEAD,
                "main_sha": _RESET_FOLLOWUP_MERGE_MAIN,
            }):
        raise HostValidationError("reset post-merge source span lacks its unique immutable claim and no-op sync events")

    parents = _git(repo, "rev-list", "--parents", "-n", "1", _RESET_FOLLOWUP_MERGE).split()
    if parents != [_RESET_FOLLOWUP_MERGE, _RESET_FOLLOWUP_ARCHIVE, _RESET_FOLLOWUP_MERGE_MAIN]:
        raise HostValidationError("reset post-merge source span has unexpected synchronization merge parents")
    followup_parent = _git(repo, "rev-parse", f"{_RESET_FOLLOWUP_HEAD}^1")
    if followup_parent != _RESET_FOLLOWUP_MERGE:
        raise HostValidationError("reset post-merge follow-up is not the one pinned child of the sync merge")
    status = subprocess.run(
        ["git", "diff", "--name-status", "--no-renames", _RESET_FOLLOWUP_MERGE,
         _RESET_FOLLOWUP_HEAD], cwd=repo, text=True, capture_output=True,
    )
    if status.returncode:
        raise HostValidationError("cannot inspect reset post-merge follow-up file set")
    rows = [line.split("\t") for line in status.stdout.splitlines()]
    if len(rows) != len(_RESET_FOLLOWUP_PATHS) or any(
        len(row) != 2 or row[0] != "M" for row in rows
    ) or {row[1] for row in rows} != _RESET_FOLLOWUP_PATHS:
        raise HostValidationError("reset post-merge follow-up contains unpinned paths or file operations")
    for path in sorted(_RESET_FOLLOWUP_PATHS):
        for revision in (_RESET_FOLLOWUP_MERGE, _RESET_FOLLOWUP_HEAD):
            entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                   cwd=repo, capture_output=True)
            if entry.returncode or not entry.stdout:
                raise HostValidationError("reset post-merge follow-up path is missing from a pinned tree")
            mode = entry.stdout.split(b"\t", 1)[0].split()[0]
            if mode != b"100644":
                raise HostValidationError("reset post-merge follow-up has a non-regular or executable path")
    return {
        "canonical_archive_commit": _RESET_FOLLOWUP_ARCHIVE,
        "sync_merge_commit": _RESET_FOLLOWUP_MERGE,
        "sync_merge_main_parent": _RESET_FOLLOWUP_MERGE_MAIN,
        "post_merge_followup_commit": _RESET_FOLLOWUP_HEAD,
        "followup_paths": sorted(_RESET_FOLLOWUP_PATHS),
        "merge_tree_proof": "exact-content-addressed-merge-and-ordered-parents",
    }


def _verify_archive_sync_followup(
    repo: Path, target_workstream: str, target_packet_text: str,
    landing_commit: str, trace_landing: str, events: list[dict],
) -> dict:
    """Prove archive-first sync merges and one declared follow-up across retry races."""
    chain = subprocess.run(
        ["git", "rev-list", "--first-parent", "--reverse", f"{landing_commit}..{trace_landing}"],
        cwd=repo, text=True, capture_output=True,
    )
    if chain.returncode or not chain.stdout.splitlines():
        raise HostValidationError("post-merge source span has no first-parent history after its archive")
    commits = chain.stdout.splitlines()
    merges: list[dict[str, str]] = []
    followup_commits: list[str] = []
    previous = landing_commit
    for commit in commits:
        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()
        if len(parents) == 3 and parents[1] == previous:
            merges.append({"commit": commit, "first_parent": parents[1], "main_sha": parents[2]})
        elif len(parents) == 2 and parents[1] == previous and merges:
            followup_commits.append(commit)
        else:
            raise HostValidationError("post-merge source span has an unbound commit or merge topology")
        previous = commit
    if not merges or not followup_commits:
        raise HostValidationError("post-merge source span needs a sync merge and a declared follow-up")

    sync_events = [(index, event.get("data", {})) for index, event in enumerate(events)
                   if event.get("event") == "main_sync"]
    landing_started = [index for index, event in enumerate(events)
                       if event.get("event") == "landing_started"]
    if len(landing_started) != 1:
        raise HostValidationError("post-merge source trace lacks a unique landing start")
    expected_sync = []
    for merge in merges:
        matches = [(index, data) for index, data in sync_events
                   if isinstance(data, dict)
                   and data.get("head") == merge["commit"]
                   and data.get("main_sha") == merge["main_sha"]
                   and (data.get("changed") is True or data.get("changed") is False)]
        if len(matches) != 1:
            raise HostValidationError("post-merge source merge lacks a unique exact main-sync witness")
        expected_sync.append(matches[0][0])
    if expected_sync != sorted(expected_sync) or expected_sync[-1] >= landing_started[0]:
        raise HostValidationError("post-merge source sync events are out of lifecycle order")
    if any(index >= landing_started[0] for index, _ in sync_events):
        raise HostValidationError("post-merge source trace records sync after landing started")

    # No-op retries may occur at an authenticated current tip in this same
    # lineage, but may not name a stale merge, arbitrary head, or main SHA.
    for index, data in sync_events:
        if index in expected_sync:
            continue
        prior_merges = [merge_index for merge_index, sync_index in enumerate(expected_sync)
                        if sync_index < index]
        if not isinstance(data, dict) or not prior_merges or index >= landing_started[0]:
            raise HostValidationError("post-merge source span has an unbound no-op main-sync event")
        latest = prior_merges[-1]
        latest_commit_index = commits.index(merges[latest]["commit"])
        next_merge_index = (commits.index(merges[latest + 1]["commit"])
                            if latest + 1 < len(merges) else len(commits))
        allowed_heads = set(commits[latest_commit_index:next_merge_index])
        if (data.get("changed") is not False or data.get("head") not in allowed_heads
                or data.get("main_sha") != merges[latest]["main_sha"]):
            raise HostValidationError("post-merge source no-op event does not bind the current sync tip")
    final_parents = _git(repo, "rev-list", "--parents", "-n", "1", trace_landing).split()
    if len(final_parents) == 2:
        final_retry = [(index, data) for index, data in sync_events
                       if isinstance(data, dict) and data == {
                           "changed": False, "head": trace_landing,
                           "main_sha": merges[-1]["main_sha"]}]
        if len(final_retry) != 1 or final_retry[0][0] >= landing_started[0]:
            raise HostValidationError("post-merge source span lacks its final no-op retry witness")
    previous_sync_index = -1
    for merge, index in zip(merges, expected_sync):
        if index <= previous_sync_index:
            raise HostValidationError("post-merge source sync merges are out of trace order")
        previous_sync_index = index
        expected_tree = subprocess.run(
            ["git", "merge-tree", "--write-tree", merge["first_parent"], merge["main_sha"]],
            cwd=repo, text=True, capture_output=True,
        )
        actual_tree = _git(repo, "rev-parse", f"{merge['commit']}^{{tree}}")
        expected_tree_sha = expected_tree.stdout.splitlines()[0].strip() if expected_tree.stdout.splitlines() else None
        if not expected_tree_sha:
            raise HostValidationError("post-merge sync tree has no deterministic merge-tree result")
        if expected_tree.returncode or expected_tree_sha != actual_tree:
            resolution_paths = set(_changed_paths(repo, f"{expected_tree_sha}..{actual_tree}"))
            readme_path = f"{PACKET_ROOT}/README.md"
            first_readme = subprocess.run(["git", "show", f"{merge['first_parent']}:{readme_path}"],
                                          cwd=repo, capture_output=True)
            main_readme = subprocess.run(["git", "show", f"{merge['main_sha']}:{readme_path}"],
                                         cwd=repo, capture_output=True)
            merged_readme = subprocess.run(["git", "show", f"{merge['commit']}:{readme_path}"],
                                           cwd=repo, capture_output=True)
            if (resolution_paths != {readme_path} or first_readme.returncode
                    or main_readme.returncode or merged_readme.returncode
                    or not _managed_packet_index_additive_reconciliation(
                        first_readme.stdout, main_readme.stdout, merged_readme.stdout)):
                raise HostValidationError(
                    "post-merge sync differs from deterministic merge beyond additive managed-index reconciliation"
                )

    packet_header = target_packet_text.split("\n## ", 1)[0].splitlines()
    work_surface_lines = []
    for index, line in enumerate(packet_header):
        if not re.match(r"^-\s*Work surface:\s*", line):
            continue
        work_surface_lines.append(re.sub(r"^-\s*Work surface:\s*", "", line))
        for continuation in packet_header[index + 1:]:
            if re.match(r"^-\s*[A-Z][^:]*:\s*", continuation):
                break
            if continuation.startswith((" ", "\t")):
                work_surface_lines.append(continuation.strip())
        break
    work_surface = " ".join(work_surface_lines)
    declared = {token for token in re.findall(r"`([^`]+)`", work_surface)
                if token.startswith("custodian/") and "{" not in token and "}" not in token}
    declared.update(_expand_braced_work_surface_paths(work_surface))
    followup_paths: set[str] = set()
    for commit in followup_commits:
        parent = _git(repo, "rev-parse", f"{commit}^1")
        status = subprocess.run(["git", "diff", "--name-status", "--no-renames", parent, commit],
                                cwd=repo, text=True, capture_output=True)
        if status.returncode:
            raise HostValidationError("cannot inspect post-merge follow-up file operations")
        rows = [line.split("\t") for line in status.stdout.splitlines()]
        if (not rows or any(len(row) != 2 or row[0] != "M" or row[1] not in declared for row in rows)):
            raise HostValidationError("post-merge follow-up has undeclared paths or non-modification operations")
        for _, path in rows:
            for revision in (parent, commit):
                entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                       cwd=repo, capture_output=True)
                if entry.returncode or not entry.stdout:
                    raise HostValidationError("post-merge follow-up path is missing from a pinned tree")
                mode = entry.stdout.split(b"\t", 1)[0].split()[0]
                if mode != b"100644":
                    raise HostValidationError("post-merge follow-up contains a non-regular or executable path")
            followup_paths.add(path)
    if not _source_code_paths(sorted(followup_paths)):
        raise HostValidationError("post-merge follow-up has no declared implementation or test source")
    return {
        "canonical_archive_commit": landing_commit,
        "sync_merges": merges,
        "sync_merge_commit": merges[0]["commit"],
        "sync_merge_main_parent": merges[0]["main_sha"],
        "post_merge_followup_commit": followup_commits[0],
        "post_merge_followup_commits": followup_commits,
        "source_head": trace_landing,
        "followup_paths": sorted(followup_paths),
        "merge_tree_proof": "exact-trace-parent-and-bounded-declared-follow-up",
    }


def _verified_blender_source_artifact(repo: Path, landing_commit: str,
                                      target_packet_text: str,
                                      extra_archive_paths: set[str]) -> dict | None:
    if _BLENDER_SOURCE_PATH not in extra_archive_paths:
        return None
    if landing_commit != _BLENDER_SOURCE_ARCHIVE:
        raise HostValidationError("Blender source artifact is not from its exact pinned archive")
    work_surface = header_field(target_packet_text, "Work surface") or ""
    if (_BLENDER_SOURCE_ROOT not in work_surface
            or "operator_south_cutout_rig_v1.blend" not in target_packet_text
            or _BLENDER_RECEIPT_PATH not in extra_archive_paths):
        raise HostValidationError("Blender source artifact is outside its packet-declared source-work contract")
    for revision in (_BLENDER_SOURCE_ARCHIVE,):
        entry = subprocess.run(["git", "ls-tree", "-z", revision, "--", _BLENDER_SOURCE_PATH],
                               cwd=repo, capture_output=True)
        if entry.returncode or not entry.stdout or entry.stdout.split(b"\t", 1)[0].split()[0] != b"100644":
            raise HostValidationError("Blender source artifact is not a tracked regular archive file")
    pointer = _git(repo, "show", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_SOURCE_PATH}")
    pointer_match = re.fullmatch(
        r"version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n?",
        pointer,
    )
    try:
        receipt = json.loads(_git(repo, "show", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_RECEIPT_PATH}"))
    except (HostValidationError, json.JSONDecodeError) as exc:
        raise HostValidationError("Blender source artifact receipt is missing or malformed") from exc
    if (pointer_match is None or pointer_match.group(1) != _BLENDER_SOURCE_OID
            or not isinstance(receipt, dict)
            or receipt.get("schema") != "custodian.operator_motion_foundry.blender_rig_receipt.v1"
            or receipt.get("status") != "candidate_not_art_approved"
            or receipt.get("blend_sha256") != _BLENDER_SOURCE_OID):
        raise HostValidationError("Blender source artifact does not match its exact LFS and receipt evidence")
    return {
        "path": _BLENDER_SOURCE_PATH,
        "archive_commit": _BLENDER_SOURCE_ARCHIVE,
        "lfs_sha256": _BLENDER_SOURCE_OID,
        "receipt_path": _BLENDER_RECEIPT_PATH,
        "receipt_blob": _git(repo, "rev-parse", f"{_BLENDER_SOURCE_ARCHIVE}:{_BLENDER_RECEIPT_PATH}"),
    }


def _changed_paths(repo: Path, revision: str) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", "--no-renames", revision], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(result.stderr.strip() or "could not enumerate source-span paths")
    return sorted({path for path in result.stdout.splitlines() if path})


def _source_code_paths(paths: list[str]) -> set[str]:
    return {path for path in paths if Path(path).suffix.lower() in _IMPLEMENTATION_SUFFIXES}


def _trace_events(repo: Path, ref: str) -> list[dict]:
    result = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(f"source-span workstream trace is unreadable: {ref}")
    events = []
    try:
        for line in result.stdout.splitlines():
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError("event is not an object")
            events.append(value)
    except (json.JSONDecodeError, ValueError) as exc:
        raise HostValidationError(f"source-span workstream trace is malformed: {ref}") from exc
    if not events:
        raise HostValidationError(f"source-span workstream trace is empty: {ref}")
    if any(event.get("schema") != "custodian.workflow_trace_event.v1"
           or event.get("schema_version") != 1
           or not isinstance(event.get("data"), dict) for event in events):
        raise HostValidationError(f"source-span workstream trace has invalid event provenance: {ref}")
    return events


def _verified_landing_claim(repo: Path, event: dict, workstream: str,
                            landing_run_id: str, selected_base: str) -> bool:
    """Verify a claim event preserved in a landing trace, including retries."""
    data = event.get("data")
    if (event.get("run_id") != landing_run_id or event.get("workstream") != workstream
            or not isinstance(data, dict)):
        return False
    base = data.get("main_sha")
    claim_oid = data.get("claim_oid")
    if (not isinstance(base, str) or not re.fullmatch(r"[0-9a-f]{40,64}", base)
            or not isinstance(claim_oid, str) or not re.fullmatch(r"[0-9a-f]{40,64}", claim_oid)
            or data.get("local_ref") != f"refs/custodian/claims/{workstream}/{landing_run_id}"
            or data.get("remote_ref") != f"refs/heads/dispatch-claims/{workstream}"):
        return False
    resolved = subprocess.run(["git", "rev-parse", "--verify", f"{claim_oid}^{{commit}}"],
                              cwd=repo, text=True, capture_output=True)
    if resolved.returncode or resolved.stdout.strip() != claim_oid:
        return False
    parents = subprocess.run(["git", "rev-list", "--parents", "-n", "1", claim_oid],
                             cwd=repo, text=True, capture_output=True)
    fields = parents.stdout.split()
    if parents.returncode or len(fields) != 2 or fields[1] != base:
        return False
    subject = subprocess.run(["git", "show", "-s", "--format=%s", claim_oid],
                             cwd=repo, text=True, capture_output=True)
    expected_subject = re.compile(
        rf"^workstream claim {re.escape(workstream)} [^:\s]+:[0-9]+:{re.escape(landing_run_id)}$"
    )
    if subject.returncode or not expected_subject.fullmatch(subject.stdout.rstrip()):
        return False
    return subprocess.run(["git", "merge-base", "--is-ancestor", base, selected_base],
                          cwd=repo, capture_output=True).returncode == 0


def _git_tree_entry(repo: Path, revision: str, path: str) -> tuple[str, str] | None:
    result = subprocess.run(["git", "ls-tree", revision, "--", path], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise HostValidationError(f"cannot inspect pinned Git tree entry: {path}")
    fields = result.stdout.rstrip("\n").split("\t", 1)
    if len(fields) != 2 or fields[1] != path:
        return None
    mode_type_sha = fields[0].split()
    if len(mode_type_sha) != 3:
        raise HostValidationError(f"malformed pinned Git tree entry: {path}")
    return mode_type_sha[0], mode_type_sha[2]


def _is_ancestor(repo: Path, ancestor: str, descendant: str) -> bool:
    return subprocess.run(["git", "merge-base", "--is-ancestor", ancestor, descendant],
                          cwd=repo, capture_output=True).returncode == 0


def _source_path_documented(path: str, target_packet_text: str, documented: set[str],
                            packet_terms: set[str], uid_companion_paths: set[str],
                            attested_scope_paths: set[str]) -> bool:
    """Check exact documented source identity, including only verified attestation paths."""
    if path in uid_companion_paths:
        return _source_path_documented(path[:-4], target_packet_text, documented,
                                       packet_terms, uid_companion_paths, attested_scope_paths)
    if path in attested_scope_paths:
        return True
    name = Path(path).name
    if path in documented or name in target_packet_text:
        return True
    if name.startswith("test_") and re.search(r"\b(test|tests|fixture)\b", target_packet_text, re.I):
        terms = set(re.findall(r"[a-z0-9]+", Path(name).stem.lower())) - {"test", "tests", "v1"}
        return len(terms & packet_terms) >= 2
    return False


def _scope_review_receipt(review_text: str) -> dict[str, str] | None:
    """Parse one flat reviewer-authored PASS receipt from the archived review packet."""
    sections = list(re.finditer(r"(?m)^## Independent Review[ \t]*$", review_text))
    if len(sections) != 1:
        return None
    section = review_text[sections[0].end():]
    following = re.search(r"(?m)^## [^\r]*$", section)
    if following:
        section = section[:following.start()]
    names = (
        "Schema", "Review workstream", "Review target workstream", "Status",
        "Blocking defects", "Material gaps", "Reviewer context", "Reviewer provenance",
        "Reviewed main", "Reviewed implementation commit",
    )
    values = {}
    for name in names:
        matches = re.findall(rf"(?m)^- {re.escape(name)}: `([^`\r\n]+)`\s*$", section)
        if len(matches) != 1:
            return None
        values[name] = matches[0].strip()
    return values


def _verified_grunt_scope_attestation(repo: Path, reviewed_main: str,
                                     extra_archive_paths: set[str]) -> dict:
    """Verify the one exact Grunt post-hoc Markdown exception and its accepted review.

    The JSON is intentionally not self-authorizing. Its correction must have an
    archived, canonical independent PASS, with the review's target receipt and
    implementation identity both verified from Git history.
    """
    attested_archive_paths = extra_archive_paths.intersection(_GRUNT_SCOPE_FILES)
    if attested_archive_paths != set(_GRUNT_SCOPE_FILES):
        raise HostValidationError("post-hoc Grunt scope attestation does not cover all six historical paths")

    source_packet_entry = _git_tree_entry(repo, _GRUNT_SCOPE_SOURCE_ARCHIVE,
                                          _GRUNT_SCOPE_SOURCE_PACKET)
    if source_packet_entry != ("100644", _GRUNT_SCOPE_SOURCE_PACKET_BLOB):
        raise HostValidationError("pinned original Grunt packet blob or mode does not match")
    source_entries = {}
    for path, expected_blob in _GRUNT_SCOPE_FILES.items():
        entry = _git_tree_entry(repo, _GRUNT_SCOPE_SOURCE_ARCHIVE, path)
        if entry != ("100644", expected_blob):
            raise HostValidationError(f"pinned historical Grunt Markdown blob or mode does not match: {path}")
        source_entries[path] = {"mode": entry[0], "blob": entry[1]}

    attestation_entry = _git_tree_entry(repo, reviewed_main, _GRUNT_SCOPE_ATTESTATION_PATH)
    if attestation_entry is None or attestation_entry[0] != "100644":
        raise HostValidationError("reviewed main lacks the regular-file Grunt scope attestation")
    try:
        attestation_bytes = subprocess.run(
            ["git", "show", f"{reviewed_main}:{_GRUNT_SCOPE_ATTESTATION_PATH}"],
            cwd=repo, capture_output=True, check=True,
        ).stdout
        attestation = json.loads(attestation_bytes)
    except (subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        raise HostValidationError("Grunt scope attestation is unreadable or invalid JSON") from exc
    expected_attestation = {
        "schema": "custodian.review_source_scope_attestation.v1",
        "source_workstream": _GRUNT_SCOPE_SOURCE_WORKSTREAM,
        "source_archive_commit": _GRUNT_SCOPE_SOURCE_ARCHIVE,
        "source_packet_path": _GRUNT_SCOPE_SOURCE_PACKET,
        "source_packet_blob": _GRUNT_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": [
            {"path": path, "blob": blob, "mode": "100644"}
            for path, blob in sorted(_GRUNT_SCOPE_FILES.items())
        ],
        "reason": "The original archived Work surface omitted these exact Grunt raster paths.",
        "post_hoc": True,
    }
    canonical_bytes = (json.dumps(expected_attestation, indent=2, sort_keys=True) + "\n").encode("utf-8")
    if attestation != expected_attestation or attestation_bytes != canonical_bytes:
        raise HostValidationError("Grunt scope attestation bytes do not match the exact post-hoc authorization")

    origin_result = subprocess.run(
        ["git", "log", "--format=%H", reviewed_main, "--",
         _GRUNT_SCOPE_ATTESTATION_PATH], cwd=repo, text=True, capture_output=True,
    )
    if origin_result.returncode:
        raise HostValidationError("cannot resolve Grunt scope attestation origin commit")
    origins = [commit for commit in origin_result.stdout.splitlines()
               if _git_tree_entry(repo, commit, _GRUNT_SCOPE_ATTESTATION_PATH) == attestation_entry]
    if len(origins) != 1:
        raise HostValidationError("Grunt scope attestation has missing or ambiguous exact-blob origin history")
    origin_commit = origins[0]

    # The correction review is the sole activating authority. Validate both
    # reviewer outcome and the separately appended target receipt using the
    # repository's canonical parsers and receipt-delta verifier.
    try:
        correction_text = read_git_text(repo, reviewed_main, _GRUNT_SCOPE_CORRECTION_PACKET)
        review_text = read_git_text(repo, reviewed_main, _GRUNT_SCOPE_REVIEW_PACKET)
    except ValueError as exc:
        raise HostValidationError("Grunt scope attestation lacks archived correction review evidence") from exc
    correction = parse_packet(_GRUNT_SCOPE_CORRECTION_PACKET, correction_text)
    review = parse_packet(_GRUNT_SCOPE_REVIEW_PACKET, review_text)
    if (correction.error or correction.kind not in {"implementation", "correction"}
            or correction.status != "complete"
            or correction.workstream != _GRUNT_SCOPE_CORRECTION_WORKSTREAM
            or review.error or review.kind != "review" or review.status != "complete"
            or review.workstream != _GRUNT_SCOPE_REVIEW_WORKSTREAM
            or review.review_target_workstream != _GRUNT_SCOPE_CORRECTION_WORKSTREAM
            or review.review_target_packet != _GRUNT_SCOPE_CORRECTION_PACKET):
        raise HostValidationError("Grunt scope attestation correction/review packet identity is incomplete")

    outcome, outcome_error = review_outcome.parse_review_outcome(review_text)
    if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
        raise HostValidationError("Grunt scope attestation has no canonical independent PASS outcome")
    accepted, _, acceptance_reason = review_outcome.review_acceptance(
        review_text, correction_text, _GRUNT_SCOPE_REVIEW_WORKSTREAM,
    )
    if not accepted:
        raise HostValidationError(f"Grunt scope attestation review is not accepted: {acceptance_reason}")
    review_baseline = read_git_text(repo, outcome["Reviewed main"], _GRUNT_SCOPE_CORRECTION_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, outcome["Reviewed main"], _GRUNT_SCOPE_CORRECTION_PACKET,
        _GRUNT_SCOPE_CORRECTION_WORKSTREAM, review_baseline,
    )
    if identity_error:
        raise HostValidationError(f"Grunt scope attestation target identity is invalid: {identity_error}")
    if not _is_ancestor(repo, origin_commit, implementation_commit):
        raise HostValidationError("Grunt scope attestation was not present by its correction archive")
    if not _is_ancestor(repo, outcome["Reviewed main"], reviewed_main):
        raise HostValidationError("accepted Grunt attestation review is not an ancestor of reviewed main")
    if not _is_ancestor(repo, implementation_commit, outcome["Reviewed main"]):
        raise HostValidationError("accepted attestation review predates the correction implementation")
    receipt, receipt_error = verify_review_receipt_delta(
        review_baseline, correction_text, review_workstream=_GRUNT_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], target_implementation_commit=implementation_commit,
    )
    if receipt_error or not receipt:
        raise HostValidationError(f"accepted Grunt attestation review target receipt is invalid: {receipt_error}")
    identity_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=_GRUNT_SCOPE_REVIEW_WORKSTREAM,
        target_workstream=_GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        reviewed_main=outcome["Reviewed main"], implementation_commit=implementation_commit,
        run_id=outcome["Run ID"], review_cycle=review.review_cycle,
    )
    if identity_error:
        raise HostValidationError(f"accepted Grunt attestation review identity is invalid: {identity_error}")
    reviewer_receipt = _scope_review_receipt(review_text)
    if reviewer_receipt is None:
        raise HostValidationError("accepted Grunt attestation review lacks one canonical reviewer receipt")
    expected_receipt = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": _GRUNT_SCOPE_REVIEW_WORKSTREAM,
        "Review target workstream": _GRUNT_SCOPE_CORRECTION_WORKSTREAM,
        "Status": "passed", "Blocking defects": "0", "Material gaps": "0",
        "Reviewer context": "fresh", "Reviewed main": outcome["Reviewed main"],
        "Reviewed implementation commit": implementation_commit,
    }
    if any(reviewer_receipt.get(field) != value for field, value in expected_receipt.items()) or (
        reviewer_receipt.get("Reviewer provenance") not in {"different-agent", "same-agent-fresh-context"}
    ):
        raise HostValidationError("accepted Grunt attestation reviewer receipt does not match its PASS outcome")

    return {
        "kind": "accepted-post-hoc-exact-markdown-attestation",
        "attestation_path": _GRUNT_SCOPE_ATTESTATION_PATH,
        "attestation_commit": origin_commit,
        "attestation_blob": attestation_entry[1],
        "attestation_sha256": _sha256(attestation_bytes),
        "source_archive_commit": _GRUNT_SCOPE_SOURCE_ARCHIVE,
        "source_packet_blob": _GRUNT_SCOPE_SOURCE_PACKET_BLOB,
        "source_files": source_entries,
        "approval_review_workstream": _GRUNT_SCOPE_REVIEW_WORKSTREAM,
        "approval_review_packet": _GRUNT_SCOPE_REVIEW_PACKET,
        "approval_review_packet_blob": _git_tree_entry(
            repo, reviewed_main, _GRUNT_SCOPE_REVIEW_PACKET,
        )[1],
        "approval_target_packet": _GRUNT_SCOPE_CORRECTION_PACKET,
        "approval_target_packet_blob": _git_tree_entry(
            repo, reviewed_main, _GRUNT_SCOPE_CORRECTION_PACKET,
        )[1],
        "approval_reviewed_main": outcome["Reviewed main"],
        "approval_run_id": outcome["Run ID"],
        "approval_implementation_commit": implementation_commit,
        "approval_outcome": outcome["Outcome"],
    }
def _split_landing_source_span(repo: Path, reviewed_main: str, landing_commit: str,
                               target_workstream: str, target_packet_path: str,
                               target_packet_text: str) -> dict:
    """Resolve an archive landing to its exact source-bearing workstream range.

    The archive-introduction commit remains the canonical implementation identity.
    One immutable lifecycle trace may pin that commit directly, or pin a verified
    two-parent main-sync merge whose first parent is the archive commit. The
    immediately preceding source span must be a linear first-parent range and its
    implementation paths must be named by the archived packet.
    """
    active_packet = target_packet_path.replace("/archived/", "/", 1)
    prefix = f"refs/remotes/origin/agent-diagnostics/{target_workstream}/"
    refs = subprocess.run(["git", "for-each-ref", "--format=%(refname)", prefix],
                          cwd=repo, text=True, capture_output=True)
    if refs.returncode:
        raise HostValidationError("could not enumerate committed source-span workstream traces")
    claim_records = []
    landing_records = []
    legacy_records = []
    for ref in refs.stdout.splitlines():
        events = _trace_events(repo, ref)
        run_ids = {event.get("run_id") for event in events}
        if len(run_ids) != 1:
            continue
        run_id = next(iter(run_ids))
        if not ref.endswith("/" + str(run_id)):
            continue
        if any(event.get("workstream") != target_workstream or event.get("packet") != active_packet
               for event in events):
            continue
        started = [event for event in events if event.get("event") == "remote_claim_acquired"]
        published = [event for event in events if event.get("event") == "worktree_published"]
        landing_started = [event for event in events if event.get("event") == "landing_started"]
        landed = [event for event in events if event.get("event") == "landing_completed"]
        teardown_started = [event for event in events if event.get("event") == "teardown_started"]
        teardown_completed = [event for event in events if event.get("event") == "teardown_completed"]
        branch = f"agent/{target_workstream}"
        if len(started) == len(published) == 1 and not landing_started and not landed:
            claim, publication = started[0]["data"], published[0]["data"]
            base, path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(path, str) and Path(path).is_absolute()
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": path, "events": events})
            continue
        if (not published and len(landing_started) == len(landed) == len(teardown_started) == len(teardown_completed) == 1
                and len(started) <= 1):
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            trace_landing = start_data.get("start_sha")
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            if (isinstance(trace_landing, str) and re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                    and start_data.get("branch") == branch and start_data.get("target") == "main"
                    and landed_data.get("head") == trace_landing and landed_data.get("outcome") == "landed"
                    and teardown_data.get("head") == trace_landing and teardown_data.get("branch") == branch
                    and removed_data.get("head") == trace_landing and removed_data.get("branch") == branch
                    and removed_data.get("worktree_removed") is True and isinstance(path, str)
                    and Path(path).is_absolute()):
                landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                        "path": path, "branch": branch, "events": events})
            continue
        if (len(started) == len(published) == len(landing_started) == len(landed) == 1
                and not teardown_started and not teardown_completed):
            claim, publication = started[0]["data"], published[0]["data"]
            start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
            base, trace_landing = claim.get("main_sha"), start_data.get("start_sha")
            path = publication.get("worktree")
            if (isinstance(base, str) and publication.get("head") == base
                    and publication.get("branch") == branch and start_data.get("branch") == branch
                    and isinstance(trace_landing, str) and landed_data.get("head") == trace_landing):
                legacy_records.append((ref, run_id, base, trace_landing, path, events))
            continue
        if len(landing_started) != 1 or len(landed) != 1:
            continue
        start_data, landed_data = landing_started[0]["data"], landed[0]["data"]
        trace_landing = start_data.get("start_sha")
        if (not isinstance(trace_landing, str) or not re.fullmatch(r"[0-9a-f]{40,64}", trace_landing)
                or start_data.get("branch") != branch or start_data.get("target") != "main"
                or landed_data.get("head") != trace_landing):
            continue
        if teardown_started or teardown_completed:
            if len(teardown_started) != 1 or len(teardown_completed) != 1:
                continue
            teardown_data, removed_data = teardown_started[0]["data"], teardown_completed[0]["data"]
            path = teardown_data.get("worktree")
            if (landed_data.get("outcome") != "landed"
                    or teardown_data.get("head") != trace_landing or teardown_data.get("branch") != branch
                    or removed_data.get("head") != trace_landing or removed_data.get("branch") != branch
                    or (removed_data.get("worktree") is not None
                        and removed_data.get("worktree") != path)
                    or removed_data.get("worktree_removed") is not True
                    or not isinstance(path, str) or not Path(path).is_absolute()):
                continue
        else:
            path = None
        if len(started) > 1 or len(published) > 1:
            continue
        if started:
            # A landing trace may preserve an earlier failed claim attempt. It
            # is not sufficient provenance alone; cross-check its base against
            # the independently validated claim record below.
            if started[0]["data"].get("main_sha") is None:
                continue
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": branch, "events": events})

        # Support older single-trace lifecycles that contain claim, publication,
        # landing, and teardown together. The same strict field checks apply to
        # each role, and pair uniqueness below prevents ambiguous reuse.
        if len(started) == len(published) == 1:
            claim, publication = started[0]["data"], published[0]["data"]
            base, published_path = claim.get("main_sha"), publication.get("worktree")
            if (isinstance(base, str) and re.fullmatch(r"[0-9a-f]{40,64}", base)
                    and publication.get("head") == base and publication.get("upstream") == base
                    and publication.get("branch") == branch and publication.get("clean") is True
                    and isinstance(published_path, str) and Path(published_path).is_absolute()
                    and published_path == path
                    and claim.get("remote_ref") == f"refs/heads/dispatch-claims/{target_workstream}"
                    and isinstance(claim.get("claim_oid"), str)
                    and re.fullmatch(r"[0-9a-f]{40,64}", claim["claim_oid"])):
                claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                                      "branch": branch, "worktree": published_path,
                                      "events": events})

    # Bind the two trace roles independently. A landing trace can preserve an
    # earlier failed remote-claim attempt; its teardown path identifies the
    # published checkout, while the exact claim base is checked against it.
    if not claim_records and len(legacy_records) == 1:
        ref, run_id, base, trace_landing, path, events = legacy_records[0]
        claim_records.append({"ref": ref, "run_id": run_id, "base": base,
                              "branch": f"agent/{target_workstream}", "worktree": path,
                              "events": events})
        landing_records.append({"ref": ref, "run_id": run_id, "landing": trace_landing,
                                "path": path, "branch": f"agent/{target_workstream}",
                                "events": events})
    recorded_main = re.findall(r"(?im)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$",
                               target_packet_text)
    if len(recorded_main) != 1:
        raise HostValidationError("split target packet has missing or ambiguous Reviewed main provenance")
    exact_base = recorded_main[0]
    matching_pairs = []
    for claim in claim_records:
        for completed in landing_records:
            if (claim["worktree"] == completed["path"]
                    and claim["branch"] == completed["branch"]
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        claim["base"]], cwd=repo, capture_output=True).returncode == 0
                    and subprocess.run(["git", "merge-base", "--is-ancestor", exact_base,
                                        completed["landing"]], cwd=repo, capture_output=True).returncode == 0):
                landing_claims = [event for event in completed["events"]
                                  if event.get("event") == "remote_claim_acquired"]
                if (len(landing_claims) > 1
                        or any(not _verified_landing_claim(repo, event, target_workstream,
                                                           completed["run_id"], claim["base"])
                               for event in landing_claims)):
                    continue
                matching_pairs.append((claim, completed))
    if len(matching_pairs) != 1:
        raise HostValidationError("split landing has missing or ambiguous exact workstream trace provenance")
    claim_record, landing_record = matching_pairs[0]
    source_base = claim_record["base"]
    trace_landing = landing_record["landing"]
    ref, run_id, events = landing_record["ref"], landing_record["run_id"], landing_record["events"]

    for sha, label in ((source_base, "source base"), (recorded_main[0], "packet Reviewed main"),
                       (landing_commit, "canonical landing"), (trace_landing, "trace landing"),
                       (reviewed_main, "pinned reviewed main")):
        resolved = subprocess.run(["git", "rev-parse", "--verify", f"{sha}^{{commit}}"], cwd=repo,
                                  text=True, capture_output=True)
        if resolved.returncode or resolved.stdout.strip() != sha:
            raise HostValidationError(f"split landing {label} is not an available full commit SHA")
    if subprocess.run(["git", "merge-base", "--is-ancestor", recorded_main[0], source_base],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base does not descend from packet Reviewed main")
    if subprocess.run(["git", "merge-base", "--is-ancestor", source_base, landing_commit],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("source-span base is not an ancestor of the canonical landing")

    # A legitimate synchronization merge is narrowly bound by both its parent
    # order and the immutable lifecycle main_sync event. Do not derive the source
    # span from this merge: it may contain unrelated changes from prior main.
    trace_landing_kind = "canonical-archive"
    trace_main_sync_sha = None
    reset_followup = None
    archive_sync_followup = None
    if trace_landing != landing_commit:
        sync_events = [event for event in events if event.get("event") == "main_sync"]
        if (target_workstream == _RESET_FOLLOWUP_WORKSTREAM
                and landing_commit == _RESET_FOLLOWUP_ARCHIVE
                and trace_landing == _RESET_FOLLOWUP_HEAD):
            sync_data = sync_events[0].get("data", {}) if len(sync_events) == 1 else {}
            if not isinstance(sync_data, dict):
                raise HostValidationError("reset follow-up trace has malformed main-sync provenance")
            trace_main_sync_sha = sync_data.get("main_sha")
            trace_landing_kind = "main-sync-merge-followup"
        else:
            history = subprocess.run(
                ["git", "rev-list", "--first-parent", "--reverse",
                 f"{landing_commit}..{trace_landing}"], cwd=repo, text=True, capture_output=True,
            )
            commits = history.stdout.splitlines() if history.returncode == 0 else []
            first_parents = [_git(repo, "rev-list", "--parents", "-n", "1", commit).split()
                             for commit in commits]
            saw_followup = False
            valid_tail = len(first_parents) >= 2 and len(first_parents[0]) == 3 \
                and first_parents[0][1] == landing_commit
            for index, parents in enumerate(first_parents[1:], start=1):
                if len(parents) == 3 and parents[1] == commits[index - 1]:
                    continue
                if len(parents) == 2 and parents[1] == commits[index - 1]:
                    saw_followup = True
                    continue
                valid_tail = False
                break
            has_followup_chain = (
                valid_tail and saw_followup
            )
            if has_followup_chain:
                archive_sync_followup = _verify_archive_sync_followup(
                    repo, target_workstream, target_packet_text, landing_commit, trace_landing, events,
                )
                trace_main_sync_sha = archive_sync_followup["sync_merges"][-1]["main_sha"]
                trace_landing_kind = "main-sync-merge-followup"
            else:
                parent_line = _git(repo, "rev-list", "--parents", "-n", "1", trace_landing).split()
                if len(parent_line) != 3 or parent_line[1] != landing_commit:
                    raise HostValidationError("trace landing is not the exact two-parent archive-first main-sync merge")
                second_parent = parent_line[2]
                exact_true = [event for event in sync_events
                              if isinstance(event.get("data"), dict)
                              and event["data"].get("changed") is True
                              and event["data"].get("head") == trace_landing]
                if len(exact_true) == 1:
                    sync_data = exact_true[0]["data"]
                    valid_sync = sync_data.get("main_sha") == second_parent
                elif exact_true:
                    valid_sync = False
                else:
                    # A retry is admitted only for a unique immutable no-op event.
                    sync_data = sync_events[0].get("data", {}) if len(sync_events) == 1 else {}
                    valid_sync = (len(sync_events) == 1
                                  and isinstance(sync_data, dict)
                                  and sync_data.get("changed") is False
                                  and sync_data.get("head") == trace_landing
                                  and sync_data.get("main_sha") == second_parent)
                if not valid_sync:
                    raise HostValidationError("trace landing lacks an exact main-sync merge provenance event")
                trace_landing_kind = "main-sync-merge"
                trace_main_sync_sha = second_parent
    if subprocess.run(["git", "merge-base", "--is-ancestor", trace_landing, reviewed_main],
                      cwd=repo, capture_output=True).returncode:
        raise HostValidationError("trace landing is not an ancestor of pinned reviewed main")
    if target_workstream == _RESET_FOLLOWUP_WORKSTREAM:
        reset_followup = _verify_reset_archive_merge_followup(
            repo, target_workstream, target_packet_path, source_base, landing_commit,
            trace_landing, trace_main_sync_sha, ref, run_id, events, claim_record, landing_record,
        )

    # Validate the canonical archive commit independently of the later main-sync
    # merge. Its allowed closeout consists only of this packet's active deletion,
    # archived creation, exact root summary and generated packet index.
    archive_parent_line = _git(repo, "rev-list", "--parents", "-n", "1", landing_commit).split()
    if len(archive_parent_line) != 2:
        raise HostValidationError("canonical archive landing must have exactly one parent")
    archive_parent = archive_parent_line[1]
    archive_paths = set(_changed_paths(repo, f"{archive_parent}..{landing_commit}"))
    summary_path = f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"
    allowed_archive_paths = {active_packet, target_packet_path, summary_path,
                             f"{PACKET_ROOT}/README.md"}
    if not {active_packet, target_packet_path}.issubset(archive_paths):
        raise HostValidationError("archive landing is missing its active or archived packet closeout")

    extra_archive_paths = archive_paths - allowed_archive_paths
    pinned_reset_archive = (
        target_workstream == _RESET_FOLLOWUP_WORKSTREAM
        and landing_commit == _RESET_FOLLOWUP_ARCHIVE
    )
    if pinned_reset_archive and archive_paths != _RESET_ARCHIVE_PATHS:
        raise HostValidationError("reset canonical archive has an unpinned closeout path set")
    source_bearing_archive = bool(extra_archive_paths) and not pinned_reset_archive
    source_artifact = _verified_blender_source_artifact(
        repo, landing_commit, target_packet_text, extra_archive_paths,
    ) if target_workstream == _BLENDER_SOURCE_WORKSTREAM else None
    # Godot .gd.uid is a data-only companion, not an implementation source.
    # Permit it only when its .gd is modified in this source-bearing archive;
    # the .gd must also pass the unchanged packet documentation/coverage gates.
    uid_companion_paths = {
        path for path in extra_archive_paths
        if path.endswith(".gd.uid") and path[:-4] in extra_archive_paths
    }
    scope_attestation = None
    if source_bearing_archive:
        work_surface = header_field(target_packet_text, "Work surface") or ""
        declared_markdown_paths = set(_REPOSITORY_MARKDOWN_PATH_RE.findall(work_surface))
        if (target_workstream == "grunt-candidate-raster-workflow-v1"
                and extra_archive_paths.intersection(_GRUNT_SCOPE_FILES)):
            if landing_commit != _GRUNT_SCOPE_SOURCE_ARCHIVE:
                raise HostValidationError("post-hoc Grunt scope attestation names a different source archive")
            scope_attestation = _verified_grunt_scope_attestation(
                repo, reviewed_main, extra_archive_paths,
            )
        attested_paths = set(scope_attestation["source_files"]) if scope_attestation else set()
        if any(Path(path).suffix.lower() not in _IMPLEMENTATION_SUFFIXES
               and path not in uid_companion_paths
               and not (source_artifact is not None and path == source_artifact["path"])
               and not (Path(path).suffix.lower() == ".md"
                        and (path in declared_markdown_paths
                             or path in attested_paths))
               for path in extra_archive_paths):
            raise HostValidationError("archive-only landing contains unrelated paths")
        for path in sorted(uid_companion_paths):
            uid_text = _git(repo, "show", f"{landing_commit}:{path}")
            if not re.fullmatch(r"uid://[a-z0-9]{8,32}", uid_text):
                raise HostValidationError("archive landing contains malformed Godot script UID sidecar")
    elif archive_paths - allowed_archive_paths and not pinned_reset_archive:
        raise HostValidationError("archive-only landing contains unrelated paths")

    def has_path(revision: str, path: str) -> bool:
        result = subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                                capture_output=True)
        return result.returncode == 0

    if (not has_path(archive_parent, active_packet) or has_path(landing_commit, active_packet)
            or has_path(archive_parent, target_packet_path) or not has_path(landing_commit, target_packet_path)):
        raise HostValidationError("archive-only landing does not delete the active packet and create its canonical archive")
    # Archive closeout and source-bearing paths must all be regular, non-executable files.
    for revision in (archive_parent, landing_commit):
        for path in archive_paths:
            result = subprocess.run(["git", "ls-tree", "-z", revision, "--", path],
                                    cwd=repo, capture_output=True)
            if result.returncode:
                raise HostValidationError("could not inspect archive closeout file modes")
            if result.stdout:
                mode = result.stdout.split(b"\t", 1)[0].split()[0]
                if mode != b"100644":
                    raise HostValidationError("archive landing contains an executable or non-regular path")

    # A source-bearing archive includes its final source/test edits. An archive-
    # only closeout ends at its parent. Neither span includes a later main-sync.
    followup = reset_followup or archive_sync_followup
    source_head = landing_commit if source_bearing_archive else archive_parent
    if followup is not None:
        source_head = followup.get("source_head", followup["post_merge_followup_commit"])
    chain_end = landing_commit if followup is not None else source_head
    chain = subprocess.run(["git", "rev-list", "--first-parent", "--reverse",
                            f"{source_base}..{chain_end}"], cwd=repo,
                           text=True, capture_output=True)
    if chain.returncode or not chain.stdout.splitlines():
        raise HostValidationError("split landing has no source-bearing commits after its recorded workstream base")
    commits = chain.stdout.splitlines()
    if followup is not None:
        commits.extend(followup.get("post_merge_followup_commits",
                                    [followup["post_merge_followup_commit"]]))
    merge_commits = []
    owned_paths = set()
    for index, commit in enumerate(commits):
        parents = _git(repo, "rev-list", "--parents", "-n", "1", commit).split()[1:]
        if len(parents) == 1:
            owned_paths.update(_changed_paths(repo, f"{parents[0]}..{commit}"))
        else:
            merge_commits.append((index, commit, parents))
    if len(merge_commits) > 1:
        raise HostValidationError("split source span contains multiple synchronization merges")
    checkpoint_resume_merge = None
    if merge_commits:
        if ref != claim_record["ref"] or run_id != claim_record["run_id"]:
            raise HostValidationError("checkpoint-resume merge claim and lifecycle events are not from one trace")
        merge_index, merge_sha, parents = merge_commits[0]
        if len(parents) != 2 or merge_index == 0 or parents[0] != commits[merge_index - 1]:
            raise HostValidationError("checkpoint-resume merge has invalid ordered parents")
        first_parent, second_parent = parents
        if not _is_ancestor(repo, source_base, second_parent):
            raise HostValidationError("checkpoint-resume merge second parent is outside published history")
        if not _is_ancestor(repo, second_parent, reviewed_main):
            raise HostValidationError("checkpoint-resume merge second parent is outside reviewed main")
        checkpoint_events = [
            (i, event) for i, event in enumerate(events)
            if event.get("event") == "checkpoint_completed"
            and isinstance(event.get("data"), dict)
            and event["data"].get("remote_head") == first_parent
            and event["data"].get("branch") == claim_record["branch"]
            and event["data"].get("removed") is False
        ]
        resume_events = [
            (i, event) for i, event in enumerate(events)
            if event.get("event") == "worktree_resumed"
            and isinstance(event.get("data"), dict)
            and event["data"].get("head") == merge_sha
            and event["data"].get("branch") == claim_record["branch"]
            and event["data"].get("worktree") == claim_record["worktree"]
        ]
        if len(checkpoint_events) != 1 or len(resume_events) != 1:
            raise HostValidationError("checkpoint-resume merge lacks a unique matching lifecycle pair")
        checkpoint_pos, checkpoint_event = checkpoint_events[0]
        resume_pos, resume_event = resume_events[0]
        if checkpoint_pos >= resume_pos or resume_pos >= len(events) - 1:
            raise HostValidationError("checkpoint-resume lifecycle events are out of order")
        preceding_checkpoints = [event for i, event in enumerate(events)
                                 if i < resume_pos and event.get("event") == "checkpoint_completed"]
        all_resumes = [event for event in events if event.get("event") == "worktree_resumed"]
        if preceding_checkpoints != [checkpoint_event] or all_resumes != [resume_event]:
            raise HostValidationError("checkpoint-resume trace contains conflicting lifecycle events")
        sync_events = [(i, event) for i, event in enumerate(events)
                       if event.get("event") == "main_sync"]
        later_noop = [(i, event) for i, event in sync_events
                      if i > resume_pos and isinstance(event.get("data"), dict)
                      and event["data"].get("changed") is False
                      and event["data"].get("head") == landing_commit
                      and event["data"].get("main_sha") == second_parent]
        if len(later_noop) != 1:
            raise HostValidationError("checkpoint-resume merge lacks its later exact no-op main-sync witness")
        merge_tree = subprocess.run(["git", "merge-tree", "--write-tree", first_parent, second_parent],
                                    cwd=repo, text=True, capture_output=True)
        stored_tree = _git(repo, "rev-parse", f"{merge_sha}^{{tree}}")
        if merge_tree.returncode or not merge_tree.stdout.splitlines() \
                or merge_tree.stdout.splitlines()[0].strip() != stored_tree:
            raise HostValidationError("checkpoint-resume merge tree differs from deterministic Git merge")
        inherited_paths = set(_changed_paths(repo, f"{source_base}..{second_parent}"))
        # Local authorship is the union of first-parent non-merge commit diffs.
        # Paths touched on both sides remain owned and keep their test coverage.
        for path in owned_paths:
            if any(subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"],
                                  cwd=repo, capture_output=True).returncode
                   for revision in (merge_sha, source_head)):
                raise HostValidationError("checkpoint-resume merge loses workstream-owned source")
        checkpoint_resume_merge = {
            "commit": merge_sha, "first_parent": first_parent, "second_parent": second_parent,
            "checkpoint_event_index": checkpoint_pos, "resume_event_index": resume_pos,
            "main_sync_event_index": later_noop[0][0], "tree": stored_tree,
            "checkpoint_event_id": {"run_id": run_id, "position": checkpoint_pos,
                                    "timestamp_utc": checkpoint_event.get("timestamp_utc")},
            "resume_event_id": {"run_id": run_id, "position": resume_pos,
                                "timestamp_utc": resume_event.get("timestamp_utc")},
            "main_sync_event_id": {"run_id": run_id, "position": later_noop[0][0],
                                   "timestamp_utc": later_noop[0][1].get("timestamp_utc")},
            "merge_tree_proof": "git-merge-tree-write-tree-exact",
            "owned_paths": sorted(owned_paths), "inherited_paths": sorted(inherited_paths),
            "overlapping_paths": sorted(owned_paths.intersection(inherited_paths)),
        }
    if followup is None and (
        (source_bearing_archive and commits[-1] != landing_commit)
        or (not source_bearing_archive and archive_parent != commits[-1])
    ):
        raise HostValidationError("split source span does not end at its canonical archive boundary")
    if followup is not None:
        source_paths = sorted(set(_changed_paths(repo, f"{source_base}..{landing_commit}")
                                  + followup["followup_paths"]))
    else:
        source_paths = sorted(owned_paths) if checkpoint_resume_merge else _changed_paths(
            repo, f"{source_base}..{source_head}")
    code_paths = _source_code_paths(source_paths)
    if not code_paths:
        raise HostValidationError("split source span contains no implementation source or test files")

    # The archived task must itself identify every source/test path so a branch
    # carrying unrelated code cannot be laundered through an archive-only commit.
    documented = set(re.findall(r"custodian/[A-Za-z0-9_./-]+", target_packet_text))
    documented.add(f"{target_workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md")
    work_surface = header_field(target_packet_text, "Work surface") or ""
    documented.update(_expand_braced_work_surface_paths(work_surface))
    packet_terms = set(re.findall(r"[a-z0-9]+", target_packet_text.lower()))
    archive_source_paths = set(extra_archive_paths) if source_bearing_archive else set()

    attested_source_paths = (
        set(scope_attestation["source_files"]) if scope_attestation is not None else set()
    )

    def is_documented(path: str) -> bool:
        if path in archive_source_paths and path in documented:
            return True
        return _source_path_documented(
            path, target_packet_text, documented, packet_terms,
            uid_companion_paths, attested_source_paths,
        )

    undocumented = {path for path in code_paths if not is_documented(path)}
    undocumented.update(path for path in archive_source_paths if not is_documented(path))
    if undocumented:
        raise HostValidationError(
            "split source span contains code/test paths not documented by its target packet: "
            + ", ".join(sorted(undocumented))
        )

    if (trace_landing_kind in {"main-sync-merge", "main-sync-merge-followup"}
            and reset_followup is None):
        if archive_sync_followup is not None:
            sync_merges = archive_sync_followup["sync_merges"]
        else:
            sync_merges = [{"commit": trace_landing, "first_parent": landing_commit,
                            "main_sha": trace_main_sync_sha}]
        readme_path = f"{PACKET_ROOT}/README.md"
        sync_source_paths = set(source_paths)
        for sync_merge in sync_merges:
            merge = sync_merge["commit"]
            first_parent = sync_merge["first_parent"]
            changed_in_merge = set(_changed_paths(repo, f"{first_parent}..{merge}"))
            if target_packet_path in changed_in_merge:
                raise HostValidationError(
                    "main-sync merge changes archived target packet from archive-first-parent version"
                )
            changed_source_paths = changed_in_merge.intersection(sync_source_paths)
            if readme_path in changed_source_paths:
                first_parent_readme = subprocess.run(
                    ["git", "show", f"{first_parent}:{readme_path}"], cwd=repo,
                    capture_output=True,
                )
                second_parent_readme = subprocess.run(
                    ["git", "show", f"{sync_merge['main_sha']}:{readme_path}"], cwd=repo,
                    capture_output=True,
                )
                merged_readme = subprocess.run(
                    ["git", "show", f"{merge}:{readme_path}"], cwd=repo,
                    capture_output=True,
                )
                if (first_parent_readme.returncode or second_parent_readme.returncode
                        or merged_readme.returncode
                        or not _managed_packet_index_additive_reconciliation(
                            first_parent_readme.stdout, second_parent_readme.stdout,
                            merged_readme.stdout)):
                    raise HostValidationError(
                        "main-sync README change is not an additive managed-index reconciliation"
                    )
                changed_source_paths.remove(readme_path)
            if changed_source_paths:
                raise HostValidationError(
                    "main-sync merge changes reviewed source from archive-first-parent version"
                )

    trace_sha = subprocess.run(["git", "rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=repo,
                               text=True, capture_output=True, check=True).stdout.strip()
    trace_blob = subprocess.run(["git", "show", f"{ref}:trace.jsonl"], cwd=repo,
                                capture_output=True, check=True).stdout
    provenance = {"kind": "workstream-lifecycle-trace",
            "ref": ref, "trace_commit": trace_sha, "trace_sha256": _sha256(trace_blob),
            "run_id": run_id, "workstream": target_workstream,
            "trace_landing_commit": trace_landing,
            "trace_landing_kind": trace_landing_kind,
            "trace_main_sync_sha": trace_main_sync_sha,
            "claim_trace": {"ref": claim_record["ref"], "run_id": claim_record["run_id"],
                            "worktree": claim_record["worktree"], "branch": claim_record["branch"],
                            "base": claim_record["base"]},
            "landing_trace": {"ref": landing_record["ref"], "run_id": landing_record["run_id"],
                              "worktree": landing_record["path"], "branch": landing_record["branch"],
                              "landing": landing_record["landing"]},
            "archive_kind": "source-bearing" if source_bearing_archive else "archive-only"}
    if checkpoint_resume_merge is not None:
        provenance["checkpoint_resume_merge"] = checkpoint_resume_merge
    if scope_attestation is not None:
        provenance["scope_attestation"] = scope_attestation
    if followup is not None:
        provenance["post_merge_followup"] = followup
    if source_artifact is not None:
        provenance["source_artifact"] = source_artifact
    return {"base": source_base, "head": source_head, "commits": commits,
            "paths": source_paths, "provenance": provenance}


def resolve_validation_source_span(repo: Path, reviewed_main: str, implementation_commit: str,
                                   target_workstream: str | None = None,
                                   target_packet_path: str | None = None) -> dict:
    """Keep canonical review identity separate from the source/test validation range."""
    repo = Path(repo).resolve()
    landing = _git(repo, "rev-parse", "--verify", f"{implementation_commit}^{{commit}}")
    parent = _git(repo, "rev-parse", f"{landing}^1")
    landing_paths = _changed_paths(repo, f"{parent}..{landing}")

    def has_path(revision: str, path: str) -> bool:
        return subprocess.run(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=repo,
                              capture_output=True).returncode == 0

    archive_transition = False
    if target_workstream and target_packet_path and "/archived/" in target_packet_path:
        active_packet = target_packet_path.replace("/archived/", "/", 1)
        archive_transition = (has_path(parent, active_packet) and not has_path(landing, active_packet)
                             and not has_path(parent, target_packet_path)
                             and has_path(landing, target_packet_path))
    if _source_code_paths(landing_paths) and not archive_transition:
        return {"base": parent, "head": landing, "commits": [landing], "paths": landing_paths,
                "provenance": {"kind": "canonical-implementation-commit"}}
    if not target_workstream or not target_packet_path:
        raise HostValidationError("archive-only implementation requires exact target workstream provenance")
    try:
        packet_text = _git(repo, "show", f"{reviewed_main}:{target_packet_path}")
    except HostValidationError as exc:
        raise HostValidationError("cannot load pinned target packet for source-span provenance") from exc
    return _split_landing_source_span(repo, reviewed_main, landing, target_workstream,
                                      target_packet_path, packet_text)


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
    code_paths = _source_code_paths(implementation_paths)
    reported_paths = set(report.get("changed_files") or [])
    if not code_paths.issubset(reported_paths):
        raise HostValidationError("host validation changed-file selection omits part of the implementation diff")
    covered = set(coverage.get("covered_files") or [])
    excluded = set(coverage.get("excluded_files") or [])
    if not code_paths.issubset(covered | excluded):
        raise HostValidationError("host validation coverage omits files from the implementation diff")
    code_paths = _source_code_paths(implementation_paths)
    if not code_paths or not code_paths.issubset(covered):
        raise HostValidationError("host validation does not cover changed implementation source/test files")
    covered_by = coverage.get("covered_by")
    if not isinstance(covered_by, dict) or any(
        not (set(covered_by.get(path, [])) & set(selected)) for path in code_paths
    ):
        raise HostValidationError("host validation has no selected test owner for changed source/test files")


def run_coordinator_validation(repo: Path, run_dir: Path, reviewed_main: str, implementation_commit: str,
                               *, target_workstream: str | None = None,
                               target_packet_path: str | None = None,
                               run_validation: Callable | None = None,
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

    source_span = resolve_validation_source_span(
        worktree, reviewed_main, implementation_commit, target_workstream, target_packet_path,
    )
    source_base = source_span["base"]
    source_head = source_span["head"]
    implementation_paths = list(source_span["paths"])
    # The validation base is the source-span base, so every source/test file
    # under review must also be selected by the canonical changed-file runner.
    selected_source_paths = _git_paths(worktree, f"{source_base}..{reviewed_main}")
    required_changed_paths = set(_source_code_paths(implementation_paths))
    if not required_changed_paths or not required_changed_paths.issubset(selected_source_paths):
        raise HostValidationError("canonical changed-file selection does not include the implementation diff")
    code_paths = [path for path in implementation_paths
                  if Path(path).suffix.lower() in {".gd", ".py", ".gdshader", ".tscn", ".tres", ".json"}]
    source_hashes = _source_hashes(worktree, code_paths)
    capabilities = capability_probe()

    command = [sys.executable, str(worktree / "custodian/tools/validation/run_validation.py"),
               "--changed", "--base", source_base, "--json"]
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
        "source_span": source_span,
        "source_span_base": source_base,
        "source_span_head": source_head,
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
                                  implementation_commit: str, *, target_workstream: str | None = None,
                                  target_packet_path: str | None = None,
                                  expected_report_sha256: str,
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
    expected_span = resolve_validation_source_span(
        repo, reviewed_main, implementation_commit, target_workstream, target_packet_path,
    )
    if (metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or metadata.get("source_span") != expected_span
            or metadata.get("source_span_base") != expected_span.get("base")
            or metadata.get("source_span_head") != expected_span.get("head")
            or metadata.get("report_sha256") != expected_report_sha256
            or metadata.get("source_changed_during_validation") is not False):
        raise HostValidationError("coordinator validation provenance does not match the pinned review identity")
    if _git(Path(repo), "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main:
        raise HostValidationError("reviewed worktree HEAD changed after host validation")
    if _source_hashes(Path(repo), metadata.get("code_paths") or []) != metadata.get("source_sha256"):
        raise HostValidationError("reviewed implementation source changed after host validation")
    if metadata.get("implementation_paths") != expected_span.get("paths"):
        raise HostValidationError("coordinator source path inventory differs from the verified source span")
    _validate_report(report, expected_span.get("paths") or [])
    return report
