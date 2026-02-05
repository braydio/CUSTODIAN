"""Tests for terminal input parsing and sector matching."""

from game.simulations.world_state.core.config import SECTORS
from game.simulations.world_state.terminal.parser import (
    parse_input,
    resolve_sector_name,
)


def test_parse_input_with_quotes_and_flags() -> None:
    parsed = parse_input('status "Security Gate / Checkpoint" --verbose')

    assert parsed is not None
    assert parsed.verb == "status"
    assert parsed.args == ["security gate / checkpoint"]
    assert parsed.flags == {"verbose": "true"}


def test_resolve_sector_name_exact() -> None:
    name, error = resolve_sector_name("command center", SECTORS)

    assert error is None
    assert name == "Command Center"


def test_resolve_sector_name_prefix() -> None:
    name, error = resolve_sector_name("maintenance", SECTORS)

    assert error is None
    assert name == "Maintenance Yard"


def test_resolve_sector_name_ambiguous() -> None:
    name, error = resolve_sector_name("hangar", SECTORS)

    assert name is None
    assert error is not None
    assert "ambiguous" in error.casefold()


def test_resolve_sector_name_missing() -> None:
    name, error = resolve_sector_name("archive", SECTORS)

    assert name is None
    assert error == "Sector not found."
