from enum import Enum


class StructureState(Enum):
    OPERATIONAL = "OPERATIONAL"
    DAMAGED = "DAMAGED"
    OFFLINE = "OFFLINE"
    DESTROYED = "DESTROYED"


class Structure:
    def __init__(
        self,
        id: str,
        name: str,
        sector: str,
        *,
        min_power: float = 0.4,
        standard_power: float = 1.0,
    ):
        self.id = id
        self.name = name
        self.sector = sector
        self.min_power = min_power
        self.standard_power = standard_power
        self.state = StructureState.OPERATIONAL

    def degrade(self) -> None:
        if self.state == StructureState.OPERATIONAL:
            self.state = StructureState.DAMAGED
        elif self.state == StructureState.DAMAGED:
            self.state = StructureState.OFFLINE
        elif self.state == StructureState.OFFLINE:
            self.state = StructureState.DESTROYED

    def can_autorepair(self) -> bool:
        return self.state in {
            StructureState.OPERATIONAL,
            StructureState.DAMAGED,
        }


STRUCTURE_TYPES = {
    "WALL": {
        "cost": 5,
        "max_hp": 150,
        "blocks": True,
        "power": 0,
        "logistics": 0,
    },
    "TURRET": {
        "cost": 20,
        "max_hp": 100,
        "blocks": True,
        "power": 5,
        "logistics": 1,
    },
    "GENERATOR": {
        "cost": 30,
        "max_hp": 120,
        "blocks": True,
        "power": -10,
        "logistics": 1,
    },
}


def generate_perimeter_positions(level: int, width: int, height: int) -> set[tuple[int, int]]:
    """Return deterministic perimeter wall coordinates for fortification levels."""

    if width <= 0 or height <= 0:
        return set()

    clamped = max(0, min(4, int(level)))
    positions: set[tuple[int, int]] = set()

    def add_if_valid(x: int, y: int) -> None:
        if 0 <= x < width and 0 <= y < height:
            positions.add((x, y))

    if clamped >= 1:
        for x in range(width):
            add_if_valid(x, 0)
            add_if_valid(x, height - 1)
        for y in range(height):
            add_if_valid(0, y)
            add_if_valid(width - 1, y)

    if clamped >= 2:
        for x in range(width):
            add_if_valid(x, 1)
            add_if_valid(x, height - 2)
        for y in range(height):
            add_if_valid(1, y)
            add_if_valid(width - 2, y)

    if clamped >= 3:
        # Interior 2x2 blocks mirrored at all four corners.
        for x in (1, 2):
            for y in (height - 2, height - 3):
                add_if_valid(x, y)
                add_if_valid(width - 1 - x, y)
                add_if_valid(x, height - 1 - y)
                add_if_valid(width - 1 - x, height - 1 - y)

    if clamped >= 4:
        mid_x = width // 2
        mid_y = height // 2
        for y in range(2, max(2, height - 2)):
            add_if_valid(mid_x, y)
        for x in range(2, max(2, width - 2)):
            add_if_valid(x, mid_y)

    return positions


def create_fabrication_structures() -> list[Structure]:
    return [
        Structure(
            id="FB_CORE",
            name="FABRICATION CORE",
            sector="FABRICATION",
        ),
        Structure(
            id="FB_TOOLS",
            name="ASSEMBLY TOOLS",
            sector="FABRICATION",
        ),
    ]
