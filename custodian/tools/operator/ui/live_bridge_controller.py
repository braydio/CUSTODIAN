"""Textual-facing lifecycle adapter for the presentation-only Live Bridge."""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Callable

from live_bridge.server import DEFAULT_HOST, DEFAULT_PORT, LiveBridgeServer
from live_bridge.state import ConnectionState


class LiveBridgeUIStatus(str, Enum):
    STOPPED = "stopped"
    STARTING = "starting"
    WAITING = "waiting"
    CONNECTED = "connected"
    UNAVAILABLE = "unavailable"


@dataclass(frozen=True, slots=True)
class LiveBridgeSnapshot:
    status: LiveBridgeUIStatus
    host: str = DEFAULT_HOST
    port: int = DEFAULT_PORT
    aseprite_version: str | None = None
    error: str | None = None


class LiveBridgeController:
    """Owns server lifecycle and projects immutable UI status."""

    def __init__(
        self,
        repo_root: Path,
        *,
        port: int = DEFAULT_PORT,
        server_factory: Callable[..., LiveBridgeServer] = LiveBridgeServer,
    ) -> None:
        self.server = server_factory(repo_root, port=port)
        self._status = LiveBridgeUIStatus.STOPPED
        self._error: str | None = None

    async def start(self) -> None:
        if self._status not in (LiveBridgeUIStatus.STOPPED, LiveBridgeUIStatus.UNAVAILABLE):
            return
        self._status = LiveBridgeUIStatus.STARTING
        self._error = None
        try:
            await self.server.start()
        except Exception as error:  # Presentation boundary: server failures are non-fatal.
            self._status = LiveBridgeUIStatus.UNAVAILABLE
            self._error = str(error).strip() or error.__class__.__name__
            return
        self._status = LiveBridgeUIStatus.WAITING

    async def stop(self) -> None:
        try:
            await self.server.stop()
        finally:
            self._status = LiveBridgeUIStatus.STOPPED

    def snapshot(self) -> LiveBridgeSnapshot:
        if self._status in (
            LiveBridgeUIStatus.STARTING,
            LiveBridgeUIStatus.UNAVAILABLE,
            LiveBridgeUIStatus.STOPPED,
        ):
            status = self._status
        elif self.server.state.connection is ConnectionState.CONNECTED:
            status = LiveBridgeUIStatus.CONNECTED
        else:
            status = LiveBridgeUIStatus.WAITING
        return LiveBridgeSnapshot(
            status=status,
            host=self.server.HOST,
            port=self.server.port,
            aseprite_version=self.server.state.aseprite_version,
            error=self._error,
        )
