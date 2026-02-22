# World-State Simulation

Backend-authoritative simulation of a static command post under pressure.

## Layout

- Entry: `game/simulations/world_state/sandbox_world.py`
- Core: `game/simulations/world_state/core/`
- Terminal stack: `game/simulations/world_state/terminal/`
- Servers:
  - `custodian-terminal/server.py`
  - `game/simulations/world_state/server.py`

## Core State

`GameState` tracks:

- world time, ambient threat, assaults/approaches
- command failure latches
- sector and structure state
- comms fidelity and last fidelity lines
- repairs, policies, fabrication queue, inventory/stocks
- presence mode/location and active task
- doctrine/allocation/readiness
- deterministic seed and operator log

## Sector Layout

Implemented sectors:

- COMMAND
- COMMS
- DEFENSE GRID
- POWER
- ARCHIVE
- STORAGE
- HANGAR
- GATEWAY
- FABRICATION

## Tick Orchestration

`core/simulation.py::step_world` coordinates subsystem updates including:

- events and pressure
- assault approach movement/spawn/resolve
- transit interception effects
- repair/fabrication progression
- fidelity refresh and failure checks

## Command-Driven Time

- No hidden background stepping in terminal operation.
- Time advances via `WAIT`, `WAIT NX`, `WAIT UNTIL ...`.
- Read/config commands do not advance time.

## Assault Model

- Approaches spawn from ingress routes and traverse graph edges.
- ETA is derived from traversal progress.
- Tactical engagement resolves over multiple ticks.
- Tactical command verbs can alter active assault outcomes.
- After-action effects feed damage, power load, materials/stocks, and repair pressure.

## Information Model

- Comms fidelity gates operator-visible certainty.
- `STATUS` and `WAIT` output degrade as fidelity drops.
- Fidelity transitions are surfaced via diegetic signal events.

## Tuning

- Primary knobs are in `game/simulations/world_state/core/config.py`.
