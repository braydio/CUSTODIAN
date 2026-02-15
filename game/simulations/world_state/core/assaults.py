import time

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
    COMMAND_CENTER_BREACH_DAMAGE,
    GATEWAY_ASSAULT_TIMER_ACCEL,
)
from .effects import add_global_effect, add_sector_effect
from .repairs import cancel_repair_for_structure, regress_repairs_in_sectors
from .structures import StructureState


def maybe_start_assault_timer(state):
    if state.assault_timer is None and not state.in_major_assault:
        base = state.rng.randint(ASSAULT_TIMER_BASE_MIN, ASSAULT_TIMER_BASE_MAX)
        weak = sum(sector.damage for sector in state.weakest_sectors())
        timer = max(
            ASSAULT_TIMER_MIN, int(base - weak * ASSAULT_TIMER_WEAK_DAMAGE_MULT)
        )
        gateway = state.sectors.get("GATEWAY")
        if gateway and gateway.damage >= 1.0:
            timer = max(ASSAULT_TIMER_MIN, timer - GATEWAY_ASSAULT_TIMER_ACCEL * 2)
        state.assault_timer = timer


def tick_assault_timer(state):
    if state.assault_timer is None:
        return
    state.assault_timer -= 1
    gateway = state.sectors.get("GATEWAY")
    if gateway and gateway.damage >= 1.0:
        state.assault_timer -= GATEWAY_ASSAULT_TIMER_ACCEL
    comms = state.sectors.get("COMMS")
    warning_window = 6 if not (comms and comms.damage >= 1.0) else 2
    if 0 < state.assault_timer <= warning_window:
        print("[Warning] Hostile coordination detected.")
    if state.assault_timer <= 0:
        start_assault(state)


def _eligible_assault_targets(state):
    return [sector for sector in state.sectors.values() if sector.damage < 2.0]


def _select_focus_targets(state, count: int):
    eligible = _eligible_assault_targets(state)
    if not eligible:
        return []

    focused = state.focused_sector
    weights = []
    for sector in eligible:
        weights.append(0.25 if focused and sector.id == focused else 1.0)

    targets = []
    pool = list(zip(eligible, weights))
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
    eligible.sort(key=lambda s: s.damage + s.alertness, reverse=True)
    return eligible[:count]


def start_assault(state):
    state.in_major_assault = True
    state.assault_timer = None
    state.assault_count += 1

    target_count = 3
    if state.hardened:
        target_count = max(1, target_count - 1)

    if state.hardened:
        targets = _select_hardened_targets(state, target_count)
    else:
        targets = _select_focus_targets(state, target_count)

    assault = AssaultInstance(
        faction_profile=state.faction_profile,
        target_sectors=targets,
        threat_budget=100,  # fixed for now, matches your tutorial spec
        start_time=state.time,
    )

    state.current_assault = assault

    print("\n=== MAJOR ASSAULT BEGINS ===")
    print(assault)
    print()


def resolve_assault(state, tick_delay=0.05):
    assault = state.current_assault
    duration = state.rng.randint(ASSAULT_DURATION_MIN, ASSAULT_DURATION_MAX)
    assault.duration_ticks = duration
    target_names = {sector.name for sector in assault.target_sectors}
    archive_pre_damage = state.sectors["ARCHIVE"].damage

    def on_tick(sectors, tick):
        assault.tick()
        if state.dev_trace:
            print(
                {
                    "tick": assault.elapsed_ticks,
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
            world_sector.alertness += ASSAULT_ALERTNESS_PER_TICK
            state.ambient_threat += ASSAULT_THREAT_PER_TICK

        time.sleep(tick_delay)

    summary = resolve_tactical_assault(assault, on_tick, state=state)

    assault.resolved = True
    state.current_assault = None
    state.in_major_assault = False
    state.focused_sector = None
    state.hardened = False

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

    archive_post_damage = state.sectors["ARCHIVE"].damage
    if archive_pre_damage < 1.0 and archive_post_damage >= 1.0:
        state.archive_losses += 1

    print(outcome)
    print("\n=== ASSAULT REPULSED ===\n")
    return outcome


def _apply_assault_outcome(state, assault, outcome, target_names):
    """Apply post-assault consequences and return the primary outcome line."""

    # Outcome selection
    if "COMMAND" in target_names and outcome.penetration == "severe":
        command_center = state.sectors["COMMAND"]
        command_center.damage = max(command_center.damage, COMMAND_CENTER_BREACH_DAMAGE)
        regress_repairs_in_sectors(state, target_names)
        return "[ASSAULT] COMMAND BREACHED."

    if outcome.penetration == "none" and outcome.intensity == "low":
        state.ambient_threat += 0.2
        for sector in assault.target_sectors:
            sector.alertness *= 0.85
        return "[ASSAULT] DEFENSES HELD. ENEMY WITHDREW."

    if outcome.penetration == "none":
        _degrade_target_structures(state, target_names)
        regress_repairs_in_sectors(state, target_names)
        return "[ASSAULT] ENEMY REPULSED. INFRASTRUCTURE DAMAGE REPORTED."

    if outcome.penetration == "partial":
        _degrade_target_structures(state, target_names)
        regress_repairs_in_sectors(state, target_names)
        target = assault.target_sectors[0]
        target.alertness += 1.0
        add_sector_effect(target, "sensor_blackout", severity=1.0, decay=0.02)
        return "[ASSAULT] BREACH CONTAINED. SECTOR CONTROL DEGRADED."

    # Severe penetration but not command center breach -> strategic loss
    _degrade_target_structures(state, target_names)
    regress_repairs_in_sectors(state, target_names)
    target = assault.target_sectors[0]
    target.power = max(0.2, target.power - 0.2)
    add_global_effect(state, "signal_interference", severity=1.0, decay=0.0)
    return "[ASSAULT] CRITICAL SYSTEM LOST. NO REPLACEMENT AVAILABLE."


def _degrade_target_structures(state, target_names: set[str]) -> None:
    for structure in state.structures.values():
        if structure.sector not in target_names:
            continue
        before = structure.state
        structure.degrade()
        if before != StructureState.DESTROYED and structure.state == StructureState.DESTROYED:
            cancel_repair_for_structure(state, structure.id)
