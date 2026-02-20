from collections import defaultdict
from typing import Any
import math
import random

from .config import (
    ALERTNESS_DECAY,
    ALERTNESS_FROM_DAMAGE,
    AMBIENT_THREAT_GROWTH,
    AMBIENT_THREAT_REPAIR_RECOVERY,
    AMBIENT_THREAT_STABILITY_RECOVERY,
    ARCHIVE_LOSS_LIMIT,
    COMMAND_CENTER_LOCATION,
    COMMAND_CENTER_BREACH_DAMAGE,
    COMMAND_BREACH_RECOVERY_TICKS,
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
from .defense import DEFAULT_DEFENSE_ALLOCATION, compute_readiness, normalize_doctrine
from .assault_ledger import AssaultLedger, AssaultTickRecord, append_record
from .policies import PolicyState, default_fabrication_allocation


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
        self.assaults: list[Any] = []
        self.command_breach_recovery_ticks: int | None = None
        self.is_failed = False
        self.failure_reason = None
        self.assault_ledger = AssaultLedger()
        self.assault_trace_enabled = False
        self.last_assault_lines = []
        self.last_structure_loss_lines: list[str] = []
        self.last_repair_lines: list[str] = []
        self.last_fabrication_lines: list[str] = []
        self.last_after_action_lines: list[str] = []
        self.materials = 3
        self.inventory = {
            "SCRAP": 12,
            "COMPONENTS": 0,
            "ASSEMBLIES": 0,
            "MODULES": 0,
        }
        self.repair_drone_stock = 0
        self.turret_ammo_stock = 6
        self.operator_log: list[str] = []
        self._last_sector_status: dict[str, str] = {}
        self.pending_structure_losses: set[str] = set()
        self.detected_structure_losses: set[str] = set()
        self.sector_recovery_windows: dict[str, dict[str, float]] = {}
        self.policies = PolicyState()
        self.fab_allocation = default_fabrication_allocation()
        self.fabrication_queue: list[Any] = []
        self.sector_fort_levels = {name: 0 for name in SECTORS}
        self.power_load = 1.0

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
        self.autonomy_override_enabled = True
        self.autonomy_strength_bonus = 0.0
        self.assault_tactical_effects: dict[str, dict[str, int]] = {}
        self.defense_doctrine = "BALANCED"
        self.doctrine_last_changed_time = 0
        self.defense_allocation = dict(DEFAULT_DEFENSE_ALLOCATION)
        self.readiness_cache = None
        self.last_target_weights: dict[str, float] = {}

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
        if self.assaults or self.assault_timer is not None:
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
            "inventory": dict(self.inventory),
            "stocks": {
                "repair_drones": self.repair_drone_stock,
                "turret_ammo": self.turret_ammo_stock,
            },
            "power_load": self.power_load,
            "policies": {
                "repair_intensity": self.policies.repair_intensity,
                "defense_readiness": self.policies.defense_readiness,
                "surveillance_coverage": self.policies.surveillance_coverage,
                "fabrication_allocation": dict(self.fab_allocation),
                "fortification": dict(self.sector_fort_levels),
            },
            "defense": {
                "doctrine": self.defense_doctrine,
                "allocation": dict(self.defense_allocation),
                "readiness": self.compute_readiness(),
            },
            "fabrication_queue": [
                {
                    "id": task.id,
                    "name": task.name,
                    "remaining": max(0, int(task.ticks_remaining)),
                    "category": task.category,
                    "cost": task.material_cost,
                }
                for task in self.fabrication_queue
            ],
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

    def set_defense_doctrine(self, doctrine: str) -> bool:
        normalized = normalize_doctrine(doctrine)
        if normalized is None:
            return False
        if self.defense_doctrine != normalized:
            self.defense_doctrine = normalized
            self.doctrine_last_changed_time = self.time
        return True

    def compute_readiness(self) -> float:
        return compute_readiness(self)

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
    if command_center.damage >= COMMAND_CENTER_BREACH_DAMAGE:
        if state.command_breach_recovery_ticks is None:
            state.command_breach_recovery_ticks = COMMAND_BREACH_RECOVERY_TICKS
            return False
        if state.command_breach_recovery_ticks > 0:
            state.command_breach_recovery_ticks -= 1
            return False
    else:
        state.command_breach_recovery_ticks = None
        if state.archive_losses < ARCHIVE_LOSS_LIMIT:
            return False

    state.is_failed = True
    if command_center.damage >= COMMAND_CENTER_BREACH_DAMAGE:
        state.failure_reason = "COMMAND CENTER LOST"
        append_record(
            state,
            AssaultTickRecord(
                tick=state.time,
                targeted_sector=command_center.id,
                target_weight=0.0,
                assault_strength=0.0,
                defense_mitigation=0.0,
                failure_triggered=True,
                note="FAILURE_CHAIN:COMMAND",
            ),
        )
    else:
        state.failure_reason = "ARCHIVAL INTEGRITY LOST"
        archive = state.sectors.get("ARCHIVE")
        append_record(
            state,
            AssaultTickRecord(
                tick=state.time,
                targeted_sector=archive.id if archive else "AR",
                target_weight=0.0,
                assault_strength=0.0,
                defense_mitigation=0.0,
                failure_triggered=True,
                note="FAILURE_CHAIN:ARCHIVE",
            ),
        )
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

    # Maintenance loop: disciplined recovery on core systems can bleed threat down.
    command_sector = state.sectors.get("COMMAND")
    comms_sector = state.sectors.get("COMMS")
    no_active_assault = (
        not state.assaults
        and state.current_assault is None
        and not state.in_major_assault
    )
    if (
        no_active_assault
        and command_sector is not None
        and comms_sector is not None
        and power_sector is not None
        and state.ambient_threat >= 2.0
        and command_sector.damage < 0.5
        and comms_sector.damage < 0.5
        and power_sector.damage < 0.5
    ):
        state.ambient_threat = max(
            0.0,
            state.ambient_threat - (AMBIENT_THREAT_STABILITY_RECOVERY * delta),
        )

    if state.active_repairs and no_active_assault:
        state.ambient_threat = max(
            0.0,
            state.ambient_threat - (AMBIENT_THREAT_REPAIR_RECOVERY * delta),
        )

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
        recovery = state.sector_recovery_windows.get(sector.name)
        if recovery:
            sector.damage = max(0.0, sector.damage - recovery.get("damage_rate", 0.0) * delta)
            sector.alertness = max(0.0, sector.alertness - recovery.get("alertness_rate", 0.0) * delta)
            recovery["remaining"] = max(0.0, recovery.get("remaining", 0.0) - delta)
            if recovery["remaining"] <= 0.0:
                state.sector_recovery_windows.pop(sector.name, None)
        sector.occupied = False
