# Firefox ChatGPT Relay Send and Poll Fix V1 Completion Summary

Authoring chat: not-recorded

## Outcome
- Status: success
- What changed: Scoped Firefox accessibility snapshots to the unique enabled Send button's accessible label, added support for ChatGPT's current `data-user-message-bubble` transcript marker during delivery verification, and made the response reader wait while the UI reports `data-response-starting`. Documented Python-first sending and two-minute Python polling, with Firefox MCP as a selector/debug fallback.
- Files changed: `CUSTODIAN_CHAT_RELAY.md`; `custodian/tools/orchestration/send_chatgpt_message.py`; `custodian/tools/orchestration/get_chatgpt_response.py`; `custodian/tools/orchestration/test_chatgpt_relay_firefox.py`.

## Validation
- `python3 -W error::ResourceWarning -m unittest discover -s custodian/tools/orchestration -p 'test_*.py' -v`: passed, 17 tests.
- Focused regression tests were observed failing before the corresponding changes, then passing.
- `python3 -m py_compile` on the relay scripts, client, and tests: passed.
- `git diff --check`: passed.
- Python response-reader smoke against the exact ChatGPT conversation: passed; stable response detected, output withheld from validation log.
- Sender dry run: passed; no browser state changed during validation.

## Process Feedback
- Friction severity: low
- What went wrong: The previous sender used an unscoped snapshot that omitted the visible Send control; its post-click confirmation also counted only an older user-message attribute, causing a false delivery timeout.
- Root cause / contributing factors: ChatGPT's current page uses a Send button that is surfaced by an accessible-label-scoped snapshot and user bubbles marked with `data-user-message-bubble`.
- Tooling / docs drift discovered: The Python response reader already supports the current user-bubble marker and two-minute polling, but the operator procedure incorrectly prioritized Firefox MCP page inspection.
- Follow-up: fixed-in-scope

## Next Handoff
- Next packet: none
- Next packet state: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Use `send_chatgpt_message.py --submit`, then `get_chatgpt_response.py --wait --interval 120 --max-wait 600`; use Firefox MCP to diagnose the visible UI only when Python cannot safely identify it.
- Blockers or open questions: none
