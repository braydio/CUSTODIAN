"""Canonical location registry for normalization."""

from __future__ import annotations


class LocationRegistry:
    def __init__(self):
        self._aliases: dict[str, str] = {}

    def register(self, canonical: str, aliases: list[str]) -> None:
        self._aliases[canonical.upper()] = canonical
        for alias in aliases:
            self._aliases[alias.upper()] = canonical

    def normalize(self, name: str) -> str | None:
        if not name:
            return None
        return self._aliases.get(name.strip().upper())

