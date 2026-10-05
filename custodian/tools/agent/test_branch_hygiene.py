"""Temporary git graph tests for report-only branch classification."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("branch_hygiene.py")
SPEC = importlib.util.spec_from_file_location("branch_hygiene", SCRIPT)
hygiene = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hygiene)


def git(cwd: Path, *args: str) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if p.returncode:
        raise AssertionError(p.stderr)
    return p.stdout.strip()


class BranchHygieneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote)); git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Test"); git(self.repo, "config", "user.email", "test@example.test")
        (self.repo / "base").write_text("base\n"); git(self.repo, "add", "base"); git(self.repo, "commit", "-m", "base"); git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "branch", "landed")
        (self.repo / "unique").write_text("unique\n"); git(self.repo, "add", "unique"); git(self.repo, "commit", "-m", "unique")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "push", "origin", "refs/heads/landed:refs/heads/landed")
        git(self.repo, "branch", "historical", "HEAD^")
        (self.repo / "later").write_text("later\n"); git(self.repo, "add", "later"); git(self.repo, "commit", "-m", "later")
        git(self.repo, "push", "origin", "HEAD:refs/heads/main")
        git(self.repo, "push", "origin", "HEAD^:refs/heads/historical")
        git(self.repo, "checkout", "-b", "divergent", "HEAD~2")
        (self.repo / "divergent").write_text("separate\n"); git(self.repo, "add", "divergent"); git(self.repo, "commit", "-m", "separate history")
        git(self.repo, "push", "origin", "HEAD:refs/heads/divergent")
        git(self.repo, "push", "origin", "HEAD:refs/heads/agent/active")
        git(self.repo, "checkout", "main")
        git(self.repo, "fetch", "origin")

    def tearDown(self):
        self.temp.cleanup()

    def test_classifies_landed_and_protected(self):
        self.assertEqual(hygiene.classify(self.repo, "landed", {"main"})[0], "LANDED_SAFE_DELETE")
        self.assertEqual(hygiene.classify(self.repo, "main", {"main"})[0], "PROTECTED")
        self.assertEqual(hygiene.classify(self.repo, "divergent", {"main"})[0], "ARCHIVE_CANDIDATE")
        self.assertEqual(hygiene.classify(self.repo, "agent/active", {"main"})[0], "ACTIVE")

    def test_diagnostic_refs_are_preserved_and_never_retired(self):
        git(self.repo, "push", "origin", "HEAD:refs/heads/agent-diagnostics/sample/run-1")
        git(self.repo, "fetch", "origin")
        self.assertEqual(hygiene.classify(self.repo, "agent-diagnostics/sample/run-1", {"main"})[0], "DIAGNOSTIC_PRESERVE")
        with self.assertRaisesRegex(hygiene.HygieneError, "diagnostic ref"):
            hygiene.retire(self.repo, "agent-diagnostics/sample/run-1", self.base / "archive.md")
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent-diagnostics/sample/run-1"))

    def test_report_only_does_not_write_refs(self):
        before = git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)", "refs/remotes", "refs/tags")
        result = subprocess.run(["python3", str(SCRIPT), "divergent"], cwd=self.repo, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        after = git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)", "refs/remotes", "refs/tags")
        self.assertEqual(before, after)

    def test_unique_retirement_verifies_archive_before_remote_delete(self):
        head = git(self.repo, "rev-parse", "origin/divergent")
        ledger = self.base / "archive.md"
        hygiene.retire(self.repo, "divergent", ledger, "test archive")
        refs = git(self.repo, "ls-remote", "--tags", "origin", "archive/divergent-*").splitlines()
        self.assertTrue(any(line.split()[0] == head for line in refs))
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "divergent"), "")
        self.assertIn(head, ledger.read_text())

    def test_protected_main_cannot_be_retired(self):
        with self.assertRaisesRegex(hygiene.HygieneError, "protected"):
            hygiene.retire(self.repo, "main", self.base / "archive.md")
        self.assertNotEqual(git(self.repo, "ls-remote", "--heads", "origin", "main"), "")

    def test_dirty_attached_worktree_blocks_retirement(self):
        path = self.base / "dirty-worktree"
        git(self.repo, "worktree", "add", str(path), "divergent")
        (path / "uncommitted").write_text("preserve\n")
        with self.assertRaisesRegex(hygiene.HygieneError, "dirty worktree"):
            hygiene.retire(self.repo, "divergent", self.base / "archive.md")
        self.assertNotEqual(git(self.repo, "ls-remote", "--heads", "origin", "divergent"), "")
        self.assertTrue((path / "uncommitted").exists())

    def test_exact_head_approval_retires_only_the_audited_agent_ref(self):
        head = git(self.repo, "rev-parse", "origin/agent/active")
        ledger = self.base / "archive.md"
        result = subprocess.run(
            ["python3", str(SCRIPT), "--retire-approved", f"agent/active={head}", "--ledger", str(ledger), "--note", "approved stale branch"],
            cwd=self.repo,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RETIRED_APPROVED\tagent/active\t" + head, result.stdout)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active"), "")
        archived = git(self.repo, "ls-remote", "--tags", "origin", "archive/agent-active-*").splitlines()
        self.assertTrue(any(line.split()[0] == head for line in archived))
        self.assertIn(head, ledger.read_text())
        self.assertIn("approved stale branch", ledger.read_text())

    def test_exact_head_approval_archives_even_if_main_now_contains_the_head(self):
        git(self.repo, "push", "origin", "main:refs/heads/agent/approved-contained")
        git(self.repo, "fetch", "origin")
        head = git(self.repo, "rev-parse", "origin/agent/approved-contained")
        ledger = self.base / "archive.md"
        hygiene.retire(
            self.repo,
            "agent/approved-contained",
            ledger,
            "approved exact head",
            expected_head=head,
        )
        archived = git(self.repo, "ls-remote", "--tags", "origin", "archive/agent-approved-contained-*").splitlines()
        self.assertTrue(any(line.split()[0] == head for line in archived))
        self.assertIn("approved head preserved; already contained by main", ledger.read_text())
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/approved-contained"), "")

    def test_mismatched_approved_sha_performs_no_retirement_mutation(self):
        head = git(self.repo, "rev-parse", "origin/agent/active")
        ledger = self.base / "archive.md"
        result = subprocess.run(
            ["python3", str(SCRIPT), "--retire-approved", f"agent/active={'0' * 40}", "--ledger", str(ledger)],
            cwd=self.repo,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("head mismatch", result.stderr)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0], head)
        self.assertEqual(git(self.repo, "ls-remote", "--tags", "origin", "archive/agent-active-*"), "")
        self.assertFalse(ledger.exists())

    def test_approved_retirement_rejects_protected_and_diagnostic_refs(self):
        diagnostic = "agent-diagnostics/sample/run-1"
        git(self.repo, "push", "origin", f"HEAD:refs/heads/{diagnostic}")
        git(self.repo, "fetch", "origin")
        for branch in ("main", diagnostic):
            with self.subTest(branch=branch):
                head = git(self.repo, "rev-parse", f"origin/{branch}")
                with self.assertRaises(hygiene.HygieneError):
                    hygiene.retire(self.repo, branch, self.base / "archive.md", expected_head=head)
                self.assertNotEqual(git(self.repo, "ls-remote", "--heads", "origin", f"refs/heads/{branch}"), "")

    def test_approved_retirement_blocks_a_dirty_attached_agent_worktree(self):
        path = self.base / "dirty-approved-worktree"
        git(self.repo, "worktree", "add", "--track", "-b", "agent/active", str(path), "origin/agent/active")
        (path / "uncommitted").write_text("preserve\n")
        head = git(self.repo, "rev-parse", "origin/agent/active")
        with self.assertRaisesRegex(hygiene.HygieneError, "dirty worktree"):
            hygiene.retire(self.repo, "agent/active", self.base / "archive.md", expected_head=head)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0], head)
        self.assertTrue((path / "uncommitted").exists())

    def test_approved_retirement_blocks_an_attached_head_beyond_remote(self):
        path = self.base / "ahead-approved-worktree"
        git(self.repo, "worktree", "add", "--track", "-b", "agent/active", str(path), "origin/agent/active")
        (path / "local-only").write_text("preserve\n")
        git(path, "add", "local-only")
        git(path, "commit", "-m", "local-only commit")
        head = git(self.repo, "rev-parse", "origin/agent/active")
        with self.assertRaisesRegex(hygiene.HygieneError, "local commits/state beyond its remote head"):
            hygiene.retire(self.repo, "agent/active", self.base / "archive.md", expected_head=head)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0], head)
        self.assertTrue((path / "local-only").exists())

    def test_approved_retirement_rejects_non_agent_and_malformed_approval(self):
        for approval in (
            "main=" + "0" * 40,
            "agent-diagnostics/run-1=" + "0" * 40,
            "agent/active=ABCDEF",
            "agent/../main=" + "0" * 40,
        ):
            with self.subTest(approval=approval), self.assertRaises(hygiene.HygieneError):
                hygiene.parse_approved_retirement(approval)

    def test_default_apply_still_preserves_divergent_agent_refs(self):
        head = git(self.repo, "rev-parse", "origin/agent/active")
        result = subprocess.run(
            ["python3", str(SCRIPT), "--apply", "agent/active", "--ledger", str(self.base / "archive.md")],
            cwd=self.repo,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ACTIVE\tagent/active\t" + head, result.stdout)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0], head)
        self.assertEqual(git(self.repo, "ls-remote", "--tags", "origin", "archive/agent-active-*"), "")

    def test_ledger_write_failure_keeps_approved_remote_branch(self):
        head = git(self.repo, "rev-parse", "origin/agent/active")
        ledger = self.base / "ledger-is-a-directory"
        ledger.mkdir()
        with self.assertRaisesRegex(hygiene.HygieneError, "could not write branch archive ledger"):
            hygiene.retire(self.repo, "agent/active", ledger, expected_head=head)
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0], head)

    def test_approved_delete_lease_preserves_a_remote_head_that_moves_after_archive(self):
        approved_head = git(self.repo, "rev-parse", "origin/agent/active")
        archive = hygiene.archive_tag

        def archive_then_advance_remote(repo, branch, head, date):
            tag = archive(repo, branch, head, date)
            git(repo, "checkout", "--detach", f"origin/{branch}")
            (repo / "concurrent").write_text("concurrent update\n")
            git(repo, "add", "concurrent")
            git(repo, "commit", "-m", "concurrent remote update")
            git(repo, "push", "origin", f"HEAD:refs/heads/{branch}")
            git(repo, "checkout", "main")
            return tag

        with patch.object(hygiene, "archive_tag", side_effect=archive_then_advance_remote):
            with self.assertRaises(hygiene.HygieneError):
                hygiene.retire(self.repo, "agent/active", self.base / "archive.md", expected_head=approved_head)
        remote_head = git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/active").split()[0]
        self.assertNotEqual(remote_head, approved_head)
        self.assertTrue((self.base / "archive.md").is_file())


if __name__ == "__main__":
    unittest.main()
