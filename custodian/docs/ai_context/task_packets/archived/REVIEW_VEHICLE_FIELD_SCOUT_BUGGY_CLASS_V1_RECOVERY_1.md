# REVIEW: VEHICLE FIELD SCOUT BUGGY CLASS V1 RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `vehicle-field-scout-buggy-class-v1-recovery-1`
- Locks: `none`
- Review: `none`
- Review target workstream: `vehicle-field-scout-buggy-class-v1-recovery-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1.md`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the Scout is a concrete wreck-first production class on top of the reviewed restoration lifecycle, not a semantic rename or a bypass around restoration.
- Reviewed implementation acceptance: Verify every Acceptance clause from the archived recovery packet against landed main.
- Review evidence: Archived packet/summary, live class data/scene/runtime, predecessor restoration evidence, fresh spawn/restore/drive probe.
- Correction threshold: Correct only confirmed acceptance defects/material proof gaps; non-blocking tuning goes next-slice/deferred.
- Focused validation: Re-run the reviewed wreck-restoration smoke, registry/lifecycle/exit smokes, and implementation-created class/scene smoke.
- Review focus: Stable ID and exact movement preservation; 100 HP durability authority; exact recovery profile; semantic scene; wreck-first authored+resolver spawn; no pilotability before restore; 40 HP after restore; field repair after restore; hardpoints/seat; compatibility alias disposition; no new behavior fork.
- Acceptance: Publish findings-first durable review with stable R0-NN IDs. Blocking defects/material gaps create `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1` plus paired review. Do not patch implementation.
- Non-goals: No art judgment, economy retune, scanner work, additional class design, or direct fixes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

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
- Detailed review summary: `REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`

### Findings

#### R0-01 — P1, R1 Scout restoration still accepts raw-resource payment

- Class: `blocking_defect`
- Domain: `runtime, architecture`
- Affected acceptance: The profile requires exactly one each of `field_drive_coupler_mk1`, `custodian_control_relay_mk1`, and `structural_brace_kit_mk1`; raw-resource-only restoration fails; successful installation consumes the assemblies and restores the same Scout at 40 HP.
- Evidence: `vehicle_restoration_profiles.json` declares only `cost: { ruin_scrap: 12, structural_alloy: 6, power_components: 1 }`. `vehicle_restoration_interaction.gd` pays that `ResourceLedger` cost before calling `restore_from_wreck()`. The three required item IDs are absent from live runtime/content. The active recovery design explicitly requires component IDs for R1+.
- Proof gap: The Scout smoke asserts the raw-resource `cost`, then directly invokes `restore_from_wreck(0.4)`, bypassing the production interaction and any fabricated-item gate.
- Disposition: `correction`
- Rationale: This is a payment-authority bypass that contradicts the archived class acceptance and active recovery design. The correction must consume the reviewed component-recovery API; that predecessor review is not yet archived on current main, so the correction packet depends on it.

#### R0-02 — P2, CURRENT_STATE retains a superseded LightBuggy scene claim

- Class: `non_blocking_issue`
- Domain: `documentation`
- Affected acceptance: The semantic Scout scene replaces the old production path and no live `light_buggy.tscn` alias remains.
- Evidence: The top-level Scout state and active class spec identify `field_scout_buggy_mk1.tscn`; a later Vehicle Registry V1 paragraph still claims the production ID uses the `LightBuggy` scene. Targeted search found no `light_buggy.tscn` references in live runtime/scenes/content, and the old scene file is deleted.
- Disposition: `next_slice`
- Rationale: This stale status claim does not create a runtime alias. Reconcile it in the vehicle Asset V2/current-state documentation pass.

### Acceptance Evidence

- `run_validation.py --test vehicle_field_scout_class --json`: PASS (1/1; known ObjectDB/resource shutdown warnings).
- `run_validation.py --test vehicle_wreck_restoration --json`: PASS (1/1; known ObjectDB/resource shutdown warnings).
- `run_validation.py --test vehicle_runtime_lifecycle --json`: PASS (1/1; expected blocked-exit warning).
- `run_validation.py --test vehicle_exit_clearance --json`: PASS (1/1; expected pathological-blockage warning).
- `godot --headless --path . --script res://tools/validation/validate_vehicle_registry.gd`: PASS.
- Code review graph was rebuilt at `993633bb8d8d517cb608e7756a15a5f61d9751e6`; it analyzed the 29-file implementation change. Targeted source inspection followed graph context where snippets were unavailable.
- Reviewed runtime/profile/scene/validation files were not modified.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes` (independent review completed)
- Completion boundary satisfied: `yes` (findings and bounded correction/re-review packets recorded)
- Acceptance satisfied: `no` (R0-01 blocks class acceptance)
- Superseded/legacy production path disposition: `removed`
- Evidence: See `Acceptance Evidence` and findings above.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The class smoke passes while asserting the raw-resource profile and bypassing the actual restoration interaction; initial claim output was lost while the cold-worktree Git LFS checkout completed.
- Root cause / contributing factors: The required R1 component-recovery runtime is absent from current main; the Scout smoke directly calls the lower-level lifecycle transition.
- Prevention / pipeline improvement: Preserve the component-recovery predecessor as a hard dependency and make the Scout smoke prove raw-resource refusal, exact item consumption, and successful restoration through production interaction.
- Tooling / docs drift discovered: `CURRENT_STATE.md` retains an obsolete LightBuggy scene claim; `review_pairing_contract` was already reported failing on unrelated `visual-review-question-answer-capture-v1` metadata.
- Follow-up: `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`
- What worked: Focused vehicle validations independently reproduced their reported green status.

## Handoff

- Next workstream: `vehicle-field-scout-buggy-asset-v2 if passed`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `Only landed scene/family identity reconciliation unless findings invalidate the art contract.`
- Next action: Review class recovery independently and release Asset V2 on pass.
- Blockers or open questions: `none`
