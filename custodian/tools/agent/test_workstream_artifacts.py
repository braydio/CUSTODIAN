"""Focused run-artifact finalization coverage for workstream lifecycle."""

import importlib.util
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
            "- Dispatch: `auto`\n- Status: `ready`\n"
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
