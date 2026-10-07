# CORRECTION: Vehicle Field Scout Buggy Class V1 Recovery 1 — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-part-fabrication-recovery-v1, review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Locks: `vehicle-runtime, vehicle-content, vehicle-restoration-runtime`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `ff5fc4056217e004901ea342f0de4422b8162775`
- Parent implementation: `vehicle-field-scout-buggy-class-v1-recovery-1` — `custodian/docs/ai_context/task_packets/archived/VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1.md`
- Parent review: `review-vehicle-field-scout-buggy-class-v1-recovery-1` — `custodian/docs/ai_context/task_packets/archived/REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1.md`
- Findings addressed: `R0-01`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Make production Field Scout restoration use the reviewed R1 SERVICE fabricated-assembly recovery flow.
- Completion boundary: Done when raw resources alone cannot restore the Scout, its profile requires the three reviewed service assemblies, and a completed held interaction consumes each once before restoring the same Scout to 40 HP.
- Current defect/evidence: The Scout profile still defines direct ResourceLedger costs (12 ruin scrap, 6 structural alloy, 1 power component). The interaction pays this raw cost at the wreck. The Scout smoke asserts the raw values and bypasses the interaction with `restore_from_wreck(0.4)`. The R1 component runtime is absent on current main; wait for its paired review dependency before implementation.
- Evidence: Parent review finding `R0-01`; `design/02_features/vehicles/VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`; live restoration profile/interaction/class smoke; archived implementation packet and summary.
- Task-specific authority: `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; `FIELD_SCOUT_BUGGY_MK1.md`; reviewed component-recovery API and authority.
- Work surface: `custodian/content/vehicles/vehicle_restoration_profiles.json`; `custodian/tools/validation/vehicle_field_scout_class_smoke.gd`; `custodian/tools/validation/validation_manifest.json` only if ownership changes; minimal production integration in `vehicle_restoration_interaction.gd` only if the reviewed predecessor API requires a mechanical adapter. Do not re-own `FabPipeline`, `InventoryManager`, `VehicleKnowledgeState`, component catalog, or generic recovery-grade behavior.
- Required correction: (1) Rewrite only `field_scout_recovery_light` to `recovery_grade: SERVICE`, remove the legacy raw `cost`, and require exactly `{field_drive_coupler_mk1:1, custodian_control_relay_mk1:1, structural_brace_kit_mk1:1}` while preserving `initial_state=WRECKAGE`, `hold_duration=4.0`, and `restored_health_fraction=0.40`. (2) Consume the reviewed generic component-recovery API rather than adding Scout-specific inventory/payment code. (3) Rewrite `vehicle_field_scout_class_smoke.gd` so it grants raw resources first and proves restoration still refuses, then fabricates/grants the three actual component items through the reviewed public seams, drives the production held interaction, proves exact item consumption and same-instance 40 HP restoration, then verifies entry + field repair. (4) Remove any direct `restore_from_wreck(0.4)` success path from the Scout smoke. (5) Do not modify recipe costs or generic recovery machinery.
- Preserve: Stable registry ID and semantic scene; exact movement values; data-owned 100 HP; wreck-first authored/resolver spawns; no pilotability before restoration; seat/hardpoints/footprint/empty loadout; post-restore field repair and entry; shared lifecycle ownership; no `light_buggy.tscn` alias.
- Non-goals: No economy retuning, class redesign, other vehicle grades, scanner behavior, production art, Asset V2 work, or unrelated documentation cleanup.
- Acceptance: (1) Scout profile is R1 SERVICE with exactly the three required item IDs and no raw-resource cost. (2) Materials without fabricated assemblies cannot restore it and leave ledger/inventory unchanged. (3) Missing parts are identified before the hold. (4) Completed uninterrupted hold consumes each item exactly once and restores the same Scout to 40/100 HP. (5) Interrupted holds consume nothing. (6) Field repair and entry work after restoration. (7) Both spawn paths remain wrecked/non-pilotable until restoration. (8) The focused smoke rejects direct-restore bypasses.
- Validation: Run `vehicle_part_fabrication_recovery`, `vehicle_diagnosis_knowledge`, `vehicle_field_scout_class`, `vehicle_wreck_restoration`, `vehicle_registry_contract`, `vehicle_runtime_lifecycle`, and `vehicle_exit_clearance`; run registry validator if separate; validate profile schema and `git diff --check`; then changed-file closeout once. The Scout smoke must fail if the profile regresses to raw `cost` or if it bypasses the interaction.
- Task overrides: `none`
- Deferred: R0-02 stale CURRENT_STATE LightBuggy claim for the Asset V2/current-state documentation pass; production vehicle presentation remains with the existing successor.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile the corrected Scout profile and smoke with the reviewed component-recovery API; do not recreate component authority.
