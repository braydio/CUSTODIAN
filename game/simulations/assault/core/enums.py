from enum import Enum


class EnemyType(Enum):
    ZEALOT = "zealot"
    ICONOCLAST = "iconoclast"
    RAIDER = "raider"


class DamageType(Enum):
    BLUNT = "blunt"
    BALLISTIC = "ballistic"


class SectorType(Enum):
    COMMAND = "command"
    GOAL = "goal"
    PERIPHERAL = "peripheral"
