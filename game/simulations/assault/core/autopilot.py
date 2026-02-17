def run_autopilot(sector, doctrine: str = "BALANCED", defense_bias: float = 1.0):
    if not sector.has_hostiles():
        return

    output_mult = 1.0
    if doctrine == "AGGRESSIVE":
        output_mult = 1.2
    elif doctrine == "SENSOR_PRIORITY":
        output_mult = 0.9
    output_mult *= max(0.75, min(1.25, defense_bias))

    for defense in sector.defenses:
        original = defense.effective_output
        defense.effective_output = original * output_mult
        defense.activate(sector.enemies)
        defense.effective_output = original
