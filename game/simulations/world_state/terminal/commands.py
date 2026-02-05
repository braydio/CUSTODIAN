"""Command registry and handlers for the world-state terminal."""

from dataclasses import dataclass
from typing import Callable, Dict, List, Optional

from game.simulations.world_state.core.config import SECTORS
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.parser import ParsedCommand


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
        text: Primary output line.
        lines: Optional list of additional output lines.
        warnings: Optional list of warning messages.
    """

    ok: bool
    text: str
    lines: Optional[List[str]] = None
    warnings: Optional[List[str]] = None


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


def handle_status(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Return a terse summary of current world state."""

    assault_state = "active" if state.in_major_assault else "idle"
    timer_text = "none" if state.assault_timer is None else str(state.assault_timer)
    lines = [
        f"Assault={assault_state} Timer={timer_text}",
        f"Location={state.player_location}",
        f"Authority={'command' if state.in_command_center else 'field'}",
    ]
    return CommandResult(
        ok=True,
        text=(
            f"Time={state.time} Threat={state.ambient_threat:.2f} "
            f"Location={state.player_location}"
        ),
        lines=lines,
    )


def handle_sectors(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """List all sector names."""

    return CommandResult(ok=True, text="Sectors:", lines=list(SECTORS))


def handle_power(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Report sector power status."""

    lines = []
    for name in SECTORS:
        sector = state.sectors[name]
        lines.append(f"{sector.name}: PWR={sector.power:.2f}")
    return CommandResult(ok=True, text="Power status:", lines=lines)


def handle_wait(state: GameState, parsed: ParsedCommand) -> CommandResult:
    """Advance the simulation by a specified number of ticks."""

    ticks = 1
    if parsed.args:
        try:
            ticks = int(parsed.args[0])
        except ValueError:
            return CommandResult(ok=False, text="Ticks must be an integer.")
    if ticks <= 0:
        return CommandResult(ok=False, text="Ticks must be positive.")

    for _ in range(ticks):
        step_world(state)

    return CommandResult(ok=True, text=f"Waited {ticks} ticks.")


def register_default_commands() -> None:
    """Register the default command set."""

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
            name="sectors",
            authority="read",
            handler=handle_sectors,
            usage="sectors",
            description="List all sectors.",
        )
    )
    register_command(
        Command(
            name="power",
            authority="read",
            handler=handle_power,
            usage="power",
            description="Show sector power levels.",
        )
    )
    register_command(
        Command(
            name="wait",
            authority="write",
            handler=handle_wait,
            usage="wait [ticks]",
            description="Advance the simulation by requested ticks.",
        )
    )


register_default_commands()
