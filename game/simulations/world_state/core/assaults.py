import random
import time

from .assault_instance import AssaultInstance
from .tactical_bridge import resolve_tactical_assault
from ..assault_outcome import AssaultOutcome

from .config import (
    ASSAULT_ALERTNESS_PER_TICK,
    ASSAULT_DAMAGE_PER_TICK,
    ASSAULT_DURATION_MAX,
    ASSAULT_DURATION_MIN,
    ASSAULT_THREAT_PER_TICK,
    ASSAULT_TIMER_BASE_MAX,
    ASSAULT_TIMER_BASE_MIN,
    ASSAULT_TIMER_MIN,
    ASSAULT_TIMER_WEAK_DAMAGE_MULT,
    COMMAND_CENTER_BREACH_DAMAGE,
    DEFENSE_ASSAULT_DAMAGE_MULT,
    GATEWAY_ASSAULT_TIMER_ACCEL,
)
from .effects import add_global_effect, add_sector_effect


def maybe_start_assault_timer(state):
    if state.assault_timer is None and not state.in_major_assault:
        base = random.randint(ASSAULT_TIMER_BASE_MIN, ASSAULT_TIMER_BASE_MAX)
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


def start_assault(state):
    state.in_major_assault = True
    state.assault_timer = None
    state.assault_count += 1

    targets = state.weakest_sectors(3)
    if state.focused_sector:
        focused = next(
            (sector for sector in targets if sector.id == state.focused_sector),
            None,
        )
        if focused:
            replacements = [
                sector
                for sector in state.sectors.values()
                if sector not in targets and sector.id != state.focused_sector
            ]
            if replacements:
                replacements.sort(
                    key=lambda s: s.damage + s.alertness, reverse=True
                )
                targets.remove(focused)
                targets.append(replacements[0])

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
    duration = random.randint(ASSAULT_DURATION_MIN, ASSAULT_DURATION_MAX)
    assault.duration_ticks = duration
    target_names = {sector.name for sector in assault.target_sectors}
    pre_damage = {sector.name: sector.damage for sector in assault.target_sectors}

    def on_tick(sectors, tick):
        assault.tick()
        defense = state.sectors.get("DEFENSE GRID")
        defense_mult = DEFENSE_ASSAULT_DAMAGE_MULT if defense and defense.damage >= 1.0 else 1.0
        for sector in sectors:
            if not sector.has_hostiles():
                continue
            world_sector = next(
                (s for s in assault.target_sectors if s.name == sector.name), None
            )
            if world_sector is None:
                continue
            print(f"[Assault] Fighting in {world_sector.name}")
            damage_mult = defense_mult
            if state.focused_sector:
                if world_sector.id == state.focused_sector:
                    damage_mult *= 0.7
                else:
                    damage_mult *= 1.1
            world_sector.damage += ASSAULT_DAMAGE_PER_TICK * damage_mult
            world_sector.alertness += ASSAULT_ALERTNESS_PER_TICK
            state.ambient_threat += ASSAULT_THREAT_PER_TICK

        time.sleep(tick_delay)

    summary = resolve_tactical_assault(assault, on_tick)

    assault.resolved = True
    state.current_assault = None
    state.in_major_assault = False
    state.focused_sector = None
    state.focused_sector = None

    outcome = AssaultOutcome(
        threat_budget=assault.threat_budget,
        duration=summary["duration"],
        spawned=summary["spawned"],
        killed=summary["killed"],
        retreated=summary["retreated"],
        remaining=summary["remaining"],
    )

    assault_damage = sum(
        max(0.0, sector.damage - pre_damage.get(sector.name, 0.0))
        for sector in assault.target_sectors
    )

    message = _apply_assault_outcome(state, assault, outcome, assault_damage, target_names)
    state.last_assault_lines = [message] if message else []

    print(outcome)
    print("\n=== ASSAULT REPULSED ===\n")
    return outcome


def _apply_assault_outcome(state, assault, outcome, assault_damage, target_names):
    """Apply post-assault consequences and return the primary outcome line."""

    # Outcome selection
    if "COMMAND" in target_names and outcome.penetration == "severe":
        command_center = state.sectors["COMMAND"]
        command_center.damage = max(command_center.damage, COMMAND_CENTER_BREACH_DAMAGE)
        return "[ASSAULT] COMMAND BREACHED."

    if outcome.penetration == "none" and assault_damage < 0.5:
        state.ambient_threat += 0.2
        for sector in assault.target_sectors:
            sector.alertness *= 0.85
        return "[ASSAULT] DEFENSES HELD. ENEMY WITHDREW."

    if outcome.penetration == "none":
        for sector in assault.target_sectors:
            sector.damage += 0.6
            sector.alertness += 0.4
        return "[ASSAULT] ENEMY REPULSED. INFRASTRUCTURE DAMAGE REPORTED."

    if outcome.penetration == "partial":
        target = assault.target_sectors[0]
        target.damage = max(target.damage, 2.0)
        target.alertness += 1.0
        add_sector_effect(target, "sensor_blackout", severity=1.0, decay=0.02)
        return "[ASSAULT] BREACH CONTAINED. SECTOR CONTROL DEGRADED."

    # Severe penetration but not command center breach -> strategic loss
    target = assault.target_sectors[0]
    target.power = max(0.2, target.power - 0.2)
    add_global_effect(state, "signal_interference", severity=1.0, decay=0.0)
    return "[ASSAULT] CRITICAL SYSTEM LOST. NO REPLACEMENT AVAILABLE."
