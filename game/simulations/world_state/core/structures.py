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
