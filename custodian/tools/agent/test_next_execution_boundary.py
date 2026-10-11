#!/usr/bin/env python3
"""Focused policy tests for next_execution_boundary.py."""
from __future__ import annotations

import unittest
import json
import subprocess
import tempfile
from pathlib import Path

import next_execution_boundary as boundary

ROOT = Path(__file__).resolve().parents[3]


class BoundaryTests(unittest.TestCase):
    def test_unqualified_request_is_exactly_one_pair(self):
        request = boundary.normalize_request({})
        self.assertEqual(request["mode"], "single-pair")
        self.assertEqual(request["max_pairs"], 1)

    def test_continuous_chain_requires_a_positive_explicit_budget(self):
        for maximum in (None, 0, -1, True, "3"):
            with self.subTest(max_pairs=maximum), self.assertRaises(boundary.BoundaryError):
                boundary.normalize_request({"mode": "continuous-chain", "max_pairs": maximum})
        self.assertEqual(
            boundary.normalize_request({"mode": "continuous-chain", "max_pairs": 3})["max_pairs"],
            3,
        )

    def test_skill_exposes_single_pair_default_and_explicit_bounded_mode(self):
        skill = " ".join((ROOT / ".agents/skills/custodian-next/SKILL.md").read_text().split())
        self.assertIn("An unqualified invocation is `single-pair`", skill)
        self.assertIn("explicit positive `max_pairs`", skill)
        self.assertIn("does not select packets or claim work", skill)
        self.assertIn("paired_review_runner.py", skill)
        self.assertIn("In `single-pair`, stop", skill)

    def test_receipt_rejects_non_finite_elapsed_and_unaccepted_review(self):
        args = dict(
            invocation_id="run-1", workstream="done-task", pair_index=1, max_pairs=2,
            pair_completed=True, phase="pair-boundary", landed_sha="abc123",
            review_status="passed", elapsed_seconds=1.0,
            validation_summary="passed", next_eligibility="none",
        )
        with self.assertRaises(boundary.BoundaryError):
            boundary.receipt(**{**args, "elapsed_seconds": float("nan")})
        with self.assertRaises(boundary.BoundaryError):
            boundary.receipt(**{**args, "review_status": "pending"})

    def test_pause_resume_counts_completed_pairs_not_review_stages(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 4},
            {"completed_pairs": 2, "phase": "review", "current_workstream": "pair-three"},
        )
        self.assertEqual(result["action"], "run_paired_review")
        self.assertEqual(result["completed_pairs"], 2)
        self.assertEqual(result["remaining_pairs"], 2)

    def test_verified_active_worktree_resumes_even_with_global_request(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 5, "explicit_general_next": True},
            {"active_claim": "verified", "current_workstream": "active-task", "phase": "start"},
        )
        self.assertEqual(result["action"], "resume_current")
        self.assertEqual(result["workstream"], "active-task")

    def test_stale_last_claim_requires_audit_and_never_reclaims(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 5, "explicit_general_next": True},
            {"active_claim": "stale", "phase": "start", "general_candidate_eligible": True},
        )
        self.assertEqual(result["action"], "stop")
        self.assertTrue(result["reconcile_required"])

    def test_unambiguous_named_handoff_uses_exact_successor(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 5},
            {"phase": "pair-boundary", "current_workstream": "done-task", "review": {"required": False},
             "handoff": {"next_workstream": "candidate-a", "eligible": True}},
        )
        self.assertEqual(result["action"], "claim_named_successor")

    def test_ambiguous_handoff_stops_without_guessing(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 5},
            {"phase": "pair-boundary", "current_workstream": "done-task", "review": {"required": False},
             "handoff": {"ambiguous": True, "next_workstream": "candidate-a", "eligible": True}},
        )
        self.assertEqual(result["action"], "stop")
        self.assertEqual(result["reason"], "handoff_ambiguous")

    def test_review_blocked_stops_before_any_general_fallback(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 5, "explicit_general_next": True},
            {"phase": "pair-boundary", "current_workstream": "active-task", "review": {"required": True, "status": "blocked"},
             "general_candidate_eligible": True},
        )
        self.assertEqual(result["action"], "stop")
        self.assertEqual(result["reason"], "paired_review_blocked")

    def test_findings_within_review_cycle_resume_the_same_pair(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 3},
            {"phase": "pair-boundary", "current_workstream": "active-task",
             "review": {"required": True, "status": "findings", "correction_available": True}},
        )
        self.assertEqual(result["action"], "resume_current")
        self.assertEqual(result["completed_pairs"], 0)

    def test_no_successor_uses_explicit_general_fallback_once(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 3, "explicit_general_next": True},
            {"phase": "pair-boundary", "completed_pairs": 0, "current_workstream": "done-task",
             "review": {"required": True, "status": "passed"}, "handoff": {"next_workstream": None},
             "general_candidate_eligible": True, "general_candidate_kind": "implementation"},
        )
        self.assertEqual(result["action"], "claim_general_next")
        self.assertEqual(result["completed_pairs"], 1)

    def test_general_fallback_rejects_review_or_no_candidate(self):
        base = {"phase": "pair-boundary", "current_workstream": "done-task",
                "review": {"required": False}, "handoff": {"next_workstream": None}}
        for facts in (
            {**base, "general_candidate_eligible": False},
            {**base, "general_candidate_eligible": True, "general_candidate_kind": "review"},
        ):
            result = boundary.evaluate(
                {"mode": "continuous-chain", "max_pairs": 3, "explicit_general_next": True}, facts
            )
            self.assertEqual(result["action"], "stop")

    def test_dependency_chain_claims_only_dispatcher_verified_predecessor(self):
        result = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 4},
            {"phase": "pair-boundary", "current_workstream": "done-task", "review": {"required": False},
             "handoff": {"next_workstream": "successor", "eligible": False,
                         "eligible_predecessor": "predecessor", "predecessor_eligible": True}},
        )
        self.assertEqual(result["action"], "claim_dependency_predecessor")
        self.assertEqual(result["workstream"], "predecessor")

    def test_single_pair_stops_after_accepted_review(self):
        result = boundary.evaluate(
            {"mode": "single-pair"},
            {"phase": "pair-boundary", "current_workstream": "done-task", "review": {"required": False},
             "handoff": {"next_workstream": "successor", "eligible": True}},
        )
        self.assertEqual(result["action"], "stop")
        self.assertEqual(result["reason"], "pair_budget_reached")

    def test_human_and_manual_gates_stop(self):
        for gate, expected in (("human_decision", "human_decision_required"),
                               ("manual_dispatch", "manual_dispatch_hold"),
                               ("refresh_required", "planning_refresh_required")):
            result = boundary.evaluate(
                {"mode": "continuous-chain", "max_pairs": 3},
                {"phase": "pair-boundary", "current_workstream": "done-task", "review": {"required": False},
                 "handoff": {"next_workstream": "successor", "eligible": True, gate: True}},
            )
            self.assertEqual(result["action"], "stop")
            self.assertEqual(result["reason"], expected)

    def test_boundary_receipt_has_required_compact_fields(self):
        result = boundary.receipt(
            invocation_id="run-1", workstream="done-task", pair_index=1, max_pairs=3,
            pair_completed=True, phase="pair-boundary", landed_sha="abc123",
            review_status="passed", elapsed_seconds=61.234,
            validation_summary="changed sweep passed", next_eligibility="successor ready",
        )
        self.assertEqual(result["schema"], boundary.SCHEMA)
        self.assertEqual(result["elapsed_seconds"], 61.23)
        self.assertEqual(result["landed_sha"], "abc123")
        self.assertEqual(result["invocation_id"], "run-1")

    def test_invocation_progress_recovers_completed_pairs_from_run_traces(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            subprocess.run(["git", "init", str(repo)], check=True, capture_output=True)
            trace_dir = repo / ".git/custodian-workflow/traces"
            first_data = None
            for workstream in ("first-task", "second-task"):
                target = trace_dir / workstream / "run.jsonl"
                target.parent.mkdir(parents=True, exist_ok=True)
                data = {"invocation_id": "run-15", "workstream": workstream,
                        "pair_completed": True, "landed_sha": "abc123", "review_status": "passed"}
                target.write_text(json.dumps({"event": "execution_boundary_receipt", "data": data}) + "\n")
                if workstream == "first-task":
                    first_data = data
            repeated = trace_dir / "first-task" / "resume.jsonl"
            repeated.write_text(json.dumps({"event": "execution_boundary_receipt", "data": first_data}) + "\n")
            progress = boundary.invocation_progress(repo, "run-15")
            self.assertEqual(progress["completed_pairs"], 2)
            self.assertEqual({item["workstream"] for item in progress["pairs"]}, {"first-task", "second-task"})

    def test_blocked_packet_can_fall_back_only_for_an_explicit_general_request(self):
        facts = {"phase": "blocked", "completed_pairs": 0, "handoff": {},
                 "general_candidate_eligible": True, "general_candidate_kind": "implementation"}
        allowed = boundary.evaluate(
            {"mode": "continuous-chain", "max_pairs": 3, "explicit_general_next": True}, facts
        )
        denied = boundary.evaluate({"mode": "continuous-chain", "max_pairs": 3}, facts)
        self.assertEqual(allowed["action"], "claim_general_next")
        self.assertEqual(denied["action"], "stop")


if __name__ == "__main__":
    unittest.main()
