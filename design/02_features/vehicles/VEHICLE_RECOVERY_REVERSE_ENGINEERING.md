# Vehicle Recovery, Diagnosis, and Reverse Engineering

**Status:** active design authority  
**Parent:** `design/02_features/vehicles/VEHICLES.md`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Core fantasy

Vehicles are not health bars with wheels. A wreck is a machine whose missing or failed systems must be understood, replaced, and recommissioned.

The progression loop is:

```text
find wreck
  -> diagnose surviving / failed systems
  -> if knowledge is insufficient, scan compatible vehicles or assemblies
  -> accumulate mechanical understanding + pattern evidence
  -> unlock the missing assembly recipe
  -> fabricate the replacement assembly from raw resources
  -> install required assemblies at the wreck
  -> bootstrap / ignition
  -> recover the vehicle in damaged-but-operational condition
```

Raw resources may be applied directly to a wreck only for deliberately primitive, patchwork recovery grades. A proper Custodian vehicle never accepts `ruin_scrap` as a magic universal repair potion.

## Recovery grades

| Grade | Label | Restoration rule |
| --- | --- | --- |
| R0 | PATCHWORK | Genuine junkers / improvised machines. Direct material repair is allowed. No fabricated assembly requirement. |
| R1 | SERVICE | Standard industrial/Custodian machines. Diagnose faults and install known fabricated service assemblies. Raw materials enter only through fabrication recipes. |
| R2 | TECHNICAL | Advanced machines. Missing assemblies require vehicle-knowledge thresholds and pattern evidence before their fabrication recipes unlock. |
| R3 | RESTRICTED | Rare/advanced platforms. Requires higher domain knowledge plus exact/specific pattern evidence, and may require an advanced fabrication capability. |
| R4 | RELIC | Unique or Archive-adjacent machinery. Recovery may require authored discoveries, intact donor hardware, or narrative/Archive authority in addition to research. Never unlocked by generic grind alone. |

R0 should be uncommon and visibly crude. The Field Scout Buggy Mk I is **R1 SERVICE**, not R0.

## Knowledge model

Vehicle reverse engineering has named domains rather than one generic XP bar:

- `CHASSIS` — structure, mounts, load paths, service geometry.
- `MOBILITY` — wheels/tracks/hover hardware, steering, suspension, final drive.
- `POWERTRAIN` — drive power, energy conversion, transmission and thermal systems.
- `CONTROL` — control relays, actuators, drive-by-wire, supervisory electronics.
- `SPECIALTY` — sensors, field systems, faction/role-specific equipment.

A future platform may declare an additional specialized domain only when the existing five cannot express it cleanly.

### Scanning

Scanning produces two related outputs:

1. **Domain knowledge** — reusable mechanical understanding.
2. **Pattern evidence** — proof that the Operator has observed a specific assembly family closely enough to reconstruct it.

Useful sources:
- operational/intact vehicle: strongest scan;
- disabled but largely intact vehicle: strong;
- wreck with surviving subsystem: partial;
- loose/intact assembly: strong evidence for that assembly;
- heavily destroyed/missing subsystem: diagnosis only, little or no pattern evidence.

The same physical instance grants research only once. Repeated examples of the same archetype grant diminishing domain knowledge, while a new variant or previously unseen assembly can still grant fresh pattern evidence. This prevents one parked buggy from becoming an infinite textbook while preserving the fantasy of learning by inspecting multiple machines.

## Recipe gating

A vehicle-component fabrication recipe may specify:

```json
{
  "requires_vehicle_knowledge": [
    {
      "domain": "MOBILITY",
      "level": 2
    }
  ],
  "requires_vehicle_patterns": [
    {
      "pattern_id": "electrohydraulic_steering_rack",
      "evidence": 2
    }
  ]
}
```

Both requirements must be satisfied before `FabPipeline` exposes the recipe as fabricable. Arrays are the canonical schema so one recipe can require multiple domains or patterns. A compatibility reader may normalize an older singular object at the boundary, but content should not author two permanent forms.

Knowledge unlocks the **recipe**. It never creates the physical part.

## Authority boundaries

- `VehicleKnowledgeState` owns vehicle-domain knowledge, scan fingerprints, pattern evidence, and recipe-knowledge queries. It belongs in persistent state.
- Vehicle scan/diagnostic runtime decides what a particular target can teach, but never spends or grants fabrication materials.
- `FabPipeline` remains the fabrication-job authority and `ResourceLedger` remains raw-material payment authority.
- Fabricated replacement assemblies are ordinary persistent items in `InventoryManager`; do not misuse `BuildInventory`, which remains the Ready Build / placement-token authority.
- `PilotableVehicle` remains health/wreck/operational lifecycle authority.
- Vehicle restoration consumes required fabricated assemblies only after its actual hold/installation completes successfully.

## Component contract

R1+ restoration profiles declare required component IDs instead of raw-material costs.

Example Scout service requirements:

```text
field_drive_coupler_mk1      x1
custodian_control_relay_mk1  x1
structural_brace_kit_mk1     x1
```

Those three recipes are starter-known service patterns. The player still has to fabricate the parts, carry them to the wreck, install them, and perform the bootstrap. They are not research-gated because the first Scout teaches the loop.

Example R2 wreck:

```text
Diagnosis:
  DRIVE COUPLER ................ serviceable
  POWER CONDITIONER ............ missing
  STEERING ACTUATOR ............ missing
  CONTROL RELAY ................ serviceable

Power conditioner:
  POWERTRAIN knowledge 1/2
  pattern evidence 1/2
  FABRICATION: LOCKED

Steering actuator:
  MOBILITY knowledge 2/2
  pattern evidence 2/2
  FABRICATION: AVAILABLE
```

The wreck itself becomes a long-lived objective until the player understands and fabricates what it needs.

## Starter Scout component recipes

The three first-service recipes intentionally preserve the original raw material bill while moving those materials behind real fabrication:

| Component | Raw fabrication inputs | Build time |
| --- | --- | ---: |
| `field_drive_coupler_mk1` | 5 ruin scrap + 2 structural alloy | 4.5 s |
| `custodian_control_relay_mk1` | 2 ruin scrap + 1 power component | 3.5 s |
| `structural_brace_kit_mk1` | 5 ruin scrap + 4 structural alloy | 4.0 s |

Combined: 12 ruin scrap + 6 structural alloy + 1 power component, matching the old direct-restoration material bill. This is a mechanics migration, not a hidden first-vehicle cost increase.

Completed component outputs belong to `InventoryManager`. `BuildInventory` remains reserved for Ready Build / placement tokens and must not become a vehicle-parts ledger.

## Field Scout onboarding

The Field Scout Buggy Mk I is R1 SERVICE:

1. discover Scout wreck;
2. diagnose three failed service assemblies;
3. starter maintenance knowledge already recognizes the recipes;
4. fabricate the three replacement assemblies through the existing Field Fabricator;
5. return and install them;
6. perform a held bootstrap/ignition interaction;
7. Scout comes online at 40/100 HP;
8. ordinary field repair handles additional health after recovery.

This teaches the full assembly loop without forcing research grinding before the player has ever driven a vehicle.

## Advanced progression examples

- Scanning two intact wheeled haulers and one Scout may raise `MOBILITY` enough to reconstruct a heavy steering actuator.
- A recovered APC may be technically understandable but still blocked because the player has never observed its power conditioner pattern.
- Finding an intact enemy vehicle becomes useful even when the player does not want that vehicle: it is a mobile research specimen.
- A rare wreck can appear hours before it is recoverable, creating a remembered world objective rather than a chest the player immediately opens.
- R4/Relic recovery can require Archive records or an intact donor component, so generic scan grinding cannot trivialize unique machines.

## UX principle

Diagnosis should always tell the player **why** recovery is blocked:

- MISSING ASSEMBLY
- PATTERN UNKNOWN
- KNOWLEDGE INSUFFICIENT
- FABRICATOR CAPABILITY INSUFFICIENT
- PART FABRICATED / READY TO INSTALL

Never collapse these into a generic `requirements not met`.

## Presentation and art consequences

Recovery art needs to communicate machine state, not only health:

- wreck silhouette;
- scan/diagnostic overlay;
- subsystem-highlight / missing-part socket treatment;
- installation/tool FX;
- power-routing/bootstrap FX;
- ignition/start transition;
- final online state.

Advanced platforms can reuse shared diagnostic/install FX while owning class-specific wreck and critical-assembly silhouettes.

## Explicit non-goals

- no freeform survival crafting grid;
- no generic research tree replacing ARRN;
- no random loot-roll requirement for a mandatory part;
- no universal scrap-to-vehicle conversion for R1+;
- no repeated scanning of one instance for infinite knowledge;
- no direct health restoration from fabricated vehicle assemblies; they unlock recovery, after which ordinary repair owns HP.
