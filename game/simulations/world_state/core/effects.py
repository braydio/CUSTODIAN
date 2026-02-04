from .config import CRITICAL_SECTORS


EFFECT_DECAY_MIN = 0.01


def add_sector_effect(sector, key, severity, decay=0.03):
    existing = sector.effects.get(key)
    if existing:
        existing["severity"] = max(existing["severity"], severity)
        existing["decay"] = max(existing["decay"], decay)
        return
    sector.effects[key] = {"severity": severity, "decay": decay}


def add_global_effect(state, key, severity, decay=0.02):
    existing = state.global_effects.get(key)
    if existing:
        existing["severity"] = max(existing["severity"], severity)
        existing["decay"] = max(existing["decay"], decay)
        return
    state.global_effects[key] = {"severity": severity, "decay": decay}


def apply_sector_effects(state, sector):
    to_remove = []
    for key, data in sector.effects.items():
        severity = data["severity"]
        if key == "power_drain":
            sector.power = max(0.2, sector.power - 0.02 * severity)
        elif key == "structural_fatigue":
            sector.damage += 0.01 * severity
        elif key == "alertness_residue":
            sector.alertness += 0.03 * severity
        elif key == "coolant_leak":
            sector.power = max(0.3, sector.power - 0.015 * severity)
            sector.damage += 0.01 * severity
        elif key == "sensor_blackout":
            sector.alertness += 0.02 * severity
            if sector.name in CRITICAL_SECTORS:
                state.ambient_threat += 0.02 * severity

        data["severity"] = max(0.0, severity - max(data["decay"], EFFECT_DECAY_MIN))
        if data["severity"] <= 0.0:
            to_remove.append(key)

    for key in to_remove:
        sector.effects.pop(key, None)


def apply_global_effects(state):
    to_remove = []
    for key, data in state.global_effects.items():
        severity = data["severity"]
        if key == "signal_interference":
            state.ambient_threat += 0.015 * severity
        elif key == "supply_strain":
            state.ambient_threat += 0.01 * severity

        data["severity"] = max(0.0, severity - max(data["decay"], EFFECT_DECAY_MIN))
        if data["severity"] <= 0.0:
            to_remove.append(key)

    for key in to_remove:
        state.global_effects.pop(key, None)
