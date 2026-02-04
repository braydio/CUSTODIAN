"""Interactive REPL for Phase 1 world-state control."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import CommandResult
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.processor import process_command


def run_repl() -> None:
    """Start the deterministic operator loop.

    The loop reads commands, processes them immediately, and prints the
    result without background ticking.
    """

    state = GameState()
    print("World-state terminal online.")
    print("Type 'help' for command list. 'quit' to exit.")
    while True:
        try:
            raw = input("> ")
        except EOFError:
            print("\nTerminal closed.")
            break
        parsed = parse_input(raw)
        if parsed is None:
            continue
        if parsed.verb in {"quit", "exit"}:
            print("Terminal closed.")
            break
        result = process_command(state, parsed)
        if isinstance(result, CommandResult) and result.message:
            print(result.message)
