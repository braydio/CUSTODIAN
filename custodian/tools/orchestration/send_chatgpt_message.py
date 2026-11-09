#!/usr/bin/env python3
"""Stage or send a message to an exact ChatGPT conversation via Firefox MCP.

This script uses the visible ChatGPT composer and attachment input. It never
navigates, creates a tab, or submits unless --submit is explicitly provided.
Firefox must already be running with Marionette enabled on port 2828. The script
starts a short-lived Firefox DevTools MCP client and attaches to that instance.

Examples:
  python send_chatgpt_message.py --url URL --text-file note.txt
  python send_chatgpt_message.py --url URL --text-file note.txt \
      --attachment ~/Downloads/evidence.zip --stage
  python send_chatgpt_message.py --url URL --text-file note.txt \
      --attachment ~/Downloads/evidence.zip --submit
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import time
from pathlib import Path

try:
    from .firefox_mcp_client import (
        FirefoxMCPClient,
        canonical_url,
        evaluate,
        select_conversation,
        snapshot,
        uid_for_snapshot_line,
        upload_files,
    )
except ImportError:  # direct script invocation
    from firefox_mcp_client import (
        FirefoxMCPClient,
        canonical_url,
        evaluate,
        select_conversation,
        snapshot,
        uid_for_snapshot_line,
        upload_files,
    )


def read_message(text: str | None, text_file: str | None) -> str:
    if bool(text is not None) == bool(text_file):
        raise ValueError("provide exactly one of --text or --text-file")
    message = text if text is not None else Path(text_file).expanduser().read_text(encoding="utf-8")
    if not message.strip():
        raise ValueError("message text must not be empty")
    return message


def resolve_attachments(values: list[str]) -> list[Path]:
    paths = [Path(value).expanduser().resolve(strict=True) for value in values]
    for path in paths:
        if not path.is_file():
            raise ValueError(f"attachment is not a regular file: {path}")
    return paths


def normalized_text(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


COMPOSER_STATE_JS = r"""() => {
  const composers = Array.from(document.querySelectorAll(
    '[contenteditable="true"][aria-label*="Ask ChatGPT"]'
  )).filter(element => element.getClientRects().length > 0);
  if (composers.length !== 1) return { count: composers.length };
  const composer = composers[0];
  const form = composer.closest('form');
  if (!form) return { count: 1, formFound: false };
  const chipNames = Array.from(form.querySelectorAll('button[aria-label^="Remove "]'))
    .map(button => button.getAttribute('aria-label').replace(/^Remove\s+/, '').trim())
    .filter(Boolean);
  const inputNames = Array.from(form.querySelectorAll('input[type="file"]'))
    .flatMap(input => Array.from(input.files || [], file => file.name));
  return {
    count: 1,
    formFound: true,
    text: composer.innerText || '',
    chipNames,
    inputNames,
    visible: !!composer.getClientRects().length
  };
}"""


def composer_state(client: FirefoxMCPClient) -> dict:
    state = evaluate(client, COMPOSER_STATE_JS)
    if not isinstance(state, dict):
        raise ValueError("Firefox MCP returned an invalid ChatGPT composer state")
    if state.get("count") != 1 or state.get("formFound") is not True or not state.get("visible"):
        raise ValueError("could not identify exactly one visible ChatGPT composer")
    chip_names = [name for name in state.get("chipNames", []) if name]
    input_names = [name for name in state.get("inputNames", []) if name]
    if chip_names and input_names and chip_names != input_names:
        raise ValueError("attachment chips and file inputs disagree; refusing to modify the draft")
    state["attachmentNames"] = chip_names or input_names
    return state


def focus_composer(client: FirefoxMCPClient) -> None:
    focused = evaluate(
        client,
        "() => { const elements = Array.from(document.querySelectorAll("
        "'[contenteditable=\"true\"][aria-label*=\"Ask ChatGPT\"]'))"
        ".filter(element => element.getClientRects().length > 0); "
        "if (elements.length !== 1) return false; elements[0].focus(); "
        "return document.activeElement === elements[0]; }",
    )
    if focused is not True:
        raise ValueError("could not focus the visible ChatGPT composer")


def stage_message(client: FirefoxMCPClient, message: str, attachments: list[Path]) -> None:
    state = composer_state(client)
    existing_names = state["attachmentNames"]
    expected_names = [path.name for path in attachments]
    if len(expected_names) != len(set(expected_names)):
        raise ValueError("requested attachments contain duplicate filenames")
    if existing_names and existing_names != expected_names:
        raise ValueError(
            "composer already has different staged attachments; refusing to replace or duplicate them"
        )
    if not attachments and existing_names:
        raise ValueError("composer already has attached files; refusing to send them with this message")

    current_text = state.get("text", "")
    if current_text.strip():
        if (
            normalized_text(current_text) == normalized_text(message)
            and existing_names == expected_names
        ):
            # Idempotent retry after a previous stage succeeded but a later check failed.
            return
        raise ValueError("composer already contains a different draft; refusing to overwrite it")

    if attachments and not existing_names:
        upload_files(client, [str(path) for path in attachments])
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if composer_state(client)["attachmentNames"] == expected_names:
                break
            time.sleep(0.5)
        else:
            raise TimeoutError("attachment selection was applied, but filename chips did not appear")

    focus_composer(client)
    client.call_tool("type_text", {"text": message})
    if normalized_text(composer_state(client).get("text", "")) != normalized_text(message):
        raise RuntimeError("composer text did not match the requested message")


def submit_message(client: FirefoxMCPClient, message: str, timeout: float = 30) -> None:
    before = evaluate(
        client,
        "() => ({userCount: document.querySelectorAll("
        "'[data-message-author-role=\"user\"]').length, "
        "sendButtons: Array.from(document.querySelectorAll('button')).filter(button => { "
        "const label = (button.getAttribute('aria-label') || button.innerText || '').trim(); "
        "return /^(send|send message)$/i.test(label) && "
        "button.getClientRects().length > 0 && !button.disabled; }).length})",
    )
    if not isinstance(before, dict) or before.get("sendButtons") != 1:
        raise ValueError("could not identify one enabled Send button; message remains staged")
    previous_user_count = before["userCount"]
    send_uid = uid_for_snapshot_line(
        snapshot(client, includeAll=True, includeAttributes=True, maxLines=400),
        re.compile(r'\bbutton\s+"(?:send|send message)"', re.IGNORECASE),
    )
    client.call_tool("click_by_uid", {"uid": send_uid})

    expected = normalized_text(message)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        state = evaluate(
            client,
            "() => ({users: Array.from(document.querySelectorAll("
            "'[data-message-author-role=\"user\"]')).map(element => element.innerText || ''), "
            "composer: Array.from(document.querySelectorAll("
            "'[contenteditable=\"true\"][aria-label*=\"Ask ChatGPT\"]'))"
            ".map(element => element.innerText || '')})",
        )
        if isinstance(state, dict) and len(state.get("users", [])) > previous_user_count:
            latest_message = normalized_text(state["users"][-1])
            composer_cleared = len(state.get("composer", [])) == 1 and not state["composer"][0].strip()
            try:
                attachments_cleared = not composer_state(client)["attachmentNames"]
            except Exception:
                attachments_cleared = False
            if latest_message == expected and composer_cleared and attachments_cleared:
                return
        time.sleep(0.5)
    raise TimeoutError(
        "Send was clicked, but the new user message and cleared composer were not both "
        "confirmed; do not retry automatically"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=os.getenv("CUSTODIAN_CHAT_URL"), required=not os.getenv("CUSTODIAN_CHAT_URL"),
                        help="exact conversation URL (or CUSTODIAN_CHAT_URL)")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--text", help="message text")
    source.add_argument("--text-file", help="UTF-8 file containing the message")
    parser.add_argument("--attachment", action="append", default=[], metavar="PATH",
                        help="local attachment path; repeat as needed (for example ~/Downloads/review.zip)")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--stage", action="store_true",
                        help="attach files and fill the composer, leaving it unsent")
    action.add_argument("--submit", action="store_true",
                        help="attach files, fill the composer, and click Send")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        url = args.url
        canonical_url(url)
        message = read_message(args.text, args.text_file)
        attachments = resolve_attachments(args.attachment)
        if not args.stage and not args.submit:
            print(f"DRY RUN: target={url}; message_chars={len(message)}; attachments={[p.name for p in attachments]}")
            print("No browser state changed. Add --stage to fill the composer or --submit to send.")
            return 0

        with FirefoxMCPClient() as client:
            select_conversation(client, url)
            stage_message(client, message, attachments)
            if args.submit:
                submit_message(client, message)
                print(f"SENT: conversation={url}; message_chars={len(message)}; attachments={len(attachments)}")
            else:
                print(f"STAGED: conversation={url}; message_chars={len(message)}; attachments={len(attachments)}; not sent")
        return 0
    except Exception as exc:
        print(f"SEND ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
