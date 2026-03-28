# World Expansion & The Hub Implementation Roadmap

**Project:** CUSTODIAN  
**Created:** 2026-03-27  
**Status:** 🔴 In Progress

---

## Overview

Three major expansions to transform CUSTODIAN from a single-map wave defense into a full campaign-driven tactical experience:

1. **Expanded World Map** - Multiple regions/biomes beyond the compound
2. **Tile-Based Compound Construction** - Distinct wall tiles making up the compound structure  
3. **The Hub** - Campaign system generating procedurally unique missions

---

# Part 1: Expanded World Map

## Current State

- Single procgen compound map
- Fixed sector positions
- Limited exploration

## Target State

- Multiple explorable regions (beyond compound)
- Diverse biomes and environments
- World map navigation between areas
- Campaign-driven mission selection

## Biomes (from Hub system)

| Biome | Environmental Tags | Threat Profile |
|-------|-------------------|---------------|
| RUINED URBAN | LOW VISIBILITY, STRUCTURAL INSTABILITY | MUTATED ORGANICS |
| ARID WASTELAND | RADIATION, LOW VISIBILITY | AUTONOMOUS WAR MACHINES |
| SUBTERRANEAN COMPLEX | LOW VISIBILITY, SIGNAL ECHO | POST-HUMAN FACTIONS |
| BIO-OVERGROWN ZONE | BIOCONTAMINATION, LOW VISIBILITY | FERAL DEFENSE SYSTEMS |
| ORBITAL DERELICT | SIGNAL ECHO, STRUCTURAL INSTABILITY | UNKNOWN ANOMALY |

## World Structure

```
WORLD MAP
├── THE COMPOUND (Home Base)
│   ├── COMMAND (Hub access)
│   ├── 9 Sectors with distinct buildings
│   ├── ARRN Relay positions
│   ├── Defense perimeter
│   └── Wall tile grid
│
├── REGION_1 (Campaign Mission)
│   ├── Objective sites
│   ├── Threat zones
│   └── Environmental hazards
│
├── REGION_2 (Campaign Mission)
│   └── ...
│
└── REGION_N (Campaign Mission)
```

## Implementation

### Phase 1: World Manager

```gdscript
# core/systems/world/world_manager.gd
class_name WorldManager
extends Node

enum WorldState { COMPOUND, REGION, TRANSIT }

var current_world: WorldState = WorldState.COMPOUND
var active_region: String = ""
var regions: Dictionary = {}  # region_id -> RegionData

func transition_to_world(target: String):
    # Unload current world
    # Load target world
    # Position player
    
func get_world_bounds() -> Rect2:
    match current_world:
        COMPOUND: return compound_bounds
        REGION: return active_region_bounds
```

### Phase 2: Region Loading

- Each region is a separate Godot scene or procedurally generated
- Regions loaded on-demand for campaign missions
- Seamless transitions between compound and regions

---

# Part 2: Tile-Based Compound Construction

## Current State

- Procedural wall generation from tilemap
- Limited granularity

## Target State

- Each wall segment is a distinct tile/entity
- Destructible wall tiles
- Tactical cover system
- Power routing through wall network

## Tile System Architecture

```gdscript
# entities/wall/tile_system.gd
class_name WallTileSystem
extends Node2D

enum TileType {
    WALL_STANDARD,
    WALL_REINFORCED, 
    WALL_DESTRUCTIBLE,
    WALL_POWER_CONDUIT,
    WALL_SENSOR,
    DOOR_STANDARD,
    DOOR_SECURE,
    GATE_EXPANSION,
    TURRET_MOUNT,
}

@export var tile_size: Vector2 = Vector2(32, 32)
var tile_grid: Dictionary = {}  # Vector2 -> TileData

struct TileData:
    var type: TileType
    var health: float
    var power_connection: bool
    var is_destructible: bool
```

## Tile Types

| Type | Health | Destructible | Special |
|------|--------|---------------|---------|
| WALL_STANDARD | 100 | Yes | None |
| WALL_REINFORCED | 200 | No | Takes 2x damage |
| WALL_DESTRUCTIBLE | 50 | Yes | Drops resources |
| WALL_POWER_CONDUIT | 100 | Yes | Routes power |
| WALL_SENSOR | 75 | Yes | Detection bonus |
| DOOR_STANDARD | 80 | Yes | Opens/closes |
| DOOR_SECURE | 150 | No | Requires auth |
| GATE_EXPANSION | 120 | Yes | Vehicle access |
| TURRET_MOUNT | 200 | No | Turret placement |

## Compound Layout (9 Sectors + Transit)

```
                    [ARCHIVE]
                       |
            [T_NORTH]---[COMMS]---[STORAGE]
                       |
    [POWER]---[COMMAND]---[FABRICATION]
                       |
            [T_SOUTH]---[DEFENSE GRID]---[HANGAR]---[GATEWAY]
```

## Wall Grid Construction

Each sector building constructed from wall tiles:
- COMMAND: 8x8 tile grid + COMMAND center
- POWER: 6x6 + power conduit network
- etc.

## Implementation Tasks

- [ ] Create wall tile entity system
- [ ] Implement tile placement algorithm
- [ ] Add destructible tile physics
- [ ] Create power conduit routing
- [ ] Build sector buildings from tiles
- [ ] Add tile damage states (intact → damaged → destroyed)

---

# Part 3: The Hub (Campaign System)

## Overview

The Hub is the strategic layer that generates unique campaign missions. Players choose missions, complete objectives, and build their knowledge archive.

## Core Data Structures

### HubState

```gdscript
class_name HubState
extends Resource

var seed: int
var capability_flags: Dictionary = {}
var unlocked_scenario_archetypes: Array = []
var unlocked_victory_modifiers: Array = []
var knowledge_archive: Array = []  # ArchiveEntry[]
var campaign_history: Array = []    # CampaignRecord[]
```

### CampaignScenario

```gdscript
class_name CampaignScenario
extends Resource

var id: String  # UUID
var seed: int
var region: Region
var difficulty: Difficulty
var setting: Setting
var threat_profile: ThreatProfile
var victory_conditions: VictoryConditions
var optional_subvictories: OptionalSubvictories
var resource_profile: ResourceProfile
var uncertainty: Uncertainty
var reward_profile: RewardProfile
```

### Campaign Regions

| Region ID | Biome | Difficulty Range | Primary Threat |
|-----------|-------|-----------------|----------------|
| RX-###A | RUINED URBAN | 0.0-0.4 | MUTATED ORGANICS |
| RX-###B | ARID WASTELAND | 0.2-0.6 | AUTONOMOUS WAR MACHINES |
| RX-###C | SUBTERRANEAN | 0.4-0.8 | POST-HUMAN FACTIONS |

## Difficulty Descriptors

| Score Range | Descriptor | Meaning |
|------------|------------|---------|
| 0.0-0.2 | LOW CONFIDENCE OPERATION | Easy, familiar territory |
| 0.2-0.4 | UNSTABLE CONDITIONS | Moderate difficulty |
| 0.4-0.6 | HIGH RISK ENGAGEMENT | Challenging |
| 0.6-0.8 | SEVERE OPERATIONAL COMPLEXITY | Hard |
| 0.8+ | EXTINCTION-LEVEL UNKNOWN | Very Hard |

## Victory Conditions

| Type | Goal |
|------|------|
| RECOVERY | Extract artifact/data |
| STABILIZE | Secure location |
| CONTAINMENT | Prevent spread |
| NEUTRALIZE | Eliminate threat |

## Rewards & Unlocks

| Archetype | Unlocks |
|-----------|---------|
| ARCHIVAL KNOWLEDGE | RECON_SIGNAL_FILTER, ARCHIVE_LOSS_TOLERANCE+1 |
| SCHEMATICS | SECONDARY_OBJECTIVE_DETECTION |
| LOST TECHNOLOGY | RECON_SIGNAL_FILTER |
| BIOLOGICAL DATA | SECONDARY_OBJECTIVE_DETECTION |
| CULTURAL RECORDS | ARCHIVE_LOSS_TOLERANCE+1 |

## Capability Flags

| Flag | Effect |
|------|--------|
| recon_depth (0-3) | Reveal more mission details |
| archive_loss_tolerance | Failures before game over |
| subvictory_detection | See optional objectives |

## Hub Interface Flow

```
1. COMPOUND → Access COMMAND terminal
2. Select "HUB" or "CAMPAIGN"
3. View available mission offers (3 generated scenarios)
4. Each offer shows:
   - Region ID
   - Difficulty descriptor
   - Biome
   - Primary threat
   - Victory type
   - Reward archetype
5. Select mission → Deploy to region
6. Complete objectives → Return to compound
7. Hub updates with:
   - Campaign history
   - Knowledge archive
   - New capability flags
   - Unlocked archetypes
```

## Implementation Phases

### Phase 1: Core Data Structures

```gdscript
# res://core/systems/hub/hub_data.gd
class_name HubData
extends Resource

# Data classes
class Region extends Resource:
    var region_id: String
    var similarity_hint: String  # FRINGE, CORE, LEGACY, FRAGMENTED

class Difficulty extends Resource:
    var score: float
    var descriptor: String

class Setting extends Resource:
    var biome: String
    var environmental_tags: Array[String]

class ThreatProfile extends Resource:
    var dominant_threat: String
    var secondary_threats: Array[String]
    var signal_confidence: float

class VictoryCondition extends Resource:
    var type: String  # RECOVERY, STABILIZATION, etc.
    var target_descriptor: String
    var completion_threshold: float
```

### Phase 2: Scenario Generation

```gdscript
# res://core/systems/hub/scenario_generator.gd
class_name ScenarioGenerator
extends Node

const BIOMES = ["RUINED URBAN", "ARID WASTELAND", "SUBTERRANEAN COMPLEX", ...]
const THREATS = ["MUTATED ORGANICS", "AUTONOMOUS WAR MACHINES", ...]
const VICTORY_TYPES = ["RECOVERY", "STABILIZATION", "CONTAINMENT", "NEUTRALIZATION"]

func generate_scenario(hub: HubState, seed: int) -> CampaignScenario:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed
    
    var region = _generate_region(rng)
    var setting = _generate_setting(rng)
    var threats = _generate_threats(rng)
    var victory = _generate_victory(rng)
    # ... combine into scenario
    
func generate_offers(hub: HubState, count: int = 3) -> Array[CampaignScenario]:
    # Generate multiple offers for player choice
```

### Phase 3: Knowledge & Progression

```gdscript
# res://core/systems/hub/knowledge_system.gd
class_name KnowledgeSystem
extends Node

func apply_outcome(hub: HubState, outcome: CampaignOutcome) -> HubState:
    # Process victory/partial/failure
    # Update capability_flags
    # Add to knowledge_archive
    # Update campaign_history
    
func get_recon_bonus(hub: HubState, scenario: CampaignScenario) -> CampaignScenario:
    # Reveal more details based on recon_depth
    # Mask/unmask fields based on capability
```

### Phase 4: Hub UI

```
# Terminal Hub Interface

═══════════════════════════════════════
        THE HUB - CAMPAIGN COMMAND
═══════════════════════════════════════

COMMAND CENTER STATUS:
- Archive Losses: 0/3
- Campaign Streak: 5
- Knowledge Archive: 12 ENTRIES

AVAILABLE MISSIONS:

[1] RX-742A - ARID WASTELAND
    Difficulty: HIGH RISK ENGAGEMENT
    Threat: AUTONOMOUS WAR MACHINES
    Objective: RECOVERY
    Reward: SCHEMATICS
    ─────────────────────────────

[2] RX-391B - RUINED URBAN  
    Difficulty: UNSTABLE CONDITIONS
    Threat: MUTATED ORGANICS
    Objective: STABILIZATION
    Reward: ARCHIVAL KNOWLEDGE
    ─────────────────────────────

[3] RX-118C - SUBTERRANEAN
    Difficulty: SEVERE OPERATIONAL COMPLEXITY
    Threat: POST-HUMAN FACTIONS
    Objective: CONTAINMENT
    Reward: LOST TECHNOLOGY
    ─────────────────────────────

SELECT MISSION [1-3] OR [R]EFRESH: _
```

### Phase 5: Region World Generation

Each campaign mission generates a unique region:

```gdscript
# res://core/systems/hub/region_generator.gd
class_name RegionGenerator
extends Node

func generate_region(scenario: CampaignScenario) -> RegionWorld:
    # Create region scene based on:
    # - scenario.setting.biome
    # - scenario.setting.environmental_tags
    # - scenario.threat_profile
    # - scenario.victory_conditions
    
    # Place objective(s) based on victory type
    # Spawn threat zones
    # Add environmental hazards
    # Configure extraction points
```

---

# Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WORLD MANAGER                            │
├─────────────────────────────────────────────────────────────┤
│  COMPOUND WORLD          │    REGION WORLD                 │
│  ┌─────────────────┐    │  ┌─────────────────────────┐  │
│  │ 9 Sectors       │    │  │ Campaign Scenario      │  │
│  │ Tile Walls      │    │  │ Biome Tileset          │  │
│  │ ARRN Relays     │    │  │ Objectives              │  │
│  │ Player Home     │    │  │ Threats                │  │
│  └─────────────────┘    │  │ Extraction Points      │  │
│                         │  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Campaign Mission
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       THE HUB                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────┐   │
│  │ HubState        │    │ Scenario Generator        │   │
│  │ - seed          │    │ - Biome selection          │   │
│  │ - capabilities │    │ - Difficulty calc          │   │
│  │ - archive       │    │ - Threat profiles          │   │
│  │ - history       │    │ - Victory conditions       │   │
│  └─────────────────┘    └─────────────────────────────┘   │
│                                                            │
│  ┌─────────────────┐    ┌─────────────────────────────┐   │
│  │ Knowledge Sys   │    │ Region Generator          │   │
│  │ - outcome proc │    │ - World construction       │   │
│  │ - unlocks       │    │ - Entity placement         │   │
│  │ - progression  │    │ - Hazard zones             │   │
│  └─────────────────┘    └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

# File Structure

```
custodian/
├── core/
│   └── systems/
│       ├── world/
│       │   ├── world_manager.gd
│       │   ├── world_transition.gd
│       │   └── world_bounds.gd
│       │
│       ├── compound/
│       │   ├── tile_system.gd
│       │   ├── wall_tile.gd
│       │   ├── power_conduit.gd
│       │   └── sector_builder.gd
│       │
│       └── hub/
│           ├── hub_manager.gd
│           ├── hub_data.gd           # Data classes
│           ├── scenario_generator.gd  # Mission generation
│           ├── knowledge_system.gd    # Progression
│           ├── region_generator.gd    # World generation
│           └── hub_ui.gd             # Terminal interface
│
├── entities/
│   ├── wall/
│   │   ├── wall_tile.tscn
│   │   ├── wall_standard.gd
│   │   ├── wall_reinforced.gd
│   │   ├── wall_destructible.gd
│   │   ├── wall_power_conduit.gd
│   │   └── door.gd
│   │
│   └── sectors/
│       ├── sector.gd
│       ├── command_sector.gd
│       ├── power_sector.gd
│       └── ... (9 sectors)
│
├── worlds/
│   ├── compound/
│   │   └── compound_world.tscn
│   │
│   └── regions/
│       ├── region_base.tscn
│       ├── biome_tilesets/
│       │   ├── ruined_urban.tres
│       │   ├── arid_wasteland.tres
│       │   └── ...
│       └── region_spawner.gd
│
└── ui/
    └── hub/
        └── campaign_selection.tscn
```

---

# Implementation Roadmap

## Priority 1: Foundation (Week 1-2)

- [ ] World Manager system
- [ ] Hub data classes (all dataclasses)
- [ ] Basic HubState save/load
- [ ] Scenario generator (deterministic)

## Priority 2: Compound Tiles (Week 2-3)

- [ ] Wall tile entity system
- [ ] Tile types (standard, reinforced, destructible)
- [ ] Sector building from tiles
- [ ] Power conduit routing
- [ ] Door/gate systems

## Priority 3: Campaign Flow (Week 3-4)

- [ ] Terminal Hub interface
- [ ] Mission offer generation (3 per refresh)
- [ ] Region loading from campaign
- [ ] Victory/defeat processing
- [ ] Knowledge archive updates

## Priority 4: Region Worlds (Week 4-6)

- [ ] Biome-based tilesets
- [ ] Objective placement
- [ ] Threat zone generation
- [ ] Environmental hazards
- [ ] Extraction point logic

## Priority 5: Polish (Week 6-7)

- [ ] Hub UI enhancements
- [ ] Campaign history display
- [ ] Knowledge archive viewer
- [ ] Difficulty balancing

---

# Reference Files

## Python Source (Migration Reference)

- `python-sim/game/simulations/world_state/core/hub.py` - Full Hub logic
- `python-sim/game/simulations/world_state/core/config.py` - Sector definitions
- `python-sim/game/simulations/world_state/core/state.py` - GameState integration

---

# Next Steps

1. **Start with Hub data classes** - Translate Python dataclasses to GDScript
2. **Create scenario generator** - Port the deterministic generation logic
3. **Build terminal Hub UI** - Basic campaign selection
4. **Add tile system** - Wall construction for compound
5. **Expand world manager** - Multiple region support

---

*This document defines the complete expansion. Update TRACKING.md with task assignments.*
