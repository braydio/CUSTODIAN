#!/usr/bin/env python3
"""Pure execution-boundary policy for the CUSTODIAN Next skill.

This module does not inspect Git, select packets, claim work, or run reviews.
Callers supply facts from the dispatcher, the active worktree, and the durable
packet handoff; those authorities remain responsible for their own domains.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any


SCHEMA = "custodian.next_execution_boundary.v1"
MODES = {"single-task", "continuous-chain"}
PHASES = {"start", "implementation", "task-boundary", "blocked"}
REVIEW_STATUSES = {"none", "pending", "passed", "findings", "human_required", "blocked"}


class BoundaryError(ValueError):
    """The invocation or facts are malformed or internally inconsistent."""


def _nonnegative_int(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise BoundaryError(f"{label} must be a non-negative integer")
    return value


def normalize_request(raw: dict[str, Any]) -> dict[str, Any]:
    """Normalize the invocation budget; an unqualified request is one pair."""
    mode = raw.get("mode", "single-task")
    if mode not in MODES:
        raise BoundaryError("mode must be single-task or continuous-chain")
    if mode == "single-task":
        maximum = 1
    else:
        maximum = raw.get("max_tasks")
        if isinstance(maximum, bool) or not isinstance(maximum, int) or maximum <= 0:
            raise BoundaryError("continuous-chain requires a positive max_tasks")

    scope = raw.get("scope")
    if scope is not None:
        if not isinstance(scope, list) or any(
            not isinstance(item, str) or not item.strip() for item in scope
        ):
            raise BoundaryError("scope must be null or a list of workstream IDs")
        scope = sorted(set(item.strip() for item in scope))

    general_next = raw.get("explicit_general_next", False)
    if not isinstance(general_next, bool):
        raise BoundaryError("explicit_general_next must be a boolean")
    return {
        "schema": SCHEMA,
        "mode": mode,
        "max_tasks": maximum,
        "scope": scope,
        "explicit_general_next": general_next,
    }


def _stop(request: dict[str, Any], completed: int, reason: str, **extra: Any) -> dict[str, Any]:
    return {
        "schema": SCHEMA,
        "action": "stop",
        "mode": request["mode"],
        "max_tasks": request["max_tasks"],
        "completed_tasks": completed,
        "remaining_tasks": max(0, request["max_tasks"] - completed),
        "reason": reason,
        **extra,
    }


def _claim(request: dict[str, Any], completed: int, action: str, workstream: str | None = None) -> dict[str, Any]:
    return {
        "schema": SCHEMA,
        "action": action,
        "mode": request["mode"],
        "max_tasks": request["max_tasks"],
        "completed_tasks": completed,
        "remaining_tasks": max(0, request["max_tasks"] - completed),
        "workstream": workstream,
        "reason": "dispatcher must verify eligibility and remains claim authority",
    }


def evaluate(request_data: dict[str, Any], facts: dict[str, Any]) -> dict[str, Any]:
    """Return one safe next action from normalized dispatcher/workstream facts.

    A task advances at a durable checkpoint boundary. Review is optional and does
    not define the task budget.
    """
    request = normalize_request(request_data)
    completed = _nonnegative_int(facts.get("completed_tasks", 0), "completed_tasks")
    if completed >= request["max_tasks"]:
        return _stop(request, completed, "task_budget_reached")

    phase = facts.get("phase", "start")
    if phase not in PHASES:
        raise BoundaryError(f"phase must be one of {', '.join(sorted(PHASES))}")

    active = facts.get("active_claim", "none")
    if active not in {"none", "verified", "stale", "ambiguous"}:
        raise BoundaryError("active_claim must be none, verified, stale, or ambiguous")
    current = facts.get("current_workstream")
    if current is not None and (not isinstance(current, str) or not current.strip()):
        raise BoundaryError("current_workstream must be a non-empty ID or null")
    if active == "ambiguous":
        return _stop(request, completed, "ownership_ambiguous", reconcile_required=True)
    if active == "stale":
        return _stop(request, completed, "stale_claim_requires_dispatch_audit", reconcile_required=True)
    if active == "verified":
        if not current:
            raise BoundaryError("verified active claim requires current_workstream")
        return {
            "schema": SCHEMA,
            "action": "resume_current",
            "mode": request["mode"],
            "max_tasks": request["max_tasks"],
            "completed_tasks": completed,
            "remaining_tasks": request["max_tasks"] - completed,
            "workstream": current,
            "reason": "verified active claim takes precedence over any new claim",
        }

    if phase == "implementation":
        if not current:
            raise BoundaryError(f"{phase} phase requires current_workstream")
        return {
            "schema": SCHEMA,
            "action": "resume_current",
            "mode": request["mode"],
            "max_tasks": request["max_tasks"],
            "completed_tasks": completed,
            "remaining_tasks": request["max_tasks"] - completed,
            "workstream": current,
            "reason": "finish the active implementation before considering another claim",
        }

    if phase == "task-boundary":
        if not current:
            raise BoundaryError("task-boundary phase requires current_workstream")
        completed += 1

    if completed >= request["max_tasks"]:
        return _stop(request, completed, "task_budget_reached", completed_workstream=current)

    if phase == "blocked":
        return _stop(request, completed, "blocked_workstream", blocked_workstream=current)

    handoff = facts.get("handoff", {})
    if not isinstance(handoff, dict):
        raise BoundaryError("handoff must be an object")
    if handoff.get("ambiguous") is True:
        return _stop(request, completed, "handoff_ambiguous", blocked_workstream=current)
    next_id = handoff.get("next_workstream")
    if next_id is not None and (not isinstance(next_id, str) or not next_id.strip()):
        raise BoundaryError("handoff.next_workstream must be a non-empty ID or null")
    gates = [
        label for key, label in (
            ("refresh_required", "planning_refresh_required"),
            ("manual_dispatch", "manual_dispatch_hold"),
            ("human_decision", "human_decision_required"),
        ) if handoff.get(key) is True
    ]
    blocker = handoff.get("technical_blocker")
    if blocker:
        gates.append("technical_blocker")
    if gates:
        return _stop(request, completed, gates[0], blockers=gates, blocked_workstream=next_id or current)
    if phase == "blocked":
        return _stop(request, completed, "blocked_workstream", blocked_workstream=current)

    scope = request["scope"]
    if next_id and scope is not None and next_id not in scope:
        return _stop(request, completed, "successor_outside_scope", next_workstream=next_id)
    if next_id and handoff.get("eligible") is True:
        kind = handoff.get("kind", "implementation")
        if kind != "implementation":
            return _stop(request, completed, "named_successor_is_not_an_implementation", next_workstream=next_id)
        return _claim(request, completed, "claim_named_successor", next_id)

    predecessor = handoff.get("eligible_predecessor")
    if next_id and predecessor and handoff.get("predecessor_eligible") is True:
        if not isinstance(predecessor, str) or not predecessor.strip():
            raise BoundaryError("handoff.eligible_predecessor must be a non-empty ID")
        if scope is not None and predecessor not in scope:
            return _stop(request, completed, "predecessor_outside_scope", next_workstream=predecessor)
        return _claim(request, completed, "claim_dependency_predecessor", predecessor)
    if next_id:
        reason = "named_successor_not_eligible"
        next_workstream = next_id
    else:
        reason = "no_same_series_successor"
        next_workstream = None

    if request["explicit_general_next"] and facts.get("general_candidate_eligible") is True:
        if facts.get("general_candidate_kind", "implementation") != "implementation":
            return _stop(request, completed, "general_candidate_is_not_an_implementation")
        return _claim(request, completed, "claim_general_next", None)
    return _stop(request, completed, reason, next_workstream=next_workstream)


def receipt(*, invocation_id: str, workstream: str, task_index: int, max_tasks: int,
            task_checkpointed: bool, phase: str, checkpoint_sha: str | None,
            review_status: str = "not-run", elapsed_seconds: float, validation_summary: str,
            next_eligibility: str) -> dict[str, Any]:
    """Build a compact, schema-checked task-boundary receipt for RunTrace."""
    if (not isinstance(invocation_id, str) or not invocation_id.strip()
            or not isinstance(workstream, str) or not workstream.strip()
            or phase not in {"implementation", "task-boundary", "blocked"}):
        raise BoundaryError("receipt requires an invocation ID, workstream, and valid phase")
    if _nonnegative_int(task_index, "task_index") < 1:
        raise BoundaryError("task_index must be at least one")
    if isinstance(max_tasks, bool) or not isinstance(max_tasks, int) or max_tasks <= 0 or task_index > max_tasks:
        raise BoundaryError("task_index must fit a positive max_tasks budget")
    if not isinstance(task_checkpointed, bool):
        raise BoundaryError("task_checkpointed must be a boolean")
    if checkpoint_sha is not None and not isinstance(checkpoint_sha, str):
        raise BoundaryError("checkpoint_sha must be a string or null")
    if (isinstance(elapsed_seconds, bool) or not isinstance(elapsed_seconds, (int, float))
            or not math.isfinite(elapsed_seconds) or elapsed_seconds < 0):
        raise BoundaryError("elapsed_seconds must be a finite non-negative number")
    if not all(isinstance(item, str) for item in (review_status, validation_summary, next_eligibility)):
        raise BoundaryError("review_status, validation_summary and next_eligibility must be strings")
    return {"schema": SCHEMA, "invocation_id": invocation_id.strip(), "workstream": workstream.strip(),
            "task_index": task_index, "max_tasks": max_tasks, "task_checkpointed": task_checkpointed,
            "phase": phase, "checkpoint_sha": checkpoint_sha, "review_status": review_status,
            "elapsed_seconds": round(elapsed_seconds, 2), "validation_summary": validation_summary.strip(),
            "next_eligibility": next_eligibility.strip()}

def invocation_progress(repo: Path, invocation_id: str) -> dict[str, Any]:
    """Recover checkpointed task count from local durable RunTrace records."""
    if not invocation_id.strip():
        raise BoundaryError("invocation_id must be non-empty")
    from workflow_control import common_dir
    trace_root = common_dir(repo) / "custodian-workflow" / "traces"
    checkpointed: dict[str, dict[str, Any]] = {}
    if trace_root.exists():
        for path in sorted(trace_root.glob("*/*.jsonl")):
            try:
                for line in path.read_text(encoding="utf-8").splitlines():
                    event = json.loads(line); data = event.get("data", {})
                    if event.get("event") == "execution_boundary_receipt" and data.get("invocation_id") == invocation_id and data.get("task_checkpointed") is True:
                        checkpointed[str(data["workstream"])] = {"workstream": data["workstream"],
                            "checkpoint_sha": data.get("checkpoint_sha"), "review_status": data.get("review_status", "not-run")}
            except (OSError, json.JSONDecodeError, AttributeError, KeyError, TypeError):
                continue
    tasks = sorted(checkpointed.values(), key=lambda item: item["workstream"])
    return {"schema": SCHEMA, "invocation_id": invocation_id, "completed_tasks": len(tasks), "tasks": tasks}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    evaluate_parser = subs.add_parser("evaluate", help="evaluate one routing boundary from facts")
    evaluate_parser.add_argument("--state", type=Path, help="JSON with request and facts; defaults to stdin")
    receipt_parser = subs.add_parser("record-receipt", help="append a structured receipt to the active RunTrace")
    receipt_parser.add_argument("--invocation-id", required=True)
    receipt_parser.add_argument("--workstream", required=True)
    receipt_parser.add_argument("--task-index", type=int, required=True)
    receipt_parser.add_argument("--max-tasks", type=int, required=True)
    receipt_parser.add_argument("--task-checkpointed", choices=("true", "false"), required=True)
    receipt_parser.add_argument("--phase", choices=("implementation", "task-boundary", "blocked"), required=True)
    receipt_parser.add_argument("--checkpoint-sha")
    receipt_parser.add_argument("--review-status", required=True)
    receipt_parser.add_argument("--elapsed-seconds", type=float, required=True)
    receipt_parser.add_argument("--validation-summary", required=True)
    receipt_parser.add_argument("--next-eligibility", required=True)
    progress_parser = subs.add_parser("progress", help="recover completed task checkpoints for an invocation from RunTrace")
    progress_parser.add_argument("--invocation-id", required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == "evaluate":
            raw = json.loads(args.state.read_text() if args.state else sys.stdin.read())
            if not isinstance(raw, dict) or not isinstance(raw.get("request", {}), dict) or not isinstance(raw.get("facts", {}), dict):
                raise BoundaryError("input must contain request and facts objects")
            result = evaluate(raw.get("request", {}), raw.get("facts", {}))
            print(json.dumps(result, sort_keys=True))
            return 0

        if args.command == "progress":
            print(json.dumps(invocation_progress(Path.cwd().resolve(), args.invocation_id), sort_keys=True))
            return 0

        data = receipt(
            invocation_id=args.invocation_id,
            workstream=args.workstream,
            task_index=args.task_index,
            max_tasks=args.max_tasks,
            task_checkpointed=args.task_checkpointed == "true",
            phase=args.phase,
            checkpoint_sha=args.checkpoint_sha,
            review_status=args.review_status,
            elapsed_seconds=args.elapsed_seconds,
            validation_summary=args.validation_summary,
            next_eligibility=args.next_eligibility,
        )
        from workflow_control import RunTrace

        repo = Path.cwd().resolve()
        trace = RunTrace.resume(repo, str(data.get("workstream", "")))
        trace.record("execution_boundary_receipt", **data)
        published = trace.publish()
        print(json.dumps({**data, "diagnostics_published": published}, sort_keys=True))
        return 0
    except (OSError, json.JSONDecodeError, BoundaryError) as error:
        print(f"next_execution_boundary: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
