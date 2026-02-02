from collections import defaultdict

from .config import (
    ALERTNESS_DECAY,
    ALERTNESS_FROM_DAMAGE,
    AMBIENT_THREAT_GROWTH,
    SECTORS,
)
from .effects import apply_global_effects, apply_sector_effects
from .factions import build_faction_profile


class SectorState:
    def __init__(self, name):
        self.name = name
        self.damage = 0.0
        self.alertness = 0.0
        self.power = 1.0
        self.last_event = None
        self.occupied = False
        self.effects = {}

    def __str__(self):
        effects = ", ".join(self.effects.keys())
        effect_text = f" FX={effects}" if effects else ""
        return (
            f"{self.name}: "
            f"DMG={self.damage:.2f} "
            f"ALERT={self.alertness:.2f} "
            f"PWR={self.power:.2f}"
            f"{effect_text}"
        )


class GameState:
    def __init__(self):
        self.time = 0
        self.ambient_threat = 0.0
        self.assault_timer = None
        self.in_major_assault = False
        self.player_present = True

        self.assault_count = 0
        self.event_cooldowns = defaultdict(int)
        self.faction_profile = build_faction_profile()
        self.event_catalog = None
        self.global_effects = {}

        self.sectors = {name: SectorState(name) for name in SECTORS}

    def weakest_sectors(self, n=2):
        return sorted(
            self.sectors.values(), key=lambda s: s.damage + s.alertness, reverse=True
        )[:n]

    def __str__(self):
        global_fx = ", ".join(self.global_effects.keys())
        fx_text = f" GlobalFX={global_fx}" if global_fx else ""
        lines = [f"Time={self.time} Threat={self.ambient_threat:.2f}{fx_text}"]
        for sector in self.sectors.values():
            lines.append(str(sector))
        return "\n".join(lines)


def advance_time(state, delta=1):
    state.time += delta
    state.ambient_threat += AMBIENT_THREAT_GROWTH * delta
    apply_global_effects(state)

    for sector in state.sectors.values():
        apply_sector_effects(state, sector)
        # Damage keeps a sector unstable while slowly settling.
        sector.alertness += sector.damage * ALERTNESS_FROM_DAMAGE
        sector.alertness = max(0.0, sector.alertness - ALERTNESS_DECAY)
        sector.occupied = False
