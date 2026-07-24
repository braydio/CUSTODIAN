# CUSTODIAN Design Documentation

!ATTENTION ASSISTANTS!

! CUSTODIAN - Is not a tactical wave defense. It is more similar to a roguelike/roguelite, real-time tactical, base-builder in a procedurally generated universe. The wave defense style gameplay is for testing only. Production will be continuous. Please be sure to update this anywhere it is referenced (like below, though it is not required that it be as verbose)!

**Project:** CUSTODIAN - Godot-based contract-driven tactical defense / procgen campaign game  
**Last Updated:** 2026-07-08

---

## Directory Structure

```
design/
├── README.md                      # This file - index & overview
│
├── 00_meta/                       # Meta documents (templates, status, tracking)
│   ├── AGENTS.md                  # PAI-OpenCode agent instructions
│   ├── MASTER_ROADMAP.md          # Canonical milestone/feature tracking
│   ├── PROJECT_STATUS.md          # Current project state
│   ├── SIZING_STRATEGY.md
│   ├── TEMPLATE_*.md
│   ├── _ACTIVE_DEPRECATED.md      # Superseded by MASTER_ROADMAP
│   ├── DOCS_DRIFT_REPORT.md       # Canonical doc vs. code integrity tracking
│   ├── TRACKING.md                # Superseded by MASTER_ROADMAP
│   ├── LORE_GAMEPLAY_DUMP.md      # Archived
│   ├── GAME_NOTES.md              # Archived
│   ├── GAME_NOTES_DRAFT.md        # Archived draft
│   ├── GAMEPLAY_NOTES.md          # Incorporated into feature docs
│   ├── PROCGEN_PIPELINE_CORRECTION.md
│   ├── PROCGEN_WALL_COLLISION_FIX.md
│   ├── REQUIRED_ASSETS.md         # Deprecated pointer to root canonical tracker
│   ├── SPRITE_PIPELINE_INSTRUCT.md
│   └── UID_DUPLICATE_FIX.md
│
├── 01_systems/                    # Core system designs
│   ├── CAMERA_SYSTEM.md
│   ├── CAMERA_COMBAT_INTEGRATION.md
│   ├── COMMAND_TERMINAL_UI.md
│   ├── INTEREST_MANAGEMENT_SYSTEM.md
│   ├── NEW_FEATURE_TO_DESIGN-TERMINAL.md
│   ├── ROADMAP_COMMAND_TERMINAL.md
│   ├── SECTOR_HEATMAP_SYSTEM.md
│   ├── TERMINAL_COMMAND_INTERFACE.md
│   ├── WORLD_HISTORY_SYSTEM.md
│   └── WORLD_STATE_GRAPH_SYSTEM.md
│
├── 02_features/                   # Feature specs & implementations
│   ├── allied_units/              # Allied unit designs
│   ├── animation/                 # Animation system
│   ├── arrn/                      # ARRN system
│   ├── assault/                   # Assault/combat design
│   ├── balance/                   # Balance targets
│   ├── combat_feel/               # Combat feel tuning
│   ├── debug_ui/                  # Debug/dev UI
│   ├── enemy_director/            # Enemy wave director
│   ├── enemy_objective/           # Enemy objective system & encounters
│   ├── events/                    # World event designs
│   ├── forest_shrumb/             # Forest Shrumb critter
│   ├── free_roam/                 # Free-roam pre-assault
│   ├── game_over/                 # Game over flow
│   ├── lighting/                  # Lighting system
│   ├── minimap/                   # Tactical minimap spec
│   ├── operator/                  # Operator/player systems
│   ├── pixel_planet/              # Pixel Planet contract system
│   ├── power/                     # Power systems
│   ├── procgen/                   # Procedural generation
│   ├── props/                     # Procedural props
│   ├── repair/                    # Repair mechanics
│   ├── resource_collection/       # Resource harvesting/gathering
│   ├── resource_fabrication/      # Resource fabrication pipeline
│   ├── runtime_camera/            # Runtime camera
│   ├── sector_damage/             # Sector damage
│   ├── shadow/                    # Shadow system
│   ├── terminal/                  # Terminal UI
│   ├── turret/                    # Placeable turrets
│   ├── upgrades/                  # Upgrade system
│   ├── vehicles/                  # Vehicles
│   ├── wave_spawning/             # Wave spawning system
│   ├── weapon_data/               # Weapon data system
│   ├── world_expansion/           # World expansion
│   └── _requests/                 # Feature requests (backlog)
│
├── 03_world/                      # World lore, factions, and content
│   ├── lore/                      # Core lore and hardening
│   ├── factions/                  # Faction profiles
│   └── locations/                 # Location lore
│
├── 04_architecture/               # High-level architecture
│   ├── CAMPAIGN_FLOW_AND_GAME_LOOP.md
│   ├── COMPOUND_TILE_SYSTEM.md
│   ├── HOME_CUSTODIAN_FIELD_TERMINAL.md
│   ├── HUB_CHROMA_PROGRESSION.md
│   ├── HUB_DOCTRINE.md
│   ├── HUB_RETURN_GRAMMAR.md
│   ├── HUB_SPATIAL_LAYOUT.md
│   ├── HUB_SYSTEM_META_PROGRESSION.md
│   ├── INTEGRATION_CONTRACT_GLUE_LAYER.md
│   ├── REGION_GENERATION_SYSTEM.md
│   ├── RUNTIME_WORLD_AND_CAMERA_STABILIZATION.md
│   ├── SIMPLIFIED_POWER_IN_ROOMS.md
│   ├── SPRITE_PIPELINE_SYSTEM.md
│   └── WORLD_TRANSITION_SYSTEM.md
│
├── 05_levels/                     # Level designs & implementations
│   ├── MAP_DESIGN.md
│   ├── SUNDERED_KEEP_CONTINUED.md
│   ├── SUNDERED_KEEP_LARGE_FRONT_GATE.md
│   ├── SUNDERED_KEEP_LEVEL_EXPANSION.md
│   ├── SUNDERED_KEEP_PHASE_1.md
│   ├── SUNDERED_KEEP_VISTA_APPROACH.md
│   ├── SUNDERED_KEEP_ROUTE_STAGES.md
│   ├── SUNDERED_KEEP_WORK.md
│   └── TEMPORALLY_ADRIFT_CASTLE_SET.md
│
├── 06_reference/                  # Research & reference material
│   ├── DRONE_ASSETS_NEEDED.md
│   └── EDGAR_ROOM_TEMPLATE_SYSTEM.md
│
└── 90_codex/                      # Non-runtime idea parking lot and triage system
    ├── README.md                  # Authority boundary and workflow
    ├── 00_index.md                # Idea-card index
    ├── 01_hall_of_great_ideas.md
    ├── 02_backlog.md
    ├── 03_graduated.md
    ├── templates/IDEA_CARD.md
    └── {simulation,ai,world,combat,audio,rendering,animation,tooling,lore,experiments}/
```

---

## Quick Reference

| Category | Path | Purpose |
|----------|------|---------|
| **Meta/Status** | `00_meta/` | Tracking, roadmap, drift reports, archived notes |
| **Core Systems** | `01_systems/` | Terminal, camera, command interface |
| **Features** | `02_features/` | All feature specs and implementations |
| **Feature Requests** | `02_features/_requests/` | Unimplemented feature designs (backlog) |
| **World/Lore** | `03_world/` | World lore, factions, visual references |
| **Architecture** | `04_architecture/` | High-level design decisions |
| **Levels** | `05_levels/` | Level designs and map implementations |
| **Reference** | `06_reference/` | Research and reference material |
| **Idea Codex** | `90_codex/` | Non-runtime idea inventory; not active implementation truth |

---

## Status Labels

| Status | Meaning |
|--------|---------|
| `draft` | Work in progress, incomplete |
| `active` | Currently being implemented |
| `review` | Implementation complete, awaiting review |
| `complete` | Done and integrated |
| `blocked` | Waiting on dependency |
| `deprecated` | Superseded by newer doc |
| `request` | Feature request / pre-design (in `_requests/`) |

---

## Active Focus (2026-07-24)

**Priority 1 - Runtime Polish:**
- Field patch system with audio feedback
- Shrumb drop icon updates
- Combat feel tuning (hit-stop, screen shake, knockback)

**Priority 2 - Procgen Handoff Fixes:**
- Mouse/world aim path validation against procgen camera
- Shadow system integration with dynamic procgen updates

**Priority 3 - Mission Flow:**
- Mission state machine implementation
- Free-roam pre-assault loop
- Compound sectors as real spawned entities

**Priority 4 - Campaign Architecture:**
- ARRN relay network
- World expansion & Hub system
- Power & logistics gameplay

---

## Key Links

- **Godot Project:** `custodian/`
- **Content:** `custodian/content/`
- **Scenes:** `custodian/scenes/`
- **Scripts:** `custodian/game/`
- **Runtime Procgen:** `custodian/game/world/procgen/`

---

*Use `00_meta/MASTER_ROADMAP.md` for both milestone planning and day-to-day task management. `00_meta/TRACKING.md` and `00_meta/_ACTIVE_DEPRECATED.md` are deprecated — see MASTER_ROADMAP.md.*
