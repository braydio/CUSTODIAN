#!/usr/bin/env python3
"""Contract tests for the canonical paired-review outcome and accepted-review semantics."""
from __future__ import annotations

import unittest

import review_outcome as ro

MAIN = "a" * 40
IMPL = "b" * 40
RUN = "20261016T000000Z-0123456789ab"


def render(**overrides):
    values = dict(outcome="findings", review_workstream="review-x", target_workstream="x",
                  reviewed_main=MAIN, implementation_commit=IMPL, provenance="different-agent",
                  run_id=RUN, review_cycle=0, ids=("R0-01",))
    values.update(overrides)
    return ro.render_review_outcome(**values)


class ReviewOutcomeParserTests(unittest.TestCase):
    def test_round_trip_for_every_outcome(self):
        for outcome, ids in (("passed", ()), ("findings", ("R0-01", "R0-02")), ("human_required", ("R0-01",))):
            parsed, error = ro.parse_review_outcome("# P\n\n" + render(outcome=outcome, ids=ids))
            self.assertIsNone(error)
            self.assertEqual(parsed["Outcome"], outcome)
            self.assertEqual(ro.finding_ids(parsed), ids)

    def test_absent_section_is_not_an_error_but_defects_always_are(self):
        self.assertEqual(ro.parse_review_outcome("# P\n\n## Goal\nx\n"), (None, None))
        good = render()
        for label, text in {
            "duplicate section": good + "\n" + good,
            "unknown outcome": good.replace("`findings`", "`approved`"),
            "unknown schema": good.replace(ro.SCHEMA, "custodian.review_outcome.v0"),
            "short sha": good.replace(MAIN, "a" * 12),
            "bad run id": good.replace(RUN, "run-1"),
            "stale context": good.replace("Reviewer context: `fresh`", "Reviewer context: `reused`"),
            "bad provenance": good.replace("different-agent", "self"),
            "pass with findings ids": render(outcome="passed", ids=()).replace("`none`", "`R0-01`"),
            "findings with none": good.replace("`R0-01`", "`none`"),
            "id from wrong cycle": good.replace("R0-01", "R1-01"),
            "duplicate ids": render(ids=("R0-01", "R0-01")) if False else good.replace("`R0-01`", "`R0-01, R0-01`"),
            "extra content": good + "- Approved by: `me`\n",
            "missing field": good.replace("- Run ID: `" + RUN + "`\n", ""),
            "repeated field": good + "- Run ID: `" + RUN + "`\n",
            "prose line": good + "Looks fine to me.\n",
        }.items():
            parsed, error = ro.parse_review_outcome(text)
            self.assertIsNone(parsed, label)
            self.assertTrue(error, label)

    def test_render_refuses_non_canonical_input(self):
        with self.assertRaises(ValueError):
            render(outcome="findings", ids=())
        with self.assertRaises(ValueError):
            render(outcome="passed", ids=("R0-01",))

    def test_identity_binding_rejects_every_mismatch(self):
        parsed, _ = ro.parse_review_outcome(render())
        kwargs = dict(review_workstream="review-x", target_workstream="x", reviewed_main=MAIN,
                      implementation_commit=IMPL, run_id=RUN, review_cycle=0)
        self.assertIsNone(ro.outcome_identity_error(parsed, **kwargs))
        for field, value in (("review_workstream", "review-y"), ("target_workstream", "y"),
                             ("reviewed_main", "c" * 40), ("implementation_commit", "d" * 40),
                             ("run_id", "20261016T000001Z-0123456789ab"), ("review_cycle", 1)):
            self.assertTrue(ro.outcome_identity_error(parsed, **{**kwargs, field: value}), field)
        self.assertTrue(ro.outcome_identity_error(parsed, **{**kwargs, "implementation_commit": None}))


class FindingEvidenceTests(unittest.TestCase):
    def test_ids_match_whole_tokens_only(self):
        self.assertTrue(ro.finding_evidenced("**R0-01 - defect**", "R0-01"))
        self.assertTrue(ro.finding_evidenced("see R0-01, R0-02.", "R0-02"))
        self.assertFalse(ro.finding_evidenced("**R0-011 - defect**", "R0-01"))
        self.assertFalse(ro.finding_evidenced("prefixXR0-01", "R0-01"))
        self.assertFalse(ro.finding_evidenced("R0-01-extra", "R0-01"))
        self.assertFalse(ro.finding_evidenced("", "R0-01"))

    def test_a_crlf_section_is_read_as_the_same_outcome_not_as_absent(self):
        # A heading with a trailing CR must never be mistaken for "no outcome" (which would
        # fall through to the legacy pass path).
        parsed, error = ro.parse_review_outcome(render().replace("\n", "\r\n"))
        self.assertIsNone(error)
        self.assertEqual(parsed["Outcome"], "findings")
        crlf_findings = render().replace("\n", "\r\n")
        accepted, name, _ = ro.review_acceptance(
            crlf_findings, "## Independent Review\n\n- Status: `passed`\n", "review-x")
        self.assertFalse(accepted, "a CRLF findings outcome must not fall back to a legacy pass")
        self.assertEqual(name, "findings")


class AcceptedReviewTests(unittest.TestCase):
    RECEIPT = ("## Independent Review\n\n### Review Receipt: review-x\n- Status: `passed`\n"
               "- Blocking defects: `0`\n- Material gaps: `0`\n")

    def test_only_verified_pass_accepts(self):
        passed = render(outcome="passed", ids=())
        self.assertEqual(ro.review_acceptance(passed, self.RECEIPT, "review-x")[0], True)
        for outcome in ("findings", "human_required"):
            accepted, name, _ = ro.review_acceptance(render(outcome=outcome), self.RECEIPT, "review-x")
            self.assertFalse(accepted)
            self.assertEqual(name, outcome)

    def test_pass_without_canonical_target_receipt_or_with_wrong_review_is_rejected(self):
        passed = render(outcome="passed", ids=())
        self.assertFalse(ro.review_acceptance(passed, None, "review-x")[0])
        self.assertFalse(ro.review_acceptance(passed, "# target\n", "review-x")[0])
        self.assertFalse(ro.review_acceptance(passed, self.RECEIPT, "review-other")[0])
        duplicated = self.RECEIPT + "\n" + self.RECEIPT.split("\n\n", 1)[1]
        self.assertFalse(ro.review_acceptance(passed, duplicated, "review-x")[0])
        self.assertFalse(ro.review_acceptance(passed, self.RECEIPT.replace("Blocking defects: `0`", "Blocking defects: `1`"),
                                              "review-x")[0])

    def test_legacy_reviews_accept_only_an_unambiguous_pass(self):
        accepts = lambda target: ro.review_acceptance("# legacy review\n", target, "review-x")[0]
        self.assertTrue(accepts("## Independent Review\n\n- Status: `passed`\n"))
        self.assertTrue(accepts("## Independent Review\n\n- Status: `pass`\n"))
        self.assertTrue(accepts(self.RECEIPT))
        self.assertFalse(accepts(None))
        self.assertFalse(accepts("# no receipt\n"))
        self.assertFalse(accepts("## Independent Review\n\n- Status: `findings`\n"))
        self.assertFalse(accepts("## Independent Review\n\n- Status: `passed`\n- Status: `human_required`\n"))
        self.assertFalse(accepts("## Independent Review\n\n- Status: `passed`\n\n## Independent Review\n\n- Status: `passed`\n"))

    def test_verified_duplicate_legacy_vehicle_review(self):
        # A real archived case: two consistent PASS summaries for the same
        # pinned implementation. Do not require a new independent review merely
        # because the historical author repeated its heading.
        from pathlib import Path
        root = Path(__file__).resolve().parents[3]
        packet_dir = root / "custodian/docs/ai_context/task_packets/archived"
        target = (packet_dir / "VEHICLE_WRECK_RESTORATION_FOUNDATION_V1_REVIEW_CORRECTIONS_1.md").read_text()
        review = (packet_dir / "REVIEW_VEHICLE_WRECK_RESTORATION_FOUNDATION_V1_REVIEW_CORRECTIONS_1.md").read_text()
        workstream = "review-vehicle-wreck-restoration-foundation-v1-review-corrections-1"
        accepted, _outcome, reason = ro.review_acceptance(review, target, workstream)
        self.assertTrue(accepted, reason)

        # Red-team every material contradiction; two sections cannot launder a
        # failing review, absent provenance, mismatched target, or extra review.
        tampered = {
            "first nonpass": target.replace("- Status: `passed`", "- Status: `findings`", 1),
            "second nonpass": target.rsplit("- Status: `passed`", 1)[0] +
                "- Status: `human_required`" + target.rsplit("- Status: `passed`", 1)[1],
            "wrong review": target.replace(
                "- Review workstream: `" + workstream + "`",
                "- Review workstream: `review-unrelated`"),
            "wrong main": target.replace("Reviewed on main: `e56a75cfb`",
                                         "Reviewed on main: `deadbeef0`"),
            "blocking defect": target.replace("- Blocking defects: `0`",
                                               "- Blocking defects: `1`"),
            "material gap": target.replace("- Material evidence gaps: `0`",
                                            "- Material evidence gaps: `1`"),
            "missing provenance": target.replace("- Reviewer provenance: `different-agent`", ""),
            "stale context": target.replace("- Reviewer context: `fresh`",
                                            "- Reviewer context: `reused`"),
            "three summaries": target + "\n## Independent Review\n\n- Status: `passed`\n",
        }
        for label, altered in tampered.items():
            accepted, _outcome, _reason = ro.review_acceptance(review, altered, workstream)
            self.assertFalse(accepted, label)
        for label, altered_review in {
            "separate review not passed": review.replace("- Status: `passed`",
                                                         "- Status: `findings`", 1),
            "separate review different commit": review.replace("a5df0bb65", "deadbeef0"),
            "separate review different main": review.replace("e56a75cfb", "deadbeef0"),
        }.items():
            self.assertFalse(ro.review_acceptance(altered_review, target, workstream)[0], label)

    def test_malformed_outcome_never_falls_back_to_a_legacy_pass(self):
        broken = render(outcome="findings").replace("Finding IDs: `R0-01`", "Finding IDs: `none`")
        accepted, name, reason = ro.review_acceptance(
            broken, "## Independent Review\n\n- Status: `passed`\n", "review-x")
        self.assertFalse(accepted)
        self.assertIn("malformed", reason)


class CorrectionLineageTests(unittest.TestCase):
    def setUp(self):
        self.outcome, _ = ro.parse_review_outcome(render())

    _DEFAULT = object()

    def check(self, name="x-review-corrections-1", text="- Findings addressed: `R0-01`\n", review="review-x",
              outcome=_DEFAULT):
        return ro.correction_lineage_error(name, text, review, self.outcome if outcome is self._DEFAULT else outcome)

    def test_linked_correction_is_allowed(self):
        self.assertIsNone(self.check())

    def test_every_lineage_violation_is_rejected(self):
        self.assertTrue(self.check(name="x-review-corrections-2"))
        self.assertTrue(self.check(name="y-review-corrections-1"))
        self.assertTrue(self.check(text="- Findings addressed: `R0-02`\n"))
        self.assertTrue(self.check(text="- nothing\n"))
        self.assertTrue(self.check(review="review-y"))
        self.assertTrue(self.check(outcome=None))
        human, _ = ro.parse_review_outcome(render(outcome="human_required"))
        self.assertTrue(self.check(outcome=human))
        passed, _ = ro.parse_review_outcome(render(outcome="passed", ids=()))
        self.assertTrue(self.check(outcome=passed))

    def test_second_cycle_lineage_uses_the_root_and_next_number(self):
        parsed, _ = ro.parse_review_outcome(render(
            review_workstream="review-x-review-corrections-1", target_workstream="x-review-corrections-1",
            review_cycle=1, ids=("R1-01",)))
        self.assertIsNone(self.check(name="x-review-corrections-2", text="- Findings addressed: `R1-01`\n",
                                     review="review-x-review-corrections-1", outcome=parsed))
        self.assertTrue(self.check(name="x-review-corrections-1", text="- Findings addressed: `R1-01`\n",
                                   review="review-x-review-corrections-1", outcome=parsed))


if __name__ == "__main__":
    unittest.main()
