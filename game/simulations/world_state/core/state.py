from collections import defaultdict

from .config import (
    ALERTNESS_DECAY,
    ALERTNESS_FROM_DAMAGE,
    AMBIENT_THREAT_GROWTH,
    COMMAND_CENTER_BREACH_DAMAGE,
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
    """Shared world-state container for the simulation."""

    def __init__(self):
        """Initialize the world-state simulation state."""

        self.time = 0
        self.ambient_threat = 0.0
        self.assault_timer = None
        self.in_major_assault = False
        self.is_failed = False
        self.failure_reason = None

        # Player state
        self.player_location = "Command Center"
        self.current_assault = None

        # World progression
        self.assault_count = 0
        self.event_cooldowns = defaultdict(int)
        self.faction_profile = build_faction_profile()
        self.event_catalog = None
        self.global_effects = {}

        # Sector states
        self.sectors = {name: SectorState(name) for name in SECTORS}

    @property
    def in_command_center(self) -> bool:
        """Return True when the operator is in the Command Center."""
        return self.player_location == "Command Center"

    def weakest_sectors(self, n=2):
        return sorted(
            self.sectors.values(),
            key=lambda s: s.damage + s.alertness,
            reverse=True,
        )[:n]

    def __str__(self):
        global_fx = ", ".join(self.global_effects.keys())
        fx_text = f" GlobalFX={global_fx}" if global_fx else ""
        lines = [
            f"Time={self.time} Threat={self.ambient_threat:.2f}{fx_text}",
            f"Location={self.player_location}",
        ]
        for sector in self.sectors.values():
            lines.append(str(sector))
        return "\n".join(lines)


def check_failure(state: GameState) -> bool:
    """Mark the simulation as failed when Command Center breach criteria are met.

    Args:
        state: Mutable simulation state to inspect.

    Returns:
        True when this call transitions the state into failure mode.
    """

    if state.is_failed:
        return False

    command_center = state.sectors["Command Center"]
    if command_center.damage < COMMAND_CENTER_BREACH_DAMAGE:
        return False

    state.is_failed = True
    state.failure_reason = "COMMAND CENTER BREACHED."
    return True


def reset_game_state(state: GameState) -> None:
    """Reset a mutable game state instance to a fresh session baseline.

    Args:
        state: Existing state instance to reset in place.
    """

    fresh_state = GameState()
    state.__dict__.clear()
    state.__dict__.update(fresh_state.__dict__)


def advance_time(state: GameState, delta: int = 1) -> None:
    """Advance global and sector clocks by the given tick count."""

    state.time += delta
    state.ambient_threat += AMBIENT_THREAT_GROWTH * delta
    apply_global_effects(state)

    for sector in state.sectors.values():
        apply_sector_effects(state, sector)
        # Damage keeps a sector unstable while slowly settling.
        sector.alertness += sector.damage * ALERTNESS_FROM_DAMAGE
        sector.alertness = max(0.0, sector.alertness - ALERTNESS_DECAY)
        sector.occupied = False
