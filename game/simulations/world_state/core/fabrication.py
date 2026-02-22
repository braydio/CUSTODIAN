"""Fabrication queue tick helpers."""

from __future__ import annotations

from dataclasses import dataclass
from itertools import count

from .policies import FAB_CATEGORIES


@dataclass
class FabricationTask:
    id: int
    name: str
    ticks_remaining: float
    material_cost: int
    category: str
    inputs: dict[str, int]
    outputs: dict[str, int]


_TASK_IDS = count(1)

RECIPES = {
    "COMPONENTS_BATCH": {
        "name": "COMPONENTS BATCH",
        "category": "REPAIRS",
        "ticks": 6.0,
        "inputs": {"SCRAP": 2},
        "outputs": {"COMPONENTS": 1},
    },
    "DRONE_FRAME": {
        "name": "DRONE FRAME",
        "category": "DRONES",
        "ticks": 8.0,
        "inputs": {"COMPONENTS": 3},
        "outputs": {"ASSEMBLIES": 1},
    },
    "ELECTRONICS_CORE": {
        "name": "ELECTRONICS CORE",
        "category": "DEFENSE",
        "ticks": 10.0,
        "inputs": {"COMPONENTS": 2, "ASSEMBLIES": 1},
        "outputs": {"MODULES": 1},
    },
    "REPAIR_DRONE": {
        "name": "REPAIR DRONE",
        "category": "DRONES",
        "ticks": 12.0,
        "inputs": {"COMPONENTS": 5, "ASSEMBLIES": 2, "MODULES": 1},
        "outputs": {"REPAIR_DRONE": 1},
    },
    "TURRET_AMMO": {
        "name": "TURRET AMMO",
        "category": "DEFENSE",
        "ticks": 7.0,
        "inputs": {"COMPONENTS": 1},
        "outputs": {"TURRET_AMMO": 3},
    },
    "ARCHIVE_PLATING": {
        "name": "ARCHIVE PLATING",
        "category": "ARCHIVE",
        "ticks": 14.0,
        "inputs": {"COMPONENTS": 3, "ASSEMBLIES": 1},
        "outputs": {"ARCHIVE_ARMOR": 1},
    },
}


def tick_fabrication(state) -> list[str]:
    if not state.fabrication_queue:
        return []

    task = state.fabrication_queue[0]
    category = str(task.category).upper()
    allocation_level = int(state.fab_allocation.get(category, 2))
    throughput_mult = 0.5 + (allocation_level * 0.25)
    throughput_mult *= max(0.25, float(getattr(state, "fabrication_throughput_mult", 1.0)))

    # Fortification posture diverts throughput capacity into infrastructure upkeep.
    fort_avg = 0.0
    if state.sector_fort_levels:
        fort_avg = sum(state.sector_fort_levels.values()) / len(state.sector_fort_levels)
    throughput_mult *= max(0.6, 1.0 - (fort_avg * 0.06))

    task.ticks_remaining -= throughput_mult
    if task.ticks_remaining > 0:
        return []

    state.fabrication_queue.pop(0)
    lines = [f"FABRICATION COMPLETE: {task.name}"]
    for output, amount in task.outputs.items():
        if output == "REPAIR_DRONE":
            state.repair_drone_stock += int(amount)
        elif output == "TURRET_AMMO":
            state.turret_ammo_stock += int(amount)
        elif output == "ARCHIVE_ARMOR":
            archive = state.sectors.get("ARCHIVE")
            if archive is not None:
                archive.damage = max(0.0, archive.damage - (0.2 * int(amount)))
        else:
            state.inventory[output] = int(state.inventory.get(output, 0)) + int(amount)
    return lines


def is_valid_fabrication_category(category: str) -> bool:
    return str(category).strip().upper() in FAB_CATEGORIES


def recipe_catalog() -> list[str]:
    return sorted(RECIPES.keys())


def resolve_recipe(token: str) -> dict | None:
    normalized = str(token).strip().upper().replace("-", "_").replace(" ", "_")
    return RECIPES.get(normalized)


def start_fabrication_task(state, recipe_token: str) -> str:
    recipe = resolve_recipe(recipe_token)
    if not recipe:
        return "UNKNOWN FAB ITEM."
    if len(state.fabrication_queue) >= 6:
        return "FAB QUEUE FULL."

    for resource, amount in recipe["inputs"].items():
        if int(state.inventory.get(resource, 0)) < int(amount):
            return f"FAB FAILED: INSUFFICIENT {resource}."

    for resource, amount in recipe["inputs"].items():
        state.inventory[resource] = int(state.inventory.get(resource, 0)) - int(amount)

    state.fabrication_queue.append(
        FabricationTask(
            id=next(_TASK_IDS),
            name=recipe["name"],
            ticks_remaining=float(recipe["ticks"]),
            material_cost=0,
            category=recipe["category"],
            inputs=dict(recipe["inputs"]),
            outputs=dict(recipe["outputs"]),
        )
    )
    return f"FAB QUEUED: {recipe['name']}"


def cancel_fabrication_task(state, task_id: int) -> str:
    for idx, task in enumerate(state.fabrication_queue):
        if int(task.id) != int(task_id):
            continue
        state.fabrication_queue.pop(idx)
        for resource, amount in task.inputs.items():
            refund = int(amount * 0.5 + 0.5)
            state.inventory[resource] = int(state.inventory.get(resource, 0)) + refund
        return f"FAB TASK {task_id} CANCELED."
    return "FAB TASK NOT FOUND."


def set_fabrication_priority(state, category: str) -> str:
    normalized = str(category).strip().upper()
    if not is_valid_fabrication_category(normalized):
        return "FAB CATEGORY MUST BE DEFENSE, DRONES, REPAIRS, OR ARCHIVE."
    for key in FAB_CATEGORIES:
        state.fab_allocation[key] = 1
    state.fab_allocation[normalized] = 4
    return f"FAB PRIORITY SET: {normalized}"
