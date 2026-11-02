from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class EventInstance:
    """Canonical per-tick event trigger record."""

    tick: int
    event_key: str
    event_name: str
    sector: str
    detected: bool
