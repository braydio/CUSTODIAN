#!/usr/bin/env python3
"""Findings/human_required closeout and same-run recovery tests (real Git, no mocks of the gates)."""
from __future__ import annotations

import fcntl
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import paired_review_runner as runner
import review_outcome
from test_paired_review_runner import append_receipt, target_packet

WORKSTREAM = "review-sample"
TARGET_WORKSTREAM = "sample-impl"
RUN_ID = "20261016T000000Z-0123456789ab"
CHAT = "https://chatgpt.com/c/example"
ACTIVE = f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md"
ARCHIVE = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
TARGET = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
README = f"{runner.PACKET_ROOT}/README.md"
SUMMARY = runner.expected_summary_path(WORKSTREAM)
SIDECAR = "custodian/tools/validation/sample_smoke.gd.uid"
SIDECAR_BYTES = b"uid://sidecar-must-survive\n"

REVIEW_HEADER = f"""# Review
- Packet schema: `custodian.task_packet.v2`
- Workstream: `{WORKSTREAM}`
- Kind: `review`
- Status: `{{status}}`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `{TARGET_WORKSTREAM}`
- Locks: `agent-workflow`
- Review target workstream: `{TARGET_WORKSTREAM}`
- Review target packet: `{TARGET}`
- Authoring chat: `{CHAT}`

## Goal
Review the sample implementation.
"""
FINDING = "\n## Independent Review Findings\n\n**R0-01 - Blocking defect: sample behavior is wrong.**\n"
SUMMARY_TEXT = f"Authoring chat: {CHAT}\n\n## Next Handoff\n- Next workstream: none\n"


def sh(cwd, *args, check=True):
    result = subprocess.run(["git", "-C", str(cwd), *args], text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


class Fixture:
    """A published main, a stranded review branch/worktree and a protected run directory."""

    def __init__(self, base: Path, *, sidecar: bool = True):
        self.base = base
        self.remote = base / "origin.git"
        self.repo = base / "repo"
        subprocess.run(["git", "init", "--bare", "-q", str(self.remote)], check=True)
        subprocess.run(["git", "init", "-q", "-b", "main", str(self.repo)], check=True)
        sh(self.repo, "config", "user.name", "test")
        sh(self.repo, "config", "user.email", "test@example.invalid")
        (self.repo / "implementation.py").write_text("implementation\n")
        sh(self.repo, "add", "implementation.py")
        sh(self.repo, "commit", "-qm", "implementation")
        self.implementation = sh(self.repo, "rev-parse", "HEAD")
        self.baseline = target_packet(self.implementation)
        for path, text in ((TARGET, self.baseline), (ACTIVE, REVIEW_HEADER.format(status="ready")),
                           (README, "- [review-sample](REVIEW_SAMPLE.md)\n")):
            (self.repo / path).parent.mkdir(parents=True, exist_ok=True)
            (self.repo / path).write_text(text)
        sh(self.repo, "add", "-A")
        sh(self.repo, "commit", "-qm", "fixture")
        sh(self.repo, "remote", "add", "origin", str(self.remote))
        sh(self.repo, "push", "-qu", "origin", "main")
        self.reviewed_main = sh(self.repo, "rev-parse", "HEAD")
        self.worktree = base / "review-worktree"
        sh(self.repo, "worktree", "add", "-qb", f"agent/{WORKSTREAM}", str(self.worktree))
        (self.worktree / ACTIVE).write_text(REVIEW_HEADER.format(status="blocked") + FINDING)
        (self.worktree / SUMMARY).write_text(SUMMARY_TEXT)
        sh(self.worktree, "add", "-A")
        sh(self.worktree, "commit", "-qm", "review finding")
        sh(self.worktree, "push", "-qu", "origin", f"agent/{WORKSTREAM}")
        self.tip = sh(self.worktree, "rev-parse", "HEAD")
        if sidecar:
            (self.worktree / SIDECAR).parent.mkdir(parents=True, exist_ok=True)
            (self.worktree / SIDECAR).write_bytes(SIDECAR_BYTES)
        self.common = (self.repo / ".git").resolve()
        self.run_dir = self.common / "custodian-review-runs" / WORKSTREAM / RUN_ID
        self.run_dir.mkdir(parents=True)
        self.write_metadata()
        receipt = {"schema": "custodian.dispatch.claim.v1", "result": "claimed", "workstream": WORKSTREAM,
                   "branch": f"agent/{WORKSTREAM}", "worktree": str(self.worktree), "packet": ACTIVE,
                   "verified": True}
        (self.run_dir / "claim.stdout").write_text(runner.CLAIM_SENTINEL + json.dumps(receipt) + "\n")
        (self.run_dir / "codex.jsonl").write_text('{"original": "evidence"}\n')
        self.checkout = base / "recovery-checkout"

    def write_metadata(self, **override):
        metadata = {"schema": runner.SCHEMA, "run_id": RUN_ID, "workstream": WORKSTREAM,
                    "phase": "post_exit_recovery", "branch": f"agent/{WORKSTREAM}",
                    "worktree": str(self.worktree), "packet": ACTIVE, "reviewed_main": self.reviewed_main}
        metadata.update(override)
        (self.run_dir / "metadata.json").write_text(json.dumps(metadata))

    def outcome(self, outcome="findings", **override):
        values = dict(outcome=outcome, review_workstream=WORKSTREAM, target_workstream=TARGET_WORKSTREAM,
                      reviewed_main=self.reviewed_main, implementation_commit=self.implementation,
                      provenance="same-agent-fresh-context", run_id=RUN_ID, review_cycle=0,
                      ids=("R0-01",) if outcome != "passed" else ())
        values.update(override)
        return review_outcome.render_review_outcome(**values)

    def reviewer_closeout(self, section: str | None = None):
        """What a reviewer (or the recovery) leaves in the worktree for a findings closeout."""
        text = (self.worktree / ACTIVE).read_text().replace("Status: `blocked`", "Status: `complete`")
        (self.worktree / ARCHIVE).parent.mkdir(parents=True, exist_ok=True)
        body = self.outcome() if section is None else section
        (self.worktree / ARCHIVE).write_text(text.rstrip("\n") + "\n\n" + body)
        (self.worktree / ACTIVE).unlink()

    def lander(self, checkout: Path):
        sh(checkout, "push", "origin", "HEAD:main")

    def recover(self, **kwargs):
        defaults = dict(isolated_checkout=self.checkout, outcome="findings", ids=("R0-01",),
                        provenance="same-agent-fresh-context", apply=True, lander=self.lander)
        defaults.update(kwargs)
        return runner.recover_closeout(self.repo, WORKSTREAM, RUN_ID, **defaults)

    def snapshot(self):
        """Everything recovery must never change about the protected original."""
        names = sorted(p.name for p in self.run_dir.iterdir() if p.name not in {runner.JOURNAL_NAME,
                                                                                   "closeout-integrity.json"})
        return {
            "head": sh(self.worktree, "rev-parse", "HEAD"), "branch": sh(self.worktree, "branch", "--show-current"),
            "status": sh(self.worktree, "status", "--porcelain=v1", "--untracked-files=all"),
            "sidecar": (self.worktree / SIDECAR).read_bytes() if (self.worktree / SIDECAR).exists() else None,
            "evidence": {name: (self.run_dir / name).read_bytes() for name in names},
        }

    def remote_branch_exists(self):
        return bool(sh(self.repo, "ls-remote", "--heads", "origin", f"refs/heads/agent/{WORKSTREAM}"))

    def main_commits_touching(self, path):
        sh(self.repo, "fetch", "-q", "origin", "main")
        return len(sh(self.repo, "log", "--format=%H", "origin/main", "--", path).splitlines())


class FixtureCase(unittest.TestCase):
    sidecar = True

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.fx = Fixture(Path(self.temp.name), sidecar=self.sidecar)


class NonpassingCoordinatorTests(FixtureCase):
    sidecar = False

    def finish_intercept(self, landed="f" * 40):
        calls = []
        original = subprocess.run

        def fake(argv, *args, **kwargs):
            if any(str(part).endswith("workstream.py") for part in argv):
                calls.append(list(argv))
                return subprocess.CompletedProcess(argv, 0, f"verified {landed} reachable from origin/main", "")
            return original(argv, *args, **kwargs)
        return calls, patch.object(runner.subprocess, "run", side_effect=fake)

    def close(self):
        fx = self.fx
        return runner.coordinator_finish_nonpassing_review(
            fx.repo, WORKSTREAM, fx.worktree, ACTIVE, TARGET_WORKSTREAM, TARGET, fx.baseline, CHAT,
            fx.reviewed_main, fx.run_dir)

    def test_findings_closeout_commits_evidence_only_and_never_touches_the_target(self):
        self.fx.reviewer_closeout()
        calls, finish = self.finish_intercept()
        with finish:
            self.assertEqual(self.close(), "f" * 40)
        self.assertEqual(len(calls), 1)
        committed = set(sh(self.fx.worktree, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").splitlines())
        self.assertEqual(committed, {ACTIVE, ARCHIVE})
        self.assertEqual((self.fx.worktree / TARGET).read_text(), self.fx.baseline)
        self.assertEqual(sh(self.fx.worktree, "diff", self.fx.reviewed_main, "HEAD", "--", TARGET), "")
        report = json.loads((self.fx.run_dir / "closeout-integrity.json").read_text())
        self.assertTrue(runner.validation_report_is_green(self.fx.run_dir / "closeout-integrity.json"))
        self.assertIn("closeout integrity only", report["scope"])
        self.assertEqual(report["outcome"], "findings")
        self.assertIn(str(self.fx.run_dir / "closeout-integrity.json"), calls[0])

    def test_human_required_closeout_is_accepted_the_same_way(self):
        self.fx.reviewer_closeout(self.fx.outcome("human_required"))
        _, finish = self.finish_intercept()
        with finish:
            self.close()

    def test_unsafe_closeouts_are_rejected_before_any_commit(self):
        fx = self.fx
        passing_target = append_receipt(
            fx.baseline, review_workstream=WORKSTREAM, target_workstream=TARGET_WORKSTREAM,
            reviewed_main=fx.reviewed_main, implementation_commit=fx.implementation)
        cases = {
            "target gained a pass receipt": (None, lambda: (fx.worktree / TARGET).write_text(passing_target),
                                             "outside its bounded evidence scope"),
            "extra file": (None, lambda: (fx.worktree / "extra.py").write_text("x\n"), "outside its bounded"),
            "pass outcome in nonpassing path": (fx.outcome("passed"), None, "not a findings or human_required"),
            "no outcome section": ("", None, "no Review Outcome"),
            "wrong run id": (fx.outcome(run_id="20261016T000001Z-0123456789ab"), None, "does not match the pinned"),
            "wrong implementation": (fx.outcome(implementation_commit="d" * 40), None, "does not match the pinned"),
            "wrong reviewed main": (fx.outcome(reviewed_main="e" * 40), None, "does not match the pinned"),
            "wrong review workstream": (fx.outcome(review_workstream="review-other"), None, "does not match the pinned"),
            "finding without evidence": (fx.outcome(ids=("R0-01", "R0-02")), None, "R0-02 has no written evidence"),
            "wrong cycle": (fx.outcome(review_cycle=1, ids=("R1-01",)), None, "does not match the pinned"),
        }
        for label, (section, mutate, expected) in cases.items():
            with self.subTest(label):
                sh(fx.worktree, "reset", "-q", "--hard", fx.tip)
                sh(fx.worktree, "clean", "-qfd")
                fx.reviewer_closeout(section)
                if mutate:
                    mutate()
                head = sh(fx.worktree, "rev-parse", "HEAD")
                with self.assertRaisesRegex(runner.RunnerError, expected):
                    self.close()
                self.assertEqual(sh(fx.worktree, "rev-parse", "HEAD"), head, "no commit may be made")
                self.assertEqual(sh(fx.worktree, "diff", "--cached", "--name-only"), "")

    def test_summary_without_next_handoff_or_backlink_is_rejected(self):
        for label, text, expected in (("no handoff", f"Authoring chat: {CHAT}\n", "Next Handoff"),
                                      ("no backlink", "## Next Handoff\n- x\n", "authoring-chat backlink")):
            with self.subTest(label):
                sh(self.fx.worktree, "reset", "-q", "--hard", self.fx.tip)
                self.fx.reviewer_closeout()
                (self.fx.worktree / SUMMARY).write_text(text)
                with self.assertRaisesRegex(runner.RunnerError, expected):
                    self.close()

    def test_staged_evidence_is_refused_and_retry_after_interrupted_finish_adds_no_second_commit(self):
        fx = self.fx
        fx.reviewer_closeout()
        sh(fx.worktree, "add", ACTIVE)
        with self.assertRaisesRegex(runner.RunnerError, "staged evidence before coordinator"):
            self.close()
        sh(fx.worktree, "reset", "-q")
        original = subprocess.run
        failures = []

        def fail_once(argv, *args, **kwargs):
            if any(str(part).endswith("workstream.py") for part in argv):
                failures.append(1)
                return subprocess.CompletedProcess(argv, 1, "", "interrupted landing")
            return original(argv, *args, **kwargs)
        with patch.object(runner.subprocess, "run", side_effect=fail_once):
            with self.assertRaisesRegex(runner.RunnerError, "branch and evidence preserved"):
                self.close()
        head = sh(fx.worktree, "rev-parse", "HEAD")
        _, finish = self.finish_intercept()
        with finish:
            self.close()
        self.assertEqual(sh(fx.worktree, "rev-parse", "HEAD"), head, "retry must converge without a new commit")
        self.assertEqual(sh(fx.worktree, "rev-list", "--count", f"{fx.tip}..HEAD"), "1")

    def test_ordinary_pass_path_rejects_a_findings_closeout(self):
        fx = self.fx
        fx.reviewer_closeout()
        (fx.run_dir / "validation.json").write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": True, "coverage": {"complete": True},
            "tests": [{"status": "passed"}]}))
        metadata_path = fx.run_dir / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata.update({"fresh": True, "exit_code": 0, "run_dir": str(fx.run_dir),
                         "implementation_commit": fx.implementation, "review_cycle": 0})
        metadata_path.write_text(json.dumps(metadata))
        final = (f"Workstream: {WORKSTREAM}\nReviewed main: {fx.reviewed_main}\n"
                 f"Reviewed implementation commit: {fx.implementation}\n"
                 "Verdict: findings — 1 blocking defect and 0 material gaps. R0-01.\n")
        (fx.run_dir / "last-message.txt").write_text(final)
        events = [
            {"type": "thread.started", "thread_id": "synthetic-findings-thread"},
            {"type": "turn.started"},
            {"item": {"type": "agent_message", "text": final}},
            {"type": "turn.completed"},
        ]
        (fx.run_dir / "codex.jsonl").write_text(
            "".join(json.dumps(event) + "\n" for event in events))
        before = fx.snapshot()
        refs_before = sh(fx.repo, "for-each-ref")
        host_evidence = {"implementation_commit": fx.implementation,
                         "report_sha256": "pinned-report", "metadata_sha256": "pinned-metadata"}
        with patch.object(runner, "verify_coordinator_validation"):
            with self.assertRaisesRegex(runner.RunnerError, "archived packet does not contain one canonical PASS outcome"):
                runner.coordinator_finish_review(
                    fx.repo, WORKSTREAM, fx.worktree, ACTIVE, TARGET_WORKSTREAM, TARGET,
                    fx.baseline, CHAT, fx.reviewed_main, fx.run_dir, host_evidence)
        self.assertEqual(fx.snapshot(), before)
        self.assertEqual(sh(fx.repo, "for-each-ref"), refs_before)


class RecoverCloseoutTests(FixtureCase):
    def test_plan_is_read_only_and_reports_the_protected_inventory(self):
        fx = self.fx
        before = fx.snapshot()
        refs = sh(fx.repo, "for-each-ref")
        plan = fx.recover(apply=False)
        self.assertEqual(plan["mode"], "plan")
        self.assertEqual(plan["published_tip"], fx.tip)
        self.assertEqual(plan["implementation_commit"], fx.implementation)
        self.assertIn(SIDECAR, plan["protected_files"])
        self.assertEqual(fx.snapshot(), before)
        self.assertEqual(sh(fx.repo, "for-each-ref"), refs)
        self.assertFalse((fx.run_dir / runner.JOURNAL_NAME).exists())
        self.assertFalse(fx.checkout.exists())

    def test_apply_closes_as_findings_lands_once_and_leaves_the_original_untouched(self):
        fx = self.fx
        before = fx.snapshot()
        result = fx.recover()
        self.assertEqual(result["stage"], "complete")
        self.assertEqual(result["outcome"], "findings")
        self.assertFalse(result["claim_released"])
        self.assertTrue(result["claim_release_pending"])
        self.assertTrue(fx.remote_branch_exists(), "claim is released only on explicit request")
        self.assertEqual(fx.snapshot(), before, "original claim, worktree, sidecar and run evidence are immutable")
        sh(fx.repo, "fetch", "-q", "origin", "main")
        archived = sh(fx.repo, "show", f"origin/main:{ARCHIVE}")
        parsed, error = review_outcome.parse_review_outcome(archived)
        self.assertIsNone(error)
        self.assertEqual((parsed["Outcome"], parsed["Run ID"], parsed["Reviewed implementation commit"]),
                         ("findings", RUN_ID, fx.implementation))
        self.assertIn("Status: `complete`", archived)
        self.assertIn("R0-01", archived)
        self.assertEqual(sh(fx.repo, "show", f"origin/main:{TARGET}"), fx.baseline.rstrip("\n"))
        self.assertNotEqual(subprocess.run(["git", "-C", str(fx.repo), "cat-file", "-e", f"origin/main:{ACTIVE}"],
                                           capture_output=True).returncode, 0, "the active packet must be archived")
        self.assertEqual(json.loads((fx.run_dir / runner.JOURNAL_NAME).read_text())["stage"], "complete")
        self.assertTrue(runner.validation_report_is_green(fx.run_dir / "closeout-integrity.json"))

    def test_release_claim_deletes_only_the_remote_branch_after_landing(self):
        fx = self.fx
        before = fx.snapshot()
        result = fx.recover(release_claim=True)
        self.assertTrue(result["claim_released"])
        self.assertFalse(fx.remote_branch_exists())
        self.assertEqual(fx.snapshot(), before)
        self.assertTrue((fx.worktree / SIDECAR).exists(), "the protected local worktree and its sidecar remain")

    def test_repeated_recovery_converges_to_the_identical_result(self):
        fx = self.fx
        first = fx.recover()
        main_after_first = sh(fx.repo, "rev-parse", "origin/main")
        second = fx.recover()
        third = fx.recover(apply=False)
        self.assertEqual(first, second)
        self.assertEqual(first, third)
        sh(fx.repo, "fetch", "-q", "origin", "main")
        self.assertEqual(sh(fx.repo, "rev-parse", "origin/main"), main_after_first)
        self.assertEqual(fx.main_commits_touching(ARCHIVE), 1)
        self.assertEqual(sh(fx.repo, "branch", "--list", "recovery/*").count("recovery/"), 1)

    def test_interrupted_landing_resumes_without_a_second_commit_or_claim(self):
        fx = self.fx

        def failing_lander(_checkout):
            raise runner.RunnerError("land_main blocked; simulated interruption")
        with self.assertRaisesRegex(runner.RunnerError, "simulated interruption"):
            fx.recover(lander=failing_lander)
        journal = json.loads((fx.run_dir / runner.JOURNAL_NAME).read_text())
        self.assertEqual(journal["stage"], "published")
        commit_after_interruption = sh(fx.checkout, "rev-parse", "HEAD")
        result = fx.recover()
        self.assertEqual(result["stage"], "complete")
        self.assertEqual(result["landed_commit"], commit_after_interruption)
        self.assertEqual(fx.main_commits_touching(ARCHIVE), 1)

    def test_interrupted_after_commit_stage_resumes_from_the_journal(self):
        fx = self.fx
        with patch.object(runner, "landed_nonpassing_review_state",
                          side_effect=runner.RunnerError("simulated crash after commit")):
            with self.assertRaisesRegex(runner.RunnerError, "simulated crash"):
                fx.recover()
        self.assertEqual(json.loads((fx.run_dir / runner.JOURNAL_NAME).read_text())["stage"], "committed")
        commits = sh(fx.checkout, "rev-list", "--count", f"{fx.tip}..HEAD")
        result = fx.recover()
        self.assertEqual(result["stage"], "complete")
        self.assertEqual(sh(fx.checkout, "rev-list", "--count", f"{fx.tip}..HEAD"), commits)

    def test_sync_with_a_moved_main_revalidates_and_still_lands(self):
        fx = self.fx
        (fx.repo / "unrelated.txt").write_text("other work landed meanwhile\n")
        sh(fx.repo, "add", "unrelated.txt")
        sh(fx.repo, "commit", "-qm", "unrelated")
        sh(fx.repo, "push", "-q", "origin", "main")
        result = fx.recover()
        self.assertEqual(result["stage"], "complete")
        sh(fx.repo, "fetch", "-q", "origin", "main")
        self.assertEqual(sh(fx.repo, "show", "origin/main:unrelated.txt"), "other work landed meanwhile")

    def test_falsified_stale_or_mismatched_identity_is_refused_before_any_write(self):
        fx = self.fx

        def tamper_claim_worktree():
            path = fx.run_dir / "claim.stdout"
            path.write_text(path.read_text().replace(str(fx.worktree), str(fx.base / "elsewhere")))

        cases = {
            "unknown run": (lambda: fx.run_dir.joinpath("metadata.json").unlink(), "metadata is missing"),
            "wrong phase": (lambda: fx.write_metadata(phase="complete"), "not a recoverable post-exit"),
            "wrong schema": (lambda: fx.write_metadata(schema="other.v1"), "does not match the requested"),
            "foreign workstream": (lambda: fx.write_metadata(workstream="review-other"), "does not match the requested"),
            "falsified claim worktree": (tamper_claim_worktree, "could not be verified"),
            "stale reviewed main": (lambda: fx.write_metadata(reviewed_main="1" * 40), "not an ancestor|identity is invalid|cat-file|fatal"),
            "metadata branch swapped": (lambda: fx.write_metadata(branch="agent/review-other"), "do not name the same"),
        }
        for label, (mutate, expected) in cases.items():
            with self.subTest(label):
                fx.write_metadata()
                (fx.run_dir / "claim.stdout").write_text(
                    runner.CLAIM_SENTINEL + json.dumps({
                        "schema": "custodian.dispatch.claim.v1", "result": "claimed", "workstream": WORKSTREAM,
                        "branch": f"agent/{WORKSTREAM}", "worktree": str(fx.worktree), "packet": ACTIVE,
                        "verified": True}) + "\n")
                mutate()
                with self.assertRaisesRegex(runner.RunnerError, expected):
                    fx.recover()
                self.assertFalse((fx.run_dir / runner.JOURNAL_NAME).exists())
                self.assertFalse(fx.checkout.exists())

    def write_truncated_claim(self, *, header=None, drop=(), worktree=None):
        """The real stranded run stored claim.stdout cut off mid-JSON after the plain header."""
        fx = self.fx
        values = {"workstream": WORKSTREAM, "branch": f"agent/{WORKSTREAM}",
                  "worktree": worktree or str(fx.worktree), "packet": ACTIVE}
        values.update(header or {})
        lines = ["CLAIMED"] + [f"{key}: {value}" for key, value in values.items() if key not in drop]
        lines += ["visual review: none", "", "NEXT:", "Read AGENTS.md.", "agent: codex-reviewer",
                  runner.CLAIM_SENTINEL + '{"schema": "custodian.dispatch.claim.v1", "result": "claimed", "work']
        (fx.run_dir / "claim.stdout").write_text("\n".join(lines))

    def test_a_truncated_claim_receipt_falls_back_to_the_verified_header_and_recovers(self):
        fx = self.fx
        self.write_truncated_claim()
        before = fx.snapshot()
        plan = fx.recover(apply=False)
        self.assertEqual(plan["original_worktree"], str(fx.worktree))
        result = fx.recover()
        self.assertEqual(result["stage"], "complete")
        self.assertEqual(fx.snapshot(), before)

    def test_the_fallback_is_used_and_conflicting_or_unverifiable_claims_are_refused(self):
        fx = self.fx
        self.write_truncated_claim()
        claim = runner._claim_identity(fx.run_dir, WORKSTREAM, fx.repo, json.loads((fx.run_dir / "metadata.json").read_text()))
        self.assertIn("header", claim["source"])
        path = fx.run_dir / "claim.stdout"
        path.write_text(path.read_text() + "\n" + runner.CLAIM_SENTINEL + "{}")
        with self.assertRaises(runner.RunnerError):
            runner._claim_identity(fx.run_dir, WORKSTREAM, fx.repo, json.loads((fx.run_dir / "metadata.json").read_text()))
        self.write_truncated_claim(header={"worktree": str(fx.base / "missing")})
        meta = json.loads((fx.run_dir / "metadata.json").read_text())
        meta["worktree"] = str(fx.base / "missing")
        with self.assertRaisesRegex(runner.RunnerError, "could not be verified"):
            runner._claim_identity(fx.run_dir, WORKSTREAM, fx.repo, meta)

    def test_a_truncated_claim_receipt_still_fails_closed_on_any_disagreement(self):
        fx = self.fx
        cases = {
            "header worktree differs from metadata": (dict(worktree=str(fx.base / "elsewhere")),
                                                      "does not match the run metadata identity"),
            "header branch differs from metadata": (dict(header={"branch": "agent/review-other"}),
                                                    "does not match the run metadata identity"),
            "header packet differs from metadata": (dict(header={"packet": f"{runner.PACKET_ROOT}/OTHER.md"}),
                                                    "does not match the run metadata identity"),
            "header omits a field": (dict(drop=("packet",)), "does not match the run metadata identity"),
            "header repeats a field": (None, "repeats workstream"),
        }
        for label, (kwargs, expected) in cases.items():
            with self.subTest(label):
                if kwargs is None:
                    self.write_truncated_claim()
                    path = fx.run_dir / "claim.stdout"
                    path.write_text(path.read_text().replace("branch:", f"workstream: {WORKSTREAM}\nbranch:", 1))
                else:
                    self.write_truncated_claim(**kwargs)
                with self.assertRaisesRegex(runner.RunnerError, expected):
                    fx.recover(apply=False)
        (fx.run_dir / "claim.stdout").write_text("garbage with no header\n")
        with self.assertRaisesRegex(runner.RunnerError, "neither a parseable receipt nor a CLAIMED header"):
            fx.recover(apply=False)

    def test_a_parseable_but_unverified_receipt_never_falls_back_to_the_header(self):
        fx = self.fx
        self.write_truncated_claim()
        receipt = {"schema": "custodian.dispatch.claim.v1", "result": "started", "workstream": WORKSTREAM,
                   "branch": f"agent/{WORKSTREAM}", "worktree": str(fx.worktree), "packet": ACTIVE,
                   "verified": True}
        path = fx.run_dir / "claim.stdout"
        text = path.read_text().rsplit(runner.CLAIM_SENTINEL, 1)[0]
        path.write_text(text + runner.CLAIM_SENTINEL + json.dumps(receipt) + "\n")
        with self.assertRaisesRegex(runner.RunnerError, "does not verify the requested review claim"):
            fx.recover(apply=False)

    def test_an_unpublished_or_moved_original_head_is_refused(self):
        fx = self.fx
        (fx.worktree / "local_only.txt").write_text("unpublished\n")
        sh(fx.worktree, "add", "local_only.txt")
        sh(fx.worktree, "commit", "-qm", "unpublished local commit")
        with self.assertRaisesRegex(runner.RunnerError, "not the exact published branch tip"):
            fx.recover()
        self.assertFalse((fx.run_dir / runner.JOURNAL_NAME).exists())

    def test_unsupported_requests_fail_closed(self):
        fx = self.fx
        for label, kwargs, expected in (
            ("pass is never recovered", dict(outcome="passed"), "only as findings or human_required"),
            ("no finding ids", dict(ids=()), "stable finding IDs"),
            ("malformed id", dict(ids=("finding-1",)), "stable finding IDs"),
            ("duplicate ids", dict(ids=("R0-01", "R0-01")), "stable finding IDs"),
            ("unrecorded finding", dict(ids=("R0-01", "R0-07")), "R0-07 has no written evidence"),
            ("unknown provenance", dict(provenance="myself"), "explicit reviewer provenance"),
        ):
            with self.subTest(label):
                with self.assertRaisesRegex(runner.RunnerError, expected):
                    fx.recover(**kwargs)
        with self.assertRaisesRegex(runner.RunnerError, "exact review workstream and run ID"):
            runner.recover_closeout(fx.repo, WORKSTREAM, "latest", isolated_checkout=fx.checkout, outcome="findings",
                                    ids=("R0-01",), provenance="different-agent")

    def test_a_dirty_coordination_checkout_is_not_a_recovery_surface(self):
        fx = self.fx
        (fx.repo / "implementation.py").write_text("dirty coordination edit\n")
        with self.assertRaisesRegex(runner.RunnerError, "dirty persistent coordination checkout"):
            fx.recover()
        self.assertEqual((fx.repo / "implementation.py").read_text(), "dirty coordination edit\n")

    def test_another_active_supervisor_blocks_recovery(self):
        fx = self.fx
        lock_path = fx.common / "custodian-review-runs" / "locks" / f"{WORKSTREAM}.lock"
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        with lock_path.open("a") as held:
            fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaisesRegex(runner.RunnerError, "another supervisor or recovery"):
                fx.recover()

    def test_protected_bytes_changing_between_attempts_stops_without_release(self):
        fx = self.fx

        def failing_lander(_checkout):
            raise runner.RunnerError("land_main blocked; simulated interruption")
        with self.assertRaises(runner.RunnerError):
            fx.recover(lander=failing_lander)
        (fx.worktree / SIDECAR).write_bytes(b"uid://changed-by-someone\n")
        with self.assertRaisesRegex(runner.RunnerError, "inventory changed"):
            fx.recover()
        self.assertTrue(fx.remote_branch_exists())

    def test_release_is_refused_when_the_remote_branch_holds_unlanded_commits(self):
        fx = self.fx
        fx.recover()
        # someone pushes a new unique commit to the claim branch after landing
        sh(fx.checkout, "checkout", "-q", "-b", "scratch")
        (fx.checkout / "late.txt").write_text("late\n")
        sh(fx.checkout, "add", "late.txt")
        sh(fx.checkout, "commit", "-qm", "late unique work")
        sh(fx.checkout, "push", "-q", "origin", f"HEAD:refs/heads/agent/{WORKSTREAM}")
        journal = fx.run_dir / runner.JOURNAL_NAME
        data = json.loads(journal.read_text())
        data["stage"] = "landed"
        data.pop("result")
        journal.write_text(json.dumps(data))
        sh(fx.checkout, "checkout", "-q", f"recovery/{WORKSTREAM}-{RUN_ID.rsplit('-', 1)[1]}")
        with self.assertRaisesRegex(runner.RunnerError, "claim release refused"):
            fx.recover(release_claim=True)
        self.assertTrue(fx.remote_branch_exists())

    def test_review_branch_commits_outside_the_bounded_paths_never_ride_a_landing(self):
        fx = self.fx
        (fx.worktree / "game_code.gd").write_text("extends Node # not review evidence\n")
        sh(fx.worktree, "add", "game_code.gd")
        sh(fx.worktree, "commit", "-qm", "unbounded commit on the review branch")
        sh(fx.worktree, "push", "-q", "origin", f"agent/{WORKSTREAM}")
        for apply in (False, True):
            with self.subTest(apply=apply):
                with self.assertRaisesRegex(runner.RunnerError, "outside the bounded evidence scope: game_code.gd"):
                    fx.recover(apply=apply)
        self.assertFalse((fx.run_dir / runner.JOURNAL_NAME).exists())
        self.assertFalse(fx.checkout.exists())
        sh(fx.repo, "fetch", "-q", "origin", "main")
        self.assertNotEqual(subprocess.run(["git", "-C", str(fx.repo), "cat-file", "-e", "origin/main:game_code.gd"],
                                           capture_output=True).returncode, 0)

    def test_a_rename_into_an_allowed_path_cannot_hide_a_deleted_source_file(self):
        fx = self.fx
        sh(fx.worktree, "mv", "implementation.py", ARCHIVE)
        sh(fx.worktree, "commit", "-qam", "rename a source file into an allowed path")
        allowed = {ACTIVE, ARCHIVE, README, SUMMARY}
        error = runner._branch_scope_error(fx.worktree, "HEAD", allowed)
        self.assertIsNotNone(error, "the deleted source must be reported, not only the allowed destination")
        self.assertIn("implementation.py", error)

    def test_a_preseeded_recovery_checkout_with_an_extra_commit_is_refused_before_publishing(self):
        fx = self.fx
        branch = f"recovery/{WORKSTREAM}-{RUN_ID.rsplit('-', 1)[1]}"
        sh(fx.repo, "worktree", "add", "-qb", branch, str(fx.checkout), f"origin/agent/{WORKSTREAM}")
        sh(fx.checkout, "config", "user.name", "test")
        sh(fx.checkout, "config", "user.email", "test@example.invalid")
        (fx.checkout / "planted.gd").write_text("extends Node\n")
        sh(fx.checkout, "add", "planted.gd")
        sh(fx.checkout, "commit", "-qm", "planted commit")
        remote_tip = sh(fx.repo, "ls-remote", "origin", f"refs/heads/agent/{WORKSTREAM}")
        with self.assertRaisesRegex(runner.RunnerError, "outside the bounded evidence scope: planted.gd"):
            fx.recover()
        self.assertEqual(sh(fx.repo, "ls-remote", "origin", f"refs/heads/agent/{WORKSTREAM}"), remote_tip)
        self.assertEqual(fx.main_commits_touching("planted.gd"), 0)

    def test_a_rewound_checkout_no_longer_descends_from_the_journaled_recovery_head(self):
        fx = self.fx

        def failing_lander(_checkout):
            raise runner.RunnerError("land_main blocked; simulated interruption")
        with self.assertRaises(runner.RunnerError):
            fx.recover(lander=failing_lander)
        sh(fx.checkout, "reset", "-q", "--hard", fx.tip)
        with self.assertRaisesRegex(runner.RunnerError, "no longer descends from the journaled recovery head|outcome"):
            fx.recover()
        self.assertEqual(fx.main_commits_touching(ARCHIVE), 0)

    def test_a_completed_recovery_can_release_its_claim_later_and_only_once_safe(self):
        fx = self.fx
        first = fx.recover()
        self.assertTrue(first["claim_release_pending"])
        self.assertTrue(fx.remote_branch_exists())
        released = fx.recover(release_claim=True)
        self.assertTrue(released["claim_released"])
        self.assertFalse(released["claim_release_pending"])
        self.assertFalse(fx.remote_branch_exists())
        self.assertEqual(fx.recover(release_claim=True), released, "a further release request is a no-op")
        self.assertEqual(fx.recover(), released)

    def test_late_release_refuses_when_the_protected_original_changed(self):
        fx = self.fx
        fx.recover()
        (fx.worktree / SIDECAR).write_bytes(b"uid://tampered-after-completion\n")
        with self.assertRaisesRegex(runner.RunnerError, "protected original worktree changed"):
            fx.recover(release_claim=True)
        self.assertTrue(fx.remote_branch_exists())

    def test_release_never_deletes_a_branch_that_moved_after_verification(self):
        fx = self.fx
        fx.recover()
        real_git = runner.git
        pushed = []

        def racing_git(repo, *args, **kwargs):
            output = real_git(repo, *args, **kwargs)
            if args[:2] == ("rev-parse", "--verify") and any("origin/agent/" in part for part in args) and not pushed:
                other = fx.base / "late-clone"
                subprocess.run(["git", "clone", "-q", str(fx.remote), str(other)], check=True)
                sh(other, "config", "user.name", "late")
                sh(other, "config", "user.email", "late@example.invalid")
                sh(other, "checkout", "-q", f"agent/{WORKSTREAM}")
                (other / "late.txt").write_text("a live reviewer pushed after the check\n")
                sh(other, "add", "late.txt")
                sh(other, "commit", "-qm", "late push")
                sh(other, "push", "-q", "origin", f"HEAD:refs/heads/agent/{WORKSTREAM}")
                pushed.append(1)
            return output
        with patch.object(runner, "git", side_effect=racing_git):
            with self.assertRaises(runner.RunnerError):
                runner._release_claim(fx.repo, f"agent/{WORKSTREAM}")
        self.assertTrue(pushed)
        self.assertTrue(fx.remote_branch_exists(), "the late push must survive")
        self.assertIn("late push", sh(fx.repo, "log", "-1", "--format=%s", f"origin/agent/{WORKSTREAM}")
                      if sh(fx.repo, "fetch", "-q", "origin") == "" else "")

    def test_cli_requires_an_explicit_mode_and_prints_the_plan(self):
        with self.assertRaises(SystemExit):
            runner.main(["recover-closeout", WORKSTREAM, "--run-id", RUN_ID, "--outcome", "findings",
                         "--finding-ids", "R0-01", "--provenance", "different-agent",
                         "--isolated-checkout", str(self.fx.checkout)])


class WorkstreamNonpassingGateTests(FixtureCase):
    """workstream.py finish gates must accept a bounded findings closeout and nothing looser."""
    sidecar = False

    def commit_closeout(self, section=None, mutate=None):
        fx = self.fx
        fx.reviewer_closeout(section)
        if mutate:
            mutate()
        sh(fx.worktree, "add", "-A")
        sh(fx.worktree, "commit", "-qm", "closeout")

    def gate(self):
        import workstream
        return workstream._paired_review_artifact_preflight_error(WORKSTREAM, self.fx.worktree,
                                                                  self.fx.worktree / ARCHIVE)

    def test_bounded_findings_closeout_passes_the_artifact_gate_without_a_target_receipt(self):
        self.commit_closeout()
        self.assertIsNone(self.gate())

    def test_human_required_closeout_passes_the_gate_too(self):
        self.commit_closeout(self.fx.outcome("human_required"))
        self.assertIsNone(self.gate())

    def test_gate_rejects_every_unsafe_nonpassing_closeout(self):
        fx = self.fx
        passing = append_receipt(fx.baseline, review_workstream=WORKSTREAM, target_workstream=TARGET_WORKSTREAM,
                                 reviewed_main=fx.reviewed_main, implementation_commit=fx.implementation)
        cases = {
            "target packet modified": (None, lambda: (fx.worktree / TARGET).write_text(passing),
                                       "change to the reviewed packet|nonpassing review changing"),
            "unrelated file changed": (None, lambda: (fx.worktree / "extra.py").write_text("x\n"),
                                       "nonpassing review changing extra.py"),
            "outcome names another implementation": (fx.outcome(implementation_commit="d" * 40), None,
                                                      "Review Outcome Reviewed implementation commit"),
            "outcome names another review": (fx.outcome(review_workstream="review-other"), None,
                                             "Review Outcome Review workstream"),
            "malformed outcome": (fx.outcome().replace("Finding IDs: `R0-01`", "Finding IDs: `none`"), None,
                                  "rejects the Review Outcome"),
            "finding without written evidence": (fx.outcome(ids=("R0-01", "R0-02")), None,
                                                 "no written evidence for R0-02"),
            "wrong review cycle": (fx.outcome(review_cycle=1, ids=("R1-01",)), None,
                                   "Review Outcome Review cycle"),
        }
        for label, (section, mutate, expected) in cases.items():
            with self.subTest(label):
                sh(fx.worktree, "reset", "-q", "--hard", fx.tip)
                sh(fx.worktree, "clean", "-qfd")
                self.commit_closeout(section, mutate)
                self.assertRegex(self.gate() or "", expected)

    def test_a_review_without_any_outcome_or_receipt_still_requires_the_target_receipt(self):
        fx = self.fx
        text = (fx.worktree / ACTIVE).read_text().replace("Status: `blocked`", "Status: `complete`")
        (fx.worktree / ARCHIVE).parent.mkdir(parents=True, exist_ok=True)
        (fx.worktree / ARCHIVE).write_text(text)
        (fx.worktree / ACTIVE).unlink()
        sh(fx.worktree, "add", "-A")
        sh(fx.worktree, "commit", "-qm", "closeout without verdict")
        self.assertRegex(self.gate() or "", "requires a committed change to the reviewed packet receipt")

    def test_closeout_preflight_does_not_demand_a_target_receipt_for_a_nonpassing_review(self):
        import workstream
        fx = self.fx
        self.commit_closeout()
        report_path = fx.run_dir / "closeout-integrity.json"
        report_path.write_text(json.dumps(runner.nonpassing_integrity_report("findings")))
        report = workstream.closeout_preflight(WORKSTREAM, fx.worktree, report_path)
        gates = {item["gate"] for item in report["blockers"]}
        self.assertNotIn("review_receipt", gates)
        self.assertNotIn("review_artifact_scope", gates)
        self.assertEqual(report["review_receipt_blockers"], [])
        self.assertEqual([item["status"] for item in report["review_artifact_checks"]], ["pass"])

    def test_closeout_preflight_still_blocks_a_review_with_neither_receipt_nor_outcome(self):
        import workstream
        fx = self.fx
        text = (fx.worktree / ACTIVE).read_text().replace("Status: `blocked`", "Status: `complete`")
        (fx.worktree / ARCHIVE).parent.mkdir(parents=True, exist_ok=True)
        (fx.worktree / ARCHIVE).write_text(text)
        (fx.worktree / ACTIVE).unlink()
        sh(fx.worktree, "add", "-A")
        sh(fx.worktree, "commit", "-qm", "closeout without verdict")
        report = workstream.closeout_preflight(WORKSTREAM, fx.worktree, None)
        self.assertIn("review_receipt", {item["gate"] for item in report["blockers"]})


if __name__ == "__main__":
    unittest.main()
