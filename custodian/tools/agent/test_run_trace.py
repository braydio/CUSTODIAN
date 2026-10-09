"""Focused CLI regression for local and published workflow trace listing."""

import contextlib
import importlib.util
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("run_trace.py")
SPEC = importlib.util.spec_from_file_location("custodian_run_trace_tests", SCRIPT)
run_trace = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(run_trace)


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, check=True)
    return result.stdout.strip()


class RunTraceTests(unittest.TestCase):
    def test_list_cli_resolves_repo_and_includes_local_trace(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            git(repo, "init", "-b", "main")
            trace_dir = repo / ".git/custodian-workflow/traces/sample-work"
            trace_dir.mkdir(parents=True)
            (trace_dir / "20261009T120000Z-test.jsonl").write_text('{"event":"started"}\n')
            output = io.StringIO()
            with mock.patch.object(Path, "cwd", return_value=repo), contextlib.redirect_stdout(output):
                result = run_trace.main(["list", "--workstream", "sample-work"])
            self.assertEqual(result, 0)
            rows = json.loads(output.getvalue())
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["workstream"], "sample-work")
            self.assertEqual(rows[0]["source"], "local")


if __name__ == "__main__":
    unittest.main()
