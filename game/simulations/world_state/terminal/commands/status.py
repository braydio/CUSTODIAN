"""STATUS command handler."""

from game.simulations.world_state.core.config import ARCHIVE_LOSS_LIMIT, SECTOR_DEFS
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState


def cmd_status(state: GameState) -> list[str]:
    """Build the locked STATUS report output."""

    comms_status = state.sectors["COMMS"].status_label()
    snapshot = state.snapshot()
    focus_lookup = {sector["id"]: sector["name"] for sector in SECTOR_DEFS}
    resources = snapshot.get("resources", {})
    if comms_status == "COMPROMISED":
        lines = [
            "TIME: ??",
            "THREAT: UNKNOWN",
            "ASSAULT: NO SIGNAL",
            "",
            "ARCHIVE STATUS: NO SIGNAL",
            "",
            "RESOURCES:",
            f"- MATERIALS: {resources.get('materials', 0)}",
            "",
            "SECTORS:",
        ]
        for sector in snapshot["sectors"]:
            status = "NO DATA" if sector["name"] != "COMMS" else "COMPROMISED"
            lines.append(f"{sector['name']}: {status}")
        return lines

    lines = [
        f"TIME: {snapshot['time']}",
        f"THREAT: {snapshot['threat']}",
        f"ASSAULT: {snapshot['assault']}",
        "",
    ]

    if comms_status == "DAMAGED":
        lines[1] = "THREAT: ELEVATED"
        lines[2] = "ASSAULT: UNKNOWN"
        lines.append("SYSTEM POSTURE: ACTIVE")
        lines.append("ARCHIVE STATUS: DEGRADED")
        lines.extend(
            [
                "",
                "RESOURCES:",
                f"- MATERIALS: {resources.get('materials', 0)}",
            ]
        )
        if state.active_repairs:
            lines.append("REPAIRS: ACTIVE")
        lines.extend(
            [
                "",
                "SECTORS:",
            ]
        )
        for sector in snapshot["sectors"]:
            status = "STABLE"
            if sector["status"] in {"ALERT", "DAMAGED", "COMPROMISED"}:
                status = "ACTIVITY DETECTED"
            lines.append(f"{sector['name']}: {status}")
        return lines

    if comms_status == "ALERT":
        lines[2] = "ASSAULT: UNSTABLE"
        lines.append("SYSTEM POSTURE: FOCUSED")
        loss_floor = state.archive_losses if state.archive_losses > 0 else 0
        lines.append(f"ARCHIVE LOSSES: {loss_floor}+")
        lines.extend(
            [
                "",
                "RESOURCES:",
                f"- MATERIALS: {resources.get('materials', 0)}",
            ]
        )
        if state.active_repairs:
            lines.append("REPAIRS: ACTIVE")
        lines.extend(
            [
                "",
                "SECTORS:",
            ]
        )
        for sector in snapshot["sectors"]:
            status = sector["status"]
            if status == "DAMAGED":
                status = "UNSTABLE"
            lines.append(f"{sector['name']}: {status}")
        return lines

    if state.hardened:
        posture = "HARDENED"
    elif state.focused_sector:
        focused_name = focus_lookup.get(state.focused_sector, "UNKNOWN")
        posture = f"FOCUSED ({focused_name})"
    else:
        posture = "ACTIVE"
    lines.append(f"SYSTEM POSTURE: {posture}")
    lines.append(f"ARCHIVE LOSSES: {state.archive_losses}/{ARCHIVE_LOSS_LIMIT}")
    lines.extend(
        [
            "",
            "RESOURCES:",
            f"- MATERIALS: {resources.get('materials', 0)}",
        ]
    )
    if state.active_repairs:
        lines.append("REPAIRS:")
        for repair in snapshot.get("active_repairs", []):
            structure = state.structures.get(repair["id"])
            name = structure.name if structure else repair["id"]
            lines.append(f"- {repair['id']} {name}: {repair['ticks']} TICKS REMAINING")
    lines.extend(
        [
            "",
            "SECTORS:",
        ]
    )
    for sector in snapshot["sectors"]:
        lines.append(f"{sector['name']}: {sector['status']}")
        if comms_status == "STABLE":
            sector_structures = [
                s for s in state.structures.values() if s.sector == sector["name"]
            ]
            for structure in sector_structures:
                lines.append(
                    f"    * {structure.id} {structure.name}: {structure.state.value}"
                )
    return lines
