# PROJECT: CUSTODIAN

A 2.5D isometric real-time tactical base defense game built on Godot 4.x.

> CUSTODIAN is not about winning campaigns.
> It is about deciding what must be known before it disappears forever.

---

## Core Identity

- You are the last operator inside a failing machine.
- Information systems are gone; history is fragmented.
- Enemies are driven by ideology, scarcity, and misunderstanding.
- Victory is survival & reconstruction of physical artifacts and lost knowledge.
- Campaign victories unlock hub capabilities, archive entries, and scenario access.

---

## High-Level Gameplay Loop

```
Start Campaign
        ↓
Build / Fortify Base
        ↓
Expeditions (knowledge + materials)
        ↓
Real-Time Assault Defense
        ↓
Repair & Recovery
        ↓
Repeat until objective achieved or lost
```

---

## Engine

- **Godot 4.x** — primary game engine
- **2.5D Isometric** — stylized minimal / schematic industrial art
- **Fixed-step simulation** — 60Hz or 30Hz deterministic tick
- **FTL-style pause** — hard pause with command issuing while paused

---

## Operator

Single embodied operator controlled via **WASD**:

- **Melee weapon slot** — close-quarters combat
- **Ranged weapon slot** — hitscan (standard) + projectiles (heavy)
- **Utility tool slot** — repair, relay interface, sector stabilization

---

## Systems (Persistent)

- Power grid simulation
- Logistics throughput model
- Fabrication queue
- Assault wave resolution (real-time)
- Relay stabilization and knowledge progression
- Structural damage propagation

---

## Development

### Godot Project

```
project.godot          # Godot project file
scenes/                # Game scenes
scripts/               # GDScript logic
resources/              # Assets and configurations
```

### Running

```bash
# Open in Godot 4.x editor
# Press F5 to run

# Or export for target platform via Godot export menu
```

### Architecture

```
GameState (pure data)
Systems (pure logic)    # Combat, power, logistics, fabrication
Scene (visual)          # Isometric presentation
Input (commands)        # WASD + pause menu
```

---

## Documentation

- `design/MASTER_DESIGN_DOCTRINE.md` — **LOCKED** master design reference
- `design/00_foundations/` — Foundational design docs
- `design/10_systems/` — System specifications
- `design/20_features/` — Feature specs and implementations
- `design/archive/` — Historical and deprecated docs

---

## Core Design Pillars

1. Reconstruction over extermination
2. Information is power
3. Systems interact visibly
4. Operator embodiment enhances — not replaces — systemic gameplay
5. Tactical pause is a strategic tool
6. Upgrades expand capability, not inflate raw stats
7. The base feels like a machine under stress

---

## Terminal Interface (Deprecated)

The Python terminal interface is **deprecated** and preserved only as a secondary debug/diagnostic interface.

Primary development targets Godot-native gameplay.

---

## Scope Guardrails

**CUSTODIAN IS:**
- Tactical
- Systemic
- Embodied
- Strategic

**CUSTODIAN IS NOT:**
- Squad-based RTS (at launch)
- Action shooter
- Roguelite stat-inflation treadmill
- Pure base-builder sandbox
