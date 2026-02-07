# COMMAND CONTRACT — CUSTODIAN

## Status
- Implemented end-to-end between terminal frontend and backend command processor.
- `/command` is live on both Flask server surfaces used in prototypes:
  - `custodian-terminal/streaming-server.py` (UI webserver)
  - `game/simulations/world_state/server.py` (world-state server module)

## Transport
- Client submit path: `custodian-terminal/terminal.js` posts JSON commands to `/command` using `{ "command": "<string>" }`.
- UI server handler: `custodian-terminal/streaming-server.py` reads `command` first, then legacy `raw`, dispatches to `process_command`, and serializes `CommandResult`.
- World-state server handler: `game/simulations/world_state/server.py` reads `command` first, then legacy `raw`, validates non-empty string input, dispatches to `process_command`, and serializes `CommandResult`.

## Request Shape
- Method: `POST`
- Path: `/command`
- Canonical JSON body: `{ "command": "<string>" }`
- Compatibility fallback: `{ "raw": "<string>" }`

Validation behavior:
- Canonical path is string `command` input from the browser terminal.
- `game/simulations/world_state/server.py` maps missing/empty/non-string input to unknown-command output.
- Parser trims whitespace and normalizes verb casing server-side.

## Response Shape
- `ok` (boolean): command acceptance/execution status.
- `text` (string): single primary operator-facing line.
- `lines` (optional string[]): ordered detail lines appended after `text`.
- `warnings` (optional string[]): non-fatal warning lines.

## Implemented Command Set
- `STATUS`
  - Returns high-level board snapshot:
    - `TIME: <int>`
    - `THREAT: LOW|ELEVATED|HIGH|CRITICAL`
    - `ASSAULT: NONE|PENDING|ACTIVE`
    - sector status list (`STABLE|ALERT|DAMAGED|COMPROMISED`)
  - Does not advance time.
- `WAIT`
  - Advances simulation by exactly one tick.
  - Primary line: `TIME ADVANCED.`
  - Optional detail lines for meaningful changes (`[EVENT]`, `[WARNING]`, assault start/end markers, failure termination lines).
- `HELP`
  - Returns locked operator-facing command list (`STATUS`, `WAIT`, `HELP`).
- `RESET` / `REBOOT`
  - Reset in-memory `GameState` and return:
    - `text="SYSTEM REBOOTED."`
    - `lines=["SESSION READY."]`

## Failure and Error Semantics
- Unknown/invalid command line:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["TYPE HELP FOR AVAILABLE COMMANDS."]`
- Failure lockout (Command Center breached):
  - Non-reset verbs return `ok=false`
  - `text` set to latched failure reason (typically `COMMAND CENTER BREACHED.`)
  - `lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]`

## Runtime Notes
- Backend authority is server-side (`process_command` mutates server-owned `GameState`).
- State is process-local and persistent while Flask process is running.
- Endpoint currently has no authentication in prototype scope.
