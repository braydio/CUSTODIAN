from __future__ import annotations

import json
import sys
import unittest
from unittest.mock import patch

try:
    from . import get_chatgpt_response_firefox as get_chatgpt_response, send_chatgpt_message_firefox as send_chatgpt_message
except ImportError:
    import get_chatgpt_response_firefox as get_chatgpt_response
    import send_chatgpt_message_firefox as send_chatgpt_message

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
    def test_wait_mode_sleeps_two_minutes_between_python_polls(self) -> None:
        class FakeClient:
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, traceback):
                return None

        with patch.object(
            sys,
            "argv",
            [
                "get_chatgpt_response_firefox.py",
                "--url",
                "https://chatgpt.com/c/conversation-1",
                "--wait",
            ],
        ), patch(
            f"{get_chatgpt_response.__name__}.FirefoxMCPClient",
            return_value=FakeClient(),
        ), patch(
            f"{get_chatgpt_response.__name__}.select_conversation"
        ), patch(
            f"{get_chatgpt_response.__name__}.read_once",
            side_effect=[IN_PROGRESS, "stable answer"],
        ), patch(
            f"{get_chatgpt_response.__name__}.time.monotonic", return_value=10
        ), patch(f"{get_chatgpt_response.__name__}.time.sleep") as sleep, patch(
            "builtins.print"
        ):
            result = get_chatgpt_response.main()
        self.assertEqual(result, 0)
        sleep.assert_called_once_with(120.0)

    def test_response_starting_state_returns_in_progress(self) -> None:
        with patch(
            f"{get_chatgpt_response.__name__}.probe",
            return_value={"kind": "sample", "busy": False, "starting": True, "text": "Thinking"},
        ), patch(f"{get_chatgpt_response.__name__}.time.sleep") as sleep:
            result = read_once(object(), "request-1", 2)
        self.assertEqual(result, IN_PROGRESS)
        sleep.assert_not_called()

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
    def test_send_button_snapshot_is_scoped_to_accessible_label(self) -> None:
        class FakeClient:
            def __init__(self) -> None:
                self.calls: list[tuple[str, dict]] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                args = arguments or {}
                self.calls.append((name, args))
                if name == "evaluate_script":
                    return evaluate_result(
                        [{"ariaLabel": "Send", "accessibleName": "Send"}]
                    )
                if name == "take_snapshot":
                    return {
                        "content": [
                            {
                                "type": "text",
                                "text": 'uid=e2 button "Send" focusable interactive',
                            }
                        ]
                    }
                raise AssertionError(f"unexpected browser interaction: {name}")

        client = FakeClient()
        self.assertEqual(send_chatgpt_message.send_button_uid(client), "e2")
        self.assertEqual(
            client.calls[1],
            (
                "take_snapshot",
                {
                    "selector": 'button[aria-label="Send"]',
                    "includeAll": True,
                    "includeAttributes": True,
                    "maxLines": 100,
                },
            ),
        )

    def test_submit_accepts_current_chatgpt_user_bubble_marker(self) -> None:
        message = "relay request"

        class FakeClient:
            def __init__(self) -> None:
                self.eval_count = 0
                self.calls: list[tuple[str, dict]] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                args = arguments or {}
                self.calls.append((name, args))
                if name == "evaluate_script":
                    self.eval_count += 1
                    function = args["function"]
                    if self.eval_count == 1:
                        if "[data-user-message-bubble]" not in function:
                            raise AssertionError("pre-submit count omitted current user bubble marker")
                        return evaluate_result({"userCount": 1})
                    if self.eval_count == 2:
                        return evaluate_result(
                            [{"ariaLabel": "Send", "accessibleName": "Send"}]
                        )
                    if self.eval_count == 3:
                        if "[data-user-message-bubble]" not in function:
                            raise AssertionError("post-submit verification omitted current user bubble marker")
                        return evaluate_result({"users": ["earlier", message], "composer": [""]})
                    return evaluate_result(
                        {
                            "count": 1,
                            "formFound": True,
                            "visible": True,
                            "text": "",
                            "chipNames": [],
                            "inputNames": [],
                        }
                    )
                if name == "take_snapshot":
                    self.assert_scoped_send_snapshot(args)
                    return {
                        "content": [
                            {"type": "text", "text": 'uid=e2 button "Send" focusable interactive'}
                        ]
                    }
                if name == "click_by_uid":
                    return {"content": [{"type": "text", "text": "clicked"}]}
                raise AssertionError(f"unexpected browser interaction: {name}")

            @staticmethod
            def assert_scoped_send_snapshot(args: dict) -> None:
                if args.get("selector") != 'button[aria-label="Send"]':
                    raise AssertionError("Send snapshot was not scoped to the accessible button")

        client = FakeClient()
        submit_message(client, message, timeout=1)
        self.assertIn(("click_by_uid", {"uid": "e2"}), client.calls)

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
                self.eval_count = 0

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                self.calls.append(name)
                if name == "evaluate_script":
                    self.eval_count += 1
                    if self.eval_count == 1:
                        return evaluate_result({"userCount": 3})
                    return evaluate_result([])
                raise AssertionError(f"unexpected browser mutation: {name}")

        client = FakeClient()
        with self.assertRaisesRegex(ValueError, "enabled Send button"):
            submit_message(client, "message")
        self.assertEqual(client.calls, ["evaluate_script", "evaluate_script"])


if __name__ == "__main__":
    unittest.main()
