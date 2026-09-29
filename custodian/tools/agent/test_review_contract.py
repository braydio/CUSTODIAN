"""Structural fixtures for V2 review findings and correction deltas."""
import unittest
from pathlib import Path

try:
    from . import dispatch
    from .review_contract import (
        CORRECTION_FIELDS, FINDING_CLASSES, FINDING_DISPOSITIONS,
        validate_correction_delta, validate_finding_record,
    )
except ImportError:
    import dispatch
    from review_contract import (
        CORRECTION_FIELDS, FINDING_CLASSES, FINDING_DISPOSITIONS,
        validate_correction_delta, validate_finding_record,
    )


class ReviewContractTests(unittest.TestCase):
    def test_authoring_templates_match_structural_contract(self):
        root = Path(__file__).resolve().parents[3]
        review_template = (root / "custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md").read_text()
        correction_template = (root / "custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md").read_text()
        self.assertIn(dispatch.BOUNDED_REVIEW_OVERRIDE, review_template)
        for field in ("Reviewed main", "Reviewed implementation acceptance", "Review evidence", "Correction threshold", "Focused validation"):
            self.assertIn(f"- {field}:", review_template)
        for field in CORRECTION_FIELDS:
            self.assertIn(f"- {field}:", correction_template)
        for finding_class in FINDING_CLASSES:
            self.assertIn(finding_class, review_template)
        for disposition in FINDING_DISPOSITIONS:
            self.assertIn(disposition, review_template)

    def test_each_finding_class_and_disposition_is_structurally_supported(self):
        for index, finding_class in enumerate(sorted(FINDING_CLASSES), start=1):
            disposition = sorted(FINDING_DISPOSITIONS)[(index - 1) % len(FINDING_DISPOSITIONS)]
            record = {
                "ID": f"R0-{index:02d}",
                "Class": finding_class,
                "Domain": "implementation",
                "Acceptance affected": "acceptance claim A",
                "Evidence": "fixture evidence reference",
                "Disposition": disposition,
                "Rationale": "fixture rationale",
            }
            self.assertEqual(validate_finding_record(record), [])

    def test_malformed_finding_id_and_disposition_are_rejected(self):
        record = {
            "ID": "R00-1",
            "Class": "blocking_defect",
            "Domain": "implementation",
            "Acceptance affected": "A1",
            "Evidence": "test evidence",
            "Disposition": "fix_something",
            "Rationale": "fixture",
        }
        errors = validate_finding_record(record)
        self.assertTrue(any("malformed finding ID" in error for error in errors))
        self.assertTrue(any("invalid finding disposition" in error for error in errors))

    def test_correction_delta_requires_parentage_and_finding_ids(self):
        fields = {field: "fixture evidence" for field in CORRECTION_FIELDS}
        fields["Findings addressed"] = "R0-02, R1-01"
        self.assertEqual(validate_correction_delta(fields), [])
        fields["Findings addressed"] = ""
        errors = validate_correction_delta(fields)
        self.assertTrue(any("at least one finding ID" in error for error in errors))

    def test_correction_delta_rejects_malformed_ids(self):
        fields = {field: "fixture evidence" for field in CORRECTION_FIELDS}
        fields["Findings addressed"] = "R0-01, R00-2"
        self.assertIn("malformed correction finding ID: R00-2", validate_correction_delta(fields))


if __name__ == "__main__":
    unittest.main()
