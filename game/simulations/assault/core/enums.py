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


class DefenseDoctrine(Enum):
    BALANCED = "BALANCED"
    AGGRESSIVE = "AGGRESSIVE"
    COMMAND_FIRST = "COMMAND_FIRST"
    INFRASTRUCTURE_FIRST = "INFRASTRUCTURE_FIRST"
    SENSOR_PRIORITY = "SENSOR_PRIORITY"
