# Operator Ranged Domain Extraction (F3) — Recovery Continuation

Workstream: `operator-ranged-domain-extraction`
Status: partial; the original claimed branch and worktree remain active.
Authoring chat: not-recorded

## Recovery and runtime publication

- Fetched `origin/main` at `d80f498f32b2702ce9f6f95fd91c203e73f4f178` and read the current existing-workstream continuity and lifecycle rules. The F3 checkout was clean, no process was writing in that checkout, and `workstream.py resume operator-ranged-domain-extraction` resumed the existing branch in place. It merged current main without conflict; no claim or worktree was replaced.
- The canonical strict Operator sync selected 588 assets with zero warnings. Its generated manifest no longer references the intentionally removed north relaxed posture PNG. Godot import and `build_operator_runtime_frames.gd` completed; the SpriteFrames resource contains 588 animations. A structured check found no missing PNG references among the 588 manifest/resource paths.
- Focused F3 validation passed 7/7: `operator_modular_defense_ranged`, `operator_ranged_ballistic_aim`, `operator_fixed_tick_spine`, `operator_primary_ranged_modular_fire`, `operator_ranged_ready_input`, `operator_sidearm_canonical`, and `operator_weapon_socket`.
- Commit `c1676941236324883ecc2ac5a9908b36c38951d7` contains only the generated runtime manifest and SpriteFrames correction. It was pushed to the original `agent/operator-ranged-domain-extraction` branch through the normal checkpoint lifecycle; the checkout remains active and the `operator-runtime` lock remains held.

## Validation and remaining gates

- Canonical changed-file validation on the synchronized F3 branch selected 61 tests: 13 passed, one failed, and 47 were skipped after the unit-tier failure. The failure is `operator_2_5d_cohort_dependency_closure`; it asserts all eight historical source-strip hashes match even though those files are unavailable. The higher-tier skips are downstream of this unit failure.
- The separately owned `operator-2-5d-source-strip-evidence-availability-correction-v1` worktree was clean and had no process writer, so it was resumed in place. Its focused smoke and changed-file validation pass (3/3, complete coverage). Its normal finish is blocked by the existing archive transition: archived packet transition `ab4071bad05854eaed87e14f5baef69a6365da41` is not the current tip after the authorized main sync and required summary-name repair at `c2bfac58fdf02bb12b7ca3fdf303b969f7ef4e39`. That correction remains off main and its worktree remains preserved.
- The two runtime resources are valid in the F3 checkout, but AP2 remains gated until the correction is landed and F3 changed-file validation is green. No Alpine artwork or evidence was altered.
- Godot generated 13 import sidecars during import. Their source PNGs are all tracked; only those exact new sidecars were removed. No source PNG or unique evidence was removed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: high
- What went wrong: the canonical SpriteFrames still referenced a removed north posture sheet; after repairing it through the producer pipeline, changed-file validation remained blocked by the separate source-strip evidence smoke and its correction's archive-transition gate.
- Root cause / contributing factors: the manifest and SpriteFrames had both retained stale generated state; the source-strip smoke treated unavailable files as hash mismatches; the correction branch's archived packet predates its required summary repair and current-main sync.
- Prevention / pipeline improvement: keep runtime manifest and SpriteFrames regeneration coupled; give source-strip evidence explicit unavailable/mismatch states; reconcile archived packet transition provenance before applying current main to already archived work.
- Tooling / docs drift discovered: normal same-claim resume succeeds under the updated policy, but the archived source-strip correction's finish gate does not accept its resume-bound sync plus required summary repair.
- Follow-up: `operator-2-5d-source-strip-evidence-availability-correction-v1`
- What worked: exact claim continuation, canonical asset generation, reference integrity check, focused smokes, and a normal remote checkpoint preserved the F3 repair.

## Next Handoff

- Next workstream: `operator-ranged-domain-extraction`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: resolve the source-strip correction's archive-transition provenance through its supported lifecycle, land it, rerun F3 changed-file validation, then finish F3 and reevaluate AP2.
- Blockers or open questions: source-strip correction is validated but not on main because its archived packet transition guard rejects the post-archive summary repair; F3 cannot finish green until that correction is landed.
