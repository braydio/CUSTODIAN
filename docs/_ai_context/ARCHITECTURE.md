# ARCHITECTURE — CUSTODIAN

## Core Shape

- Terminal-first simulation interface.
- Backend-authoritative world state (`GameState`) with deterministic tick progression.
- Frontend is a transport and projection layer, not game authority.

## Runtime Layers

1. Command layer
- Parser + processor dispatch in `game/simulations/world_state/terminal/`.
- Commands return `CommandResult` payloads.

2. World-state layer
- Tick orchestration in `core/simulation.py::step_world`.
- Subsystems: events, assaults, repairs, power, policies, fabrication, presence.

3. UI layer
- Browser terminal in `custodian-terminal/`.
- Boot stream + command POST + snapshot polling.

## Time Model

- No hidden background time in terminal operation.
- Time advances through explicit commands (`WAIT`, `WAIT NX`, `WAIT UNTIL ...`).
- `WAIT` currently advances 5 ticks per unit; while an assault is active it advances 1 tick per unit.

## Authority Model

- Command authority is location-based.
- While deployed in field mode, strategic command verbs are blocked and return `COMMAND AUTHORITY REQUIRED.`

## Failure Model

- COMMAND-center loss and archive-integrity loss latch failure mode.
- In failure mode, only `RESET` and `REBOOT` are accepted.

## Entrypoints

- Unified: `python -m game`
- UI: `python -m game --ui`
- REPL: `python -m game --repl`
- Autonomous sim loop: `python -m game --sim`
