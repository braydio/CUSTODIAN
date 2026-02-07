# COMMAND CONTRACT — CUSTODIAN

## Status
- Implemented end-to-end between terminal frontend and backend command processor.
- `/command` is live on both Flask server surfaces used in prototypes:
  - `custodian-terminal/streaming-server.py` (UI webserver)
  - `game/simulations/world_state/server.py` (world-state server module)

## Transport
- Client submit path: `custodian-terminal/terminal.js` posts JSON commands to `/command`.
- UI server handler: `custodian-terminal/server.py` parses request JSON, dispatches to `process_command`, and returns `{ok, lines}`.
- World-state server handler: `game/simulations/world_state/server.py` exposes the same payload contract and processing path.

## Request Shape
- Method: `POST`
- Path: `/command`
- JSON body: `{ "raw": "<string>" }`

Validation behavior:
- Canonical path is string `command` input from the browser terminal.
- `game/simulations/world_state/server.py` maps missing/empty/non-string input to unknown-command output.
- Parser trims whitespace and normalizes verb casing server-side.

## Response Shape
- `ok` (boolean): command acceptance/execution status.
- `lines` (string[]): ordered terminal lines (primary line first).

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
- `WAIT 10X`
  - Advances simulation by ten ticks.
  - Primary line: `TIME ADVANCED x10.`
  - Detail lines summarize events, warnings, assault transitions, and failure termination lines seen during the burst.
- `FOCUS <SECTOR_ID>`
  - Sets the focused sector by ID (for example `FOCUS POWER`).
  - Returns confirmation line: `[FOCUS SET] <SECTOR_NAME>`
  - Does not advance time.
- `HELP`
  - Returns locked operator-facing command list (`STATUS`, `WAIT`, `HELP`).
- `RESET` / `REBOOT`
  - Reset in-memory `GameState` and return:
    - `text="SYSTEM REBOOTED."`
    - `lines=["SESSION READY."]`

## Failure and Error Semantics
- Unknown/invalid command line:
  - `ok=false`
  - `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`
- Failure lockout (COMMAND breached):
  - `ok=false`
  - `lines=["COMMAND BREACHED.", "SESSION TERMINATED."]`

## Runtime Notes
- Backend authority is server-side (`process_command` mutates server-owned `GameState`).
- State is process-local and persistent while Flask process is running.
- Endpoint currently has no authentication in prototype scope.

## Snapshot Endpoint (Read-Only)
- `GET /snapshot` returns the canonical `GameState.snapshot()` payload.
- Used for UI projections (sector map) and does not mutate state.
