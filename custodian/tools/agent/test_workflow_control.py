from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from custodian.tools.agent.workflow_control import RunTrace, redact, sanitize_argv


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


if __name__ == "__main__":
    unittest.main()
