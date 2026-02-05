"""Tests for terminal input parsing."""

from game.simulations.world_state.terminal.parser import parse_input


def test_parse_input_with_quotes() -> None:
    """Quoted args should be preserved and verb uppercased."""

    parsed = parse_input('status "Security Gate / Checkpoint"')

    assert parsed is not None
    assert parsed.verb == "STATUS"
    assert parsed.args == ["Security Gate / Checkpoint"]


def test_parse_input_empty_returns_none() -> None:
    """Empty input should not produce a command."""

    assert parse_input("   ") is None
