# Codex Handoff — CUSTODIAN Project Update

**Date:** 2026-03-03
**Status:** Major Architecture Pivot Complete

---

## What Changed

CUSTODIAN has undergone a fundamental architecture pivot. The project is no longer a Python terminal-first simulation with a browser UI. It is now a **Godot 4.x native game**.

### Before
- Python backend simulation (`game/simulations/world_state/`)
- Terminal UI as primary interface (`custodian-terminal/`)
- Backend-authoritative model
- Command-driven time progression (`WAIT`, `WAIT NX`)

### After
- Godot 4.x (Compatibility renderer for 2.5D isometric)
- Native real-time gameplay with WASD operator control
- Godot-authoritative model
- Fixed-step simulation (60Hz) with FTL-style pause
- Terminal preserved only as secondary/debug interface

---

## Project Structure

```
~/Projects/CUSTODIAN/
├── custodian/          # Active Godot development
│   ├── core/          # GameState, Simulation controller
│   ├── entities/      # Operator, enemies
│   ├── scenes/        # Game scenes
│   └── ui/            # Interface
├── python-sim/         # Legacy (deprecated but preserved)
│   ├── game/          # Python simulation (reference only)
│   ├── custodian-terminal/  # Terminal UI (deprecated)
│   └── design/         # All design docs
└── design/            # Moved to python-sim/
```

---

## Outstanding Deliverables — New Approach

The legacy Python implementation had these active workstreams. They now need to be reimplemented in Godot:

### 1. Combat System
- **Legacy:** Terminal command parsing, damage calculation in Python
- **New:** Real-time hitscan + projectile hybrid, WASD operator with weapon slots
- **Priority:** HIGH — Core gameplay loop

### 2. Assault System
- **Legacy:** Spatial approach, multi-tick tactical resolution
- **New:** Real-time enemy spawning, base defense under pressure
- **Priority:** HIGH — Core pressure loop

### 3. Infrastructure Systems (Power, Logistics, Fabrication)
- **Legacy:** Python simulation with terminal commands
- **New:** Real-time system simulation, visible in Godot
- **Priority:** MEDIUM — Systemic depth

### 4. ARRN Relay Network
- **Legacy:** Terminal commands (`SCAN RELAYS`, `STABILIZE`, `SYNC`)
- **New:** In-game relay interaction, knowledge progression
- **Priority:** MEDIUM — Core progression pillar

### 5. Save System
- **Legacy:** Python state serialization
- **New:** Godot-native serialization, mid-assault saves
- **Priority:** HIGH — Required for campaign model

---

## Documents That Need Updates

### Update in Place (in `python-sim/design/`)

| Document | Action |
|----------|--------|
| `MASTER_DESIGN_DOCTRINE.md` | Already updated — this is the LOCKED reference |
| `00_foundations/ARCHITECTURE.md` | Mark as deprecated, reference Godot architecture |
| `00_foundations/CORE_DESIGN_PRINCIPLES.md` | Update timing model, add isometric context |
| `00_foundations/GAME_IDENTITY_LOCK.md` | Add isometric/embodied to locked identity |
| `30_playable_game/RTS_LAYER.md` | Mark deprecated — now primary mode |
| `30_playable_game/PLAYER_CONTROL_MODEL.md` | Update to WASD + pause |
| `30_playable_game/ENGINE_PORT_PLAN.md` | Update for Godot-native |

### Archive (Move to `python-sim/design/archive/terminal-deprecated/`)

- All terminal-specific command docs
- Terminal parser/processor documentation
- `/command` contract docs

### Create New (in `custodian/` or shared)

- Godot project architecture doc
- GDScript coding standards
- Scene hierarchy specification

---

## Immediate Priorities for Codex

1. **Verify Godot project runs** — `cd custodian && godot`
2. **Prototype combat feel** — Get WASD + basic shooting working
3. **Define sector system** — Static base layout per master design
4. **Begin assault implementation** — Basic enemy spawning and approach
5. **Update design docs** — Bring all docs in line with Godot pivot

---

## Key Design References

- **`python-sim/design/MASTER_DESIGN_DOCTRINE.md`** — LOCKED master reference, defines all core decisions
- **Godot project:** `custodian/project.godot` — Configured with Compatibility renderer, 2D physics, WASD input map

---

## Notes

- The Python terminal is NOT being deleted — it's preserved as reference and debug tool
- Deterministic simulation principle is MAINTAINED — fixed-step with deterministic RNG
- All systemic mechanics (power, logistics, fabrication, relays) remain — just reimplemented in Godot
- The "embodied operator" is the key new element — player is NOT just issuing commands

---

Let me know if you need clarification on any of this.
