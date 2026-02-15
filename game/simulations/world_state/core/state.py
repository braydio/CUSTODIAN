from collections import defaultdict
from typing import Any
import math
import random

from .config import (
    ALERTNESS_DECAY,
    ALERTNESS_FROM_DAMAGE,
    AMBIENT_THREAT_GROWTH,
    ARCHIVE_LOSS_LIMIT,
    COMMAND_CENTER_LOCATION,
    COMMAND_CENTER_BREACH_DAMAGE,
    FIELD_ACTION_IDLE,
    PLAYER_MODE_COMMAND,
    POWER_THREAT_MULT,
    STORAGE_DECAY_MULT,
    SECTOR_DEFS,
    SECTORS,
)
from .structures import Structure, StructureState, create_fabrication_structures
from .effects import apply_global_effects, apply_sector_effects
from .factions import build_faction_profile
from .snapshot_migration import migrate_snapshot
from .tasks import task_to_dict


class SectorState:
    def __init__(self, sector_id: str, name: str):
        self.id = sector_id
        self.name = name
        self.damage = 0.0
        self.alertness = 0.0
        self.power = 1.0
        self.last_event = None
        self.occupied = False
        self.effects = {}

    def status_label(self) -> str:
        """Map sector metrics to one-word status label."""

        if self.damage >= 2.0:
            return "COMPROMISED"
        if self.damage >= 1.0 or self.alertness >= 2.0:
            return "DAMAGED"
        if self.alertness >= 0.8 or self.occupied:
            return "ALERT"
        return "STABLE"

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

    def __init__(self, seed: int | None = None):
        """Initialize the world-state simulation state."""

        self.seed = seed if seed is not None else random.randrange(0, 2**32)
        self.rng = random.Random(self.seed)
        self.time = 0
        self.ambient_threat = 0.0
        self.assault_timer = None
        self.in_major_assault = False
        self.is_failed = False
        self.failure_reason = None
        self.last_assault_lines = []
        self.last_repair_lines: list[str] = []
        self.materials = 3
        self.operator_log: list[str] = []
        self._last_sector_status: dict[str, str] = {}

        # Player state
        self.player_mode = PLAYER_MODE_COMMAND
        self.player_location = COMMAND_CENTER_LOCATION
        self.field_action = FIELD_ACTION_IDLE
        self.active_task: Any | None = None
        self.fidelity = "FULL"
        self.last_fidelity_lines: list[str] = []
        self.current_assault = None
        self.field_assault_warning_pending = 0
        self.dev_mode = False
        self.dev_trace = False
        self.focused_sector = None
        self.hardened = False
        self.archive_losses = 0

        # World progression
        self.assault_count = 0
        self.event_cooldowns = defaultdict(int)
        self.faction_profile = build_faction_profile(self.rng)
        self.event_catalog = None
        self.global_effects = {}

        # Sector states
        self.sectors = {
            sector["name"]: SectorState(sector["id"], sector["name"])
            for sector in SECTOR_DEFS
        }
        self.structures: dict[str, Structure] = {}
        self.active_repairs: dict[str, dict] = {}
        for sector in SECTOR_DEFS:
            structure_id = f"{sector['id']}_CORE"
            self.structures[structure_id] = Structure(
                structure_id,
                f"{sector['name']} CORE",
                sector["name"],
            )
        for structure in create_fabrication_structures():
            self.structures[structure.id] = structure

    def threat_bucket(self) -> str:
        """Map ambient threat to a Phase 1 bucket."""

        if self.ambient_threat < 1.5:
            return "LOW"
        if self.ambient_threat < 3.0:
            return "ELEVATED"
        if self.ambient_threat < 5.0:
            return "HIGH"
        return "CRITICAL"

    def assault_state(self) -> str:
        """Return current assault phase label."""

        if self.in_major_assault or self.current_assault is not None:
            return "ACTIVE"
        if self.assault_timer is not None:
            return "PENDING"
        return "NONE"

    def snapshot(self) -> dict:
        """Return a read-only snapshot for STATUS and UI projections."""

        sectors = []
        for name in SECTORS:
            sector = self.sectors[name]
            sector_id = sector.id
            sector_structures = [
                s for s in self.structures.values() if s.sector == sector.name
            ]
            damaged = any(
                s.state != StructureState.OPERATIONAL for s in sector_structures
            )
            status = sector.status_label()
            if sector_structures and damaged:
                status = "DAMAGED"
            sectors.append(
                {
                    "id": sector_id,
                    "name": sector.name,
                    "status": status,
                }
            )

        return {
            "snapshot_version": 2,
            "time": self.time,
            "threat": self.threat_bucket(),
            "assault": self.assault_state(),
            "sectors": sectors,
            "failed": self.is_failed,
            "focused_sector": self.focused_sector,
            "hardened": self.hardened,
            "archive_losses": self.archive_losses,
            "archive_limit": ARCHIVE_LOSS_LIMIT,
            "resources": {"materials": self.materials},
            "active_repairs": [
                {
                    "id": sid,
                    "remaining": max(0, int(math.ceil(job["remaining"]))),
                    "total": int(math.ceil(job["total"])),
                    "cost": job["cost"],
                }
                for sid, job in self.active_repairs.items()
            ],
            "player_mode": self.player_mode,
            "player_location": self.player_location,
            "field_action": self.field_action,
            "active_task": task_to_dict(self.active_task),
            "seed": self.seed,
            "operator_log": list(self.operator_log[-50:]),
        }

    @property
    def in_command_center(self) -> bool:
        """Return True when the operator is in the COMMAND sector."""
        return self.player_mode == PLAYER_MODE_COMMAND

    def in_command_mode(self) -> bool:
        return self.player_mode == PLAYER_MODE_COMMAND

    def in_field_mode(self) -> bool:
        return not self.in_command_mode()

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

    @classmethod
    def from_snapshot(cls, snapshot: dict) -> "GameState":
        migrated = migrate_snapshot(snapshot)
        state = cls(seed=migrated.get("seed"))
        state.time = int(migrated.get("time", 0))
        state.player_mode = migrated.get("player_mode", state.player_mode)
        state.player_location = migrated.get("player_location", state.player_location)
        state.field_action = migrated.get("field_action", state.field_action)
        return state


def check_failure(state: GameState) -> bool:
    """Mark the simulation as failed when COMMAND breach criteria are met.

    Args:
        state: Mutable simulation state to inspect.

    Returns:
        True when this call transitions the state into failure mode.
    """

    if state.is_failed:
        return False

    command_center = state.sectors["COMMAND"]
    if command_center.damage < COMMAND_CENTER_BREACH_DAMAGE:
        if state.archive_losses < ARCHIVE_LOSS_LIMIT:
            return False

    state.is_failed = True
    if command_center.damage >= COMMAND_CENTER_BREACH_DAMAGE:
        state.failure_reason = "COMMAND CENTER LOST"
    else:
        state.failure_reason = "ARCHIVAL INTEGRITY LOST"
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
    threat_growth = AMBIENT_THREAT_GROWTH * delta
    power_sector = state.sectors.get("POWER")
    if power_sector and power_sector.damage >= 1.0:
        threat_growth *= POWER_THREAT_MULT
    state.ambient_threat += threat_growth
    apply_global_effects(state)

    storage_sector = state.sectors.get("STORAGE")
    storage_damaged = bool(storage_sector and storage_sector.damage >= 1.0)

    for sector in state.sectors.values():
        apply_sector_effects(state, sector)
        # Damage keeps a sector unstable while slowly settling.
        sector.alertness += sector.damage * ALERTNESS_FROM_DAMAGE
        if storage_damaged and sector.name != "STORAGE":
            sector.alertness += sector.damage * ALERTNESS_FROM_DAMAGE * STORAGE_DECAY_MULT
        sector.alertness = max(0.0, sector.alertness - ALERTNESS_DECAY)
        sector.occupied = False
