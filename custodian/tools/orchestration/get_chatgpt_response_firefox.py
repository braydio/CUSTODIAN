#!/usr/bin/env python3
"""Read the completed reply to one ChatGPT browser turn via Firefox MCP.

Read-only browser adapter. No private endpoints, auth data, page navigation, or writes.
Firefox must already be running with Marionette enabled on port 2828. The script
starts a short-lived Firefox DevTools MCP client and attaches to that instance.

Exit 0: exactly 'RESPONSE IN PROGRESS' or the completed assistant text.
Exit 2: cannot safely identify the tab, request, or browser state.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time

try:
    from .firefox_mcp_client import (
        FirefoxMCPClient,
        canonical_url,
        evaluate,
        select_conversation,
    )
except ImportError:  # direct script invocation
    from firefox_mcp_client import (
        FirefoxMCPClient,
        canonical_url,
        evaluate,
        select_conversation,
    )

IN_PROGRESS = "RESPONSE IN PROGRESS"

# Operates on visible conversation DOM, not ChatGPT's private application APIs.
PROBE_JS = r"""({requestId}) => {
  const selector = [
    '[data-message-author-role="user"]',
    '[data-message-author-role="assistant"]',
    '[data-user-message-bubble="true"]',
    '[data-dil-message-id]'
  ].join(', ');

  const entries = Array.from(document.querySelectorAll(selector))
    .filter(el => el instanceof HTMLElement)
    .map(el => ({
      role: el.getAttribute('data-message-author-role') ||
        (el.hasAttribute('data-user-message-bubble') ? 'user' : 'assistant'),
      text: (el.innerText || '').trim(),
      id: el.getAttribute('data-message-id') || ''
    }));

  const users = entries
    .map((entry, index) => ({ entry, index }))
    .filter(row => row.entry.role === 'user');

  if (users.length === 0) {
    return { kind: 'error', reason: 'NO_USER_MESSAGES' };
  }

  const latestUserIndex = users[users.length - 1].index;
  let index = latestUserIndex;

  if (requestId) {
    const matches = users.filter(row => row.entry.text.includes(requestId));

    if (matches.length === 0) {
      return { kind: 'error', reason: 'REQUEST_ID_NOT_FOUND' };
    }

    index = matches[matches.length - 1].index;

    if (latestUserIndex > index) {
      return { kind: 'error', reason: 'NEWER_USER_MESSAGE' };
    }
  }

  const replies = entries
    .slice(index + 1)
    .filter(entry => entry.role === 'assistant');

  const text = replies
    .map(entry => entry.text)
    .filter(Boolean)
    .join('\n\n')
    .trim();

  const isVisible = el => !!(el && el.getClientRects().length);

  const stop = Array.from(document.querySelectorAll(
    'button[data-testid="stop-button"], button[data-testid="composer-stop-button"], ' +
    'button[aria-label*="Stop generating" i], button[aria-label*="Stop streaming" i], ' +
    'button[aria-label="Stop"], button[title="Stop"], [data-response-starting]'
  )).some(isVisible);

  const starting = Array.from(document.querySelectorAll('[data-response-starting]'))
    .some(isVisible);
  const streaming = !!document.querySelector(
    '[data-message-author-role="assistant"] .result-streaming, ' +
    '[data-message-author-role="assistant"][aria-busy="true"], ' +
    '[data-dil-message-id] [aria-busy="true"], ' +
    '[data-talvt-turn-state="in_progress"] [data-dil-message-id], ' +
    '[data-response-starting]'
  );

  return {
    kind: 'sample',
    text,
    busy: stop || streaming || starting,
    starting,
    assistantCount: replies.length,
    latestUserIndex
  };
}"""


def probe(client: FirefoxMCPClient, request_id: str | None) -> dict:
    function = f"() => ({PROBE_JS})({json.dumps(request_id or '')})"
    result = evaluate(client, function)
    if not isinstance(result, dict):
        raise ValueError("Firefox MCP returned an invalid conversation probe")
    return result


def read_once(client: FirefoxMCPClient, request_id: str | None, settle_seconds: float) -> str:
    first = probe(client, request_id)
    if first.get("kind") == "error":
        raise ValueError(first.get("reason", "UNKNOWN_REQUEST_ERROR"))
    if first.get("kind") != "sample":
        raise ValueError(f"unexpected conversation probe result: {first!r}")
    if first.get("busy") or first.get("starting"):
        return IN_PROGRESS
    if not first.get("text"):
        return IN_PROGRESS
    time.sleep(settle_seconds)
    second = probe(client, request_id)
    if second.get("kind") == "error":
        raise ValueError(second.get("reason", "UNKNOWN_REQUEST_ERROR"))
    if (
        second.get("kind") != "sample"
        or second.get("busy")
        or second.get("starting")
        or second.get("assistantCount") != first.get("assistantCount")
        or not second.get("text")
        or second.get("text") != first.get("text")
    ):
        return IN_PROGRESS
    return second["text"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--url",
        default=os.getenv("CUSTODIAN_CHAT_URL"),
        help="Conversation URL (or CUSTODIAN_CHAT_URL); optional if exactly one chat tab is open",
    )
    parser.add_argument(
        "--request-id",
        default=None,
        help="Exact unique identifier included in the submitted user message",
    )
    parser.add_argument(
        "--settle",
        type=float,
        default=2.0,
        help="Seconds of unchanged reply text and no stop control required (default: 2)",
    )
    parser.add_argument(
        "--wait", action="store_true", help="Poll locally until a reply or deadline"
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=120.0,
        help="Seconds between checks in --wait mode (default: 120)",
    )
    parser.add_argument(
        "--max-wait",
        type=float,
        default=600.0,
        help="Maximum seconds in --wait mode (default: 600)",
    )
    args = parser.parse_args()
    if not 0.5 <= args.settle <= 30 or args.interval < 2 or args.max_wait < 0:
        parser.error("invalid timing arguments")
    if args.url:
        canonical_url(args.url)
    try:
        with FirefoxMCPClient() as client:
            select_conversation(client, args.url)
            deadline = time.monotonic() + args.max_wait
            while True:
                result = read_once(client, args.request_id, args.settle)
                if (
                    result != IN_PROGRESS
                    or not args.wait
                    or time.monotonic() >= deadline
                ):
                    print(result)
                    return 0
                time.sleep(min(args.interval, max(0.0, deadline - time.monotonic())))
    except Exception as exc:
        # Keep the low-token stdout contract: diagnostics only on stderr.
        print(f"RELAY ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
