"""Focused positive and negative controls for the exact owner waiver lane."""
import hashlib
import importlib.util
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
EXCEPTION_PATH = Path(__file__).with_name("owner_review_exception.py")
spec = importlib.util.spec_from_file_location("custodian_owner_review_exception_tests", EXCEPTION_PATH)
owner_exception = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = owner_exception
spec.loader.exec_module(owner_exception)

DISPATCH_PATH = Path(__file__).with_name("dispatch.py")
spec = importlib.util.spec_from_file_location("custodian_dispatch_owner_exception_tests", DISPATCH_PATH)
dispatch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = dispatch
spec.loader.exec_module(dispatch)


def sha(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def approval(message: str | None = None) -> dict:
    message = message or (
        "I explicitly waive review-operator-chassis-authority-seal-v1 as unresolved, "
        "authorize retirement of its obsolete execution claim, and accept it without a review PASS."
    )
    return {
        "schema": "custodian.chat_owner_approval.v1",
        "approver": "project-owner",
        "source_url": "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e",
        "user_message": message,
        "user_message_sha256": sha(message),
        "retire_claim": True,
    }


class ApprovalTests(unittest.TestCase):
    def test_exact_owner_message_is_accepted_as_unresolved_waiver(self):
        owner_exception._validate_chat_approval(approval(), owner_exception.REVIEW_ID)

    def test_wrong_identity_missing_approval_and_tampered_message_reject(self):
        cases = []
        wrong = approval(); wrong["approver"] = "agent"
        cases.append(wrong)
        missing = approval(); missing["user_message"] = ""
        cases.append(missing)
        tampered = approval(); tampered["user_message_sha256"] = "0" * 64
        cases.append(tampered)
        for value in cases:
            with self.subTest(value=value):
                with self.assertRaises(owner_exception.ExceptionError):
                    owner_exception._validate_chat_approval(value, owner_exception.REVIEW_ID)

    def test_wrong_conversation_and_review_target_reject(self):
        value = approval(); value["source_url"] = "https://example.com/c/not-chatgpt"
        with self.assertRaises(owner_exception.ExceptionError):
            owner_exception._validate_chat_approval(value, owner_exception.REVIEW_ID)
        with self.assertRaises(owner_exception.ExceptionError):
            owner_exception._validate_chat_approval(approval(), "review-other-v1")

    def test_pass_claim_cannot_be_used_as_the_exception_disposition(self):
        value = approval("I waive review-operator-chassis-authority-seal-v1 as unresolved and authorize it as passed.")
        with self.assertRaises(owner_exception.ExceptionError):
            owner_exception._validate_chat_approval(value, owner_exception.REVIEW_ID)


class RecordTests(unittest.TestCase):
    def setUp(self):
        self.plan = {
            "review_workstream": owner_exception.REVIEW_ID,
            "implementation_workstream": owner_exception.IMPLEMENTATION_ID,
            "implementation_commit": "a" * 40,
            "main_sha": "b" * 40,
            "review_packet": "custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md",
            "review_packet_sha256": sha("review bytes"),
            "implementation_packet": "custodian/docs/ai_context/task_packets/archived/OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md",
            "implementation_packet_sha256": sha("implementation bytes"),
            "review_outcome": "unresolved",
            "review_outcome_detail": "review host validation did not launch",
            "preserved_review_runs": [{
                "run_id": "fixture-run", "phase": "host_validation_recovery",
                "implementation_commit": "a" * 40,
                "metadata_sha256": "e" * 64, "recovery_sha256": "f" * 64,
                "claim_receipt_sha256": "1" * 64,
            }],
            "remote_claim_sha": None,
            "remote_agent_branch_sha": None,
            "local_agent_branch_sha": None,
            "registered_local_review_worktree": None,
            "paired_review_lock_held": False,
        }

    def test_record_preserves_unresolved_review_truth_and_pins_exact_target(self):
        record = owner_exception.make_record(self.plan, approval(), reason="Owner accepts the unresolved review.")
        valid, reason = owner_exception.verify_record(
            record, owner_exception.REVIEW_ID, "implementation bytes", "review bytes",
        )
        self.assertTrue(valid, reason)
        self.assertEqual(record["decision"], "waived_unresolved")
        self.assertEqual(record["original_review_outcome"], "unresolved")
        self.assertEqual(record["claim_retirement"], "already_absent")

    def test_stale_packet_bytes_wrong_workstream_and_tampered_record_reject(self):
        record = owner_exception.make_record(self.plan, approval(), reason="Exact owner decision.")
        valid, _ = owner_exception.verify_record(record, "review-other-v1", "implementation bytes", "review bytes")
        self.assertFalse(valid)
        valid, _ = owner_exception.verify_record(record, owner_exception.REVIEW_ID, "changed", "review bytes")
        self.assertFalse(valid)
        record["disposition"] = "passed"
        valid, _ = owner_exception.verify_record(record, owner_exception.REVIEW_ID, "implementation bytes", "review bytes")
        self.assertFalse(valid)

    def test_copying_record_or_changing_review_run_commit_rejects(self):
        record = owner_exception.make_record(self.plan, approval(), reason="Exact owner decision.")
        copied = dict(record)
        copied["review_workstream"] = "review-another-v1"
        unsigned = {key: value for key, value in copied.items() if key != "record_sha256"}
        copied["record_sha256"] = owner_exception._sha(owner_exception._json_canonical(unsigned))
        self.assertFalse(owner_exception.verify_record(copied, "review-another-v1", "implementation bytes", "review bytes")[0])
        record["preserved_review_runs"][0]["implementation_commit"] = "9" * 40
        unsigned = {key: value for key, value in record.items() if key != "record_sha256"}
        record["record_sha256"] = owner_exception._sha(owner_exception._json_canonical(unsigned))
        self.assertFalse(owner_exception.verify_record(record, owner_exception.REVIEW_ID, "implementation bytes", "review bytes")[0])

    def test_exact_review_dependency_can_be_satisfied_without_archived_pass(self):
        review = owner_exception.REVIEW_ID
        text = (
            "# F2\n\n- Workstream: `operator-melee-domain-extraction`\n- Status: `ready`\n"
            "- Dispatch: `auto`\n- Priority: `P1`\n- Depends on: `" + review + "`\n"
            "- Locks: `none`\n- Kind: `implementation`\n- Review: `none`\n"
        )
        packet = dispatch.parse_packet("f2.md", text)
        exact = {review: {"activation_state": "accepted", "record": {"disposition": "owner_accepted_with_review_exception"}}}
        ok, why = dispatch._decision(packet, [packet], [], set(), auto_only=True,
                                     owner_exceptions=exact,
                                     review_rejections={review: (None, "unresolved")})
        self.assertTrue(ok, why)
        unrelated_text = text.replace("Depends on: `" + review + "`", "Depends on: `some-other-review`")
        unrelated = dispatch.parse_packet("other.md", unrelated_text)
        ok, why = dispatch._decision(unrelated, [unrelated], [], set(), auto_only=True,
                                     owner_exceptions=exact)
        self.assertFalse(ok)
        self.assertIn("some-other-review", why or "")

    def test_owner_waiver_stays_inert_until_its_own_paired_review_passes(self):
        self.assertFalse(owner_exception.activation_review_accepted("", ""))
        review_id = owner_exception.ACTIVATION_REVIEW_ID
        target_id = owner_exception.ACTIVATION_TARGET_ID
        main = "1" * 40
        commit = "2" * 40
        report = owner_exception.review_outcome.render_review_outcome(
            outcome="passed", review_workstream=review_id, target_workstream=target_id,
            reviewed_main=main, implementation_commit=commit, provenance="different-agent",
            run_id="20261109T000000Z-0123456789ab", review_cycle=0, ids=(),
        )
        target = (
            "## Independent Review\n\n"
            f"### Review Receipt: {review_id}\n- Status: `passed`\n"
            "- Blocking defects: `0`\n- Material gaps: `0`\n"
        )
        self.assertTrue(owner_exception.activation_review_accepted(report, target))


if __name__ == "__main__":
    unittest.main()
