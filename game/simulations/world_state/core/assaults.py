import time
from collections import deque
from uuid import uuid4

from .assault_instance import AssaultInstance
from .tactical_bridge import resolve_tactical_assault
from ..assault_outcome import AssaultOutcome

from .config import (
    ASSAULT_ALERTNESS_PER_TICK,
    ASSAULT_DURATION_MAX,
    ASSAULT_DURATION_MIN,
    ASSAULT_THREAT_PER_TICK,
    ASSAULT_TIMER_BASE_MAX,
    ASSAULT_TIMER_BASE_MIN,
    ASSAULT_TIMER_MIN,
    ASSAULT_TIMER_WEAK_DAMAGE_MULT,
    ASSAULT_TARGET_ALERTNESS_WEIGHT,
    ASSAULT_TARGET_COMMAND_BONUS,
    ASSAULT_TARGET_DAMAGE_WEIGHT,
    ASSAULT_TARGET_STATIC_WEIGHT,
    ASSAULT_TARGET_TRANSIT_BONUS,
    COMMAND_CENTER_BREACH_DAMAGE,
    EDGE_TRAVEL_TICKS,
    INGRESS_N,
    INGRESS_S,
    MAX_ACTIVE_ASSAULTS_TUTORIAL,
    TRAVEL_GRAPH,
    TRANSIT_NODES,
    WORLD_GRAPH,
)
from .effects import add_global_effect, add_sector_effect
from .assault_ledger import AssaultTickRecord, append_record
from .defense import (
    defense_bias_for_sector,
    doctrine_sector_priority_multiplier,
    doctrine_threat_multiplier,
)
from .policies import FORTIFICATION_MULT
from .power import comms_fidelity, structure_effective_output
from .repairs import cancel_repair_for_structure, regress_repairs_in_sectors
from .structure_effects import apply_structure_destroyed_effects
from .structures import StructureState


class AssaultApproach:
    """Spatial ingress approach that moves through world graph nodes."""

    def __init__(self, ingress: str, target: str, route: list[str]):
        self.id = str(uuid4())
        self.ingress = ingress
        self.target = target
        self.route = route
        self.index = 0
        self.ticks_to_next = EDGE_TRAVEL_TICKS
        self.state = "APPROACHING"  # APPROACHING | ENGAGED

    def current_node(self) -> str:
        return self.route[min(self.index, len(self.route) - 1)]

    def eta_ticks(self) -> int:
        if self.state != "APPROACHING":
            return 0
        remaining_edges = max(0, (len(self.route) - 1) - self.index)
        if remaining_edges == 0:
            return 0
        return self.ticks_to_next + max(0, remaining_edges - 1) * EDGE_TRAVEL_TICKS


def compute_route(start: str, goal: str) -> list[str]:
    if start == goal:
        return [start]

    visited: set[str] = set()
    queue: deque[list[str]] = deque([[start]])
    while queue:
        path = queue.popleft()
        node = path[-1]
        if node == goal:
            return path
        if node in visited:
            continue
        visited.add(node)
        for neighbor in WORLD_GRAPH.get(node, []):
            if neighbor in visited:
                continue
            queue.append(path + [neighbor])
    return []


def _refresh_assault_eta(state) -> None:
    pending = [a.eta_ticks() for a in state.assaults if a.state == "APPROACHING"]
    state.assault_timer = min(pending) if pending else None


def maybe_start_assault_timer(state):
    """Compatibility shim for older callsites."""
    maybe_spawn_assault(state)
    _refresh_assault_eta(state)


def tick_assault_timer(state):
    """Compatibility shim for older callsites."""
    advance_assaults(state)
    _refresh_assault_eta(state)


def _eligible_assault_targets(state):
    return [sector for sector in state.sectors.values() if sector.damage < 2.0]


def _sector_static_priority(sector_name: str) -> float:
    if sector_name == "COMMAND":
        return 2.0
    if sector_name == "ARCHIVE":
        return 1.8
    if sector_name == "DEFENSE GRID":
        return 1.6
    if sector_name == "POWER":
        return 1.4
    if sector_name in {"COMMS", "GATEWAY"}:
        return 1.2
    return 1.0


def _transit_lanes() -> dict[str, set[str]]:
    lanes: dict[str, set[str]] = {}
    for transit in TRANSIT_NODES:
        members = set(TRAVEL_GRAPH.get(transit, []))
        members.discard("COMMAND")
        members.discard(transit)
        lanes[transit] = members
    return lanes


TRANSIT_LANES = _transit_lanes()


def _transit_pressure_bonus(state, sector_name: str) -> float:
    bonus = 0.0
    for members in TRANSIT_LANES.values():
        if sector_name not in members:
            continue
        lane_degraded = any(
            state.sectors[name].damage >= 1.0 or state.sectors[name].alertness >= 2.0
            for name in members
            if name in state.sectors
        )
        if lane_degraded:
            bonus += ASSAULT_TARGET_TRANSIT_BONUS
    return bonus


def _sector_dynamic_priority(sector) -> float:
    return (
        sector.damage * ASSAULT_TARGET_DAMAGE_WEIGHT
        + sector.alertness * ASSAULT_TARGET_ALERTNESS_WEIGHT
    )


def _sector_target_weight(state, sector) -> float:
    weight = _sector_static_priority(sector.name) * ASSAULT_TARGET_STATIC_WEIGHT
    weight += _sector_dynamic_priority(sector)
    weight += _transit_pressure_bonus(state, sector.name)
    if sector.name == "COMMAND":
        weight += ASSAULT_TARGET_COMMAND_BONUS
    weight *= doctrine_sector_priority_multiplier(state.defense_doctrine, sector.name)
    weight *= max(0.6, 1.6 - defense_bias_for_sector(state.defense_allocation, sector.name))

    if state.focused_sector and sector.id == state.focused_sector:
        weight *= 0.25

    return max(0.05, weight)


def _select_focus_targets(state, count: int):
    eligible = _eligible_assault_targets(state)
    if not eligible:
        return []

    if state.assault_trace_enabled:
        state.last_target_weights = {
            sector.id: round(_sector_target_weight(state, sector), 4)
            for sector in eligible
        }

    targets = []
    pool = [(sector, _sector_target_weight(state, sector)) for sector in eligible]
    while pool and len(targets) < count:
        sectors, sector_weights = zip(*pool)
        chosen = state.rng.choices(sectors, weights=sector_weights, k=1)[0]
        targets.append(chosen)
        pool = [(sector, weight) for sector, weight in pool if sector is not chosen]

    return targets


def _select_hardened_targets(state, count: int):
    eligible = _eligible_assault_targets(state)
    if not eligible:
        return []
    if state.assault_trace_enabled:
        state.last_target_weights = {
            sector.id: round(_sector_target_weight(state, sector), 4)
            for sector in eligible
        }
    eligible.sort(key=lambda s: _sector_target_weight(state, s), reverse=True)
    return eligible[:count]


def _choose_spawn_targets(state, count: int):
    if state.hardened:
        return _select_hardened_targets(state, count)
    return _select_focus_targets(state, count)


def choose_target_sector(state) -> str | None:
    targets = _choose_spawn_targets(state, 1)
    if not targets:
        return None
    return targets[0].name


def maybe_spawn_assault(state) -> None:
    if state.current_assault is not None or state.in_major_assault:
        return
    if len(state.assaults) >= MAX_ACTIVE_ASSAULTS_TUTORIAL:
        _refresh_assault_eta(state)
        return
    if state.ambient_threat <= 1.5:
        _refresh_assault_eta(state)
        return

    spawn_chance = min(0.65, 0.08 + state.ambient_threat * 0.06)
    if state.rng.random() > spawn_chance:
        _refresh_assault_eta(state)
        return

    ingress = state.rng.choice([INGRESS_N, INGRESS_S])
    target = choose_target_sector(state)
    if not target:
        _refresh_assault_eta(state)
        return

    route = compute_route(ingress, target)
    if not route:
        _refresh_assault_eta(state)
        return

    state.assaults.append(AssaultApproach(ingress=ingress, target=target, route=route))
    _refresh_assault_eta(state)


def maybe_warn(state, node: str) -> None:
    fidelity = comms_fidelity(state)
    if fidelity == "FULL":
        chance = 0.8
    elif fidelity == "DEGRADED":
        chance = 0.6
    elif fidelity == "FRAGMENTED":
        chance = 0.4
    else:
        chance = 0.2

    if state.rng.random() < chance:
        line = f"[WARNING] HOSTILE MOVEMENT NEAR {node}"
    else:
        line = "[EVENT] SIGNAL INTERFERENCE DETECTED"

    if line not in state.last_assault_lines:
        state.last_assault_lines.append(line)


def advance_assaults(state) -> None:
    engaged: list[AssaultApproach] = []

    for approach in state.assaults:
        if approach.state != "APPROACHING":
            continue

        approach.ticks_to_next -= 1
        if approach.ticks_to_next <= 0:
            approach.index += 1
            if approach.index >= len(approach.route) - 1:
                approach.state = "ENGAGED"
                engaged.append(approach)
            else:
                approach.ticks_to_next = EDGE_TRAVEL_TICKS

        node = approach.current_node()
        if node in TRANSIT_NODES:
            maybe_warn(state, node)

    if engaged and state.current_assault is None and not state.in_major_assault:
        approach = engaged[0]
        target_sector = state.sectors.get(approach.target)
        if target_sector is not None:
            _start_assault(state, [target_sector])
        state.assaults = [a for a in state.assaults if a.id != approach.id]

    _refresh_assault_eta(state)


def start_assault(state):
    target_count = 3
    if state.hardened:
        target_count = max(1, target_count - 1)
    targets = _choose_spawn_targets(state, target_count)
    _start_assault(state, targets)


def _start_assault(state, targets) -> None:
    state.in_major_assault = True
    state.assault_timer = None
    state.assault_count += 1

    readiness = state.compute_readiness()
    assault = AssaultInstance(
        faction_profile=state.faction_profile,
        target_sectors=targets,
        threat_budget=100,
        start_time=state.time,
        readiness=readiness,
        threat_scale=doctrine_threat_multiplier(state.defense_doctrine),
    )
    assault.defense_doctrine = state.defense_doctrine
    assault.defense_allocation = dict(state.defense_allocation)
    state.current_assault = assault
    print("\n=== MAJOR ASSAULT BEGINS ===")
    print(assault)
    print()


def resolve_assault(state, tick_delay=0.05):
    assault = state.current_assault
    ledger_start = len(state.assault_ledger.ticks)
    duration = state.rng.randint(ASSAULT_DURATION_MIN, ASSAULT_DURATION_MAX)
    assault.duration_ticks = duration
    target_names = {sector.name for sector in assault.target_sectors}
    archive_pre_damage = state.sectors["ARCHIVE"].damage

    def on_tick(sectors, tick):
        assault.tick()
        if state.dev_trace:
            print(
                {
                    "tick": getattr(assault, "ticks_elapsed", tick),
                    "active_sectors": [s.name for s in sectors if s.has_hostiles()],
                    "ambient_threat": state.ambient_threat,
                    "alertness": {
                        sector.name: sector.alertness for sector in assault.target_sectors
                    },
                }
            )
        for sector in sectors:
            if not sector.has_hostiles():
                continue
            world_sector = next(
                (s for s in assault.target_sectors if s.name == sector.name), None
            )
            if world_sector is None:
                continue
            print(f"[Assault] Fighting in {world_sector.name}")
            world_sector.occupied = True
            pressure = _incoming_damage_multiplier(state, world_sector.name)
            world_sector.alertness += ASSAULT_ALERTNESS_PER_TICK * pressure
            state.ambient_threat += ASSAULT_THREAT_PER_TICK
            target_weight = _sector_target_weight(state, world_sector)
            assault_strength = max(1.0, assault.threat_budget / max(1, assault.duration_ticks))
            defense_mitigation = max(0.0, min(1.0, 1.0 / pressure))
            append_record(
                state,
                AssaultTickRecord(
                    tick=state.time,
                    targeted_sector=world_sector.id,
                    target_weight=target_weight,
                    assault_strength=assault_strength,
                    defense_mitigation=defense_mitigation,
                    failure_triggered=state.is_failed,
                ),
            )

        time.sleep(tick_delay)

    summary = resolve_tactical_assault(assault, on_tick, state=state)

    assault.resolved = True
    state.current_assault = None
    state.in_major_assault = False
    state.focused_sector = None
    state.hardened = False
    _refresh_assault_eta(state)

    outcome = AssaultOutcome(
        threat_budget=assault.threat_budget,
        duration=summary["duration"],
        spawned=summary["spawned"],
        killed=summary["killed"],
        retreated=summary["retreated"],
        remaining=summary["remaining"],
    )

    message = _apply_assault_outcome(state, assault, outcome, target_names)
    state.last_assault_lines = [message] if message else []
    summary_lines = _generate_after_action_summary(state, ledger_start)
    if summary_lines:
        state.last_assault_lines.extend(summary_lines)

    archive_post_damage = state.sectors["ARCHIVE"].damage
    if archive_pre_damage < 1.0 and archive_post_damage >= 1.0:
        state.archive_losses += 1

    print(outcome)
    print("\n=== ASSAULT REPULSED ===\n")
    return outcome


def _apply_assault_outcome(state, assault, outcome, target_names):
    """Apply post-assault consequences and return the primary outcome line."""
    regression_targets = _effective_repair_regression_targets(state, target_names)

    # Outcome selection
    if "COMMAND" in target_names and outcome.penetration == "severe":
        command_center = state.sectors["COMMAND"]
        command_center.damage = max(command_center.damage, COMMAND_CENTER_BREACH_DAMAGE)
        regress_repairs_in_sectors(state, regression_targets)
        return "[ASSAULT] COMMAND BREACHED."

    if outcome.penetration == "none" and outcome.intensity == "low":
        state.ambient_threat += 0.2
        for sector in assault.target_sectors:
            sector.alertness *= 0.85
        return "[ASSAULT] DEFENSES HELD. ENEMY WITHDREW."

    if outcome.penetration == "none":
        _degrade_target_structures(state, target_names)
        regress_repairs_in_sectors(state, regression_targets)
        award_salvage(state, outcome)
        return "[ASSAULT] ENEMY REPULSED. INFRASTRUCTURE DAMAGE REPORTED."

    if outcome.penetration == "partial":
        _degrade_target_structures(state, target_names)
        regress_repairs_in_sectors(state, regression_targets)
        target = assault.target_sectors[0]
        target.alertness += 1.0
        add_sector_effect(target, "sensor_blackout", severity=1.0, decay=0.02)
        award_salvage(state, outcome)
        return "[ASSAULT] BREACH CONTAINED. SECTOR CONTROL DEGRADED."

    if state.autonomy_override_enabled and _compute_defensive_margin(state, outcome) >= 0:
        _degrade_target_structures(state, target_names)
        regress_repairs_in_sectors(state, regression_targets)
        award_salvage(state, outcome)
        return "[ASSAULT] AUTONOMOUS SYSTEMS HELD PERIMETER."

    # Severe penetration but not command center breach -> strategic loss
    _degrade_target_structures(state, target_names)
    regress_repairs_in_sectors(state, regression_targets)
    target = assault.target_sectors[0]
    target.power = max(0.2, target.power - 0.2)
    add_global_effect(state, "signal_interference", severity=1.0, decay=0.0)
    award_salvage(state, outcome)
    return "[ASSAULT] CRITICAL SYSTEM LOST. NO REPLACEMENT AVAILABLE."


def _compute_defensive_margin(state, outcome) -> float:
    defense = state.structures.get("DF_CORE")
    defense_output = 0.0
    if defense is not None:
        defense_output = structure_effective_output(state, defense)
    return (
        (outcome.killed + outcome.retreated)
        + (defense_output * 2.0)
        + max(0.0, state.compute_readiness() - 0.5) * 4.0
        + state.autonomy_strength_bonus
        - outcome.remaining
    )


def _incoming_damage_multiplier(state, sector_name: str) -> float:
    multiplier = 1.0 / defense_bias_for_sector(state.defense_allocation, sector_name)
    fort_level = int(state.sector_fort_levels.get(sector_name, 0))
    multiplier /= max(1.0, FORTIFICATION_MULT[fort_level])
    doctrine = state.defense_doctrine
    if doctrine == "AGGRESSIVE":
        multiplier *= 1.15
    elif doctrine == "COMMAND_FIRST":
        multiplier *= 0.5 if sector_name == "COMMAND" else 1.2
    elif doctrine == "INFRASTRUCTURE_FIRST":
        if sector_name in {"POWER", "COMMS", "FABRICATION"}:
            multiplier *= 0.7
        elif sector_name in {"GATEWAY", "HANGAR", "DEFENSE GRID"}:
            multiplier *= 1.15
    elif doctrine == "SENSOR_PRIORITY":
        multiplier *= 0.75 if sector_name == "COMMS" else 1.05
    return max(0.25, min(2.0, multiplier))


def _effective_repair_regression_targets(state, target_names: set[str]) -> set[str]:
    selected: set[str] = set()
    for sector_name in target_names:
        bias = defense_bias_for_sector(state.defense_allocation, sector_name)
        if bias >= 1.25:
            continue
        selected.add(sector_name)
    return selected


def _degrade_target_structures(state, target_names: set[str]) -> None:
    for structure in state.structures.values():
        if structure.sector not in target_names:
            continue
        steps = 1
        pressure = _incoming_damage_multiplier(state, structure.sector)
        if pressure <= 0.6:
            steps = 0
        elif pressure >= 1.35:
            steps = 2
        before = structure.state
        for _ in range(steps):
            structure.degrade()
        if before != StructureState.DESTROYED and structure.state == StructureState.DESTROYED:
            cancel_repair_for_structure(state, structure.id)
            if structure.id not in state.detected_structure_losses:
                state.pending_structure_losses.add(structure.id)
            state.last_structure_loss_lines.extend(
                apply_structure_destroyed_effects(state, structure.id)
            )
            sector = state.sectors.get(structure.sector)
            append_record(
                state,
                AssaultTickRecord(
                    tick=state.time,
                    targeted_sector=sector.id if sector else structure.sector,
                    target_weight=(
                        _sector_target_weight(state, sector)
                        if sector is not None
                        else 0.0
                    ),
                    assault_strength=0.0,
                    defense_mitigation=0.0,
                    building_destroyed=structure.id,
                    failure_triggered=state.is_failed,
                ),
            )


def award_salvage(state, outcome) -> None:
    if outcome.penetration == "none":
        return
    if outcome.penetration == "partial":
        state.materials += 1
        return
    if outcome.penetration == "severe":
        state.materials += 2


def _generate_after_action_summary(state, ledger_start: int) -> list[str]:
    destroyed = []
    for record in state.assault_ledger.ticks[ledger_start:]:
        if record.building_destroyed and record.building_destroyed not in destroyed:
            destroyed.append(record.building_destroyed)
    if not destroyed:
        return []
    return [
        "AFTER ACTION SUMMARY:",
        "LOSS: " + ", ".join(destroyed),
        (
            "POLICY LOAD: "
            f"R{state.policies.repair_intensity} "
            f"D{state.policies.defense_readiness} "
            f"S{state.policies.surveillance_coverage} "
            f"| POWER {state.power_load:.2f}"
        ),
    ]
