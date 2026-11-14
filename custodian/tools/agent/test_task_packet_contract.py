"""Direct unit coverage for the shared task-packet grammar/validation module.

dispatch.py's own test suite (test_dispatch.py) proves behavioral parity of
the dispatcher after this module was extracted from it. This file covers
task_packet_contract.py's public surface directly, including the pieces
(Completion Truth parsing, V2 structural fields) that check_ai_context.py
and workstream.py's finish-gate also depend on.
"""

import importlib.util
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("task_packet_contract.py")
SPEC = importlib.util.spec_from_file_location("custodian_task_packet_contract_tests", SCRIPT)
tpc = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = tpc
SPEC.loader.exec_module(tpc)


def legacy_packet(workstream_id: str, status: str = "ready", dispatch: str = "auto", extra: str = "") -> str:
    return (
        "# Legacy Packet\n\n"
        f"- Workstream: `{workstream_id}`\n"
        f"- Status: `{status}`\n"
        f"- Dispatch: `{dispatch}`\n"
        "- Priority: `P2`\n"
        "- Depends on: `none`\n"
        "- Locks: `none`\n"
        f"{extra}"
    )


def v2_packet(workstream_id: str, kind: str = "implementation", status: str = "complete", extra: str = "") -> str:
    return (
        "# V2 Packet\n\n"
        "- Packet schema: `custodian.task_packet.v2`\n"
        f"- Workstream: `{workstream_id}`\n"
        f"- Status: `{status}`\n"
        "- Dispatch: `manual`\n"
        "- Priority: `P2`\n"
        "- Depends on: `none`\n"
        "- Locks: `none`\n"
        f"- Kind: `{kind}`\n"
        "- Review: `none`\n"
        f"{extra}"
    )


class ParsePacketTests(unittest.TestCase):
    def test_minimal_legacy_packet_parses_clean(self):
        packet = tpc.parse_packet("p.md", legacy_packet("sample-work"))
        self.assertIsNone(packet.error)
        self.assertEqual(packet.workstream, "sample-work")
        self.assertEqual(packet.status, "ready")
        self.assertEqual(packet.dispatch, "auto")
        self.assertEqual(packet.kind, "implementation")
        self.assertEqual(packet.review, "none")
        self.assertIsNone(packet.schema)

    def test_v2_packet_reports_schema_and_kind(self):
        packet = tpc.parse_packet("p.md", v2_packet("v2-work", kind="correction"))
        self.assertIsNone(packet.error)
        self.assertEqual(packet.schema, "custodian.task_packet.v2")
        self.assertEqual(packet.kind, "correction")
        self.assertTrue(tpc.is_v2_packet(packet))

    def test_invalid_workstream_id_is_reported(self):
        packet = tpc.parse_packet("p.md", legacy_packet("Not Kebab"))
        self.assertIsNotNone(packet.error)
        self.assertIn("Workstream", packet.error)

    def test_authoring_and_refresh_chat_metadata_parse(self):
        text = (
            legacy_packet("chat-work")
            + "- Authoring chat: `https://chatgpt.com/c/example-authoring`\n"
            + "- Refresh planning chat: `https://chatgpt.com/c/example-refresh`\n"
        )
        packet = tpc.parse_packet("p.md", text)
        self.assertEqual(packet.authoring_chat, "https://chatgpt.com/c/example-authoring")
        self.assertEqual(packet.refresh_planning_chat, "https://chatgpt.com/c/example-refresh")

    def test_visual_review_metadata_defaults_none_and_validates(self):
        packet = tpc.parse_packet("p.md", legacy_packet("no-visual"))
        self.assertEqual(packet.visual_review, "none")
        required = tpc.parse_packet(
            "p.md",
            legacy_packet("visual-required") + "- Visual review: `required`\n",
        )
        self.assertIsNone(required.error)
        self.assertEqual(required.visual_review, "required")
        invalid = tpc.parse_packet(
            "p.md",
            legacy_packet("visual-invalid") + "- Visual review: `sometimes`\n",
        )
        self.assertIsNotNone(invalid.error)
        self.assertIn("Visual review", invalid.error)

    def test_duplicate_field_is_reported(self):
        text = legacy_packet("dup-work") + "- Status: `blocked`\n"
        packet = tpc.parse_packet("p.md", text)
        self.assertIsNotNone(packet.error)
        self.assertIn("duplicate", packet.error)

    def test_depends_on_and_locks_split_on_comma(self):
        text = legacy_packet("multi-dep", extra="")
        text = text.replace("- Depends on: `none`", "- Depends on: `a-b, c-d`")
        text = text.replace("- Locks: `none`", "- Locks: `lock-one, lock-two`")
        packet = tpc.parse_packet("p.md", text)
        self.assertIsNone(packet.error)
        self.assertEqual(packet.dependencies, ("a-b", "c-d"))
        self.assertEqual(packet.locks, ("lock-one", "lock-two"))

    def test_review_auto_requires_paired_review_workstream(self):
        text = legacy_packet("needs-pair") + "- Review: `auto`\n"
        packet = tpc.parse_packet("p.md", text)
        self.assertIsNotNone(packet.error)
        self.assertIn("Paired review workstream", packet.error)


class QueueContractTests(unittest.TestCase):
    def test_rejects_v2_draft_auto_but_preserves_legacy_and_archived_history(self):
        active = tpc.parse_packet("draft.md", v2_packet("draft-auto", status="draft").replace("Dispatch: `manual`", "Dispatch: `auto`"))
        legacy = tpc.parse_packet("legacy.md", legacy_packet("legacy-draft", status="draft", dispatch="auto"))
        archived = tpc.parse_packet("old.md", v2_packet("old-draft", status="draft").replace("Dispatch: `manual`", "Dispatch: `auto`"))
        errors = tpc.validate_queue_contract([active, legacy], [archived])
        self.assertIn("draft/auto", errors["draft-auto"])
        self.assertNotIn("legacy-draft", errors)
        self.assertNotIn("old-draft", errors)

    def test_missing_dependency_identity_and_duplicate_workstream_are_reported(self):
        first = tpc.parse_packet("one.md", legacy_packet("duplicate-id").replace("Depends on: `none`", "Depends on: `missing-id`"))
        second = tpc.parse_packet("two.md", legacy_packet("duplicate-id"))
        errors = tpc.validate_queue_contract([first, second])
        self.assertIn("duplicate Workstream identity", errors["duplicate-id"])
        self.assertIn("missing dependency identity: missing-id", errors["duplicate-id"])

    def test_draft_manual_requires_concrete_park_reason(self):
        draft = tpc.parse_packet("parked.md", v2_packet("parked", status="draft"))
        self.assertIn("concrete refresh or human-decision reason", tpc.validate_queue_contract(
            [draft], texts={"parked.md": "# Parked\n"})["parked"])
        self.assertEqual(tpc.validate_queue_contract(
            [draft], texts={"parked.md": "# Parked\n\nRefresh required after user decision.\n"}), {})


class ReviewPairingTests(unittest.TestCase):
    def test_draft_manual_pair_is_parked_but_does_not_break_global_pairing(self):
        impl_text = (
            legacy_packet("parked-impl", status="draft", dispatch="manual")
            + "- Review: `auto`\n"
            + "- Paired review workstream: `review-parked-impl`\n"
        )
        review_text = (
            "# Review Packet\n\n"
            "- Workstream: `review-parked-impl`\n"
            "- Status: `draft`\n"
            "- Dispatch: `manual`\n"
            "- Priority: `P2`\n"
            "- Depends on: `parked-impl`\n"
            "- Locks: `none`\n"
            "- Kind: `review`\n"
            "- Review: `none`\n"
            "- Review target workstream: `parked-impl`\n"
            f"- Review target packet: `{tpc.PACKET_ROOT}/archived/PARKED_IMPL.md`\n"
            f"- Task overrides: `{tpc.BOUNDED_REVIEW_OVERRIDE}`\n"
        )
        def parse_impl(txt):
            return tpc.parse_packet(f"{tpc.PACKET_ROOT}/PARKED_IMPL.md", txt)
        review = tpc.parse_packet(f"{tpc.PACKET_ROOT}/REVIEW_PARKED_IMPL.md", review_text)
        parked = parse_impl(impl_text)
        self.assertEqual(tpc.validate_review_pairing([parked, review]), {})
        # A ready implementation may never hide behind a parked review.
        ready = parse_impl(impl_text.replace("- Status: `draft`", "- Status: `ready`")
                                   .replace("- Dispatch: `manual`", "- Dispatch: `auto`"))
        errors = tpc.validate_review_pairing([ready, review])
        self.assertIn("must declare Status: ready", errors["parked-impl"])
        self.assertIn("must declare Dispatch: auto", errors["parked-impl"])
        # An explicitly blocked/manual implementation also needs a
        # ready/auto or blocked/manual paired reviewer, not a draft.
        blocked = parse_impl(impl_text.replace("- Status: `draft`", "- Status: `blocked`"))
        errors = tpc.validate_review_pairing([blocked, review])
        self.assertIn("must be ready/auto or blocked/manual", errors["parked-impl"])

    def test_correctly_paired_auto_review_has_no_errors(self):
        impl_text = (
            legacy_packet("impl-work")
            + "- Review: `auto`\n"
            + "- Paired review workstream: `review-impl-work`\n"
        )
        review_text = (
            "# Review Packet\n\n"
            "- Workstream: `review-impl-work`\n"
            "- Status: `ready`\n"
            "- Dispatch: `auto`\n"
            "- Priority: `P2`\n"
            "- Depends on: `impl-work`\n"
            "- Locks: `none`\n"
            "- Kind: `review`\n"
            "- Review: `none`\n"
            "- Review target workstream: `impl-work`\n"
            f"- Review target packet: `{tpc.PACKET_ROOT}/archived/IMPL_WORK.md`\n"
            f"- Task overrides: `{tpc.BOUNDED_REVIEW_OVERRIDE}`\n"
        )
        impl = tpc.parse_packet(f"{tpc.PACKET_ROOT}/IMPL_WORK.md", impl_text)
        review = tpc.parse_packet(f"{tpc.PACKET_ROOT}/REVIEW_IMPL_WORK.md", review_text)
        errors = tpc.validate_review_pairing([impl, review])
        self.assertEqual(errors, {})

    def test_blocked_manual_implementation_can_keep_review_blocked_manual(self):
        impl_text = (
            legacy_packet("gated-work", status="blocked", dispatch="manual")
            + "- Review: `auto`\n"
            + "- Paired review workstream: `review-gated-work`\n"
        )
        review_text = (
            "# Review Packet\n\n"
            "- Workstream: `review-gated-work`\n"
            "- Status: `blocked`\n"
            "- Dispatch: `manual`\n"
            "- Priority: `P2`\n"
            "- Depends on: `gated-work`\n"
            "- Locks: `none`\n"
            "- Kind: `review`\n"
            "- Review: `none`\n"
            "- Review target workstream: `gated-work`\n"
            f"- Review target packet: `{tpc.PACKET_ROOT}/archived/GATED_WORK.md`\n"
            f"- Task overrides: `{tpc.BOUNDED_REVIEW_OVERRIDE}`\n"
        )
        impl = tpc.parse_packet(f"{tpc.PACKET_ROOT}/GATED_WORK.md", impl_text)
        review = tpc.parse_packet(f"{tpc.PACKET_ROOT}/REVIEW_GATED_WORK.md", review_text)
        self.assertEqual(tpc.validate_review_pairing([impl, review]), {})

    def test_missing_paired_review_is_reported(self):
        impl_text = (
            legacy_packet("orphan-work")
            + "- Review: `auto`\n"
            + "- Paired review workstream: `review-orphan-work`\n"
        )
        impl = tpc.parse_packet(f"{tpc.PACKET_ROOT}/ORPHAN_WORK.md", impl_text)
        errors = tpc.validate_review_pairing([impl])
        self.assertIn("orphan-work", errors)
        self.assertIn("no matching active packet", errors["orphan-work"])

    def test_auto_review_without_bounded_override_is_reported(self):
        review_text = (
            "# Review Packet\n\n"
            "- Workstream: `review-bad`\n"
            "- Status: `ready`\n"
            "- Dispatch: `auto`\n"
            "- Priority: `P2`\n"
            "- Depends on: `none`\n"
            "- Locks: `none`\n"
            "- Kind: `review`\n"
            "- Review: `none`\n"
        )
        review = tpc.parse_packet(f"{tpc.PACKET_ROOT}/REVIEW_BAD.md", review_text)
        errors = tpc.validate_review_pairing([review])
        self.assertIn("review-bad", errors)
        self.assertIn("TASK OVERRIDE", errors["review-bad"])


class ReviewCycleTests(unittest.TestCase):
    def test_review_cycle_exhausted_at_cap(self):
        packet = tpc.parse_packet("p.md", legacy_packet("cycled") + "- Review cycle: `2`\n- Max automatic review cycles: `2`\n")
        self.assertTrue(tpc.review_cycle_exhausted(packet))

    def test_review_cycle_not_exhausted_below_cap(self):
        packet = tpc.parse_packet("p.md", legacy_packet("cycled") + "- Review cycle: `1`\n- Max automatic review cycles: `2`\n")
        self.assertFalse(tpc.review_cycle_exhausted(packet))


class V2RequiredFieldTests(unittest.TestCase):
    def test_v2_required_field_values_reads_populated_fields(self):
        text = v2_packet("v2-fields")
        text = text.replace("- Kind: `implementation`\n", "- Kind: `implementation`\n- Goal: Do the thing.\n")
        values = tpc.v2_required_field_values(text)
        self.assertEqual(values["Goal"], "Do the thing.")
        self.assertIsNone(values["Completion boundary"])

    def test_field_with_continuation_lines_is_folded(self):
        text = (
            "# P\n\n"
            "- Goal: First line\n"
            "  continues here\n"
            "- Status: `ready`\n"
        )
        self.assertEqual(tpc._header_field_with_continuations(text, "Goal"), "First line continues here")


class ValidationReferenceTests(unittest.TestCase):
    def test_validation_references_preserve_supported_spellings(self):
        text = (
            "# Packet\n\n- Workstream: `paths`\n- Status: `ready`\n"
            "## Validation\n\n"
            "Run `custodian/tools/a.py`, `res://tools/b.gd`, and `tools/c.sh`.\n"
        )
        self.assertEqual(
            tpc._validation_script_references(text),
            ("custodian/tools/a.py", "res://tools/b.gd", "tools/c.sh"),
        )

    def test_validation_reference_candidates_are_confined_to_supported_roots(self):
        self.assertEqual(tpc._validation_reference_candidates("custodian/tools/a.py"), ("custodian/tools/a.py",))
        self.assertEqual(tpc._validation_reference_candidates("res://tools/a.py"), ("custodian/tools/a.py",))
        self.assertEqual(tpc._validation_reference_candidates("tools/a.py"), ("tools/a.py", "custodian/tools/a.py"))
        self.assertEqual(tpc._validation_reference_candidates("res://addons/a.py"), ())


class CompletionTruthTests(unittest.TestCase):
    def test_missing_section_returns_none(self):
        self.assertIsNone(tpc.parse_completion_truth(v2_packet("no-truth")))

    def test_truthful_all_yes_receipt_parses_clean(self):
        extra = (
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `yes`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Superseded/legacy production path disposition: `removed`\n"
            "- Evidence: tests pass, old path deleted\n"
        )
        truth = tpc.parse_completion_truth(v2_packet("truthful") + extra)
        self.assertIsNotNone(truth)
        self.assertIsNone(truth.error)
        self.assertTrue(truth.all_yes)

    def test_any_no_is_not_all_yes_but_parses_without_error(self):
        extra = (
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `no`\n"
            "- Acceptance satisfied: `yes`\n"
            "- Superseded/legacy production path disposition: `n/a`\n"
            "- Evidence: boundary not fully closed, see Deferred\n"
        )
        truth = tpc.parse_completion_truth(v2_packet("honest-partial") + extra)
        self.assertIsNotNone(truth)
        self.assertIsNone(truth.error)
        self.assertFalse(truth.all_yes)

    def test_missing_evidence_is_an_error(self):
        extra = (
            "\n## Completion Truth\n\n"
            "- Completion schema: `custodian.task_completion.v1`\n"
            "- Goal satisfied: `yes`\n"
            "- Completion boundary satisfied: `yes`\n"
            "- Acceptance satisfied: `yes`\n"
        )
        truth = tpc.parse_completion_truth(v2_packet("no-evidence") + extra)
        self.assertIsNotNone(truth)
        self.assertIsNotNone(truth.error)
        self.assertFalse(truth.all_yes)

    def test_completion_truth_required_for_implementation_and_correction_not_review(self):
        implementation = tpc.parse_packet("p.md", v2_packet("impl-kind", kind="implementation"))
        correction = tpc.parse_packet("p.md", v2_packet("corr-kind", kind="correction"))
        review = tpc.parse_packet("p.md", v2_packet("review-kind", kind="review"))
        legacy = tpc.parse_packet("p.md", legacy_packet("legacy-kind"))
        self.assertTrue(tpc.completion_truth_required(implementation))
        self.assertTrue(tpc.completion_truth_required(correction))
        self.assertFalse(tpc.completion_truth_required(review))
        self.assertFalse(tpc.completion_truth_required(legacy))


if __name__ == "__main__":
    unittest.main()
