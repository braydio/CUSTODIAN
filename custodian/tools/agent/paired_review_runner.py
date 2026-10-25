#!/usr/bin/env python3
"""Claim and supervise one exact paired review in a fresh ephemeral Codex session."""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

TOOLS_ROOT = Path(__file__).resolve().parents[1]
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))
from godot_project_lock import job_budget_root, scratch_root
import paired_review_host_validation as host_validation
from paired_review_host_validation import (
    HostValidationError,
    _validate_report,
    run_coordinator_validation,
    verify_coordinator_validation,
)

import review_outcome
from task_packet_contract import ID_RE, PACKET_ROOT, parse_packet
from review_receipt_delta import (
    read_git_text,
    render_review_receipt,
    resolve_target_implementation_commit,
    verify_review_receipt_delta,
)
from workflow_control import common_dir, redact

SCHEMA = "custodian.paired_review_run.v1"
CLAIM_SENTINEL = "CUSTODIAN_DISPATCH_RESULT_JSON:"
CONTINUATION_SCHEMA = "custodian.paired_review_continuation.v1"

# This recovery exists for one independently reviewed, already-held run. It is
# intentionally not an alternate parser or a general invalid-disposition retry.
INVALID_DISPOSITION_WORKSTREAM = "review-agent-paired-review-prevalidation-recovery-plan-v1"
INVALID_DISPOSITION_RUN_ID = "20261019T055243Z-1d73c6a01b1e"
INVALID_DISPOSITION_TARGET = "agent-paired-review-prevalidation-recovery-plan-v1"
INVALID_DISPOSITION_IMPLEMENTATION = "7a9b5018543c483dd27082505f232e9618869e28"
INVALID_DISPOSITION_SHA256 = "6e6cc2d61796684baf23d5b74c7f1fc08091c13f509a8c00ceeb85f0d2933779"
INVALID_DISPOSITION_CONTINUATION = "continuation-01"
INVALID_DISPOSITION_TARGET_PACKET = (
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md"
)
INVALID_DISPOSITION_ACTIVE_PACKET = (
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md"
)
INVALID_DISPOSITION_REVIEW_PACKET = (
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md"
)
ROOT_SYNC_DEFERRAL_WORKSTREAMS = frozenset({
    "agent-paired-review-invalid-disposition-recovery-v1",
    "review-agent-paired-review-invalid-disposition-recovery-v1",
})

# This second continuation is authorized only for the exact run whose first
# fresh continuation exited 0 but omitted its canonical archived disposition.
MISSING_ARCHIVED_DISPOSITION_WORKSTREAM = (
    "review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1"
)
MISSING_ARCHIVED_DISPOSITION_RUN_ID = "20261020T114129Z-536181b31d70"
MISSING_ARCHIVED_DISPOSITION_PARENT = "continuation-01"
MISSING_ARCHIVED_DISPOSITION_CHILD = "continuation-02"

FAILED_IMPORT_RECOVERY_WORKSTREAM = (
    "review-agent-paired-review-missing-archived-disposition-continuation-v1"
)
FAILED_IMPORT_RECOVERY_RUN_ID = "20261020T165418Z-53992bd05f83"
FAILED_IMPORT_RECOVERY_MAX_RETRIES = 2
CARROW_MISSING_WORKTREE_WORKSTREAM = "review-carrow-interior-layout-authoring-v1"
CARROW_MISSING_WORKTREE_RUN_ID = "20261018T072047Z-83514d0c54fd"
CARROW_MISSING_WORKTREE_REVIEWED_MAIN = "099c44353dfd258c233016b88cc50ba2dd502ef1"
CARROW_MISSING_WORKTREE_IMPLEMENTATION = "9b15c2c4aa3f5c56584cd45ac96913ea1c81d9c6"
CARROW_MISSING_WORKTREE_REPORTS = {
    "validation.json": "7df3a536f45999d1f5a53d258d4bd61d9fd1a547f9408b5c85cac84b8ce0f6f6",
    "coordinator-validation.json": "5b870281fc110dc5654ee6c2ad804cdac9895fd0a925ab733c492c9c09c17517",
}
CARROW_MISSING_WORKTREE_RUN_MANIFEST = {
    "RECOVERY.md": "8693732508024e057cddb944012894beea55bb62489468fb0741e624bc4f4687",
    "claim-receipt.json": "a19b613da6e05c797662fd8e9b6ccf54c2b9ba710f4d3488dff57aea2051ac25",
    "claim.stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "claim.stdout": "b35f72240fae17d6946a7511c0beff843a877532ca21557c217e773c9ae38016",
    "coordinator-validation.json": "5b870281fc110dc5654ee6c2ad804cdac9895fd0a925ab733c492c9c09c17517",
    "metadata.json": "048a8290c3a3ff8a5997251561b9482fa29f04f1bb6e950ad23454b688b45348",
    "validation.json": "7df3a536f45999d1f5a53d258d4bd61d9fd1a547f9408b5c85cac84b8ce0f6f6",
}

# This recovery is deliberately bound to one already-authored reviewer PASS.
# It does not change ordinary continuation or the nonpassing closeout API.
ADVANCED_HEAD_PASS_WORKSTREAM = "review-agent-paired-review-exact-claim-parking-v1"
ADVANCED_HEAD_PASS_RUN_ID = "20261019T164227Z-e6abe304ef6c"
ADVANCED_HEAD_PASS_TARGET = "agent-paired-review-exact-claim-parking-v1"
ADVANCED_HEAD_PASS_REVIEWED_MAIN = "2a0352441abfae7ec174c1d614f675949f68922f"
ADVANCED_HEAD_PASS_REVIEWER_COMMIT = "94e2a8c76d37242803f9261673f3cb55356d2ee0"
ADVANCED_HEAD_PASS_REMOTE_TIP = "2a0352441abfae7ec174c1d614f675949f68922f"
ADVANCED_HEAD_PASS_WORKTREE = (
    "/home/braydenchaffee/Projects/.custodian-worktrees/"
    "review-agent-paired-review-exact-claim-parking-v1-20261019T164232Z-f6ba03fc69a3"
)
ADVANCED_HEAD_PASS_TARGET_PACKET = (
    f"{PACKET_ROOT}/archived/AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md"
)
ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET = (
    f"{PACKET_ROOT}/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md"
)
ADVANCED_HEAD_PASS_REVIEW_PACKET = (
    f"{PACKET_ROOT}/archived/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md"
)
ADVANCED_HEAD_PASS_SUMMARY = "REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1_CLAUDE_SUMMARY.md"
ADVANCED_HEAD_PASS_ALLOWED_BASE_PATHS = frozenset({
    ADVANCED_HEAD_PASS_SUMMARY,
    f"{PACKET_ROOT}/README.md",
    ADVANCED_HEAD_PASS_TARGET_PACKET,
    ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET,
    ADVANCED_HEAD_PASS_REVIEW_PACKET,
})
ADVANCED_HEAD_PASS_ORIGINAL_EVIDENCE_SHA256 = {
    "RECOVERY.md": "59ce514875b50e4a925b06303f42666e59a7c2190d3c7092af49ce7cde905a63",
    "claim-receipt.json": "641b1b260aa1dc7476fd1cb1448465415c77e92eae54ad9bea35a35b1eaf6e91",
    "claim.stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "claim.stdout": "284a7db0b6440258154405ef6aa0c23b680b40681e270b17a74af0c4435e2738",
    "codex.jsonl": "bbcc05811889bfd4796a9d29912fea3fde4bf488e5b00df34c50af299d64c1f2",
    "codex.stderr": "93d91d37a070fe05f0e23be70fa3fa7b579ecc00e9fd02d420386a81b366546a",
    "coordinator-validation.json": "dbbfa3ed3f2e69f636aabf66a63973a343db4571572bbefcd7421f9eeb725fdc",
    "last-message.txt": "2aedc38d42e7ed681a14a6e29723008fc6c26345c0f40f9f33428cfd0c6870e0",
    "metadata.json": "3ef49232df5362859fccc32acd5c66df21ca53e33cffb9f04bc91e4a8509af02",
    "validation.json": "5976264c08738dc8d088bd447d90dcfbaabd2ed99fe9866d18dd5ba305c95ae1",
}
ADVANCED_HEAD_PASS_RECOVERY_SCHEMA = "custodian.paired_review_advanced_head_pass_recovery.v1"
ADVANCED_HEAD_PASS_RECOVERY_ROOT = "custodian-review-recoveries/advanced-head-pass-closeout"

PROCESSION_PASS_WORKSTREAM = "review-agent-paired-review-procession-test-fixture-repair-v1"
PROCESSION_PASS_RUN_ID = "20261024T074548Z-1c9611762049"
PROCESSION_PASS_TARGET = "agent-paired-review-procession-test-fixture-repair-v1"
PROCESSION_PASS_REVIEWED_MAIN = "7b82b9630e9a63c52e86f8b4805c577a85496aa5"
PROCESSION_PASS_IMPLEMENTATION = "7b82b9630e9a63c52e86f8b4805c577a85496aa5"
PROCESSION_PASS_REVIEWER_BRANCH_BASE = "7b82b9630e9a63c52e86f8b4805c577a85496aa5"
PROCESSION_PASS_REVIEWER_LOCAL_HEAD = "03372f4ffcc7acffcd675e6ed4e988cec866750b"
PROCESSION_PASS_WORKTREE = (
    "/home/braydenchaffee/Projects/.custodian-worktrees/"
    "review-agent-paired-review-procession-test-fixture-repair-v1-20261024T074609Z-f3f9a621ba72"
)
PROCESSION_PASS_TARGET_PACKET = f"{PACKET_ROOT}/archived/PROCESSION_TEST_FIXTURE_REPAIR_V1.md"
PROCESSION_PASS_ACTIVE_REVIEW_PACKET = f"{PACKET_ROOT}/REVIEW_PROCESSION_TEST_FIXTURE_REPAIR_V1.md"
PROCESSION_PASS_ARCHIVED_REVIEW_PACKET = f"{PACKET_ROOT}/archived/REVIEW_PROCESSION_TEST_FIXTURE_REPAIR_V1.md"
PROCESSION_PASS_SUMMARY = "REVIEW_AGENT_PAIRED_REVIEW_PROCESSION_TEST_FIXTURE_REPAIR_V1_CLAUDE_SUMMARY.md"
PROCESSION_PASS_ALLOWED_PATHS = frozenset({
    PROCESSION_PASS_ACTIVE_REVIEW_PACKET, PROCESSION_PASS_ARCHIVED_REVIEW_PACKET,
    PROCESSION_PASS_TARGET_PACKET, f"{PACKET_ROOT}/README.md", PROCESSION_PASS_SUMMARY,
})
PROCESSION_PASS_RECOVERY_SCHEMA = "custodian.paired_review_procession_pass_closeout_recovery.v1"
PROCESSION_PASS_RECOVERY_ROOT = "custodian-review-recoveries/procession-pass-closeout"


class RunnerError(RuntimeError):
    pass


def reviewer_cache_roots(repo: Path) -> list[Path]:
    """Return the narrow writable CUSTODIAN roots used by validation locks and HOME."""
    roots = {scratch_root(create=False).resolve(), job_budget_root(create=False)}
    common = common_dir(repo).resolve()
    for root in roots:
        if root == common or root in common.parents or common in root.parents:
            raise RunnerError(f"CUSTODIAN cache root overlaps shared Git metadata: {root}")
        if len(root.parts) < 3 or root == Path.home().resolve():
            raise RunnerError(f"refusing broad reviewer cache permission: {root}")
    scratch_root(create=True)
    job_budget_root(create=True)
    return sorted(roots, key=str)


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise RunnerError(redact(result.stderr or result.stdout))
    return result.stdout.strip()


def packet_at_main(repo: Path, workstream: str):
    git(repo, "fetch", "origin", "main")
    paths = git(repo, "ls-tree", "-r", "--name-only", "origin/main", PACKET_ROOT).splitlines()
    matches = []
    for path in paths:
        if not path.endswith(".md") or "/archived/" in path:
            continue
        content = read_git_text(repo, "origin/main", path)
        packet = parse_packet(path, content)
        if packet.workstream == workstream:
            matches.append((path, content, packet))
    if len(matches) != 1:
        raise RunnerError(f"expected one active packet for {workstream}, found {len(matches)}")
    return matches[0]


def current_review_authority(content: str) -> str:
    """Keep current review gates while excluding explicitly scoped successor gates.

    A future handoff never gates the current review. A preceding
    ``## Refresh Planning Authority`` section, however, remains a current
    human gate unless it explicitly declares ``Refresh applies to: successor``
    AND the future handoff names a real next workstream. Missing or ambiguous
    scope fails closed.
    """
    handoff = re.search(r"(?im)^##[ \t]+(?:handoff|next handoff)[ \t]*$", content)
    authority = content[:handoff.start()] if handoff else content
    if not handoff:
        return authority
    next_workstream = re.search(
        r"(?im)^\s*-\s*Next workstream:\s*`?([a-z0-9-]+)`?\s*$",
        content[handoff.start():],
    )
    if not next_workstream or next_workstream.group(1) == "none":
        return authority

    sections = list(re.finditer(r"(?m)^##[ \t]+[^\r\n]+$", authority))
    for index in range(len(sections) - 1, -1, -1):
        heading = sections[index]
        if heading.group(0).strip().casefold() != "## refresh planning authority":
            continue
        end = sections[index + 1].start() if index + 1 < len(sections) else len(authority)
        body = authority[heading.end():end]
        if re.search(r"(?im)^\s*-\s*Refresh applies to:\s*`?successor`?\s*$", body):
            authority = authority[:heading.start()] + authority[end:]
    return authority


def validate_eligible_review(repo: Path, workstream: str):
    path, content, packet = packet_at_main(repo, workstream)
    if packet.error:
        raise RunnerError(f"invalid review packet: {packet.error}")
    if packet.kind != "review":
        raise RunnerError("refusing to launch a non-review packet")
    if packet.status != "ready" or packet.dispatch != "auto":
        raise RunnerError("review must be ready/auto on fetched origin/main")
    if not packet.review_target_workstream or not packet.review_target_packet:
        raise RunnerError("review packet must name its completed target")
    if packet.review_target_workstream not in packet.dependencies:
        raise RunnerError("review target must be an explicit dependency")
    if packet.visual_review == "required":
        raise RunnerError("review packet requires a human visual review")
    authority = current_review_authority(content)
    if re.search(r"(?im)^\s*-\s*(?:ChatGPT/user planning refresh required|Human decision required):\s*`?yes\b", authority):
        raise RunnerError("review packet requires a human planning/decision gate")
    if re.search(r"(?im)^\s*-\s*Refresh owner:\s*`?(?:chatgpt-user|human)", authority):
        raise RunnerError("review packet has a human-owned refresh gate")

    target_path = packet.review_target_packet
    try:
        target_content = read_git_text(repo, "origin/main", target_path)
    except ValueError as exc:
        raise RunnerError("completed review target is absent from origin/main") from exc
    target = parse_packet(target_path, target_content)
    if target.kind not in {"implementation", "correction"} or target.status != "complete":
        raise RunnerError("review target must be an archived, complete implementation/correction")
    if target_path != f"{PACKET_ROOT}/archived/{Path(target_path).name}":
        raise RunnerError("review target must be in the canonical archived packet directory")
    _, identity_error = resolve_target_implementation_commit(
        repo, git(repo, "rev-parse", "origin/main^{commit}"), target_path,
        packet.review_target_workstream, target_content,
    )
    if identity_error:
        raise RunnerError(f"review target implementation identity is invalid: {identity_error}")
    return path, content, packet


def codex_preflight() -> str:
    executable = shutil.which("codex")
    if not executable:
        raise RunnerError("codex executable unavailable; no review claim was created")
    probe = subprocess.run([executable, "exec", "--help"], text=True, capture_output=True)
    help_text = probe.stdout + probe.stderr
    required = ("--ephemeral", "--json", "--output-last-message", "--cd", "--add-dir", "--approve-for-me")
    missing = [flag for flag in required if flag not in help_text]
    if probe.returncode or missing:
        raise RunnerError(f"codex exec preflight failed before claim (missing: {', '.join(missing) or 'exec help'})")
    return executable


def parse_claim_receipt(stdout: str, workstream: str, repo: Path, *, allow_missing_worktree: bool = False) -> dict:
    lines = [line for line in stdout.splitlines() if line.startswith(CLAIM_SENTINEL)]
    if len(lines) != 1:
        raise RunnerError("dispatcher did not return exactly one structured claim receipt")
    try:
        receipt = json.loads(lines[0][len(CLAIM_SENTINEL):])
    except json.JSONDecodeError as exc:
        raise RunnerError("dispatcher claim receipt was malformed") from exc
    if not isinstance(receipt, dict):
        raise RunnerError("dispatcher claim receipt must be a JSON object")
    if receipt.get("result") != "claimed" or receipt.get("workstream") != workstream or receipt.get("verified") is not True:
        raise RunnerError("dispatcher receipt does not verify the requested review claim")
    if not all(isinstance(receipt.get(field), str) and receipt.get(field) for field in ("worktree", "branch", "packet")):
        raise RunnerError("dispatcher receipt omitted branch, worktree, or packet identity")
    worktree = Path(receipt.get("worktree", "")).resolve()
    if allow_missing_worktree:
        pass
    else:
        if not worktree.is_dir() or git(worktree, "branch", "--show-current") != receipt.get("branch"):
            raise RunnerError("dispatcher worktree/branch identity could not be verified")
        if common_dir(worktree) != common_dir(repo):
            raise RunnerError("dispatcher returned a worktree from another repository")
    expected_packet = f"{PACKET_ROOT}/{Path(receipt.get('packet', '')).name}"
    if receipt.get("packet") != expected_packet:
        raise RunnerError("dispatcher returned an unexpected packet path")
    return receipt


def prompt_for(workstream: str, packet_path: str, target_path: str, *, run_dir: Path | None = None,
               authoring_chat: str | None = None, reviewed_main: str | None = None,
               implementation_commit: str | None = None,
               implementation_summary_path: str | None = None,
               validation_sha256: str | None = None,
               source_span: dict | None = None) -> str:
    validation_path = str(run_dir / "validation.json") if run_dir else "the run evidence directory's validation.json"
    review_summary_path = expected_summary_path(workstream)
    implementation_summary = implementation_summary_path or "the target implementation's exact root summary path"
    backlink = f"Use this exact Authoring chat URL in the summary: {authoring_chat}" if authoring_chat else "Preserve the packet's exact Authoring chat URL in the summary."
    pinned = f"Review the immutable baseline `origin/main` at `{reviewed_main}`; report this exact SHA in the review receipt." if reviewed_main else "Record the exact immutable reviewed-main SHA in the review receipt."
    implementation = (f"The exact reviewed implementation SHA derived from the pinned archived packet history is `{implementation_commit}`; report this exact SHA in the review receipt."
                      if implementation_commit else "Derive the implementation SHA from the exact archived target history; do not guess or use a reviewer-supplied value without verifying it.")
    source_range = (f"Host validation covered the separately pinned source span `{source_span.get('base')}`..`{source_span.get('head')}`; the canonical archive/receipt implementation identity remains `{implementation_commit}`. Inspect both the source span and archive landing."
                    if source_span else "Use the pinned canonical implementation commit as the source range unless coordinator provenance records a separate source span.")
    return f"""You are the fresh independent paired reviewer for CUSTODIAN workstream `{workstream}`.

Reconstruct the review solely from durable repository evidence in this claimed worktree. Read `AGENTS.md`, `custodian/AGENTS.md`, `{packet_path}`, `{target_path}`, `{implementation_summary}`, and the landed diff/current main. {pinned} {implementation} {source_range} Inspect the coordinator-authored validation report at `{validation_path}` (SHA-256 `{validation_sha256 or 'provided in coordinator-validation.json'}`) as immutable execution evidence. Do not run or replace the host validation report. Independently assess the implementation and report your own verdict. Do not use, request, or infer the implementation-session transcript. Do not edit reviewed implementation/runtime code or `{implementation_summary}`; treat it as read-only. Record findings first. Write the canonical review summary only to `{review_summary_path}` and the required review receipt. Choose `passed`, `findings`, or `human_required` from your own evidence-backed conclusion; do not default to PASS. {backlink}

This is a restricted reviewer checkout. Do not run `git fetch`, `git push`, `git add`, `git commit`, `workstream.py checkpoint`, or `workstream.py finish`; shared Git metadata and landing belong to the coordinator. Do not remove the worktree or branch. If the target packet needs its receipt, append exactly one `### Review Receipt: {workstream}` block under `## Independent Review` (or append that section at EOF), preserving all existing target bytes. Use this exact field layout, substituting the review packet's exact target identity and the pinned main and implementation SHAs:

```markdown
### Review Receipt: {workstream}
- Schema: `custodian.paired_review.v1`
- Review workstream: `{workstream}`
- Review target workstream: `<exact target workstream>`
- Status: `<passed | findings | human_required>`
- Blocking defects: `<count supported by your findings>`
- Material gaps: `<count supported by your findings>`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent` or `same-agent-fresh-context`
- Reviewed main: `<full pinned main SHA>`
- Reviewed implementation commit: `<full implementation SHA>`
```

Do not edit any other target bytes. The coordinator owns `{validation_path}`; never overwrite or author it. Update/archive only the authorized review packet and managed index. If blocked, write the canonical review summary explaining the blocker and leave the packet/worktree recoverable. Do not claim another packet or hop to the global queue. Report the exact result and evidence paths."""


def validation_report_is_green(path: Path) -> bool:
    try:
        report = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    tests = report.get("tests") if isinstance(report, dict) else None
    coverage = report.get("coverage") if isinstance(report, dict) else None
    return (report.get("schema") == "custodian.validation.result.v1" and report.get("passed") is True
            and isinstance(coverage, dict) and coverage.get("complete") is True
            and isinstance(tests, list) and bool(tests)
            and all(isinstance(test, dict) and test.get("status") == "passed" for test in tests))


def _changed_paths(repo: Path, *args: str) -> list[str]:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if result.returncode:
        raise RunnerError(redact(result.stderr or result.stdout))
    return [line for line in result.stdout.splitlines() if line]


def _verified_reviewer_pass(repo: Path, archived_text: str, metadata: dict, worktree: Path,
                            workstream: str, target_workstream: str, reviewed_main: str,
                            implementation_commit: str) -> dict[str, str]:
    """Authenticate a canonical archived PASS against its fresh reviewer session and pinned run."""
    run_id = metadata.get("run_id")
    session_dir = Path(str(metadata.get("run_dir", ""))).resolve()
    if metadata.get("schema") == CONTINUATION_SCHEMA:
        session_dir = Path(str(metadata.get("last_message", ""))).resolve().parent
    if (not isinstance(run_id, str) or not _RUN_ID_RE.fullmatch(run_id)
            or metadata.get("workstream") != workstream
            or metadata.get("fresh") is not True or metadata.get("exit_code") != 0
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or not session_dir.is_dir()):
        raise RunnerError("reviewer session metadata does not authenticate the pinned PASS")
    try:
        final = (session_dir / "last-message.txt").read_text(encoding="utf-8")
        events = (session_dir / "codex.jsonl").read_text(encoding="utf-8").splitlines()
        outcome, outcome_error = review_outcome.parse_review_outcome(archived_text)
    except OSError as exc:
        raise RunnerError("fresh reviewer session evidence is missing") from exc
    if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
        raise RunnerError("archived packet does not contain one canonical PASS outcome")
    identity_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=workstream, target_workstream=target_workstream,
        reviewed_main=reviewed_main, implementation_commit=implementation_commit,
        run_id=run_id, review_cycle=int(metadata.get("review_cycle", 0)),
    )
    if identity_error:
        raise RunnerError("archived PASS outcome identity failed: " + identity_error)
    receipt = _independent_review_receipt(archived_text)
    expected_receipt = render_review_receipt(outcome)
    if receipt is None or archived_text.count(expected_receipt) != 1:
        raise RunnerError("archived independent-review receipt differs from its canonical PASS outcome")
    agent_messages: list[str] = []
    completed_turns = 0
    for line in events:
        try:
            event = json.loads(line)
        except json.JSONDecodeError as exc:
            raise RunnerError("reviewer session contains malformed JSON") from exc
        item = event.get("item") if isinstance(event, dict) else None
        if isinstance(item, dict) and item.get("type") == "agent_message":
            if not isinstance(item.get("text"), str):
                raise RunnerError("reviewer session contains a malformed agent message")
            agent_messages.append(item["text"])
        if isinstance(event, dict) and event.get("type") == "turn.completed":
            completed_turns += 1
    if completed_turns != 1 or len(agent_messages) != 1 or agent_messages[0].strip() != final.strip():
        raise RunnerError("reviewer final output does not uniquely match its raw fresh session")
    if (not re.search(r"(?i)(?:verdict|review outcome):?\s*`?passed\b", final)
            or workstream not in final):
        raise RunnerError("reviewer-authored final output does not support this exact PASS identity")
    summary_path = worktree / expected_summary_path(workstream)
    try:
        summary = summary_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise RunnerError("canonical reviewer summary is missing") from exc
    if (run_id not in summary or reviewed_main not in summary
            or "## Review Outcome" not in summary or "passed" not in summary.lower()):
        raise RunnerError("canonical reviewer summary does not support the pinned PASS")
    return outcome


def _process_owns_worktree(worktree: Path) -> list[dict[str, str]]:
    """Find same-host processes whose cwd or argv is attached to the exact reviewer checkout."""
    owners: list[dict[str, str]] = []
    proc = Path("/proc")
    if not proc.is_dir():
        raise RunnerError("host process inventory is unavailable; cannot prove reviewer exit")
    exact = str(worktree.resolve())
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            pid = int(entry.name)
            argv = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace").strip()
            cwd = str((entry / "cwd").resolve())
        except FileNotFoundError:
            continue
        except PermissionError as exc:
            raise RunnerError(f"cannot inspect process {entry.name}; reviewer exit cannot be proven") from exc
        except OSError as exc:
            raise RunnerError(f"cannot inspect process {entry.name}; reviewer exit cannot be proven") from exc
        if pid != os.getpid() and (cwd == exact or cwd.startswith(exact + os.sep) or exact in argv):
            owners.append({"pid": str(pid), "cwd": cwd, "argv_sha256": _sha256_bytes(argv.encode())})
    return owners


def _procession_pass_journal_path(common: Path) -> Path:
    path = common / PROCESSION_PASS_RECOVERY_ROOT / PROCESSION_PASS_RUN_ID / "recovery.jsonl"
    current = common
    for part in Path(PROCESSION_PASS_RECOVERY_ROOT).parts + (PROCESSION_PASS_RUN_ID,):
        current = current / part
        if current.is_symlink() or (current.exists() and not current.is_dir()):
            raise RunnerError("PASS recovery journal path is occupied or contains a symlink")
    if not path.resolve().is_relative_to(common.resolve()):
        raise RunnerError("PASS recovery journal path escapes shared Git metadata")
    return path


def _read_procession_journal(path: Path) -> list[dict]:
    if not path.exists():
        return []
    events: list[dict] = []
    previous = "0" * 64
    try:
        for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            event = json.loads(line)
            if not isinstance(event, dict):
                raise RunnerError("PASS recovery journal event is not an object")
            claimed = event.pop("event_sha256", None)
            canonical = json.dumps(event, sort_keys=True, separators=(",", ":")).encode()
            if (event.get("sequence") != index or event.get("previous_sha256") != previous
                    or claimed != _sha256_bytes(canonical)):
                raise RunnerError("PASS recovery journal hash chain is invalid")
            event["event_sha256"] = claimed
            events.append(event)
            previous = claimed
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("PASS recovery journal is unreadable or malformed") from exc
    stages = [event.get("stage") for event in events]
    if (not stages or stages[0] != "prepared"
            or any(stage not in {"prepared", "retry_started", "closeout_blocked", "complete"}
                   for stage in stages)
            or stages.count("complete") > 1):
        raise RunnerError("PASS recovery journal has an invalid stage sequence")
    allowed_next = {"prepared": {"closeout_blocked", "complete"},
                    "closeout_blocked": {"retry_started"},
                    "retry_started": {"closeout_blocked", "complete"},
                    "complete": set()}
    if any(next_stage not in allowed_next[stage]
           for stage, next_stage in zip(stages, stages[1:])):
        raise RunnerError("PASS recovery journal has an invalid stage transition")
    return events


def _append_procession_journal(path: Path, event: dict, *, create: bool = False) -> dict:
    events = _read_procession_journal(path)
    payload = {**event, "sequence": len(events) + 1,
               "previous_sha256": events[-1]["event_sha256"] if events else "0" * 64}
    payload["event_sha256"] = _sha256_bytes(json.dumps(payload, sort_keys=True, separators=(",", ":")).encode())
    flags = os.O_WRONLY | os.O_APPEND
    flags |= getattr(os, "O_NOFOLLOW", 0)
    if create:
        flags |= os.O_CREAT | os.O_EXCL
    if not create and not path.is_file():
        raise RunnerError("PASS recovery journal disappeared before append")
    fd = os.open(path, flags, 0o600)
    with os.fdopen(fd, "ab") as handle:
        handle.write((json.dumps(payload, sort_keys=True) + "\n").encode())
        handle.flush()
        os.fsync(handle.fileno())
    if create:
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    return payload


def plan_procession_pass_closeout(repo: Path) -> dict:
    """Read-only authentication and closeout plan for the one preserved Procession PASS."""
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    reviewed_main = PROCESSION_PASS_REVIEWED_MAIN
    branch = f"agent/{PROCESSION_PASS_WORKSTREAM}"
    run_dir = common / "custodian-review-runs" / PROCESSION_PASS_WORKSTREAM / PROCESSION_PASS_RUN_ID
    try:
        metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("exact Procession review run metadata is missing or malformed") from exc
    if (metadata.get("schema") != SCHEMA or metadata.get("workstream") != PROCESSION_PASS_WORKSTREAM
            or metadata.get("run_id") != PROCESSION_PASS_RUN_ID
            or metadata.get("phase") != "post_exit_recovery"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("branch") != branch
            or metadata.get("worktree") != PROCESSION_PASS_WORKTREE
            or metadata.get("packet") != PROCESSION_PASS_ACTIVE_REVIEW_PACKET
            or metadata.get("post_exit_error") != "reviewed target failed pinned receipt-delta verification: candidate must contain exactly one Independent Review section"):
        raise RunnerError("original Procession run identity or recorded closeout failure differs")
    continuation_dir = run_dir / "continuation-01"
    try:
        child = json.loads((continuation_dir / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("the one preserved same-claim continuation evidence is missing") from exc
    if (child.get("schema") != CONTINUATION_SCHEMA or child.get("workstream") != PROCESSION_PASS_WORKSTREAM
            or child.get("run_id") != PROCESSION_PASS_RUN_ID or child.get("phase") != "coordinator_closeout"
            or child.get("reviewer_launch_count") != 1 or child.get("exit_code") != 0
            or child.get("reviewed_main") != reviewed_main or child.get("implementation_commit") != PROCESSION_PASS_IMPLEMENTATION
            or child.get("target_workstream") != PROCESSION_PASS_TARGET
            or child.get("target_packet_path") != PROCESSION_PASS_TARGET_PACKET):
        raise RunnerError("preserved continuation is not the exact completed reviewer closeout attempt")
    original_manifest = _file_manifest(run_dir, omit=continuation_dir)
    if child.get("run_evidence_sha256") != original_manifest:
        raise RunnerError("same-claim continuation does not bind the unchanged original run manifest")
    for record in child.get("preserved_files", []):
        copy = Path(str(record.get("copy", "")))
        if (not copy.is_file() or copy.is_symlink()
                or _sha256_bytes(copy.read_bytes()) != record.get("sha256")):
            raise RunnerError("a continuation-preserved reviewer artifact is missing or changed")
    if not (continuation_dir / "preserved_files.json").is_file():
        raise RunnerError("continuation omits its preserved-artifact inventory")
    try:
        preserved_inventory = json.loads((continuation_dir / "preserved_files.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("continuation preserved-artifact inventory is malformed") from exc
    if preserved_inventory != child.get("preserved_files"):
        raise RunnerError("continuation preserved-artifact inventory does not match its metadata")

    worktree = Path(PROCESSION_PASS_WORKTREE)
    if worktree.is_symlink() or not worktree.is_dir() or worktree.resolve() != worktree:
        raise RunnerError("exact reviewer checkout is missing, foreign, or symlinked")
    claim = _claim_identity(run_dir, PROCESSION_PASS_WORKSTREAM, repo, metadata)
    if (claim.get("worktree") != str(worktree) or claim.get("branch") != branch
            or claim.get("packet") != PROCESSION_PASS_ACTIVE_REVIEW_PACKET
            or common_dir(worktree).resolve() != common
            or git(worktree, "branch", "--show-current") != branch):
        raise RunnerError("claim receipt and attached reviewer checkout identity differ")
    if git(worktree, "status", "--porcelain", "--untracked-files=all"):
        raise RunnerError("protected reviewer checkout has uncommitted or untracked changes")
    if _process_owns_worktree(worktree):
        raise RunnerError("an active local process still owns the protected reviewer checkout")
    worktrees = [Path(item).resolve() for item in git(repo, "worktree", "list", "--porcelain").split("\n\n")
                 if item.startswith("worktree ") for item in [item.splitlines()[0][9:]]]
    if worktrees.count(worktree) != 1:
        raise RunnerError("reviewer checkout is not the unique attached worktree for this repository")

    current_main = fetch_and_pin_main(repo)
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, current_main],
                      cwd=repo, capture_output=True).returncode:
        raise RunnerError("current main does not descend from the pinned Procession review baseline")
    git(repo, "fetch", "origin", branch)
    remote_tip = git(repo, "rev-parse", "--verify", f"refs/remotes/origin/{branch}^{{commit}}")
    local_head = git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    if remote_tip != PROCESSION_PASS_REVIEWER_BRANCH_BASE or local_head != PROCESSION_PASS_REVIEWER_LOCAL_HEAD:
        raise RunnerError("published review branch or preserved local closeout head changed")
    commits = git(worktree, "rev-list", "--reverse", f"{remote_tip}..{local_head}").splitlines()
    expected_commits = ["5fd877b9b98c1a072d535e5116d3c24307904892", PROCESSION_PASS_REVIEWER_LOCAL_HEAD]
    if commits != expected_commits:
        raise RunnerError("local review branch contains an unexpected commit chain")
    commit_paths = [set(git(worktree, "diff", "--no-renames", "--name-only", f"{sha}^", sha).splitlines())
                    for sha in commits]
    if (commit_paths[0] != {PROCESSION_PASS_SUMMARY, PROCESSION_PASS_TARGET_PACKET,
                            PROCESSION_PASS_ACTIVE_REVIEW_PACKET, PROCESSION_PASS_ARCHIVED_REVIEW_PACKET}
            or commit_paths[1] != {PROCESSION_PASS_ARCHIVED_REVIEW_PACKET}):
        raise RunnerError("preserved local review commits change paths outside the exact closeout evidence")
    if not PROCESSION_PASS_ALLOWED_PATHS.issuperset(set().union(*commit_paths)):
        raise RunnerError("preserved local review history contains an undeclared path")

    target_baseline = read_git_text(repo, reviewed_main, PROCESSION_PASS_TARGET_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, PROCESSION_PASS_TARGET_PACKET, PROCESSION_PASS_TARGET, target_baseline,
    )
    if identity_error or implementation_commit != PROCESSION_PASS_IMPLEMENTATION:
        raise RunnerError("pinned Procession implementation identity failed: "
                          + str(identity_error or implementation_commit))
    archive_text = (worktree / PROCESSION_PASS_ARCHIVED_REVIEW_PACKET).read_text(encoding="utf-8")
    outcome = _verified_reviewer_pass(
        repo, archive_text, child, worktree, PROCESSION_PASS_WORKSTREAM,
        PROCESSION_PASS_TARGET, reviewed_main, implementation_commit,
    )
    target_candidate = (worktree / PROCESSION_PASS_TARGET_PACKET).read_text(encoding="utf-8")
    receipt, receipt_error = verify_review_receipt_delta(
        target_baseline, target_candidate, review_workstream=PROCESSION_PASS_WORKSTREAM,
        target_workstream=PROCESSION_PASS_TARGET, reviewed_main=reviewed_main,
        target_implementation_commit=implementation_commit,
    )
    if receipt_error or receipt is None or not target_candidate.endswith(render_review_receipt(outcome)):
        raise RunnerError("preserved target receipt does not exactly verify the archived reviewer PASS: "
                          + str(receipt_error or "receipt mismatch"))
    host_evidence = _host_evidence_for_continuation(
        repo, worktree, run_dir, metadata, reviewed_main, implementation_commit,
        PROCESSION_PASS_TARGET, PROCESSION_PASS_TARGET_PACKET,
    )
    host_evidence.update({"run_id": PROCESSION_PASS_RUN_ID, "review_cycle": 0,
                          "continuation_dir": str(continuation_dir)})
    lock = common / "custodian-review-runs" / "locks" / f"{PROCESSION_PASS_WORKSTREAM}.lock"
    if not lock.is_file():
        raise RunnerError("original paired-review supervisor lock file is missing")
    journal_path = _procession_pass_journal_path(common)
    journal_events = _read_procession_journal(journal_path)
    journal = journal_events[-1] if journal_events else None
    if journal is not None:
        if (journal.get("schema") != PROCESSION_PASS_RECOVERY_SCHEMA
                or journal.get("workstream") != PROCESSION_PASS_WORKSTREAM
                or journal.get("run_id") != PROCESSION_PASS_RUN_ID
                or journal.get("original_run_manifest") != _file_manifest(run_dir)):
            raise RunnerError("PASS recovery journal conflicts with the exact run evidence")
    plan = {
        "schema": "custodian.paired_review_procession_pass_closeout_plan.v1",
        "workstream": PROCESSION_PASS_WORKSTREAM, "run_id": PROCESSION_PASS_RUN_ID,
        "target_workstream": PROCESSION_PASS_TARGET, "reviewed_main": reviewed_main,
        "implementation_commit": implementation_commit, "coordinator_main": current_main,
        "branch": branch, "remote_tip": remote_tip, "local_head": local_head,
        "commit_chain": commits, "commit_paths": [sorted(paths) for paths in commit_paths],
        "claim_receipt_sha256": _sha256_bytes((run_dir / "claim-receipt.json").read_bytes()),
        "original_run_manifest": _file_manifest(run_dir),
        "reviewer_session_metadata_sha256": _sha256_bytes((continuation_dir / "metadata.json").read_bytes()),
        "reviewer_final_sha256": _sha256_bytes((continuation_dir / "last-message.txt").read_bytes()),
        "review_archive_sha256": _sha256_bytes(archive_text.encode()),
        "reviewer_outcome": outcome,
        "target_baseline_sha256": _sha256_bytes(target_baseline.encode()),
        "target_candidate_sha256": _sha256_bytes(target_candidate.encode()),
        "target_receipt": receipt,
        "host_validation": {key: host_evidence[key] for key in ("report_sha256", "metadata_sha256", "implementation_commit")},
        "reviewer_process_owners": [], "journal": str(journal_path),
        "journal_stage": journal.get("stage") if journal else None,
        "journal_event_sha256": journal.get("event_sha256") if journal else None,
        "action": "finish-only-existing-verified-review-artifacts",
    }
    plan["plan_sha256"] = _sha256_bytes(json.dumps(plan, sort_keys=True, separators=(",", ":")).encode())
    return plan


def apply_procession_pass_closeout(repo: Path, plan_sha256: str) -> dict:
    if not re.fullmatch(r"[0-9a-f]{64}", plan_sha256):
        raise RunnerError("Procession PASS closeout apply requires the exact plan SHA-256")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    lock_path = common / "custodian-review-runs" / "locks" / f"{PROCESSION_PASS_WORKSTREAM}.lock"
    if not lock_path.is_file():
        raise RunnerError("original paired-review supervisor lock file is missing")
    with lock_path.open("rb") as supervisor_lock:
        try:
            fcntl.flock(supervisor_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError("another supervisor owns the exact Procession review") from exc
        fresh = plan_procession_pass_closeout(repo)
        if fresh["plan_sha256"] != plan_sha256:
            raise RunnerError("Procession run, refs, owner state or artifacts changed; obtain a fresh read-only plan")
        journal_path = Path(fresh["journal"])
        journal_path.parent.mkdir(parents=True, exist_ok=True)
        journal_events = _read_procession_journal(journal_path)
        journal = journal_events[-1] if journal_events else None
        journal_data = {"schema": PROCESSION_PASS_RECOVERY_SCHEMA,
                        "workstream": PROCESSION_PASS_WORKSTREAM,
                        "run_id": PROCESSION_PASS_RUN_ID,
                        "plan_sha256": plan_sha256,
                        "original_run_manifest": fresh["original_run_manifest"]}
        if journal is not None:
            if any(journal.get(key) != value for key, value in journal_data.items()
                   if key != "plan_sha256"):
                raise RunnerError("existing PASS recovery journal belongs to another plan")
            if journal.get("stage") == "complete":
                return journal["result"]
            if journal.get("stage") != "closeout_blocked":
                raise RunnerError("existing PASS recovery journal is not in a resumable blocked state")
            _append_procession_journal(
                journal_path, {**journal_data, "stage": "retry_started", "retry_plan_sha256": plan_sha256},
            )
        else:
            _append_procession_journal(journal_path, {**journal_data, "stage": "prepared"}, create=True)
        worktree = Path(PROCESSION_PASS_WORKTREE)
        run_dir = common / "custodian-review-runs" / PROCESSION_PASS_WORKSTREAM / PROCESSION_PASS_RUN_ID
        before_manifest = fresh["original_run_manifest"]
        try:
            metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
            continuation_dir = run_dir / "continuation-01"
            child = json.loads((continuation_dir / "metadata.json").read_text(encoding="utf-8"))
            child["implementation_commit"] = fresh["implementation_commit"]
            host_evidence = _host_evidence_for_continuation(
                repo, worktree, run_dir, metadata, fresh["reviewed_main"],
                fresh["implementation_commit"], PROCESSION_PASS_TARGET, PROCESSION_PASS_TARGET_PACKET,
            )
            host_evidence.update({"run_id": PROCESSION_PASS_RUN_ID, "review_cycle": 0,
                                  "continuation_dir": str(continuation_dir)})
            archive_text = (worktree / PROCESSION_PASS_ARCHIVED_REVIEW_PACKET).read_text(encoding="utf-8")
            outcome = _verified_reviewer_pass(
                repo, archive_text, child, worktree, PROCESSION_PASS_WORKSTREAM,
                PROCESSION_PASS_TARGET, fresh["reviewed_main"], fresh["implementation_commit"],
            )
            target_baseline = read_git_text(repo, fresh["reviewed_main"], PROCESSION_PASS_TARGET_PACKET)
            result_sha = coordinator_finish_review(
                repo, PROCESSION_PASS_WORKSTREAM, worktree, PROCESSION_PASS_ACTIVE_REVIEW_PACKET,
                PROCESSION_PASS_TARGET, PROCESSION_PASS_TARGET_PACKET, target_baseline,
                "not-recorded", fresh["reviewed_main"], continuation_dir, host_evidence,
            )
            if _file_manifest(run_dir) != before_manifest:
                raise RunnerError("original Procession run evidence changed during closeout")
            verified_main = fetch_and_pin_main(repo)
            state = landed_review_state(
                repo, verified_main, PROCESSION_PASS_WORKSTREAM,
                PROCESSION_PASS_ACTIVE_REVIEW_PACKET, PROCESSION_PASS_TARGET,
                PROCESSION_PASS_TARGET_PACKET, target_baseline, "not-recorded", fresh["reviewed_main"],
            )
            if not state["complete"]:
                raise RunnerError("landed Procession PASS did not satisfy canonical review state: "
                                  + "; ".join(state["reasons"]))
            result = {"schema": PROCESSION_PASS_RECOVERY_SCHEMA, "workstream": PROCESSION_PASS_WORKSTREAM,
                      "run_id": PROCESSION_PASS_RUN_ID, "reviewer_commit": PROCESSION_PASS_REVIEWER_LOCAL_HEAD,
                      "landed_commit": result_sha, "verified_main": verified_main,
                      "outcome": outcome["Outcome"], "original_run_evidence_unchanged": True,
                      "coordinator_verified": True}
            _append_procession_journal(
                journal_path, {**journal_data, "stage": "complete", "result": result},
            )
            return result
        except (RunnerError, OSError, ValueError, subprocess.SubprocessError) as exc:
            _append_procession_journal(
                journal_path, {**journal_data, "stage": "closeout_blocked", "reason": redact(str(exc))},
            )
            raise


def coordinator_finish_review(repo: Path, workstream: str, worktree: Path, active_packet_path: str,
                              target_workstream: str, target_packet_path: str, target_content: str,
                              authoring_chat: str | None, reviewed_main: str, run_dir: Path,
                              host_evidence: dict, *, defer_teardown: bool = False) -> str:
    """Commit only bounded reviewer evidence and delegate landing to workstream.py."""
    evidence_dir = Path(host_evidence.get("evidence_run_dir", run_dir)).resolve()
    report = evidence_dir / "validation.json"
    try:
        if host_evidence.get("continuation_dir"):
            _verify_host_validation_at_commit(
                worktree, evidence_dir, reviewed_main, host_evidence["implementation_commit"], host_evidence,
                target_workstream=target_workstream, target_packet_path=target_packet_path,
            )
        else:
            verify_coordinator_validation(repo=worktree, run_dir=evidence_dir, reviewed_main=reviewed_main,
                                          implementation_commit=host_evidence["implementation_commit"],
                                          target_workstream=target_workstream,
                                          target_packet_path=target_packet_path,
                                          expected_report_sha256=host_evidence["report_sha256"],
                                          expected_metadata_sha256=host_evidence["metadata_sha256"])
    except (HostValidationError, KeyError) as exc:
        raise RunnerError(f"coordinator validation evidence failed immutable verification: {exc}") from exc
    if not validation_report_is_green(report):
        raise RunnerError(f"reviewer did not provide a green structured validation report: {report}")
    summary_path = expected_summary_path(workstream)
    archive_path = f"{PACKET_ROOT}/archived/{Path(active_packet_path).name}"
    allowed = {active_packet_path, archive_path, f"{PACKET_ROOT}/README.md", summary_path, target_packet_path}
    current_head = git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    existing_state = landed_review_state(repo, current_head, workstream, active_packet_path,
                                         target_workstream, target_packet_path, target_content,
                                         authoring_chat, reviewed_main)
    if existing_state["complete"]:
        scope_error = _branch_scope_error(worktree, current_head, allowed)
        if scope_error:
            raise RunnerError("already-committed review has out-of-scope changes: " + scope_error)
        archived = _show_at(repo, current_head, archive_path)
        outcome_error = _passing_outcome_error(
            archived, workstream=workstream, target_workstream=target_workstream,
            reviewed_main=reviewed_main, implementation_commit=host_evidence["implementation_commit"],
            run_id=host_evidence.get("run_id"), review_cycle=host_evidence.get("review_cycle"),
        )
        if outcome_error:
            raise RunnerError("already-committed review lacks the exact independent PASS disposition: " + outcome_error)
        if git(worktree, "status", "--porcelain", "--untracked-files=all"):
            raise RunnerError("already-committed review worktree has additional changes; preserving it for inspection")
        recovery_dir = Path(host_evidence.get("continuation_dir", run_dir)).resolve()
        is_support_review = workstream in ROOT_SYNC_DEFERRAL_WORKSTREAMS
        recovery_evidence = (Path(host_evidence["recovery_evidence"])
                             if host_evidence.get("recovery_evidence") else None)
        return _finish_via_workstream(
            repo, workstream, worktree, report, recovery_dir,
            defer_root_sync=is_support_review or recovery_evidence is not None,
            recovery_evidence=recovery_evidence, defer_teardown=defer_teardown,
        )
    changed = set(_changed_paths(worktree, "diff", "--name-only", "origin/main...HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--name-only", "HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    changed.update(_changed_paths(worktree, "ls-files", "--others", "--exclude-standard"))
    unexpected = sorted(changed - allowed)
    if unexpected:
        raise RunnerError("reviewer changed files outside its bounded evidence scope: " + ", ".join(unexpected))
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, target_packet_path, target_workstream, target_content,
    )
    if identity_error:
        raise RunnerError("reviewed target implementation identity is invalid: " + identity_error)
    target_candidate = (worktree / target_packet_path).read_bytes().decode("utf-8")
    _, receipt_error = verify_review_receipt_delta(
        target_content, target_candidate,
        review_workstream=workstream, target_workstream=target_workstream,
        reviewed_main=reviewed_main,
        target_implementation_commit=implementation_commit,
    )
    if receipt_error:
        archive_text = (worktree / archive_path).read_text(encoding="utf-8")
        run_metadata_path = Path(host_evidence.get("continuation_dir", run_dir)) / "metadata.json"
        if not run_metadata_path.is_file():
            run_metadata_path = run_dir / "metadata.json"
        try:
            reviewer_metadata = json.loads(run_metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RunnerError("cannot authenticate archived reviewer PASS session for receipt recovery") from exc
        reviewer_metadata.setdefault("implementation_commit", host_evidence.get("implementation_commit"))
        reviewer_metadata.setdefault("review_cycle", host_evidence.get("review_cycle", 0))
        outcome = _verified_reviewer_pass(
            repo, archive_text, reviewer_metadata, worktree, workstream, target_workstream,
            reviewed_main, implementation_commit,
        )
        if re.search(r"(?m)^## Independent Review[ \t]*$", target_content):
            raise RunnerError("pinned target already has an Independent Review section; refusing receipt synthesis")
        if target_candidate != target_content:
            raise RunnerError("target contains an unverified delta; coordinator may append only a missing PASS receipt")
        rendered = render_review_receipt(outcome)
        if not target_content.endswith("\n"):
            raise RunnerError("pinned target does not end with a newline; refusing receipt synthesis")
        target_candidate = target_content + "\n## Independent Review\n\n" + rendered
        _, receipt_error = verify_review_receipt_delta(
            target_content, target_candidate, review_workstream=workstream,
            target_workstream=target_workstream, reviewed_main=reviewed_main,
            target_implementation_commit=implementation_commit,
        )
        if receipt_error:
            raise RunnerError("coordinator-rendered PASS receipt failed canonical verification: " + receipt_error)
        target_file = worktree / target_packet_path
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_bytes(target_candidate.encode("utf-8"))
    else:
        receipt, _ = verify_review_receipt_delta(
            target_content, target_candidate, review_workstream=workstream,
            target_workstream=target_workstream, reviewed_main=reviewed_main,
            target_implementation_commit=implementation_commit,
        )
        archive_text = (worktree / archive_path).read_text(encoding="utf-8")
        archived_receipt = _independent_review_receipt(archive_text)
        if (receipt is None or archived_receipt is None
                or any(receipt.get(key) != archived_receipt.get(key) for key in (
                    "Schema", "Review workstream", "Review target workstream", "Status",
                    "Blocking defects", "Material gaps", "Reviewer context", "Reviewer provenance",
                    "Reviewed main", "Reviewed implementation commit"))):
            raise RunnerError("existing target receipt differs from the archived independent-review receipt")
    if not (worktree / archive_path).is_file() or not (worktree / summary_path).is_file():
        raise RunnerError("reviewer did not write the archived packet and exact root summary")
    if _changed_paths(worktree, "diff", "--cached", "--name-only"):
        raise RunnerError("reviewer staged evidence before coordinator authorization")
    staged = subprocess.run(["git", "add", "-A", "--", *sorted(allowed)], cwd=worktree, text=True, capture_output=True)
    if staged.returncode:
        raise RunnerError(redact(staged.stderr or staged.stdout))
    staged_paths = set(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    if not staged_paths or staged_paths - allowed:
        raise RunnerError("coordinator staged no review evidence or staged an unauthorized path")
    committed = subprocess.run(["git", "commit", "-m", "paired review receipt, closeout"], cwd=worktree,
                               text=True, capture_output=True)
    if committed.returncode:
        raise RunnerError(redact(committed.stderr or committed.stdout))
    branch_head = git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    branch_state = landed_review_state(repo, branch_head, workstream, active_packet_path,
                                       target_workstream, target_packet_path, target_content,
                                       authoring_chat, reviewed_main)
    if not branch_state["complete"]:
        raise RunnerError("review evidence failed exact pre-land verification: " + "; ".join(branch_state["reasons"]))
    recovery_dir = Path(host_evidence.get("continuation_dir", run_dir)).resolve()
    is_support_review = workstream in ROOT_SYNC_DEFERRAL_WORKSTREAMS
    recovery_evidence = (Path(host_evidence["recovery_evidence"])
                         if host_evidence.get("recovery_evidence") else None)
    return _finish_via_workstream(
        repo, workstream, worktree, report, recovery_dir,
        defer_root_sync=is_support_review or recovery_evidence is not None,
        recovery_evidence=recovery_evidence, defer_teardown=defer_teardown,
    )


def _stage_bounded(worktree: Path, allowed: set[str]) -> None:
    """Stage only bounded paths that exist on disk or are tracked.

    ``git add -A -- <path>`` fails for a path that is already gone from both the index
    and the worktree, which is exactly the state of a retry after an interrupted commit.
    """
    pathspecs = [path for path in sorted(allowed)
                 if (worktree / path).exists() or git(worktree, "ls-files", "--", path)]
    if not pathspecs:
        return
    staged = subprocess.run(["git", "add", "-A", "--", *pathspecs], cwd=worktree, text=True, capture_output=True)
    if staged.returncode:
        raise RunnerError(redact(staged.stderr or staged.stdout))


def _finish_via_workstream(repo: Path, workstream: str, worktree: Path, report: Path, run_dir: Path, *,
                           defer_root_sync: bool = False, recovery_evidence: Path | None = None,
                           defer_teardown: bool = False) -> str:
    """Delegate landing and teardown to workstream.py finish; return the verified landed commit."""
    finish_cmd = [sys.executable, str(repo / "custodian/tools/agent/workstream.py"), "finish", workstream,
                  "--validation-report", str(report)]
    if defer_root_sync:
        finish_cmd.append("--defer-root-sync")
    if recovery_evidence is not None:
        finish_cmd.extend(["--defer-root-sync-evidence", str(recovery_evidence)])
    if defer_teardown:
        finish_cmd.append("--defer-teardown")
    finished = subprocess.run(finish_cmd, cwd=repo, text=True, capture_output=True)
    finish_output = finished.stderr + finished.stdout
    if finished.returncode and "provide a green --validation-report-after-sync" in finish_output:
        after_sync_report = run_dir / "validation-after-sync.json"
        validation = subprocess.run([sys.executable, str(repo / "custodian/tools/validation/run_validation.py"),
                                     "--changed", "--json"], cwd=worktree, text=True, capture_output=True)
        if validation.returncode:
            raise RunnerError("post-sync changed-file validation failed; recovery retained: "
                              + redact(validation.stderr or validation.stdout))
        _write(after_sync_report, validation.stdout)
        if not validation_report_is_green(after_sync_report):
            raise RunnerError("post-sync changed-file validation report is not green; recovery retained")
        retry = finish_cmd + ["--validation-report-after-sync", str(after_sync_report)]
        finished = subprocess.run(retry, cwd=repo, text=True, capture_output=True)
    if finished.returncode:
        raise RunnerError("coordinator workstream finish failed; branch and evidence preserved: "
                          + redact(finished.stderr or finished.stdout))
    landed = re.search(r"verified ([0-9a-f]{40,64}) reachable from origin/main", finished.stdout + finished.stderr)
    if not landed and "already finished:" in (finished.stdout + finished.stderr):
        return fetch_and_pin_main(repo)
    if not landed:
        raise RunnerError("workstream finish did not return its verified landed commit; inspect preserved run evidence")
    return landed.group(1)


def nonpassing_review_reasons(archived_text: str, summary_text: str, target_text: str, *, repo: Path,
                              workstream: str, active_packet_path: str, target_workstream: str,
                              target_packet_path: str, target_content: str, authoring_chat: str | None,
                              reviewed_main: str, run_id: str | None = None) -> list[str]:
    """Every reason a findings/human_required closeout is not safe to land (empty means safe).

    A nonpassing review concludes administratively, so the reviewed target packet must
    stay byte-identical to its pinned baseline: it never gains an acceptance receipt
    and never inherits an old PASS.
    """
    archive_path = f"{PACKET_ROOT}/archived/{Path(active_packet_path).name}"
    reasons: list[str] = []
    packet = parse_packet(archive_path, archived_text)
    if packet.error or packet.kind != "review" or packet.status != "complete" or packet.workstream != workstream:
        reasons.append("exact archived review packet is not complete")
    if packet.review_target_workstream != target_workstream or packet.review_target_packet != target_packet_path:
        reasons.append("archived review packet names a different target")
    outcome, error = review_outcome.parse_review_outcome(archived_text)
    if error or outcome is None:
        reasons.append(error or "archived review packet has no Review Outcome")
    elif outcome["Outcome"] not in review_outcome.NONPASSING:
        reasons.append("Review Outcome is not a findings or human_required conclusion")
    else:
        implementation_commit, identity_error = resolve_target_implementation_commit(
            repo, reviewed_main, target_packet_path, target_workstream, target_content,
        )
        if identity_error:
            reasons.append(identity_error)
        binding = review_outcome.outcome_identity_error(
            outcome, review_workstream=workstream, target_workstream=target_workstream,
            reviewed_main=reviewed_main, implementation_commit=implementation_commit,
            run_id=run_id, review_cycle=packet.review_cycle,
        )
        if binding:
            reasons.append(binding)
        evidence = archived_text[:archived_text.index("## Review Outcome")]
        for finding in review_outcome.finding_ids(outcome):
            if not review_outcome.finding_evidenced(evidence, finding):
                reasons.append(f"finding {finding} has no written evidence in the review packet")
    if target_text != target_content:
        reasons.append("reviewed target packet bytes changed; a nonpassing review must not touch it")
    if authoring_chat and packet.authoring_chat != authoring_chat:
        reasons.append("archived review packet changed its authoring-chat identity")
    if authoring_chat and f"Authoring chat: {authoring_chat}" not in summary_text:
        reasons.append("exact closing summary is missing the packet authoring-chat backlink")
    if not next_handoff(summary_text):
        reasons.append("exact closing summary omits Next Handoff")
    return reasons


def landed_nonpassing_review_state(repo: Path, revision: str, workstream: str, review_packet_path: str,
                                   target_workstream: str, target_packet_path: str,
                                   expected_target_content: str, authoring_chat: str | None,
                                   reviewed_main: str, run_id: str | None = None) -> dict:
    """Verify a findings/human_required closeout from exact paths at one pinned revision."""
    archive_path = f"{PACKET_ROOT}/archived/{Path(review_packet_path).name}"
    result = {"complete": False, "revision": revision, "summary_path": expected_summary_path(workstream),
              "reasons": []}
    try:
        archived_text = _show_at(repo, revision, archive_path)
        summary_text = _show_at(repo, revision, result["summary_path"])
        target_text = _show_at(repo, revision, target_packet_path)
    except RunnerError as exc:
        result["reasons"].append(str(exc))
        return result
    result["reasons"] += nonpassing_review_reasons(
        archived_text, summary_text, target_text, repo=repo, workstream=workstream,
        active_packet_path=review_packet_path, target_workstream=target_workstream,
        target_packet_path=target_packet_path, target_content=expected_target_content,
        authoring_chat=authoring_chat, reviewed_main=reviewed_main, run_id=run_id,
    )
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, revision],
                      cwd=repo, text=True, capture_output=True).returncode:
        result["reasons"].append("pinned post-review main is not descended from the reviewed main")
    outcome, _ = review_outcome.parse_review_outcome(archived_text)
    result["outcome"] = outcome["Outcome"] if outcome else None
    result["complete"] = not result["reasons"]
    return result


def nonpassing_integrity_report(outcome: str) -> dict:
    """Green closeout-integrity evidence. It deliberately says nothing about the reviewed behavior."""
    checks = ("archived review packet complete and bound to its target",
              "Review Outcome canonical and pinned to the exact review",
              "every finding ID has written evidence",
              "reviewed target packet byte-identical to its pinned baseline",
              "canonical closing summary carries the backlink and Next Handoff")
    return {"schema": "custodian.validation.result.v1", "passed": True,
            "scope": "paired review closeout integrity only; no claim about the reviewed behavior",
            "outcome": outcome, "coverage": {"complete": True},
            "tests": [{"name": name, "status": "passed"} for name in checks]}


def coordinator_finish_nonpassing_review(repo: Path, workstream: str, worktree: Path, active_packet_path: str,
                                         target_workstream: str, target_packet_path: str, target_content: str,
                                         authoring_chat: str | None, reviewed_main: str, run_dir: Path) -> str:
    """Land a findings/human_required review without ever touching the reviewed target packet."""
    summary_path = expected_summary_path(workstream)
    archive_path = f"{PACKET_ROOT}/archived/{Path(active_packet_path).name}"
    allowed = {active_packet_path, archive_path, f"{PACKET_ROOT}/README.md", summary_path}
    changed = set(_changed_paths(worktree, "diff", "--name-only", "origin/main...HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--name-only", "HEAD"))
    changed.update(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    changed.update(_changed_paths(worktree, "ls-files", "--others", "--exclude-standard"))
    unexpected = sorted(changed - allowed)
    if unexpected:
        raise RunnerError("nonpassing review changed files outside its bounded evidence scope: " + ", ".join(unexpected))
    if not (worktree / archive_path).is_file() or not (worktree / summary_path).is_file():
        raise RunnerError("reviewer did not write the archived packet and exact root summary")
    if _changed_paths(worktree, "diff", "--cached", "--name-only"):
        raise RunnerError("reviewer staged evidence before coordinator authorization")
    reasons = nonpassing_review_reasons(
        (worktree / archive_path).read_bytes().decode("utf-8"), (worktree / summary_path).read_bytes().decode("utf-8"),
        (worktree / target_packet_path).read_bytes().decode("utf-8"), repo=repo, workstream=workstream,
        active_packet_path=active_packet_path, target_workstream=target_workstream,
        target_packet_path=target_packet_path, target_content=target_content, authoring_chat=authoring_chat,
        reviewed_main=reviewed_main, run_id=run_dir.name,
    )
    if reasons:
        raise RunnerError("nonpassing review evidence failed closeout verification: " + "; ".join(reasons))
    _stage_bounded(worktree, allowed)
    staged_paths = set(_changed_paths(worktree, "diff", "--cached", "--name-only"))
    if staged_paths - allowed:
        raise RunnerError("coordinator staged an unauthorized path")
    if staged_paths:
        committed = subprocess.run(["git", "commit", "-m", "paired review findings closeout"], cwd=worktree,
                                   text=True, capture_output=True)
        if committed.returncode:
            raise RunnerError(redact(committed.stderr or committed.stdout))
    branch_head = git(worktree, "rev-parse", "--verify", "HEAD^{commit}")
    state = landed_nonpassing_review_state(repo, branch_head, workstream, active_packet_path, target_workstream,
                                           target_packet_path, target_content, authoring_chat, reviewed_main,
                                           run_dir.name)
    if not state["complete"]:
        raise RunnerError("nonpassing review evidence failed exact pre-land verification: " + "; ".join(state["reasons"]))
    report = run_dir / "closeout-integrity.json"
    _write(report, json.dumps(nonpassing_integrity_report(state["outcome"]), indent=2, sort_keys=True) + "\n")
    return _finish_via_workstream(repo, workstream, worktree, report, run_dir)


def _write(path: Path, value: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def _write_atomic(path: Path, value: str):
    """Durably replace a file: a crash leaves either the old or the new bytes, never a torn write."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        handle.write(value)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def _write_bytes_exclusive(path: Path, value: bytes) -> None:
    """Create immutable run evidence without replacing a prior file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(value)
            handle.flush()
            os.fsync(handle.fileno())
    except Exception:
        try:
            path.unlink()
        except OSError:
            pass
        raise
    directory_fd = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(directory_fd)
    finally:
        os.close(directory_fd)


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _file_manifest(root: Path, *, omit: Path | None = None) -> dict[str, str]:
    result: dict[str, str] = {}
    for path in sorted(root.rglob("*")):
        if omit is not None and (path == omit or omit in path.parents):
            continue
        if path.is_symlink():
            raise RunnerError(f"refusing symlink in protected run evidence: {path}")
        if path.is_file():
            result[str(path.relative_to(root))] = _sha256_bytes(path.read_bytes())
    return result


def _advanced_head_original_manifest(run_dir: Path) -> dict[str, str]:
    actual = _file_manifest(run_dir)
    if actual != ADVANCED_HEAD_PASS_ORIGINAL_EVIDENCE_SHA256:
        raise RunnerError("original exact-run evidence manifest changed; advanced-head PASS recovery refused")
    return actual


def _advanced_head_recovery_journal_path(common: Path) -> Path:
    path = common / ADVANCED_HEAD_PASS_RECOVERY_ROOT / ADVANCED_HEAD_PASS_RUN_ID / "recovery.json"
    current = common
    for part in Path(ADVANCED_HEAD_PASS_RECOVERY_ROOT).parts + (ADVANCED_HEAD_PASS_RUN_ID,):
        current = current / part
        if current.is_symlink():
            raise RunnerError("advanced-head recovery journal directory must not contain symlinks")
        if current.exists() and not current.is_dir():
            raise RunnerError("advanced-head recovery journal parent is not a directory")
    if not path.resolve().is_relative_to(common.resolve()):
        raise RunnerError("advanced-head recovery journal escapes shared Git metadata")
    return path


def _advanced_head_packet_header(text: str) -> dict[str, str]:
    """Read unique, unindented metadata lines from this exact archived review packet."""
    lines = text.splitlines()
    header: dict[str, list[str]] = {}
    title_seen = False
    started = False
    for line in lines:
        if not title_seen:
            if not line.strip():
                continue
            if not line.startswith("# "):
                raise RunnerError("archived review packet has no canonical title before its metadata")
            title_seen = True
            continue
        if not started and not line.strip():
            continue
        if not line.strip():
            break
        if line.startswith("#"):
            break
        started = True
        if line.lstrip().startswith("-") and not line.startswith("- "):
            raise RunnerError("archived review packet contains malformed or indented metadata")
        match = re.fullmatch(r"- ([^:]+):[ \t]*(.*?)[ \t]*", line)
        if match:
            key, value = match.groups()
            header.setdefault(key, []).append(value.strip().strip("`").strip())
    for key in ("Workstream", "Kind", "Status", "Review", "Review target workstream",
                "Review target packet", "Reviewed main", "Reviewer context",
                "Reviewer provenance", "Review cycle"):
        if len(header.get(key, [])) != 1:
            raise RunnerError(f"archived review packet must contain exactly one {key} header")
    return {key: values[0] for key, values in header.items() if len(values) == 1}


def _advanced_head_legacy_pass_metadata_is_exact(text: str, workstream: str) -> bool:
    """Recognize only this archived packet's legacy `Review: passed` closeout field."""
    if workstream != ADVANCED_HEAD_PASS_WORKSTREAM:
        return False
    try:
        header = _advanced_head_packet_header(text)
    except RunnerError:
        return False
    outcome, outcome_error = review_outcome.parse_review_outcome(text)
    if (outcome_error or outcome is None or outcome.get("Outcome") != "passed"
            or review_outcome.outcome_identity_error(
                outcome, review_workstream=ADVANCED_HEAD_PASS_WORKSTREAM,
                target_workstream=ADVANCED_HEAD_PASS_TARGET,
                reviewed_main=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
                implementation_commit=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
                run_id=ADVANCED_HEAD_PASS_RUN_ID, review_cycle=0,
            )):
        return False
    return (header.get("Workstream") == ADVANCED_HEAD_PASS_WORKSTREAM
            and header.get("Kind") == "review"
            and header.get("Status") == "complete"
            and header.get("Review") == "passed"
            and header.get("Review target workstream") == ADVANCED_HEAD_PASS_TARGET
            and header.get("Review target packet") == ADVANCED_HEAD_PASS_TARGET_PACKET
            and header.get("Reviewed main") == ADVANCED_HEAD_PASS_REVIEWED_MAIN
            and header.get("Reviewer context") == "fresh"
            and header.get("Reviewer provenance") in review_outcome.PROVENANCE
            and header.get("Review cycle") == "0")


def _append_advanced_head_outcome(original: str, outcome_section: str) -> str:
    separator = "" if original.endswith("\n\n") else "\n" if original.endswith("\n") else "\n\n"
    return original + separator + outcome_section


def _advanced_head_reviewer_pass(repo: Path, run_dir: Path, review_packet: str, summary: str,
                                 metadata: dict) -> tuple[str, str]:
    """Bind the canonical outcome to the reviewer-authored final message and raw session."""
    if (metadata.get("schema") != SCHEMA
            or metadata.get("workstream") != ADVANCED_HEAD_PASS_WORKSTREAM
            or metadata.get("run_id") != ADVANCED_HEAD_PASS_RUN_ID
            or metadata.get("phase") != "post_exit_recovery"
            or metadata.get("fresh") is not True or metadata.get("exit_code") != 0
            or metadata.get("reviewed_main") != ADVANCED_HEAD_PASS_REVIEWED_MAIN):
        raise RunnerError("original run metadata does not prove the exact fresh reviewer session")
    try:
        final = (run_dir / "last-message.txt").read_text(encoding="utf-8")
        lines = (run_dir / "codex.jsonl").read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise RunnerError("reviewer-authored final output or raw session is missing") from exc
    agent_messages: list[str] = []
    completed_turns = 0
    for line in lines:
        try:
            event = json.loads(line)
        except json.JSONDecodeError as exc:
            raise RunnerError("raw reviewer session contains malformed JSON") from exc
        item = event.get("item") if isinstance(event, dict) else None
        if isinstance(item, dict) and item.get("type") == "agent_message":
            if not isinstance(item.get("text"), str):
                raise RunnerError("raw reviewer session contains an invalid agent message")
            agent_messages.append(item["text"])
        if isinstance(event, dict) and event.get("type") == "turn.completed":
            completed_turns += 1
    if (completed_turns != 1 or len(agent_messages) != 1
            or agent_messages[0].strip() != final.strip()):
        raise RunnerError("raw reviewer session and captured final message do not uniquely agree")
    pass_pattern = re.compile(
        r"(?s)\bVerdict:\s*`passed`\s*[—–-]\s*0 blocking defects and 0 material gaps\."
    )
    if len(pass_pattern.findall(final)) != 1:
        raise RunnerError("reviewer-authored final message does not contain one unambiguous PASS")
    if (f"Workstream: {ADVANCED_HEAD_PASS_WORKSTREAM}" not in final
            or ADVANCED_HEAD_PASS_REVIEWED_MAIN not in final
            or "## Review findings" not in summary
            or "## Independent verification" not in summary
            or "Status: `passed`" not in summary
            or "Blocking defects: `0`" not in summary
            or "Material gaps: `0`" not in summary
            or ADVANCED_HEAD_PASS_REVIEWED_MAIN not in summary):
        raise RunnerError("reviewer summary/final output do not support the exact PASS identity")
    packet = _advanced_head_packet_header(review_packet)
    if (packet["Kind"] != "review" or packet["Workstream"] != ADVANCED_HEAD_PASS_WORKSTREAM
            or packet["Review target workstream"] != ADVANCED_HEAD_PASS_TARGET
            or packet["Review target packet"] != ADVANCED_HEAD_PASS_TARGET_PACKET
            or packet["Status"] != "complete" or packet["Review"] != "passed"
            or packet["Reviewer context"] != "fresh"
            or packet["Reviewer provenance"] not in review_outcome.PROVENANCE
            or packet["Review cycle"] != "0"):
        raise RunnerError("archived review packet identity or reviewer provenance is contradictory")
    if (not packet["Reviewed main"] or subprocess.run(
            ["git", "merge-base", "--is-ancestor", packet["Reviewed main"],
             ADVANCED_HEAD_PASS_REVIEWED_MAIN], cwd=repo, capture_output=True).returncode):
        # The packet's Reviewed main records its authoring baseline; the run pins
        # the later immutable review baseline. It must be an ancestor, never a fork.
        raise RunnerError("review packet authoring baseline is not an ancestor of the verified run baseline")
    return packet["Reviewer provenance"], final


def _advanced_head_sha(repo: Path, ref: str) -> str:
    result = subprocess.run(["git", "rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=repo,
                            text=True, capture_output=True)
    if result.returncode:
        raise RunnerError(f"required advanced-head recovery ref is unavailable: {ref}")
    sha = result.stdout.strip()
    if not re.fullmatch(r"[0-9a-f]{40,64}", sha):
        raise RunnerError(f"required advanced-head recovery ref is malformed: {ref}")
    return sha


def _advanced_head_commit_chain(repo: Path, worktree: Path, local_head: str,
                                remote_tip: str, *, allow_recovery_child: bool = False,
                                allow_published_recovery_tip: bool = False
                                ) -> tuple[list[str], list[str], list[str]]:
    if remote_tip not in {ADVANCED_HEAD_PASS_REMOTE_TIP, local_head}:
        raise RunnerError("remote review claim tip is neither the preserved tip nor the journaled recovery commit")
    if (remote_tip == local_head and remote_tip != ADVANCED_HEAD_PASS_REMOTE_TIP
            and not allow_published_recovery_tip):
        raise RunnerError("remote recovery commit has no matching exact-run recovery journal")
    if subprocess.run(["git", "merge-base", "--is-ancestor", remote_tip, local_head],
                      cwd=worktree, capture_output=True).returncode:
        raise RunnerError("remote claim tip is not an ancestor of the preserved local review history")
    if local_head != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
        if not allow_recovery_child:
            raise RunnerError("local recovery child has no matching exact-run recovery journal")
        parent = subprocess.run(["git", "rev-parse", "--verify", f"{local_head}^{{commit}}^"],
                                cwd=worktree, text=True, capture_output=True)
        if parent.returncode or parent.stdout.strip() != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
            raise RunnerError("local review HEAD is not the preserved reviewer commit or its exact recovery child")
    commits = git(worktree, "rev-list", "--reverse",
                  f"{ADVANCED_HEAD_PASS_REMOTE_TIP}..{local_head}").splitlines()
    expected_commits = ([ADVANCED_HEAD_PASS_REVIEWER_COMMIT]
                        if local_head == ADVANCED_HEAD_PASS_REVIEWER_COMMIT
                        else [ADVANCED_HEAD_PASS_REVIEWER_COMMIT, local_head])
    if commits != expected_commits:
        raise RunnerError("local review ancestry contains missing, unrelated, or extra commits")
    if git(worktree, "rev-parse", f"{ADVANCED_HEAD_PASS_REVIEWER_COMMIT}^") != ADVANCED_HEAD_PASS_REMOTE_TIP:
        raise RunnerError("reviewer-authored commit no longer has the exact original remote tip as parent")
    base_paths = sorted(set(git(worktree, "diff", "--no-renames", "--name-only",
                                f"{ADVANCED_HEAD_PASS_REMOTE_TIP}..{ADVANCED_HEAD_PASS_REVIEWER_COMMIT}").splitlines()))
    if set(base_paths) != set(ADVANCED_HEAD_PASS_ALLOWED_BASE_PATHS):
        raise RunnerError("reviewer-authored commit changed paths outside the exact review artifact manifest")
    recovery_paths: list[str] = []
    if local_head != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
        recovery_paths = sorted(set(git(worktree, "diff", "--no-renames", "--name-only",
                                        f"{ADVANCED_HEAD_PASS_REVIEWER_COMMIT}..{local_head}").splitlines()))
        if recovery_paths != [ADVANCED_HEAD_PASS_REVIEW_PACKET]:
            raise RunnerError("recovery child commit changes files outside the one Review Outcome path")
    return commits, base_paths, recovery_paths


def _advanced_head_recovery_journal(common: Path, evidence_manifest: dict[str, str]) -> dict | None:
    path = _advanced_head_recovery_journal_path(common)
    if not path.exists():
        return None
    if path.is_symlink():
        raise RunnerError("advanced-head recovery journal must not be a symlink")
    try:
        journal = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("advanced-head recovery journal is missing or malformed") from exc
    allowed_keys = {"schema", "workstream", "run_id", "reviewer_commit", "stage",
                    "initial_plan_sha256", "original_evidence_sha256", "recovery_commit",
                    "published_head", "reason", "result"}
    if (not isinstance(journal, dict) or set(journal) - allowed_keys
            or journal.get("schema") != ADVANCED_HEAD_PASS_RECOVERY_SCHEMA
            or journal.get("workstream") != ADVANCED_HEAD_PASS_WORKSTREAM
            or journal.get("run_id") != ADVANCED_HEAD_PASS_RUN_ID
            or journal.get("reviewer_commit") != ADVANCED_HEAD_PASS_REVIEWER_COMMIT
            or journal.get("original_evidence_sha256") != evidence_manifest
            or not re.fullmatch(r"[0-9a-f]{64}", str(journal.get("initial_plan_sha256", "")))):
        raise RunnerError("advanced-head recovery journal identity or evidence manifest is contradictory")
    if journal.get("stage") not in {"prepared", "outcome_committed", "published",
                                    "coordinator_closeout_blocked", "complete"}:
        raise RunnerError("advanced-head recovery journal has an unknown transition stage")
    recovery_commit = journal.get("recovery_commit")
    if journal["stage"] == "prepared":
        if recovery_commit is not None:
            raise RunnerError("prepared recovery journal unexpectedly names a recovery commit")
    elif not isinstance(recovery_commit, str) or not re.fullmatch(r"[0-9a-f]{40,64}", recovery_commit):
        raise RunnerError("advanced-head recovery journal omits its committed outcome child")
    if journal.get("published_head") not in (None, recovery_commit):
        raise RunnerError("advanced-head recovery journal published SHA differs from its outcome child")
    if journal["stage"] == "complete":
        result = journal.get("result")
        if (not isinstance(result, dict) or result.get("coordinator_verified") is not True
                or result.get("outcome") != "passed"
                or result.get("reviewer_commit") != ADVANCED_HEAD_PASS_REVIEWER_COMMIT):
            raise RunnerError("completed recovery journal lacks the exact coordinator-verified PASS receipt")
    return journal


def _advanced_head_plan_unlocked(repo: Path) -> dict:
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    run_dir = common / "custodian-review-runs" / ADVANCED_HEAD_PASS_WORKSTREAM / ADVANCED_HEAD_PASS_RUN_ID
    try:
        metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("exact advanced-head review run metadata is missing or malformed") from exc
    if (metadata.get("run_dir") != str(run_dir)
            or metadata.get("branch") != f"agent/{ADVANCED_HEAD_PASS_WORKSTREAM}"
            or Path(str(metadata.get("worktree", ""))).resolve() != Path(ADVANCED_HEAD_PASS_WORKTREE)
            or metadata.get("packet") != ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET):
        raise RunnerError("exact advanced-head run/claim identity differs from the authorized recovery")
    evidence_manifest = _advanced_head_original_manifest(run_dir)
    recovery_journal = _advanced_head_recovery_journal(common, evidence_manifest)
    if list(run_dir.glob("continuation-*")):
        raise RunnerError("exact run has continuation children; preserve them and use their existing recovery")
    if metadata.get("reviewed_main") != ADVANCED_HEAD_PASS_REVIEWED_MAIN:
        raise RunnerError("original review run pins a different reviewed-main SHA")

    main_sha = fetch_and_pin_main(repo)
    if subprocess.run(["git", "merge-base", "--is-ancestor", ADVANCED_HEAD_PASS_REVIEWED_MAIN, main_sha],
                      cwd=repo, capture_output=True).returncode:
        raise RunnerError("current origin/main does not descend from the exact reviewed baseline")
    branch = f"agent/{ADVANCED_HEAD_PASS_WORKSTREAM}"
    git(repo, "fetch", "origin", branch)
    remote_tip = _advanced_head_sha(repo, f"refs/remotes/origin/{branch}")
    claim = _claim_identity(run_dir, ADVANCED_HEAD_PASS_WORKSTREAM, repo, metadata)
    worktree = Path(claim["worktree"]).resolve()
    if (str(worktree) != ADVANCED_HEAD_PASS_WORKTREE
            or claim.get("branch") != branch
            or claim.get("packet") != ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET
            or git(worktree, "branch", "--show-current") != branch
            or common_dir(worktree).resolve() != common):
        raise RunnerError("protected review claim is not attached to its exact original worktree")
    if git(worktree, "status", "--porcelain", "--untracked-files=all"):
        raise RunnerError("protected review worktree is not clean; advanced-head recovery refused")
    reviewer_head = _advanced_head_sha(worktree, "HEAD")
    recovery_child_allowed = bool(recovery_journal)
    published_recovery_tip_allowed = bool(
        recovery_journal and recovery_journal.get("stage") != "prepared"
        and recovery_journal.get("recovery_commit") == reviewer_head
    )
    commits, paths, recovery_paths = _advanced_head_commit_chain(
        repo, worktree, reviewer_head, remote_tip, allow_recovery_child=recovery_child_allowed,
        allow_published_recovery_tip=published_recovery_tip_allowed,
    )
    if reviewer_head != ADVANCED_HEAD_PASS_REVIEWER_COMMIT and not recovery_child_allowed:
        raise RunnerError("local advanced HEAD is not the exact recovery child recorded in its journal")

    target_baseline = _show_at(repo, ADVANCED_HEAD_PASS_REVIEWED_MAIN, ADVANCED_HEAD_PASS_TARGET_PACKET)
    target_text = _show_at(worktree, reviewer_head, ADVANCED_HEAD_PASS_TARGET_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, ADVANCED_HEAD_PASS_REVIEWED_MAIN, ADVANCED_HEAD_PASS_TARGET_PACKET,
        ADVANCED_HEAD_PASS_TARGET, target_baseline,
    )
    if identity_error or implementation_commit != ADVANCED_HEAD_PASS_REVIEWED_MAIN:
        raise RunnerError("reviewed implementation identity failed exact recovery verification: "
                          + str(identity_error or implementation_commit))
    receipt, receipt_error = verify_review_receipt_delta(
        target_baseline, target_text, review_workstream=ADVANCED_HEAD_PASS_WORKSTREAM,
        target_workstream=ADVANCED_HEAD_PASS_TARGET,
        reviewed_main=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
        target_implementation_commit=implementation_commit,
    )
    if receipt_error or receipt is None:
        raise RunnerError("preserved target receipt failed exact baseline verification: "
                          + str(receipt_error or "receipt absent"))
    review_text = _show_at(worktree, reviewer_head, ADVANCED_HEAD_PASS_REVIEW_PACKET)
    summary_text = _show_at(worktree, reviewer_head, ADVANCED_HEAD_PASS_SUMMARY)
    reviewer_provenance, final_message = _advanced_head_reviewer_pass(
        repo, run_dir, review_text, summary_text, metadata,
    )
    expected_outcome = review_outcome.render_review_outcome(
        outcome="passed", review_workstream=ADVANCED_HEAD_PASS_WORKSTREAM,
        target_workstream=ADVANCED_HEAD_PASS_TARGET,
        reviewed_main=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
        implementation_commit=implementation_commit,
        provenance=reviewer_provenance, run_id=ADVANCED_HEAD_PASS_RUN_ID,
        review_cycle=0, ids=(),
    )
    existing_outcome, outcome_error = review_outcome.parse_review_outcome(review_text)
    if outcome_error:
        raise RunnerError("archived reviewer disposition already contains malformed outcome data")
    if reviewer_head == ADVANCED_HEAD_PASS_REVIEWER_COMMIT and existing_outcome is not None:
        raise RunnerError("preserved reviewer commit unexpectedly contains a Review Outcome")
    if reviewer_head != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
        if existing_outcome is None:
            raise RunnerError("recovery child commit is missing its canonical Review Outcome")
        if existing_outcome != review_outcome.parse_review_outcome(expected_outcome)[0]:
            raise RunnerError("recovery child outcome does not exactly match the reviewer-authored PASS")
        parent_text = _show_at(worktree, ADVANCED_HEAD_PASS_REVIEWER_COMMIT, ADVANCED_HEAD_PASS_REVIEW_PACKET)
        expected_text = _append_advanced_head_outcome(parent_text, expected_outcome)
        if review_text != expected_text:
            raise RunnerError("recovery child changed archived review packet bytes beyond the canonical outcome append")

    host_evidence = _host_evidence_for_continuation(
        repo, worktree, run_dir, metadata, ADVANCED_HEAD_PASS_REVIEWED_MAIN,
        implementation_commit, ADVANCED_HEAD_PASS_TARGET, ADVANCED_HEAD_PASS_TARGET_PACKET,
    )
    host_evidence.update({"run_id": ADVANCED_HEAD_PASS_RUN_ID, "review_cycle": 0})
    journal_path = _advanced_head_recovery_journal_path(common)
    result = {
        "schema": "custodian.paired_review_advanced_head_pass_plan.v1",
        "workstream": ADVANCED_HEAD_PASS_WORKSTREAM,
        "run_id": ADVANCED_HEAD_PASS_RUN_ID,
        "reviewed_main": ADVANCED_HEAD_PASS_REVIEWED_MAIN,
        "implementation_commit": implementation_commit,
        "coordinator_main": main_sha,
        "branch": branch,
        "remote_tip": remote_tip,
        "reviewer_commit": ADVANCED_HEAD_PASS_REVIEWER_COMMIT,
        "local_head": reviewer_head,
        "commit_chain": commits,
        "changed_paths": paths,
        "recovery_changed_paths": recovery_paths,
        "run_evidence_sha256": evidence_manifest,
        "review_summary_sha256": _sha256_bytes(summary_text.encode("utf-8")),
        "reviewer_final_sha256": _sha256_bytes(final_message.encode("utf-8")),
        "target_receipt": receipt,
        "outcome": review_outcome.parse_review_outcome(expected_outcome)[0],
        "recovery_state": "outcome_already_appended" if existing_outcome is not None else "outcome_pending",
        "recovery_journal_stage": recovery_journal.get("stage") if recovery_journal else None,
        "recovery_journal": str(journal_path),
        "host_validation": {key: host_evidence[key] for key in
                            ("report_sha256", "metadata_sha256", "implementation_commit")},
    }
    result["plan_sha256"] = _sha256_bytes(json.dumps(result, sort_keys=True, separators=(",", ":")).encode())
    return result


def plan_advanced_head_pass_closeout(repo: Path, workstream: str, run_id: str) -> dict:
    if (workstream != ADVANCED_HEAD_PASS_WORKSTREAM or run_id != ADVANCED_HEAD_PASS_RUN_ID):
        raise RunnerError("advanced-head PASS recovery accepts only its exact authorized workstream and run")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    lock_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    if not lock_path.is_file():
        raise RunnerError("original paired-review supervisor lock is missing")
    with lock_path.open("rb") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError("another supervisor or recovery holds the exact review run") from exc
        return _advanced_head_plan_unlocked(repo)


def apply_advanced_head_pass_closeout(repo: Path, workstream: str, run_id: str,
                                      plan_sha256: str) -> dict:
    if (workstream != ADVANCED_HEAD_PASS_WORKSTREAM or run_id != ADVANCED_HEAD_PASS_RUN_ID
            or not re.fullmatch(r"[0-9a-f]{64}", plan_sha256)):
        raise RunnerError("advanced-head PASS apply requires the exact authorized workstream, run and plan digest")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    lock_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    if not lock_path.is_file():
        raise RunnerError("original paired-review supervisor lock is missing")
    with lock_path.open("rb") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError("another supervisor or recovery holds the exact review run") from exc
        fresh = _advanced_head_plan_unlocked(repo)
        if fresh["plan_sha256"] != plan_sha256:
            raise RunnerError("origin/main, claim, worktree, evidence or plan state changed; obtain a fresh read-only plan")
        worktree = Path(ADVANCED_HEAD_PASS_WORKTREE)
        run_dir = common / "custodian-review-runs" / workstream / run_id
        journal_dir = Path(fresh["recovery_journal"]).parent
        journal_dir.mkdir(parents=True, exist_ok=True)
        journal_path = _advanced_head_recovery_journal_path(common)
        journal = {"schema": ADVANCED_HEAD_PASS_RECOVERY_SCHEMA, "workstream": workstream,
                   "run_id": run_id, "initial_plan_sha256": plan_sha256,
                   "original_evidence_sha256": fresh["run_evidence_sha256"],
                   "reviewer_commit": ADVANCED_HEAD_PASS_REVIEWER_COMMIT,
                   "stage": "prepared"}
        if journal_path.exists():
            try:
                existing = json.loads(journal_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                raise RunnerError("existing advanced-head recovery journal is malformed") from exc
            if (not isinstance(existing, dict) or any(existing.get(key) != value for key, value in journal.items()
                                                       if key != "stage")):
                raise RunnerError("existing recovery journal conflicts with the pinned exact-run evidence")
            journal = existing
        else:
            _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")

        review_path = worktree / ADVANCED_HEAD_PASS_REVIEW_PACKET
        current_text = review_path.read_text(encoding="utf-8")
        outcome, outcome_error = review_outcome.parse_review_outcome(current_text)
        if outcome_error:
            raise RunnerError("archived review packet has malformed outcome content")
        if outcome is None:
            if fresh["local_head"] != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
                raise RunnerError("only the exact reviewer commit may receive the missing outcome section")
            expected_section = review_outcome.render_review_outcome(
                outcome="passed", review_workstream=workstream,
                target_workstream=ADVANCED_HEAD_PASS_TARGET,
                reviewed_main=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
                implementation_commit=fresh["implementation_commit"],
                provenance=fresh["outcome"]["Reviewer provenance"],
                run_id=run_id, review_cycle=0, ids=(),
            )
            review_path.write_text(_append_advanced_head_outcome(current_text, expected_section), encoding="utf-8")
            staged = subprocess.run(["git", "add", "--", ADVANCED_HEAD_PASS_REVIEW_PACKET], cwd=worktree,
                                    text=True, capture_output=True)
            if staged.returncode:
                raise RunnerError(redact(staged.stderr or staged.stdout))
            staged_paths = set(_changed_paths(worktree, "diff", "--cached", "--name-only"))
            if staged_paths != {ADVANCED_HEAD_PASS_REVIEW_PACKET}:
                raise RunnerError("advanced-head recovery staged an unauthorized path")
            if _show_at(worktree, "HEAD", ADVANCED_HEAD_PASS_REVIEW_PACKET) != current_text:
                raise RunnerError("recovery changed reviewer-authored packet bytes before the outcome append")
            committed = subprocess.run(["git", "commit", "-m", "paired review outcome recovery"], cwd=worktree,
                                       text=True, capture_output=True)
            if committed.returncode:
                raise RunnerError(redact(committed.stderr or committed.stdout))
            if git(worktree, "rev-parse", "HEAD^") != ADVANCED_HEAD_PASS_REVIEWER_COMMIT:
                raise RunnerError("recovery commit did not preserve the reviewer-authored commit as its parent")
            journal.update({"stage": "outcome_committed", "recovery_commit": git(worktree, "rev-parse", "HEAD")})
            _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")

        if journal.get("stage") == "prepared":
            journal.update({"stage": "outcome_committed", "recovery_commit": git(worktree, "rev-parse", "HEAD")})
            _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")

        # Publish by ordinary fast-forward only. The subsequent coordinator call
        # delegates validation, landing, cleanup and root sync to workstream.py.
        pushed = subprocess.run(["git", "push", "origin", f"HEAD:refs/heads/{fresh['branch']}"],
                                cwd=worktree, text=True, capture_output=True)
        if pushed.returncode:
            raise RunnerError("fast-forward publication of preserved review history failed: "
                              + redact(pushed.stderr or pushed.stdout))
        journal.update({"stage": "published", "published_head": git(worktree, "rev-parse", "HEAD")})
        _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")

        metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
        active_text = _show_at(worktree, "HEAD", ADVANCED_HEAD_PASS_REVIEW_PACKET)
        packet = parse_packet(ADVANCED_HEAD_PASS_REVIEW_PACKET, active_text)
        target_content = _show_at(repo, ADVANCED_HEAD_PASS_REVIEWED_MAIN, ADVANCED_HEAD_PASS_TARGET_PACKET)
        host_evidence = _host_evidence_for_continuation(
            repo, worktree, run_dir, metadata, ADVANCED_HEAD_PASS_REVIEWED_MAIN,
            fresh["implementation_commit"], ADVANCED_HEAD_PASS_TARGET, ADVANCED_HEAD_PASS_TARGET_PACKET,
        )
        host_evidence.update({"run_id": run_id, "review_cycle": 0})
        try:
            landed = coordinator_finish_review(
                repo, workstream, worktree, ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET,
                ADVANCED_HEAD_PASS_TARGET, ADVANCED_HEAD_PASS_TARGET_PACKET, target_content,
                packet.authoring_chat, ADVANCED_HEAD_PASS_REVIEWED_MAIN,
                journal_dir, host_evidence, defer_teardown=True,
            )
        except (RunnerError, HostValidationError, OSError, ValueError, subprocess.SubprocessError) as exc:
            journal.update({"stage": "coordinator_closeout_blocked", "reason": redact(str(exc))})
            _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")
            raise

        verified_main = fetch_and_pin_main(repo)
        if subprocess.run(["git", "merge-base", "--is-ancestor", ADVANCED_HEAD_PASS_REVIEWER_COMMIT,
                           verified_main], cwd=repo, capture_output=True).returncode:
            raise RunnerError("landed main does not preserve the original reviewer-authored commit ancestry")
        landed_state = landed_review_state(
            repo, verified_main, workstream, ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET,
            ADVANCED_HEAD_PASS_TARGET, ADVANCED_HEAD_PASS_TARGET_PACKET, target_content,
            packet.authoring_chat, ADVANCED_HEAD_PASS_REVIEWED_MAIN,
        )
        if not landed_state["complete"]:
            raise RunnerError("landed advanced-head PASS failed coordinator verification: "
                              + "; ".join(landed_state["reasons"]))
        archived = _show_at(repo, verified_main, ADVANCED_HEAD_PASS_REVIEW_PACKET)
        parsed, parse_error = review_outcome.parse_review_outcome(archived)
        if parse_error or parsed is None:
            raise RunnerError("landed review lacks one canonical Review Outcome")
        identity_error = review_outcome.outcome_identity_error(
            parsed, review_workstream=workstream, target_workstream=ADVANCED_HEAD_PASS_TARGET,
            reviewed_main=ADVANCED_HEAD_PASS_REVIEWED_MAIN,
            implementation_commit=fresh["implementation_commit"], run_id=run_id, review_cycle=0,
        )
        if identity_error or parsed.get("Outcome") != "passed":
            raise RunnerError("landed Review Outcome identity failed: " + str(identity_error or parsed.get("Outcome")))
        _advanced_head_original_manifest(run_dir)
        result = {"schema": ADVANCED_HEAD_PASS_RECOVERY_SCHEMA, "workstream": workstream,
                  "run_id": run_id, "reviewer_commit": ADVANCED_HEAD_PASS_REVIEWER_COMMIT,
                  "landed_commit": landed, "verified_main": verified_main,
                  "outcome": "passed", "reviewer_commit_preserved": True,
                  "original_run_evidence_unchanged": True,
                  "coordinator_verified": True}
        journal.update({"stage": "complete", "result": result})
        _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")
        return result


def _advanced_head_pass_recovery_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="paired_review_runner.py recover-advanced-head-pass")
    parser.add_argument("review_workstream", choices=(ADVANCED_HEAD_PASS_WORKSTREAM,))
    parser.add_argument("--run-id", required=True)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--plan-sha256", help="exact digest from a fresh read-only --plan; required with --apply")
    args = parser.parse_args(argv)
    try:
        if args.plan:
            if args.plan_sha256:
                raise RunnerError("read-only plan cannot include an apply digest")
            result = plan_advanced_head_pass_closeout(Path.cwd(), args.review_workstream, args.run_id)
        else:
            if not args.plan_sha256:
                raise RunnerError("advanced-head PASS apply requires the exact digest from --plan")
            result = apply_advanced_head_pass_closeout(
                Path.cwd(), args.review_workstream, args.run_id, args.plan_sha256,
            )
    except (RunnerError, HostValidationError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"paired_review_runner: BLOCKED: {redact(str(exc))}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


def _procession_pass_closeout_recovery_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="paired_review_runner.py recover-procession-pass-closeout")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true", help="emit a read-only exact-run closeout plan")
    mode.add_argument("--apply", action="store_true", help="apply the exact authorized closeout plan")
    parser.add_argument("--plan-sha256", help="exact digest from a fresh --plan; required with --apply")
    args = parser.parse_args(argv)
    try:
        if args.plan:
            if args.plan_sha256:
                raise RunnerError("read-only Procession PASS plan cannot include an apply digest")
            result = plan_procession_pass_closeout(Path.cwd())
        else:
            if not args.plan_sha256:
                raise RunnerError("Procession PASS closeout apply requires --plan-sha256")
            result = apply_procession_pass_closeout(Path.cwd(), args.plan_sha256)
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (RunnerError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"paired_review_runner: BLOCKED: {redact(str(exc))}", file=sys.stderr)
        return 2


def _preserve_file(source: Path, destination: Path) -> dict[str, str]:
    raw = source.read_bytes()
    _write_bytes_exclusive(destination, raw)
    if destination.read_bytes() != raw:
        raise RunnerError(f"byte-exact preservation check failed for {source}")
    return {"source": str(source), "copy": str(destination), "sha256": _sha256_bytes(raw)}


def _continuation_prompt(workstream: str, packet_path: str, target_path: str, *, run_id: str,
                         target_workstream: str | None = None,
                         reviewed_main: str, implementation_commit: str, authoring_chat: str | None,
                         continuation_dir: Path, preserved: list[dict[str, str]],
                         report_sha256: str, source_span: dict | None = None,
                         validation_report_path: Path | None = None,
                         continuation_number: int = 1) -> str:
    preserved_lines = "\n".join(
        f"- Original `{item['source']}` is preserved byte-for-byte at `{item['copy']}` "
        f"(SHA-256 `{item['sha256']}`). Treat it only as historical worktree context, not as a verdict."
        for item in preserved
    ) or "- No prior worktree review artifacts were present."
    backlink = authoring_chat or "not-recorded"
    source_range = (f"The immutable coordinator validation covered source span `{source_span.get('base')}`..`{source_span.get('head')}`. Inspect that complete source/test diff; the canonical archived implementation identity remains `{implementation_commit}`."
                    if source_span else f"Inspect the source span recorded in `{continuation_dir}/host-validation/coordinator-validation.json`; the canonical archived implementation identity remains `{implementation_commit}`.")
    report_path = validation_report_path or continuation_dir / "prior-run-evidence/validation.json"
    archive_path = f"{PACKET_ROOT}/archived/{Path(packet_path).name}"
    summary_path = expected_summary_path(workstream)
    receipt_target_workstream = target_workstream or (
        "agent-" + Path(target_path).name.removeprefix("AGENT_").removesuffix(".md").lower().replace("_", "-")
    )
    receipt_shape = f"""
If and only if your independent outcome is `passed`, append this canonical structure to `{target_path}` after the exact pinned baseline bytes (fill the provenance truthfully; do not add prose inside the receipt):

## Independent Review

### Review Receipt: {workstream}
- Schema: `custodian.paired_review.v1`
- Review workstream: `{workstream}`
- Review target workstream: `{receipt_target_workstream}`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed main: `{reviewed_main}`
- Reviewed implementation commit: `{implementation_commit}`

Add exactly one such receipt and no duplicate `## Independent Review` section.""" if continuation_number == 2 else ""
    receipt_instruction = f"""
For this explicitly authorized second continuation, use these exact artifact paths:
- Active review packet to complete: `{packet_path}`.
- Complete canonical archived review packet, including the Review Outcome: `{archive_path}`.
- Pinned archived implementation target (do not rewrite its implementation or acceptance): `{target_path}`.
- Append one canonical `## Independent Review` section with exactly one `### Review Receipt: {workstream}` to that target only if your own verdict is `passed`; the receipt path is `{target_path}`. Use the exact canonical receipt fields from `custodian/tools/agent/review_receipt_delta.py`; do not append a PASS receipt for findings or human-required.
- Exact root review summary: `{summary_path}`.

The coordinator will reject a missing archived packet, a receipt placed only in the review packet, an extra or malformed Independent Review section, a mismatched Review Outcome, or a missing summary. Earlier PASS text is not a verdict and is not supplied as review evidence. Prior worktree notes are historical context only; independently re-evaluate the implementation and produce only the verdict you reach. Preserve findings or human-required outcomes without claiming PASS.{receipt_shape}""" if continuation_number == 2 else ""
    return f"""You are a new fresh independent reviewer continuing the exact preserved paired-review claim `{workstream}`.

This is a new ephemeral reviewer context, not a restoration of the original Codex session. The original claim, branch, worktree, and run ID remain unchanged. Review run ID: `{run_id}`. Review the immutable baseline `{reviewed_main}` and implementation commit `{implementation_commit}`. {source_range} Read `{packet_path}`, the archived target `{target_path}`, the original reviewer disposition snapshots below, the implementation's exact root summary, the original authoring-chat URL `{backlink}`, and the immutable coordinator validation report at `{report_path}` (SHA-256 `{report_sha256}`). Independently inspect the exact archived implementation diff and all applicable acceptance claims. A green coordinator report proves execution coverage only; it is not a review verdict.

Original reviewer evidence snapshots:
{preserved_lines}

Write your own findings-first disposition. Retain the old notes as historical evidence and clearly distinguish your independent conclusions. Do not infer or request the original implementation-session transcript. Do not edit implementation/runtime code or the target implementation summary. Author the canonical review receipt, complete archived review packet, and exact root `{summary_path}`. Record `Reviewer context: fresh`, truthful provenance, exact pinned SHAs, and exact authoring-chat backlink. Include one canonical `## Review Outcome` with schema `custodian.review_outcome.v1`, this exact run ID `{run_id}`, the target workstream, review cycle, and `Finding IDs: none` only for `passed`; findings and human-required outcomes need unique stable cycle-scoped finding IDs. If evidence supports findings, `human_required`, or a blocker, record that outcome and leave the claim recoverable; do not manufacture PASS.{receipt_instruction}

The coordinator grants writable access to this continuation evidence directory, the original claimed worktree, and the established CUSTODIAN validation cache roots. Do not run `git fetch`, `git push`, `git add`, `git commit`, `workstream.py checkpoint`, or `workstream.py finish`; the coordinator owns all Git mutation and closeout. Do not claim or resume any workstream. Preserve all original run evidence outside `{continuation_dir}` byte-for-byte."""


def unresolved_prior_run(common: Path, workstream: str, current_run_id: str) -> Path | None:
    """Find a prior post-claim run that must be recovered before any new claim."""
    safe_phases = {"preflight_complete", "claim_failed", "complete"}
    for metadata_path in sorted((common / "custodian-review-runs" / workstream).glob("*/metadata.json")):
        if metadata_path.parent.name == current_run_id:
            continue
        try:
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return metadata_path.parent
        if metadata.get("workstream") == workstream and metadata.get("phase") not in safe_phases:
            return metadata_path.parent
    return None


def safe_output(value: str) -> str:
    """Redact credential-shaped text and secret-keyed JSON fields in runner logs."""
    safe_lines = []
    for line in value.splitlines():
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError:
            safe_lines.append(redact(line))
            continue

        def scrub(item):
            if isinstance(item, dict):
                return {key: "<redacted>" if re.search(r"(?i)(authorization|api.?key|access.?token|refresh.?token|password|secret|credential|private.?key)", str(key)) else scrub(val) for key, val in item.items()}
            if isinstance(item, list):
                return [scrub(val) for val in item]
            if isinstance(item, str):
                return redact(item)
            return item
        safe_lines.append(json.dumps(scrub(parsed), sort_keys=True))
    return "\n".join(safe_lines) + ("\n" if value.endswith("\n") else "")


def next_handoff(summary: str) -> str:
    match = re.search(r"(?ms)^## Next Handoff\s*\n(.*?)(?=^## |\Z)", summary)
    return match.group(1).strip() if match else ""


def expected_summary_path(workstream: str) -> str:
    """Return the one canonical root summary path used by workstream.py."""
    return f"{workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"


def _show_at(repo: Path, revision: str, path: str) -> str:
    """Read one exact path from one pinned commit (never a grep result)."""
    try:
        return read_git_text(repo, revision, path)
    except ValueError as exc:
        raise RunnerError(redact(str(exc))) from exc


def fetch_and_pin_main(repo: Path) -> str:
    """Fetch successfully, then return the immutable commit used for verification."""
    git(repo, "fetch", "origin", "main")
    revision = git(repo, "rev-parse", "--verify", "origin/main^{commit}")
    if not re.fullmatch(r"[0-9a-f]{40,64}", revision):
        raise RunnerError("origin/main did not resolve to a full commit ID")
    return revision


def landed_review_state(repo: Path, revision: str, workstream: str, review_packet_path: str,
                        target_workstream: str, target_packet_path: str,
                        expected_target_content: str, authoring_chat: str | None,
                        reviewed_main: str | None = None) -> dict:
    """Verify completion from exact archived packet, summary and receipt paths."""
    archive_path = f"{PACKET_ROOT}/archived/{Path(review_packet_path).name}"
    result = {"complete": False, "revision": revision, "summary_path": expected_summary_path(workstream),
              "reasons": []}
    try:
        archived_text = _show_at(repo, revision, archive_path)
        summary_text = _show_at(repo, revision, result["summary_path"])
        target_text = _show_at(repo, revision, target_packet_path)
    except RunnerError as exc:
        result["reasons"].append(str(exc))
        return result

    archived = parse_packet(archive_path, archived_text)
    target = parse_packet(target_packet_path, target_text)
    archived_error = archived.error
    if (archived_error == "invalid Review metadata"
            and _advanced_head_legacy_pass_metadata_is_exact(archived_text, workstream)):
        archived_error = None
    if archived_error or archived.kind != "review" or archived.status != "complete" or archived.workstream != workstream:
        result["reasons"].append("exact archived review packet is not complete")
    if archived.review_target_workstream != target_workstream or archived.review_target_packet != target_packet_path:
        result["reasons"].append("archived review packet names a different target")
    archived_receipt = _independent_review_receipt(archived_text)
    if archived_receipt is None:
        result["reasons"].append("archived review packet has no unambiguous independent review receipt")
    else:
        for key, expected in (("Schema", "custodian.paired_review.v1"),
                              ("Review target workstream", target_workstream),
                              ("Status", "passed"), ("Blocking defects", "0"),
                              ("Material gaps", "0"), ("Reviewer context", "fresh")):
            if archived_receipt.get(key) != expected:
                result["reasons"].append(f"archived review receipt has missing or mismatched {key}")
        if archived_receipt.get("Reviewer provenance") not in {"different-agent", "same-agent-fresh-context"}:
            result["reasons"].append("archived review receipt has missing or invalid reviewer provenance")
        if archived_receipt.get("Review workstream", workstream) != workstream:
            result["reasons"].append("archived review receipt identifies a different review workstream")
        if reviewed_main and archived_receipt.get("Reviewed main") != reviewed_main:
            result["reasons"].append("archived review receipt does not match the pinned reviewed main")
    if target.error or target.kind not in {"implementation", "correction"} or target.workstream != target_workstream or target.status != "complete":
        result["reasons"].append("exact reviewed implementation packet is not complete")
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main or "", target_packet_path, target_workstream, expected_target_content,
    )
    receipt, receipt_error = verify_review_receipt_delta(
        expected_target_content, target_text, review_workstream=workstream,
        target_workstream=target_workstream, reviewed_main=reviewed_main or "",
        target_implementation_commit=implementation_commit,
    )
    if identity_error:
        result["reasons"].append(identity_error)
    if receipt_error:
        result["reasons"].append(receipt_error)
    if authoring_chat and archived.authoring_chat != authoring_chat:
        result["reasons"].append("archived review packet changed its authoring-chat identity")
    if reviewed_main and subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, revision],
                                        cwd=repo, text=True, capture_output=True).returncode:
        result["reasons"].append("pinned post-review main is not descended from the reviewed main")

    reviewed_commit_value = receipt.get("Reviewed implementation commit") if receipt else None
    if not reviewed_commit_value:
        result["reasons"].append("independent review receipt is absent or not passed")
    if reviewed_commit_value and implementation_commit:
        commit = reviewed_commit_value
        if archived_receipt and archived_receipt.get("Reviewed implementation commit") != commit:
            result["reasons"].append("archived review receipt names a different implementation commit than target receipt")
        target_full = git(repo, "rev-parse", "--verify", f"{implementation_commit or ''}^{{commit}}", check=False)
        review_full = git(repo, "rev-parse", "--verify", f"{commit}^{{commit}}", check=False)
        if not target_full or target_full != review_full:
            result["reasons"].append("review receipt names a different implementation commit than the archived target")
        if subprocess.run(["git", "cat-file", "-e", f"{commit}^{{commit}}"], cwd=repo,
                          text=True, capture_output=True).returncode:
            result["reasons"].append("reviewed implementation commit is unavailable")
        elif subprocess.run(["git", "merge-base", "--is-ancestor", commit, revision], cwd=repo,
                            text=True, capture_output=True).returncode:
            result["reasons"].append("reviewed implementation commit is not an ancestor of pinned main")
    result["reviewed_implementation_commit"] = reviewed_commit_value
    if authoring_chat and f"Authoring chat: {authoring_chat}" not in summary_text:
        result["reasons"].append("exact closing summary is missing the packet authoring-chat backlink")
    if not next_handoff(summary_text):
        result["reasons"].append("exact closing summary omits Next Handoff")
    result["complete"] = not result["reasons"]
    return result


def _independent_review_receipt(packet_text: str) -> dict[str, str] | None:
    """Parse a single flat receipt from the archived reviewer-authored packet."""
    matches = list(re.finditer(r"(?m)^## Independent Review[ \t]*$", packet_text))
    if len(matches) != 1:
        return None
    section = packet_text[matches[0].end():]
    next_section = re.search(r"(?m)^## [^\r]*$", section)
    if next_section:
        section = section[:next_section.start()]
    result: dict[str, str] = {}
    for name in ("Schema", "Review workstream", "Review target workstream", "Status",
                 "Blocking defects", "Material gaps", "Reviewer context", "Reviewer provenance",
                 "Reviewed main", "Reviewed implementation commit"):
        values = re.findall(rf"(?m)^- {re.escape(name)}: `?([^`\r\n]+)`?\s*$", section)
        if len(values) == 1:
            result[name] = values[0].strip()
    return result


def _repair_invalid_disposition(original: bytes) -> tuple[bytes, dict[str, str]]:
    """Relocate the four known handoff lines without changing a canonical outcome byte."""
    if _sha256_bytes(original) != INVALID_DISPOSITION_SHA256:
        raise RunnerError("preserved disposition digest does not match the authorized invalid-disposition recovery")
    try:
        text = original.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise RunnerError("preserved disposition is not UTF-8") from exc
    sections = list(review_outcome._SECTION_RE.finditer(text))
    if len(sections) != 1:
        raise RunnerError("invalid-disposition recovery requires exactly one Review Outcome section")
    start = sections[0].start()
    canonical_field = re.search(r"(?m)^- Finding IDs: `[^`\r\n]+`\r?\n", text[sections[0].end():])
    if canonical_field is None:
        raise RunnerError("invalid-disposition recovery cannot identify the end of the canonical outcome fields")
    canonical_end = sections[0].end() + canonical_field.end()
    if text[canonical_end:].startswith("\r\n"):
        canonical_end += 2
    elif text[canonical_end:].startswith("\n"):
        canonical_end += 1
    suffix = text[canonical_end:]
    if not suffix.endswith("\n"):
        raise RunnerError("invalid-disposition recovery requires the exact captured trailing handoff")
    suffix_lines = suffix.splitlines()
    expected_labels = ("Refresh reason", "Next action", "Blockers or open questions")
    values: dict[str, str] = {}
    if len(suffix_lines) != 5 or suffix_lines[3] != "":
        raise RunnerError("invalid-disposition recovery requires the exact four-line handoff")
    for line, label in zip(suffix_lines[:3], expected_labels, strict=True):
        match = re.fullmatch(rf"- {re.escape(label)}: `([^`\r\n]+)`", line)
        if match is None:
            raise RunnerError("invalid-disposition recovery requires the exact four-line handoff")
        values[label] = match.group(1)
    authoring = re.fullmatch(r"Authoring chat: (https://[^\s`]+)", suffix_lines[4])
    if authoring is None:
        raise RunnerError("invalid-disposition recovery requires the exact four-line handoff")
    values["Authoring chat"] = authoring.group(1)
    if (values["Refresh reason"] != "none"
            or values["Authoring chat"] == ""):
        raise RunnerError("invalid-disposition handoff values do not match the captured reviewer evidence")

    handoff = (
        "\n## Next Handoff\n\n"
        f"- Refresh reason: `{values['Refresh reason']}`\n"
        f"- Next action: `{values['Next action']}`\n"
        f"- Blockers or open questions: `{values['Blockers or open questions']}`\n"
        f"- Authoring chat: `{values['Authoring chat']}`\n"
    )
    repaired_text = text[:canonical_end] + handoff
    outcome, error = review_outcome.parse_review_outcome(repaired_text)
    if error or outcome is None:
        raise RunnerError(f"relocated disposition does not pass the canonical outcome parser: {error or 'missing'}")
    canonical_before = text[start:canonical_end]
    canonical_after_start = repaired_text.index("## Review Outcome")
    canonical_after_end = repaired_text.index("## Next Handoff", canonical_after_start)
    canonical_after = repaired_text[canonical_after_start:canonical_after_end]
    if canonical_after.removesuffix("\n") != canonical_before:
        raise RunnerError("invalid-disposition repair changed canonical outcome bytes")
    if (outcome.get("Outcome") != "passed"
            or outcome.get("Review workstream") != INVALID_DISPOSITION_WORKSTREAM
            or outcome.get("Review target workstream") != INVALID_DISPOSITION_TARGET
            or outcome.get("Reviewed main") != INVALID_DISPOSITION_IMPLEMENTATION
            or outcome.get("Reviewed implementation commit") != INVALID_DISPOSITION_IMPLEMENTATION
            or outcome.get("Run ID") != INVALID_DISPOSITION_RUN_ID
            or outcome.get("Review cycle") != "0"
            or outcome.get("Finding IDs") != "none"
            or outcome.get("Reviewer provenance") != "same-agent-fresh-context"):
        raise RunnerError("canonical disposition identity or reviewer outcome differs from the authorized PASS")
    return repaired_text.encode("utf-8"), outcome


def _append_verified_invalid_disposition_receipt(baseline: str, reviewer_receipt: dict[str, str]) -> bytes:
    """Append the one target receipt supported by the preserved reviewer-authored PASS."""
    expected_fields = {
        "Schema", "Review workstream", "Review target workstream", "Status", "Blocking defects",
        "Material gaps", "Reviewer context", "Reviewer provenance", "Reviewed main",
        "Reviewed implementation commit",
    }
    if set(reviewer_receipt) != expected_fields or any(not reviewer_receipt.get(key) for key in expected_fields):
        raise RunnerError("reviewer-authored PASS receipt is incomplete or ambiguous")
    expected = {
        "Schema": "custodian.paired_review.v1",
        "Review workstream": INVALID_DISPOSITION_WORKSTREAM,
        "Review target workstream": INVALID_DISPOSITION_TARGET,
        "Status": "passed", "Blocking defects": "0", "Material gaps": "0",
        "Reviewer context": "fresh", "Reviewed main": INVALID_DISPOSITION_IMPLEMENTATION,
        "Reviewed implementation commit": INVALID_DISPOSITION_IMPLEMENTATION,
    }
    if any(reviewer_receipt.get(key) != value for key, value in expected.items()):
        raise RunnerError("reviewer-authored PASS receipt does not match the exact pinned review identity")
    if reviewer_receipt.get("Reviewer provenance") not in review_outcome.PROVENANCE:
        raise RunnerError("reviewer-authored PASS receipt has invalid reviewer provenance")
    if re.search(r"(?m)^## Independent Review[ \t]*$", baseline):
        raise RunnerError("pinned target baseline already contains an Independent Review section")
    fields = (
        "Schema", "Review workstream", "Review target workstream", "Status", "Blocking defects",
        "Material gaps", "Reviewer context", "Reviewer provenance", "Reviewed main",
        "Reviewed implementation commit",
    )
    receipt = f"### Review Receipt: {INVALID_DISPOSITION_WORKSTREAM}\n" + "".join(
        f"- {name}: `{reviewer_receipt[name]}`\n" for name in fields
    )
    if not baseline.endswith("\n"):
        raise RunnerError("pinned target baseline must end with a newline")
    candidate = baseline + "\n## Independent Review\n\n" + receipt
    verified, error = verify_review_receipt_delta(
        baseline, candidate, review_workstream=INVALID_DISPOSITION_WORKSTREAM,
        target_workstream=INVALID_DISPOSITION_TARGET,
        reviewed_main=INVALID_DISPOSITION_IMPLEMENTATION,
        target_implementation_commit=INVALID_DISPOSITION_IMPLEMENTATION,
    )
    if error or verified != reviewer_receipt:
        raise RunnerError("reviewer-authored PASS receipt failed verify_review_receipt_delta: "
                          + (error or "receipt values differ"))
    return candidate.encode("utf-8")


def launch_codex(argv: list[str], worktree: Path, prompt: str, run_dir: Path, timeout: float | None) -> int:
    """Stream redacted JSONL/stderr to durable files while supervising Codex."""
    with (run_dir / "codex.jsonl").open("w", encoding="utf-8") as stdout_log, \
         (run_dir / "codex.stderr").open("w", encoding="utf-8") as stderr_log:
        process = subprocess.Popen(argv, cwd=worktree, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, bufsize=1)

        def copy_lines(source, destination):
            for line in iter(source.readline, ""):
                destination.write(safe_output(line))
                destination.flush()
            source.close()

        stdout_thread = threading.Thread(target=copy_lines, args=(process.stdout, stdout_log), daemon=True)
        stderr_thread = threading.Thread(target=copy_lines, args=(process.stderr, stderr_log), daemon=True)
        stdout_thread.start()
        stderr_thread.start()
        try:
            process.stdin.write(prompt)
            process.stdin.close()
            try:
                process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                raise
        finally:
            stdout_thread.join(timeout=10)
            stderr_thread.join(timeout=10)
        return process.returncode


def run(repo: Path, workstream: str, *, codex_path: str | None = None, timeout: float | None = None) -> int:
    if not ID_RE.fullmatch(workstream):
        raise RunnerError("review workstream must be lowercase kebab-case")
    if timeout is not None and (timeout <= 0 or not float(timeout) < float("inf")):
        raise RunnerError("timeout must be a positive finite number")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    expected_packet_path, _content, packet = validate_eligible_review(repo, workstream)
    executable = codex_path or codex_preflight()
    if codex_path:
        help_result = subprocess.run([executable, "exec", "--help"], text=True, capture_output=True)
        if help_result.returncode or "--ephemeral" not in (help_result.stdout + help_result.stderr):
            raise RunnerError("test/injected Codex executable lacks ephemeral exec support")

    common = common_dir(repo)
    cache_roots = reviewer_cache_roots(repo)
    run_id = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:12]}"
    run_dir = common / "custodian-review-runs" / workstream / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    mutex_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    mutex_path.parent.mkdir(parents=True, exist_ok=True)
    with mutex_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError(f"another local runner already supervises {workstream}; no claim attempted") from exc
        metadata = {"schema": SCHEMA, "run_id": run_id, "workstream": workstream,
                    "phase": "preflight_complete", "created_utc": datetime.now(timezone.utc).isoformat(),
                    "run_dir": str(run_dir)}
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        prior_run = unresolved_prior_run(common, workstream, run_id)
        if prior_run:
            metadata.update({"phase": "blocked_prior_recovery", "prior_run_dir": str(prior_run)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"A prior run for `{workstream}` passed claim and has unresolved state. Recover it before another review claim. Prior evidence: `{prior_run}`. No new dispatcher claim was attempted.\n")
            raise RunnerError(f"prior claimed review needs recovery before retry; inspect {prior_run}; no new claim attempted")
        claim_cmd = [sys.executable, str(repo / "custodian/tools/agent/dispatch.py"), "claim", workstream,
                     "--agent", "codex-reviewer"]
        claimed = subprocess.run(claim_cmd, cwd=repo, text=True, capture_output=True)
        _write(run_dir / "claim.stdout", redact(claimed.stdout))
        _write(run_dir / "claim.stderr", redact(claimed.stderr))
        if claimed.returncode:
            metadata["phase"] = "claim_failed"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            raise RunnerError(f"exact review claim failed; no Codex process launched (see {run_dir})")
        try:
            receipt = parse_claim_receipt(claimed.stdout, workstream, repo)
        except RunnerError as exc:
            metadata.update({"phase": "claim_receipt_invalid", "receipt_error": redact(str(exc))})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Dispatcher reported a successful claim but its receipt could not be verified. Do not retry or reclaim `{workstream}` until `dispatch.py last-claim --json` and remote claims are reconciled. Run evidence: `{run_dir}`.\n")
            raise
        receipt_bytes = (json.dumps(receipt, indent=2, sort_keys=True) + "\n").encode("utf-8")
        _write_bytes_exclusive(run_dir / "claim-receipt.json", receipt_bytes)
        worktree = Path(receipt["worktree"]).resolve()
        actual_path = receipt["packet"]
        if actual_path != expected_packet_path:
            metadata.update({"phase": "claim_packet_mismatch", "worktree": str(worktree), "branch": receipt["branch"]})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Dispatcher claimed an unexpected packet for `{workstream}`. Preserve branch `{receipt['branch']}` and worktree `{worktree}` and reconcile the claim. Run evidence: `{run_dir}`.\n")
            raise RunnerError("dispatcher receipt packet differs from the fetched eligible packet")
        if not (worktree / actual_path).is_file():
            _write(run_dir / "RECOVERY.md", f"Claimed packet missing from verified worktree. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"claimed packet missing from verified worktree; recover at {worktree}")
        # Pin the baseline from the claimed checkout after dispatch has finished
        # synchronizing it. Keep the SHA and target bytes fixed for the full run.
        reviewed_main = git(worktree, "rev-parse", "--verify", "origin/main^{commit}")
        try:
            target_content = read_git_text(worktree, reviewed_main, packet.review_target_packet)
        except ValueError as exc:
            raise RunnerError("claimed review target is absent from its pinned main") from exc
        implementation_commit, identity_error = resolve_target_implementation_commit(
            worktree, reviewed_main, packet.review_target_packet,
            packet.review_target_workstream or "", target_content,
        )
        if identity_error:
            raise RunnerError("claimed review target implementation identity is invalid: " + identity_error)
        try:
            host_evidence = run_coordinator_validation(
                worktree, run_dir, reviewed_main, implementation_commit,
                target_workstream=packet.review_target_workstream,
                target_packet_path=packet.review_target_packet,
            )
        except HostValidationError as exc:
            metadata.update({"phase": "host_validation_recovery", "reviewed_main": reviewed_main,
                             "implementation_commit": implementation_commit,
                             "host_validation_error": redact(str(exc)), "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Trusted coordinator host validation failed before reviewer launch: {redact(str(exc))}. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`. No reviewer verdict was requested. Do not reclaim.\n")
            raise RunnerError(f"host validation failed before reviewer launch; claim preserved at {worktree}; evidence: {run_dir}") from exc
        metadata["host_validation"] = {key: value for key, value in host_evidence.items()
                                       if key in {"implementation_parent", "report_path", "report_sha256",
                                                  "metadata_sha256", "summary", "selected", "source_span",
                                                  "source_span_base", "source_span_head"}}
        metadata.update({"phase": "claimed", "branch": receipt["branch"], "worktree": str(worktree),
                         "packet": actual_path, "codex": str(executable), "fresh": True})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        last_message = run_dir / "last-message.txt"
        argv = [str(executable), "exec", "--ephemeral", "--json", "--approve-for-me",
                "--cd", str(worktree), "--add-dir", str(run_dir)]
        for cache_root in cache_roots:
            argv.extend(("--add-dir", str(cache_root)))
        argv.extend(("--output-last-message", str(last_message), "-"))
        metadata["phase"] = "codex_running"
        metadata["invocation"] = ["codex", "exec", "--ephemeral", "--json", "--approve-for-me",
                                  "--cd", str(worktree), "--add-dir", "<run-dir>",
                                  *(item for root in cache_roots for item in ("--add-dir", str(root))),
                                  "--output-last-message", "<run-dir>/last-message.txt", "-"]
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        started = time.monotonic()
        try:
            exit_code = launch_codex(argv, worktree, prompt_for(workstream, actual_path,
                                      packet.review_target_packet or "", run_dir=run_dir,
                                      authoring_chat=packet.authoring_chat,
                                      reviewed_main=reviewed_main,
                                      implementation_commit=implementation_commit,
                                      implementation_summary_path=expected_summary_path(packet.review_target_workstream or ""),
                                      validation_sha256=host_evidence["report_sha256"],
                                      source_span=host_evidence.get("source_span")), run_dir, timeout)
        except subprocess.TimeoutExpired:
            metadata.update({"phase": "codex_timeout_recovery", "elapsed_seconds": round(time.monotonic() - started, 3),
                             "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex timed out after claim. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`. Do not delete or reclaim.\n")
            return 2
        except OSError as exc:
            metadata.update({"phase": "codex_launch_failed_recovery", "launch_error": redact(str(exc)),
                             "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex failed to launch after claim: {redact(str(exc))}. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`. Do not delete or reclaim.\n")
            return 2
        if last_message.is_file():
            _write(last_message, safe_output(last_message.read_text(encoding="utf-8", errors="replace")))
        elif exit_code == 0:
            metadata["phase"] = "failed_missing_final_message"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex exited 0 without the required final-message capture. Preserve branch `{receipt['branch']}` and worktree `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"final-message capture is missing; recovery at {run_dir}")
        metadata.update({"phase": "codex_exited", "exit_code": exit_code,
                         "elapsed_seconds": round(time.monotonic() - started, 3)})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")

        try:
            # A failed fetch cannot be replaced with stale refs or reviewer-local files.
            pinned_main = fetch_and_pin_main(repo)
            if exit_code == 0:
                try:
                    verify_coordinator_validation(worktree, run_dir, reviewed_main, implementation_commit,
                                                  target_workstream=packet.review_target_workstream,
                                                  target_packet_path=packet.review_target_packet,
                                                  expected_report_sha256=host_evidence["report_sha256"],
                                                  expected_metadata_sha256=host_evidence["metadata_sha256"])
                except HostValidationError as exc:
                    raise RunnerError(f"coordinator validation evidence failed post-review verification: {exc}") from exc
                pinned_main = coordinator_finish_review(repo, workstream, worktree, actual_path,
                                                       packet.review_target_workstream or "",
                                                       packet.review_target_packet or "", target_content,
                                                       packet.authoring_chat, reviewed_main, run_dir,
                                                       host_evidence)
            state = landed_review_state(repo, pinned_main, workstream, actual_path,
                                        packet.review_target_workstream or "",
                                        packet.review_target_packet or "", target_content,
                                        packet.authoring_chat, reviewed_main)
        except RunnerError as exc:
            metadata.update({"phase": "post_exit_recovery", "reviewed_main": reviewed_main,
                             "post_exit_error": redact(str(exc)), "recovery_worktree": str(worktree)})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Coordinator could not verify/land review evidence: {redact(str(exc))}. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`. Do not reclaim the review.\n")
            raise RunnerError(f"post-exit coordinator recovery required; preserve claim at {worktree}; evidence: {run_dir}") from exc
        complete = state["complete"]
        if exit_code == 0 and not complete:
            metadata.update({"phase": "failed_missing_durable_review_state", "post_exit_state": state})
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Codex exited 0 but exact landed review evidence is incomplete: {state['reasons']}. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"Codex exited 0 without durable review state; recovery at {run_dir}")
        summary_path = state["summary_path"]
        try:
            summary_text = _show_at(repo, pinned_main, summary_path)
        except RunnerError:
            summary_text = ""
        if not complete and not re.search(r"(?i)\b(blocked|blocker|partial|failed|incomplete|unable)\b", summary_text):
            metadata["phase"] = "failed_unexplained_active_review"
            _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
            _write(run_dir / "RECOVERY.md", f"Review workstream is active but its summary does not explain the blocker. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            raise RunnerError(f"active review lacks an explicit blocker explanation; recovery at {run_dir}")
        handoff = next_handoff(summary_text)
        metadata.update({"phase": "complete" if complete else "blocked_recoverable",
                         "reviewed_main": reviewed_main, "post_exit_main": pinned_main,
                         "durable_summary": summary_path, "archived_on_origin_main": complete,
                         "post_exit_state": state,
                         "next_handoff": handoff})
        _write(run_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")
        print(f"paired_review_runner: {'COMPLETE' if complete else 'BLOCKED_RECOVERABLE'} {workstream}")
        print(f"persistent summary: {summary_path}")
        if handoff:
            print("## Next Handoff\n" + handoff)
        if not complete:
            _write(run_dir / "RECOVERY.md", f"Review remains active/blocked with durable summary. Preserve `{receipt['branch']}` and `{worktree}`. Run evidence: `{run_dir}`.\n")
            return 2
        return exit_code


JOURNAL_SCHEMA = "custodian.paired_review_closeout_journal.v1"
JOURNAL_NAME = "closeout-journal.json"
CLOSEOUT_STAGES = ("prepared", "outcome_written", "committed", "published", "landed", "complete")
_RUN_ID_RE = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$")


def _branch_scope_error(worktree: Path, revision: str, allowed: set[str]) -> str | None:
    """The branch's own commits (merge-base with origin/main .. revision) must stay in bounded paths.

    Working-tree cleanliness is not enough: committed arbitrary files would otherwise ride a
    recovery landing onto main.
    """
    # --no-renames: default rename detection prints only the destination and would hide a deleted source.
    outside = sorted(set(_changed_paths(worktree, "diff", "--no-renames", "--name-only",
                                        f"origin/main...{revision}")) - allowed)
    if outside:
        return "review branch commits change files outside the bounded evidence scope: " + ", ".join(outside)
    return None


_CLAIM_PARSE_ERRORS = ("dispatcher claim receipt was malformed",
                       "dispatcher did not return exactly one structured claim receipt")


def _claim_identity(run_dir: Path, workstream: str, repo: Path, metadata: dict) -> dict:
    """The original claim's branch/worktree/packet identity, verified.

    The structured dispatcher receipt is preferred and judged strictly. Older runs stored a
    truncated ``claim.stdout`` whose JSON receipt is cut off mid-string. Only for that
    parse failure, the plain header lines of the same file must agree exactly with
    ``metadata.json`` on all four identity fields, and the worktree, branch, repository
    and packet path are then verified in Git exactly as for a structured receipt. A
    receipt that parses but does not verify, or any disagreement, still fails closed.
    """
    text = (run_dir / "claim.stdout").read_text(encoding="utf-8")
    try:
        return parse_claim_receipt(text, workstream, repo)
    except RunnerError as structured:
        if not any(marker in str(structured) for marker in _CLAIM_PARSE_ERRORS):
            raise
        if sum(line.startswith(CLAIM_SENTINEL) for line in text.splitlines()) > 1:
            raise  # conflicting receipts are not a truncation
    lines = text.splitlines()
    if not lines or lines[0].strip() != "CLAIMED":
        raise RunnerError("claim.stdout has neither a parseable receipt nor a CLAIMED header")
    header: dict[str, str] = {}
    for line in lines[1:]:
        if not line.strip():
            break
        key, separator, value = line.partition(": ")
        if separator and key in ("workstream", "branch", "worktree", "packet"):
            if key in header:
                raise RunnerError(f"claim.stdout header repeats {key}")
            header[key] = value.strip()
    expected = {"workstream": workstream, "branch": metadata.get("branch"),
                "worktree": metadata.get("worktree"), "packet": metadata.get("packet")}
    if header != expected:
        raise RunnerError("claim.stdout header does not match the run metadata identity")
    worktree = Path(header["worktree"]).resolve()
    if not worktree.is_dir() or git(worktree, "branch", "--show-current") != header["branch"]:
        raise RunnerError("claimed worktree/branch identity could not be verified")
    if common_dir(worktree) != common_dir(repo):
        raise RunnerError("claimed worktree belongs to another repository")
    if header["packet"] != f"{PACKET_ROOT}/{Path(header['packet']).name}":
        raise RunnerError("claimed packet path is not a root task packet")
    return {"schema": "custodian.dispatch.claim.v1", "result": "claimed", "verified": True,
            "workstream": workstream, "branch": header["branch"], "worktree": str(worktree),
            "packet": header["packet"], "source": "claim.stdout header (receipt truncated)"}


def _remote_branch_exists(repo: Path, branch: str) -> bool:
    return bool(subprocess.run(["git", "ls-remote", "--heads", "origin", f"refs/heads/{branch}"], cwd=repo,
                               text=True, capture_output=True).stdout.strip())


def _release_claim(repo: Path, branch: str) -> bool:
    """Delete the remote claim branch only when every commit on it is already on origin/main.

    The delete is conditional on the exact SHA that was verified, so a push by a reviewer
    that is somehow still alive between the check and the delete is never destroyed.
    """
    if not _remote_branch_exists(repo, branch):
        return True
    git(repo, "fetch", "origin", "main", branch)
    sha = git(repo, "rev-parse", "--verify", f"origin/{branch}^{{commit}}")
    if subprocess.run(["git", "merge-base", "--is-ancestor", sha, "origin/main"], cwd=repo,
                      capture_output=True).returncode:
        raise RunnerError("claim release refused: the published review branch has commits not on origin/main")
    git(repo, "push", "origin", f"--force-with-lease=refs/heads/{branch}:{sha}", f":refs/heads/{branch}")
    return not _remote_branch_exists(repo, branch)


def _worktree_inventory(worktree: Path) -> dict[str, str]:
    """SHA-256 of every modified or untracked file, so a protected checkout can be proven untouched."""
    raw = subprocess.run(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"], cwd=worktree,
                         capture_output=True)
    if raw.returncode:
        raise RunnerError(redact(raw.stderr.decode("utf-8", errors="replace")))
    inventory: dict[str, str] = {}
    entries = [entry for entry in raw.stdout.decode("utf-8", errors="surrogateescape").split("\0") if entry]
    index = 0
    while index < len(entries):
        entry = entries[index]
        status, name = entry[:2], entry[3:]
        if status[0] in "RC":
            index += 1  # the next NUL field is the rename/copy source
        target = worktree / name
        inventory[name] = (hashlib.sha256(target.read_bytes()).hexdigest() if target.is_file() else "<absent>")
        index += 1
    return inventory


def _closeout_intent(workstream: str, run_id: str, outcome: str, ids: tuple[str, ...], provenance: str,
                     tip: str, reviewed_main: str, implementation_commit: str) -> dict:
    return {"workstream": workstream, "run_id": run_id, "outcome": outcome, "finding_ids": list(ids),
            "provenance": provenance, "published_tip": tip, "reviewed_main": reviewed_main,
            "implementation_commit": implementation_commit}


def _default_lander(worktree: Path) -> None:
    # The runner publishes the recovery commits on the claim branch before landing, so landing must
    # tolerate exactly that ref (and only for a fast-forward; land_main still refuses it for a rebase).
    upstream = subprocess.run(["git", "rev-parse", "--symbolic-full-name", "@{upstream}"], cwd=worktree,
                              text=True, capture_output=True).stdout.strip()
    allow = ["--allow-published-ref", upstream] if upstream.startswith("refs/remotes/origin/agent/") else []
    landed = subprocess.run([sys.executable, str(Path(__file__).with_name("land_main.py")), *allow], cwd=worktree,
                            env={**os.environ, "CUSTODIAN_WORKSTREAM_FINISH": "1"}, text=True, capture_output=True)
    if landed.returncode:
        raise RunnerError("land_main blocked; recovery state preserved: " + redact(landed.stderr or landed.stdout))


def recover_closeout(repo: Path, workstream: str, run_id: str, *, isolated_checkout: Path, outcome: str,
                     ids: tuple[str, ...], provenance: str, apply: bool = False, release_claim: bool = False,
                     lander=None) -> dict:
    """Plan or apply the administrative findings/human_required closeout of one stranded review run.

    The original claim, branch, worktree and run evidence are never modified: the recovery
    works in its own recovery-branch checkout at the exact published tip, journals every
    stage atomically, and converges on retry. The claim is released (remote agent branch
    deleted) only when ``release_claim`` is passed AND every unique commit is already on
    ``origin/main``. A plan (``apply=False``) writes nothing in the repository or run directory.
    """
    if not ID_RE.fullmatch(workstream) or not _RUN_ID_RE.fullmatch(run_id):
        raise RunnerError("recovery needs an exact review workstream and run ID")
    if outcome not in review_outcome.NONPASSING:
        raise RunnerError("recovery closes a review only as findings or human_required; a pass is never recovered")
    if not ids or not all(review_outcome.FINDING_ID_RE.fullmatch(item) for item in ids) or len(set(ids)) != len(ids):
        raise RunnerError("recovery requires unique stable finding IDs such as R0-01")
    if provenance not in review_outcome.PROVENANCE:
        raise RunnerError("recovery requires an explicit reviewer provenance")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    if git(repo, "status", "--porcelain", "--untracked-files=no"):
        raise RunnerError("a dirty persistent coordination checkout is not a recovery surface; use a clean checkout")
    common = common_dir(repo)
    run_dir = common / "custodian-review-runs" / workstream / run_id
    try:
        metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"original run metadata is missing or malformed: {exc}") from exc
    if (metadata.get("schema") != SCHEMA or metadata.get("run_id") != run_id
            or metadata.get("workstream") != workstream):
        raise RunnerError("original run metadata does not match the requested review run")
    if metadata.get("phase") not in {"post_exit_recovery", "closeout_recovery"}:
        raise RunnerError(f"run phase {metadata.get('phase')!r} is not a recoverable post-exit state")
    journal_path = run_dir / JOURNAL_NAME
    journal = json.loads(journal_path.read_text(encoding="utf-8")) if journal_path.is_file() else None
    if journal and journal.get("stage") not in CLOSEOUT_STAGES:
        raise RunnerError("recovery journal has an unrecognized stage; refusing to guess")

    lock_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError("another supervisor or recovery already holds this review workstream") from exc
        return _recover_locked(repo, common, workstream, run_id, run_dir, metadata, journal, journal_path,
                               isolated_checkout, outcome, ids, provenance, apply, release_claim,
                               lander or _default_lander)


def _recover_locked(repo, common, workstream, run_id, run_dir, metadata, journal, journal_path,
                    isolated_checkout, outcome, ids, provenance, apply, release_claim, lander) -> dict:
    git(repo, "fetch", "origin", "main")
    claim = _claim_identity(run_dir, workstream, repo, metadata)
    branch, original = claim["branch"], Path(claim["worktree"]).resolve()
    if branch != f"agent/{workstream}" or branch != metadata.get("branch") or str(original) != str(
            Path(metadata.get("worktree", "")).resolve()):
        raise RunnerError("claim receipt, run metadata and branch do not name the same claimed worktree")
    if journal and journal.get("stage") == "complete":
        result = journal["result"]
        if release_claim and not result.get("claim_released"):
            # A completed recovery may release its claim later, but only with the protected
            # original still byte-identical to what was journaled before any write.
            if (_worktree_inventory(original) != journal.get("inventory")
                    or git(original, "rev-parse", "HEAD") != journal["intent"]["published_tip"]):
                raise RunnerError("the protected original worktree changed; refusing to release the claim")
            released = _release_claim(repo, branch)
            result = {**result, "claim_released": released, "claim_release_pending": not released,
                      "claim_release_requested": True}
            _write_atomic(journal_path, json.dumps({**journal, "result": result}, indent=2, sort_keys=True) + "\n")
        return result
    if journal:
        # Retries trust only the tip recorded before any write: publishing advances origin/<branch>.
        tip = journal["intent"]["published_tip"]
    else:
        git(repo, "fetch", "origin", branch)
        tip = git(repo, "rev-parse", "--verify", f"origin/{branch}^{{commit}}")
    if git(original, "rev-parse", "HEAD") != tip:
        raise RunnerError("original worktree HEAD is not the exact published branch tip")
    reviewed_main = metadata.get("reviewed_main", "")
    if not re.fullmatch(r"[0-9a-f]{40,64}", reviewed_main) or subprocess.run(
            ["git", "merge-base", "--is-ancestor", reviewed_main, tip], cwd=repo, capture_output=True).returncode:
        raise RunnerError("pinned reviewed main is missing or not an ancestor of the published review branch")
    active_path = claim["packet"]
    archive_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
    tip_packet_path = active_path if subprocess.run(
        ["git", "cat-file", "-e", f"{tip}:{active_path}"], cwd=repo, capture_output=True).returncode == 0 else archive_path
    tip_packet = _show_at(repo, tip, tip_packet_path)
    header = parse_packet(tip_packet_path, tip_packet)
    if header.error or header.kind != "review" or header.workstream != workstream or not header.review_target_packet:
        raise RunnerError("published review packet is not the exact claimed review")
    target_workstream, target_path = header.review_target_workstream, header.review_target_packet
    target_content = _show_at(repo, reviewed_main, target_path)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, target_path, target_workstream, target_content)
    if identity_error:
        raise RunnerError("pinned target implementation identity is invalid: " + identity_error)
    if _show_at(repo, tip, target_path) != target_content:
        raise RunnerError("published review branch changed the reviewed target packet")
    evidence = tip_packet.split("## Review Outcome")[0]
    for finding in ids:
        if not review_outcome.finding_evidenced(evidence, finding):
            raise RunnerError(f"finding {finding} has no written evidence in the preserved review packet")
    summary_path = expected_summary_path(workstream)
    summary_text = _show_at(repo, tip, summary_path)
    allowed = {active_path, archive_path, f"{PACKET_ROOT}/README.md", summary_path}
    scope_error = _branch_scope_error(repo, tip, allowed)
    if scope_error:
        raise RunnerError(scope_error)
    inventory = _worktree_inventory(original)
    intent = _closeout_intent(workstream, run_id, outcome, ids, provenance, tip, reviewed_main, implementation_commit)
    if journal and (journal.get("intent") != intent or journal.get("inventory") != inventory):
        raise RunnerError("recovery journal intent or protected inventory changed since it was prepared")
    recovery_branch = f"recovery/{workstream}-{run_id.rsplit('-', 1)[1]}"
    plan = {"schema": "custodian.paired_review_closeout_plan.v1", "mode": "apply" if apply else "plan",
            "workstream": workstream, "run_id": run_id, "branch": branch, "original_worktree": str(original),
            "published_tip": tip, "reviewed_main": reviewed_main, "implementation_commit": implementation_commit,
            "outcome": outcome, "finding_ids": list(ids), "recovery_branch": recovery_branch,
            "isolated_checkout": str(isolated_checkout), "protected_files": inventory,
            "stage": journal["stage"] if journal else "none", "claim_release_requested": bool(release_claim)}
    if not apply:
        return plan

    stage = journal["stage"] if journal else "none"

    def advance(new_stage: str, **extra) -> None:
        nonlocal journal, stage
        journal = {**(journal or {"schema": JOURNAL_SCHEMA, "intent": intent, "inventory": inventory}),
                   "stage": new_stage, **extra}
        stage = new_stage
        _write_atomic(journal_path, json.dumps(journal, indent=2, sort_keys=True) + "\n")

    if stage == "none":
        advance("prepared")
    checkout = Path(isolated_checkout).resolve()
    if checkout == original:
        raise RunnerError("the isolated recovery checkout must not be the protected original worktree")
    if not checkout.exists():
        git(repo, "worktree", "add", "-b", recovery_branch, str(checkout), f"origin/{branch}")
    if common_dir(checkout) != common or git(checkout, "branch", "--show-current") != recovery_branch:
        raise RunnerError("isolated checkout is not this review's recovery branch in the same repository")
    if subprocess.run(["git", "merge-base", "--is-ancestor", tip, "HEAD"], cwd=checkout,
                      capture_output=True).returncode:
        raise RunnerError("isolated checkout does not descend from the exact published review tip")
    dirty = {line[3:] for line in _changed_paths(checkout, "status", "--porcelain=v1", "--untracked-files=all")}
    if dirty - allowed:
        raise RunnerError("isolated checkout has unexpected changes: " + ", ".join(sorted(dirty - allowed)))

    if CLOSEOUT_STAGES.index(stage) < CLOSEOUT_STAGES.index("outcome_written"):
        archived_file = checkout / archive_path
        if not (archived_file.is_file() and "## Review Outcome" in archived_file.read_text(encoding="utf-8")):
            source = checkout / (active_path if (checkout / active_path).is_file() else archive_path)
            text = source.read_text(encoding="utf-8")
            if "## Review Outcome" in text:
                raise RunnerError("preserved review packet already carries an unjournaled Review Outcome")
            text, replaced = re.subn(r"(?m)^(- Status: )`(?:blocked|ready|in_progress|draft)`", r"\1`complete`", text, count=1)
            if not replaced:
                raise RunnerError("preserved review packet has no closable Status line")
            section = review_outcome.render_review_outcome(
                outcome=outcome, review_workstream=workstream, target_workstream=target_workstream,
                reviewed_main=reviewed_main, implementation_commit=implementation_commit,
                provenance=provenance, run_id=run_id, review_cycle=header.review_cycle, ids=ids)
            archived_file.parent.mkdir(parents=True, exist_ok=True)
            archived_file.write_text(text.rstrip("\n") + "\n\n" + section, encoding="utf-8")
            if source != archived_file:
                source.unlink()
        advance("outcome_written")
    if CLOSEOUT_STAGES.index(stage) < CLOSEOUT_STAGES.index("committed"):
        _stage_bounded(checkout, allowed)
        staged_paths = set(_changed_paths(checkout, "diff", "--cached", "--name-only"))
        if staged_paths - allowed:
            raise RunnerError("recovery staged an unauthorized path")
        if staged_paths:
            committed = subprocess.run(["git", "commit", "-m", "paired review findings closeout"], cwd=checkout,
                                       text=True, capture_output=True)
            if committed.returncode:
                raise RunnerError(redact(committed.stderr or committed.stdout))
        advance("committed", recovery_head=git(checkout, "rev-parse", "HEAD"))

    def verified() -> dict:
        head = git(checkout, "rev-parse", "HEAD")
        scope = _branch_scope_error(checkout, head, allowed)
        if scope:
            raise RunnerError(scope)
        recorded = (journal or {}).get("recovery_head")
        if recorded and subprocess.run(["git", "merge-base", "--is-ancestor", recorded, head], cwd=checkout,
                                       capture_output=True).returncode:
            raise RunnerError("isolated checkout no longer descends from the journaled recovery head")
        state = landed_nonpassing_review_state(
            repo, head, workstream, active_path, target_workstream, target_path,
            target_content, header.authoring_chat, reviewed_main, run_id)
        if not state["complete"]:
            raise RunnerError("recovered closeout failed exact verification: " + "; ".join(state["reasons"]))
        return state

    state = verified()
    _write_atomic(run_dir / "closeout-integrity.json",
                  json.dumps(nonpassing_integrity_report(state["outcome"]), indent=2, sort_keys=True) + "\n")
    if CLOSEOUT_STAGES.index(stage) < CLOSEOUT_STAGES.index("published"):
        git(checkout, "push", "origin", f"HEAD:refs/heads/{branch}")
        advance("published")
    if CLOSEOUT_STAGES.index(stage) < CLOSEOUT_STAGES.index("landed"):
        git(checkout, "fetch", "origin", "main")
        if subprocess.run(["git", "merge-base", "--is-ancestor", "origin/main", "HEAD"], cwd=checkout,
                          capture_output=True).returncode:
            merged = subprocess.run(["git", "merge", "--no-edit", "origin/main"], cwd=checkout, text=True,
                                    capture_output=True)
            if merged.returncode:
                subprocess.run(["git", "merge", "--abort"], cwd=checkout, capture_output=True)
                raise RunnerError("main synchronization conflicted; recovery state preserved: "
                                  + redact(merged.stderr or merged.stdout))
            verified()
        if subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"], cwd=checkout,
                          capture_output=True).returncode:
            lander(checkout)
            git(checkout, "fetch", "origin", "main")
        if subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"], cwd=checkout,
                          capture_output=True).returncode:
            raise RunnerError("landing did not verify as reachable from origin/main; recovery state preserved")
        advance("landed", landed_commit=git(checkout, "rev-parse", "HEAD"))
    if _worktree_inventory(original) != inventory or git(original, "rev-parse", "HEAD") != tip:
        raise RunnerError("the protected original worktree changed during recovery; stopping without release")

    released = _release_claim(repo, branch) if release_claim else not _remote_branch_exists(repo, branch)
    result = {**plan, "mode": "apply", "stage": "complete", "outcome": state["outcome"],
              "landed_commit": journal["landed_commit"], "claim_released": released,
              "claim_release_pending": not released,
              "original_worktree_untouched": True}
    advance("complete", result=result)
    return result


def _recover_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="paired_review_runner.py recover-closeout")
    parser.add_argument("review_workstream")
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--outcome", required=True, choices=review_outcome.NONPASSING)
    parser.add_argument("--finding-ids", required=True, help="comma-separated stable IDs, e.g. R0-01")
    parser.add_argument("--provenance", required=True, choices=review_outcome.PROVENANCE)
    parser.add_argument("--isolated-checkout", type=Path, required=True)
    parser.add_argument("--release-claim", action="store_true")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    try:
        result = recover_closeout(
            Path.cwd(), args.review_workstream, args.run_id, isolated_checkout=args.isolated_checkout,
            outcome=args.outcome, ids=tuple(item.strip() for item in args.finding_ids.split(",")),
            provenance=args.provenance, apply=args.apply, release_claim=args.release_claim)
    except (RunnerError, OSError, subprocess.SubprocessError, ValueError) as exc:
        print(f"paired_review_runner: BLOCKED: {redact(str(exc))}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


def _continuation_metadata(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"continuation state is missing or malformed: {path}") from exc
    if not isinstance(value, dict) or value.get("schema") != CONTINUATION_SCHEMA:
        raise RunnerError(f"continuation state has an unknown schema: {path}")
    return value


def _manifest_digest(manifest: dict[str, str]) -> str:
    return _sha256_bytes(json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode())


def _verify_missing_archived_disposition_parent(run_dir: Path, workstream: str, run_id: str,
                                                original: dict) -> tuple[dict, dict[str, str]]:
    """Verify the sole exact continuation-01 eligible for one continuation-02."""
    if (workstream != MISSING_ARCHIVED_DISPOSITION_WORKSTREAM
            or run_id != MISSING_ARCHIVED_DISPOSITION_RUN_ID):
        raise RunnerError("missing-archived-disposition continuation accepts only its exact protected run")
    parent_dir = run_dir / MISSING_ARCHIVED_DISPOSITION_PARENT
    child_dir = run_dir / MISSING_ARCHIVED_DISPOSITION_CHILD
    if parent_dir.is_symlink() or not parent_dir.is_dir():
        raise RunnerError("exact missing_archived_disposition recovery requires a real preserved continuation-01")
    if child_dir.is_symlink() or (os.path.lexists(child_dir) and not child_dir.is_dir()):
        raise RunnerError("continuation-02 path is unsafe")
    expected_children = [MISSING_ARCHIVED_DISPOSITION_PARENT]
    if child_dir.is_dir():
        expected_children.append(MISSING_ARCHIVED_DISPOSITION_CHILD)
    children = sorted(path.name for path in run_dir.glob("continuation-*")
                      if path.is_dir() or path.is_symlink())
    if children != expected_children:
        raise RunnerError("exact missing_archived_disposition recovery permits only continuation-01 and its one continuation-02")
    parent = _continuation_metadata(parent_dir / "metadata.json")
    if (parent.get("workstream") != workstream or parent.get("run_id") != run_id
            or parent.get("phase") != "missing_archived_disposition"
            or parent.get("exit_code") != 0):
        raise RunnerError("continuation-01 must record exact missing_archived_disposition and reviewer exit_code 0")
    for key in ("branch", "worktree", "active_packet_path", "target_workstream",
                "target_packet_path", "reviewed_main", "implementation_commit"):
        value = parent.get(key)
        if not isinstance(value, str) or not value:
            raise RunnerError(f"continuation-01 omits exact identity field {key}")
    for key in ("branch", "worktree", "packet", "reviewed_main"):
        if original.get(key) != parent.get({"packet": "active_packet_path"}.get(key, key)):
            raise RunnerError(f"continuation-01 {key} differs from the original run identity")
    parent_host = parent.get("host_evidence")
    original_host = original.get("host_validation")
    if (not isinstance(parent_host, dict) or not isinstance(original_host, dict)
            or parent_host.get("report_sha256") != original_host.get("report_sha256")
            or parent_host.get("metadata_sha256") != original_host.get("metadata_sha256")):
        raise RunnerError("continuation-01 host-validation identity differs from the original run")
    recorded_original = parent.get("run_evidence_sha256")
    if not isinstance(recorded_original, dict) or not recorded_original:
        raise RunnerError("continuation-01 lacks the original-run evidence manifest")
    all_run_evidence = _file_manifest(run_dir)
    actual_original = {
        name: digest for name, digest in all_run_evidence.items()
        if not name.startswith(f"{MISSING_ARCHIVED_DISPOSITION_PARENT}/")
        and not name.startswith(f"{MISSING_ARCHIVED_DISPOSITION_CHILD}/")
    }
    if actual_original != recorded_original:
        raise RunnerError("original run evidence does not match the manifest recorded before continuation-01")

    preserved_files = parent.get("preserved_files")
    preserved_manifest = parent_dir / "preserved-files.json"
    if preserved_manifest.is_symlink() or not preserved_manifest.is_file():
        raise RunnerError("continuation-01 preserved-files manifest is missing or unsafe")
    try:
        indexed = json.loads(preserved_manifest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("continuation-01 preserved-files manifest is malformed") from exc
    if not isinstance(preserved_files, list) or indexed != preserved_files:
        raise RunnerError("continuation-01 preserved-files index differs from its metadata")
    for item in preserved_files:
        if (not isinstance(item, dict) or set(item) != {"source", "copy", "sha256"}
                or not isinstance(item.get("copy"), str)
                or not re.fullmatch(r"[0-9a-f]{64}", str(item.get("sha256", "")))):
            raise RunnerError("continuation-01 contains a malformed preserved reviewer artifact")
        copy_path = Path(item["copy"])
        if (copy_path.is_symlink() or not copy_path.is_file()
                or not copy_path.resolve().is_relative_to(parent_dir.resolve())
                or _sha256_bytes(copy_path.read_bytes()) != item["sha256"]):
            raise RunnerError("continuation-01 preserved reviewer artifact failed its recorded hash")
    return parent, _file_manifest(parent_dir)


def _coordinator_checkout_sha(repo: Path) -> str:
    """Require a clean main checkout or detached clean checkout at cached origin/main."""
    if git(repo, "status", "--porcelain", "--untracked-files=all"):
        raise RunnerError("coordinator checkout is dirty; protected review continuation refused")
    head = git(repo, "rev-parse", "--verify", "HEAD^{commit}")
    origin_main = git(repo, "rev-parse", "--verify", "origin/main^{commit}")
    branch = git(repo, "branch", "--show-current")
    if branch not in {"main", ""} or head != origin_main:
        raise RunnerError("continuation requires clean main or detached checkout exactly at origin/main; for a clean behind-only main use: python3 custodian/tools/agent/persistent_checkout_sync.py apply root")
    return origin_main


def _active_packet_cached(repo: Path, workstream: str):
    paths = git(repo, "ls-tree", "-r", "--name-only", "origin/main", PACKET_ROOT).splitlines()
    matches = []
    for path in paths:
        if not path.endswith(".md") or "/archived/" in path:
            continue
        content = read_git_text(repo, "origin/main", path)
        packet = parse_packet(path, content)
        if packet.workstream == workstream:
            matches.append((path, content, packet))
    if len(matches) != 1:
        raise RunnerError(f"expected one active review packet for {workstream}, found {len(matches)}")
    return matches[0]


def _completed_host_continuation(repo: Path, run_dir: Path, workstream: str, run_id: str) -> dict | None:
    """Allow only a byte-verified completed child to use the idempotent plan path."""
    children = sorted(path for path in run_dir.glob("continuation-*") if path.is_dir())
    if not children:
        return None
    if [path.name for path in children] != ["continuation-01"]:
        raise RunnerError("host recovery has duplicate or noncanonical continuation children")
    child_dir = children[0]
    child = _continuation_metadata(child_dir / "metadata.json")
    if (child.get("phase") != "complete" or child.get("run_id") != run_id
            or child.get("workstream") != workstream):
        raise RunnerError("host recovery has an incomplete child; preserve it and inspect its metadata")
    if child.get("run_evidence_sha256") != _file_manifest(run_dir, omit=child_dir):
        raise RunnerError("completed host continuation no longer matches its immutable original evidence")
    for key in ("branch", "worktree", "active_packet_path", "target_workstream", "target_packet_path",
                "reviewed_main", "implementation_commit"):
        if not isinstance(child.get(key), str) or not child[key]:
            raise RunnerError(f"completed host continuation omits exact identity field {key}")
    host_evidence = child.get("host_evidence")
    if not isinstance(host_evidence, dict) or host_evidence.get("continuation_dir") != str(child_dir):
        raise RunnerError("completed host continuation evidence path changed")
    return {"phase": "complete", "metadata_sha256": _sha256_bytes((child_dir / "metadata.json").read_bytes()),
            "manifest_sha256": hashlib.sha256(json.dumps(
                _file_manifest(child_dir), sort_keys=True, separators=(",", ":")).encode()).hexdigest()}


def _failed_import_report_pair(run_dir: Path, original: dict, workstream: str, run_id: str) -> dict | None:
    """Authenticate the one known failed TLS/import validation pair without rewriting it."""
    if (workstream != FAILED_IMPORT_RECOVERY_WORKSTREAM or run_id != FAILED_IMPORT_RECOVERY_RUN_ID
            or isinstance(original.get("host_validation"), dict)):
        return None
    try:
        report_bytes = (run_dir / "validation.json").read_bytes()
        metadata_bytes = (run_dir / "coordinator-validation.json").read_bytes()
        report = json.loads(report_bytes)
        metadata = json.loads(metadata_bytes)
    except (OSError, json.JSONDecodeError):
        return None
    if (not isinstance(report, dict) or not isinstance(metadata, dict)
            or report.get("schema") != "custodian.validation.result.v1"
            or report.get("passed") is not False
            or report.get("infrastructure_failure") != "import"
            or metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != original.get("reviewed_main")
            or metadata.get("implementation_commit") != original.get("implementation_commit")
            or metadata.get("exit_code") != 3
            or metadata.get("source_changed_during_validation") is not True
            or metadata.get("report_path") != str((run_dir / "validation.json").resolve())
            or metadata.get("report_sha256") != _sha256_bytes(report_bytes)
            or metadata.get("report_parse_error") is not None):
        return None
    if metadata.get("code_paths") != [
        "custodian/tools/agent/paired_review_runner.py",
        "custodian/tools/agent/test_paired_review_runner.py",
    ]:
        return None
    return {
        "report_sha256": _sha256_bytes(report_bytes),
        "metadata_sha256": _sha256_bytes(metadata_bytes),
        "report_bytes": len(report_bytes), "metadata_bytes": len(metadata_bytes),
        "exit_code": metadata["exit_code"],
        "infrastructure_failure": report["infrastructure_failure"],
    }


def _failed_import_retry_state(run_dir: Path, worktree: Path, workstream: str,
                               run_id: str, original_manifest: dict[str, str]) -> tuple[dict | None, int]:
    """Verify a previously failed host-only attempt and return the next bounded attempt number."""
    child_dir = run_dir / "continuation-01"
    if not child_dir.exists():
        return None, 1
    if child_dir.is_symlink() or not child_dir.is_dir():
        raise RunnerError("failed-import recovery continuation-01 is unsafe")
    child = _continuation_metadata(child_dir / "metadata.json")
    if (child.get("workstream") != workstream or child.get("run_id") != run_id
            or child.get("phase") != "host_validation_failed"
            or child.get("reviewer_launch_count") != 0
            or child.get("original_run_manifest") != original_manifest
            or child.get("generated_import_recovery") is None):
        raise RunnerError("existing continuation is not an authenticated failed host-only import attempt")
    attempts = child.get("host_validation_attempts")
    if not isinstance(attempts, list) or not 1 <= len(attempts) <= FAILED_IMPORT_RECOVERY_MAX_RETRIES:
        raise RunnerError("failed-import retry attempt journal is malformed or outside its bound")
    for number, attempt in enumerate(attempts, 1):
        if (not isinstance(attempt, dict) or attempt.get("attempt") != number
                or attempt.get("status") != "failed"):
            raise RunnerError("failed-import retry journal contains a nonfailed or out-of-order attempt")
        attempt_dir = child_dir / "host-validation" / f"attempt-{number:02d}"
        if (attempt.get("manifest") != _file_manifest(attempt_dir)
                or attempt.get("manifest_sha256") != _manifest_digest(attempt.get("manifest", {}))):
            raise RunnerError("failed host-validation attempt evidence changed after recording")
        try:
            report = json.loads((attempt_dir / "validation.json").read_text(encoding="utf-8"))
            validation_metadata = json.loads((attempt_dir / "coordinator-validation.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RunnerError("failed host-validation attempt report or provenance is missing or malformed") from exc
        if (not isinstance(report, dict) or report.get("passed") is not False
                or report.get("infrastructure_failure") != "import"
                or not isinstance(validation_metadata, dict)
                or validation_metadata.get("source_changed_during_validation") is not False
                or validation_metadata.get("report_sha256") != _sha256_bytes(
                    (attempt_dir / "validation.json").read_bytes())
                or attempt.get("report_sha256") != validation_metadata.get("report_sha256")
                or attempt.get("metadata_sha256") != _sha256_bytes(
                    (attempt_dir / "coordinator-validation.json").read_bytes())):
            raise RunnerError("bounded retry is allowed only after a recorded import infrastructure failure")
        try:
            host_validation._verify_generated_import_manifest(worktree, attempt_dir, validation_metadata)
        except HostValidationError as exc:
            raise RunnerError("generated import artifact evidence failed retry verification") from exc
    if _file_manifest(run_dir, omit=child_dir) != original_manifest:
        raise RunnerError("original failed validation evidence changed during retry recovery")
    if len(attempts) >= FAILED_IMPORT_RECOVERY_MAX_RETRIES:
        raise RunnerError("bounded host-validation retry budget is exhausted; preserve the exact failure state")
    return child, len(attempts) + 1


def _host_recovery_plan_unlocked(repo: Path, workstream: str, run_id: str, *,
                                 attest_no_active_owner: bool = False,
                                 attest_no_unique_evidence: bool = False) -> dict:
    """Read-only exact-run preflight; caller holds the per-workstream review lock."""
    if attest_no_active_owner != attest_no_unique_evidence:
        raise RunnerError("missing-checkout operator attestations must be supplied together")
    origin_main = _coordinator_checkout_sha(repo)
    remote_main = subprocess.run(["git", "ls-remote", "--heads", "origin", "main"],
                                 cwd=repo, text=True, capture_output=True)
    if remote_main.returncode:
        raise RunnerError("cannot verify current origin/main for host-validation recovery plan")
    remote_main_sha = next((line.split()[0] for line in remote_main.stdout.splitlines()
                            if len(line.split()) == 2 and line.split()[1] == "refs/heads/main"), None)
    if remote_main_sha != origin_main:
        raise RunnerError("cached origin/main is stale; on a clean behind-only coordinator run: python3 custodian/tools/agent/persistent_checkout_sync.py apply root, then re-plan (do not alter the protected review)")

    common = common_dir(repo).resolve()
    expected_root = (common / "custodian-review-runs" / workstream).resolve()
    run_dir = (expected_root / run_id).resolve()
    if run_dir.parent != expected_root or not run_dir.is_dir():
        raise RunnerError("exact original review run directory is absent or outside its canonical location")
    metadata_path = run_dir / "metadata.json"
    try:
        metadata_bytes = metadata_path.read_bytes()
        original = json.loads(metadata_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("original host-validation run metadata is missing or malformed") from exc
    if (not isinstance(original, dict) or original.get("schema") != SCHEMA
            or original.get("run_id") != run_id or original.get("workstream") != workstream
            or original.get("run_dir") != str(run_dir)
            or original.get("phase") != "host_validation_recovery"):
        raise RunnerError("original run is not the exact eligible host_validation_recovery")
    report_paths = [run_dir / "validation.json", run_dir / "coordinator-validation.json"]
    for path in report_paths:
        if path.is_symlink() or (path.exists() and not path.is_file()):
            raise RunnerError(f"original host-validation report is unsafe: {path.name}")
    reports_present = [path.is_file() for path in report_paths]
    if any(reports_present) and not all(reports_present):
        raise RunnerError("original host-validation report pair is incomplete")
    prevalidation_interruption = not any(reports_present)
    if prevalidation_interruption:
        pinned_result_keys = ("host_validation", "validation_evidence_sha256", "host_validation_dir")
        if any(key in original for key in pinned_result_keys):
            raise RunnerError("original metadata claims pinned host-validation evidence but its reports are missing")
        if any(path.exists() or path.is_symlink() for path in run_dir.glob("continuation-*")):
            raise RunnerError("pre-validation recovery already has continuation children; inspect them before planning")
    if not re.fullmatch(r"[0-9a-f]{40,64}", str(original.get("reviewed_main", ""))):
        raise RunnerError("original run omits its exact pinned reviewed-main SHA")
    reviewed_main = git(repo, "rev-parse", "--verify", f"{original['reviewed_main']}^{{commit}}")
    if subprocess.run(["git", "merge-base", "--is-ancestor", reviewed_main, origin_main],
                      cwd=repo, capture_output=True).returncode:
        raise RunnerError("pinned reviewed main is not an ancestor of current origin/main")
    failed_import = _failed_import_report_pair(run_dir, original, workstream, run_id)
    retry_child = None
    retry_number = 1
    failed_import_sidecars = []
    if failed_import:
        if not all(reports_present):
            raise RunnerError("failed-import recovery requires the complete original failed report pair")
        failed_metadata = json.loads((run_dir / "coordinator-validation.json").read_text(encoding="utf-8"))
        worktree_from_metadata = Path(str(original.get("recovery_worktree", ""))).resolve()
        if (worktree_from_metadata.is_dir()
                and (run_dir / "continuation-01").is_dir()):
            existing_manifest = _file_manifest(run_dir, omit=run_dir / "continuation-01")
            retry_child, retry_number = _failed_import_retry_state(
                run_dir, worktree_from_metadata, workstream, run_id, existing_manifest,
            )
            recovery = retry_child["generated_import_recovery"]
            if recovery.get("manifest_path") != "original-generated-imports/manifest.json":
                raise RunnerError("preserved original import-sidecar manifest path is noncanonical")
            manifest_path = run_dir / "continuation-01" / recovery["manifest_path"]
            if (manifest_path.is_symlink() or not manifest_path.is_file()
                    or _sha256_bytes(manifest_path.read_bytes()) != recovery.get("manifest_sha256")):
                raise RunnerError("preserved original import-sidecar manifest changed")
            try:
                preserved_sidecars = json.loads(manifest_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                raise RunnerError("preserved original import-sidecar manifest is malformed") from exc
            if not isinstance(preserved_sidecars, list) or {item.get("sidecar_path") for item in preserved_sidecars} != set(host_validation.FAILED_IMPORT_RECOVERY_SIDECARS):
                raise RunnerError("preserved original import-sidecar inventory is incomplete")
            for item in preserved_sidecars:
                evidence_relative = item.get("evidence_path")
                if (not isinstance(evidence_relative, str)
                        or not evidence_relative.startswith("original-generated-imports/files/")
                        or ".." in Path(evidence_relative).parts):
                    raise RunnerError("preserved original import-sidecar evidence path is noncanonical")
                evidence_path = run_dir / "continuation-01" / evidence_relative
                if not evidence_path.resolve().is_relative_to((run_dir / "continuation-01").resolve()):
                    raise RunnerError("preserved original import-sidecar evidence escapes continuation-01")
                if (evidence_path.is_symlink() or not evidence_path.is_file()
                        or _sha256_bytes(evidence_path.read_bytes()) != item.get("sha256")):
                    raise RunnerError("preserved original import-sidecar bytes changed")
        else:
            tracked_changes = subprocess.run(
                ["git", "status", "--porcelain=v1", "--untracked-files=all"], cwd=worktree_from_metadata,
                text=True, capture_output=True, check=True,
            ).stdout.splitlines() if worktree_from_metadata.is_dir() else []
            allowed = {"?? " + path for path in host_validation.FAILED_IMPORT_RECOVERY_SIDECARS}
            if set(tracked_changes) != allowed:
                raise RunnerError("failed-import recovery worktree has tracked edits or unrelated untracked files")
            code_paths = failed_metadata.get("code_paths")
            source_hashes = failed_metadata.get("source_sha256")
            if (not isinstance(code_paths, list) or not isinstance(source_hashes, dict)
                    or set(code_paths) != set(source_hashes)
                    or code_paths != ["custodian/tools/agent/paired_review_runner.py",
                                      "custodian/tools/agent/test_paired_review_runner.py"]
                    or any(_sha256_bytes(subprocess.run(
                        ["git", "show", f"{reviewed_main}:{path}"], cwd=repo,
                        capture_output=True, check=True,
                    ).stdout) != source_hashes[path] for path in code_paths)):
                raise RunnerError("failed-import code source hashes differ from the pinned reviewed main")
            try:
                failed_import_sidecars = host_validation.verified_failed_import_sidecars(worktree_from_metadata)
            except HostValidationError as exc:
                raise RunnerError(str(exc)) from exc
    completed_child = None if failed_import else _completed_host_continuation(repo, run_dir, workstream, run_id)
    carrow_missing_worktree = (
        workstream == CARROW_MISSING_WORKTREE_WORKSTREAM
        and run_id == CARROW_MISSING_WORKTREE_RUN_ID
        and all(reports_present) and not failed_import and completed_child is None
    )
    if all(reports_present) and not failed_import and completed_child is None and not carrow_missing_worktree:
        raise RunnerError("existing host-validation reports are neither a verified green pin nor the exact failed import pair")
    if completed_child:
        child = _continuation_metadata(run_dir / "continuation-01/metadata.json")
        active_path = str(child["active_packet_path"])
        archived_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
        archived_text = read_git_text(repo, "origin/main", archived_path)
        packet = parse_packet(active_path, archived_text)
        active_content = archived_text
    else:
        active_path, active_content, packet = _active_packet_cached(repo, workstream)
    expected_status = "complete" if completed_child else "ready"
    if (packet.error or packet.kind != "review" or packet.status != expected_status or packet.dispatch != "auto"
            or not packet.review_target_workstream or not packet.review_target_packet
            or (completed_child is None and original.get("packet") is not None
                and original.get("packet") != active_path)
            or (completed_child is not None and (
                packet.workstream != workstream
                or packet.review_target_workstream != child.get("target_workstream")
                or packet.review_target_packet != child.get("target_packet_path")
                or packet.authoring_chat != child.get("authoring_chat")))):
        raise RunnerError("current review packet no longer matches the original exact claim")
    branch = f"agent/{workstream}"
    if original.get("branch") not in (None, branch):
        raise RunnerError("original run branch identity is not the canonical review branch")
    recorded_worktree = original.get("recovery_worktree")
    missing_prevalidation_checkout_candidate = (
        ((prevalidation_interruption and isinstance(recorded_worktree, str) and bool(recorded_worktree))
         and not Path(recorded_worktree).exists() and not Path(recorded_worktree).is_symlink())
        or (workstream == CARROW_MISSING_WORKTREE_WORKSTREAM
            and run_id == CARROW_MISSING_WORKTREE_RUN_ID)
    )
    receipt, receipt_source = _host_validation_claim_receipt(
        run_dir, workstream, repo, original, active_path,
        allow_missing_worktree=missing_prevalidation_checkout_candidate,
    )
    if completed_child:
        receipt_text = CLAIM_SENTINEL + json.dumps(receipt, sort_keys=True)
        sentinels = [line for line in receipt_text.splitlines() if line.startswith(CLAIM_SENTINEL)]
        if len(sentinels) != 1:
            raise RunnerError("completed run's original claim receipt is missing or ambiguous")
        try:
            receipt_value = json.loads(sentinels[0][len(CLAIM_SENTINEL):])
        except json.JSONDecodeError as exc:
            raise RunnerError("completed run's original claim receipt is malformed") from exc
        if (not isinstance(receipt_value, dict) or receipt_value.get("result") != "claimed"
                or receipt_value.get("verified") is not True or receipt_value.get("workstream") != workstream):
            raise RunnerError("completed run's original claim receipt identity is invalid")
        receipt = receipt_value
    worktree = Path(receipt["worktree"]).resolve()
    if carrow_missing_worktree:
        recorded_checkout = Path(str(receipt.get("worktree", ""))).expanduser()
        if str(recorded_checkout) != str(worktree) or recorded_checkout.resolve(strict=False) != recorded_checkout:
            raise RunnerError("Carrow recorded worktree path contains a symlink or noncanonical component")
        if (original.get("reviewed_main") != CARROW_MISSING_WORKTREE_REVIEWED_MAIN
                or original.get("implementation_commit") != CARROW_MISSING_WORKTREE_IMPLEMENTATION
                or receipt.get("branch") != f"agent/{CARROW_MISSING_WORKTREE_WORKSTREAM}"
                or receipt.get("result") != "claimed" or receipt.get("verified") is not True):
            raise RunnerError("Carrow missing-worktree recovery identity differs from the pinned original claim")
        if _file_manifest(run_dir) != CARROW_MISSING_WORKTREE_RUN_MANIFEST:
            raise RunnerError("Carrow original run evidence differs from the exact preserved seven-file manifest")
        validation = json.loads((run_dir / "validation.json").read_text(encoding="utf-8"))
        coordinator = json.loads((run_dir / "coordinator-validation.json").read_text(encoding="utf-8"))
        if (validation.get("passed") is not False
                or coordinator.get("report_sha256") != CARROW_MISSING_WORKTREE_REPORTS["validation.json"]
                or coordinator.get("reviewed_main") != CARROW_MISSING_WORKTREE_REVIEWED_MAIN
                or coordinator.get("implementation_commit") != CARROW_MISSING_WORKTREE_IMPLEMENTATION):
            raise RunnerError("Carrow historical failed report provenance does not match its pinned identity")
        if worktree.exists() or worktree.is_symlink():
            raise RunnerError("recorded Carrow recovery destination is occupied; preserve it for inspection")
        worktree_entries = [block for block in git(repo, "worktree", "list", "--porcelain").split("\n\n") if block.strip()]
        if any(f"worktree {worktree}" in entry.splitlines() for entry in worktree_entries):
            raise RunnerError("recorded Carrow recovery destination still has Git worktree metadata")
        branch_ref = f"branch refs/heads/{receipt['branch']}"
        if any(branch_ref in entry.splitlines() for entry in worktree_entries):
            raise RunnerError("Carrow claim branch is already attached to another worktree")
        if git(repo, "rev-parse", "--verify", f"refs/heads/{receipt['branch']}^{{commit}}") != CARROW_MISSING_WORKTREE_REVIEWED_MAIN:
            raise RunnerError("Carrow local review branch moved from the pinned reviewed main")
        remote_branch = subprocess.run(["git", "ls-remote", "--heads", "origin", receipt["branch"]],
                                       cwd=repo, text=True, capture_output=True)
        if remote_branch.returncode or remote_branch.stdout.split() != [
                CARROW_MISSING_WORKTREE_REVIEWED_MAIN, f"refs/heads/{receipt['branch']}"]:
            raise RunnerError("Carrow remote review branch moved from the pinned reviewed main")
        if git(repo, "rev-list", "--count", f"{CARROW_MISSING_WORKTREE_REVIEWED_MAIN}..refs/heads/{receipt['branch']}") != "0":
            raise RunnerError("Carrow review branch contains unique commits that recovery cannot preserve")
    prevalidation_missing_worktree = (
        prevalidation_interruption and not carrow_missing_worktree
        and not worktree.exists() and not worktree.is_symlink()
    )
    missing_worktree_trace = None
    remote_branch_sha = None
    if prevalidation_missing_worktree:
        if not (attest_no_active_owner and attest_no_unique_evidence):
            raise RunnerError("missing pre-validation checkout requires both explicit operator attestations")
        recorded = Path(str(receipt.get("worktree", ""))).expanduser()
        expected_parent = (repo.parent / ".custodian-worktrees").resolve()
        if (not recorded.is_absolute() or str(recorded) != str(worktree)
                or recorded.resolve(strict=False) != recorded
                or recorded.parent.resolve(strict=False) != expected_parent
                or not expected_parent.is_dir()):
            raise RunnerError("missing pre-validation checkout path is not its canonical managed location")
        if (original.get("recovery_worktree") != str(recorded)
                or original.get("branch") not in (None, receipt["branch"])
                or original.get("worktree") not in (None, str(recorded))
                or original.get("packet") not in (None, active_path)):
            raise RunnerError("missing pre-validation checkout metadata differs from the original claim")
        worktree_entries = [block for block in git(repo, "worktree", "list", "--porcelain").split("\n\n")
                            if block.strip()]
        if any(f"worktree {recorded}" in entry.splitlines() for entry in worktree_entries):
            raise RunnerError("missing pre-validation checkout still has Git worktree metadata")
        branch_ref = f"branch refs/heads/{receipt['branch']}"
        if any(branch_ref in entry.splitlines() for entry in worktree_entries):
            raise RunnerError("missing pre-validation branch is attached to another checkout")
        if git(repo, "rev-parse", "--verify", f"refs/heads/{receipt['branch']}^{{commit}}") != reviewed_main:
            raise RunnerError("missing pre-validation local review branch moved from its pinned baseline")
        remote_branch = subprocess.run(["git", "ls-remote", "--heads", "origin", receipt["branch"]],
                                       cwd=repo, text=True, capture_output=True)
        if remote_branch.returncode:
            raise RunnerError("cannot verify missing pre-validation remote review branch")
        remote_rows = [line.split() for line in remote_branch.stdout.splitlines() if line.split()]
        if remote_rows != [[reviewed_main, f"refs/heads/{receipt['branch']}"]]:
            raise RunnerError("missing pre-validation remote review branch moved from its pinned baseline")
        remote_branch_sha = remote_rows[0][0]
        trace_ref = receipt.get("trace_ref")
        claim_run_id = receipt.get("run_id")
        expected_trace_ref = (f"refs/heads/agent-diagnostics/{workstream}/{claim_run_id}"
                              if isinstance(claim_run_id, str) else "")
        if (not isinstance(trace_ref, str) or trace_ref != expected_trace_ref
                or not re.fullmatch(r"[A-Za-z0-9Tz-]+", str(claim_run_id or ""))):
            raise RunnerError("missing pre-validation claim omits its exact diagnostic trace identity")
        trace_branch = trace_ref.removeprefix("refs/heads/")
        trace_remote = subprocess.run(["git", "ls-remote", "--heads", "origin", trace_branch],
                                      cwd=repo, text=True, capture_output=True)
        if trace_remote.returncode:
            raise RunnerError("cannot verify missing pre-validation diagnostic trace ref")
        trace_rows = [line.split() for line in trace_remote.stdout.splitlines() if line.split()]
        if len(trace_rows) != 1 or trace_rows[0][1] != trace_ref:
            raise RunnerError("missing pre-validation diagnostic trace ref is absent or ambiguous")
        cached_trace = subprocess.run(["git", "rev-parse", "--verify",
                                       f"refs/remotes/origin/{trace_branch}^{{commit}}"],
                                      cwd=repo, text=True, capture_output=True)
        if cached_trace.returncode or cached_trace.stdout.strip() != trace_rows[0][0]:
            raise RunnerError("cached diagnostic trace ref is stale; fetch origin and re-plan")
        trace_result = subprocess.run(["git", "show", f"origin/{trace_branch}:trace.jsonl"],
                                      cwd=repo, capture_output=True)
        if trace_result.returncode:
            raise RunnerError("published missing pre-validation diagnostic trace is unavailable")
        try:
            trace_events = [json.loads(line) for line in trace_result.stdout.decode("utf-8").splitlines()
                            if line.strip()]
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise RunnerError("published missing pre-validation trace is malformed") from exc
        matching_events = [event for event in trace_events
                           if event.get("workstream") == workstream
                           and event.get("run_id") == claim_run_id]
        run_started = [event for event in matching_events if event.get("event") == "run_started"]
        published = [event for event in matching_events if event.get("event") == "worktree_published"]
        started = [event for event in matching_events if event.get("event") == "start_completed"]
        completed = [event for event in matching_events if event.get("event") == "run_completed"]
        if (len(run_started) != 1 or len(published) != 1 or len(started) != 1 or len(completed) != 1
                or any(event.get("schema") != "custodian.workflow_trace_event.v1"
                       or event.get("schema_version") != 1 for event in matching_events)
                or matching_events.index(run_started[0]) > matching_events.index(published[0])
                or matching_events.index(published[0]) > matching_events.index(started[0])
                or matching_events.index(started[0]) > matching_events.index(completed[0])
                or matching_events[-1] is not completed[0]
                or run_started[0].get("data", {}).get("packet") != active_path
                or not isinstance(published[0].get("data"), dict)
                or published[0]["data"].get("worktree") != str(recorded)
                or published[0]["data"].get("branch") != receipt["branch"]
                or published[0]["data"].get("head") != reviewed_main
                or published[0]["data"].get("clean") is not True
                or started[0].get("data", {}).get("worktree") != str(recorded)
                or started[0].get("data", {}).get("branch") != receipt["branch"]
                or completed[0].get("data", {}).get("outcome") != "claimed"):
            raise RunnerError("published trace does not prove one clean original checkout publication")
        if any("reviewer" in str(event.get("event", "")).lower()
               or "continuation" in str(event.get("event", "")).lower()
               for event in matching_events):
            raise RunnerError("missing pre-validation trace records later reviewer or continuation activity")
        process_owners = _processes_owning_review_checkout(recorded, workstream, run_id)
        if process_owners:
            raise RunnerError("an active process still owns the missing review checkout: "
                              + ", ".join(str(item["pid"]) for item in process_owners))
        missing_worktree_trace = {
            "claim_run_id": claim_run_id,
            "trace_ref": trace_ref,
            "trace_commit": trace_rows[0][0],
            "trace_sha256": _sha256_bytes(trace_result.stdout),
            "active_process_owners": [],
            "worktree_admin_entry_absent": True,
            "branch_attachment_absent": True,
        }
    recorded_worktree = original.get("recovery_worktree") if original.get("phase") == "host_validation_recovery" else original.get("worktree")
    if (receipt.get("branch") != branch or receipt.get("packet") != active_path
            or (recorded_worktree is not None and recorded_worktree != str(worktree))
            or (original.get("packet") is not None and original.get("packet") != active_path)
            or (completed_child is not None and (
                child.get("branch") != branch or child.get("worktree") != str(worktree)
                or child.get("reviewed_main") != reviewed_main
                or child.get("implementation_commit") != original.get("implementation_commit")
                or child.get("active_packet_path") != active_path))
            or (completed_child is None and not failed_import and not carrow_missing_worktree
                and not prevalidation_missing_worktree and (
                common_dir(worktree).resolve() != common
                or git(worktree, "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main
                or git(worktree, "status", "--porcelain", "--untracked-files=all")))):
        raise RunnerError("original claim/worktree is foreign, dirty, moved, or differs from its pinned baseline")
    if failed_import:
        if (common_dir(worktree).resolve() != common
                or git(worktree, "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main
                or git(worktree, "diff", "--cached", "--name-only")
                or git(worktree, "diff", "--name-only")):
            raise RunnerError("failed-import recovery worktree has tracked changes or moved from its pinned baseline")
    if completed_child is None:
        remote_branch = subprocess.run(["git", "ls-remote", "--heads", "origin", branch],
                                       cwd=repo, text=True, capture_output=True)
        if remote_branch.returncode:
            raise RunnerError("cannot verify original review branch on origin")
        remote_branch_sha = next((line.split()[0] for line in remote_branch.stdout.splitlines()
                                  if len(line.split()) == 2 and line.split()[1] == f"refs/heads/{branch}"), None)
        if remote_branch_sha != reviewed_main:
            raise RunnerError("published original review branch is missing or moved from pinned main")

    target_path = packet.review_target_packet
    if target_path != f"{PACKET_ROOT}/archived/{Path(target_path).name}":
        raise RunnerError("original review target is not at its canonical archived path")
    target_content = read_git_text(repo, reviewed_main, target_path)
    target = parse_packet(target_path, target_content)
    if (target.error or target.workstream != packet.review_target_workstream
            or target.kind not in {"implementation", "correction"} or target.status != "complete"):
        raise RunnerError("pinned archived implementation target is invalid or incomplete")
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, target_path, packet.review_target_workstream, target_content,
    )
    if identity_error or original.get("implementation_commit") != implementation_commit:
        raise RunnerError("original canonical implementation identity failed verification")
    if carrow_missing_worktree:
        source_span = coordinator.get("source_span")
        try:
            source_span = host_validation.verify_pinned_canonical_commit_source_span(
                repo, implementation_commit, source_span,
            )
        except HostValidationError as exc:
            raise RunnerError("Carrow immutable report source-span provenance failed verification") from exc
    else:
        source_span = host_validation.resolve_validation_source_span(
            repo, reviewed_main, implementation_commit, packet.review_target_workstream, target_path,
        )

    required_evidence = [run_dir / "metadata.json", run_dir / "claim.stdout"]
    if prevalidation_missing_worktree:
        required_evidence.append(run_dir / "claim-receipt.json")
    if not prevalidation_interruption:
        required_evidence = [*report_paths, *required_evidence]
    evidence_hashes = {}
    for path in required_evidence:
        if not path.is_file() or path.is_symlink():
            raise RunnerError(f"original pre-launch evidence is missing or unsafe: {path.name}")
        evidence_hashes[path.name] = _sha256_bytes(path.read_bytes())
    continuation_dirs = sorted(path.name for path in run_dir.glob("continuation-*") if path.is_dir())
    if continuation_dirs and not (failed_import and continuation_dirs == ["continuation-01"] and retry_child):
        raise RunnerError("original run already has continuation children; inspect them before any new attempt")
    manifest = _file_manifest(run_dir)
    plan = {
        "schema": "custodian.paired_review_host_recovery_plan.v1",
        "workstream": workstream, "run_id": run_id, "original_phase": original["phase"],
        "coordinator_main": origin_main, "reviewed_main": reviewed_main,
        "implementation_commit": implementation_commit, "source_span": source_span,
        "branch": branch, "worktree": str(worktree), "packet": active_path,
        "target_workstream": packet.review_target_workstream, "target_packet": target_path,
        "evidence_sha256": evidence_hashes, "continuation_state": completed_child,
        "host_validation_state": ("carrow_failed_nonimport_missing_worktree" if carrow_missing_worktree else
                                  "pre_validation_missing_worktree" if prevalidation_missing_worktree else
                                  "failed_import" if failed_import else
                                  "pre_validation_interrupted" if prevalidation_interruption else "validated"),
        "operator_attestations": {
            "no_active_review_owner": attest_no_active_owner,
            "no_unique_untracked_or_ignored_evidence": attest_no_unique_evidence,
        },
        "requires_fresh_host_validation": prevalidation_interruption or bool(failed_import) or carrow_missing_worktree,
        "failed_validation_evidence": ({
            "kind": "historical_non_import_validation_failure",
            "validation_report_sha256": CARROW_MISSING_WORKTREE_REPORTS["validation.json"],
            "coordinator_report_sha256": CARROW_MISSING_WORKTREE_REPORTS["coordinator-validation.json"],
            "original_outcome_preserved": True,
        } if carrow_missing_worktree else failed_import),
        "generated_import_sidecars": failed_import_sidecars,
        "host_validation_attempt": retry_number,
        "retry_budget": 1 if carrow_missing_worktree else FAILED_IMPORT_RECOVERY_MAX_RETRIES,
        "existing_continuation_manifest": _file_manifest(run_dir / "continuation-01") if retry_child else None,
        "original_run_manifest_sha256":
            hashlib.sha256(json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()).hexdigest(),
        "reviewer_context": "fresh", "will_create_claim": False,
        "will_modify_original_run_files": False,
    }
    if prevalidation_missing_worktree:
        evidence_hashes["claim-receipt.json"] = _sha256_bytes((run_dir / "claim-receipt.json").read_bytes())
        plan.update({
            "trace_ref": missing_worktree_trace["trace_ref"],
            "trace_commit": missing_worktree_trace["trace_commit"],
            "trace_sha256": missing_worktree_trace["trace_sha256"],
            "remote_branch_sha": remote_branch_sha,
            "missing_checkout_proof": missing_worktree_trace,
            "worktree_reconstruction": {
                "mode": "exact_claimed_checkout", "destination": str(worktree),
                "branch": receipt["branch"], "head": reviewed_main,
                "journal": "continuation-01/worktree-recovery.jsonl",
            },
        })
    encoded = json.dumps(plan, sort_keys=True, separators=(",", ":")).encode()
    plan["plan_sha256"] = hashlib.sha256(encoded).hexdigest()
    return plan


def plan_host_validation_recovery(repo: Path, workstream: str, run_id: str, *,
                                  attest_no_active_owner: bool = False,
                                  attest_no_unique_evidence: bool = False) -> dict:
    if not ID_RE.fullmatch(workstream) or not _RUN_ID_RE.fullmatch(run_id):
        raise RunnerError("plan requires an exact review workstream and shaped run ID")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    common = common_dir(repo).resolve()
    lock_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    if not lock_path.is_file():
        raise RunnerError("original paired-review supervisor lock is missing; cannot establish exclusive plan")
    with lock_path.open("rb") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError("another local process is supervising the original review") from exc
        if attest_no_active_owner and attest_no_unique_evidence:
            return _host_recovery_plan_unlocked(
                repo, workstream, run_id,
                attest_no_active_owner=True, attest_no_unique_evidence=True,
            )
        if attest_no_active_owner != attest_no_unique_evidence:
            raise RunnerError("missing-checkout recovery attestations must be supplied together")
        return _host_recovery_plan_unlocked(repo, workstream, run_id)


def _continuation_worktree(repo: Path, child: dict) -> Path:
    """Resolve only the exact recorded worktree for coordinator recovery."""
    path = Path(str(child.get("worktree", ""))).resolve()
    if path.is_dir():
        if common_dir(path).resolve() != common_dir(repo).resolve():
            raise RunnerError("continuation worktree is attached to another Git common directory")
        if git(path, "branch", "--show-current") != child.get("branch"):
            raise RunnerError("continuation worktree is no longer on its exact claimed branch")
        return path
    branch = str(child.get("branch", ""))
    if not re.fullmatch(r"agent/[a-z0-9][a-z0-9-]*", branch):
        raise RunnerError("continuation omits its exact stable review branch")
    exists = subprocess.run(["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
                            cwd=repo).returncode == 0
    if not exists:
        raise RunnerError("continuation worktree is gone and its exact review branch is absent")
    return repo


def _verify_run_evidence(run_dir: Path, expected: dict[str, str], continuation_dir: Path) -> None:
    actual = _file_manifest(run_dir, omit=continuation_dir)
    if actual != expected:
        raise RunnerError("original paired-review run evidence changed during continuation")


def _legacy_claim_receipt(stdout: str, workstream: str, repo: Path, metadata: dict, *,
                          expected_identity: dict[str, str] | None = None) -> dict:
    """Verify a complete historical identity header against independently pinned identity."""
    expected = expected_identity or {
        "workstream": workstream,
        "branch": str(metadata.get("branch", "")),
        "worktree": str(metadata.get("worktree", "")),
        "packet": str(metadata.get("packet", "")),
    }
    if set(expected) != {"workstream", "branch", "worktree", "packet"}:
        raise RunnerError("legacy claim identity is incomplete")
    if stdout.count("CLAIMED\n") != 1:
        raise RunnerError("truncated claim receipt has no unique CLAIMED header")
    observed: dict[str, str] = {}
    for field in expected:
        values = re.findall(rf"(?m)^{re.escape(field)}:[ \t]*(.+?)[ \t]*$", stdout)
        if len(values) != 1:
            raise RunnerError(f"truncated claim header omits or repeats {field}")
        observed[field] = values[0]
    if any(not value for value in expected.values()) or observed != expected:
        raise RunnerError("truncated claim header disagrees with exact original run metadata")
    receipt = {"schema": "custodian.dispatch.claim.v1", "result": "claimed",
               "workstream": workstream, "verified": True,
               "branch": observed["branch"], "worktree": observed["worktree"],
               "packet": observed["packet"]}
    return parse_claim_receipt(CLAIM_SENTINEL + json.dumps(receipt, sort_keys=True), workstream, repo)


def _host_validation_claim_receipt(run_dir: Path, workstream: str, repo: Path, metadata: dict,
                                   packet: str, *,
                                   allow_missing_worktree: bool = False) -> tuple[dict, str]:
    """Resolve structured or specifically truncated legacy claim evidence without writing it."""
    branch = f"agent/{workstream}"
    recorded_worktree = metadata.get("recovery_worktree")
    if not isinstance(recorded_worktree, str) or not recorded_worktree:
        raise RunnerError("legacy host-validation claim omits its recorded recovery worktree")
    if allow_missing_worktree and not (claim_file := run_dir / "claim-receipt.json").is_file():
        raise RunnerError("missing-checkout recovery requires the original structured claim receipt")
    expected = {"workstream": workstream, "branch": branch,
                "worktree": str(Path(recorded_worktree).resolve()), "packet": packet}
    for name, value in (("branch", branch), ("worktree", expected["worktree"]), ("packet", packet)):
        recorded = metadata.get(name)
        if recorded is not None:
            normalized = str(Path(recorded).resolve()) if name == "worktree" else str(recorded)
            if normalized != value:
                raise RunnerError(f"original run metadata {name} conflicts with canonical claim identity")

    claim_file = run_dir / "claim-receipt.json"
    if claim_file.is_file():
        try:
            value = json.loads(claim_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RunnerError("structured original claim receipt is malformed") from exc
        receipt = parse_claim_receipt(CLAIM_SENTINEL + json.dumps(value, sort_keys=True), workstream, repo,
                                      allow_missing_worktree=allow_missing_worktree)
        source = "claim-receipt.json"
    else:
        try:
            stdout = (run_dir / "claim.stdout").read_text(encoding="utf-8")
        except OSError as exc:
            raise RunnerError("original dispatcher claim output is missing") from exc
        sentinels = [line for line in stdout.splitlines() if line.startswith(CLAIM_SENTINEL)]
        if len(sentinels) > 1:
            raise RunnerError("original claim output contains conflicting structured receipts")
        if sentinels:
            payload = sentinels[0][len(CLAIM_SENTINEL):]
            try:
                json.loads(payload)
            except json.JSONDecodeError as exc:
                if not _claim_json_was_truncated(payload, exc):
                    raise RunnerError("original claim receipt is malformed rather than truncated") from exc
                receipt = _legacy_claim_receipt(stdout, workstream, repo, metadata,
                                                expected_identity=expected)
                source = "verified-truncated-claim.stdout-header"
            else:
                # A parseable receipt is authoritative and cannot fall back on a disagreeing header.
                receipt = parse_claim_receipt(stdout, workstream, repo,
                                              allow_missing_worktree=allow_missing_worktree)
                source = "claim.stdout"
        else:
            # Historical dispatcher output was cut off before its sentinel. An unterminated capture
            # is required in addition to the complete, unique identity header and live Git checks.
            if not stdout or stdout.endswith(("\n", "\r")):
                raise RunnerError("original structured claim receipt is missing or ambiguous")
            receipt = _legacy_claim_receipt(stdout, workstream, repo, metadata,
                                           expected_identity=expected)
            source = "verified-truncated-claim.stdout-header"

    if any(receipt.get(field) != value for field, value in expected.items()):
        raise RunnerError("original dispatcher receipt differs from canonical claim identity")
    return receipt, source


def _processes_owning_review_checkout(worktree: Path, workstream: str, run_id: str) -> list[dict[str, object]]:
    """Find same-user processes that still reference an exact lost reviewer checkout."""
    proc_root = Path("/proc")
    if not proc_root.is_dir():
        raise RunnerError("host process ownership cannot be verified on this platform")
    excluded = {os.getpid()}
    parent = os.getppid()
    while parent > 1 and parent not in excluded:
        excluded.add(parent)
        try:
            fields = (proc_root / str(parent) / "stat").read_text().rsplit(")", 1)[1].split()
            parent = int(fields[1])
        except (OSError, ValueError, IndexError):
            break
    expected = str(worktree)
    owners = []
    for entry in proc_root.iterdir():
        if not entry.name.isdigit() or int(entry.name) in excluded:
            continue
        try:
            if entry.stat().st_uid != os.getuid():
                continue
            process_name = (entry / "comm").read_text().strip()
            if process_name in {"systemd", "(sd-pam)", "ssh-agent"}:
                continue
            command = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "replace")
            cwd = os.readlink(entry / "cwd").removesuffix(" (deleted)")
        except FileNotFoundError:
            continue
        except PermissionError as exc:
            raise RunnerError(f"cannot inspect same-user process {entry.name} for review ownership") from exc
        if cwd == expected or expected in command:
            owners.append({"pid": int(entry.name), "cwd_match": cwd == expected,
                           "command_path_match": expected in command})
            continue
        command_lower = command.lower()
        if ((workstream in command or run_id in command)
                and any(token in command_lower for token in ("codex", "paired_review_runner", "workstream.py"))):
            owners.append({"pid": int(entry.name), "identity_command_match": True})
    return owners


def _claim_json_was_truncated(payload: str, error: json.JSONDecodeError) -> bool:
    trimmed = payload.rstrip()
    return (trimmed.startswith("{") and not trimmed.endswith("}")
            and error.pos >= max(0, len(trimmed) - 1))


def _host_evidence_for_continuation(repo: Path, worktree: Path, run_dir: Path, metadata: dict,
                                    reviewed_main: str, implementation_commit: str,
                                    target_workstream: str, target_packet_path: str) -> dict:
    pinned = metadata.get("host_validation")
    if not isinstance(pinned, dict):
        raise RunnerError("original run has no pinned coordinator host-validation evidence; refusing continuation")
    report_path = (run_dir / "validation.json").resolve()
    metadata_path = (run_dir / "coordinator-validation.json").resolve()
    if (Path(str(pinned.get("report_path", ""))).resolve() != report_path
            or not re.fullmatch(r"[0-9a-f]{64}", str(pinned.get("report_sha256", "")))
            or not re.fullmatch(r"[0-9a-f]{64}", str(pinned.get("metadata_sha256", "")))):
        raise RunnerError("original run's coordinator validation paths or digests are incomplete")
    try:
        validation_metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("original run's coordinator validation provenance is missing or malformed") from exc
    if not isinstance(validation_metadata, dict):
        raise RunnerError("original coordinator validation provenance must be a JSON object")
    if (validation_metadata.get("worktree") != str(worktree)
            or validation_metadata.get("reviewed_main") != reviewed_main
            or validation_metadata.get("implementation_commit") != implementation_commit):
        raise RunnerError("coordinator validation provenance belongs to a different checkout or pinned target")
    host_evidence = {
        "implementation_commit": implementation_commit,
        "report_sha256": pinned["report_sha256"],
        "metadata_sha256": pinned["metadata_sha256"],
        "evidence_run_dir": str(run_dir),
    }
    try:
        verify_coordinator_validation(
            repo=worktree, run_dir=run_dir, reviewed_main=reviewed_main,
            implementation_commit=implementation_commit,
            target_workstream=target_workstream, target_packet_path=target_packet_path,
            expected_report_sha256=host_evidence["report_sha256"],
            expected_metadata_sha256=host_evidence["metadata_sha256"],
        )
    except HostValidationError as exc:
        raise RunnerError(f"pinned coordinator validation evidence failed verification: {exc}") from exc
    return host_evidence


def _verify_host_validation_at_commit(repo: Path, run_dir: Path, reviewed_main: str,
                                      implementation_commit: str, host_evidence: dict, *,
                                      target_workstream: str, target_packet_path: str) -> None:
    """Verify pinned host evidence after the original review worktree was torn down."""
    report_path = run_dir / "validation.json"
    metadata_path = run_dir / "coordinator-validation.json"
    try:
        report_bytes = report_path.read_bytes()
        metadata_bytes = metadata_path.read_bytes()
        report = json.loads(report_bytes)
        metadata = json.loads(metadata_bytes)
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"completed continuation host evidence is missing or malformed: {exc}") from exc
    if not isinstance(report, dict) or not isinstance(metadata, dict):
        raise RunnerError("completed continuation validation report/provenance must be JSON objects")
    if (_sha256_bytes(report_bytes) != host_evidence.get("report_sha256")
            or _sha256_bytes(metadata_bytes) != host_evidence.get("metadata_sha256")):
        raise RunnerError("completed continuation host-evidence digests changed")
    if (metadata.get("schema") != "custodian.paired_review_host_validation.v1"
            or metadata.get("reviewed_main") != reviewed_main
            or metadata.get("implementation_commit") != implementation_commit
            or metadata.get("report_sha256") != host_evidence.get("report_sha256")
            or metadata.get("source_changed_during_validation") is not False):
        raise RunnerError("completed continuation host-validation provenance has the wrong identity")
    expected_span = host_validation.resolve_validation_source_span(
        repo, reviewed_main, implementation_commit, target_workstream, target_packet_path,
    )
    if (metadata.get("source_span") != expected_span
            or metadata.get("source_span_base") != expected_span.get("base")
            or metadata.get("source_span_head") != expected_span.get("head")
            or metadata.get("implementation_paths") != expected_span.get("paths")):
        raise RunnerError("completed continuation source-span provenance changed")
    try:
        _validate_report(report, expected_span.get("paths") or [])
    except HostValidationError as exc:
        raise RunnerError(f"completed continuation report is not canonical and green: {exc}") from exc
    source_hashes = metadata.get("source_sha256")
    code_paths = metadata.get("code_paths")
    if not isinstance(source_hashes, dict) or not isinstance(code_paths, list) or set(source_hashes) != set(code_paths):
        raise RunnerError("completed continuation source-hash inventory is incomplete")
    for relative, expected_hash in source_hashes.items():
        try:
            raw = subprocess.run(["git", "show", f"{reviewed_main}:{relative}"], cwd=repo,
                                 capture_output=True, check=True).stdout
        except subprocess.CalledProcessError as exc:
            raise RunnerError(f"pinned validation source is absent from reviewed main: {relative}") from exc
        if _sha256_bytes(raw) != expected_hash:
            raise RunnerError(f"pinned validation source hash changed: {relative}")


def _worktree_review_artifacts(worktree: Path, workstream: str, target_workstream: str,
                               active_packet_path: str, target_packet_path: str) -> list[Path]:
    candidates = {worktree / active_packet_path, worktree / target_packet_path}
    canonical = worktree / expected_summary_path(workstream)
    candidates.add(canonical)
    tokens = {workstream.upper().replace("-", "_"), target_workstream.upper().replace("-", "_")}
    for path in worktree.glob("*_SUMMARY.md"):
        if any(token in path.name for token in tokens):
            candidates.add(path)
    return sorted((path for path in candidates if path.is_file()), key=str)


def _reviewer_dirty_surface(worktree: Path, active_packet_path: str,
                            summary_paths: set[str], *, allowed_untracked: set[str] | None = None) -> tuple[list[str], list[str]]:
    cached = _changed_paths(worktree, "diff", "--cached", "--name-only")
    if cached:
        raise RunnerError("protected review worktree has staged changes; refusing continuation")
    changed = _changed_paths(worktree, "diff", "--name-only")
    untracked = _changed_paths(worktree, "ls-files", "--others", "--exclude-standard")
    # The pinned target packet is read-only in reviewer-owned work. A prior
    # uncommitted receipt is contradictory evidence and must be reconciled first.
    allowed_tracked = {active_packet_path, *summary_paths}
    unexpected_tracked = sorted(set(changed) - allowed_tracked)
    if unexpected_tracked:
        raise RunnerError("protected review worktree has unrelated tracked changes: "
                          + ", ".join(unexpected_tracked))
    allowed_untracked = allowed_untracked or set()
    unexpected_untracked = sorted(path for path in untracked
                                  if path not in summary_paths
                                  and path not in allowed_untracked
                                  and not (path.startswith("custodian/tools/validation/")
                                           and path.endswith(".gd.uid")))
    if unexpected_untracked:
        raise RunnerError("protected review worktree has unclassified untracked files: "
                          + ", ".join(unexpected_untracked))
    return changed, untracked


def _verify_continuation_completion(repo: Path, run_dir: Path, continuation_dir: Path,
                                    child: dict) -> dict:
    workstream = child.get("workstream")
    target_workstream = child.get("target_workstream")
    target_path = child.get("target_packet_path")
    active_path = child.get("active_packet_path")
    reviewed_main = child.get("reviewed_main")
    run_id = child.get("run_id")
    if (not all(isinstance(item, str) and item for item in
                (workstream, target_workstream, target_path, active_path, reviewed_main, run_id))
            or not _RUN_ID_RE.fullmatch(run_id)):
        raise RunnerError("completed continuation state omits its exact review identity")
    if child.get("run_evidence_sha256") != _file_manifest(run_dir, omit=continuation_dir):
        raise RunnerError("original paired-review evidence no longer matches its continuation receipt")
    reviewed_main = git(repo, "rev-parse", "--verify", f"{reviewed_main}^{{commit}}")
    target_content = read_git_text(repo, reviewed_main, target_path)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, reviewed_main, target_path, target_workstream, target_content,
    )
    if identity_error:
        raise RunnerError("completed continuation target identity failed verification: " + identity_error)
    host_evidence = child.get("host_evidence") or {}
    evidence_dir = Path(str(host_evidence.get("evidence_run_dir", run_dir))).resolve()
    host_metadata = json.loads((evidence_dir / "coordinator-validation.json").read_text(encoding="utf-8"))
    if host_metadata.get("implementation_commit") != implementation_commit:
        raise RunnerError("completed continuation validation names another implementation commit")
    _verify_host_validation_at_commit(
        repo, evidence_dir, reviewed_main, implementation_commit, host_evidence,
        target_workstream=target_workstream, target_packet_path=target_path,
    )
    revision = fetch_and_pin_main(repo)
    state = landed_review_state(
        repo, revision, workstream, active_path, target_workstream, target_path,
        target_content, child.get("authoring_chat"), reviewed_main,
    )
    if not state["complete"]:
        raise RunnerError("completed continuation has no independently verified landed pass: "
                          + "; ".join(state["reasons"]))
    archived_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
    archived_text = read_git_text(repo, revision, archived_path)
    outcome, outcome_error = review_outcome.parse_review_outcome(archived_text)
    if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
        raise RunnerError("landed continuation lacks one canonical independent passed outcome")
    outcome_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=workstream, target_workstream=target_workstream,
        reviewed_main=reviewed_main, implementation_commit=implementation_commit,
        run_id=run_id, review_cycle=child.get("review_cycle"),
    )
    if outcome_error:
        raise RunnerError("landed continuation outcome identity failed verification: " + outcome_error)
    return state


def _recover_exact_invalid_disposition(repo: Path, run_dir: Path, continuation_dir: Path,
                                       original: dict, child: dict) -> dict:
    """Verify and repair only the one authorized reviewer disposition and missing receipt."""
    if (child.get("workstream") != INVALID_DISPOSITION_WORKSTREAM
            or child.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or child.get("phase") != "invalid_reviewer_disposition"
            or child.get("disposition_error") != "Review Outcome contains non-canonical content"
            or child.get("active_packet_path") != INVALID_DISPOSITION_ACTIVE_PACKET
            or child.get("target_workstream") != INVALID_DISPOSITION_TARGET
            or child.get("target_packet_path") != INVALID_DISPOSITION_TARGET_PACKET
            or child.get("reviewed_main") != INVALID_DISPOSITION_IMPLEMENTATION
            or child.get("implementation_commit") != INVALID_DISPOSITION_IMPLEMENTATION
            or child.get("review_cycle") != 0
            or continuation_dir.name != INVALID_DISPOSITION_CONTINUATION):
        raise RunnerError("invalid-disposition recovery is limited to the exact held run and phase")
    child_paths = [path for path in run_dir.glob("continuation-*") if path.exists() or path.is_symlink()]
    if child_paths != [continuation_dir] or continuation_dir.is_symlink() or not continuation_dir.is_dir():
        raise RunnerError("invalid-disposition recovery requires the sole preserved continuation-01 child")
    if (original.get("schema") != SCHEMA or original.get("workstream") != INVALID_DISPOSITION_WORKSTREAM
            or original.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or original.get("phase") != "post_exit_recovery"
            or original.get("run_dir") != str(run_dir)
            or original.get("reviewed_main") != INVALID_DISPOSITION_IMPLEMENTATION):
        raise RunnerError("original run identity or phase differs from the authorized held review")
    original_manifest = _file_manifest(run_dir, omit=continuation_dir)
    if child.get("run_evidence_sha256") != original_manifest:
        raise RunnerError("original run evidence manifest changed; invalid-disposition recovery refused")

    recovery_dir = continuation_dir / "recovery-evidence"
    preserved_path = recovery_dir / "original-malformed-review-disposition.md"
    preservation_meta_path = recovery_dir / "original-malformed-review-disposition.json"
    if recovery_dir.is_symlink() or preserved_path.is_symlink() or preservation_meta_path.is_symlink():
        raise RunnerError("original disposition preservation paths contain a symlink")
    try:
        preserved = preserved_path.read_bytes()
        preservation = json.loads(preservation_meta_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("original malformed disposition preservation evidence is missing or malformed") from exc
    if (not isinstance(preservation, dict)
            or preservation.get("schema") != "custodian.paired_review_invalid_disposition_preservation.v1"
            or preservation.get("run_id") != INVALID_DISPOSITION_RUN_ID
            or preservation.get("workstream") != INVALID_DISPOSITION_WORKSTREAM
            or preservation.get("repair_applied") is not False
            or preservation.get("preserved_path") != str(preserved_path)
            or preservation.get("source_path") != str(Path(child.get("worktree", "")) / INVALID_DISPOSITION_REVIEW_PACKET)
            or preservation.get("sha256") != INVALID_DISPOSITION_SHA256
            or preservation.get("size_bytes") != len(preserved)
            or _sha256_bytes(preserved) != INVALID_DISPOSITION_SHA256):
        raise RunnerError("captured malformed disposition or its preservation checksum changed")
    unexpected_recovery_files = {
        path.name for path in recovery_dir.iterdir()
    } - {preserved_path.name, preservation_meta_path.name, "recovery-applied.json"}
    if unexpected_recovery_files:
        raise RunnerError("unexpected recovery evidence already exists: "
                          + ", ".join(sorted(unexpected_recovery_files)))
    preserved_files = child.get("preserved_files")
    if not isinstance(preserved_files, list):
        raise RunnerError("continuation omits its preserved reviewer-evidence inventory")
    for record in preserved_files:
        if not isinstance(record, dict) or not isinstance(record.get("copy"), str):
            raise RunnerError("continuation has a malformed preserved reviewer-evidence record")
        copy_path = Path(record["copy"])
        if (not copy_path.resolve().is_relative_to(continuation_dir.resolve())
                or not copy_path.is_file() or copy_path.is_symlink()
                or _sha256_bytes(copy_path.read_bytes()) != record.get("sha256")):
            raise RunnerError("a preserved reviewer-authored evidence copy changed")

    receipt_file = run_dir / "claim-receipt.json"
    try:
        claim_value = json.loads(receipt_file.read_text(encoding="utf-8"))
        claim_stdout = (run_dir / "claim.stdout").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError("original structured claim evidence is missing or malformed") from exc
    claim = parse_claim_receipt(CLAIM_SENTINEL + json.dumps(claim_value, sort_keys=True),
                                INVALID_DISPOSITION_WORKSTREAM, repo)
    stdout_claim = parse_claim_receipt(claim_stdout, INVALID_DISPOSITION_WORKSTREAM, repo)
    worktree = Path(claim["worktree"]).resolve()
    expected_branch = f"agent/{INVALID_DISPOSITION_WORKSTREAM}"
    expected_claim = {
        "workstream": INVALID_DISPOSITION_WORKSTREAM, "branch": expected_branch,
        "worktree": str(worktree), "packet": INVALID_DISPOSITION_ACTIVE_PACKET,
    }
    if (any(claim.get(key) != value or stdout_claim.get(key) != value for key, value in expected_claim.items())
            or original.get("branch") != expected_branch or original.get("worktree") != str(worktree)
            or original.get("packet") != expected_claim["packet"]
            or child.get("branch") != expected_branch or child.get("worktree") != str(worktree)
            or common_dir(worktree).resolve() != common_dir(repo).resolve()
            or not worktree.is_dir() or git(worktree, "branch", "--show-current") != expected_branch
            or git(worktree, "rev-parse", "--verify", "HEAD^{commit}") != INVALID_DISPOSITION_IMPLEMENTATION):
        raise RunnerError("original claim, run, worktree, branch, or packet identity does not match")
    if stdout_claim != claim:
        raise RunnerError("claim stdout and structured claim receipt disagree")
    git(repo, "fetch", "origin", expected_branch)
    if git(repo, "rev-parse", "--verify", f"refs/remotes/origin/{expected_branch}^{{commit}}") != INVALID_DISPOSITION_IMPLEMENTATION:
        raise RunnerError("published held review branch moved from its original pinned base")

    allowed_paths = {
        INVALID_DISPOSITION_ACTIVE_PACKET,
        INVALID_DISPOSITION_REVIEW_PACKET, INVALID_DISPOSITION_TARGET_PACKET,
        f"{PACKET_ROOT}/README.md", expected_summary_path(INVALID_DISPOSITION_WORKSTREAM),
    }
    changed_paths = set(_changed_paths(worktree, "diff", "--name-only", "HEAD"))
    changed_paths.update(_changed_paths(worktree, "ls-files", "--others", "--exclude-standard"))
    unexpected = sorted(changed_paths - allowed_paths)
    if unexpected:
        raise RunnerError("held review worktree has changes outside its bounded review evidence: "
                          + ", ".join(unexpected))

    archived_path = worktree / INVALID_DISPOSITION_REVIEW_PACKET
    target_path = worktree / INVALID_DISPOSITION_TARGET_PACKET
    try:
        current_disposition = archived_path.read_bytes()
        current_target = target_path.read_bytes()
        last_message = (continuation_dir / "last-message.txt").read_text(encoding="utf-8")
        summary_path = worktree / expected_summary_path(INVALID_DISPOSITION_WORKSTREAM)
        reviewer_summary = summary_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise RunnerError("reviewer-authored disposition, summary, or target evidence is missing") from exc
    if ("review outcome: passed" not in last_message.casefold()
            or INVALID_DISPOSITION_RUN_ID not in last_message
            or "same-agent-fresh-context" not in last_message
            or "Review outcome: passed" not in reviewer_summary
            or INVALID_DISPOSITION_RUN_ID not in reviewer_summary
            or f"Authoring chat: {child.get('authoring_chat')}" not in reviewer_summary):
        raise RunnerError("reviewer's recorded summary does not independently support the pinned PASS")

    repaired_disposition, outcome = _repair_invalid_disposition(preserved)
    reviewer_receipt = _independent_review_receipt(current_disposition.decode("utf-8", errors="strict"))
    if reviewer_receipt is None:
        raise RunnerError("reviewer-authored independent PASS receipt is absent or ambiguous")
    if (reviewer_receipt.get("Review workstream") != outcome["Review workstream"]
            or reviewer_receipt.get("Review target workstream") != outcome["Review target workstream"]
            or reviewer_receipt.get("Status") != "passed"
            or reviewer_receipt.get("Blocking defects") != "0"
            or reviewer_receipt.get("Material gaps") != "0"
            or reviewer_receipt.get("Reviewer context") != "fresh"
            or reviewer_receipt.get("Reviewer provenance") != outcome["Reviewer provenance"]
            or reviewer_receipt.get("Reviewed main") != outcome["Reviewed main"]
            or reviewer_receipt.get("Reviewed implementation commit") != outcome["Reviewed implementation commit"]):
        raise RunnerError("reviewer-authored target receipt contradicts the canonical PASS disposition")
    archived_packet = parse_packet(INVALID_DISPOSITION_REVIEW_PACKET, current_disposition.decode("utf-8"))
    if (archived_packet.error or archived_packet.workstream != INVALID_DISPOSITION_WORKSTREAM
            or archived_packet.kind != "review"
            or archived_packet.review_target_workstream != INVALID_DISPOSITION_TARGET
            or archived_packet.review_target_packet != INVALID_DISPOSITION_TARGET_PACKET
            or archived_packet.authoring_chat != child.get("authoring_chat")
            or str(archived_packet.review_cycle) != outcome["Review cycle"]):
        raise RunnerError("reviewer-authored archived packet identity contradicts the exact run")
    outcome_error = review_outcome.outcome_identity_error(
        outcome, review_workstream=INVALID_DISPOSITION_WORKSTREAM,
        target_workstream=INVALID_DISPOSITION_TARGET,
        reviewed_main=INVALID_DISPOSITION_IMPLEMENTATION,
        implementation_commit=INVALID_DISPOSITION_IMPLEMENTATION,
        run_id=INVALID_DISPOSITION_RUN_ID, review_cycle=archived_packet.review_cycle,
    )
    if outcome_error:
        raise RunnerError("canonical PASS identity failed verification: " + outcome_error)

    baseline = read_git_text(repo, INVALID_DISPOSITION_IMPLEMENTATION, INVALID_DISPOSITION_TARGET_PACKET)
    implementation_commit, identity_error = resolve_target_implementation_commit(
        repo, INVALID_DISPOSITION_IMPLEMENTATION, INVALID_DISPOSITION_TARGET_PACKET,
        INVALID_DISPOSITION_TARGET, baseline,
    )
    if identity_error or implementation_commit != INVALID_DISPOSITION_IMPLEMENTATION:
        raise RunnerError("pinned archived implementation identity failed verification")
    receipt_candidate = _append_verified_invalid_disposition_receipt(baseline, reviewer_receipt)
    if current_target not in {baseline.encode("utf-8"), receipt_candidate}:
        raise RunnerError("reviewed target contains changes beyond the exact missing-receipt correction")
    if current_disposition not in {preserved, repaired_disposition}:
        raise RunnerError("review disposition differs from both preserved and exact repaired bytes")
    if current_target != baseline.encode("utf-8") and current_target != receipt_candidate:
        raise RunnerError("reviewed target receipt recovery is ambiguous")

    original_metadata = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
    host_evidence = _host_evidence_for_continuation(
        repo, worktree, run_dir, original_metadata, INVALID_DISPOSITION_IMPLEMENTATION,
        INVALID_DISPOSITION_IMPLEMENTATION, INVALID_DISPOSITION_TARGET,
        INVALID_DISPOSITION_TARGET_PACKET,
    )
    host_metadata = json.loads((run_dir / "coordinator-validation.json").read_text(encoding="utf-8"))
    if (original_metadata.get("host_validation", {}).get("report_sha256") != host_evidence["report_sha256"]
            or original_metadata.get("host_validation", {}).get("metadata_sha256") != host_evidence["metadata_sha256"]
            or host_metadata.get("implementation_commit") != INVALID_DISPOSITION_IMPLEMENTATION):
        raise RunnerError("green host validation is not pinned to the exact reviewed implementation")

    handoff = recovery_dir / "recovery-applied.json"
    recovery = {
        "schema": "custodian.paired_review_invalid_disposition_recovery.v1",
        "workstream": INVALID_DISPOSITION_WORKSTREAM,
        "run_id": INVALID_DISPOSITION_RUN_ID,
        "continuation": INVALID_DISPOSITION_CONTINUATION,
        "original_disposition_sha256": INVALID_DISPOSITION_SHA256,
        "repaired_disposition_sha256": _sha256_bytes(repaired_disposition),
        "target_baseline_sha256": _sha256_bytes(baseline.encode("utf-8")),
        "target_receipt_sha256": _sha256_bytes(receipt_candidate),
        "reviewer_receipt": reviewer_receipt,
        "run_evidence_sha256": original_manifest,
        "report_sha256": host_evidence["report_sha256"],
        "coordinator_validation_sha256": host_evidence["metadata_sha256"],
        "reviewed_main": INVALID_DISPOSITION_IMPLEMENTATION,
        "implementation_commit": INVALID_DISPOSITION_IMPLEMENTATION,
        "root_sync_pending": True,
        "claim_cleanup_pending": True,
        "reviewer_relaunched": False,
    }
    recovery_bytes = json.dumps(recovery, indent=2, sort_keys=True).encode("utf-8") + b"\n"
    if handoff.exists() and handoff.read_bytes() != recovery_bytes:
        raise RunnerError("existing invalid-disposition recovery journal contradicts the verified evidence")

    # All evidence is checked before the first write. Each artifact is an exact,
    # deterministic replacement, so a process interruption can safely retry.
    if current_disposition == preserved:
        _write_atomic(archived_path, repaired_disposition.decode("utf-8"))
    if current_target == baseline.encode("utf-8"):
        _write_atomic(target_path, receipt_candidate.decode("utf-8"))
    if not handoff.exists():
        _write_bytes_exclusive(handoff, recovery_bytes)
    if (archived_path.read_bytes() != repaired_disposition or target_path.read_bytes() != receipt_candidate
            or preserved_path.read_bytes() != preserved or _sha256_bytes(preserved_path.read_bytes()) != INVALID_DISPOSITION_SHA256
            or _file_manifest(run_dir, omit=continuation_dir) != original_manifest):
        raise RunnerError("post-repair verification failed; original claim and worktree remain protected")
    parsed_outcome, parse_error = review_outcome.parse_review_outcome(archived_path.read_text(encoding="utf-8"))
    if parse_error or parsed_outcome != outcome:
        raise RunnerError("repaired review disposition failed canonical parser verification")
    receipt, receipt_error = verify_review_receipt_delta(
        baseline, target_path.read_text(encoding="utf-8"),
        review_workstream=INVALID_DISPOSITION_WORKSTREAM, target_workstream=INVALID_DISPOSITION_TARGET,
        reviewed_main=INVALID_DISPOSITION_IMPLEMENTATION,
        target_implementation_commit=INVALID_DISPOSITION_IMPLEMENTATION,
    )
    if receipt_error or receipt != reviewer_receipt:
        raise RunnerError("repaired target receipt failed canonical verification: " + (receipt_error or "mismatch"))

    child["invalid_disposition_recovery"] = recovery
    child["root_sync_deferral"] = {"authorized": True, "root_sync_pending": True,
                                   "evidence": str(handoff), "run_evidence_sha256": original_manifest}
    child["host_evidence"] = {**child.get("host_evidence", {}), "continuation_dir": str(continuation_dir)}
    child["phase"] = "coordinator_closeout"
    child["recovery_evidence"] = str(handoff)
    _write_atomic(continuation_dir / "metadata.json", json.dumps(child, indent=2, sort_keys=True) + "\n")
    return child


def continue_run(repo: Path, workstream: str, run_id: str, *,
                 authorize_fresh_reviewer_context: bool = False,
                 recover_host_validation: bool = False,
                 recover_invalid_disposition: bool = False,
                 recover_missing_archived_disposition: bool = False,
                 attest_no_active_owner: bool = False,
                 attest_no_unique_evidence: bool = False,
                 plan_sha256: str | None = None,
                 codex_path: str | None = None, timeout: float | None = None) -> int:
    """Continue one exact preserved review claim in a new independent Codex context."""
    if recover_missing_archived_disposition:
        if (not authorize_fresh_reviewer_context or recover_host_validation or recover_invalid_disposition
                or plan_sha256 or workstream != MISSING_ARCHIVED_DISPOSITION_WORKSTREAM
                or run_id != MISSING_ARCHIVED_DISPOSITION_RUN_ID):
            raise RunnerError("missing-archived-disposition recovery accepts only its exact run with explicit fresh-reviewer authorization")
    if recover_invalid_disposition:
        if (authorize_fresh_reviewer_context or recover_host_validation or recover_missing_archived_disposition or plan_sha256
                or workstream != INVALID_DISPOSITION_WORKSTREAM or run_id != INVALID_DISPOSITION_RUN_ID):
            raise RunnerError("invalid-disposition recovery accepts only the exact held run and does not launch a reviewer")
    elif not authorize_fresh_reviewer_context:
        raise RunnerError("same-run continuation requires --authorize-fresh-reviewer-context")
    if (recover_invalid_disposition or recover_missing_archived_disposition) and codex_path is not None:
        raise RunnerError("special exact-run recovery must not accept an injected reviewer executable")
    if not ID_RE.fullmatch(workstream) or not _RUN_ID_RE.fullmatch(run_id):
        raise RunnerError("continuation requires an exact review workstream and shaped run ID")
    if timeout is not None and (timeout <= 0 or not float(timeout) < float("inf")):
        raise RunnerError("timeout must be a positive finite number")
    repo = Path(git(repo, "rev-parse", "--show-toplevel")).resolve()
    coordinator_main = _coordinator_checkout_sha(repo)
    common = common_dir(repo).resolve()
    expected_root = (common / "custodian-review-runs" / workstream).resolve()
    run_dir = (expected_root / run_id).resolve()
    if run_dir.parent != expected_root or not run_dir.is_dir():
        raise RunnerError("exact original review run directory is absent or outside its canonical location")

    mutex_path = common / "custodian-review-runs" / "locks" / f"{workstream}.lock"
    mutex_path.parent.mkdir(parents=True, exist_ok=True)
    if (recover_host_validation or recover_invalid_disposition or recover_missing_archived_disposition) and not mutex_path.is_file():
        raise RunnerError("original paired-review supervisor lock is missing")
    locked_recovery = recover_host_validation or recover_invalid_disposition or recover_missing_archived_disposition
    with mutex_path.open("rb" if locked_recovery else "a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RunnerError(f"another local process is supervising {workstream}; continuation refused") from exc

        try:
            original = json.loads((run_dir / "metadata.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RunnerError("original run metadata is missing or malformed") from exc
        if not isinstance(original, dict):
            raise RunnerError("original run metadata must be a JSON object")
        if (original.get("schema") != SCHEMA or original.get("run_id") != run_id
                or original.get("workstream") != workstream
                or original.get("run_dir") != str(run_dir)
                or original.get("phase") != ("host_validation_recovery" if recover_host_validation
                                               else "post_exit_recovery")):
            expected_phase = "host_validation_recovery" if recover_host_validation else "post-exit recovery"
            raise RunnerError(f"original run metadata is not the exact eligible {expected_phase}")
        if recover_host_validation:
            plan = _host_recovery_plan_unlocked(
                repo, workstream, run_id,
                attest_no_active_owner=attest_no_active_owner,
                attest_no_unique_evidence=attest_no_unique_evidence,
            )
            if not plan_sha256 or plan.get("plan_sha256") != plan_sha256:
                raise RunnerError("apply requires the exact SHA-256 from a fresh read-only recovery plan")
            reconstruction_state = plan.get("host_validation_state")
            missing_checkout_reconstruction = reconstruction_state in {
                "carrow_failed_nonimport_missing_worktree", "pre_validation_missing_worktree"
            }
            carrow_reconstruction = reconstruction_state == "carrow_failed_nonimport_missing_worktree"
            if missing_checkout_reconstruction:
                if not (attest_no_active_owner and attest_no_unique_evidence):
                    raise RunnerError("missing-worktree recovery requires both explicit operator attestations")
                if plan.get("operator_attestations") != {
                        "no_active_review_owner": True,
                        "no_unique_untracked_or_ignored_evidence": True}:
                    raise RunnerError("missing-worktree recovery plan does not bind both required operator attestations")
                continuation_dir = run_dir / "continuation-01"
                worktree = Path(plan["worktree"]).resolve()
                receipt, _ = _host_validation_claim_receipt(
                    run_dir, workstream, repo, original, str(plan["packet"]),
                    allow_missing_worktree=True,
                )
                if worktree != Path(receipt["worktree"]).resolve() or worktree.exists() or worktree.is_symlink():
                    raise RunnerError("missing-worktree recovery destination changed after the fresh plan")
                if worktree.parent.name != ".custodian-worktrees" or not worktree.parent.is_dir():
                    raise RunnerError("recorded checkout parent is absent or outside the managed worktree root")
                reviewed_head = plan["reviewed_main"]
                implementation_head = plan["implementation_commit"]
                original_manifest = _file_manifest(run_dir)
                reconstruction_record = {
                    "schema": CONTINUATION_SCHEMA, "workstream": workstream, "run_id": run_id,
                    "phase": "worktree_reconstruction_started", "created_utc": datetime.now(timezone.utc).isoformat(),
                    "original_run_dir": str(run_dir), "branch": receipt["branch"],
                    "worktree": str(worktree), "reviewed_main": reviewed_head,
                    "implementation_commit": implementation_head,
                    "original_run_manifest": original_manifest,
                    "original_run_manifest_sha256": _manifest_digest(original_manifest),
                    "recovery_plan_sha256": plan_sha256,
                    "operator_attestations": plan["operator_attestations"],
                    "reviewer_launch_count": 0, "host_validation_attempts": [],
                }
                continuation_dir.mkdir(parents=False, exist_ok=False)
                _write_bytes_exclusive(continuation_dir / "metadata.json",
                                       (json.dumps(reconstruction_record, indent=2, sort_keys=True) + "\n").encode())
                journal_path = continuation_dir / "worktree-recovery.jsonl"
                journal_event = {"schema": "custodian.paired_review_worktree_recovery_event.v1",
                                 "event": "reconstruction_started", "run_id": run_id,
                                 "workstream": workstream, "plan_sha256": plan_sha256,
                                 "worktree": str(worktree), "branch": receipt["branch"],
                                 "head": reviewed_head, "original_run_manifest_sha256": _manifest_digest(original_manifest)}
                _write_bytes_exclusive(journal_path,
                                       (json.dumps(journal_event, sort_keys=True) + "\n").encode())
                try:
                    subprocess.run(["git", "worktree", "add", str(worktree), receipt["branch"]],
                                   cwd=repo, text=True, capture_output=True, check=True)
                    if (common_dir(worktree).resolve() != common
                            or git(worktree, "branch", "--show-current") != receipt["branch"]
                            or git(worktree, "rev-parse", "--verify", "HEAD^{commit}") != reviewed_head
                            or git(worktree, "status", "--porcelain=v1", "--untracked-files=all")):
                        raise RunnerError("reconstructed checkout failed exact clean identity verification")
                except (OSError, subprocess.SubprocessError, RunnerError) as exc:
                    reconstruction_record["phase"] = "worktree_reconstruction_partial"
                    reconstruction_record["error"] = redact(str(exc))
                    _write_atomic(continuation_dir / "metadata.json",
                                  json.dumps(reconstruction_record, indent=2, sort_keys=True) + "\n")
                    journal_event = {**journal_event, "event": "reconstruction_partial", "error": redact(str(exc))}
                    with journal_path.open("ab") as journal:
                        journal.write((json.dumps(journal_event, sort_keys=True) + "\n").encode())
                        journal.flush()
                        os.fsync(journal.fileno())
                    raise RunnerError("checkout reconstruction is partial; preserve it and do not replay") from exc
                reconstruction_record["phase"] = "worktree_reconstructed"
                _write_atomic(continuation_dir / "metadata.json",
                              json.dumps(reconstruction_record, indent=2, sort_keys=True) + "\n")
                journal_event = {**journal_event, "event": "reconstruction_complete"}
                with journal_path.open("ab") as journal:
                    journal.write((json.dumps(journal_event, sort_keys=True) + "\n").encode())
                    journal.flush()
                    os.fsync(journal.fileno())
        else:
            carrow_reconstruction = False
            missing_checkout_reconstruction = False

        continuation_dir = run_dir / (
            MISSING_ARCHIVED_DISPOSITION_CHILD if recover_missing_archived_disposition else "continuation-01"
        )
        parent_continuation = None
        parent_continuation_manifest: dict[str, str] | None = None
        if recover_missing_archived_disposition:
            parent_continuation, parent_continuation_manifest = _verify_missing_archived_disposition_parent(
                run_dir, workstream, run_id, original,
            )
        child_metadata_path = continuation_dir / "metadata.json"
        if recover_invalid_disposition and not continuation_dir.is_dir():
            raise RunnerError("exact invalid-disposition recovery requires the existing preserved continuation-01")
        retry_host_validation = False
        retry_child = None
        if recover_host_validation and continuation_dir.is_dir() and not missing_checkout_reconstruction:
            retry_child = _continuation_metadata(child_metadata_path)
            retry_host_validation = retry_child.get("phase") == "host_validation_failed"
            if not retry_host_validation:
                raise RunnerError("existing host recovery continuation is not an authenticated failed validation retry")
            if (retry_child.get("reviewer_launch_count") != 0
                    or retry_child.get("original_run_manifest") != _file_manifest(run_dir, omit=continuation_dir)):
                raise RunnerError("failed host retry state changed or already launched a reviewer")
        if continuation_dir.exists() and not retry_host_validation and not missing_checkout_reconstruction:
            child = _continuation_metadata(child_metadata_path)
            if (child.get("run_id") != run_id or child.get("workstream") != workstream
                    or child.get("schema") != CONTINUATION_SCHEMA):
                raise RunnerError("existing continuation directory is bound to a different run")
            if recover_missing_archived_disposition:
                if (child.get("continuation_number") != 2
                        or child.get("parent_continuation") != MISSING_ARCHIVED_DISPOSITION_PARENT
                        or child.get("parent_continuation_sha256") != _manifest_digest(parent_continuation_manifest or {})
                        or child.get("parent_continuation_manifest") != parent_continuation_manifest
                        or child.get("run_evidence_sha256") != _file_manifest(run_dir, omit=continuation_dir)):
                    raise RunnerError("existing continuation-02 no longer matches its exact preserved parent manifests")
                if child.get("phase") not in {"coordinator_closeout", "landed_verification_failed", "complete"}:
                    raise RunnerError("continuation-02 already consumed its one reviewer launch; preserve and inspect its phase")
            if recover_invalid_disposition and child.get("phase") == "invalid_reviewer_disposition":
                child = _recover_exact_invalid_disposition(repo, run_dir, continuation_dir, original, child)
            elif recover_invalid_disposition and child.get("phase") not in {
                    "coordinator_closeout", "landed_verification_failed", "complete"}:
                raise RunnerError("exact held run is not in its authorized invalid-disposition recovery state")
            elif recover_invalid_disposition:
                recovery = child.get("invalid_disposition_recovery")
                if (not isinstance(recovery, dict)
                        or recovery.get("schema") != "custodian.paired_review_invalid_disposition_recovery.v1"
                        or recovery.get("workstream") != workstream or recovery.get("run_id") != run_id
                        or recovery.get("original_disposition_sha256") != INVALID_DISPOSITION_SHA256
                        or recovery.get("root_sync_pending") is not True):
                    raise RunnerError("continuation closeout lacks the exact verified invalid-disposition recovery record")
            try:
                state = _verify_continuation_completion(repo, run_dir, continuation_dir, child)
            except (RunnerError, HostValidationError, OSError, ValueError, subprocess.SubprocessError):
                if child.get("phase") == "complete":
                    raise
            else:
                recovery = child.get("invalid_disposition_recovery")
                if isinstance(recovery, dict) and recovery.get("claim_cleanup_pending") is True:
                    recovery_path = continuation_dir / "metadata.json"
                    evidence_path = continuation_dir / "recovery-evidence/recovery-applied.json"
                    _finish_via_workstream(
                        repo, workstream, Path(child["worktree"]),
                        Path(str((child.get("host_evidence") or {}).get("evidence_run_dir", run_dir))) / "validation.json",
                        continuation_dir, defer_root_sync=True, recovery_evidence=recovery_path,
                    )
                    if Path(child["worktree"]).exists() or _remote_branch_exists(repo, child["branch"]):
                        raise RunnerError("verified PASS landed but claim/worktree cleanup remains pending")
                    recovery["claim_cleanup_pending"] = False
                    recovery["cleanup_verified"] = True
                    recovery["cleanup_receipt_sha256"] = _sha256_bytes(evidence_path.read_bytes())
                child.update({"phase": "complete", "landed_commit": child.get("landed_commit", state["revision"]),
                              "verified_main": state["revision"], "post_exit_state": state, "outcome": "passed"})
                if isinstance(recovery, dict):
                    child["invalid_disposition_recovery"] = recovery
                    child["root_sync_deferral"] = {**child.get("root_sync_deferral", {}),
                                                   "root_sync_pending": True,
                                                   "claim_cleanup_pending": False}
                _write_atomic(child_metadata_path, json.dumps(child, indent=2, sort_keys=True) + "\n")
                print(f"paired_review_runner: COMPLETE {workstream} (verified existing continuation)")
                print(f"landed commit: {state['revision']}")
                return 0
            if child.get("phase") not in {"coordinator_closeout", "landed_verification_failed"}:
                raise RunnerError("this exact run already has an incomplete continuation; preserve it and inspect its metadata")

            # A prior fresh reviewer may have completed an exact PASS and then
            # lost control during coordinator closeout. Reuse that authored
            # disposition and retry only coordinator verification/finish.
            active_path = str(child.get("active_packet_path", ""))
            target_path = str(child.get("target_packet_path", ""))
            target_workstream = str(child.get("target_workstream", ""))
            archived_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
            try:
                active_content = (repo / active_path).read_text(encoding="utf-8")
            except OSError:
                active_content = ""
            if active_content:
                packet = parse_packet(active_path, active_content)
            else:
                archived = read_git_text(repo, "origin/main", archived_path)
                packet = parse_packet(active_path, archived)
                if packet.workstream != workstream:
                    raise RunnerError("incomplete continuation archived packet identity changed")
            if (packet.review_target_packet != target_path or packet.review_target_workstream != target_workstream
                    or packet.authoring_chat != child.get("authoring_chat")):
                raise RunnerError("incomplete continuation packet identity changed")
            reviewed_main = child.get("reviewed_main")
            if target_path != child.get("target_packet_path") or target_workstream != child.get("target_workstream"):
                raise RunnerError("incomplete continuation target identity changed")
            reviewed_main = git(repo, "rev-parse", "--verify", f"{reviewed_main}^{{commit}}")
            target_content = read_git_text(repo, reviewed_main, target_path)
            implementation_commit, identity_error = resolve_target_implementation_commit(
                repo, reviewed_main, target_path, target_workstream, target_content,
            )
            if identity_error or implementation_commit != child.get("implementation_commit"):
                raise RunnerError("incomplete continuation implementation identity failed verification")
            archive_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
            recovery_worktree = _continuation_worktree(repo, child)
            committed_head = git(recovery_worktree, "rev-parse", "--verify", "HEAD^{commit}")
            branch_state = landed_review_state(
                repo, committed_head, workstream, active_path, target_workstream, target_path,
                target_content, child.get("authoring_chat"), reviewed_main,
            )
            if branch_state["complete"]:
                archived_text = read_git_text(repo, committed_head, archive_path)
            else:
                if recovery_worktree == repo:
                    raise RunnerError("review branch has no complete PASS receipt and its claimed worktree is gone")
                archived_text = (recovery_worktree / archive_path).read_text(encoding="utf-8")
            outcome, outcome_error = review_outcome.parse_review_outcome(archived_text)
            if outcome_error or outcome is None or outcome.get("Outcome") != "passed":
                raise RunnerError("incomplete continuation has no exact reviewer-authored PASS disposition")
            outcome_error = review_outcome.outcome_identity_error(
                outcome, review_workstream=workstream, target_workstream=target_workstream,
                reviewed_main=reviewed_main, implementation_commit=implementation_commit,
                run_id=run_id, review_cycle=packet.review_cycle,
            )
            if outcome_error:
                raise RunnerError("incomplete continuation PASS identity failed verification: " + outcome_error)
            host_evidence = _host_evidence_for_continuation(repo, recovery_worktree, run_dir, original,
                                                        reviewed_main, implementation_commit,
                                                        target_workstream, target_path)
            host_evidence["continuation_dir"] = str(continuation_dir)
            recovery = child.get("invalid_disposition_recovery")
            recovery_evidence_path = continuation_dir / "recovery-evidence/recovery-applied.json"
            if isinstance(recovery, dict):
                host_evidence["recovery_evidence"] = str(child_metadata_path)
            resumed_land = coordinator_finish_review(
                repo, workstream, recovery_worktree, active_path,
                target_workstream, target_path, target_content, packet.authoring_chat,
                reviewed_main, continuation_dir, host_evidence,
                defer_teardown=isinstance(recovery, dict),
            )
            try:
                state = _verify_continuation_completion(repo, run_dir, continuation_dir, child)
            except (RunnerError, HostValidationError, OSError, ValueError, subprocess.SubprocessError):
                if child.get("phase") == "complete":
                    raise
                state = None
            if state is not None:
                if isinstance(recovery, dict):
                    _finish_via_workstream(
                        repo, workstream, recovery_worktree,
                        Path(str(host_evidence.get("evidence_run_dir", run_dir))) / "validation.json",
                        continuation_dir, defer_root_sync=True,
                        recovery_evidence=child_metadata_path,
                    )
                    if recovery_worktree.exists() or _remote_branch_exists(repo, child["branch"]):
                        raise RunnerError("PASS receipt is verified but safe claim cleanup is still pending")
                    recovery["claim_cleanup_pending"] = False
                    recovery["cleanup_verified"] = True
                    recovery["cleanup_receipt_sha256"] = _sha256_bytes(recovery_evidence_path.read_bytes())
                child.update({"phase": "complete", "landed_commit": child.get("landed_commit", state["revision"]),
                              "verified_main": state["revision"], "post_exit_state": state, "outcome": "passed"})
                if isinstance(recovery, dict):
                    child["invalid_disposition_recovery"] = recovery
                    child["root_sync_deferral"] = {**child.get("root_sync_deferral", {}),
                                                   "root_sync_pending": True,
                                                   "claim_cleanup_pending": False}
                _write_atomic(child_metadata_path, json.dumps(child, indent=2, sort_keys=True) + "\n")
                print(f"paired_review_runner: COMPLETE {workstream} (resumed coordinator closeout)")
                print(f"landed commit: {resumed_land}")
                return 0

            if recover_invalid_disposition:
                raise RunnerError("recovered PASS failed post-land verification; reviewer launch is prohibited")

        if codex_path:
            executable = codex_path
            help_result = subprocess.run([executable, "exec", "--help"], text=True, capture_output=True)
            help_text = help_result.stdout + help_result.stderr
            required = ("--ephemeral", "--json", "--output-last-message", "--cd", "--add-dir", "--approve-for-me")
            if help_result.returncode or any(flag not in help_text for flag in required):
                raise RunnerError("injected Codex executable lacks the required fresh ephemeral invocation support")
        else:
            executable = codex_preflight()

        # Fetch only after proving the coordinator checkout is clean and canonical.
        active_path, active_content, packet = validate_eligible_review(repo, workstream)
        if recover_host_validation and git(repo, "rev-parse", "origin/main^{commit}") != coordinator_main:
            raise RunnerError("origin/main advanced after the read-only plan; stop and prepare a new plan")
        if packet.review_target_workstream is None or packet.review_target_packet is None:
            raise RunnerError("active review packet omits its exact target identity")
        if (original.get("packet") is not None and original.get("packet") != active_path):
            raise RunnerError("original claim packet path differs from current active packet identity")
        reviewed_main = original.get("reviewed_main")
        if not isinstance(reviewed_main, str) or not re.fullmatch(r"[0-9a-f]{40,64}", reviewed_main):
            raise RunnerError("original run omits its pinned reviewed-main SHA")
        reviewed_main = git(repo, "rev-parse", "--verify", f"{reviewed_main}^{{commit}}")
        target_path = packet.review_target_packet
        if target_path != f"{PACKET_ROOT}/archived/{Path(target_path).name}":
            raise RunnerError("review target path is not its exact canonical archived path")
        target_content = read_git_text(repo, reviewed_main, target_path)
        target = parse_packet(target_path, target_content)
        if (target.error or target.workstream != packet.review_target_workstream
                or target.kind not in {"implementation", "correction"} or target.status != "complete"):
            raise RunnerError("pinned archived target is invalid or incomplete")
        implementation_commit, identity_error = resolve_target_implementation_commit(
            repo, reviewed_main, target_path, packet.review_target_workstream, target_content,
        )
        if identity_error:
            raise RunnerError("pinned implementation identity failed verification: " + identity_error)

        if recover_host_validation:
            receipt, receipt_source_name = _host_validation_claim_receipt(
                run_dir, workstream, repo, original, active_path,
            )
        else:
            claim_file = run_dir / "claim-receipt.json"
            if claim_file.is_file():
                try:
                    receipt_value = json.loads(claim_file.read_text(encoding="utf-8"))
                except json.JSONDecodeError as exc:
                    raise RunnerError("structured original claim receipt is malformed") from exc
                receipt_source = CLAIM_SENTINEL + json.dumps(receipt_value, sort_keys=True)
                receipt = parse_claim_receipt(receipt_source, workstream, repo)
                receipt_source_name = "claim-receipt.json"
            else:
                try:
                    receipt_source = (run_dir / "claim.stdout").read_text(encoding="utf-8")
                except OSError as exc:
                    raise RunnerError("original structured claim receipt is missing") from exc
                sentinels = [line for line in receipt_source.splitlines() if line.startswith(CLAIM_SENTINEL)]
                if len(sentinels) != 1:
                    raise RunnerError("original structured claim receipt is missing or ambiguous")
                payload = sentinels[0][len(CLAIM_SENTINEL):]
                try:
                    json.loads(payload)
                except json.JSONDecodeError as exc:
                    if not _claim_json_was_truncated(payload, exc):
                        raise RunnerError("original claim receipt is malformed rather than truncated") from exc
                    receipt = _legacy_claim_receipt(receipt_source, workstream, repo, original)
                    receipt_source_name = "verified-truncated-claim.stdout-header"
                else:
                    # A parseable but unverified receipt never falls back on human-readable fields.
                    receipt = parse_claim_receipt(receipt_source, workstream, repo)
                    receipt_source_name = "claim.stdout"
        worktree = Path(receipt["worktree"]).resolve()
        branch = f"agent/{workstream}"
        if recover_host_validation:
            recorded_worktree = original.get("recovery_worktree")
            metadata_identity_mismatch = (
                (original.get("branch") is not None and original.get("branch") != branch)
                or (recorded_worktree is not None
                    and Path(str(recorded_worktree)).resolve() != worktree)
                or (original.get("packet") is not None and original.get("packet") != active_path)
            )
        else:
            metadata_identity_mismatch = (
                original.get("branch") != branch
                or Path(str(original.get("worktree", ""))).resolve() != worktree
                or original.get("packet") != active_path
            )
        if receipt["branch"] != branch or receipt["packet"] != active_path or metadata_identity_mismatch:
            raise RunnerError("original dispatcher receipt, metadata, branch, and packet do not agree")
        if common_dir(worktree).resolve() != common or git(worktree, "branch", "--show-current") != branch:
            raise RunnerError("original claimed checkout is missing, foreign, or on another branch")
        if git(worktree, "rev-parse", "--verify", "HEAD^{commit}") != reviewed_main:
            raise RunnerError("original review checkout head differs from its pinned reviewed-main SHA")
        if git(worktree, "rev-parse", "--verify", f"refs/heads/{branch}^{{commit}}") != reviewed_main:
            raise RunnerError("original local review branch moved away from its pinned reviewed main")
        git(repo, "fetch", "origin", branch)
        if git(repo, "rev-parse", "--verify", f"refs/remotes/origin/{branch}^{{commit}}") != reviewed_main:
            raise RunnerError("published review branch moved away from its pinned reviewed main")
        try:
            original_packet_text = (worktree / active_path).read_text(encoding="utf-8")
        except OSError as exc:
            raise RunnerError("original claimed worktree no longer contains its exact active packet") from exc
        original_packet = parse_packet(active_path, original_packet_text)
        if (original_packet.error or original_packet.workstream != workstream
                or original_packet.review_target_workstream != packet.review_target_workstream
                or original_packet.review_target_packet != target_path
                or original_packet.authoring_chat != packet.authoring_chat):
            raise RunnerError("original worktree packet identity differs from the current paired review")
        same_run_heading = f"### Review Receipt: {workstream}"
        if same_run_heading in target_content:
            raise RunnerError("pinned target already contains a receipt for this review; refusing a duplicate")
        if (worktree / target_path).read_bytes() != target_content.encode("utf-8"):
            raise RunnerError("original review worktree target differs from the pinned archived baseline")
        archive_path = f"{PACKET_ROOT}/archived/{Path(active_path).name}"
        if (recover_missing_archived_disposition
                and (worktree / archive_path).exists()):
            raise RunnerError("continuation-01 state already contains an archived review disposition")

        cache_roots = reviewer_cache_roots(repo)
        summary_paths = {expected_summary_path(workstream)}
        untracked = _changed_paths(worktree, "ls-files", "--others", "--exclude-standard")
        artifacts = _worktree_review_artifacts(
            worktree, workstream, packet.review_target_workstream, active_path, target_path,
        )
        for relative in untracked:
            if ((relative.startswith("custodian/tools/validation/") and relative.endswith(".gd.uid"))
                    or relative in summary_paths):
                candidate = worktree / relative
                if candidate.is_file() and candidate not in artifacts:
                    artifacts.append(candidate)
        artifacts.sort(key=str)
        review_summary_token = workstream.upper().replace("-", "_")
        summary_paths.update(path.relative_to(worktree).as_posix() for path in artifacts
                             if path.name.endswith("_SUMMARY.md")
                             and (path.name == expected_summary_path(workstream)
                                  or path.name.startswith("REVIEW_")
                                  or "_REVIEW_" in path.name
                                  or review_summary_token in path.name))
        allowed_import_sidecars = ({item["sidecar_path"] for item in plan.get("generated_import_sidecars", [])}
                                   if recover_host_validation else set())
        tracked_changes, untracked = _reviewer_dirty_surface(
            worktree, active_path, summary_paths, allowed_untracked=allowed_import_sidecars,
        )
        original_run_manifest = (_file_manifest(run_dir, omit=continuation_dir)
                                 if retry_host_validation or missing_checkout_reconstruction else _file_manifest(run_dir))
        if recover_missing_archived_disposition:
            if (parent_continuation_manifest is None
                    or _file_manifest(run_dir / MISSING_ARCHIVED_DISPOSITION_PARENT) != parent_continuation_manifest):
                raise RunnerError("protected run or continuation-01 changed during continuation-02 preflight")
        if not recover_host_validation:
            host_evidence = _host_evidence_for_continuation(
                repo, worktree, run_dir, original, reviewed_main, implementation_commit,
                packet.review_target_workstream, target_path,
            )
            host_evidence["continuation_dir"] = str(continuation_dir)

        # A single fixed child makes uncertain interruptions non-replayable.
        if not retry_host_validation and not missing_checkout_reconstruction:
            continuation_dir.mkdir(parents=False, exist_ok=False)
        initial = retry_child if retry_host_validation else (
            _continuation_metadata(child_metadata_path) if missing_checkout_reconstruction else {
            "schema": CONTINUATION_SCHEMA, "workstream": workstream, "run_id": run_id,
            "phase": "prepared", "created_utc": datetime.now(timezone.utc).isoformat(),
            "original_run_dir": str(run_dir), "branch": branch, "worktree": str(worktree),
            "active_packet_path": active_path, "target_workstream": packet.review_target_workstream,
            "target_packet_path": target_path, "authoring_chat": packet.authoring_chat,
            "reviewed_main": reviewed_main, "implementation_commit": implementation_commit,
            "review_cycle": packet.review_cycle,
            "claim_receipt_source": receipt_source_name,
            "source_span": plan.get("source_span") if recover_host_validation else None,
            "run_evidence_sha256": original_run_manifest,
            "initial_tracked_changes": tracked_changes,
            "initial_untracked_files": untracked,
        })
        if recover_host_validation and not retry_host_validation:
            initial.update({
                "original_run_manifest": original_run_manifest,
                "failed_validation_evidence": plan.get("failed_validation_evidence"),
                "host_validation_attempts": [],
                "reviewer_launch_count": 0,
            })
            if missing_checkout_reconstruction:
                initial["original_run_manifest"] = original_run_manifest
                initial["original_run_manifest_sha256"] = _manifest_digest(original_run_manifest)
                initial["operator_attestations"] = plan["operator_attestations"]
            sidecar_records = plan.get("generated_import_sidecars", [])
            if sidecar_records:
                recovery_dir = continuation_dir / "original-generated-imports"
                files_dir = recovery_dir / "files"
                files_dir.mkdir(parents=True, exist_ok=False)
                preserved_records = []
                for record in sidecar_records:
                    source = worktree / record["sidecar_path"]
                    raw = source.read_bytes()
                    if (_sha256_bytes(raw) != record["sha256"]
                            or len(raw) != record["size_bytes"]
                            or source.is_symlink()):
                        raise RunnerError("protected import sidecar changed after the read-only plan")
                    evidence_name = record["sha256"] + ".png.import"
                    destination = files_dir / evidence_name
                    _write_bytes_exclusive(destination, raw)
                    if _sha256_bytes(destination.read_bytes()) != record["sha256"]:
                        raise RunnerError("protected import sidecar preservation copy failed verification")
                    preserved_records.append({**record,
                                              "evidence_path": f"original-generated-imports/files/{evidence_name}"})
                manifest_bytes = (json.dumps(preserved_records, indent=2, sort_keys=True) + "\n").encode()
                manifest_path = recovery_dir / "manifest.json"
                _write_bytes_exclusive(manifest_path, manifest_bytes)
                initial["generated_import_recovery"] = {
                    "manifest_path": "original-generated-imports/manifest.json",
                    "manifest_sha256": _sha256_bytes(manifest_bytes),
                    "count": len(preserved_records),
                }
                initial["phase"] = "host_validation_sidecars_preserved"
                _write_bytes_exclusive(
                    child_metadata_path,
                    (json.dumps(initial, indent=2, sort_keys=True) + "\n").encode(),
                )
                for record in preserved_records:
                    source = worktree / record["sidecar_path"]
                    if (_sha256_bytes(source.read_bytes()) != record["sha256"]
                            or _sha256_bytes((continuation_dir / record["evidence_path"]).read_bytes()) != record["sha256"]):
                        raise RunnerError("protected import sidecar changed before controlled cleanup")
                for record in preserved_records:
                    source = worktree / record["sidecar_path"]
                    if source.is_symlink() or not source.is_file() or _sha256_bytes(source.read_bytes()) != record["sha256"]:
                        raise RunnerError("protected import sidecar changed before controlled cleanup")
                    source.unlink()
            if _file_manifest(run_dir, omit=continuation_dir) != original_run_manifest:
                raise RunnerError("original failed host-validation evidence changed during sidecar preservation")
        if recover_missing_archived_disposition:
            initial.update({
                "continuation_number": 2,
                "parent_continuation": MISSING_ARCHIVED_DISPOSITION_PARENT,
                "parent_continuation_manifest": parent_continuation_manifest,
                "parent_continuation_sha256": _manifest_digest(parent_continuation_manifest or {}),
                "original_run_manifest": parent_continuation.get("run_evidence_sha256"),
                "original_run_manifest_sha256": _manifest_digest(
                    parent_continuation.get("run_evidence_sha256", {})),
            })
            _write_bytes_exclusive(
                continuation_dir / "prior-continuation-01-manifest.json",
                (json.dumps({
                    "schema": "custodian.paired_review_prior_continuation_manifest.v1",
                    "workstream": workstream,
                    "run_id": run_id,
                    "parent_continuation": MISSING_ARCHIVED_DISPOSITION_PARENT,
                    "original_run_manifest": parent_continuation.get("run_evidence_sha256"),
                    "continuation_01_manifest": parent_continuation_manifest,
                    "continuation_01_manifest_sha256": _manifest_digest(parent_continuation_manifest or {}),
                }, indent=2, sort_keys=True) + "\n").encode(),
            )
        if recover_host_validation:
            attempt_number = int(plan["host_validation_attempt"])
            validation_dir = continuation_dir / "host-validation" / f"attempt-{attempt_number:02d}"
            validation_dir.mkdir(parents=True, exist_ok=False)
            initial["phase"] = "host_validation_running"
            initial["host_validation_dir"] = str(validation_dir)
            if not child_metadata_path.exists():
                _write_bytes_exclusive(child_metadata_path,
                                       (json.dumps(initial, indent=2, sort_keys=True) + "\n").encode())
            else:
                _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            try:
                host_evidence = run_coordinator_validation(
                    worktree, validation_dir, reviewed_main, implementation_commit,
                    target_workstream=packet.review_target_workstream,
                    target_packet_path=target_path,
                    **({"source_span_override": plan["source_span"]}
                       if missing_checkout_reconstruction else {}),
                )
            except (HostValidationError, OSError, subprocess.SubprocessError, ValueError) as exc:
                attempt_manifest = _file_manifest(validation_dir)
                attempt_record = {"attempt": attempt_number, "status": "failed",
                                  "manifest": attempt_manifest,
                                  "manifest_sha256": _manifest_digest(attempt_manifest),
                                  "report_sha256": attempt_manifest.get("validation.json"),
                                  "metadata_sha256": attempt_manifest.get("coordinator-validation.json"),
                                  "error": redact(str(exc))}
                attempts = list(initial.get("host_validation_attempts", []))
                attempts.append(attempt_record)
                initial.update({"phase": "host_validation_failed", "error": redact(str(exc)),
                                "host_validation_attempts": attempts,
                                "reviewer_launch_count": 0})
                if _file_manifest(run_dir, omit=continuation_dir) != original_run_manifest:
                    initial["phase"] = "original_evidence_changed"
                    _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
                    raise RunnerError("original run evidence changed during corrected host validation") from exc
                _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
                raise RunnerError("corrected host validation did not pass; original run remains protected") from exc
            host_evidence["evidence_run_dir"] = str(validation_dir)
            host_evidence["continuation_dir"] = str(continuation_dir)
            attempt_manifest = _file_manifest(validation_dir)
            attempts = list(initial.get("host_validation_attempts", []))
            attempts.append({"attempt": attempt_number, "status": "passed",
                             "manifest": attempt_manifest,
                             "manifest_sha256": _manifest_digest(attempt_manifest)})
            initial["host_evidence"] = host_evidence
            initial["host_validation_attempts"] = attempts
            initial["reviewer_launch_count"] = 0
            initial["phase"] = "prepared"
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
        else:
            initial["host_evidence"] = {key: value for key, value in host_evidence.items()
                                        if key != "continuation_dir"}
            _write_bytes_exclusive(child_metadata_path,
                                   (json.dumps(initial, indent=2, sort_keys=True) + "\n").encode())

        preserved: list[dict[str, str]] = []
        preserve_dir = continuation_dir / "preserved-reviewer-files"
        for index, artifact in enumerate(artifacts):
            record = _preserve_file(artifact, preserve_dir / f"{index:02d}-{artifact.name}")
            preserved.append(record)
        reports_dir = continuation_dir / "prior-run-evidence"
        for artifact in sorted(run_dir.glob("*.json")):
            if artifact.is_file():
                preserved.append(_preserve_file(artifact, reports_dir / artifact.name))
        _write_bytes_exclusive(
            continuation_dir / "preserved-files.json",
            (json.dumps(preserved, indent=2, sort_keys=True) + "\n").encode(),
        )
        # Move only generated Godot UID sidecars and noncanonical untracked summaries
        # after a verified byte-exact copy is durable in this exact continuation.
        preserved_by_source = {item["source"]: item for item in preserved}
        for relative in untracked:
            source = worktree / relative
            if relative in summary_paths and relative != expected_summary_path(workstream):
                item = preserved_by_source.get(str(source))
                if item is None:
                    raise RunnerError(f"noncanonical summary lacks a verified preservation copy: {relative}")
                source.unlink()
            elif relative.startswith("custodian/tools/validation/") and relative.endswith(".gd.uid"):
                item = preserved_by_source.get(str(source))
                if item is None:
                    raise RunnerError(f"generated sidecar lacks a verified preservation copy: {relative}")
                source.unlink()
        if (_file_manifest(run_dir, omit=continuation_dir) != original_run_manifest
                or (recover_missing_archived_disposition
                    and _file_manifest(run_dir / MISSING_ARCHIVED_DISPOSITION_PARENT)
                    != parent_continuation_manifest)):
            raise RunnerError("original paired-review evidence changed during continuation preparation")

        last_message = continuation_dir / "last-message.txt"
        argv = [str(executable), "exec", "--ephemeral", "--json", "--approve-for-me",
                "--cd", str(worktree), "--add-dir", str(continuation_dir)]
        for cache_root in cache_roots:
            argv.extend(("--add-dir", str(cache_root)))
        argv.extend(("--output-last-message", str(last_message), "-"))
        initial.update({"phase": "reviewer_starting", "preserved_files": preserved,
                        "reviewer_launch_count": 1,
                        "invocation": ["codex", "exec", "--ephemeral", "--json", "--approve-for-me",
                                       "--cd", str(worktree), "--add-dir", "<continuation-dir>",
                                       *(item for root in cache_roots for item in ("--add-dir", str(root))),
                                       "--output-last-message", "<continuation-dir>/last-message.txt", "-"]})
        _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
        started = time.monotonic()
        try:
            exit_code = launch_codex(
                argv, worktree,
                _continuation_prompt(
                    workstream, active_path, target_path, run_id=run_id,
                    target_workstream=packet.review_target_workstream,
                    reviewed_main=reviewed_main, implementation_commit=implementation_commit,
                    authoring_chat=packet.authoring_chat, continuation_dir=continuation_dir,
                    preserved=preserved, report_sha256=host_evidence["report_sha256"],
                    source_span=host_evidence.get("source_span"),
                    validation_report_path=(
                        Path(host_evidence["evidence_run_dir"]) / "validation.json"
                        if recover_host_validation else continuation_dir / "prior-run-evidence/validation.json"
                    ),
                            continuation_number=2 if recover_missing_archived_disposition else 1,
                ), continuation_dir, timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            initial.update({"phase": "reviewer_interrupted", "error": redact(str(exc)),
                            "elapsed_seconds": round(time.monotonic() - started, 3)})
            if (recover_missing_archived_disposition
                    and (_file_manifest(run_dir, omit=continuation_dir) != original_run_manifest
                         or _file_manifest(run_dir / MISSING_ARCHIVED_DISPOSITION_PARENT)
                         != parent_continuation_manifest)):
                initial["phase"] = "original_evidence_changed"
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("fresh reviewer did not finish or protected evidence changed; exact claim and evidence remain protected") from exc
        if last_message.is_file():
            _write_atomic(last_message, safe_output(last_message.read_text(encoding="utf-8", errors="replace")))
        if (_file_manifest(run_dir, omit=continuation_dir) != original_run_manifest
                or (recover_missing_archived_disposition
                    and _file_manifest(run_dir / MISSING_ARCHIVED_DISPOSITION_PARENT)
                    != parent_continuation_manifest)):
            initial.update({"phase": "original_evidence_changed", "exit_code": exit_code})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("original run evidence changed while the reviewer was active")
        try:
            verify_coordinator_validation(
                repo=worktree, run_dir=Path(host_evidence.get("evidence_run_dir", run_dir)), reviewed_main=reviewed_main,
                implementation_commit=implementation_commit,
                target_workstream=packet.review_target_workstream,
                target_packet_path=target_path,
                **({"source_span_override": plan["source_span"]}
                   if missing_checkout_reconstruction else {}),
                expected_report_sha256=host_evidence["report_sha256"],
                expected_metadata_sha256=host_evidence["metadata_sha256"],
            )
        except HostValidationError as exc:
            initial.update({"phase": "host_evidence_changed", "exit_code": exit_code,
                            "error": redact(str(exc))})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("pinned host evidence failed post-review verification") from exc
        initial.update({"phase": "reviewer_exited", "exit_code": exit_code,
                        "elapsed_seconds": round(time.monotonic() - started, 3),
                        "last_message": str(last_message) if last_message.exists() else None})
        _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
        if exit_code != 0:
            initial["phase"] = "reviewer_blocked"
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            print(f"paired_review_runner: BLOCKED_RECOVERABLE {workstream}; original claim preserved")
            return 2

        archived_file = worktree / archive_path
        if not archived_file.is_file():
            initial["phase"] = "missing_archived_disposition"
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("fresh reviewer did not author the exact archived review packet")
        archived_text = archived_file.read_text(encoding="utf-8")
        outcome, outcome_error = review_outcome.parse_review_outcome(archived_text)
        if outcome_error or outcome is None:
            initial.update({"phase": "invalid_reviewer_disposition", "disposition_error": outcome_error or "missing"})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("fresh reviewer disposition is missing or malformed")
        identity_error = review_outcome.outcome_identity_error(
            outcome, review_workstream=workstream, target_workstream=packet.review_target_workstream,
            reviewed_main=reviewed_main, implementation_commit=implementation_commit,
            run_id=run_id, review_cycle=packet.review_cycle,
        )
        if identity_error:
            initial.update({"phase": "invalid_reviewer_disposition", "disposition_error": identity_error})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError(identity_error)
        if outcome["Outcome"] != "passed":
            initial.update({"phase": "reviewer_nonpassing", "outcome": outcome["Outcome"],
                            "finding_ids": review_outcome.finding_ids(outcome)})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            print(f"paired_review_runner: {outcome['Outcome'].upper()} {workstream}; original claim and worktree preserved")
            return 2

        if workstream != f"review-{packet.review_target_workstream}":
            raise RunnerError("passing continuation identity is not the exact paired review of its target")
        initial["phase"] = "coordinator_closeout"
        _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
        landed = coordinator_finish_review(
            repo, workstream, worktree, active_path, packet.review_target_workstream,
            target_path, target_content, packet.authoring_chat, reviewed_main,
            continuation_dir, host_evidence,
        )
        try:
            state = _verify_continuation_completion(repo, run_dir, continuation_dir, initial)
        except (RunnerError, HostValidationError, OSError, ValueError, subprocess.SubprocessError) as exc:
            initial.update({"phase": "landed_verification_failed", "landed_commit": landed,
                            "verification_error": redact(str(exc))})
            _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
            raise RunnerError("coordinator closeout landed without an exact verified independent receipt") from exc
        revision = state["revision"]
        initial.update({"phase": "complete", "landed_commit": landed, "verified_main": revision,
                        "post_exit_state": state, "outcome": "passed"})
        _write_atomic(child_metadata_path, json.dumps(initial, indent=2, sort_keys=True) + "\n")
        _verify_run_evidence(run_dir, original_run_manifest, continuation_dir)
        print(f"paired_review_runner: COMPLETE {workstream}")
        print(f"landed commit: {landed}")
        return 0


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "recover-procession-pass-closeout":
        return _procession_pass_closeout_recovery_main(argv[1:])
    if argv and argv[0] == "recover-closeout":
        return _recover_main(argv[1:])
    if argv and argv[0] == "recover-advanced-head-pass":
        return _advanced_head_pass_recovery_main(argv[1:])
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("review_workstream", help="exact paired review workstream; global-next is unsupported")
    parser.add_argument("--timeout", type=float, default=None)
    parser.add_argument("--continue-run", default=None,
                        help="continue this exact preserved paired-review run in a new fresh reviewer context")
    parser.add_argument("--authorize-fresh-reviewer-context", action="store_true",
                        help="explicitly authorize a new independent reviewer session on the original claim/worktree")
    parser.add_argument("--recover-host-validation", action="store_true",
                        help="recover this exact run from pre-launch host_validation_recovery")
    parser.add_argument("--recover-invalid-disposition", action="store_true",
                        help="repair and close only the exact preserved invalid-disposition run; never launches a reviewer")
    parser.add_argument("--recover-missing-archived-disposition", action="store_true",
                        help="launch the one explicitly authorized continuation-02 for the exact held missing-archive run")
    recovery_mode = parser.add_mutually_exclusive_group()
    recovery_mode.add_argument("--plan", action="store_true",
                               help="print a read-only, SHA-pinned host-validation recovery plan")
    recovery_mode.add_argument("--apply", action="store_true",
                               help="apply the exact explicitly authorized host-validation recovery plan")
    parser.add_argument("--plan-sha256", default=None,
                        help="exact plan_sha256 emitted by a fresh --plan (required with --apply)")
    parser.add_argument("--attest-no-active-review-owner", action="store_true",
                        help="operator attests no process or remote operator still owns the exact Carrow review")
    parser.add_argument("--attest-no-unique-worktree-evidence", action="store_true",
                        help="operator attests missing checkout held no unique untracked/ignored evidence")
    args = parser.parse_args(argv)
    try:
        if args.recover_invalid_disposition:
            if (args.continue_run is None or args.review_workstream != INVALID_DISPOSITION_WORKSTREAM
                    or args.continue_run != INVALID_DISPOSITION_RUN_ID
                    or args.authorize_fresh_reviewer_context or args.recover_host_validation
                    or args.recover_missing_archived_disposition
                    or args.plan or args.apply or args.plan_sha256 or args.timeout is not None):
                raise RunnerError("invalid-disposition recovery requires only its exact workstream and --continue-run ID")
            return continue_run(
                Path.cwd(), args.review_workstream, args.continue_run,
                recover_invalid_disposition=True,
            )
        if args.recover_missing_archived_disposition:
            if (args.continue_run is None or not args.authorize_fresh_reviewer_context
                    or args.recover_host_validation or args.plan or args.apply or args.plan_sha256
                    or args.review_workstream != MISSING_ARCHIVED_DISPOSITION_WORKSTREAM
                    or args.continue_run != MISSING_ARCHIVED_DISPOSITION_RUN_ID):
                raise RunnerError("missing-archive recovery requires its exact run, --recover-missing-archived-disposition, and --authorize-fresh-reviewer-context")
            return continue_run(
                Path.cwd(), args.review_workstream, args.continue_run,
                authorize_fresh_reviewer_context=True,
                recover_missing_archived_disposition=True, timeout=args.timeout,
            )
        if args.recover_host_validation:
            if args.continue_run is None:
                raise RunnerError("host-validation recovery requires the exact --continue-run ID")
            if args.plan:
                if args.authorize_fresh_reviewer_context or args.apply or args.plan_sha256:
                    raise RunnerError("read-only --plan cannot include apply authorization or a plan digest")
                plan = plan_host_validation_recovery(
                    Path.cwd(), args.review_workstream, args.continue_run,
                    **({"attest_no_active_owner": True, "attest_no_unique_evidence": True}
                       if args.attest_no_active_review_owner and args.attest_no_unique_worktree_evidence else {}),
                )
                print(json.dumps(plan, indent=2, sort_keys=True))
                return 0
            if not args.apply or not args.authorize_fresh_reviewer_context or not args.plan_sha256:
                raise RunnerError("host recovery apply requires --apply, --authorize-fresh-reviewer-context, and --plan-sha256")
            if args.attest_no_active_review_owner != args.attest_no_unique_worktree_evidence:
                raise RunnerError("Carrow operator attestations must be supplied together")
            return continue_run(
                Path.cwd(), args.review_workstream, args.continue_run,
                authorize_fresh_reviewer_context=True, recover_host_validation=True,
                **({"attest_no_active_owner": True, "attest_no_unique_evidence": True}
                   if args.attest_no_active_review_owner and args.attest_no_unique_worktree_evidence else {}),
                plan_sha256=args.plan_sha256, timeout=args.timeout,
            )
        if args.apply or args.plan or args.plan_sha256 or args.attest_no_active_review_owner or args.attest_no_unique_worktree_evidence:
            raise RunnerError("--plan/--apply/--plan-sha256 are reserved for --recover-host-validation")
        if args.continue_run is not None or args.authorize_fresh_reviewer_context:
            if args.continue_run is None or not args.authorize_fresh_reviewer_context:
                raise RunnerError("continuation requires both --continue-run and --authorize-fresh-reviewer-context")
            return continue_run(Path.cwd(), args.review_workstream, args.continue_run,
                                authorize_fresh_reviewer_context=True, timeout=args.timeout)
        return run(Path.cwd(), args.review_workstream, timeout=args.timeout)
    except (RunnerError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"paired_review_runner: BLOCKED: {redact(str(exc))}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
