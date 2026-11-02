"""ARRN relay network state, progression, and helpers."""

from __future__ import annotations

from game.simulations.world_state.core.config import COMMAND_CENTER_LOCATION
from game.simulations.world_state.core.display_names import display_location, display_relay


KNOWLEDGE_TRACK = "RELAY_RECOVERY"
KNOWLEDGE_MAX = 7
KNOWLEDGE_DRIFT_PERIOD = 40
WEAK_SYNC_FAIL_CHANCE = 0.10

RELAY_DECAY_BASE = 0.5
RELAY_DECAY_PER_ACTIVE_ASSAULT = 0.2

RELAY_STABLE_MIN = 70.0
RELAY_WEAK_MIN = 30.0
RELAY_STABILITY_MAX = 100.0

RELAY_STATUSES = {"UNKNOWN", "LOCATED", "UNSTABLE", "STABLE", "WEAK", "DORMANT"}

KNOWLEDGE_UNLOCKS = {
    1: "SIGNAL_RECONSTRUCTION_I",
    2: "MAINTENANCE_ARCHIVE_I",
    3: "THREAT_FORECAST_I",
    4: "FAB_BLUEPRINTS_I",
    5: "LOGISTICS_OPTIMIZATION_I",
    6: "SIGNAL_RECONSTRUCTION_II",
    7: "ARCHIVAL_SYNTHESIS",
}


def default_relay_nodes() -> dict[str, dict]:
    return {
        "R_NORTH": {
            "sector": "T_NORTH",
            "status": "LOCATED",
            "stability": 80.0,
            "stability_ticks_required": 3,
            "risk_profile": "TRANSIT",
            "last_stabilized_time": None,
        },
        "R_SOUTH": {
            "sector": "T_SOUTH",
            "status": "LOCATED",
            "stability": 80.0,
            "stability_ticks_required": 3,
            "risk_profile": "TRANSIT",
            "last_stabilized_time": None,
        },
        "R_ARCHIVE": {
            "sector": "ARCHIVE",
            "status": "UNKNOWN",
            "stability": 40.0,
            "stability_ticks_required": 4,
            "risk_profile": "FRINGE",
            "last_stabilized_time": None,
        },
        "R_GATEWAY": {
            "sector": "GATEWAY",
            "status": "UNKNOWN",
            "stability": 40.0,
            "stability_ticks_required": 4,
            "risk_profile": "FRINGE",
            "last_stabilized_time": None,
        },
    }


def _knowledge_level(state) -> int:
    return int(state.knowledge_index.get(KNOWLEDGE_TRACK, 0))


def _active_assault_count(state) -> int:
    active_major = 1 if (state.current_assault is not None or state.in_major_assault) else 0
    approaching = len([a for a in state.assaults if getattr(a, "state", "") == "APPROACHING"])
    return active_major + approaching


def _status_from_stability(stability: float) -> str:
    if stability >= RELAY_STABLE_MIN:
        return "STABLE"
    if stability >= RELAY_WEAK_MIN:
        return "WEAK"
    return "DORMANT"


def _count_dormant_relays(state) -> int:
    count = 0
    for relay in state.relay_nodes.values():
        if str(relay.get("status", "UNKNOWN")).upper() == "DORMANT":
            count += 1
    return count


def _dormancy_pressure_from_count(dormant_count: int, knowledge_level: int) -> int:
    if dormant_count <= 0:
        return 0
    if knowledge_level >= 7:
        # ARCHIVAL_SYNTHESIS halves dormancy pressure but never inverts it.
        return max(0, (dormant_count + 1) // 2)
    return dormant_count


def _apply_relay_benefits(state) -> None:
    level = _knowledge_level(state)
    benefits = state.relay_benefits

    benefits["remote_repair_discount"] = 1 if level >= 2 else 0
    benefits["threat_forecast_bonus"] = 1 if level >= 3 else 0
    benefits["fab_blueprints_archive"] = 1 if level >= 4 else 0
    benefits["logistics_optimization"] = 1 if level >= 5 else 0
    benefits["signal_reconstruction_i"] = 1 if level >= 1 else 0
    benefits["signal_reconstruction_ii"] = 1 if level >= 6 else 0
    benefits["archival_synthesis"] = 1 if level >= 7 else 0


def refresh_relay_benefits(state) -> None:
    _apply_relay_benefits(state)


def relay_effective_fidelity_floor(state, fidelity: str) -> str:
    token = str(fidelity).upper()
    if int(state.relay_benefits.get("signal_reconstruction_ii", 0)) > 0 and token in {"LOST", "FRAGMENTED"}:
        return "DEGRADED"
    if int(state.relay_benefits.get("signal_reconstruction_i", 0)) > 0 and token == "DEGRADED":
        return "FULL"
    return token


def threat_forecast_bonus_ticks(state) -> int:
    return int(state.relay_benefits.get("threat_forecast_bonus", 0))


def logistics_penalty_modifier(state) -> float:
    if int(state.relay_benefits.get("logistics_optimization", 0)) > 0:
        return 0.9
    return 1.0


def resolve_relay_id(state, token: str) -> str | None:
    normalized = str(token).strip().upper()
    if not normalized:
        return None
    if normalized in state.relay_nodes:
        return normalized
    for relay_id, relay in state.relay_nodes.items():
        if str(relay.get("sector", "")).upper() == normalized:
            return relay_id
    return None


def relay_scan_lines(state, fidelity: str) -> list[str]:
    if fidelity == "LOST":
        return ["RELAY SCAN: NO SIGNAL."]
    if fidelity == "FRAGMENTED":
        return ["RELAY SCAN: SIGNAL IRREGULAR.", "CONTACT REQUIRES FIELD VERIFICATION."]

    lines = ["RELAY NETWORK:"]
    for relay_id in sorted(state.relay_nodes.keys()):
        relay = state.relay_nodes[relay_id]
        sector = str(relay.get("sector", "UNKNOWN"))
        relay_name = display_relay(relay_id)
        sector_name = display_location(sector)
        status = str(relay.get("status", "UNKNOWN")).upper()
        required = int(relay.get("stability_ticks_required", 0))
        stability = float(relay.get("stability", 0.0))

        if fidelity == "DEGRADED":
            if status in {"UNKNOWN", "DORMANT"}:
                status_text = "IRREGULAR"
            elif status == "STABLE":
                status_text = "STABLE"
            elif status == "WEAK":
                status_text = "WEAK"
            else:
                status_text = "ACTIVE"
            lines.append(f"- {relay_name}: {status_text}")
            continue

        lines.append(
            f"- {relay_name}: {status} | SECTOR {sector_name} | STABILITY {int(round(stability))} | STABILIZE {required} TICKS"
        )

    lines.append(f"PENDING PACKETS: {state.relay_packets_pending}")
    lines.append(f"KNOWLEDGE INDEX: {_knowledge_level(state)}/{KNOWLEDGE_MAX}")
    lines.append(f"DORMANCY PRESSURE: {int(getattr(state, 'dormancy_pressure', 0))}")
    return lines


def complete_relay_stabilization(state, relay_id: str) -> list[str]:
    relay = state.relay_nodes.get(relay_id)
    if not relay:
        return []
    relay["status"] = "STABLE"
    relay["stability"] = RELAY_STABILITY_MAX
    relay["last_stabilized_time"] = state.time
    state.relay_packets_pending += 1
    return [f"RELAY STABLE: {display_relay(relay_id)}", "PACKET READY FOR SYNC."]


def apply_sync(state) -> tuple[int, int, int]:
    packets = int(state.relay_packets_pending)
    current = _knowledge_level(state)
    if packets <= 0:
        return 0, current, 0

    weak_relays = sum(
        1
        for relay in state.relay_nodes.values()
        if str(relay.get("status", "UNKNOWN")).upper() == "WEAK"
    )
    failed_packets = 0
    for _ in range(min(weak_relays, packets)):
        if state.rng.random() < WEAK_SYNC_FAIL_CHANCE:
            failed_packets += 1
    successful_packets = max(0, packets - failed_packets)

    active_relays = sum(
        1
        for relay in state.relay_nodes.values()
        if str(relay.get("status", "UNKNOWN")).upper() in {"STABLE", "WEAK"}
    )
    weak_ratio = 0.0 if active_relays <= 0 else weak_relays / active_relays
    effective_gain = int(round(successful_packets * (1.0 - (0.5 * weak_ratio))))
    effective_gain = max(0, min(successful_packets, effective_gain))

    state.relay_packets_pending = 0
    new_level = min(KNOWLEDGE_MAX, current + effective_gain)
    state.knowledge_index[KNOWLEDGE_TRACK] = new_level
    state.last_sync_time = state.time
    _apply_relay_benefits(state)

    dormant_count = _count_dormant_relays(state)
    state.dormancy_pressure = _dormancy_pressure_from_count(dormant_count, new_level)

    return successful_packets, new_level, failed_packets


def tick_relays(state) -> None:
    active_assaults = _active_assault_count(state)
    decay_rate = RELAY_DECAY_BASE + (active_assaults * RELAY_DECAY_PER_ACTIVE_ASSAULT)

    active_relay_id = ""
    if state.active_task and getattr(state.active_task, "type", "") == "RELAY":
        active_relay_id = str(getattr(state.active_task, "relay_id", "")).upper()

    for relay_id, relay in state.relay_nodes.items():
        status = str(relay.get("status", "UNKNOWN")).upper()
        stability = max(0.0, min(RELAY_STABILITY_MAX, float(relay.get("stability", 0.0))))
        relay["stability"] = stability

        if status == "UNKNOWN":
            continue
        if status == "UNSTABLE" and relay_id == active_relay_id:
            continue

        stability = max(0.0, stability - decay_rate)
        relay["stability"] = stability
        if status == "LOCATED":
            if stability < RELAY_WEAK_MIN:
                relay["status"] = "DORMANT"
            continue
        if status != "UNSTABLE":
            relay["status"] = _status_from_stability(stability)

    level = _knowledge_level(state)
    dormant_count = _count_dormant_relays(state)
    state.dormancy_pressure = _dormancy_pressure_from_count(dormant_count, level)

    if (
        state.dormancy_pressure >= 3
        and state.time > 0
        and state.time % KNOWLEDGE_DRIFT_PERIOD == 0
    ):
        state.knowledge_index[KNOWLEDGE_TRACK] = max(0, level - 1)
        level = _knowledge_level(state)

    _apply_relay_benefits(state)


def knowledge_status_lines(state, fidelity: str) -> list[str]:
    lines = ["KNOWLEDGE STATUS:"]
    if fidelity == "LOST":
        lines.append("INDEX: NO SIGNAL")
        return lines

    level = _knowledge_level(state)
    lines.append(f"INDEX: {level}/{KNOWLEDGE_MAX}")
    lines.append(f"DORMANCY PRESSURE: {int(getattr(state, 'dormancy_pressure', 0))}")
    lines.append(f"PENDING PACKETS: {int(state.relay_packets_pending)}")

    if fidelity == "FRAGMENTED":
        lines.append("UNLOCKS: SIGNAL FRAGMENTED")
        return lines

    lines.append("UNLOCKS:")
    unlocked = [name for tier, name in KNOWLEDGE_UNLOCKS.items() if level >= tier]
    if not unlocked:
        lines.append("- NONE")
    else:
        for name in unlocked:
            lines.append(f"- {name}")
    return lines


def can_sync(state) -> bool:
    return state.player_location == COMMAND_CENTER_LOCATION and state.in_command_mode()
