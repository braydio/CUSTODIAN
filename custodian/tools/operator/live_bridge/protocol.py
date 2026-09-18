"""Versioned messages and capability/path boundaries for the live bridge."""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
import json
from pathlib import Path
from typing import Any, Mapping

MESSAGE_SCHEMA = "custodian.operator_live_bridge.message.v1"


class ProtocolError(ValueError):
    """A peer sent a message outside the live-bridge contract."""


class MessageType(str, Enum):
    CLIENT_HELLO = "client.hello"
    SERVER_HELLO = "server.hello"
    EDITOR_STATE = "editor.state"
    EDITOR_SITE_CHANGED = "editor.site_changed"
    DOCUMENT_CHANGED = "document.changed"
    OPEN_WORKBENCH = "command.open_workbench"
    SELECT_FRAME = "command.select_frame"
    EXPORT_PREVIEW = "command.export_preview"
    SAVE = "command.save"
    COMMAND_RESULT = "command.result"
    HEARTBEAT = "heartbeat"


COMMAND_TYPES = frozenset({
    MessageType.OPEN_WORKBENCH,
    MessageType.SELECT_FRAME,
    MessageType.EXPORT_PREVIEW,
    MessageType.SAVE,
})

REQUIRED_CAPABILITIES = frozenset({
    "websocket",
    "app_events_sitechange",
    "sprite_change_events",
    "sprite_is_modified",
    "timer",
    "frame_selection",
    "image_render_export",
})


@dataclass(frozen=True, slots=True)
class Message:
    session_id: str
    sequence: int
    type: MessageType
    payload: dict[str, Any]
    cause: int | None = None
    schema: str = MESSAGE_SCHEMA

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "session_id": self.session_id,
            "sequence": self.sequence,
            "type": self.type.value,
            "cause": self.cause,
            "payload": self.payload,
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), separators=(",", ":"), sort_keys=True)


def parse_message(raw: str | bytes | Mapping[str, Any]) -> Message:
    try:
        data = json.loads(raw) if isinstance(raw, (str, bytes, bytearray)) else dict(raw)
    except (json.JSONDecodeError, UnicodeDecodeError, TypeError) as exc:
        raise ProtocolError("message must be a JSON object") from exc
    if not isinstance(data, dict):
        raise ProtocolError("message must be a JSON object")
    expected = {"schema", "session_id", "sequence", "type", "cause", "payload"}
    if set(data) != expected:
        missing = sorted(expected - set(data))
        extra = sorted(set(data) - expected)
        raise ProtocolError(f"invalid envelope fields; missing={missing}, extra={extra}")
    if data["schema"] != MESSAGE_SCHEMA:
        raise ProtocolError(f"unsupported schema: {data['schema']!r}")
    if not isinstance(data["session_id"], str) or not data["session_id"].strip():
        raise ProtocolError("session_id must be a non-empty string")
    if isinstance(data["sequence"], bool) or not isinstance(data["sequence"], int) or data["sequence"] < 1:
        raise ProtocolError("sequence must be a positive integer")
    cause = data["cause"]
    if cause is not None and (isinstance(cause, bool) or not isinstance(cause, int) or cause < 1):
        raise ProtocolError("cause must be null or a positive integer")
    if not isinstance(data["payload"], dict):
        raise ProtocolError("payload must be an object")
    try:
        message_type = MessageType(data["type"])
    except ValueError as exc:
        raise ProtocolError(f"unsupported message type: {data['type']!r}") from exc
    message = Message(
        session_id=data["session_id"], sequence=data["sequence"], type=message_type,
        cause=cause, payload=dict(data["payload"]),
    )
    _validate_payload(message)
    return message


def _validate_payload(message: Message) -> None:
    payload = message.payload
    if message.type is MessageType.CLIENT_HELLO:
        for key in ("aseprite_version", "api_version", "capabilities"):
            if key not in payload:
                raise ProtocolError(f"client.hello missing {key}")
        if not isinstance(payload["aseprite_version"], str) or not payload["aseprite_version"]:
            raise ProtocolError("aseprite_version must be a non-empty string")
        if not isinstance(payload["api_version"], str) or not payload["api_version"]:
            raise ProtocolError("api_version must be a non-empty string")
        validate_capabilities(payload["capabilities"])
        if "editor_state" in payload:
            if not isinstance(payload["editor_state"], dict):
                raise ProtocolError("editor_state must be an object")
            _validate_editor_payload(payload["editor_state"])
    elif message.type is MessageType.SELECT_FRAME:
        _positive_int(payload, "frame")
    elif message.type is MessageType.EDITOR_STATE:
        _validate_editor_payload(payload)
    elif message.type is MessageType.EDITOR_SITE_CHANGED:
        _validate_editor_payload(payload)
    elif message.type is MessageType.DOCUMENT_CHANGED:
        _validate_editor_payload(payload)
        if "revision" in payload and payload["revision"] is not None:
            _nonnegative_int(payload, "revision")
    elif message.type is MessageType.COMMAND_RESULT and message.cause is None:
        raise ProtocolError("command.result must identify its command in cause")
    elif message.type in (MessageType.OPEN_WORKBENCH, MessageType.EXPORT_PREVIEW):
        key = "path" if message.type is MessageType.OPEN_WORKBENCH else "output_path"
        if not isinstance(payload.get(key), str) or not payload[key]:
            raise ProtocolError(f"{message.type.value} requires {key}")


def _positive_int(payload: Mapping[str, Any], key: str) -> None:
    value = payload.get(key)
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ProtocolError(f"{key} must be a positive integer")


def _nonnegative_int(payload: Mapping[str, Any], key: str) -> None:
    value = payload.get(key)
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ProtocolError(f"{key} must be a non-negative integer")


def _validate_editor_payload(payload: Mapping[str, Any]) -> None:
    if "has_document" in payload and not isinstance(payload["has_document"], bool):
        raise ProtocolError("has_document must be a boolean")
    if "frame" in payload and payload["frame"] is not None:
        _positive_int(payload, "frame")
    if "revision" in payload and payload["revision"] is not None:
        _nonnegative_int(payload, "revision")
    for key in ("document_path", "layer", "layer_id"):
        if key in payload and payload[key] is not None and not isinstance(payload[key], str):
            raise ProtocolError(f"{key} must be a string")
    if "sprite_id" in payload and payload["sprite_id"] is not None:
        value = payload["sprite_id"]
        if isinstance(value, bool) or not isinstance(value, (int, str)):
            raise ProtocolError("sprite_id must be a string or integer")
    if "modified" in payload and payload["modified"] is not None and not isinstance(payload["modified"], bool):
        raise ProtocolError("modified must be a boolean")


def validate_capabilities(capabilities: Any) -> frozenset[str]:
    if not isinstance(capabilities, list) or any(not isinstance(item, str) for item in capabilities):
        raise ProtocolError("capabilities must be a list of strings")
    supplied = frozenset(capabilities)
    missing = sorted(REQUIRED_CAPABILITIES - supplied)
    if missing:
        raise ProtocolError(f"missing required capabilities: {', '.join(missing)}")
    return supplied


class BridgePathPolicy:
    """Confines all future bridge files to disposable Workbench-owned roots."""

    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root).resolve()
        self.workbench_root = (self.repo_root / ".ai/operator_animation_workbench").resolve()
        self.preview_root = (self.workbench_root / "live").resolve()

    def validate_workbench(self, path: str | Path) -> Path:
        resolved = self._resolve(path)
        self._require_within(resolved, self.workbench_root, "workbench")
        if resolved.suffix.lower() != ".aseprite":
            raise ProtocolError("workbench path must name an .aseprite document")
        return resolved

    def validate_preview(self, path: str | Path) -> Path:
        resolved = self._resolve(path)
        self._require_within(resolved, self.preview_root, "preview output")
        if resolved.suffix.lower() != ".png":
            raise ProtocolError("preview output path must name a PNG")
        return resolved

    def validate_message_paths(self, message: Message) -> None:
        if message.type is MessageType.OPEN_WORKBENCH:
            self.validate_workbench(message.payload["path"])
        elif message.type is MessageType.EXPORT_PREVIEW:
            self.validate_preview(message.payload["output_path"])

    def _resolve(self, path: str | Path) -> Path:
        candidate = Path(path)
        if not candidate.is_absolute():
            candidate = self.repo_root / candidate
        return candidate.resolve()

    @staticmethod
    def _require_within(path: Path, root: Path, label: str) -> None:
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise ProtocolError(f"{label} path is outside {root}") from exc
