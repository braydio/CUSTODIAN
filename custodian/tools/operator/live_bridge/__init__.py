"""Local, presentation-only bridge foundation for Operator authoring tools."""

from .protocol import MESSAGE_SCHEMA, Message, MessageType, ProtocolError
from .server import LiveBridgeServer
from .state import BridgeState, ConnectionState

__all__ = [
    "MESSAGE_SCHEMA",
    "BridgeState",
    "ConnectionState",
    "LiveBridgeServer",
    "Message",
    "MessageType",
    "ProtocolError",
]
