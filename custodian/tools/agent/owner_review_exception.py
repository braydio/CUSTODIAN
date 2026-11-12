#!/usr/bin/env python3
"""Plan and record one owner-authorized, commit-pinned review exception.

RETIRED 2026-11-12: paired review was retired by owner decision, so no new
exceptions are created through this lane. The owner decision is now simply
`Review: none` on the implementation packet. This module is kept only so
the one historical exception record
(`review-operator-chassis-authority-seal-v1`) still verifies; do not extend
it to new workstreams.

An exception is a distinct administrative disposition. It never edits a review
packet or makes ``review_outcome.review_acceptance`` return PASS.
"""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parent))
import review_outcome
from task_packet_contract import PACKET_ROOT, parse_packet
from workflow_control import common_mutex

SCHEMA = "custodian.owner_review_exception.v1"
REGISTRY = "custodian/docs/ai_context/owner_review_exceptions"
REVIEW_ID = "review-operator-chassis-authority-seal-v1"
IMPLEMENTATION_ID = "operator-chassis-authority-seal-v1"
ACTIVATION_REVIEW_ID = "review-owner-review-exception-lane-v1"
ACTIVATION_TARGET_ID = "owner-review-exception-lane-v1"


class ExceptionError(RuntimeError):
    pass


def _git(repo: Path, *args: str, check: bool = True) -> str:
    p = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and p.returncode:
        raise ExceptionError((p.stderr or p.stdout).strip())
    return p.stdout.strip()


def _sha(text: str | bytes) -> str:
    data = text.encode("utf-8") if isinstance(text, str) else text
    return hashlib.sha256(data).hexdigest()


def _read(repo: Path, tree: str, path: str) -> str:
    result = subprocess.run(["git", "show", f"{tree}:{path}"], cwd=repo,
                            text=True, capture_output=True)
    return result.stdout if result.returncode == 0 else ""


def _json_canonical(value: dict) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def _validate_chat_approval(approval: dict, review_id: str) -> None:
    """Validate the exact owner instruction captured from the authenticated chat.

    The ChatGPT conversation is the approval surface; the digest binds the
    durable record to the exact user message rather than an editable packet
    flag or a caller-supplied yes/no switch.
    """
    if not isinstance(approval, dict) or approval.get("schema") != "custodian.chat_owner_approval.v1":
        raise ExceptionError("missing authenticated ChatGPT owner approval receipt")
    url = approval.get("source_url")
    parsed = urlsplit(url or "")
    if (parsed.scheme != "https" or parsed.hostname != "chatgpt.com"
            or not re.search(r"/c/[A-Za-z0-9-]+/?$", parsed.path)):
        raise ExceptionError("owner approval must cite one exact ChatGPT conversation URL")
    if approval.get("approver") != "project-owner":
        raise ExceptionError("approval identity is not the project owner")
    message = approval.get("user_message")
    message_sha = approval.get("user_message_sha256")
    if not isinstance(message, str) or not message.strip() or message_sha != _sha(message):
        raise ExceptionError("owner approval message is missing or its digest does not match")
    normalized = message.lower()
    required = (
        review_id,
        "waiv",
        "unresolved",
        "authoriz",
    )
    if not all(token in normalized for token in required):
        raise ExceptionError("owner message does not explicitly waive this unresolved review")
    if "passed" in normalized and re.search(r"\b(pass|passed)\b", normalized):
        # The project-owner language may contrast the exception with PASS, but
        # must not purport to change the review's verdict.
        if "not" not in normalized and "without" not in normalized:
            raise ExceptionError("owner approval may not represent the review as passed")
    if approval.get("retire_claim") is not True:
        raise ExceptionError("owner approval does not authorize exact claim retirement")


def _target_state(repo: Path, tree: str, review_id: str, implementation_commit: str) -> dict:
    if review_id != REVIEW_ID:
        raise ExceptionError("this first exception lane is restricted to the exact chassis review")
    active_path = f"{PACKET_ROOT}/REVIEW_OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md"
    archived_path = f"{PACKET_ROOT}/archived/OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md"
    review_text = _read(repo, tree, active_path)
    implementation_text = _read(repo, tree, archived_path)
    if not review_text or not implementation_text:
        raise ExceptionError("current main lacks the exact chassis review or archived implementation packet")
    review = parse_packet(active_path, review_text)
    implementation = parse_packet(archived_path, implementation_text)
    if (review.error or review.workstream != REVIEW_ID or review.kind != "review"
            or review.review_target_workstream != IMPLEMENTATION_ID
            or review.review_target_packet != archived_path):
        raise ExceptionError("chassis review target identity or packet bytes do not match")
    if implementation.error or implementation.workstream != IMPLEMENTATION_ID or implementation.status != "complete":
        raise ExceptionError("chassis implementation is not the exact archived complete target")
    if not re.fullmatch(r"[0-9a-f]{40}", implementation_commit):
        raise ExceptionError("preserved review run lacks one exact implementation commit")
    if subprocess.run(["git", "cat-file", "-e", f"{implementation_commit}^{{commit}}"], cwd=repo).returncode:
        raise ExceptionError("pinned implementation commit is unavailable locally")
    if subprocess.run(["git", "merge-base", "--is-ancestor", implementation_commit, tree], cwd=repo).returncode:
        raise ExceptionError("pinned implementation commit is not part of the current main history")
    outcome = "unresolved"
    outcome_detail = "No review verdict is present; the host-validation recovery remains unresolved."
    # Preserve any archived review truth. A normal PASS stays normal; an
    # exception is only useful when the exact review has not been accepted.
    archived_review_path = f"{PACKET_ROOT}/archived/REVIEW_OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md"
    archived_review_text = _read(repo, tree, archived_review_path)
    if archived_review_text:
        accepted, outcome_name, reason = review_outcome.review_acceptance(
            archived_review_text, implementation_text, REVIEW_ID,
        )
        if accepted:
            raise ExceptionError("the exact chassis review already has an authentic PASS; no exception is needed")
        outcome = outcome_name or "unresolved"
        outcome_detail = reason
    return {
        "review_workstream": REVIEW_ID,
        "implementation_workstream": IMPLEMENTATION_ID,
        "review_packet": active_path,
        "review_packet_sha256": _sha(review_text),
        "implementation_packet": archived_path,
        "implementation_packet_sha256": _sha(implementation_text),
        "implementation_commit": implementation_commit,
        "review_outcome": outcome,
        "review_outcome_detail": outcome_detail,
    }


def plan(repo: Path, review_id: str = REVIEW_ID) -> dict:
    repo = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    main_sha = _git(repo, "rev-parse", "refs/remotes/origin/main")
    remote = _git(repo, "ls-remote", "origin", "refs/heads/main").split()
    if not remote or remote[0] != main_sha:
        raise ExceptionError("cached origin/main is stale; refresh coordination refs before planning")
    common = Path(_git(repo, "rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = (repo / common).resolve()
    review_runs = common / "custodian-review-runs" / review_id
    runs = []
    implementation_commits = set()
    if review_runs.is_dir():
        for run in sorted(p for p in review_runs.iterdir() if p.is_dir()):
            metadata = run / "metadata.json"
            recovery = run / "RECOVERY.md"
            if metadata.is_file():
                metadata_bytes = metadata.read_bytes()
                try:
                    meta = json.loads(metadata_bytes)
                except ValueError as exc:
                    raise ExceptionError(f"malformed preserved review metadata: {run.name}") from exc
                if meta.get("workstream") == review_id:
                    receipt = run / "claim-receipt.json"
                    implementation_commit = meta.get("implementation_commit")
                    if isinstance(implementation_commit, str):
                        implementation_commits.add(implementation_commit)
                    runs.append({
                        "run_id": run.name,
                        "phase": meta.get("phase"),
                        "host_validation_error": meta.get("host_validation_error"),
                        "metadata_sha256": _sha(metadata_bytes),
                        "recovery_sha256": _sha(recovery.read_bytes()) if recovery.is_file() else None,
                        "claim_receipt_sha256": _sha(receipt.read_bytes()) if receipt.is_file() else None,
                        "implementation_commit": implementation_commit,
                    })
    if len(implementation_commits) != 1:
        raise ExceptionError("preserved review runs do not establish one exact implementation commit")
    target = _target_state(repo, "origin/main", review_id, next(iter(implementation_commits)))
    claims = _git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)",
                  "refs/remotes/origin/dispatch-claims").splitlines()
    branches = _git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)",
                    "refs/remotes/origin/agent").splitlines()
    local_claim = next((line.split(" ", 1)[1] for line in claims
                        if line.startswith(f"origin/dispatch-claims/{review_id} ")), None)
    remote_branch = next((line.split(" ", 1)[1] for line in branches
                          if line.startswith(f"origin/agent/{review_id} ")), None)
    local_branches = _git(repo, "for-each-ref", "--format=%(refname:short) %(objectname)",
                          f"refs/heads/agent/{review_id}").splitlines()
    local_branch = local_branches[0].split(" ", 1)[1] if local_branches else None
    worktrees = _git(repo, "worktree", "list", "--porcelain")
    exact_worktree = any(
        f"branch refs/heads/agent/{review_id}" in block
        for block in worktrees.split("\n\n")
    )
    lock_path = common / "custodian-review-runs" / "locks" / f"{review_id}.lock"
    lock_present = lock_path.is_file() and not lock_path.is_symlink()
    lock_held = False
    if lock_present:
        with lock_path.open("rb") as lock_handle:
            try:
                fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                lock_held = True
            else:
                fcntl.flock(lock_handle, fcntl.LOCK_UN)
    dependents = []
    for path in _git(repo, "ls-tree", "-r", "--name-only", "origin/main", "--", PACKET_ROOT).splitlines():
        if not path.endswith(".md") or "/archived/" in path:
            continue
        text = _read(repo, "origin/main", path)
        packet = parse_packet(path, text)
        if review_id in packet.dependencies:
            dependents.append({"workstream": packet.workstream, "path": path})
    result = {
        "schema": "custodian.owner_review_exception_plan.v1",
        "main_sha": main_sha,
        **target,
        "preserved_review_runs": runs,
        "remote_claim_sha": local_claim,
        "remote_agent_branch_sha": remote_branch,
        "local_agent_branch_sha": local_branch,
        "registered_local_review_worktree": exact_worktree,
        "paired_review_lock_file_present": lock_present,
        "paired_review_lock_held": lock_held,
        "dependent_workstreams": dependents,
        "consequence": "Only the named review dependency may be satisfied administratively; original review truth remains unresolved.",
    }
    result["plan_sha256"] = _sha(_json_canonical(result))
    return result


def make_record(plan_value: dict, approval: dict, *, reason: str) -> dict:
    _validate_chat_approval(approval, plan_value["review_workstream"])
    if not reason.strip():
        raise ExceptionError("an explicit owner-exception reason is required")
    if plan_value["review_outcome"] == "passed":
        raise ExceptionError("an owner exception cannot replace or duplicate PASS")
    record = {
        "schema": SCHEMA,
        "disposition": "owner_accepted_with_review_exception",
        "decision": "waived_unresolved",
        "review_workstream": plan_value["review_workstream"],
        "implementation_workstream": plan_value["implementation_workstream"],
        "implementation_commit": plan_value["implementation_commit"],
        "main_sha": plan_value["main_sha"],
        "review_packet": plan_value["review_packet"],
        "review_packet_sha256": plan_value["review_packet_sha256"],
        "implementation_packet": plan_value["implementation_packet"],
        "implementation_packet_sha256": plan_value["implementation_packet_sha256"],
        "original_review_outcome": plan_value["review_outcome"],
        "original_review_outcome_detail": plan_value["review_outcome_detail"],
        "preserved_review_runs": plan_value["preserved_review_runs"],
        "claim_inventory": {
            "remote_dispatch_claim_sha": plan_value["remote_claim_sha"],
            "remote_agent_branch_sha": plan_value["remote_agent_branch_sha"],
            "local_agent_branch_sha": plan_value["local_agent_branch_sha"],
            "registered_worktree": plan_value["registered_local_review_worktree"],
            "paired_review_lock_held": plan_value["paired_review_lock_held"],
        },
        "owner_identity": approval["approver"],
        "authorization_source_url": approval["source_url"],
        "authorization_message_sha256": approval["user_message_sha256"],
        "reason": reason.strip(),
        "claim_retirement": (
            "already_absent"
            if plan_value["remote_claim_sha"] is None and plan_value["remote_agent_branch_sha"] is None
            else "owner_authorized_exact_claim_retirement_pending"
        ),
        "recorded_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    record["record_sha256"] = _sha(_json_canonical(record))
    return record


def verify_record(record: dict, review_id: str, implementation_text: str, review_text: str) -> tuple[bool, str]:
    if not isinstance(record, dict) or record.get("schema") != SCHEMA:
        return False, "owner exception record schema is invalid"
    if record.get("disposition") != "owner_accepted_with_review_exception" or record.get("decision") != "waived_unresolved":
        return False, "owner exception disposition is not the explicit unresolved waiver"
    if record.get("review_workstream") != review_id or review_id != REVIEW_ID:
        return False, "owner exception targets a different review workstream"
    if record.get("implementation_workstream") != IMPLEMENTATION_ID:
        return False, "owner exception targets a different implementation workstream"
    if record.get("review_packet_sha256") != _sha(review_text) or record.get("implementation_packet_sha256") != _sha(implementation_text):
        return False, "owner exception packet bytes are stale or mismatched"
    if record.get("owner_identity") != "project-owner" or not record.get("authorization_source_url"):
        return False, "owner identity or authorization source is missing"
    source = urlsplit(record["authorization_source_url"])
    if (source.scheme != "https" or source.hostname != "chatgpt.com"
            or not re.search(r"/c/[A-Za-z0-9-]+/?$", source.path)):
        return False, "owner exception has no exact ChatGPT authorization conversation"
    if not re.fullmatch(r"[0-9a-f]{40}", record.get("implementation_commit", "")):
        return False, "owner exception does not pin one implementation commit"
    runs = record.get("preserved_review_runs")
    if not isinstance(runs, list) or not runs:
        return False, "owner exception lacks preserved review-run evidence"
    if not any(
        isinstance(run, dict)
        and run.get("implementation_commit") == record.get("implementation_commit")
        and run.get("phase") == "host_validation_recovery"
        and all(re.fullmatch(r"[0-9a-f]{64}", run.get(field, ""))
                for field in ("metadata_sha256", "recovery_sha256", "claim_receipt_sha256"))
        for run in runs
    ):
        return False, "owner exception does not bind the exact unresolved review run"
    if record.get("original_review_outcome") not in {"unresolved", "findings", "human_required"}:
        return False, "owner exception cannot replace a passing or malformed review outcome"
    claim = record.get("claim_inventory")
    if not isinstance(claim, dict):
        return False, "owner exception lacks the exact claim/lock inventory"
    expected_retirement = (
        "already_absent"
        if claim.get("remote_dispatch_claim_sha") is None and claim.get("remote_agent_branch_sha") is None
        else "owner_authorized_exact_claim_retirement_pending"
    )
    if record.get("claim_retirement") != expected_retirement:
        return False, "claim-retirement disposition does not match the exact remote refs"
    if not re.fullmatch(r"[0-9a-f]{64}", record.get("authorization_message_sha256", "")):
        return False, "owner exception has no exact authorization message digest"
    record_sha = record.get("record_sha256")
    unsigned = {key: value for key, value in record.items() if key != "record_sha256"}
    if record_sha != _sha(_json_canonical(unsigned)):
        return False, "owner exception record digest is invalid"
    return True, "owner exception verified; canonical review remains unresolved"


def activation_review_accepted(review_text: str, target_text: str) -> bool:
    """Keep the case waiver inert until its own fresh paired review passes."""
    accepted, outcome, _reason = review_outcome.review_acceptance(
        review_text, target_text, ACTIVATION_REVIEW_ID,
    )
    return accepted and outcome == "passed"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    p_plan = sub.add_parser("plan")
    p_plan.add_argument("--repo", type=Path, default=Path.cwd())
    p_plan.add_argument("--review-workstream", default=REVIEW_ID)
    p_apply = sub.add_parser("apply", help="write the exact authenticated owner decision as a tracked registry record")
    p_apply.add_argument("--repo", type=Path, default=Path.cwd())
    p_apply.add_argument("--plan-json", type=Path, required=True)
    p_apply.add_argument("--approval-json", type=Path, required=True)
    p_apply.add_argument("--plan-sha256", required=True)
    p_apply.add_argument("--reason", required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == "plan":
            result = plan(args.repo, args.review_workstream)
        else:
            repo = Path(_git(args.repo, "rev-parse", "--show-toplevel")).resolve()
            plan_value = json.loads(args.plan_json.read_text(encoding="utf-8"))
            approval = json.loads(args.approval_json.read_text(encoding="utf-8"))
            if args.plan_sha256 != plan_value.get("plan_sha256"):
                raise ExceptionError("supplied plan digest does not match the saved plan")
            if plan_value.get("plan_sha256") != _sha(_json_canonical({k: v for k, v in plan_value.items() if k != "plan_sha256"})):
                raise ExceptionError("owner exception plan digest is invalid")
            with common_mutex(repo, timeout_seconds=0):
                fresh = plan(repo, plan_value["review_workstream"])
                if fresh.get("plan_sha256") != args.plan_sha256:
                    raise ExceptionError("owner exception plan is stale; recompute and obtain owner approval again")
                result = make_record(fresh, approval, reason=args.reason)
                path = repo / REGISTRY / f"{fresh['review_workstream']}.json"
                if path.is_symlink():
                    raise ExceptionError("owner exception target path is a symlink")
                if path.exists():
                    existing = json.loads(path.read_text(encoding="utf-8"))
                    valid, _ = verify_record(
                        existing, fresh["review_workstream"],
                        _read(repo, "origin/main", fresh["implementation_packet"]),
                        _read(repo, "origin/main", fresh["review_packet"]),
                    )
                    def stable(value: dict) -> dict:
                        return {key: item for key, item in value.items()
                                if key not in {"record_sha256", "recorded_utc"}}
                    if valid and stable(existing) == stable(result):
                        print(json.dumps({"result": "identical_owner_exception_already_applied", "record": existing}, indent=2, sort_keys=True))
                        return 0
                    raise ExceptionError("a conflicting owner exception already exists for this review")
                path.parent.mkdir(parents=True, exist_ok=True)
                with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent,
                                                 prefix=f".{path.name}.", suffix=".tmp", delete=False) as tmp:
                    tmp.write(json.dumps(result, indent=2, sort_keys=True) + "\n")
                    tmp.flush()
                    os.fsync(tmp.fileno())
                    temporary = Path(tmp.name)
                os.replace(temporary, path)
                result = {"result": "owner_exception_record_written", "path": str(path), "record": result}
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, ExceptionError) as exc:
        print(f"owner exception error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
