"""Structure-destruction side effects for world-state assaults."""

from __future__ import annotations

from .effects import add_global_effect


STRUCTURE_LOSS_EFFECTS: dict[str, list[str]] = {
    "CM_CORE": ["comms_core_lost"],
    "DF_CORE": ["defense_core_lost"],
    "FB_TOOLS": ["tools_lost"],
    "PW_CORE": ["power_core_lost"],
    "AR_CORE": ["archive_core_lost"],
}


def apply_structure_destroyed_effects(state, structure_id: str) -> list[str]:
    """Apply deterministic system effects when a structure is destroyed."""

    lines: list[str] = []
    for effect in STRUCTURE_LOSS_EFFECTS.get(structure_id, []):
        if effect == "comms_core_lost":
            add_global_effect(state, "signal_interference", severity=1.0, decay=0.03)
            lines.append("[WARNING] COMMS CORE LOST. SENSOR FIDELITY COLLAPSING.")
            continue
        if effect == "defense_core_lost":
            lines.append("[WARNING] DEFENSE GRID CORE LOST. FIRE CONTROL DEGRADED.")
            continue
        if effect == "tools_lost":
            lines.append("[WARNING] FABRICATION TOOLS LOST. REPAIR SPEED DEGRADED.")
            continue
        if effect == "power_core_lost":
            state.ambient_threat += 0.2
            lines.append("[WARNING] POWER CORE LOST. LOAD SHEDDING CASCADE DETECTED.")
            continue
        if effect == "archive_core_lost":
            lines.append("[WARNING] ARCHIVE CORE LOST. KNOWLEDGE PRESERVATION AT RISK.")
            continue
    return lines
