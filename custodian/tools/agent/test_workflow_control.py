from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock

from custodian.tools.agent.workflow_control import (
    DEFAULT_AGENT_ID, RunTrace, WorkflowControlError, common_mutex,
    dispatch_mutex_path, redact, resolve_agent_id, sanitize_argv,
)


class WorkflowControlTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bare = self.root / "remote.git"
        subprocess.run(["git", "init", "--bare", str(self.bare)], check=True, capture_output=True)
        self.repo = self.root / "repo"
        subprocess.run(["git", "init", str(self.repo)], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.repo), "config", "user.name", "test"], check=True)
        subprocess.run(["git", "-C", str(self.repo), "config", "user.email", "test@example.invalid"], check=True)
        (self.repo / "tracked").write_text("ok\n")
        subprocess.run(["git", "-C", str(self.repo), "add", "tracked"], check=True)
        subprocess.run(["git", "-C", str(self.repo), "commit", "-m", "initial"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.repo), "branch", "-M", "main"], check=True)
        subprocess.run(["git", "-C", str(self.repo), "remote", "add", "origin", str(self.bare)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "push", "-u", "origin", "main"], check=True, capture_output=True)

    def tearDown(self):
        self.temp.cleanup()

    def test_trace_redacts_secrets_and_publishes_diagnostics_only_ref(self):
        trace = RunTrace.start(self.repo, "trace-check", agent="codex")
        trace.record("test_event", api_key="swordfish", argv=sanitize_argv(["tool", "--password", "secret-value", "Bearer abcdefghijklmnop"]))
        self.assertTrue(trace.publish())
        content = subprocess.run(["git", "--git-dir", str(self.bare), "show", f"refs/heads/agent-diagnostics/trace-check/{trace.run_id}:trace.jsonl"],
                                 text=True, capture_output=True, check=True).stdout
        self.assertNotIn("swordfish", content)
        self.assertNotIn("secret-value", content)
        self.assertNotIn("abcdefghijklmnop", content)
        self.assertNotIn("token-secret", redact("https://user:token-secret@example.invalid/repo.git"))
        lines = [json.loads(line) for line in content.splitlines()]
        self.assertEqual(lines[-1]["event"], "test_event")
        refs = subprocess.run(["git", "--git-dir", str(self.bare), "for-each-ref", "--format=%(refname)"], text=True, capture_output=True, check=True).stdout
        self.assertNotIn("refs/heads/agent/trace-check", refs)
        self.assertNotIn("refs/heads/dispatch-claims/trace-check", refs)

    def _lock_holder(self, hold_seconds=2):
        path = dispatch_mutex_path(self.repo)
        path.parent.mkdir(parents=True, exist_ok=True)
        code = (
            "import fcntl,sys,time; handle=open(sys.argv[1],'a'); "
            "fcntl.flock(handle,fcntl.LOCK_EX); print('ready',flush=True); time.sleep(float(sys.argv[2]))"
        )
        process = subprocess.Popen(
            [sys.executable, "-c", code, str(path), str(hold_seconds)],
            stdout=subprocess.PIPE, text=True,
        )
        self.assertEqual(process.stdout.readline().strip(), "ready")
        process.stdout.close()
        return process, path

    def test_common_mutex_fails_fast_when_busy(self):
        holder, lock_path = self._lock_holder()
        inode = lock_path.stat().st_ino
        started = time.monotonic()
        try:
            with self.assertRaisesRegex(WorkflowControlError, "LOCAL DISPATCH BUSY"):
                with common_mutex(self.repo, timeout_seconds=0):
                    self.fail("busy mutex unexpectedly acquired")
            self.assertLess(time.monotonic() - started, 0.5)
            self.assertTrue(lock_path.exists())
            self.assertEqual(lock_path.stat().st_ino, inode)
        finally:
            holder.terminate()
            holder.wait(timeout=3)

    def test_common_mutex_rejects_unbounded_wait_values(self):
        with self.assertRaisesRegex(WorkflowControlError, "must be finite"):
            with common_mutex(self.repo, timeout_seconds=float("inf")):
                self.fail("infinite timeout should be rejected")

    def test_common_mutex_can_wait_for_bounded_timeout(self):
        holder, lock_path = self._lock_holder(hold_seconds=3)
        try:
            started = time.monotonic()
            with self.assertRaisesRegex(WorkflowControlError, "LOCAL DISPATCH BUSY"):
                with common_mutex(self.repo, timeout_seconds=0.35):
                    self.fail("busy mutex unexpectedly acquired")
            elapsed = time.monotonic() - started
            self.assertGreaterEqual(elapsed, 0.3)
            self.assertLess(elapsed, 1.0)
            self.assertTrue(lock_path.exists())
        finally:
            holder.terminate()
            holder.wait(timeout=3)
        with common_mutex(self.repo, timeout_seconds=0):
            self.assertTrue(lock_path.exists())

    def test_diagnostic_publish_timeout_is_non_authoritative(self):
        trace = RunTrace.start(self.repo, "timeout-check", agent="codex")
        with mock.patch(
            "custodian.tools.agent.workflow_control.git",
            side_effect=subprocess.TimeoutExpired(["git", "ls-remote"], 0.01),
        ) as git_mock:
            self.assertFalse(trace.publish())
        git_mock.assert_called_once()
        self.assertEqual(git_mock.call_args.kwargs["timeout"], 15.0)
        events = [json.loads(line)["event"] for line in trace.path.read_text().splitlines()]
        self.assertIn("diagnostic_publish_failed", events)
        trace.complete("claimed", publish=False)
        events = [json.loads(line) for line in trace.path.read_text().splitlines()]
        self.assertEqual(events[-1]["event"], "run_completed")
        self.assertEqual(events[-1]["data"]["outcome"], "claimed")

    def test_trace_completion_methods_publish_by_default(self):
        trace = RunTrace.start(self.repo, "default-publish", agent="codex")
        with mock.patch.object(trace, "publish", return_value=True) as publish:
            trace.complete("finished")
            trace.finish_blocked("expected test block")
        self.assertEqual(publish.call_count, 2)

    def test_trace_completion_methods_publish_by_default(self):
        trace = RunTrace.start(self.repo, "default-publish", agent="codex")
        with mock.patch.object(trace, "publish", return_value=True) as publish:
            trace.complete("finished")
            trace.finish_blocked("expected test block")
        self.assertEqual(publish.call_count, 2)


class ResolveAgentIdTests(unittest.TestCase):
    def test_explicit_flag_wins_over_environment(self):
        with mock.patch.dict(os.environ, {"CUSTODIAN_AGENT_ID": "env-agent"}, clear=False):
            self.assertEqual(resolve_agent_id("claude"), "claude")
            self.assertEqual(resolve_agent_id("codex"), "codex")

    def test_environment_used_when_no_explicit_flag(self):
        with mock.patch.dict(os.environ, {"CUSTODIAN_AGENT_ID": "env-agent"}, clear=False):
            self.assertEqual(resolve_agent_id(None), "env-agent")

    def test_neutral_default_when_nothing_specified(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertEqual(resolve_agent_id(None), DEFAULT_AGENT_ID)
            self.assertEqual(DEFAULT_AGENT_ID, "unspecified")

    def test_blank_environment_value_is_treated_as_absent(self):
        with mock.patch.dict(os.environ, {"CUSTODIAN_AGENT_ID": "   "}, clear=False):
            self.assertEqual(resolve_agent_id(None), DEFAULT_AGENT_ID)

    def test_never_silently_defaults_to_codex(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertNotEqual(resolve_agent_id(None), "codex")
            self.assertNotEqual(resolve_agent_id(""), "codex")


if __name__ == "__main__":
    unittest.main()
