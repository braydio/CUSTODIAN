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
    active_layer_id: str | None = None
    document_modified: bool | None = None
    document_revision: int = 0
    last_received_sequence: int | None = None
    last_acknowledged_command: int | None = None
    pending_commands: set[int] = field(default_factory=set)
    known_commands: set[int] = field(default_factory=set)
    last_event_user_originated: bool | None = None
    layer_visibility: dict[str, bool] = field(default_factory=dict)
    layer_ids: dict[str, str] = field(default_factory=dict)

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
        supplied_revision = message.payload.get("revision")
        if (
            message.type in (MessageType.EDITOR_STATE, MessageType.EDITOR_SITE_CHANGED)
            and supplied_revision is not None
            and supplied_revision < self.document_revision
        ):
            raise ValueError("document revision must not move backwards")
        self.last_received_sequence = message.sequence
        if message.type in (MessageType.EDITOR_STATE, MessageType.EDITOR_SITE_CHANGED):
            self._apply_editor_payload(message.payload)
        elif message.type is MessageType.LAYER_STATE_CHANGED:
            self._apply_layer_payload(message.payload)
        elif message.type is MessageType.DOCUMENT_CHANGED:
            supplied = message.payload.get("revision")
            if supplied is not None and supplied < self.document_revision:
                raise ValueError("document revision must not move backwards")
            self.document_revision = supplied if supplied is not None else self.document_revision + 1
            if "modified" in message.payload:
                self.document_modified = bool(message.payload["modified"])
            self._apply_document_payload(message.payload)
        if message.type in (MessageType.EDITOR_SITE_CHANGED, MessageType.DOCUMENT_CHANGED, MessageType.LAYER_STATE_CHANGED, MessageType.COMMAND_RESULT):
            linked = message.cause in self.known_commands if message.cause is not None else False
            self.last_event_user_originated = not linked
            if linked:
                self.last_acknowledged_command = message.cause
                self.pending_commands.discard(message.cause)

    def _apply_editor_payload(self, payload: dict[str, Any]) -> None:
        previous_document = self.active_document_path
        if payload.get("has_document") is False:
            self.active_document_path = None
            self.active_sprite_id = None
            self.active_frame = None
            self.active_layer = None
            self.active_layer_id = None
            self.document_modified = None
            self.layer_visibility.clear()
            self.layer_ids.clear()
            return
        if "document_path" in payload and payload["document_path"] != previous_document:
            self.layer_visibility.clear()
            self.layer_ids.clear()
        mappings = {
            "document_path": "active_document_path",
            "sprite_id": "active_sprite_id",
            "frame": "active_frame",
            "layer": "active_layer",
            "layer_id": "active_layer_id",
            "modified": "document_modified",
            "revision": "document_revision",
        }
        for source, target in mappings.items():
            if source in payload:
                setattr(self, target, payload[source])

    def _apply_layer_payload(self, payload: dict[str, Any]) -> None:
        layer = payload.get("layer")
        if not isinstance(layer, str):
            return
        visible = payload.get("visible")
        if isinstance(visible, bool):
            self.layer_visibility[layer] = visible
        layer_id = payload.get("layer_id")
        if isinstance(layer_id, str):
            self.layer_ids[layer] = layer_id

    def _apply_document_payload(self, payload: dict[str, Any]) -> None:
        for source, target in {
            "document_path": "active_document_path",
            "sprite_id": "active_sprite_id",
        }.items():
            if source in payload:
                setattr(self, target, payload[source])
