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
        git(self.repo, "checkout", "main")
        git(self.repo, "fetch", "origin")

    def tearDown(self):
        self.temp.cleanup()

    def test_classifies_landed_and_protected(self):
        self.assertEqual(hygiene.classify(self.repo, "landed", {"main"})[0], "LANDED_SAFE_DELETE")
        self.assertEqual(hygiene.classify(self.repo, "main", {"main"})[0], "PROTECTED")
        self.assertEqual(hygiene.classify(self.repo, "divergent", {"main"})[0], "ARCHIVE_CANDIDATE")


if __name__ == "__main__":
    unittest.main()
