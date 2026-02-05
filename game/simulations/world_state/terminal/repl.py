"""Interactive REPL for Phase 1 world-state control."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def run_repl() -> None:
    """Start the deterministic operator loop."""

    state = GameState()
    print("WORLD-STATE TERMINAL ONLINE.")
    print("COMMANDS: STATUS, WAIT, HELP. TYPE QUIT TO EXIT.")

    while True:
        try:
            raw = input("> ")
        except EOFError:
            print("\nTERMINAL CLOSED.")
            break

        if raw.strip().upper() in {"QUIT", "EXIT"}:
            print("TERMINAL CLOSED.")
            break

        result = process_command(state, raw)
        for line in result.lines:
            print(line)
