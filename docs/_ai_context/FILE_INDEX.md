# FILE INDEX — CUSTODIAN

## Entrypoints

- `game/__main__.py` — unified entrypoint (`python -m game`).
- `game/run.py` — world simulation runner shim.

## World-State Core

- `game/simulations/world_state/core/state.py` — `GameState`, snapshot shape, failure checks.
- `game/simulations/world_state/core/simulation.py` — tick orchestration (`step_world`).
- `game/simulations/world_state/core/assaults.py` — approach movement, assault resolution, after-action effects.
- `game/simulations/world_state/core/repairs.py` — repair progression/cancellation/regression.
- `game/simulations/world_state/core/fabrication.py` — fabrication queue and recipe processing.
- `game/simulations/world_state/core/power.py` — power efficiency and comms fidelity mapping.
- `game/simulations/world_state/core/detection.py` — surveillance/fidelity warning-window helpers.

## Terminal Stack

- `game/simulations/world_state/terminal/parser.py` — command parsing/tokenization.
- `game/simulations/world_state/terminal/processor.py` — authority checks and command dispatch.
- `game/simulations/world_state/terminal/commands/help.py` — categorical help tree.
- `game/simulations/world_state/terminal/commands/wait.py` — WAIT/WAIT UNTIL behavior.
- `game/simulations/world_state/terminal/repl.py` — interactive CLI REPL.

## Server Contract

- `game/simulations/world_state/server_contracts.py` — shared request parsing/result serialization and replay cache.
- `game/simulations/world_state/server.py` — world-state server endpoints.
- `custodian-terminal/server.py` — UI server endpoints and static host.

## Terminal UI

- `custodian-terminal/index.html` — shell layout.
- `custodian-terminal/boot.js` — boot stream + audio sequencing.
- `custodian-terminal/terminal.js` — input loop, history, hints, autocomplete, output rendering.
- `custodian-terminal/sector-map.js` — snapshot projection for sector map/system panel.
- `custodian-terminal/style.css` — terminal and panel styling.

## Tests

- `game/simulations/world_state/tests/` — parser, processor, simulation, and feature behavior tests.
