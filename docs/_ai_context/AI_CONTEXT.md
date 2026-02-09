=== ARCHITECTURE.md ===
# ARCHITECTURE — CUSTODIAN (Canonical)

## High-Level Loop
- Recon / Expedition → Return with knowledge + materials → Build / reinforce base → Assault → Repair → Repeat.

## Simulation Structure
- World-state simulation is the ambient loop that drives events and assault timing.
- Assault simulation is a focused resolution prototype; it can be invoked by the world-state layer.

## Interface
- Terminal-first interface; UI is a thin view of the simulation state and command results.
- Operational, perimeter-defense language with terse output.

## Authority Model
- Authority is location-based (COMMAND sector presence) rather than flags.

## Time Model
- Time advances by explicit ticks; avoid hidden background time in the world simulation.

## Phase 1 Terminal Design Lock (Historical Plan)
- Rationale: build a deterministic, command-driven loop before any map UI to avoid UI creep and ensure a playable spine.
- Loop invariant: `BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS -> ...` (world only moves on `WAIT`/`WAIT 10X`).
- Phase 1 command set: `STATUS`, `WAIT`, `WAIT 10X`, `FOCUS`, `HELP` only (no aliases).
- `STATUS` output rules: ASCII, all caps, no recommendations; fields: TIME, THREAT bucket, ASSAULT state, sector list with one-word state; never advances time.
- `WAIT` output rules: advance exactly one tick; minimal output only; no full status dump; may emit event/warning/assault lines.
- `WAIT 10X` output rules: advance exactly ten ticks; summarize events, warnings, assault transitions, and failure lines without full status dumps.
- Error phrasing reserved: `UNKNOWN COMMAND. TYPE HELP FOR AVAILABLE COMMANDS.` and `COMMAND DENIED. COMMAND CENTER REQUIRED.`
- Map UI now exists as a read-only projection of `STATUS` via `/snapshot` and never advances time.
- Acceptance criteria: boot completes, `STATUS` and `WAIT`/`WAIT 10X` work, time advances only via `WAIT`/`WAIT 10X`, `STATUS` reflects changes.
- Current code diverges (extra commands + authority gating); treat this as a reference spec, not current behavior.

## Canonical Entrypoints
- Unified entrypoint: `python -m game` (`--ui` default, `--sim`, `--repl`).
- World sim: `game/run.py` (imports `game.simulations.world_state.core.simulation.sandbox_world`).
- World sim standalone: `game/simulations/world_state/sandbox_world.py`.
- World-state terminal REPL: `game/simulations/world_state/terminal/repl.py`.
- Assault sim standalone: `game/simulations/assault/sandbox_assault.py`.
- Terminal UI server: `custodian-terminal/server.py`.

## Notes
- This file should only change when architectural decisions are locked or revised.



=== COMMAND_CONTRACT.md ===
# COMMAND CONTRACT — CUSTODIAN

## Status
- Implemented end-to-end between terminal frontend and backend command processor.
- `/command` is active and used by the browser terminal command path.

## Transport
- Client submit path: `custodian-terminal/terminal.js` posts JSON commands to `/command`.
- UI server handler: `custodian-terminal/server.py` parses request JSON, dispatches to `process_command`, and serializes `CommandResult`.
- World-state server handler: `game/simulations/world_state/server.py` exposes the same payload contract and processing path.

## Request Shape
- Method: `POST`
- Path: `/command`
- Canonical JSON body: `{ "command": "<string>" }`
- Compatibility fallback: `{ "raw": "<string>" }`

Validation behavior:
- Missing/empty/non-string command input resolves to unknown-command output.
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
- `WAIT 10X`
  - Advances simulation by ten ticks.
  - Primary line: `TIME ADVANCED x10.`
  - Detail lines summarize events, warnings, assault transitions, and failure termination lines seen during the burst.
- `FOCUS <SECTOR_ID>`
  - Sets the focused sector by ID (for example `FOCUS POWER`).
  - Confirmation line: `[FOCUS SET] <SECTOR_NAME>`
  - Does not advance time.
- `HELP`
  - Returns locked command list for Phase 1.
- `RESET` / `REBOOT`
  - Reset in-memory `GameState` and return:
    - `text="SYSTEM REBOOTED."`
    - `lines=["SESSION READY."]`

## Failure and Error Semantics
- Unknown/invalid command line:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["TYPE HELP FOR AVAILABLE COMMANDS."]`
- Failure lockout (COMMAND breached):
  - Non-reset verbs return `ok=false`
  - `text` set to latched failure reason (typically `COMMAND BREACHED.`)
  - `lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]`

## Runtime Notes
- Backend authority is server-side (`process_command` mutates server-owned `GameState`).
- State is process-local and persistent while Flask process is running.
- Endpoint currently has no authentication in prototype scope.

## Snapshot Endpoint (Read-Only)
- `GET /snapshot` returns the canonical `GameState.snapshot()` payload.
- Used for UI projections (sector map) and does not mutate state.



=== CURRENT_STATE.md ===
# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence is implemented in `custodian-terminal/boot.js`, and command submit/render transport is implemented in `custodian-terminal/terminal.js`.
- Primary terminal UI webserver is `custodian-terminal/server.py` (static asset serving, SSE boot stream via `/stream/boot`, and `/command`).
- World-state server module `game/simulations/world_state/server.py` also exposes `/command` (plus `/stream`) and is covered by endpoint tests.
- World-state simulation spine is implemented with procedural events, assault timing, and a COMMAND breach failure latch.
- World-state terminal stack is wired end-to-end (`parser.py`, `commands/`, `processor.py`, `result.py`, `repl.py`).
- Unified entrypoint is available at `python -m game` with `--ui` (default), `--sim`, and `--repl`.
- Automated tests exist for parser/processor behavior, simulation stepping, terminal contracts, and `/command` endpoint behavior.
- Git hooks for docs/secret hygiene exist; enable via `git config core.hooksPath .githooks`.

## Terminal Command Surface (Implemented)
- Accepted operator commands in normal operation: `STATUS`, `WAIT`, `WAIT 10X`, `FOCUS`, `HELP`.
- Failure-recovery commands: `RESET`, `REBOOT`.
  - In failure mode, only `RESET`/`REBOOT` are accepted.
  - Outside failure mode, `RESET`/`REBOOT` still reset the in-process `GameState`.
- Unknown or invalid command input returns:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["TYPE HELP FOR AVAILABLE COMMANDS."]`

## `/command` Contract (Implemented)
- Request: `POST /command` with canonical JSON key `{ "command": "<string>" }`.
- Compatibility fallback: `{ "raw": "<string>" }` is still accepted.
- Empty, missing, or non-string command input resolves to the same unknown-command payload.
- Success and failure payload shape is:
  - `ok` (bool)
  - `text` (primary line)
  - optional `lines` (ordered detail lines)
  - optional `warnings` (non-fatal warning lines)
- Runtime model: Flask server process keeps a persistent in-memory `GameState` across requests.

## Locked Decisions
- Terminal-first interface with terse, operational output.
- World time advances only on explicit time-bearing commands (`WAIT`, `WAIT 10X`) in terminal mode.
- `STATUS` remains a high-level board view (time, threat bucket, assault state, sector statuses).
- Command processor is backend-authoritative; frontend local echo is display-only.

## Flexible Areas
- Exact phrasing of non-contract detail lines (`[EVENT]`, `[WARNING]`, assault begin/end markers).
- Timing and pressure tuning in `core/config.py` and event weights/cooldowns in `events.py`.
- Retirement timing for legacy `{raw}` fallback once all clients are migrated.

## In Progress
- None.



=== DEVLOG.md ===
# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from the former `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.
- Updated terminal boot flow: `boot.js` appends a system log and unlocks command mode; terminal input submits to `/command` and renders lines or failure messages.
- Implemented `/command` in `custodian-terminal/server.py` using a persistent `GameState` and the terminal command processor.
- Added unified entrypoint `python -m game` with `--ui`/`--sim`/`--repl` modes and updated README entrypoints.
- Fixed `custodian-terminal/server.py` to add the repo root to `sys.path` so `python -m game --ui` can import `game`.
- Renamed boot and server files to canonical `boot.js` and `server.py`.
- Expanded terminal boot audio base (hum + relay + beep + alert) with policy-safe unlock and one-shot helpers.

## 2026-02-06
- Updated terminal boot flow integration so UI command submit/render path uses backend `CommandResult` payloads (`ok`, `text`, optional `lines`/`warnings`).
- Standardized world-state `/command` request handling on canonical `{command}` with temporary `{raw}` fallback.
- Added world-state failure latch (`is_failed`, `failure_reason`) on COMMAND breach threshold.
- Updated `step_world` and terminal `WAIT` behavior to emit final failure lines and halt normal progression after breach.
- Updated terminal processor lockout so only `RESET`/`REBOOT` are accepted while failed.
- Extended world-state terminal tests to cover failure trigger, failure finality, and reboot-required behavior.
- Reconciled AI context docs to current implementation state: removed stale unwired `/command` assumptions, documented live endpoint contract/command set, and aligned cross-references in docs.
- Verified no `AGENTS_ADDENDUM.md` remains in repo scope, so no addendum carryover items remain to prune.



=== FILE_INDEX.md ===
# FILE INDEX — CUSTODIAN

- `game/__main__.py` — unified entrypoint (`python -m game`).
- `game/run.py` — main world simulation entry point.
- `game/simulations/world_state/core/simulation.py` — world-state tick loop (`sandbox_world`).
- `game/simulations/world_state/core/state.py` — `GameState` and time progression.
- `game/simulations/world_state/core/events.py` — ambient event generation.
- `game/simulations/world_state/core/assaults.py` — assault timing + lifecycle.
- `game/simulations/world_state/terminal/` — command parser, processor, registry, and REPL.
- `game/simulations/world_state/server.py` — world-state SSE stream server.
- `game/simulations/assault/core/assault.py` — assault resolution logic.
- `custodian-terminal/index.html` — terminal UI shell.
- `custodian-terminal/boot.js` — boot sequence + system log + SSE fallback + audio base.
- `custodian-terminal/terminal.js` — terminal buffer + input handling.
- `custodian-terminal/server.py` — static server + boot stream + `/command` endpoint.
- `.githooks/` — local git hooks (pre-commit, commit-msg, post-commit).
- `tests/` — pytest suite for world-state stepping and terminal commands.



=== SIMULATION_RULES.md ===
# SIMULATION RULES — CUSTODIAN

## Time
- The world simulation advances by explicit ticks.
- No hidden background ticking outside the world simulation loop.
- Terminal command loop advances time only via `wait`.

## State
- `GameState` is the authoritative container for world-state data.
- Assaults are stateful objects tracked in the world state.

## Assaults
- Assault lifecycle is managed by the world-state layer.
- Assault resolution is delegated to the assault prototype module.

## Autopilot
- Reactive only; it should not introduce hidden time progression.

## Output
- Simulation output remains operational, terse, and grounded.
- Avoid verbose narration or speculative text.
