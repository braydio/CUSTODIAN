"""Isolated Git and Git LFS tests for the turn-scoped dispatcher."""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from custodian.tools.agent import turn_dispatcher_v2 as td


def run(*args, cwd=None, env=None, check=True):
    proc = subprocess.run(args, cwd=cwd, env=env, check=check, text=True,
                          capture_output=True)
    return proc.stdout.strip()


class TurnDispatcherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="custodian-turn-v2-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.origin = self.base / "origin.git"
        self.repo = self.base / "repo"
        run("git", "init", "--bare", str(self.origin))
        run("git", "init", "-b", "main", str(self.repo))
        run("git", "config", "user.name", "Test", cwd=self.repo)
        run("git", "config", "user.email", "test@example.com", cwd=self.repo)
        packets = self.repo / "custodian/docs/ai_context/task_packets"
        packets.mkdir(parents=True)
        self.packet = packets / "EXAMPLE.md"
        self.packet.write_text(
            "- Workstream: example-task\n- Status: draft\n- Dispatch: manual\n"
            "- Depends on: blocked-predecessor\n- Locks: legacy-lock\n"
            "\n## Handoff\n- Workstream: unrelated-body-value\n"
            "- Authoring chat: repeated-body-value\n", encoding="utf-8")
        (self.repo / "cache_input.py").write_text("value = 42\n", encoding="utf-8")
        (self.repo / ".gitignore").write_text(".godot/\nevidence_local/\n__pycache__/\n", encoding="utf-8")
        run("git", "add", ".", cwd=self.repo)
        run("git", "commit", "-m", "baseline", cwd=self.repo)
        run("git", "remote", "add", "origin", str(self.origin), cwd=self.repo)
        run("git", "push", "-u", "origin", "main", cwd=self.repo)

    def test_normal_selection_ignores_legacy_status_locks_and_dependencies(self):
        result = td.inspect(self.repo, "example-task", "normal")
        self.assertEqual(result["branch"], "agent/example-task")
        self.assertIsNone(result["remote_head"])
        self.assertIn("v2-identity", result["selection_policy"])

    def test_historical_selection_uses_same_v2_readiness(self):
        result = td.inspect(self.repo, "example-task", "historical")
        self.assertEqual(result["mode"], "historical")
        self.assertIsNone(result["remote_head"])

    def test_historical_mode_rehydrates_exact_existing_remote_commit(self):
        (self.repo / "historical.py").write_text("prior work\n", encoding="utf-8")
        run("git", "add", "historical.py", cwd=self.repo)
        run("git", "commit", "-m", "historical checkpoint", cwd=self.repo)
        source_sha = run("git", "rev-parse", "HEAD", cwd=self.repo)
        run("git", "push", "origin", f"{source_sha}:refs/heads/agent/example-task", cwd=self.repo)
        result = td.begin(self.repo, "example-task", "historical", self.base / "historical-turns")
        checkout = Path(result["checkout"])
        self.assertEqual(result["source"], "agent/example-task")
        self.assertEqual(result["source_sha"], source_sha)
        self.assertFalse(result["source_is_ancestor_of_current_main"])
        self.assertTrue(result["current_main_is_ancestor_of_source"])
        self.assertEqual((checkout / "historical.py").read_text(encoding="utf-8"), "prior work\n")
        receipt = json.loads(Path(result["acquisition_receipt"]).read_text(encoding="utf-8"))
        self.assertEqual(receipt["source_sha"], source_sha)
        run("git", "worktree", "remove", str(checkout), cwd=self.repo)
        run("git", "update-ref", "-d", f"refs/heads/{result['local_branch']}", source_sha, cwd=self.repo)

    def test_explicit_unresolved_user_design_hold_blocks_both_modes(self):
        content = self.packet.read_text(encoding="utf-8")
        self.packet.write_text(content.replace("- Locks: legacy-lock\n", "- Locks: legacy-lock\n- User design hold: unresolved\n"),
                               encoding="utf-8")
        run("git", "add", ".", cwd=self.repo)
        run("git", "commit", "-m", "record design hold", cwd=self.repo)
        run("git", "push", "origin", "main", cwd=self.repo)
        for mode in ("normal", "historical"):
            with self.subTest(mode=mode), self.assertRaisesRegex(td.DispatchError, "user-owned"):
                td.inspect(self.repo, "example-task", mode)

    def test_packet_bytes_are_read_from_authenticated_origin_main(self):
        self.packet.write_text("- Workstream: wrong-local-identity\n", encoding="utf-8")
        result = td.inspect(self.repo, "example-task", "normal")
        self.assertTrue(result["packet"].endswith("EXAMPLE.md"))
        self.assertEqual(result["task_definition_sha"], run("git", "rev-parse", "origin/main", cwd=self.repo))

    def test_owner_authorized_new_work_requires_conversation_and_exact_instruction_digest(self):
        with self.assertRaisesRegex(td.DispatchError, "authorization URL"):
            td.inspect(self.repo, "new-owner-task", "owner-authorized")
        with self.assertRaisesRegex(td.DispatchError, "exact ChatGPT"):
            td.inspect(self.repo, "new-owner-task", "owner-authorized", "https://example.com/c/1", "a" * 64)
        with self.assertRaisesRegex(td.DispatchError, "exact ChatGPT"):
            td.inspect(self.repo, "new-owner-task", "owner-authorized", "https://chatgpt.com/g/g-test/c/", "a" * 64)
        with self.assertRaisesRegex(td.DispatchError, "lowercase SHA-256"):
            td.inspect(self.repo, "new-owner-task", "owner-authorized", "https://chatgpt.com/g/g-test/c/owner-auth", "A" * 64)
        result = td.inspect(self.repo, "new-owner-task", "owner-authorized",
                            "https://chatgpt.com/g/g-test/c/owner-auth", "a" * 64)
        self.assertEqual(result["definition_kind"], "missing")
        self.assertEqual(result["owner_authorization"]["instruction_sha256"], "a" * 64)
        self.assertFalse(result["owner_authorization"]["identity_verified"])

    def test_owner_authorized_new_work_acquires_and_checkpoints_with_provenance(self):
        auth_url = "https://chatgpt.com/g/g-test/c/owner-auth"
        digest = "b" * 64
        result = td.begin(self.repo, "new-owner-task", "owner-authorized", self.base / "owner-turns",
                          auth_url, digest)
        checkout = Path(result["checkout"])
        run("git", "config", "user.name", "Test", cwd=checkout)
        run("git", "config", "user.email", "test@example.com", cwd=checkout)
        (checkout / "owner_work.py").write_text("print('authorized')\n", encoding="utf-8")
        receipt = json.loads(Path(result["acquisition_receipt"]).read_text(encoding="utf-8"))
        self.assertEqual(receipt["definition_kind"], "missing")
        self.assertEqual(receipt["owner_authorization"]["reference"], auth_url)
        output = td.checkpoint(self.repo, "new-owner-task", checkout, self.handoff(),
                               "owner-authorized checkpoint", self.base / "owner-turns")
        self.assertTrue(output["retired"])
        branch_text = run("git", "--git-dir", str(self.origin), "show",
                          f"{output['branch']}:custodian/docs/ai_context/turn_handoffs/new-owner-task.md")
        self.assertIn(f"owner-authorized:{auth_url}#sha256={digest}", branch_text)
        self.assertEqual(td.remote_branch(self.repo, "agent/new-owner-task"), output["head"])

    def test_owner_authorized_checkpoint_requires_reacquisition_if_packet_is_published(self):
        result = td.begin(self.repo, "new-owner-task", "owner-authorized", self.base / "owner-turns",
                          "https://chatgpt.com/g/g-test/c/owner-auth", "c" * 64)
        checkout = Path(result["checkout"])
        run("git", "config", "user.name", "Test", cwd=checkout)
        run("git", "config", "user.email", "test@example.com", cwd=checkout)
        packets = self.repo / "custodian/docs/ai_context/task_packets"
        (packets / "NEW_OWNER.md").write_text("- Workstream: new-owner-task\n- Status: draft\n", encoding="utf-8")
        run("git", "add", ".", cwd=self.repo)
        run("git", "commit", "-m", "publish owner task definition", cwd=self.repo)
        run("git", "push", "origin", "main", cwd=self.repo)
        with self.assertRaisesRegex(td.DispatchError, "appeared after owner-authorized"):
            td.checkpoint(self.repo, "new-owner-task", checkout, self.handoff(),
                          "blocked checkpoint", self.base / "owner-turns")
        self.assertTrue(checkout.exists())

    def test_ambiguous_published_packet_identity_fails_closed(self):
        packets = self.repo / "custodian/docs/ai_context/task_packets"
        (packets / "DUPLICATE.md").write_text("- Workstream: example-task\n- Status: draft\n", encoding="utf-8")
        run("git", "add", ".", cwd=self.repo)
        run("git", "commit", "-m", "ambiguous task identity", cwd=self.repo)
        run("git", "push", "origin", "main", cwd=self.repo)
        with self.assertRaisesRegex(td.DispatchError, "ambiguous authenticated"):
            td.inspect(self.repo, "example-task", "owner-authorized",
                       "https://chatgpt.com/g/g-test/c/owner-auth", "d" * 64)

    def test_missing_historical_branch_starts_fresh_from_main(self):
        result = td.begin(self.repo, "example-task", "historical", self.base / "turns")
        self.assertTrue(result["source"].startswith("origin/main"))
        self.assertEqual(result["source_sha"], run("git", "rev-parse", "origin/main", cwd=self.repo))
        checkout = Path(result["checkout"])
        self.assertTrue(checkout.is_dir())
        self.assertEqual(run("git", "-C", str(checkout), "rev-parse", "HEAD"), result["source_sha"])
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), result["source_sha"])

    def test_historical_branch_diverged_from_main_is_reused_and_marked(self):
        main_sha = run("git", "rev-parse", "HEAD", cwd=self.repo)
        run("git", "checkout", "--orphan", "historical-root", cwd=self.repo)
        run("git", "rm", "-rf", ".", cwd=self.repo)
        (self.repo / "historical_only.py").write_text("preserve history\n", encoding="utf-8")
        run("git", "add", "historical_only.py", cwd=self.repo)
        run("git", "commit", "-m", "divergent historical base", cwd=self.repo)
        old_sha = run("git", "rev-parse", "HEAD", cwd=self.repo)
        run("git", "push", "origin", f"{old_sha}:refs/heads/agent/example-task", cwd=self.repo)
        run("git", "checkout", "main", cwd=self.repo)
        result = td.begin(self.repo, "example-task", "historical", self.base / "diverged-turns")
        self.assertEqual(result["source_sha"], old_sha)
        self.assertFalse(result["source_is_ancestor_of_current_main"])
        self.assertFalse(result["current_main_is_ancestor_of_source"])
        self.assertEqual(run("git", "rev-parse", "origin/main", cwd=self.repo), main_sha)
        self.assertTrue((Path(result["checkout"]) / "historical_only.py").is_file())
        checkout = Path(result["checkout"])
        run("git", "worktree", "remove", str(checkout), cwd=self.repo)
        run("git", "update-ref", "-d", f"refs/heads/{result['local_branch']}", old_sha, cwd=self.repo)

    def test_missing_historical_lfs_data_blocks_without_fallback(self):
        base = run("git", "rev-parse", "HEAD", cwd=self.repo)
        run("git", "push", "origin", f"{base}:refs/heads/agent/example-task", cwd=self.repo)
        with patch.object(td, "hydrate_and_verify_lfs",
                          side_effect=td.DispatchError("historical LFS object unavailable")):
            with self.assertRaisesRegex(td.DispatchError, "checkout retained") as caught:
                td.begin(self.repo, "example-task", "historical", self.base / "turns")
        receipt_path = Path(str(caught.exception).split("receipt ", 1)[1])
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(receipt["source"], "agent/example-task")
        self.assertEqual(receipt["source_sha"], base)
        self.assertIn("required LFS data was not verified", receipt["reason"])
        self.assertTrue(Path(receipt["checkout"]).is_dir())
        self.assertIsNone(td.remote_branch(self.repo, "agent/example-task-recovery-fresh"))

    def turn_checkout(self):
        result = td.begin(self.repo, "example-task", "normal", self.base / "turns")
        checkout = Path(result["checkout"])
        run("git", "config", "user.name", "Test", cwd=checkout)
        run("git", "config", "user.email", "test@example.com", cwd=checkout)
        return result, checkout

    def handoff(self):
        path = self.base / "handoff.md"
        path.write_text("Original goal: demo\nImplemented: demo\nRemaining: none\n"
                        "Validation: isolated tests\nSources/evidence: none\n"
                        "Resume: inspect branch and handoff\n",
                        encoding="utf-8")
        return path

    def test_checkpoint_publishes_handoff_and_retires_exact_turn(self):
        result, checkout = self.turn_checkout()
        (checkout / "source.py").write_text("print('durable')\n", encoding="utf-8")
        import py_compile
        import importlib.util
        cache_source = checkout / "cache_input.py"
        cache = Path(importlib.util.cache_from_source(str(cache_source)))
        cache.parent.mkdir()
        py_compile.compile(str(cache_source), cfile=str(cache), doraise=True)
        output = td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                               "turn checkpoint", self.base / "turns")
        self.assertTrue(output["retired"])
        self.assertFalse(checkout.exists())
        retirement = json.loads(Path(output["retirement_receipt"]).read_text(encoding="utf-8"))
        self.assertEqual(retirement["status"], "retired")
        self.assertEqual(Path(output["retirement_receipt"]).stat().st_mode & 0o777, 0o600)
        again = td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                              "retry retirement", self.base / "turns")
        self.assertTrue(again["idempotent"])
        self.assertEqual(again["head"], output["head"])
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), output["head"])
        names = run("git", "--git-dir", str(self.origin), "ls-tree", "-r", "--name-only",
                    "refs/heads/agent/example-task")
        self.assertIn("source.py", names)
        self.assertIn("turn_handoffs/example-task.md", names)
        receipt = json.loads(Path(output["receipt"]).read_text(encoding="utf-8"))
        self.assertEqual(receipt["status"], "published")
        self.assertEqual(Path(output["receipt"]).stat().st_mode & 0o777, 0o600)
        self.assertIn(cache.relative_to(checkout).as_posix(), receipt["ignored_disposable"])
        handoff = run("git", "--git-dir", str(self.origin), "show",
                      "refs/heads/agent/example-task:custodian/docs/ai_context/turn_handoffs/example-task.md")
        self.assertIn("Acquisition source: origin/main (no prior branch; fresh start)", handoff)
        self.assertIn("Acquisition source commit:", handoff)
        resumed = json.loads(run("python3", str(Path(td.__file__)), "--repo", str(self.repo),
                                 "--pool", str(self.base / "turns"), "begin", "example-task",
                                 "--mode", "normal"))
        self.assertEqual(resumed["source_sha"], output["head"])
        self.assertEqual(resumed["source"], "agent/example-task")
        resumed_checkout = Path(resumed["checkout"])
        resumed_sha = run("git", "-C", str(resumed_checkout), "rev-parse", "HEAD")
        run("git", "worktree", "remove", str(resumed_checkout), cwd=self.repo)
        run("git", "update-ref", "-d", f"refs/heads/{resumed['local_branch']}", resumed_sha, cwd=self.repo)

    def test_checkpoint_retries_after_crash_beneath_exact_checkout_removal(self):
        result, checkout = self.turn_checkout()
        (checkout / "durable.py").write_text("verified\n", encoding="utf-8")
        original_git = td.git
        interrupted = False

        def fail_after_remove(repo, *args, **kwargs):
            nonlocal interrupted
            value = original_git(repo, *args, **kwargs)
            if not interrupted and args[:2] == ("worktree", "remove"):
                interrupted = True
                raise td.DispatchError("injected crash after checkout removal")
            return value

        with patch.object(td, "git", side_effect=fail_after_remove):
            with self.assertRaisesRegex(td.DispatchError, "injected crash"):
                td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                              "interrupted retirement", self.base / "turns")
        self.assertFalse(checkout.exists())
        resumed = td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                                "retry after retirement", self.base / "turns")
        self.assertTrue(resumed["idempotent"])
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), resumed["head"])
        local_ref = subprocess.run(["git", "-C", str(self.repo), "show-ref", "--verify", "--quiet",
                                    f"refs/heads/{result['local_branch']}"], capture_output=True)
        self.assertNotEqual(local_ref.returncode, 0)

    def test_non_force_first_branch_creation_preserves_racing_writer(self):
        other = self.base / "other"
        run("git", "clone", str(self.origin), str(other))
        run("git", "config", "user.name", "Other", cwd=other)
        run("git", "config", "user.email", "other@example.com", cwd=other)
        run("git", "checkout", "-b", "other-writer", "origin/main", cwd=other)
        (other / "racing.py").write_text("winner\n", encoding="utf-8")
        run("git", "add", "racing.py", cwd=other)
        run("git", "commit", "-m", "racing writer", cwd=other)
        winner = run("git", "rev-parse", "HEAD", cwd=other)
        original_git = td.git
        raced = False

        def race(repo, *args, **kwargs):
            nonlocal raced
            if not raced and args[:2] == ("push", "origin") and str(args[-1]).endswith(
                    "refs/heads/agent/example-task"):
                raced = True
                run("git", "push", "origin", "HEAD:refs/heads/agent/example-task", cwd=other)
            return original_git(repo, *args, **kwargs)

        with patch.object(td, "git", side_effect=race):
            with self.assertRaisesRegex(td.DispatchError, "git push origin"):
                td.begin(self.repo, "example-task", "normal", self.base / "turns")
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), winner)
        self.assertEqual(len(td.attached(self.repo)), 1)

    def test_unknown_ignored_data_retains_checkout_with_machine_receipt(self):
        _, checkout = self.turn_checkout()
        evidence = checkout / "evidence_local/capture.bin"
        evidence.parent.mkdir()
        evidence.write_bytes(b"unique evidence")
        with self.assertRaisesRegex(td.DispatchError, "receipt") as caught:
            td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                          "turn checkpoint", self.base / "turns")
        self.assertTrue(checkout.exists())
        receipt_path = Path(str(caught.exception).split("receipt ", 1)[1])
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(receipt["status"], "blocked")
        self.assertIn("evidence_local/capture.bin", receipt["ignored_unresolved"])

    def test_ignored_directory_name_does_not_make_unknown_content_disposable(self):
        cache = self.repo / ".godot/cache.bin"
        cache.parent.mkdir()
        cache.write_bytes(b"unknown unique bytes")
        disposable, unresolved = td.classify_ignored(self.repo)
        self.assertEqual(disposable, [])
        self.assertEqual(unresolved, [".godot/cache.bin"])

    def test_verified_python_bytecode_is_classified_by_contents_and_source(self):
        import py_compile
        import importlib.util
        source = self.repo / "module.py"
        source.write_text("value = 42\n", encoding="utf-8")
        (self.repo / ".gitignore").write_text("__pycache__/\n", encoding="utf-8")
        run("git", "add", ".gitignore", "module.py", cwd=self.repo)
        run("git", "commit", "-m", "tracked source", cwd=self.repo)
        cache = Path(importlib.util.cache_from_source(str(source)))
        cache.parent.mkdir()
        py_compile.compile(str(source), cfile=str(cache), doraise=True)
        disposable, unresolved = td.classify_ignored(self.repo)
        self.assertEqual(disposable, [cache.relative_to(self.repo).as_posix()])
        self.assertEqual(unresolved, [])

    def test_secret_untracked_path_blocks_before_staging(self):
        _, checkout = self.turn_checkout()
        (checkout / ".env").write_text("TOKEN=private\n", encoding="utf-8")
        with self.assertRaisesRegex(td.DispatchError, "potential secrets"):
            td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                          "turn checkpoint", self.base / "turns")
        self.assertTrue((checkout / ".env").exists())
        self.assertFalse(run("git", "-C", str(checkout), "diff", "--cached", "--name-only"))

    def test_missing_handoff_field_blocks(self):
        _, checkout = self.turn_checkout()
        bad = self.base / "bad-handoff.md"
        bad.write_text("Original goal: x\nRemaining: y\n", encoding="utf-8")
        with self.assertRaisesRegex(td.DispatchError, "Implemented"):
            td.checkpoint(self.repo, "example-task", checkout, bad,
                          "turn checkpoint", self.base / "turns")

    def test_non_fast_forward_concurrent_writer_is_not_overwritten(self):
        _, checkout = self.turn_checkout()
        (checkout / "source.py").write_text("ours\n", encoding="utf-8")
        # Publish an independent commit from the same base before this turn pushes.
        other = self.base / "other"
        run("git", "clone", str(self.origin), str(other))
        run("git", "config", "user.name", "Other", cwd=other)
        run("git", "config", "user.email", "other@example.com", cwd=other)
        run("git", "checkout", "-b", "other-writer", "origin/main", cwd=other)
        (other / "other.py").write_text("theirs\n", encoding="utf-8")
        run("git", "add", "other.py", cwd=other)
        run("git", "commit", "-m", "other writer", cwd=other)
        other_sha = run("git", "rev-parse", "HEAD", cwd=other)
        run("git", "push", "origin", "HEAD:refs/heads/agent/example-task", cwd=other)
        with self.assertRaisesRegex(td.DispatchError, "not verified"):
            td.checkpoint(self.repo, "example-task", checkout, self.handoff(),
                          "turn checkpoint", self.base / "turns")
        self.assertTrue(checkout.exists())
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), other_sha)

    def test_remote_sha_verification_failure_retains_published_checkout(self):
        _, checkout = self.turn_checkout()
        handoff = self.handoff()
        with patch.object(td, "remote_branch", return_value=None):
            with self.assertRaisesRegex(td.DispatchError, "checkout retained"):
                td.checkpoint(self.repo, "example-task", checkout, handoff,
                              "turn checkpoint", self.base / "turns")
        self.assertTrue(checkout.exists())
        head = td.git(checkout, "rev-parse", "HEAD")
        self.assertEqual(td.remote_branch(self.repo, "agent/example-task"), head)

    def test_lfs_checkout_failure_writes_receipt_and_retains_new_checkout(self):
        with patch.object(td, "hydrate_and_verify_lfs", side_effect=td.DispatchError("simulated interrupted hydration")):
            with self.assertRaisesRegex(td.DispatchError, "checkout retained") as caught:
                td.begin(self.repo, "example-task", "normal", self.base / "turns")
        receipt_text = str(caught.exception).split("receipt ", 1)[1]
        receipt = json.loads(Path(receipt_text).read_text(encoding="utf-8"))
        checkout = Path(receipt["checkout"])
        self.assertTrue(checkout.is_dir())
        self.assertEqual(receipt["status"], "blocked")

    @unittest.skipUnless(shutil.which("git-lfs"), "Git LFS is not installed")
    def test_real_lfs_pointer_and_local_object_are_verified(self):
        run("git", "lfs", "install", "--local", cwd=self.repo)
        run("git", "lfs", "track", "*.bin", cwd=self.repo)
        source = self.repo / "material.bin"
        source.write_bytes(b"verified LFS payload" * 64)
        run("git", "add", ".gitattributes", "material.bin", cwd=self.repo)
        run("git", "commit", "-m", "add LFS source", cwd=self.repo)
        run("git", "lfs", "push", "origin", "main", cwd=self.repo)
        run("git", "push", "origin", "HEAD:refs/heads/main", cwd=self.repo,
            env={**os.environ, "GIT_LFS_SKIP_PUSH": "1"})
        restored = self.base / "fresh-clone"
        run("git", "clone", str(self.origin), str(restored))
        run("git", "lfs", "install", "--local", cwd=restored)
        run("git", "lfs", "fetch", "origin", "HEAD", cwd=restored)
        run("git", "lfs", "checkout", cwd=restored)
        self.assertEqual((restored / "material.bin").read_bytes(), source.read_bytes())
        checkout, local_branch = td.make_turn_checkout(
            self.repo, "example-task", "agent/example-task", run("git", "rev-parse", "HEAD", cwd=self.repo),
            self.base / "lfs-turns")
        try:
            run("git", "config", "user.name", "Test", cwd=checkout)
            run("git", "config", "user.email", "test@example.com", cwd=checkout)
            listed = td.hydrate_and_verify_lfs(checkout)
            self.assertTrue(any("material.bin" in line for line in listed))
            self.assertEqual((checkout / "material.bin").read_bytes(), source.read_bytes())
        finally:
            run("git", "worktree", "remove", str(checkout), cwd=self.repo)
            run("git", "update-ref", "-d", f"refs/heads/{local_branch}", run("git", "rev-parse", "HEAD", cwd=self.repo), cwd=self.repo)

    @unittest.skipUnless(shutil.which("git-lfs"), "Git LFS is not installed")
    def test_missing_lfs_object_fails_verification(self):
        run("git", "lfs", "install", "--local", cwd=self.repo)
        run("git", "lfs", "track", "*.bin", cwd=self.repo)
        source = self.repo / "missing.bin"
        source.write_bytes(b"local-only LFS payload" * 64)
        run("git", "add", ".gitattributes", "missing.bin", cwd=self.repo)
        run("git", "commit", "-m", "add local LFS pointer", cwd=self.repo)
        listing = run("git", "lfs", "ls-files", "--long", cwd=self.repo)
        oid = listing.split()[0]
        object_path = self.repo / ".git/lfs/objects" / oid[:2] / oid[2:4] / oid
        self.assertTrue(object_path.is_file())
        object_path.unlink()
        source.unlink()
        self.assertFalse(object_path.exists())
        self.assertTrue(td.lfs_files(self.repo))
        with self.assertRaises(td.DispatchError):
            td.hydrate_and_verify_lfs(self.repo)


if __name__ == "__main__":
    unittest.main(verbosity=2)
