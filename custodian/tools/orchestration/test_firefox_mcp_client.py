from __future__ import annotations

import json
import sys
import unittest

try:
    from .firefox_mcp_client import (
        BrowserPage,
        FirefoxMCPClient,
        FirefoxMCPError,
        canonical_url,
        parse_evaluate_result,
        parse_page_list,
        result_text,
        select_conversation,
        server_command,
        upload_files,
    )
except ImportError:
    from firefox_mcp_client import (
        BrowserPage,
        FirefoxMCPClient,
        FirefoxMCPError,
        canonical_url,
        parse_evaluate_result,
        parse_page_list,
        result_text,
        select_conversation,
        server_command,
        upload_files,
    )


class FirefoxMCPClientTests(unittest.TestCase):
    def test_default_server_uses_existing_marionette_session(self) -> None:
        command = server_command({})
        self.assertIn("--connect-existing", command)
        self.assertEqual(command[command.index("--marionette-port") + 1], "2828")
        self.assertIn("--tool-preset", command)

    def test_server_command_override_requires_json_argv(self) -> None:
        self.assertEqual(
            server_command({"CUSTODIAN_FIREFOX_MCP_COMMAND": '["mcp", "--test"]'}),
            ["mcp", "--test"],
        )
        with self.assertRaises(ValueError):
            server_command({"CUSTODIAN_FIREFOX_MCP_COMMAND": "mcp --test"})

    def test_stdio_initialize_and_tool_call(self) -> None:
        fake_server = r'''
import json, sys
for line in sys.stdin:
    request = json.loads(line)
    method = request.get("method")
    if method == "initialize":
        response = {"jsonrpc": "2.0", "id": request["id"], "result": {"protocolVersion": "2025-03-26"}}
        print(json.dumps(response), flush=True)
    elif method == "tools/call":
        response = {"jsonrpc": "2.0", "id": request["id"], "result": {"content": [{"type": "text", "text": request["params"]["name"]}]}}
        print(json.dumps(response), flush=True)
'''
        with FirefoxMCPClient(
            command=[sys.executable, "-u", "-c", fake_server], timeout=2, startup_timeout=2
        ) as client:
            result = client.call_tool("list_pages")
        self.assertEqual(result_text(result), "list_pages")

    def test_mcp_remote_error_fails_closed(self) -> None:
        fake_server = r'''
import json, sys
for line in sys.stdin:
    request = json.loads(line)
    if request.get("method") == "initialize":
        print(json.dumps({"jsonrpc": "2.0", "id": request["id"], "result": {}}), flush=True)
    elif request.get("method") == "tools/call":
        print(json.dumps({"jsonrpc": "2.0", "id": request["id"], "error": {"code": -1, "message": "failed"}}), flush=True)
'''
        with FirefoxMCPClient(
            command=[sys.executable, "-u", "-c", fake_server], timeout=2, startup_timeout=2
        ) as client:
            with self.assertRaisesRegex(FirefoxMCPError, "tools/call failed"):
                client.call_tool("list_pages")

    def test_evaluate_result_parses_json_fence(self) -> None:
        result = {
            "content": [
                {
                    "type": "text",
                    "text": 'Script ran and returned:\n```json\n{"ok":true,"count":2}\n```',
                }
            ]
        }
        self.assertEqual(parse_evaluate_result(result), {"ok": True, "count": 2})

    def test_page_list_and_canonical_conversation(self) -> None:
        pages = parse_page_list(
            "2 pages (selected: 1)\n"
            " [0] Untitled (about:blank)\n"
            ">[1] ChatGPT (https://chatgpt.com/g/p/c/conversation-1)"
        )
        self.assertEqual(
            pages,
            [BrowserPage(1, "ChatGPT", "https://chatgpt.com/g/p/c/conversation-1")],
        )
        self.assertEqual(
            canonical_url("https://chatgpt.com/g/p/c/conversation-1?model=x"),
            "/g/p/c/conversation-1",
        )
        with self.assertRaises(ValueError):
            canonical_url("https://example.com/c/conversation-1")

    def test_select_conversation_requires_one_exact_tab(self) -> None:
        target = "https://chatgpt.com/g/p/c/conversation-1"

        class FakeClient:
            def __init__(self, page_text: str) -> None:
                self.page_text = page_text
                self.calls: list[tuple[str, dict]] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                args = arguments or {}
                self.calls.append((name, args))
                if name == "list_pages":
                    return {"content": [{"type": "text", "text": self.page_text}]}
                if name == "select_page":
                    return {"content": [{"type": "text", "text": "selected"}]}
                if name == "evaluate_script":
                    return {
                        "content": [
                            {
                                "type": "text",
                                "text": f'Script ran and returned:\n```json\n{{"url":"{target}","title":"ChatGPT"}}\n```',
                            }
                        ]
                    }
                raise AssertionError(name)

        client = FakeClient(f">[2] ChatGPT ({target})")
        selected = select_conversation(client, target)
        self.assertEqual(selected.index, 2)
        self.assertIn(("select_page", {"pageIdx": 2}), client.calls)

        duplicate = FakeClient(f"[1] ChatGPT ({target})\n[2] ChatGPT ({target})")
        with self.assertRaisesRegex(ValueError, "found 2"):
            select_conversation(duplicate, target)

    def test_upload_files_passes_multiple_paths_without_shell(self) -> None:
        class FakeClient:
            def __init__(self) -> None:
                self.calls: list[tuple[str, dict]] = []

            def call_tool(self, name: str, arguments: dict | None = None) -> dict:
                args = arguments or {}
                self.calls.append((name, args))
                if name == "take_snapshot":
                    self.assert_attach_selector(args)
                    return {
                        "content": [
                            {
                                "type": "text",
                                "text": 'uid=file1 input "Attach files" focusable interactive',
                            }
                        ]
                    }
                return {"content": [{"type": "text", "text": "uploaded"}]}

            @staticmethod
            def assert_attach_selector(args: dict) -> None:
                if args.get("selector") != 'input[type="file"][aria-label="Attach files"]':
                    raise AssertionError("the file selector must target ChatGPT's Attach files input")

        client = FakeClient()
        upload_files(client, ["/tmp/first.zip", "/tmp/second.zip"])
        self.assertEqual(
            client.calls[-1],
            (
                "upload_file_by_uid",
                {"uid": "file1", "filePath": "/tmp/first.zip\n/tmp/second.zip"},
            ),
        )


if __name__ == "__main__":
    unittest.main()
