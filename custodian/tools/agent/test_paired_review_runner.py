#!/usr/bin/env python3
"""Focused contract tests for the synchronous paired-review runner."""
from __future__ import annotations

import json
import fcntl
import hashlib
import io
import os
import re
import subprocess
import sys
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest.mock import patch

import paired_review_runner as runner
import paired_review_host_validation as host_validation
from godot_project_lock import (
    BUDGET_FD_ENV, BUDGET_REENTRANCY_ENV, MAX_JOBS_ENV,
    GodotJobBudget, godot_home, job_budget_root,
)
from review_receipt_delta import (
    read_git_text,
    resolve_target_implementation_commit,
    verify_review_receipt_delta,
)

ROOT = Path(__file__).resolve().parents[3]


def review_packet(*, visual="none", refresh="no"):
    return f"""# Review packet
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md`
- Visual review: `{visual}`
- ChatGPT/user planning refresh required: `{refresh}`

## Goal
Review this task.
"""


def target_packet(implementation_commit="a" * 40):
    return f"""# Implementation
- Packet schema: `custodian.task_packet.v2`
- Workstream: `sample-impl`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow`
- Implementation commit: `{implementation_commit}`

## Goal
Retain the exact implementation goal.

## Acceptance
Retain the exact acceptance contract.

## Completion Truth
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`

## Implementation
```gdscript
func preserved_code():
    return true
```
"""


def append_receipt(target, *, review_workstream, target_workstream, reviewed_main, implementation_commit):
    section = f"""### Review Receipt: {review_workstream}
- Schema: `custodian.paired_review.v1`
- Review workstream: `{review_workstream}`
- Review target workstream: `{target_workstream}`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{reviewed_main}`
- Reviewed implementation commit: `{implementation_commit}`
"""
    if "## Independent Review\n" in target:
        return target.rstrip("\n") + "\n\n" + section
    return target + f"""
## Independent Review

{section}"""


class PairedReviewRunnerTests(unittest.TestCase):
    def test_validation_timeout_manifest_change_is_exactly_one_field(self):
        repository = Path(__file__).resolve().parents[3]
        manifest_path = "custodian/tools/validation/validation_manifest.json"
        original = subprocess.run(
            ["git", "show", "030dbe986c0ced4e8b1dc2c816f466c81146b5f2:" + manifest_path],
            cwd=repository, check=True, capture_output=True,
        ).stdout
        current_main = subprocess.run(
            ["git", "show", "origin/main:" + manifest_path],
            cwd=repository, check=True, capture_output=True,
        ).stdout

        def pair_record(raw):
            document = json.loads(raw)
            matches = [item for item in document["tests"]
                       if item.get("id") == "paired_review_runner_unit"]
            self.assertEqual(len(matches), 1)
            return matches[0]

        original_pair = pair_record(original)
        current_pair = pair_record(current_main)
        self.assertEqual(original_pair["timeout_sec"], 30)
        self.assertIn(current_pair["timeout_sec"], (30, 60, 90))
        self.assertEqual({k: v for k, v in original_pair.items() if k != "timeout_sec"},
                         {k: v for k, v in current_pair.items() if k != "timeout_sec"})
        if current_pair["timeout_sec"] != 90:
            marker = b'"id": "paired_review_runner_unit"'
            start = current_main.index(marker)
            end = current_main.index(b'      "needs_import": false', start)
            chunk = current_main[start:end]
            match = re.search(rb'"timeout_sec": (?:30|60)', chunk)
            self.assertIsNotNone(match)
            patched_chunk = (chunk[:match.start()] + b'"timeout_sec": 90'
                             + chunk[match.end():])
            expected = current_main[:start] + patched_chunk + current_main[end:]
        else:
            expected = current_main
        actual = (repository / manifest_path).read_bytes()
        self.assertEqual(actual, expected)

    def test_invalid_disposition_repair_moves_only_the_four_allowlisted_handoff_lines(self):
        canonical = runner.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=runner.INVALID_DISPOSITION_WORKSTREAM,
            target_workstream=runner.INVALID_DISPOSITION_TARGET,
            reviewed_main=runner.INVALID_DISPOSITION_IMPLEMENTATION,
            implementation_commit=runner.INVALID_DISPOSITION_IMPLEMENTATION,
            provenance="same-agent-fresh-context", run_id=runner.INVALID_DISPOSITION_RUN_ID,
            review_cycle=0, ids=(),
        )
        handoff = (
            "- Refresh reason: `none`\n"
            "- Next action: `Coordinator may now create and verify the exact read-only recovery plan.`\n"
            "- Blockers or open questions: `The historical plan remains read-only.`\n\n"
            "Authoring chat: https://chatgpt.com/c/exact-recovery\n"
        )
        original = ("# Preserved disposition\n\n" + canonical.rstrip("\n") + "\n" + handoff).encode()
        with patch.object(runner, "INVALID_DISPOSITION_SHA256", hashlib.sha256(original).hexdigest()):
            repaired, outcome = runner._repair_invalid_disposition(original)
        repaired_text = repaired.decode()
        parsed, error = runner.review_outcome.parse_review_outcome(repaired_text)
        self.assertIsNone(error)
        self.assertEqual(parsed, outcome)
        self.assertEqual(parsed["Outcome"], "passed")
        self.assertIn(canonical, repaired_text)
        self.assertNotIn("Refresh reason", repaired_text[:repaired_text.index("## Next Handoff")])
        self.assertIn("- Refresh reason: `none`", repaired_text)
        self.assertIn("- Next action: `Coordinator may now create and verify the exact read-only recovery plan.`", repaired_text)
        self.assertIn("- Blockers or open questions: `The historical plan remains read-only.`", repaired_text)
        self.assertIn("- Authoring chat: `https://chatgpt.com/c/exact-recovery`", repaired_text)

    def test_invalid_disposition_repair_rejects_digest_drift_and_unrecognized_content(self):
        canonical = runner.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=runner.INVALID_DISPOSITION_WORKSTREAM,
            target_workstream=runner.INVALID_DISPOSITION_TARGET,
            reviewed_main=runner.INVALID_DISPOSITION_IMPLEMENTATION,
            implementation_commit=runner.INVALID_DISPOSITION_IMPLEMENTATION,
            provenance="same-agent-fresh-context", run_id=runner.INVALID_DISPOSITION_RUN_ID,
            review_cycle=0, ids=(),
        )
        malformed = ("# Disposition\n\n" + canonical.rstrip("\n") + "\n"
                     "- Refresh reason: `none`\n"
                     "- Next action: `Plan only.`\n"
                     "- Blockers or open questions: `None.`\n\n"
                     "Authoring chat: https://chatgpt.com/c/exact-recovery\n")
        with self.assertRaisesRegex(runner.RunnerError, "preserved disposition digest"):
            runner._repair_invalid_disposition(malformed.encode())
        extra = malformed.replace("Authoring chat:", "Unexpected: extra\n\nAuthoring chat:")
        with patch.object(runner, "INVALID_DISPOSITION_SHA256", hashlib.sha256(extra.encode()).hexdigest()):
            with self.assertRaisesRegex(runner.RunnerError, "exact four-line handoff"):
                runner._repair_invalid_disposition(extra.encode())

    def test_invalid_disposition_target_receipt_is_derived_and_verified_as_exact_append(self):
        baseline = target_packet(runner.INVALID_DISPOSITION_IMPLEMENTATION)
        reviewer = {
            "Schema": "custodian.paired_review.v1",
            "Review workstream": runner.INVALID_DISPOSITION_WORKSTREAM,
            "Review target workstream": runner.INVALID_DISPOSITION_TARGET,
            "Status": "passed", "Blocking defects": "0", "Material gaps": "0",
            "Reviewer context": "fresh", "Reviewer provenance": "same-agent-fresh-context",
            "Reviewed main": runner.INVALID_DISPOSITION_IMPLEMENTATION,
            "Reviewed implementation commit": runner.INVALID_DISPOSITION_IMPLEMENTATION,
        }
        candidate = runner._append_verified_invalid_disposition_receipt(baseline, reviewer)
        receipt, error = verify_review_receipt_delta(
            baseline, candidate.decode(), review_workstream=runner.INVALID_DISPOSITION_WORKSTREAM,
            target_workstream=runner.INVALID_DISPOSITION_TARGET,
            reviewed_main=runner.INVALID_DISPOSITION_IMPLEMENTATION,
            target_implementation_commit=runner.INVALID_DISPOSITION_IMPLEMENTATION,
        )
        self.assertIsNone(error)
        self.assertEqual(receipt, reviewer)
        self.assertTrue(candidate.startswith(baseline.encode()))
        with self.assertRaisesRegex(runner.RunnerError, "reviewer-authored PASS receipt"):
            runner._append_verified_invalid_disposition_receipt(baseline, {**reviewer, "Status": "findings"})

    def _invalid_disposition_fixture(self):
        fixture = self._continuation_fixture()
        run_id = fixture["run_id"]
        workstream = "review-sample"
        target_workstream = "sample"
        active = fixture["active"]
        target_path = fixture["target"]
        archived_path = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
        reviewed_main = fixture["reviewed_main"]
        receipt = {
            "Schema": "custodian.paired_review.v1", "Review workstream": workstream,
            "Review target workstream": target_workstream, "Status": "passed",
            "Blocking defects": "0", "Material gaps": "0", "Reviewer context": "fresh",
            "Reviewer provenance": "same-agent-fresh-context", "Reviewed main": reviewed_main,
            "Reviewed implementation commit": reviewed_main,
        }
        receipt_block = f"### Review Receipt: {workstream}\n" + "".join(
            f"- {key}: `{value}`\n" for key, value in (
                ("Schema", receipt["Schema"]), ("Review workstream", receipt["Review workstream"]),
                ("Review target workstream", receipt["Review target workstream"]), ("Status", receipt["Status"]),
                ("Blocking defects", receipt["Blocking defects"]), ("Material gaps", receipt["Material gaps"]),
                ("Reviewer context", receipt["Reviewer context"]),
                ("Reviewer provenance", receipt["Reviewer provenance"]),
                ("Reviewed main", receipt["Reviewed main"]),
                ("Reviewed implementation commit", receipt["Reviewed implementation commit"]),
            )
        )
        archived = fixture["review"].replace("- Status: `ready`", "- Status: `complete`")
        archived += "\n## Independent Review\n\nReviewer PASS evidence.\n\n" + receipt_block + "\n"
        archived += runner.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=workstream, target_workstream=target_workstream,
            reviewed_main=reviewed_main, implementation_commit=reviewed_main,
            provenance="same-agent-fresh-context", run_id=run_id, review_cycle=0, ids=(),
        )
        archived += ("- Refresh reason: `none`\n- Next action: `Plan only.`\n"
                     "- Blockers or open questions: `No blocker.`\n\n"
                     "Authoring chat: https://chatgpt.com/c/continuation-test\n")
        archive_file = fixture["worktree"] / archived_path
        archive_file.parent.mkdir(parents=True, exist_ok=True)
        archive_file.write_text(archived)
        fixture["prior_summary"].unlink(missing_ok=True)
        summary = fixture["worktree"] / runner.expected_summary_path(workstream)
        summary.write_text(f"Review outcome: passed\nRun ID: {run_id}\nAuthoring chat: {fixture['chat']}\n")
        continuation = fixture["run_dir"] / "continuation-01"
        evidence = continuation / "recovery-evidence"
        evidence.mkdir(parents=True)
        preserved = evidence / "original-malformed-review-disposition.md"
        preserved.write_bytes(archived.encode())
        digest = hashlib.sha256(archived.encode()).hexdigest()
        (evidence / "original-malformed-review-disposition.json").write_text(json.dumps({
            "schema": "custodian.paired_review_invalid_disposition_preservation.v1",
            "workstream": workstream, "run_id": run_id, "repair_applied": False,
            "preserved_path": str(preserved), "source_path": str(archive_file),
            "sha256": digest, "size_bytes": len(archived.encode()),
        }))
        preserved_copy = continuation / "preserved-reviewer-files/02-REVIEW_SAMPLE.md"
        preserved_copy.parent.mkdir(parents=True)
        preserved_copy.write_bytes(archived.encode())
        report = fixture["run_dir"] / "validation.json"
        report.write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": True,
            "coverage": {"complete": True}, "tests": [{"id": "test", "status": "passed"}],
        }))
        coordinator = fixture["run_dir"] / "coordinator-validation.json"
        coordinator.write_text(json.dumps({
            "schema": "custodian.paired_review_host_validation.v1",
            "worktree": str(fixture["worktree"]), "reviewed_main": reviewed_main,
            "implementation_commit": reviewed_main,
        }))
        original = {
            "schema": runner.SCHEMA, "run_id": run_id, "workstream": workstream,
            "phase": "post_exit_recovery", "run_dir": str(fixture["run_dir"]),
            "branch": "agent/review-sample", "worktree": str(fixture["worktree"]),
            "packet": active, "reviewed_main": reviewed_main,
            "host_validation": {
                "report_path": str(report), "report_sha256": hashlib.sha256(report.read_bytes()).hexdigest(),
                "metadata_sha256": hashlib.sha256(coordinator.read_bytes()).hexdigest(),
            },
        }
        (fixture["run_dir"] / "metadata.json").write_text(json.dumps(original))
        (fixture["run_dir"] / "last-message.txt").write_text(
            f"Review outcome: passed\nRun ID {run_id}\nsame-agent-fresh-context\n")
        # The continuation's preserved-file manifest is an independent immutable copy.
        child = {
            "schema": runner.CONTINUATION_SCHEMA, "workstream": workstream, "run_id": run_id,
            "phase": "invalid_reviewer_disposition",
            "disposition_error": "Review Outcome contains non-canonical content",
            "branch": "agent/review-sample", "worktree": str(fixture["worktree"]),
            "active_packet_path": active, "target_workstream": target_workstream,
            "target_packet_path": target_path, "reviewed_main": reviewed_main,
            "implementation_commit": reviewed_main, "review_cycle": 0,
            "authoring_chat": fixture["chat"],
            "preserved_files": [{"copy": str(preserved_copy), "sha256": digest}],
        }
        child["run_evidence_sha256"] = runner._file_manifest(fixture["run_dir"], omit=continuation)
        (continuation / "metadata.json").write_text(json.dumps(child))
        (continuation / "last-message.txt").write_text(
            f"Review outcome: passed\nRun ID {run_id}\nsame-agent-fresh-context\n")
        with patch.object(runner, "INVALID_DISPOSITION_WORKSTREAM", workstream), \
             patch.object(runner, "INVALID_DISPOSITION_RUN_ID", run_id), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET", target_workstream), \
             patch.object(runner, "INVALID_DISPOSITION_IMPLEMENTATION", reviewed_main), \
             patch.object(runner, "INVALID_DISPOSITION_SHA256", digest), \
             patch.object(runner, "INVALID_DISPOSITION_ACTIVE_PACKET", active), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET_PACKET", target_path), \
             patch.object(runner, "INVALID_DISPOSITION_REVIEW_PACKET", archived_path):
            fixture.update({"workstream": workstream, "target_workstream": target_workstream,
                            "review_packet_path": archived_path, "continuation": continuation,
                            "preserved": preserved, "original_manifest": child["run_evidence_sha256"],
                            "reviewer_receipt": receipt, "archived_bytes": archived.encode()})
        return fixture

    def test_exact_invalid_disposition_recovery_repairs_only_review_artifacts(self):
        fixture = self._invalid_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        workstream, run_id = fixture["workstream"], fixture["run_id"]
        reviewed_main = fixture["reviewed_main"]
        original_report = (fixture["run_dir"] / "validation.json").read_bytes()
        original_coord = (fixture["run_dir"] / "coordinator-validation.json").read_bytes()
        with patch.object(runner, "INVALID_DISPOSITION_WORKSTREAM", workstream), \
             patch.object(runner, "INVALID_DISPOSITION_RUN_ID", run_id), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET", fixture["target_workstream"]), \
             patch.object(runner, "INVALID_DISPOSITION_IMPLEMENTATION", reviewed_main), \
             patch.object(runner, "INVALID_DISPOSITION_SHA256", hashlib.sha256(fixture["archived_bytes"]).hexdigest()), \
             patch.object(runner, "INVALID_DISPOSITION_ACTIVE_PACKET", fixture["active"]), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET_PACKET", fixture["target"]), \
             patch.object(runner, "INVALID_DISPOSITION_REVIEW_PACKET", fixture["review_packet_path"]), \
             patch.object(runner, "verify_coordinator_validation") as verify:
            child_path = fixture["continuation"] / "metadata.json"
            original = json.loads((fixture["run_dir"] / "metadata.json").read_text())
            child = json.loads(child_path.read_text())
            with patch.object(runner, "resolve_target_implementation_commit", return_value=(reviewed_main, None)):
                recovered = runner._recover_exact_invalid_disposition(
                    fixture["repo"], fixture["run_dir"], fixture["continuation"], original, child,
                )
            verify.assert_called_once()
        archive = (fixture["worktree"] / fixture["review_packet_path"]).read_text()
        target = (fixture["worktree"] / fixture["target"]).read_text()
        outcome, error = runner.review_outcome.parse_review_outcome(archive)
        self.assertIsNone(error)
        self.assertEqual(outcome["Outcome"], "passed")
        self.assertEqual(recovered["phase"], "coordinator_closeout")
        self.assertTrue(recovered["root_sync_deferral"]["root_sync_pending"])
        receipt, receipt_error = verify_review_receipt_delta(
            fixture["target_content"], target, review_workstream=workstream,
            target_workstream=fixture["target_workstream"], reviewed_main=reviewed_main,
            target_implementation_commit=reviewed_main,
        )
        self.assertIsNone(receipt_error)
        self.assertEqual(receipt, fixture["reviewer_receipt"])
        self.assertEqual(fixture["preserved"].read_bytes(), fixture["archived_bytes"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"], omit=fixture["continuation"]),
                         fixture["original_manifest"])
        self.assertEqual((fixture["run_dir"] / "validation.json").read_bytes(), original_report)
        self.assertEqual((fixture["run_dir"] / "coordinator-validation.json").read_bytes(), original_coord)

    def test_exact_invalid_disposition_recovery_rejects_changed_manifest_before_packet_writes(self):
        fixture = self._invalid_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        (fixture["run_dir"] / "RECOVERY.md").write_text("changed evidence\n")
        archive_path = fixture["worktree"] / fixture["review_packet_path"]
        original_archive = archive_path.read_bytes()
        target_path = fixture["worktree"] / fixture["target"]
        original_target = target_path.read_bytes()
        with patch.object(runner, "INVALID_DISPOSITION_WORKSTREAM", fixture["workstream"]), \
             patch.object(runner, "INVALID_DISPOSITION_RUN_ID", fixture["run_id"]), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET", fixture["target_workstream"]), \
             patch.object(runner, "INVALID_DISPOSITION_IMPLEMENTATION", fixture["reviewed_main"]), \
             patch.object(runner, "INVALID_DISPOSITION_SHA256", hashlib.sha256(fixture["archived_bytes"]).hexdigest()), \
             patch.object(runner, "INVALID_DISPOSITION_ACTIVE_PACKET", fixture["active"]), \
             patch.object(runner, "INVALID_DISPOSITION_TARGET_PACKET", fixture["target"]), \
             patch.object(runner, "INVALID_DISPOSITION_REVIEW_PACKET", fixture["review_packet_path"]):
            with self.assertRaisesRegex(runner.RunnerError, "evidence manifest changed"):
                runner._recover_exact_invalid_disposition(
                    fixture["repo"], fixture["run_dir"], fixture["continuation"],
                    json.loads((fixture["run_dir"] / "metadata.json").read_text()),
                    json.loads((fixture["continuation"] / "metadata.json").read_text()),
                )
        self.assertEqual(archive_path.read_bytes(), original_archive)
        self.assertEqual(target_path.read_bytes(), original_target)

    def test_exact_invalid_disposition_recovery_rejects_mismatched_claim_and_target_identity(self):
        for mismatch in ("claim", "target"):
            with self.subTest(mismatch=mismatch):
                fixture = self._invalid_disposition_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                child_path = fixture["continuation"] / "metadata.json"
                child = json.loads(child_path.read_text())
                original = json.loads((fixture["run_dir"] / "metadata.json").read_text())
                if mismatch == "target":
                    child["target_packet_path"] = "custodian/docs/ai_context/task_packets/archived/FOREIGN.md"
                else:
                    claim_path = fixture["run_dir"] / "claim-receipt.json"
                    claim = json.loads(claim_path.read_text())
                    claim["worktree"] = str(fixture["repo"] / "foreign-worktree")
                    claim_path.write_text(json.dumps(claim))
                    (fixture["run_dir"] / "claim.stdout").write_text(
                        runner.CLAIM_SENTINEL + json.dumps(claim, sort_keys=True) + "\n")
                    child["run_evidence_sha256"] = runner._file_manifest(
                        fixture["run_dir"], omit=fixture["continuation"])
                archive_path = fixture["worktree"] / fixture["review_packet_path"]
                target_path = fixture["worktree"] / fixture["target"]
                before_archive, before_target = archive_path.read_bytes(), target_path.read_bytes()
                with patch.object(runner, "INVALID_DISPOSITION_WORKSTREAM", fixture["workstream"]), \
                     patch.object(runner, "INVALID_DISPOSITION_RUN_ID", fixture["run_id"]), \
                     patch.object(runner, "INVALID_DISPOSITION_TARGET", fixture["target_workstream"]), \
                     patch.object(runner, "INVALID_DISPOSITION_IMPLEMENTATION", fixture["reviewed_main"]), \
                     patch.object(runner, "INVALID_DISPOSITION_SHA256", hashlib.sha256(fixture["archived_bytes"]).hexdigest()), \
                     patch.object(runner, "INVALID_DISPOSITION_ACTIVE_PACKET", fixture["active"]), \
                     patch.object(runner, "INVALID_DISPOSITION_TARGET_PACKET", fixture["target"]), \
                     patch.object(runner, "INVALID_DISPOSITION_REVIEW_PACKET", fixture["review_packet_path"]):
                    with self.assertRaises(runner.RunnerError):
                        runner._recover_exact_invalid_disposition(
                            fixture["repo"], fixture["run_dir"], fixture["continuation"], original, child,
                        )
                self.assertEqual(archive_path.read_bytes(), before_archive)
                self.assertEqual(target_path.read_bytes(), before_target)

    def test_reviewer_writable_roots_are_the_exact_custodian_namespaces(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repo = base / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            scratch = base / "review-scratch"
            xdg = base / "xdg-cache"
            with patch.dict(os.environ, {
                "CUSTODIAN_SCRATCH_DIR": str(scratch),
                "XDG_CACHE_HOME": str(xdg),
            }):
                roots = runner.reviewer_cache_roots(repo)
                home = godot_home()
                self.assertEqual(home, scratch / "godot-home")
                home_probe = home / "reviewer-home-write-probe"
                home_probe.write_text("writable\n")
                self.assertEqual(home_probe.read_text(), "writable\n")
            self.assertEqual(roots, sorted([scratch.resolve(), (xdg / "custodian").resolve()], key=str))
            self.assertTrue(scratch.is_dir())
            self.assertTrue((xdg / "custodian").is_dir())
            common = runner.common_dir(repo).resolve()
            self.assertTrue(all(root != common and root not in common.parents and common not in root.parents
                                for root in roots))
            with patch.dict(os.environ, {
                "CUSTODIAN_SCRATCH_DIR": str(xdg / "custodian"),
                "XDG_CACHE_HOME": str(xdg),
            }):
                self.assertEqual(runner.reviewer_cache_roots(repo), [(xdg / "custodian").resolve()])

    def test_reviewer_cache_permission_shares_the_coordinator_job_slot(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repo = base / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            cache_home = base / "cache-home"
            env = os.environ.copy()
            env["XDG_CACHE_HOME"] = str(cache_home)
            env[MAX_JOBS_ENV] = "1"
            env.pop(BUDGET_REENTRANCY_ENV, None)
            env.pop(BUDGET_FD_ENV, None)
            code = (
                "import sys; sys.path.insert(0, %r); "
                "from godot_project_lock import GodotJobBudget; "
                "with_budget = GodotJobBudget('reviewer-probe', timeout_sec=5); "
                "with_budget.__enter__(); print('ACQUIRED', flush=True); with_budget.__exit__(None, None, None)"
            ) % str(ROOT / "custodian/tools")
            with patch.dict(os.environ, env, clear=True):
                roots = runner.reviewer_cache_roots(repo)
                self.assertIn(job_budget_root(), roots)
                with GodotJobBudget("coordinator-probe", timeout_sec=2) as coordinator:
                    self.assertTrue(coordinator.acquired)
                    self.assertIn(coordinator.path.parent.parent.resolve(), roots)
                    child = subprocess.Popen([sys.executable, "-c", code], env=env,
                                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    with self.assertRaises(subprocess.TimeoutExpired):
                        child.communicate(timeout=0.3)
                stdout, stderr = child.communicate(timeout=5)
                self.assertEqual(child.returncode, 0, stderr)
                self.assertIn("ACQUIRED", stdout)

    def test_reviewer_cache_root_refuses_shared_git_metadata(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp) / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            common = runner.common_dir(repo)
            with patch.dict(os.environ, {
                "CUSTODIAN_SCRATCH_DIR": str(common / "scratch"),
                "XDG_CACHE_HOME": str(Path(temp) / "cache"),
            }):
                with self.assertRaisesRegex(runner.RunnerError, "overlaps shared Git metadata"):
                    runner.reviewer_cache_roots(repo)

    def test_real_archived_correction_target_keeps_exact_blob_and_resolves_landing(self):
        pinned_main = "607c76aba831ed5fcc313f00489e10df75a8a375"
        target_path = (
            "custodian/docs/ai_context/task_packets/archived/"
            "AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md"
        )
        target_workstream = "agent-paired-review-coordinator-boundary-v1-review-corrections-1"
        baseline = read_git_text(ROOT, pinned_main, target_path)

        self.assertTrue(baseline.endswith("\n"))
        self.assertFalse(re.search(r"(?m)^- Implementation commit:", baseline))
        self.assertNotEqual(runner.git(ROOT, "show", f"{pinned_main}:{target_path}"), baseline)
        implementation, error = resolve_target_implementation_commit(
            ROOT, pinned_main, target_path, target_workstream, baseline,
        )
        self.assertIsNone(error)
        self.assertEqual(implementation, "16b9dfdd6ce09889b85c61372e02d0eccea5de76")

        candidate = append_receipt(
            baseline, review_workstream="review-agent-paired-review-coordinator-boundary-v1-review-corrections-1",
            target_workstream=target_workstream, reviewed_main=pinned_main,
            implementation_commit=implementation,
        )
        receipt, error = verify_review_receipt_delta(
            baseline, candidate,
            review_workstream="review-agent-paired-review-coordinator-boundary-v1-review-corrections-1",
            target_workstream=target_workstream, reviewed_main=pinned_main,
            target_implementation_commit=implementation,
        )
        self.assertIsNone(error)
        self.assertEqual(receipt["Reviewed implementation commit"], implementation)

    def test_real_surface_lift_archive_resolves_unique_landing_without_follow_ambiguity(self):
        pinned_main = "be58b0b845499f1e4340c8217c09304ab3667904"
        target_path = (
            "custodian/docs/ai_context/task_packets/archived/"
            "ASH_BELL_SURFACE_LIFT_V2_ASSET_INTAKE.md"
        )
        target_workstream = "ash-bell-surface-lift-v2-asset-intake"
        baseline = read_git_text(ROOT, pinned_main, target_path)

        self.assertFalse(re.search(r"(?m)^- Implementation commit:", baseline))
        implementation, error = resolve_target_implementation_commit(
            ROOT, pinned_main, target_path, target_workstream, baseline,
        )
        self.assertIsNone(error)
        self.assertEqual(implementation, "f3b94d0768bc110755f2b9be1d1e60d22fe1577c")

    def test_legacy_archive_identity_rejects_ambiguous_reintroduction_and_wrong_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.name", "Test"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.test"], cwd=repo, check=True)
            target_path = "custodian/docs/ai_context/task_packets/archived/TARGET.md"
            target = repo / target_path
            target.parent.mkdir(parents=True)
            target.write_text(
                "# Target\n- Workstream: `target-impl`\n- Kind: `correction`\n"
                "- Status: `complete`\n- Reviewed main: `0000000000000000000000000000000000000000`\n"
            )
            subprocess.run(["git", "add", target_path], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "archive target"], cwd=repo, check=True)
            first_archive = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, text=True,
                                           check=True, capture_output=True).stdout.strip()
            target.unlink()
            subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "remove target"], cwd=repo, check=True)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(
                "# Target\n- Workstream: `target-impl`\n- Kind: `correction`\n"
                "- Status: `complete`\n- Reviewed main: `0000000000000000000000000000000000000000`\n"
            )
            subprocess.run(["git", "add", target_path], cwd=repo, check=True)
            subprocess.run(["git", "commit", "-qm", "reintroduce target"], cwd=repo, check=True)
            pinned_main = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, text=True,
                                        check=True, capture_output=True).stdout.strip()

            _, error = resolve_target_implementation_commit(repo, pinned_main, target_path, "target-impl")
            self.assertEqual(error, "pinned target has no unique complete archive-introduction commit")
            _, error = resolve_target_implementation_commit(repo, pinned_main, target_path, "other-impl")
            self.assertEqual(error, "pinned target is not one complete identified implementation packet")
            self.assertNotEqual(first_archive, pinned_main)

    def test_review_receipt_delta_allows_only_one_valid_append(self):
        main = "b" * 40
        implementation = "a" * 40
        baseline = target_packet(implementation)
        valid = append_receipt(baseline, review_workstream="review-sample", target_workstream="sample-impl",
                               reviewed_main=main, implementation_commit=implementation)
        receipt, error = verify_review_receipt_delta(
            baseline, valid, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNone(error)
        self.assertEqual(receipt["Reviewed implementation commit"], implementation)
        for changed in (
            valid.replace("Status: `passed`", "Status: `findings`"),
            valid.replace("Reviewer provenance: `different-agent`", "Reviewer provenance: `unspecified`"),
            valid.replace(main, "c" * 40),
            valid.replace(implementation, "d" * 40),
            valid.replace("Review workstream: `review-sample`", "Review workstream: `review-spoof`"),
            valid.replace("Review target workstream: `sample-impl`", "Review target workstream: `other-impl`"),
            valid.replace("- Status: `complete`", "- Status: `draft`"),
            valid.replace("Retain the exact implementation goal", "Rewrite the goal"),
            valid.replace("Retain the exact acceptance contract", "Rewrite acceptance"),
            valid.replace("Completion boundary satisfied: `yes`", "Completion boundary satisfied: `no`"),
            valid.replace("return true", "return false"),
            valid + "\n## Independent Review\n\n- Status: `passed`\n",
            valid + "\n### Review Receipt: review-sample\n",
        ):
            _, error = verify_review_receipt_delta(
                baseline, changed, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=main, target_implementation_commit=implementation)
            self.assertIsNotNone(error, changed)

    def test_review_receipt_delta_preserves_prior_receipt_bytes(self):
        main = "b" * 40
        implementation = "a" * 40
        baseline = append_receipt(target_packet(implementation), review_workstream="review-old",
                                  target_workstream="sample-impl", reviewed_main=main,
                                  implementation_commit=implementation)
        candidate = append_receipt(baseline, review_workstream="review-sample",
                                   target_workstream="sample-impl", reviewed_main=main,
                                   implementation_commit=implementation)
        receipt, error = verify_review_receipt_delta(
            baseline, candidate, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNone(error)
        self.assertEqual(receipt["Review workstream"], "review-sample")
        tampered = candidate.replace("Reviewer context: `fresh`", "Reviewer context: `stale`", 1)
        _, error = verify_review_receipt_delta(
            baseline, tampered, review_workstream="review-sample", target_workstream="sample-impl",
            reviewed_main=main, target_implementation_commit=implementation)
        self.assertIsNotNone(error)

    def test_prior_claimed_run_blocks_reclaim_until_recovered(self):
        with tempfile.TemporaryDirectory() as temp:
            common = Path(temp)
            old_run = common / "custodian-review-runs/review-sample/old-run"
            old_run.mkdir(parents=True)
            (old_run / "metadata.json").write_text(json.dumps({"workstream": "review-sample",
                                                               "phase": "post_exit_recovery"}))
            self.assertEqual(runner.unresolved_prior_run(common, "review-sample", "new-run"), old_run)
            metadata = json.loads((old_run / "metadata.json").read_text())
            metadata["phase"] = "complete"
            (old_run / "metadata.json").write_text(json.dumps(metadata))
            self.assertIsNone(runner.unresolved_prior_run(common, "review-sample", "new-run"))

    def _continuation_fixture(self, *, receipt=True):
        temp = tempfile.TemporaryDirectory()
        base = Path(temp.name)
        repo = base / "repo"
        repo.mkdir()
        subprocess.run(["git", "init", "-q", "-b", "main", str(repo)], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.name", "Test"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
        remote = base / "remote.git"
        subprocess.run(["git", "init", "-q", "--bare", str(remote)], check=True)
        subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", str(remote)], check=True)
        active = f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md"
        target = f"{runner.PACKET_ROOT}/archived/SAMPLE.md"
        chat = "https://chatgpt.com/c/continuation-test"
        review = review_packet().replace("sample-impl", "sample").replace("SAMPLE_IMPL.md", "SAMPLE.md").replace(
            "- Visual review: `none`", f"- Visual review: `none`\n- Authoring chat: `{chat}`")
        (repo / active).parent.mkdir(parents=True, exist_ok=True)
        (repo / active).write_text(review)
        target_file = repo / target
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_text(target_packet().replace("sample-impl", "sample"))
        target_content = target_file.read_text()
        summary = repo / runner.expected_summary_path("sample")
        summary.write_text(f"Implementation summary\nAuthoring chat: {chat}\n")
        subprocess.run(["git", "-C", str(repo), "add", active, target, summary.relative_to(repo).as_posix()], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-qm", "baseline"], check=True)
        reviewed_main = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                       text=True, capture_output=True).stdout.strip()
        subprocess.run(["git", "-C", str(repo), "push", "-q", "origin", "main"], check=True)
        worktree = base / "review-worktree"
        subprocess.run(["git", "-C", str(repo), "worktree", "add", "-q", "-b", "agent/review-sample",
                        str(worktree), reviewed_main], check=True)
        subprocess.run(["git", "-C", str(worktree), "push", "-q", "-u", "origin", "agent/review-sample"], check=True)
        (worktree / active).write_text(review + "\n## Previous Review Disposition\n\nBlocked pending continuation.\n")
        prior_summary = worktree / "SAMPLE_REVIEW_CLAUDE_SUMMARY.md"
        prior_summary.write_text("Original reviewer notes: blocked before complete regressions.\n")
        run_id = "20261017T120000Z-012345abcdef"
        common = runner.common_dir(repo)
        run_dir = common / "custodian-review-runs" / "review-sample" / run_id
        run_dir.mkdir(parents=True)
        report = {"schema": "custodian.validation.result.v1", "passed": True,
                  "coverage": {"complete": True}, "tests": [{"id": "test", "status": "passed"}]}
        (run_dir / "validation.json").write_text(json.dumps(report))
        (run_dir / "coordinator-validation.json").write_text(json.dumps({
            "schema": "custodian.paired_review_host_validation.v1",
            "worktree": str(worktree), "reviewed_main": reviewed_main,
            "implementation_commit": "a" * 40,
        }))
        (run_dir / "codex.jsonl").write_text("original reviewer log\n")
        receipt_value = {"schema": "custodian.dispatch.claim.v1", "result": "claimed",
                         "workstream": "review-sample", "verified": True,
                         "worktree": str(worktree), "branch": "agent/review-sample", "packet": active}
        if receipt:
            (run_dir / "claim-receipt.json").write_text(json.dumps(receipt_value))
            (run_dir / "claim.stdout").write_text(
                runner.CLAIM_SENTINEL + json.dumps(receipt_value) + "\n")
        metadata = {
            "schema": runner.SCHEMA, "run_id": run_id, "workstream": "review-sample",
            "phase": "post_exit_recovery", "run_dir": str(run_dir),
            "branch": "agent/review-sample", "worktree": str(worktree), "packet": active,
            "reviewed_main": reviewed_main,
            "host_validation": {"report_path": str(run_dir / "validation.json"),
                                "report_sha256": "c" * 64, "metadata_sha256": "d" * 64},
        }
        (run_dir / "metadata.json").write_text(json.dumps(metadata))
        return {"temp": temp, "repo": repo, "worktree": worktree, "run_dir": run_dir,
                "active": active, "target": target, "review": review, "chat": chat,
                "reviewed_main": reviewed_main, "run_id": run_id, "receipt": receipt_value,
                "prior_summary": prior_summary, "target_content": target_content,
                "landed": {"complete": False, "revision": "f" * 40}}

    def _prepare_host_recovery(self, fixture, *, reports=True):
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata.update({"phase": "host_validation_recovery",
                         "reviewed_main": fixture["reviewed_main"],
                         "implementation_commit": "a" * 40,
                         "recovery_worktree": str(fixture["worktree"])})
        # The real failed prelaunch run predates durable branch/packet copies in
        # metadata; those identities come from the original verified receipt.
        for key in ("branch", "worktree", "packet"):
            metadata.pop(key, None)
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        (fixture["run_dir"] / "RECOVERY.md").write_text("preserved host-validation failure\n")
        if reports:
            (fixture["run_dir"] / "validation.json").write_text('{"passed":false}\n')
            (fixture["run_dir"] / "coordinator-validation.json").write_text('{"failed":true}\n')
        else:
            metadata.pop("host_validation", None)
            metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
            (fixture["run_dir"] / "validation.json").unlink(missing_ok=True)
            (fixture["run_dir"] / "coordinator-validation.json").unlink(missing_ok=True)
        lock = runner.common_dir(fixture["repo"]) / "custodian-review-runs/locks/review-sample.lock"
        lock.parent.mkdir(parents=True, exist_ok=True)
        lock.touch(exist_ok=True)
        return runner._file_manifest(fixture["run_dir"])

    def test_host_recovery_plan_accepts_verified_prevalidation_interruption_read_only(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture, reports=False)
        self._make_host_recovery_worktree_clean(fixture)
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["implementation_commit"] = fixture["reviewed_main"]
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        original_manifest = runner._file_manifest(fixture["run_dir"])
        span = {"base": "8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8",
                "head": "5b5de5717ae10aa5bbacbd53433571aae016c555",
                "commits": ["5b5de5717ae10aa5bbacbd53433571aae016c555"],
                "paths": ["custodian/tools/agent/sample.py"],
                "provenance": {"kind": "verified-test-fixture"}}
        with patch.object(runner, "resolve_target_implementation_commit",
                          return_value=(fixture["reviewed_main"], None)), \
             patch.object(host_validation, "resolve_validation_source_span", return_value=span):
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"])
        self.assertEqual(plan["host_validation_state"], "pre_validation_interrupted")
        self.assertTrue(plan["requires_fresh_host_validation"])
        self.assertEqual(plan["source_span"]["base"], "8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8")
        self.assertEqual(plan["evidence_sha256"].keys(), {"metadata.json", "claim.stdout"})
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), original_manifest)
        self.assertFalse((fixture["run_dir"] / "validation.json").exists())
        self.assertFalse((fixture["run_dir"] / "coordinator-validation.json").exists())
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_failed_import_recovery_plan_is_read_only_and_pins_exact_sidecars_and_failed_pair(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture)
        repo, worktree, run_dir = fixture["repo"], fixture["worktree"], fixture["run_dir"]
        code_paths = ["custodian/tools/agent/paired_review_runner.py",
                      "custodian/tools/agent/test_paired_review_runner.py"]
        for path in code_paths:
            target = repo / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("pinned validation source\n")
        sidecar_paths = set(host_validation.FAILED_IMPORT_RECOVERY_SIDECARS)
        sources = sorted(path[:-len(".import")] for path in sidecar_paths)
        for source in sources:
            (repo / source).parent.mkdir(parents=True, exist_ok=True)
            (repo / source).write_bytes(b"tracked image fixture")
        subprocess.run(["git", "-C", str(repo), "add", *code_paths, *sources], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-qm", "pin recovery sources"], check=True)
        reviewed_main = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                       text=True, capture_output=True).stdout.strip()
        subprocess.run(["git", "-C", str(repo), "push", "-q", "origin", "main"], check=True)
        subprocess.run(["git", "-C", str(worktree), "merge", "--ff-only", "main"], check=True,
                       capture_output=True)
        subprocess.run(["git", "-C", str(worktree), "push", "-q", "origin", "agent/review-sample"], check=True)
        self._make_host_recovery_worktree_clean(fixture)
        fixture["reviewed_main"] = reviewed_main
        metadata_path = run_dir / "metadata.json"
        original = json.loads(metadata_path.read_text())
        original.update({"reviewed_main": reviewed_main, "implementation_commit": "a" * 40,
                         "recovery_worktree": str(worktree)})
        original.pop("host_validation", None)
        metadata_path.write_text(json.dumps(original, sort_keys=True) + "\n")
        for name in ("validation.json", "coordinator-validation.json"):
            (run_dir / name).unlink(missing_ok=True)
        report = {"schema": "custodian.validation.result.v1", "passed": False,
                  "infrastructure_failure": "import"}
        report_bytes = (json.dumps(report) + "\n").encode()
        (run_dir / "validation.json").write_bytes(report_bytes)
        (run_dir / "coordinator-validation.json").write_text(json.dumps({
            "schema": "custodian.paired_review_host_validation.v1",
            "worktree": str(worktree), "reviewed_main": reviewed_main,
            "implementation_commit": "a" * 40, "implementation_parent": reviewed_main,
            "code_paths": code_paths,
            "source_sha256": {path: hashlib.sha256((repo / path).read_bytes()).hexdigest()
                              for path in code_paths},
            "exit_code": 3, "source_changed_during_validation": True,
            "report_path": str((run_dir / "validation.json").resolve()),
            "report_sha256": hashlib.sha256(report_bytes).hexdigest(),
            "report_parse_error": None,
        }))
        for sidecar_path in sorted(sidecar_paths):
            source = sidecar_path[:-len(".import")]
            (worktree / sidecar_path).write_text(
                "[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n"
                "uid=\"uid://fixture123\"\npath=\"res://.godot/imported/candidate.ctex\"\n\n"
                "[deps]\n\nsource_file=\"res://" + source.removeprefix("custodian/") + "\"\n"
                "dest_files=[\"res://.godot/imported/candidate.ctex\"]\n\n[params]\ncompress/mode=0\n")
        source_span = {"base": reviewed_main, "head": reviewed_main,
                       "paths": code_paths, "provenance": {"kind": "synthetic-test"}}
        before = runner._file_manifest(run_dir)
        with patch.object(runner, "FAILED_IMPORT_RECOVERY_WORKSTREAM", "review-sample"), \
             patch.object(runner, "FAILED_IMPORT_RECOVERY_RUN_ID", fixture["run_id"]), \
             patch.object(host_validation, "FAILED_IMPORT_RECOVERY_WORKSTREAM", "review-sample"), \
             patch.object(host_validation, "FAILED_IMPORT_RECOVERY_RUN_ID", fixture["run_id"]), \
             patch.object(host_validation, "FAILED_IMPORT_RECOVERY_SIDECARS", sidecar_paths), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
             patch.object(host_validation, "resolve_validation_source_span", return_value=source_span):
            plan = runner.plan_host_validation_recovery(repo, "review-sample", fixture["run_id"])
            self.assertEqual(plan["host_validation_state"], "failed_import")
            self.assertTrue(plan["requires_fresh_host_validation"])
            self.assertEqual(plan["host_validation_attempt"], 1)
            self.assertEqual(len(plan["generated_import_sidecars"]), 12)
            self.assertEqual({item["sidecar_path"] for item in plan["generated_import_sidecars"]}, sidecar_paths)
            self.assertEqual(plan["failed_validation_evidence"]["report_sha256"],
                             hashlib.sha256(report_bytes).hexdigest())
            self.assertEqual(runner._file_manifest(run_dir), before)
            first_sidecar = sorted(sidecar_paths)[0]
            self.assertTrue((worktree / first_sidecar).is_file())
            (worktree / first_sidecar).write_text("[remap]\nimporter=\"texture\"\n")
            with self.assertRaisesRegex(runner.RunnerError, "malformed"):
                runner.plan_host_validation_recovery(repo, "review-sample", fixture["run_id"])

    def test_host_recovery_plan_rejects_partial_reports_or_prior_validation_pins(self):
        for report_name, metadata_pin in (("validation.json", None), (None, "host_validation"),
                                          (None, "validation_evidence_sha256")):
            with self.subTest(report_name=report_name, metadata_pin=metadata_pin):
                fixture = self._continuation_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                self._prepare_host_recovery(fixture, reports=False)
                self._make_host_recovery_worktree_clean(fixture)
                if report_name:
                    (fixture["run_dir"] / report_name).write_text('{"passed":true}\n')
                else:
                    metadata_path = fixture["run_dir"] / "metadata.json"
                    metadata = json.loads(metadata_path.read_text())
                    metadata[metadata_pin] = {"report_sha256": "a" * 64}
                    metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
                span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                        "paths": ["custodian/tools/agent/sample.py"],
                        "provenance": {"kind": "test-fixture"}}
                with patch.object(runner, "resolve_target_implementation_commit",
                                  return_value=(fixture["reviewed_main"], None)), \
                     patch.object(host_validation, "resolve_validation_source_span", return_value=span), \
                     self.assertRaisesRegex(runner.RunnerError, "report|validation evidence|pinned"):
                    runner.plan_host_validation_recovery(
                        fixture["repo"], "review-sample", fixture["run_id"])

    def test_host_recovery_operator_attestations_must_be_paired(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture)
        with self.assertRaisesRegex(runner.RunnerError, "supplied together"):
            runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
                attest_no_active_owner=True,
            )

    def test_pinned_canonical_source_span_verifier_requires_exact_rename_aware_diff(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        changed = fixture["repo"] / "custodian/tools/agent/source.py"
        changed.parent.mkdir(parents=True, exist_ok=True)
        changed.write_text("validated source\n")
        subprocess.run(["git", "-C", str(fixture["repo"]), "add", str(changed.relative_to(fixture["repo"]))],
                       check=True)
        subprocess.run(["git", "-C", str(fixture["repo"]), "commit", "-qm", "implementation"], check=True)
        implementation = subprocess.run(["git", "-C", str(fixture["repo"]), "rev-parse", "HEAD"],
                                        check=True, text=True, capture_output=True).stdout.strip()
        parent = subprocess.run(["git", "-C", str(fixture["repo"]), "rev-parse", "HEAD^"],
                                check=True, text=True, capture_output=True).stdout.strip()
        source_span = {"base": parent, "head": implementation, "commits": [implementation],
                       "paths": ["custodian/tools/agent/source.py"],
                       "provenance": {"kind": "canonical-implementation-commit"}}
        self.assertEqual(host_validation.verify_pinned_canonical_commit_source_span(
            fixture["repo"], implementation, source_span), source_span)
        altered = {**source_span, "paths": ["custodian/tools/agent/other.py"]}
        with self.assertRaisesRegex(host_validation.HostValidationError, "exact canonical implementation"):
            host_validation.verify_pinned_canonical_commit_source_span(
                fixture["repo"], implementation, altered)

    def test_host_recovery_prevalidation_plan_rejects_mismatched_claim_and_existing_child(self):
        for mismatch in ("claim", "child"):
            with self.subTest(mismatch=mismatch):
                fixture = self._continuation_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                self._prepare_host_recovery(fixture, reports=False)
                self._make_host_recovery_worktree_clean(fixture)
                if mismatch == "claim":
                    claim_path = fixture["run_dir"] / "claim-receipt.json"
                    claim = json.loads(claim_path.read_text())
                    claim["worktree"] = str(fixture["repo"] / "foreign-worktree")
                    claim_path.write_text(json.dumps(claim))
                else:
                    child = fixture["run_dir"] / "continuation-01"
                    child.mkdir()
                    (child / "metadata.json").write_text(json.dumps({"phase": "interrupted"}))
                span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                        "paths": ["custodian/tools/agent/sample.py"],
                        "provenance": {"kind": "test-fixture"}}
                with patch.object(runner, "resolve_target_implementation_commit",
                                  return_value=(fixture["reviewed_main"], None)), \
                     patch.object(host_validation, "resolve_validation_source_span", return_value=span), \
                     self.assertRaisesRegex(runner.RunnerError, "claim|worktree|continuation"):
                    runner.plan_host_validation_recovery(
                        fixture["repo"], "review-sample", fixture["run_id"])

    def test_host_recovery_apply_rejects_original_manifest_changed_after_plan(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture, reports=False)
        self._make_host_recovery_worktree_clean(fixture)
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["implementation_commit"] = fixture["reviewed_main"]
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                "paths": ["custodian/tools/agent/sample.py"],
                "provenance": {"kind": "test-fixture"}}
        with patch.object(runner, "resolve_target_implementation_commit",
                          return_value=(fixture["reviewed_main"], None)), \
             patch.object(host_validation, "resolve_validation_source_span", return_value=span):
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"])
            (fixture["run_dir"] / "RECOVERY.md").write_text("changed after plan\n")
            with self.assertRaisesRegex(runner.RunnerError, "exact SHA-256"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True, recover_host_validation=True,
                    plan_sha256=plan["plan_sha256"],
                )
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def _make_host_recovery_worktree_clean(self, fixture):
        subprocess.run(["git", "-C", str(fixture["worktree"]), "restore", "--source",
                        fixture["reviewed_main"], "--staged", "--worktree", "--", fixture["active"]],
                       check=True)
        fixture["prior_summary"].unlink(missing_ok=True)

    def _prepare_carrow_missing_worktree_fixture(self, fixture):
        self._prepare_host_recovery(fixture)
        self._make_host_recovery_worktree_clean(fixture)
        run_dir = fixture["run_dir"]
        metadata_path = run_dir / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["implementation_commit"] = fixture["reviewed_main"]
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        report_bytes = b'{"passed":false}\n'
        (run_dir / "validation.json").write_bytes(report_bytes)
        coordinator = {"schema": "custodian.paired_review_host_validation.v1",
                      "reviewed_main": fixture["reviewed_main"],
                      "implementation_commit": fixture["reviewed_main"],
                      "report_sha256": hashlib.sha256(report_bytes).hexdigest(),
                      "source_changed_during_validation": False}
        (run_dir / "coordinator-validation.json").write_text(json.dumps(coordinator, sort_keys=True) + "\n")
        subprocess.run(["git", "-C", str(fixture["repo"]), "worktree", "remove", str(fixture["worktree"])],
                       check=True, capture_output=True)
        fixture["carrow_report_sha"] = hashlib.sha256(report_bytes).hexdigest()
        fixture["carrow_coordinator_sha"] = hashlib.sha256(
            (run_dir / "coordinator-validation.json").read_bytes()).hexdigest()
        fixture["carrow_run_manifest"] = runner._file_manifest(run_dir)

    def _carrow_plan_patches(self, fixture):
        from contextlib import ExitStack
        stack = ExitStack()
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_WORKSTREAM", "review-sample"))
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_RUN_ID", fixture["run_id"]))
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_REVIEWED_MAIN", fixture["reviewed_main"]))
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_IMPLEMENTATION", fixture["reviewed_main"]))
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_REPORTS", {
            "validation.json": fixture["carrow_report_sha"],
            "coordinator-validation.json": fixture["carrow_coordinator_sha"],
        }))
        stack.enter_context(patch.object(runner, "CARROW_MISSING_WORKTREE_RUN_MANIFEST",
                                         fixture["carrow_run_manifest"]))
        span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                "commits": [fixture["reviewed_main"]], "paths": ["custodian/tools/agent/sample.py"],
                "provenance": {"kind": "canonical-implementation-commit"}}
        stack.enter_context(patch.object(host_validation, "verify_pinned_canonical_commit_source_span",
                                         return_value=span))
        stack.enter_context(patch.object(runner, "resolve_target_implementation_commit",
                                         return_value=(fixture["reviewed_main"], None)))
        stack.enter_context(patch.object(host_validation, "resolve_validation_source_span", return_value=span))
        return stack, span

    def _relocate_carrow_fixture_checkout(self, fixture):
        destination = fixture["repo"].parent / ".custodian-worktrees" / fixture["worktree"].name
        destination.parent.mkdir(parents=True)
        self.assertFalse(destination.exists())
        fixture["worktree"] = destination
        receipt = dict(fixture["receipt"], worktree=str(destination))
        fixture["receipt"] = receipt
        (fixture["run_dir"] / "claim-receipt.json").write_text(json.dumps(receipt))
        (fixture["run_dir"] / "claim.stdout").write_text(
            runner.CLAIM_SENTINEL + json.dumps(receipt, sort_keys=True) + "\n")
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["recovery_worktree"] = str(destination)
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        fixture["carrow_run_manifest"] = runner._file_manifest(fixture["run_dir"])

    def test_carrow_missing_worktree_plan_is_exact_and_read_only(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_carrow_missing_worktree_fixture(fixture)
        stack, _ = self._carrow_plan_patches(fixture)
        with stack:
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
                attest_no_active_owner=True, attest_no_unique_evidence=True,
            )
        self.assertEqual(plan["host_validation_state"], "carrow_failed_nonimport_missing_worktree")
        self.assertTrue(plan["requires_fresh_host_validation"])
        self.assertEqual(plan["retry_budget"], 1)
        self.assertEqual(plan["operator_attestations"], {
            "no_active_review_owner": True,
            "no_unique_untracked_or_ignored_evidence": True,
        })
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), fixture["carrow_run_manifest"])
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_carrow_missing_worktree_plan_rejects_altered_historical_report(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_carrow_missing_worktree_fixture(fixture)
        (fixture["run_dir"] / "validation.json").write_bytes(b'{"passed":true}\n')
        stack, _ = self._carrow_plan_patches(fixture)
        with stack, self.assertRaisesRegex(runner.RunnerError, "seven-file manifest"):
            runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
                attest_no_active_owner=True, attest_no_unique_evidence=True,
            )

    def test_carrow_missing_worktree_plan_rejects_forged_claim_occupied_destination_and_foreign_checkout(self):
        for case in ("forged_claim", "occupied", "foreign_checkout"):
            with self.subTest(case=case):
                fixture = self._continuation_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                self._prepare_carrow_missing_worktree_fixture(fixture)
                if case == "forged_claim":
                    claim_path = fixture["run_dir"] / "claim-receipt.json"
                    claim = json.loads(claim_path.read_text())
                    claim["verified"] = False
                    claim_path.write_text(json.dumps(claim))
                elif case == "occupied":
                    fixture["worktree"].mkdir()
                    (fixture["worktree"] / "preserve.txt").write_text("foreign bytes")
                else:
                    alternate = fixture["repo"].parent / "foreign-review-checkout"
                    subprocess.run(["git", "-C", str(fixture["repo"]), "worktree", "add",
                                    str(alternate), "agent/review-sample"], check=True, capture_output=True)
                stack, _ = self._carrow_plan_patches(fixture)
                pattern = {"forged_claim": "does not verify", "occupied": "destination is occupied",
                           "foreign_checkout": "already attached to another worktree"}[case]
                with stack, self.assertRaisesRegex(runner.RunnerError, pattern):
                    runner.plan_host_validation_recovery(
                        fixture["repo"], "review-sample", fixture["run_id"],
                        attest_no_active_owner=True, attest_no_unique_evidence=True,
                    )

    def test_carrow_missing_worktree_plan_rejects_local_and_remote_branch_movement(self):
        for case in ("local", "remote"):
            with self.subTest(case=case):
                fixture = self._continuation_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                self._prepare_carrow_missing_worktree_fixture(fixture)
                repo = fixture["repo"]
                new_commit = subprocess.run(
                    ["git", "-C", str(repo), "commit-tree", f"{fixture['reviewed_main']}^{{tree}}",
                     "-p", fixture["reviewed_main"], "-m", "moved review branch"],
                    check=True, text=True, capture_output=True,
                ).stdout.strip()
                if case == "local":
                    subprocess.run(["git", "-C", str(repo), "update-ref",
                                    "refs/heads/agent/review-sample", new_commit], check=True)
                else:
                    subprocess.run(["git", "-C", str(repo), "push", "-q", "origin",
                                    f"{new_commit}:refs/heads/agent/review-sample"], check=True)
                stack, _ = self._carrow_plan_patches(fixture)
                pattern = "local review branch moved" if case == "local" else "remote review branch moved"
                with stack, self.assertRaisesRegex(runner.RunnerError, pattern):
                    runner.plan_host_validation_recovery(
                        repo, "review-sample", fixture["run_id"],
                        attest_no_active_owner=True, attest_no_unique_evidence=True,
                    )

    def test_carrow_missing_worktree_apply_requires_both_attestations_and_refuses_replay(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_carrow_missing_worktree_fixture(fixture)
        stack, _ = self._carrow_plan_patches(fixture)
        with stack:
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
            )
            with self.assertRaisesRegex(runner.RunnerError, "both explicit operator attestations"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True, recover_host_validation=True,
                    plan_sha256=plan["plan_sha256"],
                )
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

        (fixture["run_dir"] / "continuation-01").mkdir()
        (fixture["run_dir"] / "continuation-01/metadata.json").write_text('{"phase":"partial"}\n')
        stack, _ = self._carrow_plan_patches(fixture)
        with stack, self.assertRaisesRegex(runner.RunnerError, "continuation state has an unknown schema"):
            runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
                attest_no_active_owner=True, attest_no_unique_evidence=True,
            )

    def test_carrow_missing_worktree_apply_reconstructs_then_gates_reviewer_on_green_validation(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_carrow_missing_worktree_fixture(fixture)
        self._relocate_carrow_fixture_checkout(fixture)
        stack, source_span = self._carrow_plan_patches(fixture)
        with stack:
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"],
                attest_no_active_owner=True, attest_no_unique_evidence=True,
            )
            validation_report = {"schema": "custodian.validation.result.v1", "passed": True,
                                 "coverage": {"complete": True}, "selected": [], "tests": []}

            def green_validation(worktree, run_dir, reviewed_main, implementation_commit, **kwargs):
                report_bytes = (json.dumps(validation_report, sort_keys=True) + "\n").encode()
                metadata_bytes = b'{"schema":"synthetic-green-validation"}\n'
                (run_dir / "validation.json").write_bytes(report_bytes)
                (run_dir / "coordinator-validation.json").write_bytes(metadata_bytes)
                return {
                    "report_sha256": hashlib.sha256(report_bytes).hexdigest(),
                    "metadata_sha256": hashlib.sha256(metadata_bytes).hexdigest(),
                    "evidence_run_dir": str(run_dir), "source_span": source_span,
                }

            with patch.object(runner, "run_coordinator_validation", side_effect=green_validation), \
                 patch.object(runner, "verify_coordinator_validation"), \
                 patch.object(runner, "codex_preflight", return_value="codex-fixture") as preflight, \
                 patch.object(runner, "launch_codex", side_effect=subprocess.TimeoutExpired("codex-fixture", 1)) as launch:
                with self.assertRaisesRegex(runner.RunnerError, "fresh reviewer did not finish"):
                    runner.continue_run(
                        fixture["repo"], "review-sample", fixture["run_id"],
                        authorize_fresh_reviewer_context=True, recover_host_validation=True,
                        attest_no_active_owner=True, attest_no_unique_evidence=True,
                        plan_sha256=plan["plan_sha256"],
                    )
            preflight.assert_called_once()
            launch.assert_called_once()
        continuation = fixture["run_dir"] / "continuation-01"
        child = json.loads((continuation / "metadata.json").read_text())
        self.assertEqual(child["phase"], "reviewer_interrupted")
        self.assertEqual(child["reviewer_launch_count"], 1)
        self.assertEqual(child["host_validation_attempts"][0]["status"], "passed")
        self.assertEqual(child["operator_attestations"], {
            "no_active_review_owner": True,
            "no_unique_untracked_or_ignored_evidence": True,
        })
        self.assertEqual(runner._file_manifest(fixture["run_dir"], omit=continuation),
                         fixture["carrow_run_manifest"])

    def _host_recovery_fakes(self, fixture, *, outcome="findings", fail_validation=False):
        packet = runner.parse_packet(fixture["active"], fixture["review"])
        source_span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                       "paths": ["custodian/tools/agent/sample.py"],
                       "provenance": {"kind": "test-fixture"}}

        def fake_validation(worktree, run_dir, reviewed_main, implementation_commit,
                            *, target_workstream=None, target_packet_path=None):
            self.assertEqual(Path(worktree), fixture["worktree"])
            self.assertEqual(Path(run_dir), fixture["run_dir"] / "continuation-01/host-validation/attempt-01")
            self.assertEqual(reviewed_main, fixture["reviewed_main"])
            self.assertEqual(implementation_commit, "a" * 40)
            self.assertEqual(target_workstream, "sample")
            self.assertEqual(target_packet_path, fixture["target"])
            run_dir.mkdir(parents=True, exist_ok=True)
            (run_dir / "validation.json").write_text(json.dumps({
                "schema": "custodian.validation.result.v1", "passed": True,
                "coverage": {"complete": True}, "tests": [{"id": "test", "status": "passed"}],
            }) + "\n")
            (run_dir / "coordinator-validation.json").write_text('{"pinned":true}\n')
            if fail_validation:
                raise host_validation.HostValidationError("simulated corrected validation failure")
            return {"implementation_commit": implementation_commit,
                    "report_sha256": hashlib.sha256((run_dir / "validation.json").read_bytes()).hexdigest(),
                    "metadata_sha256": hashlib.sha256((run_dir / "coordinator-validation.json").read_bytes()).hexdigest(),
                    "source_span": source_span}

        def fake_launch(_argv, worktree, prompt, continuation_dir, _timeout):
            self.assertTrue((continuation_dir / "host-validation/attempt-01/validation.json").is_file())
            self.assertIn("fresh independent reviewer", prompt.lower())
            self.assertIn(fixture["run_id"], prompt)
            self.assertIn("host-validation/attempt-01/validation.json", prompt)
            archive = worktree / f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            archive.parent.mkdir(parents=True, exist_ok=True)
            text = fixture["review"].replace("- Status: `ready`", "- Status: `complete`")
            text += "\n## Independent Review\n\nFresh reviewer evidence.\n\n"
            text += runner.review_outcome.render_review_outcome(
                outcome=outcome, review_workstream="review-sample", target_workstream="sample",
                reviewed_main=fixture["reviewed_main"], implementation_commit="a" * 40,
                provenance="different-agent", run_id=fixture["run_id"], review_cycle=0,
                ids=("R0-01",) if outcome != "passed" else (),
            )
            archive.write_text(text)
            active = worktree / fixture["active"]
            if active.exists():
                active.unlink()
            if outcome == "passed":
                target_file = worktree / fixture["target"]
                target_file.write_text(append_receipt(
                    target_file.read_text(), review_workstream="review-sample", target_workstream="sample",
                    reviewed_main=fixture["reviewed_main"], implementation_commit="a" * 40))
            (worktree / runner.expected_summary_path("review-sample")).write_text(
                f"Independent review.\nAuthoring chat: {fixture['chat']}\n")
            (continuation_dir / "last-message.txt").write_text("independent findings\n")
            return 0

        patches = [
            patch.object(runner, "_host_recovery_plan_unlocked", return_value={
                "plan_sha256": "e" * 64, "source_span": source_span,
                "host_validation_attempt": 1, "failed_validation_evidence": None,
                "generated_import_sidecars": []}),
            patch.object(runner, "validate_eligible_review", return_value=(
                fixture["active"], fixture["review"], packet)),
            patch.object(runner, "codex_preflight", return_value="/fake/codex"),
            patch.object(runner, "reviewer_cache_roots", return_value=[]),
            patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)),
            patch.object(runner, "run_coordinator_validation", side_effect=fake_validation),
            patch.object(runner, "verify_coordinator_validation"),
            patch.object(runner, "launch_codex", side_effect=fake_launch),
            patch.object(runner, "coordinator_finish_review", return_value="f" * 40),
            patch.object(runner, "_verify_continuation_completion", return_value={"revision": "f" * 40}),
        ]
        return patches

    def _continuation_patches(self, fixture, *, outcome="passed", finish_side_effect=None):
        packet = runner.parse_packet(fixture["active"], fixture["review"])

        def fake_launch(_argv, worktree, _prompt, continuation_dir, _timeout):
            continuation_name = fixture.get("continuation_name", "continuation-01")
            self.assertIn(continuation_name, str(continuation_dir))
            self.assertIn("fresh independent reviewer", _prompt.lower())
            self.assertIn(fixture["run_id"], _prompt)
            self.assertIn("preserved-reviewer-files", _prompt)
            if continuation_name == "continuation-02":
                self.assertIn(f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md", _prompt)
                self.assertIn(fixture["target"], _prompt)
                self.assertIn(runner.expected_summary_path("review-sample"), _prompt)
            self.assertEqual((fixture["run_dir"] / "codex.jsonl").read_text(), "original reviewer log\n")
            archive = worktree / f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            archive.parent.mkdir(parents=True, exist_ok=True)
            implementation = "a" * 40
            text = fixture["review"].replace("- Status: `ready`", "- Status: `complete`")
            text += "\n## Independent Review\n\nIndependent fresh review disposition.\n\n"
            text += runner.review_outcome.render_review_outcome(
                outcome=outcome, review_workstream="review-sample", target_workstream="sample",
                reviewed_main=fixture["reviewed_main"], implementation_commit=implementation,
                provenance="different-agent", run_id=fixture["run_id"], review_cycle=0,
                ids=() if outcome == "passed" else ("R0-01",))
            if not fixture.get("omit_archived_packet"):
                archive.write_text(text)
            fixture["archived_text"] = text
            active_file = worktree / fixture["active"]
            if active_file.exists():
                active_file.unlink()
            if outcome == "passed":
                target_file = worktree / fixture["target"]
                baseline = target_file.read_text()
                target_file.write_text(append_receipt(
                    baseline, review_workstream="review-sample", target_workstream="sample",
                    reviewed_main=fixture["reviewed_main"], implementation_commit=implementation))
            summary = worktree / runner.expected_summary_path("review-sample")
            summary.write_text(f"Fresh review complete.\nAuthoring chat: {fixture['chat']}\n\n"
                               "## Next Handoff\n- Next workstream: none\n- Next action: done\n")
            (continuation_dir / "last-message.txt").write_text("reviewer complete\n")
            if fixture.get("mutate_parent_during_launch"):
                (fixture["run_dir"] / "continuation-01" / "unexpected.txt").write_text("mutation\n")
            return 0

        def finish(*args, **kwargs):
            if finish_side_effect:
                return finish_side_effect(*args, **kwargs)
            fixture["landed"]["complete"] = True
            return "f" * 40

        return (
            patch.object(runner, "validate_eligible_review", return_value=(fixture["active"], fixture["review"], packet)),
            patch.object(runner, "codex_preflight", return_value="/fake/codex"),
            patch.object(runner, "reviewer_cache_roots", return_value=[]),
            patch.object(runner, "_host_evidence_for_continuation", return_value={
                "implementation_commit": "a" * 40, "report_sha256": "c" * 64,
                "metadata_sha256": "d" * 64, "evidence_run_dir": str(fixture["run_dir"])}),
            patch.object(runner, "verify_coordinator_validation"),
            patch.object(runner, "_verify_host_validation_at_commit"),
            patch.object(runner, "launch_codex", side_effect=fake_launch),
            patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)),
            patch.object(runner, "coordinator_finish_review", side_effect=finish),
            patch.object(runner, "fetch_and_pin_main", return_value=fixture["reviewed_main"]),
            patch.object(runner, "read_git_text", side_effect=lambda _repo, _revision, path:
                         fixture["target_content"] if path == fixture["target"] else fixture["archived_text"]),
            patch.object(runner, "landed_review_state", side_effect=lambda *args, **kwargs: {
                "complete": fixture["landed"]["complete"], "revision": fixture["landed"]["revision"],
                "reasons": [] if fixture["landed"]["complete"] else ["review receipt not landed"],
                "summary_path": runner.expected_summary_path("review-sample")}),
        )

    def _missing_archived_disposition_fixture(self):
        fixture = self._continuation_fixture()
        run_dir = fixture["run_dir"]
        continuation_01 = run_dir / "continuation-01"
        continuation_01.mkdir()
        preserved_dir = continuation_01 / "preserved-reviewer-files"
        preserved_dir.mkdir()
        preserved_source = fixture["prior_summary"]
        preserved_copy = preserved_dir / preserved_source.name
        preserved_copy.write_bytes(preserved_source.read_bytes())
        preserved = [{"source": str(preserved_source), "copy": str(preserved_copy),
                      "sha256": hashlib.sha256(preserved_copy.read_bytes()).hexdigest()}]
        (continuation_01 / "preserved-files.json").write_text(json.dumps(preserved, indent=2, sort_keys=True) + "\n")
        parent_manifest = runner._file_manifest(run_dir, omit=continuation_01)
        child = {
            "schema": runner.CONTINUATION_SCHEMA,
            "workstream": "review-sample",
            "run_id": fixture["run_id"],
            "phase": "missing_archived_disposition",
            "exit_code": 0,
            "branch": "agent/review-sample",
            "worktree": str(fixture["worktree"]),
            "active_packet_path": fixture["active"],
            "target_workstream": "sample",
            "target_packet_path": fixture["target"],
            "reviewed_main": fixture["reviewed_main"],
            "implementation_commit": "a" * 40,
            "run_evidence_sha256": parent_manifest,
            "host_evidence": {"report_sha256": "c" * 64, "metadata_sha256": "d" * 64},
            "preserved_files": preserved,
        }
        (continuation_01 / "metadata.json").write_text(json.dumps(child, indent=2, sort_keys=True) + "\n")
        (continuation_01 / "last-message.txt").write_text("prior PASS prose is not a canonical outcome\n")
        lock = runner.common_dir(fixture["repo"]) / "custodian-review-runs/locks/review-sample.lock"
        lock.parent.mkdir(parents=True, exist_ok=True)
        lock.touch(exist_ok=True)
        fixture["continuation_name"] = "continuation-02"
        fixture["prior_run_manifest"] = runner._file_manifest(run_dir)
        fixture["prior_continuation_manifest"] = runner._file_manifest(continuation_01)
        return fixture

    def test_missing_archived_disposition_continuation_uses_exact_second_child_and_preserves_parents(self):
        fixture = self._missing_archived_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        patches = self._continuation_patches(fixture)
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        commands = []
        original_subprocess_run = runner.subprocess.run

        def record_commands(argv, *args, **kwargs):
            commands.append(argv)
            return original_subprocess_run(argv, *args, **kwargs)

        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]), \
             patch.object(runner.subprocess, "run", side_effect=record_commands):
            result = runner.continue_run(
                fixture["repo"], "review-sample", fixture["run_id"],
                authorize_fresh_reviewer_context=True,
                recover_missing_archived_disposition=True,
            )
            self.assertEqual(result, 0)
            self.assertEqual(runner.continue_run(
                fixture["repo"], "review-sample", fixture["run_id"],
                authorize_fresh_reviewer_context=True,
                recover_missing_archived_disposition=True,
            ), 0)
        continuation_02 = fixture["run_dir"] / "continuation-02"
        state = json.loads((continuation_02 / "metadata.json").read_text())
        self.assertEqual(state["phase"], "complete")
        self.assertEqual(state["continuation_number"], 2)
        self.assertEqual(state["parent_continuation_sha256"],
                         hashlib.sha256(json.dumps(fixture["prior_continuation_manifest"],
                                                   sort_keys=True, separators=(",", ":")).encode()).hexdigest())
        prior_manifest = json.loads((continuation_02 / "prior-continuation-01-manifest.json").read_text())
        self.assertEqual(prior_manifest["continuation_01_manifest"], fixture["prior_continuation_manifest"])
        self.assertEqual(prior_manifest["original_run_manifest"],
                         json.loads((fixture["run_dir"] / "continuation-01/metadata.json").read_text())[
                             "run_evidence_sha256"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"], omit=continuation_02),
                         fixture["prior_run_manifest"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"] / "continuation-01"),
                         fixture["prior_continuation_manifest"])
        self.assertEqual(active_patches[6].call_count, 1)
        self.assertFalse(any("dispatch.py" in " ".join(map(str, argv)) for argv in commands))

    def test_missing_archived_disposition_continuation_rejects_wrong_parent_phase_before_launch(self):
        fixture = self._missing_archived_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        child_path = fixture["run_dir"] / "continuation-01/metadata.json"
        child = json.loads(child_path.read_text())
        child["phase"] = "reviewer_nonpassing"
        child_path.write_text(json.dumps(child, sort_keys=True) + "\n")
        before = runner._file_manifest(fixture["run_dir"])
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]), \
             patch.object(runner, "launch_codex") as launch:
            with self.assertRaisesRegex(runner.RunnerError, "missing_archived_disposition"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        launch.assert_not_called()
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), before)

    def test_missing_archived_disposition_continuation_rejects_changed_original_manifest(self):
        fixture = self._missing_archived_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        (fixture["run_dir"] / "codex.jsonl").write_text("changed original evidence\n")
        before = runner._file_manifest(fixture["run_dir"])
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]), \
             patch.object(runner, "launch_codex") as launch:
            with self.assertRaisesRegex(runner.RunnerError, "original run evidence"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        launch.assert_not_called()
        self.assertFalse((fixture["run_dir"] / "continuation-02").exists())
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), before)

    def test_missing_archived_disposition_continuation_rejects_forged_identity_or_parent_evidence(self):
        cases = ("worktree", "branch", "claim", "report", "missing-report", "symlink")
        for case in cases:
            with self.subTest(case=case):
                fixture = self._missing_archived_disposition_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                child_path = fixture["run_dir"] / "continuation-01/metadata.json"
                child = json.loads(child_path.read_text())
                if case == "worktree":
                    child["worktree"] = str(fixture["temp"].name) + "/wrong-worktree"
                    child_path.write_text(json.dumps(child, sort_keys=True) + "\n")
                elif case == "branch":
                    child["branch"] = "agent/wrong-review"
                    child_path.write_text(json.dumps(child, sort_keys=True) + "\n")
                elif case == "claim":
                    receipt_path = fixture["run_dir"] / "claim-receipt.json"
                    receipt = json.loads(receipt_path.read_text())
                    receipt["workstream"] = "review-spoof"
                    receipt_path.write_text(json.dumps(receipt) + "\n")
                elif case == "report":
                    (fixture["run_dir"] / "validation.json").write_text("{\"passed\":false}\n")
                elif case == "missing-report":
                    (fixture["run_dir"] / "validation.json").unlink()
                else:
                    (fixture["run_dir"] / "continuation-01/unsafe-link").symlink_to(
                        fixture["run_dir"] / "codex.jsonl")
                with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
                     patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]), \
                     patch.object(runner, "launch_codex") as launch:
                    with self.assertRaises(runner.RunnerError):
                        runner.continue_run(
                            fixture["repo"], "review-sample", fixture["run_id"],
                            authorize_fresh_reviewer_context=True,
                            recover_missing_archived_disposition=True,
                        )
                launch.assert_not_called()
                self.assertFalse((fixture["run_dir"] / "continuation-02").exists())

    def test_missing_archived_disposition_continuation_rejects_preexisting_child_without_replay(self):
        fixture = self._missing_archived_disposition_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        continuation_02 = fixture["run_dir"] / "continuation-02"
        continuation_02.mkdir()
        (continuation_02 / "preserved-marker.txt").write_text("keep\n")
        before = runner._file_manifest(fixture["run_dir"])
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]), \
             patch.object(runner, "launch_codex") as launch:
            with self.assertRaisesRegex(runner.RunnerError, "continuation state is missing or malformed"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        launch.assert_not_called()
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), before)

    def test_missing_archived_disposition_continuation_detects_parent_mutation_after_reviewer(self):
        fixture = self._missing_archived_disposition_fixture()
        fixture["mutate_parent_during_launch"] = True
        self.addCleanup(fixture["temp"].cleanup)
        patches = self._continuation_patches(fixture)
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]):
            with self.assertRaisesRegex(runner.RunnerError, "original run evidence changed"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        child = json.loads((fixture["run_dir"] / "continuation-02/metadata.json").read_text())
        self.assertEqual(child["phase"], "original_evidence_changed")
        self.assertEqual(active_patches[6].call_count, 1)

    def test_missing_archived_disposition_child_with_missing_archive_cannot_launch_again(self):
        fixture = self._missing_archived_disposition_fixture()
        fixture["omit_archived_packet"] = True
        self.addCleanup(fixture["temp"].cleanup)
        patches = self._continuation_patches(fixture)
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", fixture["run_id"]):
            with self.assertRaisesRegex(runner.RunnerError, "did not author the exact archived review packet"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
            child_path = fixture["run_dir"] / "continuation-02/metadata.json"
            child_before = child_path.read_bytes()
            with self.assertRaisesRegex(runner.RunnerError, "consumed its one reviewer launch"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        self.assertEqual(active_patches[6].call_count, 1)
        self.assertEqual(child_path.read_bytes(), child_before)

    def test_missing_archived_disposition_continuation_rejects_wrong_run_before_git_access(self):
        with patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_WORKSTREAM", "review-sample"), \
             patch.object(runner, "MISSING_ARCHIVED_DISPOSITION_RUN_ID", "20261017T120000Z-012345abcdef"), \
             patch.object(runner, "git") as git:
            with self.assertRaisesRegex(runner.RunnerError, "exact run with explicit fresh-reviewer authorization"):
                runner.continue_run(
                    Path("."), "review-sample", "20261017T120001Z-012345abcdef",
                    authorize_fresh_reviewer_context=True,
                    recover_missing_archived_disposition=True,
                )
        git.assert_not_called()

    def test_missing_archived_disposition_cli_requires_both_explicit_recovery_authorizations(self):
        with patch.object(runner, "continue_run") as continuation:
            result = runner.main([
                runner.MISSING_ARCHIVED_DISPOSITION_WORKSTREAM,
                "--continue-run", runner.MISSING_ARCHIVED_DISPOSITION_RUN_ID,
                "--recover-missing-archived-disposition",
            ])
        self.assertEqual(result, 2)
        continuation.assert_not_called()

    def test_missing_archived_disposition_prompt_names_all_canonical_artifact_paths(self):
        prompt = runner._continuation_prompt(
            "review-sample", "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md",
            "custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md",
            run_id="20261017T120000Z-012345abcdef", target_workstream="sample-impl", reviewed_main="b" * 40,
            implementation_commit="a" * 40, authoring_chat="https://chatgpt.com/c/test",
            continuation_dir=Path("/tmp/continuation-02"), preserved=[],
            report_sha256="c" * 64, continuation_number=2,
        )
        self.assertIn("custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md", prompt)
        self.assertIn("custodian/docs/ai_context/task_packets/archived/REVIEW_SAMPLE.md", prompt)
        self.assertIn("custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md", prompt)
        self.assertIn("### Review Receipt: review-sample", prompt)
        self.assertIn("Review target workstream: `sample-impl`", prompt)
        self.assertIn("REVIEW_SAMPLE_CLAUDE_SUMMARY.md", prompt)

    def test_same_run_continuation_preserves_originals_and_completed_retry_verifies_without_claim(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        patches = self._continuation_patches(fixture)
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        original_log = fixture["run_dir"] / "codex.jsonl"
        original_log_sha = hashlib.sha256(original_log.read_bytes()).hexdigest()
        commands = []
        original_subprocess_run = runner.subprocess.run

        def record_commands(argv, *args, **kwargs):
            commands.append(argv)
            return original_subprocess_run(argv, *args, **kwargs)

        with patch.object(runner.subprocess, "run", side_effect=record_commands):
            self.assertEqual(runner.continue_run(
                fixture["repo"], "review-sample", fixture["run_id"],
                authorize_fresh_reviewer_context=True), 0)
            first_child = fixture["run_dir"] / "continuation-01"
            state = json.loads((first_child / "metadata.json").read_text())
            self.assertEqual(state["phase"], "complete")
            preserved_summary = first_child / "preserved-reviewer-files/01-SAMPLE_REVIEW_CLAUDE_SUMMARY.md"
            self.assertEqual(preserved_summary.read_bytes(),
                             b"Original reviewer notes: blocked before complete regressions.\n")
            self.assertFalse(fixture["prior_summary"].exists())
            self.assertEqual(hashlib.sha256(original_log.read_bytes()).hexdigest(), original_log_sha)
            self.assertFalse(any(isinstance(argv, list) and "dispatch.py" in " ".join(map(str, argv))
                                and "claim" in argv for argv in commands))
            self.assertEqual(runner.continue_run(
                fixture["repo"], "review-sample", fixture["run_id"],
                authorize_fresh_reviewer_context=True), 0)

    def test_same_run_continuation_rejects_missing_claim_receipt_without_creating_child(self):
        fixture = self._continuation_fixture(receipt=False)
        self.addCleanup(fixture["temp"].cleanup)
        with patch.object(runner, "validate_eligible_review", return_value=(
                fixture["active"], fixture["review"], runner.parse_packet(fixture["active"], fixture["review"]))), \
             patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
             patch.object(runner, "_host_evidence_for_continuation"):
            with self.assertRaisesRegex(runner.RunnerError, "structured claim receipt"):
                runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                    authorize_fresh_reviewer_context=True)
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_accepts_only_git_verified_legacy_truncated_claim_header(self):
        fixture = self._continuation_fixture(receipt=False)
        self.addCleanup(fixture["temp"].cleanup)
        claim = fixture["receipt"]
        prefix = ("CLAIMED\n"
                  f"workstream: {claim['workstream']}\n"
                  f"branch: {claim['branch']}\n"
                  f"worktree: {claim['worktree']}\n"
                  f"packet: {claim['packet']}\n"
                  f"{runner.CLAIM_SENTINEL}{{\"schema\":\"custodian.dispatch.claim.v1\",\"result\":")
        stdout_path = fixture["run_dir"] / "claim.stdout"
        stdout_path.write_text(prefix)
        with patch.object(runner, "validate_eligible_review", return_value=(
                fixture["active"], fixture["review"], runner.parse_packet(fixture["active"], fixture["review"]))), \
             patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
             patch.object(runner, "_host_evidence_for_continuation", side_effect=runner.RunnerError("stop after receipt verification")) as host_validation:
            with self.assertRaisesRegex(runner.RunnerError, "stop after receipt verification"):
                runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                    authorize_fresh_reviewer_context=True)
        host_validation.assert_called_once()
        self.assertEqual(stdout_path.read_text(), prefix)
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_rejects_wrong_run_worktree_branch_sha_and_phase(self):
        cases = (
            ("worktree", lambda f: json.loads((f["run_dir"] / "claim-receipt.json").read_text())
             | {"worktree": str(f["repo"] / "missing-worktree")}, "worktree/branch identity"),
            ("branch", lambda f: json.loads((f["run_dir"] / "claim-receipt.json").read_text())
             | {"branch": "agent/other-review"}, "worktree/branch identity"),
            ("sha", lambda f: None, "Needed a single revision"),
            ("phase", lambda f: None, "not the exact eligible post-exit recovery"),
        )
        for case, _mutate, expected in cases:
            with self.subTest(case=case):
                fixture = self._continuation_fixture()
                if case == "worktree":
                    (fixture["run_dir"] / "claim-receipt.json").write_text(json.dumps(
                        json.loads((fixture["run_dir"] / "claim-receipt.json").read_text())
                        | {"worktree": str(fixture["repo"] / "missing-worktree")}))
                elif case == "branch":
                    receipt = json.loads((fixture["run_dir"] / "claim-receipt.json").read_text())
                    receipt["branch"] = "agent/other-review"
                    (fixture["run_dir"] / "claim-receipt.json").write_text(json.dumps(receipt))
                elif case == "sha":
                    metadata = json.loads((fixture["run_dir"] / "metadata.json").read_text())
                    metadata["reviewed_main"] = "0" * 40
                    (fixture["run_dir"] / "metadata.json").write_text(json.dumps(metadata))
                else:
                    metadata = json.loads((fixture["run_dir"] / "metadata.json").read_text())
                    metadata["phase"] = "codex_running"
                    (fixture["run_dir"] / "metadata.json").write_text(json.dumps(metadata))
                self.addCleanup(fixture["temp"].cleanup)
                with patch.object(runner, "validate_eligible_review", return_value=(
                        fixture["active"], fixture["review"],
                        runner.parse_packet(fixture["active"], fixture["review"]))), \
                     patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                     patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
                    with self.assertRaisesRegex(runner.RunnerError, expected):
                        runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                            authorize_fresh_reviewer_context=True)
                self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_requires_clean_coordinator_checkout(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        (fixture["repo"] / "unrelated.txt").write_text("keep this\n")
        with self.assertRaisesRegex(runner.RunnerError, "coordinator checkout is dirty"):
            runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                authorize_fresh_reviewer_context=True)
        self.assertTrue((fixture["repo"] / "unrelated.txt").is_file())
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_rejects_modified_target_and_untrusted_host_evidence(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        target_path = fixture["worktree"] / fixture["target"]
        target_path.write_text(fixture["target_content"] + "\nUncommitted prior receipt.\n")
        with patch.object(runner, "validate_eligible_review", return_value=(
                fixture["active"], fixture["review"], runner.parse_packet(fixture["active"], fixture["review"]))), \
             patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
             patch.object(runner, "_host_evidence_for_continuation") as host_validation:
            with self.assertRaisesRegex(runner.RunnerError, "target differs from the pinned"):
                runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                    authorize_fresh_reviewer_context=True)
            host_validation.assert_not_called()
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_nonpassing_disposition_never_calls_coordinator(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        patches = self._continuation_patches(fixture, outcome="findings")
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        self.assertEqual(runner.continue_run(
            fixture["repo"], "review-sample", fixture["run_id"],
            authorize_fresh_reviewer_context=True), 2)
        state = json.loads((fixture["run_dir"] / "continuation-01/metadata.json").read_text())
        self.assertEqual(state["phase"], "reviewer_nonpassing")
        self.assertFalse(active_patches[8].mock_calls)

    def test_same_run_continuation_cli_requires_both_explicit_flags(self):
        with patch.object(runner, "continue_run") as continuation:
            self.assertEqual(runner.main(["review-sample", "--continue-run", "20261017T120000Z-012345abcdef"]), 2)
            self.assertEqual(runner.main(["review-sample", "--authorize-fresh-reviewer-context"]), 2)
        continuation.assert_not_called()

    def test_invalid_disposition_cli_is_exact_run_recovery_without_reviewer_authorization(self):
        with patch.object(runner, "continue_run", return_value=0) as recovery:
            self.assertEqual(runner.main([
                runner.INVALID_DISPOSITION_WORKSTREAM, "--continue-run", runner.INVALID_DISPOSITION_RUN_ID,
                "--recover-invalid-disposition",
            ]), 0)
            self.assertEqual(runner.main([
                "review-sample", "--continue-run", "20261017T120000Z-012345abcdef",
                "--recover-invalid-disposition",
            ]), 2)
        recovery.assert_called_once_with(
            Path.cwd(), runner.INVALID_DISPOSITION_WORKSTREAM, runner.INVALID_DISPOSITION_RUN_ID,
            recover_invalid_disposition=True,
        )

    def test_host_recovery_cli_plan_is_read_only_and_apply_requires_fresh_context_and_digest(self):
        run_id = "20261017T120000Z-012345abcdef"
        plan = {"schema": "custodian.paired_review_host_recovery_plan.v1",
                "run_id": run_id, "plan_sha256": "e" * 64}
        output = io.StringIO()
        with patch.object(runner, "plan_host_validation_recovery", return_value=plan) as make_plan, \
             patch.object(runner, "continue_run", return_value=0) as apply, \
             patch("sys.stdout", output):
            self.assertEqual(runner.main(["review-sample", "--continue-run", run_id,
                                          "--recover-host-validation", "--plan"]), 0)
            self.assertEqual(json.loads(output.getvalue()), plan)
            make_plan.assert_called_once()
            self.assertEqual(runner.main(["review-sample", "--continue-run", run_id,
                                          "--recover-host-validation", "--apply",
                                          "--authorize-fresh-reviewer-context"]), 2)
            apply.assert_not_called()
            self.assertEqual(runner.main(["review-sample", "--continue-run", run_id,
                                          "--recover-host-validation", "--apply",
                                          "--authorize-fresh-reviewer-context",
                                          "--plan-sha256", "e" * 64]), 0)
        apply.assert_called_once_with(
            Path.cwd(), "review-sample", run_id, authorize_fresh_reviewer_context=True,
            recover_host_validation=True, plan_sha256="e" * 64, timeout=None,
        )

    def test_host_recovery_stale_plan_is_rejected_before_creating_child(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        with patch.object(runner, "_host_recovery_plan_unlocked", return_value={"plan_sha256": "e" * 64}), \
             patch.object(runner, "codex_preflight") as launch:
            with self.assertRaisesRegex(runner.RunnerError, "exact SHA-256"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True, recover_host_validation=True,
                    plan_sha256="f" * 64,
                )
        launch.assert_not_called()
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), original_manifest)

    def test_host_recovery_plan_is_read_only_and_refuses_an_active_supervisor(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        expected = {"schema": "custodian.paired_review_host_recovery_plan.v1",
                    "run_id": fixture["run_id"], "plan_sha256": "e" * 64}
        lock = runner.common_dir(fixture["repo"]) / "custodian-review-runs/locks/review-sample.lock"
        with patch.object(runner, "_host_recovery_plan_unlocked", return_value=expected) as build_plan:
            self.assertEqual(runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"]), expected)
        build_plan.assert_called_once_with(fixture["repo"], "review-sample", fixture["run_id"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), original_manifest)
        with lock.open("rb") as held:
            fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaisesRegex(runner.RunnerError, "another local process"):
                runner.plan_host_validation_recovery(
                    fixture["repo"], "review-sample", fixture["run_id"])

    def test_host_recovery_plan_verifies_legacy_header_when_stdout_truncated_before_receipt(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture, reports=False)
        self._make_host_recovery_worktree_clean(fixture)
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["implementation_commit"] = fixture["reviewed_main"]
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        claim = fixture["receipt"]
        stdout = ("CLAIMED\n"
                  f"workstream: {claim['workstream']}\n"
                  f"branch: {claim['branch']}\n"
                  f"worktree: {claim['worktree']}\n"
                  f"packet: {claim['packet']}\n\n"
                  "NEXT:\ncd /truncated/worktree\nImplement only this workstr")
        (fixture["run_dir"] / "claim.stdout").write_text(stdout)
        (fixture["run_dir"] / "claim-receipt.json").unlink()
        original_manifest = runner._file_manifest(fixture["run_dir"])
        span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                "commits": [], "paths": ["custodian/tools/agent/sample.py"],
                "provenance": {"kind": "test-fixture"}}
        with patch.object(runner, "resolve_target_implementation_commit",
                          return_value=(fixture["reviewed_main"], None)), \
             patch.object(host_validation, "resolve_validation_source_span", return_value=span):
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"])
        self.assertEqual(plan["branch"], claim["branch"])
        self.assertEqual(plan["packet"], claim["packet"])
        self.assertEqual(plan["worktree"], str(fixture["worktree"].resolve()))
        self.assertEqual(plan["reviewed_main"], fixture["reviewed_main"])
        self.assertEqual(plan["host_validation_state"], "pre_validation_interrupted")
        self.assertTrue(plan["requires_fresh_host_validation"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), original_manifest)
        self.assertFalse((fixture["run_dir"] / "claim-receipt.json").exists())

    def test_host_recovery_legacy_header_and_structured_receipt_disagreements_fail_closed(self):
        for structured in (False, True):
            with self.subTest(structured=structured):
                fixture = self._continuation_fixture()
                self.addCleanup(fixture["temp"].cleanup)
                self._prepare_host_recovery(fixture, reports=False)
                self._make_host_recovery_worktree_clean(fixture)
                metadata_path = fixture["run_dir"] / "metadata.json"
                metadata = json.loads(metadata_path.read_text())
                metadata["implementation_commit"] = fixture["reviewed_main"]
                metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
                claim = fixture["receipt"]
                stdout = ("CLAIMED\n"
                          f"workstream: {claim['workstream']}\n"
                          f"branch: {claim['branch']}\n"
                          f"worktree: {claim['worktree']}\n"
                          f"packet: {claim['packet']}\n\nNEXT:\ncut")
                (fixture["run_dir"] / "claim.stdout").write_text(stdout)
                if structured:
                    bad = {**claim, "worktree": str(fixture["repo"] / "foreign-worktree")}
                    (fixture["run_dir"] / "claim-receipt.json").write_text(json.dumps(bad))
                else:
                    (fixture["run_dir"] / "claim-receipt.json").unlink()
                    (fixture["run_dir"] / "claim.stdout").write_text(
                        stdout.replace(f"worktree: {claim['worktree']}", "worktree: /foreign/worktree"))
                span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                        "commits": [], "paths": ["custodian/tools/agent/sample.py"],
                        "provenance": {"kind": "test-fixture"}}
                with patch.object(runner, "resolve_target_implementation_commit",
                                  return_value=(fixture["reviewed_main"], None)), \
                     patch.object(host_validation, "resolve_validation_source_span", return_value=span), \
                     self.assertRaisesRegex(runner.RunnerError, "claim|worktree|identity"):
                    runner.plan_host_validation_recovery(
                        fixture["repo"], "review-sample", fixture["run_id"])

    def test_host_recovery_apply_reuses_legacy_verifier_before_any_child_write(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        self._prepare_host_recovery(fixture, reports=False)
        self._make_host_recovery_worktree_clean(fixture)
        metadata_path = fixture["run_dir"] / "metadata.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["implementation_commit"] = fixture["reviewed_main"]
        metadata_path.write_text(json.dumps(metadata, sort_keys=True) + "\n")
        claim = fixture["receipt"]
        stdout = ("CLAIMED\n"
                  f"workstream: {claim['workstream']}\n"
                  f"branch: {claim['branch']}\n"
                  f"worktree: {claim['worktree']}\n"
                  f"packet: {claim['packet']}\n\nNEXT:\ncut")
        (fixture["run_dir"] / "claim.stdout").write_text(stdout)
        (fixture["run_dir"] / "claim-receipt.json").unlink()
        original_manifest = runner._file_manifest(fixture["run_dir"])
        span = {"base": fixture["reviewed_main"], "head": fixture["reviewed_main"],
                "commits": [], "paths": ["custodian/tools/agent/sample.py"],
                "provenance": {"kind": "test-fixture"}}
        parsed = runner.parse_packet(fixture["active"], fixture["review"])
        with patch.object(runner, "resolve_target_implementation_commit",
                          return_value=(fixture["reviewed_main"], None)), \
             patch.object(host_validation, "resolve_validation_source_span", return_value=span), \
             patch.object(runner, "validate_eligible_review",
                          return_value=(fixture["active"], fixture["review"], parsed)), \
             patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
             patch.object(runner, "_worktree_review_artifacts",
                          side_effect=runner.RunnerError("stopped after exact claim verification")) as stop:
            plan = runner.plan_host_validation_recovery(
                fixture["repo"], "review-sample", fixture["run_id"])
            with self.assertRaisesRegex(runner.RunnerError, "stopped after exact claim verification"):
                runner.continue_run(
                    fixture["repo"], "review-sample", fixture["run_id"],
                    authorize_fresh_reviewer_context=True, recover_host_validation=True,
                    plan_sha256=plan["plan_sha256"],
                )
        stop.assert_called_once()
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())
        self.assertEqual(runner._file_manifest(fixture["run_dir"]), original_manifest)

    def test_completed_host_continuation_is_reusable_only_with_exact_parent_manifest(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        child_dir = fixture["run_dir"] / "continuation-01"
        child_dir.mkdir()
        child = {
            "schema": runner.CONTINUATION_SCHEMA, "phase": "complete",
            "run_id": fixture["run_id"], "workstream": "review-sample",
            "branch": "agent/review-sample", "worktree": str(fixture["worktree"]),
            "active_packet_path": fixture["active"], "target_workstream": "sample",
            "target_packet_path": fixture["target"], "reviewed_main": fixture["reviewed_main"],
            "implementation_commit": "a" * 40,
            "host_evidence": {"continuation_dir": str(child_dir)},
            "run_evidence_sha256": original_manifest,
        }
        child_path = child_dir / "metadata.json"
        child_path.write_text(json.dumps(child, sort_keys=True) + "\n")
        state = runner._completed_host_continuation(
            fixture["repo"], fixture["run_dir"], "review-sample", fixture["run_id"])
        self.assertEqual(state["phase"], "complete")
        self.assertEqual(len(state["metadata_sha256"]), 64)
        self.assertEqual(len(state["manifest_sha256"]), 64)
        (fixture["run_dir"] / "RECOVERY.md").write_text("altered after completion\n")
        with self.assertRaisesRegex(runner.RunnerError, "original evidence"):
            runner._completed_host_continuation(
                fixture["repo"], fixture["run_dir"], "review-sample", fixture["run_id"])

    def test_host_recovery_revalidates_in_child_then_launches_fresh_reviewer_without_rewriting_parent(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        patches = self._host_recovery_fakes(fixture, outcome="findings")
        active = [item.start() for item in patches]
        self.addCleanup(lambda: [item.stop() for item in reversed(patches)])

        self.assertEqual(runner.continue_run(
            fixture["repo"], "review-sample", fixture["run_id"],
            authorize_fresh_reviewer_context=True, recover_host_validation=True,
            plan_sha256="e" * 64,
        ), 2)
        child = fixture["run_dir"] / "continuation-01"
        state = json.loads((child / "metadata.json").read_text())
        self.assertEqual(state["phase"], "reviewer_nonpassing")
        self.assertEqual(state["host_evidence"]["evidence_run_dir"],
                         str(child / "host-validation/attempt-01"))
        self.assertEqual(runner._file_manifest(fixture["run_dir"], omit=child), original_manifest)
        self.assertEqual(active[5].call_count, 1)
        self.assertEqual(active[7].call_count, 1)

    def test_host_recovery_validation_failure_records_child_and_preserves_original_evidence(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        patches = self._host_recovery_fakes(fixture, fail_validation=True)
        active = [item.start() for item in patches]
        self.addCleanup(lambda: [item.stop() for item in reversed(patches)])
        with self.assertRaisesRegex(runner.RunnerError, "corrected host validation did not pass"):
            runner.continue_run(
                fixture["repo"], "review-sample", fixture["run_id"],
                authorize_fresh_reviewer_context=True, recover_host_validation=True,
                plan_sha256="e" * 64,
            )
        child = fixture["run_dir"] / "continuation-01"
        state = json.loads((child / "metadata.json").read_text())
        self.assertEqual(state["phase"], "host_validation_failed")
        self.assertEqual(state["host_validation_attempts"][0]["status"], "failed")
        self.assertIn("validation.json", state["host_validation_attempts"][0]["manifest"])
        self.assertEqual(runner._file_manifest(fixture["run_dir"], omit=child), original_manifest)
        active[7].assert_not_called()

    def test_host_recovery_pass_is_coordinator_closed_only_after_fresh_reviewer_disposition(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        original_manifest = self._prepare_host_recovery(fixture)
        patches = self._host_recovery_fakes(fixture, outcome="passed")
        active = [item.start() for item in patches]
        self.addCleanup(lambda: [item.stop() for item in reversed(patches)])
        self.assertEqual(runner.continue_run(
            fixture["repo"], "review-sample", fixture["run_id"],
            authorize_fresh_reviewer_context=True, recover_host_validation=True,
            plan_sha256="e" * 64,
        ), 0)
        state = json.loads((fixture["run_dir"] / "continuation-01/metadata.json").read_text())
        self.assertEqual(state["phase"], "complete")
        self.assertEqual(state["outcome"], "passed")
        active[8].assert_called_once()
        active[9].assert_called_once()
        self.assertEqual(runner._file_manifest(
            fixture["run_dir"], omit=fixture["run_dir"] / "continuation-01"), original_manifest)

    def test_same_run_continuation_rejects_malformed_run_id_before_git_access(self):
        with patch.object(runner, "git") as git:
            with self.assertRaisesRegex(runner.RunnerError, "exact review workstream and shaped run ID"):
                runner.continue_run(Path("."), "review-sample", "not-a-run",
                                    authorize_fresh_reviewer_context=True)
        git.assert_not_called()

    def test_same_run_continuation_lock_blocks_parallel_reviewer(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)
        lock_path = runner.common_dir(fixture["repo"]) / "custodian-review-runs/locks/review-sample.lock"
        lock_path.parent.mkdir(parents=True)
        with lock_path.open("a") as held:
            fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaisesRegex(runner.RunnerError, "another local process"):
                runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                    authorize_fresh_reviewer_context=True)
        self.assertFalse((fixture["run_dir"] / "continuation-01").exists())

    def test_same_run_continuation_after_commit_failure_keeps_one_reviewer_attempt(self):
        fixture = self._continuation_fixture()
        self.addCleanup(fixture["temp"].cleanup)

        def fail_after_commit(_repo, _workstream, worktree, active_path, target_workstream,
                              target_path, _target_content, _chat, _reviewed_main,
                              _run_dir, _host_evidence):
            archive = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            summary = runner.expected_summary_path("review-sample")
            subprocess.run(["git", "add", "-A", "--", active_path, archive, target_path, summary],
                           cwd=worktree, check=True)
            subprocess.run(["git", "commit", "-qm", "simulated coordinator commit"],
                           cwd=worktree, check=True)
            raise runner.RunnerError("simulated crash after coordinator commit")

        patches = self._continuation_patches(fixture)
        active_patches = [patcher.start() for patcher in patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(patches)])
        with self.assertRaisesRegex(runner.RunnerError, "simulated crash after coordinator commit"):
            with patch.object(runner, "coordinator_finish_review", side_effect=fail_after_commit):
                runner.continue_run(fixture["repo"], "review-sample", fixture["run_id"],
                                    authorize_fresh_reviewer_context=True)
        self.assertEqual(json.loads((fixture["run_dir"] / "continuation-01/metadata.json").read_text())["phase"],
                         "coordinator_closeout")
        retry_patches = self._continuation_patches(fixture)
        retry_active = [patcher.start() for patcher in retry_patches]
        self.addCleanup(lambda: [patcher.stop() for patcher in reversed(retry_patches)])
        self.assertEqual(runner.continue_run(
            fixture["repo"], "review-sample", fixture["run_id"],
            authorize_fresh_reviewer_context=True), 0)
        self.assertEqual(active_patches[6].call_count, 1)
        self.assertEqual(retry_active[6].call_count, 0)
        self.assertEqual(retry_active[8].call_count, 1)

    def test_fetch_failure_is_not_ignored_or_replaced_by_stale_main(self):
        with patch.object(runner, "git", side_effect=runner.RunnerError("FETCH_HEAD is read-only")) as git:
            with self.assertRaisesRegex(runner.RunnerError, "FETCH_HEAD is read-only"):
                runner.fetch_and_pin_main(Path("."))
        self.assertEqual(git.call_count, 1)

    def test_coordinator_commits_only_bounded_review_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            remote = base / "origin.git"
            repo = base / "repo"
            subprocess.run(["git", "init", "--bare", "-q", str(remote)], check=True)
            subprocess.run(["git", "init", "-q", "-b", "main", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            active = f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md"
            archive = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            target_path = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
            readme = f"{runner.PACKET_ROOT}/README.md"
            (repo / active).parent.mkdir(parents=True)
            (repo / active).write_text("active review packet\n")
            (repo / target_path).parent.mkdir(parents=True)
            implementation_file = repo / "implementation.py"
            implementation_file.write_text("implementation\n")
            subprocess.run(["git", "-C", str(repo), "add", "implementation.py"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "implementation"], check=True)
            implementation_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                                text=True, capture_output=True).stdout.strip()
            baseline_target = target_packet(implementation_sha)
            (repo / target_path).write_text(baseline_target)
            (repo / readme).write_text("active packet index\n")
            subprocess.run(["git", "-C", str(repo), "add", active, readme, target_path], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture"], check=True)
            target_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                        text=True, capture_output=True).stdout.strip()
            subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", str(remote)], check=True)
            subprocess.run(["git", "-C", str(repo), "push", "-qu", "origin", "main"], check=True)
            worktree = base / "review-worktree"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", "agent/review-sample",
                            str(worktree)], check=True)
            (worktree / active).unlink()
            (worktree / archive).parent.mkdir(parents=True, exist_ok=True)
            (worktree / target_path).write_text(append_receipt(
                baseline_target, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=target_sha, implementation_commit=implementation_sha))
            (worktree / archive).write_text(f"""# Review
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `{target_path}`
- Authoring chat: `https://chatgpt.com/c/example`

## Independent Review
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-sample`
- Review target workstream: `sample-impl`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{target_sha}`
- Reviewed implementation commit: `{implementation_sha}`
""")
            (worktree / readme).write_text("archived review packet index\n")
            summary = worktree / runner.expected_summary_path("review-sample")
            summary.write_text("Authoring chat: https://chatgpt.com/c/example\n\n## Next Handoff\n- Next workstream: none\n")
            run_dir = base / "run"
            run_dir.mkdir()
            (run_dir / "validation.json").write_text(json.dumps({
                "schema": "custodian.validation.result.v1", "passed": True,
                "coverage": {"complete": True}, "tests": [{"status": "passed"}]}))
            host_evidence = {"implementation_commit": implementation_sha,
                             "report_sha256": "report-digest", "metadata_sha256": "metadata-digest"}

            implementation_summary = worktree / runner.expected_summary_path("sample-impl")
            implementation_summary.write_text("reviewer must not replace the implementation summary\n")
            with patch.object(runner, "verify_coordinator_validation"), \
                 self.assertRaisesRegex(runner.RunnerError, "outside its bounded evidence scope"):
                runner.coordinator_finish_review(repo, "review-sample", worktree, active, "sample-impl",
                                                 target_path, baseline_target,
                                                 "https://chatgpt.com/c/example", target_sha, run_dir,
                                                 host_evidence)
            implementation_summary.unlink()

            original_run = subprocess.run
            finish_calls = []
            def intercept_finish(argv, *args, **kwargs):
                if any(str(part).endswith("workstream.py") for part in argv):
                    finish_calls.append((argv, kwargs.get("cwd")))
                    return subprocess.CompletedProcess(argv, 0,
                                                        f"finished agent/review-sample; verified {target_sha} reachable from origin/main", "")
                return original_run(argv, *args, **kwargs)

            with patch.object(runner.subprocess, "run", side_effect=intercept_finish), \
                 patch.object(runner, "verify_coordinator_validation"):
                landed_sha = runner.coordinator_finish_review(repo, "review-sample", worktree, active, "sample-impl",
                                                             target_path, baseline_target,
                                                             "https://chatgpt.com/c/example", target_sha, run_dir,
                                                             host_evidence)
            self.assertEqual(landed_sha, target_sha)
            self.assertEqual(len(finish_calls), 1)
            self.assertEqual(Path(finish_calls[0][1]), repo)
            committed = subprocess.run(["git", "-C", str(worktree), "diff-tree", "--no-commit-id",
                                        "--name-only", "-r", "HEAD"], check=True, text=True,
                                       capture_output=True).stdout.splitlines()
            self.assertEqual(set(committed), {active, archive, readme, summary.name, target_path})

    def test_landed_review_uses_exact_summary_and_pinned_git_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            target_path = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
            implementation_file = repo / "implementation.py"
            implementation_file.write_text("implementation\n")
            subprocess.run(["git", "-C", str(repo), "add", "implementation.py"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "implementation"], check=True)
            implementation_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                                text=True, capture_output=True).stdout.strip()
            target_text = target_packet(implementation_sha)
            target_file = repo / target_path
            target_file.parent.mkdir(parents=True)
            target_file.write_text(target_text)
            subprocess.run(["git", "-C", str(repo), "add", target_path], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "target"], check=True)
            target_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                        text=True, capture_output=True).stdout.strip()
            (repo / target_path).write_text(append_receipt(
                target_text, review_workstream="review-sample", target_workstream="sample-impl",
                reviewed_main=target_sha, implementation_commit=implementation_sha))
            review_path = f"{runner.PACKET_ROOT}/archived/REVIEW_SAMPLE.md"
            review_text = f"""# Review
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sample`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sample-impl`
- Locks: `agent-workflow`
- Review target workstream: `sample-impl`
- Review target packet: `{target_path}`
- Authoring chat: `https://chatgpt.com/c/example`

## Independent Review
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-sample`
- Review target workstream: `sample-impl`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{target_sha}`
- Reviewed implementation commit: `{implementation_sha}`
"""
            summary_path = runner.expected_summary_path("review-sample")
            summary = (f"Authoring chat: https://chatgpt.com/c/example\n\n## Next Handoff\n"
                       "- Next workstream: none\n- Next action: done\n")
            subprocess.run(["git", "-C", str(repo), "add", target_path], check=True)
            for path, content in ((review_path, review_text), (summary_path, summary),
                                   ("UNRELATED_CLAUDE_SUMMARY.md", "review-sample appears here only\n")):
                file = repo / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(content)
            subprocess.run(["git", "-C", str(repo), "add", review_path, summary_path,
                            "UNRELATED_CLAUDE_SUMMARY.md"], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "review"], check=True)
            revision = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                      text=True, capture_output=True).stdout.strip()
            reviewer_checkout = repo.parent / "reviewer-checkout"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "--detach",
                            str(reviewer_checkout), revision], check=True, text=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "worktree", "remove", str(reviewer_checkout)],
                           check=True, text=True, capture_output=True)
            grep = subprocess.run(["git", "-C", str(repo), "grep", "-l", "review-sample", revision,
                                   "--", "*_CLAUDE_SUMMARY.md"], check=True, text=True, capture_output=True).stdout
            self.assertIn(f"{revision}:UNRELATED_CLAUDE_SUMMARY.md", grep)
            state = runner.landed_review_state(repo, revision, "review-sample",
                                               f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md", "sample-impl",
                                               target_path, target_text,
                                               "https://chatgpt.com/c/example", target_sha)
            self.assertTrue(state["complete"], state["reasons"])
            self.assertEqual(state["summary_path"], summary_path)

            subprocess.run(["git", "-C", str(repo), "rm", summary_path], check=True,
                           text=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "remove exact summary"], check=True)
            missing_revision = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                                              text=True, capture_output=True).stdout.strip()
            missing = runner.landed_review_state(repo, missing_revision, "review-sample",
                                                 f"{runner.PACKET_ROOT}/REVIEW_SAMPLE.md", "sample-impl",
                                                 target_path, target_text,
                                                 "https://chatgpt.com/c/example", target_sha)
            self.assertFalse(missing["complete"])
            self.assertTrue(missing["reasons"])

    def test_fake_codex_fixture_advertises_required_ephemeral_interface(self):
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp) / "codex"
            capture = Path(temp) / "capture.json"
            source = f'''#!{sys.executable}
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
if args == ["exec", "--help"]:
    print("codex exec --ephemeral --json --output-last-message --sandbox --cd --add-dir --approve-for-me")
    raise SystemExit(0)
if "--sandbox" in args and "--approve-for-me" in args:
    print("incompatible approval flags", file=sys.stderr)
    raise SystemExit(2)
prompt = sys.stdin.read()
Path(os.environ["FAKE_CODEX_CAPTURE_PATH"]).write_text(json.dumps({{"args": args, "cwd": os.getcwd(), "prompt": prompt}}))
output = Path(args[args.index("--output-last-message") + 1])
output.write_text("fake review finished\\n")
print(json.dumps({{"type": "done", "api_key": "fixture-secret"}}))
'''
            fixture.write_text(source)
            fixture.chmod(0o755)
            with patch.dict(os.environ, {"PATH": temp, "FAKE_CODEX_CAPTURE_PATH": str(capture)}):
                self.assertEqual(runner.codex_preflight(), str(fixture))
                rejected = subprocess.run([str(fixture), "exec", "--sandbox", "workspace-write", "--approve-for-me"],
                                           text=True, capture_output=True)
                self.assertEqual(rejected.returncode, 2)
                run_dir = Path(temp) / "run-evidence"
                run_dir.mkdir()
                argv = [str(fixture), "exec", "--ephemeral", "--json", "--approve-for-me", "--cd", temp,
                        "--add-dir", str(run_dir), "--output-last-message", str(run_dir / "last.txt"), "-"]
                self.assertEqual(runner.launch_codex(argv, Path(temp), "review prompt", run_dir, None), 0)
            observed = json.loads(capture.read_text())
            self.assertEqual(observed["cwd"], temp)
            self.assertIn("--ephemeral", observed["args"])
            self.assertIn("--approve-for-me", observed["args"])
            self.assertNotIn("--sandbox", observed["args"])
            self.assertEqual(observed["prompt"], "review prompt")
            self.assertNotIn("fixture-secret", (run_dir / "codex.jsonl").read_text())

    def test_human_gate_and_non_review_are_refused(self):
        packet = runner.parse_packet("review.md", review_packet(visual="required"))
        with patch.object(runner, "packet_at_main", return_value=("review.md", review_packet(visual="required"), packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human visual"):
                runner.validate_eligible_review(Path("."), "review-sample")
        packet = runner.parse_packet("impl.md", target_packet())
        with patch.object(runner, "packet_at_main", return_value=("impl.md", target_packet(), packet)):
            with self.assertRaisesRegex(runner.RunnerError, "non-review"):
                runner.validate_eligible_review(Path("."), "sample-impl")
        gated = review_packet(refresh="yes")
        packet = runner.parse_packet("review.md", gated)
        with patch.object(runner, "packet_at_main", return_value=("review.md", gated, packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human planning"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_successor_handoff_refresh_does_not_gate_current_review(self):
        # Both section spellings are live: F15-A uses "Next Handoff", WB25 "Handoff".
        for heading in ("## Handoff", "## Next Handoff"):
            with self.subTest(heading=heading):
                content = review_packet() + f"""
{heading}
- Next workstream: `next-slice`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
"""
                packet = runner.parse_packet("review.md", content)
                target = target_packet()
                with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)), \
                     patch.object(runner, "read_git_text", return_value=target), \
                     patch.object(runner, "git", return_value="a" * 40), \
                     patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
                    runner.validate_eligible_review(Path("."), "review-sample")

    def test_successor_scoped_refresh_planning_authority_does_not_gate_review(self):
        content = review_packet() + """
## Refresh Planning Authority
- Refresh applies to: `successor`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh instruction: After this review passes, plan the next slice.

## Handoff
- Next workstream: `next-slice`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
"""
        packet = runner.parse_packet("review.md", content)
        with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)), \
             patch.object(runner, "read_git_text", return_value=target_packet()), \
             patch.object(runner, "git", return_value="a" * 40), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
            runner.validate_eligible_review(Path("."), "review-sample")

        for gated in (
            content.replace("- Refresh applies to: `successor`\n", ""),
            content.replace("- Next workstream: `next-slice`", "- Next workstream: `none`"),
            content.split("## Handoff", 1)[0],
            content.replace("- ChatGPT/user planning refresh required: `no`",
                            "- ChatGPT/user planning refresh required: `yes`", 1),
        ):
            with self.subTest(gated=gated[-90:]):
                parsed = runner.parse_packet("review.md", gated)
                with patch.object(runner, "packet_at_main", return_value=("review.md", gated, parsed)):
                    with self.assertRaisesRegex(runner.RunnerError, "human planning|human-owned"):
                        runner.validate_eligible_review(Path("."), "review-sample")

    def test_actual_vaultwing_review_successor_refresh_is_not_a_current_gate(self):
        review_path = "custodian/docs/ai_context/task_packets/REVIEW_VAULTWING_RUNTIME_HARDENING.md"
        content = (ROOT / review_path).read_text(encoding="utf-8")
        self.assertIn("- Refresh applies to: `successor`", content)
        parsed = runner.parse_packet(review_path, content)
        self.assertIsNone(parsed.error)
        self.assertEqual(parsed.status, "ready")
        target = (ROOT / parsed.review_target_packet).read_text(encoding="utf-8")
        with patch.object(runner, "packet_at_main", return_value=(review_path, content, parsed)), \
             patch.object(runner, "git", return_value=target), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
            runner.validate_eligible_review(ROOT, "review-vaultwing-runtime-hardening")

    def test_actual_wb25_review_packet_is_eligible_despite_successor_refresh(self):
        # WB25's review correctly left the active queue after closeout. Reuse the
        # immutable historical packet, restoring only pre-claim lifecycle metadata
        # in memory so this regression survives normal archive transitions.
        review_path = "custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md"
        archived_content = (ROOT / review_path).read_text(encoding="utf-8")
        self.assertIn("- Status: complete", archived_content)
        self.assertIn("- Review: none", archived_content)
        archived_packet_data = runner.parse_packet(review_path, archived_content)
        self.assertIsNone(archived_packet_data.error)
        self.assertEqual(archived_packet_data.status, "complete")
        self.assertEqual(archived_packet_data.review, "none")
        review_content = archived_content.replace("- Status: complete", "- Status: ready", 1)
        review_packet_data = runner.parse_packet(review_path, review_content)
        self.assertIsNone(review_packet_data.error)
        target_content = (ROOT / review_packet_data.review_target_packet).read_text(encoding="utf-8")
        with patch.object(runner, "packet_at_main", return_value=(review_path, review_content, review_packet_data)), \
             patch.object(runner, "git", return_value=target_content), \
             patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)):
            runner.validate_eligible_review(ROOT, "review-operator-2-5d-workbench-review-automation")

    def test_human_owner_in_current_review_authority_is_refused(self):
        content = review_packet() + """
## Current Review Authority
- Refresh owner: `chatgpt-user`
## Handoff
- Refresh owner: `none`
"""
        packet = runner.parse_packet("review.md", content)
        with patch.object(runner, "packet_at_main", return_value=("review.md", content, packet)):
            with self.assertRaisesRegex(runner.RunnerError, "human-owned refresh"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_review_target_must_be_complete_and_present(self):
        packet = runner.parse_packet("review.md", review_packet())
        with patch.object(runner, "packet_at_main", return_value=("review.md", review_packet(), packet)), \
             patch.object(runner, "git", side_effect=runner.RunnerError("missing")):
            with self.assertRaisesRegex(runner.RunnerError, "completed review target"):
                runner.validate_eligible_review(Path("."), "review-sample")

    def test_missing_codex_fails_preflight_without_claim_process(self):
        packet = runner.parse_packet("review.md", review_packet())
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            with patch.object(runner, "git", return_value=str(repo)), \
                 patch.object(runner, "validate_eligible_review", return_value=("review.md", "", packet)), \
                 patch.object(runner, "codex_preflight", side_effect=runner.RunnerError("codex unavailable")), \
                 patch.object(runner.subprocess, "run") as claim:
                with self.assertRaisesRegex(runner.RunnerError, "codex unavailable"):
                    runner.run(repo, "review-sample")
                claim.assert_not_called()

    def test_duplicate_local_runner_refuses_before_claim(self):
        packet = runner.parse_packet("review.md", review_packet())
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            common = repo / ".git"
            lock_path = common / "custodian-review-runs/locks/review-sample.lock"
            lock_path.parent.mkdir(parents=True)
            with lock_path.open("a") as held:
                fcntl.flock(held, fcntl.LOCK_EX | fcntl.LOCK_NB)
                with patch.object(runner, "git", return_value=str(repo)), \
                     patch.object(runner, "validate_eligible_review", return_value=("review.md", "", packet)), \
                     patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                     patch.object(runner, "common_dir", return_value=common), \
                     patch.object(runner.subprocess, "run") as claim:
                    with self.assertRaisesRegex(runner.RunnerError, "another local runner"):
                        runner.run(repo, "review-sample")
                    claim.assert_not_called()

    def test_codex_launch_failure_after_claim_leaves_recovery_card(self):
        packet_text = review_packet()
        packet = runner.parse_packet("review.md", packet_text)
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp) / "repo"
            common = repo / ".git"
            worktree = Path(temp) / "claimed-review"
            worktree.mkdir(parents=True)
            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(worktree), "branch": "agent/review-sample",
                       "packet": "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"}
            (worktree / receipt["packet"]).parent.mkdir(parents=True)
            (worktree / receipt["packet"]).write_text(packet_text)
            completed = subprocess.CompletedProcess([], 0, "claim receipt", "")
            with patch.object(runner, "git", return_value=str(repo)), \
                 patch.object(runner, "validate_eligible_review", return_value=(receipt["packet"], packet_text, packet)), \
                 patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                 patch.object(runner, "run_coordinator_validation", return_value={
                     "implementation_commit": "a" * 40, "implementation_parent": "b" * 40,
                     "report_path": str(common / "validation.json"), "report_sha256": "c" * 64,
                     "metadata_sha256": "d" * 64, "summary": {}, "selected": []}), \
                 patch.object(runner, "common_dir", return_value=common), \
                 patch.object(runner, "parse_claim_receipt", return_value=receipt), \
                 patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
                 patch.object(runner.subprocess, "run", return_value=completed), \
                 patch.object(runner.subprocess, "Popen", side_effect=OSError("fixture launch failure")):
                self.assertEqual(runner.run(repo, "review-sample"), 2)
            run_dir = next((common / "custodian-review-runs/review-sample").iterdir())
            metadata = json.loads((run_dir / "metadata.json").read_text())
            self.assertEqual(metadata["phase"], "codex_launch_failed_recovery")
            recovery = (run_dir / "RECOVERY.md").read_text()
            self.assertIn(str(worktree), recovery)
            self.assertIn(str(run_dir), recovery)

    def test_receipt_verifies_exact_branch_worktree_and_packet(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp) / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "checkout", "-qb", "agent/review-sample"], check=True)
            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(repo), "branch": "agent/review-sample",
                       "packet": "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"}
            parsed = runner.parse_claim_receipt("CLAIMED\n" + runner.CLAIM_SENTINEL + json.dumps(receipt), "review-sample", repo)
            self.assertEqual(parsed["workstream"], "review-sample")
            receipt["workstream"] = "other-review"
            with self.assertRaisesRegex(runner.RunnerError, "does not verify"):
                runner.parse_claim_receipt(runner.CLAIM_SENTINEL + json.dumps(receipt), "review-sample", repo)

    def test_prompt_is_durable_evidence_only_and_safe_logs_redact_secrets(self):
        prompt = runner.prompt_for("review-sample", "review.md", "archived/impl.md",
                                   implementation_summary_path="SAMPLE_IMPL_CLAUDE_SUMMARY.md",
                                   validation_sha256="abc123")
        self.assertIn("Do not use, request, or infer the implementation-session transcript", prompt)
        self.assertIn("Do not run `git fetch`, `git push`, `git add`, `git commit`", prompt)
        self.assertIn("workstream.py finish", prompt)
        self.assertIn("validation.json", prompt)
        self.assertIn("Write the canonical review summary only to `REVIEW_SAMPLE_CLAUDE_SUMMARY.md`", prompt)
        self.assertIn("Do not edit reviewed implementation/runtime code or `SAMPLE_IMPL_CLAUDE_SUMMARY.md`", prompt)
        self.assertIn("Choose `passed`, `findings`, or `human_required`", prompt)
        self.assertIn("SHA-256 `abc123`", prompt)
        self.assertNotIn("transcript contents", prompt)
        line = json.dumps({"type": "event", "api_key": "private-value", "message": "Bearer abcdefghijklmnop"})
        safe = runner.safe_output(line)
        self.assertNotIn("private-value", safe)
        self.assertNotIn("abcdefghijklmnop", safe)

    def test_next_handoff_is_returned_from_durable_summary(self):
        summary = "## Findings\nPass\n\n## Next Handoff\n- Next workstream: none\n- Next action: done\n"
        self.assertIn("Next workstream: none", runner.next_handoff(summary))

    def test_nonzero_codex_exit_is_preserved_with_sanitized_streamed_logs(self):
        class Input(io.StringIO):
            def close(self):
                self.captured = self.getvalue()
                super().close()
        class FailedCodex:
            returncode = 19
            def __init__(self, argv, **kwargs):
                self.stdin = Input()
                self.stdout = io.StringIO('{"api_key":"never-log-this"}\n')
                self.stderr = io.StringIO("codex failed\n")
            def wait(self, timeout=None):
                return self.returncode
        with tempfile.TemporaryDirectory() as temp:
            run_dir = Path(temp)
            with patch.object(runner.subprocess, "Popen", side_effect=lambda argv, **kwargs: FailedCodex(argv, **kwargs)):
                exit_code = runner.launch_codex(["codex", "exec"], Path(temp), "review", run_dir, None)
            self.assertEqual(exit_code, 19)
            self.assertNotIn("never-log-this", (run_dir / "codex.jsonl").read_text())
            self.assertIn("codex failed", (run_dir / "codex.stderr").read_text())

    def test_success_claims_exact_review_and_launches_fresh_ephemeral_cwd(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repo = base / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            packet_path = "custodian/docs/ai_context/task_packets/REVIEW_SAMPLE.md"
            target_packet_path_expected = "custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md"
            (repo / packet_path).parent.mkdir(parents=True)
            (repo / packet_path).write_text(review_packet())
            (repo / "AGENTS.md").write_text("test guidance\n")
            target = repo / "custodian/docs/ai_context/task_packets/archived/SAMPLE_IMPL.md"
            target.parent.mkdir(parents=True)
            target.write_text(target_packet())
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture"], check=True)
            worktree = base / "review-worktree"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", "agent/review-sample", str(worktree)], check=True)
            cache_root = base / "review-cache" / "custodian"
            cache_root.mkdir(parents=True)

            receipt = {"result": "claimed", "workstream": "review-sample", "verified": True,
                       "worktree": str(worktree), "branch": "agent/review-sample", "packet": packet_path}
            completed = subprocess.CompletedProcess([], 0, "CLAIMED\n" + runner.CLAIM_SENTINEL + json.dumps(receipt), "")
            original_run = subprocess.run
            def run_side_effect(argv, *args, **kwargs):
                if argv and len(argv) > 1 and str(argv[1]).endswith("dispatch.py"):
                    self.assertEqual(argv[2:5], ["claim", "review-sample", "--agent"])
                    self.assertEqual(argv[5], "codex-reviewer")
                    return completed
                if argv and argv[:2] == ["git", "show"]:
                    requested = argv[2]
                    if requested == f"{'a' * 40}:{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md":
                        return subprocess.CompletedProcess(argv, 0, target_packet(), "")
                    if requested == f"{'a' * 40}:{summary_path}":
                        return subprocess.CompletedProcess(argv, 0, summary if summary_available["value"] else "", "")
                if argv and argv[:2] == ["git", "cat-file"]:
                    return subprocess.CompletedProcess(argv, 0 if summary_available["value"] else 1, "", "")
                return original_run(argv, *args, **kwargs)

            summary_path = "REVIEW_SAMPLE_CLAUDE_SUMMARY.md"
            summary = "## Findings\nPass.\n\n## Next Handoff\n- Next workstream: none\n- Next action: done\n"
            summary_available = {"value": True}
            def git_side_effect(_repo, *args, check=True):
                if args == ("rev-parse", "--show-toplevel"):
                    return str(repo)
                if args == ("show", f"{'a' * 40}:{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"):
                    return target_packet()
                if args == ("show", f"{'a' * 40}:{summary_path}"):
                    return summary if summary_available["value"] else ""
                if args == ("rev-parse", "--verify", "origin/main^{commit}"):
                    return "a" * 40
                if args == ("branch", "--show-current"):
                    return "agent/review-sample"
                if args[:3] == ("fetch", "origin", "main"):
                    return ""
                raise AssertionError(f"unexpected git call: {args}")

            class CaptureInput(io.StringIO):
                captured = ""
                def close(self):
                    self.captured = self.getvalue()
                    super().close()

            self_test = self
            class FakeCodex:
                def __init__(self, argv, cwd, stdin, stdout, stderr, text, bufsize):
                    self.argv, self.cwd = argv, cwd
                    self.stdin = CaptureInput()
                    self.stdout = io.StringIO(json.dumps({"type": "done", "api_key": "should-not-persist"}) + "\n")
                    self.stderr = io.StringIO()
                    self.returncode = 0
                    self.prompt = ""
                def wait(self, timeout=None):
                    self.prompt = self.stdin.captured
                    self.assert_ephemeral = "--ephemeral" in self.argv
                    self_test.assertEqual(Path(self.cwd), worktree)
                    self_test.assertTrue(self.assert_ephemeral)
                    self_test.assertEqual(self.argv[self.argv.index("--cd") + 1], str(worktree))
                    self_test.assertIn("--approve-for-me", self.argv)
                    self_test.assertNotIn("--sandbox", self.argv)
                    add_dirs = [self.argv[index + 1] for index, value in enumerate(self.argv[:-1])
                                if value == "--add-dir"]
                    self_test.assertEqual(len(add_dirs), 2)
                    self_test.assertIn("custodian-review-runs/review-sample/", add_dirs[0])
                    self_test.assertEqual(add_dirs[1], str(cache_root))
                    common = runner.common_dir(repo).resolve()
                    writable = [Path(str(worktree)).resolve(), *(Path(path).resolve() for path in add_dirs)]
                    for forbidden in (common / "FETCH_HEAD", common / "index"):
                        self_test.assertFalse(any(path == forbidden or path in forbidden.parents
                                                  for path in writable), str(forbidden))
                    self_test.assertFalse(any(Path(path).resolve() == common or
                                              Path(path).resolve() in common.parents or
                                              common in Path(path).resolve().parents
                                              for path in add_dirs[1:]))
                    self_test.assertIn("Do not use, request, or infer the implementation-session transcript", self.prompt)
                    report_path = Path(add_dirs[0]) / "validation.json"
                    self_test.assertEqual(json.loads(report_path.read_text())["passed"], True)
                    self_test.assertIn("REVIEW_SAMPLE_CLAUDE_SUMMARY.md", self.prompt)
                    self_test.assertIn("SAMPLE_IMPL_CLAUDE_SUMMARY.md", self.prompt)
                    self_test.assertIn("abc123", self.prompt)
                    (cache_root / "reviewer-write-probe").write_text("writable\n")
                    output_path = Path(self.argv[self.argv.index("--output-last-message") + 1])
                    output_path.write_text("review complete\n")
                    return self.returncode

            def fake_host_validation(_worktree, run_dir, _reviewed_main, implementation_commit,
                                     *, target_workstream=None, target_packet_path=None):
                self.assertEqual(target_workstream, "sample-impl")
                self.assertEqual(target_packet_path, target_packet_path_expected)
                report = {"schema": "custodian.validation.result.v1", "passed": True,
                          "coverage": {"complete": True}, "tests": [{"id": "focused", "status": "passed"}]}
                (run_dir / "validation.json").write_text(json.dumps(report))
                (run_dir / "coordinator-validation.json").write_text("{}")
                return {"implementation_commit": implementation_commit, "implementation_parent": "b" * 40,
                        "report_path": str(run_dir / "validation.json"), "report_sha256": "abc123",
                        "metadata_sha256": "def456", "summary": {"passed": 1}, "selected": ["focused"]}

            with patch.object(runner, "validate_eligible_review", return_value=(packet_path, review_packet(), runner.parse_packet(packet_path, review_packet()))), \
                 patch.object(runner, "codex_preflight", return_value="/fake/codex"), \
                 patch.object(runner, "run_coordinator_validation", side_effect=fake_host_validation), \
                 patch.object(runner, "verify_coordinator_validation"), \
                 patch.object(runner.subprocess, "run", side_effect=run_side_effect), \
                 patch.object(runner.subprocess, "Popen", side_effect=lambda argv, **kwargs: FakeCodex(argv, **kwargs)), \
                 patch.object(runner, "git", side_effect=git_side_effect), \
                 patch.object(runner, "coordinator_finish_review", return_value="a" * 40), \
                 patch.object(runner, "reviewer_cache_roots", return_value=[cache_root]), \
                 patch.object(runner, "resolve_target_implementation_commit", return_value=("a" * 40, None)), \
                 patch.object(runner, "landed_review_state", side_effect=lambda *args: {
                     "complete": summary_available["value"], "summary_path": summary_path,
                     "reasons": [] if summary_available["value"] else ["missing exact summary"]}), \
                 patch.object(runner, "common_dir", return_value=repo / ".git"):
                self.assertEqual(runner.run(repo, "review-sample"), 0)
                summary_available["value"] = False
                with self.assertRaisesRegex(runner.RunnerError, "without durable review state"):
                    runner.run(repo, "review-sample")

            run_dirs = list((repo / ".git/custodian-review-runs/review-sample").glob("*"))
            self.assertEqual(len(run_dirs), 2)
            successful_run = next(path for path in run_dirs if json.loads((path / "metadata.json").read_text())["phase"] == "complete")
            log_text = (successful_run / "codex.jsonl").read_text()
            self.assertNotIn("should-not-persist", log_text)
            metadata = json.loads((successful_run / "metadata.json").read_text())
            self.assertEqual(metadata["phase"], "complete")
            self.assertEqual(metadata["next_handoff"].splitlines()[0], "- Next workstream: none")
            failed_run = next(path for path in run_dirs if json.loads((path / "metadata.json").read_text())["phase"] == "failed_missing_durable_review_state")
            self.assertTrue((failed_run / "RECOVERY.md").is_file())


class AdvancedHeadPassRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "config", "user.name", "test"], check=True)
        subprocess.run(["git", "-C", str(self.repo), "config", "user.email", "test@example.invalid"], check=True)

    def git(self, *args):
        result = subprocess.run(["git", *args], cwd=self.repo, text=True, capture_output=True)
        if result.returncode:
            raise AssertionError(result.stderr or result.stdout)
        return result.stdout.strip()

    def _base_commit(self):
        active = runner.ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET
        target = runner.ADVANCED_HEAD_PASS_TARGET_PACKET
        readme = f"{runner.PACKET_ROOT}/README.md"
        (self.repo / active).parent.mkdir(parents=True, exist_ok=True)
        (self.repo / active).write_text("# Active review\n")
        (self.repo / target).parent.mkdir(parents=True, exist_ok=True)
        (self.repo / target).write_text("# Target packet\n")
        (self.repo / readme).write_text("active review\n")
        self.git("add", "--", active, target, readme)
        self.git("commit", "-m", "base")
        return self.git("rev-parse", "HEAD")

    def _reviewer_commit(self, *, extra_path=None):
        active = runner.ADVANCED_HEAD_PASS_ACTIVE_REVIEW_PACKET
        archive = runner.ADVANCED_HEAD_PASS_REVIEW_PACKET
        target = runner.ADVANCED_HEAD_PASS_TARGET_PACKET
        readme = f"{runner.PACKET_ROOT}/README.md"
        (self.repo / archive).write_text("# Archived review\n")
        (self.repo / active).unlink()
        (self.repo / target).write_text("# Target packet\n\n## Independent Review\n")
        (self.repo / readme).write_text("review archived\n")
        (self.repo / runner.ADVANCED_HEAD_PASS_SUMMARY).write_text("review summary\n")
        paths = [active, archive, target, readme, runner.ADVANCED_HEAD_PASS_SUMMARY]
        if extra_path:
            (self.repo / extra_path).parent.mkdir(parents=True, exist_ok=True)
            (self.repo / extra_path).write_text("unrelated\n")
            paths.append(extra_path)
        self.git("add", "-A", "--", *paths)
        self.git("commit", "-m", "reviewer closeout")
        return self.git("rev-parse", "HEAD")

    def _chain_patches(self, base, reviewer):
        return (
            patch.object(runner, "ADVANCED_HEAD_PASS_REMOTE_TIP", base),
            patch.object(runner, "ADVANCED_HEAD_PASS_REVIEWER_COMMIT", reviewer),
        )

    def test_commit_chain_accepts_only_pinned_reviewer_commit_and_outcome_child(self):
        base = self._base_commit()
        reviewer = self._reviewer_commit()
        with patch.object(runner, "ADVANCED_HEAD_PASS_REMOTE_TIP", base), \
             patch.object(runner, "ADVANCED_HEAD_PASS_REVIEWER_COMMIT", reviewer):
            commits, paths, recovery = runner._advanced_head_commit_chain(
                self.repo, self.repo, reviewer, base,
            )
            self.assertEqual(commits, [reviewer])
            self.assertEqual(set(paths), set(runner.ADVANCED_HEAD_PASS_ALLOWED_BASE_PATHS))
            self.assertEqual(recovery, [])
            review_path = self.repo / runner.ADVANCED_HEAD_PASS_REVIEW_PACKET
            review_path.write_text(review_path.read_text() + "\n## Review Outcome\n\nrecovery\n")
            self.git("add", "--", runner.ADVANCED_HEAD_PASS_REVIEW_PACKET)
            self.git("commit", "-m", "append outcome")
            child = self.git("rev-parse", "HEAD")
            commits, _, recovery = runner._advanced_head_commit_chain(
                self.repo, self.repo, child, base, allow_recovery_child=True,
            )
            self.assertEqual(commits, [reviewer, child])
            self.assertEqual(recovery, [runner.ADVANCED_HEAD_PASS_REVIEW_PACKET])
            commits, _, _ = runner._advanced_head_commit_chain(
                self.repo, self.repo, child, child, allow_recovery_child=True,
                allow_published_recovery_tip=True,
            )
            self.assertEqual(commits, [reviewer, child])
            with self.assertRaisesRegex(runner.RunnerError, "no matching exact-run recovery journal"):
                runner._advanced_head_commit_chain(self.repo, self.repo, child, child)

    def test_commit_chain_rejects_unrelated_remote_reversed_or_extra_ancestry(self):
        base = self._base_commit()
        reviewer = self._reviewer_commit()
        with patch.object(runner, "ADVANCED_HEAD_PASS_REMOTE_TIP", base), \
             patch.object(runner, "ADVANCED_HEAD_PASS_REVIEWER_COMMIT", reviewer):
            with self.assertRaisesRegex(runner.RunnerError, "neither the preserved tip"):
                runner._advanced_head_commit_chain(self.repo, self.repo, reviewer, "f" * 40)
            with self.assertRaisesRegex(runner.RunnerError, "no matching exact-run recovery journal"):
                runner._advanced_head_commit_chain(self.repo, self.repo, base, base)
            (self.repo / "unrelated.txt").write_text("unrelated\n")
            self.git("add", "--", "unrelated.txt")
            self.git("commit", "-m", "unrelated child")
            extra = self.git("rev-parse", "HEAD")
            with self.assertRaisesRegex(runner.RunnerError, "one Review Outcome path"):
                runner._advanced_head_commit_chain(self.repo, self.repo, extra, base,
                                                   allow_recovery_child=True)

    def test_commit_chain_rejects_extra_paths_in_original_reviewer_commit(self):
        base = self._base_commit()
        reviewer = self._reviewer_commit(extra_path="unrelated.txt")
        with patch.object(runner, "ADVANCED_HEAD_PASS_REMOTE_TIP", base), \
             patch.object(runner, "ADVANCED_HEAD_PASS_REVIEWER_COMMIT", reviewer):
            with self.assertRaisesRegex(runner.RunnerError, "exact review artifact manifest"):
                runner._advanced_head_commit_chain(self.repo, self.repo, reviewer, base)

    def test_reviewer_pass_requires_raw_final_summary_and_packet_agreement(self):
        main_sha = self._base_commit()
        run_dir = Path(self.temp.name) / "run"
        run_dir.mkdir()
        workstream = "review-agent-paired-review-exact-claim-parking-v1"
        run_id = "20261019T164227Z-e6abe304ef6c"
        final = (f"Workstream: {workstream}\n\nVerdict: `passed` — 0 blocking defects and 0 material gaps.\n"
                 f"Pinned SHA: `{main_sha}`.\n")
        (run_dir / "last-message.txt").write_text(final)
        (run_dir / "codex.jsonl").write_text("\n".join((
            json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": final}}),
            json.dumps({"type": "turn.completed"}),
        )) + "\n")
        summary = (f"## Verdict\nStatus: `passed`\nBlocking defects: `0`\nMaterial gaps: `0`\n"
                   f"Reviewed main: `{main_sha}`\n"
                   "## Review findings\nNo blocking findings.\n## Independent verification\nDone.\n")
        packet = ("# Review\n- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `review`\n- Status: `complete`\n"
                  "- Dispatch: `auto`\n- Priority: `P0`\n- Depends on: `agent-paired-review-exact-claim-parking-v1`\n"
                  "- Locks: `test`\n- Review: `passed`\n"
                  "- Review target workstream: `agent-paired-review-exact-claim-parking-v1`\n"
                  f"- Review target packet: `{runner.ADVANCED_HEAD_PASS_TARGET_PACKET}`\n"
                  f"- Reviewed main: `{main_sha}`\n- Reviewer context: `fresh`\n"
                  "- Reviewer provenance: `different-agent`\n- Review cycle: `0`\n")
        metadata = {"schema": runner.SCHEMA, "workstream": workstream, "run_id": run_id,
                    "phase": "post_exit_recovery", "fresh": True, "exit_code": 0,
                    "reviewed_main": main_sha}
        with patch.object(runner, "ADVANCED_HEAD_PASS_REVIEWED_MAIN", main_sha):
            provenance, accepted = runner._advanced_head_reviewer_pass(
                self.repo, run_dir, packet, summary, metadata,
            )
            self.assertEqual(provenance, "different-agent")
            self.assertEqual(accepted, final)
            bad_final = final.replace("passed", "findings")
            (run_dir / "last-message.txt").write_text(bad_final)
            (run_dir / "codex.jsonl").write_text("\n".join((
                json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": bad_final}}),
                json.dumps({"type": "turn.completed"}),
            )) + "\n")
            with self.assertRaisesRegex(runner.RunnerError, "unambiguous PASS"):
                runner._advanced_head_reviewer_pass(self.repo, run_dir, packet, summary, metadata)

    def test_exact_original_manifest_fails_closed_on_hash_or_file_set_change(self):
        run_dir = Path(self.temp.name) / "run-manifest"
        run_dir.mkdir()
        (run_dir / "metadata.json").write_text("original\n")
        manifest = {"metadata.json": hashlib.sha256(b"original\n").hexdigest()}
        with patch.object(runner, "ADVANCED_HEAD_PASS_ORIGINAL_EVIDENCE_SHA256", manifest):
            self.assertEqual(runner._advanced_head_original_manifest(run_dir), manifest)
            (run_dir / "metadata.json").write_text("changed\n")
            with self.assertRaisesRegex(runner.RunnerError, "manifest changed"):
                runner._advanced_head_original_manifest(run_dir)

    def test_outcome_append_preserves_every_existing_packet_byte(self):
        original = "# Review\r\n\r\nReviewer evidence.\r\n"
        outcome = "## Review Outcome\n- Outcome: `passed`\n"
        appended = runner._append_advanced_head_outcome(original, outcome)
        self.assertTrue(appended.startswith(original))
        self.assertEqual(appended[len(original):], "\n" + outcome)

    def test_recovery_journal_is_required_and_bound_before_accepting_advanced_head(self):
        manifest = {"metadata.json": "a" * 64}
        journal_path = (self.repo / ".git" / runner.ADVANCED_HEAD_PASS_RECOVERY_ROOT /
                        runner.ADVANCED_HEAD_PASS_RUN_ID / "recovery.json")
        journal_path.parent.mkdir(parents=True)
        journal = {
            "schema": runner.ADVANCED_HEAD_PASS_RECOVERY_SCHEMA,
            "workstream": runner.ADVANCED_HEAD_PASS_WORKSTREAM,
            "run_id": runner.ADVANCED_HEAD_PASS_RUN_ID,
            "reviewer_commit": runner.ADVANCED_HEAD_PASS_REVIEWER_COMMIT,
            "original_evidence_sha256": manifest,
            "initial_plan_sha256": "b" * 64,
            "stage": "prepared",
        }
        journal_path.write_text(json.dumps(journal))
        self.assertEqual(runner._advanced_head_recovery_journal(self.repo / ".git", manifest), journal)
        journal["original_evidence_sha256"] = {"metadata.json": "c" * 64}
        journal_path.write_text(json.dumps(journal))
        with self.assertRaisesRegex(runner.RunnerError, "identity or evidence manifest"):
            runner._advanced_head_recovery_journal(self.repo / ".git", manifest)

    def test_recovery_journal_rejects_symlinked_parent(self):
        external = Path(self.temp.name) / "external"
        external.mkdir()
        (self.repo / ".git" / "custodian-review-recoveries").symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(runner.RunnerError, "must not contain symlinks"):
            runner._advanced_head_recovery_journal_path(self.repo / ".git")

    def test_legacy_pass_metadata_exception_is_exact_run_only_and_rejects_duplicates(self):
        workstream = runner.ADVANCED_HEAD_PASS_WORKSTREAM
        packet = ("# Archived review\n- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `review`\n- Status: `complete`\n"
                  "- Dispatch: `auto`\n- Priority: `P0`\n- Depends on: `target`\n- Locks: `test`\n"
                  f"- Review: `passed`\n- Review target workstream: `{runner.ADVANCED_HEAD_PASS_TARGET}`\n"
                  f"- Review target packet: `{runner.ADVANCED_HEAD_PASS_TARGET_PACKET}`\n"
                  f"- Reviewed main: `{runner.ADVANCED_HEAD_PASS_REVIEWED_MAIN}`\n"
                  "- Reviewer context: `fresh`\n- Reviewer provenance: `different-agent`\n- Review cycle: `0`\n")
        packet += runner.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=workstream,
            target_workstream=runner.ADVANCED_HEAD_PASS_TARGET,
            reviewed_main=runner.ADVANCED_HEAD_PASS_REVIEWED_MAIN,
            implementation_commit=runner.ADVANCED_HEAD_PASS_REVIEWED_MAIN,
            provenance="different-agent", run_id=runner.ADVANCED_HEAD_PASS_RUN_ID,
            review_cycle=0, ids=(),
        )
        self.assertTrue(runner._advanced_head_legacy_pass_metadata_is_exact(packet, workstream))
        self.assertFalse(runner._advanced_head_legacy_pass_metadata_is_exact(packet, "review-other"))
        duplicate = packet.replace("- Review: `passed`", "- Review: `passed`\n- Review: `auto`")
        self.assertFalse(runner._advanced_head_legacy_pass_metadata_is_exact(duplicate, workstream))
        indented = packet.replace("- Review: `passed`", "  - Review: `passed`")
        self.assertFalse(runner._advanced_head_legacy_pass_metadata_is_exact(indented, workstream))

    def test_stale_apply_digest_stops_before_journaling(self):
        run_id = "20261019T164227Z-e6abe304ef6c"
        workstream = "review-agent-paired-review-exact-claim-parking-v1"
        lock = self.repo / ".git/custodian-review-runs/locks" / f"{workstream}.lock"
        lock.parent.mkdir(parents=True)
        lock.write_bytes(b"")
        plan = {"plan_sha256": "a" * 64}
        with patch.object(runner, "ADVANCED_HEAD_PASS_WORKSTREAM", workstream), \
             patch.object(runner, "ADVANCED_HEAD_PASS_RUN_ID", run_id), \
             patch.object(runner, "_advanced_head_plan_unlocked", return_value=plan):
            with self.assertRaisesRegex(runner.RunnerError, "state changed"):
                runner.apply_advanced_head_pass_closeout(
                    self.repo, workstream, run_id, "b" * 64,
                )
        self.assertFalse((self.repo / ".git" / runner.ADVANCED_HEAD_PASS_RECOVERY_ROOT).exists())


class PairedReviewHostValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "repo"
        self.root.mkdir()
        self.run_dir = Path(self.temp.name) / "run"
        self.run_dir.mkdir()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "test"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "core.filemode", "true"], check=True)
        (self.root / "README.md").write_text("base\n")
        self._commit("base")
        self.base = self._git("rev-parse", "HEAD")
        self.changed_paths = [
            "custodian/game/world/transfer.gd",
            "custodian/tools/validation/transfer_smoke.gd",
        ]
        for path in self.changed_paths:
            target = self.root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("extends RefCounted\n")
        self._commit("implementation")
        self.implementation = self._git("rev-parse", "HEAD")
        self.reviewed_main = self.implementation

    def tearDown(self):
        self.temp.cleanup()

    def _git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, check=True, text=True,
                              capture_output=True).stdout.strip()

    @contextmanager
    def _historical_claim_objects(self):
        """Supply exact trace-referenced claim commits absent from fresh clones.

        Diagnostic refs preserve trace.jsonl, but temporary dispatch-claim refs
        are deleted after publication. Their commit OIDs remain in the traces
        and are verified by host validation, so keep these exact object payloads
        in a temporary alternate object database instead of relying on dangling
        objects left in a developer's local repository.
        """
        claims = {
            "34a947cf00cb0050fbb435bb1840eed57adf63b0": (
                "ed748c33cd10c7d55c84752cfc79eea15fcea72d",
                "83bdbd1e53fdcb06b18a5a5645f70a050c3cba01", 1792308887,
                "workstream claim agent-paired-review-source-bearing-archive-gate-v1 codex:1245682:20261018T073442Z-9f32a80a4938"),
            "4f9f0e47f4d2c67ad8d6da3952e9889fe4597282": (
                "cbd4903f8533c5426c1f41bff86248fa7114d924",
                "1bb09be3cd76115413f9f433f7f8bf2048a7b81c", 1792370157,
                "workstream claim queue-execution-frontier-restoration-v1 codex:3683168:20261019T003556Z-5bd6e454aaf3"),
            "562bb25ee319985637ab365ecdb575371e0415f1": (
                "c8b7c19806d38fa8a88e5b36499467985a472bd4",
                "7119b4c385266e8928070b8e534ea3a5844a5f9f", 1792305694,
                "workstream claim agent-paired-review-source-span-main-sync-recovery-v1 codex:736221:20261018T064130Z-f6559c757a1f"),
            "a604d137ae0523410d3aa3e67b2c978e83a5691f": (
                "d69f4d3fc067f1a6ac7aa6c2489c553cc7311db4",
                "8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8", 1792376569,
                "workstream claim agent-paired-review-source-bearing-archive-gate-v1 codex:271048:20261019T022243Z-fbd7e4e2f3d7"),
            "b8db1853f396042e517ffe6ca13f8fd93b8837b6": (
                "cbd4903f8533c5426c1f41bff86248fa7114d924",
                "1bb09be3cd76115413f9f433f7f8bf2048a7b81c", 1792370028,
                "workstream claim queue-execution-frontier-restoration-v1 codex:3657389:20261019T003347Z-547f6421486d"),
            "ca0664cd9bbe8252846de67070b72fe5f1033e58": (
                "cbd4903f8533c5426c1f41bff86248fa7114d924",
                "1bb09be3cd76115413f9f433f7f8bf2048a7b81c", 1792370248,
                "workstream claim queue-execution-frontier-restoration-v1 codex:3694848:20261019T003727Z-bb7d35e7b6b9"),
            "cf0d93037d8f15bbf42585c717a17963547e2c12": (
                "b626e00b2f058b79d6978cd071fbdbd9cfc85f82",
                "06cbe9521dfa8efe82fb5820709646ca6d1486e7", 1792284761,
                "workstream claim agent-paired-review-host-validation-recovery-v1-review-corrections-1 codex:2356473:20261018T005240Z-25f5254d4395"),
            "f8f0bcfadb5ee08f393dd9427ae255e590e914ed": (
                "bf2cfb7acab460be5c5fbda2acda8e0203f45842",
                "6c818d16ed7c3dd19f156b80348fa4bc6929c748", 1792266810,
                "workstream claim worktree-backlog-census-and-safety-ledger-v1-review-corrections-1 codex:3998399:20261017T195329Z-de38cd920078"),
            "dcccefcd08be0651006f8c69c2c5adf6ad983106": (
                "8bbecae38ce1853b761f61a5e97086ac73ed0b0d",
                "d7061ab8f3ae7b641a91544465431db81574f735", 1792411738,
                "workstream claim agent-paired-review-braced-work-surface-v1 codex:903295:20261019T120857Z-96de098ad393"),
            "b59691d03f91bdd4e24eca195e186cfaedc73751": (
                "fde4d27b0bf4d693d1ffc530aed3f8a7c5e4037a",
                "55918d257cb3c663fb066f56eb79b23d174b7ae2", 1792408672,
                "workstream claim operator-motion-foundry-core-v1 codex:503300:20261019T111751Z-bc1d9d1546fb"),
        }
        with tempfile.TemporaryDirectory() as temporary:
            object_repo = Path(temporary) / "claim-objects.git"
            subprocess.run(["git", "init", "--bare", "-q", str(object_repo)], check=True)
            for oid, (tree, parent, timestamp, subject) in claims.items():
                payload = (
                    f"tree {tree}\nparent {parent}\n"
                    f"author codex <codex@workflow.invalid> {timestamp} -0400\n"
                    f"committer codex <codex@workflow.invalid> {timestamp} -0400\n\n"
                    f"{subject}\n"
                )
                actual = subprocess.run(
                    ["git", "hash-object", "-w", "-t", "commit", "--stdin"],
                    cwd=object_repo, input=payload, check=True, text=True, capture_output=True,
                ).stdout.strip()
                self.assertEqual(actual, oid, "historical claim fixture must retain its exact OID")
            old_alternates = os.environ.get("GIT_ALTERNATE_OBJECT_DIRECTORIES", "")
            alternates = str(object_repo / "objects")
            if old_alternates:
                alternates += os.pathsep + old_alternates
            with patch.dict(os.environ, {"GIT_ALTERNATE_OBJECT_DIRECTORIES": alternates}):
                yield

    def test_historical_execution_reset_archive_merge_followup_is_exactly_pinned(self):
        workstream = "agent-execution-reset-v1"
        archive = f"{runner.PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md"
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, "9c607b6d5df1149b31590eeae9eaf57b73b482f3",
                "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0", workstream, archive,
            )
        self.assertEqual(span["base"], "b5a46e82913455cb341c84811fd9be66b78ed138")
        self.assertEqual(span["head"], "f635c33d8bb209d9cbc4fafb4aff88af27084867")
        self.assertEqual(span["provenance"]["post_merge_followup"]["canonical_archive_commit"],
                         "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0")
        self.assertEqual(span["provenance"]["trace_landing_commit"], span["head"])
        self.assertEqual(span["provenance"]["post_merge_followup"]["post_merge_followup_commit"], span["head"])
        self.assertIn("custodian/tools/agent/test_workstream.py", span["paths"])
        self.assertEqual(set(span["provenance"]["post_merge_followup"]["followup_paths"]), {
            "AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md",
            "custodian/docs/ai_context/task_packets/archived/AGENT_EXECUTION_RESET_V1.md",
            "custodian/tools/agent/test_workstream.py",
        })

    def test_historical_blender_source_archive_admits_only_receipted_declared_blend(self):
        workstream = "operator-motion-foundry-blender-2d-rig-v1"
        archive = f"{runner.PACKET_ROOT}/archived/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md"
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, "9c607b6d5df1149b31590eeae9eaf57b73b482f3",
                "a6604a80be32c9078336ae48de6c4e43ec6815c7", workstream, archive,
            )
        blend = "custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/blender/operator_south_cutout_rig_v1.blend"
        self.assertEqual(span["head"], "a6604a80be32c9078336ae48de6c4e43ec6815c7")
        self.assertIn(blend, span["paths"])
        self.assertEqual(span["provenance"]["archive_kind"], "source-bearing")
        self.assertEqual(span["provenance"]["source_artifact"]["path"], blend)

    def test_pinned_reset_followup_rejects_wrong_run_duplicate_sync_and_wrong_final_head(self):
        workstream = "agent-execution-reset-v1"
        archive = f"{runner.PACKET_ROOT}/archived/AGENT_EXECUTION_RESET_V1.md"
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, "9c607b6d5df1149b31590eeae9eaf57b73b482f3",
                "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0", workstream, archive,
            )
            provenance = span["provenance"]
            trace = host_validation._trace_events(ROOT, provenance["ref"])
            claim_record = provenance["claim_trace"]
            claim_record = {**claim_record, "ref": provenance["ref"]}
            landing_record = provenance["landing_trace"]
            landing_record = {**landing_record, "ref": provenance["ref"],
                              "path": landing_record["worktree"]}
            verifier_args = (
                ROOT, workstream, archive, span["base"],
                "bf0f59f478c361b6b34b6e0c6c354c8f3649eac0",
            )
            mutations = []
            duplicate_sync = json.loads(json.dumps(trace))
            duplicate_sync.append(json.loads(json.dumps(next(
                event for event in trace if event["event"] == "main_sync"
            ))))
            mutations.append((duplicate_sync, "unique immutable claim and no-op sync"))
            bad_parent = json.loads(json.dumps(trace))
            next(event for event in bad_parent if event["event"] == "main_sync")["data"]["main_sha"] = "0" * 40
            mutations.append((bad_parent, "unique immutable claim and no-op sync"))
            for events, expected in mutations:
                with self.subTest(expected=expected), self.assertRaisesRegex(
                    host_validation.HostValidationError, expected,
                ):
                    host_validation._verify_reset_archive_merge_followup(
                        *verifier_args, "f635c33d8bb209d9cbc4fafb4aff88af27084867",
                        "134e4c2913fbb88ea25fd5395ff6dc059e26f05f", provenance["ref"],
                        provenance["run_id"], events, claim_record, landing_record,
                    )
            with self.assertRaisesRegex(host_validation.HostValidationError, "pinned run"):
                host_validation._verify_reset_archive_merge_followup(
                    *verifier_args, "0" * 40, "134e4c2913fbb88ea25fd5395ff6dc059e26f05f",
                    provenance["ref"], provenance["run_id"], trace, claim_record, landing_record,
                )
            with self.assertRaisesRegex(host_validation.HostValidationError, "pinned run"):
                host_validation._verify_reset_archive_merge_followup(
                    *verifier_args, "f635c33d8bb209d9cbc4fafb4aff88af27084867",
                    "134e4c2913fbb88ea25fd5395ff6dc059e26f05f", provenance["ref"],
                    "20261020T135840Z-db96534ed3a7", trace, claim_record, landing_record,
                )

    def test_blender_source_artifact_gate_rejects_wrong_archive_or_missing_receipt(self):
        workstream = "operator-motion-foundry-blender-2d-rig-v1"
        archive = f"{runner.PACKET_ROOT}/archived/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md"
        packet = subprocess.run(
            ["git", "show", f"9c607b6d5df1149b31590eeae9eaf57b73b482f3:{archive}"],
            cwd=ROOT, check=True, text=True, capture_output=True,
        ).stdout
        paths = {host_validation._BLENDER_SOURCE_PATH, host_validation._BLENDER_RECEIPT_PATH}
        with self.assertRaisesRegex(host_validation.HostValidationError, "exact pinned archive"):
            host_validation._verified_blender_source_artifact(ROOT, "0" * 40, packet, paths)
        with self.assertRaisesRegex(host_validation.HostValidationError, "packet-declared"):
            host_validation._verified_blender_source_artifact(
                ROOT, host_validation._BLENDER_SOURCE_ARCHIVE, packet,
                {host_validation._BLENDER_SOURCE_PATH},
            )
        unlisted = "custodian/asset_drop/source_work/operator/elsewhere/unauthorized.blend"
        self.assertIsNone(host_validation._verified_blender_source_artifact(
            ROOT, host_validation._BLENDER_SOURCE_ARCHIVE, packet, {unlisted},
        ))

    def _commit(self, message):
        subprocess.run(["git", "add", "-f", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", message], cwd=self.root, check=True)

    def _build_checkpoint_resume_fixture(self, *, variant="valid"):
        """Build a minimal real-Git checkpoint/resume history for adversarial controls."""
        repository = Path(self.temp.name) / f"checkpoint-{variant}"
        repository.mkdir()
        subprocess.run(["git", "init", "-q", str(repository)], check=True)
        for key, value in (("user.name", "test"), ("user.email", "test@example.invalid")):
            subprocess.run(["git", "-C", str(repository), "config", key, value], check=True)

        def git(*args, input_text=None):
            result = subprocess.run(["git", *args], cwd=repository, text=True,
                                    input=input_text, capture_output=True)
            if result.returncode:
                raise AssertionError(result.stderr or result.stdout)
            return result.stdout.strip()

        workstream = "agent-synthetic-checkpoint-resume"
        active = f"{runner.PACKET_ROOT}/SYNTHETIC_CHECKPOINT_RESUME.md"
        archive = f"{runner.PACKET_ROOT}/archived/SYNTHETIC_CHECKPOINT_RESUME.md"
        source_path = "custodian/tools/agent/provenance_fixture.py"
        test_path = "custodian/tools/agent/test_qzx.py"
        branch = f"agent/{workstream}"
        worktree = f"/tmp/{workstream}-20261020T120000Z-abcdef123456"
        run_id = "20261020T120000Z-abcdef123456"

        (repository / "README.md").write_text("base\n")
        for path in (source_path, test_path):
            target = repository / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("a\nb\nc\nd\ne\n" if path == source_path else "base\n")
        git("add", "-A")
        git("commit", "-qm", "initial reviewed history")
        reviewed_base = git("rev-parse", "HEAD")
        packet = (f"# Synthetic checkpoint resume\n"
                  f"- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `implementation`\n"
                  f"- Status: `in_progress`\n- Reviewed main: `{reviewed_base}`\n"
                  f"- Work surface: `{source_path}`; `{test_path if variant != 'unowned-test' else source_path}`\n")
        (repository / active).parent.mkdir(parents=True, exist_ok=True)
        (repository / active).write_text(packet)
        git("add", active)
        git("commit", "-qm", "publish source packet")
        source_base = git("rev-parse", "HEAD")

        git("checkout", "-qb", "workstream")
        (repository / source_path).write_text(
            "local implementation\nb\nc\nd\ne\n" if variant == "overlap"
            else "local implementation\nb\nc\nd\ne\n"
        )
        if variant != "unowned-test":
            (repository / test_path).write_text("base\nlocal test\n")
        else:
            (repository / test_path).write_text("base\nlocal unowned test\n")
        git("add", source_path, test_path)
        if variant == "undocumented-source":
            extra_source = "custodian/tools/agent/extra_qzx.py"
            (repository / extra_source).write_text("unowned local source\n")
            git("add", extra_source)
        git("commit", "-qm", "author implementation source")
        first_parent = git("rev-parse", "HEAD")
        if variant == "source-loss":
            (repository / source_path).unlink()
            git("add", source_path)
            git("commit", "-qm", "delete owned implementation source")
            first_parent = git("rev-parse", "HEAD")

        git("checkout", "-qb", "published-main", source_base)
        if variant == "unrelated-second-parent":
            # An independently rooted commit is not part of the claimed published history.
            git("checkout", "--orphan", "unrelated-main")
            (repository / "unrelated.md").write_text("foreign history\n")
            git("add", "-A")
            git("commit", "-qm", "unrelated history")
            second_parent = git("rev-parse", "HEAD")
        else:
            if variant == "overlap":
                (repository / source_path).write_text("a\nb\nc\nd\nmain addition\n")
                git("add", source_path)
            else:
                (repository / "published-main.md").write_text("published main\n")
                git("add", "published-main.md")
            git("commit", "-qm", "advance published main")
            second_parent = git("rev-parse", "HEAD")

        git("checkout", "workstream")
        if variant == "reordered-parents":
            ordered_tree = subprocess.run(
                ["git", "merge-tree", "--write-tree", second_parent, first_parent],
                cwd=repository, text=True, capture_output=True,
            )
            self.assertEqual(ordered_tree.returncode, 0, ordered_tree.stderr)
            tree = ordered_tree.stdout.splitlines()[0].strip()
            merge = git("commit-tree", tree, "-m", "reordered checkpoint merge",
                        "-p", second_parent, "-p", first_parent)
        elif variant in {"octopus-parents", "unrelated-second-parent"}:
            tree = git("rev-parse", f"{first_parent}^{{tree}}")
            if variant == "unrelated-second-parent":
                merge = git("commit-tree", tree, "-m", "unrelated checkpoint merge",
                            "-p", first_parent, "-p", second_parent)
            else:
                blob = git("hash-object", "-w", "--stdin", input_text="third parent\n")
                third_tree = git("mktree", input_text=f"100644 blob {blob}\tthird.txt\n")
                third_parent = git("commit-tree", third_tree, "-m", "third published parent",
                                   "-p", source_base)
                merge = git("commit-tree", tree, "-m", "octopus checkpoint merge",
                            "-p", first_parent, "-p", second_parent, "-p", third_parent)
        else:
            merge_result = subprocess.run(["git", "merge-tree", "--write-tree", first_parent,
                                           second_parent], cwd=repository, text=True,
                                          capture_output=True)
            if variant == "altered-tree":
                tree = git("rev-parse", f"{first_parent}^{{tree}}")
            else:
                self.assertEqual(merge_result.returncode, 0, merge_result.stderr)
                tree = merge_result.stdout.splitlines()[0].strip()
            merge = git("commit-tree", tree, "-m", "checkpoint resume merge",
                        "-p", first_parent, "-p", second_parent)
        git("reset", "--hard", merge)

        if variant == "repeated-merge":
            git("checkout", "-qb", "published-main-extra", source_base)
            (repository / "extra-main.md").write_text("extra main\n")
            git("add", "extra-main.md")
            git("commit", "-qm", "advance extra main")
            extra_parent = git("rev-parse", "HEAD")
            git("checkout", "workstream")
            git("merge", "--no-ff", "published-main-extra", "-m", "extra synchronization merge")

        # Archive-only closeout must follow the source span and preserve its exact target identity.
        (repository / archive).parent.mkdir(parents=True, exist_ok=True)
        (repository / archive).write_text(packet.replace("`in_progress`", "`complete`"))
        (repository / active).unlink()
        summary = f"{workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md"
        (repository / summary).write_text("synthetic closeout\n")
        (repository / f"{runner.PACKET_ROOT}/README.md").write_text("archived packet index\n")
        git("add", "-A")
        git("commit", "-qm", "archive workstream")
        landing = git("rev-parse", "HEAD")
        trace_landing = landing
        sync_side = None
        if variant == "sync-source-mutation":
            git("checkout", "-qb", "mutated-main", landing)
            (repository / source_path).write_text("local implementation\nb\nc\nd\nmain mutation\n")
            git("add", source_path)
            git("commit", "-qm", "mutate source on later main")
            sync_side = git("rev-parse", "HEAD")
            git("checkout", "-qb", "main-sync", landing)
            git("merge", "--no-ff", "mutated-main", "-m", "later main synchronization")
            trace_landing = git("rev-parse", "HEAD")

        claim_oid = git("commit-tree", f"{source_base}^{{tree}}", "-p", source_base,
                        "-m", f"workstream claim {workstream} codex:42:{run_id}")
        events = []
        def emit(name, data):
            events.append({"schema": "custodian.workflow_trace_event.v1", "schema_version": 1,
                           "run_id": run_id, "workstream": workstream, "packet": active,
                           "event": name, "data": data})
        emit("remote_claim_acquired", {"claim_oid": claim_oid, "main_sha": source_base,
             "local_ref": f"refs/custodian/claims/{workstream}/{run_id}",
             "remote_ref": f"refs/heads/dispatch-claims/{workstream}"})
        emit("worktree_published", {"head": source_base, "upstream": source_base,
             "branch": branch, "clean": True, "worktree": worktree})
        emit("start_completed", {"branch": branch, "worktree": worktree})
        trace_first_parent, trace_second_parent = (
            (second_parent, first_parent) if variant == "reordered-parents"
            else (first_parent, second_parent)
        )
        emit("checkpoint_completed", {"remote_head": trace_first_parent, "branch": branch,
             "removed": False})
        emit("worktree_resumed", {"head": merge, "branch": branch, "worktree": worktree})
        emit("main_sync", {"changed": False, "head": landing, "main_sha": trace_second_parent})
        if sync_side:
            emit("main_sync", {"changed": True, "head": trace_landing, "main_sha": sync_side})
        emit("landing_started", {"start_sha": trace_landing, "branch": branch, "target": "main"})
        emit("landing_completed", {"head": trace_landing, "outcome": "landed"})
        emit("teardown_started", {"head": trace_landing, "branch": branch, "worktree": worktree})
        emit("teardown_completed", {"head": trace_landing, "branch": branch,
             "worktree_removed": True, "worktree": worktree})
        raw = ("\n".join(json.dumps(event, sort_keys=True) for event in events) + "\n").encode()
        blob = git("hash-object", "-w", "--stdin", input_text=raw.decode())
        trace_tree = git("mktree", input_text=f"100644 blob {blob}\ttrace.jsonl\n")
        trace_commit = git("commit-tree", trace_tree, "-m", "checkpoint resume trace")
        trace_ref = f"refs/remotes/origin/agent-diagnostics/{workstream}/{run_id}"
        git("update-ref", trace_ref, trace_commit)
        return {"repo": repository, "base": reviewed_base, "source_base": source_base,
                "first_parent": first_parent, "second_parent": second_parent,
                "merge": merge, "landing": landing, "trace_landing": trace_landing,
                "reviewed_main": trace_landing, "workstream": workstream,
                "archive": archive, "source_path": source_path, "test_path": test_path}

    def _report(self, *, passed=True, changed_paths=None, selected=True):
        files = list(self.changed_paths if changed_paths is None else changed_paths)
        ids = ["transfer_smoke"] if selected else []
        return {
            "schema": "custodian.validation.result.v1",
            "passed": passed,
            "changed_files": files,
            "selected": ids,
            "tests": ([{"id": "transfer_smoke", "status": "passed"}] if selected else []),
            "summary": {"selected": len(ids), "passed": len(ids), "failed": 0,
                        "timed_out": 0, "skipped": 0, "infrastructure_errors": 0},
            "coverage": {"complete": True, "covered_files": files, "uncovered_files": [],
                         "excluded_files": [], "covered_by": {path: ids for path in files}},
        }

    def _run(self, report, *, source_edit=False):
        def execute(command, cwd):
            self.assertEqual(Path(cwd), self.root)
            self.assertEqual(command[-4:], ["--changed", "--base", self.base, "--json"])
            self.assertNotIn("--no-godot-lock", command)
            if source_edit:
                (self.root / self.changed_paths[0]).write_text("modified after validation\n")
            return subprocess.CompletedProcess(command, 0, json.dumps(report) + "\n", "")

        return execute

    def _tracked_png(self):
        source = "custodian/tools/iteration/grunt_candidate_ab/generated/candidate_e_64px.png"
        path = self.root / source
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"tracked-png-fixture")
        subprocess.run(["git", "-C", str(self.root), "add", source], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "tracked png"], check=True)
        self.reviewed_main = self._git("rev-parse", "HEAD")
        return source

    def _godot_png_import(self, source):
        return ("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n"
                "uid=\"uid://fixture123\"\npath=\"res://.godot/imported/candidate.ctex\"\n"
                "metadata={\n\"vram_texture\": false\n}\n\n[deps]\n\n"
                f"source_file=\"res://{source.removeprefix('custodian/')}\"\ndest_files=[\"res://.godot/imported/candidate.ctex\"]\n\n"
                "[params]\ncompress/mode=0\n")

    def test_host_validation_preserves_and_removes_only_new_valid_png_import_sidecars(self):
        source = self._tracked_png()
        sidecar = self.root / f"{source}.import"
        content = self._godot_png_import(source)

        def execute(command, cwd):
            sidecar.write_text(content)
            return subprocess.CompletedProcess(command, 0, json.dumps(self._report()) + "\n", "")

        evidence = host_validation.run_coordinator_validation(
            self.root, self.run_dir, self.reviewed_main, self.implementation,
            run_validation=execute,
            capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
        )
        self.assertFalse(sidecar.exists())
        manifest_path = self.run_dir / "generated-import-artifacts/manifest.json"
        manifest = json.loads(manifest_path.read_text())
        self.assertEqual(manifest[0]["source_path"], source)
        self.assertEqual(manifest[0]["sha256"], hashlib.sha256(content.encode()).hexdigest())
        saved = self.run_dir / manifest[0]["evidence_path"]
        self.assertEqual(saved.read_text(), content)
        self.assertFalse(host_validation._git(self.root, "status", "--porcelain", "--untracked-files=all"))
        self.assertEqual(evidence["generated_import_manifest_sha256"],
                         hashlib.sha256(manifest_path.read_bytes()).hexdigest())
        verified = host_validation.verify_coordinator_validation(
            self.root, self.run_dir, self.reviewed_main, self.implementation,
            expected_report_sha256=evidence["report_sha256"],
            expected_metadata_sha256=evidence["metadata_sha256"],
        )
        self.assertTrue(verified["passed"])
        saved.write_text(saved.read_text() + "# tampered\n")
        with self.assertRaisesRegex(host_validation.HostValidationError, "generated import artifact"):
            host_validation.verify_coordinator_validation(
                self.root, self.run_dir, self.reviewed_main, self.implementation,
                expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )

    def test_host_validation_preserves_new_png_import_sidecars_even_when_import_fails(self):
        source = self._tracked_png()
        sidecar = self.root / f"{source}.import"
        content = self._godot_png_import(source)

        def execute(command, cwd):
            sidecar.write_text(content)
            return subprocess.CompletedProcess(command, 3, json.dumps({
                "schema": "custodian.validation.result.v1", "passed": False,
                "infrastructure_failure": "import",
            }) + "\n", "ERROR: TLS handshake error")

        with self.assertRaisesRegex(host_validation.HostValidationError, "exit code 3"):
            host_validation.run_coordinator_validation(
                self.root, self.run_dir, self.reviewed_main, self.implementation,
                run_validation=execute,
                capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
            )
        self.assertFalse(sidecar.exists())
        manifest_path = self.run_dir / "generated-import-artifacts/manifest.json"
        manifest = json.loads(manifest_path.read_text())
        self.assertEqual(manifest[0]["source_path"], source)
        report = json.loads((self.run_dir / "validation.json").read_text())
        self.assertFalse(report["passed"])
        self.assertTrue((self.run_dir / "coordinator-validation.stderr").is_file())

    def test_host_validation_does_not_remove_invalid_or_unrelated_import_sidecars(self):
        source = "custodian/tools/iteration/grunt_candidate_ab/generated/candidate_e_64px.png"
        self._tracked_png()
        sidecar = self.root / f"{source}.import"

        def execute(command, cwd):
            sidecar.write_text("[remap]\nimporter=\"texture\"\n")
            return subprocess.CompletedProcess(command, 0, json.dumps(self._report()) + "\n", "")

        with self.assertRaisesRegex(host_validation.HostValidationError, "unclassified|source changed"):
            host_validation.run_coordinator_validation(
                self.root, self.run_dir, self.reviewed_main, self.implementation,
                run_validation=execute,
                capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
            )
        self.assertTrue(sidecar.is_file())

    def test_exact_failed_import_sidecar_inventory_authenticates_all_twelve_and_rejects_extras(self):
        expected = sorted(host_validation.FAILED_IMPORT_RECOVERY_SIDECARS)
        for sidecar in expected:
            source = sidecar[:-len(".import")]
            path = self.root / source
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"tracked png fixture")
        subprocess.run(["git", "-C", str(self.root), "add", *[item[:-len(".import")] for item in expected]], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "tracked grunt preview PNGs"], check=True)
        for sidecar in expected:
            source = sidecar[:-len(".import")]
            (self.root / sidecar).write_text(self._godot_png_import(source))
        records = host_validation.verified_failed_import_sidecars(self.root)
        self.assertEqual([item["sidecar_path"] for item in records], expected)
        extra = self.root / "custodian/tools/iteration/grunt_candidate_ab/generated/candidate_e_96px.png.import"
        extra.write_text(self._godot_png_import("custodian/tools/iteration/grunt_candidate_ab/generated/candidate_e_96px.png"))
        with self.assertRaisesRegex(host_validation.HostValidationError, "unrelated untracked"):
            host_validation.verified_failed_import_sidecars(self.root)
        extra.unlink()
        (self.root / expected[0]).write_text("[remap]\nimporter=\"texture\"\n")
        with self.assertRaisesRegex(host_validation.HostValidationError, "malformed"):
            host_validation.verified_failed_import_sidecars(self.root)

    def test_failed_import_pair_classifier_requires_exact_infrastructure_failure_and_hashes(self):
        original = {"workstream": runner.FAILED_IMPORT_RECOVERY_WORKSTREAM,
                    "run_id": runner.FAILED_IMPORT_RECOVERY_RUN_ID,
                    "reviewed_main": "a" * 40, "implementation_commit": "b" * 40}
        report = {"schema": "custodian.validation.result.v1", "passed": False,
                  "infrastructure_failure": "import"}
        report_bytes = (json.dumps(report) + "\n").encode()
        (self.run_dir / "validation.json").write_bytes(report_bytes)
        coordinator = {"schema": "custodian.paired_review_host_validation.v1",
                       "reviewed_main": original["reviewed_main"],
                       "implementation_commit": original["implementation_commit"],
                       "exit_code": 3, "source_changed_during_validation": True,
                       "report_path": str((self.run_dir / "validation.json").resolve()),
                       "report_sha256": hashlib.sha256(report_bytes).hexdigest(),
                       "report_parse_error": None,
                       "code_paths": ["custodian/tools/agent/paired_review_runner.py",
                                      "custodian/tools/agent/test_paired_review_runner.py"]}
        (self.run_dir / "coordinator-validation.json").write_text(json.dumps(coordinator))
        evidence = runner._failed_import_report_pair(
            self.run_dir, original, original["workstream"], original["run_id"],
        )
        self.assertEqual(evidence["infrastructure_failure"], "import")
        self.assertEqual(evidence["report_sha256"], hashlib.sha256(report_bytes).hexdigest())
        report["infrastructure_failure"] = "test"
        (self.run_dir / "validation.json").write_text(json.dumps(report) + "\n")
        self.assertIsNone(runner._failed_import_report_pair(
            self.run_dir, original, original["workstream"], original["run_id"],
        ))
        report["infrastructure_failure"] = "import"
        (self.run_dir / "validation.json").write_text(json.dumps(report) + "\n")
        self.assertIsNone(runner._failed_import_report_pair(
            self.run_dir, original, "review-other", original["run_id"],
        ))

    def test_failed_import_retry_state_is_append_only_and_bounded_to_two_attempts(self):
        workstream = runner.FAILED_IMPORT_RECOVERY_WORKSTREAM
        run_id = runner.FAILED_IMPORT_RECOVERY_RUN_ID
        child_dir = self.run_dir / "continuation-01"
        attempt_dir = child_dir / "host-validation/attempt-01"
        attempt_dir.mkdir(parents=True)
        (attempt_dir / "validation.json").write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": False,
            "infrastructure_failure": "import",
        }) + "\n")
        report_sha = hashlib.sha256((attempt_dir / "validation.json").read_bytes()).hexdigest()
        (attempt_dir / "coordinator-validation.json").write_text(json.dumps({
            "schema": "custodian.paired_review_host_validation.v1",
            "source_changed_during_validation": False, "report_sha256": report_sha,
            "generated_import_manifest_sha256": None,
        }) + "\n")
        manifest = runner._file_manifest(attempt_dir)
        attempt = {"attempt": 1, "status": "failed", "manifest": manifest,
                   "manifest_sha256": runner._manifest_digest(manifest),
                   "report_sha256": manifest["validation.json"],
                   "metadata_sha256": manifest["coordinator-validation.json"]}
        child = {"schema": runner.CONTINUATION_SCHEMA, "workstream": workstream,
                 "run_id": run_id, "phase": "host_validation_failed",
                 "reviewer_launch_count": 0, "generated_import_recovery": {"count": 12},
                 "host_validation_attempts": [attempt]}
        original_manifest = runner._file_manifest(self.run_dir, omit=child_dir)
        child["original_run_manifest"] = original_manifest
        child_dir.mkdir(exist_ok=True)
        (child_dir / "metadata.json").write_text(json.dumps(child))
        self.assertEqual(runner._failed_import_retry_state(
            self.run_dir, self.root, workstream, run_id, original_manifest,
        )[1], 2)
        report_path = attempt_dir / "validation.json"
        report_path.write_text('{"passed":true}\n')
        with self.assertRaisesRegex(runner.RunnerError, "evidence changed"):
            runner._failed_import_retry_state(
                self.run_dir, self.root, workstream, run_id, original_manifest,
            )
        (attempt_dir / "validation.json").write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": False,
            "infrastructure_failure": "import",
        }) + "\n")
        report_sha = hashlib.sha256((attempt_dir / "validation.json").read_bytes()).hexdigest()
        (attempt_dir / "coordinator-validation.json").write_text(json.dumps({
            "schema": "custodian.paired_review_host_validation.v1",
            "source_changed_during_validation": False, "report_sha256": report_sha,
            "generated_import_manifest_sha256": None,
        }) + "\n")
        attempts = []
        for number in (1, 2):
            current_dir = child_dir / "host-validation" / f"attempt-{number:02d}"
            if number == 2:
                current_dir.mkdir(parents=True)
                (current_dir / "validation.json").write_bytes((attempt_dir / "validation.json").read_bytes())
                (current_dir / "coordinator-validation.json").write_bytes(
                    (attempt_dir / "coordinator-validation.json").read_bytes())
            current_manifest = runner._file_manifest(current_dir)
            attempts.append({"attempt": number, "status": "failed", "manifest": current_manifest,
                             "manifest_sha256": runner._manifest_digest(current_manifest),
                             "report_sha256": current_manifest["validation.json"],
                             "metadata_sha256": current_manifest["coordinator-validation.json"]})
        child["host_validation_attempts"] = attempts
        (child_dir / "metadata.json").write_text(json.dumps(child))
        with self.assertRaisesRegex(runner.RunnerError, "retry budget is exhausted"):
            runner._failed_import_retry_state(
                self.run_dir, self.root, workstream, run_id, original_manifest,
            )

    def _run_validation(self, report=None, **kwargs):
        return host_validation.run_coordinator_validation(
            self.root, self.run_dir, self.reviewed_main, self.implementation,
            run_validation=self._run(report or self._report(), **kwargs),
            capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
        )

    def _install_trace(self, workstream, packet_path, run_id, base, landing, *,
                       ref_suffix=None, main_sync=None, malformed_data=False,
                       include_claim=True, include_landing=True, worktree=None,
                       branch=None, claim_base=None, extra_events=()):
        branch = branch or f"agent/{workstream}"
        worktree = worktree or f"/tmp/{workstream}-{run_id}"
        events = []
        if include_claim:
            claim_parent = claim_base or base
            claim_oid = self._git(
                "commit-tree", f"{claim_parent}^{{tree}}", "-p", claim_parent,
                "-m", f"workstream claim {workstream} codex:1:{run_id}",
            )
            events.extend([
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "remote_claim_acquired",
                 "data": {"claim_oid": claim_oid, "main_sha": claim_parent,
                          "local_ref": f"refs/custodian/claims/{workstream}/{run_id}",
                          "remote_ref": f"refs/heads/dispatch-claims/{workstream}"}},
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "worktree_published",
                 "data": {"head": claim_base or base, "upstream": claim_base or base,
                          "branch": branch, "clean": True, "worktree": worktree}},
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "start_completed",
                 "data": {"branch": branch, "worktree": worktree}},
            ])
        if main_sync is not None:
            events.append({"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                           "workstream": workstream, "packet": packet_path,
                           "event": "main_sync", "data": main_sync})
        if include_landing:
            events.extend([
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "landing_started",
                 "data": {"start_sha": landing, "branch": branch, "target": "main"}},
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "landing_completed",
                 "data": {"head": landing, "outcome": "landed"}},
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "teardown_started",
                 "data": {"head": landing, "branch": branch, "worktree": worktree}},
                {"schema": "custodian.workflow_trace_event.v1", "run_id": run_id,
                 "workstream": workstream, "packet": packet_path, "event": "teardown_completed",
                 "data": {"head": landing, "branch": branch,
                          "worktree_removed": True, "worktree": worktree}},
            ])
        events.extend(extra_events)
        for event in events:
            event["schema_version"] = 1
        if malformed_data:
            events[0]["data"] = ["forged"]
        raw = ("\n".join(json.dumps(item, sort_keys=True) for item in events) + "\n").encode()
        blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], cwd=self.root,
                              input=raw, check=True, capture_output=True).stdout.decode().strip()
        tree = subprocess.run(["git", "mktree"], cwd=self.root, input=f"100644 blob {blob}\ttrace.jsonl\n",
                              text=True, check=True, capture_output=True).stdout.strip()
        commit = subprocess.run(["git", "commit-tree", tree, "-m", "diagnostic trace"], cwd=self.root,
                                text=True, check=True, capture_output=True).stdout.strip()
        ref = (f"refs/remotes/origin/agent-diagnostics/{workstream}/"
               f"{ref_suffix or run_id}")
        subprocess.run(["git", "update-ref", ref, commit], cwd=self.root, check=True)
        return ref

    def _build_main_sync_landing(self, *, unrelated_archive_path=None,
                                 source_bearing_archive=False,
                                 executable_archive_path=None,
                                 nonregular_archive_path=None,
                                 archive_doc_path=None,
                                 declared_work_surface_path=None,
                                 mentioned_elsewhere_path=None,
                                 mentioned_elsewhere_text=None,
                                 code_paths=None,
                                 work_surface=None,
                                 archive_uid_path=None,
                                 archive_uid_text="uid://do0pqluwda6jl\n"):
        workstream = "sample-main-sync"
        active = f"{runner.PACKET_ROOT}/SAMPLE_MAIN_SYNC.md"
        archive = f"{runner.PACKET_ROOT}/archived/SAMPLE_MAIN_SYNC.md"
        index = f"{runner.PACKET_ROOT}/README.md"
        summary = "SAMPLE_MAIN_SYNC_CLAUDE_SUMMARY.md"
        reviewed_main = self._git("rev-parse", "HEAD")
        work_surface = list(work_surface) if work_surface is not None else [
            "- `custodian/game/world/transfer.gd`",
            "- `custodian/tools/validation/transfer_smoke.gd`",
        ]
        if declared_work_surface_path:
            work_surface.append(f"- `{declared_work_surface_path}`")
        packet = (f"# Sample\n- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `implementation`\n"
                  f"- Status: `in_progress`\n- Reviewed main: `{reviewed_main}`\n"
                  f"- Work surface:\n" + "\n".join(f"  {line}" for line in work_surface) + "\n")
        if mentioned_elsewhere_path:
            packet += f"\n## Evidence\nThe related file is `{mentioned_elsewhere_path}`.\n"
        if mentioned_elsewhere_text:
            packet += f"\n## Evidence\n{mentioned_elsewhere_text}\n"
        Path(self.root / active).parent.mkdir(parents=True, exist_ok=True)
        (self.root / active).write_text(packet)
        (self.root / index).write_text("active index\n")
        self._commit("publish active packet")
        source_base = self._git("rev-parse", "HEAD")
        code_paths = list(code_paths) if code_paths is not None else [
            "custodian/game/world/transfer.gd",
            "custodian/tools/validation/transfer_smoke.gd",
        ]
        for path in code_paths:
            target = self.root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"source {reviewed_main}\n")
        subprocess.run(["git", "add", "-f", *code_paths], cwd=self.root, check=True)
        self._commit("implement source")
        source_head = self._git("rev-parse", "HEAD")
        (self.root / archive).parent.mkdir(parents=True, exist_ok=True)
        (self.root / archive).write_text(packet.replace("`in_progress`", "`complete`"))
        (self.root / active).unlink()
        (self.root / summary).write_text("completion summary\n")
        (self.root / index).write_text("archived index\n")
        if source_bearing_archive:
            for path in code_paths:
                (self.root / path).write_text("source-bearing archive update\n")
        if archive_doc_path:
            doc = self.root / archive_doc_path
            doc.parent.mkdir(parents=True, exist_ok=True)
            doc.write_text("declared documentation update\n")
        if archive_uid_path:
            sidecar = self.root / archive_uid_path
            sidecar.parent.mkdir(parents=True, exist_ok=True)
            sidecar.write_text(archive_uid_text)
        if executable_archive_path:
            (self.root / executable_archive_path).chmod(0o755)
        if nonregular_archive_path:
            target = self.root / nonregular_archive_path
            target.unlink()
            target.symlink_to("transfer.gd")
        if unrelated_archive_path:
            extra = self.root / unrelated_archive_path
            extra.parent.mkdir(parents=True, exist_ok=True)
            extra.write_text("unrelated\n")
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        self._commit("archive packet")
        archive_landing = self._git("rev-parse", "HEAD")

        # A prior-main commit diverges from the workstream branch and contributes
        # only unrelated documentation, as happens during a safe main sync.
        main_branch = f"fixture-main-{self._git('rev-parse', 'HEAD')[:8]}"
        self._git("checkout", "-q", "-b", main_branch, source_base)
        (self.root / "main-only.md").write_text(f"prior main {reviewed_main}\n")
        subprocess.run(["git", "add", "-f", "main-only.md"], cwd=self.root, check=True)
        self._commit("advance main")
        prior_main = self._git("rev-parse", "HEAD")
        self._git("checkout", "-q", "-")
        subprocess.run(["git", "merge", "--no-ff", main_branch, "-m", "main sync"],
                       cwd=self.root, check=True, capture_output=True)
        merge = self._git("rev-parse", "HEAD")
        self.reviewed_main = merge
        self._install_trace(
            workstream, active, "20261018T020000Z-012345abcdef", source_base, merge,
            main_sync={"changed": True, "head": merge, "main_sha": prior_main},
        )
        return {"workstream": workstream, "active": active, "archive": archive,
                "index": index, "summary": summary, "source_base": source_base,
                "source_head": source_head, "archive_landing": archive_landing,
                "prior_main": prior_main, "merge": merge, "code_paths": code_paths,
                "initial_reviewed_main": reviewed_main, "reviewed_main": self.reviewed_main}

    def _commit_tree(self, tree, message, parents):
        command = ["git", "commit-tree", tree, "-m", message]
        for parent in parents:
            command.extend(["-p", parent])
        return subprocess.run(command, cwd=self.root, check=True, text=True,
                              capture_output=True).stdout.strip()

    def _replace_trace_landing(self, fixture, landing, *, main_sha=None, changed=True):
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root,
                       check=True, capture_output=True)
        self._install_trace(
            fixture["workstream"], fixture["active"], "20261018T020001Z-012345abcdef",
            fixture["source_base"], landing,
            main_sync={"changed": changed, "head": landing,
                       "main_sha": main_sha or fixture["prior_main"]},
        )

    def _replace_trace_main_sync_events(self, fixture, landing, events):
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        rendered = [
            {"schema": "custodian.workflow_trace_event.v1",
             "schema_version": 1,
             "run_id": "20261018T020001Z-012345abcdef",
             "workstream": fixture["workstream"], "packet": fixture["active"],
             "event": "main_sync", "data": event}
            for event in events[1:]
        ]
        first = events[0] if events else None
        self._install_trace(
            fixture["workstream"], fixture["active"], "20261018T020001Z-012345abcdef",
            fixture["source_base"], landing,
            main_sync=first,
            extra_events=rendered,
        )

    def _managed_readme(self, prefix, entries, suffix):
        return (prefix + host_validation.MANAGED_BLOCK_START.encode() + b"\n"
                + b"\n".join(entries) + b"\n"
                + host_validation.MANAGED_BLOCK_END.encode() + suffix)

    def test_managed_index_reconciliation_accepts_only_additive_prior_main_entries(self):
        prefix, suffix = b"before\n", b"\nafter\n"
        old = "- `OLD.md` — old".encode()
        prior_addition = "- `NEW.md` — new".encode()
        first = self._managed_readme(prefix, [old], suffix)
        prior = self._managed_readme(prefix, [old, prior_addition], suffix)
        merged = self._managed_readme(prefix, [old, prior_addition], suffix)
        self.assertTrue(host_validation._managed_packet_index_additive_reconciliation(
            first, prior, merged))

    def test_managed_index_reconciliation_rejects_outside_block_changes(self):
        first = self._managed_readme(b"before\n", ["- `OLD.md` — old".encode()], b"\nafter\n")
        prior = self._managed_readme(b"before\n", ["- `OLD.md` — old".encode(), "- `NEW.md` — new".encode()], b"\nafter\n")
        for merged in (
            self._managed_readme(b"changed\n", ["- `OLD.md` — old".encode(), "- `NEW.md` — new".encode()], b"\nafter\n"),
            self._managed_readme(b"before\n", ["- `OLD.md` — old".encode(), "- `NEW.md` — new".encode()], b"\nchanged\n"),
        ):
            with self.subTest(merged=merged):
                self.assertFalse(host_validation._managed_packet_index_additive_reconciliation(
                    first, prior, merged))

    def test_managed_index_reconciliation_rejects_malformed_or_duplicate_markers(self):
        first = self._managed_readme(b"before\n", ["- `OLD.md` — old".encode()], b"\nafter\n")
        prior = self._managed_readme(b"before\n", ["- `OLD.md` — old".encode(), "- `NEW.md` — new".encode()], b"\nafter\n")
        marker = host_validation.MANAGED_BLOCK_START.encode()
        end = host_validation.MANAGED_BLOCK_END.encode()
        bad_values = (
            first.replace(end, b"missing-end"),
            first + marker,
            first.replace(marker, marker + b"\n" + marker),
            first.replace(marker + b"\n", marker + b" extra\n"),
        )
        for merged in bad_values:
            with self.subTest(merged=merged):
                self.assertFalse(host_validation._managed_packet_index_additive_reconciliation(
                    first, prior, merged))

    def test_managed_index_reconciliation_rejects_fabricated_deleted_or_replaced_entries(self):
        first_entries = ["- `OLD.md` — old".encode(), "- `KEEP.md` — keep".encode()]
        prior_entries = first_entries + ["- `NEW.md` — new".encode()]
        first = self._managed_readme(b"before\n", first_entries, b"\nafter\n")
        prior = self._managed_readme(b"before\n", prior_entries, b"\nafter\n")
        invalid = (
            [first_entries[0], "- `FABRICATED.md` — fabricated".encode(), first_entries[1]],
            [first_entries[0], "- `NEW.md` — new".encode()],
            ["- `OLD.md` — replaced".encode(), first_entries[1]],
        )
        for entries in invalid:
            with self.subTest(entries=entries):
                merged = self._managed_readme(b"before\n", entries, b"\nafter\n")
                self.assertFalse(host_validation._managed_packet_index_additive_reconciliation(
                    first, prior, merged))

    def test_historical_braced_work_surface_noop_merge_resolves_readme_reconciliation(self):
        workstream = "agent-paired-review-braced-work-surface-v1"
        refs = subprocess.run(
            ["git", "for-each-ref", "--format=%(refname)",
             f"refs/remotes/origin/agent-diagnostics/{workstream}/"],
            cwd=ROOT, check=True, text=True, capture_output=True,
        ).stdout.splitlines()
        if not refs:
            self.skipTest("pinned braced-work-surface lifecycle trace is unavailable")
        archive = (f"{runner.PACKET_ROOT}/archived/"
                   "AGENT_PAIRED_REVIEW_BRACED_WORK_SURFACE_V1.md")
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, "3b3d3893236f1ef61a00d03f0fb6dddaa3a48274",
                "c5e5b7032a1c0853cffac39931e703d81942bc03", workstream, archive,
            )
        self.assertEqual(span["provenance"]["trace_landing_commit"],
                         "3b3d3893236f1ef61a00d03f0fb6dddaa3a48274")
        self.assertEqual(span["provenance"]["trace_main_sync_sha"],
                         "f6a9e745f6db34d0d8c79f2edc56eb5f8049e633")

    def _install_alternate_merge(self, fixture, *, parents=None, changed_path=None,
                                 main_sha=None):
        self._git("checkout", "-q", "--detach", fixture["archive_landing"])
        if changed_path:
            path = self.root / changed_path
            if changed_path == fixture["archive"]:
                path.write_text(path.read_text() + "\nmerge alteration\n")
            else:
                path.write_text("altered in main-sync merge\n")
            subprocess.run(["git", "add", changed_path], cwd=self.root, check=True)
        tree = self._git("write-tree")
        parents = parents or [fixture["archive_landing"], fixture["prior_main"]]
        commit = self._commit_tree(tree, "alternate main-sync merge", parents)
        reviewed_tree = self._git("rev-parse", f"{commit}^{{tree}}")
        fixture["reviewed_main"] = self._commit_tree(
            reviewed_tree, "pin alternate merge", [commit])
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        self._replace_trace_landing(fixture, commit, main_sha=main_sha)
        return commit

    def test_host_runs_canonical_changed_gate_from_pinned_parent_and_verifies_evidence(self):
        evidence = self._run_validation()

        self.assertEqual(evidence["implementation_parent"], self.base)
        self.assertEqual(evidence["implementation_commit"], self.implementation)
        self.assertEqual(evidence["reviewed_main"], self.reviewed_main)
        self.assertEqual(set(evidence["implementation_paths"]), set(self.changed_paths))
        self.assertEqual(evidence["report_sha256"], hashlib.sha256(
            (self.run_dir / "validation.json").read_bytes()).hexdigest())
        verified = host_validation.verify_coordinator_validation(
            self.root, self.run_dir, self.reviewed_main, self.implementation,
            expected_report_sha256=evidence["report_sha256"],
            expected_metadata_sha256=evidence["metadata_sha256"],
        )
        self.assertTrue(verified["passed"])

    def test_host_rejects_vacuous_or_failed_validation_reports(self):
        for report in (self._report(selected=False), self._report(passed=False)):
            with self.subTest(report=report):
                with self.assertRaises(host_validation.HostValidationError):
                    self._run_validation(report)

    def test_host_rejects_report_that_does_not_cover_implementation_diff(self):
        report = self._report(changed_paths=["README.md"])
        with self.assertRaisesRegex(host_validation.HostValidationError, "implementation diff"):
            self._run_validation(report)

    def test_host_rejects_code_path_without_a_selected_test_owner(self):
        report = self._report()
        report["coverage"]["covered_by"][self.changed_paths[0]] = []
        with self.assertRaisesRegex(host_validation.HostValidationError, "selected test owner"):
            host_validation._validate_report(report, self.changed_paths)

    def test_host_rejects_source_drift_during_validation(self):
        with self.assertRaisesRegex(host_validation.HostValidationError, "source changed"):
            self._run_validation(source_edit=True)

    def test_host_socket_preflight_failure_stops_before_validation(self):
        def socket_denied():
            raise host_validation.HostValidationError("sandbox socket bind denied")

        with self.assertRaisesRegex(host_validation.HostValidationError, "socket bind denied"):
            host_validation.run_coordinator_validation(
                self.root, self.run_dir, self.reviewed_main, self.implementation,
                run_validation=lambda *_: self.fail("validation must not launch after failed preflight"),
                capability_probe=socket_denied,
            )
        self.assertFalse((self.run_dir / "validation.json").exists())

    def test_host_rejects_report_modified_after_reviewer_execution(self):
        evidence = self._run_validation()
        (self.run_dir / "validation.json").write_text(json.dumps(self._report(passed=False)))
        with self.assertRaisesRegex(host_validation.HostValidationError, "digest"):
            host_validation.verify_coordinator_validation(
                self.root, self.run_dir, self.reviewed_main, self.implementation,
                expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )

    def test_archive_only_landing_uses_trace_pinned_source_commit_and_keeps_landing_identity(self):
        workstream = "sample-impl"
        active = f"{runner.PACKET_ROOT}/SAMPLE_IMPL.md"
        archive = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
        index = f"{runner.PACKET_ROOT}/README.md"
        initial_main = self.base
        packet = (f"# Sample\n- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `implementation`\n"
                  f"- Status: `in_progress`\n- Reviewed main: `{initial_main}`\n"
                  f"\n## Work surface\n- `custodian/tools/agent/worktree_backlog_census.py`\n"
                  f"- `custodian/tools/agent/test_worktree_backlog_census.py`\n")
        (self.root / active).parent.mkdir(parents=True, exist_ok=True)
        (self.root / active).write_text(packet)
        (self.root / index).write_text("active index\n")
        self._commit("publish active implementation packet")
        source_base = self._git("rev-parse", "HEAD")
        code_paths = ["custodian/tools/agent/worktree_backlog_census.py",
                      "custodian/tools/agent/test_worktree_backlog_census.py"]
        for path in code_paths:
            target = self.root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("source\n")
        self._commit("implement sample workstream")
        source_head = self._git("rev-parse", "HEAD")
        archived_packet = packet.replace("`in_progress`", "`complete`")
        (self.root / archive).parent.mkdir(parents=True, exist_ok=True)
        (self.root / archive).write_text(archived_packet)
        (self.root / active).unlink()
        (self.root / f"{workstream.upper().replace('-', '_')}_CLAUDE_SUMMARY.md").write_text(
            "completion summary\n")
        (self.root / index).write_text("archived index\n")
        self._commit("archive sample workstream")
        landing = self._git("rev-parse", "HEAD")
        self._install_trace(workstream, active, "20261018T010000Z-012345abcdef",
                            source_base, landing, worktree="/tmp/sample-workstream")

        span = host_validation.resolve_validation_source_span(
            self.root, landing, landing, workstream, archive,
        )
        self.assertEqual(span["base"], source_base)
        self.assertEqual(span["head"], source_head)
        self.assertEqual(span["commits"], [source_head])
        self.assertEqual(set(span["paths"]), set(code_paths))
        self.assertEqual(span["provenance"]["kind"], "workstream-lifecycle-trace")

        selected_paths = subprocess.run(["git", "diff", "--name-only", f"{source_base}...{landing}"],
                                        cwd=self.root, check=True, text=True,
                                        capture_output=True).stdout.splitlines()
        report = {"schema": "custodian.validation.result.v1", "passed": True,
                  "changed_files": selected_paths, "selected": ["census_contract"],
                  "tests": [{"id": "census_contract", "status": "passed"}],
                  "summary": {"selected": 1, "passed": 1, "failed": 0, "timed_out": 0,
                              "skipped": 0, "infrastructure_errors": 0},
                  "coverage": {"complete": True, "covered_files": code_paths,
                               "uncovered_files": [],
                               "excluded_files": sorted(set(selected_paths) - set(code_paths)),
                               "covered_by": {path: ["census_contract"] for path in code_paths}}}

        def validate(command, cwd):
            self.assertEqual(Path(cwd), self.root)
            self.assertEqual(command[-4:], ["--changed", "--base", source_base, "--json"])
            return subprocess.CompletedProcess(command, 0, json.dumps(report) + "\n", "")

        run_dir = self.run_dir / "split-landing"
        run_dir.mkdir()
        evidence = host_validation.run_coordinator_validation(
            self.root, run_dir, landing, landing, target_workstream=workstream,
            target_packet_path=archive, run_validation=validate,
            capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
        )
        self.assertEqual(evidence["implementation_commit"], landing)
        self.assertEqual(evidence["source_span"]["head"], source_head)
        self.assertEqual(evidence["source_span"]["base"], source_base)
        verified = host_validation.verify_coordinator_validation(
            self.root, run_dir, landing, landing, target_workstream=workstream,
            target_packet_path=archive, expected_report_sha256=evidence["report_sha256"],
            expected_metadata_sha256=evidence["metadata_sha256"],
        )
        self.assertTrue(verified["passed"])
        (self.root / code_paths[0]).write_text("mutated after validation\n")
        with self.assertRaisesRegex(host_validation.HostValidationError, "source changed"):
            host_validation.verify_coordinator_validation(
                self.root, run_dir, landing, landing, target_workstream=workstream,
                target_packet_path=archive, expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )

    def test_archived_w1_correction_resolves_exact_source_commit_and_scope(self):
        reviewed_main = "b5b85ca47a1eacad9879c6abf55257d378ae0c91"
        workstream = "worktree-backlog-census-and-safety-ledger-v1-review-corrections-1"
        target = (f"{runner.PACKET_ROOT}/archived/"
                  "WORKTREE_BACKLOG_CENSUS_AND_SAFETY_LEDGER_V1_REVIEW_CORRECTIONS_1.md")
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, reviewed_main, reviewed_main, workstream, target,
            )
        self.assertEqual(span["base"], "6c818d16ed7c3dd19f156b80348fa4bc6929c748")
        self.assertEqual(span["head"], "1b586174fa7fbd9c1c94e6adbc36ee85bf809f4f")
        self.assertEqual(span["commits"], ["1b586174fa7fbd9c1c94e6adbc36ee85bf809f4f"])
        self.assertEqual(span["provenance"]["kind"], "workstream-lifecycle-trace")
        self.assertEqual(span["provenance"]["run_id"], "20261017T195329Z-de38cd920078")
        self.assertIn("custodian/tools/agent/worktree_backlog_census.py", span["paths"])
        self.assertIn("custodian/tools/agent/test_worktree_backlog_census.py", span["paths"])

    def test_historical_host_recovery_correction_resolves_pinned_main_sync_merge(self):
        reviewed_main = "f12717e61213d7d30ae6b3e670d45e71507cd784"
        archive_landing = "1fa679c33f49bf3ee7d08072c82f747809b00b35"
        workstream = "agent-paired-review-host-validation-recovery-v1-review-corrections-1"
        target = (f"{runner.PACKET_ROOT}/archived/"
                  "AGENT_PAIRED_REVIEW_HOST_VALIDATION_RECOVERY_V1_REVIEW_CORRECTIONS_1.md")
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, reviewed_main, archive_landing, workstream, target,
            )
        self.assertEqual(span["base"], "06cbe9521dfa8efe82fb5820709646ca6d1486e7")
        self.assertEqual(span["head"], "48a0bfc4836fbc88cd4406cc814959dcfc6e453b")
        self.assertEqual(span["commits"], [span["head"]])
        self.assertEqual(host_validation._source_code_paths(span["paths"]), {
            "custodian/tools/agent/paired_review_runner.py",
            "custodian/tools/agent/test_paired_review_runner.py",
        })
        provenance = span["provenance"]
        self.assertEqual(provenance["kind"], "workstream-lifecycle-trace")
        self.assertEqual(provenance["trace_landing_kind"], "main-sync-merge")
        self.assertEqual(provenance["trace_landing_commit"], reviewed_main)
        self.assertEqual(provenance["trace_main_sync_sha"],
                         "623dd45ddf35f9c88460386ac047db3e9c1f8d52")

    def test_split_landing_accepts_only_verified_main_sync_merge(self):
        fixture = self._build_main_sync_landing()
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["base"], fixture["source_base"])
        self.assertEqual(span["head"], fixture["source_head"])
        self.assertEqual(span["provenance"]["trace_landing_commit"], fixture["merge"])
        self.assertEqual(span["provenance"]["trace_main_sync_sha"], fixture["prior_main"])
        self.assertEqual(span["provenance"]["trace_landing_kind"], "main-sync-merge")

    def test_split_landing_accepts_declared_archive_sync_followup(self):
        fixture = self._build_main_sync_landing()
        work_branch = self._git("branch", "--show-current")
        followup_path = fixture["code_paths"][1]
        followup_file = self.root / followup_path
        followup_file.write_text(followup_file.read_text() + "post-merge regression\n")
        self._git("add", followup_path)
        self._git("commit", "-qm", "bounded post-merge follow-up")
        followup = self._git("rev-parse", "HEAD")
        self._git("checkout", "-qb", "later-main", fixture["prior_main"])
        (self.root / "later-main-only.md").write_text("later main publication\n")
        self._git("add", "later-main-only.md")
        self._git("commit", "-qm", "advance main again")
        later_main = self._git("rev-parse", "HEAD")
        self._git("checkout", "-q", work_branch)
        subprocess.run(["git", "merge", "--no-ff", "later-main", "-m", "second main sync"],
                       cwd=self.root, check=True, capture_output=True)
        second_sync = self._git("rev-parse", "HEAD")
        post_sync_path = fixture["code_paths"][0]
        post_sync_file = self.root / post_sync_path
        post_sync_file.write_text(post_sync_file.read_text() + "post-second-sync regression\n")
        self._git("add", post_sync_path)
        self._git("commit", "-qm", "second bounded post-merge follow-up")
        final_sync = self._git("rev-parse", "HEAD")
        self.reviewed_main = final_sync
        fixture["reviewed_main"] = final_sync

        run_id = "20261018T020000Z-012345abcdef"
        valid_ref = f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/{run_id}"
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        events = []
        def emit(name, data):
            events.append({"schema": "custodian.workflow_trace_event.v1", "schema_version": 1,
                           "run_id": run_id, "workstream": fixture["workstream"],
                           "packet": fixture["active"], "event": name, "data": data})
        claim_oid = self._git("commit-tree", f"{fixture['source_base']}^{{tree}}", "-p",
                              fixture["source_base"], "-m",
                              f"workstream claim {fixture['workstream']} codex:1:{run_id}")
        worktree = f"/tmp/{fixture['workstream']}-{run_id}"
        emit("remote_claim_acquired", {"claim_oid": claim_oid, "main_sha": fixture["source_base"],
             "local_ref": f"refs/custodian/claims/{fixture['workstream']}/{run_id}",
             "remote_ref": f"refs/heads/dispatch-claims/{fixture['workstream']}"})
        emit("worktree_published", {"head": fixture["source_base"], "upstream": fixture["source_base"],
             "branch": f"agent/{fixture['workstream']}", "clean": True, "worktree": worktree})
        emit("main_sync", {"changed": True, "head": fixture["merge"],
             "main_sha": fixture["prior_main"]})
        emit("main_sync", {"changed": False, "head": followup,
             "main_sha": fixture["prior_main"]})
        emit("main_sync", {"changed": True, "head": second_sync,
             "main_sha": later_main})
        emit("main_sync", {"changed": False, "head": final_sync,
             "main_sha": later_main})
        emit("landing_started", {"start_sha": final_sync, "branch": f"agent/{fixture['workstream']}",
             "target": "main"})
        emit("landing_completed", {"head": final_sync, "outcome": "landed"})
        emit("teardown_started", {"head": final_sync, "branch": f"agent/{fixture['workstream']}",
             "worktree": worktree})
        emit("teardown_completed", {"head": final_sync, "branch": f"agent/{fixture['workstream']}",
             "worktree": worktree, "worktree_removed": True})
        raw = ("\n".join(json.dumps(event, sort_keys=True) for event in events) + "\n").encode()
        blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], cwd=self.root,
                              input=raw, check=True, capture_output=True).stdout.decode().strip()
        tree = subprocess.run(["git", "mktree"], cwd=self.root,
                              input=f"100644 blob {blob}\ttrace.jsonl\n", text=True,
                              check=True, capture_output=True).stdout.strip()
        trace_commit = self._git("commit-tree", tree, "-m", "post-merge follow-up trace")
        self._git("update-ref", valid_ref, trace_commit)

        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["head"], final_sync)
        self.assertEqual(span["provenance"]["trace_landing_kind"], "main-sync-merge-followup")
        self.assertEqual(span["provenance"]["post_merge_followup"]["sync_merge_commit"], fixture["merge"])
        self.assertEqual(span["provenance"]["post_merge_followup"]["followup_paths"],
                         sorted([followup_path, post_sync_path]))
        self.assertEqual(len(span["provenance"]["post_merge_followup"]["post_merge_followup_commits"]), 2)

        invalid = events[:4] + events[5:]
        invalid_raw = ("\n".join(json.dumps(event, sort_keys=True) for event in invalid) + "\n").encode()
        invalid_blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], cwd=self.root,
                                      input=invalid_raw, check=True,
                                      capture_output=True).stdout.decode().strip()
        invalid_tree = subprocess.run(["git", "mktree"], cwd=self.root,
                                      input=f"100644 blob {invalid_blob}\ttrace.jsonl\n", text=True,
                                      check=True, capture_output=True).stdout.strip()
        invalid_commit = self._git("commit-tree", invalid_tree, "-m", "trace missing retry proof")
        self._git("update-ref", valid_ref, invalid_commit)
        span_without_intermediate_retry = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span_without_intermediate_retry["head"], final_sync)

    def test_split_landing_binds_latest_sync_merge_to_exact_final_noop_witness(self):
        fixture = self._build_main_sync_landing()
        followup_path = fixture["code_paths"][1]
        followup_file = self.root / followup_path
        followup_file.write_text(followup_file.read_text() + "post-merge regression\n")
        self._git("add", followup_path)
        self._git("commit", "-qm", "bounded post-merge follow-up")
        final_head = self._git("rev-parse", "HEAD")
        fixture["reviewed_main"] = final_head
        self.reviewed_main = final_head

        # The final no-op sync is emitted after a merge conflict was resolved in
        # the descendant commit. It authenticates the latest merge's second
        # parent and the exact descendant tip; no merge-head event exists.
        self._replace_trace_main_sync_events(fixture, final_head, [{
            "changed": False, "head": final_head, "main_sha": fixture["prior_main"],
        }])
        span = host_validation.resolve_validation_source_span(
            self.root, final_head, fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["head"], final_head)
        self.assertEqual(span["provenance"]["trace_landing_commit"], final_head)
        self.assertEqual(span["provenance"]["trace_main_sync_sha"], fixture["prior_main"])
        self.assertEqual(span["provenance"]["post_merge_followup"]["sync_merge_commit"],
                         fixture["merge"])

        for bad_main_sha, sync_events in (
            ("0" * 40, [{"changed": False, "head": final_head, "main_sha": "0" * 40}]),
            (fixture["prior_main"], [
                {"changed": False, "head": final_head, "main_sha": fixture["prior_main"]},
                {"changed": False, "head": final_head, "main_sha": fixture["prior_main"]},
            ]),
        ):
            with self.subTest(main_sha=bad_main_sha, count=len(sync_events)):
                self._replace_trace_main_sync_events(fixture, final_head, sync_events)
                with self.assertRaises(host_validation.HostValidationError):
                    host_validation.resolve_validation_source_span(
                        self.root, final_head, fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_split_landing_accepts_direct_declared_tail_only_with_exact_tip_witness(self):
        fixture = self._build_main_sync_landing()
        self._git("checkout", "-qb", "direct-tail", fixture["archive_landing"])
        followup_path = fixture["code_paths"][0]
        followup_file = self.root / followup_path
        followup_file.write_text(followup_file.read_text() + "direct archive tail\n")
        self._git("add", followup_path)
        self._git("commit", "-qm", "direct bounded archive follow-up")
        final_head = self._git("rev-parse", "HEAD")
        fixture["reviewed_main"] = final_head
        self.reviewed_main = final_head
        self._replace_trace_main_sync_events(fixture, final_head, [{
            "changed": False, "head": final_head, "main_sha": final_head,
        }])

        span = host_validation.resolve_validation_source_span(
            self.root, final_head, fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["head"], final_head)
        self.assertEqual(span["provenance"]["trace_landing_kind"], "archive-source-followup")
        self.assertEqual(span["provenance"]["trace_main_sync_sha"], final_head)
        self.assertEqual(span["provenance"]["post_merge_followup"]["sync_merges"], [])

        for bad_event in (
            {"changed": True, "head": final_head, "main_sha": final_head},
            {"changed": False, "head": fixture["archive_landing"], "main_sha": final_head},
            {"changed": False, "head": final_head, "main_sha": fixture["prior_main"]},
        ):
            with self.subTest(event=bad_event):
                self._replace_trace_main_sync_events(fixture, final_head, [bad_event])
                with self.assertRaises(host_validation.HostValidationError):
                    host_validation.resolve_validation_source_span(
                        self.root, final_head, fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_split_landing_rejects_direct_tail_outside_surface_and_nonregular_path(self):
        fixture = self._build_main_sync_landing()
        self._git("checkout", "-qb", "direct-tail-out-of-scope", fixture["archive_landing"])
        rogue_path = "custodian/tools/agent/rogue_helper.py"
        rogue = self.root / rogue_path
        rogue.parent.mkdir(parents=True, exist_ok=True)
        rogue.write_text("unreviewed helper\n")
        self._git("add", rogue_path)
        self._git("commit", "-qm", "out of surface tail")
        out_of_scope_head = self._git("rev-parse", "HEAD")
        fixture["reviewed_main"] = out_of_scope_head
        self.reviewed_main = out_of_scope_head
        self._replace_trace_main_sync_events(fixture, out_of_scope_head, [{
            "changed": False, "head": out_of_scope_head, "main_sha": out_of_scope_head,
        }])
        with self.assertRaises(host_validation.HostValidationError):
            host_validation.resolve_validation_source_span(
                self.root, out_of_scope_head, fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

        self._git("checkout", "-qb", "direct-tail-nonregular", fixture["archive_landing"])
        source = self.root / fixture["code_paths"][0]
        source.unlink()
        source.symlink_to("transfer.gd")
        self._git("add", fixture["code_paths"][0])
        self._git("commit", "-qm", "nonregular source tail")
        nonregular_head = self._git("rev-parse", "HEAD")
        fixture["reviewed_main"] = nonregular_head
        self.reviewed_main = nonregular_head
        self._replace_trace_main_sync_events(fixture, nonregular_head, [{
            "changed": False, "head": nonregular_head, "main_sha": nonregular_head,
        }])
        with self.assertRaisesRegex(host_validation.HostValidationError, "non-modification|non-regular"):
            host_validation.resolve_validation_source_span(
                self.root, nonregular_head, fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def _install_split_trace_pair(self, fixture, *, claim_path=None, teardown_path=None,
                                  claim_base=None, claim_branch=None,
                                  claim_run="20261018T020010Z-012345abcdef",
                                  landing_run="20261018T020011Z-012345abcdef"):
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        worktree = claim_path or f"/tmp/{fixture['workstream']}-claimed"
        self._install_trace(
            fixture["workstream"], fixture["active"], claim_run,
            claim_base or fixture["source_base"], fixture["merge"],
            include_landing=False, worktree=worktree, branch=claim_branch,
        )
        self._install_trace(
            fixture["workstream"], fixture["active"], landing_run,
            fixture["source_base"], fixture["merge"], include_claim=False,
            worktree=teardown_path or worktree,
            main_sync={"changed": True, "head": fixture["merge"],
                       "main_sha": fixture["prior_main"]},
        )
        return worktree

    def _earlier_claim_event(self, fixture, landing_run, earlier_base, *,
                             claim_run=None, local_ref=None, subject_run=None):
        claim_run = claim_run or landing_run
        subject_run = subject_run or claim_run
        claim_oid = self._git(
            "commit-tree", f"{earlier_base}^{{tree}}", "-p", earlier_base,
            "-m", f"workstream claim {fixture['workstream']} codex:1:{subject_run}",
        )
        return {
            "schema": "custodian.workflow_trace_event.v1",
            "run_id": claim_run,
            "workstream": fixture["workstream"],
            "packet": fixture["active"],
            "event": "remote_claim_acquired",
            "data": {
                "claim_oid": claim_oid,
                "main_sha": earlier_base,
                "local_ref": local_ref or f"refs/custodian/claims/{fixture['workstream']}/{claim_run}",
                "remote_ref": f"refs/heads/dispatch-claims/{fixture['workstream']}",
            },
        }

    def _split_pair_with_earlier_claim(self, fixture=None, *, earlier_base=None, claim_run=None,
                                       local_ref=None, subject_run=None, duplicates=0):
        fixture = fixture or self._build_main_sync_landing(source_bearing_archive=True)
        landing_run = "20261018T020011Z-012345abcdef"
        self._install_split_trace_pair(fixture, landing_run=landing_run)
        earlier_base = earlier_base or fixture["initial_reviewed_main"]
        events = [self._earlier_claim_event(
            fixture, landing_run, earlier_base, claim_run=claim_run,
            local_ref=local_ref, subject_run=subject_run,
        )]
        for index in range(duplicates):
            events.append(self._earlier_claim_event(
                fixture, landing_run, earlier_base, subject_run=f"{landing_run}-{index}",
            ))
        self._install_trace(
            fixture["workstream"], fixture["active"], landing_run,
            fixture["source_base"], fixture["merge"], include_claim=False,
            worktree=f"/tmp/{fixture['workstream']}-claimed", main_sync={
                "changed": True, "head": fixture["merge"], "main_sha": fixture["prior_main"],
            }, extra_events=events,
        )
        return fixture, landing_run

    def test_split_landing_accepts_identity_verified_earlier_ancestor_claim(self):
        fixture, landing_run = self._split_pair_with_earlier_claim()
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["base"], fixture["source_base"])
        self.assertNotEqual(span["base"], fixture["reviewed_main"])
        self.assertEqual(span["provenance"]["landing_trace"]["run_id"], landing_run)

    def test_split_landing_rejects_mismatched_earlier_claim_identity(self):
        fixture, _ = self._split_pair_with_earlier_claim(
            local_ref="refs/custodian/claims/another-workstream/20261018T020011Z-012345abcdef",
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_earlier_claim_with_mismatched_run_identity(self):
        fixture, _ = self._split_pair_with_earlier_claim(subject_run="another-run")
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_earlier_claim_event_from_another_run(self):
        fixture, _ = self._split_pair_with_earlier_claim(claim_run="another-run")
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_ambiguous_earlier_claim_events(self):
        fixture, _ = self._split_pair_with_earlier_claim(duplicates=1)
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_unrelated_earlier_claim_base(self):
        fixture = self._build_main_sync_landing(source_bearing_archive=True)
        unrelated = self._git(
            "commit-tree", f"{fixture['source_base']}^{{tree}}", "-m", "unrelated base",
        )
        fixture, _ = self._split_pair_with_earlier_claim(fixture, earlier_base=unrelated)
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_reversed_earlier_claim_ancestry(self):
        fixture = self._build_main_sync_landing(source_bearing_archive=True)
        later_base = self._git(
            "commit-tree", f"{fixture['source_base']}^{{tree}}", "-p",
            fixture["source_base"], "-m", "later base",
        )
        fixture, _ = self._split_pair_with_earlier_claim(fixture, earlier_base=later_base)
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_trace_continuation_requires_exact_worktree_link_and_unique_pair(self):
        fixture = self._build_main_sync_landing()
        self._install_split_trace_pair(fixture, teardown_path="/tmp/other-worktree")
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

        fixture = self._build_main_sync_landing()
        worktree = self._install_split_trace_pair(fixture)
        self._install_trace(
            fixture["workstream"], fixture["active"], "20261018T020012Z-012345abcdef",
            fixture["source_base"], fixture["merge"], include_landing=False,
            worktree=worktree,
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "ambiguous"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_source_bearing_archive_with_split_traces_proves_and_rechecks_coverage(self):
        fixture = self._build_main_sync_landing(source_bearing_archive=True)
        worktree = self._install_split_trace_pair(fixture)
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["base"], fixture["source_base"])
        self.assertEqual(span["head"], fixture["archive_landing"])
        self.assertEqual(span["provenance"]["claim_trace"]["run_id"],
                         "20261018T020010Z-012345abcdef")
        self.assertEqual(span["provenance"]["landing_trace"]["run_id"],
                         "20261018T020011Z-012345abcdef")
        self.assertEqual(span["provenance"]["claim_trace"]["worktree"], worktree)
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])),
                         set(fixture["code_paths"]))

        selected_paths = subprocess.run(
            ["git", "diff", "--name-only", f"{fixture['source_base']}..{fixture['reviewed_main']}"],
            cwd=self.root, check=True, text=True, capture_output=True,
        ).stdout.splitlines()
        report = {"schema": "custodian.validation.result.v1", "passed": True,
                  "changed_files": selected_paths, "selected": ["transfer_contract"],
                  "tests": [{"id": "transfer_contract", "status": "passed"}],
                  "summary": {"selected": 1, "passed": 1, "failed": 0, "timed_out": 0,
                              "skipped": 0, "infrastructure_errors": 0},
                  "coverage": {"complete": True, "covered_files": fixture["code_paths"],
                               "uncovered_files": [],
                               "excluded_files": sorted(set(selected_paths) - set(fixture["code_paths"])),
                               "covered_by": {path: ["transfer_contract"]
                                              for path in fixture["code_paths"]}}}

        def validate(command, cwd):
            self.assertEqual(Path(cwd), self.root)
            self.assertEqual(command[-4:], ["--changed", "--base", fixture["source_base"], "--json"])
            return subprocess.CompletedProcess(command, 0, json.dumps(report) + "\n", "")

        run_dir = self.run_dir / "source-bearing-split-traces"
        run_dir.mkdir()
        evidence = host_validation.run_coordinator_validation(
            self.root, run_dir, fixture["reviewed_main"], fixture["archive_landing"],
            target_workstream=fixture["workstream"], target_packet_path=fixture["archive"],
            run_validation=validate,
            capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
        )
        verified = host_validation.verify_coordinator_validation(
            self.root, run_dir, fixture["reviewed_main"], fixture["archive_landing"],
            target_workstream=fixture["workstream"], target_packet_path=fixture["archive"],
            expected_report_sha256=evidence["report_sha256"],
            expected_metadata_sha256=evidence["metadata_sha256"],
        )
        self.assertTrue(verified["passed"])

        (self.root / fixture["code_paths"][0]).write_text("mutated after validation\n")
        with self.assertRaisesRegex(host_validation.HostValidationError, "source changed"):
            host_validation.verify_coordinator_validation(
                self.root, run_dir, fixture["reviewed_main"], fixture["archive_landing"],
                target_workstream=fixture["workstream"], target_packet_path=fixture["archive"],
                expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )

    def test_source_bearing_archive_accepts_markdown_path_declared_in_work_surface(self):
        doc_path = "custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md"
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            archive_doc_path=doc_path,
            declared_work_surface_path=doc_path,
        )
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["provenance"]["archive_kind"], "source-bearing")
        self.assertIn(doc_path, span["paths"])

    def test_braced_work_surface_expansion_is_bounded_and_exact(self):
        declaration = "`custodian/tools/operator/motion_foundry/{__init__,schema,rig,motion,render,qa,cli}.py`"
        self.assertEqual(host_validation._expand_braced_work_surface_paths(declaration), {
            f"custodian/tools/operator/motion_foundry/{name}.py"
            for name in ("__init__", "schema", "rig", "motion", "render", "qa", "cli")
        })
        self.assertEqual(host_validation._expand_braced_work_surface_paths(
            "`custodian/tools/operator/literal.py`"), set())
        self.assertEqual(host_validation._expand_braced_work_surface_paths(
            "custodian/tools/operator/{outside,header}.py"), set())

        too_many = ",".join(f"file_{index}" for index in range(33))
        malformed = (
            "`custodian/tools/operator/{one}.py`",
            "`custodian/tools/operator/{one,one}.py`",
            "`custodian/tools/operator/{one,{two,three}}.py`",
            "`custodian/tools/operator/../{one,two}.py`",
            "`custodian//operator/{one,two}.py`",
            "`/custodian/tools/operator/{one,two}.py`",
            "`custodian/tools/operator/{one,two/three}.py`",
            "`custodian/tools/operator/{one,two}.p*.py`",
            "`custodian/tools/operator/{one,two}.md`",
            f"`custodian/tools/operator/{{{too_many}}}.py`",
            "`custodian/tools/operator/{one,two}.py/extra.py`",
        )
        for value in malformed:
            with self.subTest(value=value), self.assertRaises(host_validation.HostValidationError):
                host_validation._expand_braced_work_surface_paths(value)

    def test_source_bearing_archive_accepts_exact_seven_module_brace_list(self):
        names = ("__init__", "schema", "rig", "motion", "render", "qa", "cli")
        modules = [f"custodian/tools/operator/motion_foundry/{name}.py" for name in names]
        smoke = "custodian/tools/validation/transfer_smoke.gd"
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            code_paths=[*modules, smoke],
            work_surface=[
                "- `custodian/tools/operator/motion_foundry/{__init__,schema,rig,motion,render,qa,cli}.py`",
                f"- `{smoke}`",
            ],
        )
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])), set([*modules, smoke]))

    def test_source_bearing_archive_rejects_module_omitted_from_brace_list(self):
        modules = [f"custodian/tools/operator/motion_foundry/{name}.py"
                   for name in ("schema", "rig", "render", "cli")]
        smoke = "custodian/tools/validation/transfer_smoke.gd"
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            code_paths=[*modules, smoke],
            work_surface=[
                "- `custodian/tools/operator/motion_foundry/{schema,rig,render}.py`",
                f"- `{smoke}`",
            ],
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "not documented"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_source_bearing_archive_rejects_plausible_extra_paths_and_basename_matches(self):
        declared = [f"custodian/tools/operator/motion_foundry/{name}.py"
                    for name in ("schema", "rig", "render", "cli")]
        smoke = "custodian/tools/validation/transfer_smoke.gd"
        extras = ["custodian/tools/operator/motion_foundry/rig_extra.py",
                  "custodian/elsewhere/schema.py"]
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            code_paths=[*declared, smoke, *extras],
            work_surface=[
                "- `custodian/tools/operator/motion_foundry/{schema,rig,render,cli}.py`",
                f"- `{smoke}`",
            ],
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "not documented"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_brace_expression_outside_work_surface_does_not_authorize_source(self):
        modules = ["custodian/tools/operator/motion_foundry/schema.py",
                   "custodian/tools/operator/motion_foundry/rig.py"]
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            code_paths=[*modules, *self.changed_paths],
            work_surface=[f"- `{self.changed_paths[0]}`", f"- `{self.changed_paths[1]}`"],
            mentioned_elsewhere_text=("Other context: "
                "`custodian/tools/operator/motion_foundry/{schema,rig}.py`"),
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "not documented"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_historical_mf1_landing_resolves_when_local_trace_is_available(self):
        workstream = "operator-motion-foundry-core-v1"
        refs = subprocess.run(
            ["git", "for-each-ref", "--format=%(refname)",
             f"refs/remotes/origin/agent-diagnostics/{workstream}/"],
            cwd=ROOT, check=True, text=True, capture_output=True,
        ).stdout.splitlines()
        if not refs:
            self.skipTest("pinned MF1 lifecycle trace refs are unavailable in this checkout")
        archive = (f"{runner.PACKET_ROOT}/archived/"
                   "OPERATOR_MOTION_FOUNDRY_CORE_V1.md")
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, "a563a872dbe11a582c776bc329c334cdda73c543",
                "645f1a701696045149fbf9dd3c988cbbadfcf06b", workstream, archive,
            )
        self.assertEqual(span["base"], "55918d257cb3c663fb066f56eb79b23d174b7ae2")
        self.assertEqual(span["head"], "645f1a701696045149fbf9dd3c988cbbadfcf06b")
        self.assertEqual(span["provenance"]["run_id"], "20261019T111751Z-bc1d9d1546fb")
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])), {
            "custodian/tools/operator/motion_foundry/__init__.py",
            "custodian/tools/operator/motion_foundry/schema.py",
            "custodian/tools/operator/motion_foundry/rig.py",
            "custodian/tools/operator/motion_foundry/motion.py",
            "custodian/tools/operator/motion_foundry/render.py",
            "custodian/tools/operator/motion_foundry/qa.py",
            "custodian/tools/operator/motion_foundry/cli.py",
            "custodian/tools/validation/operator_motion_foundry_core_smoke.py",
            "custodian/tools/validation/validation_manifest.json",
        })

    def test_source_bearing_archive_rejects_markdown_path_mentioned_outside_work_surface(self):
        doc_path = "custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md"
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True,
            archive_doc_path=doc_path,
            mentioned_elsewhere_path=doc_path,
        )
        with self.assertRaisesRegex(host_validation.HostValidationError,
                                    "archive-only landing contains unrelated paths"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def _build_grunt_attestation_approval_history(self):
        """Build a real Git history with canonical correction PASS receipts."""
        repository = Path(self.temp.name) / "grunt-attestation"
        base_main = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "origin/main^{commit}"],
                                   check=True, text=True, capture_output=True).stdout.strip()
        subprocess.run(["git", "clone", "-q", "--shared", "--no-checkout", str(ROOT),
                        str(repository)], check=True)
        subprocess.run(["git", "-C", str(repository), "checkout", "-q", "--detach", base_main],
                       check=True)
        subprocess.run(["git", "-C", str(repository), "config", "user.name", "test"], check=True)
        subprocess.run(["git", "-C", str(repository), "config", "user.email",
                        "test@example.invalid"], check=True)
        trace_prefix = "refs/remotes/origin/agent-diagnostics/grunt-candidate-raster-workflow-v1/"
        trace_refs = subprocess.run(["git", "for-each-ref", "--format=%(refname) %(objectname)",
                                     trace_prefix], cwd=ROOT, check=True, text=True,
                                    capture_output=True).stdout.splitlines()
        if not trace_refs:
            self.fail("the immutable historical Grunt lifecycle traces are unavailable")
        for record in trace_refs:
            ref, commit = record.split()
            subprocess.run(["git", "-C", str(repository), "update-ref", ref, commit], check=True)
        attestation_path = "custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json"
        attestation_source = subprocess.run(
            ["git", "show", f"{base_main}:{attestation_path}"], cwd=ROOT,
            check=True, capture_output=True,
        ).stdout
        target_path = ("custodian/docs/ai_context/task_packets/archived/"
                       "AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md")
        original_target = subprocess.run(
            ["git", "show", f"{base_main}:{target_path}"], cwd=ROOT,
            check=True, text=True, capture_output=True,
        ).stdout
        reviewed_base = re.search(r"(?im)^- Reviewed main:\s*`?([0-9a-f]{40,64})`?\s*$",
                                  original_target).group(1)
        correction_archive_commit = subprocess.run(
            ["git", "log", "--diff-filter=AR", "--format=%H", base_main, "--", target_path],
            cwd=ROOT, check=True, text=True, capture_output=True,
        ).stdout.splitlines()[0]
        target = f"""# Correction packet
- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-grunt-raster-review-scope-attestation-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-grunt-attestation`
- Reviewed main: `{reviewed_base}`

## Goal
Verify the exact post-hoc attestation.
"""
        (repository / attestation_path).parent.mkdir(parents=True, exist_ok=True)
        (repository / attestation_path).write_bytes(attestation_source)
        (repository / target_path).parent.mkdir(parents=True, exist_ok=True)
        (repository / target_path).write_text(target, encoding="utf-8")
        subprocess.run(["git", "-C", str(repository), "add", "--", attestation_path, target_path],
                       check=True)
        subprocess.run(["git", "-C", str(repository), "commit", "-qm", "install exact attestation"],
                       check=True)
        implementation_commit = subprocess.run(
            ["git", "-C", str(repository), "rev-parse", "HEAD"], check=True,
            text=True, capture_output=True,
        ).stdout.strip()

        review_workstream = "review-agent-grunt-raster-review-scope-attestation-v1"
        review_packet_path = ("custodian/docs/ai_context/task_packets/archived/"
                              "REVIEW_AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md")
        review_path = ("custodian/docs/ai_context/task_packets/"
                       "REVIEW_AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md")
        review_source = subprocess.run(
            ["git", "show", f"{base_main}:{review_path}"], cwd=ROOT,
            check=True, text=True, capture_output=True,
        ).stdout
        review_source = review_source.replace("- Status: `ready`", "- Status: `complete`", 1)
        review_source += f"""
## Independent Review

- Schema: `custodian.paired_review.v1`
- Review workstream: `{review_workstream}`
- Review target workstream: `agent-grunt-raster-review-scope-attestation-v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `{implementation_commit}`
- Reviewed implementation commit: `{correction_archive_commit}`
"""
        review_source += "\n" + runner.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=review_workstream,
            target_workstream="agent-grunt-raster-review-scope-attestation-v1",
            reviewed_main=implementation_commit, implementation_commit=correction_archive_commit,
            provenance="different-agent", run_id="20261020T100000Z-abcdef123456",
            review_cycle=0, ids=(),
        )
        baseline_target = (repository / target_path).read_text(encoding="utf-8")
        final_target = append_receipt(
            baseline_target, review_workstream=review_workstream,
            target_workstream="agent-grunt-raster-review-scope-attestation-v1",
            reviewed_main=implementation_commit, implementation_commit=correction_archive_commit,
        )
        (repository / target_path).write_text(final_target, encoding="utf-8")
        (repository / review_packet_path).parent.mkdir(parents=True, exist_ok=True)
        (repository / review_packet_path).write_text(review_source, encoding="utf-8")
        subprocess.run(["git", "-C", str(repository), "add", "--", target_path,
                        review_packet_path], check=True)
        subprocess.run(["git", "-C", str(repository), "commit", "-qm", "record independent PASS"],
                       check=True)
        accepted_main = subprocess.run(
            ["git", "-C", str(repository), "rev-parse", "HEAD"], check=True,
            text=True, capture_output=True,
        ).stdout.strip()
        return repository, correction_archive_commit, accepted_main, attestation_path, target_path, review_packet_path

    def test_grunt_six_file_scope_attestation_requires_canonical_independent_review_acceptance(self):
        repository, correction_commit, approved_main, attestation_path, _, review_path = (
            self._build_grunt_attestation_approval_history()
        )
        exact_paths = set(host_validation._GRUNT_SCOPE_FILES)
        with self.assertRaisesRegex(host_validation.HostValidationError, "lacks archived correction review"):
            host_validation._verified_grunt_scope_attestation(repository, correction_commit, exact_paths)

        provenance = host_validation._verified_grunt_scope_attestation(repository, approved_main, exact_paths)
        self.assertEqual(provenance["kind"], "accepted-post-hoc-exact-markdown-attestation")
        self.assertEqual(
            host_validation._git_tree_entry(repository, provenance["attestation_commit"], attestation_path),
            ("100644", provenance["attestation_blob"]),
        )
        self.assertEqual(subprocess.run(
            ["git", "merge-base", "--is-ancestor", provenance["attestation_commit"],
             correction_commit], cwd=repository, capture_output=True,
        ).returncode, 0)
        self.assertEqual(provenance["approval_implementation_commit"], correction_commit)
        self.assertEqual(provenance["approval_outcome"], "passed")
        self.assertEqual(set(provenance["source_files"]), exact_paths)
        target_text = subprocess.run(
            ["git", "show", "e29847bb2dc409ad994ac59ee3e8bb4db637142e:"
             "custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"],
            cwd=repository, check=True, text=True, capture_output=True,
        ).stdout
        documented = set(re.findall(r"custodian/[A-Za-z0-9_./-]+", target_text))
        documented.add("GRUNT_CANDIDATE_RASTER_WORKFLOW_V1_CLAUDE_SUMMARY.md")
        packet_terms = set(re.findall(r"[a-z0-9]+", target_text.lower()))
        for path in exact_paths:
            self.assertTrue(host_validation._source_path_documented(
                path, target_text, documented, packet_terms, set(), exact_paths,
            ))
        for seventh in (
            "custodian/tools/iteration/raster_pipeline/extra.py",
            "custodian/tools/iteration/raster_pipeline/extra.json",
            "custodian/tools/iteration/raster_pipeline/extra.md",
        ):
            self.assertFalse(host_validation._source_path_documented(
                seventh, target_text, documented, packet_terms, set(), exact_paths,
            ), seventh)
        with self.assertRaisesRegex(host_validation.HostValidationError, "lacks archived correction review"):
            host_validation.resolve_validation_source_span(
                repository, correction_commit, "e29847bb2dc409ad994ac59ee3e8bb4db637142e",
                "grunt-candidate-raster-workflow-v1",
                "custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md",
            )
        replay = host_validation.resolve_validation_source_span(
            repository, approved_main, "e29847bb2dc409ad994ac59ee3e8bb4db637142e",
            "grunt-candidate-raster-workflow-v1",
            "custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md",
        )
        self.assertEqual(set(replay["paths"]).intersection(exact_paths), exact_paths)
        self.assertEqual(replay["provenance"]["scope_attestation"]["approval_outcome"], "passed")
        source_paths = host_validation._source_code_paths(replay["paths"])
        changed_paths = subprocess.run(
            ["git", "diff", "--name-only", "--no-renames",
             f"{replay['base']}..{approved_main}"], cwd=repository,
            check=True, text=True, capture_output=True,
        ).stdout.splitlines()
        report = {
            "schema": "custodian.validation.result.v1", "passed": True,
            "changed_files": changed_paths, "selected": ["historical_grunt_source"],
            "tests": [{"id": "historical_grunt_source", "status": "passed"}],
            "summary": {"selected": 1, "passed": 1, "failed": 0, "timed_out": 0,
                        "skipped": 0, "infrastructure_errors": 0},
            "coverage": {"complete": True, "covered_files": sorted(source_paths),
                         "uncovered_files": [], "excluded_files": [],
                         "covered_by": {path: ["historical_grunt_source"] for path in source_paths}},
        }
        run_dir = self.run_dir / "grunt-six-file-coordinator"
        run_dir.mkdir()

        def validate(command, cwd):
            self.assertEqual(Path(cwd), repository)
            self.assertEqual(command[-4:], ["--changed", "--base", replay["base"], "--json"])
            return subprocess.CompletedProcess(command, 0, json.dumps(report) + "\n", "")

        evidence = host_validation.run_coordinator_validation(
            repository, run_dir, approved_main, "e29847bb2dc409ad994ac59ee3e8bb4db637142e",
            target_workstream="grunt-candidate-raster-workflow-v1",
            target_packet_path=("custodian/docs/ai_context/task_packets/archived/"
                                "GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"),
            run_validation=validate,
            capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
        )
        metadata = json.loads((run_dir / "coordinator-validation.json").read_text())
        self.assertEqual(metadata["source_span"]["provenance"]["scope_attestation"],
                         replay["provenance"]["scope_attestation"])
        verified = host_validation.verify_coordinator_validation(
            repository, run_dir, approved_main, "e29847bb2dc409ad994ac59ee3e8bb4db637142e",
            target_workstream="grunt-candidate-raster-workflow-v1",
            target_packet_path=("custodian/docs/ai_context/task_packets/archived/"
                                "GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"),
            expected_report_sha256=evidence["report_sha256"],
            expected_metadata_sha256=evidence["metadata_sha256"],
        )
        self.assertTrue(verified["passed"])
        metadata_path = run_dir / "coordinator-validation.json"
        preserved_metadata = metadata_path.read_bytes()
        metadata_path.write_bytes(preserved_metadata.replace(b'"approval_outcome": "passed"',
                                                             b'"approval_outcome": "findings"'))
        with self.assertRaisesRegex(host_validation.HostValidationError,
                                    "provenance digest changed"):
            host_validation.verify_coordinator_validation(
                repository, run_dir, approved_main, "e29847bb2dc409ad994ac59ee3e8bb4db637142e",
                target_workstream="grunt-candidate-raster-workflow-v1",
                target_packet_path=("custodian/docs/ai_context/task_packets/archived/"
                                    "GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md"),
                expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )

        # A forged PASS outcome without an accepted target receipt cannot activate it.
        outcome_forgery = Path(self.temp.name) / "forged-outcome"
        subprocess.run(["git", "-C", str(repository), "worktree", "add", "-q", "-b",
                        "fixture/forged-outcome", str(outcome_forgery), approved_main], check=True)
        forged_review = outcome_forgery / review_path
        forged_review.write_text(forged_review.read_text().replace(
            "- Outcome: `passed`", "- Outcome: `findings`", 1).replace(
                "- Finding IDs: `none`", "- Finding IDs: `R0-01`", 1), encoding="utf-8")
        subprocess.run(["git", "-C", str(outcome_forgery), "add", "--", review_path], check=True)
        subprocess.run(["git", "-C", str(outcome_forgery), "commit", "-qm", "invalidate PASS"],
                       check=True)
        forged_main = subprocess.run(["git", "-C", str(repository), "rev-parse",
                                      "fixture/forged-outcome"], check=True, text=True,
                                     capture_output=True).stdout.strip()
        with self.assertRaisesRegex(host_validation.HostValidationError, "no canonical independent PASS"):
            host_validation._verified_grunt_scope_attestation(repository, forged_main, exact_paths)
        subprocess.run(["git", "-C", str(repository), "worktree", "remove", "--force",
                        str(outcome_forgery)], check=True)

        # Altering the attestation after its accepted origin is detected by exact bytes.
        mutated = Path(self.temp.name) / "mutated-attestation"
        subprocess.run(["git", "-C", str(repository), "worktree", "add", "-q", "-b",
                        "fixture/mutated-attestation", str(mutated), approved_main], check=True)
        attestation = mutated / attestation_path
        attestation.write_text(attestation.read_text().replace("post_hoc\": true", "post_hoc\": false"),
                               encoding="utf-8")
        subprocess.run(["git", "-C", str(mutated), "add", "--", attestation_path], check=True)
        subprocess.run(["git", "-C", str(mutated), "commit", "-qm", "mutate accepted attestation"],
                       check=True)
        mutated_main = subprocess.run(["git", "-C", str(repository), "rev-parse",
                                       "fixture/mutated-attestation"], check=True, text=True,
                                      capture_output=True).stdout.strip()
        with self.assertRaisesRegex(host_validation.HostValidationError, "exact post-hoc authorization"):
            host_validation._verified_grunt_scope_attestation(repository, mutated_main, exact_paths)
        subprocess.run(["git", "-C", str(repository), "worktree", "remove", "--force",
                        str(mutated)], check=True)

    def test_grunt_six_file_scope_attestation_rejects_changed_entries_and_modes(self):
        repository, _, approved_main, attestation_path, _, _ = (
            self._build_grunt_attestation_approval_history()
        )
        variants = []
        for index in range(len(host_validation._GRUNT_SCOPE_FILES)):
            variants.append((f"blob-{index}", lambda data, i=index: data["source_files"][i].update(
                blob="0" * 40)))
        variants.extend((
            ("renamed-path", lambda data: data["source_files"][0].update(path="custodian/docs/renamed.md")),
            ("wrong-mode", lambda data: data["source_files"][0].update(mode="100755")),
            ("extra-seventh", lambda data: data["source_files"].append({
                "path": "custodian/tools/iteration/raster_pipeline/extra.py",
                "blob": "0" * 40, "mode": "100644",
            })),
        ))
        for name, mutate in variants:
            attestation = repository / attestation_path
            original = subprocess.run(
                ["git", "-C", str(repository), "show", f"{approved_main}:{attestation_path}"],
                check=True, capture_output=True,
            ).stdout
            attestation.write_bytes(original)
            if name == "wrong-mode":
                subprocess.run(["git", "-C", str(repository), "add", "--", attestation_path],
                               check=True)
                subprocess.run(["git", "-C", str(repository), "update-index", "--chmod=+x",
                                "--", attestation_path], check=True)
            else:
                data = json.loads(original)
                mutate(data)
                attestation.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n",
                                       encoding="utf-8")
                subprocess.run(["git", "-C", str(repository), "add", "--", attestation_path],
                               check=True)
            subprocess.run(["git", "-C", str(repository), "commit", "-qm", f"mutate {name}"],
                           check=True)
            head = subprocess.run(["git", "-C", str(repository), "rev-parse", "HEAD"],
                                  check=True, text=True, capture_output=True).stdout.strip()
            expected = "regular-file" if name == "wrong-mode" else "exact post-hoc authorization"
            with self.subTest(variant=name), self.assertRaisesRegex(
                host_validation.HostValidationError, expected,
            ):
                host_validation._verified_grunt_scope_attestation(
                    repository, head, set(host_validation._GRUNT_SCOPE_FILES),
                )
            subprocess.run(["git", "-C", str(repository), "reset", "--hard", approved_main],
                           check=True, stdout=subprocess.DEVNULL)

    def test_source_bearing_archive_accepts_changed_documented_gd_uid(self):
        uid_path = "custodian/game/world/transfer.gd.uid"
        fixture = self._build_main_sync_landing(
            source_bearing_archive=True, archive_uid_path=uid_path,
        )
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["provenance"]["archive_kind"], "source-bearing")
        self.assertIn(uid_path, span["paths"])
        self.assertNotIn(uid_path, host_validation._source_code_paths(span["paths"]))
        self.assertIn("custodian/game/world/transfer.gd",
                      host_validation._source_code_paths(span["paths"]))

    def test_source_bearing_archive_rejects_invalid_uid_companions(self):
        for index, (sidecar, contents, extra, error) in enumerate((
            ("custodian/game/world/rogue.gd.uid", "uid://do0pqluwda6jl\n",
             {}, "archive-only landing contains unrelated paths"),
            ("custodian/game/world/transfer.gd.uid", "not-a-godot-uid\n",
             {}, "malformed Godot script UID sidecar"),
            ("custodian/game/world/transfer.py.uid", "uid://do0pqluwda6jl\n",
             {}, "archive-only landing contains unrelated paths"),
            ("custodian/game/world/rogue.gd.uid", "uid://do0pqluwda6jl\n",
             {"unrelated_archive_path": "custodian/game/world/rogue.gd"},
             "not documented"),
        )):
            if index:
                self.tearDown()
                self.setUp()
            with self.subTest(sidecar=sidecar):
                fixture = self._build_main_sync_landing(
                    source_bearing_archive=True, archive_uid_path=sidecar,
                    archive_uid_text=contents, **extra,
                )
                with self.assertRaisesRegex(host_validation.HostValidationError, error):
                    host_validation.resolve_validation_source_span(
                        self.root, fixture["reviewed_main"], fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_source_bearing_archive_rejects_undocumented_noncode_executable_and_symlink_paths(self):
        for index, (kwargs, message) in enumerate((
            ({"unrelated_archive_path": "custodian/docs/unrelated.md",
              "source_bearing_archive": True}, "archive-only landing contains unrelated paths"),
            ({"unrelated_archive_path": "custodian/tools/agent/unrelated.py",
              "source_bearing_archive": True}, "not documented"),
            ({"source_bearing_archive": True,
              "executable_archive_path": "custodian/game/world/transfer.gd"}, "executable or non-regular"),
            ({"source_bearing_archive": True,
              "nonregular_archive_path": "custodian/game/world/transfer.gd"}, "executable or non-regular"),
        )):
            if index:
                self.tearDown()
                self.setUp()
            with self.subTest(kwargs=kwargs):
                fixture = self._build_main_sync_landing(**kwargs)
                with self.assertRaisesRegex(host_validation.HostValidationError, message):
                    host_validation.resolve_validation_source_span(
                        self.root, fixture["reviewed_main"], fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_historical_source_bearing_archive_resolves_exact_source_and_landing(self):
        landing = "6519a2b2db0bad5f14d7a6993e17c92aca58d081"
        workstream = "agent-paired-review-source-span-main-sync-recovery-v1"
        archive = (f"{runner.PACKET_ROOT}/archived/"
                   "AGENT_PAIRED_REVIEW_SOURCE_SPAN_MAIN_SYNC_RECOVERY_V1.md")
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, landing, landing, workstream, archive,
            )
        self.assertEqual(span["base"], "7119b4c385266e8928070b8e534ea3a5844a5f9f")
        self.assertEqual(span["head"], landing)
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])), {
            "custodian/tools/agent/paired_review_host_validation.py",
            "custodian/tools/agent/test_paired_review_runner.py",
        })
        self.assertEqual(span["provenance"]["archive_kind"], "source-bearing")
        self.assertEqual(span["provenance"]["claim_trace"]["base"], span["base"])
        self.assertEqual(span["provenance"]["landing_trace"]["landing"], landing)

    def test_historical_checkpoint_resume_merge_replays_owned_paths_and_coverage(self):
        reviewed_main = "447c358c312da83c726ac96c5c0fb899b4b8548c"
        workstream = "agent-grunt-raster-review-scope-attestation-v1"
        archive = (f"{runner.PACKET_ROOT}/archived/"
                   "AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md")
        exact_attested_paths = set(host_validation._GRUNT_SCOPE_FILES)
        repository = Path(self.temp.name) / "historical-grunt"
        subprocess.run(["git", "clone", "-q", "--shared", "--no-checkout", str(ROOT),
                        str(repository)], check=True)
        subprocess.run(["git", "-C", str(repository), "checkout", "-q", "--detach",
                        reviewed_main], check=True)
        prefix = f"refs/remotes/origin/agent-diagnostics/{workstream}/"
        for record in subprocess.run(
            ["git", "for-each-ref", "--format=%(refname) %(objectname)", prefix],
            cwd=ROOT, check=True, text=True, capture_output=True,
        ).stdout.splitlines():
            ref, commit = record.split()
            subprocess.run(["git", "-C", str(repository), "update-ref", ref, commit], check=True)
        with self._historical_claim_objects(), patch.object(
            host_validation, "_verified_grunt_scope_attestation",
            return_value={"source_files": sorted(exact_attested_paths)},
        ):
            span = host_validation.resolve_validation_source_span(
                repository, reviewed_main, reviewed_main, workstream, archive,
            )
            merge = span["provenance"]["checkpoint_resume_merge"]
            self.assertEqual(merge["commit"], "08236e69087852cc8a2dfd96edd64a742685e662")
            self.assertEqual(merge["first_parent"], "d0e44dd859d8fb497c9139dd418a9d3c019d377b")
            self.assertEqual(merge["second_parent"], "1f04495f729e830c625b88bdf3f0ceb34264d7be")
            self.assertEqual(merge["merge_tree_proof"], "git-merge-tree-write-tree-exact")
            self.assertIn("custodian/tools/agent/paired_review_host_validation.py", span["paths"])
            self.assertIn("custodian/tools/agent/test_paired_review_runner.py", span["paths"])
            self.assertNotIn("custodian/tools/agent/paired_review_runner.py", span["paths"])
            self.assertNotIn("custodian/tools/agent/workstream.py", span["paths"])

            code_paths = host_validation._source_code_paths(span["paths"])
            changed_paths = subprocess.run(
                ["git", "diff", "--name-only", "--no-renames", f"{span['base']}..{reviewed_main}"],
                cwd=repository, check=True, text=True, capture_output=True,
            ).stdout.splitlines()
            report = {
                "schema": "custodian.validation.result.v1", "passed": True,
                "changed_files": changed_paths, "selected": ["historical_checkpoint_resume"],
                "tests": [{"id": "historical_checkpoint_resume", "status": "passed"}],
                "summary": {"selected": 1, "passed": 1, "failed": 0, "timed_out": 0,
                            "skipped": 0, "infrastructure_errors": 0},
                "coverage": {"complete": True, "covered_files": sorted(code_paths),
                             "uncovered_files": [], "excluded_files": [],
                             "covered_by": {path: ["historical_checkpoint_resume"]
                                            for path in code_paths}},
            }
            run_dir = self.run_dir / "checkpoint-resume-replay"
            run_dir.mkdir()

            def validate(command, cwd):
                self.assertEqual(Path(cwd), repository)
                self.assertEqual(command[-4:], ["--changed", "--base", span["base"], "--json"])
                return subprocess.CompletedProcess(command, 0, json.dumps(report) + "\n", "")

            evidence = host_validation.run_coordinator_validation(
                repository, run_dir, reviewed_main, reviewed_main,
                target_workstream=workstream, target_packet_path=archive,
                run_validation=validate,
                capability_probe=lambda: {"loopback_bind": True, "godot_home_writable": True},
            )
            verified = host_validation.verify_coordinator_validation(
                repository, run_dir, reviewed_main, reviewed_main,
                target_workstream=workstream, target_packet_path=archive,
                expected_report_sha256=evidence["report_sha256"],
                expected_metadata_sha256=evidence["metadata_sha256"],
            )
            self.assertTrue(verified["passed"])

            trace_ref = ("refs/remotes/origin/agent-diagnostics/" + workstream +
                         "/20261019T195635Z-441f0bc5ee6f")
            original_trace_commit = subprocess.run(
                ["git", "rev-parse", trace_ref], cwd=repository, check=True,
                text=True, capture_output=True,
            ).stdout.strip()
            trace_bytes = subprocess.run(
                ["git", "show", f"{trace_ref}:trace.jsonl"], cwd=repository,
                check=True, capture_output=True,
            ).stdout
            canonical_events = [json.loads(line) for line in trace_bytes.splitlines()]

            def replace_trace(events):
                raw = b"".join(json.dumps(event, sort_keys=True).encode() + b"\n"
                                for event in events)
                blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], cwd=repository,
                                      input=raw, check=True, capture_output=True).stdout.decode().strip()
                tree = subprocess.run(["git", "mktree"], cwd=repository,
                                      input=f"100644 blob {blob}\ttrace.jsonl\n",
                                      text=True, check=True, capture_output=True).stdout.strip()
                commit = subprocess.run(["git", "-c", "user.name=test",
                                         "-c", "user.email=test@example.invalid",
                                         "commit-tree", tree, "-m", "forged trace"],
                                        cwd=repository, text=True, check=True,
                                        capture_output=True).stdout.strip()
                subprocess.run(["git", "update-ref", trace_ref, commit], cwd=repository, check=True)

            mutations = []
            for mutate in (
                lambda events: next(event for event in events
                    if event["event"] == "checkpoint_completed")["data"].update(
                        remote_head="0" * 40),
                lambda events: next(event for event in events
                    if event["event"] == "worktree_resumed")["data"].update(
                        worktree="/tmp/unrelated-checkout"),
                lambda events: events.append(next(event for event in events
                    if event["event"] == "worktree_resumed").copy()),
                lambda events: events.remove(next(event for event in events
                    if event["event"] == "checkpoint_completed")),
                lambda events: next(event for event in events
                    if event["event"] == "main_sync")["data"].update(main_sha="0" * 40),
            ):
                events = json.loads(json.dumps(canonical_events))
                mutate(events)
                mutations.append(events)
            for events in mutations:
                replace_trace(events)
                with self.assertRaises(host_validation.HostValidationError):
                    host_validation.resolve_validation_source_span(
                        repository, reviewed_main, reviewed_main, workstream, archive,
                    )
            subprocess.run(["git", "update-ref", trace_ref, original_trace_commit],
                           cwd=repository, check=True)

    def test_checkpoint_resume_merge_adversarial_real_git_histories(self):
        valid = self._build_checkpoint_resume_fixture()
        span = host_validation.resolve_validation_source_span(
            valid["repo"], valid["reviewed_main"], valid["landing"],
            valid["workstream"], valid["archive"],
        )
        provenance = span["provenance"]["checkpoint_resume_merge"]
        self.assertEqual(provenance["commit"], valid["merge"])
        self.assertEqual(set(provenance["owned_paths"]), {
            valid["source_path"], valid["test_path"],
        })

        cases = (
            ("altered-tree", "merge tree differs from deterministic Git merge"),
            ("reordered-parents", "invalid ordered parents|no implementation source"),
            ("octopus-parents", "invalid ordered parents"),
            ("unrelated-second-parent", "second parent is outside published history"),
            ("repeated-merge", "multiple synchronization merges"),
            ("source-loss", "loses workstream-owned source"),
            ("sync-source-mutation", "main-sync merge changes reviewed source"),
            ("undocumented-source", "paths not documented by its target packet"),
            ("unowned-test", "paths not documented by its target packet"),
        )
        for variant, expected in cases:
            with self.subTest(variant=variant):
                fixture = self._build_checkpoint_resume_fixture(variant=variant)
                with self.assertRaisesRegex(host_validation.HostValidationError, expected):
                    host_validation.resolve_validation_source_span(
                        fixture["repo"], fixture["reviewed_main"], fixture["landing"],
                        fixture["workstream"], fixture["archive"],
                    )

        overlap = self._build_checkpoint_resume_fixture(variant="overlap")
        overlap_span = host_validation.resolve_validation_source_span(
            overlap["repo"], overlap["reviewed_main"], overlap["landing"],
            overlap["workstream"], overlap["archive"],
        )
        overlap_provenance = overlap_span["provenance"]["checkpoint_resume_merge"]
        self.assertIn(overlap["source_path"], overlap_provenance["overlapping_paths"])
        self.assertIn(overlap["source_path"], overlap_provenance["owned_paths"])
        self.assertIn(overlap["source_path"], overlap_span["paths"])

    def test_source_bearing_gate_resolves_earlier_failed_claim_without_widening_source_span(self):
        reviewed_main = "9cbbfef899957f2e3fff3306b74accf28cd846dc"
        source_base = "8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8"
        failed_claim_base = "83bdbd1e53fdcb06b18a5a5645f70a050c3cba01"
        canonical_landing = "a407674f3d76d9990b5c1056447a31a7e36a4d5d"
        workstream = "agent-paired-review-source-bearing-archive-gate-v1"
        archive = (f"{runner.PACKET_ROOT}/archived/"
                   "AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md")
        self.assertEqual(subprocess.run(
            ["git", "merge-base", "--is-ancestor", failed_claim_base, source_base],
            cwd=ROOT, capture_output=True,
        ).returncode, 0)
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, reviewed_main, canonical_landing, workstream, archive,
            )
        self.assertEqual(span["base"], source_base)
        self.assertEqual(span["head"], "5b5de5717ae10aa5bbacbd53433571aae016c555")
        self.assertEqual(span["commits"], [span["head"]])
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])), {
            "custodian/tools/agent/paired_review_host_validation.py",
            "custodian/tools/agent/test_paired_review_runner.py",
        })
        self.assertNotIn(failed_claim_base, span["commits"])

    def test_queue_frontier_split_trace_source_bearing_archive_resolves_historically(self):
        landing = "aa9ddfc611fede93eaa3fe8dd68b9063a87a7a94"
        workstream = "queue-execution-frontier-restoration-v1"
        archive = f"{runner.PACKET_ROOT}/archived/QUEUE_EXECUTION_FRONTIER_RESTORATION_V1.md"
        with self._historical_claim_objects():
            span = host_validation.resolve_validation_source_span(
                ROOT, landing, landing, workstream, archive,
            )
        self.assertEqual(span["base"], "1bb09be3cd76115413f9f433f7f8bf2048a7b81c")
        self.assertEqual(span["head"], landing)
        self.assertEqual(set(host_validation._source_code_paths(span["paths"])), {
            "custodian/tools/agent/queue_frontier.py",
            "custodian/tools/agent/test_queue_frontier.py",
        })
        self.assertEqual(span["provenance"]["claim_trace"]["run_id"],
                         "20261019T003727Z-bb7d35e7b6b9")
        self.assertEqual(span["provenance"]["landing_trace"]["run_id"],
                         "20261019T003347Z-547f6421486d")

    def test_split_landing_rejects_invalid_main_sync_trace(self):
        fixture = self._build_main_sync_landing()
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        self._replace_trace_landing(fixture, fixture["merge"],
                                    main_sha=fixture["source_base"], changed=True)
        with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_accepts_exact_noop_main_sync_merge(self):
        fixture = self._build_main_sync_landing()
        self._replace_trace_landing(fixture, fixture["merge"], changed=False)
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["base"], fixture["source_base"])
        self.assertEqual(span["head"], fixture["source_head"])
        self.assertEqual(span["provenance"]["trace_landing_commit"], fixture["merge"])
        self.assertEqual(span["provenance"]["trace_main_sync_sha"], fixture["prior_main"])
        self.assertEqual(span["provenance"]["trace_landing_kind"], "main-sync-merge")

    def test_split_landing_rejects_noop_event_on_single_parent_landing(self):
        fixture = self._build_main_sync_landing()
        self._git("checkout", "-q", "--detach", fixture["archive_landing"])
        tree = self._git("write-tree")
        single_parent_landing = self._commit_tree(
            tree, "single-parent source landing", [fixture["archive_landing"]],
        )
        fixture["reviewed_main"] = self._commit_tree(
            tree, "pin single-parent landing", [single_parent_landing],
        )
        self._replace_trace_landing(fixture, single_parent_landing,
                                    main_sha=fixture["archive_landing"], changed=False)
        with self.assertRaisesRegex(host_validation.HostValidationError, "source tail"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_missing_duplicate_and_conflicting_main_sync_events(self):
        fixture = self._build_main_sync_landing()
        valid = {"changed": False, "head": fixture["merge"],
                 "main_sha": fixture["prior_main"]}
        events = (
            [],
            [valid, valid],
        )
        for main_sync_events in events:
            with self.subTest(main_sync_events=main_sync_events):
                self._replace_trace_main_sync_events(fixture, fixture["merge"], main_sync_events)
                with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
                    host_validation.resolve_validation_source_span(
                        self.root, fixture["reviewed_main"], fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_split_landing_preserves_legacy_true_sync_with_later_noop_attempt(self):
        fixture = self._build_main_sync_landing()
        self._replace_trace_main_sync_events(fixture, fixture["merge"], [
            {"changed": True, "head": fixture["merge"],
             "main_sha": fixture["prior_main"]},
            {"changed": False, "head": fixture["merge"],
             "main_sha": fixture["prior_main"]},
        ])
        span = host_validation.resolve_validation_source_span(
            self.root, fixture["reviewed_main"], fixture["archive_landing"],
            fixture["workstream"], fixture["archive"],
        )
        self.assertEqual(span["provenance"]["trace_main_sync_sha"], fixture["prior_main"])

    def test_split_landing_rejects_missing_or_malformed_main_sync_fields(self):
        fixture = self._build_main_sync_landing()
        malformed = (
            {"changed": False, "main_sha": fixture["prior_main"]},
            {"changed": False, "head": fixture["merge"]},
            {"changed": "false", "head": fixture["merge"],
             "main_sha": fixture["prior_main"]},
            {"changed": 0, "head": fixture["merge"],
             "main_sha": fixture["prior_main"]},
            {"changed": None, "head": fixture["merge"],
             "main_sha": fixture["prior_main"]},
        )
        for event in malformed:
            with self.subTest(event=event):
                self._replace_trace_main_sync_events(fixture, fixture["merge"], [event])
                with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
                    host_validation.resolve_validation_source_span(
                        self.root, fixture["reviewed_main"], fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_split_landing_rejects_noop_event_with_wrong_merge_head_or_parent(self):
        fixture = self._build_main_sync_landing()
        for event in (
            {"changed": False, "head": fixture["archive_landing"],
             "main_sha": fixture["prior_main"]},
            {"changed": False, "head": fixture["merge"],
             "main_sha": fixture["source_base"]},
        ):
            with self.subTest(event=event):
                self._replace_trace_main_sync_events(fixture, fixture["merge"], [event])
                with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
                    host_validation.resolve_validation_source_span(
                        self.root, fixture["reviewed_main"], fixture["archive_landing"],
                        fixture["workstream"], fixture["archive"],
                    )

    def test_split_landing_rejects_malformed_or_forged_trace_events(self):
        fixture = self._build_main_sync_landing()
        valid_ref = (f"refs/remotes/origin/agent-diagnostics/{fixture['workstream']}/"
                     "20261018T020000Z-012345abcdef")
        subprocess.run(["git", "update-ref", "-d", valid_ref], cwd=self.root, check=True)
        self._install_trace(
            fixture["workstream"], fixture["active"], "20261018T020001Z-012345abcdef",
            fixture["source_base"], fixture["merge"],
            main_sync={"changed": True, "head": fixture["merge"],
                       "main_sha": fixture["prior_main"]},
            malformed_data=True,
        )
        with self.assertRaisesRegex(host_validation.HostValidationError,
                                    "invalid event provenance"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_wrong_main_sync_merge_parent_order_and_count(self):
        fixture = self._build_main_sync_landing()
        commit = self._install_alternate_merge(
            fixture, parents=[fixture["prior_main"], fixture["archive_landing"]],
            main_sha=fixture["archive_landing"],
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_three_parent_main_sync_commit(self):
        fixture = self._build_main_sync_landing()
        self._install_alternate_merge(
            fixture, parents=[fixture["archive_landing"], fixture["prior_main"],
                              fixture["source_base"]],
        )
        with self.assertRaisesRegex(host_validation.HostValidationError, "main-sync merge"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_source_mutation_in_merge(self):
        fixture = self._build_main_sync_landing()
        self._install_alternate_merge(fixture, changed_path=fixture["code_paths"][0])
        with self.assertRaisesRegex(host_validation.HostValidationError, "changes reviewed source"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_archived_target_mutation_in_merge(self):
        fixture = self._build_main_sync_landing()
        self._install_alternate_merge(fixture, changed_path=fixture["archive"])
        with self.assertRaisesRegex(host_validation.HostValidationError, "changes archived target"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_split_landing_rejects_unrelated_archive_closeout_path(self):
        fixture = self._build_main_sync_landing(
            unrelated_archive_path="custodian/game/unrelated.gd")
        with self.assertRaisesRegex(host_validation.HostValidationError,
                                    "not documented"):
            host_validation.resolve_validation_source_span(
                self.root, fixture["reviewed_main"], fixture["archive_landing"],
                fixture["workstream"], fixture["archive"],
            )

    def test_archive_only_landing_rejects_missing_or_ambiguous_trace_and_unrelated_code(self):
        workstream = "sample-impl"
        active = f"{runner.PACKET_ROOT}/SAMPLE_IMPL.md"
        archive = f"{runner.PACKET_ROOT}/archived/SAMPLE_IMPL.md"
        initial_main = self.base
        packet = (f"# Sample\n- Packet schema: `custodian.task_packet.v2`\n"
                  f"- Workstream: `{workstream}`\n- Kind: `implementation`\n"
                  f"- Status: `in_progress`\n- Reviewed main: `{initial_main}`\n"
                  f"\n## Work surface\n- `custodian/tools/agent/worktree_backlog_census.py`\n")
        (self.root / active).parent.mkdir(parents=True, exist_ok=True)
        (self.root / active).write_text(packet)
        (self.root / f"{runner.PACKET_ROOT}/README.md").write_text("active\n")
        self._commit("publish packet")
        source_base = self._git("rev-parse", "HEAD")
        code = self.root / "custodian/tools/agent/worktree_backlog_census.py"
        code.parent.mkdir(parents=True, exist_ok=True)
        code.write_text("source\n")
        self._commit("implementation source")
        source_head = self._git("rev-parse", "HEAD")
        extra = self.root / "custodian/game/unrelated.gd"
        extra.parent.mkdir(parents=True, exist_ok=True)
        extra.write_text("unrelated\n")
        self._commit("unrelated implementation")
        (self.root / archive).parent.mkdir(parents=True, exist_ok=True)
        (self.root / archive).write_text(packet.replace("`in_progress`", "`complete`"))
        (self.root / active).unlink()
        (self.root / f"{runner.PACKET_ROOT}/README.md").write_text("archived\n")
        self._commit("archive packet")
        landing = self._git("rev-parse", "HEAD")
        with self.assertRaisesRegex(host_validation.HostValidationError, "trace provenance"):
            host_validation.resolve_validation_source_span(self.root, landing, landing, workstream, archive)
        self._install_trace(workstream, active, "20261018T010001Z-012345abcdef", source_base, landing)
        with self.assertRaisesRegex(host_validation.HostValidationError, "not documented"):
            host_validation.resolve_validation_source_span(self.root, landing, landing, workstream, archive)
        self._install_trace(workstream, active, "20261018T010002Z-012345abcdef", source_base, landing)
        with self.assertRaisesRegex(host_validation.HostValidationError, "ambiguous"):
            host_validation.resolve_validation_source_span(self.root, landing, landing, workstream, archive)


if __name__ == "__main__":
    unittest.main()
