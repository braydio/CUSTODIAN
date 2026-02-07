"""Command processor for the world-state terminal."""

from collections.abc import Callable

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import (
    cmd_focus,
    cmd_help,
    cmd_reset,
    cmd_status,
    cmd_wait,
    cmd_wait_ticks,
)
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.result import CommandResult

Handler = Callable[[GameState], list[str]]


COMMAND_HANDLERS: dict[str, Handler] = {
    "STATUS": cmd_status,
    "WAIT": cmd_wait,
    "HELP": lambda _state: cmd_help(),
}


def _unknown_command() -> CommandResult:
    return CommandResult(
        ok=False,
        text="UNKNOWN COMMAND.",
        lines=["TYPE HELP FOR AVAILABLE COMMANDS."],
    )


def _parse_wait_ticks(args: list[str]) -> int | None:
    if not args:
        return 1
    if len(args) != 1:
        return None
    token = args[0].strip().upper()
    if not token.endswith("X"):
        return None
    count_text = token[:-1]
    if count_text != "10":
        return None
    return 10


def process_command(state: GameState, raw: str) -> CommandResult:
    """Parse and dispatch a command against a mutable game state.

    Args:
        state: Long-lived world-state instance.
        raw: Raw terminal input line.

    Returns:
        Command result payload with primary text and optional detail lines.
    """

    parsed = parse_input(raw)
    if parsed is None:
        return _unknown_command()

    if parsed.verb in {"RESET", "REBOOT"}:
        lines = cmd_reset(state)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return CommandResult(ok=True, text=primary_line, lines=detail_lines)

    if state.is_failed:
        return CommandResult(
            ok=False,
            text=state.failure_reason or "SESSION FAILED.",
            lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."],
        )

    handler = COMMAND_HANDLERS.get(parsed.verb)
    if handler is None:
        return _unknown_command()

    if parsed.verb == "WAIT":
        ticks = _parse_wait_ticks(parsed.args)
        if ticks is None:
            return _unknown_command()
        lines = cmd_wait_ticks(state, ticks)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return CommandResult(ok=True, text=primary_line, lines=detail_lines)

    if parsed.verb == "FOCUS":
        if len(parsed.args) != 1:
            return _unknown_command()
        lines = cmd_focus(state, parsed.args[0])
        if lines[:2] == ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]:
            return _unknown_command()
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return CommandResult(ok=True, text=primary_line, lines=detail_lines)

    # Phase 1 authority model: all commands are allowed.
    lines = handler(state)
    primary_line = lines[0] if lines else "COMMAND EXECUTED."
    detail_lines = lines[1:] if len(lines) > 1 else None
    return CommandResult(ok=True, text=primary_line, lines=detail_lines)
