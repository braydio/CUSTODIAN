"""Command processor for the world-state terminal."""

from typing import Optional

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import CommandResult, get_command
from game.simulations.world_state.terminal.parser import ParsedCommand


def process_command(
    state: GameState, parsed: Optional[ParsedCommand]
) -> Optional[CommandResult]:
    """Apply a parsed command to the game state.

    Args:
        state: Current game state.
        parsed: Parsed command, or None for empty input.

    Returns:
        CommandResult if a command was executed, otherwise None.
    """

    if parsed is None:
        return None

    command = get_command(parsed.verb)
    if command is None:
        return CommandResult(ok=False, message="Unknown command. Use 'help'.")

    if command.authority == "write" and not state.player_present:
        return CommandResult(ok=False, message="Write authority denied.")

    return command.handler(state, parsed)
