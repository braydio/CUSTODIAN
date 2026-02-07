# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence is implemented in `custodian-terminal/boot.js`, and command submit/render transport is implemented in `custodian-terminal/terminal.js`.
- Primary terminal UI webserver is `custodian-terminal/server.py` (static asset serving, SSE boot stream via `/stream/boot`, and `/command`).
- World-state server module `game/simulations/world_state/server.py` also exposes `/command` (plus `/stream`) and is covered by endpoint tests.
- World-state simulation spine is implemented with procedural events, assault timing, and a Command Center breach failure latch.
- World-state terminal stack is wired end-to-end (`parser.py`, `commands/`, `processor.py`, `result.py`, `repl.py`), and backend dispatch remains authoritative.
- Unified entrypoint is available at `python -m game` with `--ui` (default), `--sim`, and `--repl`.
- Automated tests exist for parser/processor behavior, simulation stepping, terminal contracts, and `/command` endpoint behavior.
- Git hooks for docs/secret hygiene exist; enable via `git config core.hooksPath .githooks`.

## Terminal Command Surface (Implemented)
- Accepted operator commands in normal operation: `STATUS`, `WAIT`, `HELP`.
- Failure-recovery commands: `RESET`, `REBOOT`.
  - In failure mode, only `RESET`/`REBOOT` are accepted.
  - Outside failure mode, `RESET`/`REBOOT` still reset the in-process `GameState`.
- Unknown or invalid command input returns:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["TYPE HELP FOR AVAILABLE COMMANDS."]`

## `/command` Contract (Implemented)
- Request: `POST /command` with canonical JSON key `{ "command": "<string>" }`.
- Compatibility fallback: `{ "raw": "<string>" }` is still accepted by both Flask handlers.
- Input validation differs by endpoint today:
  - `game/simulations/world_state/server.py` explicitly maps missing/empty/non-string input to the unknown-command payload.
  - `custodian-terminal/streaming-server.py` forwards canonical/fallback values directly to `process_command`; expected path is string command input from `terminal.js`.
- Success and failure payload shape is:
  - `ok` (bool)
  - `text` (primary line)
  - optional `lines` (ordered detail lines)
  - optional `warnings` (non-fatal warning lines)
- Runtime model: Flask server process keeps a persistent in-memory `GameState` across requests.

## Locked Decisions
- Terminal-first interface with terse, operational output.
- World time advances only on explicit time-bearing commands (`WAIT`) in terminal mode.
- `STATUS` remains a high-level board view (time, threat bucket, assault state, sector statuses).
- Command processor is backend-authoritative; frontend local echo is display-only.

## Flexible Areas
- Exact phrasing of non-contract detail lines (`[EVENT]`, `[WARNING]`, assault begin/end markers).
- Timing and pressure tuning in `core/config.py` and event weights/cooldowns in `events.py`.
- Retirement timing for legacy `{raw}` fallback once all clients are migrated.

## In Progress
- None.
