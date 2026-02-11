# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence is implemented in `custodian-terminal/boot.js` with power-cycle audio and SSE fallback; command submit/render transport in `custodian-terminal/terminal.js`, and the sector map + system panel projections in `custodian-terminal/sector-map.js` using `custodian-terminal/sector_layout.js`.
- Primary terminal UI webserver is `custodian-terminal/server.py` (static asset serving, SSE boot stream via `/stream/boot`, plus `/command` and `/snapshot`).
- World-state server module `game/simulations/world_state/server.py` also exposes `/command`, `/snapshot` (plus `/stream`).
- World-state simulation spine is implemented with procedural events, assault timing, and COMMAND/ARCHIVE failure latches.
- Hub scaffolding exists in `game/simulations/world_state/core/hub.py` with offer generation, recon refinement, hub mutation rules, and snapshot/load seams.
- Phase 1.5 asymmetry is active: sector roles influence threat growth, assault damage, warnings, and event frequency.
- World-state terminal stack is wired end-to-end (`parser.py`, `commands/`, `processor.py`, `result.py`, `repl.py`).
- Structure-level damage scaffolding exists (`core/structures.py`) with timed repairs (`core/repairs.py`), driven by `REPAIR`, `WAIT`, and the materials economy (status-aware repair reissue).
- Canonical sector layout now includes 9 sectors with FABRICATION present but inert.
- Unified entrypoint is available at `python -m game` with `--ui` (default), `--sim`, and `--repl`.
- Automated tests exist for parser/processor behavior and simulation stepping.
- Git hooks for docs/secret hygiene exist; enable via `git config core.hooksPath .githooks`.

## Terminal Command Surface (Implemented)
- Accepted operator commands in normal operation: `STATUS`, `WAIT`, `WAIT NX`, `FOCUS`, `HARDEN`, `REPAIR`, `SCAVENGE`, `HELP`.
- Failure-recovery commands: `RESET`, `REBOOT`.
- Unknown or invalid command input returns:
  - `ok=false`
  - `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`

## `/command` Contract (Implemented)
- Request: `POST /command` with JSON key `{ "raw": "<string>" }`.
- Input validation differs by endpoint today:
  - `game/simulations/world_state/server.py` explicitly maps missing/empty/non-string input to the unknown-command payload.
  - `custodian-terminal/server.py` forwards `raw` directly to `process_command`.
- Success and failure payload shape is:
  - `ok` (bool)
  - `lines` (string[]; primary line first)
- Runtime model: Flask server process keeps a persistent in-memory `GameState` across requests.

## Locked Decisions
- Terminal-first interface with terse, operational output.
- World time advances only on explicit time-bearing commands (`WAIT`, `WAIT 10X`) in terminal mode.
- `STATUS` remains a high-level board view (time, threat bucket, assault state, posture, archive losses, sector statuses).
- `STATUS` output degrades with COMMS fidelity (FULL/ALERT/DAMAGED/COMPROMISED).
- `WAIT`/`WAIT 10X` output now follows the information degradation spec (event/warning + optional interpretive line, fidelity-gated summaries).
- Command processor is backend-authoritative; frontend local echo is display-only.

## Flexible Areas
- Exact phrasing of non-contract detail lines (`[EVENT]`, `[WARNING]`, assault begin/end markers).
- Timing and pressure tuning in `core/config.py` and event weights/cooldowns in `events.py`.

## In Progress
- None.
