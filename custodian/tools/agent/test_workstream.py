"""Focused temporary-repository coverage for workstream lifecycle primitives."""

import importlib.util
import hashlib
import io
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
import task_packet_index
from custodian.tools.validation import run_validation


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

    def test_validation_producer_reports_stable_commit_and_tree_identity(self):
        selected = [{"id": "identity_fixture", "type": "python", "tier": "unit",
                     "owners": ["custodian/tools/agent/test_workstream.py"],
                     "script": "custodian/tools/agent/test_workstream.py"}]
        stdout = io.StringIO()
        result = [{"id": "identity_fixture", "tier": "unit", "status": "passed",
                   "duration_ms": 1, "warnings": []}]
        with (mock.patch.object(run_validation, "load_manifest", return_value=selected),
              mock.patch.object(run_validation, "load_warning_patterns", return_value=[]),
              mock.patch.object(run_validation, "load_coverage_excludes", return_value=[]),
              mock.patch.object(run_validation, "select_tests", return_value=selected),
              mock.patch.object(run_validation, "execute_tiered", return_value=result),
              mock.patch.object(run_validation, "GodotProjectLock", return_value=mock.MagicMock(
                  __enter__=lambda *_: None, __exit__=lambda *_: None)),
              mock.patch.object(run_validation, "GodotJobBudget", return_value=mock.MagicMock(
                  __enter__=lambda *_: None, __exit__=lambda *_: None)),
              mock.patch.object(run_validation, "REPO_ROOT", self.repo),
              mock.patch.object(run_validation, "MANIFEST_PATH", self.repo / "unused-manifest.json"),
              mock.patch.object(run_validation, "WARNINGS_PATH", self.repo / "unused-warnings.json"),
              mock.patch("sys.stdout", stdout)):
            exit_code = run_validation.main([
                "--changed", "--changed-path", "custodian/tools/agent/test_workstream.py",
                "--test", "identity_fixture", "--json",
            ])
        self.assertEqual(exit_code, 0, stdout.getvalue())
        report = json.loads(stdout.getvalue())
        self.assertEqual(report["source_identity"], run_validation.source_identity(self.repo))
        self.assertIs(report["source_changed_during_validation"], False)
        self.assertTrue(report["passed"])

        changed_stdout = io.StringIO()
        changed_identity = {**report["source_identity"], "tree": "0" * 40}
        with (mock.patch.object(run_validation, "load_manifest", return_value=selected),
              mock.patch.object(run_validation, "load_warning_patterns", return_value=[]),
              mock.patch.object(run_validation, "load_coverage_excludes", return_value=[]),
              mock.patch.object(run_validation, "select_tests", return_value=selected),
              mock.patch.object(run_validation, "execute_tiered", return_value=result),
              mock.patch.object(run_validation, "GodotProjectLock", return_value=mock.MagicMock(
                  __enter__=lambda *_: None, __exit__=lambda *_: None)),
              mock.patch.object(run_validation, "GodotJobBudget", return_value=mock.MagicMock(
                  __enter__=lambda *_: None, __exit__=lambda *_: None)),
              mock.patch.object(run_validation, "REPO_ROOT", self.repo),
              mock.patch.object(run_validation, "MANIFEST_PATH", self.repo / "unused-manifest.json"),
              mock.patch.object(run_validation, "WARNINGS_PATH", self.repo / "unused-warnings.json"),
              mock.patch.object(run_validation, "source_identity", side_effect=[report["source_identity"], changed_identity]),
              mock.patch("sys.stdout", changed_stdout)):
            changed_exit_code = run_validation.main([
                "--changed", "--changed-path", "custodian/tools/agent/test_workstream.py",
                "--test", "identity_fixture", "--json",
            ])
        self.assertEqual(changed_exit_code, 4)
        changed_report = json.loads(changed_stdout.getvalue())
        self.assertFalse(changed_report["passed"])
        self.assertTrue(changed_report["source_changed_during_validation"])

    def _source_sync_merge_fixture(self, *, witness=True, packetless=False):
        workstream_id = "agent-source-sync-witness-fixture"
        branch = workstream.branch_for(workstream_id)
        active_packet = f"custodian/docs/ai_context/task_packets/{workstream_id.upper().replace('-', '_')}.md"
        if not packetless:
            active_path = self.repo / active_packet
            active_path.parent.mkdir(parents=True, exist_ok=True)
            active_path.write_text(
                f"# Fixture\n- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
            )
            git(self.repo, "add", active_packet)
            git(self.repo, "commit", "-m", "publish fixture packet")
        source_base = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", "-b", branch)
        (self.repo / "source.py").write_text("owned source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "add source")
        merge_first = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", "main")
        (self.repo / "main-change.txt").write_text("main advance\n")
        git(self.repo, "add", "main-change.txt")
        git(self.repo, "commit", "-m", "advance main")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        merge_second = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "checkout", branch)
        git(self.repo, "merge", "--no-ff", "origin/main", "-m", "synchronize main")
        merge_commit = git(self.repo, "rev-parse", "HEAD")

        run_id = "20261031T000000Z-123456abcdef"
        claim_oid = git(
            self.repo, "commit-tree", f"{source_base}^{{tree}}", "-p", source_base,
            "-m", f"workstream claim {workstream_id} codex:{os.getpid()}:{run_id}",
        )
        trace = workstream.RunTrace.start(
            self.repo, workstream_id, packet=None if packetless else active_packet,
            agent="codex", run_id=run_id,
        )
        trace.record("remote_claim_acquired", remote_ref=f"refs/heads/dispatch-claims/{workstream_id}",
                     local_ref=f"refs/custodian/claims/{workstream_id}/{run_id}",
                     claim_oid=claim_oid, main_sha=source_base)
        trace.record("worktree_published", worktree=str(self.repo), branch=branch,
                     head=source_base, upstream=source_base, clean=True)
        if witness:
            trace.record("checkpoint_started", remove_worktree=False)
            trace.record("checkpoint_completed", branch=branch, remote_head=merge_first,
                         removed=False)
            trace.record("worktree_resumed", branch=branch, worktree=str(self.repo),
                         head=merge_commit)
        return workstream_id, source_base, merge_commit, merge_second, trace

    def _inherited_main_merge_fixture(self):
        workstream_id = "agent-inherited-main-resume-fixture"
        branch = workstream.branch_for(workstream_id)
        active_packet = f"custodian/docs/ai_context/task_packets/{workstream_id.upper().replace('-', '_')}.md"
        active = self.repo / active_packet
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            f"# Fixture\n- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
        )
        git(self.repo, "add", active_packet)
        git(self.repo, "commit", "-m", "publish inherited resume fixture")
        claim_base = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", "-b", branch)

        run_id = "20261101T000000Z-abcdef123456"
        claim_oid = git(
            self.repo, "commit-tree", f"{claim_base}^{{tree}}", "-p", claim_base,
            "-m", f"workstream claim {workstream_id} codex:{os.getpid()}:{run_id}",
        )
        trace = workstream.RunTrace.start(
            self.repo, workstream_id, packet=active_packet, agent="codex", run_id=run_id,
        )
        trace.record(
            "remote_claim_acquired",
            remote_ref=f"refs/heads/dispatch-claims/{workstream_id}",
            local_ref=f"refs/custodian/claims/{workstream_id}/{run_id}",
            claim_oid=claim_oid, main_sha=claim_base,
        )
        trace.record(
            "worktree_published", worktree=str(self.repo), branch=branch,
            head=claim_base, upstream=claim_base, clean=True,
        )

        git(self.repo, "checkout", "main")
        (self.repo / "upstream-linear.txt").write_text("published upstream\n")
        git(self.repo, "add", "upstream-linear.txt")
        git(self.repo, "commit", "-m", "publish upstream linear change")
        side_base = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", "-b", "upstream-topic")
        (self.repo / "upstream-topic.txt").write_text("published topic\n")
        git(self.repo, "add", "upstream-topic.txt")
        git(self.repo, "commit", "-m", "publish upstream topic change")
        git(self.repo, "checkout", "main")
        (self.repo / "upstream-main.txt").write_text("published mainline\n")
        git(self.repo, "add", "upstream-main.txt")
        git(self.repo, "commit", "-m", "publish upstream mainline change")
        git(self.repo, "merge", "--no-ff", "upstream-topic", "-m", "merge upstream topic")
        inherited_head = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        self.assertEqual(git(self.repo, "rev-parse", "origin/main"), inherited_head)

        git(self.repo, "checkout", branch)
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), claim_base)
        self.assertTrue(workstream.sync_main(self.repo))
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), inherited_head)
        trace.record("worktree_resumed", branch=branch, worktree=str(self.repo), head=inherited_head)
        self.assertTrue(trace.publish())

        (self.repo / "source.py").write_text("authored after resume\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "author source after inherited resume")
        source_head = git(self.repo, "rev-parse", "HEAD")
        return workstream_id, claim_base, inherited_head, source_head, trace, side_base

    def test_finish_source_span_accepts_authenticated_inherited_main_merge_prefix(self):
        workstream_id, claim_base, inherited_head, source_head, trace, _ = (
            self._inherited_main_merge_fixture()
        )
        self.assertEqual(git(self.repo, "rev-parse", f"{inherited_head}^1"),
                         git(self.repo, "rev-parse", "origin/main^1"))
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, source_head, trace,
        ))

        original = trace.path.read_text()
        events = [json.loads(line) for line in original.splitlines()]
        resume = next(event for event in events if event["event"] == "worktree_resumed")
        resume["data"]["head"] = source_head
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIsNotNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, source_head, trace,
        ))

        trace.path.write_text(original)
        events = [json.loads(line) for line in original.splitlines()]
        resume = next(event for event in events if event["event"] == "worktree_resumed")
        resume["data"]["worktree"] = str(self.base / "other-worktree")
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIsNotNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, source_head, trace,
        ))

    def _after_sync_witness(self, trace, sync_head: str, main_sha: str) -> None:
        identity = workstream._git_source_identity(self.repo, sync_head)
        trace.record("validation_after_sync", path="after-sync.json", sha256="a" * 64,
                     passed=True, sync_head=sync_head, sync_main_sha=main_sha,
                     source_commit=identity["commit"], source_tree=identity["tree"],
                     source_status_sha256=identity["worktree_status_sha256"])

    def test_finish_source_span_rejects_sync_merge_without_lifecycle_witness(self):
        workstream_id, source_base, merge_commit, _, trace = self._source_sync_merge_fixture(witness=False)
        error = workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        )
        self.assertIsNotNone(error)
        self.assertIn("checkpoint", error)

    def test_finish_source_span_accepts_exact_checkpoint_resume_merge_witness(self):
        workstream_id, source_base, merge_commit, _, trace = self._source_sync_merge_fixture()
        error = workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        )
        self.assertIsNone(error)

    def test_source_span_sync_merge_accepts_published_source_first_parent(self):
        workstream_id, _, merge_commit, _, trace = self._source_sync_merge_fixture(packetless=True)
        fields = git(self.repo, "rev-list", "--parents", "-n", "1", merge_commit).split()
        first_parent, second_parent = fields[1:]
        self.assertFalse(subprocess.run(
            ["git", "merge-base", "--is-ancestor", first_parent, "origin/main"],
            cwd=self.repo, capture_output=True,
        ).returncode == 0)
        self.assertTrue(subprocess.run(
            ["git", "merge-base", "--is-ancestor", second_parent, "origin/main"],
            cwd=self.repo, capture_output=True,
        ).returncode == 0)
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))

    def test_source_merge_resolution_rejects_unrelated_tree_changes(self):
        base = self.repo / "merge-base.txt"
        base.write_text("base\n")
        git(self.repo, "add", "merge-base.txt")
        git(self.repo, "commit", "-m", "add merge base fixture")
        merge_base = git(self.repo, "rev-parse", "HEAD")
        first_parent = git(self.repo, "rev-parse", "HEAD")
        second_parent = git(self.repo, "rev-parse", "HEAD")
        actual_tree = git(self.repo, "rev-parse", "HEAD^{tree}")
        self.assertFalse(workstream._authenticated_source_merge_resolution(
            self.repo, merge_base, first_parent, second_parent, first_parent,
            actual_tree, actual_tree,
        ))

    def test_finish_source_span_accepts_packetless_checkpoint_resume_merge_and_rejects_packet_drift(self):
        workstream_id, _, merge_commit, _, trace = self._source_sync_merge_fixture(packetless=True)
        self.assertIsNone(trace.packet)
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))

        original = trace.path.read_text()
        events = [json.loads(line) for line in original.splitlines()]
        events[0]["packet"] = f"{workstream.TASK_PACKET_ROOT}/OTHER.md"
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("packetless lifecycle trace contains packet metadata",
                      workstream._source_span_sync_merge_witness_error(
                          workstream_id, self.repo, merge_commit, trace,
                      ))
        trace.path.write_text(original)

        associated_packet = (self.repo / workstream.TASK_PACKET_ROOT
                             / f"{workstream_id.upper().replace('-', '_')}.md")
        associated_packet.parent.mkdir(parents=True, exist_ok=True)
        associated_packet.write_text(
            f"# Fixture\n- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
        )
        try:
            self.assertIn("conflicts with an associated task packet",
                          workstream._source_span_sync_merge_witness_error(
                              workstream_id, self.repo, merge_commit, trace,
                          ))
        finally:
            associated_packet.unlink()

    def test_finish_source_span_rejects_changed_main_sync_without_checkpoint(self):
        workstream_id, _, merge_commit, main_sha, trace = self._source_sync_merge_fixture(witness=False)
        trace.record("main_sync", changed=True, head=merge_commit, main_sha=main_sha)
        self._after_sync_witness(trace, merge_commit, main_sha)
        error = workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        )
        self.assertIsNotNone(error)
        self.assertIn("checkpoint", error)

    def test_finish_source_span_accepts_changed_main_sync_after_verified_checkpoint(self):
        workstream_id, _, merge_commit, main_sha, trace = self._source_sync_merge_fixture(witness=False)
        merge_first = git(self.repo, "rev-parse", f"{merge_commit}^1")
        trace.record("checkpoint_started", remove_worktree=False)
        trace.record("checkpoint_completed", branch=workstream.branch_for(workstream_id),
                     remote_head=merge_first, removed=False)
        trace.record("main_sync", changed=True, head=merge_commit, main_sha=main_sha)
        self._after_sync_witness(trace, merge_commit, main_sha)
        error = workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        )
        self.assertIsNone(error)

    def test_finish_source_span_rejects_missing_duplicate_or_mismatched_after_sync_report_witness(self):
        workstream_id, _, merge_commit, main_sha, trace = self._source_sync_merge_fixture(witness=False)
        first_parent = git(self.repo, "rev-parse", f"{merge_commit}^1")
        trace.record("checkpoint_started", remove_worktree=False)
        trace.record("checkpoint_completed", branch=workstream.branch_for(workstream_id),
                     remote_head=first_parent, removed=False)
        trace.record("main_sync", changed=True, head=merge_commit, main_sha=main_sha)
        missing = workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        )
        self.assertIn("after-sync validation witness", missing)

        self._after_sync_witness(trace, merge_commit, main_sha)
        original = trace.path.read_text()
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))
        events = [json.loads(line) for line in original.splitlines()]
        witness = next(event for event in events if event.get("event") == "validation_after_sync")
        events.append(json.loads(json.dumps(witness)))
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("unique after-sync", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))

        events = [json.loads(line) for line in original.splitlines()]
        witness = next(event for event in events if event.get("event") == "validation_after_sync")
        witness["data"]["source_tree"] = "0" * 40
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("invalid or misordered", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))

        events = [json.loads(line) for line in original.splitlines()]
        witness = next(event for event in events if event.get("event") == "validation_after_sync")
        events.remove(witness)
        sync_index = next(i for i, event in enumerate(events) if event.get("event") == "main_sync")
        events.insert(sync_index, witness)
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("invalid or misordered", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace,
        ))
        trace.path.write_text(original)

    def test_finish_source_span_requires_exact_final_noop_after_changed_sync(self):
        workstream_id, _, merge_commit, main_sha, trace = self._source_sync_merge_fixture(witness=False)
        merge_first = git(self.repo, "rev-parse", f"{merge_commit}^1")
        trace.record("checkpoint_started", remove_worktree=False)
        trace.record("checkpoint_completed", branch=workstream.branch_for(workstream_id),
                     remote_head=merge_first, removed=False)
        trace.record("main_sync", changed=True, head=merge_commit, main_sha=main_sha)
        self._after_sync_witness(trace, merge_commit, main_sha)
        trace.record("main_sync", changed=False, head=merge_commit, main_sha=main_sha)
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace, require_final_noop=True,
        ))

        original = trace.path.read_text()
        events = [json.loads(line) for line in original.splitlines()]
        no_op = events[-1]
        no_op["data"]["main_sha"] = "0" * 40
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("final no-op", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace, require_final_noop=True,
        ))

        events = [json.loads(line) for line in original.splitlines()]
        events.append(json.loads(json.dumps(events[-1])))
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("final no-op", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, merge_commit, trace, require_final_noop=True,
        ))
        trace.path.write_text(original)

    def test_finish_source_span_binds_two_changed_sync_merges_to_separate_checkpoints(self):
        workstream_id, _, first_merge, first_main, trace = self._source_sync_merge_fixture()
        branch = workstream.branch_for(workstream_id)
        events = [json.loads(line) for line in trace.path.read_text().splitlines()]
        events = [event for event in events if event["event"] != "worktree_resumed"]
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        trace.record("main_sync", changed=True, head=first_merge, main_sha=first_main)
        self._after_sync_witness(trace, first_merge, first_main)

        git(self.repo, "checkout", "main")
        (self.repo / "main-change-2.txt").write_text("second main advance\n")
        git(self.repo, "add", "main-change-2.txt")
        git(self.repo, "commit", "-m", "advance main a second time")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        second_main = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "checkout", branch)
        git(self.repo, "merge", "--no-ff", "origin/main", "-m", "synchronize main again")
        second_merge = git(self.repo, "rev-parse", "HEAD")
        second_parent = git(self.repo, "rev-parse", f"{second_merge}^1")
        self.assertEqual(second_parent, first_merge)

        trace.record("checkpoint_started", remove_worktree=False)
        trace.record("checkpoint_completed", branch=branch, remote_head=second_parent,
                     removed=False)
        trace.record("main_sync", changed=True, head=second_merge, main_sha=second_main)
        self._after_sync_witness(trace, second_merge, second_main)
        trace.record("main_sync", changed=False, head=second_merge, main_sha=second_main)
        self.assertIsNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, second_merge, trace, require_final_noop=True,
        ))

        original = trace.path.read_text()
        events = [json.loads(line) for line in original.splitlines()]
        second_checkpoint = next(
            event for event in events
            if event["event"] == "checkpoint_completed"
            and event["data"].get("remote_head") == second_parent
        )
        events.remove(second_checkpoint)
        second_checkpoint_start = max(
            i for i, event in enumerate(events)
            if event["event"] == "checkpoint_started"
            and i < events.index(next(e for e in events if e["event"] == "main_sync"
                                      and e["data"].get("head") == second_merge))
        )
        del events[second_checkpoint_start]
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("checkpoint", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, second_merge, trace, require_final_noop=True,
        ))

        trace.path.write_text(original)

    def test_finish_source_span_rejects_wrong_merge_tree_parent_order_and_main(self):
        workstream_id, source_base, merge_commit, _, trace = self._source_sync_merge_fixture()
        first_parent = git(self.repo, "rev-parse", f"{merge_commit}^1")
        second_parent = git(self.repo, "rev-parse", f"{merge_commit}^2")
        original_trace = trace.path.read_text()

        wrong_tree_commit = git(
            self.repo, "commit-tree", f"{first_parent}^{{tree}}",
            "-p", first_parent, "-p", second_parent, "-m", "wrong deterministic tree",
        )
        events = [json.loads(line) for line in original_trace.splitlines()]
        resume = next(event for event in events if event["event"] == "worktree_resumed")
        resume["data"]["head"] = wrong_tree_commit
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIn("deterministic merge tree", workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, wrong_tree_commit, trace,
        ))

        wrong_order_commit = git(
            self.repo, "commit-tree", f"{merge_commit}^{{tree}}",
            "-p", second_parent, "-p", first_parent, "-m", "reversed synchronization parents",
        )
        events = [json.loads(line) for line in original_trace.splitlines()]
        resume = next(event for event in events if event["event"] == "worktree_resumed")
        resume["data"]["head"] = wrong_order_commit
        trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
        self.assertIsNotNone(workstream._source_span_sync_merge_witness_error(
            workstream_id, self.repo, wrong_order_commit, trace,
        ))

        trace.path.write_text(original_trace)
        old_main = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "update-ref", "refs/remotes/origin/main", source_base)
        try:
            self.assertIn("outside origin/main", workstream._source_span_sync_merge_witness_error(
                workstream_id, self.repo, merge_commit, trace,
            ))
        finally:
            git(self.repo, "update-ref", "refs/remotes/origin/main", old_main)

    def test_finish_source_span_rejects_tampered_or_reused_lifecycle_witnesses(self):
        workstream_id, source_base, merge_commit, main_sha, trace = self._source_sync_merge_fixture()
        original = trace.path.read_text()
        bad_claim = git(
            self.repo, "commit-tree", f"{source_base}^{{tree}}", "-p", source_base,
            "-m", f"forged claim for {workstream_id}",
        )
        mutations = (
            "wrong-run", "wrong-workstream", "wrong-packet", "wrong-schema-version",
            "wrong-data-shape", "wrong-branch", "wrong-claim-base", "wrong-claim-subject",
            "wrong-claim-pid", "wrong-checkpoint-head", "removed-checkpoint",
            "duplicate-checkpoint", "checkpoint-after-resume", "wrong-resume-head",
            "wrong-resume-branch", "wrong-worktree", "duplicate-resume", "reordered",
            "wrong-sync-main", "duplicate-sync", "conflicting-sync-resume",
        )
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                events = [json.loads(line) for line in original.splitlines()]
                checkpoints = [event for event in events if event["event"] == "checkpoint_completed"]
                resumes = [event for event in events if event["event"] == "worktree_resumed"]
                claims = [event for event in events if event["event"] == "remote_claim_acquired"]
                if mutation == "wrong-run":
                    events[0]["run_id"] = "20261031T000000Z-000000000000"
                elif mutation == "wrong-workstream":
                    events[0]["workstream"] = "agent-other"
                elif mutation == "wrong-packet":
                    events[0]["packet"] = "custodian/docs/ai_context/task_packets/OTHER.md"
                elif mutation == "wrong-schema-version":
                    events[0]["schema_version"] = 2
                elif mutation == "wrong-data-shape":
                    events[0]["data"] = []
                elif mutation == "wrong-branch":
                    checkpoints[0]["data"]["branch"] = "agent/other"
                elif mutation == "wrong-claim-base":
                    claims[0]["data"]["main_sha"] = "0" * 40
                elif mutation == "wrong-claim-subject":
                    claims[0]["data"]["claim_oid"] = bad_claim
                elif mutation == "wrong-claim-pid":
                    claims[0]["pid"] += 1
                elif mutation == "wrong-checkpoint-head":
                    checkpoints[0]["data"]["remote_head"] = "0" * 40
                elif mutation == "removed-checkpoint":
                    checkpoints[0]["data"]["removed"] = True
                elif mutation == "duplicate-checkpoint":
                    events.append(json.loads(json.dumps(checkpoints[0])))
                elif mutation == "checkpoint-after-resume":
                    events.remove(checkpoints[0])
                    events.append(checkpoints[0])
                elif mutation == "wrong-resume-head":
                    resumes[0]["data"]["head"] = "0" * 40
                elif mutation == "wrong-resume-branch":
                    resumes[0]["data"]["branch"] = "agent/other"
                elif mutation == "wrong-worktree":
                    resumes[0]["data"]["worktree"] = "/tmp/other-worktree"
                elif mutation == "duplicate-resume":
                    events.append(json.loads(json.dumps(resumes[0])))
                elif mutation == "reordered":
                    events.remove(resumes[0])
                    events.insert(events.index(checkpoints[0]), resumes[0])
                elif mutation in {"wrong-sync-main", "duplicate-sync", "conflicting-sync-resume"}:
                    sync_data = {"changed": True, "head": merge_commit, "main_sha": main_sha}
                    if mutation == "wrong-sync-main":
                        sync_data["main_sha"] = "0" * 40
                    sync = json.loads(json.dumps(resumes[0]))
                    sync["event"] = "main_sync"
                    sync["data"] = sync_data
                    events.append(sync)
                    if mutation == "duplicate-sync":
                        events.append(json.loads(json.dumps(sync)))
                trace.path.write_text("".join(json.dumps(event) + "\n" for event in events))
                self.assertIsNotNone(workstream._source_span_sync_merge_witness_error(
                    workstream_id, self.repo, merge_commit, trace,
                ))
        trace.path.write_text(original)

    def test_finish_blocks_unwitnessed_source_merge_before_publishing_branch(self):
        workstream_id, _, merge_commit, _, trace = self._source_sync_merge_fixture(witness=False)
        active_rel = trace.packet
        active = self.repo / active_rel
        archived = self.repo / workstream.TASK_PACKET_ARCHIVE / active.name
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("`in_progress`", "`complete`"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive fixture packet")

        with mock.patch.object(workstream, "fetch"), \
             mock.patch.object(workstream, "find_worktree", return_value=self.repo), \
             mock.patch.object(workstream, "artifact_preflight", return_value=[]), \
             mock.patch.object(workstream, "_completion_truth_preflight"), \
             mock.patch.object(workstream, "status_clean", return_value=True), \
             mock.patch.object(workstream, "closing_summary_committed_for_workstream"), \
             mock.patch.object(workstream, "validation_green", return_value=True), \
             mock.patch.object(workstream, "git", wraps=workstream.git) as git_call:
            with self.assertRaisesRegex(workstream.WorkstreamError, "checkpoint"):
                workstream._finish_impl(
                    workstream_id, self._green_report(), repo=self.repo, trace=trace,
                )

        self.assertFalse(any(call.args and call.args[0] == "push" for call in git_call.call_args_list))
        self.assertEqual(git(self.repo, "ls-remote", "--heads", "origin", f"agent/{workstream_id}"), "")

    def test_finish_blocks_landing_when_post_sync_trace_cannot_be_published(self):
        workstream_id = "finish-trace-publish-block"
        path = workstream.start(workstream_id, self.repo)
        self._commit_task_work(path, workstream_id)
        main_before = git(self.repo, "rev-parse", "origin/main")
        (self.repo / "main-advance-for-trace").write_text("advance\n")
        git(self.repo, "add", "main-advance-for-trace")
        git(self.repo, "commit", "-m", "advance main before finish")
        git(self.repo, "push", "origin", "main")

        real_run = workstream.subprocess.run
        landing_calls = []
        def observe_landing(args, *call_args, **call_kwargs):
            if args and "land_main.py" in str(args[0]):
                landing_calls.append(args)
            return real_run(args, *call_args, **call_kwargs)

        original_after_sync = workstream._after_sync_report_data
        def bind_fixture_report(report: Path, source_path: Path, sync_head: str):
            payload = json.loads(report.read_text())
            payload["coverage"] = {"complete": True, "uncovered_files": []}
            payload["selected"] = ["fixture"]
            payload["tests"] = [{"id": "fixture", "status": "passed"}]
            payload["summary"] = {"selected": 1, "passed": 1, "failed": 0,
                                  "timed_out": 0, "skipped": 0,
                                  "infrastructure_errors": 0}
            payload["source_identity"] = workstream._git_source_identity(source_path, sync_head)
            payload["source_changed_during_validation"] = False
            report.write_text(json.dumps(payload))
            return original_after_sync(report, source_path, sync_head)

        with mock.patch.object(workstream.RunTrace, "publish", return_value=False), \
             mock.patch.object(workstream, "_after_sync_report_data", side_effect=bind_fixture_report), \
             mock.patch.object(workstream.subprocess, "run", side_effect=observe_landing):
            with self.assertRaisesRegex(workstream.WorkstreamError, "lifecycle trace publication failed"):
                workstream.finish(
                    workstream_id, self._green_report("pre-sync.json"),
                    validation_report_after_sync=self._green_report("post-sync.json"), repo=path,
                )

        self.assertEqual(landing_calls, [])
        self.assertTrue(path.exists())
        self.assertEqual(git(self.repo, "rev-parse", "origin/main"), git(self.repo, "rev-parse", "main"))
        self.assertNotEqual(main_before, git(self.repo, "rev-parse", "origin/main"))
        self.assertNotEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))

    def test_finish_runs_operator_authority_guard_before_any_push(self):
        workstream_id = "operator-guard-fixture"
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        actor = self.repo / "custodian/game/actors/operator/operator.gd"
        actor.parent.mkdir(parents=True)
        actor.write_text("extends CharacterBody2D\n")
        guard = self.repo / "custodian/tools/validation/operator_chassis_authority_guard.py"
        guard.parent.mkdir(parents=True)
        guard.write_text(
            "import json, sys\n"
            "print(json.dumps({'passed': False, 'failures': ['fixture rejected']}))\n"
            "sys.exit(1)\n"
        )
        git(self.repo, "add", "custodian/game/actors/operator/operator.gd",
            "custodian/tools/validation/operator_chassis_authority_guard.py")
        git(self.repo, "commit", "-m", "add operator authority fixture")

        with mock.patch.object(workstream, "fetch"), \
             mock.patch.object(workstream, "find_worktree", return_value=self.repo), \
             mock.patch.object(workstream, "git", wraps=workstream.git) as git_call:
            with self.assertRaisesRegex(workstream.WorkstreamError, "fixture rejected"):
                workstream._finish_impl(workstream_id, self.repo / "validation.json", repo=self.repo)

        self.assertFalse(any(call.args and call.args[0] == "push" for call in git_call.call_args_list))
        self.assertEqual(git(self.repo, "branch", "--show-current"), branch)
        self.assertTrue(actor.exists())

    def test_operator_authority_guard_leaves_unrelated_workstreams_unaffected(self):
        result = workstream._run_operator_chassis_authority_guard(self.repo, self.repo)
        self.assertEqual(result["status"], "not_applicable")

    def test_closeout_preflight_reports_operator_authority_guard_failure(self):
        failure = {"status": "blocked", "failures": ["fixture rejected"]}
        with mock.patch.object(workstream, "_run_operator_chassis_authority_guard",
                                return_value=failure) as guard_call:
            result = workstream.closeout_preflight("operator-guard-fixture", self.repo)
        self.assertEqual(result["operator_chassis_authority_guard"], failure)
        self.assertTrue(any(
            item["gate"] == "operator_chassis_authority_guard" and item["detail"] == "fixture rejected"
            for item in result["blockers"]
        ))
        guard_call.assert_called_once_with(self.repo.resolve(), self.repo.resolve())

    def test_failed_import_recovery_accepts_only_pinned_carow_main_advance(self):
        repo = Path(__file__).resolve().parents[3]
        pinned = workstream.FAILED_IMPORT_ARCHIVE_RECOVERY
        current = "b5b1e5f2450f3f577a5df5c173c338e6da5187d1"
        expected = [
            "0da9923e818645178a079eece3482216cd295ccc",
            "0ed185fd23946eeb8a6d5835c171000a65f75a68",
            "e1cfee4692a754a98a27d7fb3cf382dc55328bb8",
            "ae5e0d8719d028f8feba6f4250633c30dfe0f470",
            "bc79a4938577a9822f2d1c3c95ac701f5e8cb0d9",
            current,
        ]
        actual = workstream.git(
            "rev-list", "--first-parent", "--reverse",
            f"{pinned['final_main']}..{current}", cwd=repo,
        ).splitlines()
        self.assertEqual(actual, expected)
        expected_paths = [
            {"custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md"},
            {"custodian/docs/ai_context/task_packets/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"},
            {"custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"},
            {"design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md"},
            {"custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md"},
            {
                "custodian/docs/ai_context/task_packets/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
                "custodian/docs/ai_context/task_packets/README.md",
                "custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
            },
        ]
        for commit, expected_commit_paths in zip(expected, expected_paths):
            actual_paths = set(workstream.git(
                "diff-tree", "--no-commit-id", "--name-only", "-r", commit, cwd=repo,
            ).splitlines())
            self.assertEqual(actual_paths, expected_commit_paths)

        self.assertTrue(workstream._failed_import_main_advance_is_authorized(
            repo, pinned, current,
        ))
        self.assertFalse(workstream._failed_import_main_advance_is_authorized(
            repo, pinned, current + "1",
        ))
        forged = dict(pinned)
        forged["authorized_main_advance"] = dict(pinned["authorized_main_advance"])
        forged["authorized_main_advance"]["commits"] = expected[:-1] + ["1" * 40]
        self.assertFalse(workstream._failed_import_main_advance_is_authorized(
            repo, forged, current,
        ))
        forged_paths = dict(pinned)
        forged_paths["authorized_main_advance"] = dict(pinned["authorized_main_advance"])
        forged_paths["authorized_main_advance"]["commit_paths"] = [
            ["unrelated/unauthorized.md"],
            *pinned["authorized_main_advance"]["commit_paths"][1:],
        ]
        self.assertFalse(workstream._failed_import_main_advance_is_authorized(
            repo, forged_paths, current,
        ))

    def test_failed_import_suffix_allows_three_bounded_corrections_then_exact_sync(self):
        git(self.repo, "checkout", "main")
        for relative in ("custodian/tools/agent/workstream.py",
                         "custodian/tools/agent/test_workstream.py"):
            path = self.repo / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("base\n")
        git(self.repo, "add", "custodian/tools/agent/workstream.py",
            "custodian/tools/agent/test_workstream.py")
        git(self.repo, "commit", "-m", "seed bounded recovery correction paths")
        correction_base = git(self.repo, "rev-parse", "HEAD")
        branch = "agent-test-bounded-recovery-suffix"
        git(self.repo, "checkout", "-b", branch)
        corrections = []
        correction_paths = (
            "custodian/tools/agent/workstream.py",
            "custodian/tools/agent/test_workstream.py",
        )
        for index in range(3):
            relative = correction_paths[index % 2]
            (self.repo / relative).write_text(f"correction {index}\n")
            git(self.repo, "add", relative)
            git(self.repo, "commit", "-m", f"bounded correction {index}")
            corrections.append(git(self.repo, "rev-parse", "HEAD"))

        git(self.repo, "checkout", "main")
        (self.repo / "unrelated-main.md").write_text("main advance\n")
        git(self.repo, "add", "unrelated-main.md")
        git(self.repo, "commit", "-m", "advance main")
        main = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", branch)

        self.assertEqual(
            workstream._failed_import_recovery_suffix(
                self.repo, corrections, correction_base, main,
            ),
            (corrections, None),
        )

        git(self.repo, "merge", "--no-ff", "main", "-m", "exact recovery sync")
        sync = git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(
            workstream._failed_import_recovery_suffix(
                self.repo, [*corrections, sync], correction_base, main,
            ),
            (corrections, sync),
        )

        git(self.repo, "checkout", "-b", "agent-test-fourth-recovery-correction", corrections[-1])
        (self.repo / correction_paths[0]).write_text("fourth correction\n")
        git(self.repo, "add", correction_paths[0])
        git(self.repo, "commit", "-m", "fourth bounded-path correction")
        fourth = git(self.repo, "rev-parse", "HEAD")
        self.assertIsNone(workstream._failed_import_recovery_suffix(
            self.repo, [*corrections, fourth], correction_base, main,
        ))

        git(self.repo, "checkout", "-b", "agent-test-sync-before-correction-tail", sync)
        (self.repo / correction_paths[0]).write_text("post-sync correction\n")
        git(self.repo, "add", correction_paths[0])
        git(self.repo, "commit", "-m", "correction after sync")
        after_sync = git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(
            workstream._failed_import_recovery_suffix(
                self.repo, [*corrections, sync, after_sync], correction_base, main,
            ),
            ([*corrections, after_sync], sync),
        )
        (self.repo / correction_paths[1]).write_text("second post-sync correction\n")
        git(self.repo, "add", correction_paths[1])
        git(self.repo, "commit", "-m", "second post-sync correction")
        second_after_sync = git(self.repo, "rev-parse", "HEAD")
        self.assertIsNone(workstream._failed_import_recovery_suffix(
            self.repo, [*corrections, sync, after_sync, second_after_sync], correction_base, main,
        ))

    def test_index_merge_accepts_only_authenticated_completed_archive_removal(self):
        # This historical main-sync required a removal because main had already
        # archived another task. The additive-only check must remain strict.
        from paired_review_host_validation import (
            _managed_packet_index_additive_reconciliation as additive,
            _managed_packet_index_archival_reconciliation as archival,
        )
        import paired_review_host_validation as host_validation

        repo = Path(__file__).resolve().parents[3]
        first = "44b1ce5b44ff9e40cb017cfef1cea9abba8826ab"
        main = "c39d5b771c730b8bd25efb0f005adfca3abe6b43"
        merge = "7a8be70c366fd00b00d488b5385eccb6dff47e6e"
        readme = "custodian/docs/ai_context/task_packets/README.md"
        versions = [
            subprocess.run(["git", "show", f"{ref}:{readme}"], cwd=repo,
                           capture_output=True, check=True).stdout
            for ref in (first, main, merge)
        ]
        self.assertFalse(additive(*versions))
        self.assertTrue(archival(repo, first, main, merge))
        self.assertTrue(workstream._authenticated_managed_index_reconciliation(
            host_validation, repo, first, main, merge, *versions,
        ))

        # A foreign or fabricated merge cannot be excused by the archival path.
        self.assertFalse(workstream._authenticated_managed_index_reconciliation(
            host_validation, repo, first, main, first, *versions,
        ))

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
        legacy_summary = self.repo / "AGENT_TEST_ARCHIVE_TIP_LEGACY_CLAUDE_SUMMARY.md"
        legacy_summary.write_bytes(b"canonical closeout bytes\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "add", str(legacy_summary.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))
        preflight = workstream.closeout_preflight(workstream_id, self.repo)
        self.assertEqual(preflight["archive_transition"]["status"], "pass")

        canonical_summary = self.repo / workstream._expected_summary_filename(workstream_id)
        legacy_bytes = legacy_summary.read_bytes()
        legacy_summary.unlink()
        canonical_summary.write_bytes(legacy_bytes)
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "rename archived summary to canonical filename")
        rename_commit = git(self.repo, "rev-parse", "HEAD")
        transition_commit = git(self.repo, "rev-parse", "HEAD^1")
        self.assertTrue(workstream._is_authorized_archive_summary_rename(
            workstream_id, self.repo, transition_commit,
            "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_ARCHIVE_TIP.md",
            rename_commit,
        ))
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

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

    def test_archive_summary_rename_rejects_real_git_near_misses(self):
        workstream_id = "agent-test-summary-rename"
        branch = workstream.branch_for(workstream_id)
        active = self.repo / "custodian/docs/ai_context/task_packets/AGENT_TEST_SUMMARY_RENAME.md"
        archived_rel = "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_SUMMARY_RENAME.md"
        archived = self.repo / archived_rel
        legacy_rel = "AGENT_TEST_SUMMARY_RENAME_OLD_CLAUDE_SUMMARY.md"
        legacy = self.repo / legacy_rel
        canonical_rel = workstream._expected_summary_filename(workstream_id)
        canonical = self.repo / canonical_rel
        git(self.repo, "checkout", "-b", branch)
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            f"# Test\n- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
        )
        git(self.repo, "add", str(active.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish summary rename packet")
        (self.repo / "source.py").write_text("source\n")
        legacy.write_bytes(b"identical closing summary\n")
        git(self.repo, "add", "source.py", legacy_rel)
        git(self.repo, "commit", "-m", "implement and write legacy summary")
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive summary rename packet")
        archive = git(self.repo, "rev-parse", "HEAD")

        mutations = ("changed-bytes", "wrong-destination", "copy", "extra-path",
                     "executable", "symlink", "changed-packet", "wrong-parent",
                     "source-edit")
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                git(self.repo, "checkout", "-B", branch, archive)
                if mutation == "wrong-parent":
                    git(self.repo, "commit", "--allow-empty", "-m", "insert unrelated parent")
                legacy.unlink(missing_ok=True)
                destination = (self.repo / "WRONG_CLAUDE_SUMMARY.md"
                              if mutation == "wrong-destination" else canonical)
                if mutation == "symlink":
                    destination.symlink_to("source.py")
                else:
                    destination.write_bytes(
                        b"changed closing summary\n" if mutation == "changed-bytes"
                        else b"identical closing summary\n"
                    )
                    if mutation == "executable":
                        destination.chmod(0o755)
                if mutation == "copy":
                    legacy.write_bytes(b"identical closing summary\n")
                if mutation == "extra-path":
                    (self.repo / "unrelated.txt").write_text("extra\n")
                if mutation == "changed-packet":
                    archived.write_text(archived.read_text() + "- Changed: true\n")
                if mutation == "source-edit":
                    (self.repo / "source.py").write_text("modified after archive\n")
                git(self.repo, "add", "-A")
                git(self.repo, "commit", "-m", f"attempt invalid summary rename: {mutation}")
                candidate = git(self.repo, "rev-parse", "HEAD")
                self.assertFalse(workstream._is_authorized_archive_summary_rename(
                    workstream_id, self.repo, archive, archived_rel, candidate,
                ))
                self.assertIsNotNone(workstream._archive_transition_tip_error(
                    workstream_id, self.repo,
                ))

        with self.subTest(mutation="second-rename"):
            git(self.repo, "checkout", "-B", branch, archive)
            legacy.unlink()
            canonical.write_bytes(b"identical closing summary\n")
            git(self.repo, "add", "-A")
            git(self.repo, "commit", "-m", "first exact rename")
            extra_legacy = self.repo / "SECOND_CLAUDE_SUMMARY.md"
            canonical.unlink()
            extra_legacy.write_bytes(b"identical closing summary\n")
            git(self.repo, "add", "-A")
            git(self.repo, "commit", "-m", "second summary rename")
            self.assertIsNotNone(workstream._archive_transition_tip_error(
                workstream_id, self.repo,
            ))

        with self.subTest(mutation="merge-instead-of-single-parent"):
            side_branch = "summary-rename-side-branch"
            git(self.repo, "checkout", "-B", side_branch, archive)
            legacy.unlink()
            canonical.write_bytes(b"identical closing summary\n")
            git(self.repo, "add", "-A")
            git(self.repo, "commit", "-m", "prepare summary rename side branch")
            git(self.repo, "checkout", "-B", branch, archive)
            git(self.repo, "merge", "--no-ff", side_branch, "-m", "merge summary rename")
            candidate = git(self.repo, "rev-parse", "HEAD")
            self.assertFalse(workstream._is_authorized_archive_summary_rename(
                workstream_id, self.repo, archive, archived_rel, candidate,
            ))
            self.assertIsNotNone(workstream._archive_transition_tip_error(
                workstream_id, self.repo,
            ))

    def test_archive_guard_accepts_only_exact_rc119_metadata_correction(self):
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["archive"],
                         "704a1fbb3df6deae64e06291769eabd1d48f7eb2")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["correction"],
                         "81fb8ca935bb2d5f9f00f18d547c185035e7b8dd")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["archive_tree"],
                         "14574039da27513ecaad7b02aeb08f75d2a11ae4")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["correction_tree"],
                         "58e639a24470c27a1999a796fd0ae53d5ed778a5")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["archive_parent"],
                         "e1bff4eb3360e7f0fcdbc5bb67fa86bc2b600f4f")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["archive_packet_blob_oid"],
                         "16307c7f771abe5587ccd95baa6f69e239544e59")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["archive_packet_sha256"],
                         "01398f7950b9cbf617d97204e03e041cb6df99983ac187e8b66a3f56073c8764")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["corrected_packet_blob_oid"],
                         "b3d842692d5b31871f86b03b6a830dee1734be1a")
        self.assertEqual(workstream.ARCHIVE_METADATA_FOLLOWUP["corrected_packet_sha256"],
                         "b42d92e3d40815a37ec17fa5a776e480950d99520a253f1e0500b859af5315d8")
        workstream_id = "review-agent-paired-review-runner-profile-summary-coverage-v1"
        branch = workstream.branch_for(workstream_id)
        active_rel = (
            "custodian/docs/ai_context/task_packets/"
            "REVIEW_AGENT_PAIRED_REVIEW_RUNNER_PROFILE_SUMMARY_COVERAGE_V1.md"
        )
        archived_rel = f"custodian/docs/ai_context/task_packets/archived/{Path(active_rel).name}"
        active = self.repo / active_rel
        archived = self.repo / archived_rel
        git(self.repo, "checkout", "-b", branch)
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            "# Protected review fixture\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Kind: `review`\n- Review: `passed`\n"
            "- Review target workstream: `agent-paired-review-runner-profile-summary-coverage-v1`\n"
            "- Review target packet: `custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_RUNNER_PROFILE_SUMMARY_COVERAGE_V1.md`\n"
        )
        git(self.repo, "add", active_rel)
        git(self.repo, "commit", "-m", "publish review fixture")
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text())
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive review fixture")
        archive = git(self.repo, "rev-parse", "HEAD")
        archive_parent = git(self.repo, "rev-parse", "HEAD^1")
        archive_tree = git(self.repo, "rev-parse", "HEAD^{tree}")
        archive_packet_blob = git(self.repo, "rev-parse", f"HEAD:{archived_rel}")
        archive_packet_sha256 = hashlib.sha256(archived.read_bytes()).hexdigest()

        archived.write_text(archived.read_text().replace(
            "- Review: `passed`", "- Review: `none`", 1,
        ))
        git(self.repo, "add", archived_rel)
        git(self.repo, "commit", "-m", "correct administrative review metadata")
        correction = git(self.repo, "rev-parse", "HEAD")
        pin = {
            "workstream": workstream_id,
            "archive": archive,
            "archive_parent": archive_parent,
            "archive_tree": archive_tree,
            "archive_packet_blob_oid": archive_packet_blob,
            "archive_packet_sha256": archive_packet_sha256,
            "correction": correction,
            "correction_tree": git(self.repo, "rev-parse", "HEAD^{tree}"),
            "corrected_packet_blob_oid": git(self.repo, "rev-parse", f"HEAD:{archived_rel}"),
            "corrected_packet_sha256": hashlib.sha256(archived.read_bytes()).hexdigest(),
            "packet": archived_rel,
        }
        with mock.patch.dict(workstream.ARCHIVE_METADATA_FOLLOWUP, pin):
            self.assertTrue(workstream._is_authorized_archive_metadata_followup(
                workstream_id, self.repo, archive, archived_rel, correction,
            ))
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

            # Normal finish's archive-first main sync remains accepted after
            # the exact correction; the merge is independently tree-verified.
            git(self.repo, "checkout", "main")
            (self.repo / "main-advance.txt").write_text("unrelated main change\n")
            git(self.repo, "add", "main-advance.txt")
            git(self.repo, "commit", "-m", "advance main")
            git(self.repo, "push", "origin", "main")
            git(self.repo, "fetch", "origin")
            git(self.repo, "checkout", branch)
            git(self.repo, "merge", "--no-ff", "origin/main", "-m", "sync main")
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

            # A new post-sync edit to the protected review packet is outside
            # the one correction pinned above.
            archived.write_text(archived.read_text() + "- Extra: unauthorized\n")
            git(self.repo, "add", archived_rel)
            git(self.repo, "commit", "-m", "edit archived review again")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

        # Near-miss pre-sync histories cannot borrow the pinned correction:
        # extra bytes, another path, or a changed reviewer target all hash to
        # different commits and remain blocked.
        for mutation in ("extra-bytes", "extra-path", "changed-target", "wrong-parent",
                         "changed-summary"):
            with self.subTest(mutation=mutation):
                git(self.repo, "checkout", "-B", branch, archive)
                if mutation == "extra-path":
                    (self.repo / "outside.txt").write_text("unapproved\n")
                    git(self.repo, "add", "outside.txt")
                elif mutation == "wrong-parent":
                    (self.repo / "outside.txt").write_text("unexpected parent\n")
                    git(self.repo, "add", "outside.txt")
                    git(self.repo, "commit", "-m", "insert unauthorized parent")
                    archived.write_text(archived.read_text().replace(
                        "- Review: `passed`", "- Review: `none`", 1,
                    ))
                    git(self.repo, "add", archived_rel)
                elif mutation == "changed-summary":
                    archived.write_text(archived.read_text().replace(
                        "- Review: `passed`", "- Review: `none`", 1,
                    ))
                    (self.repo / "summary.md").write_text("unauthorized summary edit\n")
                    git(self.repo, "add", archived_rel, "summary.md")
                else:
                    text = archived.read_text()
                    text = text.replace("- Review: `passed`", "- Review: `none`", 1)
                    if mutation == "extra-bytes":
                        text += "- Extra: unapproved\n"
                    else:
                        text = text.replace(
                            "- Review target workstream: `agent-paired-review-runner-profile-summary-coverage-v1`",
                            "- Review target workstream: `forged-target`",
                        )
                    archived.write_text(text)
                    git(self.repo, "add", archived_rel)
                git(self.repo, "commit", "-m", f"attempt {mutation}")
                candidate = git(self.repo, "rev-parse", "HEAD")
                with mock.patch.dict(workstream.ARCHIVE_METADATA_FOLLOWUP, pin):
                    self.assertFalse(workstream._is_authorized_archive_metadata_followup(
                        workstream_id, self.repo, archive, archived_rel, candidate,
                    ))
                    self.assertIsNotNone(workstream._archive_transition_tip_error(
                        workstream_id, self.repo,
                    ))

    def test_rc119_production_pin_authenticates_preserved_commits_without_mocking(self):
        pinned = workstream.ARCHIVE_METADATA_FOLLOWUP
        repo = Path(__file__).resolve().parents[3]
        for commit in (pinned["archive"], pinned["correction"]):
            available = subprocess.run(
                ["git", "cat-file", "-e", f"{commit}^{{commit}}"], cwd=repo,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            ).returncode == 0
            if not available:
                self.skipTest("preserved RC-119 commits are not present in this checkout's object database")
        self.assertTrue(workstream._is_authorized_archive_metadata_followup(
            pinned["workstream"], repo, pinned["archive"], pinned["packet"],
            pinned["correction"],
        ))

        protected = repo.parent / (
            "review-agent-paired-review-runner-profile-summary-coverage-v1-"
            "20261031T154805Z-601d4382c346"
        )
        if protected.is_dir():
            self.assertEqual(git(protected, "rev-parse", "HEAD"), pinned["correction"])
            self.assertIsNone(workstream._archive_transition_tip_error(
                pinned["workstream"], protected,
            ))

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
        legacy_summary = self.repo / "AGENT_TEST_ARCHIVE_TRACE_OLD_CLAUDE_SUMMARY.md"
        legacy_summary.write_text("historical summary filename\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "add", str(legacy_summary.relative_to(self.repo)))
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
        legacy_summary = self.repo / "AGENT_TEST_ARCHIVE_TRACE_OLD_CLAUDE_SUMMARY.md"
        legacy_summary.write_text("historical summary filename\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "add", str(legacy_summary.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")
        archive = git(self.repo, "rev-parse", "HEAD")

        legacy_summary.unlink()
        canonical_summary = self.repo / workstream._expected_summary_filename(workstream_id)
        canonical_summary.write_bytes(b"historical summary filename\n")
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "correct summary filename")

        # Make an independently published main commit, then sync it into the task branch.
        git(self.repo, "checkout", "main")
        (self.repo / "main-only").write_text("main\n")
        git(self.repo, "add", "main-only")
        git(self.repo, "commit", "-m", "advance main")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
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

    @mock.patch.object(workstream, "_run_operator_chassis_authority_guard",
                       return_value={"status": "passed"})
    def test_archive_guard_accepts_authenticated_post_archive_recovery_chain(self, _guard):
        workstream_id = "agent-paired-review-failed-host-validation-import-recovery-v1"
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["archive"],
                         "25229d8d3874608f7b8492df98bc3df4385a9d28")
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["final_sync"],
                         "d83319a3a9c211fe3947e4951bfaa06f1684bf05")
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["final_main"],
                         "8e4bca145658b825bb6dedeed595a3c53497a138")
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["claim_oid"],
                         "5249f25988aa13cdf99372754509fb7b91eeef94")
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["trace_anchor"],
                         "173104f75f4380aa2c5eadf0e0c8ca2f2bd04855")
        self.assertEqual(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["correction_commits"], [
            "d68bd6e5c5b151ddd6aa38485ae9c2302a5fe993",
            "a3f7bfc4fbb7911b7dfe2a2982cff6de981f99a8",
            "819c9347a59f0029ce8d52ddcdcf6c58838ab2c0",
            "596dc6c1e9c949eb18940769e4232351ad9f1e60",
            "9c806d5dd592c14ce0e82ceeeff056bb284305e7",
        ])
        branch = workstream.branch_for(workstream_id)
        active_rel = "custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"
        archived_rel = "custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"
        authoring_chat = "https://chatgpt.com/c/test-recovery"
        packets = self.repo / active_rel
        packets.parent.mkdir(parents=True, exist_ok=True)
        packets.write_text(
            "# Recovery fixture\n\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Status: `ready`\n"
            f"- Authoring chat: `{authoring_chat}`\n"
            "- Work surface: `custodian/tools/agent/workstream.py`; "
            "`custodian/tools/agent/test_workstream.py`\n"
        )
        source_path = self.repo / "custodian/tools/agent/workstream.py"
        test_path = self.repo / "custodian/tools/agent/test_workstream.py"
        source_path.parent.mkdir(parents=True, exist_ok=True)
        source_path.write_text("baseline lifecycle gate\n")
        test_path.write_text("baseline lifecycle tests\n")
        git(self.repo, "add", active_rel, "custodian/tools/agent/workstream.py",
            "custodian/tools/agent/test_workstream.py")
        git(self.repo, "commit", "-m", "publish recovery fixture")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "checkout", "-b", branch)
        claim_base = git(self.repo, "rev-parse", "HEAD")

        (self.repo / "source.py").write_text("implementation\n")
        git(self.repo, "add", "source.py"); git(self.repo, "commit", "-m", "implement recovery")
        packet_text = packets.read_text().replace("- Status: `ready`", "- Status: `complete`")
        packet_text += (
            "\n## Completion Truth\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `yes`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Evidence: `fixture evidence`.\n"
            "\n## Next Handoff\n"
            f"- Authoring chat: `{authoring_chat}`\n"
        )
        archived = self.repo / archived_rel
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(packet_text); packets.unlink()
        summary_rel = workstream._expected_summary_filename(workstream_id)
        summary = self.repo / summary_rel
        summary.write_text(
            "recovery complete\n\n## Next Handoff\n"
            f"- Authoring chat: `{authoring_chat}`\n"
        )
        git(self.repo, "add", "-A"); git(self.repo, "commit", "-m", "archive recovery packet")
        archive_commit = git(self.repo, "rev-parse", "HEAD")

        summary.write_text(
            "recovery complete\n\n"
            f"Authoring chat: {authoring_chat}\n\n## Next Handoff\n"
            f"- Authoring chat: {authoring_chat}\n"
        )
        git(self.repo, "add", summary_rel); git(self.repo, "commit", "-m", "repair summary provenance")
        provenance_commit = git(self.repo, "rev-parse", "HEAD")
        premerge_archived_text = archived.read_text()

        # The first sync is a clean merge. A later main refresh to the active
        # packet is reconciled into the archived packet during the second sync.
        git(self.repo, "checkout", "main")
        (self.repo / "first-main-advance").write_text("first\n")
        git(self.repo, "add", "first-main-advance")
        git(self.repo, "commit", "-m", "advance main before first sync")
        first_main = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "checkout", branch)
        git(self.repo, "merge", "--no-ff", "main", "-m", "first sync")
        first_merge = git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^1"), provenance_commit)
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^2"), first_main)

        archived.write_text(archived.read_text().replace(
            "- Evidence: `fixture evidence`.",
            "- Evidence: `fixture evidence.`\n"
            f"- Post-sync validation: `After merge `{first_merge}`, changed-file validation "
            "passed 43/43 with complete coverage and no timeouts; the manifest retained "
            "the authorized 90-second bound.`",
        ))
        git(self.repo, "add", archived_rel); git(self.repo, "commit", "-m", "record post-sync evidence")
        post_sync = git(self.repo, "rev-parse", "HEAD")
        self.assertTrue(workstream._post_sync_completion_evidence_is_bounded(
            self.repo, post_sync, archived_rel,
        ))
        git(self.repo, "checkout", "-b", "adversarial-post-sync-evidence", post_sync)
        archived.write_text(archived.read_text().replace(
            "- Evidence: `fixture evidence.`",
            "- Evidence: `forged completion evidence.`",
        ))
        git(self.repo, "add", archived_rel)
        git(self.repo, "commit", "-m", "forge post-sync completion evidence")
        forged_post_sync = git(self.repo, "rev-parse", "HEAD")
        self.assertFalse(workstream._post_sync_completion_evidence_is_bounded(
            self.repo, forged_post_sync, archived_rel,
        ))
        git(self.repo, "checkout", branch)
        summary.write_text(summary.read_text() + "\nBlocker: finish retry after sync conflict\n")
        git(self.repo, "add", summary_rel); git(self.repo, "commit", "-m", "record finish blocker")
        blocker_commit = git(self.repo, "rev-parse", "HEAD")
        final_premerge_archived_text = archived.read_text()

        # The exact published refresh is merged with one bounded archive-path
        # resolution, followed by the authorized source/test correction.
        git(self.repo, "checkout", "main")
        active_text = packets.read_text() + (
            "\n## Planning Refresh: Exact archive-transition recovery (2026-10-21)\n"
            "- Authorized scope: `same claimed workstream`\n\n"
            "## Handoff\n- Next: `finish safely`\n"
        )
        packets.write_text(active_text)
        git(self.repo, "add", active_rel); git(self.repo, "commit", "-m", "authorize recovery refresh")
        final_main = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "checkout", branch)
        merge = subprocess.run(["git", "merge", "--no-commit", "--no-ff", "main"],
                               cwd=self.repo, text=True, capture_output=True)
        self.assertNotEqual(merge.returncode, 0)
        packets.unlink(missing_ok=True)
        refresh_block = (
            "## Planning Refresh: Exact archive-transition recovery (2026-10-21)\n"
            "- Authorized scope: `same claimed workstream`"
        )
        prefix, suffix = final_premerge_archived_text.split("## Next Handoff", 1)
        archived.write_text(prefix.rstrip() + "\n\n" + refresh_block +
                            "\n\n## Next Handoff" + suffix)
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "sync latest main")
        final_merge = git(self.repo, "rev-parse", "HEAD")
        correction_paths = (
            "custodian/tools/agent/workstream.py",
            "custodian/tools/agent/test_workstream.py",
        )
        for index in range(3):
            paths = correction_paths if index == 2 else (correction_paths[index],)
            for rel in paths:
                path = self.repo / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(f"authorized correction {index}\n")
            git(self.repo, "add", *paths)
            git(self.repo, "commit", "-m", f"correct archive transition gate {index}")
        final_head = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "fetch", "origin")
        git(self.repo, "checkout", "main")
        worktree = self.base / "recovery-worktree"
        git(self.repo, "worktree", "add", str(worktree), branch)

        run_id = workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["run_id"]
        trace_repo = self.base / "trace-repo"
        git(self.base, "clone", str(self.remote), str(trace_repo))
        git(trace_repo, "checkout", "main")
        events = [
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": active_rel, "run_id": run_id, "event": "remote_claim_acquired",
             "data": {"remote_ref": f"refs/heads/dispatch-claims/{workstream_id}",
                      "claim_oid": claim_base, "main_sha": claim_base}},
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": active_rel, "run_id": run_id, "event": "worktree_published",
             "data": {"branch": branch, "clean": True, "head": claim_base,
                      "upstream": claim_base, "worktree": str(worktree)}},
            {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
             "packet": active_rel, "run_id": run_id, "event": "validation_report",
             "data": {"passed": True}},
        ]
        for event in events:
            event["schema_version"] = 1
            event["timestamp_utc"] = "2026-10-21T00:00:00+00:00"
        (trace_repo / "trace.jsonl").write_text("".join(json.dumps(event) + "\n" for event in events))
        git(trace_repo, "add", "trace.jsonl"); git(trace_repo, "commit", "-m", "publish trace")
        git(trace_repo, "push", "origin", f"HEAD:refs/heads/agent-diagnostics/{workstream_id}/{run_id}")
        trace_anchor = git(trace_repo, "rev-parse", "HEAD")
        initial_trace = (trace_repo / "trace.jsonl").read_text()
        git(worktree, "fetch", "origin")
        self.assertEqual(git(worktree, "rev-parse", "HEAD"), final_head)
        self.assertEqual(git(self.repo, "rev-parse", f"{final_merge}^2"), final_main)
        config = dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY)
        config.update({
            "archive": archive_commit,
            "summary_repair": provenance_commit,
            "first_sync": first_merge,
            "post_sync_evidence": post_sync,
            "blocker_note": blocker_commit,
            "final_sync": final_merge,
            "claim_base": claim_base,
            "claim_oid": claim_base,
            "trace_anchor": trace_anchor,
            "first_main": first_main,
            "final_main": final_main,
            "correction_commits": [],
        })
        # A fourth source/test follow-up is outside this recovery's bounded
        # correction chain even though it touches only authorized paths.
        git(worktree, "checkout", "-b", "adversarial-fourth-correction")
        for rel in correction_paths:
            path = worktree / rel
            path.write_text("excess correction\n")
        git(worktree, "add", *correction_paths)
        git(worktree, "commit", "-m", "add fourth correction")
        with mock.patch.dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY, config):
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))
        git(worktree, "checkout", branch)
        with mock.patch.dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY, config):
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, worktree))
            preflight = workstream.closeout_preflight(workstream_id, worktree)
            self.assertEqual(preflight["archive_transition"]["status"], "pass", preflight)

            # The original trace stopped before finish could emit main_sync.
            # A later truthful no-op witness is also accepted when present.
            no_op = {"schema": "custodian.workflow_trace_event.v1", "workstream": workstream_id,
                     "packet": active_rel, "run_id": run_id, "event": "main_sync",
                     "data": {"changed": False, "head": final_head, "main_sha": final_main}}
            (trace_repo / "trace.jsonl").write_text(
                (trace_repo / "trace.jsonl").read_text() + json.dumps(no_op) + "\n"
            )
            git(trace_repo, "add", "trace.jsonl"); git(trace_repo, "commit", "-m", "record truthful no-op sync")
            git(trace_repo, "push", "origin", f"HEAD:refs/heads/agent-diagnostics/{workstream_id}/{run_id}")
            git(worktree, "fetch", "origin")
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # A second claim record in the immutable trace is ambiguous and
            # cannot authenticate the pinned recovery.
            diag_ref = f"refs/heads/agent-diagnostics/{workstream_id}/{run_id}"
            git(trace_repo, "fetch", "origin", f"{diag_ref}:refs/heads/diag")
            git(trace_repo, "checkout", "diag")
            trace_file = trace_repo / "trace.jsonl"
            original_trace = trace_file.read_text()
            duplicate_claim = json.loads(original_trace.splitlines()[0])
            trace_file.write_text(original_trace + json.dumps(duplicate_claim) + "\n")
            git(trace_repo, "add", "trace.jsonl"); git(trace_repo, "commit", "-m", "tamper duplicate claim")
            git(trace_repo, "push", "origin", f"HEAD:{diag_ref}")
            git(worktree, "fetch", "origin")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # A false changed=true witness cannot be inferred from the merge
            # history; the immutable run must report the actual no-op.
            trace_file.write_text(original_trace)
            trace_events = [json.loads(line) for line in original_trace.splitlines()]
            trace_events[-1]["data"]["changed"] = True
            trace_file.write_text("".join(json.dumps(event) + "\n" for event in trace_events))
            git(trace_repo, "add", "trace.jsonl"); git(trace_repo, "commit", "-m", "forge changed sync")
            git(trace_repo, "push", "origin", f"HEAD:{diag_ref}")
            git(worktree, "fetch", "origin")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # Restore an authentic descendant trace. A changed pinned main SHA
            # or a reversed merge-parent expectation must also fail closed.
            trace_file.write_text(original_trace)
            git(trace_repo, "add", "trace.jsonl"); git(trace_repo, "commit", "-m", "restore pinned trace")
            git(trace_repo, "push", "origin", f"HEAD:{diag_ref}")
            git(worktree, "fetch", "origin")
            wrong_pin = dict(config)
            wrong_pin["final_main"] = first_main
            with mock.patch.dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY, wrong_pin):
                self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))
            wrong_claim = dict(config)
            wrong_claim["claim_oid"] = "1" * 40
            with mock.patch.dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY, wrong_claim):
                self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # A direct post-sync correction with an undeclared path cannot use
            # the two allowed source/test files to authorize unrelated edits.
            git(worktree, "checkout", "-b", "adversarial-extra-path", final_merge)
            for rel in ("custodian/tools/agent/workstream.py",
                        "custodian/tools/agent/test_workstream.py", "outside.py"):
                path = worktree / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("unauthorized correction\n")
            git(worktree, "add", "custodian/tools/agent/workstream.py",
                "custodian/tools/agent/test_workstream.py", "outside.py")
            git(worktree, "commit", "-m", "add undeclared correction path")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # An executable mode is also outside the exact regular-file contract.
            git(worktree, "checkout", "-b", "adversarial-file-mode", final_merge)
            for rel in ("custodian/tools/agent/workstream.py",
                        "custodian/tools/agent/test_workstream.py"):
                path = worktree / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("authorized paths, wrong mode\n")
            git(worktree, "add", "custodian/tools/agent/workstream.py",
                "custodian/tools/agent/test_workstream.py")
            git(worktree, "update-index", "--chmod=+x", "custodian/tools/agent/workstream.py")
            git(worktree, "commit", "-m", "change correction file mode")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))

            # Finally reject an unrelated descendant even with the authentic
            # correction already present on its first parent.
            git(worktree, "checkout", "--force", branch)
            git(worktree, "checkout", "-b", "adversarial-followup")
            (worktree / "outside.py").write_text("unrelated\n")
            git(worktree, "add", "outside.py"); git(worktree, "commit", "-m", "unrelated followup")
            self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, worktree))
            git(worktree, "checkout", branch)

            # The recovered branch remains verifiable after an unrelated
            # latest-main advance. Restore the original trace with no inferred
            # sync event, then require the normal finish path to validate its
            # genuine post-advance merge.
            trace_file.write_text(initial_trace)
            git(trace_repo, "add", "trace.jsonl")
            git(trace_repo, "commit", "-m", "restore original pre-finish trace")
            git(trace_repo, "push", "origin", f"HEAD:{diag_ref}")
            git(worktree, "fetch", "origin")
            git(self.repo, "checkout", "main")
            advance_paths = [
                "custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/ASSEMBLY_GALLERY_SPEC_V1.md",
                "custodian/docs/ai_context/task_packets/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
                "custodian/docs/ai_context/task_packets/REVIEW_CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md",
                "design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md",
            ]
            advance_commits = []
            for index, relative in enumerate(advance_paths):
                path = self.repo / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(f"bounded documentation advance {index}\n")
                git(self.repo, "add", relative)
                git(self.repo, "commit", "-m", f"bounded unrelated main documentation {index}")
                advance_commits.append(git(self.repo, "rev-parse", "HEAD"))
            git(self.repo, "push", "origin", "main")
            latest_main = git(self.repo, "rev-parse", "HEAD")
            workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["authorized_main_advance"] = {
                "base": final_main,
                "head": latest_main,
                "commits": advance_commits,
                "commit_paths": [[relative] for relative in advance_paths],
            }
            run_id = workstream.FAILED_IMPORT_ARCHIVE_RECOVERY["run_id"]
            active_trace = workstream.RunTrace(
                self.repo, workstream_id, run_id, packet=active_rel,
            )
            active_trace.path.parent.mkdir(parents=True, exist_ok=True)
            active_trace.path.write_text(initial_trace)
            active_trace.active_path.parent.mkdir(parents=True, exist_ok=True)
            active_trace.active_path.write_text(json.dumps({
                "run_id": run_id,
                "workstream": workstream_id,
                "trace_path": str(active_trace.path),
                "diagnostic_ref": active_trace.diagnostic_ref,
            }) + "\n")
            git(worktree, "fetch", "origin")
            self.assertEqual(git(worktree, "rev-parse", "origin/main"), latest_main)
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, worktree))
            preflight = workstream.closeout_preflight(workstream_id, worktree)
            self.assertEqual(preflight["archive_transition"]["status"], "pass")
            with self.assertRaisesRegex(workstream.WorkstreamError, "provide a green --validation-report-after-sync"):
                workstream.finish(
                    workstream_id, self._green_report("validation-before-sync.json"), repo=self.repo,
                )
            self.assertEqual(git(worktree, "rev-parse", "HEAD^2"), latest_main)
            git(self.repo, "fetch", "origin")
            trace_ref = (
                f"refs/remotes/origin/agent-diagnostics/{workstream_id}/"
                f"{workstream.FAILED_IMPORT_ARCHIVE_RECOVERY['run_id']}"
            )
            trace_remote_ref = trace_ref.replace("refs/remotes/origin/", "refs/heads/")
            git(self.repo, "fetch", "origin", f"{trace_remote_ref}:{trace_ref}")
            synced_events = [json.loads(line) for line in git(
                self.repo, "show", f"{trace_ref}:trace.jsonl",
            ).splitlines() if line.strip()]
            sync_witnesses = [event["data"] for event in synced_events
                              if event.get("event") == "main_sync"]
            self.assertEqual(sync_witnesses, [{
                "changed": True, "head": git(worktree, "rev-parse", "HEAD"),
                "main_sha": latest_main,
            }])
            self.assertTrue(workstream._failed_import_recovery_trace_is_authentic(
                synced_events, workstream_id,
                workstream.FAILED_IMPORT_ARCHIVE_RECOVERY,
                active_rel, branch, str(worktree), git(worktree, "rev-parse", "HEAD"),
                git(worktree, "rev-parse", "origin/main"), trace_ref,
                git(worktree, "rev-parse", trace_ref),
            ), active_trace.path.read_text())
            for rel in ("custodian/tools/agent/workstream.py",
                        "custodian/tools/agent/test_workstream.py"):
                with (worktree / rel).open("a", encoding="utf-8") as stream:
                    stream.write("\n# bounded post-sync correction\n")
            git(worktree, "add", "custodian/tools/agent/workstream.py",
                "custodian/tools/agent/test_workstream.py")
            git(worktree, "commit", "-m", "record bounded post-sync correction")
            self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, worktree))
            retry_head = git(worktree, "rev-parse", "HEAD")
            preflight = workstream.closeout_preflight(workstream_id, worktree)
            self.assertEqual(preflight["archive_transition"]["status"], "pass", preflight)
            workstream.finish(
                workstream_id,
                self._green_report("validation-after-sync.json"),
                repo=self.repo,
            )
            git(self.repo, "fetch", "origin")
            git(self.repo, "fetch", "origin", f"{trace_remote_ref}:{trace_ref}")
            final_events = [json.loads(line) for line in git(
                self.repo, "show", f"{trace_ref}:trace.jsonl",
            ).splitlines() if line.strip()]
            sync_witnesses = [event["data"] for event in final_events
                              if event.get("event") == "main_sync"]
            self.assertEqual([event["changed"] for event in sync_witnesses], [True, False])
            self.assertEqual(sync_witnesses[1]["head"], retry_head)
            self.assertEqual(
                git(self.repo, "merge-base", "--is-ancestor",
                    sync_witnesses[0]["head"], sync_witnesses[1]["head"]),
                "",
            )
            self.assertEqual(sync_witnesses[1]["main_sha"], latest_main)
            self.assertTrue(any(event.get("event") == "finish_completed"
                                and event.get("data", {}).get("outcome") == "finished"
                                for event in final_events))
            self.assertTrue(any(event.get("event") == "validation_report"
                                and event.get("data", {}).get("path") == "validation-after-sync.json"
                                and event.get("data", {}).get("passed") is True
                                for event in final_events))
            self.assertFalse(worktree.exists())

    def test_historical_failed_import_first_sync_conflict_reconciliation_is_exact(self):
        repository = Path(__file__).resolve().parents[3]
        pinned = dict(workstream.FAILED_IMPORT_ARCHIVE_RECOVERY)
        archived_rel = (
            "custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"
        )
        self.assertTrue(workstream._failed_import_first_sync_is_bounded(
            repository, pinned, archived_rel,
        ))
        active_rel = (
            "custodian/docs/ai_context/task_packets/"
            "AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md"
        )
        self.assertTrue(workstream._reconciled_archive_packet_matches(
            repository, pinned["final_sync"], archived_rel, active_rel,
        ))

        # The reconciliation is bound to the exact recorded regression-test
        # output. A different source blob cannot inherit this merge authority.
        forged = dict(pinned)
        forged["first_sync_test_runner_blob"] = "0" * 40
        self.assertFalse(workstream._failed_import_first_sync_is_bounded(
            repository, forged, archived_rel,
        ))

    def test_archive_guard_recovers_resolved_current_main_sync_without_erasing_conflict_evidence(self):
        workstream_id = "agent-test-resolved-main-sync"
        active = self.repo / "custodian/docs/ai_context/task_packets/AGENT_TEST_RESOLVED_MAIN_SYNC.md"
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_RESOLVED_MAIN_SYNC.md"
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            "# Test\n- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n- Status: `in_progress`\n"
            "- Work surface: `source.py`; `test_source.py`\n"
        )
        git(self.repo, "add", str(active.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish active packet")
        git(self.repo, "push", "origin", "main")
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        (self.repo / "source.py").write_text("source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "implement source")
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("in_progress", "complete"))
        active.unlink()
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", "archive packet")

        git(self.repo, "checkout", "main")
        (self.repo / "main-only").write_text("new main\n")
        git(self.repo, "add", "main-only")
        git(self.repo, "commit", "-m", "advance main")
        git(self.repo, "push", "origin", "main")
        main_sha = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", branch)
        git(self.repo, "merge", "--no-ff", "main", "-m", "resolved sync merge")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^2"), main_sha)

        (self.repo / "source.py").write_text("source with in-surface follow-up\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "bounded follow-up")
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

        (self.repo / "outside.py").write_text("out of scope\n")
        git(self.repo, "add", "outside.py")
        git(self.repo, "commit", "-m", "unbound follow-up")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def _managed_index_conflict_history(self, mode: str = "success") -> tuple[str, str]:
        workstream_id = "agent-test-resolved-main-sync"
        filename = "AGENT_TEST_RESOLVED_MAIN_SYNC.md"
        packet_rel = f"custodian/docs/ai_context/task_packets/{filename}"
        archived_rel = f"custodian/docs/ai_context/task_packets/archived/{filename}"
        active = self.repo / packet_rel
        active.parent.mkdir(parents=True, exist_ok=True)
        active.write_text(
            "# Test archive conflict\n\n"
            f"- Workstream: `{workstream_id}`\n- Status: `ready`\n"
            "- Dispatch: `auto`\n- Priority: `P0`\n- Depends on: `none`\n"
            "- Locks: `none`\n- Kind: `implementation`\n- Review: `none`\n"
            "- Goal: Preserve this generated row while the archive transition is merged.\n"
            "- Work surface: source.py; test_source.py\n"
        )
        extra_rel = "custodian/docs/ai_context/task_packets/ZZ_EXTRA_READY.md"
        extra = self.repo / extra_rel
        extra.write_text(
            "# Extra ready packet\n\n"
            "- Workstream: `agent-test-extra-ready`\n- Status: `ready`\n"
            "- Dispatch: `auto`\n- Priority: `P0`\n- Depends on: `none`\n"
            "- Locks: `none`\n- Kind: `implementation`\n- Review: `none`\n"
            "- Goal: Keep a neighboring generated index entry.\n"
        )
        readme_rel = "custodian/docs/ai_context/task_packets/README.md"
        readme = self.repo / readme_rel
        readme.write_text(
            "### Ready / Auto Dispatch\n\n"
            "<!-- task_packet_index:managed:start -->\n_None._\n"
            "<!-- task_packet_index:managed:end -->\n"
        )
        (self.repo / "source.py").write_text("base source\n")
        (self.repo / "test_source.py").write_text("base test\n")
        if mode == "extra-conflict":
            (self.repo / "outside.py").write_text("base outside\n")
        git(self.repo, "add", packet_rel, extra_rel, readme_rel, "source.py", "test_source.py")
        if mode == "extra-conflict":
            git(self.repo, "add", "outside.py")
        self.assertTrue(task_packet_index.write(self.repo))
        git(self.repo, "add", readme_rel)
        git(self.repo, "commit", "-m", "publish active test packet")
        git(self.repo, "push", "origin", "main")
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        (self.repo / "source.py").write_text("implemented source\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "complete scoped source work")
        archived = self.repo / archived_rel
        archived.parent.mkdir(parents=True, exist_ok=True)
        archived.write_text(active.read_text().replace("Status: `ready`", "Status: `blocked`"))
        summary_rel = "AGENT_TEST_RESOLVED_MAIN_SYNC_CLAUDE_SUMMARY.md"
        (self.repo / summary_rel).write_text("completed\nAuthoring chat: not-recorded\n")
        active.unlink()
        task_packet_index.write(self.repo)
        git(self.repo, "add", archived_rel, packet_rel, readme_rel, summary_rel)
        git(self.repo, "commit", "-m", "archive the bounded task")
        archive_commit = git(self.repo, "rev-parse", "HEAD")

        git(self.repo, "checkout", "main")
        row = next(line for line in readme.read_text().splitlines()
                   if line.startswith(f"- `{filename}` — "))
        readme.write_text(readme.read_text().replace(row, row + " updated on main"))
        if mode == "extra-conflict":
            (self.repo / "outside.py").write_text("main outside\n")
            git(self.repo, "add", "outside.py")
        git(self.repo, "add", readme_rel)
        git(self.repo, "commit", "-m", "refresh generated row on main")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        main_sha = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "checkout", branch)
        merge = subprocess.run(
            ["git", "merge", "--no-ff", "origin/main", "-m", "interrupted sync merge"],
            cwd=self.repo, text=True, capture_output=True,
        )
        self.assertNotEqual(merge.returncode, 0, merge.stdout + merge.stderr)
        conflicted = subprocess.run(["git", "status", "--porcelain"], cwd=self.repo,
                                    text=True, capture_output=True, check=True).stdout
        expected_conflicts = {"custodian/docs/ai_context/task_packets/README.md"}
        if mode == "extra-conflict":
            expected_conflicts.add("outside.py")
        self.assertEqual({line[3:] for line in conflicted.splitlines()}, expected_conflicts)
        git(self.repo, "add", *sorted(expected_conflicts))
        if mode == "altered-merge-tree":
            (self.repo / "unauthorized.txt").write_text("forged merge content\n")
            git(self.repo, "add", "unauthorized.txt")
        git(self.repo, "commit", "-m", "record interrupted merge")
        merge_commit = git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^1"), archive_commit)
        self.assertEqual(git(self.repo, "rev-parse", "HEAD^2"), main_sha)
        return workstream_id, merge_commit

    def test_archive_guard_authenticates_managed_index_conflict_repair_and_bare_paths(self):
        workstream_id, merge_commit = self._managed_index_conflict_history()
        readme = self.repo / "custodian/docs/ai_context/task_packets/README.md"
        self.assertTrue(readme.read_text().count("<<<<<<< HEAD") == 1)
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))
        self.assertEqual(
            workstream._work_surface_paths(
                "- Work surface: source.py; prose mentions outside.py; "
                "`custodian/docs/AGENTS.md`; ../outside.py; /tmp/secret.py; test_source.py"
            ),
            {"source.py", "custodian/docs/AGENTS.md", "test_source.py"},
        )
        self.assertEqual(
            workstream._work_surface_paths(
                "- Work surface: custodian/AGENTS.md; "
                "custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md; "
                "custodian/docs/ai_context/CONTEXT.md; "
                "custodian/docs/ai_context/task_packets/README.md policy prose "
                "(do not hand-edit its managed index); directly stale governance text only."
            ),
            {
                "custodian/AGENTS.md",
                "custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md",
                "custodian/docs/ai_context/CONTEXT.md",
                "custodian/docs/ai_context/task_packets/README.md",
            },
        )

        self.assertTrue(task_packet_index.write(self.repo))
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        repair = git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(git(self.repo, "rev-parse", f"{repair}^1"), merge_commit)
        (self.repo / "source.py").write_text("bounded in-surface follow-up\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "record scoped follow-up")
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_RESOLVED_MAIN_SYNC.md"
        archived.write_text(archived.read_text().replace("Status: `blocked`", "Status: `complete`"))
        git(self.repo, "add", str(archived.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "record bounded closeout evidence")
        self.assertTrue(task_packet_index.check(self.repo)[0])
        self.assertIsNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_unrepaired_managed_index_conflict(self):
        workstream_id, _ = self._managed_index_conflict_history()
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_delayed_managed_index_repair(self):
        workstream_id, _ = self._managed_index_conflict_history()
        (self.repo / "source.py").write_text("post-conflict commit before repair\n")
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "delay the managed index repair")
        task_packet_index.write(self.repo)
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair after an intervening commit")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_repair_that_changes_content_outside_managed_index(self):
        workstream_id, _ = self._managed_index_conflict_history()
        readme = self.repo / "custodian/docs/ai_context/task_packets/README.md"
        task_packet_index.write(self.repo)
        readme.write_text(readme.read_text().replace("### Ready / Auto Dispatch", "### altered heading"))
        git(self.repo, "add", str(readme.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "alter content around repair")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_additional_conflict_path(self):
        workstream_id, _ = self._managed_index_conflict_history("extra-conflict")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_altered_merge_tree(self):
        workstream_id, _ = self._managed_index_conflict_history("altered-merge-tree")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_unauthorized_post_archive_file(self):
        workstream_id, _ = self._managed_index_conflict_history()
        task_packet_index.write(self.repo)
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        (self.repo / "unrelated.py").write_text("outside declared scope\n")
        git(self.repo, "add", "unrelated.py")
        git(self.repo, "commit", "-m", "add unauthorized post archive file")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_pins_work_surface_to_archive_transition(self):
        workstream_id, _ = self._managed_index_conflict_history()
        task_packet_index.write(self.repo)
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        archived = self.repo / "custodian/docs/ai_context/task_packets/archived/AGENT_TEST_RESOLVED_MAIN_SYNC.md"
        archived.write_text(archived.read_text().replace(
            "source.py; test_source.py", "source.py; test_source.py; unrelated.py"
        ))
        git(self.repo, "add", str(archived.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "attempt to widen archived work surface")
        (self.repo / "unrelated.py").write_text("scope expansion must not authorize this\n")
        git(self.repo, "add", "unrelated.py")
        git(self.repo, "commit", "-m", "change newly declared path")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_executable_work_surface_followup(self):
        workstream_id, _ = self._managed_index_conflict_history()
        task_packet_index.write(self.repo)
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        source = self.repo / "source.py"
        source.write_text("unexpected executable follow-up\n")
        source.chmod(0o755)
        git(self.repo, "add", "source.py")
        git(self.repo, "commit", "-m", "make scoped file executable")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_symlink_work_surface_followup(self):
        workstream_id, _ = self._managed_index_conflict_history()
        task_packet_index.write(self.repo)
        git(self.repo, "add", "custodian/docs/ai_context/task_packets/README.md")
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        target = self.repo / "test_source.py"
        target.unlink()
        target.symlink_to("source.py")
        git(self.repo, "add", "test_source.py")
        git(self.repo, "commit", "-m", "replace scoped file with symlink")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_stale_final_managed_index(self):
        workstream_id, _ = self._managed_index_conflict_history()
        task_packet_index.write(self.repo)
        readme = self.repo / "custodian/docs/ai_context/task_packets/README.md"
        git(self.repo, "add", str(readme.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "repair exact managed index conflict")
        readme.write_text(readme.read_text().replace(
            "<!-- task_packet_index:managed:end -->",
            "- `STALE.md` — stale generated entry\n<!-- task_packet_index:managed:end -->",
        ))
        git(self.repo, "add", str(readme.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "leave stale managed index after repair")
        self.assertIsNotNone(workstream._archive_transition_tip_error(workstream_id, self.repo))

    def test_archive_guard_rejects_missing_duplicate_or_reversed_index_markers(self):
        valid = (
            b"<!-- task_packet_index:managed:start -->\n_None._\n"
            b"<!-- task_packet_index:managed:end -->\n"
        )
        malformed = (
            valid.replace(b"<!-- task_packet_index:managed:start -->\n",
                          b"<!-- task_packet_index:managed:start -->\n"
                          b"<!-- task_packet_index:managed:start -->\n"),
            valid.replace(b"<!-- task_packet_index:managed:end -->\n", b""),
            b"<!-- task_packet_index:managed:end -->\n_None._\n"
            b"<!-- task_packet_index:managed:start -->\n",
        )
        for readme in malformed:
            with self.subTest(readme=readme):
                self.assertIsNone(workstream._managed_index_split(readme))

    def test_archive_guard_rejects_forged_conflict_merge_parent(self):
        workstream_id, merge_commit = self._managed_index_conflict_history()
        archive = git(self.repo, "rev-parse", f"{merge_commit}^1")
        wrong_main = git(self.repo, "rev-parse", f"{merge_commit}^2^1")
        tree = git(self.repo, "rev-parse", f"{merge_commit}^{{tree}}")
        forged = subprocess.run(
            ["git", "commit-tree", tree, "-p", archive, "-p", wrong_main],
            cwd=self.repo, input="forged merge ancestry\n", text=True, capture_output=True, check=True,
        ).stdout.strip()
        git(self.repo, "checkout", "--detach", forged)
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
        packet = self.repo / "custodian/docs/ai_context/task_packets/SAMPLE_WORK.md"
        packet.parent.mkdir(parents=True, exist_ok=True)
        packet.write_text("- Workstream: `sample-work`\n")
        git(self.repo, "add", str(packet.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "add sample packet")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        path = workstream.start("sample-work", self.repo)
        self.assertEqual(git(path, "branch", "--show-current"), "agent/sample-work")
        self.assertNotEqual(path, self.repo)
        self.assertFalse(path.is_relative_to(self.repo))
        self.assertEqual(git(path, "rev-parse", "HEAD"), git(self.repo, "rev-parse", "origin/main"))
        self.assertEqual(git(path, "rev-parse", "@{upstream}"), git(self.repo, "rev-parse", "origin/agent/sample-work"))
        trace = next((Path(self.repo / ".git/custodian-workflow/traces/sample-work").glob("*.jsonl")))
        first_event = json.loads(trace.read_text().splitlines()[0])
        self.assertEqual(first_event["execution_generation"], "execution-reset-v1-20261020")
        self.assertEqual(
            first_event["packet"],
            "custodian/docs/ai_context/task_packets/SAMPLE_WORK.md",
        )

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
        report: dict[str, object] = {}
        path = workstream.start("disposition-work", self.repo, report=report)
        self.assertEqual(report["checkout"], "created")
        self.assertNotIn("checkout_profile", report)
        resumed_report: dict[str, object] = {}
        resumed = workstream.resume("disposition-work", self.repo, report=resumed_report)
        self.assertEqual(resumed_report["checkout"], "resumed")
        self.assertEqual(resumed, path)

    def test_start_report_keeps_profile_receipt_separate_from_checkout_disposition(self):
        profile_path = "profile.json"
        (self.repo / profile_path).write_text(json.dumps({
            "schema": workstream.worktree_provisioning.PROFILE_SCHEMA,
            "include_paths": ["base"], "hydrate_lfs_paths": [],
        }) + "\n")
        git(self.repo, "add", profile_path)
        git(self.repo, "commit", "-m", "publish fixture checkout profile")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        report: dict[str, object] = {}
        path = workstream.start("profile-report", self.repo, report=report, profile_path=profile_path)
        evidence = report["checkout_profile"]
        self.assertEqual(report["checkout"], "created")
        self.assertIsInstance(evidence, dict)
        self.assertEqual(evidence["profile"], profile_path)
        self.assertEqual(evidence["paths"], ["base"])
        self.assertEqual(evidence["hydrated_lfs_paths"], [])
        self.assertTrue((path / "base").is_file())

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

    def _green_source_report(self, path: Path, name: str = "after-sync.json", *,
                             identity: dict[str, str] | None = None) -> Path:
        report = self.base / name
        report.write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": True,
            "coverage": {"complete": True, "uncovered_files": []},
            "selected": ["fixture"],
            "tests": [{"id": "fixture", "status": "passed"}],
            "summary": {"selected": 1, "passed": 1, "failed": 0,
                        "timed_out": 0, "skipped": 0, "infrastructure_errors": 0},
            "source_identity": identity or workstream._git_source_identity(path),
            "source_changed_during_validation": False,
        }))
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
        packet = self.repo / "custodian/docs/ai_context/task_packets/NEEDS_SYNC.md"
        packet.parent.mkdir(parents=True, exist_ok=True)
        packet.write_text("- Workstream: `needs-sync`\n- Status: `in_progress`\n")
        git(self.repo, "add", str(packet.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish needs-sync packet")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        path = workstream.start("needs-sync", self.repo)
        self._commit_task_work(path, "needs-sync")
        (self.repo / "main-advance").write_text("advance\n")
        git(self.repo, "add", "main-advance")
        git(self.repo, "commit", "-m", "main advances")
        git(self.repo, "push", "origin", "main")
        trace = workstream.RunTrace.resume(self.repo, "needs-sync")
        with mock.patch.object(workstream, "artifact_preflight", return_value=[]):
            with self.assertRaisesRegex(workstream.WorkstreamError, "after-sync"):
                workstream.finish("needs-sync", self._green_report(), repo=path)
            self.assertTrue(path.exists())
            workstream.finish(
                "needs-sync", self._green_report("validation-2.json"),
                validation_report_after_sync=self._green_source_report(path, "after-sync.json"), repo=path,
            )
        events = [json.loads(line) for line in trace.path.read_text().splitlines()]
        checkpoint_positions = [i for i, event in enumerate(events)
                                if event["event"] == "checkpoint_completed"]
        changed_sync_positions = [i for i, event in enumerate(events)
                                  if event["event"] == "main_sync"
                                  and event["data"].get("changed") is True]
        self.assertEqual(len(checkpoint_positions), 2)
        self.assertEqual(len(changed_sync_positions), 1)
        self.assertLess(checkpoint_positions[0], changed_sync_positions[0])
        changed_sync = events[changed_sync_positions[0]]["data"]
        first_checkpoint = events[checkpoint_positions[0]]["data"]
        self.assertEqual(first_checkpoint["branch"], "agent/needs-sync")
        self.assertIs(first_checkpoint["removed"], False)
        self.assertEqual(
            first_checkpoint["remote_head"],
            git(self.repo, "rev-parse", f"{changed_sync['head']}^1"),
        )
        final_noop_positions = [i for i, event in enumerate(events)
                                if event["event"] == "main_sync"
                                and event["data"].get("changed") is False]
        self.assertEqual(len(final_noop_positions), 1)
        self.assertGreater(final_noop_positions[0], changed_sync_positions[0])
        self.assertFalse(path.exists())

    def test_finish_retry_rejects_false_after_sync_report_before_republication(self):
        packet = self.repo / "custodian/docs/ai_context/task_packets/NEEDS_SYNC_RETRY.md"
        packet.parent.mkdir(parents=True, exist_ok=True)
        packet.write_text("- Workstream: `needs-sync-retry`\n- Status: `in_progress`\n")
        git(self.repo, "add", str(packet.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "publish needs-sync-retry packet")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        path = workstream.start("needs-sync-retry", self.repo)
        self._commit_task_work(path, "needs-sync-retry")

        (self.repo / "main-advance-retry").write_text("advance\n")
        git(self.repo, "add", "main-advance-retry")
        git(self.repo, "commit", "-m", "main advances during retry regression")
        git(self.repo, "push", "origin", "main")

        trace = workstream.RunTrace.resume(self.repo, "needs-sync-retry")
        with mock.patch.object(workstream, "artifact_preflight", return_value=[]):
            with self.assertRaisesRegex(workstream.WorkstreamError, "after-sync"):
                workstream.finish("needs-sync-retry", self._green_report(), repo=path)
            self.assertTrue(path.exists())
            branch = "agent/needs-sync-retry"
            published_before_retry = git(
                self.repo, "ls-remote", "--heads", "origin", branch,
            ).split()[0]
            synchronized_head = git(path, "rev-parse", "HEAD")
            false_report = self._red_report("false-after-sync.json")

            with self.assertRaisesRegex(workstream.WorkstreamError, "after-sync"):
                workstream.finish(
                    "needs-sync-retry", self._green_report("validation-retry.json"),
                    validation_report_after_sync=false_report, repo=path,
                )

            self.assertTrue(path.exists())
            self.assertEqual(git(path, "rev-parse", "HEAD"), synchronized_head)
            self.assertEqual(
                git(self.repo, "ls-remote", "--heads", "origin", branch).split()[0],
                published_before_retry,
            )
            self.assertFalse(workstream.task_head_reachable_from_main(path))

            stale_report = self._green_source_report(
                path, "stale-after-sync.json", identity=workstream._git_source_identity(self.repo),
            )
            with self.assertRaisesRegex(workstream.WorkstreamError, "exact synchronized source"):
                workstream.finish(
                    "needs-sync-retry", self._green_report("validation-stale-retry.json"),
                    validation_report_after_sync=stale_report, repo=path,
                )
            self.assertEqual(
                git(self.repo, "ls-remote", "--heads", "origin", branch).split()[0],
                published_before_retry,
            )

            malformed_report = self._green_source_report(path, "malformed-after-sync.json")
            malformed_payload = json.loads(malformed_report.read_text())
            malformed_payload["summary"]["passed"] = 0
            malformed_report.write_text(json.dumps(malformed_payload))
            with self.assertRaisesRegex(workstream.WorkstreamError, "green, complete"):
                workstream.finish(
                    "needs-sync-retry", self._green_report("validation-malformed-retry.json"),
                    validation_report_after_sync=malformed_report, repo=path,
                )
            self.assertEqual(
                git(self.repo, "ls-remote", "--heads", "origin", branch).split()[0],
                published_before_retry,
            )

            altered_report = self._green_source_report(path, "altered-after-sync.json")
            (path / "feature").write_text("changed after report creation\n")
            with self.assertRaisesRegex(workstream.WorkstreamError, "source changed after synchronization"):
                workstream._after_sync_report_data(altered_report, path, synchronized_head)
            git(path, "checkout", "--", "feature")

            valid_report = self._green_source_report(path, "valid-after-sync.json")
            with mock.patch.object(
                    workstream, "_checkpoint_impl",
                    side_effect=workstream.WorkstreamError("simulated interruption after witness publication")):
                with self.assertRaisesRegex(workstream.WorkstreamError, "simulated interruption"):
                    workstream.finish(
                        "needs-sync-retry", self._green_report("validation-valid-retry.json"),
                        validation_report_after_sync=valid_report, repo=path,
                    )
            events = [json.loads(line) for line in trace.path.read_text().splitlines() if line.strip()]
            witnesses = [event for event in events if event.get("event") == "validation_after_sync"]
            self.assertEqual(len(witnesses), 1)
            self.assertTrue(git(self.repo, "ls-remote", "origin", trace.diagnostic_ref))
            with mock.patch.object(workstream, "artifact_preflight", return_value=[]):
                workstream.finish(
                    "needs-sync-retry", self._green_report("validation-valid-retry.json"),
                    repo=path,
                )
            events = [json.loads(line) for line in trace.path.read_text().splitlines() if line.strip()]
            witnesses = [event for event in events if event.get("event") == "validation_after_sync"]
            self.assertEqual(len(witnesses), 1)
            witness = witnesses[0]["data"]
            self.assertEqual(witness["source_commit"], synchronized_head)
            self.assertEqual(witness["source_tree"], git(self.repo, "rev-parse", f"{synchronized_head}^{{tree}}"))
            self.assertEqual(witness["sha256"], hashlib.sha256(valid_report.read_bytes()).hexdigest())
            self.assertEqual(witness["source_status_sha256"], workstream._git_source_identity(
                self.repo, synchronized_head,
            )["worktree_status_sha256"])
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
