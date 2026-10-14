#!/usr/bin/env python3
"""Focused contract tests for the synchronous paired-review runner."""
from __future__ import annotations

import json
import fcntl
import io
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import paired_review_runner as runner
from review_receipt_delta import (
    read_git_text,
    resolve_target_implementation_commit,
    verify_review_receipt_delta,
)

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


def target_packet(implementation_commit="a" * 40):
    return f"""# Implementation
- Packet schema: `custodian.task_packet.v2`
- Workstream: `sample-impl`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow`
- Implementation commit: `{implementation_commit}`

## Goal
Retain the exact implementation goal.

## Acceptance
Retain the exact acceptance contract.

## Completion Truth
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`

## Implementation
```gdscript
func preserved_code():
    return true
```
"""


def append_receipt(target, *, review_workstream, target_workstream, reviewed_main, implementation_commit):
    section = f"""### Review Receipt: {review_workstream}
- Schema: `custodian.paired_review.v1`
- Review workstream: `{review_workstream}`
- Review target workstream: `{target_workstream}`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{reviewed_main}`
- Reviewed implementation commit: `{implementation_commit}`
"""
    if "## Independent Review\n" in target:
        return target.rstrip("\n") + "\n\n" + section
    return target + f"""
## Independent Review

{section}"""


class PairedReviewRunnerTests(unittest.TestCase):
    def test_real_archived_correction_target_keeps_exact_blob_and_resolves_landing(self):
        pinned_main = "607c76aba831ed5fcc313f00489e10df75a8a375"
        target_path = (
            "custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md"
        )
        target_workstream = "agent-paired-review-coordinator-boundary-v1-review-corrections-1"
        baseline = read_git_text(ROOT, pinned_main, target_path)

        self.assertTrue(baseline.endswith("\n"))
        self.assertFalse(re.search(r"(?m)^- Implementation commit:", baseline))
        self.assertNotEqual(runner.git(ROOT, "show", f"{pinned_main}:{target_path}"), baseline)
        implementation, error = resolve_target_implementation_commit(
            ROOT, pinned_main, target_path, target_workstream, baseline,
        )
        self.assertIsNone(error)
        self.assertEqual(implementation, "16b9dfdd6ce09889b85c61372e02d0eccea5de76")

        candidate = append_receipt(
            baseline, review_workstream="review-agent-paired-review-coordinator-boundary-v1-review-corrections-1",
            target_workstream=target_workstream, reviewed_main=pinned_main,
            implementation_commit=implementation,
        )
        receipt, error = verify_review_receipt_delta(
            baseline, candidate,
            review_workstream="review-agent-paired-review-coordinator-boundary-v1-review-corrections-1",
            target_workstream=target_workstream, reviewed_main=pinned_main,
            target_implementation_commit=implementation,
        )
        self.assertIsNone(error)
        self.assertEqual(receipt["Reviewed implementation commit"], implementation)

    def test_real_surface_lift_archive_resolves_unique_landing_without_follow_ambiguity(self):
        pinned_main = "be58b0b845499f1e4340c8217c09304ab3667904"
        target_path = (
            "custodian/docs/ai_context/task_packets/archived/"
            "ASH_BELL_SURFACE_LIFT_V2_ASSET_INTAKE.md"
        )
        target_workstream = "ash-bell-surface-lift-v2-asset-intake"
        baseline = read_git_text(ROOT, pinned_main, target_path)

        self.assertFalse(re.search(r"(?m)^- Implementation commit:", baseline))
        implementation, error = resolve_target_implementation_commit(
            ROOT, pinned_main, target_path, target_workstream, baseline,
        )
        self.assertIsNone(error)
        self.assertEqual(implementation, "f3b94d0768bc110755f2b9be1d1e60d22fe1577c")

    def test_legacy_archive_identity_rejects_ambiguous_reintroduction_and_wrong_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.name", "Test"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.test"], cwd=repo, check=True)
            target_path = "custodian/docs/ai_context/task_packets/archived/TARGET.md"
            target = repo / target_path
            target.parent.mkdir(parents=True)
            target.write_text(
                "# Target\n- Workstream: `target-impl`\n- Kind: `correction`\n"
                "- Status: `complete`\n- Reviewed main: `0000000000000000000000000000000000000000`\n"
            )
            subprocess.run(["git", "add", target_path], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "archive target"], cwd=repo, check=True)
            first_archive = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, text=True,
                                           check=True, capture_output=True).stdout.strip()
            target.unlink()
            subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "remove target"], cwd=repo, check=True)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(
                "# Target\n- Workstream: `target-impl`\n- Kind: `correction`\n"
                "- Status: `complete`\n- Reviewed main: `0000000000000000000000000000000000000000`\n"
            )
            subprocess.run(["git", "add", target_path], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "reintroduce target"], cwd=repo, check=True)
            pinned_main = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, text=True,
                                        check=True, capture_output=True).stdout.strip()

            _, error = resolve_target_implementation_commit(repo, pinned_main, target_path, "target-impl")
            self.assertEqual(error, "pinned target has no unique complete archive-introduction commit")
            _, error = resolve_target_implementation_commit(repo, pinned_main, target_path, "other-impl")
            self.assertEqual(error, "pinned target is not one complete identified implementation packet")
            self.assertNotEqual(first_archive, pinned_main)

    def test_review_receipt_delta_allows_only_one_valid_append(self):
        main = "b" * 40
        implementation = "a" * 40
        baseline = target_packet(implementation)
        valid = append_receipt(baseline, review_workstream="review-sample", target_workstream="sample-impl",
                               reviewed_main=main, implementation_commit=implementation)
        receipt, error = verify_review_receipt_delta(
            baseline, valid, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNone(error)
        self.assertEqual(receipt["Reviewed implementation commit"], implementation)
        for changed in (
            valid.replace("Status: `passed`", "Status: `findings`"),
            valid.replace("Reviewer provenance: `different-agent`", "Reviewer provenance: `unspecified`"),
            valid.replace(main, "c" * 40),
            valid.replace(implementation, "d" * 40),
            valid.replace("Review workstream: `review-sample`", "Review workstream: `review-spoof`"),
            valid.replace("Review target workstream: `sample-impl`", "Review target workstream: `other-impl`"),
            valid.replace("- Status: `complete`", "- Status: `draft`"),
            valid.replace("Retain the exact implementation goal", "Rewrite the goal"),
            valid.replace("Retain the exact acceptance contract", "Rewrite acceptance"),
            valid.replace("Completion boundary satisfied: `yes`", "Completion boundary satisfied: `no`"),
            valid.replace("return true", "return false"),
            valid + "\n## Independent Review\n\n- Status: `passed`\n",
            valid + "\n### Review Receipt: review-sample\n",
        ):
            _, error = verify_review_receipt_delta(
                baseline, changed, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=main, target_implementation_commit=implementation)
            self.assertIsNotNone(error, changed)

    def test_review_receipt_delta_preserves_prior_receipt_bytes(self):
        main = "b" * 40
        implementation = "a" * 40
        baseline = append_receipt(target_packet(implementation), review_workstream="review-old",
                                  target_workstream="sample-impl", reviewed_main=main,
                                  implementation_commit=implementation)
        candidate = append_receipt(baseline, review_workstream="review-sample",
                                   target_workstream="sample-impl", reviewed_main=main,
                                   implementation_commit=implementation)
        receipt, error = verify_review_receipt_delta(
            baseline, candidate, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNone(error)
        self.assertEqual(receipt["Review workstream"], "review-sample")
        tampered = candidate.replace("Reviewer context: `fresh`", "Reviewer context: `stale`", 1)
        _, error = verify_review_receipt_delta(
            baseline, tampered, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNotNone(error)

    def test_prior_claimed_run_blocks_reclaim_until_recovered(self):
        with tempfile.TemporaryDirectory() as temp:
            common = Path(temp)
            old_run = common / "custodian-review-runs/review-sample/old-run"
            old_run.mkdir(parents=True)
            (old_run / "metadata.json").write_text(json.dumps({"workstream": "review-sample",
                                                               "phase": "post_exit_recovery"}))
            self.assertEqual(runner.unresolved_prior_run(common, "review-sample", "new-run"), old_run)
            metadata = json.loads((old_run / "metadata.json").read_text())
            metadata["phase"] = "complete"
            (old_run / "metadata.json").write_text(json.dumps(metadata))
            self.assertIsNone(runner.unresolved_prior_run(common, "review-sample", "new-run"))

    def test_fetch_failure_is_not_ignored_or_replaced_by_stale_main(self):
        with patch.object(runner, "git", side_effect=runner.RunnerError("FETCH_HEAD is read-only")) as git:
            with self.assertRaisesRegex(runner.RunnerError, "FETCH_HEAD is read-only"):
                runner.fetch_and_pin_main(Path("."))
        self.assertEqual(git.call_count, 1)

    def test_coordinator_commits_only_bounded_review_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            remote = base / "origin.git"
            repo = base / "repo"
            subprocess.run(["git", "init", "--bare", "-q", str(remote)], check=True)
            subprocess.run(["git", "init", "-q", "-b", "main", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            active = f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md"
            archive = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            target_path = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
            readme = f"{runner.PACKET_ROOT}/README.md"
            (repo / active).parent.mkdir(parents=True)
            (repo / active).write_text("active review packet\n")
            (repo / target_path).parent.mkdir(parents=True)
            implementation_file = repo / "implementation.py"
            implementation_file.write_text("implementation\n")
            subprocess.run(["git", "-C", str(repo), "add", "implementation.py"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "implementation"], check=True)
            implementation_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                                text=True, capture_output=True).stdout.strip()
            baseline_target = target_packet(implementation_sha)
            (repo / target_path).write_text(baseline_target)
            (repo / readme).write_text("active packet index\n")
            subprocess.run(["git", "-C", str(repo), "add", active, readme, target_path], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture"], check=True)
            target_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                        text=True, capture_output=True).stdout.strip()
            subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", str(remote)], check=True)
            subprocess.run(["git", "-C", str(repo), "push", "-qu", "origin", "main"], check=True)
            worktree = base / "review-worktree"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", "agent/review-sample",
                            str(worktree)], check=True)
            (worktree / active).unlink()
            (worktree / archive).parent.mkdir(parents=True, exist_ok=True)
            (worktree / target_path).write_text(append_receipt(
                baseline_target, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=target_sha, implementation_commit=implementation_sha))
            (worktree / archive).write_text(f"""# Review
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `{target_path}`
- Authoring chat: `https://chatgpt.com/c/example`

## Independent Review
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-sample`
- Review target workstream: `sample-impl`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{target_sha}`
- Reviewed implementation commit: `{implementation_sha}`
""")
            (worktree / readme).write_text("archived review packet index\n")
            summary = worktree / runner.expected_summary_path("review-sample")
            summary.write_text("Authoring chat: https://chatgpt.com/c/example\n\n## Next Handoff\n- Next workstream: none\n")
            run_dir = base / "run"
            run_dir.mkdir()
            (run_dir / "validation.json").write_text(json.dumps({
                "schema": "custodian.validation.result.v1", "passed": True,
                "coverage": {"complete": True}, "tests": [{"status": "passed"}]}))

            (worktree / "unauthorized.py").write_text("reviewer must not add this\n")
            with self.assertRaisesRegex(runner.RunnerError, "outside its bounded evidence scope"):
                runner.coordinator_finish_review(repo, "review-sample", worktree, active, "sample-impl",
                                                 target_path, baseline_target,
                                                 "https://chatgpt.com/c/example", target_sha, run_dir)
            (worktree / "unauthorized.py").unlink()

            original_run = subprocess.run
            finish_calls = []
            def intercept_finish(argv, *args, **kwargs):
                if any(str(part).endswith("workstream.py") for part in argv):
                    finish_calls.append((argv, kwargs.get("cwd")))
                    return subprocess.CompletedProcess(argv, 0,
                                                        f"finished agent/review-sample; verified {target_sha} reachable from origin/main", "")
                return original_run(argv, *args, **kwargs)

            with patch.object(runner.subprocess, "run", side_effect=intercept_finish):
                landed_sha = runner.coordinator_finish_review(repo, "review-sample", worktree, active, "sample-impl",
                                                             target_path, baseline_target,
                                                             "https://chatgpt.com/c/example", target_sha, run_dir)
            self.assertEqual(landed_sha, target_sha)
            self.assertEqual(len(finish_calls), 1)
            self.assertEqual(Path(finish_calls[0][1]), repo)
            committed = subprocess.run(["git", "-C", str(worktree), "diff-tree", "--no-commit-id",
                                        "--name-only", "-r", "HEAD"], check=True, text=True,
                                       capture_output=True).stdout.splitlines()
            self.assertEqual(set(committed), {active, archive, readme, summary.name, target_path})

    def test_landed_review_uses_exact_summary_and_pinned_git_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            target_path = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
            implementation_file = repo / "implementation.py"
            implementation_file.write_text("implementation\n")
            subprocess.run(["git", "-C", str(repo), "add", "implementation.py"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "implementation"], check=True)
            implementation_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                                text=True, capture_output=True).stdout.strip()
            target_text = target_packet(implementation_sha)
            target_file = repo / target_path
            target_file.parent.mkdir(parents=True)
            target_file.write_text(target_text)
            subprocess.run(["git", "-C", str(repo), "add", target_path], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "target"], check=True)
            target_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                        text=True, capture_output=True).stdout.strip()
            (repo / target_path).write_text(append_receipt(
                target_text, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=target_sha, implementation_commit=implementation_sha))
            review_path = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            review_text = f"""# Review
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `{target_path}`
- Authoring chat: `https://chatgpt.com/c/example`

## Independent Review
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-sample`
- Review target workstream: `sample-impl`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{target_sha}`
- Reviewed implementation commit: `{implementation_sha}`
"""
            summary_path = runner.expected_summary_path("review-sample")
            summary = (f"Authoring chat: https://chatgpt.com/c/example\n\n## Next Handoff\n"
                       "- Next workstream: none\n- Next action: done\n")
            subprocess.run(["git", "-C", str(repo), "add", target_path], check=True)
            for path, content in ((review_path, review_text), (summary_path, summary),
                                   ("UNRELATED_CLAUDE_SUMMARY.md", "review-sample appears here only\n")):
                file = repo / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(content)
            subprocess.run(["git", "-C", str(repo), "add", review_path, summary_path,
                            "UNRELATED_CLAUDE_SUMMARY.md"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "review"], check=True)
            revision = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                      text=True, capture_output=True).stdout.strip()
            reviewer_checkout = repo.parent / "reviewer-checkout"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "--detach",
                            str(reviewer_checkout), revision], check=True, text=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "worktree", "remove", str(reviewer_checkout)],
                           check=True, text=True, capture_output=True)
            grep = subprocess.run(["git", "-C", str(repo), "grep", "-l", "review-sample", revision,
                                   "--", "*_CLAUDE_SUMMARY.md"], check=True, text=True, capture_output=True).stdout
            self.assertIn(f"{revision}:UNRELATED_CLAUDE_SUMMARY.md", grep)
            state = runner.landed_review_state(repo, revision, "review-sample",
                                               f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md", "sample-impl",
                                               target_path, target_text,
                                               "https://chatgpt.com/c/example", target_sha)
            self.assertTrue(state["complete"], state["reasons"])
            self.assertEqual(state["summary_path"], summary_path)

            subprocess.run(["git", "-C", str(repo), "rm", summary_path], check=True,
                           text=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "remove exact summary"], check=True)
            missing_revision = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                              text=True, capture_output=True).stdout.strip()
            missing = runner.landed_review_state(repo, missing_revision, "review-sample",
                                                 f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md", "sample-impl",
                                                 target_path, target_text,
                                                 "https://chatgpt.com/c/example", target_sha)
            self.assertFalse(missing["complete"])
            self.assertTrue(missing["reasons"])

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
                     patch.object(runner, "read_git_text", return_value=target), \
                     patch.object(runner, "git", return_value="a" * 40), \
                     patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
                    runner.validate_eligible_review(Path("."), "review-sample")

    def test_successor_scoped_refresh_planning_authority_does_not_gate_review(self):
        content = review_packet() + """
## Refresh Planning Authority
- Refresh applies to: `successor`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh instruction: After this review passes, plan the next slice.

## Handoff
- Next workstream: `next-slice`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
"""
        packet = runner.parse_packet("review.md", content)
        with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)), \
             patch.object(runner, "read_git_text", return_value=target_packet()), \
             patch.object(runner, "git", return_value="a" * 40), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
            runner.validate_eligible_review(Path("."), "review-sample")

        for gated in (
            content.replace("- Refresh applies to: `successor`\n", ""),
            content.replace("- Next workstream: `next-slice`", "- Next workstream: `none`"),
            content.split("## Handoff", 1)[0],
            content.replace("- ChatGPT/user planning refresh required: `no`",
                            "- ChatGPT/user planning refresh required: `yes`", 1),
        ):
            with self.subTest(gated=gated[-90:]):
                parsed = runner.parse_packet("review.md", gated)
                with patch.object(runner, "packet_at_main", return_value=("review.md", gated, parsed)):
                    with self.assertRaisesRegex(runner.RunnerError, "human planning|human-owned"):
                        runner.validate_eligible_review(Path("."), "review-sample")

    def test_actual_vaultwing_review_successor_refresh_is_not_a_current_gate(self):
        review_path = "custodian/docs/ai_context/task_packets/REVIEW_VAULTWING_RUNTIME_HARDENING.md"
        content = (ROOT / review_path).read_text(encoding="utf-8")
        self.assertIn("- Refresh applies to: `successor`", content)
        parsed = runner.parse_packet(review_path, content)
        self.assertIsNone(parsed.error)
        self.assertEqual(parsed.status, "ready")
        target = (ROOT / parsed.review_target_packet).read_text(encoding="utf-8")
        with patch.object(runner, "packet_at_main", return_value=(review_path, content, parsed)), \
             patch.object(runner, "git", return_value=target), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
            runner.validate_eligible_review(ROOT, "review-vaultwing-runtime-hardening")

    def test_actual_wb25_review_packet_is_eligible_despite_successor_refresh(self):
        # WB25's review correctly left the active queue after closeout. Reuse the
        # immutable historical packet, restoring only pre-claim lifecycle metadata
        # in memory so this regression survives normal archive transitions.
        review_path = "custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md"
        archived_content = (ROOT / review_path).read_text(encoding="utf-8")
        self.assertIn("- Status: complete", archived_content)
        self.assertIn("- Review: none", archived_content)
        archived_packet_data = runner.parse_packet(review_path, archived_content)
        self.assertIsNone(archived_packet_data.error)
        self.assertEqual(archived_packet_data.status, "complete")
        self.assertEqual(archived_packet_data.review, "none")
        review_content = archived_content.replace("- Status: complete", "- Status: ready", 1)
        review_packet_data = runner.parse_packet(review_path, review_content)
        self.assertIsNone(review_packet_data.error)
        target_content = (ROOT / review_packet_data.review_target_packet).read_text(encoding="utf-8")
        with patch.object(runner, "packet_at_main", return_value=(review_path, review_content, review_packet_data)), \
             patch.object(runner, "git", return_value=target_content), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
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
                 patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
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
        self.assertIn("Do not run `git fetch`, `git push`, `git add`, `git commit`", prompt)
        self.assertIn("workstream.py finish", prompt)
        self.assertIn("validation.json", prompt)
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
                if argv and argv[:2] == ["git", "show"]:
                    requested = argv[2]
                    if requested == f"{'a' * 40}:{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md":
                        return subprocess.CompletedProcess(argv, 0, target_packet(), "")
                    if requested == f"{'a' * 40}:{summary_path}":
                        return subprocess.CompletedProcess(argv, 0, summary if summary_available["value"] else "", "")
                if argv and argv[:2] == ["git", "cat-file"]:
                    return subprocess.CompletedProcess(argv, 0 if summary_available["value"] else 1, "", "")
                return original_run(argv, *args, **kwargs)

            summary_path = "REVIEW_SAMPLE_CLAUDE_SUMMARY.md"
            summary = "## Findings\nPass.\n\n## Next Handoff\n- Next workstream: none\n- Next action: done\n"
            summary_available = {"value": True}
            def git_side_effect(_repo, *args, check=True):
                if args == ("rev-parse", "--show-toplevel"):
                    return str(repo)
                if args == ("show", f"{'a' * 40}:{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"):
                    return target_packet()
                if args == ("show", f"{'a' * 40}:{summary_path}"):
                    return summary if summary_available["value"] else ""
                if args == ("rev-parse", "--verify", "origin/main^{commit}"):
                    return "a" * 40
                if args == ("branch", "--show-current"):
                    return "agent/review-sample"
                if args[:3] == ("fetch", "origin", "main"):
                    return ""
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
                    report_path = Path(self.argv[self.argv.index("--add-dir") + 1]) / "validation.json"
                    report_path.write_text(json.dumps({"schema": "custodian.validation.result.v1", "passed": True,
                                                       "coverage": {"complete": True}, "tests": [{"status": "passed"}]}))
                    output_path = Path(self.argv[self.argv.index("--output-last-message") + 1])
                    output_path.write_text("review complete\n")
                    return self.returncode

            with patch.object(runner, "validate_eligible_review", return_value=(packet_path, review_packet(), runner.parse_packet(packet_path, review_packet()))), \
                 patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                 patch.object(runner.subprocess, "run", side_effect=run_side_effect), \
                 patch.object(runner.subprocess, "Popen", side_effect=lambda argv, **kwargs: FakeCodex(argv, **kwargs)), \
                 patch.object(runner, "git", side_effect=git_side_effect), \
                 patch.object(runner, "coordinator_finish_review", return_value="a" * 40), \
                 patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
                 patch.object(runner, "landed_review_state", side_effect=lambda *args: {
                     "complete": summary_available["value"], "summary_path": summary_path,
                     "reasons": [] if summary_available["value"] else ["missing exact summary"]}), \
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
