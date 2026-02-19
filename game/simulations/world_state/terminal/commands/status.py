"""STATUS command handler."""

import math

from game.simulations.world_state.core.config import (
    ARCHIVE_LOSS_LIMIT,
    COMMAND_CENTER_BREACH_DAMAGE,
    SECTOR_DEFS,
)
from game.simulations.world_state.core.policies import render_slider
from game.simulations.world_state.core.power import comms_fidelity
from game.simulations.world_state.core.state import GameState


MARKERS = {
    "COMPROMISED": "X",
    "DAMAGED": "!",
    "ALERT": "~",
    "ACTIVITY DETECTED": "?",
    "STABLE": ".",
}


def _sector_priority_by_label(label: str) -> int:
    order = {
        "COMPROMISED": 0,
        "DAMAGED": 1,
        "ALERT": 2,
        "ACTIVITY DETECTED": 3,
        "STABLE": 4,
        "NO DATA": 5,
    }
    return order.get(label, 6)


def _sector_priority(sector) -> int:
    return _sector_priority_by_label(sector.status_label())


def _compute_situation_header(state: GameState, sector_status_by_name: dict[str, str]) -> str:
    degraded = []
    for sector in state.sectors.values():
        label = sector_status_by_name.get(sector.name, sector.status_label())
        if label in ("DAMAGED", "COMPROMISED"):
            degraded.append(sector.name)

    if degraded:
        count = len(degraded)
        return f"SITUATION: {count} SYSTEM{'S' if count > 1 else ''} DEGRADED"

    if state.fidelity != "FULL":
        return "SITUATION: INFORMATION UNSTABLE"

    return "SITUATION: STABLE"


def _system_posture(state: GameState, fidelity: str) -> str:
    if state.hardened:
        return "HARDENED"
    if state.focused_sector and fidelity == "FULL":
        focus_lookup = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
        focused_name = focus_lookup.get(state.focused_sector, "UNKNOWN")
        return f"FOCUSED ({focused_name})"
    if state.focused_sector and fidelity != "FULL":
        return "FOCUSED"
    return "ACTIVE"


def _render_compact_field_view(state: GameState, sector_status_by_name: dict[str, str]) -> list[str]:
    lines = []
    lines.append(f"LOCATION: {state.player_location}")
    lines.append(f"FIDELITY: {state.fidelity}")
    lines.append("")

    sorted_sectors = sorted(state.sectors.values(), key=_sector_priority)
    stable_header_added = False
    for sector in sorted_sectors:
        label = sector_status_by_name.get(sector.name, sector.status_label())
        marker = MARKERS.get(label, ".")
        if marker == "." and not stable_header_added:
            lines.append("---")
            stable_header_added = True
        prefix = ">" if sector.name == state.player_location else " "
        lines.append(f"{prefix} {sector.name:<12} {marker}")
    return lines


def _append_repairs(lines: list[str], snapshot: dict, state: GameState, fidelity: str) -> None:
    repairs = snapshot.get("active_repairs", [])
    if not repairs:
        return
    if fidelity == "LOST":
        lines.append("REPAIRS: NO SIGNAL")
        return

    lines.append("REPAIRS:")
    for repair in repairs:
        structure = state.structures.get(repair["id"])
        name = structure.name if structure else repair["id"]
        if fidelity == "FULL":
            done = repair["total"] - repair["remaining"]
            lines.append(f"- {repair['id']} {name}: {done}/{repair['total']} TICKS")
        elif fidelity == "DEGRADED":
            lines.append(f"- {repair['id']}: IN PROGRESS")
        else:
            lines.append("- MAINTENANCE SIGNALS DETECTED")


def _append_assault_eta(lines: list[str], state: GameState, fidelity: str) -> None:
    approaches = [assault for assault in state.assaults if getattr(assault, "state", "") == "APPROACHING"]
    if not approaches:
        return
    if fidelity == "LOST":
        return
    if fidelity == "FRAGMENTED":
        lines.append("THREAT: APPROACH SIGNALS DETECTED")
        return

    if fidelity == "DEGRADED":
        eta_values = []
        for assault in approaches:
            eta_fn = getattr(assault, "eta_ticks", None)
            eta_values.append(max(0, int(eta_fn() if callable(eta_fn) else 0)))
        eta = min(eta_values) if eta_values else 0
        lines.append(f"THREAT: APPROACH ETA~{eta}")
        return

    for assault in approaches:
        eta = max(0, int(assault.eta_ticks()))
        lines.append(f"THREAT: {assault.target} ETA~{eta}")


def _append_recovery_windows(lines: list[str], state: GameState, fidelity: str) -> None:
    windows = state.sector_recovery_windows
    if not windows:
        return
    if fidelity == "LOST":
        return

    lines.append("RECOVERY:")
    ordered = sorted(windows.items(), key=lambda item: item[0])
    if fidelity == "FULL":
        for sector_name, window in ordered:
            mode = str(window.get("mode", "REMOTE")).upper()
            remaining = max(0, int(math.ceil(float(window.get("remaining", 0.0)))))
            lines.append(f"- {sector_name}: {mode} ({remaining} TICKS)")
        return
    if fidelity == "DEGRADED":
        for sector_name, _window in ordered:
            lines.append(f"- {sector_name}: RECOVERY ACTIVE")
        return
    lines.append("- RECOVERY SIGNATURE DETECTED")


def _append_debug_trace_status(lines: list[str], state: GameState) -> None:
    if not state.dev_mode:
        return
    if not state.dev_trace and not state.assault_trace_enabled:
        return

    lines.append("DEBUG:")
    lines.append("- ASSAULT TRACE: ON")
    lines.append(f"- LEDGER ROWS: {len(state.assault_ledger.ticks)}")
    lines.append("- TRACE LINES EMIT ON WAIT; SUMMARY VIA DEBUG REPORT")


def _render_sector_attention_lines(
    state: GameState,
    sector_status_by_name: dict[str, str],
    *,
    limit: int = 3,
) -> list[str]:
    lines = ["SECTORS:"]
    command_status = sector_status_by_name.get("COMMAND", state.sectors["COMMAND"].status_label())
    lines.append(f"- COMMAND: {command_status}")

    attention: list[tuple[str, str]] = []
    for sector in state.sectors.values():
        if sector.name == "COMMAND":
            continue
        label = sector_status_by_name.get(sector.name, sector.status_label())
        if label in {"COMPROMISED", "DAMAGED", "ALERT"}:
            attention.append((sector.name, label))

    attention.sort(key=lambda item: _sector_priority_by_label(item[1]))
    for name, label in attention[:limit]:
        lines.append(f"- {name}: {label}")

    remaining = max(0, len(attention) - limit)
    if remaining > 0:
        lines.append(f"- +{remaining} OTHER SECTORS REQUIRE REVIEW")
    if not attention:
        lines.append("- ALL OTHER SECTORS STABLE")

    return lines


def _brief_assault_line(state: GameState, fidelity: str) -> str | None:
    approaches = [assault for assault in state.assaults if getattr(assault, "state", "") == "APPROACHING"]
    if not approaches:
        return None
    if fidelity == "LOST":
        return "THREAT: APPROACH SIGNAL LOST"
    if fidelity == "FRAGMENTED":
        return "THREAT: APPROACH SIGNALS DETECTED"

    eta_pairs: list[tuple[str, int]] = []
    for assault in approaches:
        eta_fn = getattr(assault, "eta_ticks", None)
        eta = max(0, int(eta_fn() if callable(eta_fn) else 0))
        target = str(getattr(assault, "target", "UNKNOWN"))
        eta_pairs.append((target, eta))
    if not eta_pairs:
        return "THREAT: APPROACH DETECTED"
    target, eta = min(eta_pairs, key=lambda item: item[1])
    return f"THREAT: {target} ETA~{eta}"


def _brief_repair_line(snapshot: dict, state: GameState, fidelity: str) -> str:
    repairs = snapshot.get("active_repairs", [])
    if not repairs:
        return "REPAIRS: NONE ACTIVE"
    if fidelity == "LOST":
        return "REPAIRS: NO SIGNAL"
    if fidelity == "FRAGMENTED":
        return "REPAIRS: MAINTENANCE SIGNALS DETECTED"

    nearest = min(max(0, int(math.ceil(repair["remaining"]))) for repair in repairs)
    return f"REPAIRS: {len(repairs)} ACTIVE (NEXT COMPLETE ~{nearest} TICKS)"


def _append_policy_state(lines: list[str], state: GameState, fidelity: str) -> None:
    if fidelity == "LOST":
        return

    if fidelity == "FRAGMENTED":
        lines.append("POLICY: SIGNAL FRAGMENTED")
        return

    lines.append("POLICY STATE:")
    if fidelity == "DEGRADED":
        lines.extend(
            [
                "- REPAIR: ACTIVE",
                "- DEFENSE: ACTIVE",
                "- SURVEILLANCE: ACTIVE",
                f"- POWER LOAD: {state.power_load:.2f}",
            ]
        )
        return

    repair = state.policies.repair_intensity
    defense = state.policies.defense_readiness
    surveillance = state.policies.surveillance_coverage
    lines.extend(
        [
            f"- REPAIR INTENSITY: {render_slider(repair)}",
            "- + Faster recovery throughput",
            "- - Higher materials and power drain",
            f"- DEFENSE READINESS: {render_slider(defense)}",
            "- + Stronger tactical response",
            "- - Higher wear and power draw",
            f"- SURVEILLANCE COVERAGE: {render_slider(surveillance)}",
            "- + Better early threat detection",
            "- - Increased brownout pressure",
        ]
    )
    fab_parts = [f"{name}:{value}" for name, value in sorted(state.fab_allocation.items())]
    lines.append("- FAB ALLOCATION: " + " | ".join(fab_parts))
    fortified = [
        f"{name}:{level}" for name, level in state.sector_fort_levels.items() if int(level) > 0
    ]
    if fortified:
        lines.append("- FORTIFICATION: " + " | ".join(sorted(fortified)))
    else:
        lines.append("- FORTIFICATION: NONE")
    lines.append(f"- POWER LOAD: {state.power_load:.2f}")


def _root_causes_and_actions(state: GameState) -> tuple[list[str], list[str]]:
    causes: list[str] = []
    actions: list[str] = []

    command = state.sectors.get("COMMAND")
    if command and command.damage >= COMMAND_CENTER_BREACH_DAMAGE:
        ticks = state.command_breach_recovery_ticks if state.command_breach_recovery_ticks is not None else 0
        causes.append(f"COMMAND BREACH CASCADE ({ticks} TICKS TO FAILURE)")
        actions.append("REPAIR CC_CORE IMMEDIATELY")

    if state.fidelity != "FULL":
        causes.append("COMMS FIDELITY DEGRADED")
        actions.append("RESTORE COMMS POWER OR REPAIR CM_CORE")

    if state.assaults:
        causes.append("HOSTILE APPROACHES INBOUND")
        actions.append("HARDEN OR REALLOCATE DEFENSE")

    if state.materials <= 1:
        causes.append("LOW MATERIAL RESERVES")
        actions.append("SCAVENGE 5X")

    if (
        not state.assaults
        and command
        and command.damage < 0.5
        and state.sectors.get("COMMS")
        and state.sectors["COMMS"].damage < 0.5
        and state.sectors.get("POWER")
        and state.sectors["POWER"].damage < 0.5
    ):
        actions.append("HOLD COMMAND/COMMS/POWER <0.5 DAMAGE TO BLEED THREAT")

    if not causes:
        causes.append("NO CRITICAL PRESSURE DETECTED")
        actions.append("MAINTAIN REPAIRS AND MONITOR APPROACH ETA")

    return causes[:2], actions[:2]


def cmd_status(state: GameState, full: bool = False) -> list[str]:
    """Build compact command status and field tactical status outputs."""

    fidelity = comms_fidelity(state)
    snapshot = state.snapshot()
    state.fidelity = fidelity
    sector_status_by_name = {item["name"]: item["status"] for item in snapshot["sectors"]}

    if state.player_mode == "FIELD":
        return _render_compact_field_view(state, sector_status_by_name)

    if fidelity == "LOST":
        if not full:
            lines = [
                "TIME: ?? | THREAT: UNKNOWN | ASSAULT: NO SIGNAL",
                "SITUATION: INFORMATION UNSTABLE | POSTURE: UNKNOWN",
                "CAUSES: COMMS FIDELITY DEGRADED",
                "ACTIONS: RESTORE COMMS POWER OR REPAIR CM_CORE",
                "REPAIRS: NO SIGNAL",
                "RESOURCES: MATERIALS UNKNOWN",
            ]
            lines.extend(_render_sector_attention_lines(state, sector_status_by_name))
            _append_debug_trace_status(lines, state)
            return lines

        lines = [
            "TIME: ?? | THREAT: UNKNOWN | ASSAULT: NO SIGNAL",
            "POSTURE: - | ARCHIVE: NO SIGNAL",
            "DEFENSE DOCTRINE: NO SIGNAL",
            "READINESS: NO SIGNAL",
            _compute_situation_header(state, sector_status_by_name),
        ]
        _append_debug_trace_status(lines, state)
        lines.extend(["", "SECTORS:"])
        sorted_sectors = sorted(state.sectors.values(), key=_sector_priority)
        stable_header_added = False
        for sector in sorted_sectors:
            marker = MARKERS.get("NO DATA", "?")
            if marker == "." and not stable_header_added:
                lines.append("---")
                stable_header_added = True
            lines.append(f"{sector.name:<12} {marker}")
            state._last_sector_status[sector.name] = "NO DATA"
        return lines

    posture = _system_posture(state, fidelity)

    if not full:
        causes, actions = _root_causes_and_actions(state)
        situation = _compute_situation_header(state, sector_status_by_name).replace("SITUATION: ", "")
        lines = [
            f"TIME: {snapshot['time']} | THREAT: {snapshot['threat']} | ASSAULT: {snapshot['assault']}",
            f"SITUATION: {situation} | POSTURE: {posture} | FIDELITY: {fidelity}",
            "CAUSES: " + " | ".join(causes),
            "ACTIONS: " + " | ".join(actions),
            f"RESOURCES: MATERIALS {snapshot.get('resources', {}).get('materials', 0)}",
            _brief_repair_line(snapshot, state, fidelity),
        ]
        assault_line = _brief_assault_line(state, fidelity)
        if assault_line:
            lines.append(assault_line)
        lines.extend(_render_sector_attention_lines(state, sector_status_by_name))
        _append_debug_trace_status(lines, state)
        return lines

    archive_text = (
        f"{state.archive_losses}/{ARCHIVE_LOSS_LIMIT}"
        if fidelity == "FULL"
        else f"{state.archive_losses}+"
    )

    lines = [
        f"TIME: {snapshot['time']} | THREAT: {snapshot['threat']} | ASSAULT: {snapshot['assault']}",
        f"POSTURE: {posture} | ARCHIVE: {archive_text}",
        f"DEFENSE DOCTRINE: {state.defense_doctrine}",
        "ALLOCATION:",
        f"- PERIMETER: {state.defense_allocation.get('PERIMETER', 1.0):.2f}",
        f"- POWER: {state.defense_allocation.get('POWER', 1.0):.2f}",
        f"- SENSORS: {state.defense_allocation.get('SENSORS', 1.0):.2f}",
        f"- COMMAND: {state.defense_allocation.get('COMMAND', 1.0):.2f}",
        f"READINESS: {state.compute_readiness():.2f}",
        _compute_situation_header(state, sector_status_by_name),
    ]
    causes, actions = _root_causes_and_actions(state)
    lines.append("CAUSES:")
    lines.extend(f"- {cause}" for cause in causes)
    lines.append("ACTIONS:")
    lines.extend(f"- {action}" for action in actions)
    _append_assault_eta(lines, state, fidelity)

    if fidelity == "FULL":
        lines.append(f"SEED: {state.seed}")

    resources = snapshot.get("resources", {})
    lines.extend(
        [
            "",
            "RESOURCES:",
            f"- MATERIALS: {resources.get('materials', 0)}",
        ]
    )
    _append_repairs(lines, snapshot, state, fidelity)
    _append_recovery_windows(lines, state, fidelity)
    _append_policy_state(lines, state, fidelity)
    _append_debug_trace_status(lines, state)

    lines.extend(["", "SECTORS:"])
    sorted_sectors = sorted(state.sectors.values(), key=_sector_priority)
    stable_header_added = False
    for sector in sorted_sectors:
        current = sector_status_by_name.get(sector.name, sector.status_label())
        marker = MARKERS.get(current, ".")
        if marker == "." and not stable_header_added:
            lines.append("---")
            stable_header_added = True

        delta = ""
        prev = state._last_sector_status.get(sector.name)
        if prev and current != prev:
            if _sector_priority_by_label(current) < _sector_priority_by_label(prev):
                delta = " (+)"
            else:
                delta = " (-)"
        lines.append(f"{sector.name:<12} {marker}{delta}")
        state._last_sector_status[sector.name] = current
        if fidelity == "FULL":
            sector_structures = [s for s in state.structures.values() if s.sector == sector.name]
            for structure in sector_structures:
                lines.append(f"  - {structure.id} {structure.state.value}")

    return lines
