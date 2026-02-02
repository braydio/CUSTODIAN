def run_autopilot(sector):
    if not sector.has_hostiles():
        return

    for defense in sector.defenses:
        defense.activate(sector.enemies)
