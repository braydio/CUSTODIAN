"""Command processor for the world-state terminal."""

from collections.abc import Callable

from game.simulations.world_state.core.assaults import start_assault
from game.simulations.world_state.core.config import SECTOR_DEFS
from game.simulations.world_state.core.presence import tick_presence
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState
from game.simulations.world_state.core.invariants import validate_state_invariants
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.terminal.authority import requires_command_authority
from game.simulations.world_state.terminal.commands import (
    cmd_deploy,
    cmd_allocate_defense,
    cmd_config_doctrine,
    cmd_focus,
    cmd_harden,
    cmd_help,
    cmd_move,
    cmd_fortify,
    cmd_repair,
    cmd_return,
    cmd_reset,
    cmd_scavenge,
    cmd_scavenge_runs,
    cmd_set_fabrication,
    cmd_set_policy,
    cmd_status,
    cmd_wait,
    cmd_wait_until,
    cmd_wait_ticks,
)
from game.simulations.world_state.terminal.parser import parse_input
from game.simulations.world_state.terminal.result import CommandResult
from game.simulations.world_state.terminal.messages import MESSAGES

Handler = Callable[[GameState], list[str]]
SECTOR_ID_TO_NAME = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
SECTOR_NAME_TO_NAME = {sector["name"]: sector["name"] for sector in SECTOR_DEFS}


COMMAND_HANDLERS: dict[str, Handler] = {
    "STATUS": cmd_status,
    "WAIT": cmd_wait,
    "HELP": lambda state: cmd_help(dev_mode=state.dev_mode),
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


def _parse_multiplier(token: str) -> int | None:
    normalized = token.strip().upper()
    if not normalized.endswith("X"):
        return None
    body = normalized[:-1]
    if not body.isdigit():
        return None
    count = int(body)
    if count <= 0:
        return None
    return count


def _resolve_sector_name(token: str) -> str | None:
    normalized = token.strip().upper()
    if not normalized:
        return None
    return SECTOR_ID_TO_NAME.get(normalized) or SECTOR_NAME_TO_NAME.get(normalized)


def _handle_debug_command(state: GameState, args: list[str]) -> CommandResult:
    if not args:
        return CommandResult(ok=False, text="DEBUG REQUIRES SUBCOMMAND.")

    sub = args[0].upper()
    if sub == "HELP":
        return CommandResult(
            ok=True,
            text="DEBUG COMMANDS:",
            lines=[
                "- DEBUG ASSAULT",
                "- DEBUG TICK <N>",
                "- DEBUG TIMER <VALUE>",
                "- DEBUG POWER <SECTOR> <VALUE>",
                "- DEBUG DAMAGE <SECTOR> <VALUE>",
                "- DEBUG TRACE",
                "- DEBUG REPORT",
                "- DEBUG HELP",
            ],
        )
    if sub == "ASSAULT":
        return _debug_force_assault(state)
    if sub == "TICK":
        return _debug_advance_ticks(state, args[1:])
    if sub == "TIMER":
        return _debug_set_assault_timer(state, args[1:])
    if sub == "POWER":
        return _debug_set_power(state, args[1:])
    if sub == "DAMAGE":
        return _debug_set_damage(state, args[1:])
    if sub in {"TRACE", "ASSAULT_TRACE"}:
        state.dev_trace = not state.dev_trace
        state.assault_trace_enabled = state.dev_trace
        return CommandResult(ok=True, text=f"ASSAULT TRACE = {state.assault_trace_enabled}")
    if sub in {"REPORT", "ASSAULT_REPORT"}:
        return _debug_assault_report(state)

    return CommandResult(ok=False, text="UNKNOWN DEBUG SUBCOMMAND.")


def _debug_force_assault(state: GameState) -> CommandResult:
    if state.current_assault is not None or state.in_major_assault:
        return CommandResult(ok=False, text="ASSAULT ALREADY ACTIVE.")
    start_assault(state)
    return CommandResult(ok=True, text="ASSAULT FORCED.")


def _debug_advance_ticks(state: GameState, args: list[str]) -> CommandResult:
    if not args or not args[0].isdigit():
        return CommandResult(ok=False, text="DEBUG TICK <N> REQUIRED.")
    tick_count = int(args[0])
    if tick_count <= 0:
        return CommandResult(ok=False, text="TICK COUNT MUST BE > 0.")

    became_failed = False
    for _ in range(tick_count):
        became_failed = step_world(state)
        tick_presence(state)
        if became_failed:
            break

    if became_failed:
        reason = state.failure_reason or "SESSION FAILED."
        return CommandResult(
            ok=True,
            text=f"ADVANCED {tick_count} TICKS.",
            lines=[reason, "SESSION TERMINATED."],
        )
    return CommandResult(ok=True, text=f"ADVANCED {tick_count} TICKS.")


def _debug_set_assault_timer(state: GameState, args: list[str]) -> CommandResult:
    if not args or not args[0].isdigit():
        return CommandResult(ok=False, text="DEBUG TIMER <VALUE> REQUIRED.")
    state.assault_timer = int(args[0])
    return CommandResult(ok=True, text=f"ASSAULT TIMER SET TO {state.assault_timer}")


def _debug_set_power(state: GameState, args: list[str]) -> CommandResult:
    if len(args) != 2:
        return CommandResult(ok=False, text="DEBUG POWER <SECTOR> <VALUE>")
    sector_name = _resolve_sector_name(args[0])
    if sector_name is None:
        return CommandResult(ok=False, text="UNKNOWN SECTOR.")

    try:
        value = float(args[1])
    except ValueError:
        return CommandResult(ok=False, text="INVALID POWER VALUE.")

    state.sectors[sector_name].power = value
    return CommandResult(ok=True, text=f"{sector_name} POWER SET TO {value}")


def _debug_set_damage(state: GameState, args: list[str]) -> CommandResult:
    if len(args) != 2:
        return CommandResult(ok=False, text="DEBUG DAMAGE <SECTOR> <VALUE>")
    sector_name = _resolve_sector_name(args[0])
    if sector_name is None:
        return CommandResult(ok=False, text="UNKNOWN SECTOR.")

    try:
        value = float(args[1])
    except ValueError:
        return CommandResult(ok=False, text="INVALID DAMAGE VALUE.")

    state.sectors[sector_name].damage = value
    target_state = _structure_state_for_debug_damage(value)
    affected = 0
    for structure in state.structures.values():
        if structure.sector != sector_name:
            continue
        structure.state = target_state
        affected += 1
    return CommandResult(
        ok=True,
        text=f"{sector_name} DAMAGE SET TO {value}",
        lines=[f"STRUCTURES UPDATED: {affected} -> {target_state.value}"],
    )


def _structure_state_for_debug_damage(damage: float) -> StructureState:
    if damage >= 3.0:
        return StructureState.DESTROYED
    if damage >= 2.0:
        return StructureState.OFFLINE
    if damage >= 1.0:
        return StructureState.DAMAGED
    return StructureState.OPERATIONAL


def _debug_assault_report(state: GameState) -> CommandResult:
    rows = state.assault_ledger.ticks[-20:]
    if not rows:
        return CommandResult(ok=True, text="ASSAULT REPORT: NO RECORDS.")

    lines: list[str] = []
    if state.last_target_weights:
        weight_parts = [f"{sid}={value:.2f}" for sid, value in sorted(state.last_target_weights.items())]
        lines.append("TARGET WEIGHTS: " + ", ".join(weight_parts))

    for record in rows:
        line = (
            f"T{record.tick:04d} {record.targeted_sector} "
            f"W={record.target_weight:.2f} "
            f"S={record.assault_strength:.2f} "
            f"M={record.defense_mitigation:.2f}"
        )
        if record.building_destroyed:
            line += f" DESTROYED={record.building_destroyed}"
        if record.failure_triggered:
            line += " FAILURE=TRUE"
        if record.note:
            line += f" NOTE={record.note}"
        lines.append(line)

    return CommandResult(ok=True, text="ASSAULT REPORT:", lines=lines)


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

    if parsed.verb == "DEBUG":
        if not state.dev_mode:
            return _finalize_result(state, CommandResult(ok=False, text="DEV MODE DISABLED."))
        return _finalize_result(
            state,
            _handle_debug_command(state, parsed.args),
            "DEBUG",
        )

    if parsed.verb == "CONFIG":
        if len(parsed.args) != 2:
            return _finalize_result(state, CommandResult(ok=False, text="CONFIG DOCTRINE <NAME>"))
        if parsed.args[0].strip().upper() != "DOCTRINE":
            return _finalize_result(state, _unknown_command())
        lines = cmd_config_doctrine(state, parsed.args[1])
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "SET":
        if len(parsed.args) == 2:
            lines = cmd_set_policy(state, parsed.args[0], parsed.args[1])
        elif len(parsed.args) == 3 and parsed.args[0].strip().upper() == "FAB":
            lines = cmd_set_fabrication(state, parsed.args[1], parsed.args[2])
        else:
            return _finalize_result(
                state,
                CommandResult(ok=False, text="SET <REPAIR|DEFENSE|SURVEILLANCE> <0-4> | SET FAB <CAT> <0-4>"),
            )
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "FORTIFY":
        if len(parsed.args) != 2:
            return _finalize_result(state, CommandResult(ok=False, text="FORTIFY <SECTOR> <0-4>"))
        lines = cmd_fortify(state, parsed.args[0], parsed.args[1])
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "ALLOCATE":
        if len(parsed.args) != 3:
            return _finalize_result(state, CommandResult(ok=False, text="ALLOCATE DEFENSE <SECTOR> <PERCENT>"))
        if parsed.args[0].strip().upper() != "DEFENSE":
            return _finalize_result(state, _unknown_command())
        lines = cmd_allocate_defense(state, parsed.args[1], parsed.args[2])
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )

    if parsed.verb == "WAIT":
        if parsed.args and parsed.args[0].strip().upper() == "UNTIL":
            if len(parsed.args) != 2:
                return _finalize_result(
                    state,
                    CommandResult(ok=False, text="WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>"),
                )
            lines = cmd_wait_until(state, parsed.args[1])
            primary_line = lines[0] if lines else "COMMAND EXECUTED."
            detail_lines = lines[1:] if len(lines) > 1 else None
            return _finalize_result(
                state,
                CommandResult(ok=True, text=primary_line, lines=detail_lines),
                parsed.verb,
            )
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
        if len(parsed.args) > 2:
            return _finalize_result(state, CommandResult(ok=False, text="REPAIR <STRUCTURE> [FULL]"))
        full = False
        if len(parsed.args) == 2:
            if parsed.args[1].strip().upper() != "FULL":
                return _finalize_result(state, CommandResult(ok=False, text="REPAIR <STRUCTURE> [FULL]"))
            full = True
        lines = cmd_repair(state, parsed.args[0], full=full)
        primary_line = lines[0] if lines else "COMMAND EXECUTED."
        detail_lines = lines[1:] if len(lines) > 1 else None
        return _finalize_result(
            state,
            CommandResult(ok=True, text=primary_line, lines=detail_lines),
            parsed.verb,
        )
    if parsed.verb == "SCAVENGE":
        if len(parsed.args) > 1:
            return _finalize_result(state, _unknown_command())
        if not parsed.args:
            lines = cmd_scavenge(state)
        else:
            runs = _parse_multiplier(parsed.args[0])
            if runs is None:
                return _finalize_result(state, _unknown_command())
            lines = cmd_scavenge_runs(state, runs)
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
