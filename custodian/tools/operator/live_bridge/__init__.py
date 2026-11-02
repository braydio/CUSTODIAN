"""Local, presentation-only bridge foundation for Operator authoring tools."""

from .protocol import MESSAGE_SCHEMA, Message, MessageType, ProtocolError
from .server import DEFAULT_HOST, DEFAULT_PORT, LiveBridgeServer
from .state import BridgeState, ConnectionState

__all__ = [
    "MESSAGE_SCHEMA",
    "BridgeState",
    "ConnectionState",
    "DEFAULT_HOST",
    "DEFAULT_PORT",
    "LiveBridgeServer",
    "Message",
    "MessageType",
    "ProtocolError",
]
