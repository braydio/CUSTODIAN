"""Tests for command result contracts and output discipline."""

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.commands import CommandResult, get_command
from game.simulations.world_state.terminal.parser import ParsedCommand


def test_command_handlers_return_results_and_do_not_print(capsys) -> None:
    """All command handlers should return CommandResult without printing."""

    state = GameState()
    command_args = {
        "status": [],
        "sectors": [],
        "power": [],
        "wait": ["1"],
    }

    for name, args in command_args.items():
        command = get_command(name)

        assert command is not None

        parsed = ParsedCommand(raw=name, verb=name, args=args, flags={})
        result = command.handler(state, parsed)

        assert isinstance(result, CommandResult)

        captured = capsys.readouterr()
        assert captured.out == ""
        assert captured.err == ""
