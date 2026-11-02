# Operator Guard / Parry Composition Polish

## Result

Vigil armed guard and unarmed parry now use `OperatorPresentationController`'s shared defensive composition seam. The caller supplies gameplay movement legality and exact semantic identities; the controller validates the complete body/overlay plan before ownership transfer, selects the movement-owned lower identity when available, falls back to the authored lower/upper pair otherwise, and keeps the lower animation clock when its identity remains unchanged. Vigil's canonical dagger stays synchronized with the defense action. Missing required Vigil upper/weapon art returns to the existing complete-presentation fallback. Parry attempt/recovery do not add a movement lock; existing displacement locks still select the paired pose.

Unarmed guard was moved onto the same seam as well, removing its direct split-body presentation call and obsolete debug prints. The unused actor-local parry FX presentation method was removed after its behavior moved into the validated composition request. Guard simulation, timing, stamina, hit-stop, and break behavior were not changed.

## Evidence

- Focused passes: `operator_guard_flow`, `operator_parry_presentation`, `operator_modular_defense_ranged`, `operator_vigil_dagger`, `operator_visual_ownership`, and `operator_upper_fx_canonical`. The Vigil smoke includes a missing required dagger negative control and proves fallback to one complete body.
- Canonical FX pass: `operator_upper_fx_canonical`; recovery fallback now retires stale parry FX, and success/attempt FX identities are validated by the composition request.
- Moment Forge: `combat/operator_mobile_guard_strafe`, `--capture-mode evidence`, passed at `reports/moment_forge/combat/operator_mobile_guard_strafe/20261011T213553-0400`. Telemetry records parry start, active, and expiry while the lower keeps westward locomotion and the upper keeps east-facing defense.
- Changed-file closeout: final `run_validation.py --changed --base origin/main --json` selected 89, passed 89, failed 0, timed out 0, skipped 0, and reported zero uncovered files.
- `git diff --check` passed.

## Friction and Limits

One `git lfs pull` was mistakenly invoked despite the repository's local-only validation recipe. The command output was not captured, so whether it downloaded objects cannot be proven from its command record. The worktree preflight later found no checked-out pointers; no tracked art files were modified. The first Godot import in the fresh worktree reached the 120-second runner timeout after producing its import cache; focused checks then passed. The first Moment Forge run failed only at the old tick-78 post-release animation expectation; the scenario was corrected and the evidence rerun passed. A first implementation pass also had a smoke declaration-order parse error and an inferred selector type error; both were fixed. The first changed-file run found an existing FX smoke still called the superseded helper; the fallback FX cleanup and test were updated, its focused smoke passed, and the final 89-test sweep passed.

The evidence run proves structured runtime identities and visibility; it is not a human aesthetic approval. No source-work art, Asset V2 intake, or committed-action presentation was changed.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: `git lfs pull` was mistakenly invoked once; its output was not captured, leaving fetch activity unverifiable. First-run import timed out after cache generation, and the initial scenario assertion assumed the guard pose remained after its parry/guard release. The first changed-file run caught a remaining canonical FX smoke call to the removed helper.
- Root cause / contributing factors: Fresh worktree had no Godot import cache; scene-loading defensive/FX smoke entries were marked `needs_import: false`; the LFS command was issued before rechecking the local-only recipe.
- Prevention / pipeline improvement: Mark defensive/FX scene smokes `needs_import: true`, test FX through the current presentation path, and use only the repository's exact-path local-cache/local-donor LFS workflow.
- Tooling / docs drift discovered: Six required defensive/FX Operator smoke entries lacked the import prerequisite in `validation_manifest.json`.
- Follow-up: none
- What worked: Deterministic composition, identity, weapon-presence, and progress checks established the runtime contract before the single evidence capture and final changed sweep.

## Next Handoff

- Next workstream: `operator-loadout-domain-extraction`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Claim the ready F1 loadout extraction through the dispatcher.
- Blockers or open questions: none
