"""Parsing utilities for terminal input."""

from dataclasses import dataclass
import shlex
from typing import Dict, Iterable, List, Optional, Tuple


@dataclass(frozen=True)
class ParsedCommand:
    """Normalized command parsing output.

    Attributes:
        raw: Raw input text after trimming.
        verb: Normalized command verb.
        args: Non-flag arguments.
        flags: Parsed flags keyed by name.
    """

    raw: str
    verb: str
    args: List[str]
    flags: Dict[str, str]


def normalize_input(text: str) -> str:
    """Trim and casefold the input string.

    Args:
        text: Raw input string.

    Returns:
        Normalized input.
    """

    return text.strip().casefold()


def tokenize_input(text: str) -> List[str]:
    """Tokenize input text while honoring quoted strings."""

    return shlex.split(text)


def parse_input(text: str) -> Optional[ParsedCommand]:
    """Parse raw input into a command structure.

    Args:
        text: Raw input string.

    Returns:
        ParsedCommand if any tokens were provided, otherwise None.
    """

    normalized = normalize_input(text)
    if not normalized:
        return None
    tokens = tokenize_input(normalized)
    if not tokens:
        return None
    verb = tokens[0]
    args: List[str] = []
    flags: Dict[str, str] = {}
    for token in tokens[1:]:
        if token.startswith("--"):
            key_value = token[2:]
            if "=" in key_value:
                key, value = key_value.split("=", 1)
                flags[key] = value
            else:
                flags[key_value] = "true"
        elif token.startswith("-") and len(token) > 1:
            flags[token[1:]] = "true"
        else:
            args.append(token)
    return ParsedCommand(raw=normalized, verb=verb, args=args, flags=flags)


def resolve_sector_name(
    query: str, sector_names: Iterable[str]
) -> Tuple[Optional[str], Optional[str]]:
    """Resolve a sector name using exact, prefix, then contains matching.

    Args:
        query: Sector query string.
        sector_names: Iterable of sector names to match against.

    Returns:
        Tuple of (resolved_name, error_message). Error message is populated
        when resolution fails or is ambiguous.
    """

    normalized_query = query.strip().casefold()
    if not normalized_query:
        return None, "Sector name required."

    normalized_sectors = {name.casefold(): name for name in sector_names}
    if normalized_query in normalized_sectors:
        return normalized_sectors[normalized_query], None

    prefix_matches = [
        name
        for norm, name in normalized_sectors.items()
        if norm.startswith(normalized_query)
    ]
    if len(prefix_matches) == 1:
        return prefix_matches[0], None
    if len(prefix_matches) > 1:
        return None, f"Sector match ambiguous: {', '.join(sorted(prefix_matches))}."

    contains_matches = [
        name for norm, name in normalized_sectors.items() if normalized_query in norm
    ]
    if len(contains_matches) == 1:
        return contains_matches[0], None
    if len(contains_matches) > 1:
        return None, f"Sector match ambiguous: {', '.join(sorted(contains_matches))}."

    return None, "Sector not found."
