# PROJECT: CUSTODIAN

Lightweight game simulation prototypes centered on a sole survivor defending a static command post in a collapsed interstellar civilization. The campaign goal is reconstruction and knowledge preservation over extermination.

## Core

- You are the last relic of a lost institution, custodian to a static command post.
- Information systems are gone; history is fragmented.
- Enemies are driven by ideology, scarcity, and misunderstanding.
- Victory is survival & reconstruction of physical artifacts and lost knowledge.
- Campaign victories unlock < item > in the Hub.
- Victories provide a reward bonus styled after the campaign's procedurally generated target goal

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

## Base Form Factor (Phase 1)

- Static, asymmetrical outpost with 8 sectors.
- Canonical layout sectors:
  - COMMAND (tactical control when present; loss = battle lost)
  - COMMS
  - DEFENSE GRID
  - POWER
  - ARCHIVE (campaign objective; loss = campaign failure)
  - STORAGE
  - HANGAR
  - GATEWAY

## Simulations

### Custodian Terminal UI (Primary Once Wired)

Terminal UI is the primary operator entry point once backend command transport is fully wired.

Entry point:

```bash
python -m game --ui
```

Then visit `http://localhost:7331/`.

Current status:

- Boot stream and terminal shell rendering are active.
- Command transport is wired via `POST /command`.

Key files:

- `custodian-terminal/server.py`
- `custodian-terminal/boot.js`
- `custodian-terminal/terminal.js`

### World-State Simulation

Models ambient threat, sector instability, and periodic major assaults. Events are procedural but remain consistent with the theme by generating a hostile profile (ideology + form + tech expression) and building an event catalog around it.

Entry point:

```bash
python -m game --sim
```

Optional server entry point:

```bash
python game/simulations/world_state/server.py
```

Phase 1 adds a command-driven terminal loop for deterministic control:

```bash
WORLD_STATE_MODE=repl python game/simulations/world_state/sandbox_world.py
```

Usage notes:

- Use `help` to list commands and usage.
- Write commands (for example, `advance`) require Command Center authority.
- Use quotes for multi-word sector names (for example, `sector "Fuel Depot"`).

Docs:

- `docs/README.md`
- `docs/Broad_Overview_Design_Rules.md`
- `docs/SystemDesign.md`
- `docs/PROJECT_MAP.md`
- `game/simulations/world_state/docs/world-state-simulation.md`
- `game/simulations/world_state/docs/terminal-repl.md`
- `docs/ROADMAP.md`

Key files:

- `game/simulations/world_state/core/config.py`
- `game/simulations/world_state/core/events.py`
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/core/state.py`

### Assault Simulation

Focused assault-resolution prototype and data packs.

Entry point:

```bash
python game/simulations/assault/sandbox_assault.py
```

Key files:

- `game/simulations/assault/core/assault.py`
- `game/simulations/assault/core/autopilot.py`
- `game/simulations/assault/data/`

### Custodian Terminal UI

Static terminal UI prototype with boot sequence and live command loop integration.

Entry point:

```bash
python -m game --ui
```

Then visit `http://localhost:7557/`.

Key files:

- `custodian-terminal/boot.js`
- `custodian-terminal/terminal.js`

## Documentation Map

- `docs/README.md`: documentation index and usage notes.
- `docs/Broad_Overview_Design_Rules.md`: core fantasy, procedural generation logic, campaign arc.
- `docs/SystemDesign.md`: systems breakdown and implementation priorities.
- `docs/PROJECT_MAP.md`: tutorial campaign layout and sector rules.
- `docs/CommandCenter.md`: command center behavior and tactical role.
- `docs/Tutorial_Details.md`: tutorial-specific sequencing.
- `docs/ROADMAP.md`: future development plan with next steps.

## Tone & Style

- Operational, perimeter-defense language.
- Terse, grounded output.
- Keep code simple and data-driven; avoid unnecessary abstraction.

## Testing & Validation

Automated tests cover the world-state terminal logic. Run them with:

```bash
python -m pytest
```

When noting validation, describe the manual run (for example, “ran `python -m game --sim` and reviewed output”).
