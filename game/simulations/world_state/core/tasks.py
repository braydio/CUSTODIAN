"""Task dataclasses and task compatibility helpers."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class MoveTask:
    target: str
    ticks: int
    total: int
    type: str = "MOVE"


@dataclass
class RepairTask:
    structure_id: str
    ticks_remaining: int


def task_type(task: Any) -> str:
    if task is None:
        return "UNKNOWN"
    if isinstance(task, dict):
        return str(task.get("type", "UNKNOWN"))
    return str(getattr(task, "type", "UNKNOWN"))


def task_target(task: Any) -> str:
    if task is None:
        return ""
    if isinstance(task, dict):
        return str(task.get("target", ""))
    return str(getattr(task, "target", ""))


def task_ticks(task: Any) -> int:
    if task is None:
        return 0
    if isinstance(task, dict):
        return int(task.get("ticks", 0))
    return int(getattr(task, "ticks", 0))


def task_total(task: Any) -> int:
    if task is None:
        return 0
    if isinstance(task, dict):
        return int(task.get("total", task.get("ticks", 0)))
    return int(getattr(task, "total", getattr(task, "ticks", 0)))


def set_task_ticks(task: Any, value: int) -> None:
    if isinstance(task, dict):
        task["ticks"] = value
        return
    setattr(task, "ticks", value)


def task_to_dict(task: Any) -> dict[str, Any] | None:
    if task is None:
        return None
    if isinstance(task, dict):
        return dict(task)
    return {
        "type": task_type(task),
        "target": task_target(task),
        "ticks": task_ticks(task),
        "total": task_total(task),
    }
