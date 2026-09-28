"""Focused temporary-repository tests for land_main.py."""

import subprocess
import tempfile
import unittest
import os
from pathlib import Path


SCRIPT = Path(__file__).with_name("land_main.py")


def run_git(cwd: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


class LandMainTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.seed = self.base / "seed"
        self.task = self.base / "task"
        run_git(self.base, "init", "--bare", str(self.remote))
        run_git(self.base, "clone", str(self.remote), str(self.seed))
        run_git(self.seed, "checkout", "-b", "main")
        self._identity(self.seed)
        (self.seed / "shared.txt").write_text("base\n")
        run_git(self.seed, "add", "shared.txt")
        run_git(self.seed, "commit", "-m", "seed")
        run_git(self.seed, "push", "-u", "origin", "main")
        run_git(self.base, "clone", str(self.remote), str(self.task))
        run_git(self.task, "checkout", "-b", "task/work")
        self._identity(self.task)

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def _identity(repo: Path) -> None:
        run_git(repo, "config", "user.name", "Test Agent")
        run_git(repo, "config", "user.email", "agent@example.test")

    def _land(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(SCRIPT), *args], cwd=self.task, text=True, capture_output=True
        )

    def _task_commit(self, filename: str, content: str) -> None:
        (self.task / filename).write_text(content)
        run_git(self.task, "add", filename)
        run_git(self.task, "commit", "-m", "task change")

    def test_dry_run_inspects_without_landing(self) -> None:
        self._task_commit("task.txt", "task\n")
        before = run_git(self.seed, "rev-parse", "refs/heads/main")
        result = self._land("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would fetch origin/main", result.stdout)
        self.assertEqual(before, run_git(self.seed, "rev-parse", "refs/heads/main"))

    def test_clean_task_branch_lands_on_main(self) -> None:
        self._task_commit("task.txt", "task\n")
        result = self._land()
        self.assertEqual(result.returncode, 0, result.stderr)
        run_git(self.seed, "fetch", "origin", "main")
        remote_head = run_git(self.seed, "rev-parse", "origin/main")
        task_head = run_git(self.task, "rev-parse", "HEAD")
        self.assertEqual(remote_head, task_head)
        self.assertEqual((self.seed / "task.txt").exists(), False)

    def test_remote_main_race_retries_after_rebase(self) -> None:
        self._task_commit("task.txt", "task\n")
        racer = self.base / "racer"
        run_git(self.base, "clone", str(self.remote), str(racer))
        run_git(racer, "checkout", "main")
        self._identity(racer)
        bin_dir = self.base / "bin"
        bin_dir.mkdir()
        marker = self.base / "race-fired"
        wrapper = bin_dir / "git"
        wrapper.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = push ] && [ \"$2\" = origin ] && [ \"$3\" = HEAD:refs/heads/main ] && [ ! -e \"$LAND_RACE_MARKER\" ]; then\n"
            "  touch \"$LAND_RACE_MARKER\"\n"
            "  (cd \"$LAND_RACE_REPO\" && echo concurrent > concurrent.txt && /usr/bin/git add concurrent.txt && /usr/bin/git commit -m concurrent && /usr/bin/git push origin main) || exit 90\n"
            "fi\n"
            "exec /usr/bin/git \"$@\"\n"
        )
        wrapper.chmod(0o755)
        env = os.environ.copy()
        env["PATH"] = f"{bin_dir}:{env['PATH']}"
        env["LAND_RACE_MARKER"] = str(marker)
        env["LAND_RACE_REPO"] = str(racer)
        result = subprocess.run(
            ["python3", str(SCRIPT)], cwd=self.task, env=env, text=True, capture_output=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(marker.exists())
        self.assertIn("retrying", result.stdout)
        run_git(self.seed, "fetch", "origin", "main")
        self.assertEqual(run_git(self.seed, "rev-parse", "origin/main"), run_git(self.task, "rev-parse", "HEAD"))
        self.assertTrue((self.seed / "task.txt").exists() is False)

    def test_own_pushed_workstream_is_allowed_to_land(self) -> None:
        self._task_commit("task.txt", "task\n")
        run_git(self.task, "push", "-u", "origin", "HEAD:refs/heads/task/work")
        result = self._land()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_commit_published_on_unrelated_remote_branch_is_blocked(self) -> None:
        self._task_commit("task.txt", "task\n")
        run_git(self.task, "push", "origin", "HEAD:refs/heads/unrelated")
        result = self._land()
        self.assertEqual(result.returncode, 2)
        self.assertIn("already published", result.stderr)
        self.assertIn("refs/remotes/origin/unrelated", result.stderr)

    def test_rebase_conflict_aborts_and_reports_blocker(self) -> None:
        self._task_commit("shared.txt", "task side\n")
        original_head = run_git(self.task, "rev-parse", "HEAD")
        run_git(self.base, "clone", str(self.remote), str(self.base / "other"))
        other = self.base / "other"
        run_git(other, "fetch", "origin", "main")
        run_git(other, "checkout", "-B", "main", "origin/main")
        self._identity(other)
        (other / "shared.txt").write_text("main side\n")
        run_git(other, "add", "shared.txt")
        run_git(other, "commit", "-m", "concurrent main")
        run_git(other, "push", "origin", "HEAD:refs/heads/main")
        result = self._land()
        self.assertEqual(result.returncode, 2)
        self.assertIn("rebase conflict", result.stderr)
        self.assertEqual(run_git(self.task, "status", "--porcelain"), "")
        self.assertEqual(run_git(self.task, "rev-parse", "HEAD"), original_head)

    def test_dirty_worktree_is_refused(self) -> None:
        (self.task / "uncommitted.txt").write_text("dirty\n")
        result = self._land("--dry-run")
        self.assertEqual(result.returncode, 2)
        self.assertIn("worktree must be clean", result.stderr)


if __name__ == "__main__":
    unittest.main()
