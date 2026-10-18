# Vehicle Recovery Implementation Roadmap

**Status:** active  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b  
**Current reviewed main:** `f12717e61213d7d30ae6b3e670d45e71507cd784`

## Program boundary

This roadmap owns the implementation sequence for turning CUSTODIAN vehicles from a single pilotable prototype into a recoverable, learnable machine ecosystem.

**Program begins when:** a pilotable vehicle has one lifecycle/registry authority and world-spawned vehicles can exist as wreckage.

**Program ends when:** the first Scout uses reviewed fabricated-component recovery, vehicle scanning produces durable mechanical knowledge/pattern evidence, advanced recipes can be knowledge-gated, the first production vehicle family is Asset V2-native, and the shared diagnosis/install presentation families are registered for production art.

The first real advanced R2 vehicle is a later content slice that proves reuse; it is not required to finish the foundation.

## Slice DAG

| Slice | Workstream | State on current main | Primary authority | Depends on |
|---|---|---|---|---|
| V0 | `vehicle-runtime-lifecycle-hardening-v1` | complete + reviewed | `PilotableVehicle` lifecycle / PlayerController handoff | none |
| V1 | `vehicle-wreck-restoration-foundation-v1` + correction/re-review | complete + reviewed | wreck state + held restoration lifecycle | V0 review |
| V2 | `vehicle-diagnosis-knowledge-v1` | ready/auto | persistent vehicle knowledge + scan profiles | V1 final review |
| V2R | `review-vehicle-diagnosis-knowledge-v1` | ready/auto | independent proof | V2 |
| V3 | `vehicle-part-fabrication-recovery-v1` | ready/auto, dependency-gated | FabPipeline + InventoryManager + generic recovery grades | V2R |
| V3R | `review-vehicle-part-fabrication-recovery-v1` | ready/auto, dependency-gated | independent proof | V3 |
| V4 | `vehicle-field-scout-buggy-class-v1-recovery-1` | landed/reviewed with blocking R0-01 | semantic Scout class | historical predecessor |
| V4C | `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1` | ready/auto, dependency-gated | bind Scout to reviewed R1 components | V3R + V4 review |
| V4CR | paired review of V4C | ready/auto, dependency-gated | independent Scout acceptance | V4C |
| V5 | `vehicle-field-scout-buggy-asset-v2` | ready/auto, dependency-gated | Scout Asset V2 family + generic vehicle importer | V4CR |
| V5R | paired review of V5 | ready/auto | independent asset/runtime proof | V5 |
| V6 | `vehicle-recovery-presentation-manifests-v1` | ready/auto, dependency-gated | shared recovery FX/component family contracts | V5R |
| V6R | paired review of V6 | ready/auto | independent Asset V2 contract proof | V6 |
| V7 | `vehicle-recovery-fx-production-v1` | authored draft/manual; authoring handoff auto, dependency-gated | six shared recovery FX source normalization + Asset V2 ingest + runtime wiring | V6R |
| V8 | first real R2 TECHNICAL vehicle | future content slice | new vehicle class using reviewed reusable systems | V3R minimum; ideally V7 |

## V0 — Lifecycle hardening

### Design job
Make one vehicle lifecycle trustworthy before adding progression.

### Locked behavior
- one pilot ownership authority;
- disable/destruction/teardown always releases Operator safely;
- no duplicate controller-owned occupancy truth;
- safe exit remains fail-closed;
- zero-health vehicle cannot be driven.

### Review failure if
Any downstream slice adds a parallel occupancy/lifecycle authority.

## V1 — Wreck restoration foundation

### Design job
Make ordinary world-spawned vehicles begin as wreckage and require a real held recovery interaction.

### Locked behavior
- fresh world vehicle: `WRECKAGE`, 0 HP, disabled, non-pilotable;
- initial wreck state does not emit fake destruction;
- Interact must remain physically held for the configured duration;
- release/range loss/target loss/UI/death/transition cancels for free;
- successful restoration affects the same instance;
- later lethal destruction returns it to recoverable wreckage.

### Important migration note
V1's original direct ResourceLedger payment is now legacy compatibility only. V3 introduces the grade-aware generic payment modes and V4C removes the direct-material path from the production Scout.

## V2 — Diagnosis and knowledge

### Player fantasy
The Operator learns machines by inspecting machines, not by filling a generic tech-tree bar.

### Domains
- `CHASSIS`
- `MOBILITY`
- `POWERTRAIN`
- `CONTROL`
- `SPECIALTY`

### Two outputs of scanning
1. domain XP/levels: reusable mechanical understanding;
2. assembly-pattern evidence: proof the Operator has observed a specific component family closely enough to reproduce it.

### Anti-farm rules
- same physical instance grants research once;
- repeated examples of same archetype have data-driven diminishing domain returns;
- a repeated archetype can still teach a genuinely new pattern;
- wreck condition only exposes patterns that survived/are observable;
- no scan grants resources, parts, HP, or repair progress.

### Input
Use the existing sampled `repair` intent as V1 vehicle service/diagnostic action. Raw `Input.*` remains in `OperatorInputRouter`.

## V3 — Part fabrication and generic recovery grades

### Recovery grades

| Grade | Meaning | Direct raw materials at wreck? | Research gate? |
|---|---|---:|---:|
| R0 PATCHWORK | junkers / improvised machines | yes | no |
| R1 SERVICE | ordinary serviceable vehicles | no; fabricated assemblies | starter-known or known service patterns |
| R2 TECHNICAL | advanced machinery | no | domain + pattern requirements |
| R3 RESTRICTED | rare/military/specialist | no | higher requirements + future fabricator capability |
| R4 RELIC | unique/Archive-adjacent | no | authored evidence/donor hardware may be required |

### Authority chain
```text
VehicleKnowledgeState
  -> recipe knowledge query

ResourceLedger
  -> raw recipe inputs

FabPipeline
  -> lock policy + work order + build time + output

InventoryManager
  -> fabricated replacement assemblies

VehicleRestorationInteraction
  -> checks/consumes requirements after held install

PilotableVehicle
  -> wreck -> operational lifecycle transition
```

No other system may mutate a neighboring authority's state directly.

### First three production component recipes

| Component | Inputs | Build time |
|---|---|---:|
| Field Drive Coupler Mk I | 5 ruin scrap + 2 structural alloy | 4.5s |
| Custodian Control Relay Mk I | 2 ruin scrap + 1 power component | 3.5s |
| Structural Brace Kit Mk I | 5 ruin scrap + 4 structural alloy | 4.0s |

Aggregate material bill remains the original Scout cost: 12 scrap + 6 alloy + 1 power component.

## V4 / V4C — Field Scout class

The semantic class already landed:
- stable ID `custodian_ground_buggy_scout_light`;
- `field_scout_buggy_mk1.tscn`;
- 100 HP `light_scout_utility`;
- exact existing movement profile;
- one driver;
- 64px entry;
- 2x1 bottom-center footprint;
- FrontLight + RearUtility;
- no weapon/loadout;
- temporary hover compatibility art.

Its review correctly found one blocking defect: the live profile still pays raw resources. V4C is the only slice allowed to switch the production Scout to R1 SERVICE.

After V4C:
```text
find Scout wreck
 -> service-diagnose three failed assemblies
 -> fabricate three starter-known parts
 -> return with parts
 -> hold installation/bootstrap
 -> consume parts
 -> same Scout comes online at 40/100 HP
 -> ordinary field repair handles HP thereafter
```

## V5 — Scout Asset V2

This slice is pipeline/presentation infrastructure, not art creation.

### Current drive-source availability

Approved N / NE / E / SE / S 12-frame high-resolution source masters plus canonical 156×156 pixel-art normalizer outputs are present at:

`/home/braydenchaffee/CUSTODIAN-DROPBOX-UPLOADS/Custodian-Buggy`

The older three-direction Dropbox ZIP remains historical partial evidence only. The 156px outputs are the approved runtime-scale art and should be ingested byte-for-byte; do not re-normalize them to the earlier 256px planning canvas. This complete five-direction set is **source availability only** until Asset V2 ingest/binding is green; all authored drive directions are now supplied, but none is yet runtime-complete.

It registers `custodian_field_scout_buggy_mk1`, removes hover-specific importer assumptions, and allows canonical Scout body states to replace compatibility art without changing gameplay.

Body family:
- 156×156 cells;
- 8dir with authored n/ne/e/se/s and mirrored nw/w/sw;
- stable bottom-center registration;
- true alpha.

States:
- required: `parked_01` 1f, `drive_01` 12f @12fps, `disabled_01` 1f, `wreck_01` 1f;
- recommended: `engine_start_01` 7f @8fps, `engine_idle_01` 6f @6fps, `brake_01` 4f @10fps, `impact_01` 4f @12fps, `destroy_01` 8f @10fps, `restore_01` 8f @8fps, `restore_fx_01` 8f @8fps.

## V6 — Shared recovery presentation manifests

V6 registers family contracts for the shared diagnosis/install loop. It does not generate final pixels.

See `VEHICLE_RECOVERY_ART_MANIFEST.md`.

The goal is reuse: every advanced vehicle should not require a bespoke scan beam, missing-part icon vocabulary, and tool-spark system unless its design genuinely needs one.

## V7 — Shared recovery FX production

The first authored V7 production slice is `vehicle-recovery-fx-production-v1`, paired with `review-vehicle-recovery-fx-production-v1`.

Six human-selected shared recovery FX source masters now have one immutable implementation-input handoff. V7 preserves those source bytes, performs deterministic technical normalization to the reviewed 256px family contract, ingests them through Asset Pipeline V2, builds one shared SpriteFrames presentation resource, and wires the real scanner/install/recovery event seams to a reusable presenter.

The V7 packet does **not** reopen art direction or mechanics. The six selected states are `scan_sweep_01`, `fault_ping_01`, `install_sparks_01`, `power_route_01`, `bootstrap_01`, and `restore_success_01`. Component icons/props, optional `restore_failure_01`, Field Scout body polish, and post-destroy smoke remain separate later art work.

Do not hand-copy generated PNGs into runtime folders and do not let presentation become a second recovery state machine.

## V8 — First advanced R2 vehicle proof

The first real R2 vehicle should prove the system is more than Scout-specific:
- wreck is discoverable before recoverable;
- diagnosis names at least one missing advanced assembly;
- recipe reports a knowledge deficit and/or pattern deficit;
- scanning other compatible machines closes those deficits;
- component is fabricated and installed;
- recovery uses the same generic machinery as Scout.

Do not create V8 by subclassing a second recovery system.

## Cross-slice invariants

1. Raw materials directly repair wrecks only at R0.
2. R1+ uses physical fabricated component items.
3. Knowledge unlocks recipes; it never creates parts.
4. Scanning does not repair or harvest the scanned vehicle.
5. Fabrication consumes raw inputs; installation consumes fabricated items.
6. Ordinary field repair changes HP only after the vehicle is operational.
7. Wreck lifecycle stays in `PilotableVehicle`.
8. Recipe locks stay in `FabPipeline`, not terminal UI.
9. Part inventory stays in `InventoryManager`, not `BuildInventory`.
10. ARRN knowledge remains its own relay-specific progression.
11. Production input remains sampled by `OperatorInputRouter`.
12. Asset V2 is the only production art route.
13. A task cannot claim success by calling `restore_from_wreck()` directly in a test when the acceptance concerns the production restoration interaction.

## Final foundation acceptance

The vehicle recovery foundation is considered hardened when V6R passes and:
- all current production world vehicles are wreck-first;
- Scout recovery is R1 component-gated;
- scan anti-farming/persistence passed independent review;
- generic R0/R1/R2 fixture behavior passed independent review;
- Scout class correction passed;
- Scout vehicle Asset V2 family passed;
- shared recovery presentation contracts are registered;
- no stale LightBuggy production-scene claim remains.

Production art completion and first R2 content vehicle are separate milestones.
