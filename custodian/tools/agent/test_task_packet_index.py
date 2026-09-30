"""Focused temp-fixture coverage for the bounded Ready/Auto Dispatch indexer."""

import importlib.util
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

SCRIPT = Path(__file__).with_name("task_packet_index.py")
SPEC = importlib.util.spec_from_file_location("custodian_task_packet_index_tests", SCRIPT)
tpi = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = tpi
SPEC.loader.exec_module(tpi)

PACKET_ROOT = tpi.PACKET_ROOT


def ready_auto_packet(workstream_id: str, priority: str = "P2", goal: str = "Do the thing.") -> str:
    return (
        "# Packet\n\n"
        f"- Workstream: `{workstream_id}`\n"
        "- Status: `ready`\n"
        "- Dispatch: `auto`\n"
        f"- Priority: `{priority}`\n"
        "- Depends on: `none`\n"
        "- Locks: `none`\n"
        f"- Goal: {goal}\n"
    )


def manual_packet(workstream_id: str) -> str:
    return (
        "# Packet\n\n"
        f"- Workstream: `{workstream_id}`\n"
        "- Status: `ready`\n"
        "- Dispatch: `manual`\n"
        "- Priority: `P2`\n"
        "- Depends on: `none`\n"
        "- Locks: `none`\n"
        "- Goal: Manual work, never auto-indexed.\n"
    )


README_BASE = """# Agent Task Packets

Some preamble prose that must survive untouched.

## Active Packets

### Ready / Auto Dispatch

### In Progress

- `HAND_WRITTEN_IN_PROGRESS.md` — hand-maintained lifecycle note.

### Recently Complete (awaiting archive)

_None._
"""


class TaskPacketIndexTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        (self.repo / PACKET_ROOT).mkdir(parents=True, exist_ok=True)
        (self.repo / PACKET_ROOT / "README.md").write_text(README_BASE)

    def tearDown(self):
        self.temp.cleanup()

    def _write(self, filename: str, text: str) -> None:
        (self.repo / PACKET_ROOT / filename).write_text(text)

    def _readme_text(self) -> str:
        return (self.repo / PACKET_ROOT / "README.md").read_text()

    def test_goal_rendering_uses_shared_header_field_value(self):
        with patch.object(tpi, "header_field", return_value="Shared parser result") as shared:
            self.assertEqual(tpi._normalize_goal("- Goal: local duplicate would differ"), "Shared parser result")
        shared.assert_called_once_with("- Goal: local duplicate would differ", "Goal")

    def test_missing_entry_is_repaired_by_write(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work", goal="Ship alpha."))
        up_to_date, _ = tpi.check(self.repo)
        self.assertFalse(up_to_date)
        changed = tpi.write(self.repo)
        self.assertTrue(changed)
        self.assertIn("`ALPHA_WORK.md` — Ship alpha.", self._readme_text())
        up_to_date, diagnostic = tpi.check(self.repo)
        self.assertTrue(up_to_date, diagnostic)

    def test_stale_entry_is_removed_by_write(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        tpi.write(self.repo)
        self.assertIn("ALPHA_WORK.md", self._readme_text())
        (self.repo / PACKET_ROOT / "ALPHA_WORK.md").write_text(
            ready_auto_packet("alpha-work").replace("Status: `ready`", "Status: `complete`")
        )
        tpi.write(self.repo)
        self.assertNotIn("ALPHA_WORK.md", self._readme_text())

    def test_no_duplicate_entry_across_repeated_writes(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        tpi.write(self.repo)
        tpi.write(self.repo)
        self.assertEqual(self._readme_text().count("ALPHA_WORK.md"), 1)

    def test_manual_packet_is_excluded(self):
        self._write("MANUAL_WORK.md", manual_packet("manual-work"))
        tpi.write(self.repo)
        self.assertNotIn("MANUAL_WORK.md", self._readme_text())

    def test_deterministic_priority_then_path_ordering(self):
        self._write("ZEBRA_WORK.md", ready_auto_packet("zebra-work", priority="P1"))
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work", priority="P2"))
        self._write("BETA_WORK.md", ready_auto_packet("beta-work", priority="P1"))
        tpi.write(self.repo)
        text = self._readme_text()
        self.assertLess(text.index("BETA_WORK.md"), text.index("ZEBRA_WORK.md"))
        self.assertLess(text.index("ZEBRA_WORK.md"), text.index("ALPHA_WORK.md"))

    def test_malformed_packet_metadata_is_excluded_not_crashed_on(self):
        self._write("BAD_WORK.md", ready_auto_packet("Not Kebab"))
        self._write("GOOD_WORK.md", ready_auto_packet("good-work"))
        tpi.write(self.repo)
        text = self._readme_text()
        self.assertNotIn("BAD_WORK.md", text)
        self.assertIn("GOOD_WORK.md", text)

    def test_write_is_idempotent(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        first = tpi.write(self.repo)
        self.assertTrue(first)
        second = tpi.write(self.repo)
        self.assertFalse(second)

    def test_unmanaged_readme_content_is_byte_preserved(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        tpi.write(self.repo)
        text = self._readme_text()
        self.assertIn("Some preamble prose that must survive untouched.", text)
        self.assertIn("`HAND_WRITTEN_IN_PROGRESS.md` — hand-maintained lifecycle note.", text)
        self.assertIn("_None._", text)

    def test_check_reports_drift_when_markers_absent(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        up_to_date, diagnostic = tpi.check(self.repo)
        self.assertFalse(up_to_date)
        self.assertIn("managed Ready/Auto Dispatch block not found", diagnostic)

    def test_check_passes_after_write_with_no_further_changes(self):
        self._write("ALPHA_WORK.md", ready_auto_packet("alpha-work"))
        tpi.write(self.repo)
        up_to_date, diagnostic = tpi.check(self.repo)
        self.assertTrue(up_to_date, diagnostic)


if __name__ == "__main__":
    unittest.main()
