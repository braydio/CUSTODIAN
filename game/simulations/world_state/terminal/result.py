"""Terminal command result contract."""

from dataclasses import dataclass
from typing import List, Optional


@dataclass(frozen=True)
class CommandResult:
    """Structured response for terminal command handlers.

    Attributes:
        ok: Whether the command executed successfully.
        text: Primary operator-facing terminal line.
        lines: Optional ordered detail lines to print after ``text``.
        warnings: Optional warning lines for non-fatal conditions.
    """

    ok: bool
    text: str
    lines: Optional[List[str]] = None
    warnings: Optional[List[str]] = None
