"""Terminal command result contract."""

from dataclasses import dataclass
from typing import List


@dataclass(frozen=True)
class CommandResult:
    """Structured response for terminal command handlers.

    Attributes:
        ok: Whether the command executed successfully.
        lines: Ordered terminal lines to print.
    """

    ok: bool
    lines: List[str]
