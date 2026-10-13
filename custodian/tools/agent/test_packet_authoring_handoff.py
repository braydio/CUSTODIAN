"""Small, deterministic tests for opt-in packet publication boundaries."""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import BOUNDED_REVIEW_OVERRIDE, PACKET_ROOT
import packet_authoring_handoff as handoff


def implementation(marker="auto", status="draft", dispatch="manual"):
    return f"""# Implementation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `test-impl`
- Authoring handoff: `{marker}`
- Status: `{status}`
- Dispatch: `{dispatch}`
- Priority: `P1`
- Depends on: `none`
- Locks: `test-lock`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-test-impl`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `0123456789abcdef0123456789abcdef01234567`
- Goal: Demonstrate safe promotion.
- Completion boundary: Both packets become ready/auto.
- Current measured state: Draft pair is not claimable.
- Evidence: Focused unittest.
- Task-specific authority: Existing packet contract.
- Work surface: Script and test.
- Change: Run canonical validator.
- Preserve: Existing draft holds.
- Non-goals: No dispatch claim.
- Acceptance: Valid paired promotion only.
- Validation: Focused unit tests.
- Deferred: None.
"""


def review(marker="auto", status="draft", dispatch="manual"):
    return f"""# Review

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-test-impl`
- Authoring handoff: `{marker}`
- Kind: `review`
- Status: `{status}`
- Dispatch: `{dispatch}`
- Priority: `P1`
- Depends on: `test-impl`
- Locks: `test-lock`
- Review: `none`
- Review target workstream: `test-impl`
- Review target packet: `{PACKET_ROOT}/archived/TEST_IMPL.md`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Task overrides: `{BOUNDED_REVIEW_OVERRIDE}`
"""


class PacketHandoffTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        root = self.repo / PACKET_ROOT
        root.mkdir(parents=True)
        (root / "README.md").write_text("# Packets\n\n### Ready / Auto Dispatch\n")
        (root / "archived").mkdir()
        self.impl = root / "TEST_IMPL.md"
        self.rev = root / "REVIEW_TEST_IMPL.md"
        self.impl.write_text(implementation())
        self.rev.write_text(review())
        self.changed = [self.impl.relative_to(self.repo).as_posix(), self.rev.relative_to(self.repo).as_posix()]

    def tearDown(self):
        self.tmp.cleanup()

    def test_opted_in_pair_discovered_and_promoted(self):
        pairs = handoff.discover_pairs(self.repo, self.changed)
        self.assertEqual(pairs, [(self.impl, self.rev)])
        with patch.object(handoff, "validate_packet_validation_references", return_value={}):
            touched = handoff.promote(self.repo, pairs)
        self.assertEqual(len(touched), 3)
        self.assertIn("Status: `ready`", self.impl.read_text())
        self.assertIn("Dispatch: `auto`", self.rev.read_text())
        self.assertIn("`TEST_IMPL.md`", (self.impl.parent / "README.md").read_text())

    def test_marker_missing_on_review_never_promotes(self):
        self.rev.write_text(review(marker="manual"))
        with self.assertRaisesRegex(handoff.HandoffError, "both implementation and review"):
            handoff.discover_pairs(self.repo, self.changed)

    def test_untouched_non_opted_pair_not_affected(self):
        self.impl.write_text(implementation(marker="manual"))
        self.rev.write_text(review(marker="manual"))
        self.assertEqual(handoff.discover_pairs(self.repo, self.changed), [])

    def test_invalid_pair_reverts_all_files(self):
        self.rev.write_text(review().replace("different-agent", "made-up-agent"))
        old = {x: x.read_text() for x in [self.impl, self.rev, self.impl.parent / "README.md"]}
        with self.assertRaisesRegex(handoff.HandoffError, "preflight"):
            handoff.promote(self.repo, [(self.impl, self.rev)])
        for x, contents in old.items():
            self.assertEqual(x.read_text(), contents)

    def test_retry_scan_discovers_opted_pair_only(self):
        self.assertEqual(sorted(handoff.all_active_packets(self.repo)), sorted(self.changed))
        self.assertEqual(handoff.discover_pairs(self.repo, handoff.all_active_packets(self.repo)), [(self.impl, self.rev)])

    def test_ready_pair_is_idempotent(self):
        self.impl.write_text(implementation(status="ready", dispatch="auto"))
        self.rev.write_text(review(status="ready", dispatch="auto"))
        self.assertEqual(handoff.discover_pairs(self.repo, self.changed), [])

    def test_mixed_status_pair_is_rejected(self):
        self.impl.write_text(implementation(status="ready", dispatch="auto"))
        with self.assertRaisesRegex(handoff.HandoffError, "expected both"):
            handoff.discover_pairs(self.repo, self.changed)

    def test_unrelated_draft_not_touched(self):
        other = self.impl.parent / "OTHER.md"
        other.write_text(implementation(marker="manual").replace("test-impl", "other-impl"))
        with patch.object(handoff, "validate_packet_validation_references", return_value={}):
            handoff.promote(self.repo, handoff.discover_pairs(self.repo, self.changed))
        self.assertIn("Status: `draft`", other.read_text())


if __name__ == "__main__":
    unittest.main()