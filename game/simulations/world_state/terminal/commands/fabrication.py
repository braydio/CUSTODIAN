"""FAB command handlers."""

from __future__ import annotations

from game.simulations.world_state.core.fabrication import (
    cancel_fabrication_task,
    recipe_catalog,
    set_fabrication_priority,
    start_fabrication_task,
)
from game.simulations.world_state.core.state import GameState


def cmd_fab_add(state: GameState, item_name: str) -> list[str]:
    result = start_fabrication_task(state, item_name)
    if result == "UNKNOWN FAB ITEM.":
        recipes = ", ".join(recipe_catalog())
        return [result, f"KNOWN: {recipes}"]
    return [result]


def cmd_fab_queue(state: GameState) -> list[str]:
    if not state.fabrication_queue:
        return ["FAB QUEUE EMPTY."]

    lines = ["FAB QUEUE:"]
    for task in state.fabrication_queue:
        lines.append(f"{task.id}. {task.name} ({max(0, int(task.ticks_remaining))} ticks remaining)")
    return lines


def cmd_fab_cancel(state: GameState, task_id: str) -> list[str]:
    if not task_id.strip().isdigit():
        return ["FAB CANCEL <ID> REQUIRED."]
    return [cancel_fabrication_task(state, int(task_id))]


def cmd_fab_priority(state: GameState, category: str) -> list[str]:
    return [set_fabrication_priority(state, category)]

