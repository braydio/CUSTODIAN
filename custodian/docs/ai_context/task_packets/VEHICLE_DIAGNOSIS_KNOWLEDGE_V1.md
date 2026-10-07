# VEHICLE DIAGNOSIS AND KNOWLEDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-diagnosis-knowledge-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Locks: `vehicle-knowledge, vehicle-diagnostics`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-diagnosis-knowledge-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new persistent knowledge authority and scan progression that gates later fabrication`
- Reviewed main: `007a257be8799e82566b434c74e084039f663ca7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Add vehicle diagnosis/reverse-engineering progression so scanning real vehicles and surviving assemblies builds named mechanical knowledge and pattern evidence without granting parts or spending resources.
- Completion boundary: Done when one persistent vehicle-knowledge authority records domain XP/levels, unique scan fingerprints, per-archetype diminishing returns, and assembly pattern evidence; vehicle definitions expose scan-teachable domains/patterns; an Operator-facing scan interaction can inspect intact, disabled, and wrecked vehicles; repeat scanning one instance grants nothing; and downstream systems can query whether a knowledge/pattern requirement is satisfied.
- Current measured state: Vehicle wreck lifecycle/restoration exists and its held-input correction has landed pending fresh re-review. `FabPipeline` already has ARRN-gated recipes and unlock outputs, but there is no general vehicle knowledge authority. ARRN's `RELAY_RECOVERY` knowledge track is relay-specific and must not be repurposed. Persistent-state architecture explicitly reserves durable unlock/knowledge state for `game/state/persistent/`.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; `custodian/game/state/persistent/README.md`; `custodian/game/systems/core/systems/arrn/{knowledge_system,benefits_manager}.gd`; live vehicle registry/definition/runtime; `FabPipeline`.
- Task-specific authority: `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; reviewed wreck lifecycle; current persistent-state rules.
- Work surface: new focused vehicle-knowledge persistent authority; vehicle scan profile/data contract; minimal vehicle definition fields; one reusable vehicle diagnostic/scan interaction or service; focused validation.
- Change: Introduce the five canonical domains `CHASSIS, MOBILITY, POWERTRAIN, CONTROL, SPECIALTY`. Each scan profile declares domain contributions and assembly-pattern IDs present in that vehicle. Store exact scanned-instance fingerprints so one physical instance pays research once. Store per-archetype scan count and apply deterministic diminishing domain returns across repeated examples while still allowing a newly observed assembly pattern to add evidence. Intact vehicles grant the strongest configured evidence, disabled intact vehicles less, wrecks only for surviving/observable systems. Expose queries equivalent to `get_domain_xp/level`, `get_pattern_evidence`, and `meets_requirement`. Keep thresholds/data tunable rather than burying progression numbers in UI/runtime code.
- Preserve: ARRN knowledge remains relay-specific; ResourceLedger/FabPipeline/InventoryManager remain untouched economic authorities; scanning never repairs/restores a vehicle; existing wreck interaction and pilotability semantics remain unchanged.
- Non-goals: No part fabrication yet, no recipe unlock wiring yet, no new generic research tree/UI, no scan combat advantage, no procedural random research loot, no persistence migration beyond the narrow new knowledge state.
- Acceptance: First scan of a configured intact vehicle grants configured domain XP and pattern evidence; same instance re-scan grants zero; a second distinct exemplar grants diminished domain XP; a new pattern on an otherwise repeated archetype still grants pattern evidence; wreck scans cannot reveal patterns marked destroyed/unobservable; knowledge survives the authority's save/load-facing serialization contract; requirement queries are deterministic and side-effect free.
- Validation: Add focused knowledge/scan smoke covering intact/disabled/wreck yields, same-instance rejection, repeated-archetype diminishing returns, new-pattern evidence, serialization round-trip, and negative requirement queries. Re-run vehicle registry/lifecycle/restoration focused suite and packet contracts.
- Task overrides: `none`
- Deferred: Player-facing research terminal page; advanced scan VFX; recipe gating and replacement-part fabrication are the next slice.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile only the final reviewed wreck-restoration APIs. Do not broaden into fabrication or ARRN.

## Handoff

- Next workstream: `review-vehicle-diagnosis-knowledge-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally so fresh review gates component fabrication.
- Blockers or open questions: `none`
