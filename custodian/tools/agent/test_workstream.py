"""Focused temporary-repository coverage for workstream lifecycle primitives."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("workstream.py")
SPEC = importlib.util.spec_from_file_location("workstream", SCRIPT)
workstream = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workstream)


def git(cwd: Path, *args: str) -> str:
    p = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if p.returncode:
        raise AssertionError(p.stderr)
    return p.stdout.strip()


class WorkstreamTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote))
        git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Test")
        git(self.repo, "config", "user.email", "test@example.test")
        (self.repo / "base").write_text("base\n")
        git(self.repo, "add", "base"); git(self.repo, "commit", "-m", "base")
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")

    def tearDown(self):
        self.temp.cleanup()

    def test_stable_kebab_id_validation(self):
        self.assertEqual(workstream.validate_id("operator-fast-chain"), "operator-fast-chain")
        for value in ("Operator", "two--words", "a/b", "one_"):
            with self.assertRaises(workstream.WorkstreamError):
                workstream.validate_id(value)

    def test_new_start_uses_origin_main_in_external_worktree(self):
        path = workstream.start("sample-work", self.repo)
        self.assertEqual(git(path, "branch", "--show-current"), "agent/sample-work")
        self.assertNotEqual(path, self.repo)
        self.assertFalse(path.is_relative_to(self.repo))
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertEqual(git(path, "rev-parse", "@{upstream}"), git(self.repo, "rev-parse", "origin/agent/sample-work"))

    def test_existing_remote_is_resumed_and_main_merge_is_non_rewriting(self):
        task = workstream.start("resume-me", self.repo)
        (task / "task").write_text("task\n"); git(task, "add", "task"); git(task, "commit", "-m", "task")
        git(task, "push", "origin", "agent/resume-me")
        task_head = git(task, "rev-parse", "HEAD")
        (self.repo / "main-change").write_text("new\n"); git(self.repo, "add", "main-change"); git(self.repo, "commit", "-m", "main advances"); git(self.repo, "push", "origin", "main")
        git(self.repo, "worktree", "remove", str(task))
        git(self.repo, "branch", "-D", "agent/resume-me")
        resumed = workstream.start("resume-me", self.repo)
        self.assertEqual(git(resumed, "branch", "--show-current"), "agent/resume-me")
        self.assertEqual(git(resumed, "rev-parse", "HEAD^"), task_head)
        self.assertTrue((resumed / "main-change").exists())

    def test_existing_remote_fast_forwards_to_new_main(self):
        path = workstream.start("fast-forward", self.repo)
        git(self.repo, "worktree", "remove", str(path)); git(self.repo, "branch", "-D", "agent/fast-forward")
        (self.repo / "main-ff").write_text("advance\n"); git(self.repo, "add", "main-ff"); git(self.repo, "commit", "-m", "advance main"); git(self.repo, "push", "origin", "main")
        resumed = workstream.start("fast-forward", self.repo)
        self.assertEqual(git(resumed, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertTrue((resumed / "main-ff").exists())

    def test_main_merge_conflict_preserves_task_worktree(self):
        path = workstream.start("conflict-work", self.repo)
        (path / "base").write_text("task version\n"); git(path, "add", "base"); git(path, "commit", "-m", "task conflict")
        git(path, "push", "origin", "agent/conflict-work")
        git(self.repo, "worktree", "remove", str(path)); git(self.repo, "branch", "-D", "agent/conflict-work")
        (self.repo / "base").write_text("main version\n"); git(self.repo, "add", "base"); git(self.repo, "commit", "-m", "main conflict"); git(self.repo, "push", "origin", "main")
        with self.assertRaisesRegex(workstream.WorkstreamError, "merge conflicted"):
            workstream.start("conflict-work", self.repo)
        attached = workstream.find_worktree(self.repo, "agent/conflict-work")
        self.assertTrue(attached.exists())
        self.assertNotEqual(git(attached, "status", "--porcelain"), "")
        self.assertNotEqual(git(self.repo, "ls-remote", "--heads", "origin", "agent/conflict-work"), "")

    def test_dirty_attached_worktree_is_preserved_and_blocks(self):
        path = workstream.start("dirty-work", self.repo)
        dirty = path / "uncommitted"; dirty.write_text("keep\n")
        with self.assertRaisesRegex(workstream.WorkstreamError, "dirty worktree"):
            workstream.start("dirty-work", self.repo)
        self.assertTrue(dirty.exists())

    def test_checkpoint_pushes_and_retains_recovery_branch(self):
        path = workstream.start("checkpoint-me", self.repo)
        (path / "saved").write_text("recoverable\n")
        git(path, "add", "saved"); git(path, "commit", "-m", "checkpoint")
        workstream.checkpoint("checkpoint-me", repo=self.repo)
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/agent/checkpoint-me"))
        self.assertTrue(path.exists())

    def test_finish_lands_verifies_and_tears_down(self):
        path = workstream.start("finish-me", self.repo)
        (path / "feature").write_text("done\n")
        (path / "SAMPLE_CLAUDE_SUMMARY.md").write_text("completed\n")
        git(path, "add", "feature", "SAMPLE_CLAUDE_SUMMARY.md")
        git(path, "commit", "-m", "finish sample")
        landed_head = git(path, "rev-parse", "HEAD")
        report = self.base / "validation.json"
        report.write_text('{"schema":"custodian.validation.result.v1","passed":true,"tests":[{"status":"passed"}]}')
        # Invoke from the task worktree itself, as the normal CLI does. Teardown
        # must continue through a surviving coordination worktree.
        workstream.finish("finish-me", report, repo=path)
        self.assertFalse(path.exists())
        self.assertNotIn("agent/finish-me", git(self.repo, "branch", "--list"))
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "agent/finish-me"), "")
        check = subprocess.run(["git", "merge-base", "--is-ancestor", landed_head, "origin/main"], cwd=self.repo)
        self.assertEqual(check.returncode, 0)


if __name__ == "__main__":
    unittest.main()
