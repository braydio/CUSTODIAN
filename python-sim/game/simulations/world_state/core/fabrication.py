"""Fabrication queue tick helpers."""

from __future__ import annotations

from dataclasses import dataclass
from itertools import count

from .config import (
    AMBIENT_FAB_BASE_UNITS_PER_TICK,
    AMBIENT_FAB_POWER_LOAD_PENALTY,
    AMBIENT_FAB_POWER_LOAD_SOFTCAP,
    AMBIENT_FAB_SUPPLY_PRESSURE_PENALTY,
)
from .policies import FAB_CATEGORIES
from .power import power_efficiency, structure_effective_output


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

AMBIENT_FAB_RULES = {
    "DEFENSE": {
        "cycle": 5.0,
        "inputs": {"COMPONENTS": 1},
        "outputs": {"TURRET_AMMO": 1},
        "line": "AMBIENT FAB: DEFENSE SUPPLY +1 TURRET_AMMO",
    },
    "DRONES": {
        "cycle": 8.0,
        "inputs": {"COMPONENTS": 2, "ASSEMBLIES": 1, "MODULES": 1},
        "outputs": {"REPAIR_DRONE": 1},
        "line": "AMBIENT FAB: SUPPORT FRAME +1 REPAIR_DRONE",
    },
    "REPAIRS": {
        "cycle": 3.0,
        "inputs": {"SCRAP": 2},
        "outputs": {"COMPONENTS": 1},
        "line": "AMBIENT FAB: MATERIALS +1 COMPONENTS",
    },
    "ARCHIVE": {
        "cycle": 4.5,
        "inputs": {"COMPONENTS": 2, "ASSEMBLIES": 1},
        "outputs": {"MODULES": 1},
        "line": "AMBIENT FAB: ARCHIVE STOCK +1 MODULES",
    },
}


def _apply_outputs(state, outputs: dict[str, int]) -> None:
    for output, amount in outputs.items():
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


def _has_inputs(state, inputs: dict[str, int]) -> bool:
    for resource, amount in inputs.items():
        if int(state.inventory.get(resource, 0)) < int(amount):
            return False
    return True


def _consume_inputs(state, inputs: dict[str, int]) -> None:
    for resource, amount in inputs.items():
        state.inventory[resource] = int(state.inventory.get(resource, 0)) - int(amount)


def ambient_fabrication_projection(state) -> dict[str, float]:
    fab_sector = state.sectors.get("FABRICATION")
    if fab_sector is None:
        return {"rate": 0.0, "power_factor": 0.0, "supply_factor": 0.0}

    core = state.structures.get("FB_CORE")
    tools = state.structures.get("FB_TOOLS")
    core_output = structure_effective_output(state, core) if core else 1.0
    tools_output = structure_effective_output(state, tools) if tools else 1.0
    local_power = power_efficiency(fab_sector.power)
    logistics_factor = max(0.25, float(getattr(state, "fabrication_throughput_mult", 1.0)))

    pressure = max(0.0, float(getattr(state, "logistics_pressure", 0.0)))
    supply_factor = max(0.2, 1.0 - (pressure * AMBIENT_FAB_SUPPLY_PRESSURE_PENALTY))

    overload = max(
        0.0,
        float(getattr(state, "power_load", 1.0)) - AMBIENT_FAB_POWER_LOAD_SOFTCAP,
    )
    power_load_factor = max(0.25, 1.0 - (overload * AMBIENT_FAB_POWER_LOAD_PENALTY))

    rate = AMBIENT_FAB_BASE_UNITS_PER_TICK
    rate *= core_output
    rate *= tools_output
    rate *= local_power
    rate *= logistics_factor
    rate *= supply_factor
    rate *= power_load_factor
    if rate < 0.01:
        rate = 0.0

    return {
        "rate": float(rate),
        "power_factor": float(local_power * power_load_factor),
        "supply_factor": float(logistics_factor * supply_factor),
    }


def _tick_ambient_fabrication(state) -> list[str]:
    if not hasattr(state, "ambient_fab_progress") or not isinstance(state.ambient_fab_progress, dict):
        state.ambient_fab_progress = {name: 0.0 for name in FAB_CATEGORIES}

    projection = ambient_fabrication_projection(state)
    state.ambient_fab_effective_rate = round(float(projection["rate"]), 3)
    state.ambient_fab_power_factor = round(float(projection["power_factor"]), 3)
    state.ambient_fab_supply_factor = round(float(projection["supply_factor"]), 3)

    if state.ambient_fab_effective_rate <= 0.0:
        return []

    total_allocation = sum(max(0, int(state.fab_allocation.get(name, 0))) for name in FAB_CATEGORIES)
    if total_allocation <= 0:
        return []

    for category in FAB_CATEGORIES:
        share = max(0, int(state.fab_allocation.get(category, 0))) / total_allocation
        state.ambient_fab_progress[category] = float(state.ambient_fab_progress.get(category, 0.0))
        state.ambient_fab_progress[category] += state.ambient_fab_effective_rate * share
        cycle = float(AMBIENT_FAB_RULES[category]["cycle"])
        state.ambient_fab_progress[category] = min(state.ambient_fab_progress[category], cycle * 1.5)

    lines: list[str] = []
    while len(lines) < 3:
        crafted = False
        ordered = sorted(
            FAB_CATEGORIES,
            key=lambda name: float(state.ambient_fab_progress.get(name, 0.0)),
            reverse=True,
        )
        for category in ordered:
            rule = AMBIENT_FAB_RULES[category]
            cycle = float(rule["cycle"])
            if float(state.ambient_fab_progress.get(category, 0.0)) < cycle:
                continue
            if not _has_inputs(state, rule["inputs"]):
                continue
            _consume_inputs(state, rule["inputs"])
            _apply_outputs(state, rule["outputs"])
            state.ambient_fab_progress[category] -= cycle
            lines.append(str(rule["line"]))
            crafted = True
            if len(lines) >= 3:
                break
        if not crafted:
            break

    return lines


def tick_fabrication(state) -> list[str]:
    lines = _tick_ambient_fabrication(state)
    if not state.fabrication_queue:
        return lines

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
        return lines

    state.fabrication_queue.pop(0)
    lines.append(f"FABRICATION COMPLETE: {task.name}")
    _apply_outputs(state, task.outputs)
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
    if str(recipe.get("name", "")).upper() == "ARCHIVE PLATING":
        if int(state.relay_benefits.get("fab_blueprints_archive", 0)) <= 0:
            return "FAB LOCKED: KNOWLEDGE TIER 4 REQUIRED."
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
