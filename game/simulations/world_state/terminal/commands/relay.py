"""Relay-network command handlers."""

from __future__ import annotations

from game.simulations.world_state.core.config import FIELD_ACTION_STABILIZING
from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.relays import (
    apply_sync,
    can_sync,
    relay_scan_lines,
    resolve_relay_id,
)
from game.simulations.world_state.core.tasks import RelayTask
from game.simulations.world_state.core.state import GameState


def cmd_scan_relays(state: GameState) -> list[str]:
    fidelity = comms_fidelity(state)
    state.fidelity = fidelity
    return relay_scan_lines(state, fidelity)


def cmd_stabilize_relay(state: GameState, relay_token: str) -> list[str]:
    if state.in_command_mode():
        return ["FIELD AUTHORITY REQUIRED."]
    if state.active_task or state.active_repairs:
        return ["ACTION IN PROGRESS."]

    relay_id = resolve_relay_id(state, relay_token)
    if relay_id is None:
        return ["UNKNOWN RELAY."]
    relay = state.relay_nodes[relay_id]
    sector = str(relay.get("sector", ""))
    if sector != state.player_location:
        return ["RELAY NOT IN CURRENT LOCATION."]
    status = str(relay.get("status", "UNKNOWN")).upper()
    if status == "STABLE":
        return [f"RELAY {relay_id} ALREADY STABLE."]

    ticks = int(relay.get("stability_ticks_required", 3))
    relay["status"] = "UNSTABLE"
    state.active_task = RelayTask(relay_id=relay_id, target=sector, ticks=ticks, total=ticks)
    state.field_action = FIELD_ACTION_STABILIZING
    return [f"STABILIZING {relay_id} ({ticks} TICKS)."]


def cmd_sync(state: GameState) -> list[str]:
    if not can_sync(state):
        return ["COMMAND AUTHORITY REQUIRED."]
    packets, new_level = apply_sync(state)
    if packets <= 0:
        return ["SYNC: NO RELAY PACKETS PENDING."]

    lines = [
        f"SYNC COMPLETE: {packets} PACKET{'S' if packets != 1 else ''}.",
        f"KNOWLEDGE INDEX RELAY_RECOVERY={new_level}.",
    ]
    if int(state.relay_benefits.get("remote_repair_discount", 0)) > 0:
        lines.append("BENEFIT ACTIVE: REMOTE REPAIR COST -1.")
    return lines
