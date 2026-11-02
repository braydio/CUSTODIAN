"""Focused safety and idempotence tests for the queue metadata repair plan."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("task_packet_repair.py")
SPEC = importlib.util.spec_from_file_location("custodian_task_packet_repair_tests", SCRIPT)
repair = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = repair
SPEC.loader.exec_module(repair)


def packet(workstream: str, modes: str = "code, architecture, runtime, persistence") -> str:
    return (
        f"# {workstream}\n\n"
        f"- Workstream: `{workstream}`\n"
        "- Status: `ready`\n"
        "- Dispatch: `auto`\n"
        f"- Review modes: `{modes}`\n\n"
        "Acceptance preserves persistence and save/load behavior.\n"
    )


class TaskPacketRepairTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        root = self.repo / repair.PACKET_ROOT
        root.mkdir(parents=True)
        for workstream in repair.MODE_IDS:
            (root / repair._mode_path(workstream)).write_text(packet(workstream))
        for workstream, (filename, old_field, _new_field) in repair.HEADER_RENAMES.items():
            (root / filename).write_text(
                f"# {workstream}\n\n- Workstream: `{workstream}`\n- Status: `ready`\n"
                f"- Dispatch: `auto`\n- {old_field}: `0123456789abcdef0123456789abcdef01234567`\n"
            )
        visual = (
            f"# {repair.VISUAL_ID}\n\n"
            f"- Workstream: `{repair.VISUAL_ID}`\n"
            "- Status: `ready`\n- Dispatch: `auto`\n"
            "- Visual review: Publish a small evidence set. Ask: is the direction sound? Stop for explicit user approval.\n\n"
            "## Completion Truth\n\n- Goal satisfied: no\n"
        )
        (root / "SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md").write_text(visual)

    def tearDown(self):
        self.temp.cleanup()

    def test_plan_is_read_only_apply_preserves_obligations_and_is_idempotent(self):
        before = {p.name: p.read_bytes() for p in (self.repo / repair.PACKET_ROOT).glob("*.md")}
        plan = repair.plan(self.repo)
        self.assertEqual(sum(item["changed"] == "true" for item in plan), 8)
        self.assertEqual(before, {p.name: p.read_bytes() for p in (self.repo / repair.PACKET_ROOT).glob("*.md")})

        applied = repair.apply(self.repo)
        self.assertEqual(sum(item["changed"] == "true" for item in applied), 8)
        self.assertEqual(sum(item["changed"] == "true" for item in repair.plan(self.repo)), 0)
        for workstream in repair.MODE_IDS:
            text = (self.repo / repair.PACKET_ROOT / repair._mode_path(workstream)).read_text()
            self.assertIn("Review modes: `code, architecture, runtime`", text)
            self.assertIn("Acceptance preserves persistence and save/load behavior.", text)
        visual = (self.repo / repair.PACKET_ROOT / "SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md").read_text()
        self.assertIn("- Visual review: required", visual)
        self.assertIn("## Visual review plan", visual)
        self.assertIn("Stop for explicit user approval.", visual)

    def test_plan_refuses_identity_or_unexpected_mode_drift(self):
        path = self.repo / repair.PACKET_ROOT / repair._mode_path(repair.MODE_IDS[0])
        path.write_text(packet("different-workstream"))
        with self.assertRaisesRegex(repair.RepairError, "expected"):
            repair.plan(self.repo)

        path.write_text(packet(repair.MODE_IDS[0], "code, architecture, persistence"))
        with self.assertRaisesRegex(repair.RepairError, "Review modes changed"):
            repair.plan(self.repo)

    def test_legacy_archive_migration_requires_completion_evidence_and_is_lossless(self):
        subprocess.run(["git", "init", "-b", "main"], cwd=self.repo, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.name", "Repair Test"], cwd=self.repo, check=True)
        subprocess.run(["git", "config", "user.email", "repair@example.test"], cwd=self.repo, check=True)
        README = self.repo / repair.PACKET_ROOT / "README.md"
        README.write_text("# Packets\n\n## Workflow\n")
        active = self.repo / repair.PACKET_ROOT
        path = active / "LEGACY_COMPLETE.md"
        payload = "# Legacy\n\n- Status: `complete`\n- Completed: exact delivered behavior and focused validation.\n"
        path.write_bytes(payload.encode())
        ambiguous = active / "LEGACY_AMBIGUOUS.md"
        ambiguous.write_text("# Ambiguous\n\n- Status: `complete`\n")
        file_index = self.repo / "custodian/docs/ai_context/FILE_INDEX.md"
        file_index.parent.mkdir(parents=True, exist_ok=True)
        file_index.write_text(f"- `custodian/docs/ai_context/task_packets/{path.name}`\n")
        subprocess.run(["git", "add", "."], cwd=self.repo, check=True)
        subprocess.run(["git", "commit", "-m", "fixture"], cwd=self.repo, check=True, capture_output=True)

        plan = repair.legacy_archive_plan(self.repo)
        self.assertEqual([item["kind"] for item in plan], ["archive", "update_reference"])
        receipt = repair.legacy_archive_apply(self.repo)
        self.assertEqual(sum(item["kind"] == "archive" for item in receipt), 1)
        self.assertFalse(path.exists())
        self.assertEqual((active / "archived/LEGACY_COMPLETE.md").read_bytes(), payload.encode())
        self.assertTrue(ambiguous.exists())
        self.assertIn("archived/LEGACY_COMPLETE.md", README.read_text())
        self.assertIn("task_packets/archived/LEGACY_COMPLETE.md", file_index.read_text())
        self.assertEqual(repair.legacy_archive_plan(self.repo), [])


if __name__ == "__main__":
    unittest.main()
