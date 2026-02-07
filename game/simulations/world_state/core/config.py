SECTOR_DEFS = [
    {"id": "CM", "name": "COMMS"},
    {"id": "DF", "name": "DEFENSE GRID"},
    {"id": "CC", "name": "COMMAND"},
    {"id": "PW", "name": "POWER"},
    {"id": "AR", "name": "ARCHIVE"},
    {"id": "ST", "name": "STORAGE"},
    {"id": "HG", "name": "HANGAR"},
    {"id": "GS", "name": "GATEWAY"},
]

SECTORS = [sector["name"] for sector in SECTOR_DEFS]

CRITICAL_SECTORS = {"COMMAND", "ARCHIVE"}

SECTOR_TAGS = {
    "COMMAND": {"command", "critical", "authority", "control"},
    "COMMS": {"comms", "info", "sensor"},
    "DEFENSE GRID": {"defense", "mitigation", "perimeter"},
    "POWER": {"power", "amplifier", "hazard"},
    "ARCHIVE": {"archive", "goal", "knowledge", "critical"},
    "STORAGE": {"storage", "buffer", "infrastructure"},
    "HANGAR": {"hangar", "egress", "approach"},
    "GATEWAY": {"gateway", "ingress", "approach"},
}

# Tuning knobs (keep simple so designers can tweak without code changes elsewhere)
AMBIENT_THREAT_GROWTH = 0.015
ALERTNESS_DECAY = 0.01
ALERTNESS_FROM_DAMAGE = 0.01

EVENT_CHANCE_BASE = 0.03
EVENT_CHANCE_PER_THREAT = 0.012
EVENT_CHANCE_MAX = 0.4
CHAIN_CHANCE = 0.5

ASSAULT_TIMER_BASE_MIN = 45
ASSAULT_TIMER_BASE_MAX = 70
ASSAULT_TIMER_MIN = 12
ASSAULT_TIMER_WEAK_DAMAGE_MULT = 5

ASSAULT_DURATION_MIN = 15
ASSAULT_DURATION_MAX = 30
ASSAULT_DAMAGE_PER_TICK = 0.2
ASSAULT_ALERTNESS_PER_TICK = 0.3
ASSAULT_THREAT_PER_TICK = 0.1

# Phase 1.5 asymmetric modifiers (keep subtle)
POWER_THREAT_MULT = 1.2
DEFENSE_ASSAULT_DAMAGE_MULT = 1.25
HANGAR_EVENT_CHANCE_BONUS = 0.05
GATEWAY_ASSAULT_TIMER_ACCEL = 1
STORAGE_DECAY_MULT = 0.5

# Terminal loss-state threshold.
COMMAND_CENTER_BREACH_DAMAGE = 2.0
