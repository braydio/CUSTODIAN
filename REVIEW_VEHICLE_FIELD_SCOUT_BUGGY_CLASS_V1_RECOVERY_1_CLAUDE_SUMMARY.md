# Review: Vehicle Field Scout Buggy Class V1 Recovery 1

- Workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Reviewed main: `993633bb8d8d517cb608e7756a15a5f61d9751e6`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b
- Reviewer context: fresh
- Reviewer provenance: different-agent

## Result

**Needs correction.** The Scout is correctly registered as a semantic wreck-first class with data-owned 100 HP durability, preserved movement tuning, the declared seat/hardpoints/footprint, post-restoration entry, and field repair. Both authored and registry-resolver spawn paths enter WRECKAGE. The old `light_buggy.tscn` file has no live runtime alias.

Blocking finding **R0-01 (P1)**: the live `field_scout_recovery_light` profile still charges 12 ruin scrap, 6 structural alloy, and 1 power component directly through `ResourceLedger`. The R1 SERVICE design and archived class acceptance require one fabricated `field_drive_coupler_mk1`, one `custodian_control_relay_mk1`, and one `structural_brace_kit_mk1`. The class smoke currently validates the raw cost and directly calls `restore_from_wreck(0.4)`, so its passing result does not prove component-gated restoration. Correction and paired re-review packets are authored. The correction depends on completion/review of the missing component-recovery predecessor.

Non-blocking finding **R0-02 (P2)**: a later section of `CURRENT_STATE.md` still describes the old production ID as backed by the `LightBuggy` scene. This is stale documentation only; live path searches found no runtime alias. Defer reconciliation to the vehicle Asset V2/current-state pass.

## Evidence

- `python3 custodian/tools/validation/run_validation.py --test vehicle_field_scout_class --json`: PASS, 1/1; known ObjectDB/resource shutdown warnings.
- `python3 custodian/tools/validation/run_validation.py --test vehicle_wreck_restoration --json`: PASS, 1/1; known ObjectDB/resource shutdown warnings.
- `python3 custodian/tools/validation/run_validation.py --test vehicle_runtime_lifecycle --json`: PASS, 1/1; expected blocked-exit warning.
- `python3 custodian/tools/validation/run_validation.py --test vehicle_exit_clearance --json`: PASS, 1/1; expected pathological-blockage warning.
- `cd custodian && godot --headless --path . --script res://tools/validation/validate_vehicle_registry.gd`: PASS.
- Rebuilt code-review graph at the reviewed main SHA and analyzed the 29-file implementation change; targeted source review covered the Scout data, scene, resolver, lifecycle, interaction, and class smoke.
- No reviewed implementation/runtime files were modified.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: The Scout smoke passed while asserting the raw-resource profile and bypassing the actual restoration interaction. Initial dispatcher output was lost while Git LFS completed cold-worktree checkout.
- Root cause / contributing factors: The R1 component-recovery runtime is absent from current main, while the Scout smoke directly invokes the lower-level lifecycle transition.
- Prevention / pipeline improvement: Keep component recovery as a hard predecessor and prove raw-resource refusal, exact assembly consumption, and production-interaction restoration in the Scout smoke.
- Tooling / docs drift discovered: `CURRENT_STATE.md` contains a stale LightBuggy scene claim; the implementation handoff records an unrelated `review_pairing_contract` failure for `visual-review-question-answer-capture-v1`.
- Follow-up: vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1
- What worked: Focused vehicle validations independently reproduced their reported green status.

## Next Handoff
- Next workstream: vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b
- Refresh reason: Wait for `review-vehicle-part-fabrication-recovery-v1` to archive complete, then reconcile the correction with its reviewed component API.
- Next action: Claim the Scout correction when both dependencies are complete; then run the paired correction review before releasing Asset V2.
- Blockers or open questions: `review-vehicle-part-fabrication-recovery-v1` is not archived complete on current main.
