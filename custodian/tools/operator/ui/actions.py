"""Feature action declarations shared by UI providers."""
from dataclasses import dataclass


@dataclass(frozen=True)
class WorkbenchAction:
    id: str
    label: str
    key: str
    mutating: bool = False


ANIMATION_ACTIONS = (
    WorkbenchAction("edit", "Edit", "e", True),
    WorkbenchAction("add_frame", "Add Frame", "a", True),
    WorkbenchAction("remove_frame", "Remove Frame", "x", True),
    WorkbenchAction("publish", "Publish", "p", True),
    WorkbenchAction("refresh", "Refresh", "r", True),
    WorkbenchAction("weapon", "Weapon", "w"),
    WorkbenchAction("validate", "Validate", "v", True),
)
