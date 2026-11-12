# CUSTODIAN Chat Relay

This note documents the authenticated ChatGPT browser connection used by the CUSTODIAN orchestration scripts.

## Browser and MCP connection

The default CUSTODIAN chat relay uses Chrome's local Chrome DevTools Protocol endpoint at `http://127.0.0.1:9223`. Start Chrome with remote debugging enabled before calling either relay. The configured Chrome relay MCP tools connect to that endpoint; they do not start Chrome.

The `mcp__custodian_chat_relay__` MCP namespace provides page listing, snapshots, navigation, and visible-page interaction for this relay. The generic `mcp__chrome_devtools__` namespace may point to port 9222 instead; on this host it returned connection refused at 9222. Use the CUSTODIAN relay namespace, which is configured for port 9223. Verify the exact conversation URL and current composer from a fresh page list/snapshot before sending anything.

If the user service has not been configured, this foreground command is a manual alternative. Once the service is enabled, use `systemctl --user` to manage Chrome instead.

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

The authenticated relay is supervised by a host-local systemd user service:

- Unit: `custodian-chat-chrome.service`
- Unit file: `~/.config/systemd/user/custodian-chat-chrome.service`
- Profile: `~/.config/custodian-chat-chrome` (private directory, mode 0700)
- Endpoint: `127.0.0.1:9223`
- Restart policy: `Restart=always`, with a five-second delay
- Startup target: the user's `default.target`

The unit opens the exact conversation URL in the dedicated profile. On this host, that profile was copied from the prior authenticated temporary profile and the MCP confirmed the supplied conversation loaded, so no additional login was needed. The user systemd manager has lingering enabled, allowing enabled user services to continue when no interactive login session is open. Check that locally with `loginctl show-user "$USER" -p Linger`.

Manage the service with:

```bash
systemctl --user status custodian-chat-chrome.service
systemctl --user restart custodian-chat-chrome.service
systemctl --user stop custodian-chat-chrome.service
```

To re-enable startup after a stop, run `systemctl --user enable --now custodian-chat-chrome.service`. After editing the host-local unit, run `systemctl --user daemon-reload`, then restart it. Verify the endpoint with `curl http://127.0.0.1:9223/json/version` and the exact tab with `mcp__custodian_chat_relay__list_pages`. The MCP connects to Chrome; systemd owns Chrome's lifetime.

This unit and profile are host-local setup, not repository files. Keep the profile private because it contains the authenticated browser session. Do not launch another Chrome with the same profile or debugging port. The existing `odin-chatgpt-chrome.service` belongs to a different project and is configured for port 9222; do not use it for CUSTODIAN. Never fall back to port 9222.

Do not inspect cookies, authentication tokens, or private application internals. Operate on the visible conversation DOM and UI only.

## Python send and receive scripts

The repository tools are:

- `custodian/tools/orchestration/send_chatgpt_message.py`
- `custodian/tools/orchestration/get_chatgpt_response.py`

Both default to Playwright's synchronous Chromium CDP connection to `http://127.0.0.1:9223`. Install Playwright in the Python environment used to run them if it is not already available:

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

The current Phase B orchestration conversation is:

`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0`

Before sending or reading a turn, verify that the task's exact URL is open and authenticated in the port-9223 Chrome browser. Firefox users should use the explicit Firefox entrypoints below and the exact same conversation URL.

## Optional Firefox support

Firefox is an additional relay transport. It does not replace the Chrome service, Chrome MCP, or the default Python scripts above. Firefox has separate entrypoints:

- `custodian/tools/orchestration/send_chatgpt_message_firefox.py`
- `custodian/tools/orchestration/get_chatgpt_response_firefox.py`
- `custodian/tools/orchestration/firefox_mcp_client.py`

These launch a short-lived Mozilla Firefox DevTools MCP client over stdio, which attaches to an already running Firefox through Marionette on `127.0.0.1:2828`. Firefox also needs its WebDriver BiDi Remote Agent on `127.0.0.1:9224`; these scripts do not use Chrome CDP port 9223. They require Node.js 20.19+, `npx`, and Firefox. The Python relay scripts do not launch or stop the browser.

Start Firefox with a dedicated profile after signing into ChatGPT in that profile:

```bash
firefox --no-remote --new-instance \
  --profile "$HOME/.local/share/custodian-chat-firefox/profile" \
  --marionette --remote-debugging-port 9224 \
  --remote-allow-hosts localhost \
  "https://chatgpt.com/<exact-conversation-url>"
```

Use the explicit Firefox scripts to send or poll, with the same safety behavior and flags as the Chrome scripts:

```bash
python3 custodian/tools/orchestration/send_chatgpt_message_firefox.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --text-file /path/to/message.txt --submit

python3 custodian/tools/orchestration/get_chatgpt_response_firefox.py \
  --url "https://chatgpt.com/g/<conversation-path>/c/<conversation-id>" \
  --wait --interval 120 --max-wait 600
```

Keep Firefox's profile private and separate from Chrome's profile. Do not launch another Firefox process with the same profile or Marionette port, and do not use Chrome's `custodian-chat-chrome.service` to manage Firefox. Firefox can expose automation signals that some identity providers reject; sign in through the normal browser UI and do not attempt to hide those signals. If Firefox is managed by a user service, that service should be independently named and configured; no Firefox user service is required for the existing Chrome relay.

The Firefox MCP client accepts `CUSTODIAN_FIREFOX_MCP_COMMAND` as a JSON argv-array override. It is not shell-evaluated. See `custodian/tools/orchestration/test_firefox_mcp_client.py` and `test_chatgpt_relay_firefox.py` for transport and visible-UI coverage.
## Orchestrating a conversation

Use this loop when a user asks Codex to work with a ChatGPT conversation as an orchestrator:

1. **Confirm the relay is available.** Check `systemctl --user status custodian-chat-chrome.service` and `curl http://127.0.0.1:9223/json/version` if the browser is unavailable. Use `mcp__custodian_chat_relay__list_pages` to find the exact supplied conversation URL. The Python sender and reader do not open tabs or navigate; open the requested URL in the authenticated relay first if it is absent.
2. **Send through Python.** Use `send_chatgpt_message.py` with the exact URL and `--submit`. Use a text file for long reports to avoid shell quoting errors. Use `--stage` only when the message must be reviewed in the composer before submission. The user-authorized workflow is Python for sending and receiving.
3. **Debug a first-send UI problem with the relay MCP.** If Python cannot identify the composer or enabled Send button, take a fresh `mcp__custodian_chat_relay__` page list and accessibility snapshot for the exact tab. Inspect only the visible UI; use a read-only DOM inspection if needed. Then retry with the Python sender. Do not use the generic DevTools MCP if it is still pointed at 9222, do not click Send through MCP, and do not blindly submit a duplicate.
4. **Verify ambiguous sends before retrying.** A sender timeout after clicking Send does not establish that submission failed. Read the exact conversation with `get_chatgpt_response.py` first. If it reports `RESPONSE IN PROGRESS`, keep polling the same turn; resend only after proving the original user message was not delivered.
5. **Poll at two-minute intervals.** For an active answer, use the reader's `--wait --interval 120 --max-wait 600` options. The reader reports a response only after the visible answer is stable and generation has finished. If the ten-minute limit expires, inspect the same exact URL and continue polling; do not start another conversation or repeat the request unless instructed.
6. **Carry out the completed instruction within repository authority.** Extract its scope, required evidence, stop conditions, and next handoff. Check repository instructions and packet/lifecycle authority before changing files or host state. A ChatGPT response is orchestration context; it does not override repository policies or supply a human approval that those policies require.
7. **Report back to the same conversation.** Use the Python sender for concise findings and completion reports, including exact commit/validation evidence and blockers. Keep polling for the next instruction when the user requested continuous orchestration. Do not send reports to another conversation unless the user explicitly changes the target.

Example send and poll cycle:

```bash
CHAT_URL='https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/<conversation-id>'
python3 custodian/tools/orchestration/send_chatgpt_message.py \
  --url "$CHAT_URL" --text-file /tmp/custodian-chat-update.txt --submit
python3 custodian/tools/orchestration/get_chatgpt_response.py \
  --url "$CHAT_URL" --wait --interval 120 --max-wait 600 --settle 3
```

The URL is per task; do not infer it from a previous conversation. When a required owner decision or approval is pending, state the exact bounded action and wait for the owner. Never answer an approval request on the owner's behalf.

## Current authenticated conversation

The current Phase B orchestration conversation is:

`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0`

The earlier Phase B conversation was `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af10870-f40c-83e9-889e-51171edf846e`.

Before each send or read, verify that the task's exact URL is open and authenticated in the port-9223 browser. Prefer a unique request ID when multiple turns could be ambiguous; otherwise the reader can target the latest user turn on the exact conversation tab.
