#!/usr/bin/env python3
"""Small stdio MCP client for Mozilla's Firefox DevTools MCP server."""
from __future__ import annotations

import json
import os
import re
import select
import subprocess
import time
from dataclasses import dataclass
from typing import Any, Sequence


DEFAULT_SERVER_COMMAND = [
    "npx",
    "-y",
    "@mozilla/firefox-devtools-mcp@latest",
    "--connect-existing",
    "--marionette-port",
    "2828",
    "--idle-timeout",
    "1800",
    "--tool-preset",
    "developer",
]
PROTOCOL_VERSION = "2025-03-26"
PAGE_LINE = re.compile(
    r"^\s*>?\s*\[(?P<index>\d+)\]\s*(?P<title>.*?)\s+"
    r"\((?P<url>https?://.+)\)\s*$"
)


class FirefoxMCPError(RuntimeError):
    """The Firefox MCP server could not safely complete the requested call."""


@dataclass(frozen=True)
class BrowserPage:
    index: int
    title: str
    url: str


def server_command(environ: dict[str, str] | None = None) -> list[str]:
    """Return the MCP command, allowing an explicit JSON argv override."""
    env = os.environ if environ is None else environ
    override = env.get("CUSTODIAN_FIREFOX_MCP_COMMAND")
    if not override:
        return list(DEFAULT_SERVER_COMMAND)
    try:
        command = json.loads(override)
    except json.JSONDecodeError as exc:
        raise ValueError("CUSTODIAN_FIREFOX_MCP_COMMAND must be a JSON argv array") from exc
    if (
        not isinstance(command, list)
        or not command
        or any(not isinstance(part, str) or not part for part in command)
    ):
        raise ValueError("CUSTODIAN_FIREFOX_MCP_COMMAND must be a non-empty JSON argv array")
    return command


class FirefoxMCPClient:
    """One short-lived MCP stdio client; it never launches or closes Firefox."""

    def __init__(
        self,
        command: Sequence[str] | None = None,
        timeout: float = 30.0,
        startup_timeout: float = 60.0,
    ) -> None:
        if timeout <= 0 or startup_timeout <= 0:
            raise ValueError("MCP timeouts must be positive")
        self.timeout = timeout
        self._next_id = 0
        self._stdout_buffer = bytearray()
        argv = list(command) if command is not None else server_command()
        if not argv:
            raise ValueError("MCP command must not be empty")
        try:
            self._process = subprocess.Popen(
                argv,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                bufsize=0,
            )
        except OSError as exc:
            raise FirefoxMCPError(
                f"could not start Firefox DevTools MCP ({argv[0]}): {exc}"
            ) from exc
        if self._process.stdin is None or self._process.stdout is None:
            self.close()
            raise FirefoxMCPError("Firefox DevTools MCP did not expose stdio pipes")
        try:
            self._request(
                "initialize",
                {
                    "protocolVersion": PROTOCOL_VERSION,
                    "capabilities": {},
                    "clientInfo": {"name": "custodian-chat-relay", "version": "1.0"},
                },
                timeout=startup_timeout,
            )
            self._notify("notifications/initialized")
        except Exception:
            self.close()
            raise

    def __enter__(self) -> "FirefoxMCPClient":
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.close()

    def _write(self, message: dict[str, Any]) -> None:
        if self._process.poll() is not None:
            raise FirefoxMCPError(
                f"Firefox DevTools MCP exited with status {self._process.returncode}"
            )
        assert self._process.stdin is not None
        payload = json.dumps(message, separators=(",", ":"), ensure_ascii=False)
        try:
            self._process.stdin.write((payload + "\n").encode("utf-8"))
            self._process.stdin.flush()
        except (BrokenPipeError, OSError) as exc:
            raise FirefoxMCPError("Firefox DevTools MCP closed its input stream") from exc

    def _notify(self, method: str, params: dict[str, Any] | None = None) -> None:
        message: dict[str, Any] = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            message["params"] = params
        self._write(message)

    def _readline(self, deadline: float) -> dict[str, Any]:
        assert self._process.stdout is not None
        fd = self._process.stdout.fileno()
        while b"\n" not in self._stdout_buffer:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("timed out waiting for Firefox DevTools MCP")
            readable, _, _ = select.select([fd], [], [], remaining)
            if not readable:
                raise TimeoutError("timed out waiting for Firefox DevTools MCP")
            chunk = os.read(fd, 65536)
            if not chunk:
                status = self._process.poll()
                raise FirefoxMCPError(
                    "Firefox DevTools MCP closed its output stream"
                    + (f" (status {status})" if status is not None else "")
                )
            self._stdout_buffer.extend(chunk)
        line, _, remainder = self._stdout_buffer.partition(b"\n")
        self._stdout_buffer = bytearray(remainder)
        try:
            message = json.loads(line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise FirefoxMCPError("Firefox DevTools MCP sent invalid JSON-RPC output") from exc
        if not isinstance(message, dict):
            raise FirefoxMCPError("Firefox DevTools MCP sent a non-object JSON-RPC message")
        return message

    def _request(
        self,
        method: str,
        params: dict[str, Any],
        timeout: float | None = None,
    ) -> dict[str, Any]:
        self._next_id += 1
        request_id = self._next_id
        self._write(
            {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params}
        )
        deadline = time.monotonic() + (self.timeout if timeout is None else timeout)
        while True:
            response = self._readline(deadline)
            if response.get("id") != request_id:
                continue
            if "error" in response:
                error = response.get("error")
                code = error.get("code") if isinstance(error, dict) else "unknown"
                message = error.get("message") if isinstance(error, dict) else "request failed"
                raise FirefoxMCPError(f"MCP {method} failed ({code}): {message}")
            result = response.get("result")
            if not isinstance(result, dict):
                raise FirefoxMCPError(f"MCP {method} returned an invalid result")
            return result

    def call_tool(self, name: str, arguments: dict[str, Any] | None = None) -> dict[str, Any]:
        result = self._request(
            "tools/call", {"name": name, "arguments": arguments or {}}
        )
        if result.get("isError"):
            raise FirefoxMCPError(f"Firefox MCP tool {name!r} reported failure")
        return result

    def close(self) -> None:
        process = getattr(self, "_process", None)
        if process is None:
            return
        if process.poll() is None and process.stdin is not None:
            try:
                process.stdin.close()
            except OSError:
                pass
        if process.poll() is None:
            try:
                process.wait(timeout=1.0)
            except subprocess.TimeoutExpired:
                process.terminate()
                try:
                    process.wait(timeout=2.0)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for stream in (process.stdin, process.stdout):
            if stream is not None and not stream.closed:
                try:
                    stream.close()
                except OSError:
                    pass


def result_text(result: dict[str, Any]) -> str:
    content = result.get("content")
    if not isinstance(content, list):
        raise FirefoxMCPError("Firefox MCP tool returned no content list")
    return "\n".join(
        item["text"]
        for item in content
        if isinstance(item, dict) and item.get("type") == "text" and isinstance(item.get("text"), str)
    )


def parse_evaluate_result(result: dict[str, Any]) -> Any:
    text = result_text(result)
    match = re.search(r"```json\s*(.*?)\s*```", text, flags=re.DOTALL | re.IGNORECASE)
    if not match:
        raise FirefoxMCPError("Firefox evaluate_script did not return a JSON value")
    try:
        return json.loads(match.group(1))
    except json.JSONDecodeError as exc:
        raise FirefoxMCPError("Firefox evaluate_script returned malformed JSON") from exc


def parse_page_list(text: str) -> list[BrowserPage]:
    pages: list[BrowserPage] = []
    for line in text.splitlines():
        match = PAGE_LINE.match(line)
        if match:
            pages.append(
                BrowserPage(
                    index=int(match.group("index")),
                    title=match.group("title").strip(),
                    url=match.group("url").strip(),
                )
            )
    return pages


def canonical_url(url: str) -> str:
    from urllib.parse import urlsplit

    parsed = urlsplit(url)
    host = (parsed.hostname or "").lower()
    if parsed.scheme != "https" or host not in {"chatgpt.com", "chat.openai.com"}:
        raise ValueError("--url must be an https://chatgpt.com conversation URL")
    path = parsed.path.rstrip("/")
    if "/c/" not in path:
        raise ValueError("--url must identify one conversation (/c/<id>)")
    return path


def is_conversation(url: str) -> bool:
    try:
        canonical_url(url)
        return True
    except ValueError:
        return False


def evaluate(client: FirefoxMCPClient, function: str) -> Any:
    return parse_evaluate_result(
        client.call_tool("evaluate_script", {"function": function})
    )


def select_conversation(client: FirefoxMCPClient, specified_url: str | None) -> BrowserPage:
    pages = parse_page_list(result_text(client.call_tool("list_pages")))
    conversations = [page for page in pages if is_conversation(page.url)]
    if specified_url:
        wanted = canonical_url(specified_url)
        matches = [page for page in conversations if canonical_url(page.url) == wanted]
        label = "specified conversation"
    else:
        matches = conversations
        label = "open ChatGPT conversation"
    if len(matches) != 1:
        raise ValueError(f"expected exactly one {label} tab; found {len(matches)}")

    page = matches[0]
    client.call_tool("select_page", {"pageIdx": page.index})
    selected = evaluate(client, "() => ({url: location.href, title: document.title})")
    if not isinstance(selected, dict) or not is_conversation(str(selected.get("url", ""))):
        raise FirefoxMCPError("selected Firefox tab is not a ChatGPT conversation")
    if canonical_url(str(selected["url"])) != canonical_url(page.url):
        raise FirefoxMCPError("selected Firefox tab changed during conversation selection")
    if specified_url and canonical_url(str(selected["url"])) != canonical_url(specified_url):
        raise FirefoxMCPError("selected Firefox tab does not match the requested conversation")
    return page


def uid_for_snapshot_line(snapshot: str, predicate: re.Pattern[str]) -> str:
    matches: list[str] = []
    for line in snapshot.splitlines():
        uid = re.search(r"\buid=([A-Za-z0-9_-]+)", line)
        if uid and predicate.search(line):
            matches.append(uid.group(1))
    if len(matches) != 1:
        raise ValueError(f"expected exactly one matching Firefox snapshot element; found {len(matches)}")
    return matches[0]


def snapshot(client: FirefoxMCPClient, **arguments: Any) -> str:
    return result_text(client.call_tool("take_snapshot", arguments))


def upload_files(client: FirefoxMCPClient, paths: Sequence[str]) -> None:
    file_snapshot = snapshot(
        client,
        selector='input[type="file"][aria-label="Attach files"]',
        includeAll=True,
        includeAttributes=True,
        maxLines=200,
    )
    file_uid = uid_for_snapshot_line(
        file_snapshot,
        re.compile(r'\binput\b.*["\']Attach files["\']', re.IGNORECASE),
    )
    client.call_tool(
        "upload_file_by_uid", {"uid": file_uid, "filePath": "\n".join(paths)}
    )
