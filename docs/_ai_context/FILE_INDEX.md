# FILE INDEX - CUSTODIAN

- `game/run.py` - main world simulation entry point.
- `game/simulations/world_state/core/simulation.py` - world-state tick loop (`sandbox_world`).
- `game/simulations/world_state/core/state.py` - `GameState` and time progression.
- `game/simulations/world_state/core/events.py` - ambient event generation.
- `game/simulations/world_state/core/assaults.py` - assault timing and lifecycle.
- `game/simulations/world_state/server.py` - Flask server with stream and command endpoints.
- `game/simulations/world_state/terminal/processor.py` - command parse/dispatch entry point.
- `game/simulations/world_state/terminal/result.py` - Phase 1 command result contract.
- `game/simulations/world_state/terminal/commands/status.py` - STATUS formatting handler.
- `game/simulations/world_state/terminal/commands/wait.py` - one-tick WAIT handler.
- `game/simulations/world_state/terminal/commands/help.py` - HELP output handler.
- `game/simulations/assault/core/assault.py` - assault resolution logic.
- `custodian-terminal/index.html` - terminal UI shell.
- `custodian-terminal/boot.js` - boot sequence and command-mode handoff.
- `custodian-terminal/terminal.js` - terminal input, API submit, and transcript rendering.
