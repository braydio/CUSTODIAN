# COMMAND CONTRACT — CUSTODIAN

## Status
- Draft. Not implemented end-to-end.

## Transport
- Client: `custodian-terminal/terminal.js` (submit handler).
- Server: `custodian-terminal/server.py` (to be added).

## Request Shape (Proposed)
- Method: `POST`
- Path: `/command`
- JSON body:
  - `command`: string (raw user input)
  - `timestamp`: ISO 8601 string (client time)
  - `session_id`: string (optional)

## Response Shape (Proposed)
- JSON body:
  - `ok`: boolean
  - `lines`: string[] (terminal lines to append)
  - `error`: string | null
  - `authority`: "residual" | "denied" | "command_center" (optional)

## Command Grammar (Proposed)
- Single-line commands, case-insensitive keyword first.
- Examples:
  - `HELP`
  - `STATUS`
  - `WAIT [ticks]`

## Authority Rules (Proposed)
- Read-only commands permitted anywhere.
- Write commands require Command Center authority.
- Denied actions return `ok=false` with a one-line reason.

## Error Semantics (Proposed)
- Unknown command: `ok=false`, `error="unknown-command"`, `lines=["Unrecognized command."]`
- Malformed arguments: `ok=false`, `error="invalid-args"`, `lines=["Invalid arguments."]`

## Notes
- This contract must be kept in sync between JS and Python implementations.
