from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import session_supervisor as supervisor
import workstream_recovery as recovery


def git(cwd: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True, check=True)
    return result.stdout.strip()


class RepoFixture:
    def __init__(self, root: Path):
        self.repo = root / "repo"
        self.remote = root / "origin.git"
        self.worktree = root / "agent-worktree"
        self.workstream = "fixture-supervised-run"
        self.packet = "custodian/docs/ai_context/task_packets/FIXTURE.md"
        self.repo.mkdir()
        git(self.repo, "init", "-b", "main")
        git(self.repo, "config", "user.name", "Fixture")
        git(self.repo, "config", "user.email", "fixture@example.invalid")
        (self.repo / self.packet).parent.mkdir(parents=True)
        (self.repo / self.packet).write_text(
            "# Fixture\n\n- Workstream: `fixture-supervised-run`\n- Status: `ready`\n"
            "- Dispatch: `auto`\n- Locks: `agent-workflow`\n- Kind: `implementation`\n"
        )
        (self.repo / "README.md").write_text("fixture\n")
        git(self.repo, "add", self.packet, "README.md")
        git(self.repo, "commit", "-m", "fixture baseline")
        subprocess.run(["git", "init", "--bare", str(self.remote)], check=True, capture_output=True)
        git(self.repo, "remote", "add", "origin", str(self.remote))
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "worktree", "add", str(self.worktree), "-b", f"agent/{self.workstream}")
        (self.worktree / "README.md").write_text("fixture\nagent-owned change\n")
        git(self.worktree, "add", "README.md")
        git(self.worktree, "commit", "-m", "agent-owned fixture change")
        git(self.worktree, "push", "-u", "origin", f"agent/{self.workstream}")
        common = Path(git(self.repo, "rev-parse", "--git-common-dir"))
        if not common.is_absolute():
            common = (self.repo / common).resolve()
        receipt_path = common / "custodian-dispatch" / "last-claim.json"
        receipt_path.parent.mkdir(parents=True)
        receipt_path.write_text(json.dumps({
            "schema": "custodian.dispatch.claim.v1", "result": "claimed", "verified": True,
            "workstream": self.workstream, "branch": f"agent/{self.workstream}",
            "worktree": str(self.worktree), "packet": self.packet, "run_id": "fixture-dispatch-run",
        }))


class SessionSupervisorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.fixture = RepoFixture(Path(self.temp.name))

    def tearDown(self):
        self.temp.cleanup()

    def journal(self):
        root = supervisor.common_dir(self.fixture.repo) / supervisor.JOURNAL_ROOT / self.fixture.workstream
        paths = list(root.glob("*.jsonl")) if root.exists() else []
        self.assertEqual(len(paths), 1)
        return paths[0]

    def test_supervised_launch_records_private_verified_exit(self):
        result = supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                      [sys.executable, "-c", "import time; time.sleep(.08)"],
                                      heartbeat_seconds=.02)
        self.assertEqual(result, 0)
        path = self.journal()
        events = supervisor.read_journal(path)
        self.assertEqual(events[0]["event"], "LAUNCH_INTENT")
        self.assertEqual(events[1]["event"], "STARTED")
        self.assertEqual(events[-1]["event"], "EXITED_CONFIRMED")
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
        self.assertEqual(events[-1]["claim_receipt_sha256"].__len__(), 64)
        self.assertNotIn("argv", json.dumps(events))
        self.assertNotIn("stdout", json.dumps(events))

    def test_hash_chain_rejects_modified_or_forged_metadata(self):
        supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                              [sys.executable, "-c", "pass"], heartbeat_seconds=.02)
        path = self.journal()
        content = path.read_text()
        path.write_text(content.replace("EXITED_CONFIRMED", "LIVE"))
        with self.assertRaises(supervisor.SupervisorError):
            supervisor.read_journal(path)

    def test_pause_signal_is_intent_and_only_exit_proves_termination(self):
        stop = threading.Event()
        stop.set()
        result = supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                      [sys.executable, "-c", "import time; time.sleep(2)"],
                                      heartbeat_seconds=.02, stop_event=stop)
        self.assertNotEqual(result, 0)
        events = supervisor.read_journal(self.journal())
        self.assertTrue(any(event["event"] == "PAUSE_REQUESTED" for event in events))
        self.assertEqual(events[-1]["event"], "EXITED_CONFIRMED")

    def test_long_idle_live_process_stays_live(self):
        errors: list[BaseException] = []

        def run():
            try:
                supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                     [sys.executable, "-c", "import time; time.sleep(.5)"],
                                     heartbeat_seconds=.03)
            except BaseException as exc:
                errors.append(exc)

        thread = threading.Thread(target=run)
        thread.start()
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            root = supervisor.common_dir(self.fixture.repo) / supervisor.JOURNAL_ROOT / self.fixture.workstream
            paths = list(root.glob("*.jsonl")) if root.exists() else []
            if paths and any(event["event"] == "STARTED" for event in supervisor.read_journal(paths[0])):
                break
            time.sleep(.01)
        rows = [item for item in recovery.audit(self.fixture.repo)["items"]
                if item.get("workstream") == self.fixture.workstream]
        self.assertEqual(rows[0]["classification"], "LIVE")
        thread.join(3)
        self.assertFalse(thread.is_alive())
        self.assertEqual(errors, [])

    def test_surviving_child_keeps_supervisor_lock_until_it_exits(self):
        code = ("import subprocess,sys,time; "
                "subprocess.Popen([sys.executable,'-c','import time; time.sleep(.2)']); "
                "time.sleep(.04)")
        supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                              [sys.executable, "-c", code], heartbeat_seconds=.01)
        events = supervisor.read_journal(self.journal())
        self.assertTrue(any(event["event"] == "PROCESS_EXITED_DESCENDANTS_OR_SCAN_UNKNOWN" for event in events))
        self.assertEqual(events[-1]["event"], "EXITED_CONFIRMED")

    def test_supervisor_sigkill_does_not_hide_a_live_child(self):
        agent_tools = str(Path(__file__).resolve().parent)
        wrapper_code = (
            "import sys; sys.path.insert(0, " + repr(agent_tools) + "); "
            "from pathlib import Path; import session_supervisor as s; "
            "s.supervise(Path(" + repr(str(self.fixture.repo)) + "), " + repr(self.fixture.workstream) + ", "
            "[sys.executable, '-c', 'import time; time.sleep(10)'], heartbeat_seconds=.03)"
        )
        wrapper = subprocess.Popen([sys.executable, "-c", wrapper_code])
        try:
            deadline = time.monotonic() + 3
            path = None
            while time.monotonic() < deadline:
                root = supervisor.common_dir(self.fixture.repo) / supervisor.JOURNAL_ROOT / self.fixture.workstream
                paths = list(root.glob("*.jsonl")) if root.exists() else []
                if paths and any(event["event"] == "STARTED" for event in supervisor.read_journal(paths[0])):
                    path = paths[0]
                    break
                time.sleep(.02)
            self.assertIsNotNone(path)
            events = supervisor.read_journal(path)
            child = events[1]["child"]
            os.kill(wrapper.pid, signal.SIGKILL)
            wrapper.wait(timeout=2)
            live_row = next(item for item in recovery.audit(self.fixture.repo)["items"]
                            if item.get("workstream") == self.fixture.workstream)
            self.assertEqual(live_row["classification"], "LIVE")
            os.killpg(child["pgid"], signal.SIGTERM)
            time.sleep(.15)
            exited_row = next(item for item in recovery.audit(self.fixture.repo)["items"]
                              if item.get("workstream") == self.fixture.workstream)
            self.assertEqual(exited_row["process_classification"], "EXITED_CONFIRMED")
            self.assertEqual(exited_row["classification"], "RECOVERABLE_CLEAN")
        finally:
            if wrapper.poll() is None:
                wrapper.kill()
                wrapper.wait(timeout=2)

    def test_terminal_signal_records_pause_then_confirms_exit(self):
        agent_tools = str(Path(__file__).resolve().parent)
        wrapper_code = (
            "import sys; sys.path.insert(0, " + repr(agent_tools) + "); "
            "from pathlib import Path; import session_supervisor as s; "
            "s.supervise(Path(" + repr(str(self.fixture.repo)) + "), " + repr(self.fixture.workstream) + ", "
            "[sys.executable, '-c', 'import time; time.sleep(10)'], heartbeat_seconds=.03)"
        )
        wrapper = subprocess.Popen([sys.executable, "-c", wrapper_code])
        try:
            deadline = time.monotonic() + 3
            path = None
            while time.monotonic() < deadline:
                root = supervisor.common_dir(self.fixture.repo) / supervisor.JOURNAL_ROOT / self.fixture.workstream
                paths = list(root.glob("*.jsonl")) if root.exists() else []
                if paths and any(event["event"] == "STARTED" for event in supervisor.read_journal(paths[0])):
                    path = paths[0]
                    break
                time.sleep(.02)
            self.assertIsNotNone(path)
            os.kill(wrapper.pid, signal.SIGTERM)
            wrapper.wait(timeout=3)
            events = supervisor.read_journal(path)
            self.assertTrue(any(event["event"] == "PAUSE_REQUESTED" for event in events))
            self.assertEqual(events[-1]["event"], "EXITED_CONFIRMED")
        finally:
            if wrapper.poll() is None:
                wrapper.kill()
                wrapper.wait(timeout=2)

    def test_paired_review_running_phase_matches_exact_codex_process(self):
        common = supervisor.common_dir(self.fixture.repo)
        run_dir = common / "custodian-review-runs" / "review-fixture" / "run-live"
        run_dir.mkdir(parents=True)
        marker = str(run_dir / "last-message.txt")
        metadata = {"schema": "custodian.paired_review_run.v1", "workstream": "review-fixture",
                    "run_id": "run-live", "phase": "codex_running"}
        (run_dir / "metadata.json").write_text(json.dumps(metadata))
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(.3)", marker])
        try:
            row = next(item for item in recovery.audit(self.fixture.repo)["items"]
                       if item.get("workstream") == "review-fixture")
            self.assertEqual(row["classification"], "LIVE")
            self.assertEqual(row["review_outcome"], "unresolved")
        finally:
            child.terminate()
            child.wait(timeout=2)
        blocked = next(item for item in recovery.audit(self.fixture.repo)["items"]
                       if item.get("workstream") == "review-fixture")
        self.assertEqual(blocked["classification"], "REVIEW_FINDINGS_OR_BLOCKED")
        self.assertEqual(blocked["review_outcome"], "unresolved")

    def test_unmanaged_codex_process_is_unknown_not_assigned(self):
        child = subprocess.Popen(["bash", "-c", "exec -a codex sleep 1"])
        try:
            deadline = time.monotonic() + 1
            rows = []
            while time.monotonic() < deadline:
                rows = [item for item in recovery.audit(self.fixture.repo)["items"]
                        if item.get("classification") == "UNMANAGED_UNKNOWN" and item.get("pid") == child.pid]
                if rows:
                    break
                time.sleep(.02)
            self.assertEqual(len(rows), 1)
            self.assertIsNone(rows[0]["workstream"])
            self.assertEqual(rows[0]["evidence"][0]["executable"], "codex")
        finally:
            child.terminate()
            child.wait(timeout=2)

    def test_second_supervisor_for_same_workstream_is_rejected(self):
        errors: list[BaseException] = []
        ready = threading.Event()

        def first():
            try:
                ready.set()
                supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                     [sys.executable, "-c", "import time; time.sleep(.35)"],
                                     heartbeat_seconds=.02)
            except BaseException as exc:
                errors.append(exc)

        thread = threading.Thread(target=first)
        thread.start()
        ready.wait(1)
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            root = supervisor.common_dir(self.fixture.repo) / supervisor.JOURNAL_ROOT / self.fixture.workstream
            if list(root.glob("*.jsonl")):
                break
            time.sleep(.01)
        with self.assertRaisesRegex(supervisor.SupervisorError, "already owns"):
            supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                  [sys.executable, "-c", "pass"], heartbeat_seconds=.02)
        thread.join(3)
        self.assertFalse(thread.is_alive())
        self.assertEqual(errors, [])

    def test_pid_reuse_and_reboot_are_not_misread(self):
        identity = {"pid": 1234, "start_ticks": 10, "ppid": 1, "pgid": 1234, "state": "S"}
        event = {"host": "host", "boot_id": "boot-a", "child": {"pid": 1234},
                 "process_group": 1234, "processes": [{"pid": 1234, "start_ticks": 10}]}
        with mock.patch.object(recovery, "process_snapshot", return_value=([dict(identity, start_ticks=11)], True)):
            live, complete = recovery._exact_live_identities(event, "host", "boot-a")
        self.assertEqual(live, [])
        self.assertFalse(complete)
        live, complete = recovery._exact_live_identities(event, "host", "boot-b")
        self.assertEqual(live, [])
        self.assertTrue(complete)
        live, complete = recovery._exact_live_identities(event, "another-host", "boot-a")
        self.assertEqual(live, [])
        self.assertFalse(complete)

    def test_unmanaged_clean_claim_missing_journal_allows_resume_advice_only(self):
        # The old session has no OR1 journal. That is not a second gate on
        # the original clean workstream's supported resume entrypoint.
        result = recovery.audit(self.fixture.repo)
        row = next(item for item in result["items"]
                   if item.get("workstream") == self.fixture.workstream)
        self.assertEqual(row["classification"], "UNMANAGED_UNKNOWN")
        self.assertFalse(row["dirty"])
        self.assertIn("workstream.py resume fixture-supervised-run",
                      row["recommended_action"])
        self.assertIn("project-owner authorization", row["recommended_action"])

        # A possible live unmanaged Codex writer cannot be silently adopted.
        observed_writer = {"workstream": None, "classification": "UNMANAGED_UNKNOWN",
                           "candidate_workstream": self.fixture.workstream}
        with mock.patch.object(recovery, "_unmanaged_codex_processes",
                               return_value=([observed_writer], True)):
            writer_result = recovery.audit(self.fixture.repo)
        writer_row = next(item for item in writer_result["items"]
                          if item.get("workstream") == self.fixture.workstream)
        self.assertNotIn("workstream.py resume", writer_row["recommended_action"])

        # Incomplete local process visibility likewise suppresses the hint.
        with mock.patch.object(recovery, "_unmanaged_codex_processes",
                               return_value=([], False)):
            unseen_result = recovery.audit(self.fixture.repo)
        unseen_row = next(item for item in unseen_result["items"]
                          if item.get("workstream") == self.fixture.workstream)
        self.assertNotIn("workstream.py resume", unseen_row["recommended_action"])

        # Dirty user data must remain protected, even with explicit authority.
        (self.fixture.worktree / "untracked-art.txt").write_text("preserve")
        dirty_result = recovery.audit(self.fixture.repo)
        dirty_row = next(item for item in dirty_result["items"]
                         if item.get("workstream") == self.fixture.workstream)
        self.assertTrue(dirty_row["dirty"])
        self.assertNotIn("workstream.py resume", dirty_row["recommended_action"])

    def test_audit_is_read_only_and_marks_unmanaged_branch(self):
        git(self.fixture.repo, "branch", "agent/fixture-historical", "HEAD")
        git(self.fixture.repo, "push", "origin", "agent/fixture-historical")
        before_refs = git(self.fixture.repo, "show-ref")
        before_status = git(self.fixture.repo, "status", "--porcelain=v1")
        result = recovery.audit(self.fixture.repo)
        self.assertFalse(result["git_fetch_performed"])
        after_refs = git(self.fixture.repo, "show-ref")
        after_status = git(self.fixture.repo, "status", "--porcelain=v1")
        self.assertEqual(before_refs, after_refs)
        self.assertEqual(before_status, after_status)
        historical = [item for item in result["items"] if item.get("workstream") == "fixture-historical"]
        self.assertEqual(len(historical), 1)
        self.assertEqual(historical[0]["classification"], "UNMANAGED_UNKNOWN")
        self.assertEqual(historical[0]["affected_locks"], [])

    def test_untracked_user_file_is_preserved_and_classified_dirty(self):
        user_file = self.fixture.worktree / "unfinished-user-edit.txt"
        user_file.write_bytes(b"keep these exact bytes\x00\xff")
        supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                              [sys.executable, "-c", "pass"], heartbeat_seconds=.02)
        row = next(item for item in recovery.audit(self.fixture.repo)["items"]
                   if item.get("workstream") == self.fixture.workstream)
        self.assertEqual(row["classification"], "RECOVERABLE_DIRTY")
        self.assertEqual(row["untracked_count"], 1)
        self.assertEqual(user_file.read_bytes(), b"keep these exact bytes\x00\xff")

    def test_post_exit_review_remains_blocked_not_passed(self):
        common = supervisor.common_dir(self.fixture.repo)
        metadata = common / "custodian-review-runs" / "review-fixture" / "run-01" / "metadata.json"
        metadata.parent.mkdir(parents=True)
        metadata.write_text(json.dumps({"schema": "custodian.paired_review_run.v1",
                                        "workstream": "review-fixture", "run_id": "run-01",
                                        "phase": "post_exit_recovery"}))
        row = next(item for item in recovery.audit(self.fixture.repo)["items"]
                   if item.get("workstream") == "review-fixture")
        self.assertEqual(row["classification"], "REVIEW_FINDINGS_OR_BLOCKED")
        self.assertIn("not be inferred as PASS", row["evidence_gap"])

    def test_stale_or_wrong_claim_receipt_blocks_before_child_spawn(self):
        receipt_path = supervisor.common_dir(self.fixture.repo) / "custodian-dispatch" / "last-claim.json"
        receipt = json.loads(receipt_path.read_text())
        receipt["workstream"] = "some-other-workstream"
        receipt_path.write_text(json.dumps(receipt))
        popen = mock.Mock()
        with mock.patch.object(supervisor, "_claim_identity", side_effect=supervisor.SupervisorError(
                "latest dispatcher receipt does not verify this workstream")):
            with self.assertRaisesRegex(supervisor.SupervisorError, "does not verify"):
                supervisor.supervise(self.fixture.repo, self.fixture.workstream, ["codex"], popen_factory=popen)
            popen.assert_not_called()

    def test_codex_exec_cannot_escape_the_dispatched_worktree(self):
        popen = mock.Mock()
        with self.assertRaisesRegex(supervisor.SupervisorError, "--cd must match"):
            supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                 ["codex", "exec", "--cd", str(self.fixture.repo)], popen_factory=popen)
        popen.assert_not_called()

    def test_crash_before_durable_launch_intent_never_spawns_child(self):
        popen = mock.Mock()
        with mock.patch.object(supervisor, "append_event", side_effect=OSError("simulated journal failure")):
            with self.assertRaisesRegex(OSError, "journal failure"):
                supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                     ["codex", "exec"], popen_factory=popen)
        popen.assert_not_called()

    def test_unresolved_journal_blocks_duplicate_supervised_launch(self):
        claim = supervisor._claim_identity(self.fixture.repo, self.fixture.workstream)
        run_id = "20260101T000000Z-0123456789abcdef"
        path = supervisor._journal_path(self.fixture.repo, self.fixture.workstream, run_id)
        intent = {**claim, "run_id": run_id, "event": "LAUNCH_INTENT", "host": "fixture-host",
                  "boot_id": "01234567-89ab-cdef-0123-456789abcdef", "supervisor": {"pid": 1,
                  "start_ticks": 1, "pgid": 1}, "command_executable": "codex",
                  "timestamp_utc": "2026-01-01T00:00:00+00:00", "monotonic_ns": 1}
        supervisor.append_event(path, intent)
        popen = mock.Mock()
        with self.assertRaisesRegex(supervisor.SupervisorError, "prior supervisor run is unresolved"):
            supervisor.supervise(self.fixture.repo, self.fixture.workstream,
                                 [sys.executable, "-c", "pass"], popen_factory=popen)
        popen.assert_not_called()


if __name__ == "__main__":
    unittest.main()
