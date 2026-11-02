"""Focused temp-fixture coverage for the read-only AI-context validator.

check_ai_context.py operates purely on filesystem state (no git plumbing
inside run_checks), so fixtures are plain directory trees rather than git
repos.
"""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_ai_context.py")
SPEC = importlib.util.spec_from_file_location("custodian_check_ai_context_tests", SCRIPT)
cac = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = cac
SPEC.loader.exec_module(cac)

PACKET_ROOT = cac.PACKET_ROOT


def _v2_implementation_packet(workstream_id: str, status: str = "ready", placeholder: bool = False) -> str:
    goal_value = "<lowercase-kebab-id>" if placeholder else "Do the specific thing."
    lines = [
        "# Sample V2 Implementation Packet",
        "",
        "- Packet schema: `custodian.task_packet.v2`",
        f"- Workstream: `{workstream_id}`",
        f"- Status: `{status}`",
        "- Dispatch: `auto`",
        "- Priority: `P2`",
        "- Depends on: `none`",
        "- Locks: `none`",
        "- Kind: `implementation`",
        "- Review: `none`",
        "- Reviewed main: `abc1234`",
        f"- Goal: {goal_value}",
        "- Completion boundary: Exact closure line.",
        "- Current measured state: Live facts as observed.",
        "- Evidence: file.gd:12, test_foo.py",
        "- Task-specific authority: design/example/AUTHORITY.md",
        "- Work surface: owner module plus consumer tests.",
        "- Change: Implement the narrow behavior change.",
        "- Preserve: adjacent behavior X.",
        "- Non-goals: unrelated system Y.",
        "- Acceptance: measurable falsifiable claim.",
        "- Validation: tools/example_smoke.py",
        "- Task overrides: `none`",
        "- Deferred: follow-up Z.",
        "",
    ]
    if status == "complete":
        lines += [
            "## Completion Truth",
            "",
            "- Completion schema: `custodian.task_completion.v1`",
            "- Goal satisfied: `yes`",
            "- Completion boundary satisfied: `yes`",
            "- Acceptance satisfied: `yes`",
            "- Superseded/legacy production path disposition: `n/a`",
            "- Evidence: tests green, behavior verified.",
            "",
            "## Execution Feedback",
            "",
            "- Feedback schema: `custodian.task_feedback.v1`",
            "- Outcome: `success`",
            "- Friction severity: `none`",
            "- What went wrong: none",
            "- Root cause / contributing factors: none",
            "- Prevention / pipeline improvement: none",
            "- Tooling / docs drift discovered: none",
            "- Follow-up: none",
            "",
        ]
    return "\n".join(lines)


def _legacy_packet(workstream_id: str, status: str = "complete") -> str:
    return (
        "# Legacy Packet\n\n"
        f"- Workstream: `{workstream_id}`\n"
        f"- Status: `{status}`\n"
    )


README_TEMPLATE = """# Agent Task Packets

## Active Packets

### Ready / Auto Dispatch

{ready_auto}

### In Progress

{in_progress}

### Recently Complete (awaiting archive)

_None._
"""


class CheckAiContextTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        for rel in cac.REQUIRED_CONTEXT_FILES:
            if rel == f"{PACKET_ROOT}/README.md":
                continue
            path = self.repo / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"# {rel}\n")
        for rel in cac.AUTHORITY_PATHS:
            path = self.repo / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("# stub\n")
        (self.repo / PACKET_ROOT).mkdir(parents=True, exist_ok=True)
        (self.repo / PACKET_ROOT / "archived").mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        self.temp.cleanup()

    def _write_active(self, filename: str, text: str) -> None:
        (self.repo / PACKET_ROOT / filename).write_text(text)

    def _write_archived(self, filename: str, text: str) -> None:
        (self.repo / PACKET_ROOT / "archived" / filename).write_text(text)

    def _write_readme(self, ready_auto: str = "", in_progress: str = "") -> None:
        (self.repo / PACKET_ROOT / "README.md").write_text(
            README_TEMPLATE.format(ready_auto=ready_auto, in_progress=in_progress)
        )

    def test_current_consistent_fixture_passes(self):
        self._write_active("SAMPLE_WORK.md", _v2_implementation_packet("sample-work"))
        self._write_readme(ready_auto="- `SAMPLE_WORK.md` — sample ready/auto packet.")
        report = cac.run_checks(self.repo)
        self.assertTrue(report.ok, report.to_json())

    def test_v2_draft_auto_is_reported_as_queue_stranding(self):
        text = _v2_implementation_packet("stranded", status="draft")
        self._write_active("STRANDED.md", text)
        self._write_readme()
        report = cac.run_checks(self.repo)
        findings = [f for f in report.findings if f.check == "packet-queue"]
        self.assertTrue(any("draft/auto" in f.message for f in findings), report.to_json())

    def test_missing_dependency_identity_is_reported(self):
        text = _v2_implementation_packet("missing-dep").replace(
            "- Depends on: `none`", "- Depends on: `unlisted-predecessor`",
        )
        self._write_active("MISSING_DEP.md", text)
        self._write_readme(ready_auto="- `MISSING_DEP.md` — missing predecessor.")
        report = cac.run_checks(self.repo)
        self.assertTrue(any(
            f.check == "packet-queue" and "missing dependency identity" in f.message
            for f in report.findings
        ), report.to_json())

    def test_missing_required_context_fails(self):
        self._write_readme()
        (self.repo / "custodian" / "AGENTS.md").unlink()
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any(f.check == "required-context" for f in report.findings))

    def test_nonexistent_active_index_entry_fails(self):
        self._write_readme(ready_auto="- `DOES_NOT_EXIST.md` — ghost entry.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any("does not exist" in f.message for f in report.findings))

    def test_archived_packet_listed_active_fails(self):
        self._write_archived("OLD_WORK.md", _legacy_packet("old-work"))
        self._write_readme(ready_auto="- `OLD_WORK.md` — should not be here.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any("indexes an archived packet as active" in f.message for f in report.findings))

    def test_ready_auto_index_with_manual_packet_fails(self):
        text = _v2_implementation_packet("manual-work").replace("- Dispatch: `auto`", "- Dispatch: `manual`")
        self._write_active("MANUAL_WORK.md", text)
        self._write_readme(ready_auto="- `MANUAL_WORK.md` — wrongly indexed as auto.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any("Ready / Auto Dispatch but packet declares" in f.message for f in report.findings))

    def test_duplicate_active_index_entry_fails(self):
        self._write_active("SAMPLE_WORK.md", _v2_implementation_packet("sample-work"))
        self._write_readme(ready_auto="- `SAMPLE_WORK.md` — first.\n- `SAMPLE_WORK.md` — duplicate.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any("duplicate entry" in f.message for f in report.findings))

    def test_malformed_workstream_and_priority_fails(self):
        text = (
            "# Bad Packet\n\n"
            "- Workstream: `Not Kebab`\n"
            "- Status: `ready`\n"
            "- Dispatch: `auto`\n"
            "- Priority: `P9`\n"
            "- Depends on: `none`\n"
            "- Locks: `none`\n"
        )
        self._write_active("BAD_PACKET.md", text)
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any(f.check == "packet-grammar" for f in report.findings))

    def test_historical_unindexed_archived_packet_is_allowed(self):
        self._write_archived("OLD_WORK.md", _legacy_packet("old-work"))
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertTrue(report.ok, report.to_json())

    def test_bounded_authority_path_missing_target_fails(self):
        self._write_readme()
        (self.repo / cac.AUTHORITY_PATHS[0]).unlink()
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any(f.check == "authority-path" for f in report.findings))

    def test_json_output_is_deterministic(self):
        self._write_active("SAMPLE_WORK.md", _v2_implementation_packet("sample-work"))
        self._write_readme(ready_auto="- `SAMPLE_WORK.md` — sample ready/auto packet.")
        first = cac.run_checks(self.repo).to_json()
        second = cac.run_checks(self.repo).to_json()
        self.assertEqual(json.dumps(first, sort_keys=True), json.dumps(second, sort_keys=True))

    def test_legacy_packet_without_schema_remains_valid(self):
        self._write_active("LEGACY_WORK.md", _legacy_packet("legacy-work", status="complete"))
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertTrue(report.ok, report.to_json())

    def test_ready_v2_packet_missing_required_field_fails(self):
        text = _v2_implementation_packet("incomplete-work").replace(
            "- Work surface: owner module plus consumer tests.\n", ""
        )
        self._write_active("INCOMPLETE_WORK.md", text)
        self._write_readme(ready_auto="- `INCOMPLETE_WORK.md` — missing a field.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any("Work surface" in f.message for f in report.findings))

    def test_ready_v2_packet_with_placeholder_fails(self):
        self._write_active("PLACEHOLDER_WORK.md", _v2_implementation_packet("placeholder-work", placeholder=True))
        self._write_readme(ready_auto="- `PLACEHOLDER_WORK.md` — still has a placeholder.")
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any(f.check == "v2-placeholder" for f in report.findings))

    def test_complete_v2_packet_missing_execution_feedback_fails(self):
        text = _v2_implementation_packet("done-work", status="complete")
        text = text.split("## Execution Feedback")[0]
        self._write_active("DONE_WORK.md", text)
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertFalse(report.ok)
        self.assertTrue(any(f.check == "execution-feedback" for f in report.findings))

    def test_complete_v2_packet_with_valid_feedback_passes(self):
        self._write_active("DONE_WORK.md", _v2_implementation_packet("done-work", status="complete"))
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertTrue(report.ok, report.to_json())

    def test_archived_complete_v2_packet_without_current_feedback_is_allowed(self):
        text = _v2_implementation_packet("old-work", status="complete").split("## Execution Feedback")[0]
        self._write_archived("OLD_WORK.md", text)
        self._write_readme()
        report = cac.run_checks(self.repo)
        self.assertTrue(report.ok, report.to_json())


if __name__ == "__main__":
    unittest.main()
