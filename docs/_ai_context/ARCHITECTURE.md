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
- Authority is location-based (Command Center presence) rather than flags.

## Time Model
- Time advances by explicit ticks; avoid hidden background time in the world simulation.

## Phase 1 Terminal Design Lock (Historical Plan)
- Rationale: build a deterministic, command-driven loop before any map UI to avoid UI creep and ensure a playable spine.
- Loop invariant: `BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS -> ...` (world only moves on `WAIT`).
- Phase 1 command set: `STATUS`, `WAIT`, `HELP` only (no aliases).
- `STATUS` output rules: ASCII, all caps, no recommendations; fields: TIME, THREAT bucket, ASSAULT state, sector list with one-word state; never advances time.
- `WAIT` output rules: advance exactly one tick; minimal output only; no full status dump; may emit event/warning/assault lines.
- Error phrasing reserved: `UNKNOWN COMMAND. TYPE HELP FOR AVAILABLE COMMANDS.` and `COMMAND DENIED. COMMAND CENTER REQUIRED.`
- Map UI deferred; when added it must be a projection of `STATUS` and never advance time.
- Acceptance criteria: boot completes, `STATUS` and `WAIT` work, time advances only via `WAIT`, `STATUS` reflects changes.
- Current code diverges (extra commands + authority gating); treat this as a reference spec, not current behavior.

## Canonical Entrypoints
- Unified entrypoint: `python -m game` (`--ui` default, `--sim`, `--repl`).
- World sim: `game/run.py` (imports `game.simulations.world_state.core.simulation.sandbox_world`).
- World sim standalone: `game/simulations/world_state/sandbox_world.py`.
- World-state terminal REPL: `game/simulations/world_state/terminal/repl.py`.
- Assault sim standalone: `game/simulations/assault/sandbox_assault.py`.
- Terminal UI server: `custodian-terminal/streaming-server.py`.

## Notes
- This file should only change when architectural decisions are locked or revised.
