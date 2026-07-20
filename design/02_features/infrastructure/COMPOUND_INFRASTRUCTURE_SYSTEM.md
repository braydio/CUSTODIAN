# Compound Infrastructure System

**Project:** CUSTODIAN
**Created:** 2026-07-20
**Status:** active — Milestone 1 runtime slice implemented
**Last Updated:** 2026-07-20
**Runtime State:** Component grid registration, Field Fabricator service scaling, Capacitor Bank construction/commissioning, terminal snapshots, and versioned registry round-trip persistence are live. Project-wide save-manager integration remains pending.
**Depends On:** `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/02_features/power/POWER_SYSTEMS_GODOT.md`, terminal FABRICATION/POWER surfaces, compound construction boundaries

## Purpose

The Compound Infrastructure System is the next bounded economy layer after resource harvesting and fabrication. It turns fabricated build tokens into persistent compound capabilities whose operation depends on construction state, structural integrity, and power allocation.

The ownership rule is:

> Fabrication creates a building package. Construction places and assembles it. Power determines whether it functions. Infrastructure services describe what it contributes. Damage and maintenance determine whether that contribution persists.

The intended loop is:

```text
Explore and harvest
        ↓
Fabricate a structure package
        ↓
Choose a valid construction site
        ↓
Deploy foundation and complete assembly
        ↓
Register generation, demand, storage, or service output
        ↓
Assign power priority
        ↓
Use, defend, damage, repair, upgrade, or replace the structure
```

This is not permission to add an unrestricted survival-building editor. V1 is a deliberately constrained extension of the existing token-gated placement flow.

## Scope

### In Scope for V1

- One abstract compound-wide electrical grid.
- Explicit per-second generation, requested demand, allocated demand, and net generation.
- Stored energy reserve and storage capacity as quantities separate from power rates.
- Independently registered power generators and consumers that do not need to be `Sector` nodes.
- Priority-based minimum and standard allocation, plus explicitly enabled overdrive.
- Structure definitions stored as reusable resources instead of scene-local balance constants.
- Token-gated placement into authored sockets, designated free-placement zones, or tactical deployment surfaces.
- Foundation, construction, commissioning, operational, damaged, disabled, and destroyed states.
- Integrity-scaled generation and service output.
- A shared infrastructure registry for service queries, terminal snapshots, uniqueness limits, and persistence.
- Terminal visibility for generation, demand, allocation, reserve, structure state, and power priority.
- First vertical slice: Power Core → powered Field Fabricator → fabricated/placed Capacitor Bank → increased reserve.

### Out of Scope for V1

- Unrestricted floors, walls, roofs, cables, plumbing, or decorative base editing.
- Per-tile electrical simulation, voltage levels, transformers, sockets, or manually drawn wires.
- Automatic procedural economy simulation or passive resource extraction.
- NPC staffing requirements; `staffing_modifier` remains `1.0` in V1.
- Random material waste or opaque failure rolls.
- Full upgrade trees for every structure.
- Mobile compound relocation.
- Expedition-site infrastructure beyond explicitly supported tactical deployables.
- Implementing the full long-term structure catalog in one milestone.

## System Overview

```text
ResourceLedger ──pays costs──▶ FabPipeline
                                   │
                                   ▼
                          BuildInventory token
                                   │
                                   ▼
ConstructionPlacement ──validates site and consumes token on commit
                                   │
                                   ▼
                         InfrastructureStructure
                          │        │        │
                 integrity│   power│ service│
                          ▼        ▼        ▼
                 InfrastructureRegistry ◀── PowerGrid
                          │                    │
                          └──── snapshots ─────┘
                                   │
                                   ▼
                         Terminal / save system
```

### Authority Boundaries

- `ResourceLedger` owns resource quantities and payment.
- `FabPipeline` owns work orders, fabrication time, and produced outputs.
- `BuildInventory` owns unplaced Ready Build tokens.
- The placement controller owns preview and site validation, but consumes a token only after a valid commit.
- `InfrastructureStructure` owns local construction, integrity, and operating state.
- Power components own requested/allocated rates; they do not own global allocation policy.
- The grid manager owns generation, reserve flow, load shedding, and allocation.
- `InfrastructureRegistry` owns placed-structure identity and aggregate service queries.
- Terminal UI projects snapshots. It never becomes simulation authority.
- `Sector` remains compound-zone authority. A free-standing structure must not pretend to be a `Sector` to receive power.

## Core Terminology and Units

Power rates and stored energy are different domains.

| Term | Meaning | Unit |
|---|---|---|
| `grid_generation_rate` | Current generator output | Power per second |
| `grid_requested_rate` | Sum of requested consumer load | Power per second |
| `grid_allocated_rate` | Load actually assigned | Power per second |
| `grid_net_rate` | Generation minus allocated load | Power per second |
| `stored_energy` | Current reserve quantity | Power-seconds |
| `storage_capacity` | Maximum reserve quantity | Power-seconds |

Player-facing UI may call the rate unit `P` and the quantity `Reserve`; internal names must retain the rate/quantity distinction.

Example terminal presentation:

```text
GENERATION     135 P/s
DEMAND         168 P/s
ALLOCATED      135 P/s
NET            -33 P/s
RESERVE        340 / 500
```

No consumer may multiply grid rates by an assumed frame rate. Integration uses `rate * delta` only where rates change stored quantities.

## Power Model

### Consumer Contract

Every powered structure declares:

```text
minimum_power
standard_power
overdrive_power
overdrive_efficiency
power_priority
allocated_power
integrity_modifier
```

V1 operating tiers:

| Tier | Allocation | Behavior |
|---|---:|---|
| `OFFLINE` | Below minimum | No active service |
| `EMERGENCY` | At minimum | Essential bounded service only |
| `DEGRADED` | Between minimum and standard | Proportional output |
| `STANDARD` | At standard | Intended full output |
| `OVERDRIVE` | At or above overdrive threshold | Improved output with heat/maintenance cost |

Reference calculation:

```gdscript
func resolve_power_efficiency() -> float:
    if allocated_power < minimum_power:
        return 0.0
    if allocated_power < standard_power:
        return allocated_power / maxf(standard_power, 0.001)
    if overdrive_enabled and overdrive_power > standard_power \
    and allocated_power >= overdrive_power:
        return overdrive_efficiency
    return 1.0

effective_output = power_efficiency * integrity_modifier * staffing_modifier
```

`staffing_modifier` is fixed at `1.0` in V1.

### Allocation Order

The allocator runs at a deterministic simulation boundary and uses stable identity as the final tie-breaker.

1. Compute generation available this tick.
2. Discharge reserve within its discharge-rate limit when requested load exceeds generation.
3. Give required critical consumers their minimum power by priority.
4. Give remaining consumers minimum power by priority.
5. Fill critical consumers toward standard.
6. Fill remaining consumers toward standard.
7. Charge reserve from surplus within its charge-rate limit.
8. Allocate explicitly enabled overdrive from remaining surplus or permitted reserve.

If reserve is exhausted, the lowest-priority demand sheds first. Overdrive is always opt-in and is never required to satisfy normal operation.

### Generation and Storage

- Generator output scales with integrity.
- Storage contributes capacity, charge rate, and discharge rate, not generation.
- V1 reserve is one grid-owned aggregate quantity; individual Capacitor Banks do not simulate separate charge inventories.
- Effective storage capacity, charge rate, and discharge rate equal their definition values multiplied by the structure integrity modifier.
- When damage lowers aggregate capacity below current reserve, the grid clamps reserve immediately and records the lost amount as a diagnostic event.
- Destroyed storage immediately removes its capacity; stored energy above the new capacity is lost.
- Destroyed generators stop contributing output before the next allocation commit.
- Registration/unregistration triggers one deterministic allocation refresh, not per-frame group rescans.

### Initial Priority Defaults

| Priority | Category |
|---:|---|
| 90 | Command Terminal |
| 85 | Gate Actuator |
| 80 | Shield Projector |
| 75 | Critical defensive turret |
| 70 | Sensor Pylon |
| 65 | Repair Station |
| 60 | General turret |
| 50 | Grid infrastructure |
| 40 | Expedition Staging Bay |
| 30 | Field Fabricator |
| 20 | Heavy Assembly Rig |
| 10 | Pattern Archive |

Priorities are defaults, not hidden hard locks. Critical-minimum protection and authority restrictions are separate policy fields.

## Construction Model

### Lifecycle

```text
LOCKED
  → AVAILABLE
  → PACKAGED
  → FOUNDATION
  → UNDER_CONSTRUCTION
  → COMMISSIONING
  → OFFLINE_UNCONNECTED
  → OPERATIONAL
  → DAMAGED
  → DISABLED
  → DESTROYED
```

The state machine must also support cancellation during `FOUNDATION` or `UNDER_CONSTRUCTION` and restoration from `DAMAGED`/`DISABLED` through repair.

### Phase 1: Fabricate Package

The existing fabrication separation remains authoritative:

```gdscript
{
    "build_id": &"capacitor_bank_mk1",
    "quantity": 1,
    "state": &"ready_for_placement",
}
```

Fabrication pays costs and creates the token. It does not instantiate the final building.

### Phase 2: Placement Preview

Placement validates:

- allowed construction boundary or authored socket;
- terrain and footprint compatibility;
- no collision overlap;
- operator-accessible installation point;
- clearance from critical paths, gates, spawn safety, and reserved readability areas;
- required site tags;
- relay coverage when required;
- no active enemy exclusion condition when the definition forbids combat placement;
- unique-structure and capacity limits.

Invalid placement is non-destructive. The Ready Build token remains in inventory.

### Phase 3: Foundation

On valid commit:

- consume exactly one matching token;
- create a physical foundation at 5–20% integrity;
- reserve its footprint and block overlapping placement;
- expose cancellation with a definition-owned refund ratio;
- remain non-operational and excluded from service aggregation.

### Phase 4: Assembly

V1 uses hybrid assembly:

1. Operator deploys the foundation.
2. Operator performs one explicit installation interaction.
3. Construction advances for a deterministic duration.
4. The structure enters commissioning.

Future cranes or construction drones may accelerate step 3 through a service modifier. V1 must not require repetitive interaction spam.

### Phase 5: Commissioning

After construction:

- play startup presentation;
- register with `InfrastructureRegistry`;
- register generator, storage, and/or consumer components;
- apply the definition's default priority;
- expose terminal state;
- remain offline if connection or allocation requirements are unmet.

## Placement Modes

### Authored Infrastructure Sockets

For large, unique, layout-defining structures:

- Reclaimed Power Core
- Heavy Assembly Rig
- Tactical Coordination Array
- Observation Mast
- Repair Station

Sockets guarantee navigation, composition, scale, and progression compatibility.

### Designated Free-Placement Zones

For medium compound structures:

- Capacitor Bank
- Grid Relay
- Load Controller
- Sensor Pylon
- Auxiliary Generator
- Munitions Loader

Placement remains free within explicitly tagged zones, not across the entire world.

### Tactical Deployment Surfaces

For combat-time Ready Builds:

- Light Barricade
- Basic Turret
- Emergency Dynamo
- Shield Projector
- Traps

This mode extends the existing token-gated placement surface and retains its valid-site/consume-on-commit contract.

## Infrastructure Services

Structures expose typed services rather than requiring other systems to know concrete scene classes.

Initial service IDs:

```text
FABRICATION
REPAIR
SENSOR_COVERAGE
DEFENSE_COORDINATION
SHIELD_COVERAGE
LOGISTICS_STORAGE
EXPEDITION_STAGING
PATTERN_DECODING
```

Example query:

```gdscript
var fab_output := InfrastructureRegistry.get_service_output(&"FABRICATION")
```

The result already incorporates construction state, connection, power efficiency, integrity, and any future staffing modifier. Callers must not reach into private power-system helpers such as `_get_fabrication_effectiveness()`.

## Initial Playable Structure Set

V1 defines eight structures, but the first milestone implements only the three needed for the Powered Fabricator Slice.

| Structure | Category | Power Contract | Primary Function | V1 Stage |
|---|---|---|---|---|
| Reclaimed Power Core | Power | Generates 100 P/s | Stable baseline generation | Milestone 1 |
| Capacitor Bank | Power | Draw 2 P/s; +250 reserve; 50/75 charge/discharge | Energy storage | Milestone 1 |
| Grid Relay | Power | Min 1 / Std 3 | Connects structures in a zone | Milestone 2 |
| Field Fabricator | Fabrication | Min 10 / Std 25 / Overdrive 40 | Produces simple Ready Builds | Milestone 1 |
| Repair Station | Recovery | Min 8 / Std 18 / Overdrive 30 | Repairs structures | Milestone 2 |
| Basic Turret Emplacement | Defense | Min 4 / Std 10 / Overdrive 15 | Automated close defense | Milestone 2 |
| Sensor Pylon | Intelligence | Min 2 / Std 7 | Detection and relay coverage | Milestone 2 |
| Shield Projector | Defense | Min 15 / Std 35 / Overdrive 55 | Area protection | Milestone 3 |

### Structure Family Roadmap

The following are catalog direction, not V1 implementation scope:

- Power: Blackwood Thermal Generator, Salvaged Turbine Array, Resonance Harvester, Emergency Dynamo.
- Distribution: Load Controller, Isolation Breaker.
- Command: Tactical Coordination Array, World Relay Uplink.
- Fabrication: Heavy Assembly Rig, Pattern Archive, Materials Processor.
- Logistics: Salvage Depot, Transfer Crane, Expedition Staging Bay, Resource Compression Vault.
- Defense: Sniper Turret, Gate Actuator, Suppression Beacon, Munitions Loader.
- Intelligence: Signal Analysis Chamber, Observation Mast, Counter-Signal Array.
- Recovery: Operator Recovery Pod, Drone Maintenance Cradle, Decontamination Chamber.

Each future structure must justify a distinct strategic dependency; larger numbers alone are not sufficient differentiation.

## Data Definitions

### StructureDefinition

Proposed path:

```text
custodian/game/infrastructure/definitions/structure_definition.gd
```

```gdscript
class_name StructureDefinition
extends Resource

@export var structure_id: StringName
@export var display_name: String
@export_multiline var description: String

@export_category("Classification")
@export var category: StringName
@export var placement_mode: StringName
@export var footprint_tiles: Vector2i
@export var unique_structure := false

@export_category("Construction")
@export var recipe_id: StringName
@export var construction_time := 10.0
@export var required_site_tags: Array[StringName]
@export_range(0.0, 1.0, 0.05) var cancellation_refund_ratio := 0.5

@export_category("Power")
@export var base_generation_rate := 0.0
@export var minimum_power := 0.0
@export var standard_power := 0.0
@export var overdrive_power := 0.0
@export var overdrive_efficiency := 1.0
@export_range(0, 100, 1) var default_priority := 50

@export_category("Storage")
@export var storage_capacity := 0.0
@export var charge_rate := 0.0
@export var discharge_rate := 0.0

@export_category("Durability")
@export var max_integrity := 100.0
@export var armor_class: StringName
@export var repair_recipe_id: StringName

@export_category("Operations")
@export var services: Array[Resource]
@export var upgrade_ids: Array[StringName]

@export_category("Presentation")
@export var scene: PackedScene
@export var construction_scene: PackedScene
@export var placement_icon: Texture2D
```

Definitions live under:

```text
custodian/content/infrastructure/definitions/
├── power/
├── command/
├── fabrication/
├── logistics/
├── defense/
├── intelligence/
└── recovery/
```

### Runtime Snapshot

Every registered structure exposes a stable snapshot:

```gdscript
{
    "instance_id": &"compound_capacitor_bank_01",
    "structure_id": &"capacitor_bank_mk1",
    "construction_state": &"operational",
    "integrity": 220.0,
    "max_integrity": 240.0,
    "power_tier": &"standard",
    "requested_power": 2.0,
    "allocated_power": 2.0,
    "priority": 50,
    "services": {},
    "world_context_id": &"compound",
    "position": Vector2.ZERO,
}
```

Save payloads use JSON-safe values and schema/version fields; runtime node references are never persisted.

## Runtime Components

### InfrastructureRegistry

Proposed path:

```text
custodian/autoload/infrastructure_registry.gd
```

Responsibilities:

- register/unregister placed structures;
- enforce stable instance identity and uniqueness limits;
- aggregate typed service output;
- expose terminal/save snapshots;
- request deterministic grid refreshes when membership changes;
- restore saved structures after their owning world context is available.

It must not perform per-frame scene-tree group scans.

### InfrastructureStructure

Proposed paths:

```text
custodian/game/infrastructure/infrastructure_structure.gd
custodian/game/infrastructure/infrastructure_structure.tscn
```

Responsibilities:

- construction lifecycle;
- integrity and repair boundary;
- component discovery;
- interaction prompts;
- startup/shutdown presentation hooks;
- snapshot capture/restore.

### Power Components

Proposed paths:

```text
custodian/game/infrastructure/components/power_generator_component.gd
custodian/game/infrastructure/components/power_consumer_component.gd
custodian/game/infrastructure/components/power_storage_component.gd
custodian/game/infrastructure/components/infrastructure_service_component.gd
```

Components register explicitly. Existing `Sector` consumers and `power_node` generators remain compatibility adapters until migrated.

### Placement and Construction

Proposed paths:

```text
custodian/game/infrastructure/construction_placement_controller.gd
custodian/game/infrastructure/construction_site_2d.gd
custodian/game/infrastructure/construction_zone_2d.gd
custodian/game/infrastructure/construction_foundation.gd
```

The initial controller should reuse proven preview/input/collision concepts from `turret_placement.gd`, but construction authority must not remain named or coupled to turrets.

## Integration Points

| System | Interface | Contract |
|---|---|---|
| `FabPipeline` | Ready Build outputs | Fabrication ends at a token; no final structure spawn |
| `BuildInventory` | consume token | Exactly one matching token after valid placement commit |
| `ResourceLedger` | payment/refund | Owns all material mutation |
| `power.gd` | registration adapter | Retain sector compatibility while adding independent component registration |
| Terminal FABRICATION | work orders/Ready Builds | Starts packages and selects placement |
| Terminal POWER | grid snapshot/priority commands | Shows rates, reserve, allocation, and staged priority changes |
| Terminal STATUS | bounded summary | Reports generation, allocated demand, reserve, and infrastructure failures |
| Compound procgen/authored map | sockets/zones | Provides placement authority and reserved navigation/readability areas |
| Damage/repair | integrity hooks | Changes generator/service output and operating state |
| Save/load | versioned snapshots | Restores definitions, transforms, lifecycle, integrity, priority, and local state |

## Persistence Contract

V1 persistence must preserve:

- stable structure instance ID;
- definition ID and definition version;
- world-context ID and transform;
- construction state and remaining construction time;
- integrity;
- priority and overdrive permission;
- grid-owned aggregate reserve quantity and capacity inputs;
- structure-specific service state.

Do not persist:

- scene-tree paths;
- node instance IDs;
- active particles or animation frames;
- cached aggregate service output;
- current allocation, which is recomputed deterministically after restore.

If the project save spine is not ready when Milestone 1 lands, the feature cannot be called complete-v1. A temporary focused serialization fixture is acceptable only as an interim validation tool.

## Terminal Contract

### POWER Page

Must distinguish:

```text
Generation rate
Requested demand
Allocated demand
Net rate
Reserve quantity/capacity
Charge/discharge limit
Selected structure priority
Selected structure tier and integrity
```

Priority and overdrive changes should be staged, previewed, and explicitly applied where the terminal authority policy requires it.

### FABRICATION Page

- Building recipes remain work orders.
- Completed packages appear as Ready Builds.
- PLACE selects a package and enters the appropriate placement mode.
- Construction progress is not fabrication queue progress.

### STATUS and Overview

STATUS reports authoritative aggregate grid state. Overview may recommend power shedding, repair, or construction, but it must use the same snapshot generation as the POWER page.

## Observability

Instrumentation routes through `DevObservatory` and never influences simulation.

Required events:

```text
infrastructure_package_placement_started
infrastructure_package_placement_rejected
infrastructure_foundation_committed
infrastructure_construction_started
infrastructure_construction_completed
infrastructure_commissioned
infrastructure_power_tier_changed
infrastructure_damaged
infrastructure_destroyed
infrastructure_repaired
```

Required gauges:

```text
infrastructure_structure_count
infrastructure_under_construction_count
grid_generation_rate
grid_requested_rate
grid_allocated_rate
grid_net_rate
grid_stored_energy
grid_storage_capacity
grid_offline_consumer_count
grid_degraded_consumer_count
```

## Asset Direction

Milestone 1 may use scene-native blockout art, but production structure assets should live under the active `content/` tree rather than the legacy `assets/` tree.

Recommended Reclaimed Power Core package:

```text
custodian/content/sprites/structures/power/reclaimed_power_core/
├── reclaimed_power_core_idle_01.png       # 192×192, 6 frames
├── reclaimed_power_core_startup_01.png    # 192×192, 8 frames
├── reclaimed_power_core_damaged_01.png    # 192×192, 4 frames
├── reclaimed_power_core_offline_01.png    # 192×192, 1 frame
└── source/
    └── reclaimed_power_core_01.aseprite
```

Presentation cannot be gameplay authority. Startup completion, connection, allocation, and damage state drive animation selection, not the reverse.

## Initial Recipe Targets

These are provisional balance inputs and require the fabrication balance pipeline before runtime adoption.

| Structure | Proposed Cost |
|---|---|
| Reclaimed Power Core | structural_alloy 30, ruin_scrap 45, power_components 6, capacitor_dust 8, signal_filament 2 |
| Capacitor Bank | structural_alloy 8, ruin_scrap 14, power_components 2, capacitor_dust 8, resin_clot 1 |
| Grid Relay | ruin_scrap 10, power_components 1, capacitor_dust 2, signal_filament 1 |
| Field Fabricator | structural_alloy 20, ruin_scrap 30, power_components 4, capacitor_dust 4, memory_glass_fragment 1 |
| Repair Station | structural_alloy 15, ruin_scrap 18, power_components 2, resin_clot 4, fiber_moss 3 |
| Basic Turret | structural_alloy 8, ruin_scrap 25, power_components 1, capacitor_dust 2 |
| Sensor Pylon | ruin_scrap 12, capacitor_dust 4, signal_filament 1 |
| Shield Projector | structural_alloy 16, ruin_scrap 20, power_components 5, capacitor_dust 10, signal_filament 2, memory_glass_fragment 1 |

The existing `turret_basic`, `power_bank_patch`, and `sensor_pylon_basic` recipes are migration inputs. Do not silently reinterpret `power_bank_patch` as a permanent Capacitor Bank without an explicit recipe/output migration.

## Milestone 1: Powered Fabricator Slice

### Goal

Prove the complete generation → consumption → fabrication → construction → storage → damage → persistence loop with the smallest useful set.

### Required Flow

```text
Reclaimed Power Core
        ↓ generation
Field Fabricator receives allocation
        ↓ produces Ready Build
Capacitor Bank foundation placed in valid zone
        ↓ assembly and commissioning
Grid reserve capacity increases
        ↓ damage/destruction
Capacity decreases and grid state reconciles
```

### Acceptance Criteria

1. A Reclaimed Power Core registers deterministic generation.
2. The Field Fabricator registers minimum/standard demand.
3. Fabrication availability and speed derive from effective service output.
4. The player fabricates one Capacitor Bank package through `FabPipeline`.
5. Placement rejects invalid sites without consuming the token.
6. Valid placement consumes exactly one token and creates a foundation.
7. Assembly completes through the hybrid construction flow.
8. Commissioning registers storage with the grid.
9. Maximum reserve increases by the definition-owned amount.
10. Damage scales storage availability according to the approved integrity policy.
11. Destruction unregisters storage and clamps excess reserve.
12. Terminal POWER and STATUS show the same authoritative change.
13. Save/load restores the placed bank, integrity, grid reserve, and priority without duplication.
14. Existing Basic Turret and Light Barricade deployment remains green.

### Implementation Status

Criteria 1–12 and 14 are implemented and covered by focused headless smokes. Criterion 13 is implemented at the versioned `InfrastructureRegistry.capture_state()` / `restore_state()` boundary and verified without duplication, but is not yet connected to a project-wide save manager because no such runtime authority currently exists. For that reason this system remains `active`, not `complete-v1`.

## Validation Plan

Proposed focused scripts:

```text
custodian/tools/validation/infrastructure_definition_contract_smoke.gd
custodian/tools/validation/power_grid_component_registration_smoke.gd
custodian/tools/validation/power_grid_reserve_allocation_smoke.gd
custodian/tools/validation/construction_placement_contract_smoke.gd
custodian/tools/validation/powered_fabricator_slice_smoke.gd
custodian/tools/validation/infrastructure_damage_unregister_smoke.gd
custodian/tools/validation/infrastructure_save_restore_smoke.gd
custodian/tools/validation/infrastructure_terminal_snapshot_smoke.gd
```

Tests must cover multiple fixed delta sizes for rate integration, stable tie-breaking for equal priorities, token preservation on invalid placement, exact token consumption on commit, and rollback if construction instantiation fails.

## Staged Roadmap

### Milestone 1 — Powered Fabricator

- Core, Field Fabricator, Capacitor Bank.
- Component registration and abstract grid.
- One construction zone.
- Persistence and terminal snapshot.

### Milestone 2 — Operational Dependencies

- Grid Relay, Repair Station, Basic Turret, Sensor Pylon.
- Zone connection and local priority control.
- Repair and sensor service queries.
- Assault-time load shedding.

### Milestone 3 — Defensive Power Decisions

- Shield Projector and explicit overdrive.
- Reserve policies and staged POWER controls.
- Structure-specific failure presentation.

### Later

- Auxiliary/fueled/environmental generators.
- Heavy assembly and logistics structures.
- Advanced intelligence and expedition preparation.
- Snapshot-and-unload compound persistence if world-context memory requires it.

## Known Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Reusing `Sector` for every building | High | Component registration with a compatibility adapter |
| Mixing rates with stored quantities | High | Explicit names/units and multi-delta tests |
| Free-placement navigation blockage | High | Tagged zones, route clearance, and atomic placement validation |
| Token loss on failed placement | High | Consume only after valid commit; rollback on spawn failure |
| Per-frame scene/group scans | Medium | Explicit registry membership and change-driven recomputation |
| Terminal becoming power authority | Medium | Read-only snapshots and command queue boundary |
| Scope explosion into survival building | High | Eight-structure V1 catalog, three-structure first milestone, hybrid placement only |
| Save/load arriving after building proliferation | High | Persistence is a Milestone 1 acceptance requirement |

## Documentation Relationships

- `RESOURCE_FABRICATION_SYSTEM.md` remains authority for harvesting, ledger, fabrication work orders, and Ready Build tokens.
- This document becomes authority for persistent infrastructure construction and operation.
- `POWER_SYSTEMS_GODOT.md` remains the current sector-power runtime summary until Power Grid V2 implementation work begins.
- `SIMPLIFIED_POWER_IN_ROOMS.md` is superseded as an implementation proposal; conduit markers must not create generators implicitly.

## Next Agent Slice

**Goal:** Produce the implementation proposal for Milestone 1 without changing runtime behavior.

**Files:**

```text
design/02_features/infrastructure/INFRASTRUCTURE_IMPLEMENTATION_PLAN.md
design/02_features/power/POWER_GRID_V2.md
custodian/game/systems/core/systems/power.gd
custodian/autoload/fab_pipeline.gd
custodian/autoload/build_inventory.gd
custodian/game/systems/core/systems/turret_placement.gd
custodian/game/ui/hud/ui.gd
custodian/content/fabrication/fab_recipes.json
```

**Constraints:**

- Design/proposal only in the next slice unless runtime implementation is explicitly requested.
- Preserve sector-power and current turret/barricade behavior through adapters.
- Keep rate and stored-energy units explicit.
- Use change-driven registration, not recurring scene-tree scans.
- Do not add freeform walls/floors/cables or the later structure catalog.
- Treat persistence and rollback as first-milestone requirements.

**Acceptance:**

- Proposed files and ownership are concrete.
- Migration steps identify compatibility boundaries.
- The transaction order for placement and construction is atomic.
- Power allocation and reserve formulas are deterministic.
- Every Milestone 1 acceptance criterion maps to a focused smoke test.
