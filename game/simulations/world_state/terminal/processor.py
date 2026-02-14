"""Command processor for the world-state terminal."""

from collections.abc import Callable

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.invariants import validate_state_invariants
from game.simulations.world_state.terminal.authority import requires_command_authority
from game.simulations.world_state.terminal.commands import (
    cmd_deploy,
    cmd_focus,
    cmd_harden,
    cmd_help,
    cmd_move,
    cmd_repair,
    cmd_return,
    cmd_reset,
    cmd_scavenge,
    cmd_status,
    cmd_wait,
    cmd_wait_ticks,
)
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.result import CommandResult
from game.simulations.world_state.terminal.messages import MESSAGES

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


def _finalize_result(state: GameState, result: CommandResult, verb: str | None = None) -> CommandResult:
    validate_state_invariants(state)
    if verb and result.text:
        state.operator_log.append(f"T{state.time:04d} {verb}: {result.text}")
        if len(state.operator_log) > 300:
            del state.operator_log[:-300]
    return result


def _parse_wait_ticks(args: list[str]) -> int | None:
    if not args:
        return 1
    if len(args) != 1:
        return None
    token = args[0].strip().upper()
    if not token.endswith("X"):
        return None
    count_text = token[:-1]
    if not count_text.isdigit():
        return None
    count = int(count_text)
    if count <= 0:
        return None
    return count


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
        return _finalize_result(state, _unknown_command())

    if parsed.verb in {"RESET", "REBOOT"}:
        lines = cmd_reset(state)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if state.is_failed:
        return _finalize_result(
            state,
            CommandResult(
            ok=False,
            text=state.failure_reason or "SESSION FAILED.",
            lines=["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."],
            ),
        )

    if state.in_field_mode() and requires_command_authority(parsed.verb):
        return _finalize_result(
            state,
            CommandResult(ok=False, text=MESSAGES["AUTHORITY_REQUIRED"]),
        )

    if parsed.verb == "WAIT":
        ticks = _parse_wait_ticks(parsed.args)
        if ticks is None:
            return _finalize_result(state, _unknown_command())
        lines = cmd_wait_ticks(state, ticks)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "DEPLOY":
        if len(parsed.args) > 1:
            return _finalize_result(state, CommandResult(ok=False, text="USE QUOTES FOR MULTI-WORD TARGET."))
        destination = parsed.args[0] if parsed.args else ""
        lines = cmd_deploy(state, destination)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "MOVE":
        if len(parsed.args) == 0:
            return _finalize_result(state, CommandResult(ok=False, text="MOVE REQUIRES TARGET."))
        if len(parsed.args) > 1:
            return _finalize_result(state, CommandResult(ok=False, text="USE QUOTES FOR MULTI-WORD TARGET."))
        lines = cmd_move(state, parsed.args[0])
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "RETURN":
        if parsed.args:
            return _finalize_result(state, _unknown_command())
        lines = cmd_return(state)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "FOCUS":
        if len(parsed.args) == 0:
            return _finalize_result(state, CommandResult(ok=False, text="FOCUS REQUIRES SECTOR ID."))
        if len(parsed.args) > 1:
            return _finalize_result(state, CommandResult(ok=False, text="USE QUOTES FOR MULTI-WORD SECTOR."))
        lines = cmd_focus(state, parsed.args[0])
        if lines[:2] == ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]:
            return _finalize_result(state, _unknown_command())
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "HARDEN":
        if parsed.args:
            return _finalize_result(state, _unknown_command())
        lines = cmd_harden(state)
        if lines[:2] == ["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]:
            return _finalize_result(state, _unknown_command())
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "REPAIR":
        if len(parsed.args) == 0:
            return _finalize_result(state, CommandResult(ok=False, text="REPAIR REQUIRES STRUCTURE ID."))
        if len(parsed.args) > 1:
            return _finalize_result(state, CommandResult(ok=False, text="USE QUOTES FOR MULTI-WORD STRUCTURE."))
        lines = cmd_repair(state, parsed.args[0])
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "SCAVENGE":
        if parsed.args:
            return _finalize_result(state, _unknown_command())
        lines = cmd_scavenge(state)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    handler = COMMAND_HANDLERS.get(parsed.verb)
    if handler is None:
        return _finalize_result(state, _unknown_command())

    # Phase 1 authority model: all commands are allowed.
    lines = handler(state)
    primary_line = lines[0] if lines else "COMMAND EXECUTED."
    detail_lines = lines[1:] if len(lines) > 1 else None
    return _finalize_result(
        state,
        CommandResult(ok=True, text=primary_line, lines=detail_lines),
        parsed.verb,
    )
