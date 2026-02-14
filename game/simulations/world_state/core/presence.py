"""Presence/task helpers for field movement."""

from __future__ import annotations

from .config import (
    FIELD_ACTION_IDLE,
    FIELD_ACTION_MOVING,
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
    state.active_task = None
    if not state.active_repairs:
        state.field_action = FIELD_ACTION_IDLE
    elif state.field_action == FIELD_ACTION_MOVING:
        state.field_action = FIELD_ACTION_IDLE

