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


if __name__ == "__main__":
    unittest.main()
