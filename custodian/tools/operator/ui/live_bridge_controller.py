"""Textual-facing lifecycle adapter for the presentation-only Live Bridge."""
from __future__ import annotations

import asyncio
import hashlib
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Callable

from live_bridge.protocol import Message, MessageType
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


@dataclass(frozen=True, slots=True)
class LiveBridgeEvent:
    message_type: MessageType
    document_path: str | None = None
    frame: int | None = None
    revision: int | None = None
    modified: bool | None = None
    cause: int | None = None
    user_originated: bool = True
    operation: str | None = None
    ok: bool | None = None
    output_path: str | None = None
    frame_count: int | None = None
    frame_width: int | None = None
    frame_height: int | None = None
    error: str | None = None


def _project_string(value: object) -> str | None:
    return value if isinstance(value, str) else None


def _project_integer(value: object, *, minimum: int = 0) -> int | None:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        return None
    return value


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
        self._events: asyncio.Queue[LiveBridgeEvent] = asyncio.Queue()
        self.server.add_message_listener(self._on_message)

    def _on_message(self, message: Message) -> None:
        if message.type is MessageType.CLIENT_HELLO:
            payload = message.payload.get("editor_state", {})
        elif message.type is MessageType.EDITOR_SITE_CHANGED:
            payload = message.payload
        elif message.type is MessageType.DOCUMENT_CHANGED:
            payload = message.payload
        elif message.type is MessageType.COMMAND_RESULT:
            payload = message.payload
            if payload.get("operation") != "export_preview":
                return
        else:
            return
        if not isinstance(payload, dict):
            return
        document_path = payload.get("document_path")
        frame = payload.get("frame")
        revision = payload.get("revision")
        modified = payload.get("modified")
        self._events.put_nowait(LiveBridgeEvent(
            message_type=message.type,
            document_path=_project_string(document_path),
            frame=_project_integer(frame, minimum=1),
            revision=_project_integer(revision),
            modified=modified if isinstance(modified, bool) else None,
            cause=message.cause,
            user_originated=message.cause is None and message.type is not MessageType.COMMAND_RESULT,
            operation="export_preview" if message.type is MessageType.COMMAND_RESULT else None,
            ok=payload.get("ok") if isinstance(payload.get("ok"), bool) else None,
            output_path=_project_string(payload.get("output_path")),
            frame_count=_project_integer(payload.get("frames"), minimum=1),
            frame_width=_project_integer(payload.get("frame_width"), minimum=1),
            frame_height=_project_integer(payload.get("frame_height"), minimum=1),
            error=_project_string(payload.get("error")),
        ))

    async def next_event(self) -> LiveBridgeEvent:
        return await self._events.get()

    async def select_frame(self, workbench_path: Path, frame_index: int) -> int:
        if frame_index < 0:
            raise ValueError("frame_index must be zero-based and non-negative")
        document = self.server.paths.validate_workbench(workbench_path)
        return await self.server.send_command(MessageType.SELECT_FRAME, {
            "frame": frame_index + 1,
            "document_path": str(document),
        })

    def _live_preview_path(self, workbench_path: Path) -> Path:
        document = self.server.paths.validate_workbench(workbench_path)
        key = hashlib.sha256(str(document).encode("utf-8")).hexdigest()[:16]
        output = self.server.paths.preview_root / f"{key}.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        return output

    async def export_preview(self, workbench_path: Path, revision: int) -> int:
        if revision < 0:
            raise ValueError("revision must be non-negative")
        document = self.server.paths.validate_workbench(workbench_path)
        output = self._live_preview_path(document)
        return await self.server.send_command(MessageType.EXPORT_PREVIEW, {
            "document_path": str(document),
            "output_path": str(output),
            "revision": revision,
        })

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
