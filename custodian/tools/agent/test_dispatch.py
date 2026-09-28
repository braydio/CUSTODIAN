"""Temporary-repository tests for task discovery, claims, and locking."""

import importlib.util
import subprocess
import shutil
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("dispatch.py")
SPEC = importlib.util.spec_from_file_location("custodian_dispatch_tests", SCRIPT)
dispatch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = dispatch
SPEC.loader.exec_module(dispatch)


def git(cwd: Path, *args: str, check=True) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


def packet(workstream, *, status="ready", dispatch_value=None, priority=None, depends=None, locks=None):
    rows = [f"- Workstream: `{workstream}`", f"- Status: `{status}`"]
    if dispatch_value is not None:
        rows.append(f"- Dispatch: `{dispatch_value}`")
    if priority is not None:
        rows.append(f"- Priority: `{priority}`")
    if depends is not None:
        rows.append(f"- Depends on: `{depends}`")
    if locks is not None:
        rows.append(f"- Locks: `{locks}`")
    return "# Packet\n\n" + "\n".join(rows) + "\n"


class DispatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote))
        git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Dispatch Test")
        git(self.repo, "config", "user.email", "dispatch@example.test")
        (self.repo / "base").write_text("base\n")
        lifecycle = self.repo / "custodian/tools/agent/workstream.py"
        lifecycle.parent.mkdir(parents=True)
        shutil.copyfile(SCRIPT.with_name("workstream.py"), lifecycle)
        git(self.repo, "add", "base", str(lifecycle.relative_to(self.repo))); git(self.repo, "commit", "-m", "base"); git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")

    def tearDown(self):
        for record in git(self.repo, "worktree", "list", "--porcelain").split("\n\n"):
            lines = record.splitlines()
            if lines and Path(lines[0].removeprefix("worktree ")).resolve() != self.repo.resolve():
                git(self.repo, "worktree", "remove", "--force", lines[0].removeprefix("worktree "), check=False)
        self.temp.cleanup()

    def add_packet(self, workstream, *, filename=None, text=None, archived=False, publish=True, push=True, **metadata):
        folder = dispatch.PACKET_ROOT + ("/archived" if archived else "")
        name = filename or workstream.upper().replace("-", "_") + ".md"
        path = self.repo / folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text if text is not None else packet(workstream, **metadata))
        git(self.repo, "add", str(path.relative_to(self.repo)))
        git(self.repo, "commit", "-m", f"packet {workstream}")
        if push:
            git(self.repo, "push", "origin", "main")
            if publish:
                git(self.repo, "fetch", "origin")
        return path

    def test_missing_dispatch_and_explicit_manual_are_not_auto_claimed(self):
        self.add_packet("legacy-task", priority="P0")
        self.add_packet("manual-task", dispatch_value="manual", priority="P0")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("legacy-task", rendered.split("MANUAL (", 1)[1])
        self.assertIn("manual-task", rendered.split("MANUAL (", 1)[1])
        self.assertIn("NO ELIGIBLE AUTO TASK", self._claim_output())

    def test_ready_auto_packet_is_eligible(self):
        self.add_packet("auto-task", dispatch_value="auto")
        self.assertIn("auto-task", dispatch.status(self.repo, output=False).split("READY", 1)[1])

    def test_non_ready_packet_is_not_eligible(self):
        self.add_packet("draft-task", status="draft", dispatch_value="auto")
        self.assertIn("status: draft", self._claim_output())

    def test_priority_and_path_tiebreak_order(self):
        self.add_packet("late", dispatch_value="auto", priority="P2", filename="z-late.md")
        self.add_packet("first", dispatch_value="auto", priority="P1", filename="z-first.md")
        self.add_packet("path-a", dispatch_value="auto", priority="P1", filename="a-path.md")
        ready_lines = dispatch.status(self.repo, output=False).split("READY (", 1)[1].splitlines()
        first_entry = next(line for line in ready_lines[1:] if line.startswith("P"))
        self.assertEqual(first_entry, "P1 path-a [" + f"{dispatch.PACKET_ROOT}/a-path.md]")
        # Mock only start's effects to observe the exact selected candidate.
        fake = mock.Mock()
        fake.start.side_effect = lambda work_id, repo: self.base / work_id
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake):
            with mock.patch("builtins.print"):
                dispatch.claim(self.repo, None, "codex", True)
        self.assertEqual(fake.start.call_args.args[0], "path-a")

    def test_archived_complete_dependency_satisfies_dependency(self):
        self.add_packet("depends-task", dispatch_value="auto", depends="base-task")
        self.assertIn("dependency: base-task", self._claim_output())
        self.add_packet("base-task", status="complete", archived=True)
        self.assertIn("depends-task", dispatch.status(self.repo, output=False).split("READY", 1)[1])

    def test_active_or_incomplete_dependency_does_not_satisfy(self):
        self.add_packet("depends-task", dispatch_value="auto", depends="base-task")
        self.add_packet("base-task", status="complete", archived=False)
        self.assertIn("dependency: base-task", dispatch.status(self.repo, output=False))
        self.add_packet("base-task", status="in_progress", archived=True)
        self.assertIn("dependency: base-task", dispatch.status(self.repo, output=False))

    def test_remote_claim_excludes_duplicate(self):
        self.add_packet("already", dispatch_value="auto")
        git(self.repo, "branch", "agent/already", "origin/main"); git(self.repo, "push", "origin", "agent/already"); git(self.repo, "fetch", "origin")
        self.assertIn("CLAIMED (1)\nalready", dispatch.status(self.repo, output=False))

    def test_local_attached_worktree_excludes_duplicate(self):
        self.add_packet("attached", dispatch_value="auto")
        git(self.repo, "worktree", "add", "-b", "agent/attached", str(self.base / "attached-wt"), "origin/main")
        self.assertIn("CLAIMED (1)\nattached", dispatch.status(self.repo, output=False))

    def test_lock_collision_names_holder_and_disjoint_locks_allow_claim(self):
        self.add_packet("holder", dispatch_value="auto", locks="asset-catalog")
        self.add_packet("collision", dispatch_value="auto", locks="asset-catalog")
        self.add_packet("independent", dispatch_value="auto", locks="level-registry")
        git(self.repo, "branch", "agent/holder", "origin/main"); git(self.repo, "push", "origin", "agent/holder"); git(self.repo, "fetch", "origin")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("lock: asset-catalog held by holder", rendered)
        self.assertIn("independent", rendered.split("READY (", 1)[1])

    def test_remote_main_discovery_works_when_local_main_is_stale(self):
        self.add_packet("remote-new", dispatch_value="auto")
        git(self.repo, "reset", "--hard", "HEAD^")
        git(self.repo, "fetch", "origin")
        self.assertIn("remote-new", dispatch.status(self.repo, output=False))

    def test_concurrent_claims_select_distinct_workstreams(self):
        self.add_packet("task-a", dispatch_value="auto", priority="P0")
        self.add_packet("task-b", dispatch_value="auto", priority="P1")
        results = []
        fake = mock.Mock()
        def fake_start(work_id, repo):
            git(repo, "branch", f"agent/{work_id}", "origin/main")
            git(repo, "push", "origin", f"agent/{work_id}")
            git(repo, "fetch", "origin")
            return self.base / f"{work_id}-worktree"
        fake.start.side_effect = fake_start
        thread_output = threading.local()
        captured = {}
        def capture(*args, **kwargs):
            captured.setdefault(thread_output.key, []).append(" ".join(map(str, args)))
        def run():
            thread_output.key = threading.get_ident()
            dispatch.claim(self.repo, None, "codex", True)
            results.append("\n".join(captured[thread_output.key]))
        threads = [threading.Thread(target=run) for _ in range(2)]
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print", side_effect=capture):
            for thread in threads: thread.start()
            for thread in threads: thread.join()
        names = [next(line.split(": ", 1)[1] for line in output.splitlines() if line.startswith("workstream:")) for output in results]
        self.assertEqual(set(names), {"task-a", "task-b"})

    def test_two_real_claims_create_workstreams_in_priority_order(self):
        self.add_packet("task-a", dispatch_value="auto", priority="P0")
        self.add_packet("task-b", dispatch_value="auto", priority="P1")
        outputs = []
        for _ in range(2):
            out = []
            with mock.patch("builtins.print", side_effect=lambda *args, **kwargs: out.append(" ".join(map(str, args)))):
                dispatch.claim(self.repo, None, "codex", True)
            outputs.append("\n".join(out))
        names = [next(line.split(": ", 1)[1] for line in output.splitlines() if line.startswith("workstream: ") and not line.startswith("workstream: agent/")) for output in outputs]
        self.assertEqual(names, ["task-a", "task-b"])
        for output, work_id in zip(outputs, names):
            self.assertIn(f"branch: agent/{work_id}", output)
            self.assertIn(f"{dispatch.PACKET_ROOT}/{work_id.upper().replace('-', '_')}.md", output)

    def test_explicit_claim_allows_manual_but_still_checks_dependencies_and_locks(self):
        self.add_packet("manual-claim", dispatch_value="manual")
        fake = mock.Mock(); fake.start.return_value = self.base / "manual-claim"
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print"):
            dispatch.claim(self.repo, "manual-claim", "codex", False)
        self.assertEqual(fake.start.call_args.args[0], "manual-claim")
        self.add_packet("blocked-manual", dispatch_value="manual", depends="missing")
        with self.assertRaisesRegex(dispatch.DispatchError, "dependency: missing"):
            dispatch.claim(self.repo, "blocked-manual", "codex", False)

    def test_malformed_dispatch_fails_closed_and_is_visible(self):
        self.add_packet("bad-dispatch", text="- Workstream: `bad-dispatch`\n- Status: `ready`\n- Dispatch: `sometimes`\n")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid packet metadata", rendered)
        self.assertIn("bad-dispatch", self._claim_output())

    def test_duplicate_dispatch_declaration_is_blocked_not_treated_as_manual(self):
        text = "- Workstream: `duplicate-dispatch`\n- Status: `ready`\n- Dispatch: `manual`\n- Dispatch: `auto`\n"
        self.add_packet("duplicate-dispatch", text=text)
        self.assertIn("duplicate Dispatch metadata", dispatch.status(self.repo, output=False))

    def test_duplicate_workstream_identity_is_not_claimable(self):
        self.add_packet("duplicate-id", filename="A.md", dispatch_value="auto")
        self.add_packet("duplicate-id", filename="B.md", dispatch_value="auto")
        self.assertIn("duplicate Workstream identity", dispatch.status(self.repo, output=False))

    def test_malformed_lock_fails_closed(self):
        self.add_packet("bad-lock", text="- Workstream: `bad-lock`\n- Status: `ready`\n- Dispatch: `auto`\n- Locks: `asset catalog`\n")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid Locks metadata", rendered)
        self.assertIn("invalid Locks metadata", self._claim_output())

    def test_no_eligible_is_successful_and_non_destructive(self):
        self.add_packet("manual-only", dispatch_value="manual")
        before = git(self.repo, "show-ref", "--heads")
        self.assertIn("NO ELIGIBLE AUTO TASK", self._claim_output())
        self.assertEqual(before, git(self.repo, "show-ref", "--heads"))

    def test_delegates_worktree_creation_to_workstream_lifecycle(self):
        self.add_packet("delegate", dispatch_value="auto")
        fake = mock.Mock(); fake.start.return_value = self.base / "delegate-worktree"
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print"):
            dispatch.claim(self.repo, None, "codex", True)
        fake.start.assert_called_once_with("delegate", self.repo)

    def test_explicit_manual_claim_respects_lock_conflicts(self):
        self.add_packet("holder", dispatch_value="auto", locks="agent-workflow")
        self.add_packet("manual-lock", dispatch_value="manual", locks="agent-workflow")
        git(self.repo, "branch", "agent/holder", "origin/main"); git(self.repo, "push", "origin", "agent/holder"); git(self.repo, "fetch", "origin")
        with self.assertRaisesRegex(dispatch.DispatchError, "lock: agent-workflow held by holder"):
            dispatch.claim(self.repo, "manual-lock", "codex", False)

    def test_invalid_workstream_metadata_is_blocked(self):
        self.add_packet("invalid", text="- Workstream: `Bad_ID`\n- Status: `ready`\n- Dispatch: `auto`\n")
        self.assertIn("invalid Workstream metadata", dispatch.status(self.repo, output=False))

    def test_packet_on_remote_is_read_without_local_pull(self):
        self.add_packet("remote-only", dispatch_value="auto", push=True)
        git(self.repo, "reset", "--hard", "HEAD^")
        # No explicit local pull: dispatch fetches and reads origin/main.
        self.assertIn("remote-only", dispatch.status(self.repo, output=False))

    def test_claim_output_identifies_workstream_branch_worktree_and_packet(self):
        self.add_packet("output-task", dispatch_value="auto")
        fake = mock.Mock(); fake.start.return_value = self.base / "output-task"
        output = []
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print", side_effect=lambda *args, **kwargs: output.append(" ".join(map(str, args)))):
            dispatch.claim(self.repo, None, "codex", True)
        rendered = "\n".join(output)
        for expected in ("workstream: output-task", "branch: agent/output-task", str(self.base / "output-task"), f"packet: {dispatch.PACKET_ROOT}/OUTPUT_TASK.md"):
            self.assertIn(expected, rendered)

    def _claim_output(self):
        output = []
        with mock.patch("builtins.print", side_effect=lambda *args, **kwargs: output.append(" ".join(map(str, args)))):
            result = dispatch.claim(self.repo, None, "codex", True)
        self.assertEqual(result, 0)
        return "\n".join(output)


if __name__ == "__main__":
    unittest.main()
