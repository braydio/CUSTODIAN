"""Small, deterministic tests for opt-in packet publication boundaries.

Paired review was retired 2026-11-12: the handoff promotes single
implementation/correction packets, never a pair, and a review packet can
never be opted in.
"""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import PACKET_ROOT
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
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Focused validation proves this packet; paired review retired 2026-11-12.`
- Reviewed main: `0123456789abcdef0123456789abcdef01234567`
- Goal: Demonstrate safe promotion.
- Completion boundary: The packet becomes ready/auto.
- Current measured state: Draft packet is not claimable.
- Evidence: Focused unittest.
- Task-specific authority: Existing packet contract.
- Work surface: Script and test.
- Change: Run canonical validator.
- Preserve: Existing draft holds.
- Non-goals: No dispatch claim.
- Acceptance: Valid single-packet promotion only.
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
"""


class PacketHandoffTests(unittest.TestCase):
    def test_promotion_commit_skips_unrelated_render_deploy(self):
        self.assertIn("[skip render]", handoff.PROMOTION_COMMIT_MESSAGE)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        root = self.repo / PACKET_ROOT
        root.mkdir(parents=True)
        (root / "README.md").write_text("# Packets\n\n### Ready / Auto Dispatch\n")
        (root / "archived").mkdir()
        self.impl = root / "TEST_IMPL.md"
        self.impl.write_text(implementation())
        self.changed = [self.impl.relative_to(self.repo).as_posix()]

    def tearDown(self):
        self.tmp.cleanup()

    def test_opted_in_packet_discovered_and_promoted(self):
        promotions = handoff.discover_promotions(self.repo, self.changed)
        self.assertEqual(promotions, [self.impl])
        with patch.object(handoff, "validate_packet_validation_references", return_value={}):
            touched = handoff.promote(self.repo, promotions)
        self.assertEqual(len(touched), 2)
        self.assertIn("Status: `ready`", self.impl.read_text())
        self.assertIn("Dispatch: `auto`", self.impl.read_text())
        self.assertIn("`TEST_IMPL.md`", (self.impl.parent / "README.md").read_text())

    def test_review_packet_opt_in_is_rejected(self):
        rev = self.impl.parent / "REVIEW_TEST_IMPL.md"
        rev.write_text(review())
        with self.assertRaisesRegex(handoff.HandoffError, "review packets are retired"):
            handoff.discover_promotions(self.repo, [rev.relative_to(self.repo).as_posix()])

    def test_untouched_non_opted_packet_not_affected(self):
        self.impl.write_text(implementation(marker="manual"))
        self.assertEqual(handoff.discover_promotions(self.repo, self.changed), [])

    def test_invalid_packet_reverts_all_files(self):
        self.impl.write_text(implementation().replace("- Goal: Demonstrate safe promotion.", "- Missing goal: Demonstrate safe promotion."))
        old = {x: x.read_text() for x in [self.impl, self.impl.parent / "README.md"]}
        with self.assertRaisesRegex(handoff.HandoffError, "preflight"):
            handoff.promote(self.repo, [self.impl])
        for x, contents in old.items():
            self.assertEqual(x.read_text(), contents)

    def test_retry_scan_discovers_opted_packet_only(self):
        self.assertEqual(sorted(handoff.all_active_packets(self.repo)), sorted(self.changed))
        self.assertEqual(handoff.discover_promotions(self.repo, handoff.all_active_packets(self.repo)), [self.impl])

    def test_ready_packet_is_idempotent(self):
        self.impl.write_text(implementation(status="ready", dispatch="auto"))
        self.assertEqual(handoff.discover_promotions(self.repo, self.changed), [])

    def test_mixed_status_packet_is_rejected(self):
        self.impl.write_text(implementation(status="ready", dispatch="manual"))
        with self.assertRaisesRegex(handoff.HandoffError, "expected draft/manual or ready/auto"):
            handoff.discover_promotions(self.repo, self.changed)

    def test_unrelated_draft_not_touched(self):
        other = self.impl.parent / "OTHER.md"
        other.write_text(implementation(marker="manual").replace("test-impl", "other-impl"))
        with patch.object(handoff, "validate_packet_validation_references", return_value={}):
            handoff.promote(self.repo, handoff.discover_promotions(self.repo, self.changed))
        self.assertIn("Status: `draft`", other.read_text())


if __name__ == "__main__":
    unittest.main()
