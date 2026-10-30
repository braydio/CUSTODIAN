"""Focused unit checks for read-only task administrator contracts."""
import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from custodian.tools.agent import task_administrator as admin


class AdministratorTests(unittest.TestCase):
    def test_proposal_schema_is_non_executable_and_evidence_bound(self):
        good = {"schema": "custodian.task_admin.proposal.v1", "action": "DIAGNOSE",
                "workstream": "sample", "evidence_sha256": "a" * 64,
                "reason": "blocked", "next_check": "inspect receipt"}
        self.assertEqual(admin.validate_proposal(good)["action"], "DIAGNOSE")
        for bad in ({**good, "action": "DISPATCH"}, {**good, "shell": "rm -rf /"},
                    {**good, "evidence_sha256": "x"}):
            with self.assertRaises(ValueError): admin.validate_proposal(bad)

    def test_event_ledger_deduplicates_and_rejects_corruption(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp); (repo / ".git").mkdir()
            with patch.object(admin, "common_dir", return_value=repo / ".git"):
                snapshot = {"schema": admin.SCHEMA, "disk": {"pressure": {"severity": "normal"}}}
                events, changed = admin.record_snapshot(repo, snapshot)
                self.assertTrue(changed); self.assertEqual(len(events), 1)
                events, changed = admin.record_snapshot(repo, snapshot)
                self.assertFalse(changed); self.assertEqual(len(events), 1)
                path = admin._event_path(repo)
                row = json.loads(path.read_text()); row["attention"] = [{"forged": True}]
                path.write_text(json.dumps(row) + "\n"); path.chmod(0o600)
                with self.assertRaises(admin.ObserverError): admin.record_snapshot(repo, snapshot)

    def test_clock_only_source_changes_do_not_wake_operator(self):
        first = {"schema": admin.SCHEMA, "generated_utc": "one", "dispatch": {"generated_at": "one", "rows": [1]}}
        second = {"schema": admin.SCHEMA, "generated_utc": "two", "dispatch": {"generated_at": "two", "rows": [1]}}
        self.assertEqual(admin._stable_evidence(first), admin._stable_evidence(second))
        a = {"disk": {"pressure": {"available_bytes": 12 * 1024**3 + 100, "used_percent": 92.0, "severity": "high"}}}
        b = {"disk": {"pressure": {"available_bytes": 12 * 1024**3 + 500, "used_percent": 92.1, "severity": "high"}}}
        self.assertEqual(admin._stable_evidence(a), admin._stable_evidence(b))

    def test_disk_pressure_frontier_includes_safe_candidate_count(self):
        result = admin._attention({"disk": {"pressure": {"severity": "critical", "available_bytes": 10},
                                             "retirement": {"eligible": [{"path": "safe"}], "blocked": [{"path": "protected"}]}}})
        self.assertEqual(result[0]["safe_retirement_candidates"], 1)
        self.assertEqual(result[0]["retirement_blockers"], 1)
        self.assertIn("Only the existing GC authority", result[0]["cause"])

    def test_duplicate_observer_lock_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp); (repo / ".git").mkdir()
            with patch.object(admin, "common_dir", return_value=repo / ".git"):
                first = admin.acquire_observer_lock(repo)
                try:
                    with self.assertRaises(admin.ObserverError): admin.acquire_observer_lock(repo)
                finally:
                    os.close(first)

    def test_unchanged_poll_does_not_call_codex_and_provider_failure_is_unknown(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp); (repo / ".git").mkdir()
            snapshot = {"schema": admin.SCHEMA, "generated_utc": "first", "source_health": {},
                        "queue_frontier": {}, "disk": {}, "packets": [], "origin_main_sha": "abc"}
            with patch.object(admin, "common_dir", return_value=repo / ".git"), \
                 patch.object(admin, "collect", side_effect=[snapshot, {**snapshot, "generated_utc": "second"}]), \
                 patch.object(admin, "run_operator", return_value={"status": "unavailable"}) as operator:
                admin.observe(repo, reason=True)
                admin.observe(repo, reason=True)
                operator.assert_called_once()
            with patch.object(admin.shutil, "which", return_value=None), \
                 patch.object(admin, "common_dir", return_value=repo / ".git"):
                self.assertEqual(admin.run_operator(repo, snapshot)["status"], "unavailable")

    def test_daily_operator_budget_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp); (repo / ".git").mkdir()
            with patch.object(admin, "common_dir", return_value=repo / ".git"):
                for _ in range(admin.MAX_TURNS_PER_DAY):
                    admin._record_operator(repo, {"status": "rejected"}, "a" * 64)
                with patch.object(admin.shutil, "which", return_value="/fake/codex"):
                    self.assertEqual(admin.run_operator(repo, {"schema": admin.SCHEMA})["status"], "budget_exhausted")


if __name__ == "__main__": unittest.main()
