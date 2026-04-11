# `design/20_features/in_progress/REGION_GENERATION_SYSTEM.md`

# Region Generation System

**Project:** CUSTODIAN
**Status:** Required After Runtime Stabilization, Hub Foundation, and World Transition Baseline
**Priority:** High
**Depends On:** Runtime World & Camera Stabilization, Hub System (Meta Progression), World Transition System
**Blocks:** Campaign Flow & Game Loop, Integration Contract, Biome Runtime Expansion
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-04-08
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

---

## 1. Purpose

Define the system that generates transient campaign regions from Hub-selected scenarios and turns them into playable runtime worlds with coherent topology, biome identity, objective placement, threat pressure, extraction structure, and deterministic reproducibility.

This system is not generic procgen for procgen’s sake. It exists to answer one specific need in the larger architecture:

> a selected `CampaignScenario` must become a concrete region world that can be entered, traversed, fought through, partially completed, abandoned, resolved, and then discarded.

The Hub already defines persistent proposal logic and the World Transition System defines how authoritative world contexts switch. This file defines what actually gets built on the other side of that transition.

It must preserve four already-established truths:

1. campaign worlds are transient and disposable, unlike the persistent Hub 
2. the active runtime is Godot-authoritative and fixed-step deterministic 
3. contract/procgen world promotion is already part of the runtime baseline 
4. designer-authored room-template hybrid generation is already an active implementation path via Edgar/Tiled room templates, not just raw noise fields 

This file is the **region-construction authority**. For the fiction meaning of Contracts, legibility classes, factions, procedural lore stack, and environmental storytelling rules, defer to `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`.

---

## 2. Why This System Exists

The project has moved beyond a single defense map. The roadmap and project status already frame the future direction as a campaign-driven structure with multiple world contexts, biome variation, mission offers, and free-roam or mission deployment beyond one fixed compound. The current runtime already includes procgen contract generation, map promotion, and world previews, but those are still centered on the current compound/combat slice rather than scenario-driven external regions.  

The Region Generation System exists to bridge that gap.

Without it:

* the Hub can generate offers, but they have nowhere meaningful to go
* the World Transition System can deploy into a campaign world, but that world has no authoritative construction rules
* difficulty, biome, and threat profile remain abstract labels instead of runtime consequences
* procedural campaigns feel like reskinned copies of the same map

With it:

* each accepted scenario becomes a deterministic, materially distinct, mechanically legible world
* replayability comes from scenario-conditioned structure rather than random clutter
* biome, threat, victory type, and uncertainty become world-building inputs, not UI flavor text

---

## 3. Design Intent

This system should produce regions that are:

### 3.1 Deterministic

The same scenario input and seed produce the same region layout, objective topology, hazard distribution, and spawn plan.

### 3.2 Legible

The player must be able to understand the navigable shape, probable objective direction, and major danger contours at runtime.

### 3.3 Scenario-Conditioned

Biome, threat profile, victory type, and scenario archetype must materially affect structure.

They should also affect what the world appears to have been, how it failed, how it was reused, and what false local reading dominates it.

### 3.4 Hybrid

Use authored room templates where they improve structure and identity; use procedural assembly where they improve replayability. The existing Edgar room-template direction is the correct backbone for this. 

### 3.5 Disposable

Regions are not persistent homesteads or revisitable open worlds. They exist to support one campaign instance and then be destroyed.

### 3.6 Systemic

Objectives, hazards, extraction, enemy ingress, and encounter pacing must come from the generation model, not be manually placed one by one.

The region should feel like a recoverable place with evidence, not a neutral arena with enemies dropped into it.

---

## 4. Non-Goals

This file does **not** define:

* Hub-side scenario proposal generation
* transition phase logic between compound and campaign worlds
* compound construction and wall tile systems
* low-level camera stabilization implementation
* detailed combat tuning or enemy AI behavior internals
* authored story scripting for every mission
* save-file schema for every entity in every region

It does define the world-construction rules those systems rely on.

---

## 5. Core Principle

A region is not a random tilemap.

A region is:

> a scenario-conditioned topological graph that is then spatialized into a playable world.

This distinction matters.

The generator should first decide:

* what kind of campaign this is
* what spaces are required
* how those spaces connect
* where risk and reward should sit
* what the player’s operational route will feel like

Only then should it assemble geometry, tiles, hazards, and entities.

If you skip the graph layer and go straight to tile noise or ad hoc room scattering, regions will feel shapeless.

Second core rule: a region should encode **procedural evidence**, not merely shape. Generation should preserve room for original function, collapse pattern, reuse pattern, present ideology, surviving truth, and false local interpretation.

---

## 6. Relationship to Existing Systems

This file must align with three major existing directions.

### 6.1 Hub System

The Hub creates `CampaignScenario` objects containing scenario seed, biome, difficulty, threat profile, victory structure, uncertainty, and reward profile. This region generator consumes that object, not a loose set of unrelated parameters.

### 6.2 World Transition System

World transition handles deployment and return. This generator provides the world-spec output that transition can build/bind.

### 6.3 Existing Procgen + Edgar Direction

There is already an implementation doc for Edgar-based room templates and hybrid assembly using Tiled templates, room graphs, door properties, and stitched layouts. That is the correct structural direction and should be treated as part of this system, not a separate competing procgen philosophy. 

---

## 7. Region Generation Responsibilities

The Region Generation System owns the following responsibilities.

### 7.1 Convert Scenario to RegionSpec

Translate abstract scenario fields into concrete world-generation parameters.

### 7.2 Build Region Topology

Create a graph of required spaces, optional spaces, chokepoints, branches, ingress, and extraction.

### 7.3 Spatialize Topology

Turn abstract graph nodes into room templates, corridor chains, terrain clusters, or mixed modules.

### 7.4 Paint World Identity

Apply biome tile palette, environmental hazards, structural dressing, visibility conditions, and encounter semantics.

This pass should also carry first-pass lore-bearing identity through:

- provenance tags
- signage/dressing families
- reuse markers
- procedural tableau opportunities
- faction-compatible machine language

### 7.5 Place Objectives

Spawn primary and optional objectives in structurally appropriate locations.

### 7.6 Place Threat Infrastructure

Determine spawn zones, pressure lanes, patrol basins, ambush pockets, and escalation anchors.

### 7.7 Export Runtime Payload

Produce a fully-baked region world or a structured payload that the runtime can instantiate into the campaign world.

That payload should reserve fields for lore-bearing generation metadata even if the first runtime implementation only consumes a subset.

---

## 7A. Content-Facing Generation Rules

Every generated region should eventually be able to answer:

- What was this place originally for?
- How did it collapse or become severed from its prior function?
- Who uses it now?
- What is actually true here?
- What do current occupants believe instead?

For first-pass implementation, the generator should at minimum support tags or derived fields for:

- `original_function`
- `collapse_mode`
- `post_collapse_reuse`
- `present_ideology`
- `surviving_truth`
- `false_local_interpretation`

These do not need to produce full authored prose. They should drive environment dressing, inspect pools, encounter posture, and machine-language snippets.

---

## 8. Canonical Input Model

The generator should accept exactly one authoritative scenario input plus optional debug overrides.

```gdscript id="u9zk7b"
func generate_region_from_scenario(
    scenario: CampaignScenario,
    debug_overrides: Dictionary = {}
) -> GeneratedRegion
```

The scenario must already contain:

* seed
* biome
* difficulty
* threat profile
* archetype
* victory type
* uncertainty metadata
* reward profile

That structure is already defined in the Hub System doc and should not be recomputed here.

---

## 9. Canonical Output Model

The generator must output a typed runtime product.

```gdscript id="3d50p5"
class_name GeneratedRegion
extends Resource

var scenario_id: String
var campaign_id: String
var region_seed: int
var world_bounds: Rect2
var graph: RegionGraph
var room_instances: Array[GeneratedRoom] = []
var corridor_instances: Array[GeneratedCorridor] = []
var objective_nodes: Array[ObjectiveAnchor] = []
var extraction_nodes: Array[ExtractionAnchor] = []
var hazard_zones: Array[HazardZone] = []
var spawn_zones: Array[SpawnZone] = []
var tile_payload: Dictionary = {}
var level_data: Dictionary = {}
var world_scene_path: String = ""
```

### 9.1 Why This Matters

The output needs to be inspectable, serializable, and reusable by:

* transition system
* mission logic
* debug tools
* save/load
* objective manager
* encounter managers

If region generation only returns a scene instance with no structured description, you lose too much systemic visibility.

---

## 10. Topological First, Geometry Second

This is the most important implementation principle in the entire file.

The region generator should have two broad phases:

### Phase A: Intent Graph

Build the mission structure as a graph of:

* entry
* progression rooms
* branching optional spaces
* primary objective sites
* extraction routes
* choke corridors
* hazard gates
* threat basins

### Phase B: Spatial Assembly

Assign physical templates and coordinates to that graph, then stamp tiles/entities.

This mirrors the direction already described in the Edgar room template doc, where room types, connectivity constraints, and template-driven layout precede assembly. 

---

## 11. Region Topology Model

The generator should use a graph model as the authoritative pre-spatial region description.

```gdscript id="9m0a7c"
class_name RegionGraph
extends Resource

var nodes: Array[RegionNode] = []
var edges: Array[RegionEdge] = []
var entry_node_id: String = ""
var primary_objective_node_ids: Array[String] = []
var extraction_node_ids: Array[String] = []
```

### 11.1 `RegionNode`

```gdscript id="et2n45"
class_name RegionNode
extends Resource

var id: String
var node_type: String              # entry, corridor, objective, extraction, hazard, staging, optional, stronghold
var structural_role: String        # hub, branch, choke, dead_end, basin, connector
var biome_tags: Array[String] = []
var threat_weight: float = 0.0
var hazard_weight: float = 0.0
var visibility_class: String = ""
var template_candidates: Array[String] = []
var metadata: Dictionary = {}
```

### 11.2 `RegionEdge`

```gdscript id="t2bt0v"
class_name RegionEdge
extends Resource

var from_node_id: String
var to_node_id: String
var edge_type: String              # corridor, breach, tunnel, open_ground, bridge
var traversal_pressure: float = 0.0
var expected_resistance: float = 0.0
var visibility_class: String = ""
var metadata: Dictionary = {}
```

### 11.3 Why Graph Roles Matter

A mission “feels” different when its graph changes even if the art palette stays the same.

Examples:

* containment mission: concentric or inward-closing graph
* recovery mission: deep push to a valuable node, then reverse-pressure extraction
* stabilization mission: central defended basin with multiple failing support branches
* observation mission: sparse movement graph with multiple sightline-driven reveal sites

That is how you make mission types structurally distinct.

---

## 12. Region Archetypes

The earlier design work already suggested safe procedural archetypes such as recovery, excavation, containment, observation, and interdiction. Those should become generation presets, because they define map logic better than just victory labels. 

### 12.1 Recovery

Goal: reach, secure, and possibly extract from a deep-value node.

Graph tendencies:

* long mainline
* medium branch count
* strong terminal objective chamber
* return pressure on extraction
* optional side chambers with archive fragments or tool caches

### 12.2 Excavation

Goal: search or uncover across multiple related nodes.

Graph tendencies:

* multiple mid-depth objective clusters
* moderate sprawl
* soft choke structure
* higher optional-room density
* hazard exposure and repeated travel

### 12.3 Containment

Goal: stop spread or isolate an unstable core.

Graph tendencies:

* central danger source
* ring or spoke topology
* support nodes required to weaken/contain core
* mounting pressure if player delays

### 12.4 Observation

Goal: gather information, confirm hypotheses, survive, exfil.

Graph tendencies:

* multiple survey points
* long sightline spaces
* less dense combat by default
* high ambiguity and threat uncertainty
* extraction may be remote rather than local

### 12.5 Interdiction

Goal: strike a moving or distributed threat network.

Graph tendencies:

* multiple pressure nodes
* route selection matters heavily
* optional targets may reduce later intensity
* higher time-to-value tradeoffs

These archetypes should be upstream of exact room placement.

---

## 13. Victory Type Translation

Victory type still matters independently of archetype and should modulate graph output.

The current roadmap already uses:

* RECOVERY
* STABILIZE
* CONTAINMENT
* NEUTRALIZE 

### 13.1 Recovery

* one or more retrieval anchors
* extraction path mandatory
* reward scaling tied to recovered count

### 13.2 Stabilize

* one or more interaction or repair sites
* usually defend/hold or reactivate sequence
* may end in local secure state rather than extraction

### 13.3 Containment

* perimeter control, seal nodes, or shutoff clusters
* hazard system must matter mechanically

### 13.4 Neutralize

* destroy target hierarchy or key threat organism/system
* stronghold or multi-wave site structure likely

Victory type should modify:

* required node count
* objective ordering
* extraction requirement
* failure conditions
* encounter pressure curve

---

## 14. Biome System

The earlier roadmap identified a set of campaign biomes:

* ruined urban
* arid wasteland
* subterranean complex
* bio-overgrown zone
* orbital derelict 

Biome should not just change art. It should affect:

* room templates
* traversal style
* visibility
* hazard frequency
* environmental resistance profile
* encounter posture

### 14.1 Ruined Urban

Structural identity:

* fractured built spaces
* collapsed corridors
* multi-entry blocks
* debris chokepoints

Mechanical tendencies:

* medium cover density
* structural instability hazard chance
* broken sightlines
* ambush corners

### 14.2 Arid Wasteland

Structural identity:

* sparse hard structures in exposed open traversal
* long lines of sight
* wind-scoured pathways

Mechanical tendencies:

* radiation hazard pockets
* low cover
* high visible approach pressure
* extraction and route planning matter more

### 14.3 Subterranean Complex

Structural identity:

* tunnels, shafts, chambers, utilities
* constrained navigation
* layered route tension

Mechanical tendencies:

* low visibility
* signal echo
* claustrophobic pressure
* chokepoints dominate

### 14.4 Bio-Overgrown Zone

Structural identity:

* mixed ruined structure + organic overtake
* soft barriers
* asymmetrical room boundaries

Mechanical tendencies:

* biocontamination
* mutable traversal zones
* hidden nest or growth clusters
* ambiguous silhouette readability

### 14.5 Orbital Derelict

Structural identity:

* hard modular structures
* decompression breaches
* zero-g themed motifs without necessarily implementing full zero-g traversal

Mechanical tendencies:

* structural instability
* directional traversal pressure
* compartment sealing
* hard segmented objective structure

Biome should therefore be a generation preset, tileset bundle, hazard palette, and template filter.

---

## 15. Threat Profile Translation

Threat profile must affect structure, not just enemy type lists.

### 15.1 Threat Inputs

From scenario:

* dominant threat
* secondary threats
* signal confidence
* difficulty-adjusted aggression expectation

### 15.2 Threat Structural Effects

#### Mutated Organics

* nests
* spread corridors
* high branch contamination
* fleshy overgrowth in node dressing
* threat often emanates outward from cluster cores

#### Autonomous War Machines

* patrol loops
* defended open lanes
* hardpoint rooms
* sensor arcs
* cleaner geometric zone ownership

#### Post-Human Factions

* fortified chambers
* adaptive routing
* purposeful occupation zones
* trap or doctrine-shaped spaces

#### Feral Defense Systems

* broken but active machinery clusters
* misaligned security corridors
* local reactivation or hazard overlap

#### Unknown Anomaly

* less predictable graph pressure
* environmental oddities
* nonstandard hazard placement
* lower information confidence, higher ambiguity

The generator should expose a “structural fingerprint” per threat family.

---

## 16. Difficulty Conditioning

Difficulty score should influence world structure in clear ways, not just enemy HP.

### 16.1 Difficulty-Driven Structural Factors

* number of branch nodes
* objective depth from entry
* fallback route count
* chokepoint density
* hazard overlap
* extraction distance
* spawn-zone count
* reinforcement angle count
* optional reward accessibility
* safe-room scarcity

### 16.2 Important Design Rule

Higher difficulty should not only mean “more enemies.” It should also mean:

* less informational certainty
* worse route forgiveness
* more hostile topology
* more punishing extraction

This matches the Hub-side principle that challenge should influence density, aggression, scarcity, and objective complexity rather than just raw scaling. 

---

## 17. Required RegionSpec Layer

Before building the final region, the generator should normalize scenario input into a concrete generation spec.

```gdscript id="97znaz"
class_name RegionSpec
extends Resource

var scenario_id: String
var region_seed: int
var archetype: String
var victory_type: String
var biome: String
var difficulty_score: float
var dominant_threat: String
var secondary_threats: Array[String] = []

var required_node_counts: Dictionary = {}
var branch_factor: float = 0.0
var desired_depth: int = 0
var hazard_density: float = 0.0
var encounter_density: float = 0.0
var extraction_required: bool = true
var template_pool: Array[String] = []
var hazard_pool: Array[String] = []
var spawn_profile: Dictionary = {}
var objective_profile: Dictionary = {}
```

This gives the generator a stable internal contract.

---

## 18. Hybrid Template Strategy

The Edgar room template system should be treated as the primary spatialization method for structured regions where possible. That document already proposes:

* room templates in Tiled
* door metadata per direction
* room graph definitions
* layouts assembled from templates and corridor rules 

### 18.1 Recommended Region Generation Modes

#### Mode A: Template-Dominant

Use authored rooms/corridors for most graph nodes, ideal for:

* subterranean complex
* orbital derelict
* fortified urban blocks
* high-structure missions

#### Mode B: Hybrid Template + Terrain

Use authored key rooms plus procedural terrain corridors/open zones, ideal for:

* arid wasteland
* bio-overgrown zone
* mixed exterior/interior missions

#### Mode C: Procedural Basin with Authored Anchors

Use large procedural terrain field with authored objective/extraction structures, ideal for:

* large open recovery routes
* unstable anomaly fields
* observation or interdiction missions in sparse landscapes

The system should support all three modes.

---

## 19. Template Taxonomy

Region templates should be typed by mission function, not just shape.

Examples:

* `entry_pad`
* `corridor_h`
* `corridor_v`
* `junction_3way`
* `junction_4way`
* `stronghold_small`
* `stronghold_large`
* `archive_chamber`
* `reactor_room`
* `growth_nest`
* `sensor_hall`
* `collapsed_street`
* `waste_processing`
* `observation_spire`
* `bridge_segment`
* `sealed_vault`
* `exfil_platform`

Each template should advertise:

* compatible biomes
* structural role
* door definitions
* recommended objective/hazard compatibility
* cover density class
* visibility class

---

## 20. Required Room Metadata

This expands on the existing Edgar room-template approach.

### 20.1 Required Room Properties

* `room_type`
* `biome_tags`
* `structural_role`
* `danger_class`
* `visibility_class`
* `supports_objective_types`
* `supports_extraction`
* `supports_spawn`
* directional door metadata

### 20.2 Why This Matters

Without typed metadata, the generator can only stitch by shape, not by mission meaning.

---

## 21. Objective Placement Rules

Objectives should be graph-aware and role-aware.

### 21.1 Primary Objective Rules

A primary objective node should:

* be reachable
* not overlap extraction by default
* sit at intended mission depth
* fit victory type semantics
* support adequate encounter/readability space around it

### 21.2 Optional Objective Rules

Optional subvictories should:

* sit off mainline or in moderate-risk detours
* not be free pickups on the critical path
* influence route selection
* provide reason to overextend

### 21.3 Objective Types

Examples:

* archive fragment cluster
* reactor stabilization console
* containment seal node
* command uplink relay
* anomaly anchor
* biological sample chamber
* tactical schematics vault

The generator should never place an objective in a template that does not explicitly support it.

---

## 22. Extraction Placement Rules

If a scenario requires extraction, extraction must be its own generation problem.

### 22.1 Extraction Modes

* return-to-entry
* remote extraction pad
* unlocked exfil after objective
* multi-pad candidate extraction
* emergency fallback extraction after failure state

### 22.2 Placement Factors

* mission archetype
* objective completion order
* difficulty
* threat family
* whether backtracking is intended tension or boring redundancy

### 22.3 Strong Rule

Do not always place extraction at the far edge of the map. Sometimes:

* return route pressure is the point
* sometimes extraction near entry is correct after deep objective traversal
* sometimes alternate exfil unlocks after objective completion

---

## 23. Hazard System

Hazards must be first-class generation outputs.

### 23.1 Hazard Classes

* radiation
* bio-contamination
* structural instability
* signal echo / jamming
* decompression breach
* corrosive seep
* electrical discharge
* low-visibility fog/dust/spores

### 23.2 Hazard Roles

Hazards can serve as:

* path tax
* route denial
* objective complication
* pacing separator
* environmental storytelling
* pressure amplifier during extraction

### 23.3 Placement Rules

Hazards should:

* reinforce biome identity
* reinforce threat identity when appropriate
* never completely destroy readability
* rarely overlap at full severity unless the scenario explicitly calls for it

### 23.4 Example

Subterranean containment mission:

* central contamination plume
* side-route electrical hazard
* low visibility in tunnel connectors
* seal nodes positioned at hazard boundaries

That is more interesting than random lava puddles equivalent.

---

## 24. Spawn and Pressure Zones

Threats should not simply appear uniformly.

### 24.1 Spawn Zone Types

* ambient pressure zone
* reinforcement ingress
* nest/core emergence
* patrol basin
* delayed escalation gate
* extraction pressure spawn

### 24.2 Structural Placement Rules

Spawn zones should be tied to:

* graph node role
* threat family
* player progress triggers
* objective state
* visibility and cover conditions

### 24.3 Good Pressure Shapes

* flank reinforcement from branch node after objective completion
* repeated organic emergence from contaminated core
* machine patrol loops in open high-visibility lanes
* post-human fallback response from stronghold-connected chambers

### 24.4 Bad Pressure Shapes

* uniform spawn circles
* random enemy piles in dead-end closets
* objective rooms with no ingress logic
* extraction zone fully surrounded with no readable approach lanes

---

## 25. Encounter Density and Quiet Space

A strong region requires alternating pressure and comprehension.

### 25.1 Quiet Spaces

These are important. Include:

* staging rooms
* observation perches
* low-threat transitions
* optional loot/knowledge pockets
* route-choice chambers

### 25.2 Why Quiet Spaces Matter

Without them:

* pacing flattens
* objective comprehension suffers
* extraction tension feels identical to travel tension
* every region becomes an endless pressure blob

---

## 26. Visibility Model

Visibility should be a generation parameter, not just a post-process effect.

### 26.1 Visibility Classes

* open
* segmented
* claustrophobic
* obstructed
* low-visibility
* long-sightline

### 26.2 What It Influences

* template selection
* objective readability
* patrol value
* ranged-vs-melee threat potency
* extraction stress

### 26.3 Biome Interaction

* arid wasteland favors long-sightline/open with dust or heat-haze interruptions
* subterranean favors segmented/claustrophobic
* ruined urban favors obstructed + broken open intersections
* orbital derelict favors compartmental segmented with occasional clean corridors

---

## 27. Region Assembly Pipeline

This is the implementation heart of the system.

### Step 1 — Normalize Scenario into RegionSpec

Derive structural parameters from the accepted scenario.

### Step 2 — Build RegionGraph

Create abstract topology with node roles and edge semantics.

### Step 3 — Choose Assembly Mode

Template-dominant, hybrid, or terrain-dominant.

### Step 4 — Assign Templates to Nodes

Resolve candidates using:

* biome compatibility
* role compatibility
* objective support
* visibility and danger class
* threat structural fingerprint

### Step 5 — Spatial Layout Solve

Lay out nodes in world space, respecting:

* door connectivity
* collision-free placement
* desired traversal depth
* branch readability
* bounds constraints

### Step 6 — Corridor / Terrain Connect

Generate physical links between placed spaces.

### Step 7 — Paint Tile Layers

Apply floor/wall/terrain/overlay biome tiles and navigation-relevant data.

### Step 8 — Place Objectives

Stamp primary and optional objective anchors.

### Step 9 — Place Hazards and Spawn Zones

Apply systemic pressure layers.

### Step 10 — Export GeneratedRegion

Produce structured output for world transition / campaign world loading.

---

## 28. Layout Solving Constraints

This needs explicit rules or it will decay into ad hoc placement.

### 28.1 Hard Constraints

* all required nodes connected
* entry reachable to all primary objective nodes
* extraction reachable when required
* no overlapping room bounds
* no sealed dead graph due to door mismatch
* mission-critical nodes valid for their objective type

### 28.2 Soft Constraints

* branch diversity
* pacing alternation
* reasonable backtracking
* biome-specific silhouette
* threat-specific pressure rhythm

### 28.3 Important Rule

A valid layout is not enough. It should also be good. Keep a scoring pass.

---

## 29. Region Quality Scoring

After generation, score candidate layouts and keep the best valid result from a limited retry budget.

### 29.1 Suggested Score Axes

* objective depth appropriateness
* branch diversity
* extraction tension
* quiet-space availability
* hazard overclutter penalty
* template repetition penalty
* route readability
* threat-fingerprint fit
* biome-fingerprint fit

### 29.2 Retry Budget

Use a bounded retry budget like:

* 8–20 candidate solves depending on complexity

This keeps determinism while improving average quality.

---

## 30. Runtime Tile Payload

The region generator must produce tilemap-ready payloads, not just room transforms.

### 30.1 Minimum Tile Layers

* floor
* walls/impassables
* hazard overlays
* decor overlays
* shadow/support overlays where relevant

### 30.2 Important Rule

Tile payload should remain compatible with the active runtime’s navigation assumptions: walkable floor cells vs blocked wall cells. The existing navigation system already treats floor tile occupancy and walls tile occupancy as walkability authority. Preserve that contract. 

---

## 31. Region Save / Resume Requirements

Campaign regions are transient, but they still need resumable identity while active.

### 31.1 Save-Surface Requirements

A resumable active region should preserve:

* scenario ID
* campaign ID
* region seed
* RegionSpec
* GeneratedRegion structured output or enough source data to rebuild it identically
* objective state
* extraction state
* resolved hazards if mutable
* enemy persistence policy as defined elsewhere

### 31.2 Important Rule

Do not rely on “rerun the generator and hope the same scene tree comes out” unless every nondeterministic surface is controlled and versioned.

---

## 32. Debug Requirements

This system absolutely needs debug tooling.

### 32.1 Graph View

Show:

* node roles
* edge types
* entry
* objective nodes
* extraction nodes

### 32.2 Template Assignment View

Show which template each node resolved to.

### 32.3 Hazard Overlay View

Show hazard zones distinctly.

### 32.4 Spawn/Pressure View

Show ingress and escalation zones.

### 32.5 Route Validation View

Show:

* entry to primary objective path
* objective to extraction path
* optional branch routes

### 32.6 Generator Summary Dump

Log:

* scenario seed
* chosen archetype
* biome
* threat family
* node counts
* retry count
* quality score
* failure reason if rejected

Without these, region generation bugs will be miserable to diagnose.

---

## 33. Module Targets

Recommended file structure:

```plaintext id="jrs59b"
custodian/core/systems/region/
    region_generator.gd
    region_spec.gd
    region_graph.gd
    region_layout_solver.gd
    region_quality_evaluator.gd
    region_exporter.gd
```

If reusing Edgar-specific pieces from the existing plan:

```plaintext id="c26fxm"
custodian/procgen/edgar/
    room_loader.gd
    room_graph.gd
    layout_assembler.gd
```

The key is not exact placement; it is separation of concerns.

### 33.1 Recommended Responsibilities

#### `region_generator.gd`

Entry point. Converts `CampaignScenario` to `GeneratedRegion`.

#### `region_spec.gd`

Defines normalized generation parameters.

#### `region_graph.gd`

Defines node/edge graph and generation helpers.

#### `region_layout_solver.gd`

Resolves graph into spatial layout.

#### `region_quality_evaluator.gd`

Scores candidate layouts.

#### `region_exporter.gd`

Converts solved layout into runtime-ready tile/entity payload.

---

## 34. Integration with World Transition

The World Transition System should not build regions itself. Instead:

1. transition manager requests region build from scenario
2. region generator returns `GeneratedRegion`
3. transition manager instantiates world from that result
4. runtime world binding occurs using the generated payload

This keeps generation deterministic and testable independently.

---

## 35. Integration with Campaign Flow

Campaign Flow later owns:

* mission state progression
* objective completion
* extraction handling
* win/loss resolution

This generator must provide enough anchors and metadata for campaign flow to bind to:

* primary objective IDs
* optional objective IDs
* extraction IDs
* spawn zone IDs
* hazard zone IDs

---

## 36. Failure Cases to Guard Against

### 36.1 Biome Skinning Only

The biome changes art but structure remains functionally identical.

### 36.2 Threat-Insensitive Layout

Threat family changes enemy scenes only, not world shape.

### 36.3 Objective Incoherence

Objectives placed in nonsensical rooms or on the main path without tension.

### 36.4 Infinite Corridor Soup

Region graph devolves into chains of identical connectors.

### 36.5 Dead Empty Open Space

Large spaces with no structural or mechanical reason.

### 36.6 Overstacked Hazards

World becomes unreadable due to too many overlapping hazard systems.

### 36.7 Extraction Afterthought

Exfil placed arbitrarily rather than built into pacing.

### 36.8 Non-Deterministic Regeneration

Same campaign resume produces different region.

### 36.9 Template Repetition Fatigue

Same handful of rooms appear every mission because scoring/diversity logic is weak.

---

## 37. Recommended Build Order

### Phase 1 — Graph Layer

* `RegionSpec`
* `RegionGraph`
* archetype presets
* victory translation rules

### Phase 2 — Template Metadata

* room taxonomy
* biome/threat/template compatibility tables
* objective-capable template metadata

### Phase 3 — Spatial Solver

* room placement
* corridor linking
* layout retries
* quality scoring

### Phase 4 — Runtime Export

* tile payload
* objective anchors
* extraction anchors
* spawn zones
* hazard zones

### Phase 5 — Scenario Conditioning

* difficulty conditioning
* threat fingerprints
* biome fingerprints
* optional objective logic

### Phase 6 — Save/Resume + Debug

* structured generation dump
* graph overlays
* deterministic rebuild support

---

## 38. Acceptance Criteria

This file is complete when all of the following are true.

### Structural

* [ ] accepted `CampaignScenario` can be converted into a `RegionSpec`
* [ ] `RegionSpec` can generate a graph-driven region
* [ ] graph is spatialized into a playable world

### Scenario Fidelity

* [ ] biome materially affects generated structure
* [ ] threat profile materially affects generated structure
* [ ] victory type materially affects objective/extraction placement
* [ ] difficulty materially affects topology, not just enemy count

### Playability

* [ ] entry, objectives, and extraction are all reachable when required
* [ ] region has readable route structure
* [ ] quiet space and pressure space both exist
* [ ] objective placement is role-compatible

### Runtime Compatibility

* [ ] tile payload supports current navigation conventions
* [ ] generated anchors can be consumed by campaign runtime systems
* [ ] generated region can be entered via world transition

### Determinism

* [ ] same input scenario and seed produce the same region output
* [ ] saved active campaign can rebuild the same region

---

## 39. Exit Condition

This file is done when you can:

1. accept a campaign scenario from the Hub,
2. generate a region from it,
3. deploy into that region,
4. verify that biome, threat, objective type, and difficulty all materially changed the world,
5. complete or abandon the mission,
6. and destroy the region afterwards without treating it as a permanent world.

That is the minimum viable Region Generation System.

---

# Progress Tracking

## Completed Files

* [1] Runtime World & Camera Stabilization
* [2] Hub System (Meta Progression)
* [3] World Transition System
* [4] Region Generation System

## Still To Go

* [5] Compound Tile System
* [6] Campaign Flow & Game Loop
* [7] Integration Contract (Glue Layer)
