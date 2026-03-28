# CUSTODIAN Design Documentation

**Project:** CUSTODIAN - Godot-based tactical wave defense with procgen contracts  
**Last Updated:** 2026-03-27

---

## Directory Structure

```
design/
├── README.md                      # This file - index & overview
├── ROADMAP.md                     # Master roadmap & milestone tracking
├── TRACKING.md                    # Sprint backlog, issues, progress
│
├── architecture/                  # High-level architecture docs
│   ├── PROJECT_STATUS.md
│   └── SIZING_STRATEGY.md
│
├── systems/                      # Core system designs
│   ├── COMMAND_TERMINAL_UI.md
│   ├── CAMERA_SYSTEM.md
│   ├── CAMERA_COMBAT_INTEGRATION.md
│   └── ROADMAP_COMMAND_TERMINAL.md
│
├── features/
│   ├── implementation/           # Active implementation docs
│   │   ├── FREE_ROAM_PRE_ASSAULT_WALKTHROUGH.md
│   │   ├── OPERATOR_ANIMATION_STATE_MACHINE.md
│   │   ├── SHADOW_SYSTEM_IMPLEMENTATION.md
│   │   └── WEAPON_DATA_INTEGRATION.md
│   │
│   └── specifications/           # Feature specs (pre-implementation)
│       ├── ANIMATION_REQUIREMENTS.md
│       ├── ANIMATION_SYSTEM_MIGRATION.md
│       ├── ATTACK_HIT_TIMING.md
│       ├── PLACEABLE_TURRETS.md
│       ├── SHADOW_SYSTEM.md
│       └── UPGRADE_FIGHT_MECHANICS.md
│
├── research/                     # Research & exploration docs
│   ├── DEERFLOW_AUTONOMOUS_CONTENT_SYSTEM.md
│   ├── EDGAR_ROOM_TEMPLATE_SYSTEM.md
│   └── DRONE_ASSETS_NEEDED.md
│
└── templates/                    # Document templates
    ├── TEMPLATE_FEATURE.md
    ├── TEMPLATE_SYSTEM.md
    └── TEMPLATE_IMPLEMENTATION.md
```

---

## Quick Reference

| Category | Path | Purpose |
|----------|------|---------|
| **Current Status** | `ROADMAP.md` | Master roadmap with milestones |
| **Active Tasks** | `TRACKING.md` | Sprint backlog, issues, progress |
| **Core Systems** | `systems/` | Terminal, contracts, waves, turrets |
| **Feature Implementation** | `features/implementation/` | Active dev docs |
| **Architecture** | `architecture/` | High-level design decisions |

---

## Workflow

### Starting New Work

1. **Check TRACKING.md** for existing tasks/issues
2. **Create feature doc** in `features/specifications/` (if new)
3. **Create implementation doc** in `features/implementation/` (if in dev)
4. **Update ROADMAP.md** with milestone alignment
5. **Update TRACKING.md** with task entry

### Document Naming

- **Systems:** `[SYSTEM]_SYSTEM.md` - Core system design
- **Features:** `[FEATURE]_SPEC.md` - Pre-implementation spec
- **Implementation:** `[FEATURE]_IMPLEMENTATION.md` - In-dev documentation
- **Research:** `[TOPIC]_RESEARCH.md` - Exploration notes

### Status Labels

| Status | Meaning |
|--------|---------|
| `draft` | Work in progress, incomplete |
| `active` | Currently being implemented |
| `review` | Implementation complete, awaiting review |
| `complete` | Done and integrated |
| `blocked` | Waiting on dependency |
| `deprecated` | Superseded by newer doc |

---

## Active Focus (2026-03-27)

**Priority 1 - Procgen Handoff Fixes:**
- Camera bounds from procgen map (not legacy sectors)
- Camera snap to procgen player spawn
- Reposition terminal/ammo caches to procgen coords
- Register camera to "camera" group for game feel

**Priority 2 - Mission Flow:**
- Mission state machine implementation
- Free-roam pre-assault loop
- Manual assault trigger via terminal

**Priority 3 - Polish:**
- Animation state machine completion
- Shadow system integration
- Weapon data system

---

## Key Links

- **Godot Project:** `custodian/`
- **Assets:** `custodian/assets/`
- **Scenes:** `custodian/scenes/`
- **Scripts:** `custodian/scripts/`
- **Runtime Procgen:** `custodian/procgen/`

---

*Use `TRACKING.md` for day-to-day task management and `ROADMAP.md` for milestone planning.*
