"""Interactive REPL for Phase 1 world-state control."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import CommandResult
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.processor import process_command


def run_repl() -> None:
    """Start the deterministic operator loop.

    The loop reads commands, processes them immediately, and prints the
    result without background ticking. The available command set is
    status, sectors, power, and wait.
    """

    state = GameState()
    print("World-state terminal online.")
    print("Commands: status, sectors, power, wait. 'quit' to exit.")
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
        if isinstance(result, CommandResult):
            output = _render_result(result)
            if output:
                print(output)


def _render_result(result: CommandResult) -> str:
    """Format a CommandResult for terminal display.

    Args:
        result: Structured result from command processing.

    Returns:
        String payload for display.
    """

    lines = []
    if result.text:
        lines.append(result.text)
    if result.lines:
        lines.extend(result.lines)
    if result.warnings:
        lines.append("Warnings:")
        lines.extend(f"- {warning}" for warning in result.warnings)
    return "\n".join(lines)
