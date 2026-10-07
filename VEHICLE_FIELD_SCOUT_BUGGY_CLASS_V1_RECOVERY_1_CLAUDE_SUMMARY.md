# Vehicle Field Scout Buggy Class V1 Recovery 1

## Result

Implemented the first concrete Scout vehicle class over the reviewed wreck-restoration lifecycle. Stable registry identity `custodian_ground_buggy_scout_light` now resolves to `Custodian Field Scout Buggy Mk I` and `field_scout_buggy_mk1.tscn`. The named `light_scout_utility` durability profile owns 100 HP; `field_scout_recovery_light` retains the exact 12 scrap, 6 alloy, 1 power component, 4-second, 40%-health recovery contract. Registry and authored game-scene paths both begin in WRECKAGE and remain non-pilotable until restored.

Preserved the `ground_wheeled_light` tuning (175 max speed, 420 acceleration, 520 deceleration, 10 turn response, 0.45 reverse, 0.78 offroad, road multiplier enabled), one driver, 64-pixel entry range, 2x1 bottom-center footprint, front light/rear utility hardpoints, and empty loadout. The old scene filename has no live compatibility alias; live consumers were migrated. Removed the unbound constant HealthBar, added the existing field repair interaction to the semantic scene, and verified restoration to 40 HP can be repaired and entered.

## Validation and measurements

- Passed `vehicle_field_scout_class`, `vehicle_wreck_restoration`, `vehicle_registry_contract`, `vehicle_runtime_lifecycle`, and `vehicle_exit_clearance`.
- The Scout smoke verifies exact registry/data values, both wreck-first spawn paths, restoration, entry, and repair above 40 HP. It emits known Godot shutdown leak warnings (6 ObjectDB instances and 2 resources) despite passing.
- The changed-file sweep selected 28 checks (10 passed, 1 failed, 17 skipped); its only failure was the unrelated `review_pairing_contract` check for `visual-review-question-answer-capture-v1`. The standalone world-origin smoke reported two unclassified direct `World` children (`WorldEnvironmentDirector`, `Ambient`); those are outside this class change.
- `git diff --check` and JSON parsing passed.

## Negative controls and deferred work

No weapon, scanner behavior, production art, fuel, cargo, passenger capacity, or extra vehicle state authority was added. Hover visuals remain explicitly named compatibility presentation for the Asset V2 successor. No `light_buggy.tscn` live alias remains. The donor commit was used only as evidence and was not merged as authority.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: changed-file sweep failed on the unrelated `review_pairing_contract` check for `visual-review-question-answer-capture-v1`; standalone world-origin smoke reported unrelated existing child classification errors.
- Root cause / contributing factors: unrelated review packet metadata is inconsistent; world-origin fixture has unclassified direct children.
- Prevention / pipeline improvement: reconcile the unrelated review packet metadata and classify the direct children in the owning world-origin task.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: focused Scout and required vehicle lifecycle validations passed.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Next Handoff
- Next workstream: review-vehicle-field-scout-buggy-class-v1-recovery-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b
- Refresh reason: none
- Next action: Finish the implementation workstream so the paired independent review can verify the wreck-first class contract.
- Blockers or open questions: none
