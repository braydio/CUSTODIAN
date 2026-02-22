"""ARRN relay network state and helpers."""

from __future__ import annotations

from game.simulations.world_state.core.config import COMMAND_CENTER_LOCATION


RELAY_STATUSES = {"UNKNOWN", "LOCATED", "UNSTABLE", "STABLE", "DORMANT"}


def default_relay_nodes() -> dict[str, dict]:
    return {
        "R_NORTH": {
            "sector": "T_NORTH",
            "status": "LOCATED",
            "stability_ticks_required": 3,
            "risk_profile": "TRANSIT",
            "last_stabilized_time": None,
        },
        "R_SOUTH": {
            "sector": "T_SOUTH",
            "status": "LOCATED",
            "stability_ticks_required": 3,
            "risk_profile": "TRANSIT",
            "last_stabilized_time": None,
        },
        "R_ARCHIVE": {
            "sector": "ARCHIVE",
            "status": "UNKNOWN",
            "stability_ticks_required": 4,
            "risk_profile": "FRINGE",
            "last_stabilized_time": None,
        },
        "R_GATEWAY": {
            "sector": "GATEWAY",
            "status": "UNKNOWN",
            "stability_ticks_required": 4,
            "risk_profile": "FRINGE",
            "last_stabilized_time": None,
        },
    }


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
        status = str(relay.get("status", "UNKNOWN"))
        required = int(relay.get("stability_ticks_required", 0))

        if fidelity == "DEGRADED":
            if status in {"UNKNOWN", "DORMANT"}:
                status_text = "IRREGULAR"
            elif status == "STABLE":
                status_text = "STABLE"
            else:
                status_text = "ACTIVE"
            lines.append(f"- {relay_id}: {status_text}")
            continue

        lines.append(f"- {relay_id}: {status} | SECTOR {sector} | STABILIZE {required} TICKS")

    lines.append(f"PENDING PACKETS: {state.relay_packets_pending}")
    lines.append(f"KNOWLEDGE INDEX: {state.knowledge_index.get('RELAY_RECOVERY', 0)}")
    return lines


def complete_relay_stabilization(state, relay_id: str) -> list[str]:
    relay = state.relay_nodes.get(relay_id)
    if not relay:
        return []
    relay["status"] = "STABLE"
    relay["last_stabilized_time"] = state.time
    state.relay_packets_pending += 1
    return [f"RELAY STABLE: {relay_id}", "PACKET READY FOR SYNC."]


def apply_sync(state) -> tuple[int, int]:
    packets = int(state.relay_packets_pending)
    if packets <= 0:
        return 0, int(state.knowledge_index.get("RELAY_RECOVERY", 0))
    state.relay_packets_pending = 0
    current = int(state.knowledge_index.get("RELAY_RECOVERY", 0))
    new_level = current + packets
    state.knowledge_index["RELAY_RECOVERY"] = new_level
    state.last_sync_time = state.time

    # First bounded reward: reduce remote DAMAGED repair costs by 1 (floor stays 1).
    if new_level >= 3:
        state.relay_benefits["remote_repair_discount"] = 1

    return packets, new_level


def can_sync(state) -> bool:
    return state.player_location == COMMAND_CENTER_LOCATION and state.in_command_mode()
