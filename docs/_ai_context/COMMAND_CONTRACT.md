# COMMAND CONTRACT — CUSTODIAN

## Status
- Implemented end-to-end between terminal frontend and backend command processor.

## Transport
- Client submit path: `custodian-terminal/terminal.js` posts commands to `/command`.
- Server handler: `custodian-terminal/streaming-server.py` parses request JSON, dispatches to `process_command`, and serializes `CommandResult`.

## Request Shape
- Method: `POST`
- Path: `/command`
- Canonical JSON body: `{ "command": "<string>" }`
- Temporary fallback JSON body: `{ "raw": "<string>" }`

Notes:
- Empty or whitespace input is treated as unknown command.
- Command verb parsing is case-insensitive; frontend currently uppercases local input rendering.

## Response Shape
- `ok` (boolean): command acceptance/execution status.
- `text` (string): single primary operator-facing line.
- `lines` (optional string[]): ordered detail lines appended after `text`.
- `warnings` (optional string[]): non-fatal warning lines.

## Implemented Command Set
- `STATUS`: read-only snapshot (`TIME`, `THREAT`, `ASSAULT`, `SECTORS`).
- `WAIT`: advances simulation by exactly one tick and returns concise event/assault/failure lines when applicable; otherwise returns one terse `[PRESSURE]` fallback line.
- `HELP`: returns command list.
- `RESET` / `REBOOT`: accepted in processor for failure recovery and state reset.

## Failure and Error Semantics
- Unknown/invalid command line:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["TYPE HELP FOR AVAILABLE COMMANDS."]`
- Failure lockout (Command Center breached):
  - Non-reset verbs return `ok=false`
  - `text` set to failure reason (`COMMAND CENTER BREACHED.` when latched by simulation)
  - `lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]`
- `RESET` or `REBOOT` during lockout return:
  - `ok=true`
  - `text="SYSTEM REBOOTED."`
  - `lines=["SESSION READY."]`

## Runtime Notes
- Backend state is process-local and persistent while the Flask server process is running.
- Endpoint does not perform auth in current prototype scope.
