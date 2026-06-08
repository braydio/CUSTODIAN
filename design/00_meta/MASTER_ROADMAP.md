# MASTER ROADMAP DESIGN

**Project:** CUSTODIAN  
**Created:** 2026-04-04  
**Status:** active  
**Last Updated:** 2026-06-07

---

## Purpose

This is the **single source of truth** for CUSTODIAN feature planning. All new features, systems, and milestones must be added here first before implementation begins.

---

## Adding New Features

### Process

```
[new idea/request]
        │
        ▼
┌───────────────────┐
│ Check this doc   │  ← MANDATORY FIRST STEP
│ (MASTER_ROADMAP) │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Feature exists?   │
│ - YES → Update    │
│ - NO → Create     │
│   new entry       │
└───────────────────┘
        │
        ▼
[Add to appropriate milestone]
        │
        ▼
[Create design doc]
        │
        ▼
[Implement]
```

### When to Add

- **New feature request** → Add to roadmap BEFORE design doc
- **Bug fix with design impact** → Add to roadmap if it changes system behavior
- **Technical debt** → Add to appropriate milestone
- **Research/spike** → Add as research task, convert to feature on completion

---

## Roadmap Structure

### Milestones

Milestones are major release checkpoints. Each has:
- **Target date** (soft)
- **Status** (backlog → planned → design → in_progress → complete)
- **Feature list** (linked to design docs)
- **Dependencies** (prerequisites)

### Feature Entry Format

```markdown
### [Feature Name]
**Doc:** `path/to/design.md`  
**Status:** backlog | planned | design | in_progress | complete  
**Priority:** P0 (critical) | P1 (high) | P2 (medium) | P3 (low)  
**Depends on:** [other features or none]  

**Summary:** 1-2 sentences on what this feature does

**Subtasks:**
- [ ] Subtask 1
- [ ] Subtask 2
```

### Status Legend

| Status | Meaning |
|--------|---------|
| backlog | Not yet scheduled |
| planned | Scheduled for future milestone |
| design | Design doc in progress |
| in_progress | Actively being implemented |
| complete | Implemented and verified |

### Priority Legend

| Priority | Meaning |
|----------|---------|
| P0 | Blocker / Core functionality - must ship |
| P1 | Important but not blocking |
| P2 | Nice to have |
| P3 | Future consideration |

---

## Current Roadmap

### Milestone v0.3.0 - Procgen Handoff Fixes
**Target:** TBD (remaining: shadow + weapon data integration)  
**Status:** in_progress

| Feature | Status | Priority |
|---------|--------|----------|
| Camera derives bounds from ProcGenRuntime | complete | P0 |
| Camera snaps to player spawn on load | complete | P0 |
| Terminal repositioned to procgen coords | complete | P1 |
| Ammo caches repositioned to procgen coords | complete | P1 |
| Camera joins "camera" group | complete | P0 |
| Mouse aim uses correct world position | complete | P1 |
| Shadow system integration | pending | P2 |
| Weapon data system integration | pending | P2 |

---

### Milestone v0.4.0 - Mission State Machine
**Target:** 2026-04-01  
**Status:** planned

| Feature | Status | Priority |
|---------|--------|----------|
| GameState phase enum | planned | P0 |
| Phase transition logic | planned | P0 |
| WaveManager phase binding | planned | P1 |
| Phase indicator in HUD | planned | P2 |

**Depends on:** v0.3.0

---

### Milestone v0.5.0 - Free-Roam Pre-Assault
**Target:** 2026-04-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Traverse procgen compound | design | P0 |
| Scavenge/pickup system | design | P1 |
| Resource collection & fabrication | design | P1 |
| Power routing between structures | design | P1 |
| Fortification placement | design | P1 |
| Terminal prep commands | design | P1 |
| Manual assault trigger | design | P0 |

**Doc:** `02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`  
**Depends on:** v0.4.0

---

### Milestone v0.6.0 - Compound Sectors as Entities
**Target:** 2026-04-30  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| COMMAND sector as entity | design | P0 |
| POWER sector as entity | design | P0 |
| DEFENSE sector as entity | design | P1 |
| FABRICATION sector as entity | design | P1 |
| Sector damage integration | design | P0 |

**Doc:** `02_features/sector_damage/implementation.md`

---

### Milestone v0.7.0 - ARRN (Relay Network)
**Target:** 2026-04-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| ARRN Manager & data model | design | P1 |
| Relay entities (4 nodes) | design | P1 |
| SCAN RELAYS command | design | P1 |
| STABILIZE RELAY interaction | design | P1 |
| SYNC & knowledge progression | design | P1 |
| Tick/decay system | design | P2 |
| Benefit activation (7 unlocks) | design | P2 |

**Doc:** `02_features/arrn/implementation.md`

---

### Milestone v0.8.0 - World Expansion & The Hub
**Target:** 2026-05-30  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| World Manager system | design | P1 |
| Hub data structures | design | P1 |
| Scenario generation (seed-based) | design | P1 |
| Terminal Hub UI | design | P1 |
| Compound tiles (wall entities) | design | P0 |
| Power conduit walls | design | P0 |
| Region world generation | design | P2 |

**Doc:** `02_features/world_expansion/implementation.md`

---

### Milestone v0.9.0 - Animation & Polish
**Target:** 2026-03-30  
**Status:** in_progress

| Feature | Status | Priority | Source |
|---------|--------|----------|--------|
| Reload state animation | in_progress | P2 | Design doc |
| Reload state with movement speed penalty | **NEW - design** | P1 | GAMEPLAY_NOTES.md |
| Interact state animation | in_progress | P2 | Design doc |
| Pickup state animation | in_progress | P2 | Design doc |
| Repair state animation | planned | P2 | Design doc |
| Crouch state animation | planned | P3 | Design doc |
| Walk NW animation bounce fix | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Animation base idle | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Animation base stance (melee/ranged) | **NEW - backlog** | P2 | GAMEPLAY_NOTES.md |
| Shadow system | pending | P2 | Design doc |
| **Operator sidearm draw/fire animation** | complete | P1 | Pipeline — 32 sheets (4 layers × 4 diagonal dirs × draw+fire) wired to modular frame system |
| **Marine dash 128×128 split-phase** | complete | P1 | Pipeline — 3-phase charge/inflight/recovery from 156px single strip; only E direction available |
| **Operator sidearm: remaining directions** | backlog | P2 | N, S, E, W cardinal directions needed for all 4 layers × 2 actions = 32 missing sheets |
| **Operator sidearm: reload animation** | backlog | P3 | No dedicated reload art exists |
| **Operator sidearm: recovery animation** | backlog | P3 | No recovery art after firing |
| **Marine dash: 8-direction split art** | backlog | P2 | Currently only E direction; needs SE/SW/NE/NW/N/S/W to match idle coverage |

**Docs:** `02_features/operator/implementation.md`, `02_features/shadow/implementation.md`

---

### Milestone v0.9.1 - Gameplay Bug Fixes (NEW)
**Target:** 2026-04-07  
**Status:** planned

| Feature | Status | Priority | Source |
|---------|--------|----------|--------|
| Spawn collision prevention | planned | P1 | GAMEPLAY_NOTES.md - Run 002 |
| Sector visual differentiation | planned | P2 | GAMEPLAY_NOTES.md - Run 002 |
| Command terminal live minimap | planned | P1 | GAMEPLAY_NOTES.md - Run 001 |
| Reduce assault waves to 3-5 for testing | planned | P2 | GAMEPLAY_NOTES.md - Run 001 |

**Note:** These are quick fixes/improvements from gameplay notes that don't warrant a full milestone but need tracking.

**Docs:** 
- `01_systems/COMMAND_TERMINAL_UI.md`
- `03_architecture/COMPOUND_TILE_SYSTEM.md`

---

### Milestone v1.0 - Power & Logistics Systems
**Target:** 2026-05-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Power generation | design | P1 |
| Power routing | design | P0 |
| Load management | design | P1 |
| Blackout mechanics | design | P1 |
| Logistics economy | design | P2 |
| Fabrication system | design | P2 |

**Doc:** `02_features/power/POWER_SYSTEMS_GODOT.md`

---

### Milestone v1.1 - Vehicle System
**Target:** 2026-06-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| ControllableActor interface | design | P0 |
| VehicleBase class | design | P0 |
| Player controller routing | design | P0 |
| Enter/exit mechanics | design | P0 |
| Light Hover Buggy archetype | design | P1 |
| Vehicle health/destruction | design | P1 |
| Vehicle weapon integration | design | P1 |

**Doc:** `02_features/vehicles/implementation.md`  
**Depends on:** Combat system, Repair mechanics, Free-roam (v0.5.0)

---

### Milestone v1.2 - Command Terminal UI
**Target:** 2026-07-15  
**Status:** design

| Feature | Status | Priority |
|---------|--------|----------|
| Four-zone layout (Header, Nav, Content, Transcript) | design | P0 |
| 12-page terminal structure | design | P0 |
| Information fidelity system | design | P0 |
| Boot sequence flow | design | P1 |
| Mode-dependent behavior (Hub/Command/Field) | design | P1 |
| Power routing page | design | P0 |
| Sector management page | design | P0 |
| Archive/knowledge system page | design | P1 |
| Command palette | design | P2 |

**Doc:** `02_features/terminal/COMMAND_TERMINAL_SPEC.md`  
**Depends on:** Power routing (v1.0), Free-roam (v0.5.0)

---

### Backlog

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Save system | backlog | P1 | Campaign persistence |
| Contract history | backlog | P2 | Track completed |
| Player progress (XP/unlocks) | backlog | P2 | Progression |
| Resource economy | backlog | P2 | Credits, materials |
| Market/trade system | backlog | P3 | Buy/sell |

---

## Completed Milestones

| Milestone | Completed | Notes |
|-----------|-----------|-------|
| Wave spawning system | 2026-03-08 | Lane spawns, variants |
| Enemy director | 2026-03-08 | Threat, budget, routing |
| Turret system | 2026-03-06 | 4 archetypes |
| Player ranged combat | 2026-03-10 | Ammo, cooldowns |
| Player melee combat | 2026-03-12 | Timing, hit-stop |
| Sprint & stamina | 2026-03-10 | Stamina HUD |
| Repair gameplay | 2026-03-07 | Hold repair |
| Supply drops | 2026-03-11 | Resource drops |
| Contract world loader | 2026-03-14 | Procgen promotion |
| Runtime wall collision | 2026-03-15 | Explicit colliders |

---

## Design Doc Integration

Every feature in the roadmap must have:

1. **Design doc** in `design/` folder
2. **Implementation code** in `design/features/implementation/` (as proposal)
3. **Status field** matching roadmap status

### Doc Path Convention

```
design/
├── 00_meta/
│   └── MASTER_ROADMAP.md          ← THIS FILE
├── 01_systems/                    ← Core systems
├── 02_features/                    ← Feature specs
│   └── [feature]/
│       └── implementation.md
├── 03_architecture/               ← High-level design
└── 04_research/                   → Spike/research
```

### Linking Format

Every design doc must include:

```markdown
**Roadmap:** [Milestone name - Feature name]
**Status:** [status from roadmap]
**Depends on:** [other features or none]
```

---

## Quick Reference

### Adding a Feature

1. Read this MASTER_ROADMAP.md first
2. Check if feature already exists
3. If new: add to appropriate milestone
4. Create design doc
5. Link design doc in roadmap entry

### Updating Status

1. Update status in this MASTER_ROADMAP.md
2. Update status in design doc

### Finding Design Docs

- Search `design/02_features/[feature_name]/`
- Check `design/features/implementation/` for code

---

## Reference Files

| File | Purpose |
|------|---------|
| `TEMPLATE_SYSTEM.md` | System design template |
| `TEMPLATE_FEATURE.md` | Feature design template |

---

*All new features must be added to this MASTER_ROADMAP.md first. This is the single source of truth.*
