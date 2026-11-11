from __future__ import annotations

import unittest
from unittest.mock import patch

try:
    from . import get_chatgpt_response, send_chatgpt_message
except ImportError:
    import get_chatgpt_response
    import send_chatgpt_message


class ChromeTransportTests(unittest.TestCase):
    def test_default_sender_and_reader_use_custodian_chrome_endpoint(self) -> None:
        expected = "http://127.0.0.1:9223"
        self.assertEqual(send_chatgpt_message.CDP_ENDPOINT, expected)
        self.assertEqual(get_chatgpt_response.CDP_ENDPOINT, expected)

    def test_reader_keeps_busy_reply_in_progress(self) -> None:
        with patch.object(
            get_chatgpt_response,
            "probe",
            return_value={"kind": "sample", "busy": True, "text": "partial"},
        ), patch.object(get_chatgpt_response.time, "sleep") as sleep:
            result = get_chatgpt_response.read_once(object(), "request-1", 2)
        self.assertEqual(result, get_chatgpt_response.IN_PROGRESS)
        sleep.assert_not_called()

    def test_reader_returns_only_a_stable_completed_reply(self) -> None:
        sample = {"kind": "sample", "busy": False, "assistantCount": 1, "text": "answer"}
        with patch.object(get_chatgpt_response, "probe", side_effect=[sample, sample]), patch.object(
            get_chatgpt_response.time, "sleep"
        ) as sleep:
            result = get_chatgpt_response.read_once(object(), "request-1", 2)
        self.assertEqual(result, "answer")
        sleep.assert_called_once_with(2)

    def test_sender_requires_an_exact_https_conversation_url(self) -> None:
        url = "https://chatgpt.com/g/example/c/conversation-1"
        self.assertEqual(send_chatgpt_message.canonical_url(url), "/g/example/c/conversation-1")
        with self.assertRaisesRegex(ValueError, "https://chatgpt.com"):
            send_chatgpt_message.canonical_url("http://chatgpt.com/g/example/c/conversation-1")


if __name__ == "__main__":
    unittest.main()
