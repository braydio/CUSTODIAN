"""Read-only census tests using isolated temporary Git repositories."""

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("worktree_backlog_census.py")
SPEC = importlib.util.spec_from_file_location("worktree_backlog_census", SCRIPT)
census_tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(census_tool)


def git(cwd: Path, *args: str) -> str:
    proc = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if proc.returncode:
        raise AssertionError(proc.stderr)
    return proc.stdout.strip()


class CensusTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote))
        git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Census Test")
        git(self.repo, "config", "user.email", "census@example.test")
        (self.repo / "base").write_text("base\n")
        (self.repo / "custodian/docs/ai_context/task_packets").mkdir(parents=True)
        git(self.repo, "add", ".")
        git(self.repo, "commit", "-m", "base")
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "fetch", "origin")
        self.workstream = self.base / "workstream"
        git(self.repo, "worktree", "add", "-b", "agent/sample-work", str(self.workstream), "origin/main")
        self.detached = self.base / "detached-support"
        git(self.repo, "worktree", "add", "--detach", str(self.detached), "origin/main")
        self.packet = self.repo / "custodian/docs/ai_context/task_packets/SAMPLE_WORK.md"
        self.packet.write_text("# Packet\n\n- Workstream: `sample-work`\n- Status: `ready`\n- Dispatch: `auto`\n")
        git(self.repo, "add", str(self.packet.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "packet")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        claim_sha = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "update-ref", "refs/remotes/origin/dispatch-claims/interrupted-sample", claim_sha)
        # Keep a matching packet audit fixture so these tests exercise actual
        # git worktree/status/ancestry reads without running queue policy twice.
        self.audit = {"schema": "custodian.task_packet_queue_audit.v1", "raw_active_markdown_count": 1,
                      "managed_packet_count": 1, "claimable_auto_count": 0,
                      "class_counts": {"claimed": 1}, "interrupted_dispatch_claim_count": 0,
                      "claim_only_orphan_dispatch_claim_count": 0,
                      "packets": [{"workstream": "sample-work", "path": "custodian/docs/ai_context/task_packets/SAMPLE_WORK.md",
                                   "kind": "implementation", "status": "ready", "actual_class": "claimed",
                                   "reasons": [], "paired_review_workstream": "review-sample-work"}],
                      "remote_agent_branches": [{"workstream": "sample-work", "head": git(self.repo, "rev-parse", "agent/sample-work"), "remote_branch_exists": False}],
                      "remote_dispatch_claims": [{"workstream": "interrupted-sample", "ref": "origin/dispatch-claims/interrupted-sample",
                                                  "head": claim_sha, "agent_branch_exists": False,
                                                  "recovery_disposition": "protected_claim_without_agent_branch"}]}

    def tearDown(self):
        for record in git(self.repo, "worktree", "list", "--porcelain").split("\n\n"):
            if record.startswith("worktree "):
                path = record.splitlines()[0].removeprefix("worktree ")
                if Path(path).resolve() != self.repo.resolve():
                    git(self.repo, "worktree", "remove", "--force", path)
        self.temp.cleanup()

    def _census(self):
        original = census_tool.subprocess.run

        def run(args, *pos, **kwargs):
            if len(args) > 1 and str(args[1]).endswith("dispatch.py"):
                return subprocess.CompletedProcess(args, 0, json.dumps(self.audit).encode(), b"")
            return original(args, *pos, **kwargs)

        with patch.object(census_tool.subprocess, "run", side_effect=run):
            return census_tool.census(self.repo)

    def test_attached_dirty_and_ahead_are_counted_without_paths(self):
        git(self.workstream, "checkout", "-b", "agent/sample-work") if git(self.workstream, "branch", "--show-current") == "" else None
        (self.workstream / ".gd.uid").write_text("private uid\n")
        (self.workstream / "changed").write_text("dirty\n")
        git(self.workstream, "add", "changed")
        git(self.workstream, "commit", "-m", "ahead")
        report = self._census()
        row = next(item for item in report["worktrees"] if item["worktree_path"] == str(self.workstream.resolve()))
        self.assertEqual(row["ahead_count"], 1)
        self.assertGreaterEqual(row["staged_count"], 0)
        self.assertEqual(row["untracked_count"], 1)
        self.assertEqual(row["classification"], "DIRTY_OR_UNIQUE_PRESERVE_FIRST")
        self.assertNotIn(".gd.uid", json.dumps(report))
        self.assertEqual(len(row["dirtiness_fingerprint_or_blocker"]), 64)

    def test_porcelain_counts_and_hash_are_stable(self):
        raw = b"1 .M N... 100644 100644 100644 abc abc path\0? local.uid\0"
        self.assertEqual(census_tool.status_counts(raw), (0, 1, 1, census_tool.hashlib.sha256(raw).hexdigest()))

    def test_duplicate_and_malformed_worktree_records_fail_closed(self):
        with self.assertRaisesRegex(census_tool.CensusError, "duplicate canonical"):
            census_tool.parse_worktrees(b"worktree /tmp/a\nHEAD " + b"a" * 40 + b"\n\nworktree /tmp/../tmp/a\nHEAD " + b"b" * 40 + b"\n\n")
        with self.assertRaisesRegex(census_tool.CensusError, "malformed"):
            census_tool.status_counts(b"1 .M malformed\0")

    def test_malformed_packet_identity_is_reported_not_merged(self):
        audit = {"packets": [{"workstream": None, "path": None, "actual_class": "invalid_recovery"}]}
        identities, invalid = census_tool.packet_index(self.repo, audit)
        self.assertEqual(identities, {})
        self.assertEqual(len(invalid), 1)
        self.assertEqual(invalid[0]["classification"], "INVALID_QUEUE_RECORD")

    def test_rename_status_consumes_both_nul_separated_paths(self):
        raw = b"2 R. N... 100644 100644 100644 abc def R100 new-name\0old-name\0"
        self.assertEqual(census_tool.status_counts(raw)[:3], (1, 0, 0))

    def test_missing_path_is_unknown_protected(self):
        original = census_tool.run

        def with_missing(args, cwd):
            raw = original(args, cwd)
            if args == ["worktree", "list", "--porcelain"]:
                raw += b"\nworktree " + str(self.base / "missing-checkout").encode() + b"\nHEAD " + b"a" * 40 + b"\nbranch refs/heads/agent/missing\n\n"
            return raw

        with patch.object(census_tool, "run", side_effect=with_missing):
            report = self._census()
        missing = next(row for row in report["worktrees"] if row["worktree_path"].endswith("missing-checkout"))
        self.assertEqual(missing["classification"], "UNKNOWN_PROTECT")
        self.assertIn("BLOCKED:", missing["dirtiness_fingerprint_or_blocker"])
        self.assertTrue(all(row["classification"] in census_tool.CLASSIFICATIONS for row in report["worktrees"]))

    def test_detached_support_and_claim_only_refs_are_separate(self):
        report = self._census()
        detached = next(row for row in report["worktrees"] if row["worktree_path"] == str(self.detached.resolve()))
        self.assertEqual(detached["classification"], "DETACHED_SUPPORT_PRESERVE")
        self.assertEqual(detached["packet_workstream"], None)
        self.assertEqual(len(report["claim_only_or_interrupted_claims"]), 1)
        self.assertEqual(report["claim_only_or_interrupted_claims"][0]["workstream"], "interrupted-sample")

    def test_census_does_not_change_worktree_or_ref_state(self):
        before_refs = git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)", "refs/heads", "refs/remotes")
        before_work = git(self.workstream, "status", "--porcelain=v2", "--untracked-files=all")
        before_detached = git(self.detached, "status", "--porcelain=v2", "--untracked-files=all")
        self._census()
        self.assertEqual(before_refs, git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)", "refs/heads", "refs/remotes"))
        self.assertEqual(before_work, git(self.workstream, "status", "--porcelain=v2", "--untracked-files=all"))
        self.assertEqual(before_detached, git(self.detached, "status", "--porcelain=v2", "--untracked-files=all"))

    def test_host_snapshot_pins_refs_heads_status_and_claim_identity_without_names(self):
        (self.workstream / "private-local.uid").write_text("private\n")
        snapshot = census_tool.host_state_snapshot(self.repo)
        self.assertTrue(any(row.startswith("refs/heads/agent/sample-work ") for row in snapshot["refs"]))
        row = next(item for item in snapshot["worktrees"] if item["worktree_path"] == str(self.workstream.resolve()))
        self.assertEqual(row["workstream_identity"], "sample-work")
        self.assertEqual(row["process_owner"], "unknown; census does not infer process liveness")
        self.assertEqual(len(row["status"]["porcelain_sha256"]), 64)
        self.assertNotIn("private-local.uid", json.dumps(snapshot))

    def test_host_evidence_capture_verifies_unchanged_state_and_private_hash(self):
        report = self._census()
        with patch.object(census_tool, "dispatch_audit", return_value=self.audit), \
             patch.object(census_tool, "census", return_value=report):
            receipt = census_tool.capture_host_evidence(self.repo)
        artifact = Path(receipt["private_path"])
        payload = artifact.read_bytes()
        self.assertEqual(census_tool.hashlib.sha256(payload).hexdigest(), receipt["sha256"])
        evidence = json.loads(payload)
        self.assertTrue(receipt["exact_non_mutation_verified"])
        self.assertTrue(evidence["comparisons"]["census_path_coverage_exact"])
        self.assertEqual(evidence["before"]["worktrees"], evidence["after"]["worktrees"])
        self.assertEqual(artifact.stat().st_mode & 0o777, 0o600)
        self.assertEqual(Path(receipt["receipt_path"]).stat().st_mode & 0o777, 0o600)
        self.assertEqual(artifact.parent.stat().st_mode & 0o777, 0o700)

    def test_host_evidence_reports_mutation_as_non_pass(self):
        report = self._census()

        def mutating_census(_repo):
            (self.workstream / "unexpected-change.uid").write_text("changed\n")
            return report

        with patch.object(census_tool, "dispatch_audit", return_value=self.audit), \
             patch.object(census_tool, "census", side_effect=mutating_census):
            receipt = census_tool.capture_host_evidence(self.repo)
        evidence = json.loads(Path(receipt["private_path"]).read_text())
        self.assertFalse(receipt["exact_non_mutation_verified"])
        self.assertFalse(evidence["comparisons"]["worktree_status_and_identity_unchanged"])


if __name__ == "__main__":
    unittest.main()
