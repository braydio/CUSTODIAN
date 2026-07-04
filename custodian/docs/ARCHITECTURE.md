# CUSTODIAN Runtime Architecture

Last updated: 2026-07-03

## Runtime Authority

Godot is the only authoritative runtime for active gameplay.

- State mutation source: simulation systems and runtime world loaders
- Presentation source: scene tree, tilemaps, UI, animation
- Input source: Godot input actions
- Timing model: fixed-step deterministic simulation
- Rendering/UI must not absorb simulation authority

---

## Target Runtime Layers

The architecture is organized into nine layers. Each layer has a defined purpose, current file locations, target ownership, and allowed/forbidden dependencies.

### 1. App / Boot Layer

**Purpose:** Chooses the startup mode — Home beginning, Contract Sandbox, Debug Preview, etc.

**Current files:**
- `custodian/scenes/game.tscn` — active main scene
- `custodian/scenes/home_custodian_begin.tscn` — dedicated Home beginning scene (not yet the application main scene)
- `custodian/project.godot` — Godot project config, input mappings, autoloads

**Target owner files:**
- `game/app/boot/` — startup mode selection and routing
- `game/app/startup_mode.gd` — manages which mode the runtime boots into
- `game/app/runtime_entrypoint.gd` — shared initialization before mode selection

**Allowed dependencies:** Persistent layer, project.godot autoloads
**Forbidden dependencies:** World layer, Actor layer, Presentation layer at boot time
**Migration notes:** Boot layer is currently implicit in `game.tscn`. Extract startup-mode selection before wiring the Home scene as default entry.

---

### 2. Persistent Layer (Meta)

**Purpose:** State that survives campaigns — hub state, knowledge state, campaign history, persistent unlock/capability state.

**Current files:**
- `custodian/game/systems/core/state/game_state.gd` — fail-state and phase authority autoload
- `custodian/game/systems/core/state/game_stats.gd` — run-stat autoload

**Target owner files:**
- `game/state/persistent/hub_state.gd` — persistent hub mutations between campaigns
- `game/state/persistent/knowledge_state.gd` — persistent lore/knowledge recovery state
- `game/state/persistent/campaign_history.gd` — completed campaign outcomes
- `game/state/legacy_autoload/game_state.gd` — compatibility façade during migration
- `game/state/legacy_autoload/game_stats.gd` — compatibility façade during migration

**Allowed dependencies:** Godot core, ResourceLedger
**Forbidden dependencies:** World lifecycle, any transient simulation state
**Migration notes:** `GameState` and `GameStats` remain as compatibility autoloads. New persistent state objects move under `game/state/persistent/`. Existing callers still use `GameState` until migrated. Target end state: three lifetime tiers (PersistentState, RunState, WorldState).

---

### 3. Run / Campaign Layer

**Purpose:** Transient state for a single campaign run — campaign session, contract scenario, campaign outcome, phase/objective authority.

**Current files:**
- `custodian/game/world/procgen/custodian_contract_map.gd` — contract generation (runs = campaigns)
- `custodian/game/systems/core/systems/wave_manager.gd` — wave state tied to a run
- `custodian/game/systems/core/systems/enemy_director.gd` — threat/composition planning per run

**Target owner files:**
- `game/state/run/campaign_session.gd` — current run session authority
- `game/state/run/campaign_outcome.gd` — outcome recording and evaluation
- `game/state/run/run_phase.gd` — phase/objective state machine

**Allowed dependencies:** Persistent layer, contract map, world lifecycle
**Forbidden dependencies:** Actor-local behavior, presentation specifics
**Migration notes:** This layer does not yet exist as explicit objects. Current run state is implicit in autoloads. Extract when implementing the campaign loop spine (Phase 4).

---

### 4. World Lifecycle Layer

**Purpose:** Manages world transitions, active world binding, and world-level context — loading/unloading maps, anchor rebinding, spawn/cleanup contracts.

**Current files:**
- `custodian/game/systems/core/systems/contract_world_loader.gd` — currently does placement + world handoff (overburdened)
- `custodian/game/systems/core/player_controller.gd` — input router that transitions with world context
- `custodian/game/world/sundered_keep/sundered_keep_map.gd` — own map lifecycle

**Target owner files:**
- `game/world/lifecycle/world_transition_manager.gd` — world load/unload/transition authority
- `game/world/lifecycle/active_world_registry.gd` — tracks which world is active
- `game/world/lifecycle/world_context.gd` — world-scoped metadata and bindings
- `game/world/placement/` — placement orchestration services (extracted from `contract_world_loader.gd`)

**Allowed dependencies:** Persistent layer, Run layer
**Forbidden dependencies:** Actor-local behavior, Presentation layer specifics
**Migration notes:** This is the spine that bridges Home / Hub / Contract / Authored maps. Implementation deferred to Phase 4. `ContractWorldLoader` is the current de-facto lifecycle manager.

---

### 5. World Construction Layer

**Purpose:** Builds worlds — procgen generation, authored maps, routes/stages, terrain/elevation, placement/insertion services.

**Current files:**
- `custodian/game/world/procgen/` — procgen tilemap, intent graph, terrain, elevation, factions, story rooms, special rooms, gothic compound, portals, progression, roads
- `custodian/game/world/gothic_compound/` — authored connected compound map
- `custodian/game/world/sundered_keep/` — authored Sundered Keep connected map
- `custodian/game/world/approaches/` — authored approach vista scenes
- `custodian/game/world/routes/` — stage/route controllers
- `custodian/game/world/lighting/` — lighting profiles and directors
- `custodian/game/world/elevation/` — elevation metadata maps
- `custodian/game/world/home/` — Home beginning scene helpers
- `custodian/game/world/events/ash_bell/` — authored events

**Target owner files:** Same physical locations, with extracted services:
- `game/world/procgen/proc_gen_tilemap.gd` → coordinator façade only
- `game/world/procgen/generation/` — level data builder, candidate metrics
- `game/world/procgen/terrain/` — already extracted (TerrainBuilder)
- `game/world/procgen/foliage/` — foliage spawning service
- `game/world/procgen/roads/` — road graph builder
- `game/world/procgen/authored_claims/` — claim registry
- `game/world/procgen/intent/` — already extracted
- `game/world/placement/` — placement services (extracted from `contract_world_loader.gd`)

**Allowed dependencies:** Seeds/profiles from Run layer, elevation/interaction queries
**Forbidden dependencies:** Presentation layer, UI specifics
**Migration notes:** ProcGenTilemap should become a coordinator. TerrainBuilder and intent services are already extracted. Next extractions: foliage, roads, candidate metrics, authored claims. `CustodianContractMap` should own selection/scoring, not construction internals.

---

### 6. Simulation Layer

**Purpose:** Deterministic simulation systems — combat, enemies, power/sectors, ARRN, fabrication/resources, intel, world systems that do not belong to individual actors.

**Current files:**
- `custodian/game/systems/combat/` — melee attack profiles
- `custodian/game/systems/stealth/` — noise event bus
- `custodian/game/systems/intel/` — intel projector and demo
- `custodian/game/systems/cognitive/` — cognitive state values
- `custodian/game/systems/drone/` — drone manager/targeting
- `custodian/game/systems/spawning/` — ambient camps
- `custodian/game/systems/world/` — world state graph, history, heatmap
- `custodian/game/systems/simulation/` — interest manager
- `custodian/game/systems/core/systems/` — ambient critter manager, inventory manager, vault manager, ARRN manager, enemy factory, enemy director, wave manager, contract world loader (these need sorting)
- `custodian/autoload/` — resource ledger, build inventory, fab pipeline

**Target owner files:**
- `game/systems/combat/` — combat simulation and profiles
- `game/systems/enemies/` — enemy director, factory, wave manager
- `game/systems/power/` — power/sector systems
- `game/systems/arrn/` — ARRN manager and support
- `game/systems/fabrication/` — resource ledger, fab pipeline, build inventory
- `game/systems/resources/` — resource node logic
- `game/systems/intel/` — intel projection
- `game/systems/simulation/` — interest management, world phasing
- `game/systems/observability/` — world state graph, history, heatmap, dev observatory

**Allowed dependencies:** World construction (for queries), entity data
**Forbidden dependencies:** Actor-specific behavior, UI presentation
**Migration notes:** `game/systems/core/systems/` currently accumulates unrelated services. Move ARRN to `game/systems/arrn/`, enemy director/factory/wave manager to `game/systems/enemies/`, world loader lifecycle to `game/world/lifecycle/` and `game/world/placement/`.

---

### 7. Actor Layer

**Purpose:** Entity behavior and presentation — operator, enemies, allies/drones, vehicles, interactables, resources/storage.

**Current files:**
- `custodian/game/actors/operator/` — operator scripts and scenes
- `custodian/game/actors/enemies/` — enemy base class, behavior components, states
- `custodian/game/actors/allies/` — combat drone actors
- `custodian/game/actors/vehicles/` — vehicle scenes
- `custodian/game/actors/relay/` — relay entities
- `custodian/game/actors/terminal/` — command terminal prop
- `custodian/game/actors/defense/` — turret
- `custodian/game/actors/base/` — legacy vehicle base
- `custodian/game/actors/storage/` — vault storage
- `custodian/game/actors/items/` — pickups (cognitive, stolen resource)
- `custodian/game/vehicles/` — vehicle registry, spawn resolver, pilotable vehicle
- `custodian/game/enemies/procgen/` — variant factory, animation libraries

**Target owner files:**
- `game/actors/operator/` — same, with extracted helpers
- `game/actors/enemies/enemy.gd` — actor-core only (health, movement, target basics)
- `game/actors/enemies/enemy_animation_controller.gd` — extracted animation logic
- `game/actors/enemies/enemy_loot_award.gd` — extracted loot logic
- `game/actors/enemies/enemy_combat_receiver.gd` — extracted combat/parry logic
- `game/actors/enemies/archetypes/` — grunt, marine, shrumb archetypes
- `game/actors/enemies/abilities/` — phased dash attack, melee attack runner, parry receiver
- `game/actors/enemies/behavior/` — state machine, components, states
- `game/actors/allies/` — drones
- `game/actors/vehicles/` — vehicles
- `game/actors/interactables/` — shared interactable patterns
- `game/actors/resources/` — resource nodes
- `game/actors/storage/` — vault storage

**Allowed dependencies:** Simulation layer (for queries), world context
**Forbidden dependencies:** UI/presentation (actors expose read-only state only)
**Migration notes:** `enemy.gd` is the most overburdened file — split into actor-core, archetypes, abilities, and behavior components. Marine dash should become a reusable ability module.

---

### 8. Presentation Layer

**Purpose:** Player-facing UI — HUD, terminal, Black Reliquary components, minimap, debug surfaces. Must not own simulation state.

**Current files:**
- `custodian/game/ui/hud/` — HUD shell, terminal, debug screen
- `custodian/game/ui/terminal/` — terminal command routing, snapshots, previews
- `custodian/game/ui/components/` — Black Reliquary panels, prompts, icons, minimap frame
- `custodian/game/ui/theme/` — palette, styles, asset catalog
- `custodian/game/ui/minimap/` — minimap panel, controller, view
- `custodian/game/ui/inventory/` — inventory overlay
- `custodian/game/ui/game_over/` — game-over modal
- `custodian/game/ui/debug/` — dev observatory overlay
- `custodian/game/ui/intel_demo/` — intel fidelity demo

**Target owner files:** Same physical organization. No structural change needed — the UI layer is already well-sorted.

**Allowed dependencies:** Read-only snapshots from Simulation and Actor layers
**Forbidden dependencies:** Mutating simulation state, owning gameplay logic
**Migration notes:** UI is already separated. Maintain the rule that UI consumes read-only state and never writes deterministic data directly.

---

### 9. Developer / Observability Layer

**Purpose:** Debug tools, observability, validation — must never become gameplay authority.

**Current files:**
- `custodian/debug/` — DebugBus, DebugSnapshotCollector, DebugImGuiConsole
- `custodian/game/systems/debug/` — DevObservatory autoload
- `custodian/tools/validation/` — smoke tests and validation scripts
- `custodian/tools/` — pipelines, balance, levels, tiles, art tools

**Target owner files:** Same physical organization. No structural change needed.

**Allowed dependencies:** Read-only access to all layers via snapshots
**Forbidden dependencies:** Writing directly to simulation state (must use queued commands or debug overrides)
**Migration notes:** Keep this layer separate. Dear ImGui is dev-only. The F9 observatory and F12 debug screen are the canonical developer surfaces.

---

## Current vs Target Layer Map

| Layer | Current Primary Files | Target | Status |
|-------|----------------------|--------|--------|
| App / Boot | implicit in `game.tscn` | `game/app/` | Not started |
| Persistent Meta | `game_state.gd`, `game_stats.gd` | `game/state/persistent/` | Façade exists |
| Run / Campaign | implicit in contract gen | `game/state/run/` | Not started |
| World Lifecycle | `contract_world_loader.gd` | `game/world/lifecycle/` | Deferred (Phase 4) |
| World Construction | `game/world/procgen/` | `game/world/procgen/` with extractions | Partial extractions |
| Simulation | `game/systems/` (mixed) | `game/systems/{combat,enemies,power,arrn,fabrication,...}` | Mixed |
| Actor | `game/actors/` | `game/actors/` with archetype/ability split | Partial extractions |
| Presentation | `game/ui/` | `game/ui/` | Well-structured |
| Developer | `debug/`, `tools/validation/` | Same | Well-structured |

## Overburdened Coordinator Files

The following files own too many concerns and are the first extraction targets:

| File | Line Count (approx) | Concerns | Extraction Target |
|------|---------------------|----------|-------------------|
| `game/world/procgen/proc_gen_tilemap.gd` | ~5000+ | Path generation, terrain, elevation, foliage, roads, portals, authored claims, level data export, candidate metrics, intent graph, reservations | `game/world/procgen/{generation,terrain,foliage,roads,authored_claims}/` |
| `game/world/procgen/custodian_contract_map.gd` | ~800+ | Seed derivation, candidate loop, terrain acceptance, scoring, final visual regeneration | Keep selection; move construction internals to world construction layer |
| `game/systems/core/systems/contract_world_loader.gd` | ~600+ | World handoff, anchor placement, vehicle placement, ARRN relay placement, resource placement, connected-map instancing | `game/world/lifecycle/` + `game/world/placement/` |
| `game/actors/enemies/enemy.gd` | ~2000+ | Base enemy + procedural variants, grunt/marine animation, marine dash, parry handshake, loot awards, behavior hooks, stat recording | `game/actors/enemies/{core,archetypes,abilities,behavior}/` |
| `game/systems/core/state/game_state.gd` | ~300+ | Run state, fail-state, phase authority, debug fields | `game/state/{persistent,run,world}/` |

---

## Determinism Rules

- Keep gameplay-affecting random choices derived from explicit seeds.
- Contract world generation is deterministic from a single contract seed.
- Avoid frame-dependent mutation paths for combat/system logic.
- Simulation systems must produce identical output given identical input.
- Presentation layer may use frame-dependent logic for visual effects only.

## Current Boot Flow

1. `res://scenes/game.tscn` loads with autoloads and scene tree.
2. `CustodianContractMap` generates contract payload (planet + world profile).
3. `ContractWorldLoader` reparents `ProcGenMap` into active world.
4. Operator and spawn nodes repositioned from procgen `level_data`.
5. Connected maps (gothic compound, Sundered Keep) are placed as `WorldIngressSite` triggers.
6. Debug/observatory autoloads initialize: DevObservatory, WorldStateGraph, etc.

## Target Boot Flow (Phase 4+)

1. App layer selects mode: Home, Contract Sandbox, or Debug Preview.
2. Persistent layer loads hub/knowledge/campaign state.
3. Campaign layer creates a new session or restores in-progress run.
4. World lifecycle transitions between Home → Hub → Contract → Authored maps → Outcome.
5. World construction builds or loads the target map.
6. Simulation and Actor layers run in the active world context.
7. Presentation renders read-only state.

--- 

## Related Docs

- `docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` — compact agent-facing ownership map
- `docs/ai_context/FILE_INDEX.md` — high-signal file index
- `docs/ai_context/CURRENT_STATE.md` — current implementation state
- `docs/ai_context/task_packets/ARCHITECTURE_ORGANIZATION_PASS.md` — migration plan
- `design/04_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md` — cross-system integration contract
- `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md` — intended macro campaign loop
