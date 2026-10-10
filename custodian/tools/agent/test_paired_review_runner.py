#!/usr/bin/env python3
"""Focused contract tests for the synchronous paired-review runner."""
from __future__ import annotations

import json
import fcntl
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import paired_review_runner as runner

ROOT = Path(__file__).resolve().parents[3]


def review_packet(*, visual="none", refresh="no"):
    return f"""# Review packet
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md`
- Visual review: `{visual}`
- ChatGPT/user planning refresh required: `{refresh}`

## Goal
Review this task.
"""


def target_packet():
    return """# Implementation
- Packet schema: `custodian.task_packet.v2`
- Workstream: `sample-impl`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow`
"""


class PairedReviewRunnerTests(unittest.TestCase):
    def test_fake_codex_fixture_advertises_required_ephemeral_interface(self):
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp) / "codex"
            capture = Path(temp) / "capture.json"
            source = f'''#!{sys.executable}
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
if args == ["exec", "--help"]:
    print("codex exec --ephemeral --json --output-last-message --sandbox --cd --add-dir --approve-for-me")
    raise SystemExit(0)
if "--sandbox" in args and "--approve-for-me" in args:
    print("incompatible approval flags", file=sys.stderr)
    raise SystemExit(2)
prompt = sys.stdin.read()
Path(os.environ["FAKE_CODEX_CAPTURE_PATH"]).write_text(json.dumps({{"args": args, "cwd": os.getcwd(), "prompt": prompt}}))
output = Path(args[args.index("--output-last-message") + 1])
output.write_text("fake review finished\\n")
print(json.dumps({{"type": "done", "api_key": "fixture-secret"}}))
'''
            fixture.write_text(source)
            fixture.chmod(0o755)
            with patch.dict(os.environ, {"PATH": temp, "FAKE_CODEX_CAPTURE_PATH": str(capture)}):
                self.assertEqual(runner.codex_preflight(), str(fixture))
                rejected = subprocess.run([str(fixture), "exec", "--sandbox", "workspace-write", "--approve-for-me"],
                                           text=True, capture_output=True)
                self.assertEqual(rejected.returncode, 2)
                run_dir = Path(temp) / "run-evidence"
                run_dir.mkdir()
                argv = [str(fixture), "exec", "--ephemeral", "--json", "--approve-for-me", "--cd", temp,
                        "--add-dir", str(run_dir), "--output-last-message", str(run_dir / "last.txt"), "-"]
                self.assertEqual(runner.launch_codex(argv, Path(temp), "review prompt", run_dir, None), 0)
            observed = json.loads(capture.read_text())
            self.assertEqual(observed["cwd"], temp)
            self.assertIn("--ephemeral", observed["args"])
            self.assertIn("--approve-for-me", observed["args"])
            self.assertNotIn("--sandbox", observed["args"])
            self.assertEqual(observed["prompt"], "review prompt")
            self.assertNotIn("fixture-secret", (run_dir / "codex.jsonl").read_text())

    def test_human_gate_and_non_review_are_refused(self):
        packet = runner.parse_packet("review.md", review_packet(visual="required"))
        with patch.object(runner, "packet_at_main", return_value=("review.md", review_packet(visual="required"), packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human visual"):
                runner.validate_eligible_review(Path("."), "review-sample")
        packet = runner.parse_packet("impl.md", target_packet())
        with patch.object(runner, "packet_at_main", return_value=("impl.md", target_packet(), packet)):
            with self.assertRaisesRegex(runner.RunnerError, "non-review"):
                runner.validate_eligible_review(Path("."), "sample-impl")
        gated = review_packet(refresh="yes")
        packet = runner.parse_packet("review.md", gated)
        with patch.object(runner, "packet_at_main", return_value=("review.md", gated, packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human planning"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_successor_handoff_refresh_does_not_gate_current_review(self):
        # Both section spellings are live: F15-A uses "Next Handoff", WB25 "Handoff".
        for heading in ("## Handoff", "## Next Handoff"):
            with self.subTest(heading=heading):
                content = review_packet() + f"""
{heading}
- Next workstream: `next-slice`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
"""
                packet = runner.parse_packet("review.md", content)
                target = target_packet()
                with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)), \
                     patch.object(runner, "git", return_value=target):
                    runner.validate_eligible_review(Path("."), "review-sample")

    def test_actual_wb25_review_packet_is_eligible_despite_successor_refresh(self):
        # WB25's review correctly left the active queue after closeout. Reuse the
        # immutable historical packet, restoring only pre-claim lifecycle metadata
        # in memory so this regression survives normal archive transitions.
        review_path = "custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md"
        archived_content = (ROOT / review_path).read_text(encoding="utf-8")
        self.assertIn("- Status: complete", archived_content)
        self.assertIn("- Review: findings recorded; blocking R0-01", archived_content)
        review_content = archived_content.replace("- Status: complete", "- Status: ready", 1)
        review_content = review_content.replace(
            "- Review: findings recorded; blocking R0-01", "- Review: none", 1
        )
        review_packet_data = runner.parse_packet(review_path, review_content)
        self.assertIsNone(review_packet_data.error)
        target_content = (ROOT / review_packet_data.review_target_packet).read_text(encoding="utf-8")
        with patch.object(runner, "packet_at_main", return_value=(review_path, review_content, review_packet_data)), \
             patch.object(runner, "git", return_value=target_content):
            runner.validate_eligible_review(ROOT, "review-operator-2-5d-workbench-review-automation")

    def test_human_owner_in_current_review_authority_is_refused(self):
        content = review_packet() + """
## Current Review Authority
- Refresh owner: `chatgpt-user`
## Handoff
- Refresh owner: `none`
"""
        packet = runner.parse_packet("review.md", content)
        with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human-owned refresh"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_review_target_must_be_complete_and_present(self):
        packet = runner.parse_packet("review.md", review_packet())
        with patch.object(runner, "packet_at_main", return_value=("review.md", review_packet(), packet)), \
             patch.object(runner, "git", side_effect=runner.RunnerError("missing")):
            with self.assertRaisesRegex(runner.RunnerError, "completed review target"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_missing_codex_fails_preflight_without_claim_process(self):
        packet = runner.parse_packet("review.md", review_packet())
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            with patch.object(runner, "git", return_value=str(repo)), \
                 patch.object(runner, "validate_eligible_review", return_value=("review.md", "", packet)), \
                 patch.object(runner, "codex_preflight", side_effect=runner.RunnerError("codex unavailable")), \
                 patch.object(runner.subprocess, "run") as claim:
                with self.assertRaisesRegex(runner.RunnerError, "codex unavailable"):
                    runner.run(repo, "review-sample")
                claim.assert_not_called()

    def test_duplicate_local_runner_refuses_before_claim(self):
        packet = runner.parse_packet("review.md", review_packet())
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            common = repo / ".git"
            lock_path = common / "custodian-review-runs/locks/review-sample.lock"
            lock_path.parent.mkdir(parents=True)
            with lock_path.open("a") as held:
                fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
                with patch.object(runner, "git", return_value=str(repo)), \
                     patch.object(runner, "validate_eligible_review", return_value=("review.md", "", packet)), \
                     patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                     patch.object(runner, "common_dir", return_value=common), \
                     patch.object(runner.subprocess, "run") as claim:
                    with self.assertRaisesRegex(runner.RunnerError, "another local runner"):
                        runner.run(repo, "review-sample")
                    claim.assert_not_called()

    def test_codex_launch_failure_after_claim_leaves_recovery_card(self):
        packet_text = review_packet()
        packet = runner.parse_packet("review.md", packet_text)
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp) / "repo"
            common = repo / ".git"
            worktree = Path(temp) / "claimed-review"
            worktree.mkdir(parents=True)
            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(worktree), "branch": "agent/review-sample",
                       "packet": "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"}
            (worktree / receipt["packet"]).parent.mkdir(parents=True)
            (worktree / receipt["packet"]).write_text(packet_text)
            completed = subprocess.CompletedProcess([], 0, "claim receipt", "")
            with patch.object(runner, "git", return_value=str(repo)), \
                 patch.object(runner, "validate_eligible_review", return_value=(receipt["packet"], packet_text, packet)), \
                 patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                 patch.object(runner, "common_dir", return_value=common), \
                 patch.object(runner, "parse_claim_receipt", return_value=receipt), \
                 patch.object(runner.subprocess, "run", return_value=completed), \
                 patch.object(runner.subprocess, "Popen", side_effect=OSError("fixture launch failure")):
                self.assertEqual(runner.run(repo, "review-sample"), 2)
            run_dir = next((common / "custodian-review-runs/review-sample").iterdir())
            metadata = json.loads((run_dir / "metadata.json").read_text())
            self.assertEqual(metadata["phase"], "codex_launch_failed_recovery")
            recovery = (run_dir / "RECOVERY.md").read_text()
            self.assertIn(str(worktree), recovery)
            self.assertIn(str(run_dir), recovery)

    def test_receipt_verifies_exact_branch_worktree_and_packet(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp) / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "checkout", "-qb", "agent/review-sample"], check=True)
            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(repo), "branch": "agent/review-sample",
                       "packet": "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"}
            parsed = runner.parse_claim_receipt("CLAIMED\n" + runner.CLAIM_SENTINEL + json.dumps(receipt), "review-sample", repo)
            self.assertEqual(parsed["workstream"], "review-sample")
            receipt["workstream"] = "other-review"
            with self.assertRaisesRegex(runner.RunnerError, "does not verify"):
                runner.parse_claim_receipt(runner.CLAIM_SENTINEL + json.dumps(receipt), "review-sample", repo)

    def test_prompt_is_durable_evidence_only_and_safe_logs_redact_secrets(self):
        prompt = runner.prompt_for("review-sample", "review.md", "archived/impl.md")
        self.assertIn("Do not use, request, or infer the implementation-session transcript", prompt)
        self.assertNotIn("transcript contents", prompt)
        line = json.dumps({"type": "event", "api_key": "private-value", "message": "Bearer abcdefghijklmnop"})
        safe = runner.safe_output(line)
        self.assertNotIn("private-value", safe)
        self.assertNotIn("abcdefghijklmnop", safe)

    def test_next_handoff_is_returned_from_durable_summary(self):
        summary = "## Findings\nPass\n\n## Next Handoff\n- Next workstream: none\n- Next action: done\n"
        self.assertIn("Next workstream: none", runner.next_handoff(summary))

    def test_nonzero_codex_exit_is_preserved_with_sanitized_streamed_logs(self):
        class Input(io.StringIO):
            def close(self):
                self.captured = self.getvalue()
                super().close()
        class FailedCodex:
            returncode = 19
            def __init__(self, argv, **kwargs):
                self.stdin = Input()
                self.stdout = io.StringIO('{"api_key":"never-log-this"}\n')
                self.stderr = io.StringIO("codex failed\n")
            def wait(self, timeout=None):
                return self.returncode
        with tempfile.TemporaryDirectory() as temp:
            run_dir = Path(temp)
            with patch.object(runner.subprocess, "Popen", side_effect=lambda argv, **kwargs: FailedCodex(argv, **kwargs)):
                exit_code = runner.launch_codex(["codex", "exec"], Path(temp), "review", run_dir, None)
            self.assertEqual(exit_code, 19)
            self.assertNotIn("never-log-this", (run_dir / "codex.jsonl").read_text())
            self.assertIn("codex failed", (run_dir / "codex.stderr").read_text())

    def test_success_claims_exact_review_and_launches_fresh_ephemeral_cwd(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repo = base / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            packet_path = "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"
            (repo / packet_path).parent.mkdir(parents=True)
            (repo / packet_path).write_text(review_packet())
            (repo / "AGENTS.md").write_text("test guidance\n")
            target = repo / "custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md"
            target.parent.mkdir(parents=True)
            target.write_text(target_packet())
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture"], check=True)
            worktree = base / "review-worktree"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", "agent/review-sample", str(worktree)], check=True)

            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(worktree), "branch": "agent/review-sample", "packet": packet_path}
            completed = subprocess.CompletedProcess([], 0, "CLAIMED\n" + runner.CLAIM_SENTINEL + json.dumps(receipt), "")
            original_run = subprocess.run
            def run_side_effect(argv, *args, **kwargs):
                if argv and len(argv) > 1 and str(argv[1]).endswith("dispatch.py"):
                    self.assertEqual(argv[2:5], ["claim", "review-sample", "--agent"])
                    self.assertEqual(argv[5], "codex-reviewer")
                    return completed
                if argv and argv[:2] == ["git", "cat-file"]:
                    return subprocess.CompletedProcess(argv, 0 if summary_available["value"] else 1, "", "")
                return original_run(argv, *args, **kwargs)

            summary_path = "REVIEW_SAMPLE_CLAUDE_SUMMARY.md"
            summary = "## Findings\nPass.\n\n## Next Handoff\n- Next workstream: none\n- Next action: done\n"
            summary_available = {"value": True}
            def git_side_effect(_repo, *args, check=True):
                if args == ("rev-parse", "--show-toplevel"):
                    return str(repo)
                if args == ("branch", "--show-current"):
                    return "agent/review-sample"
                if args[:2] == ("fetch", "origin"):
                    return ""
                if args[:2] == ("grep", "-l"):
                    return summary_path if summary_available["value"] else ""
                if args[:2] == ("cat-file", "-e"):
                    return ""
                if args[:1] == ("show",) and args[1] == f"origin/main:{summary_path}":
                    return summary
                if args[:1] == ("show",) and args[1] == f"origin/main:{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md":
                    return review_packet().replace("Status: `ready`", "Status: `complete`")
                raise AssertionError(f"unexpected git call: {args}")

            class CaptureInput(io.StringIO):
                captured = ""
                def close(self):
                    self.captured = self.getvalue()
                    super().close()

            self_test = self
            class FakeCodex:
                def __init__(self, argv, cwd, stdin, stdout, stderr, text, bufsize):
                    self.argv, self.cwd = argv, cwd
                    self.stdin = CaptureInput()
                    self.stdout = io.StringIO(json.dumps({"type": "done", "api_key": "should-not-persist"}) + "\n")
                    self.stderr = io.StringIO()
                    self.returncode = 0
                    self.prompt = ""
                def wait(self, timeout=None):
                    self.prompt = self.stdin.captured
                    self.assert_ephemeral = "--ephemeral" in self.argv
                    self_test.assertEqual(Path(self.cwd), worktree)
                    self_test.assertTrue(self.assert_ephemeral)
                    self_test.assertEqual(self.argv[self.argv.index("--cd") + 1], str(worktree))
                    self_test.assertIn("--approve-for-me", self.argv)
                    self_test.assertNotIn("--sandbox", self.argv)
                    self_test.assertIn("Do not use, request, or infer the implementation-session transcript", self.prompt)
                    output_path = Path(self.argv[self.argv.index("--output-last-message") + 1])
                    output_path.write_text("review complete\n")
                    return self.returncode

            with patch.object(runner, "validate_eligible_review", return_value=(packet_path, review_packet(), runner.parse_packet(packet_path, review_packet()))), \
                 patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                 patch.object(runner.subprocess, "run", side_effect=run_side_effect), \
                 patch.object(runner.subprocess, "Popen", side_effect=lambda argv, **kwargs: FakeCodex(argv, **kwargs)), \
                 patch.object(runner, "git", side_effect=git_side_effect), \
                 patch.object(runner, "common_dir", return_value=repo / ".git"):
                self.assertEqual(runner.run(repo, "review-sample"), 0)
                summary_available["value"] = False
                with self.assertRaisesRegex(runner.RunnerError, "without durable review state"):
                    runner.run(repo, "review-sample")

            run_dirs = list((repo / ".git/custodian-review-runs/review-sample").glob("*"))
            self.assertEqual(len(run_dirs), 2)
            successful_run = next(path for path in run_dirs if json.loads((path / "metadata.json").read_text())["phase"] == "complete")
            log_text = (successful_run / "codex.jsonl").read_text()
            self.assertNotIn("should-not-persist", log_text)
            metadata = json.loads((successful_run / "metadata.json").read_text())
            self.assertEqual(metadata["phase"], "complete")
            self.assertEqual(metadata["next_handoff"].splitlines()[0], "- Next workstream: none")
            failed_run = next(path for path in run_dirs if json.loads((path / "metadata.json").read_text())["phase"] == "failed_missing_durable_review_state")
            self.assertTrue((failed_run / "RECOVERY.md").is_file())


if __name__ == "__main__":
    unittest.main()
