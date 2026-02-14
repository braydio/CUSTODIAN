"""Centralized runtime invariants for world-state sessions."""

from __future__ import annotations

from .config import COMMAND_CENTER_LOCATION, FIELD_ACTION_IDLE, FIELD_ACTION_MOVING, FIELD_ACTION_REPAIRING


def validate_state_invariants(state) -> None:
    if state.active_task and len(state.active_repairs) > 0:
        raise AssertionError("Active task and repair cannot run simultaneously.")

    if len(state.active_repairs) > 1:
        raise AssertionError("Phase A supports at most one active repair.")

    if state.active_task and state.field_action != FIELD_ACTION_MOVING:
        raise AssertionError("field_action mismatch for active movement task.")

    if state.active_repairs and state.field_action not in {FIELD_ACTION_REPAIRING, FIELD_ACTION_IDLE}:
        raise AssertionError("field_action mismatch for active repair.")

    if state.in_command_mode() and state.player_location != COMMAND_CENTER_LOCATION:
        raise AssertionError("COMMAND mode must be located at COMMAND.")

