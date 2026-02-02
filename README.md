# PROJECT: CUSTODIAN

Lightweight game simulation prototypes centered on a sole survivor defending a static command post in a collapsed interstellar civilization. The campaign goal is reconstruction and knowledge preservation over extermination.

## Core

- You are the last relic of a lost institution maintaining a static command post.
- Information systems are gone; history is fragmented.
- Enemies are driven by ideology, scarcity, and misunderstanding.
- Victory is survival reconstruction of physical artifacts and lost knowledge.

## High-Level Loop

```
Recon / Expedition
        ↓
Return with knowledge + materials
        ↓
Build / reinforce base sectors
        ↓
Assault (defense under pressure)
        ↓
Repair, recover, adapt
        ↓
Repeat until campaign objective achieved or lost
```

## Campaign Structure (Tutorial)

- Setting: destroyed military airfield on the home planet.
- Objective: rebuild a ship to reach the Archive Hub.
- Persistence: knowledge and schematics persist; materials and construction are fragile.

## Base Form Factor (Tutorial)

- Static, asymmetrical outpost with 10 sectors.
- Two critical sectors:
  - Command Center (tactical control when present; loss = battle lost)
  - Goal Sector (campaign objective; loss = campaign failure)
- Eight peripheral sectors:
  - Main Terminal
  - Security Gate / Checkpoint
  - Hangar A
  - Hangar B
  - Fuel Depot
  - Radar / Control Tower
  - Service Tunnels
  - Maintenance Yard

## Simulations

### World-State Simulation

Models ambient threat, sector instability, and periodic major assaults. Events are procedural but remain consistent with the theme by generating a hostile profile (ideology + form + tech expression) and building an event catalog around it.

Entry point:

```bash
python game/simulations/world-state/simulate-world.py
```

Docs:

- `docs/Broad_Overview_Design_Rules.md`
- `docs/SystemDesign.md`
- `docs/PROJECT_MAP.md`
- `game/simulations/world-state/docs/world-state-simulation.md`

Key files:

- `game/simulations/world-state/world_state/config.py`
- `game/simulations/world-state/world_state/events.py`
- `game/simulations/world-state/world_state/assaults.py`
- `game/simulations/world-state/world_state/state.py`

### Assault Simulation

Focused assault-resolution prototype and data packs.

Entry point:

```bash
python game/simulations/assault/simulate_assault.py
```

Key files:

- `game/simulations/assault/core/assault.py`
- `game/simulations/assault/core/autopilot.py`
- `game/simulations/assault/data/`

## Documentation Map

- `docs/Broad_Overview_Design_Rules.md`: core fantasy, procedural generation logic, campaign arc.
- `docs/SystemDesign.md`: systems breakdown and implementation priorities.
- `docs/PROJECT_MAP.md`: tutorial campaign layout and sector rules.
- `docs/CommandCenter.md`: command center behavior and tactical role.
- `docs/Tutorial_Details.md`: tutorial-specific sequencing.

## Tone & Style

- Operational, perimeter-defense language.
- Terse, grounded output.
- Keep code simple and data-driven; avoid unnecessary abstraction.

## Testing & Validation

No automated tests yet. When noting validation, describe the manual run (for example, “ran `python game/simulations/world-state/simulate-world.py` and reviewed output”).
