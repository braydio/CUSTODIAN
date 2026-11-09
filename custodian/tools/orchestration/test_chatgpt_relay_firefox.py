from __future__ import annotations

import json
import unittest
from unittest.mock import patch

try:
    from . import get_chatgpt_response, send_chatgpt_message
except ImportError:
    import get_chatgpt_response
    import send_chatgpt_message

IN_PROGRESS = get_chatgpt_response.IN_PROGRESS
read_once = get_chatgpt_response.read_once
stage_message = send_chatgpt_message.stage_message
submit_message = send_chatgpt_message.submit_message


def evaluate_result(value: object) -> dict:
    return {
        "content": [
            {
                "type": "text",
                "text": f"Script ran and returned:\n```json\n{json.dumps(value)}\n```",
            }
        ]
    }


class ReadOnceTests(unittest.TestCase):
    def test_busy_turn_returns_in_progress_without_settling(self) -> None:
        with patch(
            f"{get_chatgpt_response.__name__}.probe",
            return_value={"kind": "sample", "busy": True, "text": "partial"},
        ), patch(f"{get_chatgpt_response.__name__}.time.sleep") as sleep:
            result = read_once(object(), "request-1", 2)
        self.assertEqual(result, IN_PROGRESS)
        sleep.assert_not_called()

    def test_stable_completed_turn_returns_text(self) -> None:
        samples = [
            {"kind": "sample", "busy": False, "text": "answer", "assistantCount": 1},
            {"kind": "sample", "busy": False, "text": "answer", "assistantCount": 1},
        ]
        with patch(f"{get_chatgpt_response.__name__}.probe", side_effect=samples), patch(
            f"{get_chatgpt_response.__name__}.time.sleep"
        ):
            result = read_once(object(), "request-1", 2)
        self.assertEqual(result, "answer")

    def test_unexpected_probe_result_fails_closed(self) -> None:
        with patch(
            f"{get_chatgpt_response.__name__}.probe", return_value={"kind": "unexpected"}
        ):
            with self.assertRaisesRegex(ValueError, "unexpected conversation probe"):
                read_once(object(), None, 2)


class SenderSafetyTests(unittest.TestCase):
    def test_different_existing_draft_is_never_overwritten(self) -> None:
        class FakeClient:
            def __init__(self) -> None:
                self.calls: list[str] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                self.calls.append(name)
                if name == "evaluate_script":
                    return evaluate_result(
                        {
                            "count": 1,
                            "formFound": True,
                            "visible": True,
                            "text": "existing owner draft",
                            "chipNames": [],
                            "inputNames": [],
                        }
                    )
                raise AssertionError(f"unexpected browser mutation: {name}")

        client = FakeClient()
        with self.assertRaisesRegex(ValueError, "different draft"):
            stage_message(client, "new relay message", [])
        self.assertEqual(client.calls, ["evaluate_script"])

    def test_submit_requires_one_enabled_send_button_before_click(self) -> None:
        class FakeClient:
            def __init__(self) -> None:
                self.calls: list[str] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                self.calls.append(name)
                if name == "evaluate_script":
                    return evaluate_result({"userCount": 3, "sendButtons": 0})
                raise AssertionError(f"unexpected browser mutation: {name}")

        client = FakeClient()
        with self.assertRaisesRegex(ValueError, "enabled Send button"):
            submit_message(client, "message")
        self.assertEqual(client.calls, ["evaluate_script"])


if __name__ == "__main__":
    unittest.main()
