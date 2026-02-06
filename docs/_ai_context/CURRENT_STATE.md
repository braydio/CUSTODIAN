# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented (JS). Boot now runs and then appends a system log before unlocking input. Commands are POSTed to `/command` and responses appended (transport wired on the UI side only).
- World-state simulation spine implemented (Python). Procedural events + assault timer active.
- World-state terminal command stack implemented in Python (parser, processor, commands, REPL), not wired to the UI yet.
- Standalone REPL exists at `game/simulations/world_state/terminal/repl.py`.
- Assault simulation prototype implemented (Python), standalone runner.
- Terminal webserver available via `custodian-terminal/streaming-server.py` (Flask + SSE boot stream). `server-streaming-boot.js` mirrors the boot flow with SSE hookup; `boot.js` currently runs the local boot sequence + system log.
- Git hooks added for doc/secret hygiene: `pre-commit`, `commit-msg`, `post-commit` (enable via `git config core.hooksPath .githooks`).
- Unit tests exist for world-state step logic and terminal parsing/processing.
- World-state terminal now supports a hard failure mode when the Command Center is breached; terminal accepts only reset/reboot until session reset.

## Implemented vs Stubbed
- Implemented: boot sequence rendering, system log lines, terminal input + submit flow, command POST transport (UI), world-state ticks, assault resolution, terminal command parsing + processing in Python.
- Stubbed: backend `/command` endpoint in terminal server, authoritative command responses to UI.
- Note: current Python terminal commands include `status`, `sectors`, `power`, `wait` with authority gating; this diverges from the Phase 1 `STATUS/WAIT/HELP` lock described in `docs/_ai_context/ARCHITECTURE.md`.

## Locked Decisions
- Terminal-first interface; operational, terse tone.
- World time advances by explicit ticks (no hidden background time in the world sim).
- Command authority is location-based, not flag-based.

## Flexible Areas
- Command grammar details and error text phrasing.
- Webserver submit endpoint placement and request validation depth.
- Telemetry cadence and formatting (front-end only today).

## In Progress
- None.

## Next Tasks
1. Implement `/command` in the terminal server and wire it to the Python terminal command processor.
2. Decide whether `boot.js` or `server-streaming-boot.js` is canonical and remove/rename the other to reduce confusion.
3. Align COMMAND_CONTRACT.md with the actual transport shape once the server endpoint exists.
