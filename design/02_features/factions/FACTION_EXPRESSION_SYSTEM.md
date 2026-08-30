# Faction Expression System

**Status:** implementation spec
**Runtime:** Godot 4.x (`custodian/`)
**Last updated:** 2026-07-29

---

## Table of Contents

1. [Design Principle](#1-design-principle)
2. [Runtime Taxonomy Lock](#2-runtime-taxonomy-lock)
3. [Canonical IDs and Classification](#3-canonical-ids-and-classification)
4. [Gameplay Boundaries](#4-gameplay-boundaries)
5. [Roster Symmetry Reduction](#5-roster-symmetry-reduction)
6. [Faction Definition Data Model](#6-faction-definition-data-model)
7. [Environment Expression](#7-environment-expression)
8. [Behavior Expression](#8-behavior-expression)
9. [Gameplay Pressure Handlers](#9-gameplay-pressure-handlers)
10. [Target Selection Doctrine](#10-target-selection-doctrine)
11. [Buried Kins Relationship Layer](#11-buried-kins-relationship-layer)
12. [First Vertical Slice: Sundered Keep](#12-first-vertical-slice-sundered-keep)
13. [Migration Order](#13-migration-order)
14. [Runtime Ownership](#14-runtime-ownership)

---

## 1. Design Principle

Factions are **different answers to the collapse of trustworthy civilization**, communicated through what they maintain, alter, defend, seal, or misinterpret — not primarily through dialogue or hostility toward the Custodian.

The canonical principle from `design/03_world/factions/_FACTION_OVERVIEW.md` remains the implementation guide:

> The player should rarely be told what a faction is. They should learn by seeing what enemies protect, what they ignore, what they steal, what they mark, what rooms they modify, what machines they maintain, what they destroy on sight, and what their bodies, tools, and rituals imply. **The best CUSTODIAN faction is one the player understands before the Hub ever names it.**

The main task of this spec is to establish a clean implementation taxonomy so gameplay cannot flatten these factions into reskinned enemy rosters.

---

## 2. Runtime Taxonomy Lock

The current `dominant_faction` field is too overloaded. It cannot cleanly represent a populated settlement, a historical inheritance, an automated defense network, and an occupying expedition using one value.

### Proposed world-profile schema

Replace `dominant_faction` with a composite structure:

```gdscript
# design/04_architecture/REGION_GENERATION_SYSTEM.md — world profile extension
{
    "resident_faction_id": "pale_bell_penitents",      # living political/social faction
    "secondary_faction_id": "",                          # optional second faction
    "continuity_tags": ["ash_bell"],                     # historical tags, not factions
    "hazard_layers": ["feral_defense_remnants"],         # security/automation hazards
    "occupancy_posture": "ritual_guarded",               # how the resident occupies space
    "expression_profile": "pale_bell_listening_site"     # which tableau/activity set to use
}
```

### Classification rules

| Field | Purpose | Examples |
|---|---|---|
| `resident_faction_id` | The dominant political/social faction in this region | `pale_bell_penitents`, `indexers`, `leaseholders`, `choir_of_provenance`, `buried_kins` |
| `secondary_faction_id` | A second faction present at lower density | Same set, or empty |
| `continuity_tags` | Historical inheritance, not an active faction | `ash_bell`, `old_custodian`, `null_warrant` |
| `hazard_layers` | Non-polity security/automation layers | `feral_defense_remnants` |
| `occupancy_posture` | How the resident faction occupies space | `ritual_guarded`, `patrolled`, `fortified`, `settled`, `quarantined`, `abandoned` |
| `expression_profile` | Which tableau/activity/decoration set to instantiate | Matches a `FactionDefinition` profile id |

### Non-polity layers

These should not share the same runtime contract as living political societies:

**Feral Defense Remnants** — automated/security hazard ecology. Not a social faction. Its own profile says it has no beliefs and is institutional violence after the institution died. It should be a composable hazard layer that can overlay any region.

**Ash-Bell** — historical continuity tag, not a faction. Used to mark regions touched by Ash-Bell history, influencing inspect text, archive content, and ambient motifs without creating an active faction roster.

---

## 3. Canonical IDs and Classification

### Faction kind enum

```gdscript
enum FactionKind {
    POLITY,          # Living political/social faction
    HAZARD_LAYER,    # Non-polity automated/security ecology
    CONTINUITY_TAG,  # Historical inheritance marker only
}
```

### Canonical polity IDs

```
pale_bell_penitents      # Cosmic devotional order — temporal-perceptual distortion
indexers                 # Classification invaders — metadata corruption
leaseholders             # Armed legal continuity — access denial
choir_of_provenance      # Verification authority — sealed choices
buried_kins              # Conditional polity — moral/relational gameplay
```

### Non-polity entries

```
feral_defense_remnants   # FactionKind.HAZARD_LAYER
ash_bell                 # FactionKind.CONTINUITY_TAG
```

---

## 4. Gameplay Boundaries

Several factions operate in adjacent conceptual territory. Their mechanical boundaries must be explicit.

| Faction | What it changes | Duration | Player counterplay |
|---|---|---:|---|
| **Pale Bell Penitents** | Perception and sequence | Temporary, room-local | Destroy/tune a signal source; recognize telegraphs |
| **Indexers** | Meaning and metadata | Persistent until corrected | Rescan, compare evidence, restore original labels |
| **Leaseholders** | Physical and systemic access | Until overridden, rerouted, or adjudicated | Alternative route, credentials, forced breach |
| **Choir of Provenance** | Availability of risky choices | Deliberate player decision | Respect, violate, or partially inspect quarantine |
| **Buried Kins** | Relationship and legitimacy | Persistent world consequence | Avoid escalation, negotiate, preserve infrastructure |
| **Feral Defense** | Space and movement | Predictable while systems remain active | Observe patrols, exploit recognition conflicts, disable systems |

### Pale Bell versus Indexers

Both affect information, but they must not feel interchangeable.

- **Pale Bell:** "The result arrived late, incompletely, or from the wrong direction."
- **Indexer:** "The result is cleanly presented, persistent, and semantically wrong."

**Pale Bell effects** must be clearly bounded and telegraphed. Do not silently falsify authoritative health, inventory, damage, or save-state information. Their canonical pressure is temporal-perceptual distortion: delayed UI updates, flickering objective markers, audio distortion near ritual sites, brief false readings on terminals.

**Indexer corruption** must leave evidence of alteration and remain until corrected. Relabeled room signage, sorted salvage, tagged corpses, altered terminal prompts. The damage is epistemic — directed at future knowledge quality.

### Indexers versus Leaseholders

- Indexers **alter what a thing means**.
- Leaseholders **assert who may access or possess it**.

Indexer combat vocabulary should lean toward correction, filing, tagging, extraction, and forced categorization — not seizure or impoundment. Terms like "Seizure Trooper" and "impound" that drift into Leaseholder territory should be avoided.

### Leaseholders versus Choir

Both can seal doors, but for different reasons:

- **Leaseholder seal:** "You have no recognized claim."
- **Choir seal:** "Opening this may propagate unverified foreign-origin records."

The Choir should not become another route-lock faction. Its best gameplay is optional, high-value quarantine where the player knowingly accepts interpretive or systemic risk.

### Buried Kins versus all others

The Buried Kins are a **conditional polity**, not a default hostile population. Their primary gameplay axis is relational:

- Default posture: guarded, not hostile
- Escalation triggers: damaging infrastructure, killing Kins, entering sealed domestic spaces
- De-escalation: repairing their equipment, leaving tribute, not entering marked zones
- Combat is a failure state, not the default interaction

Do not spawn Buried Kins as ordinary enemy encounters. They require a relationship tracker and conditional hostility gates.

---

## 5. Roster Symmetry Reduction

Every faction profile currently describes approximately eight unit archetypes:
- basic melee
- basic ranged
- heavy
- fast unit
- support
- elite
- leader
- special

Implementing all six as parallel eight-unit armies would produce 48 nominal archetypes with severe art and animation load and faction identity expressed through unit names rather than behavior.

### First production target

Per faction, implement:

1. **One unmistakable environmental tableau** — a signature room arrangement the player can learn to recognize
2. **One pre-combat activity** — what faction actors do before noticing the player
3. **One target-selection doctrine** — what they prioritize attacking
4. **One signature gameplay pressure** — how they change the player's relationship to information, access, or space
5. **At most two faction-specific combat roles** — distinct behavior profiles beyond the shared physical archetype pool

### Physical archetype reuse

Body/combat archetypes should remain composable with faction doctrine:

```text
physical archetype: grunt / marine / drone / heavy
faction doctrine:   indexer / leaseholder / pale_bell / choir
local posture:      patrol / raid / quarantine / ritual / defend_home
```

This avoids needing a bespoke `IndexerHeavy`, `LeaseholderHeavy`, `ChoirHeavy`, etc. before the factions have any systemic identity.

---

## 6. Faction Definition Data Model

### Runtime resource

`custodian/game/world/factions/faction_definition.gd`:

```gdscript
extends Resource
class_name FactionDefinition

@export var id: String = ""                          # canonical ID
@export var display_name: String = ""                # player-facing name
@export var faction_kind: int = FactionKind.POLITY   # polity / hazard / tag

# Ambient activity
@export var ambient_activity_pool: Array[String] = []

# Target selection — what this faction prioritizes
@export var target_tag_weights: Dictionary = {}       # tag -> weight (0.0 to 1.0)

# Environment expression
@export var room_tag_modifiers: Array[String] = []    # tags applied to rooms
@export var inspect_pool_id: String = ""              # which inspect text set to use

# Gameplay pressure
@export var pressure_id: String = ""                  # which pressure handler to activate

# Optional: conditional hostility (Buried Kins)
@export var default_hostile: bool = true
@export var relationship_tracking: bool = false
```

### Registry

`custodian/game/world/factions/faction_registry.gd` — autoload or singleton that:
- Loads all definitions from `custodian/content/factions/faction_definitions.json`
- Provides lookup by ID
- Exposes target tag weight queries for the objective sensor

### JSON definition data

`custodian/content/factions/faction_definitions.json`:

```json
{
  "definitions": [
    {
      "id": "indexers",
      "display_name": "The Indexers",
      "faction_kind": "polity",
      "ambient_activity_pool": [
        "replace_room_label",
        "scan_archive_node",
        "tag_body",
        "sort_recovered_objects"
      ],
      "target_tag_weights": {
        "archive_node": 1.0,
        "map_terminal": 0.9,
        "room_signage": 0.8,
        "storage": 0.2,
        "player": 0.35
      },
      "room_tag_modifiers": [
        "relabelled",
        "sorted",
        "false_taxonomy"
      ],
      "inspect_pool_id": "indexer_common",
      "pressure_id": "metadata_corruption",
      "default_hostile": true,
      "relationship_tracking": false
    },
    {
      "id": "pale_bell_penitents",
      "display_name": "Pale Bell Penitents",
      "faction_kind": "polity",
      "ambient_activity_pool": [
        "tune_dead_receiver",
        "listen_at_shrine",
        "chant_into_broken_comm",
        "mark_arrival_site",
        "arrange_ash_circle"
      ],
      "target_tag_weights": {
        "signal_source": 1.0,
        "archive_node": 0.6,
        "receiver": 0.9,
        "player": 0.5
      },
      "room_tag_modifiers": [
        "listening_shrine",
        "ash_circle",
        "dead_speaker"
      ],
      "inspect_pool_id": "pale_bell_common",
      "pressure_id": "temporal_distortion",
      "default_hostile": true,
      "relationship_tracking": false
    },
    {
      "id": "leaseholders",
      "display_name": "The Leaseholders",
      "faction_kind": "polity",
      "ambient_activity_pool": [
        "inspect_claim_seal",
        "interrogate_terminal",
        "patrol_route",
        "lock_door",
        "catalog_impounded_goods"
      ],
      "target_tag_weights": {
        "access_control": 1.0,
        "terminal": 0.8,
        "door": 0.9,
        "storage": 0.6,
        "player": 0.7
      },
      "room_tag_modifiers": [
        "sealed",
        "claimed",
        "impounded"
      ],
      "inspect_pool_id": "leaseholder_common",
      "pressure_id": "access_denial",
      "default_hostile": true,
      "relationship_tracking": false
    },
    {
      "id": "choir_of_provenance",
      "display_name": "Choir of Provenance",
      "faction_kind": "polity",
      "ambient_activity_pool": [
        "scan_artifact",
        "apply_quarantine_seal",
        "preserve_evidence",
        "purge_contradiction",
        "maintain_sterile_zone"
      ],
      "target_tag_weights": {
        "archive_node": 0.9,
        "artifact": 1.0,
        "contradiction": 0.9,
        "player": 0.4
      },
      "room_tag_modifiers": [
        "quarantined",
        "sterile",
        "preserved_evidence"
      ],
      "inspect_pool_id": "choir_common",
      "pressure_id": "quarantine_choice",
      "default_hostile": true,
      "relationship_tracking": false
    },
    {
      "id": "buried_kins",
      "display_name": "Buried Kins",
      "faction_kind": "polity",
      "ambient_activity_pool": [
        "repair_infrastructure",
        "cook_meal",
        "carry_supplies",
        "check_on_neighbor",
        "tend_garden"
      ],
      "target_tag_weights": {
        "domestic_space": 0.0,
        "life_support": 0.0,
        "water_source": 0.0,
        "player": 0.0
      },
      "room_tag_modifiers": [
        "repaired",
        "domestic",
        "inhabited"
      ],
      "inspect_pool_id": "buried_kins_common",
      "pressure_id": "relational",
      "default_hostile": false,
      "relationship_tracking": true
    },
    {
      "id": "feral_defense_remnants",
      "display_name": "Feral Defense Remnants",
      "faction_kind": "hazard_layer",
      "ambient_activity_pool": [
        "patrol_loop",
        "scan_for_intruders",
        "report_to_checkpoint",
        "maintain_barricade"
      ],
      "target_tag_weights": {
        "player": 0.9,
        "intruder": 0.9,
        "security_console": 0.3
      },
      "room_tag_modifiers": [
        "patrolled",
        "locked_down",
        "turret_active"
      ],
      "inspect_pool_id": "feral_defense_common",
      "pressure_id": "spatial_denial",
      "default_hostile": true,
      "relationship_tracking": false
    }
  ]
}
```

### Target tag pool (extensible)

These tags let the same objective sensor support all factions without hardcoded branches:

```
archive_node          # Indexers, Choir
relay                 # Pale Bell, Leaseholders
access_control        # Leaseholders
quarantine_seal       # Choir
life_support          # Buried Kins
water_source          # Buried Kins
domestic_space        # Buried Kins (no-attack zone)
signal_source         # Pale Bell
receiver              # Pale Bell
security_console      # Feral Defense
map_terminal          # Indexers
room_signage          # Indexers
storage               # generic
artifact              # Choir
contradiction         # Choir
door                  # Leaseholders
intruder              # Feral Defense
player                # universal
```

---

## 7. Environment Expression

### Room tag modifiers

When a faction occupies a room, the room receives tag modifiers that:
1. Drive prop/decal selection
2. Drive inspect text selection
3. Drive minimap marker tinting (future)
4. Drive ambient audio selection (future)

The `FactionSiteExpression` component (below) reads the `room_tag_modifiers` array from the definition and applies them deterministically.

### FactionSiteExpression

`custodian/game/world/procgen/factions/faction_site_expression.gd`:

```gdscript
extends RefCounted
class_name FactionSiteExpression

func express_site(tilemap: Node, faction: FactionDefinition, site: Dictionary) -> void:
    # 1. Apply room tag modifiers to the site's reserved region
    for tag in faction.room_tag_modifiers:
        _tag_region(tilemap, site, tag)
    
    # 2. Place faction-specific decals/props within the site radius
    _place_faction_props(tilemap, faction.id, site)
    
    # 3. Apply faction-specific tile overrides if defined
    _apply_tile_overrides(tilemap, faction.id, site)
```

This replaces the current `faction_site_geometry_stamper.gd` which only reserves a rectangular floor footprint without stamping any faction identity.

### Procedural tableau system

Each faction should have at least one **signature tableau** — a small clustered evidence scene the player can learn to recognize:

| Faction | Tableau | What it communicates |
|---|---|---|
| Pale Bell | Listening shrine with dead receiver, ash circle, tuned speaker | They listen for something that never arrives |
| Indexers | Relabeled room with sorted salvage, tagged bodies, altered terminal | They overwrite meaning with taxonomy |
| Leaseholders | Claim-sealed door with legal placard, impounded goods pile | They assert authority through procedure |
| Choir | Quarantine-taped artifact with scanner residue, sterile zone | They preserve by sealing |
| Buried Kins | Repaired living space with domestic clutter, ration shelves | They survived by staying |
| Feral Defense | Active turret with patrol route markers, checkpoint lights | They continue without command |

---

## 8. Behavior Expression

### Ambient activity system

Current state: actors walk to an anchor and wait. `activity_id` does not drive animation, interaction, prop manipulation, or target selection.

Replace the activity system with definition-driven execution:

Each `ambient_activity_pool` entry maps to a behavior fragment that includes:
- **Animation ID** — what the actor plays while performing the activity
- **Interaction target tags** — what objects the actor interacts with (if any)
- **Prop manipulation** — whether the activity places/removes/modifies a prop
- **Duration range** — how long the activity takes
- **Interrupt behavior** — what happens when the player is detected

Example flow:
```
faction: indexers
activity: replace_room_label
  → actor walks to room signage
  → plays "tagging" animation (2.5s)
  → room tag modifier "relabelled" is applied
  → if interrupted, actor drops current label and engages
```

### Behavior state machine extensions

The existing `enemy_behavior_state_machine.gd` should gain a pre-combat activity state that:
1. Reads the faction's `ambient_activity_pool`
2. Selects an activity deterministically from the pool
3. Executes the activity (animation + interaction)
4. Transitions to `notice` state on player detection

### Activity-specific execution

Current activities in `faction_site_placer.gd` (`iconoclast`, `cult_mechanist`, `scavenger`) should be replaced with the canonical faction activity pools defined above.

---

## 9. Gameplay Pressure Handlers

Each pressure ID maps to a handler that modifies gameplay within the faction's sphere of influence:

| Pressure ID | Handler | Effect |
|---|---|---|
| `temporal_distortion` | `PaleBellPressure` | Delayed UI updates, flickering objective markers, audio distortion near shrines, brief false terminal readings |
| `metadata_corruption` | `IndexerPressure` | Relabeled rooms show wrong name; terminal data has false entries; inspect text is confidently wrong |
| `access_denial` | `LeaseholderPressure` | Doors lock behind the player; terminals deny access; routes are sealed; requiring alternate pathfinding |
| `quarantine_choice` | `ChoirPressure` | Optional sealed containers with valuable contents but risk; player chooses to open or leave sealed |
| `spatial_denial` | `FeralDefensePressure` | Turret arcs, patrol routes, locked checkpoints, motion-triggered alarms |
| `relational` | `BuriedKinsPressure` | Relationship tracker; de-escalation options; consequences for aggression; trade/ally potential |

Each handler should be individually testable and bounded to the faction's region of influence.

---

## 10. Target Selection Doctrine

The objective sensor (`enemy_objective_sensor.gd`) currently scores: Operator, storage theft, storage sabotage, escape, and investigation.

Replace hardcoded faction branches with the `target_tag_weights` dictionary from the definition:

```gdscript
# Pseudocode for the sensor
func score_target(potential_target: Node, faction: FactionDefinition) -> float:
    var base_score := 0.0
    for tag in potential_target.get_tags():
        base_score += faction.target_tag_weights.get(tag, 0.0)
    return base_score
```

This lets each faction express different priorities:
- **Indexers** prioritize archive nodes and terminals over the player
- **Leaseholders** prioritize access control and doors
- **Pale Bell** prioritizes signal sources
- **Choir** prioritizes artifacts and contradictions
- **Buried Kins** will not attack domestic or life-support targets
- **Feral Defense** treats the player as primary target (security logic)

---

## 11. Buried Kins Relationship Layer

The Buried Kins are a **conditional polity**. They require:

### Relationship tracker (deferred until polity posture system exists)

```gdscript
enum RelationState {
    NEUTRAL,
    GUARDED,
    HOSTILE,
    ALLIED,
}

# Tracked per region per player session
struct FactionRelation {
    var faction_id: String
    var state: RelationState
    var escalation_triggers: Array[String]  # what the player did
    var de_escalation_progress: float
}
```

### Default behavior
- Buried Kins do not attack on sight
- They issue warnings before escalating
- Combat is a failure state, not the default interaction
- Killing a Kin has persistent reputation consequences

### Implementation priority
Defer full relationship layer until neutral/guarded/escalated postures are supported at the runtime level. For V1, Buried Kins should simply not spawn as default enemy encounters and should only appear in authored domestic spaces.

---

## 12. First Vertical Slice: Sundered Keep

Do not introduce all six factions into the Keep simultaneously.

The Keep lore identifies:
- Feral Defense as the best starter presence
- Pale Bell as appropriate for signal/anomaly spaces
- Choir as a later antagonist
- Leaseholders as optional

### Baseline layer: Feral Defense

- Gatehouse patrol route with predictable timing
- Scanner recognizes the Custodian while an attached weapon rejects them
- One predictable lockdown or turret lane in the gatehouse approach
- No dialogue or ideological behavior — pure environmental security

### One living faction site: Pale Bell

- A listening tableau in an optional signal chamber off the causeway or gatehouse
- One actor tuning or listening to a dead receiver before combat
- A local, clearly telegraphed objective-marker latency effect while the receiver is active
- Destroying or retuning the receiver ends the effect
- No permanent metadata corruption — bounded, room-local, telegraphed

### Deferred

- Choir: postpone until quarantine choices and optional-object handling exist
- Indexers: better suited to procgen archive/terminal rooms than authored Keep
- Leaseholders: optional for later Keep expansion if route-denial gameplay justifies the space
- Buried Kins: do not appear in the Keep (no domestic population)

This keeps the Keep from becoming faction soup while delivering the "first meaningful faction behavior" promised by its design.

Do not commission new faction production art until this data and behavior contract is locked.

---

## 13. Migration Order

### Phase 1 — Canon consolidation (docs only)

1. Establish `design/03_world/lore/CORE_LORE.md` + `design/03_world/factions/` as explicit lore authority
2. Reduce faction content in `design/03_world/GAME_PROTOCOLS_AND_WORLD_LORE.md` to a current summary with links
3. Keep canonical terms aligned with doctrine: "Great Severance" → "The Severing", "Penitents of Static" → "Pale Bell Penitents".
4. Fix stale paths: `design/00_canon/` → `design/03_world/lore/`, `design/03_content/` → `design/03_world/`

### Phase 2 — Canonical ID migration (runtime)

1. Create `FactionDefinition` resource and `FactionRegistry`
2. Create `custodian/content/factions/faction_definitions.json` with the six definitions
3. Replace obsolete IDs (`iconoclast`, `cult_mechanist`, `scavenger`) in world profiles, activity pools, and story templates
4. Update `faction_site_placer.gd` to use canonical IDs and activity pools
5. Update `story_room_placer.gd` to use canonical IDs
6. Keep temporary aliases only at data-load boundaries; remove after one migration cycle

### Phase 3 — Runtime classification split

1. Extend world profile schema: replace `dominant_faction` with resident/secondary/hazard/tags
2. Preserve deterministic weighted selection from existing profiles
3. Update `world_progress_profile.gd` and consumers

### Phase 4 — Environment expression

1. Implement `FactionSiteExpression` that reads definition data and stamps room tags/props
2. Implement one tableau per faction (signature room arrangement)
3. Wire into the Sundered Keep slice first

### Phase 5 — Behavior expression

1. Extend ambient state machine to read activity pools from definition data
2. Add tagged objective targets to the sensor
3. Implement activity-specific animation/interaction execution

### Phase 6 — Gameplay pressure

1. Implement one pressure handler per polity faction
2. Each handler individually testable via smoke

### Phase 7 — Buried Kins relationship layer

1. Implement only after neutral/guarded/escalated postures are supported
2. Deferred until the runtime has a relationship/alignment system

---

## 14. Runtime Ownership

```text
custodian/game/world/factions/faction_definition.gd         # Resource definition
custodian/game/world/factions/faction_registry.gd            # Singleton/autoload registry
custodian/content/factions/faction_definitions.json           # Definition data

custodian/game/world/procgen/factions/faction_site_placer.gd           # Site placement (update)
custodian/game/world/procgen/factions/faction_site_expression.gd       # New: tableau/prop/decal stamping
custodian/game/world/procgen/factions/faction_site_geometry_stamper.gd # Reservation (keep, simplify)

custodian/game/actors/enemies/components/enemy_behavior_profile.gd     # Profile factory (update)
custodian/game/actors/enemies/components/enemy_objective_sensor.gd     # Target scoring (update)
custodian/game/actors/enemies/enemy_behavior_state_machine.gd          # Ambient state (update)

custodian/game/world/procgen/story/story_room_placer.gd                # Story room templates (update)
custodian/game/world/procgen/progression/world_progress_profile.gd     # World profile schema (update)

custodian/tools/validation/faction_definition_smoke.gd                 # New: validates definitions
custodian/tools/validation/faction_story_sites_smoke.gd                # New: validates site expression
```
