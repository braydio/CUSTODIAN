"""Parsing utilities for terminal input."""

from dataclasses import dataclass
import shlex
from typing import List, Optional


@dataclass(frozen=True)
class ParsedCommand:
    """Normalized command parsing output.

    Attributes:
        raw: Raw input text after trimming.
        verb: Uppercased command verb.
        args: Positional command arguments.
    """

    raw: str
    verb: str
    args: List[str]


def parse_input(text: str) -> Optional[ParsedCommand]:
    """Parse raw input into verb and argument tokens.

    Args:
        text: Raw command line supplied by the operator.

    Returns:
        ParsedCommand when tokens exist, otherwise None.
    """

    raw = text.strip()
    if not raw:
        return None

    tokens = shlex.split(raw)
    if not tokens:
        return None

    verb = tokens[0].upper()
    args = tokens[1:]
    return ParsedCommand(raw=raw, verb=verb, args=args)
