"""Presence/task helpers for field movement."""

from __future__ import annotations

from .config import (
    FIELD_ACTION_IDLE,
    FIELD_ACTION_MOVING,
    FIELD_ACTION_STABILIZING,
    PLAYER_MODE_COMMAND,
)
from .tasks import MoveTask, set_task_ticks, task_target, task_ticks, task_type


def start_move_task(state, destination: str, ticks: int) -> None:
    state.field_action = FIELD_ACTION_MOVING
    state.active_task = MoveTask(target=destination, ticks=ticks, total=ticks)


def tick_presence(state) -> None:
    task = state.active_task
    if not task:
        return

    remaining = task_ticks(task) - 1
    set_task_ticks(task, remaining)
    if remaining > 0:
        return

    if task_type(task) == "MOVE":
        state.player_location = task_target(task)
        if state.player_location == "COMMAND":
            state.player_mode = PLAYER_MODE_COMMAND
    elif task_type(task) == "RELAY":
        from .relays import complete_relay_stabilization

        relay_id = str(getattr(task, "relay_id", "")).upper()
        lines = complete_relay_stabilization(state, relay_id)
        if lines:
            state.last_relay_lines = lines
    state.active_task = None
    if not state.active_repairs:
        state.field_action = FIELD_ACTION_IDLE
    elif state.field_action in {FIELD_ACTION_MOVING, FIELD_ACTION_STABILIZING}:
        state.field_action = FIELD_ACTION_IDLE
