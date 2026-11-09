# CUSTODIAN Chat Relay

This note documents the authenticated ChatGPT browser connection used by the CUSTODIAN orchestration scripts.

## Firefox and MCP connection

The Python sender and response reader use Mozilla's Firefox DevTools MCP server over stdio. They do not use Chrome CDP or Playwright. Each script starts a short-lived MCP client, attaches to the already-running Firefox through Marionette, selects an exact existing ChatGPT conversation tab, and exits without starting or closing Firefox.

The default MCP command is:

```bash
npx -y @mozilla/firefox-devtools-mcp@latest \
  --connect-existing --marionette-port 2828 --idle-timeout 1800 \
  --tool-preset developer
```

The Python tools use the MCP `list_pages`, `select_page`, `evaluate_script`, `take_snapshot`, `click_by_uid`, `type_text`, and `upload_file_by_uid` tools. They inspect and interact with visible page DOM only; they do not call ChatGPT private APIs or inspect cookies and authentication tokens. The sender never navigates or opens a tab. It only stages a message or submits it when `--submit` is explicitly supplied. The reader is read-only.

## Firefox service

Keep Firefox's lifetime under a systemd user service or another process manager. Use a dedicated profile for the CUSTODIAN relay, separate from the profile used for everyday browsing. A compatible foreground launch is:

```bash
firefox --no-remote --new-instance \
  --profile "$HOME/.local/share/custodian-chat-firefox/profile" \
  --marionette --remote-debugging-port 9224 \
  --remote-allow-hosts localhost \
  "https://chatgpt.com/<exact-conversation-url>"
```

Firefox must be running with Marionette on `127.0.0.1:2828` and its WebDriver BiDi Remote Agent on `127.0.0.1:9224`. The Python scripts connect through MCP; they do not use port 9224 directly. Do not launch a second Firefox process with the same profile or Marionette port. Firefox accepts one automation client at a time, so do not run a Python relay script while another MCP client is actively attached to this Firefox instance.

The process that starts Firefox owns its lifetime. To inspect a user service, use:

```bash
systemctl --user status firefox-devtools-browser.service
systemctl --user restart firefox-devtools-browser.service
systemctl --user stop firefox-devtools-browser.service
```

Mozilla documents that Marionette exposes automation signals such as `navigator.webdriver`; Google and other identity providers may reject sign-in from an automated session. Sign in manually in a normal Firefox session using the same dedicated profile, close it fully, then start the profile with Marionette. If the provider continues to block access, stop and use the normal browser for ChatGPT rather than trying to hide automation signals.

The profile is host-local authentication state, not a repository file. Keep it private. Never copy its cookies or token databases into Git, inspect them, or publish them in logs.

## Python sender and response reader

The repository tools are:

- `custodian/tools/orchestration/send_chatgpt_message.py`
- `custodian/tools/orchestration/get_chatgpt_response.py`
- `custodian/tools/orchestration/firefox_mcp_client.py`

They require Python 3.10+, Node.js 20.19+, Firefox 100+, and `npx`. The npm MCP package is fetched on demand. To use a different local command, set `CUSTODIAN_FIREFOX_MCP_COMMAND` to a JSON argv array; it is never evaluated through a shell. The Python relay has no Playwright dependency.

The sender requires an exact conversation URL and selects exactly one already-open matching tab. Without an action flag it only prints a dry-run summary. `--stage` fills the visible composer and optionally attaches files but leaves the message unsent. `--submit` stages and clicks the visible Send button.

```bash
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --text-file /path/to/message.txt --stage

# After inspecting the staged composer, explicitly submit:
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --text-file /path/to/message.txt --submit
```

Use `--text "message"` instead of `--text-file` for short messages. Attachments can be supplied with one or more `--attachment /path/to/file` options. The script refuses to overwrite a different draft or replace existing attachments. Submission sends a message to the conversation, so keep `--submit` explicit.

The response reader requires exactly one matching conversation tab. `--url` is optional only when exactly one ChatGPT conversation is open. It can match the user turn with a unique request ID included in the submitted message and reports `RESPONSE IN PROGRESS` until the reply is stable and generation is complete.

```bash
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --request-id "unique-request-id"

# Poll locally, checking every two minutes for up to ten minutes:
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --request-id "unique-request-id" --wait --interval 120 --max-wait 600
```

A completed answer is printed to stdout; connection and selector diagnostics go to stderr. A timeout after clicking Send does not establish whether submission succeeded. Read the exact conversation before considering a retry; never blindly resend.

## Orchestrating a conversation

Use this loop when a user asks Codex to work with a ChatGPT conversation as an orchestrator:

1. **Confirm the relay is available.** Check the Firefox user service and use `mcp__firefox_devtools__list_pages` to find the exact supplied conversation URL. The Python sender and reader do not open tabs or navigate; open the requested URL in the authenticated relay first if it is absent.
2. **Send through Python.** Use `send_chatgpt_message.py` with the exact URL and `--submit`. Use a text file for long reports. Use `--stage` only when the message must be reviewed in the composer before submission.
3. **Debug a first-send UI problem with Firefox MCP.** If Python cannot identify the composer or enabled Send button, take a fresh page list and accessibility snapshot for the exact tab. Inspect only the visible UI, then retry with the Python sender. Do not click Send through MCP or blindly submit a duplicate.
4. **Verify ambiguous sends before retrying.** Read the exact conversation with `get_chatgpt_response.py` first. If it reports `RESPONSE IN PROGRESS`, keep polling the same turn; resend only after proving the original user message was not delivered.
5. **Poll at two-minute intervals.** For an active answer, use `--wait --interval 120 --max-wait 600`. If the ten-minute limit expires, inspect the same exact URL and continue polling; do not start another conversation or repeat the request unless instructed.
6. **Carry out the completed instruction within repository authority.** Extract its scope, required evidence, stop conditions, and next handoff. A ChatGPT response is orchestration context; it does not override repository policies or supply human approval that those policies require.
7. **Report back to the same conversation.** Use the Python sender for concise findings and completion reports, including exact commit, validation evidence, and blockers. Do not send reports to another conversation unless the user explicitly changes the target.

Example send and poll cycle:

```bash
CHAT_URL='https://chatgpt.com/g/<conversation-path>/c/<conversation-id>'
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "$CHAT_URL" --text-file /tmp/custodian-chat-update.txt --submit
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "$CHAT_URL" --wait --interval 120 --max-wait 600 --settle 3
```

The conversation URL is per task; do not infer it from an earlier conversation. When an owner decision or approval is pending, state the exact bounded action and wait for the owner. Never answer an approval request on the owner's behalf.
