#!/usr/bin/env python3
"""Focused anti-vacuity and determinism checks for process_feedback.py."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import process_feedback as ledger

RECEIPT = '''## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: a bounded issue
- Root cause / contributing factors: fixture cause
- Prevention / pipeline improvement: fixture prevention
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
'''


def packet(workstream: str, body: str) -> str:
    return f'''# Fixture packet
- Workstream: `{workstream}`
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: none
- Locks: agent-workflow
- Kind: implementation
- Review: none
- Authoring chat: n/a
- Visual review: none

## Execution Feedback
{body}
'''


class ProcessFeedbackTests(unittest.TestCase):
    def test_fenced_fake_section_does_not_count(self):
        section, fields = ledger.feedback_section('''# Summary
```md
## Process Feedback
- Outcome: blocked
```
## Next Handoff
- Outcome: partial
''')
        self.assertIsNone(section)
        self.assertEqual(fields, {})

    def test_backticks_and_legacy_omissions_are_reported(self):
        section, fields = ledger.feedback_section('''## Process Feedback
- Outcome: `partial`
- Follow-up: `manual-follow-up`
''')
        self.assertEqual(section, "Process Feedback")
        self.assertEqual(fields["Outcome"], "partial")
        self.assertEqual(ledger.classify_followup(fields["Follow-up"]), "unowned")
        self.assertNotIn("Friction severity", fields)

    def test_next_handoff_workstream_is_not_misread_as_summary_identity(self):
        self.assertIsNone(ledger.summary_workstream("# Summary\n\n## Next Handoff\n- Next workstream: `other-task`\n- Workstream: `other-task`\n"))

    def test_only_unique_identity_pair_is_deduplicated_and_unknown_owner_stays_unclassified(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            (repo / "TASK_CLAUDE_SUMMARY.md").write_text("# Summary\nWorkstream: example-task\n" + RECEIPT)
            packet_dir = repo / ledger.PACKET_ROOT / "archived"
            packet_dir.mkdir(parents=True)
            (packet_dir / "EXAMPLE.md").write_text(packet("example-task", RECEIPT.replace("## Process Feedback", "## Execution Feedback")))
            (repo / "UNKNOWN_CLAUDE_SUMMARY.md").write_text("# Legacy\n" + RECEIPT.replace("manual-follow-up", "unrecognized owner"))
            report = ledger.build_report(repo)
            self.assertEqual(report["metrics"]["mirror_pair_count"], 1)
            self.assertEqual(report["metrics"]["logical_receipt_count"], 2)
            unknown = next(x for x in report["sources"] if x["source"].startswith("UNKNOWN"))
            self.assertEqual(unknown["follow_up_class"], "unclassified")
            self.assertEqual(unknown["provenance"], "identity-unknown")
            self.assertEqual(report, ledger.build_report(repo))
            self.assertEqual(ledger.render_markdown(report), ledger.render_markdown(ledger.build_report(repo)))

    def test_duplicate_packet_candidates_are_not_guessed_as_mirrors(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            (repo / "TASK_CLAUDE_SUMMARY.md").write_text("# Summary\nWorkstream: example-task\n" + RECEIPT)
            packet_dir = repo / ledger.PACKET_ROOT / "archived"
            packet_dir.mkdir(parents=True)
            for name in ("A.md", "B.md"):
                (packet_dir / name).write_text(packet("example-task", RECEIPT.replace("## Process Feedback", "## Execution Feedback")))
            report = ledger.build_report(repo)
            self.assertEqual(report["mirrors"], [])
            self.assertEqual(report["metrics"]["ambiguous_identity_group_count"], 1)
            self.assertEqual(report["metrics"]["logical_receipt_count"], 3)

    def test_markdown_report_escapes_table_delimiters(self):
        report = {"metrics": {"source_count": 1, "summary_count": 1, "packet_count": 0,
                               "mirror_pair_count": 0, "ambiguous_identity_group_count": 0,
                               "unowned_medium_high": 0, "receipt_status": {"partial": 1}},
                  "sources": [{"source": "A.md", "workstream": None, "receipt_status": "partial",
                               "fields": {"Outcome": "success | partial"}, "follow_up_class": "missing"}]}
        self.assertIn("success \\| partial", ledger.render_markdown(report))


if __name__ == "__main__":
    unittest.main()
