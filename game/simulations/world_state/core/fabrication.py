"""Fabrication queue tick helpers."""

from __future__ import annotations

from dataclasses import dataclass

from .policies import FAB_CATEGORIES


@dataclass
class FabricationTask:
    name: str
    ticks_remaining: float
    material_cost: int
    category: str


def tick_fabrication(state) -> list[str]:
    if not state.fabrication_queue:
        return []

    task = state.fabrication_queue[0]
    category = str(task.category).upper()
    allocation_level = int(state.fab_allocation.get(category, 2))
    throughput_mult = 0.5 + (allocation_level * 0.25)

    # Fortification posture diverts throughput capacity into infrastructure upkeep.
    fort_avg = 0.0
    if state.sector_fort_levels:
        fort_avg = sum(state.sector_fort_levels.values()) / len(state.sector_fort_levels)
    throughput_mult *= max(0.6, 1.0 - (fort_avg * 0.06))

    task.ticks_remaining -= throughput_mult
    if task.ticks_remaining > 0:
        return []

    state.fabrication_queue.pop(0)
    return [f"FABRICATION COMPLETE: {task.name}"]


def is_valid_fabrication_category(category: str) -> bool:
    return str(category).strip().upper() in FAB_CATEGORIES

