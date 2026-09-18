"""Presentation-only state held by the Operator live bridge."""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any
from uuid import uuid4

from .protocol import Message, MessageType


class ConnectionState(str, Enum):
    DISCONNECTED = "disconnected"
    CONNECTED = "connected"


@dataclass(slots=True)
class BridgeState:
    bridge_session_id: str = field(default_factory=lambda: uuid4().hex)
    connection: ConnectionState = ConnectionState.DISCONNECTED
    client_session_id: str | None = None
    aseprite_version: str | None = None
    api_version: str | None = None
    capabilities: frozenset[str] = field(default_factory=frozenset)
    active_document_path: str | None = None
    active_sprite_id: str | int | None = None
    active_frame: int | None = None
    active_layer: str | int | None = None
    document_modified: bool | None = None
    document_revision: int = 0
    last_received_sequence: int | None = None
    last_acknowledged_command: int | None = None
    pending_commands: set[int] = field(default_factory=set)
    known_commands: set[int] = field(default_factory=set)
    last_event_user_originated: bool | None = None

    def connect(self, hello: Message) -> None:
        payload = hello.payload
        self.connection = ConnectionState.CONNECTED
        self.client_session_id = hello.session_id
        self.aseprite_version = payload["aseprite_version"]
        self.api_version = payload["api_version"]
        self.capabilities = frozenset(payload["capabilities"])
        self.last_received_sequence = hello.sequence
        if isinstance(payload.get("editor_state"), dict):
            self._apply_editor_payload(payload["editor_state"])

    def disconnect(self) -> None:
        self.connection = ConnectionState.DISCONNECTED
        self.client_session_id = None
        self.pending_commands.clear()

    def track_command(self, sequence: int) -> None:
        self.pending_commands.add(sequence)
        self.known_commands.add(sequence)

    def apply(self, message: Message) -> None:
        if self.last_received_sequence is not None and message.sequence <= self.last_received_sequence:
            raise ValueError("client sequence must increase within a session")
        self.last_received_sequence = message.sequence
        if message.type is MessageType.EDITOR_STATE:
            self._apply_editor_payload(message.payload)
        elif message.type is MessageType.DOCUMENT_CHANGED:
            supplied = message.payload.get("revision")
            if supplied is not None and supplied < self.document_revision:
                raise ValueError("document revision must not move backwards")
            self.document_revision = supplied if supplied is not None else self.document_revision + 1
            if "modified" in message.payload:
                self.document_modified = bool(message.payload["modified"])
        if message.type in (MessageType.EDITOR_SITE_CHANGED, MessageType.DOCUMENT_CHANGED, MessageType.COMMAND_RESULT):
            linked = message.cause in self.known_commands if message.cause is not None else False
            self.last_event_user_originated = not linked
            if linked:
                self.last_acknowledged_command = message.cause
                self.pending_commands.discard(message.cause)

    def _apply_editor_payload(self, payload: dict[str, Any]) -> None:
        mappings = {
            "document_path": "active_document_path",
            "sprite_id": "active_sprite_id",
            "frame": "active_frame",
            "layer": "active_layer",
            "modified": "document_modified",
            "revision": "document_revision",
        }
        for source, target in mappings.items():
            if source in payload:
                setattr(self, target, payload[source])
