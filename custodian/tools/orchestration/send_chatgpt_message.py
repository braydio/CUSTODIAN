#!/usr/bin/env python3
"""Stage or send a message to an exact ChatGPT conversation via Chrome CDP.

This script uses the visible ChatGPT composer and attachment input. It never
navigates, creates a tab, or submits unless --submit is explicitly provided.
Chrome must already expose remote debugging on 127.0.0.1:9223.

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
from urllib.parse import urlsplit

CDP_ENDPOINT = "http://127.0.0.1:9223"


def canonical_url(url: str) -> str:
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


def select_tab(browser, url: str):
    wanted = canonical_url(url)
    matches = [
        page
        for context in browser.contexts
        for page in context.pages
        if not page.is_closed()
        and is_conversation(page.url)
        and canonical_url(page.url) == wanted
    ]
    if len(matches) != 1:
        raise ValueError(f"expected exactly one matching conversation tab; found {len(matches)}")
    return matches[0]


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


def staged_attachment_names(composer_form) -> list[str]:
    chip_names = composer_form.locator('button[aria-label^="Remove "]').evaluate_all(
        "buttons => buttons.map(button => "
        "button.getAttribute('aria-label').replace(/^Remove\\s+/, '').trim())"
    )
    chip_names = [name for name in chip_names if name]
    input_names = composer_form.locator('input[type="file"]').evaluate_all(
        "inputs => inputs.flatMap(input => Array.from(input.files || [], file => file.name))"
    )
    if chip_names and input_names and chip_names != input_names:
        raise ValueError("attachment chips and file inputs disagree; refusing to modify the draft")
    return chip_names or input_names


def stage_message(page, message: str, attachments: list[Path]) -> None:
    composer = page.locator('[contenteditable="true"][aria-label*="Ask ChatGPT"]:visible')
    if composer.count() != 1 or not composer.is_visible():
        raise ValueError("could not identify exactly one visible ChatGPT composer")
    composer_form = composer.locator("xpath=ancestor::form[1]")
    if composer_form.count() != 1:
        raise ValueError("could not safely scope attachment verification to the composer form")
    existing_names = staged_attachment_names(composer_form)
    expected_names = [path.name for path in attachments]
    if len(expected_names) != len(set(expected_names)):
        raise ValueError("requested attachments contain duplicate filenames")
    if existing_names and existing_names != expected_names:
        raise ValueError(
            "composer already has different staged attachments; refusing to replace or duplicate them"
        )
    if not attachments and existing_names:
        raise ValueError("composer already has attached files; refusing to send them with this message")

    current_text = composer.inner_text()
    if current_text.strip():
        if (
            normalized_text(current_text) == normalized_text(message)
            and existing_names == expected_names
        ):
            # Idempotent retry after a previous stage succeeded but a later check failed.
            return
        raise ValueError("composer already contains a different draft; refusing to overwrite it")

    if attachments and not existing_names:
        file_input = page.locator('input[type="file"][aria-label="Attach files"]')
        if file_input.count() != 1:
            raise ValueError("could not identify ChatGPT's Attach files input")
        file_input.set_input_files([str(path) for path in attachments])
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if staged_attachment_names(composer_form) == expected_names:
                break
            time.sleep(0.5)
        else:
            raise TimeoutError("attachment selection was applied, but filename chips did not appear")

    composer.fill(message)
    if normalized_text(composer.inner_text()) != normalized_text(message):
        raise RuntimeError("composer text did not match the requested message")


def submit_message(page, message: str, timeout: float = 30) -> None:
    composer = page.locator('[contenteditable="true"][aria-label*="Ask ChatGPT"]:visible')
    composer_form = composer.locator("xpath=ancestor::form[1]")
    previous_user_count = page.locator('[data-message-author-role="user"]').count()
    send = page.get_by_role("button", name=re.compile(r"^(send|send message)$", re.I))
    if send.count() != 1 or not send.is_visible() or not send.is_enabled():
        raise ValueError("could not identify one enabled Send button; message remains staged")
    send.click()

    expected = normalized_text(message)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        user_messages = page.locator('[data-message-author-role="user"]')
        if user_messages.count() > previous_user_count:
            latest_message = normalized_text(user_messages.last.inner_text())
            composer_cleared = not composer.inner_text().strip()
            try:
                attachments_cleared = not staged_attachment_names(composer_form)
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

        from playwright.sync_api import sync_playwright

        with sync_playwright() as playwright:
            browser = playwright.chromium.connect_over_cdp(CDP_ENDPOINT, timeout=8000)
            page = select_tab(browser, url)
            stage_message(page, message, attachments)
            if args.submit:
                submit_message(page, message)
                print(f"SENT: conversation={url}; message_chars={len(message)}; attachments={len(attachments)}")
            else:
                print(f"STAGED: conversation={url}; message_chars={len(message)}; attachments={len(attachments)}; not sent")
        return 0
    except Exception as exc:
        print(f"SEND ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
