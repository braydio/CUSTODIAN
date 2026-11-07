# CUSTODIAN Chat Relay

This note documents the authenticated ChatGPT browser connection used by the CUSTODIAN orchestration scripts.

## Browser and MCP connection

The CUSTODIAN chat relay uses Chrome's local Chrome DevTools Protocol endpoint at `http://127.0.0.1:9223`. Start Chrome with remote debugging enabled before calling either relay. The configured MCP tools connect to that endpoint; they do not start Chrome.

The `mcp__custodian_chat_relay__` MCP namespace provides page listing, snapshots, navigation, and visible-page interaction. A `mcp__chrome_devtools__` namespace may also be available for browser inspection. Use the CUSTODIAN relay namespace for its configured relay session. Verify the exact conversation URL and current composer from a fresh page list/snapshot before sending anything.

Example direct launch:

```bash
google-chrome-stable \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9223 \
  --user-data-dir="$HOME/.config/custodian-chat-chrome" \
  --no-first-run \
  --no-default-browser-check \
  "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>"
```

Use a dedicated Chrome profile so Chrome can start with the debugging flag and the session does not collide with a regular Chrome instance. Sign in to ChatGPT in that profile when prompted. Keep the Chrome process alive while the MCP or scripts use it. Confirm the endpoint with `curl http://127.0.0.1:9223/json/version` and confirm pages with `mcp__custodian_chat_relay__list_pages`.

The port-9223 Chrome instance used for this relay has been launched directly as a foreground process. The existing user service found on this host, `odin-chatgpt-chrome.service`, belongs to a different project and is configured for port 9222; it is not the CUSTODIAN relay service and must not be used as one. No CUSTODIAN-specific systemd user unit is defined here. If persistent supervision is needed, create a separate user unit that launches Chrome with port 9223 and a dedicated persistent profile, then verify that only the intended Chrome owns the port. Do not point multiple services at the same debugging port or profile.

Never use port 9222 as a fallback for CUSTODIAN. Do not inspect cookies, authentication tokens, or private application internals. Operate on the visible conversation DOM and UI only.

## Python send and receive scripts

The repository tools are:

- `custodian/tools/orchestration/send_chatgpt_message.py`
- `custodian/tools/orchestration/get_chatgpt_response.py`

Both use Playwright's synchronous Chromium CDP connection to `http://127.0.0.1:9223`. Install Playwright in the Python environment used to run them if it is not already available:

```bash
python3 -m pip install playwright
```

The sender requires the exact conversation URL, selects exactly one already-open matching tab, and never navigates or opens a tab. Without an action flag it only prints a dry-run summary. `--stage` fills the visible composer and optionally attaches files but leaves the message unsent. `--submit` stages and clicks the visible Send button.

```bash
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>" \
  --text-file /path/to/message.txt --stage

# After inspecting the staged composer, explicitly submit:
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>" \
  --text-file /path/to/message.txt --submit
```

Use `--text "message"` instead of `--text-file` for short messages. Attachments can be supplied with one or more `--attachment /path/to/file` options. The script refuses to overwrite a non-empty, different draft or replace existing attachments. Submission should be explicit because it sends a message to the conversation.

The response reader is read-only. It inspects visible conversation messages, can match the user turn by a unique request ID included in the submitted message, and reports `RESPONSE IN PROGRESS` until the reply is stable and generation is complete.

```bash
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>" \
  --request-id "unique-request-id"

# Poll locally, checking every two minutes for up to ten minutes:
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>" \
  --request-id "unique-request-id" --wait --interval 120 --max-wait 600
```

The reader requires exactly one matching conversation tab. Omit `--request-id` only when reading the latest user turn is unambiguous. A completed answer is printed to stdout; connection and selector diagnostics go to stderr.

## Current authenticated conversation

The conversation supplied for the current orchestration work is:

`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac`

Before sending or reading a turn, verify that this exact URL is open and authenticated in the port-9223 browser.