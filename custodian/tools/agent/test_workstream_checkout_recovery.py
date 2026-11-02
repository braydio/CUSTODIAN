"""Isolated end-to-end fixture for same-claim initial checkout recovery."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import socket
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

AGENT_TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(AGENT_TOOLS))
SPEC = importlib.util.spec_from_file_location("checkout_recovery_workstream", AGENT_TOOLS / "workstream.py")
workstream = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = workstream
SPEC.loader.exec_module(workstream)


def git(cwd: Path, *args: str, input_bytes: bytes | None = None, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, input=input_bytes, capture_output=True, check=False)
    if check and result.returncode:
        raise AssertionError((result.stderr or result.stdout).decode("utf-8", "replace"))
    return (result.stdout or b"").decode("utf-8", "replace").strip()


class InitialCheckoutRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="custodian-same-claim-recovery-")
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote))
        git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Recovery Fixture")
        git(self.repo, "config", "user.email", "recovery@example.invalid")
        (self.repo / "custodian/docs/ai_context/worktree_profiles").mkdir(parents=True)
        (self.repo / "custodian/docs/ai_context/worktree_profiles/fixture.json").write_text(json.dumps({
            "schema": "custodian.worktree_checkout_profile.v1",
            "include_paths": [
                "custodian/docs/ai_context/worktree_profiles/fixture.json",
                "custodian/keep.txt",
            ],
            "hydrate_lfs_paths": [],
        }, sort_keys=True) + "\n")
        (self.repo / "custodian/keep.txt").write_text("sparse fixture content\n")
        (self.repo / "custodian/omit.txt").write_text("must remain omitted\n")
        git(self.repo, "add", "custodian")
        git(self.repo, "commit", "-m", "fixture base")
        self.base_sha = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "fetch", "origin")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")
        self.workstream_id = "synthetic-checkout-recovery-v1"
        self.run_id = "20261031T000000Z-123456abcdef"
        self.branch = f"agent/{self.workstream_id}"
        self.claim_ref = f"refs/heads/dispatch-claims/{self.workstream_id}"
        self.diag_ref = f"refs/heads/agent-diagnostics/{self.workstream_id}/{self.run_id}"
        self.target = self.repo.parent / ".custodian-worktrees" / f"{self.workstream_id}-{self.run_id}"
        git(self.repo, "branch", self.branch, self.base_sha)
        self.claim_sha = git(self.repo, "commit-tree", f"{self.base_sha}^{{tree}}", "-p", self.base_sha,
                             "-m", "synthetic original dispatch claim")
        git(self.repo, "push", "origin", f"{self.claim_sha}:{self.claim_ref}")
        self._write_failed_trace()
        active_path = self.repo / ".git" / "custodian-workflow" / "active" / f"{self.workstream_id}.json"
        active_path.parent.mkdir(parents=True, exist_ok=True)
        active_path.write_text(json.dumps({
            "run_id": self.run_id,
            "workstream": self.workstream_id,
            "trace_path": str(self.trace_path),
            "diagnostic_ref": f"refs/heads/agent-diagnostics/{self.workstream_id}/{self.run_id}",
        }, sort_keys=True) + "\n")
        git(self.repo, "push", "origin", f"{self.diag_commit}:{self.diag_ref}")
        git(self.repo, "update-ref", self.local_diag_ref, self.diag_commit)
        self.trace_bytes = self.trace_path.read_bytes()

    def tearDown(self):
        self.temp.cleanup()

    @property
    def trace_path(self) -> Path:
        return self.repo / ".git" / "custodian-workflow" / "traces" / self.workstream_id / f"{self.run_id}.jsonl"

    @property
    def local_diag_ref(self) -> str:
        return f"refs/custodian/diagnostics/{self.workstream_id}/{self.run_id}"

    def _write_failed_trace(self, *, host: str | None = None, pid: int = 2_147_483_647,
                            run_id: str | None = None, worktree: Path | None = None) -> None:
        host = host or socket.gethostname()
        run_id = run_id or self.run_id
        worktree = worktree or self.target
        common = {"schema": "custodian.workflow.trace.v1", "schema_version": 1,
                  "host": host, "pid": pid, "workstream": self.workstream_id, "run_id": run_id}
        rows = [
            {**common, "event": "run_started", "packet": "fixture-packet", "data": {}},
            {**common, "event": "remote_claim_acquired", "data": {
                "remote_ref": self.claim_ref, "claim_oid": self.claim_sha, "main_sha": self.base_sha,
            }},
            {**common, "event": "worktree_create_begin", "data": {
                "worktree": str(worktree), "branch": self.branch, "main_sha": self.base_sha,
            }},
            {**common, "event": "run_blocked", "data": {"reason": "git-lfs smudge failed: No space left on device"}},
        ]
        raw = "".join(json.dumps(item, sort_keys=True, separators=(",", ":")) + "\n" for item in rows).encode()
        self.trace_path.parent.mkdir(parents=True, exist_ok=True)
        self.trace_path.write_bytes(raw)
        blob = git(self.repo, "hash-object", "-w", "--stdin", input_bytes=raw)
        tree = git(self.repo, "mktree", input_bytes=f"100644 blob {blob}\ttrace.jsonl\n".encode())
        self.diag_commit = git(self.repo, "-c", "user.name=Diagnostics", "-c", "user.email=diag@example.invalid",
                               "commit-tree", tree, "-m", "synthetic preserved diagnostic")

    def _plan(self) -> dict:
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            return workstream.initial_checkout_recovery_plan(
                self.workstream_id, self.run_id,
                "custodian/docs/ai_context/worktree_profiles/fixture.json", self.repo,
            )

    def test_same_claim_recovery_reuses_original_claim_and_exact_sparse_profile(self):
        plan = self._plan()
        self.assertEqual(plan["blockers"], [])
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            recovered = workstream.recover_initial_checkout(
                self.workstream_id, self.run_id,
                "custodian/docs/ai_context/worktree_profiles/fixture.json",
                plan["plan_sha256"], self.repo,
            )
        self.assertEqual(recovered, self.target)
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.claim_ref).split()[0], self.claim_sha)
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.branch).split()[0],
                         git(recovered, "rev-parse", "HEAD"))
        self.assertEqual((recovered / "custodian/keep.txt").read_text(), "sparse fixture content\n")
        self.assertFalse((recovered / "custodian/omit.txt").exists())
        self.assertEqual(self.trace_path.read_bytes(), self.trace_bytes)
        active = json.loads((self.repo / ".git" / "custodian-workflow" / "active" / f"{self.workstream_id}.json").read_text())
        self.assertNotEqual(active["run_id"], self.run_id)
        self.assertTrue((self.repo / ".git" / "custodian-workflow" / "traces" / self.workstream_id /
                         f"{active['run_id']}.jsonl").is_file())

    def test_changed_claim_ref_is_blocked_and_original_trace_is_unchanged(self):
        plan = self._plan()
        other = git(self.repo, "commit-tree", f"{self.base_sha}^{{tree}}", "-p", self.base_sha,
                    "-m", "changed claim")
        git(self.repo, "push", "--force", "origin", f"{other}:{self.claim_ref}")
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            with self.assertRaisesRegex(workstream.WorkstreamError, "recovery plan is blocked"):
                workstream.recover_initial_checkout(
                    self.workstream_id, self.run_id,
                    "custodian/docs/ai_context/worktree_profiles/fixture.json", plan["plan_sha256"], self.repo,
                )
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.claim_ref).split()[0], other)
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.branch), "")
        self.assertEqual(self.trace_path.read_bytes(), self.trace_bytes)

    def test_process_target_and_foreign_host_evidence_fail_closed(self):
        self._write_failed_trace(pid=os.getpid())
        self.assertTrue(any("still live or reused" in item for item in workstream._recovery_process_blockers(
            self.repo, self.workstream_id, os.getpid(), self.target,
        )))
        self._write_failed_trace(pid=2_147_483_647, worktree=self.target)
        self.target.mkdir(parents=True)
        (self.target / "partial").write_text("preserve me")
        self.assertTrue(any("contains data" in item for item in self._plan()["blockers"]))
        (self.target / "partial").unlink()
        self.target.rmdir()
        self._write_failed_trace(host="foreign-host.example")
        self.assertTrue(any("host differs" in item for item in self._plan()["blockers"]))
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.claim_ref).split()[0], self.claim_sha)

    def test_changed_plan_digest_refuses_apply_before_remote_branch_publication(self):
        plan = self._plan()
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            with self.assertRaisesRegex(workstream.WorkstreamError, "plan digest changed"):
                workstream.recover_initial_checkout(
                    self.workstream_id, self.run_id,
                    "custodian/docs/ai_context/worktree_profiles/fixture.json", "0" * 64, self.repo,
                )
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.branch), "")
        self.assertFalse(self.target.exists())
        self.assertEqual(self.trace_path.read_bytes(), self.trace_bytes)

    def test_missing_identity_extra_branch_bad_profile_low_space_and_ambiguous_scan_block(self):
        with self.assertRaisesRegex(workstream.WorkstreamError, "trace is unavailable"):
            workstream.initial_checkout_recovery_plan(
                self.workstream_id, self.run_id + "-missing",
                "custodian/docs/ai_context/worktree_profiles/fixture.json", self.repo,
            )
        git(self.repo, "update-ref", f"refs/heads/{self.branch}", self.claim_sha)
        self.assertTrue(any("local agent branch" in item for item in self._plan()["blockers"]))
        git(self.repo, "update-ref", f"refs/heads/{self.branch}", self.base_sha)
        git(self.repo, "push", "origin", f"{self.base_sha}:refs/heads/{self.branch}")
        self.assertTrue(any("remote agent branch already exists" in item for item in self._plan()["blockers"]))
        git(self.repo, "push", "origin", f":refs/heads/{self.branch}")
        git(self.repo, "push", "origin", f":{self.claim_ref}")
        self.assertTrue(any("remote dispatch claim is absent" in item for item in self._plan()["blockers"]))
        git(self.repo, "push", "origin", f"{self.claim_sha}:{self.claim_ref}")

        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=["cannot enumerate local processes"]):
            ambiguous = workstream.initial_checkout_recovery_plan(
                self.workstream_id, self.run_id,
                "custodian/docs/ai_context/worktree_profiles/fixture.json", self.repo,
            )
            self.assertTrue(any("cannot enumerate local processes" in item for item in ambiguous["blockers"]))
        active_path = self.repo / ".git" / "custodian-workflow" / "active" / f"{self.workstream_id}.json"
        active_raw = active_path.read_bytes()
        active_data = json.loads(active_raw)
        active_data["run_id"] = "20261031T000001Z-foreignactive"
        active_path.write_text(json.dumps(active_data, sort_keys=True) + "\n")
        self.assertTrue(any("active run pointer" in item for item in self._plan()["blockers"]))
        active_path.write_bytes(active_raw)
        usage = type("Usage", (), {"free": 0})()
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]), \
             mock.patch.object(workstream.worktree_provisioning.shutil, "disk_usage", return_value=usage):
            self.assertTrue(any("insufficient storage" in item for item in self._plan()["blockers"]))

        prior = self._plan()
        profile_path = self.repo / "custodian/docs/ai_context/worktree_profiles/fixture.json"
        profile = json.loads(profile_path.read_text())
        profile["include_paths"] = ["custodian/keep.txt"]
        profile["hydrate_lfs_paths"] = ["custodian/omit.txt"]
        profile_path.write_text(json.dumps(profile, sort_keys=True) + "\n")
        git(self.repo, "add", str(profile_path.relative_to(self.repo)))
        git(self.repo, "commit", "-m", "invalid hydration profile")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            invalid = workstream.initial_checkout_recovery_plan(
                self.workstream_id, self.run_id,
                "custodian/docs/ai_context/worktree_profiles/fixture.json", self.repo,
            )
            self.assertTrue(any("not included by profile" in item for item in invalid["blockers"]))

        valid = json.loads(profile_path.read_text())
        valid["include_paths"] = [
            "custodian/docs/ai_context/worktree_profiles/fixture.json", "custodian/keep.txt", "custodian/new.txt",
        ]
        valid["hydrate_lfs_paths"] = []
        profile_path.write_text(json.dumps(valid, sort_keys=True) + "\n")
        (self.repo / "custodian/new.txt").write_text("new main dependency\n")
        git(self.repo, "add", str(profile_path.relative_to(self.repo)), "custodian/new.txt")
        git(self.repo, "commit", "-m", "profile advances after planning")
        git(self.repo, "push", "origin", "main")
        git(self.repo, "fetch", "origin")
        with mock.patch.object(workstream, "_recovery_process_blockers", return_value=[]):
            with self.assertRaisesRegex(workstream.WorkstreamError, "plan digest changed"):
                workstream.recover_initial_checkout(
                    self.workstream_id, self.run_id,
                    "custodian/docs/ai_context/worktree_profiles/fixture.json", prior["plan_sha256"], self.repo,
                )
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.claim_ref).split()[0], self.claim_sha)
        self.assertEqual(git(self.repo, "ls-remote", "origin", self.branch), "")
        self.assertEqual(self.trace_path.read_bytes(), self.trace_bytes)
