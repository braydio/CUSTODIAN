# VEHICLE PART FABRICATION AND RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-part-fabrication-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-diagnosis-knowledge-v1`
- Locks: `vehicle-restoration-runtime, fabrication-runtime, vehicle-content`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-part-fabrication-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `cross-system recipe gating, persistent item output, and component-consuming restoration`
- Reviewed main: `007a257be8799e82566b434c74e084039f663ca7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Make R1+ wreck recovery consume fabricated replacement assemblies, with R2+ recipes gated by vehicle knowledge/pattern evidence, while preserving raw-material direct restoration only for explicit R0 PATCHWORK profiles.
- Completion boundary: Done when restoration profiles declare recovery grade and either direct materials (R0 only) or required fabricated component items (R1+); FabPipeline can gate recipes on VehicleKnowledgeState, produce replacement assemblies into InventoryManager, and expose clear lock reasons; Field Scout recovery is migrated to R1 SERVICE with three starter-known fabricated parts; successful installation consumes those parts exactly once and bootstraps the same Scout to 40 HP.
- Current measured state: Wreck restoration currently pays raw ResourceLedger materials directly at the Scout after a held interaction. FabPipeline already owns resource payment/job lifecycle and supports ARRN-gated recipes. InventoryManager already owns persistent stackable non-resource items and provides add/remove/has APIs. BuildInventory is specifically Ready Build placement-token authority and must not receive vehicle parts.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; reviewed diagnosis/knowledge predecessor; `autoload/fab_pipeline.gd`; `game/systems/core/systems/inventory_manager.gd`; `content/fabrication/fab_recipes.json`; live vehicle restoration profiles/interactions.
- Task-specific authority: `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; reviewed VehicleKnowledgeState; ResourceLedger/FabPipeline/InventoryManager ownership.
- Work surface: fabrication recipe schema/runtime and terminal projection only as needed; InventoryManager output bridge; restoration profile schema/runtime; Scout restoration profile; focused validation.
- Change: Extend FabPipeline with a bounded `inventory_item` output that calls InventoryManager and with optional `requires_vehicle_knowledge` / `requires_pattern` recipe gates alongside existing ARRN gating. Add starter-known Scout recipes `field_drive_coupler_mk1`, `custodian_control_relay_mk1`, and `structural_brace_kit_mk1`; their costs are ordinary ResourceLedger inputs paid when fabrication starts. Migrate `field_scout_recovery_light` to R1 SERVICE and require one of each component, with no direct material payment at the wreck. Restoration preflight reports missing components; held completion rechecks and atomically consumes exactly the required InventoryManager items before restoring the same vehicle at 40 HP. Add at least one fixture R0 PATCHWORK profile proving direct materials remain legal only when explicitly selected, and one R2 fixture recipe proving knowledge/pattern locks.
- Preserve: Existing FabPipeline job timing/power/service ownership; ARRN recipe gates; ResourceLedger material authority; InventoryManager persistence; reviewed physical hold/release behavior; restoration same-instance semantics; BuildInventory remains construction-only.
- Non-goals: No freeform crafting, no physical loose-part carry actors, no advanced-fabricator tier yet, no R3/R4 runtime, no production art, no balance pass.
- Acceptance: Field Scout raw-resource interaction alone cannot restore it. With materials but no fabricated assemblies, prompt/diagnosis identifies the three missing parts and refuses without spending at the wreck. Fabricating each starter-known recipe spends ResourceLedger inputs through FabPipeline and grants the exact InventoryManager item. With all three items, completed restoration consumes each exactly once and restores Scout to 40 HP. Interrupted restoration consumes nothing. R0 fixture still performs direct-material restoration. R2 fixture remains recipe-locked until both configured knowledge and pattern evidence are satisfied, then becomes fabricable without bypassing FabPipeline.
- Validation: Add focused part-fabrication/recovery smoke covering starter recipe visibility, resource payment, InventoryManager output, missing-part refusal, cancellation, exact component consumption, Scout restore, explicit R0 direct-material exception, and R2 knowledge+pattern lock/unlock. Re-run fabrication terminal command/clickable/readability where affected plus all focused vehicle tests and packet contracts.
- Task overrides: `none`
- Deferred: R3 advanced fabricator capability, R4 authored Archive/donor requirements, physical part props, broader balance.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile reviewed knowledge APIs and final wreck-restoration APIs. Do not absorb semantic Scout scene migration or production art.

## Handoff

- Next workstream: `review-vehicle-part-fabrication-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally so the semantic Scout class recovery can consume the reviewed assembly loop.
- Blockers or open questions: `none`
