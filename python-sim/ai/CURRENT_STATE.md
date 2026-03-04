# CURRENT STATE — CUSTODIAN

## Runtime Status

- **Engine:** Godot 4.x (new development target)
- **Project Status:** FOUNDATION PHASE — core project structure being established
- **Architecture:** Godot-authoritative, fixed-step simulation
- **Primary Interface:** Isometric real-time gameplay (WASD operator)
- **Secondary Interface:** Terminal (deprecated, preserved for debug)

---

## Godot Project (In Development)

### Current Focus

1. **Godot Project Setup**
   - Project structure creation
   - Scene hierarchy foundation
   - Isometric camera implementation

2. **Operator Controller**
   - WASD movement within sectors
   - Collision detection
   - Weapon slot system

3. **Combat Prototype**
   - Hitscan weapon system
   - Projectile system
   - Damage pipeline

---

## Legacy Terminal Implementation (Preserved for Reference)

The Python terminal implementation is deprecated but preserved at:

- `custodian-terminal/` — Terminal UI files
- `game/simulations/world_state/` — Python simulation core

These are **not** the primary development target. They remain for:
- Debug/diagnostic reference
- Deterministic behavior testing
- Legacy feature documentation

---

## Implemented (Legacy / Reference)

The following were implemented in the Python terminal phase and need reimplementation in Godot:

- Command parser and processor
- Spatial assault with approach traversal
- Policy/doctrine/allocation/fabrication layers
- Comms fidelity-driven information degradation
- ARRN relay progression system
- Deterministic seeded world simulation
- Ambient event and procgen systems

---

## Godot Command Surface (Target)

- **Movement:** WASD continuous movement
- **Combat:** Left-click (ranged), Right-click (melee), E (utility)
- **Pause:** Spacebar / Escape (FTL-style hard pause)
- **Camera:** Edge pan, middle mouse pan, scroll zoom

---

## Known Gaps (Godot Phase)

- No Godot scenes created yet
- No operator controller
- No combat system
- No sector navigation
- No assault waves
- No infrastructure simulation (power, logistics, fabrication)
- No save system

---

## Locked Behavior Notes

- Godot is fully authoritative
- Fixed-step simulation (60Hz or 30Hz)
- FTL-style pause freezes all simulation
- Time scaling: 1x, 2x, 4x (all deterministic)
- Save anywhere, including mid-assault

---

## Documentation Structure

- `design/MASTER_DESIGN_DOCTRINE.md` — **LOCKED** master reference
- `design/*` — Design documents
- `ai/*` — AI session context files
- `custodian-terminal/` — Deprecated terminal UI
- `game/simulations/world_state/` — Deprecated Python simulation
