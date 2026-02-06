"""Tests for terminal command parsing."""

from game.simulations.world_state.terminal.parser import parse_input


def test_parse_input_uppercases_verb_and_preserves_args() -> None:
    """Parser should normalize verb and preserve positional args."""

    parsed = parse_input('wait "north gate"')

    assert parsed is not None
    assert parsed.verb == "WAIT"
    assert parsed.args == ["north gate"]


def test_parse_input_returns_none_for_empty_text() -> None:
    """Parser should ignore empty command lines."""

    assert parse_input("   ") is None
