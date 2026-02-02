SECTORS = [
    "Command Center",
    "Goal Sector",
    "Main Terminal",
    "Security Gate / Checkpoint",
    "Hangar A",
    "Hangar B",
    "Fuel Depot",
    "Radar / Control Tower",
    "Service Tunnels",
    "Maintenance Yard",
]

CRITICAL_SECTORS = {"Command Center", "Goal Sector"}

SECTOR_TAGS = {
    "Command Center": {"command", "critical", "control", "data"},
    "Goal Sector": {"goal", "critical", "construction"},
    "Main Terminal": {"terminal", "data", "infrastructure"},
    "Security Gate / Checkpoint": {"gate", "approach", "perimeter"},
    "Hangar A": {"hangar", "approach", "open"},
    "Hangar B": {"hangar", "collapsed", "ambush"},
    "Fuel Depot": {"fuel", "hazard", "power"},
    "Radar / Control Tower": {"radar", "sensor", "tower"},
    "Service Tunnels": {"tunnels", "service", "infrastructure"},
    "Maintenance Yard": {"maintenance", "yard", "scrap"},
}

# Tuning knobs (keep simple so designers can tweak without code changes elsewhere)
AMBIENT_THREAT_GROWTH = 0.015
ALERTNESS_DECAY = 0.01
ALERTNESS_FROM_DAMAGE = 0.01

EVENT_CHANCE_BASE = 0.04
EVENT_CHANCE_PER_THREAT = 0.015
EVENT_CHANCE_MAX = 0.5
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
