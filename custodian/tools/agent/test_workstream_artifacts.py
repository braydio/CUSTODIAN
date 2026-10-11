"""Focused run-artifact finalization coverage for workstream lifecycle."""

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("workstream.py")
SPEC = importlib.util.spec_from_file_location("workstream_artifact_test_target", SCRIPT)
workstream = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workstream)


def git(cwd: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


class WorkstreamArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        git(self.repo, "init")
        git(self.repo, "config", "user.name", "Test")
        git(self.repo, "config", "user.email", "test@example.test")
        (self.repo / "base.txt").write_text("base\n")
        git(self.repo, "add", "base.txt")
        git(self.repo, "commit", "-m", "base")
        self.packet_root = self.repo / "custodian/docs/ai_context/task_packets"
        self.archive_root = self.packet_root / "archived"
        self.archive_root.mkdir(parents=True)
        (self.packet_root / "README.md").write_text(
            "# Agent Task Packets\n\n"
            "## Active Packets\n\n"
            "### In Progress\n\n"
            "### Recently Complete (awaiting archive)\n"
        )
        git(self.repo, "add", "custodian")
        git(self.repo, "commit", "-m", "packet scaffold")

    def tearDown(self):
        self.temp.cleanup()

    def commit_all(self, message: str = "artifact state") -> None:
        git(self.repo, "add", "-A")
        git(self.repo, "commit", "-m", message)

    def test_no_packet_and_no_run_debris_passes(self):
        self.assertEqual(workstream.artifact_preflight("simple-fix", self.repo), [])

    def test_active_associated_packet_blocks_even_when_complete(self):
        packet = self.packet_root / "SOME_TASK.md"
        packet.write_text(
            "# SOME TASK\n\n"
            "- Workstream: `artifact-gate`\n"
            "- Status: `complete`\n"
        )
        self.commit_all()
        with self.assertRaisesRegex(
            workstream.WorkstreamError,
            "moved to task_packets/archived",
        ):
            workstream.artifact_preflight("artifact-gate", self.repo)

    def test_archived_complete_packet_passes(self):
        packet = self.archive_root / "SOME_TASK.md"
        packet.write_text(
            "# SOME TASK\n\n"
            "- Workstream: `artifact-gate`\n"
            "- Status: `complete`\n"
        )
        self.commit_all()
        packets = workstream.artifact_preflight("artifact-gate", self.repo)
        self.assertEqual(packets, [packet])

    def test_archived_packet_with_authoring_chat_requires_exact_summary_backlink(self):
        packet = self.archive_root / "CHAT_TASK.md"
        packet.write_text(
            "# CHAT TASK\n\n"
            "- Workstream: `chat-gate`\n"
            "- Status: `complete`\n"
            "- Authoring chat: `https://chatgpt.com/c/exact-authoring-chat`\n"
        )
        summary = self.repo / "CHAT_GATE_CLAUDE_SUMMARY.md"
        summary.write_text("Completed without provenance.\n")
        self.commit_all()
        with self.assertRaisesRegex(workstream.WorkstreamError, "summary backlink gate"):
            workstream.artifact_preflight("chat-gate", self.repo)
        summary.write_text(
            "Authoring chat: https://chatgpt.com/c/exact-authoring-chat\n"
            "Completed with provenance.\n"
        )
        self.commit_all("fix summary backlink")
        self.assertEqual(workstream.artifact_preflight("chat-gate", self.repo), [packet])

    def test_archived_incomplete_packet_blocks(self):
        packet = self.archive_root / "SOME_TASK.md"
        packet.write_text(
            "# SOME TASK\n\n"
            "- Workstream: `artifact-gate`\n"
            "- Status: `in_progress`\n"
        )
        self.commit_all()
        with self.assertRaisesRegex(workstream.WorkstreamError, "not complete"):
            workstream.artifact_preflight("artifact-gate", self.repo)

    def test_archived_packet_still_listed_active_blocks(self):
        packet = self.archive_root / "SOME_TASK.md"
        packet.write_text(
            "# SOME TASK\n\n"
            "- Workstream: `artifact-gate`\n"
            "- Status: `complete`\n"
        )
        (self.packet_root / "README.md").write_text(
            "# Agent Task Packets\n\n"
            "## Active Packets\n\n"
            "### In Progress\n"
            "- `SOME_TASK.md` - stale active entry\n"
        )
        self.commit_all()
        with self.assertRaisesRegex(workstream.WorkstreamError, "still listed"):
            workstream.artifact_preflight("artifact-gate", self.repo)

    def test_untracked_run_artifacts_fail_closed_with_classification(self):
        reports = self.repo / "reports"
        reports.mkdir()
        (reports / "capture.json").write_text("{}\n")
        with self.assertRaisesRegex(workstream.WorkstreamError, "review-evidence:reports/capture.json"):
            workstream.artifact_preflight("artifact-gate", self.repo)

    def test_untracked_asset_v2_source_is_never_silently_discarded(self):
        asset = self.repo / "custodian/asset_drop/source_work/operator"
        asset.mkdir(parents=True)
        (asset / "candidate.png").write_bytes(b"not-a-real-png")
        with self.assertRaisesRegex(workstream.WorkstreamError, "asset-v2-source"):
            workstream.artifact_preflight("artifact-gate", self.repo)

    def test_closeout_preflight_reports_incomplete_truth_index_backlink_debris_and_bad_validation(self):
        workstream_id = "preflight-incomplete"
        active = self.packet_root / "ACTIVE_PREFLIGHT.md"
        active.write_text(
            "# Active\n\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Kind: `implementation`\n"
            "- Status: `complete`\n"
            "- Authoring chat: `https://chatgpt.com/c/preflight`\n"
        )
        archived = self.archive_root / "ARCHIVED_PREFLIGHT.md"
        archived.write_text(
            "# Archived\n\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Kind: `implementation`\n"
            "- Status: `complete`\n"
            "- Authoring chat: `https://chatgpt.com/c/preflight`\n"
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `no`\n"
            "- Acceptance satisfied: `yes`\n"
        )
        (self.packet_root / "README.md").write_text(
            "# Agent Task Packets\n\n## Active Packets\n\n"
            "### In Progress\n- `ARCHIVED_PREFLIGHT.md` - stale\n"
            "### Recently Complete (awaiting archive)\n"
        )
        self.commit_all("incomplete closeout state")
        debris = self.repo / "reports/leftover.json"
        debris.parent.mkdir()
        debris.write_text("{}\n")
        invalid_report = Path(self.temp.name) / "invalid-validation.json"
        invalid_report.write_text('{"schema":"wrong"}\n')

        before_head = git(self.repo, "rev-parse", "HEAD")
        before_refs = git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)")
        before_worktrees = git(self.repo, "worktree", "list", "--porcelain")
        before_files = {path.relative_to(self.repo).as_posix(): path.read_bytes()
                        for path in self.repo.rglob("*") if path.is_file() and ".git" not in path.parts}
        report = workstream.closeout_preflight(workstream_id, self.repo, invalid_report)

        self.assertFalse(report["ready_before_sync"])
        self.assertEqual(len(report["packet_blockers"]), 1)
        self.assertEqual(len(report["completion_truth_blockers"]), 2)
        self.assertEqual(report["managed_index"]["stale_archived_entries"], [archived.relative_to(self.repo).as_posix()])
        self.assertEqual(report["untracked_artifacts"], [{"path": "reports/leftover.json", "classification": "review-evidence"}])
        self.assertEqual(report["summary"]["missing_authoring_chat_backlinks"], ["https://chatgpt.com/c/preflight"])
        self.assertEqual(report["validation"]["integrity"], "invalid")
        self.assertEqual(report["post_sync"]["status"], "unknown")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), before_head)
        self.assertEqual(git(self.repo, "for-each-ref", "--format=%(refname) %(objectname)"), before_refs)
        self.assertEqual(git(self.repo, "worktree", "list", "--porcelain"), before_worktrees)
        after_files = {path.relative_to(self.repo).as_posix(): path.read_bytes()
                       for path in self.repo.rglob("*") if path.is_file() and ".git" not in path.parts}
        self.assertEqual(after_files, before_files)

    def test_closeout_preflight_reports_missing_paired_review_receipt_and_provenance(self):
        workstream_id = "review-preflight"
        target = self.archive_root / "TARGET.md"
        target.write_text("# Target\n\n- Workstream: `target`\n- Status: `complete`\n")
        packet = self.archive_root / "REVIEW_PREFLIGHT.md"
        packet.write_text(
            "# Review\n\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Kind: `review`\n"
            "- Status: `complete`\n"
            "- Review target packet: `custodian/docs/ai_context/task_packets/archived/TARGET.md`\n"
            "- Reviewer context: `fresh`\n"
            "- Reviewer provenance: `different-agent`\n"
        )
        self.commit_all("review packet without receipt")
        report = workstream.closeout_preflight(workstream_id, self.repo)
        self.assertEqual(report["review_receipt_blockers"], [packet.relative_to(self.repo).as_posix()])
        receipt = report["packets"][0]["review_receipt"]
        self.assertFalse(receipt["receipt_present"])
        self.assertEqual(receipt["reviewer_context"], "fresh")
        self.assertEqual(receipt["reviewer_provenance"], "different-agent")

    def test_paired_review_receipt_delta_passes_real_finish_and_missing_receipt_fails(self):
        workstream_id = "review-fixture-review-corrections-1"
        target_workstream = "fixture-review-corrections-1"
        review_path = "custodian/docs/ai_context/task_packets/archived/REVIEW_FIXTURE.md"
        target_path = "custodian/docs/ai_context/task_packets/archived/FIXTURE.md"
        chat = "https://chatgpt.com/c/receipt-delta-fixture"
        remote = Path(self.temp.name) / "origin.git"
        git(self.repo, "init", "-b", "main")
        git(self.repo, "branch", "-M", "main")
        git(self.repo, "init", "--bare", str(remote))
        git(self.repo, "remote", "add", "origin", str(remote))

        implementation = self.repo / "custodian/game/fixture_impl.py"
        implementation.parent.mkdir(parents=True, exist_ok=True)
        implementation.write_text("fixture implementation\n")
        git(self.repo, "add", "custodian/game/fixture_impl.py")
        git(self.repo, "commit", "-m", "fixture implementation")
        packet_predecessor = git(self.repo, "rev-parse", "HEAD")
        target = self.repo / target_path
        target.write_text(
            "# Fixture implementation\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{target_workstream}`\n"
            "- Kind: `correction`\n- Status: `complete`\n"
            f"- Reviewed main: `{packet_predecessor}`\n"
        )
        review = self.repo / review_path
        review.write_text(
            "# Fixture review\n- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n- Kind: `review`\n- Status: `complete`\n"
            "- Dispatch: `auto`\n- Review cycle: `1`\n- Max automatic review cycles: `1`\n"
            f"- Review target workstream: `{target_workstream}`\n"
            f"- Review target packet: `{target_path}`\n- Authoring chat: `{chat}`\n"
        )
        git(self.repo, "add", target_path, review_path)
        git(self.repo, "commit", "-m", "publish fixture packets")
        implementation_sha = git(self.repo, "rev-parse", "HEAD")
        reviewed_main = implementation_sha
        git(self.repo, "push", "-u", "origin", "main")
        git(self.repo, "update-ref", "refs/remotes/origin/main", reviewed_main)

        branch = workstream.branch_for(workstream_id)
        branch_path = Path(self.temp.name) / "review-branch"
        git(self.repo, "worktree", "add", "-b", branch, str(branch_path), "HEAD")
        baseline = (branch_path / target_path).read_text()
        with self.assertRaisesRegex(workstream.WorkstreamError, "requires a committed change to the reviewed packet receipt"):
            workstream.artifact_preflight(workstream_id, branch_path)

        candidate = baseline + (
            "\n## Independent Review\n\n"
            f"### Review Receipt: {workstream_id}\n"
            "- Schema: `custodian.paired_review.v1`\n"
            f"- Review workstream: `{workstream_id}`\n"
            f"- Review target workstream: `{target_workstream}`\n"
            "- Status: `passed`\n- Blocking defects: `0`\n- Material gaps: `0`\n"
            "- Reviewer context: `fresh`\n- Reviewer provenance: `different-agent`\n"
            f"- Reviewed main: `{reviewed_main}`\n"
            f"- Reviewed implementation commit: `{implementation_sha}`\n"
        )
        (branch_path / target_path).write_text(candidate)
        pinned_baseline = subprocess.run(["git", "show", f"{reviewed_main}:{target_path}"], cwd=branch_path,
                                         check=True, text=True, capture_output=True).stdout
        self.assertEqual(pinned_baseline, baseline)
        self.assertTrue(baseline.endswith("\n"), repr(baseline))
        self.assertNotIn("Implementation commit:", baseline)
        self.assertNotIn("## Independent Review", baseline)
        self.assertTrue(candidate.startswith(baseline))
        summary_path = branch_path / workstream._expected_summary_filename(workstream_id)
        summary_path.write_text(f"Authoring chat: {chat}\n\n## Next Handoff\n- Next workstream: none\n")
        git(branch_path, "add", target_path, summary_path.name)
        git(branch_path, "commit", "-m", "append exact paired review receipt")
        candidate_head = git(branch_path, "rev-parse", "HEAD")
        self.assertIsNone(workstream._paired_review_artifact_preflight_error(
            workstream_id, branch_path, branch_path / review_path))

        report = Path(self.temp.name) / "green-validation.json"
        report.write_text(json.dumps({
            "schema": "custodian.validation.result.v1", "passed": True,
            "coverage": {"complete": True}, "tests": [{"id": "fixture", "status": "passed"}],
        }))
        workstream.finish(workstream_id, report, repo=self.repo)
        landed = git(self.repo, "--git-dir", str(remote), "rev-parse", "refs/heads/main")
        self.assertEqual(git(self.repo, "merge-base", "--is-ancestor", candidate_head, landed), "")
        self.assertFalse(branch_path.exists())
        self.assertNotIn(branch, git(self.repo, "branch", "--list", branch))

    def test_closeout_preflight_is_ready_only_for_complete_committed_green_state(self):
        workstream_id = "preflight-ready"
        chat = "https://chatgpt.com/c/preflight-ready"
        packet = self.archive_root / "READY_PREFLIGHT.md"
        packet.write_text(
            "# Ready\n\n"
            "- Packet schema: `custodian.task_packet.v2`\n"
            f"- Workstream: `{workstream_id}`\n"
            "- Kind: `implementation`\n"
            "- Status: `complete`\n"
            f"- Authoring chat: `{chat}`\n"
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `yes`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Evidence: focused checks passed\n"
        )
        summary_name = workstream._expected_summary_filename(workstream_id)
        (self.repo / summary_name).write_text(f"Authoring chat: {chat}\nCloseout evidence.\n")
        self.commit_all("complete preflight state")
        branch = workstream.branch_for(workstream_id)
        git(self.repo, "checkout", "-b", branch)
        git(self.repo, "update-ref", "refs/remotes/origin/main", "HEAD")
        git(self.repo, "update-ref", f"refs/remotes/origin/{branch}", "HEAD")
        validation = Path(self.temp.name) / "green-validation.json"
        validation.write_text(json.dumps({
            "schema": "custodian.validation.result.v1",
            "passed": True,
            "coverage": {"complete": True},
            "tests": [{"id": "sample", "status": "passed"}],
        }))

        report = workstream.closeout_preflight(workstream_id, self.repo, validation)
        self.assertTrue(report["ready_before_sync"], report["blockers"])
        self.assertEqual(report["blockers"], [])
        self.assertTrue(report["summary"]["committed_at_head"])
        self.assertTrue(report["validation"]["green"])
        self.assertEqual(report["post_sync"]["status"], "unknown")
        validation.write_text(json.dumps({
            "schema": "custodian.validation.result.v1",
            "passed": False,
            "coverage": {"complete": True},
            "tests": [{"id": "sample", "status": "failed"}],
        }))
        report = workstream.closeout_preflight(workstream_id, self.repo, validation)
        self.assertFalse(report["ready_before_sync"])
        self.assertIn("validation", [item["gate"] for item in report["blockers"]])

        incomplete_reports = [
            {"coverage": {"complete": False}},
            {},
            {"coverage": []},
        ]
        for index, coverage_fields in enumerate(incomplete_reports):
            incomplete = {
                "schema": "custodian.validation.result.v1",
                "passed": True,
                "tests": [{"id": "sample", "status": "passed"}],
                **coverage_fields,
            }
            validation.write_text(json.dumps(incomplete))
            report = workstream.closeout_preflight(workstream_id, self.repo, validation)
            self.assertFalse(report["validation"]["green"], index)
            self.assertFalse(report["ready_before_sync"], index)
            self.assertIn("validation", [item["gate"] for item in report["blockers"]], index)

    def test_preflight_cli_is_json_and_does_not_create_a_run_trace(self):
        import contextlib
        import io
        import json
        import sys
        from unittest import mock

        branch_path = Path(self.temp.name) / "cli-preflight-worktree"
        git(self.repo, "worktree", "add", "-b", "agent/cli-preflight", str(branch_path), "HEAD")
        original_cwd = Path.cwd()
        before_worktrees = git(self.repo, "worktree", "list", "--porcelain")
        output = io.StringIO()
        try:
            os.chdir(self.repo)
            with mock.patch.object(sys, "argv", ["workstream.py", "preflight", "cli-preflight", "--json"]), \
                 mock.patch.object(workstream.RunTrace, "start", side_effect=AssertionError("trace created")), \
                 contextlib.redirect_stdout(output):
                result = workstream.main()
        finally:
            os.chdir(original_cwd)
        self.assertEqual(result, 0)
        data = json.loads(output.getvalue())
        self.assertEqual(data["schema"], "custodian.workstream.closeout_preflight.v1")
        self.assertFalse(data["ready_before_sync"])
        self.assertEqual(git(self.repo, "worktree", "list", "--porcelain"), before_worktrees)

    def test_paired_review_commits_only_authorized_artifacts_and_preserves_root_work(self):
        impl_path = self.repo / "custodian/game/reviewed_impl.py"
        impl_path.parent.mkdir(parents=True)
        impl_path.write_text("implementation baseline\n")
        archived_target = self.archive_root / "IMPLEMENTATION.md"
        archived_target.write_text(
            "# Implementation\n\n- Workstream: `implementation`\n- Status: `complete`\n"
        )
        review_packet = self.packet_root / "REVIEW_IMPLEMENTATION.md"
        review_packet.write_text(
            "# Review\n\n- Workstream: `review-implementation`\n- Kind: `review`\n"
            "- Dispatch: `manual`\n- Status: `ready`\n"
            "- Review target workstream: `implementation`\n"
            "- Review target packet: `custodian/docs/ai_context/task_packets/archived/IMPLEMENTATION.md`\n"
            "- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`\n"
        )
        (self.packet_root / "README.md").write_text(
            "# Agent Task Packets\n\n## Active Packets\n\n### Ready / Auto Dispatch\n"
            "- `REVIEW_IMPLEMENTATION.md`\n\n### In Progress\n\n"
            "### Recently Complete (awaiting archive)\n"
        )
        git(self.repo, "add", "custodian")
        git(self.repo, "commit", "-m", "add implementation and review authority")
        git(self.repo, "update-ref", "refs/remotes/origin/main", "HEAD")

        branch_path = Path(self.temp.name) / "review-worktree"
        git(self.repo, "worktree", "add", "-b", "agent/review-implementation", str(branch_path), "HEAD")
        unrelated = self.repo / "operator_notes.txt"
        unrelated.write_text("keep this unrelated root work\n")
        root_status = git(self.repo, "status", "--porcelain=v1", "-z")
        unrelated_bytes = unrelated.read_bytes()

        target_in_branch = branch_path / "custodian/docs/ai_context/task_packets/archived/IMPLEMENTATION.md"
        target_in_branch.write_text(target_in_branch.read_text() + "\n## Independent Review\n\n- Status: `passed`\n")
        old_review = branch_path / "custodian/docs/ai_context/task_packets/REVIEW_IMPLEMENTATION.md"
        review_archive = branch_path / "custodian/docs/ai_context/task_packets/archived/REVIEW_IMPLEMENTATION.md"
        review_archive.parent.mkdir(parents=True, exist_ok=True)
        review_archive.write_text(old_review.read_text().replace("Status: `ready`", "Status: `complete`"))
        old_review.unlink()
        index = branch_path / "custodian/docs/ai_context/task_packets/README.md"
        index.write_text(index.read_text().replace("- `REVIEW_IMPLEMENTATION.md`\n", ""))
        summary = branch_path / "REVIEW_IMPLEMENTATION_CLAUDE_SUMMARY.md"
        summary.write_text("Review closed with a passed receipt.\n")
        correction = branch_path / "custodian/docs/ai_context/task_packets/implementation-review-corrections-1.md"
        correction.write_text("- Workstream: `implementation-review-corrections-1`\n- Findings addressed: `R0-01`\n")
        paired_correction_review = branch_path / "custodian/docs/ai_context/task_packets/REVIEW_IMPLEMENTATION_REVIEW_CORRECTIONS_1.md"
        paired_correction_review.write_text("- Workstream: `review-implementation-review-corrections-1`\n")
        allowed = [
            "custodian/docs/ai_context/task_packets/archived/IMPLEMENTATION.md",
            "custodian/docs/ai_context/task_packets/archived/REVIEW_IMPLEMENTATION.md",
            "custodian/docs/ai_context/task_packets/README.md",
            "REVIEW_IMPLEMENTATION_CLAUDE_SUMMARY.md",
            "custodian/docs/ai_context/task_packets/implementation-review-corrections-1.md",
            "custodian/docs/ai_context/task_packets/REVIEW_IMPLEMENTATION_REVIEW_CORRECTIONS_1.md",
        ]
        git(branch_path, "add", *allowed)
        git(branch_path, "commit", "-m", "close independent review")

        self.assertEqual(workstream.artifact_preflight("review-implementation", branch_path), [review_archive])
        self.assertEqual((branch_path / "custodian/game/reviewed_impl.py").read_bytes(), b"implementation baseline\n")
        self.assertEqual(impl_path.read_bytes(), b"implementation baseline\n")
        self.assertEqual(unrelated.read_bytes(), unrelated_bytes)
        self.assertEqual(git(self.repo, "status", "--porcelain=v1", "-z"), root_status)
        self.assertEqual(
            workstream.paired_review_artifact_scope_error(
                "review-implementation", review_archive, review_archive.read_text(),
                allowed + ["custodian/game/reviewed_impl.py"],
                artifact_contents={
                    "custodian/docs/ai_context/task_packets/implementation-review-corrections-1.md": correction.read_text(),
                    "custodian/docs/ai_context/task_packets/REVIEW_IMPLEMENTATION_REVIEW_CORRECTIONS_1.md": paired_correction_review.read_text(),
                },
            ),
            "paired review artifact gate rejects unauthorized change: custodian/game/reviewed_impl.py",
        )


if __name__ == "__main__":
    unittest.main()
