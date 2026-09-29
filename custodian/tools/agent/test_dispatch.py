"""Temporary-repository tests for task discovery, claims, and locking."""

import importlib.util
import json
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


def packet(
    workstream, *, status="ready", dispatch_value=None, priority=None, depends=None, locks=None,
    kind=None, review=None, review_stage=None, review_modes=None, paired_review_workstream=None,
    review_cycle=None, max_review_cycles=None, review_target_workstream=None, review_target_packet=None,
    task_overrides=None,
):
    rows = [f"- Workstream: `{workstream}`", f"- Status: `{status}`"]
    if dispatch_value is not None:
        rows.append(f"- Dispatch: `{dispatch_value}`")
    if priority is not None:
        rows.append(f"- Priority: `{priority}`")
    if depends is not None:
        rows.append(f"- Depends on: `{depends}`")
    if locks is not None:
        rows.append(f"- Locks: `{locks}`")
    if kind is not None:
        rows.append(f"- Kind: `{kind}`")
    if review is not None:
        rows.append(f"- Review: `{review}`")
    if review_stage is not None:
        rows.append(f"- Review stage: `{review_stage}`")
    if review_modes is not None:
        rows.append(f"- Review modes: `{review_modes}`")
    if paired_review_workstream is not None:
        rows.append(f"- Paired review workstream: `{paired_review_workstream}`")
    if review_cycle is not None:
        rows.append(f"- Review cycle: `{review_cycle}`")
    if max_review_cycles is not None:
        rows.append(f"- Max automatic review cycles: `{max_review_cycles}`")
    if review_target_workstream is not None:
        rows.append(f"- Review target workstream: `{review_target_workstream}`")
    if review_target_packet is not None:
        rows.append(f"- Review target packet: `{review_target_packet}`")
    if task_overrides is None and kind == "review" and dispatch_value == "auto":
        task_overrides = dispatch.BOUNDED_REVIEW_OVERRIDE
    if task_overrides is not None:
        rows.append(f"- Task overrides: `{task_overrides}`")
    return "# Packet\n\n" + "\n".join(rows) + "\n"


def archived_target(workstream):
    return f"{dispatch.PACKET_ROOT}/archived/{workstream.upper().replace('-', '_')}.md"


def publish_workstream(work_id, repo):
    # A real worktree, not just a branch: dispatch.py's post-start identity
    # verification checks that the returned path actually exists and is checked
    # out on the expected branch.
    path = Path(repo).parent / f"{work_id}-worktree"
    git(repo, "worktree", "add", "-b", f"agent/{work_id}", str(path), "origin/main")
    git(path, "push", "-u", "origin", f"agent/{work_id}")
    git(repo, "fetch", "origin")
    return path


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
        fake.start.side_effect = publish_workstream
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

    def _claim_oid(self, repo, label):
        tree = git(repo, "rev-parse", "origin/main^{tree}")
        parent = git(repo, "rev-parse", "origin/main")
        return git(repo, "-c", "user.name=Test", "-c", "user.email=test@example.test", "commit-tree", tree, "-p", parent, "-m", label)

    def test_interrupted_remote_claim_is_blocked_and_visible(self):
        self.add_packet("interrupted", dispatch_value="auto")
        oid = self._claim_oid(self.repo, "interrupted claimant one")
        git(self.repo, "push", "origin", f"{oid}:refs/heads/dispatch-claims/interrupted")
        git(self.repo, "fetch", "origin")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("interrupted — remote dispatch claim interrupted; recovery required", rendered)
        self.assertIn("BLOCKED", rendered)
        with self.assertRaisesRegex(dispatch.DispatchError, "recovery required"):
            dispatch.claim(self.repo, "interrupted", "codex", False)
        self.assertNotIn("refs/remotes/origin/agent/interrupted", git(self.repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/agent"))

    def test_remote_claim_with_agent_branch_is_claimed(self):
        self.add_packet("claimed-with-marker", dispatch_value="auto")
        oid = self._claim_oid(self.repo, "claim marker")
        git(self.repo, "push", "origin", f"{oid}:refs/heads/dispatch-claims/claimed-with-marker")
        git(self.repo, "push", "origin", "origin/main:refs/heads/agent/claimed-with-marker")
        git(self.repo, "fetch", "origin")
        self.assertIn("CLAIMED (1)\nclaimed-with-marker", dispatch.status(self.repo, output=False))

    def test_two_independent_clones_racing_claim_create_one_workstream(self):
        self.add_packet("race-task", dispatch_value="auto")
        second = self.base / "second"
        git(self.base, "clone", str(self.remote), str(second))
        git(second, "config", "user.name", "Second Agent")
        git(second, "config", "user.email", "second@example.test")
        calls = []
        calls_lock = threading.Lock()
        def start(work_id, repo):
            with calls_lock:
                calls.append(Path(repo))
            return publish_workstream(work_id, repo)
        outcomes = []
        ready = threading.Barrier(2)
        def run(repo):
            try:
                ready.wait()
                with mock.patch.object(dispatch, "_load_workstream", return_value=mock.Mock(start=start)), mock.patch("builtins.print"):
                    dispatch.claim(repo, "race-task", "codex", False)
                outcomes.append("claimed")
            except dispatch.DispatchError as error:
                outcomes.append(str(error))
        threads = [threading.Thread(target=run, args=(repo,)) for repo in (self.repo, second)]
        for thread in threads: thread.start()
        for thread in threads: thread.join()
        self.assertEqual(len(calls), 1)
        self.assertEqual(sum(value == "claimed" for value in outcomes), 1)
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/race-task"))
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/race-task"))

    def test_cleanup_failure_keeps_published_workstream_claimed(self):
        self.add_packet("cleanup-task", dispatch_value="auto")
        real_run = subprocess.run
        def fail_claim_delete(args, **kwargs):
            if args[:3] == ["git", "push", "origin"] and args[-1] == ":refs/heads/dispatch-claims/cleanup-task":
                return subprocess.CompletedProcess(args, 1, "", "simulated delete rejection")
            return real_run(args, **kwargs)
        with mock.patch.object(dispatch, "_load_workstream", return_value=mock.Mock(start=publish_workstream)), \
             mock.patch("subprocess.run", side_effect=fail_claim_delete), mock.patch("builtins.print"):
            dispatch.claim(self.repo, "cleanup-task", "codex", False)
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("cleanup-task (remote claim cleanup pending)", rendered)
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/cleanup-task"))

    def test_attached_non_main_invocation_uses_coordination_checkout(self):
        existing = self.base / "existing"
        git(self.repo, "worktree", "add", "-b", "agent/existing-task", str(existing), "origin/main")
        (existing / "keep.txt").write_text("preserve me\n")
        git(existing, "add", "keep.txt"); git(existing, "commit", "-m", "existing task work")
        self.add_packet("coordination-task", dispatch_value="auto")
        self.assertFalse((existing / dispatch.PACKET_ROOT / "COORDINATION_TASK.md").exists())
        claimed_worktree = self.base / "coordination-task-worktree"
        def coordinated_start(work_id, repo):
            self.assertEqual(Path(repo).resolve(), self.repo.resolve())
            git(repo, "worktree", "add", "-b", f"agent/{work_id}", str(claimed_worktree), "origin/main")
            git(claimed_worktree, "push", "-u", "origin", f"agent/{work_id}")
            git(repo, "fetch", "origin")
            return claimed_worktree
        with mock.patch.object(dispatch, "_load_workstream", return_value=mock.Mock(start=coordinated_start)):
            self.assertIn("coordination-task", dispatch.status(existing, output=False))
            with mock.patch("builtins.print"):
                dispatch.claim(existing, "coordination-task", "codex", False)
        self.assertEqual(git(self.repo, "worktree", "list", "--porcelain").count("worktree "), 3)
        self.assertTrue((claimed_worktree / "base").exists())
        self.assertEqual(git(existing, "branch", "--show-current"), "agent/existing-task")
        self.assertEqual((existing / "keep.txt").read_text(), "preserve me\n")

    def test_local_only_clean_worktree_is_not_claim_authority_and_is_preserved(self):
        self.add_packet("attached", dispatch_value="auto")
        path = self.base / "attached-wt"
        git(self.repo, "worktree", "add", "-b", "agent/attached", str(path), "origin/main")
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("P2 attached", rendered.split("READY (", 1)[1])
        self.assertNotIn("CLAIMED (1)\nattached", rendered)
        with self.assertRaisesRegex(dispatch.DispatchError, "already exists or is attached"):
            dispatch.claim(self.repo, "attached", "codex", False)
        self.assertTrue(path.is_dir())
        self.assertEqual(git(path, "branch", "--show-current"), "agent/attached")
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/attached"))

    def test_local_only_unique_worktree_fails_closed_on_reclaim(self):
        self.add_packet("unique-local", dispatch_value="auto")
        path = self.base / "unique-local-wt"
        git(self.repo, "worktree", "add", "-b", "agent/unique-local", str(path), "origin/main")
        (path / "unique.txt").write_text("preserve\n")
        git(path, "add", "unique.txt")
        git(path, "commit", "-m", "unique local work")
        self.assertIn("P2 unique-local", dispatch.status(self.repo, output=False).split("READY (", 1)[1])
        with self.assertRaisesRegex(dispatch.DispatchError, "unique commits; explicit recovery required"):
            dispatch.claim(self.repo, "unique-local", "codex", False)
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/unique-local"))
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/unique-local"))

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
            return publish_workstream(work_id, repo)
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
        fake = mock.Mock(); fake.start.side_effect = publish_workstream
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
        fake = mock.Mock(); fake.start.side_effect = publish_workstream
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
        fake = mock.Mock(); fake.start.side_effect = publish_workstream
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

    def _publish_claimed_workstream(self, work_id):
        """Simulate a workstream already fully claimed: local attached worktree + remote branch."""
        path = self.base / f"{work_id}-attached"
        git(self.repo, "worktree", "add", "-b", f"agent/{work_id}", str(path), "origin/main")
        git(path, "push", "-u", "origin", f"agent/{work_id}")
        git(self.repo, "fetch", "origin")
        return path

    def _real_claim(self, workstream_id, agent="codex", auto_only=False):
        output = []
        with mock.patch("builtins.print", side_effect=lambda *args, **kwargs: output.append(" ".join(map(str, args)))):
            result = dispatch.claim(self.repo, workstream_id, agent, auto_only)
        self.assertEqual(result, 0)
        rendered = "\n".join(output)
        sentinel = next(line for line in rendered.splitlines() if line.startswith("CUSTODIAN_DISPATCH_RESULT_JSON:"))
        receipt = json.loads(sentinel.removeprefix("CUSTODIAN_DISPATCH_RESULT_JSON:"))
        return rendered, receipt

    # --- Reported incident fixture: claim-next must not confuse an unrelated
    # already-claimed workstream's worktree with the actually selected task. ---

    def test_claim_next_selects_ready_task_despite_unrelated_claimed_worktree(self):
        self._publish_claimed_workstream("twin-like")
        self.add_packet("twin-like", dispatch_value="auto", priority="P1")
        self.add_packet("baby-like", dispatch_value="auto", priority="P2")
        rendered_status = dispatch.status(self.repo, output=False)
        self.assertIn("twin-like", rendered_status.split("CLAIMED (", 1)[1])
        self.assertIn("baby-like", rendered_status.split("READY (", 1)[1])

        rendered, receipt = self._real_claim(None, auto_only=True)
        self.assertIn("workstream: baby-like", rendered)
        self.assertNotIn("twin-like", rendered)
        self.assertEqual(receipt["workstream"], "baby-like")
        self.assertEqual(receipt["branch"], "agent/baby-like")
        self.assertNotIn("twin-like", json.dumps(receipt))

    def test_claim_next_does_not_block_on_higher_priority_already_claimed_task(self):
        self._publish_claimed_workstream("urgent-claimed")
        self.add_packet("urgent-claimed", dispatch_value="auto", priority="P0")
        self.add_packet("lower-ready", dispatch_value="auto", priority="P2")
        rendered, receipt = self._real_claim(None, auto_only=True)
        self.assertEqual(receipt["workstream"], "lower-ready")
        self.assertIn("workstream: lower-ready", rendered)

    # --- Structured receipt schema and identity-derived disposition. ---

    def test_claim_emits_structured_receipt_with_full_schema(self):
        self.add_packet("schema-task", dispatch_value="auto")
        rendered, receipt = self._real_claim(None, auto_only=True)
        self.assertEqual(receipt["schema"], "custodian.dispatch.claim.v1")
        self.assertEqual(receipt["result"], "claimed")
        self.assertEqual(receipt["workstream"], "schema-task")
        self.assertEqual(receipt["prior_status"], "ready")
        self.assertEqual(receipt["branch"], "agent/schema-task")
        self.assertIn("schema-task-", receipt["worktree"])
        self.assertEqual(receipt["packet"], f"{dispatch.PACKET_ROOT}/SCHEMA_TASK.md")
        self.assertEqual(receipt["checkout"], "created")
        self.assertTrue(receipt["verified"])
        self.assertEqual(receipt["agent"], "codex")
        self.assertIn(f"workstream: {receipt['workstream']}", rendered)
        self.assertIn(f"branch: {receipt['branch']}", rendered)
        self.assertIn(f"packet: {receipt['packet']}", rendered)

    def test_dispatch_does_not_silently_adopt_clean_local_only_worktree(self):
        self.add_packet("resumed-task", dispatch_value="auto")
        path = self.base / "resumed-task-wt"
        git(self.repo, "worktree", "add", "-b", "agent/resumed-task", str(path), "origin/main")
        with self.assertRaisesRegex(dispatch.DispatchError, "already exists or is attached"):
            dispatch.claim(self.repo, "resumed-task", "codex", False)
        self.assertTrue(path.is_dir())
        self.assertEqual(git(path, "branch", "--show-current"), "agent/resumed-task")
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/resumed-task"))

    # --- Durable last-claim recovery. ---

    def test_last_claim_recovers_identity_after_stdout_loss(self):
        self.add_packet("recover-task", dispatch_value="auto")
        with mock.patch("builtins.print"):
            dispatch.claim(self.repo, None, "codex", True)
        with mock.patch("builtins.print") as printer:
            result = dispatch.last_claim(self.repo, as_json=True)
        self.assertEqual(result, 0)
        receipt = json.loads(printer.call_args.args[0])
        self.assertEqual(receipt["workstream"], "recover-task")
        self.assertEqual(receipt["freshness"], "current")
        self.assertEqual(receipt["freshness_reasons"], [])

    def test_last_claim_reports_no_receipt_when_none_exists(self):
        output = []
        with mock.patch("builtins.print", side_effect=lambda *args, **kwargs: output.append(" ".join(map(str, args)))):
            result = dispatch.last_claim(self.repo, as_json=False)
        self.assertEqual(result, 1)
        self.assertIn("NO LAST CLAIM RECEIPT", "\n".join(output))

    def test_last_claim_reports_stale_without_mutating_state(self):
        self.add_packet("stale-task", dispatch_value="auto")
        with mock.patch("builtins.print"):
            dispatch.claim(self.repo, None, "codex", True)
        for record in git(self.repo, "worktree", "list", "--porcelain").split("\n\n"):
            lines = record.splitlines()
            if lines and "branch refs/heads/agent/stale-task" in lines:
                git(self.repo, "worktree", "remove", "--force", lines[0].removeprefix("worktree "))
        git(self.repo, "push", "origin", "--delete", "agent/stale-task")
        before = git(self.repo, "show-ref", "--heads")
        with mock.patch("builtins.print") as printer:
            result = dispatch.last_claim(self.repo, as_json=True)
        self.assertEqual(result, 0)
        receipt = json.loads(printer.call_args.args[0])
        self.assertEqual(receipt["freshness"], "stale")
        self.assertTrue(receipt["freshness_reasons"])
        self.assertEqual(before, git(self.repo, "show-ref", "--heads"))
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "agent/stale-task"))

    # --- Already-claimed explicit diagnostic. ---

    def test_explicit_claim_of_already_claimed_task_reports_branch_and_worktree(self):
        attached = self._publish_claimed_workstream("held-task")
        self.add_packet("held-task", dispatch_value="auto")
        with self.assertRaises(dispatch.DispatchError) as ctx:
            dispatch.claim(self.repo, "held-task", "codex", False)
        message = str(ctx.exception)
        self.assertIn("ALREADY CLAIMED", message)
        self.assertIn("workstream: held-task", message)
        self.assertIn("branch: agent/held-task", message)
        self.assertIn(attached.name, message)

    # --- Post-start identity verification fails closed. ---

    def test_post_start_branch_mismatch_fails_closed_and_writes_no_receipt(self):
        self.add_packet("mismatch-task", dispatch_value="auto")
        wrong_path = self.base / "wrong-branch-worktree"

        def wrong_branch_start(work_id, repo):
            git(repo, "worktree", "add", "-b", "agent/decoy-branch", str(wrong_path), "origin/main")
            git(wrong_path, "push", "-u", "origin", "agent/decoy-branch")
            git(repo, "fetch", "origin")
            return wrong_path

        fake = mock.Mock(); fake.start.side_effect = wrong_branch_start
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print"):
            with self.assertRaisesRegex(dispatch.DispatchError, "post-start verification failed"):
                dispatch.claim(self.repo, "mismatch-task", "codex", False)
        self.assertFalse(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/agent/mismatch-task"))
        self.assertTrue(git(self.repo, "ls-remote", "--heads", "origin", "refs/heads/dispatch-claims/mismatch-task"))
        self.assertFalse(dispatch._last_claim_path(self.repo).is_file())

    # --- Paired post-land review contract ---

    def test_historical_packet_without_review_metadata_remains_valid(self):
        self.add_packet("legacy-implementation", dispatch_value="auto")
        packets = dispatch._packets(self.repo)
        p = next(p for p in packets if p.workstream == "legacy-implementation")
        self.assertIsNone(p.error)
        self.assertEqual(p.kind, "implementation")
        self.assertEqual(p.review, "none")
        self.assertEqual(dispatch.validate_review_pairing(packets), {})
        self.assertIn("legacy-implementation", dispatch.status(self.repo, output=False).split("READY (", 1)[1])

    def test_review_none_requires_no_pair(self):
        self.add_packet("solo-task", dispatch_value="auto", review="none")
        packets = dispatch._packets(self.repo)
        self.assertEqual(dispatch.validate_review_pairing(packets), {})
        self.assertIn("solo-task", dispatch.status(self.repo, output=False).split("READY (", 1)[1])

    def test_review_manual_does_not_require_pair_or_imply_auto(self):
        self.add_packet("manual-review-task", dispatch_value="auto", review="manual")
        packets = dispatch._packets(self.repo)
        p = next(p for p in packets if p.workstream == "manual-review-task")
        self.assertEqual(p.review, "manual")
        self.assertEqual(dispatch.validate_review_pairing(packets), {})
        self.assertIn("manual-review-task", dispatch.status(self.repo, output=False).split("READY (", 1)[1])

    def test_review_auto_requires_paired_review_declaration(self):
        self.add_packet("unpaired-auto", dispatch_value="auto", review="auto")
        packets = dispatch._packets(self.repo)
        p = next(p for p in packets if p.workstream == "unpaired-auto")
        self.assertIn("Review: auto requires a Paired review workstream", p.error)
        rendered = dispatch.status(self.repo, output=False)
        ready_section = rendered.split("READY (", 1)[1].split("CLAIMED (", 1)[0]
        self.assertNotIn("unpaired-auto", ready_section)

    def test_paired_review_must_declare_kind_review(self):
        self.add_packet("impl-a", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-a")
        self.add_packet(
            "review-impl-a", dispatch_value="auto", kind="implementation", review="none",
            depends="impl-a", review_target_workstream="impl-a",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn("Kind: review", errors.get("impl-a", ""))

    def test_paired_review_must_declare_review_none(self):
        self.add_packet("impl-b", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-b")
        self.add_packet(
            "review-impl-b", dispatch_value="auto", kind="review", review="auto",
            paired_review_workstream="review-somewhere-else", depends="impl-b",
            review_target_workstream="impl-b",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn("Review: none", errors.get("impl-b", ""))

    def test_paired_review_dependency_and_target_identity_must_match(self):
        self.add_packet("impl-c", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-c")
        self.add_packet("unrelated-task", dispatch_value="auto")
        # Depends on and targets the wrong workstream.
        self.add_packet(
            "review-impl-c", dispatch_value="auto", kind="review", review="none",
            depends="unrelated-task", review_target_workstream="unrelated-task",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        message = errors.get("impl-c", "")
        self.assertIn("must depend on 'impl-c'", message)
        self.assertIn("Review target workstream must be 'impl-c'", message)

    def test_paired_review_must_be_ready_and_auto_dispatchable(self):
        self.add_packet("impl-ready", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-ready")
        self.add_packet(
            "review-impl-ready", status="draft", dispatch_value="manual", kind="review", review="none",
            depends="impl-ready", review_target_workstream="impl-ready",
            review_target_packet=archived_target("impl-ready"),
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        message = errors.get("impl-ready", "")
        self.assertIn("must declare Status: ready", message)
        self.assertIn("must declare Dispatch: auto", message)
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid review pairing", rendered)
        self.assertNotIn("impl-ready", rendered.split("READY (", 1)[1].split("CLAIMED (", 1)[0])

    def test_paired_review_target_packet_must_be_exact_canonical_archive_path(self):
        self.add_packet("impl-target", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-target")
        self.add_packet(
            "review-impl-target", dispatch_value="auto", kind="review", review="none",
            depends="impl-target", review_target_workstream="impl-target",
            review_target_packet=f"{dispatch.PACKET_ROOT}/archived/../IMPL_TARGET.md",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn(
            f"Review target packet must be '{archived_target('impl-target')}'",
            errors.get("impl-target", ""),
        )
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid review pairing", rendered)

    def test_paired_review_missing_target_packet_fails_closed(self):
        self.add_packet("impl-no-target", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-no-target")
        self.add_packet(
            "review-impl-no-target", dispatch_value="auto", kind="review", review="none",
            depends="impl-no-target", review_target_workstream="impl-no-target",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn("Review target packet must be", errors.get("impl-no-target", ""))

    def test_review_blocked_until_implementation_dependency_complete(self):
        self.add_packet("impl-d", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-d")
        self.add_packet(
            "review-impl-d", dispatch_value="auto", kind="review", review="none",
            depends="impl-d", review_target_workstream="impl-d", review_target_packet=archived_target("impl-d"),
        )
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("review-impl-d (review of impl-d) — dependency: impl-d", rendered)

    def test_review_eligible_when_implementation_archived_complete(self):
        # The implementation already completed and archived; only its review
        # remains an active packet, exactly like a real post-land review.
        self.add_packet(
            "review-impl-e", dispatch_value="auto", kind="review", review="none",
            depends="impl-e", review_target_workstream="impl-e", review_target_packet=archived_target("impl-e"),
        )
        self.add_packet("impl-e", status="complete", archived=True)
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("review-impl-e", rendered.split("READY (", 1)[1])

    def test_auto_review_missing_bounded_override_is_rejected_before_claim(self):
        self.add_packet(
            "review-no-override", dispatch_value="auto", kind="review", review="none",
            depends="reviewed-impl", review_target_workstream="reviewed-impl",
            review_target_packet=archived_target("reviewed-impl"), task_overrides="none",
        )
        self.add_packet("reviewed-impl", status="complete", archived=True)
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn("bounded TASK OVERRIDE", errors.get("review-no-override", ""))
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid review pairing", rendered)
        self.assertIn("review-no-override", rendered.split("BLOCKED (", 1)[1])
        with self.assertRaisesRegex(dispatch.DispatchError, "bounded TASK OVERRIDE"):
            dispatch.claim(self.repo, "review-no-override", "codex", False)

    def test_auto_review_malformed_override_cannot_edit_reviewed_code(self):
        self.add_packet(
            "review-bad-override", dispatch_value="auto", kind="review", review="none",
            depends="reviewed-impl", review_target_workstream="reviewed-impl",
            review_target_packet=archived_target("reviewed-impl"),
            task_overrides="TASK OVERRIDE: review receipt and closing summary only.",
        )
        self.add_packet("reviewed-impl", status="complete", archived=True)
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        message = errors.get("review-bad-override", "")
        self.assertIn("malformed bounded TASK OVERRIDE", message)

    def test_wrapped_canonical_override_is_structurally_accepted(self):
        first, second = dispatch.BOUNDED_REVIEW_OVERRIDE.split("its required", 1)
        content = (
            packet(
                "review-wrapped-override", dispatch_value="auto", kind="review", review="none",
                depends="reviewed-impl", review_target_workstream="reviewed-impl",
                review_target_packet=archived_target("reviewed-impl"), task_overrides="none",
            ).replace("- Task overrides: `none`\n", "")
        )
        content += "- Task overrides: `" + first + "\n  its required" + second + "`\n"
        parsed = dispatch.parse_packet("wrapped.md", content)
        self.assertEqual(parsed.task_overrides, dispatch.BOUNDED_REVIEW_OVERRIDE)
        self.assertIsNone(dispatch._bounded_review_override_error(parsed.task_overrides))

    def test_stale_validation_script_blocks_ready_packet_with_replacement(self):
        script = self.repo / "custodian/tools/agent/agent_workflow_smoke.py"
        script.parent.mkdir(parents=True, exist_ok=True)
        script.write_text("# live script\n")
        git(self.repo, "add", str(script.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "add live validation script")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        content = packet("stale-validation", dispatch_value="auto") + (
            "\n## Validation\n\nRun `python3 custodian/tools/agent/agent_workflow_contract_smoke.py`.\n"
        )
        self.add_packet("stale-validation", dispatch_value="auto", text=content)
        errors = dispatch.validate_packet_validation_references(self.repo, dispatch._packets(self.repo))
        message = errors["stale-validation"]
        self.assertIn("custodian/tools/agent/agent_workflow_contract_smoke.py", message)
        self.assertIn("custodian/tools/agent/agent_workflow_smoke.py", message)
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("invalid validation references", rendered)
        with self.assertRaisesRegex(dispatch.DispatchError, "nearest live path"):
            dispatch.claim(self.repo, "stale-validation", "codex", True)

    def test_header_validation_field_paths_are_checked(self):
        content = packet("header-validation", dispatch_value="auto") + (
            "\n- Validation: Run `python3 custodian/tools/agent/not_here.py`.\n"
        )
        parsed = dispatch.parse_packet("packet.md", content)
        self.assertEqual(parsed.validation_scripts, ("custodian/tools/agent/not_here.py",))

    def test_passed_receipt_does_not_require_correction_packet(self):
        self.add_packet("impl-f", dispatch_value="auto", review="auto", paired_review_workstream="review-impl-f")
        self.add_packet(
            "review-impl-f", dispatch_value="auto", kind="review", review="none",
            depends="impl-f", review_target_workstream="impl-f", review_target_packet=archived_target("impl-f"),
        )
        self.assertEqual(dispatch.validate_review_pairing(dispatch._packets(self.repo)), {})

    def test_correction_packet_uses_ordinary_dispatcher_pairing(self):
        # A correction is just another Review: auto packet using the same
        # generic Depends on / Locks / paired-review machinery, per the
        # packet's own "do not build a second scheduler" instruction.
        self.add_packet(
            "impl-g-review-corrections-1", dispatch_value="auto", kind="correction", priority="P0",
            depends="review-impl-g", review="auto",
            paired_review_workstream="review-impl-g-review-corrections-1",
        )
        self.add_packet(
            "review-impl-g-review-corrections-1", dispatch_value="auto", kind="review", review="none",
            depends="impl-g-review-corrections-1", review_target_workstream="impl-g-review-corrections-1",
            review_target_packet=archived_target("impl-g-review-corrections-1"),
            review_cycle=1,
        )
        self.add_packet("review-impl-g", status="complete", archived=True)
        rendered = dispatch.status(self.repo, output=False)
        self.assertIn("impl-g-review-corrections-1 (correction)", rendered.split("READY (", 1)[1])
        self.assertEqual(dispatch.validate_review_pairing(dispatch._packets(self.repo)), {})

    def test_correction_paired_review_is_itself_validated(self):
        # The correction's own Review: auto pairing is checked with the exact
        # same rule as any implementation packet's, proving no special case.
        self.add_packet(
            "impl-h-review-corrections-1", dispatch_value="auto", kind="correction",
            depends="review-impl-h", review="auto",
            paired_review_workstream="review-impl-h-review-corrections-1",
        )
        errors = dispatch.validate_review_pairing(dispatch._packets(self.repo))
        self.assertIn("no matching active packet", errors.get("impl-h-review-corrections-1", ""))

    def test_review_cycle_parses_and_increments(self):
        self.add_packet(
            "review-impl-i-review-corrections-2", dispatch_value="auto", kind="review", review="none",
            depends="impl-i-review-corrections-2", review_target_workstream="impl-i-review-corrections-2",
            review_cycle=2, max_review_cycles=2,
        )
        packets = dispatch._packets(self.repo)
        p = next(p for p in packets if p.workstream == "review-impl-i-review-corrections-2")
        self.assertEqual(p.review_cycle, 2)
        self.assertEqual(p.max_review_cycles, 2)

    def test_max_review_cycle_reports_exhausted_for_escalation(self):
        self.add_packet(
            "review-impl-j-review-corrections-2", dispatch_value="auto", kind="review", review="none",
            depends="impl-j-review-corrections-2", review_target_workstream="impl-j-review-corrections-2",
            review_cycle=2, max_review_cycles=2,
        )
        self.add_packet(
            "review-impl-k", dispatch_value="auto", kind="review", review="none",
            depends="impl-k", review_target_workstream="impl-k",
            review_cycle=0, max_review_cycles=2,
        )
        packets = {p.workstream: p for p in dispatch._packets(self.repo)}
        self.assertTrue(dispatch.review_cycle_exhausted(packets["review-impl-j-review-corrections-2"]))
        self.assertFalse(dispatch.review_cycle_exhausted(packets["review-impl-k"]))

    def test_invalid_review_pairing_blocks_explicit_claim_until_fixed(self):
        path = self.add_packet("impl-guarded", dispatch_value="auto", review="auto")
        with self.assertRaisesRegex(dispatch.DispatchError, "Review: auto requires a Paired review workstream"):
            dispatch.claim(self.repo, "impl-guarded", "codex", False)

        path.write_text(packet(
            "impl-guarded", dispatch_value="auto", review="auto",
            paired_review_workstream="review-impl-guarded",
        ))
        git(self.repo, "add", str(path.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "fix pairing")
        git(self.repo, "push", "origin", "main")
        self.add_packet(
            "review-impl-guarded", dispatch_value="auto", kind="review", review="none",
            depends="impl-guarded", review_target_workstream="impl-guarded",
            review_target_packet=archived_target("impl-guarded"),
        )
        fake = mock.Mock(); fake.start.side_effect = publish_workstream
        with mock.patch.object(dispatch, "_load_workstream", return_value=fake), mock.patch("builtins.print"):
            result = dispatch.claim(self.repo, "impl-guarded", "codex", False)
        self.assertEqual(result, 0)


if __name__ == "__main__":
    unittest.main()
