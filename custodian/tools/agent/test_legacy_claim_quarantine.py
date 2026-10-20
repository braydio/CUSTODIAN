"""Temporary-remote tests for preservation-first legacy claim quarantine."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("legacy_claim_quarantine.py")
SPEC = importlib.util.spec_from_file_location("legacy_claim_quarantine_tests", SCRIPT)
quarantine = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = quarantine
SPEC.loader.exec_module(quarantine)


def git(cwd: Path, *args: str, input_text: str | None = None, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, input=input_text, text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


class LegacyClaimQuarantineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.remote = self.root / "remote.git"
        self.repo = self.root / "repo"
        git(self.root, "init", "--bare", str(self.remote))
        git(self.root, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Quarantine test")
        git(self.repo, "config", "user.email", "quarantine@example.test")
        (self.repo / "base.txt").write_text("base\n")
        (self.repo / ".gitignore").write_text("ignored.bin\n")
        git(self.repo, "add", "base.txt", ".gitignore")
        git(self.repo, "commit", "-m", "base")
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")
        self.workstream = "stranded-review"
        self.claim_sha = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "push", "origin", f"{self.claim_sha}:refs/heads/dispatch-claims/{self.workstream}")
        git(self.repo, "fetch", "origin")

    def tearDown(self):
        self.temp.cleanup()

    def _snapshot(self, *workstreams: str) -> Path:
        output = quarantine.snapshot(self.repo, list(workstreams or [self.workstream]), self.root / "backup")
        self.assertEqual(quarantine.verify_snapshot(Path(output["path"]))["schema"], "custodian.execution_reset_backup.v1")
        return Path(output["path"])

    def test_quarantine_preserves_claim_and_never_turns_into_review_acceptance(self):
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, None, manifest)
        self.assertFalse(plan["lock_released"])
        record_sha = quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])
        self.assertEqual(quarantine.git(self.repo, "ls-remote", "--heads", "origin", plan["claim_ref"]).split()[0], self.claim_sha)
        state = quarantine.dispatcher_state(self.repo, self.workstream, self.claim_sha, None)
        self.assertEqual(state["state"], "legacy_quarantined")
        self.assertFalse(state["lock_released"])
        self.assertEqual(state["record_sha"], record_sha)
        record = json.loads(quarantine.git(self.repo, "show", f"{record_sha}:quarantine.json"))
        self.assertEqual(record["state"], "legacy_quarantined")
        self.assertNotIn("outcome", record)
        self.assertEqual(quarantine.git(self.repo, "rev-parse", f"refs/remotes/origin/dispatch-claims/{self.workstream}"), self.claim_sha)

    def test_stale_plan_and_changed_claim_ref_fail_closed(self):
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, None, manifest)
        new_claim = git(self.repo, "commit-tree", git(self.repo, "rev-parse", "origin/main^{tree}"), "-p", self.claim_sha,
                        "-m", "changed claim")
        git(self.repo, "push", "origin", f"{new_claim}:refs/heads/dispatch-claims/{self.workstream}")
        git(self.repo, "fetch", "origin")
        with self.assertRaisesRegex(quarantine.QuarantineError, "refs do not match"):
            quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])
        self.assertFalse(quarantine.git(self.repo, "show-ref", "--verify", quarantine.quarantine_ref(self.workstream), check=False))

    def test_two_clones_cannot_apply_the_same_stale_quarantine_plan(self):
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, None, manifest)
        clone = self.root / "second-clone"
        git(self.root, "clone", str(self.remote), str(clone))
        git(clone, "config", "user.name", "Second operator")
        git(clone, "config", "user.email", "second@example.test")
        git(clone, "fetch", "origin")
        second_plan = quarantine.build_plan(clone, self.workstream, None, manifest)
        self.assertEqual(second_plan["plan_sha256"], plan["plan_sha256"])
        first_record = quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])
        with self.assertRaisesRegex(quarantine.QuarantineError, "changed|already has|atomic quarantine publication failed"):
            quarantine.apply_plan(clone, second_plan, second_plan["plan_sha256"])
        self.assertEqual(quarantine.git(self.repo, "rev-parse", f"refs/remotes/origin/{quarantine.quarantine_ref(self.workstream).removeprefix('refs/')}"), first_record)

    def test_batch_plan_publishes_all_dispositions_in_one_remote_update(self):
        second = "stranded-review-two"
        second_claim = git(self.repo, "rev-parse", "origin/main")
        git(self.repo, "push", "origin", f"{second_claim}:refs/heads/dispatch-claims/{second}")
        git(self.repo, "fetch", "origin")
        manifest = self._snapshot(self.workstream, second)
        plan = quarantine.build_batch_plan(
            self.repo, {self.workstream: None, second: None}, manifest
        )
        commits = quarantine.apply_batch_plan(self.repo, plan, plan["plan_sha256"])
        self.assertEqual(set(commits), {self.workstream, second})
        for workstream in (self.workstream, second):
            claim = quarantine._remote_sha(self.repo, f"refs/heads/dispatch-claims/{workstream}")
            self.assertIsNotNone(claim)
            state = quarantine.dispatcher_state(self.repo, workstream, claim, None)
            self.assertEqual(state["state"], "legacy_quarantined")
            self.assertTrue(state["lock_released"] is False)

    def test_active_owner_is_never_quarantined(self):
        run_id = "20261020T000000Z-active"
        trace = quarantine.common_dir(self.repo) / "custodian-workflow" / "traces" / self.workstream / f"{run_id}.jsonl"
        trace.parent.mkdir(parents=True)
        trace.write_text("\n".join(json.dumps(event) for event in (
            {"event": "run_started", "host": quarantine.socket.gethostname(), "pid": os.getpid(),
             "workstream": self.workstream, "run_id": run_id, "timestamp_utc": "2026-10-20T00:00:00Z"},
            {"event": "remote_claim_acquired", "host": quarantine.socket.gethostname(), "pid": os.getpid(),
             "workstream": self.workstream, "run_id": run_id, "data": {
                 "remote_ref": f"refs/heads/dispatch-claims/{self.workstream}", "claim_oid": self.claim_sha}},
        )) + "\n")
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, run_id, manifest)
        self.assertEqual(plan["owner"]["state"], "active_or_pid_ambiguous")
        with self.assertRaisesRegex(quarantine.QuarantineError, "active or PID-ambiguous"):
            quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])

    def test_exited_run_must_be_bound_to_the_exact_claim(self):
        run_id = "20261020T000001Z-forged-claim"
        trace = quarantine.common_dir(self.repo) / "custodian-workflow" / "traces" / self.workstream / f"{run_id}.jsonl"
        trace.parent.mkdir(parents=True, exist_ok=True)
        trace.write_text("\n".join(json.dumps(event) for event in (
            {"event": "run_started", "host": quarantine.socket.gethostname(), "pid": 99999999,
             "workstream": self.workstream, "run_id": run_id, "timestamp_utc": "2026-10-20T00:00:00Z"},
            {"event": "remote_claim_acquired", "host": quarantine.socket.gethostname(), "pid": 99999999,
             "workstream": self.workstream, "run_id": run_id, "data": {
                 "remote_ref": f"refs/heads/dispatch-claims/{self.workstream}", "claim_oid": "0" * 40}},
        )) + "\n")
        manifest = self._snapshot()
        with self.assertRaisesRegex(quarantine.QuarantineError, "exact remote claim"):
            quarantine.build_plan(self.repo, self.workstream, run_id, manifest)

    def test_missing_remote_claim_ref_preserves_the_run_claim_commit_as_record_ancestry(self):
        path = self.root / "attached"
        git(self.repo, "worktree", "add", "-b", f"agent/{self.workstream}", str(path), "origin/main")
        git(path, "push", "-u", "origin", f"agent/{self.workstream}")
        git(self.repo, "fetch", "origin")
        branch_sha = git(self.repo, "rev-parse", f"refs/remotes/origin/agent/{self.workstream}")
        git(self.repo, "push", "origin", f":refs/heads/dispatch-claims/{self.workstream}")
        run_id = "20261020T000002Z-claim-ref-already-absent"
        trace = quarantine.common_dir(self.repo) / "custodian-workflow" / "traces" / self.workstream / f"{run_id}.jsonl"
        trace.parent.mkdir(parents=True, exist_ok=True)
        trace.write_text("\n".join(json.dumps(event) for event in (
            {"event": "run_started", "host": quarantine.socket.gethostname(), "pid": 999999997,
             "workstream": self.workstream, "run_id": run_id, "timestamp_utc": "2026-10-20T00:00:00Z"},
            {"event": "remote_claim_acquired", "host": quarantine.socket.gethostname(), "pid": 999999997,
             "workstream": self.workstream, "run_id": run_id, "data": {
                 "remote_ref": f"refs/heads/dispatch-claims/{self.workstream}", "claim_oid": self.claim_sha}},
            {"event": "worktree_published", "host": quarantine.socket.gethostname(), "pid": 999999997,
             "workstream": self.workstream, "run_id": run_id, "data": {
                 "branch": f"agent/{self.workstream}", "head": branch_sha, "upstream": branch_sha,
                 "worktree": str(path)}},
        )) + "\n")
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, run_id, manifest)
        self.assertIsNone(plan["claim_sha"])
        self.assertEqual(plan["claim_acquired_sha"], self.claim_sha)
        record_sha = quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])
        record = json.loads(quarantine.git(self.repo, "show", f"{record_sha}:quarantine.json"))
        parents = quarantine.git(self.repo, "show", "-s", "--format=%P", record_sha).split()
        self.assertEqual(record["claim_acquired_sha"], self.claim_sha)
        self.assertIn(self.claim_sha, parents)
        self.assertEqual(quarantine._remote_sha(self.repo, f"refs/heads/agent/{self.workstream}"), branch_sha)
        self.assertIsNone(quarantine._remote_sha(self.repo, f"refs/heads/dispatch-claims/{self.workstream}"))

    def test_cross_generation_and_changed_remote_refs_keep_lock(self):
        manifest = self._snapshot()
        plan = quarantine.build_plan(self.repo, self.workstream, None, manifest)
        record_sha = quarantine.apply_plan(self.repo, plan, plan["plan_sha256"])
        state = quarantine.dispatcher_state(self.repo, self.workstream, self.claim_sha, None)
        self.assertEqual(state["state"], "legacy_quarantined")
        self.assertFalse(state["lock_released"])
        with mock.patch.object(quarantine, "GENERATION", "execution-reset-v2"):
            state = quarantine.dispatcher_state(self.repo, self.workstream, self.claim_sha, None)
        self.assertEqual(state["state"], "invalid")
        self.assertFalse(state["lock_released"])
        self.assertEqual(quarantine.git(self.repo, "rev-parse", f"refs/remotes/origin/{quarantine.quarantine_ref(self.workstream).removeprefix('refs/')}"), record_sha)

    def test_snapshot_contains_untracked_ignored_and_symlink_payload(self):
        agent_path = self.root / "agent-wt"
        git(self.repo, "worktree", "add", "-b", f"agent/{self.workstream}", str(agent_path), "origin/main")
        (agent_path / "untracked.txt").write_text("untracked payload\n")
        (agent_path / "ignored.bin").write_bytes(b"ignored source payload")
        (agent_path / "source-link").symlink_to("untracked.txt")
        branch_sha = git(agent_path, "rev-parse", "HEAD")
        git(agent_path, "push", "-u", "origin", f"agent/{self.workstream}")
        git(self.repo, "fetch", "origin")
        manifest_path = self._snapshot()
        archive = manifest_path.parent / f"worktree-{self.workstream}.tar"
        with quarantine.tarfile.open(archive) as tar:
            names = set(tar.getnames())
            self.assertIn("untracked.txt", names)
            self.assertIn("ignored.bin", names)
            self.assertIn("source-link", names)
            self.assertEqual(tar.extractfile("untracked.txt").read(), b"untracked payload\n")
            self.assertEqual(tar.getmember("source-link").linkname, "untracked.txt")
        self.assertEqual(quarantine.verify_snapshot(manifest_path)["workstreams"][self.workstream]["branch_sha"], branch_sha)


if __name__ == "__main__":
    unittest.main()
