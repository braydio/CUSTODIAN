"""Temporary git graph tests for report-only branch classification."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

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


if __name__ == "__main__":
    unittest.main()
