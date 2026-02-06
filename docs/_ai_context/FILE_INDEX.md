# FILE INDEX — CUSTODIAN

- `game/run.py` — main world simulation entry point.
- `game/simulations/world_state/core/simulation.py` — world-state tick loop (`sandbox_world`).
- `game/simulations/world_state/core/state.py` — `GameState` and time progression.
- `game/simulations/world_state/core/events.py` — ambient event generation.
- `game/simulations/world_state/core/assaults.py` — assault timing + lifecycle.
- `game/simulations/world_state/terminal/` — command parser, processor, registry, and REPL.
- `game/simulations/world_state/server.py` — world-state SSE stream server.
- `game/simulations/assault/core/assault.py` — assault resolution logic.
- `custodian-terminal/index.html` — terminal UI shell.
- `custodian-terminal/boot.js` — boot sequence + system log + command-mode handoff (local; no SSE).
- `custodian-terminal/server-streaming-boot.js` — boot sequence variant with SSE hookup.
- `custodian-terminal/terminal.js` — terminal buffer + input handling.
- `custodian-terminal/server.py` — static server + boot stream endpoint.
- `custodian-terminal/streaming-server.py` — static server + boot stream + `/command` endpoint.
- `.githooks/` — local git hooks (pre-commit, commit-msg, post-commit).
- `tests/` — pytest suite for world-state stepping and terminal commands.
