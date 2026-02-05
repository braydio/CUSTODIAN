"""Tests for terminal parsing and sector name resolution."""

from game.simulations.world_state.core.config import SECTORS
from game.simulations.world_state.terminal.parser import (
    parse_input,
    resolve_sector_name,
)


def test_parse_input_quotes_flags_casefold() -> None:
    """Ensure parsing honors quotes, flags, and casefolding."""

    parsed = parse_input('WAIT "2" --mode=fast -v')

    assert parsed is not None
    assert parsed.verb == "wait"
    assert parsed.args == ["2"]
    assert parsed.flags == {"mode": "fast", "v": "true"}


def test_parse_input_casefolds_verbs() -> None:
    """Verify verbs are casefolded during parsing."""

    parsed = parse_input("StAtUs")

    assert parsed is not None
    assert parsed.verb == "status"


def test_resolve_sector_name_exact() -> None:
    """Exact sector name matches should resolve cleanly."""

    name, error = resolve_sector_name("Goal Sector", SECTORS)

    assert error is None
    assert name == "Goal Sector"


def test_resolve_sector_name_prefix() -> None:
    """Prefix matches should resolve when unambiguous."""

    name, error = resolve_sector_name("maint", SECTORS)

    assert error is None
    assert name == "Maintenance Yard"


def test_resolve_sector_name_contains() -> None:
    """Contains matches should resolve when unambiguous."""

    name, error = resolve_sector_name("tower", SECTORS)

    assert error is None
    assert name == "Radar / Control Tower"


def test_resolve_sector_name_ambiguous() -> None:
    """Ambiguous matches should return an error."""

    name, error = resolve_sector_name("hangar", SECTORS)

    assert name is None
    assert error is not None
    assert "ambiguous" in error.casefold()
