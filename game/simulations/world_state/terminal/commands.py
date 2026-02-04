"""Command registry and handlers for the world-state terminal."""

from dataclasses import dataclass
from typing import Callable, Dict, Iterable, Optional

from game.simulations.world_state.core.state import GameState, SectorState, advance_time
from game.simulations.world_state.core.config import SECTORS
from game.simulations.world_state.terminal.parser import (
    ParsedCommand,
    resolve_sector_name,
)


@dataclass(frozen=True)
class Command:
    """Specification for a terminal command.

    Attributes:
        name: Command verb.
        authority: Required authority level ("read" or "write").
        handler: Callable that executes the command.
        usage: Usage string for help output.
        description: Short description of behavior.
    """

    name: str
    authority: str
    handler: Callable[[GameState, ParsedCommand], "CommandResult"]
    usage: str
    description: str


@dataclass(frozen=True)
class CommandResult:
    """Result payload returned by command handlers.

    Attributes:
        ok: Whether the command completed successfully.
        message: Text output to display to the operator.
    """

    ok: bool
    message: str


COMMANDS: Dict[str, Command] = {}


def register_command(command: Command) -> None:
    """Register a command specification in the global registry.

    Args:
        command: Command spec to register.
    """

    COMMANDS[command.name] = command


def get_command(name: str) -> Optional[Command]:
    """Lookup a command by name.

    Args:
        name: Command verb.

    Returns:
        Command spec if found, otherwise None.
    """

    return COMMANDS.get(name)


def list_commands() -> Iterable[Command]:
    """Return all registered commands sorted by name."""

    return [COMMANDS[name] for name in sorted(COMMANDS)]


def _format_sector(sector: SectorState) -> str:
    """Format a single sector line for display."""

    effects = ", ".join(sector.effects.keys())
    effect_text = f" FX={effects}" if effects else ""
    return (
        f"{sector.name}: "
        f"DMG={sector.damage:.2f} "
        f"ALERT={sector.alertness:.2f} "
        f"PWR={sector.power:.2f}"
        f"{effect_text}"
    )


def handle_help(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Return a help list of all available commands."""

    lines = ["Available commands:"]
    for command in list_commands():
        lines.append(f"- {command.usage}: {command.description}")
    return CommandResult(ok=True, message="\n".join(lines))


def handle_status(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Return a terse summary of the current world state."""

    assault_state = "active" if state.in_major_assault else "idle"
    timer_text = "none" if state.assault_timer is None else str(state.assault_timer)
    lines = [
        f"Time={state.time} Threat={state.ambient_threat:.2f}",
        f"Assault={assault_state} Timer={timer_text}",
        f"Control={'local' if state.player_present else 'remote'}",
    ]
    return CommandResult(ok=True, message="\n".join(lines))


def handle_sectors(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """List all sector names."""

    return CommandResult(ok=True, message="\n".join(SECTORS))


def handle_sector(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Return the status line for a specific sector."""

    if not parsed.args:
        return CommandResult(ok=False, message="Sector name required.")
    raw_sector = " ".join(parsed.args)
    sector_name, error = resolve_sector_name(raw_sector, SECTORS)
    if error:
        return CommandResult(ok=False, message=error)
    sector = state.sectors[sector_name]
    return CommandResult(ok=True, message=_format_sector(sector))


def handle_profile(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Return the hostile profile summary."""

    profile = state.faction_profile
    lines = [
        "Hostile profile:",
        f"{profile['label']} | Ideology: {profile['ideology']} | Tech: {profile['tech_expression']}",
        f"Doctrine: {profile['doctrine']} | Aggression: {profile['aggression']} | Signature: {profile['signature']}",
        f"Primary target: {profile['target_priority']}",
    ]
    return CommandResult(ok=True, message="\n".join(lines))


def handle_advance(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Advance time by a specified number of ticks.

    Note:
        Phase 1 advances time and ambient effects only. It does not trigger
        assaults or ambient events to keep operator control deterministic.
    """

    ticks = 1
    if parsed.args:
        try:
            ticks = int(parsed.args[0])
        except ValueError:
            return CommandResult(ok=False, message="Ticks must be an integer.")
    if ticks <= 0:
        return CommandResult(ok=False, message="Ticks must be positive.")

    for _ in range(ticks):
        advance_time(state)

    return CommandResult(ok=True, message=f"Advanced {ticks} ticks.")


def register_default_commands() -> None:
    """Register the default command set."""

    register_command(
        Command(
            name="help",
            authority="read",
            handler=handle_help,
            usage="help",
            description="List available commands.",
        )
    )
    register_command(
        Command(
            name="status",
            authority="read",
            handler=handle_status,
            usage="status",
            description="Show the current world status.",
        )
    )
    register_command(
        Command(
            name="profile",
            authority="read",
            handler=handle_profile,
            usage="profile",
            description="Show the hostile profile summary.",
        )
    )
    register_command(
        Command(
            name="sectors",
            authority="read",
            handler=handle_sectors,
            usage="sectors",
            description="List all sectors.",
        )
    )
    register_command(
        Command(
            name="sector",
            authority="read",
            handler=handle_sector,
            usage="sector <name>",
            description="Inspect a specific sector.",
        )
    )
    register_command(
        Command(
            name="advance",
            authority="write",
            handler=handle_advance,
            usage="advance [ticks]",
            description="Advance time by the requested ticks.",
        )
    )


register_default_commands()
