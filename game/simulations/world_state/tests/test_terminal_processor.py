"""Tests for terminal command processing behavior."""

from copy import deepcopy

from game.simulations.world_state.terminal.parser import ParsedCommand
from game.simulations.world_state.terminal.processor import process_command
from game.simulations.world_state.core.state import GameState


def _snapshot_state(state: GameState) -> dict:
    """Capture a stable snapshot of mutable state for comparison."""

    return {
        "time": state.time,
        "ambient_threat": state.ambient_threat,
        "assault_timer": state.assault_timer,
        "in_major_assault": state.in_major_assault,
        "player_location": state.player_location,
        "current_assault": state.current_assault,
        "assault_count": state.assault_count,
        "event_cooldowns": dict(state.event_cooldowns),
        "faction_profile": dict(state.faction_profile),
        "event_catalog": state.event_catalog,
        "global_effects": dict(state.global_effects),
        "sectors": {
            name: {
                "damage": sector.damage,
                "alertness": sector.alertness,
                "power": sector.power,
                "last_event": sector.last_event,
                "occupied": sector.occupied,
                "effects": dict(sector.effects),
            }
            for name, sector in state.sectors.items()
        },
    }


def test_wait_increments_time() -> None:
    """WAIT should advance world time."""

    state = GameState()
    parsed = ParsedCommand(raw="wait 2", verb="wait", args=["2"], flags={})

    result = process_command(state, parsed)

    assert result is not None
    assert result.ok is True
    assert state.time == 2


def test_read_only_commands_do_not_mutate_state() -> None:
    """Read-only commands should not mutate game state."""

    read_commands = {
        "status": [],
        "sectors": [],
        "power": [],
    }

    for verb, args in read_commands.items():
        state = GameState()
        parsed = ParsedCommand(raw=verb, verb=verb, args=args, flags={})
        before = _snapshot_state(deepcopy(state))

        result = process_command(state, parsed)

        assert result is not None
        assert result.ok is True
        assert _snapshot_state(state) == before
