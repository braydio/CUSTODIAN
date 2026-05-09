# Resource Fabrication System

**Project:** CUSTODIAN
**Created:** 2026-05-08
**Status:** design
**Last Updated:** 2026-05-08
**Roadmap:** v0.5.0 Free-Roam Pre-Assault — Resource Collection & Fabrication
**Depends on:** Free-roam traversal (v0.5.0), Existing operator interaction system, Existing InventoryManager autoload

---

## Purpose

Add resource-node harvesting and a minimal fabrication pipeline so recon/exploration feeds base defense preparation. This creates the economic loop that makes pre-assault preparation meaningful: explore → gather → fabricate → survive.

The system turns the existing "scavenge" design intent into concrete world objects and scripted behaviors without requiring a full survival-crafting system.

---

## Historical Context

This design synthesizes two brainstorming documents that were generated independently during design review of the CUSTODIAN project:

### Source Document 1: `design/RESOURCE_FABRICATION_PIPELINE.md`

Focused on the **mechanical implementation** of resource collection:
- Tree/ore/scrap nodes as interactable world objects
- `ResourceLedger` autoload as central resource accounting
- `PlayerResourceHarvester` as operator-side interaction component
- `FabricatorResourceBridge` to consume resources for build recipes
- Explicitly scoped to avoid survival-crafting bloat
- Provided complete GDScript pseudocode for all four core scripts
- Named the CUSTODIAN-flavored resource framing (deadfall blackwood, ruin-metal, etc.)

### Source Document 2: `design/RESOURCE_COLLECTION_PLAN.md`

Focused on the **spatial and strategic placement** of resources:
- Compound should have **limited, non-respawning tutorial nodes**
- Real resource income should come from **away maps / expedition zones**
- Three-stage rollout: Compound test nodes → Perimeter patches → Expedition maps
- Framed the core loop: Assault warning → Check fabricator needs → Choose site → Gather under danger → Return → Build → Survive

### Synthesis

Both documents agree on:
- Resource-node harvesting (not survival crafting)
- Four V1 resource types: timber, ore, scrap, power_components
- ResourceLedger as central economic authority
- Staged implementation to avoid overbuilding before core loop is validated

The Collection Plan adds the spatial staging the Pipeline doc assumes, and the Pipeline doc provides the implementation detail the Collection Plan defers. **This design document is the merged authority.**

---

## Scope

### In Scope (V1 — Compound Test Nodes)
- ResourceNode world objects (tree, ore, wreckage/scrap)
- ResourceLedger autoload for centralized resource accounting
- PlayerResourceHarvester component on the operator
- FabricatorResourceBridge for consuming resources
- Three debug/test nodes placed in the compound
- Four resource types: timber, ore, scrap, power_components
- Interaction prompts via existing InteractionLabel HUD element
- Resource deficit validation on fabricator recipes

### Out of Scope (V1)
- ❌ Survival-crafting system
- ❌ Loose item physics / dropped item pickups
- ❌ Tool durability or tool-specific requirements
- ❌ Freeform base building
- ❌ Procedural economy simulation
- ❌ Expedition maps or away-site generation
- ❌ Resource respawning
- ❌ Resource node procedural placement in procgen (V2)
- ❌ Animation/VFX for harvesting (placeholder art only)

---

## Design Philosophy

### Resource-Node Harvesting, Not Survival Crafting

Resources are **world objects** that the player walks up to and interacts with. There is no inventory UI, no crafting menu, no tool belt. The loop is:

```
See node → Walk to it → Press interact → Node depletes → Resources added to ledger → Fabricator can use them
```

### CUSTODIAN Flavor Over Generic Resources

Resources must feel like they belong in a ruined sci-fi world, not Minecraft:

| Resource | World Representation | Visual Framing |
|----------|---------------------|----------------|
| timber | Deadfall blackwood, fungal root mass, petrified trunk | Gnarled, alien-looking trees in ruin environments |
| ore | Exposed alloy veins, ferrous wreckage seams, ruin-metal deposits | Metallic crust, rusted structural remnants |
| scrap | Machine wreckage, old defense debris, fab conduit remains | Broken mechanical assemblies, wire bundles |
| power_components | Signal-wrecked relays, capacitor banks, rare salvage | Glowing or tech-looking parts (rarest) |

### Spatial Progression

Resources follow a deliberate **proximity-to-value** curve:
- **Compound** (tutorial): Limited, low-grade, non-respawning — teaches the mechanic
- **Perimeter** (early game): Small exterior zone — establishes the travel loop
- **Expedition maps** (mid/late game): Real resource income with tactical risk

This avoids the boring loop of "chop tree next to base forever" and creates meaningful expedition decisions.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  RESOURCE FABRICATION SYSTEM                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  World Layer                    Economic Layer              │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │  ResourceNode     │─────────▶│  ResourceLedger      │    │
│  │  (StaticBody2D)   │ harvest  │  (Autoload)          │    │
│  │                   │─────────▶│                      │    │
│  │  - tree           │  yield   │  - timber: 0         │    │
│  │  - ore vein       │          │  - ore: 0            │    │
│  │  - wreckage       │          │  - scrap: 0          │    │
│  └──────────────────┘          │  - power_comp: 0     │    │
│         │                      └──────────┬───────────┘    │
│         │ interacts                       │ spends          │
│         ▼                                 ▼                 │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │PlayerResource    │          │FabricatorResource    │    │
│  │Harvester         │          │Bridge                │    │
│  │(Component on     │          │(Recipe DB + Payment) │    │
│  │ Operator)         │          │                      │    │
│  └──────────────────┘          │  Recipes:            │    │
│                                 │  - barricade_light   │    │
│  Existing Systems              │  - turret_basic      │    │
│  ┌──────────────────┐          │  - power_bank_patch  │    │
│  │ InteractionLabel  │          └──────────────────────┘    │
│  │ (HUD Label)      │                                      │
│  ├──────────────────┤          Data Layer                   │
│  │ Operator         │          ┌──────────────────────┐    │
│  │ (CharacterBody2D)│          │  resource_defs.json  │    │
│  │                  │          │  (Resource metadata) │    │
│  │ - interaction_   │          └──────────────────────┘    │
│  │   range: 84px    │                                      │
│  └──────────────────┘                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Staged Implementation Roadmap

### Stage 1 — Compound Test Nodes (V1)

**Goal:** Get the mechanic working in the existing compound scene with a few hard-placed nodes.

**Scope:**
- ResourceLedger autoload
- ResourceNode scene + script
- PlayerResourceHarvester on operator
- FabricatorResourceBridge with 3 debug recipes
- 3 ruined trees, 2 ore deposits, 2 wreckage piles in `game.tscn`
- InteractionLabel shows nearest node prompt

**Validation:**
- Walk up to tree → see "CUT TIMBER (0/3)" prompt → press interact 3x → tree depletes → timber +6 in ledger
- Check fabricator recipes → confirm resource costs are enforced
- `FabricatorResourceBridge.try_start_build("barricade_light")` deducts only when sufficient

**Files created:**
| Path | Purpose |
|------|---------|
| `custodian/autoload/resource_ledger.gd` | Central resource accounting autoload |
| `custodian/game/resources/resource_node.gd` | Harvestable world object |
| `custodian/game/resources/resource_node.tscn` | Scene with Sprite2D + CollisionShape2D |
| `custodian/game/resources/player_resource_harvester.gd` | Operator-side harvest detection |
| `custodian/game/fabrication/fabricator_resource_bridge.gd` | Recipe cost checking + payment |
| `custodian/content/resources/resource_defs.json` | Resource type metadata |
| `design/features/implementation/RESOURCE_COLLECTION_SYSTEM.md` | Implementation tracking doc |

---

### Stage 2 — Perimeter Resource Patch

**Goal:** Add the first "leave the compound" harvesting loop without building a full world map.

**Scope:**
- A sub-area or small map just outside the compound gate
- Denser resource placement than compound (but still non-respawning)
- Establishes the travel loop pattern
- May include light environmental threat (ambient enemies)

**When to start:** After Stage 1 is validated in play and no disruptive bugs remain.

---

### Stage 3 — Expedition Resource Maps

**Goal:** Full expedition destinations with resource identity, tactical risk, and meaningful player choice.

**Scope:**
| Map | Resource Identity |
|-----|-------------------|
| Blackwood Verge | timber-heavy |
| Collapsed Foundry | ore-heavy |
| Dead Convoy Field | scrap-heavy |
| Signal-Wrecked Relay | power_components / rare salvage |

**When to start:** After the expedition system (world map, travel, extraction) exists.

---

## Components

### 1. ResourceLedger (Autoload)

**File:** `res://autoload/resource_ledger.gd`
**Type:** Autoload (registered in Project Settings → Autoload as `ResourceLedger`)
**Extends:** `Node`

Central economic authority. All resource additions and deductions flow through this singleton. Emits signals so HUD, terminal pages, and other systems can react to changes.

**Exports:** None (internal state only)

**Signals:**
| Signal | Arguments | Purpose |
|--------|-----------|---------|
| `changed` | `snapshot: Dictionary` | Any resource change — full state snapshot |
| `resource_added` | `resource_id: String, amount: int, new_total: int` | Resources gained |
| `resource_spent` | `cost: Dictionary` | Resources consumed by fabricator |

**Key Methods:**
| Method | Returns | Description |
|--------|---------|-------------|
| `get_amount(resource_id: String)` | `int` | Current count for a resource |
| `get_snapshot()` | `Dictionary` | Full copy of all resource counts |
| `add(resource_id: String, amount: int)` | `void` | Add resources (positive only) |
| `can_pay(cost: Dictionary)` | `bool` | Check if all costs are affordable |
| `pay(cost: Dictionary)` | `bool` | Deduct costs if affordable; returns false if insufficient |

**Initial state:**
```gdscript
{
    "timber": 0,
    "ore": 0,
    "scrap": 0,
    "power_components": 0
}
```

**Debug helper:** `debug_grant_starting_resources()` adds starter amounts for testing (timber 20, ore 12, scrap 30, power_components 2).

**Relationship to InventoryManager:** The existing `InventoryManager` autoload handles cognitive/Shrumb drops. `ResourceLedger` is a separate parallel ledger for fabrication resources. They may merge in a future logistics pass, but for V1 they remain separate to avoid coupling cognitive gameplay with the fabrication economy.

---

### 2. ResourceNode (Scene + Script)

**File:** `res://game/resources/resource_node.gd`
**Scene:** `res://game/resources/resource_node.tscn`
**Extends:** `StaticBody2D`
**Class name:** `ResourceNode`

A harvestable world object. Configured entirely through exports — no subclassing needed for tree vs. ore vs. wreckage.

**Exports:**
| Export | Type | Default | Purpose |
|--------|------|---------|---------|
| `node_kind` | enum (tree/ore/scrap) | `tree` | Visual category label |
| `harvest_action` | enum (cut/mine/salvage) | `cut` | Action required to harvest |
| `resource_id` | String | `timber` | Which resource this yields |
| `harvest_label` | String | `Harvest` | Short verb for UI prompt |
| `work_required` | int | 3 | Number of hits to deplete |
| `yield_amount` | int | 5 | Primary resource yield on depletion |
| `secondary_yields` | Dictionary | `{}` | Bonus resources on depletion (e.g. `{"scrap": 1}`) |
| `allow_repeat_harvest` | bool | `false` | Can this node be re-harvested? (V1: always false) |
| `standing_texture` | Texture2D | null | Sprite before depletion |
| `depleted_texture` | Texture2D | null | Sprite after depletion (stump/exhausted vein) |

**Internal state:**
| Variable | Type | Purpose |
|----------|------|---------|
| `_work_remaining` | int | Hits remaining until depleted |
| `_is_depleted` | bool | Has this node been fully harvested? |

**Behavior:**
1. On `_ready`: joins `resource_nodes` group, initializes work counter
2. `get_interaction_text()` returns prompt like `"CUT TIMBER (1/3)"`
3. `can_harvest(action)` checks action match + not depleted
4. `apply_harvest(action, work_amount=1)` reduces work, emits `harvested` signal
5. On depletion: adds yields to ResourceLedger, swaps texture, disables collision, emits `depleted`

**Node presets:**

| Property | Tree | Ore | Wreckage |
|----------|------|-----|----------|
| node_kind | tree | ore | scrap |
| harvest_action | cut | mine | salvage |
| resource_id | timber | ore | scrap |
| harvest_label | CUT | MINE | SALVAGE |
| work_required | 3 | 4 | 2 |
| yield_amount | 6 | 5 | 8 |
| secondary_yields | `{scrap: 1}` | `{scrap: 2}` | `{power_components: 1}` |

**Scene structure (resource_node.tscn):**
```
ResourceNode (StaticBody2D)
├── Sprite2D (texture set via script)
└── CollisionShape2D (disabled on depletion)
```

---

### 3. PlayerResourceHarvester (Component)

**File:** `res://game/resources/player_resource_harvester.gd`
**Extends:** `Node`
**Class name:** `PlayerResourceHarvester`
**Parent:** Operator node (sibling to operator.gd)

Detects nearest resource node each frame, updates the InteractionLabel, and routes interact presses into harvest attempts.

**Exports:**
| Export | Type | Default | Purpose |
|--------|------|---------|---------|
| `operator_path` | NodePath | — | Path to the operator CharacterBody2D |
| `interaction_label_path` | NodePath | — | Path to the HUD InteractionLabel |
| `interaction_range` | float | 84.0 | Max distance for resource interaction |
| `cut_action_name` | String | `interact` | Input action name for cutting |
| `mine_action_name` | String | `interact` | Input action name for mining |
| `salvage_action_name` | String | `interact` | Input action name for salvaging |

**Behavior:**
1. `_process(delta)`: Finds nearest non-depleted ResourceNode within range
2. Updates `interaction_label.text` with the node's prompt (or clears it)
3. On `interact` press: calls `_target.apply_harvest(action, 1)`
4. If wrong action: briefly shows `"WRONG TOOL / ACTION"`

**Integration note:** All three harvest actions currently map to `"interact"` — the Custodian's field multitool handles cutting, mining, and salvaging. Future tool modules can differentiate these.

**Interaction with PlayerController:** The existing `PlayerController` already handles `interact` for vehicle enter/exit. The `PlayerResourceHarvester` is a **separate component** that shares the same input action. There is no conflict because:
- Vehicle interaction requires being near a vehicle AND not in one
- Resource harvest requires being near a resource node
- These are mutually exclusive in practice (vehicles are not near resource nodes)

---

### 4. FabricatorResourceBridge (Helper)

**File:** `res://game/fabrication/fabricator_resource_bridge.gd`
**Extends:** `Node`
**Class name:** `FabricatorResourceBridge`

Recipe definition database + payment gateway. Consumes resources from ResourceLedger and reports success/failure.

**Signals:**
| Signal | Arguments | Purpose |
|--------|-----------|---------|
| `build_started` | `recipe_id: String` | Recipe successfully paid for |
| `build_failed` | `recipe_id: String, reason: String` | Payment rejected (unknown recipe or insufficient resources) |

**Debug recipes (V1):**
| Recipe ID | timber | ore | scrap | power_components |
|-----------|--------|-----|-------|------------------|
| `barricade_light` | 10 | 0 | 4 | 0 |
| `turret_basic` | 0 | 8 | 25 | 1 |
| `power_bank_patch` | 0 | 6 | 12 | 2 |

**Key Methods:**
| Method | Returns | Description |
|--------|---------|-------------|
| `can_build(recipe_id: String)` | `bool` | Check affordability + recipe exists |
| `try_start_build(recipe_id: String)` | `bool` | Attempt payment; emits success/failure signal |

---

### 5. Resource Definitions (Data)

**File:** `res://content/resources/resource_defs.json`

```json
{
    "timber": {
        "label": "Timber",
        "description": "Petrified root mass and deadfall suitable for crude structures."
    },
    "ore": {
        "label": "Raw Ore",
        "description": "Exposed metal-bearing deposits and ruin-veins."
    },
    "scrap": {
        "label": "Scrap",
        "description": "Generic fabrication feedstock recovered from wreckage."
    },
    "power_components": {
        "label": "Power Components",
        "description": "Rare salvage used for powered systems and fabricator upgrades."
    }
}
```

This file is for metadata/documentation. Runtime resource counts live in `ResourceLedger`. Fabricator costs live in `FabricatorResourceBridge.RECIPES`.

---

## Data Flow

### Harvest Flow

```
1. Player walks near ResourceNode
        │
        ▼
2. PlayerResourceHarvester._process() finds nearest node
   (checks distance ≤ interaction_range, node not depleted)
        │
        ▼
3. InteractionLabel updated with:
   "CUT TIMBER (0/3)"  or  "MINE ORE (2/4)"  or  "SALVAGE SCRAP (1/2)"
        │
        ▼
4. Player presses interact
        │
        ▼
5. Input.is_action_just_pressed("interact")
        │
        ▼
6. PlayerResourceHarvester._try_harvest_target()
        │
        ▼
7. ResourceNode.apply_harvest(harvest_action, 1)
   - Reduces _work_remaining by 1
   - Emits harvested(self, resource_id, remaining_work)
        │
        ▼
8. If _work_remaining ≤ 0:
   - ResourceLedger.add(resource_id, yield_amount)
   - ResourceLedger.add(secondary_id, amount) for each secondary yield
   - Sprite switches to depleted_texture
   - CollisionShape2D disabled
   - Emits depleted(self, resource_id, yield_amount)
```

### Fabrication Flow

```
1. Something calls FabricatorResourceBridge.can_build("barricade_light")
        │
        ▼
2. FabricatorResourceBridge.RECIPES["barricade_light"] = { timber: 10, scrap: 4 }
        │
        ▼
3. ResourceLedger.can_pay({ timber: 10, scrap: 4 })
   Returns true if timber ≥ 10 AND scrap ≥ 4
        │
        ▼
4. Something calls FabricatorResourceBridge.try_start_build("barricade_light")
        │
        ▼
5. ResourceLedger.pay({ timber: 10, scrap: 4 })
   - Deducts timber by 10
   - Deducts scrap by 4
   - Emits resource_spent({ timber: 10, scrap: 4 })
   - Emits changed(snapshot)
        │
        ▼
6. FabricatorResourceBridge emits build_started("barricade_light")
   (Consumer handles the actual spawn/construction)
```

---

## Integration Points

### Existing Systems

| System | Integration | Notes |
|--------|-------------|-------|
| **Operator** (`operator.gd`) | `PlayerResourceHarvester` added as child node | Uses existing `interaction_range` export; does not modify operator.gd |
| **PlayerController** (`player_controller.gd`) | Independent; shares `interact` input but targets different node groups | Separate responsibility; route interact to vehicle OR resource, not both |
| **InteractionLabel** (`UI` node in game.tscn) | `PlayerResourceHarvester` updates its `.text` property | No changes needed; already exists at `UI/InteractionLabel` path |
| **InventoryManager** (autoload) | Parallel system; separate ledger for cognitive drops vs. fabrication materials | May merge in future economy pass |
| **Power system** (`power.gd`) | Has `_get_fabrication_effectiveness()` — fabrication bridge should read this for scaling in V2 | V1 ignores power scaling |
| **WaveManager** | Fabricated defenses feed into sector/turret placement for wave defense | V1 bridge only adds recipes; no runtime placement |
| **Terminal HUD** (`ui.gd`) | Terminal has `_terminal_fabrication_queue` — V1 bridge can enqueue builds | Existing terminal fabrication commands should route through bridge |
| **Wall build system** (`wall_build_system.gd`) | Barricade_light recipe should eventually produce placable walls | V1: bridge only; no wall spawning yet |

### Project Settings

| Setting | Value |
|---------|-------|
| Autoload name | `ResourceLedger` |
| Autoload path | `res://autoload/resource_ledger.gd` |

---

## Asset Requirements

### V1 Placeholder Art (No Animation)

| Path | Purpose |
|------|---------|
| `custodian/assets/sprites/resources/tree_ruined_standing_01.png` | Tree node standing |
| `custodian/assets/sprites/resources/tree_ruined_stump_01.png` | Tree node depleted |
| `custodian/assets/sprites/resources/ore_vein_standing_01.png` | Ore node standing |
| `custodian/assets/sprites/resources/ore_vein_depleted_01.png` | Ore node depleted |
| `custodian/assets/sprites/resources/wreckage_salvage_01.png` | Wreckage node standing |
| `custodian/assets/sprites/resources/wreckage_depleted_01.png` | Wreckage node depleted |

### V2 Polish (Priority Optional)

| Path | Purpose |
|------|---------|
| `custodian/assets/sprites/resources/tree_chop_fx_01.png` | Chop impact effect |
| `custodian/assets/sprites/resources/ore_mine_fx_01.png` | Mining spark effect |
| `custodian/assets/sprites/resources/salvage_spark_fx_01.png` | Salvage effect |

### Art Workflow

No production animation is required for V1. Use colored placeholder shapes or repurpose existing environment sprites as temporary stand-ins. Follow the established sprite pipeline at `custodian/content/sprites/_pipeline/` when production art is requested.

---

## File Layout

```
custodian/
├── autoload/
│   └── resource_ledger.gd                    ← NEW: Autoload
├── game/
│   ├── resources/                             ← NEW: Resource collection module
│   │   ├── resource_node.gd                   ← ResourceNode script
│   │   ├── resource_node.tscn                 ← ResourceNode scene
│   │   └── player_resource_harvester.gd       ← Player-side harvester component
│   └── fabrication/                           ← NEW: Fabrication module
│       └── fabricator_resource_bridge.gd      ← Recipe bridge
├── content/
│   └── resources/
│       └── resource_defs.json                 ← NEW: Resource metadata
└── assets/
    └── sprites/
        └── resources/                         ← NEW: Placeholder sprite art
            ├── tree_ruined_standing_01.png
            ├── tree_ruined_stump_01.png
            ├── ore_vein_standing_01.png
            ├── ore_vein_depleted_01.png
            ├── wreckage_salvage_01.png
            └── wreckage_depleted_01.png

design/
├── 02_features/
│   └── resource_fabrication/
│       └── RESOURCE_FABRICATION_SYSTEM.md     ← THIS FILE
├── features/
│   └── implementation/
│       └── RESOURCE_COLLECTION_SYSTEM.md      ← NEW: Implementation tracking
├── RESOURCE_FABRICATION_PIPELINE.md           ← Preserved: Brainstorm source 1
└── RESOURCE_COLLECTION_PLAN.md                ← Preserved: Brainstorm source 2
```

---

## Configuration Reference

### ResourceNode Presets Summary

| Property | Tree | Ore | Wreckage |
|----------|------|-----|----------|
| `node_kind` | `tree` | `ore` | `scrap` |
| `harvest_action` | `cut` | `mine` | `salvage` |
| `resource_id` | `timber` | `ore` | `scrap` |
| `harvest_label` | `CUT` | `MINE` | `SALVAGE` |
| `work_required` | 3 | 4 | 2 |
| `yield_amount` | 6 | 5 | 8 |
| `secondary_yields` | `{"scrap": 1}` | `{"scrap": 2}` | `{"power_components": 1}` |

### V1 Fabricator Recipes

| Recipe ID | timber | ore | scrap | power_components |
|-----------|--------|-----|-------|------------------|
| `barricade_light` | 10 | — | 4 | — |
| `turret_basic` | — | 8 | 25 | 1 |
| `power_bank_patch` | — | 6 | 12 | 2 |

---

## Validation

### Manual Test Cases (Stage 1)

```
Test 1: Basic Harvest
  1. Place ResourceNode (tree preset) near operator spawn
  2. Walk within 84px → InteractionLabel shows "CUT TIMBER (0/3)"
  3. Press interact → label updates to "CUT TIMBER (1/3)"
  4. Press interact 2 more times → node depletes, texture swaps to stump
  5. Open debug console → `ResourceLedger.get_amount("timber")` returns 6
  6. Confirm scrap increased by 1 (secondary yield)

Test 2: Wrong Action
  1. Place ore node, walk up to it
  2. InteractionLabel shows "MINE ORE (0/4)"
  3. Note: harvester uses node's harvest_action for verification;
     currently all actions = "interact" so no conflict in V1

Test 3: Depleted Node Rejection
  1. Fully harvest a resource node
  2. Walk away and back → InteractionLabel shows nothing
  3. Press interact → no effect

Test 4: Fabricator Payment
  1. `ResourceLedger.debug_grant_starting_resources()`
  2. `FabricatorResourceBridge.can_build("barricade_light")` → true
  3. `FabricatorResourceBridge.try_start_build("barricade_light")` → true
  4. `ResourceLedger.get_amount("timber")` → 10 (was 20)
  5. `FabricatorResourceBridge.try_start_build("turret_basic")` → true (scrap 30-25=5)
  6. `FabricatorResourceBridge.try_start_build("turret_basic")` → false (scrap 5 < 25)

Test 5: Fabricator Insufficient Funds
  1. `ResourceLedger._resources = {}` (clear all)
  2. `FabricatorResourceBridge.can_build("barricade_light")` → false
  3. `FabricatorResourceBridge.try_start_build("barricade_light")` → false
  4. Signal `build_failed("barricade_light", "Insufficient resources")` emitted

Test 6: Unknown Recipe
  1. `FabricatorResourceBridge.can_build("nonexistent_recipe")` → false
  2. `FabricatorResourceBridge.try_start_build("nonexistent_recipe")` → false
  3. Signal `build_failed("nonexistent_recipe", "Unknown recipe")` emitted
```

### Godot Script Check

```bash
cd custodian
godot --headless --quit
```

---

## Known Issues

| Issue | Severity | Workaround |
|-------|----------|------------|
| All harvest actions map to same input (`interact`) | Low | Acceptable for V1; tool differentiation is V2 |
| No resource HUD | Low | Check via terminal or debug console in V1 |
| Nodes do not respawn | Low | Intentional for V1; expedition maps add renewable sources later |
| No power scaling on fabrication | Low | V1 recipes are flat costs; V2 should read `power.gd._get_fabrication_effectiveness()` |
| InteractionLabel shared between resources and vehicle prompts | Low | Vehicles and resource nodes are spatially separate; no practical conflict |

---

## Future Considerations

### V1.1 — HUD Integration
- Add resource counts to HUD (small panel showing timber/ore/scrap/power_components)
- Terminal FABRICATION page showing available recipes and current resources
- Fabrication queue status in terminal

### V1.2 — Power-Aware Fabrication
- Fabricator speed/cost scaling based on `power.gd._get_fabrication_effectiveness()`
- Fabricator requires power to operate
- Blackout stops fabrication

### V2 — Expedition Maps
- Procedural resource node placement in procgen world generation
- Resource identity per region (timber-heavy forest zones, ore-heavy industrial ruins)
- Respawn timing or migration patterns
- Environmental threats during harvest

### V2.1 — Tool Differentiation
- Cut/mine/salvage require different operator tool modules
- Tool durability and repair costs
- Upgraded tools yield more resources per hit

### V3 — Economy Depth
- Merge ResourceLedger with InventoryManager for unified logistics
- Resource conversion recipes (e.g., scrap + power = refined materials)
- Trading with other survivors / outposts
- Resource transport via vehicles

---

## Appendices

### A. Relationship to Design Brainstorms

This document supersedes both `design/RESOURCE_FABRICATION_PIPELINE.md` and `design/RESOURCE_COLLECTION_PLAN.md` as the single design authority for resource collection and fabrication. Those source documents are preserved for historical context and design rationale.

| Document | Role |
|----------|------|
| `design/RESOURCE_FABRICATION_PIPELINE.md` | Source: Implementation-level pseudocode and script contracts |
| `design/RESOURCE_COLLECTION_PLAN.md` | Source: Strategic staging and spatial design |
| `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md` | **Active:** Merged design authority (this file) |

### B. Connection to Master Roadmap

| Milestone | Feature | Status |
|-----------|---------|--------|
| v0.5.0 Free-Roam Pre-Assault | Scavenge/pickup system | **design** |
| v1.0 Power & Logistics | Fabrication system | **design** (rolled into this doc) |

The Stage 1 implementation (compound test nodes) feeds into v0.5.0. The full fabrication pipeline connects to v1.0. See `design/00_meta/MASTER_ROADMAP.md` for milestone context.
