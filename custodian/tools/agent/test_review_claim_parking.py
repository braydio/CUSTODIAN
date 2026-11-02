"""Temporary-remote tests for exact paired-review claim parking."""

from __future__ import annotations

import concurrent.futures
import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("review_claim_parking.py")
sys.path.insert(0, str(SCRIPT.parent))
SPEC = importlib.util.spec_from_file_location("review_claim_parking", SCRIPT)
parking = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = parking
assert SPEC and SPEC.loader
SPEC.loader.exec_module(parking)


def git(cwd: Path, *args: str, check: bool = True, input_text: str | None = None) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, input=input_text, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ParkingFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        git(self.base, "init", "--bare", str(self.remote))
        git(self.base, "clone", str(self.remote), str(self.repo))
        git(self.repo, "checkout", "-b", "main")
        git(self.repo, "config", "user.name", "Parking Test")
        git(self.repo, "config", "user.email", "parking@example.test")
        (self.repo / "base.txt").write_text("base\n")
        (self.repo / ".gitignore").write_text(".ignored-review-cache\n")

        self.workstream = "review-agent-paired-review-declared-doc-archive-gate-v1"
        self.run_id = "20261019T104055Z-522c04f5260b"
        self.claim_run_id = "20261019T104104Z-bf7933596f7f"
        self.target_workstream = "agent-paired-review-declared-doc-archive-gate-v1"
        self.target_packet = "custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md"
        self.worktree = self.base / "review-worktree"
        self.write_packets()
        git(self.repo, "add", "base.txt", ".gitignore", self.target_packet,
            "custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md")
        git(self.repo, "commit", "-m", "fixture main")
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main")
        self.reviewed_main = git(self.repo, "rev-parse", "HEAD")

        git(self.repo, "worktree", "add", "-b", f"agent/{self.workstream}", str(self.worktree), "origin/main")
        git(self.worktree, "config", "user.name", "Parking Test")
        git(self.worktree, "config", "user.email", "parking@example.test")
        (self.worktree / "remote-history.txt").write_text("remote claim history\n")
        git(self.worktree, "add", "remote-history.txt")
        git(self.worktree, "commit", "-m", "fixture remote claim")
        git(self.worktree, "push", "-u", "origin", f"agent/{self.workstream}")
        self.remote_sha = git(self.worktree, "rev-parse", "HEAD")
        (self.worktree / "local-review-evidence.txt").write_text("local-only preserved evidence\n")
        git(self.worktree, "add", "local-review-evidence.txt")
        git(self.worktree, "commit", "-m", "fixture local review evidence")
        self.local_sha = git(self.worktree, "rev-parse", "HEAD")
        git(self.repo, "fetch", "origin")

        self.scope = parking.ParkingScope(
            workstream=self.workstream,
            run_id=self.run_id,
            claim_run_id=self.claim_run_id,
            target_workstream=self.target_workstream,
            target_packet=self.target_packet,
            lock="paired-review-source-provenance",
            remote_branch_sha=self.remote_sha,
            local_branch_sha=self.local_sha,
        )
        self._prior_scope = parking.AUTHORIZED_SCOPE
        parking.AUTHORIZED_SCOPE = self.scope
        self.run_dir = parking.run_directory(self.repo, self.scope)
        self.extra_repos: list[Path] = []
        self.extra_worktrees: list[tuple[Path, Path]] = []
        self.create_run_evidence()

    def tearDown(self):
        parking.AUTHORIZED_SCOPE = self._prior_scope
        for repo, worktree in self.extra_worktrees:
            git(repo, "worktree", "remove", str(worktree), check=False)
        for record in git(self.repo, "worktree", "list", "--porcelain").split("\n\n"):
            lines = record.splitlines()
            if lines and Path(lines[0].removeprefix("worktree ")).resolve() != self.repo.resolve():
                git(self.repo, "worktree", "remove", lines[0].removeprefix("worktree "), check=False)
        self.temp.cleanup()

    def write_packets(self):
        review = self.repo / self.target_packet
        impl = self.repo / "custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md"
        review.parent.mkdir(parents=True, exist_ok=True)
        impl.write_text(
            "# implementation\n\n- Workstream: `agent-paired-review-declared-doc-archive-gate-v1`\n"
            "- Status: `complete`\n- Dispatch: `auto`\n- Kind: `implementation`\n"
            "- Paired review workstream: `review-agent-paired-review-declared-doc-archive-gate-v1`\n"
        )
        review.write_text(
            "# review\n\n- Workstream: `review-agent-paired-review-declared-doc-archive-gate-v1`\n"
            "- Status: `ready`\n- Dispatch: `auto`\n- Kind: `review`\n"
            "- Review target workstream: `agent-paired-review-declared-doc-archive-gate-v1`\n"
            "- Locks: `paired-review-source-provenance`\n"
        )

    def create_run_evidence(self):
        self.run_dir.mkdir(parents=True, exist_ok=True)
        claim = {
            "schema": "custodian.dispatch.claim.v1", "result": "claimed", "verified": True,
            "workstream": self.workstream, "run_id": self.claim_run_id,
            "branch": f"agent/{self.workstream}", "worktree": str(self.worktree),
        }
        original = {
            "RECOVERY.md": "preserve unresolved review\n",
            "claim-receipt.json": json.dumps(claim, sort_keys=True) + "\n",
            "claim.stderr": "", "claim.stdout": "CLAIMED\n",
            "codex.jsonl": "{}\n", "codex.stderr": "",
            "coordinator-validation.json": "{}\n",
            "last-message.txt": "reviewer exited; disposition remains unaccepted\n",
            "metadata.json": json.dumps({
                "run_id": self.run_id, "workstream": self.workstream,
                "phase": "post_exit_recovery", "branch": f"agent/{self.workstream}",
                "worktree": str(self.worktree), "reviewed_main": self.remote_sha,
                "outcome": None, "finding_ids": None,
            }, sort_keys=True) + "\n",
            "validation.json": "{}\n",
        }
        for relative, content in original.items():
            (self.run_dir / relative).write_text(content)
        manifest = {relative: sha256(self.run_dir / relative) for relative in sorted(original)}
        continuation = self.run_dir / "continuation-01"
        continuation.mkdir()
        (continuation / "metadata.json").write_text(json.dumps({
            "run_id": self.run_id, "workstream": self.workstream,
            "target_workstream": self.target_workstream,
            "phase": "coordinator_closeout", "branch": f"agent/{self.workstream}",
            "worktree": str(self.worktree), "reviewed_main": self.remote_sha,
            "implementation_commit": self.remote_sha,
            "run_evidence_sha256": manifest,
        }, sort_keys=True) + "\n")

    def attested_plan(self):
        return parking.build_plan(
            self.repo, scope=self.scope, owner_absence_attested=True,
            attested_by="Parking Test Operator",
        )

    def second_clone_with_same_claim(self):
        repo = self.base / "second-repo"
        worktree = self.base / "second-review-worktree"
        git(self.base, "clone", "--branch", "main", str(self.remote), str(repo))
        git(repo, "config", "user.name", "Parking Test Second Clone")
        git(repo, "config", "user.email", "parking-second@example.test")
        git(repo, "fetch", str(self.repo), f"refs/heads/agent/{self.workstream}:refs/heads/agent/{self.workstream}")
        git(repo, "worktree", "add", str(worktree), f"agent/{self.workstream}")
        run_dir = parking.run_directory(repo, self.scope)
        shutil.copytree(self.run_dir, run_dir)
        for relative in ("metadata.json", "claim-receipt.json", "continuation-01/metadata.json"):
            path = run_dir / relative
            data = json.loads(path.read_text())
            data["worktree"] = str(worktree)
            path.write_text(json.dumps(data, sort_keys=True) + "\n")
        continuation_path = run_dir / "continuation-01" / "metadata.json"
        continuation = json.loads(continuation_path.read_text())
        continuation["run_evidence_sha256"] = {
            relative: sha256(run_dir / relative)
            for relative in continuation["run_evidence_sha256"]
        }
        continuation_path.write_text(json.dumps(continuation, sort_keys=True) + "\n")
        self.extra_repos.append(repo)
        self.extra_worktrees.append((repo, worktree))
        return repo


class ReviewClaimParkingTests(ParkingFixture):
    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_read_only_plan_pins_evidence_and_requires_owner_attestation(self, _processes):
        before = {
            "remote_branch": git(self.repo, "ls-remote", "origin", f"refs/heads/agent/{self.workstream}"),
            "local_branch": git(self.repo, "rev-parse", f"refs/heads/agent/{self.workstream}"),
            "worktree_status": git(self.worktree, "status", "--porcelain=v1", "--untracked-files=all"),
            "run_files": sorted((p.relative_to(self.run_dir).as_posix(), sha256(p))
                                for p in self.run_dir.rglob("*") if p.is_file()),
        }
        plan = parking.build_plan(self.repo, scope=self.scope)
        self.assertFalse(plan["eligible"])
        self.assertIn("explicit owner-absence attestation is required", plan["blockers"])
        self.assertRegex(plan["plan_sha256"], r"^[0-9a-f]{64}$")
        after = {
            "remote_branch": git(self.repo, "ls-remote", "origin", f"refs/heads/agent/{self.workstream}"),
            "local_branch": git(self.repo, "rev-parse", f"refs/heads/agent/{self.workstream}"),
            "worktree_status": git(self.worktree, "status", "--porcelain=v1", "--untracked-files=all"),
            "run_files": sorted((p.relative_to(self.run_dir).as_posix(), sha256(p))
                                for p in self.run_dir.rglob("*") if p.is_file()),
        }
        self.assertEqual(after, before)
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "absent")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_park_and_unpark_preserve_claim_branch_worktree_and_run_evidence(self, _processes):
        before_remote = git(self.repo, "ls-remote", "origin", f"refs/heads/agent/{self.workstream}")
        before_local = git(self.repo, "rev-parse", f"refs/heads/agent/{self.workstream}")
        before_worktree = git(self.worktree, "status", "--porcelain=v1", "--untracked-files=all")
        before_files = sorted((p.relative_to(self.run_dir).as_posix(), sha256(p))
                              for p in self.run_dir.rglob("*") if p.is_file())
        park_plan = self.attested_plan()
        parked = parking.apply_transition(
            self.repo, action="park", scope=self.scope,
            expected_plan_sha256=park_plan["plan_sha256"],
            owner_absence_attested=True, attested_by="Parking Test Operator",
        )
        state = parking.read_remote_record(self.repo, self.scope)
        self.assertEqual(state["state"], "PARKED")
        self.assertEqual(state["record"]["run_id"], self.run_id)
        self.assertEqual(state["record"]["claim_run_id"], self.claim_run_id)
        self.assertEqual(state["record"]["remote_branch_sha"], self.remote_sha)
        self.assertEqual(state["record"]["local_branch_sha"], self.local_sha)
        self.assertEqual(parked["remote_record_sha"], state["record_sha"])
        import dispatch
        holder_packet = self.review_packet()
        lock_holders, parking_states = dispatch._execution_lock_holders(
            self.repo, [holder_packet], {self.workstream},
        )
        self.assertNotIn(self.workstream, lock_holders, parking_states)
        self.assertEqual(parking_states[self.workstream]["state"], "parked")
        self.assertEqual(git(self.repo, "ls-remote", "origin", f"refs/heads/agent/{self.workstream}"), before_remote)
        self.assertEqual(git(self.repo, "rev-parse", f"refs/heads/agent/{self.workstream}"), before_local)
        self.assertEqual(git(self.worktree, "status", "--porcelain=v1", "--untracked-files=all"), before_worktree)
        self.assertEqual(sorted((p.relative_to(self.run_dir).as_posix(), sha256(p))
                                for p in self.run_dir.rglob("*") if p.is_file()), before_files)

        unpark_plan = parking.build_plan(self.repo, action="unpark", scope=self.scope)
        self.assertTrue(unpark_plan["eligible"], unpark_plan["blockers"])
        unparked = parking.apply_transition(
            self.repo, action="unpark", scope=self.scope,
            expected_plan_sha256=unpark_plan["plan_sha256"],
        )
        state = parking.read_remote_record(self.repo, self.scope)
        self.assertEqual(state["state"], "ACTIVE")
        self.assertEqual(unparked["remote_record_sha"], state["record_sha"])
        self.assertEqual(state["record"]["previous_record_sha"], parked["remote_record_sha"])
        self.assertEqual(git(self.repo, "ls-remote", "origin", f"refs/heads/agent/{self.workstream}"), before_remote)
        lock_holders, parking_states = dispatch._execution_lock_holders(
            self.repo, [holder_packet], {self.workstream},
        )
        self.assertIn(self.workstream, lock_holders)
        self.assertEqual(parking_states[self.workstream]["state"], "active")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_changed_run_evidence_invalidates_plan_before_remote_transition(self, _processes):
        plan = self.attested_plan()
        (self.run_dir / "validation.json").write_text("changed evidence\n")
        with self.assertRaises(parking.ParkingError):
            parking.apply_transition(
                self.repo, action="park", scope=self.scope,
                expected_plan_sha256=plan["plan_sha256"],
                owner_absence_attested=True, attested_by="Parking Test Operator",
            )
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "absent")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_ignored_worktree_file_inventory_change_invalidates_plan(self, _processes):
        plan = self.attested_plan()
        self.assertTrue(plan["eligible"], plan["blockers"])
        self.assertGreater(plan["local_file_count"], 0)
        (self.worktree / ".ignored-review-cache").write_text("untracked but ignored data\n")
        with self.assertRaises(parking.ParkingError):
            parking.apply_transition(
                self.repo, action="park", scope=self.scope,
                expected_plan_sha256=plan["plan_sha256"],
                owner_absence_attested=True, attested_by="Parking Test Operator",
            )
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "absent")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([{"pid": 123}], True))
    def test_active_local_owner_blocks_even_with_operator_attestation(self, _processes):
        plan = self.attested_plan()
        self.assertFalse(plan["eligible"])
        self.assertTrue(any("active local owner process" in item for item in plan["blockers"]))
        with self.assertRaises(parking.ParkingError):
            parking.apply_transition(
                self.repo, action="park", scope=self.scope,
                expected_plan_sha256=plan["plan_sha256"],
                owner_absence_attested=True, attested_by="Parking Test Operator",
            )
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "absent")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_remote_branch_sha_change_fails_closed(self, _processes):
        changed = self.worktree / "remote-history.txt"
        changed.write_text("unexpected new remote content\n")
        git(self.worktree, "add", "remote-history.txt")
        git(self.worktree, "commit", "-m", "unexpected remote advance")
        git(self.worktree, "push", "origin", f"agent/{self.workstream}")
        plan = self.attested_plan()
        self.assertFalse(plan["eligible"])
        self.assertTrue(any("remote agent branch SHA changed" in item for item in plan["blockers"]))

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_unrecognized_scope_is_rejected(self, _processes):
        wrong = parking.ParkingScope(**{
            **self.scope.__dict__, "run_id": "20261019T000000Z-000000000000",
        })
        with self.assertRaises(parking.ParkingError):
            parking.build_plan(self.repo, scope=wrong, owner_absence_attested=True,
                               attested_by="Parking Test Operator")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_changed_local_claim_commit_fails_closed(self, _processes):
        changed = self.worktree / "remote-history.txt"
        changed.write_text("unexpected local-only commit\n")
        git(self.worktree, "add", "remote-history.txt")
        git(self.worktree, "commit", "-m", "move protected local claim")
        plan = self.attested_plan()
        self.assertFalse(plan["eligible"])
        self.assertTrue(any("local agent branch SHA changed" in item for item in plan["blockers"]))

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_changed_claim_receipt_identity_fails_closed(self, _processes):
        claim = self.run_dir / "claim-receipt.json"
        receipt = json.loads(claim.read_text())
        receipt["run_id"] = "20261019T000000Z-000000000000"
        claim.write_text(json.dumps(receipt, sort_keys=True) + "\n")
        plan = self.attested_plan()
        self.assertFalse(plan["eligible"])
        self.assertTrue(any("claim receipt does not match" in item for item in plan["blockers"]))

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_plan_digest_is_fenced_against_branch_change(self, _processes):
        plan = self.attested_plan()
        changed = self.worktree / "remote-history.txt"
        changed.write_text("unexpected remote content\n")
        git(self.worktree, "add", "remote-history.txt")
        git(self.worktree, "commit", "-m", "move local branch")
        git(self.worktree, "push", "origin", f"agent/{self.workstream}")
        with self.assertRaises(parking.ParkingError):
            parking.apply_transition(
                self.repo, action="park", scope=self.scope,
                expected_plan_sha256=plan["plan_sha256"],
                owner_absence_attested=True, attested_by="Parking Test Operator",
            )

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_second_park_is_rejected_after_unpark_history(self, _processes):
        plan = self.attested_plan()
        parked = parking.apply_transition(
            self.repo, action="park", scope=self.scope,
            expected_plan_sha256=plan["plan_sha256"],
            owner_absence_attested=True, attested_by="Parking Test Operator",
        )
        unpark_plan = parking.build_plan(self.repo, action="unpark", scope=self.scope)
        parking.apply_transition(self.repo, action="unpark", scope=self.scope,
                                 expected_plan_sha256=unpark_plan["plan_sha256"])
        again = self.attested_plan()
        self.assertFalse(again["eligible"])
        self.assertTrue(any("one-time parking transition already used" in item
                            for item in again["blockers"]))

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_unpark_restores_lock_even_if_local_run_evidence_changed(self, _processes):
        plan = self.attested_plan()
        parking.apply_transition(
            self.repo, action="park", scope=self.scope,
            expected_plan_sha256=plan["plan_sha256"],
            owner_absence_attested=True, attested_by="Parking Test Operator",
        )
        (self.run_dir / "validation.json").write_text("later local change\n")
        unpark_plan = parking.build_plan(self.repo, action="unpark", scope=self.scope)
        self.assertTrue(unpark_plan["eligible"], unpark_plan["blockers"])
        parking.apply_transition(self.repo, action="unpark", scope=self.scope,
                                 expected_plan_sha256=unpark_plan["plan_sha256"])
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "ACTIVE")

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], False))
    def test_incomplete_local_process_scan_blocks_parking(self, _processes):
        plan = self.attested_plan()
        self.assertFalse(plan["eligible"])
        self.assertTrue(any("local owner process scan is incomplete" in item
                            for item in plan["blockers"]))

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_malformed_remote_record_keeps_claim_unparked(self, _processes):
        ref = parking.parking_ref(self.scope)
        blob = git(self.repo, "hash-object", "-w", "--stdin", input_text='{"schema":"wrong"}\n')
        tree = git(self.repo, "mktree", input_text=f"100644 blob {blob}\tparking.json\n")
        commit = git(self.repo, "commit-tree", tree, "-p", self.remote_sha, "-m", "bad parking fixture")
        git(self.repo, "push", "origin", f"{commit}:{ref}")
        result = parking.read_remote_record(self.repo, self.scope)
        self.assertEqual(result["state"], "invalid")
        self.assertFalse(parking.dispatcher_parking_state(self.repo, self.review_packet(), self.remote_sha)["lock_released"])

    def review_packet(self):
        from task_packet_contract import parse_packet
        text = git(self.repo, "show", f"origin/main:{self.target_packet}")
        return parse_packet(self.target_packet, text)

    @mock.patch.object(parking, "find_local_owner_processes", return_value=([], True))
    def test_two_clones_cannot_both_create_the_parking_ref(self, _processes):
        second = self.second_clone_with_same_claim()
        first_plan = self.attested_plan()
        second_plan = parking.build_plan(
            second, scope=self.scope, owner_absence_attested=True,
            attested_by="Parking Test Operator",
        )
        self.assertTrue(first_plan["eligible"], first_plan["blockers"])
        self.assertTrue(second_plan["eligible"], second_plan["blockers"])
        self.assertNotEqual(first_plan["local_inventory_sha256"], second_plan["local_inventory_sha256"])

        def apply(repo: Path, plan: dict[str, object]):
            return parking.apply_transition(
                repo, action="park", scope=self.scope,
                expected_plan_sha256=str(plan["plan_sha256"]),
                owner_absence_attested=True, attested_by="Parking Test Operator",
            )

        outcomes: list[str] = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            futures = [executor.submit(apply, self.repo, first_plan),
                       executor.submit(apply, second, second_plan)]
            for future in futures:
                try:
                    future.result()
                    outcomes.append("parked")
                except parking.ParkingError:
                    outcomes.append("lost")
        self.assertCountEqual(outcomes, ["parked", "lost"])
        self.assertEqual(parking.read_remote_record(self.repo, self.scope)["state"], "PARKED")


if __name__ == "__main__":
    unittest.main()
