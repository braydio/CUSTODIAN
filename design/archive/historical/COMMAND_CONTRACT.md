# COMMAND CONTRACT — CUSTODIAN

## Status

- Implemented and shared by both Flask servers:
  - `custodian-terminal/server.py`
  - `game/simulations/world_state/server.py`
- Shared helpers live in `game/simulations/world_state/server_contracts.py`.

## Request

- Method: `POST`
- Path: `/command`
- Canonical body: `{ "command": "<string>" }`
- Compatibility fallback: `{ "raw": "<string>" }`
- Optional idempotency key: `{ "command_id": "<string>" }`
- Optional first-tick seed: `{ "seed": <int> }` (applied only when world time is `0`)

Validation behavior:

- Missing/empty/non-string command resolves to unknown-command output.
- Verb and arguments are parsed server-side via terminal parser.

## Response

Serialized payload shape:

- `ok` (boolean)
- `text` (string)
- `lines` (string[])

Serialization rule:

- `lines` always includes `text` first, then optional detail lines, then optional warnings.

## Error Semantics

Unknown command:

- `ok=false`
- `text="UNKNOWN COMMAND."`
- `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`

Failure lockout:

- Non-reset commands return:
  - `ok=false`
  - `text=<latched failure reason>`
  - `lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]`

## Snapshot Contract

- Method: `GET`
- Path: `/snapshot`
- Returns read-only `GameState.snapshot()` projection.
- Current snapshot schema version: `2`.

Snapshot includes world summary plus policy/defense/fabrication/repair/presence fields used by UI map and panel rendering.
