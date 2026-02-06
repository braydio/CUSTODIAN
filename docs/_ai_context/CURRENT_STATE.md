# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented in `custodian-terminal/boot.js` and terminal transport implemented in `custodian-terminal/terminal.js`.
- Terminal webserver implemented in `custodian-terminal/streaming-server.py` (Flask static serving, SSE boot stream, and `/command` endpoint).
- World-state simulation spine implemented in Python with procedural events, assault timing, and Command Center breach failure latch.
- World-state terminal stack implemented and wired end-to-end (`parser.py`, `commands/`, `processor.py`, `repl.py`).
- Unified entrypoint available at `python -m game` with `--ui` (default), `--sim`, and `--repl`.
- Unit tests exist for world-state stepping and terminal parsing/processing behavior.

## Terminal Command Surface (Implemented)
- Accepted operator commands: `STATUS`, `WAIT`, `HELP`.
- Failure-recovery commands: `RESET`, `REBOOT` (accepted only after failure lockout, both trigger in-process state reset).
- Unknown commands return `ok=false` with `UNKNOWN COMMAND.` and `TYPE HELP FOR AVAILABLE COMMANDS.`

## `/command` Contract (Implemented)
- Request: `POST /command` JSON body with canonical key `{ "command": "<string>" }`.
- Compatibility: legacy `{ "raw": "<string>" }` is still accepted as fallback.
- Response: `CommandResult` JSON with `ok`, `text`, optional `lines`, optional `warnings`.
- Runtime model: server keeps a persistent in-memory `GameState` across requests.

## Locked Decisions
- Terminal-first interface with terse, operational output.
- World time advances only on explicit time-bearing commands; no hidden idle ticking.
- `STATUS` remains a high-level board view (no raw internal numeric leakage beyond locked fields).

## Flexible Areas
- Exact phrasing of non-contract detail lines (events and warnings).
- Whether to retire the temporary `{raw}` request fallback once all clients are updated.
- Whether to consolidate or remove alternate boot scripts after final SSE path selection.

## In Progress
- None.
