"""Isolated Git tests for the opt-in turn dispatcher."""
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("turn_dispatcher_v2.py")
SPEC = importlib.util.spec_from_file_location("turn_dispatcher_v2", SCRIPT)
td = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(td)


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, check=True, text=True,
                          capture_output=True).stdout.strip()


class TurnDispatcherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.origin = self.base / "origin.git"
        self.repo = self.base / "repo"
        run("git", "init", "--bare", str(self.origin))
        run("git", "init", "-b", "main", str(self.repo))
        run("git", "config", "user.name", "Test", cwd=self.repo)
        run("git", "config", "user.email", "test@example.com", cwd=self.repo)
        directory = self.repo / "custodian/docs/ai_context/task_packets"
        directory.mkdir(parents=True)
        self.packet = directory / "EXAMPLE.md"
        self.packet.write_text("- Workstream: example-task\n- Status: ready\n- Dispatch: auto\n")
        run("git", "add", ".", cwd=self.repo)
        run("git", "commit", "-m", "baseline", cwd=self.repo)
        run("git", "remote", "add", "origin", str(self.origin), cwd=self.repo)
        run("git", "push", "-u", "origin", "main", cwd=self.repo)

    def test_inspect_no_remote_ref_mutation(self):
        result = td.inspect(self.repo, "example-task", "normal")
        self.assertEqual(result["branch"], "agent/example-task")
        self.assertIsNone(result["remote_head"])

    def test_modes_and_design_refresh(self):
        self.packet.write_text("- Workstream: example-task\n- Status: draft\n- Dispatch: manual\n")
        with self.assertRaisesRegex(td.DispatchError, "ready/auto"):
            td.inspect(self.repo, "example-task", "normal")
        with self.assertRaisesRegex(td.DispatchError, "design refresh"):
            td.inspect(self.repo, "example-task", "historical")

    def test_historical_no_remote_branch_is_blocked(self):
        with self.assertRaisesRegex(td.DispatchError, "historical branch unavailable"):
            td.begin(self.repo, "example-task", "historical", self.base / "turns")

    def create_attached(self):
        head = run("git", "rev-parse", "HEAD", cwd=self.repo)
        run("git", "push", "origin", f"{head}:refs/heads/agent/example-task", cwd=self.repo)
        pool = self.base / "turns"
        pool.mkdir()
        checkout = pool / "turn-example-task"
        run("git", "worktree", "add", "-b", "agent/example-task", str(checkout), head, cwd=self.repo)
        run("git", "config", "user.name", "Test", cwd=checkout)
        run("git", "config", "user.email", "test@example.com", cwd=checkout)
        return pool, checkout

    def test_checkpoint_commits_all_nonignored_and_retires(self):
        pool, checkout = self.create_attached()
        (checkout / "source.py").write_text("print(123)\n")
        handoff = self.base / "handoff.md"
        handoff.write_text("Original goal: x\nImplemented: y\nRemaining: z\n"
                           "Validation: pass\nResume: branch and handoff\n")
        result = td.checkpoint(self.repo, "example-task", checkout, handoff, "turn handoff", pool)
        self.assertTrue(result["retired"])
        self.assertFalse(checkout.exists())
        files = run("git", "--git-dir", str(self.origin), "ls-tree", "-r",
                    "--name-only", "refs/heads/agent/example-task")
        self.assertIn("source.py", files)
        self.assertIn("turn_handoffs/example-task.md", files)

    def test_secret_prevents_retirement(self):
        pool, checkout = self.create_attached()
        (checkout / ".env").write_text("SECRET=1\n")
        handoff = self.base / "handoff.md"
        handoff.write_text("Original goal: x\nImplemented: y\nRemaining: z\n"
                           "Validation: pass\nResume: later\n")
        with self.assertRaisesRegex(td.DispatchError, "potential secrets"):
            td.checkpoint(self.repo, "example-task", checkout, handoff, "handoff", pool)
        self.assertTrue(checkout.exists())


if __name__ == "__main__":
    unittest.main()
