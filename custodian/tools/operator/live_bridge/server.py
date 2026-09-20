"""Loopback-only asynchronous WebSocket server for the live bridge contract."""
from __future__ import annotations

import asyncio
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .protocol import COMMAND_TYPES, BridgePathPolicy, Message, MessageType, ProtocolError, parse_message
from .state import BridgeState

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 32147


class LiveBridgeServer:
    HOST = DEFAULT_HOST

    def __init__(self, repo_root: Path, port: int = DEFAULT_PORT):
        self.repo_root = Path(repo_root).resolve()
        self.port = port
        self.state = BridgeState()
        self.paths = BridgePathPolicy(self.repo_root)
        self._server: Any = None
        self._client: Any = None
        self._server_sequence = 0
        self._message_listeners: set[Callable[[Message], None]] = set()
        self._command_waiters: dict[int, asyncio.Future[Message]] = {}

    def add_message_listener(self, listener: Callable[[Message], None]) -> None:
        self._message_listeners.add(listener)

    def remove_message_listener(self, listener: Callable[[Message], None]) -> None:
        self._message_listeners.discard(listener)

    def _notify_message(self, message: Message) -> None:
        for listener in tuple(self._message_listeners):
            try:
                listener(message)
            except Exception:
                continue

    @property
    def listening_port(self) -> int | None:
        if self._server is None or not self._server.sockets:
            return None
        return self._server.sockets[0].getsockname()[1]

    async def start(self) -> None:
        if self._server is not None:
            return
        try:
            from websockets.asyncio.server import serve
        except ImportError as exc:
            raise RuntimeError(
                "Live Bridge requires the optional Operator UI dependencies; "
                "install custodian/tools/operator/ui/requirements.txt"
            ) from exc
        self._server = await serve(
            self._handle_client, self.HOST, self.port,
            close_timeout=1.0,
        )

    async def stop(self) -> None:
        self._fail_command_waiters(ConnectionError("Aseprite client disconnected"))
        client, self._client = self._client, None
        if client is not None:
            await client.close(code=1001, reason="bridge shutdown")
        if self._server is not None:
            self._server.close()
            await self._server.wait_closed()
            self._server = None
        self.state.disconnect()

    async def __aenter__(self) -> "LiveBridgeServer":
        await self.start()
        return self

    async def __aexit__(self, *_args: object) -> None:
        await self.stop()

    def _command_message(self, message_type: MessageType, payload: dict[str, Any]) -> Message:
        if message_type not in COMMAND_TYPES:
            raise ProtocolError(f"not a command type: {message_type.value}")
        if self._client is None:
            raise ConnectionError("Aseprite client is not connected")
        sequence = self._next_sequence()
        message = Message(self.state.bridge_session_id, sequence, message_type, payload)
        message = parse_message(message.to_dict())
        self.paths.validate_message_paths(message)
        return message

    async def send_command(self, message_type: MessageType, payload: dict[str, Any]) -> int:
        message = self._command_message(message_type, payload)
        self.state.track_command(message.sequence)
        await self._client.send(message.to_json())
        return message.sequence

    async def request_command(self, message_type: MessageType, payload: dict[str, Any], *, timeout: float = 10.0) -> Message:
        message = self._command_message(message_type, payload)
        loop = asyncio.get_running_loop()
        waiter = loop.create_future()
        self._command_waiters[message.sequence] = waiter
        self.state.track_command(message.sequence)
        try:
            await self._client.send(message.to_json())
            return await asyncio.wait_for(waiter, timeout=timeout)
        finally:
            self._command_waiters.pop(message.sequence, None)

    def _fail_command_waiters(self, error: Exception) -> None:
        for waiter in tuple(self._command_waiters.values()):
            if not waiter.done(): waiter.set_exception(error)
        self._command_waiters.clear()

    async def _handle_client(self, websocket: Any) -> None:
        if self._client is not None:
            await websocket.close(code=1013, reason="bridge already has a client")
            return
        accepted = False
        try:
            raw = await asyncio.wait_for(websocket.recv(), timeout=5.0)
            hello = parse_message(raw)
            if hello.type is not MessageType.CLIENT_HELLO:
                raise ProtocolError("first message must be client.hello")
            self.state.connect(hello)
            self._notify_message(hello)
            self._client = websocket
            accepted = True
            response = Message(
                self.state.bridge_session_id, self._next_sequence(), MessageType.SERVER_HELLO,
                {"accepted": True, "schema": hello.schema}, cause=hello.sequence,
            )
            await websocket.send(response.to_json())
            async for raw in websocket:
                message = parse_message(raw)
                if message.session_id != self.state.client_session_id:
                    raise ProtocolError("message session_id does not match active client session")
                self.state.apply(message)
                if message.type is MessageType.COMMAND_RESULT and message.cause is not None:
                    waiter = self._command_waiters.get(message.cause)
                    if waiter is not None and not waiter.done(): waiter.set_result(message)
                self._notify_message(message)
        except (ProtocolError, ValueError, asyncio.TimeoutError) as exc:
            await websocket.close(code=1008, reason=str(exc)[:120])
        finally:
            if accepted and self._client is websocket:
                self._client = None
                self.state.disconnect()
                self._fail_command_waiters(ConnectionError("Aseprite client disconnected"))

    def _next_sequence(self) -> int:
        self._server_sequence += 1
        return self._server_sequence
