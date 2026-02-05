# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented (JS). Tutorial feed runs before input unlock; local echo command input only.
- World-state simulation spine implemented (Python). Procedural events + assault timer active.
- World-state terminal command stack implemented in Python (parser, processor, commands, REPL), not wired to the UI yet.
- Standalone REPL exists at `game/simulations/world_state/terminal/repl.py`.
- Assault simulation prototype implemented (Python), standalone runner.
- Terminal webserver added for remote viewing (Flask + SSE boot stream); both `custodian-terminal/server.py` and `custodian-terminal/streaming-server.py` exist.
- Alternate boot sequence script `custodian-terminal/server-streaming-boot.js` mirrors `boot.js` with SSE hookup.
- Git hooks added for doc/secret hygiene: `pre-commit`, `commit-msg`, `post-commit` (enable via `git config core.hooksPath .githooks`).
- Unit tests exist for world-state step logic and terminal parsing/processing.

## Implemented vs Stubbed
- Implemented: boot sequence rendering, telemetry stubs, world-state ticks, assault resolution, terminal command parsing + processing in Python.
- Stubbed: command transport (UI to backend), webserver command endpoint, frontend command wiring.
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
1. Add command endpoint in the terminal webserver (POST) and wire JS submit to it.
2. Align COMMAND_CONTRACT.md with the current Python command set (status, sectors, power, wait) and response shape.
3. Implement HELP command and surface authoritative responses to the UI.
