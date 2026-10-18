#!/usr/bin/env python3
"""Deterministic, no-repository-mutation tests for queue_frontier."""
import copy
import unittest

from custodian.tools.agent.queue_frontier import analyze


def row(wid, classification, reasons=(), eligible=False, claimed=False):
    return {
        "workstream": wid, "path": wid + ".md",
        "actual_class": classification, "reasons": list(reasons),
        "claimed": claimed, "claim_next_eligible": eligible,
    }


class QueueFrontierTests(unittest.TestCase):
    def test_shared_dependency_and_eligible_boundary(self):
        audit = {
            "schema": "custodian.task_packet_queue_audit.v1",
            "packets": [
                row("root", "ready_auto", eligible=True),
                row("child", "dependency_lock_blocked", ["dependency not archived complete: root"]),
                row("grandchild", "dependency_lock_blocked", ["dependency not archived complete: child"]),
                row("independent", "ready_auto", eligible=True),
            ], "claimable_auto_count": 2,
        }
        snapshot = copy.deepcopy(audit)
        result = analyze(audit)
        self.assertEqual(audit, snapshot)
        self.assertEqual(result["claimable_auto"], 2)
        entry = next(x for x in result["top_blocking_frontiers"] if x["root"] == "root")
        self.assertEqual(entry["downstream_packet_count"], 2)

    def test_claimed_lock_and_invalid_do_not_override_evidence(self):
        audit = {"packets": [
            row("holder", "claimed", ["already claimed by published agent branch"], claimed=True),
            row("waiting", "dependency_lock_blocked", ["lock: graphics held by holder"]),
            row("invalid", "invalid_recovery", ["invalid queue contract: broken"]),
            row("after-invalid", "dependency_lock_blocked", ["dependency not archived complete: invalid"]),
        ]}
        results = {x["root"]: x for x in analyze(audit)["top_blocking_frontiers"]}
        self.assertEqual(results["holder"]["downstream_packet_count"], 2)
        self.assertEqual(results["invalid"]["downstream_packet_count"], 2)
        self.assertIn("original-owner", results["holder"]["cause"])

    def test_review_findings_and_cycle_preserved(self):
        audit = {"packets": [
            row("a", "dependency_lock_blocked", ["dependency not archived complete: b"]),
            row("b", "dependency_lock_blocked", ["dependency not archived complete: a"]),
            row("rejected", "dependency_lock_blocked",
                ["dependency review not accepted: review-ancestor (findings outcome)"]),
        ]}
        entries = analyze(audit)["top_blocking_frontiers"]
        self.assertTrue(any("cycle" in e["cause"] for e in entries))
        self.assertTrue(any(e["root"] == "review-ancestor"
                            and "genuine verdict" in e["cause"] for e in entries))

    def test_malformed_audit_fails_closed(self):
        with self.assertRaises(ValueError):
            analyze({"packet": []})


if __name__ == "__main__":
    unittest.main()
