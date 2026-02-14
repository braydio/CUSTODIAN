"""STATUS command handler."""

from game.simulations.world_state.core.config import ARCHIVE_LOSS_LIMIT, SECTOR_DEFS
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


def _compute_situation_header(state: GameState) -> str:
    degraded = []
    for sector in state.sectors.values():
        label = sector.status_label()
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


def _render_compact_field_view(state: GameState) -> list[str]:
    lines = []
    lines.append(f"LOCATION: {state.player_location}")
    lines.append(f"FIDELITY: {state.fidelity}")
    lines.append("")

    sorted_sectors = sorted(state.sectors.values(), key=_sector_priority)
    stable_header_added = False
    for sector in sorted_sectors:
        label = sector.status_label()
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


def cmd_status(state: GameState) -> list[str]:
    """Build compact command status and field tactical status outputs."""

    fidelity = comms_fidelity(state)
    snapshot = state.snapshot()
    state.fidelity = fidelity

    if state.player_mode == "FIELD":
        return _render_compact_field_view(state)

    if fidelity == "LOST":
        lines = [
            "TIME: ?? | THREAT: UNKNOWN | ASSAULT: NO SIGNAL",
            "POSTURE: - | ARCHIVE: NO SIGNAL",
            _compute_situation_header(state),
            "",
            "SECTORS:",
        ]
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
    archive_text = (
        f"{state.archive_losses}/{ARCHIVE_LOSS_LIMIT}"
        if fidelity == "FULL"
        else f"{state.archive_losses}+"
    )

    lines = [
        f"TIME: {snapshot['time']} | THREAT: {snapshot['threat']} | ASSAULT: {snapshot['assault']}",
        f"POSTURE: {posture} | ARCHIVE: {archive_text}",
        _compute_situation_header(state),
    ]

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

    lines.extend(["", "SECTORS:"])
    sorted_sectors = sorted(state.sectors.values(), key=_sector_priority)
    stable_header_added = False
    for sector in sorted_sectors:
        current = sector.status_label()
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

    return lines
