# CUSTODIAN Design Documentation

!ATTENTION ASSISTANTS!

! CUSTODIAN - Is not a tactical wave defense. It is more similar to a roguelike/roguelite, real-time tactical, base-builder in a procedurally generated universe. The wave defense style gameplay is for testing only. Production will be continuous. Please be sure to update this anywhere it is referenced (like below, though it is not required that it be as verbose)!

**Project:** CUSTODIAN - Godot-based contract-driven tactical defense / procgen campaign game  
**Last Updated:** 2026-05-27

---

## Directory Structure

```
design/
├── README.md                      # This file - index & overview
│
├── 00_meta/                       # Meta documents (templates, status, tracking)
│   ├── MASTER_ROADMAP.md          # Canonical milestone/feature tracking
│   ├── PROJECT_STATUS.md          # Current project state (as of 2026-05-27)
│   ├── SIZING_STRATEGY.md
│   ├── TEMPLATE_*.md
│   ├── DOCS_DRIFT_REPORT.md       # Canonical doc vs. code integrity tracking
│   ├── LORE_GAMEPLAY_DUMP.md      # Archived - moved from design/ root
│   ├── GAME_NOTES.md              # Archived - superseded by 03_content/
│   ├── GAME_NOTES_DRAFT.md        # Archived - superseded draft
│   └── GAMEPLAY_NOTES.md          # Incorporated into feature docs
│
├── 01_systems/                    # Core system designs
│   ├── COMMAND_TERMINAL_UI.md
│   ├── CAMERA_SYSTEM.md
│   ├── CAMERA_COMBAT_INTEGRATION.md
│   ├── ROADMAP_COMMAND_TERMINAL.md
│   ├── TERMINAL_COMMAND_INTERFACE.md
│   └── NEW_FEATURE_TO_DESIGN-TERMINAL.md    # Expanded terminal design
│
├── 02_features/                   # Feature specs & implementations
│   ├── animation/                 # Animation system
│   ├── arrn/                      # ARRN system
│   ├── assault/                   # Assault/combat design
│   ├── balance/                   # Balance targets
│   ├── combat_feel/               # Combat feel tuning
│   ├── debug_ui/                  # Debug/dev UI
│   ├── enemy_director/            # Enemy wave director
│   ├── enemy_objective/           # Enemy objective system
│   ├── forest_shrumb/             # Forest Shrumb critter (implemented v1)
│   │   ├── SHRUMB_CRITTER_CONSOLIDATED.md
│   │   └── FOREST_SHRUMB_RUNTIME_IMPLEMENTATION.md
│   ├── free_roam/                 # Free-roam pre-assault
│   ├── game_over/                 # Game over flow
│   ├── minimap/                   # Tactical minimap spec
│   │   ├── MINIMAP_SPEC.md
│   │   ├── MINIMAP_SYSTEM.md
│   │   └── MINIMAP_SYSTEM_CODE.md
│   ├── operator/                  # Operator/player systems
│   ├── pixel_planet/              # Pixel Planet contract system
│   ├── power/                     # Power systems
│   ├── procgen/                   # Procedural generation
│   │   ├── AUTHORED_TILED_ROOM_PIPELINE.md
│   │   ├── CURATED_WALL_PERIMETER_PROCGEN.md
│   │   ├── DESTRUCTIBLE_PROCGEN_WALLS.md
│   │   ├── HORIZONTAL_WALL_OVERLAY_TILESET.md
│   │   ├── INDOOR_OUTDOOR_PROCGEN_REGIONS.md
│   │   ├── PROCGEN_WALL_TILE_BRIDGE.md
│   │   ├── STARTER_MAP_PROCGEN.md
│   │   ├── STREAMING_PROCGEN_REVEAL.md
│   │   ├── WALL_TILE_PIPELINE.md
│   │   └── STARTER_MAP_PROCGEN_REFERENCE.png
│   ├── props/                     # Procedural props
│   ├── repair/                    # Repair mechanics
│   ├── resource_collection/       # Resource harvesting/gathering
│   │   └── RESOURCE_COLLECTION_PLAN.md
│   ├── resource_fabrication/      # Resource fabrication pipeline
│   │   ├── RESOURCE_FABRICATION_SYSTEM.md
│   │   └── RESOURCE_FABRICATION_PIPELINE.md
│   ├── runtime_camera/            # Runtime camera
│   ├── sector_damage/             # Sector damage
│   ├── shadow/                    # Shadow system
│   ├── terminal/                  # Terminal UI
│   ├── turret/                    # Placeable turrets
│   ├── upgrades/                  # Upgrade system
│   ├── vehicles/                  # Vehicles
│   │   ├── implementation.md
│   │   └── VEHICLES.md
│   ├── wave_spawning/             # Wave spawning system
│   ├── weapon_data/               # Weapon data system
│   ├── world_expansion/           # World expansion
│   │
│   └── _requests/                 # Feature requests (not yet implemented)
│       ├── ENEMY_FACTORY.md       # Procedural enemy generation factory
│       ├── ENEMY_VARIANT_SYSTEM.md # Enemy variant composition system
│       └── VARIANT_FACTORY.md     # Deterministic variant factory
│
├── 03_architecture/               # High-level architecture
│   ├── CAMPAIGN_FLOW_AND_GAME_LOOP.md
│   ├── COMPOUND_TILE_SYSTEM.md
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
├── 03_content/                    # Canon world/lore/content docs
│   ├── GAME_PROTOCOLS_AND_WORLD_LORE.md
│   ├── PROCEDURAL_LORE_GENERATION.md
│   ├── COLOR_SCHEME.png           # Visual color reference
│   ├── FACTION_PROFILES.md        # Faction lore profiles
│   └── THE_ASH-BELL_CONTINUITY.md # Near-continuity bleed lore
│
└── 04_research/                   # Research & exploration
    ├── DEERFLOW_AUTONOMOUS_CONTENT_SYSTEM.md
    ├── DRONE_ASSETS_NEEDED.md
    └── EDGAR_ROOM_TEMPLATE_SYSTEM.md
```

---

## Quick Reference

| Category | Path | Purpose |
|----------|------|---------|
| **Meta/Status** | `00_meta/` | Tracking, roadmap, drift reports, archived notes |
| **Core Systems** | `01_systems/` | Terminal, camera, command interface |
| **Features** | `02_features/` | All feature specs and implementations |
| **Feature Requests** | `02_features/_requests/` | Unimplemented feature designs (backlog) |
| **Architecture** | `03_architecture/` | High-level design decisions |
| **Content/Lore** | `03_content/` | World lore, factions, visual references |
| **Research** | `04_research/` | Exploration notes and experiments |

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

## Active Focus (2026-05-27)

**Priority 1 - Procgen Handoff Fixes:**
- Camera bounds from procgen map (not legacy sectors)
- Camera snap to procgen player spawn
- Reposition terminal/ammo caches to procgen coords
- Register camera to "camera" group for game feel

**Priority 2 - Ash-Bell / Forlorn-Ritualant Encounter:**
- Implementation of Forlorn-Ritualant encounter scene
- Silence Pressure + Thread Tension mechanics (per DETAILED_SPEC)
- Dry Fountain apparition and White Thread Knot pickup
- NPC dialogue system with proximity triggers
- Procgen rare-room injection

**Priority 3 - Mission Flow:**
- Mission state machine implementation
- Free-roam pre-assault loop
- Manual assault trigger via terminal

**Priority 4 - Polish:**
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

*Use `00_meta/MASTER_ROADMAP.md` for both milestone planning and day-to-day task management. `00_meta/TRACKING.md` and `02_features/_ACTIVE.md` are deprecated — see MASTER_ROADMAP.md.*
