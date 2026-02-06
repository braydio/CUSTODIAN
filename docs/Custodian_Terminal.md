# Custodian Terminal UI

Text-only terminal UI prototype for the custodian interface. The boot sequence runs from `custodian-terminal/boot.js`, while `custodian-terminal/terminal.js` owns command input, transcript rendering, and backend command submission. Input stays disabled through boot and the system log, then unlocks when command mode is active. An SSE-capable boot variant exists at `custodian-terminal/server-streaming-boot.js`.

## Behavior Notes

- Boot lines render with the existing type-in effect, then a system log prints before command mode.
- The terminal module tracks a buffered history and appends command/response transcript lines.
- System log introduces `STATUS`, `WAIT`, and `HELP` before input unlock.
- Prompt input posts to `POST /command` with canonical `{command}` (legacy `{raw}` accepted server-side) and appends returned `text` plus optional `lines`/`warnings` (served by `custodian-terminal/streaming-server.py`).
- Prompt interaction stays minimal by design and remains inside the terminal frame.
