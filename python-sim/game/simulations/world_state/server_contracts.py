"""Shared command endpoint contract helpers."""

from __future__ import annotations

from collections import OrderedDict
import time
from typing import Any

from game.simulations.world_state.terminal.result import CommandResult


def parse_command_payload(payload: dict[str, Any]) -> tuple[str, str | None]:
    raw = payload.get("command", payload.get("raw", ""))
    if not isinstance(raw, str):
        raw = ""
    command_id = payload.get("command_id")
    if command_id is not None:
        command_id = str(command_id)
    return raw, command_id


def serialize_command_result(result: CommandResult) -> dict[str, Any]:
    lines = []
    if result.text:
        lines.append(result.text)
    if result.lines:
        lines.extend(result.lines)
    if result.warnings:
        lines.extend(result.warnings)
    return {"ok": bool(result.ok), "text": result.text, "lines": lines}


class CommandReplayCache:
    """Short-lived replay cache for command idempotency."""

    def __init__(self, *, ttl_seconds: float = 60.0, max_entries: int = 100):
        self.ttl_seconds = ttl_seconds
        self.max_entries = max_entries
        self._entries: OrderedDict[str, tuple[float, dict[str, Any]]] = OrderedDict()

    def _evict(self) -> None:
        now = time.time()
        stale = [key for key, (ts, _) in self._entries.items() if now - ts > self.ttl_seconds]
        for key in stale:
            self._entries.pop(key, None)
        while len(self._entries) > self.max_entries:
            self._entries.popitem(last=False)

    def get(self, command_id: str | None) -> dict[str, Any] | None:
        if not command_id:
            return None
        self._evict()
        entry = self._entries.get(command_id)
        if entry is None:
            return None
        ts, payload = entry
        if time.time() - ts > self.ttl_seconds:
            self._entries.pop(command_id, None)
            return None
        return payload

    def put(self, command_id: str | None, payload: dict[str, Any]) -> None:
        if not command_id:
            return
        self._entries[command_id] = (time.time(), payload)
        self._evict()

