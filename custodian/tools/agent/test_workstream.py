"""Focused temporary-repository coverage for workstream lifecycle primitives."""

import importlib.util
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("workstream.py")
SPEC = importlib.util.spec_from_file_location("workstream", SCRIPT)
workstream = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workstream)
import persistent_checkout_sync as persistent_sync


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

    def test_archive_transition_guard_accepts_archive_at_tip_and_rejects_followup(self):
        workstream_id = "agent-test-archive-tip"
        active = self.repo / "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TIP.md"
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_ARCHIVE_TIP.md"
        active.parent.mkdir(parents=True)
        active.write_text(
            "# Test\n- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
        )
        git(self.repo, "add", str(active.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish active packet")
        (self.repo / "source.py").write_text("source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))
        preflight = workstream.closeout_preflight(workstream_id, self.repo)
        self.assertEqual(preflight["archive_transition"]["status"], "pass")

        (self.repo / "summary.md").write_text("follow-up after archive\n")
        git(self.repo, "add", "summary.md")
        git(self.repo, "commit", "-m", "unbound follow-up")
        error = workstream._archive_transition_tip_error(workstream_id, self.repo)
        self.assertIn("archive transition", error)
        self.assertIn("current branch tip", error)
        preflight = workstream.closeout_preflight(workstream_id, self.repo)
        self.assertEqual(preflight["archive_transition"]["status"], "blocked")
        self.assertTrue(any(blocker["gate"] == "archive_transition_tip"
                            for blocker in preflight["blockers"]))

    def test_finish_rejects_unbound_archive_followup_before_push(self):
        workstream_id = "agent-test-archive-tip"
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        active = self.repo / "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TIP.md"
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_ARCHIVE_TIP.md"
        active.parent.mkdir(parents=True)
        active.write_text(
            "# Test\n- Workstream: `agent-test-archive-tip`\n- Status: `in_progress`\n"
        )
        git(self.repo, "add", str(active.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish active packet")
        (self.repo / "source.py").write_text("source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")
        (self.repo / "summary.md").write_text("follow-up after archive\n")
        git(self.repo, "add", "summary.md")
        git(self.repo, "commit", "-m", "unbound follow-up")

        with mock.patch.object(workstream, "fetch"), \
             mock.patch.object(workstream, "artifact_preflight", return_value=[]), \
             mock.patch.object(workstream, "_completion_truth_preflight"), \
             mock.patch.object(workstream, "status_clean", return_value=True), \
             mock.patch.object(workstream, "closing_summary_committed_for_workstream"), \
             mock.patch.object(workstream, "validation_green", return_value=True), \
             mock.patch.object(workstream, "git", wraps=workstream.git) as git_call:
            with self.assertRaisesRegex(workstream.WorkstreamError, "current branch tip"):
                workstream._finish_impl(workstream_id, self.repo / "validation.json", repo=self.repo)
        self.assertFalse(any(call.args and call.args[0] == "push" for call in git_call.call_args_list))

    def test_archive_guard_accepts_exact_traced_sync_and_one_scoped_followup(self):
        workstream_id = "agent-test-archive-trace"
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        active = self.repo / "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TRACE.md"
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_ARCHIVE_TRACE.md"
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            "# Test\n- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
            "- Work surface: `source.py`; `test_source.py`\n"
        )
        git(self.repo, "add", str(active.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish active packet")
        (self.repo / "source.py").write_text("source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")
        archive = git(self.repo, "rev-parse", "HEAD")

        # Make an independently published main commit, then sync it into the task branch.
        git(self.repo, "checkout", "main")
        (self.repo / "main-only").write_text("main\n")
        git(self.repo, "add", "main-only")
        git(self.repo, "commit", "-m", "advance main")
        git(self.repo, "push", "origin", "main")
        main_sha = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", branch)
        git(self.repo, "merge", "--no-ff", "main", "-m", "sync main")
        merge = git(self.repo, "rev-parse", "HEAD")

        # The immutable diagnostic trace is committed on its own ref, as in production.
        run_id = "20261021T000000Z-abcdef123456"
        trace_ref = f"refs/remotes/origin/agent-diagnostics/{workstream_id}/{run_id}"
        trace_events = [
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TRACE.md",
             "run_id": run_id, "event": "remote_claim_acquired",
             "data": {"remote_ref": f"refs/heads/dispatch-claims/{workstream_id}",
                      "claim_oid": archive, "main_sha": archive}},
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TRACE.md",
             "run_id": run_id, "event": "worktree_published",
             "data": {"branch": branch, "clean": True, "head": archive,
                      "upstream": archive, "worktree": str(self.repo)}},
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TRACE.md",
             "run_id": run_id, "event": "main_sync",
             "data": {"changed": True, "head": merge, "main_sha": main_sha}},
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": "custodian/docs/ai_context/task_packets/AGENT_TEST_ARCHIVE_TRACE.md",
             "run_id": run_id, "event": "run_blocked", "data": {"reason": "validation required"}},
        ]
        trace_repo = self.base / "trace-repo"
        git(self.base, "clone", str(self.remote), str(trace_repo))
        git(trace_repo, "checkout", "main")
        (trace_repo / "trace.jsonl").write_text(
            "".join(json.dumps(event) + "\n" for event in trace_events)
        )
        git(trace_repo, "add", "trace.jsonl")
        git(trace_repo, "commit", "-m", "publish immutable trace")
        git(trace_repo, "push", "origin", f"HEAD:refs/heads/agent-diagnostics/{workstream_id}/{run_id}")
        git(self.repo, "fetch", "origin")
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

        (self.repo / "test_source.py").write_text("regression\n")
        git(self.repo, "add", "test_source.py")
        git(self.repo, "commit", "-m", "bounded producer fix")
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

        (self.repo / "outside.py").write_text("unrelated\n")
        git(self.repo, "add", "outside.py")
        git(self.repo, "commit", "-m", "unrelated followup")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_advanced_head_review_can_defer_teardown_without_deferring_root_sync(self):
        class ReachedFetch(Exception):
            pass

        with mock.patch.object(workstream, "fetch", side_effect=ReachedFetch):
            with self.assertRaises(ReachedFetch):
                workstream._finish_impl(
                    workstream.ADVANCED_HEAD_PASS_REVIEW, self.repo / "validation.json",
                    repo=self.repo, defer_teardown=True,
                )

    def test_deferred_teardown_remains_restricted_to_authorized_recoveries(self):
        with self.assertRaisesRegex(workstream.WorkstreamError, "two exact authorized"):
            workstream._finish_impl("unrelated-review", self.repo / "validation.json",
                                    repo=self.repo, defer_teardown=True)
        with self.assertRaisesRegex(workstream.WorkstreamError, "root-sync deferral"):
            workstream._finish_impl(
                workstream.INVALID_DISPOSITION_REVIEW, self.repo / "validation.json",
                repo=self.repo, defer_teardown=True,
            )

    def test_advanced_head_finish_lands_syncs_root_and_preserves_claim_worktree(self):
        workstream_id = workstream.ADVANCED_HEAD_PASS_REVIEW
        path = workstream.start(workstream_id, self.repo)
        self._archive_packet(path, workstream_id,
                             self._v2_packet_text(workstream_id, kind="review"))
        report = self._green_report()

        workstream.finish(workstream_id, report, repo=path, defer_teardown=True)

        self.assertTrue(path.is_dir())
        self.assertEqual(git(path, "branch", "--show-current"), f"agent/{workstream_id}")
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertEqual(git(self.repo, "rev-parse", f"origin/agent/{workstream_id}"),
                         git(path, "rev-parse", "HEAD"))

    def test_stable_kebab_id_validation(self):
        self.assertEqual(workstream.validate_id("operator-fast-chain"), "operator-fast-chain")
        for value in ("Operator", "two--words", "a/b", "one_"):
            with self.assertRaises(workstream.WorkstreamError):
                workstream.validate_id(value)

    def test_legacy_quarantined_claim_cannot_be_started_or_resumed(self):
        import legacy_claim_quarantine
        state = {"state": "legacy_quarantined", "record_sha": "a" * 40, "lock_released": True}
        with mock.patch.object(legacy_claim_quarantine, "local_quarantine_state", return_value=state):
            with self.assertRaisesRegex(workstream.WorkstreamError, "legacy_quarantined"):
                workstream.start("stranded-review", self.repo)
            with self.assertRaisesRegex(workstream.WorkstreamError, "legacy_quarantined"):
                workstream.resume("stranded-review", self.repo)
            with self.assertRaisesRegex(workstream.WorkstreamError, "legacy_quarantined"):
                workstream.finish("stranded-review", self.repo / "validation.json", repo=self.repo)
        ref = subprocess.run(["git", "show-ref", "--verify", "refs/heads/agent/stranded-review"],
                             cwd=self.repo, capture_output=True)
        self.assertNotEqual(ref.returncode, 0)

    def test_new_start_uses_origin_main_in_external_worktree(self):
        path = workstream.start("sample-work", self.repo)
        self.assertEqual(git(path, "branch", "--show-current"), "agent/sample-work")
        self.assertNotEqual(path, self.repo)
        self.assertFalse(path.is_relative_to(self.repo))
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertEqual(git(path, "rev-parse", "@{upstream}"), git(self.repo, "rev-parse", "origin/agent/sample-work"))
        trace = next((Path(self.repo / ".git/custodian-workflow/traces/sample-work").glob("*.jsonl")))
        first_event = json.loads(trace.read_text().splitlines()[0])
        self.assertEqual(first_event["execution_generation"], "execution-reset-v1-20261020")

    def test_dispatch_owned_start_defers_trace_publication(self):
        trace = workstream.RunTrace.start(self.repo, "deferred-start", agent="codex")
        claim = workstream.RemoteClaim(
            "deferred-start", "refs/heads/dispatch-claims/deferred-start",
            "refs/custodian/claims/deferred-start/test-run", "claim-oid", "test-run",
        )
        with mock.patch.object(trace, "publish", return_value=True) as publish:
            path = workstream.start(
                "deferred-start", self.repo, _claim=claim, _trace=trace,
                _lock_held=True, _publish_trace=False,
            )
        publish.assert_not_called()
        self.assertTrue(path.is_dir())
        self.assertEqual(git(path, "branch", "--show-current"), "agent/deferred-start")
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/deferred-start"))
        events = [json.loads(line)["event"] for line in trace.path.read_text().splitlines()]
        self.assertIn("start_completed", events)

    def test_dispatch_owned_start_failure_defers_blocked_trace_publication(self):
        trace = workstream.RunTrace.start(self.repo, "deferred-start-failure", agent="codex")
        claim = workstream.RemoteClaim(
            "deferred-start-failure", "refs/heads/dispatch-claims/deferred-start-failure",
            "refs/custodian/claims/deferred-start-failure/test-run", "claim-oid", "test-run",
        )
        with mock.patch.object(workstream, "git", side_effect=workstream.WorkstreamError("injected start failure")), \
             mock.patch.object(trace, "publish", return_value=True) as publish:
            with self.assertRaisesRegex(workstream.WorkstreamError, "injected start failure"):
                workstream.start(
                    "deferred-start-failure", self.repo, _claim=claim, _trace=trace,
                    _lock_held=True, _publish_trace=False,
                )
        publish.assert_not_called()
        events = [json.loads(line) for line in trace.path.read_text().splitlines()]
        self.assertEqual(events[-1]["event"], "run_blocked")

    def test_direct_start_keeps_best_effort_trace_publication(self):
        with mock.patch.object(workstream.RunTrace, "publish", return_value=False) as publish:
            path = workstream.start("direct-publish", self.repo)
        self.assertTrue(path.is_dir())
        publish.assert_called_once()

    def test_concurrent_direct_start_has_one_winner_and_preserves_checkout(self):
        def attempt():
            try:
                return ("ok", workstream.start("parallel-start", self.repo))
            except workstream.WorkstreamError as error:
                return ("blocked", str(error))
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: attempt(), range(2)))
        winners = [value for state, value in results if state == "ok"]
        losers = [value for state, value in results if state == "blocked"]
        self.assertEqual(len(winners), 1)
        self.assertEqual(len(losers), 1)
        self.assertTrue(winners[0].is_dir())
        self.assertEqual(git(winners[0], "branch", "--show-current"), "agent/parallel-start")
        self.assertIn("already exists", losers[0])

    def test_independent_clone_direct_start_uses_remote_claim_cas(self):
        clone = self.base / "second-clone"
        git(self.base, "clone", str(self.remote), str(clone))
        def attempt(repo):
            try:
                return ("ok", workstream.start("clone-race", repo))
            except workstream.WorkstreamError as error:
                return ("blocked", str(error))
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(attempt, (self.repo, clone)))
        winners = [value for state, value in results if state == "ok"]
        losers = [value for state, value in results if state == "blocked"]
        self.assertEqual(len(winners), 1, results)
        self.assertEqual(len(losers), 1, results)
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/clone-race"))
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/clone-race"))

    def test_failed_create_leaves_claim_and_ordinary_retry_does_not_adopt(self):
        original = workstream.git
        def injected(*args, **kwargs):
            if args[:2] == ("worktree", "add"):
                raise workstream.WorkstreamError("injected create failure")
            return original(*args, **kwargs)
        workstream.git = injected
        try:
            with self.assertRaisesRegex(workstream.WorkstreamError, "injected create failure"):
                workstream.start("interrupted-create", self.repo)
        finally:
            workstream.git = original
        claim = git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/interrupted-create")
        self.assertTrue(claim)
        with self.assertRaisesRegex(workstream.WorkstreamError, "remote claim exists"):
            workstream.start("interrupted-create", self.repo)

    def test_start_report_records_created_then_resumed_disposition(self):
        report: dict[str, str] = {}
        path = workstream.start("disposition-work", self.repo, report=report)
        self.assertEqual(report["checkout"], "created")
        resumed_report: dict[str, str] = {}
        resumed = workstream.resume("disposition-work", self.repo, report=resumed_report)
        self.assertEqual(resumed_report["checkout"], "resumed")
        self.assertEqual(resumed, path)

    def test_existing_remote_is_resumed_and_main_merge_is_non_rewriting(self):
        task = workstream.start("resume-me", self.repo)
        (task / "task").write_text("task\n"); git(task, "add", "task"); git(task, "commit", "-m", "task")
        git(task, "push", "origin", "agent/resume-me")
        task_head = git(task, "rev-parse", "HEAD")
        (self.repo / "main-change").write_text("new\n"); git(self.repo, "add", "main-change"); git(self.repo, "commit", "-m", "main advances"); git(self.repo, "push", "origin", "main")
        git(self.repo, "worktree", "remove", str(task))
        git(self.repo, "branch", "-D", "agent/resume-me")
        resumed = workstream.resume("resume-me", self.repo)
        self.assertEqual(git(resumed, "branch", "--show-current"), "agent/resume-me")
        self.assertEqual(git(resumed, "rev-parse", "HEAD^"), task_head)
        self.assertTrue((resumed / "main-change").exists())

    def test_existing_remote_fast_forwards_to_new_main(self):
        path = workstream.start("fast-forward", self.repo)
        git(self.repo, "worktree", "remove", str(path)); git(self.repo, "branch", "-D", "agent/fast-forward")
        (self.repo / "main-ff").write_text("advance\n"); git(self.repo, "add", "main-ff"); git(self.repo, "commit", "-m", "advance main"); git(self.repo, "push", "origin", "main")
        resumed = workstream.resume("fast-forward", self.repo)
        self.assertEqual(git(resumed, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertTrue((resumed / "main-ff").exists())

    def test_main_merge_conflict_preserves_task_worktree(self):
        path = workstream.start("conflict-work", self.repo)
        (path / "base").write_text("task version\n"); git(path, "add", "base"); git(path, "commit", "-m", "task conflict")
        git(path, "push", "origin", "agent/conflict-work")
        git(self.repo, "worktree", "remove", str(path)); git(self.repo, "branch", "-D", "agent/conflict-work")
        (self.repo / "base").write_text("main version\n"); git(self.repo, "add", "base"); git(self.repo, "commit", "-m", "main conflict"); git(self.repo, "push", "origin", "main")
        with self.assertRaisesRegex(workstream.WorkstreamError, "merge conflicted"):
            workstream.resume("conflict-work", self.repo)
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

    def test_start_threads_explicit_agent_into_remote_claim(self):
        with mock.patch.object(workstream, "acquire_remote_claim", wraps=workstream.acquire_remote_claim) as spy:
            workstream.start("agent-explicit-work", self.repo, agent="claude")
        self.assertEqual(spy.call_args.args[2], "claude")

    def test_start_never_silently_defaults_agent_to_codex(self):
        with mock.patch.object(workstream, "acquire_remote_claim", wraps=workstream.acquire_remote_claim) as spy:
            workstream.start("agent-default-work", self.repo)
        self.assertEqual(spy.call_args.args[2], "unspecified")
        self.assertNotEqual(spy.call_args.args[2], "codex")

    def test_cli_start_preserves_explicit_agent_flag(self):
        original_cwd = Path.cwd()
        os.chdir(self.repo)
        try:
            with mock.patch.object(workstream, "acquire_remote_claim", wraps=workstream.acquire_remote_claim) as spy, \
                 mock.patch.object(sys, "argv", ["workstream.py", "start", "agent-cli-work", "--agent", "codex"]):
                result = workstream.main()
        finally:
            os.chdir(original_cwd)
        self.assertEqual(result, 0)
        self.assertEqual(spy.call_args.args[2], "codex")

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
        (path / "FINISH_ME_CLAUDE_SUMMARY.md").write_text("completed\n")
        git(path, "add", "feature", "FINISH_ME_CLAUDE_SUMMARY.md")
        git(path, "commit", "-m", "finish sample")
        landed_head = git(path, "rev-parse", "HEAD")
        report = self.base / "validation.json"
        report.write_text('{"schema":"custodian.validation.result.v1","passed":true,"coverage":{"complete":true},"tests":[{"status":"passed"}]}')
        # Invoke from the task worktree itself, as the normal CLI does. Teardown
        # must continue through a surviving coordination worktree.
        with mock.patch.object(workstream, "apply_profiles", wraps=workstream.apply_profiles) as sync_apply:
            workstream.finish("finish-me", report, repo=path)
        sync_apply.assert_called_once_with([workstream.ROOT_PROFILE], self.repo)
        self.assertFalse(path.exists())
        self.assertNotIn("agent/finish-me", git(self.repo, "branch", "--list"))
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "agent/finish-me"), "")
        check = subprocess.run(["git", "merge-base", "--is-ancestor", landed_head, "origin/main"], cwd=self.repo)
        self.assertEqual(check.returncode, 0)
        # The clean persistent coordination checkout fast-forwards after teardown.
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))

    # --- Already-landed closeout hardening ---

    def _green_report(self, name: str = "validation.json") -> Path:
        report = self.base / name
        report.write_text('{"schema":"custodian.validation.result.v1","passed":true,"coverage":{"complete":true},"tests":[{"status":"passed"}]}')
        return report

    def _red_report(self, name: str = "red.json") -> Path:
        report = self.base / name
        report.write_text('{"schema":"custodian.validation.result.v1","passed":false,"tests":[]}')
        return report

    def _commit_task_work(self, path: Path, workstream_id: str, message: str = "work") -> None:
        (path / "feature").write_text("done\n")
        summary = workstream._expected_summary_filename(workstream_id)
        (path / summary).write_text("completed\n")
        git(path, "add", "feature", summary)
        git(path, "commit", "-m", message)

    def _simulate_already_landed(self, path: Path) -> str:
        """Push the task's current HEAD directly onto main.

        Reproduces a prior finish attempt that pushed onto origin/main (or
        otherwise landed by fast-forward) but crashed or lost its response
        before completing teardown — the real-world asset-requirements-pipeline
        edge this task packet cites.
        """
        head = git(path, "rev-parse", "HEAD")
        git(self.repo, "push", "origin", f"{head}:refs/heads/main")
        return head

    def test_finish_short_circuits_when_task_head_already_landed(self):
        path = workstream.start("already-landed", self.repo)
        self._commit_task_work(path, "already-landed")
        head = self._simulate_already_landed(path)
        # This is exactly the condition that broke the old diff-based summary
        # check: once HEAD is an ancestor of origin/main, their merge-base is
        # HEAD itself, so origin/main...HEAD is empty even though the summary
        # really is committed.
        self.assertEqual(git(path, "diff", "--name-only", "origin/main...HEAD"), "")
        workstream.finish("already-landed", self._green_report(), repo=path)
        self.assertFalse(path.exists())
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", "agent/already-landed"), "")
        check = subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=self.repo)
        self.assertEqual(check.returncode, 0)

    def test_finish_still_requires_complete_archived_packet_on_already_landed_path(self):
        path = workstream.start("packet-required", self.repo)
        packets_dir = path / "custodian/docs/ai_context/task_packets"
        packets_dir.mkdir(parents=True, exist_ok=True)
        (packets_dir / "PACKET_REQUIRED.md").write_text(
            "# Packet\n\n- Workstream: `packet-required`\n- Status: `ready`\n"
        )
        (path / "feature").write_text("done\n")
        (path / "PACKET_REQUIRED_CLAUDE_SUMMARY.md").write_text("completed\n")
        git(path, "add", "-A")
        git(path, "commit", "-m", "active, not archived, packet")
        self._simulate_already_landed(path)
        with self.assertRaisesRegex(workstream.WorkstreamError, "complete and moved.*task_packets/archived"):
            workstream.finish("packet-required", self._green_report(), repo=path)
        self.assertTrue(path.exists())

    def test_finish_still_requires_green_validation_on_already_landed_path(self):
        path = workstream.start("needs-green", self.repo)
        self._commit_task_work(path, "needs-green")
        self._simulate_already_landed(path)
        with self.assertRaisesRegex(workstream.WorkstreamError, "not green"):
            workstream.finish("needs-green", self._red_report(), repo=path)
        self.assertTrue(path.exists())

    def test_finish_rejects_passed_report_with_incomplete_coverage(self):
        path = workstream.start("incomplete-coverage", self.repo)
        self._commit_task_work(path, "incomplete-coverage")
        self._simulate_already_landed(path)
        report = self.base / "incomplete-coverage.json"
        report.write_text(
            '{"schema":"custodian.validation.result.v1","passed":true,'
            '"coverage":{"complete":false},"tests":[{"status":"passed"}]}'
        )
        with self.assertRaisesRegex(workstream.WorkstreamError, "not green"):
            workstream.finish("incomplete-coverage", report, repo=path)
        self.assertTrue(path.exists())

    def test_finish_with_extra_unlanded_commit_uses_normal_landing_path(self):
        path = workstream.start("extra-commit", self.repo)
        self._commit_task_work(path, "extra-commit", "landed part")
        landed_head = self._simulate_already_landed(path)
        (path / "extra").write_text("more\n")
        git(path, "add", "extra")
        git(path, "commit", "-m", "extra unlanded work")
        self.assertFalse(workstream.task_head_reachable_from_main(path))
        workstream.finish("extra-commit", self._green_report(), repo=path)
        self.assertFalse(path.exists())
        git(self.repo, "fetch", "origin", "main")
        final_head = git(self.repo, "rev-parse", "origin/main")
        self.assertNotEqual(final_head, landed_head)
        check = subprocess.run(["git", "cat-file", "-e", f"{final_head}:extra"], cwd=self.repo)
        self.assertEqual(check.returncode, 0)

    def test_main_advancement_during_finish_requires_and_uses_after_sync_validation(self):
        path = workstream.start("needs-sync", self.repo)
        self._commit_task_work(path, "needs-sync")
        (self.repo / "main-advance").write_text("advance\n")
        git(self.repo, "add", "main-advance")
        git(self.repo, "commit", "-m", "main advances")
        git(self.repo, "push", "origin", "main")
        with self.assertRaisesRegex(workstream.WorkstreamError, "after-sync"):
            workstream.finish("needs-sync", self._green_report(), repo=path)
        self.assertTrue(path.exists())
        workstream.finish(
            "needs-sync", self._green_report("validation-2.json"),
            validation_report_after_sync=self._green_report("after-sync.json"), repo=path,
        )
        self.assertFalse(path.exists())

    def test_teardown_tolerates_already_deleted_remote_branch(self):
        path = workstream.start("manual-teardown", self.repo)
        head = git(path, "rev-parse", "HEAD")
        git(self.repo, "push", "origin", "--delete", "agent/manual-teardown")
        workstream._teardown_workstream("manual-teardown", "agent/manual-teardown", self.repo, path, head)
        self.assertFalse(path.exists())

    def test_teardown_can_record_authorized_root_sync_deferral_without_touching_root(self):
        path = workstream.start("agent-paired-review-invalid-disposition-recovery-v1", self.repo)
        head = git(path, "rev-parse", "HEAD")
        root_head = git(self.repo, "rev-parse", "HEAD")
        with mock.patch.object(workstream, "apply_profiles") as sync:
            workstream._teardown_workstream(
                "agent-paired-review-invalid-disposition-recovery-v1",
                "agent/agent-paired-review-invalid-disposition-recovery-v1",
                self.repo, path, head, defer_root_sync=True,
            )
        sync.assert_not_called()
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), root_head)
        self.assertFalse(path.exists())

    def test_root_sync_deferral_rejects_unlisted_workstream(self):
        with self.assertRaisesRegex(workstream.WorkstreamError, "not authorized"):
            workstream._verify_root_sync_deferral("unrelated-workstream", self.repo, None)

    def test_root_sync_deferral_requires_the_exact_recovery_packet_override(self):
        packet = self.repo / "custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md"
        packet.parent.mkdir(parents=True)
        packet.write_text(
            "# Recovery\n- Packet schema: `custodian.task_packet.v2`\n"
            "- Workstream: `agent-paired-review-invalid-disposition-recovery-v1`\n"
            "- Kind: `implementation`\n- Task overrides: `Do not synchronize the root checkout; record synchronization pending.`\n"
        )
        self.assertEqual(
            workstream._verify_root_sync_deferral("agent-paired-review-invalid-disposition-recovery-v1", self.repo, None),
            "task_packet_authorized",
        )
        packet.write_text(packet.read_text().replace("Do not synchronize", "Maybe synchronize"))
        with self.assertRaisesRegex(workstream.WorkstreamError, "packet authorization"):
            workstream._verify_root_sync_deferral("agent-paired-review-invalid-disposition-recovery-v1", self.repo, None)

    def test_historical_root_sync_deferral_requires_exact_run_manifest_and_landed_receipt_bytes(self):
        disposition = b"repaired canonical disposition\n"
        target = b"pinned implementation plus one receipt\n"
        for relative, raw in ((workstream.INVALID_DISPOSITION_REVIEW_PACKET, disposition),
                              (workstream.INVALID_DISPOSITION_TARGET_PACKET, target)):
            path = self.repo / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
        git(self.repo, "add", str(Path(workstream.INVALID_DISPOSITION_REVIEW_PACKET)),
            str(Path(workstream.INVALID_DISPOSITION_TARGET_PACKET)))
        git(self.repo, "commit", "-m", "recovery evidence")
        git(self.repo, "push", "origin", "main")
        common = Path(git(self.repo, "rev-parse", "--path-format=absolute", "--git-common-dir"))
        run = common / "custodian-review-runs" / workstream.INVALID_DISPOSITION_REVIEW / workstream.INVALID_DISPOSITION_RUN_ID
        continuation = run / "continuation-01"
        continuation.mkdir(parents=True)
        original = {
            "schema": "custodian.paired_review_run.v1",
            "workstream": workstream.INVALID_DISPOSITION_REVIEW,
            "run_id": workstream.INVALID_DISPOSITION_RUN_ID,
            "run_dir": str(run), "phase": "post_exit_recovery",
        }
        original_bytes = json.dumps(original).encode("utf-8")
        (run / "metadata.json").write_bytes(original_bytes)
        recovery = {
            "schema": "custodian.paired_review_invalid_disposition_recovery.v1",
            "workstream": workstream.INVALID_DISPOSITION_REVIEW,
            "run_id": workstream.INVALID_DISPOSITION_RUN_ID,
            "continuation": "continuation-01",
            "original_disposition_sha256": workstream.INVALID_DISPOSITION_SHA256,
            "repaired_disposition_sha256": hashlib.sha256(disposition).hexdigest(),
            "target_receipt_sha256": hashlib.sha256(target).hexdigest(),
            "root_sync_pending": True,
        }
        child = {
            "schema": "custodian.paired_review_continuation.v1",
            "workstream": workstream.INVALID_DISPOSITION_REVIEW,
            "run_id": workstream.INVALID_DISPOSITION_RUN_ID,
            "phase": "coordinator_closeout", "worktree": str(self.base / "removed-worktree"),
            "invalid_disposition_recovery": recovery,
        }
        child["run_evidence_sha256"] = workstream._review_run_manifest(run)
        (continuation / "metadata.json").write_text(json.dumps(child))
        evidence = continuation / "metadata.json"
        self.assertEqual(
            workstream._verify_root_sync_deferral(workstream.INVALID_DISPOSITION_REVIEW, self.repo, evidence),
            "verified_invalid_disposition_recovery",
        )
        wrong_run = {**original, "run_dir": str(run.parent / "another-run")}
        (run / "metadata.json").write_text(json.dumps(wrong_run))
        with self.assertRaisesRegex(workstream.WorkstreamError, "identity, preservation digest, or evidence manifest"):
            workstream._verify_root_sync_deferral(workstream.INVALID_DISPOSITION_REVIEW, self.repo, evidence)
        (run / "metadata.json").write_bytes(original_bytes)
        (run / "claim.stdout").write_text("tampered original evidence\n")
        with self.assertRaisesRegex(workstream.WorkstreamError, "evidence manifest"):
            workstream._verify_root_sync_deferral(workstream.INVALID_DISPOSITION_REVIEW, self.repo, evidence)

    def test_finish_reports_already_finished_when_nothing_is_attached(self):
        path = workstream.start("fully-done", self.repo)
        self._commit_task_work(path, "fully-done")
        self._simulate_already_landed(path)
        git(self.repo, "push", "origin", "--delete", "agent/fully-done")
        git(self.repo, "worktree", "remove", "--force", str(path))
        git(self.repo, "branch", "-D", "agent/fully-done")
        # No worktree, no remote branch, no validation report needed: the
        # already-finished short-circuit runs before validation is touched.
        workstream.finish("fully-done", self.base / "does-not-exist.json", repo=self.repo)

    def test_finish_without_worktree_fails_closed_when_unverifiable(self):
        with self.assertRaisesRegex(workstream.WorkstreamError, "no attached worktree"):
            workstream.finish("never-existed", self.base / "x.json", repo=self.repo)

    def test_finish_syncs_root_with_unrelated_untracked_file_preserved(self):
        path = workstream.start("dirty-root-finish", self.repo)
        self._commit_task_work(path, "dirty-root-finish")
        preserved_file = self.repo / "uncommitted-root-file"
        preserved_file.write_text("dirty\n")
        workstream.finish("dirty-root-finish", self._green_report(), repo=path)
        self.assertEqual(preserved_file.read_text(), "dirty\n")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))

    def test_finish_leaves_diverged_persistent_root_history_untouched(self):
        path = workstream.start("diverged-root-finish", self.repo)
        self._commit_task_work(path, "diverged-root-finish")
        local_file = self.repo / "persistent-root-commit.txt"
        local_file.write_text("keep local root commit\n")
        git(self.repo, "add", "persistent-root-commit.txt")
        git(self.repo, "commit", "-m", "local root commit")
        root_head = git(self.repo, "rev-parse", "HEAD")

        workstream.finish("diverged-root-finish", self._green_report(), repo=path)

        state = persistent_sync.inspect_profile(persistent_sync.ROOT_PROFILE, self.repo)
        self.assertEqual(state.state, "DIVERGED")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), root_head)
        self.assertEqual(local_file.read_text(), "keep local root commit\n")

    # --- Completion Truth finish-gate ---

    def _v2_packet_text(self, workstream_id: str, kind: str = "implementation", extra: str = "") -> str:
        return (
            "# Sample V2 Packet\n\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Status: `complete`\n"
            "- Dispatch: `manual`\n"
            "- Priority: `P2`\n"
            "- Depends on: `none`\n"
            "- Locks: `none`\n"
            f"- Kind: `{kind}`\n"
            "- Review: `none`\n"
            f"{extra}"
        )

    def _archive_packet(self, path: Path, workstream_id: str, text: str) -> None:
        archive_dir = path / "custodian/docs/ai_context/task_packets/archived"
        archive_dir.mkdir(parents=True, exist_ok=True)
        filename = workstream_id.upper().replace("-", "_") + ".md"
        (archive_dir / filename).write_text(text)
        summary = workstream._expected_summary_filename(workstream_id)
        (path / summary).write_text("completed\n")
        git(path, "add", "-A")
        git(path, "commit", "-m", "archive packet")

    def test_finish_blocks_v2_packet_missing_completion_truth_receipt(self):
        workstream_id = "completion-truth-missing"
        path = workstream.start(workstream_id, self.repo)
        self._archive_packet(path, workstream_id, self._v2_packet_text(workstream_id))
        with self.assertRaisesRegex(workstream.WorkstreamError, "Completion Truth receipt"):
            workstream.finish(workstream_id, self._green_report(), repo=path)
        self.assertTrue(path.exists())

    def test_finish_blocks_v2_packet_with_false_completion_truth(self):
        workstream_id = "completion-truth-false"
        path = workstream.start(workstream_id, self.repo)
        completion_truth = (
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `no`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Superseded/legacy production path disposition: `n/a`\n"
            "- Evidence: tests green\n"
        )
        self._archive_packet(path, workstream_id, self._v2_packet_text(workstream_id, extra=completion_truth))
        with self.assertRaisesRegex(workstream.WorkstreamError, "all be yes"):
            workstream.finish(workstream_id, self._green_report(), repo=path)
        self.assertTrue(path.exists())

    def test_finish_accepts_v2_packet_with_truthful_completion_truth(self):
        workstream_id = "completion-truth-true"
        path = workstream.start(workstream_id, self.repo)
        completion_truth = (
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `yes`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Superseded/legacy production path disposition: `n/a`\n"
            "- Evidence: tests green\n"
        )
        self._archive_packet(path, workstream_id, self._v2_packet_text(workstream_id, extra=completion_truth))
        workstream.finish(workstream_id, self._green_report(), repo=path)
        self.assertFalse(path.exists())

    def test_finish_allows_v2_review_packet_without_completion_truth(self):
        workstream_id = "completion-truth-review"
        path = workstream.start(workstream_id, self.repo)
        self._archive_packet(path, workstream_id, self._v2_packet_text(workstream_id, kind="review"))
        workstream.finish(workstream_id, self._green_report(), repo=path)
        self.assertFalse(path.exists())

    def test_finish_allows_legacy_non_v2_complete_packet_without_completion_truth(self):
        workstream_id = "legacy-complete-packet"
        path = workstream.start(workstream_id, self.repo)
        legacy_text = (
            "# Legacy Packet\n\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Status: `complete`\n"
        )
        self._archive_packet(path, workstream_id, legacy_text)
        workstream.finish(workstream_id, self._green_report(), repo=path)
        self.assertFalse(path.exists())

    def _paired_review_packet(self, target: str, cycle: int, max_cycles: int = 2) -> str:
        return (
            "# Paired Review\n\n"
            f"- Workstream: `review-{target}`\n"
            "- Kind: `review`\n"
            f"- Review target workstream: `{target}`\n"
            "- Review target packet: `custodian/docs/ai_context/task_packets/archived/TARGET.md`\n"
            f"- Review cycle: `{cycle}`\n"
            f"- Max automatic review cycles: `{max_cycles}`\n"
        )

    def _correction_review_artifacts(self, correction: str) -> tuple[list[str], dict[str, str]]:
        correction_path = f"custodian/docs/ai_context/task_packets/{correction.upper().replace('-', '_')}.md"
        paired_path = f"custodian/docs/ai_context/task_packets/REVIEW_{correction.upper().replace('-', '_')}.md"
        return [correction_path, paired_path], {
            correction_path: f"- Workstream: `{correction}`\n- Findings addressed: `R1-02, R1-03`\n",
        }

    def test_paired_review_artifact_gate_allows_first_correction_cycle(self):
        correction = "sample-review-corrections-1"
        changed, contents = self._correction_review_artifacts(correction)
        error = workstream.paired_review_artifact_scope_error(
            "review-sample", Path("REVIEW_SAMPLE.md"), self._paired_review_packet("sample", 0), changed, contents,
        )
        self.assertIsNone(error)

    def test_paired_review_artifact_gate_allows_next_correction_in_existing_lineage(self):
        target = "sample-review-corrections-1"
        correction = "sample-review-corrections-2"
        changed, contents = self._correction_review_artifacts(correction)
        error = workstream.paired_review_artifact_scope_error(
            "review-sample-review-corrections-1", Path("REVIEW_SAMPLE_REVIEW_CORRECTIONS_1.md"),
            self._paired_review_packet(target, 1), changed, contents,
        )
        self.assertIsNone(error)

    def test_paired_review_artifact_gate_rejects_nested_or_out_of_cycle_corrections(self):
        target = "sample-review-corrections-1"
        nested = "sample-review-corrections-1-review-corrections-2"
        changed, contents = self._correction_review_artifacts(nested)
        error = workstream.paired_review_artifact_scope_error(
            "review-sample-review-corrections-1", Path("REVIEW_SAMPLE_REVIEW_CORRECTIONS_1.md"),
            self._paired_review_packet(target, 1), changed, contents,
        )
        self.assertIn("unauthorized change", error or "")

    def test_paired_review_artifact_gate_rejects_nested_target_and_cycle_mismatch(self):
        nested_target = "sample-review-corrections-1-review-corrections-2"
        error = workstream.paired_review_artifact_scope_error(
            "review-nested", Path("REVIEW_NESTED.md"),
            self._paired_review_packet(nested_target, 2), [], {},
        )
        self.assertIn("nested target lineage", error or "")

        mismatch_target = "sample-review-corrections-1"
        error = workstream.paired_review_artifact_scope_error(
            "review-mismatch", Path("REVIEW_MISMATCH.md"),
            self._paired_review_packet(mismatch_target, 0), [], {},
        )
        self.assertIn("cycle does not match target lineage", error or "")

    def test_paired_review_artifact_gate_rejects_corrections_after_cycle_limit(self):
        changed, contents = self._correction_review_artifacts("sample-review-corrections-3")
        error = workstream.paired_review_artifact_scope_error(
            "review-sample-review-corrections-2", Path("REVIEW_SAMPLE_REVIEW_CORRECTIONS_2.md"),
            self._paired_review_packet("sample-review-corrections-2", 2), changed, contents,
        )
        self.assertIn("maximum correction cycle", error or "")


if __name__ == "__main__":
    unittest.main()
