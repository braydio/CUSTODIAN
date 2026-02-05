# FILE INDEX — CUSTODIAN

- `game/run.py` — main world simulation entry point.
- `game/simulations/world_state/core/simulation.py` — world-state tick loop (`sandbox_world`).
- `game/simulations/world_state/core/state.py` — `GameState` and time progression.
- `game/simulations/world_state/core/events.py` — ambient event generation.
- `game/simulations/world_state/core/assaults.py` — assault timing + lifecycle.
- `game/simulations/assault/core/assault.py` — assault resolution logic.
- `custodian-terminal/index.html` — terminal UI shell.
- `custodian-terminal/boot.js` — boot sequence + SSE hookup.
- `custodian-terminal/terminal.js` — terminal buffer + input handling.
- `custodian-terminal/server.py` — static server + boot stream endpoint.
