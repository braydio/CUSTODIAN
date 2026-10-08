"""Focused coverage for targeted task-packet authoring preflight."""

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("validate_task_packet_authoring.py")
SPEC = importlib.util.spec_from_file_location("custodian_task_packet_authoring_tests", SCRIPT)
preflight = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = preflight
SPEC.loader.exec_module(preflight)

from task_packet_contract import BOUNDED_REVIEW_OVERRIDE

PACKET_ROOT = preflight.PACKET_ROOT


def implementation(review_modes: str = "code, architecture, visual") -> str:
    return (
        "# Implementation\n\n"
        "- Packet schema: `custodian.task_packet.v2`\n"
        "- Workstream: `sample-work`\n"
        "- Status: `ready`\n"
        "- Dispatch: `auto`\n"
        "- Priority: `P1`\n"
        "- Depends on: `none`\n"
        "- Locks: `sample-lock`\n"
        "- Kind: `implementation`\n"
        "- Review: `auto`\n"
        "- Review stage: `post-land`\n"
        f"- Review modes: `{review_modes}`\n"
        "- Paired review workstream: `review-sample-work`\n"
        "- Review cycle: `0`\n"
        "- Max automatic review cycles: `2`\n"
    )


def review(include_target: bool = True, review_modes: str = "code, architecture, visual") -> str:
    rows = [
        "# Review",
        "",
        "- Packet schema: `custodian.task_packet.v2`",
        "- Workstream: `review-sample-work`",
        "- Kind: `review`",
        "- Status: `ready`",
        "- Dispatch: `auto`",
        "- Priority: `P1`",
        "- Depends on: `sample-work`",
        "- Locks: `sample-lock`",
        "- Review: `none`",
    ]
    if include_target:
        rows += [
            "- Review target workstream: `sample-work`",
            f"- Review target packet: `{PACKET_ROOT}/archived/SAMPLE_WORK.md`",
        ]
    rows += [
        "- Visual review: `conditional`",
        "- Reviewer context: `fresh`",
        "- Reviewer provenance: `different-agent`",
        f"- Review modes: `{review_modes}`",
        "- Review cycle: `0`",
        "- Max automatic review cycles: `2`",
        f"- Task overrides: `{BOUNDED_REVIEW_OVERRIDE}`",
    ]
    return "\n".join(rows) + "\n"


class AuthoringPreflightTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        self.root = self.repo / PACKET_ROOT
        self.root.mkdir(parents=True)
        self.impl = self.root / "SAMPLE_WORK.md"
        self.rev = self.root / "REVIEW_SAMPLE_WORK.md"
        self.impl.write_text(implementation())
        self.rev.write_text(review())

    def tearDown(self):
        self.temp.cleanup()

    def validate(self, *paths: Path) -> list[str]:
        return preflight.validate_authoring_paths(self.repo, list(paths))

    def test_valid_pair_passes(self):
        self.assertEqual(self.validate(self.impl, self.rev), [])

    def test_invalid_custom_review_mode_fails_with_allowed_modes(self):
        self.impl.write_text(implementation("code, architecture, visual-contract"))
        findings = self.validate(self.impl)
        joined = "\n".join(findings)
        self.assertIn("invalid Review modes metadata", joined)
        self.assertIn("allowed Review modes", joined)
        self.assertIn("visual", joined)

    def test_review_missing_target_metadata_fails(self):
        self.rev.write_text(review(include_target=False))
        findings = self.validate(self.rev)
        joined = "\n".join(findings)
        self.assertIn("Review target workstream", joined)
        self.assertIn("Review target packet", joined)

    def test_unrelated_malformed_packet_does_not_block_targeted_pair(self):
        unrelated = self.root / "UNRELATED.md"
        unrelated.write_text(
            implementation("code, made-up-mode").replace("sample-work", "unrelated-work")
        )
        self.assertEqual(self.validate(self.impl, self.rev), [])

    def test_implementation_only_still_checks_its_existing_pair(self):
        self.rev.write_text(review(include_target=False))
        findings = self.validate(self.impl)
        self.assertTrue(any("Review target workstream" in finding for finding in findings))


if __name__ == "__main__":
    unittest.main()
