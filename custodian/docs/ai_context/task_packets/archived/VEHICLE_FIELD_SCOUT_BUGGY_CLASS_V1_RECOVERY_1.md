# VEHICLE FIELD SCOUT BUGGY CLASS V1 RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-class-v1-recovery-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-part-fabrication-recovery-v1`
- Locks: `vehicle-content, vehicle-runtime-scene`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `concrete production class integration over the reviewed wreck-restoration lifecycle`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Ship the Custodian Field Scout Buggy Mk I as the first concrete R1 SERVICE vehicle class over the reviewed wreck, diagnosis, knowledge, and fabricated-component recovery stack.
- Completion boundary: Done when stable registry ID `custodian_ground_buggy_scout_light` resolves to semantic `field_scout_buggy_mk1.tscn`, named durability and R1 SERVICE restoration profiles are data-owned, the live game/registry spawn paths produce the Scout as WRECKAGE, restoration requires the three reviewed fabricated service assemblies rather than raw-resource payment, the restored vehicle has the declared seat/footprint/hardpoints and 100-HP durability, existing field repair can operate after restoration, and old `light_buggy` compatibility naming has an explicit exit disposition.
- Current measured state: Lifecycle V1 is complete/reviewed. The pre-restoration class branch now contains donor commit `b3b40921f1fd08c6aff529cbe0b39953587bbb85`. It is superseded as a workstream but contains useful semantic class work: scene rename, 100-HP durability profile, stable registry binding, compatibility visual-kit rename, game/world-origin updates, and `vehicle_field_scout_class_smoke.gd`. It must not land directly because it still boots healthy/pilotable and predates wreck restoration. Live main still uses `light_buggy.tscn`, generic exported health, hover-buggy visual kit, and no class durability/restoration-profile identity.
- Donor evidence: selectively reapply/rebase the useful changes from `b3b40921f1fd08c6aff529cbe0b39953587bbb85` only after the reviewed wreck-restoration predecessor lands. Treat the donor as implementation evidence, not merge authority; re-derive conflicts against current main and preserve wreck-first startup/group/payment semantics.
- Evidence: Reviewed wreck-restoration predecessor; `custodian/content/vehicles/{vehicle_archetypes,vehicle_movement_profiles,vehicle_hardpoint_profiles,vehicle_loadouts,vehicle_visual_kits}.json`; live class scene; `game.tscn`; `vehicle_definition.gd`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `FIELD_SCOUT_BUGGY_MK1.md`; reviewed wreck-restoration API; `VEHICLES.md`.
- Work surface: Vehicle class data/schema; durability profile data; semantic `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`; game/registry consumers; class-focused validation.
- Change: Preserve the stable ID and exact `ground_wheeled_light` tuning (175 max speed, 420 acceleration, 520 deceleration, 10 turn response, 0.45 reverse, 0.78 offroad). Set display identity `Custodian Field Scout Buggy Mk I`; add durability profile `light_scout_utility` at 100 max HP and preserve the reviewed R1 SERVICE `field_scout_recovery_light` component requirements. Reuse the donor's semantic scene/durability/registry/validation work where it still fits current main. Create/migrate the semantic scene with one driver, 64px entry range after restoration, 2x1 bottom-center footprint, `Hardpoints/FrontLight`, `Hardpoints/RearUtility`, no weapon, and the reviewed restoration interaction plus an ordinary FieldRepairInteraction compatible with >0 HP. Live authored and registry spawn paths must begin as wreckage; raw resources alone cannot restore the Scout; the reviewed three fabricated service assemblies are consumed through the restoration flow and restored state begins at 40 HP. Keep loadout `none`. Remove or explicitly alias `light_buggy.tscn` only for proven live consumers. Temporary hover art is compatibility presentation until Asset V2 successor.
- Preserve: Reviewed restoration/lifecycle ownership; stable registry ID; exact movement feel; terrain multiplier; safe exit; procgen placement locations/counts; ResourceLedger authority; unarmed utility role.
- Non-goals: No scanner behavior, fuel, cargo, passengers, weapons, collision damage, handling rebalance, production art, or new stateful subclass unless live behavior genuinely requires one.
- Acceptance: Registry resolves the stable ID to semantic Scout scene/display name; durability max is data-owned 100; restoration profile is R1 SERVICE with exactly one `field_drive_coupler_mk1`, one `custodian_control_relay_mk1`, one `structural_brace_kit_mk1`, 4 sec bootstrap, and 40% health; both live spawn paths start wrecked and non-pilotable; after restore the declared driver/hardpoints/footprint are present and entry works; ordinary field repair can increase health above 40; exact movement values match pre-migration; no stale constant health presentation remains; any `light_buggy` compatibility alias has a named consumer/exit condition.
- Validation: Re-run reviewed wreck-restoration, vehicle knowledge, and part-fabrication/recovery smokes plus registry validation, lifecycle and exit smokes. Add/update a focused Scout class/scene smoke for exact movement/durability/restoration values, semantic scene, seat/hardpoints, wreck-first game-scene instantiation, post-restoration entry and field-repair compatibility; register it in validation manifest before closeout.
- Task overrides: `none`
- Deferred: Production wheeled/wreck/restoration art, scanner behavior, mounted combat, additional chassis classes, persistence across world reconstruction.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile landed restoration, knowledge, and component-recovery helper/signal names only. The old claimed class branch is donor implementation evidence at `b3b40921`, but never merge authority. Reapply only the compatible semantic class changes after restoration; do not revive its pristine-spawn contract or stale packet lifecycle metadata.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: removed
- Evidence: focused Scout class, wreck restoration, registry contract, runtime lifecycle, and exit clearance validations passed. The changed-file sweep selected 28 checks, with 10 passed, 1 failed, and 17 skipped; its only failure was the unrelated `review_pairing_contract` report for `visual-review-question-answer-capture-v1`. The standalone world-origin smoke reported two unrelated unclassified World children (`WorldEnvironmentDirector`, `Ambient`). JSON parsing and `git diff --check` passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: changed-file sweep completed but its output was not retained; standalone world-origin contract smoke reported existing unrelated child classification errors.
- Root cause / contributing factors: unrelated review packet metadata is inconsistent; world-origin fixture has existing unclassified direct World children.
- Prevention / pipeline improvement: capture validation command output to a durable temporary report; classify direct World children in the owning world-origin task.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: focused Scout and four required vehicle lifecycle validations passed.

## Handoff

- Next workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally so paired review gates Asset V2 presentation.
- Blockers or open questions: `none after predecessor review and stale-claim recovery`

## Independent Review

- Status: `findings`
- Review workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Reviewed on main: `993633bb8d8d517cb608e7756a15a5f61d9751e6`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `1`
- Material evidence gaps: `1 (included in R0-01)`
- Non-blocking issues: `1`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `R0-02`
- Human-decision finding IDs: `none`
- Detailed review packet: `custodian/docs/ai_context/task_packets/archived/REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1.md`
- Detailed review summary: `REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`

### Findings

#### R0-01 — P1, R1 Scout restoration still accepts raw-resource payment

- Class: `blocking_defect`
- Domain: `runtime, architecture`
- Affected acceptance: The profile requires one each of `field_drive_coupler_mk1`, `custodian_control_relay_mk1`, and `structural_brace_kit_mk1`; raw-resource-only restoration fails; successful installation consumes the assemblies and restores the same Scout at 40 HP.
- Evidence: `custodian/content/vehicles/vehicle_restoration_profiles.json` declares only `cost: { ruin_scrap: 12, structural_alloy: 6, power_components: 1 }`. `custodian/game/vehicles/vehicle_restoration_interaction.gd` pays that `ResourceLedger` cost before calling `restore_from_wreck()`. The three component IDs are absent from live runtime/content, despite the active R1 recovery design requiring component IDs.
- Proof gap: `vehicle_field_scout_class_smoke.gd` asserts the raw-resource cost and directly invokes `restore_from_wreck(0.4)`, bypassing the production interaction and component requirement.
- Disposition: `correction`
- Rationale: The raw-resource path is a production payment-authority bypass that contradicts the archived acceptance and active design. Correction 1 must consume the reviewed component-recovery API and is dependency-gated on its pending paired review.

#### R0-02 — P2, CURRENT_STATE retains a superseded LightBuggy scene claim

- Class: `non_blocking_issue`
- Domain: `documentation`
- Affected acceptance: The semantic Scout scene replaces the old production path and no live `light_buggy.tscn` alias remains.
- Evidence: The top-level Scout section and active class spec identify `field_scout_buggy_mk1.tscn`, while the later Vehicle Registry V1 paragraph still claims the production ID uses `LightBuggy`. Live runtime/scenes/content search found no `light_buggy.tscn` reference, and the old scene file is deleted.
- Disposition: `next_slice`
- Rationale: Stale documentation does not create a runtime alias; reconcile it during the vehicle Asset V2/current-state pass.

### Review Evidence

- `vehicle_field_scout_class`: PASS (1/1; known ObjectDB/resource shutdown warnings).
- `vehicle_wreck_restoration`: PASS (1/1; known ObjectDB/resource shutdown warnings).
- `vehicle_runtime_lifecycle`: PASS (1/1; expected blocked-exit warning).
- `vehicle_exit_clearance`: PASS (1/1; expected pathological-blockage warning).
- `vehicle_registry_contract`: PASS.
- `review_pairing_contract`: FAIL only for unrelated `visual-review-question-answer-capture-v1` malformed override/target metadata; this review's correction/re-review pair was not listed as a failure.
- The reviewed runtime/profile/scene/validation files were not modified.
