# Procedural Lore Generation

**Project:** CUSTODIAN  
**Created:** 2026-04-08  
**Status:** active  
**Last Updated:** 2026-04-08  
**Parent Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`  
**Primary Downstream Consumers:** `design/03_architecture/REGION_GENERATION_SYSTEM.md`, `design/02_features/pixel_planet/PIXEL_PLANET_CONTRACT_SYSTEM.md`, `design/02_features/procgen/AUTHORED_TILED_ROOM_PIPELINE.md`, `design/02_features/enemy_director/implementation.md`, `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`

---

## Purpose

Define the first concrete implementation target for lore-bearing procedural generation in CUSTODIAN.

This file exists to bridge the gap between high-level canon and runtime-facing systems. It does **not** replace the canon doc. It translates canon into practical content payloads, tag sets, wording rules, and generation responsibilities that procgen, terminal, inspect, and enemy systems can consume.

Use this doc when deciding:

- which world-identity fields a generated region should carry
- how rooms should expose provenance and reuse
- how rooms should expose impossible provenance without explaining The Unarrival directly
- how inspect text should sound
- how machine messages should sound
- how faction ideology should affect behavior and dressing
- what a first-pass procedural lore payload should look like

---

## Scope

### In Scope
- Procedural lore payload shape
- Provenance/reuse tag families
- Legibility class definitions for generation
- First-pass inspect text rules
- First-pass machine-language rules
- Faction-to-environment / faction-to-behavior mapping
- Minimum viable content hooks for runtime systems

### Out of Scope
- Full authored story arcs
- Quest scripting
- Dialogue trees
- Full archive UI schemas
- Exact implementation classes or serialization backends

---

## Core Rule

**Proceduralize evidence, not exposition.**

The generator should create conditions that let the player infer what happened. It should not try to autowrite long lore entries.

The world should answer questions through:

- layout
- objects
- damage patterns
- signage
- machine remnants
- enemy activity
- incomplete or distorted readouts

---

## Canonical Lore Payload

Every generated region should be able to carry a lore payload like this, whether as explicit fields, derived tags, or runtime metadata:

```gdscript
{
    "world_legibility_class": "stable_misinterpretation",
    "original_function": "relay_maintenance_site",
    "collapse_mode": "controlled_sealing",
    "provenance_failure": "command_packet_precedes_sender",
    "post_collapse_reuse": "salvage_nest",
    "present_ideology": "indexer",
    "surviving_truth": "site_once_routed_authenticated_traffic",
    "false_local_interpretation": "relay_chooses_the_worthy",
    "confidence_band": "approximate"
}
```

This payload can exist at more than one level:

- region-level
- room-family-level
- authored template-level
- encounter-level
- inspect-pool-level

`provenance_failure` is optional in the first runtime pass, but it is the key field for the revised Severance model. It should describe the impossible relationship, not explain the cosmic source. Good values name symptoms such as `artifact_without_origin`, `witness_precedes_event`, `machine_command_from_future`, `settlement_remembers_false_war`, or `saint_relic_precedes_arrival`.

### Minimum Viable Runtime Requirement

First-pass runtime support only needs:

- region-level payload
- optional room/template overrides
- inspect/machine snippet selection using the payload
- enemy behavior weighting hooks using `present_ideology`

---

## Legibility Classes

These are the canonical generation classes for whole-world reading.

### `stable_misinterpretation`
A functioning social or operational order built on wrong assumptions.

Generation implications:
- coherent signage replacement
- repeated rituals around practical machinery
- signs of maintenance mixed with misuse
- enemies defend meaning structures, not just chokepoints

### `dead_mechanism`
A still-operating system with no living culture that fully understands it.

Generation implications:
- machine warnings remain denotative
- automated hazards and loops are common
- rooms should feel procedural before they feel inhabited

### `contested_truth_zone`
Multiple groups impose different readings on the same place.

Generation implications:
- mixed markings and overwrite layers
- conflicting damage or barricade logic
- different enemy behaviors in different pockets

### `overwritten_world`
Earlier truth has been intentionally replaced or buried.

Generation implications:
- covered signage
- relabeled doors
- falsified records
- machine-language fragments contradict local labels

### `null_site`
Too much context is gone for safe interpretation.

Generation implications:
- sparse certainty
- fewer strong claims in terminal/readouts
- more degraded, corrupted, or unresolved outputs

### `provenance_failure`
A site where an object, room, body, record, or event has effects in history while its origin, witness chain, or sequence cannot be placed.

Generation implications:
- machine language should classify contradictions coldly
- local factions should offer mutually incompatible but locally coherent explanations
- physical evidence should imply wrong-order age, impossible ownership, or orphaned cause
- avoid exposition naming The Unarrival unless the content is deliberately late-game or sealed

---

## Provenance Tag Sets

Use these sets as first-pass enums or content families. They can expand later.

### Original Function

Recommended values:
- `relay_maintenance_site`
- `archive_annex`
- `decontamination_yard`
- `munitions_transfer_bay`
- `personnel_intake_facility`
- `weather_control_substation`
- `biotech_quarantine_node`
- `continuity_port`
- `signal_observatory`
- `civil_transit_checkpoint`

### Collapse Mode

Recommended values:
- `hard_evacuation`
- `internal_siege`
- `controlled_sealing`
- `power_starvation`
- `systemic_fire`
- `sabotage`
- `contamination_event`
- `command_abandonment`
- `defensive_lockdown`
- `archive_quarantine`

### Post-Collapse Reuse

Recommended values:
- `shrine_network`
- `salvage_nest`
- `weapons_chop_yard`
- `sleeping_den`
- `black_market_relay`
- `fungus_farm`
- `ritual_proving_ground`
- `storage_maze`
- `classification_cell`
- `signal_ward`

### Present Ideology

Recommended first-pass values:
- `indexer`
- `penitent_of_static`
- `leaseholder`
- `choir_of_provenance`
- `buried_kin`
- `feral_defense_remnant`
- `opportunist_scavenger`
- `quarantine_zealot`

These values should stay compatible with later faction systems without requiring full faction implementation today.

---

## Truth / Misinterpretation Pairs

The strongest procedural lore comes from a true statement paired with a wrong local reading.

### Pairing Rule

Do not generate `surviving_truth` without also considering `false_local_interpretation` unless the site is intentionally low-ambiguity.

### Good Examples

**Truth:** `site_once_routed_authenticated_traffic`  
**False reading:** `relay_chooses_the_worthy`

**Truth:** `vault_held_records_not_weapons`  
**False reading:** `sealed_room_contains_ancestral_armament`

**Truth:** `ritual_is_degraded_safety_procedure`  
**False reading:** `sequence_appeases_the_machine_spirit`

**Truth:** `marked_dead_were_operators_not_prisoners`  
**False reading:** `the_wall_records_traitors`

### Bad Pairing

Avoid pairs where the false interpretation is just a paraphrase of the truth. Wrong readings should distort stakes, meaning, or social behavior.

---

## Room-Level Lore Hooks

Rooms do not need full unique stories. They need strong evidence hooks.

### Minimum Room Metadata

Each authored or generated room should eventually be able to expose:

```gdscript
{
    "room_type": "processing_hall",
    "original_function": "personnel_intake_facility",
    "damage_signature": "systemic_fire",
    "reuse_signature": "ritual_proving_ground",
    "occupant_ideology": "penitent_of_static",
    "tableau_slots": ["centerpiece", "wall_marker", "floor_scatter"],
    "inspect_pool": "intake_fire_ritual"
}
```

### Minimum Room Outputs

A room should affect some combination of:

- prop family
- decal family
- signage family
- machine-message pool
- inspect pool
- enemy idle/task selection
- avoidance / reverence / desecration behavior

---

## Inspect Text Rules

Inspect text should be:

- short
- denotative
- materially grounded
- useful on repetition
- suggestive without overexplaining

### Recommended Length
- 4 to 14 words for common inspectables
- up to 20 words for rare inspectables

### Preferred Structure
- object state
- trace of use
- procedural implication

### Good Examples
- `The warning stencil survived the fire.`
- `Copper stripped clean around the seal.`
- `Someone polished this panel by hand.`
- `The chairs face the locked chamber.`
- `Burn marks stop at the threshold.`
- `Tool brackets remain. Tools do not.`

### Bad Examples
- `This room was once used by the ancient operators before the fall of civilization.`
- `The cultists believe this machine is sacred because of a misunderstanding of old archive protocol.`

### Inspect Pool Rule

Inspect pools should be keyed by provenance + collapse + reuse where possible, not by room name only.

---

## Machine-Language Rules

Residual machine language is one of the strongest lore channels in CUSTODIAN.

### Machine Text Should Be
- procedural
- denotative
- terse
- unconcerned with the player’s feelings
- reusable across sites

### Machine Text Should Not Be
- mystical on purpose
- lore-dump prose
- emotional narration
- fully explanatory

### Good Examples
- `CLEARANCE CHAIN INVALID`
- `ARCHIVAL SEAL BREACH SUSPECTED`
- `DECONTAMINATION LANE OUT OF TOLERANCE`
- `NO ACCEPTABLE OPERATOR SIGNATURE`
- `TRANSIT AUTHORITY RECORD MISMATCH`
- `INTAKE CAPACITY EXCEEDED`

### Usage Rule

Use machine language to imply original function, collapse state, or contradiction with local interpretation.

---

## Faction / Ideology Mapping

This is the first-pass implementation map from ideology to visible world behavior.

### `indexer`
Environment cues:
- relabeling
- sorting piles
- tagged shelves
- catalog marks over older signage

Behavior cues:
- seize terminals
- strip labels
- claim archive interfaces
- prioritize classification infrastructure

### `penitent_of_static`
Environment cues:
- interference shrines
- cable braids
- speaker clusters
- intentionally noisy spaces

Behavior cues:
- jam sensors
- linger near humming machinery
- corrupt relay or signal surfaces
- ritualize ambiguity

### `leaseholder`
Environment cues:
- access markers
- route claims
- stamped ownership warnings
- barricades around titled paths

Behavior cues:
- defend gates and access points
- contest control systems
- prioritize route authority and possession

### `choir_of_provenance`
Environment cues:
- sealed passages
- immaculate quarantine zones
- stripped evidence fields
- hard procedural signage

Behavior cues:
- seal, deny, purge
- destroy uncertain material
- avoid contamination over aggression when possible

### `buried_kin`
Environment cues:
- adaptive domestic reuse
- careful localized maintenance
- high continuity within a narrow area
- records preserved in odd forms

Behavior cues:
- defend local truths
- avoid senseless desecration
- resist destabilizing outside interpretation

### `feral_defense_remnant`
Environment cues:
- patrol scars
- dead sensor arcs
- warning lights without operators
- segmented lockdown remains

Behavior cues:
- patrol
- interdict
- seal compartments
- attack by obsolete logic rather than ideology speech

---

## Minimum Runtime Integration Targets

### Region Generation
Should consume or emit the canonical lore payload.

### Authored Room Pipeline
Should preserve room-level provenance/reuse metadata.

### Pixel Planet / Contract World Profile
Should reserve world identity fields at contract generation time.

### Enemy Director / Objective Systems
Should remain extensible for ideology-conditioned behaviors and target weighting.

### Terminal / Archive / Recon Surfaces
Should use confidence bands and machine/procedural language rules.

### Streaming Reveal
Should support discovery-feel without violating determinism.

---

## First-Pass Data Contract Recommendation

If a shared lore payload resource or dictionary is created, start with this exact field family:

```gdscript
{
    "world_legibility_class": String,
    "original_function": String,
    "collapse_mode": String,
    "post_collapse_reuse": String,
    "present_ideology": String,
    "surviving_truth": String,
    "false_local_interpretation": String,
    "confidence_band": String
}
```

Optional room-level extension:

```gdscript
{
    "room_type": String,
    "damage_signature": String,
    "reuse_signature": String,
    "occupant_ideology": String,
    "inspect_pool": String,
    "machine_message_pool": String
}
```

Keep it flat at first. Do not over-engineer the schema before runtime consumers exist.

---

## Implementation Priority

### Do Now
- reserve payload fields in generation docs and data contracts
- preserve authored provenance metadata in room templates
- enforce inspect and machine-language style rules
- keep enemy systems extensible for ideology-weighted behavior

### Do Soon
- generate inspect pools from provenance/reuse combos
- generate machine-message pools from original function + collapse mode
- let region generation pick tableau families from the payload

### Do Later
- contradiction packet triads
- reconstruction hearing content
- deep archive adjudication UI
- broad hypothesis graph player tooling

---

## Success Criteria

This system is doing its job when:

- two regions with different lore payloads feel different before a single long text block is read
- inspectables sound like field evidence, not lore essays
- machine messages imply system history without explaining it outright
- enemies reveal worldview through tasks and target selection
- terminal/archive wording preserves uncertainty instead of flattening it
- the player can infer a site’s past and present from evidence layers that agree or productively conflict
