"""Command processor for the world-state terminal."""

from collections.abc import Callable

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import (
    cmd_help,
    cmd_status,
    cmd_wait,
)
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.result import CommandResult

Handler = Callable[[GameState], list[str]]


COMMAND_HANDLERS: dict[str, Handler] = {
    "STATUS": cmd_status,
    "WAIT": cmd_wait,
    "HELP": lambda _state: cmd_help(),
}


def process_command(state: GameState, raw: str) -> CommandResult:
    """Parse and dispatch a command against a mutable game state.

    Args:
        state: Long-lived world-state instance.
        raw: Raw terminal input line.

    Returns:
        Phase 1 command result payload.
    """

    parsed = parse_input(raw)
    if parsed is None:
        return CommandResult(
            ok=False, lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]
        )

    handler = COMMAND_HANDLERS.get(parsed.verb)
    if handler is None:
        return CommandResult(
            ok=False, lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]
        )

    # Phase 1 authority model: all commands are allowed.
    lines = handler(state)
    return CommandResult(ok=True, lines=lines)
