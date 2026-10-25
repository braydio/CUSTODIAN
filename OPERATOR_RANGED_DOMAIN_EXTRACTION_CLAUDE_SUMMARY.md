# Operator Ranged Domain Extraction (F3) — Recovery Continuation

Workstream: `operator-ranged-domain-extraction`
Status: partial; implementation remains in the original dirty worktree, with its pre-recovery contents preserved externally.
Authoring chat: not-recorded

## Preserved identity and implementation

- Existing run: `20261012T023824Z-1d7e0a9b4533`; original branch commit `8c3ed99e31f0cafe301b203af67e5a004f32582e`.
- Current `origin/main`: `a6b419e23758ba789f1c197a5c76045515b122f5`. The original branch was an ancestor of main; commit `9d40bf760` preserves the recovered F3 work, then supported resume merged current main as `a4a282998ce86fd77ac171768457df841494f289`. RunTrace records `worktree_resumed` for the original checkout.
- Pre-recovery full-worktree preservation: `/home/braydenchaffee/Projects/.custodian-preserved/operator-ranged-domain-extraction-20261025T011444Z-20261012T023824Z-1d7e0a9b4533`, manifest SHA-256 `47fff7c25ebb2e8b5b8777c18f352bee2106c610d0b5fd9700baeaa2a75078aa`. The verified archive includes 62,807 entries / 6,902,603,373 bytes, tracked and untracked state, ignored artifacts, Git bundle and metadata.
- Existing ranged controller extraction, actor facade changes, runtime-state integration and F3 smoke/scenario changes remain in the original claimed worktree. No branch, claim or lock was replaced.

## Recovery correction and verification

- Moment Forge sidearm setup now calls the public `grant_sidearm` operation, which fills the actual runtime magazine; the earlier raw slot-property setup was not a valid gameplay setup.
- `operator_input_router.gd` now reports press/release edges only when the action changes relative to the prior sampled tick. This prevents Godot's repeated just-pressed observation while an input remains held across physics samples from buffering an unintended second sidearm shot.
- Direct `operator_ammo_reconciliation_smoke.gd` passed. `operator_input_frame`, `operator_ranged_ballistic_aim`, `operator_fixed_tick_spine`, `operator_primary_ranged_modular_fire`, `operator_ranged_ready_input`, `operator_sidearm_canonical`, `operator_weapon_socket`, and `operator_visual_ownership` passed individually.
- Sidearm capture passed with exactly one shot at tick 80, no deferred duplicate, lower locomotion preserved, and recovery before held: `/home/braydenchaffee/Projects/.custodian-preserved/operator-ranged-domain-extraction-f3-validation-20261025T013200Z/reports/moment_forge/combat/operator_sidearm_strafe_fire_recovery/operator-ranged-f3-sidearm-recovery-evidence/`.
- Primary strafe/raise/fire/lower evidence capture passed: `/home/braydenchaffee/Projects/.custodian-preserved/operator-ranged-domain-extraction-f3-validation-20261025T013200Z/reports/moment_forge/combat/operator_primary_ranged_strafe_raise_fire_lower/operator-ranged-f3-primary-recovery-evidence/`.
- `python3 -m py_compile custodian/tools/iteration/run_moment.py` and `git diff --check` passed.

## Closeout blockers

The first `run_validation.py --changed --base origin/main --json` on the stale worktree saw 190 paths, including report artifacts and two `.uid` files already tracked on current main. After preserving and relocating those artifacts, the rerun saw 13 changed paths, selected 56 tests, passed 10, failed 1 and skipped 45. It also reported three uncovered paths: `moment_runner.gd` and the two new Moment Forge scenario JSON files. This was before current-main synchronization.

The single failure, `operator_2_5d_cohort_dependency_closure`, was independently reproduced in a detached clean worktree at current `origin/main` (`a6b419e23`). The closure smoke sees its authoring workspace as available while all eight `idle_relaxed_01` source-strip paths are unavailable; all eight corresponding source-session hashes match the correction receipt. It fails `all(item["source_strip_hash_matches_correction"] for item in idle)`. This is current-main evidence and blocks a genuine green changed-file report; no exception or validation waiver was applied.

Post-sync `operator_input_frame` passed. The first post-sync `operator_ranged_ballistic_aim` run timed out. Godot reported that `operator.tscn` could not load `operator_runtime_frames.tres`; direct loading identifies the nested stale resource at line 4550: `res://content/sprites/operator/runtime/animations/ranged_2h/posture/relaxed_01/operator__full_body__ranged_2h__posture__relaxed_01__n__5f__128.png`. That image is intentionally absent, and a successful headless editor import did not repair the generated resource. No generated files were hand-edited.

The F3 implementation and documentation were committed as `9d40bf760` on the original branch. After the reports and two main-owned `.uid` files were checksum-preserved externally, the supported `workstream.py resume` merged current main into the same branch as `a4a282998`; RunTrace records the resume. The merge and post-sync summary update are now on the local branch; checkpoint/push remains pending. Post-sync import sidecars were also preserved externally at `/home/braydenchaffee/Projects/.custodian-preserved/operator-ranged-domain-extraction-import-sidecars-20261025T013620Z/`, manifest SHA-256 `fbe1662ca485cccd955b07b37880e294c3874518a815f748387450f00a0c17d1` (13 files / 13,111 bytes). The branch can become clean after the summary receipt commit. F3 remains active and holds `operator-runtime`; no finish or lock release occurred.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: high
- What went wrong: initial sidearm setup bypassed the public grant path; the full-scene run then exposed repeated physics-tick press edges. After those were corrected, canonical changed-file validation found a separate current-main closure-evidence failure and skipped higher tiers.
- Root cause / contributing factors: scenario setup used a slot flag without initializing the runtime magazine; raw engine edge state could recur during a held input; current-main closure evidence points to unavailable external source strips despite matching session hashes.
- Prevention / pipeline improvement: Moment Forge setup uses allowlisted public operations; maintain one-shot recovery assertions; repair or correctly resolve source-strip provenance before rerunning the changed-file gate.
- Tooling / docs drift discovered: `operator_input_frame` already documents and tests single-tick edge semantics, but the raw `Input.is_action_just_pressed` OR bypassed prior-sample de-duplication. Ammo reconciliation still has no manifest test ID.
- Follow-up: manual-follow-up
- What worked: verified external preservation, isolated focused tests, and one compact evidence capture per required presentation scenario.

## Next Handoff
- Next workstream: `operator-ranged-domain-extraction`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: resolve the current-main source-strip evidence failure through its owning evidence authority, then synchronize this existing workstream and rerun canonical validation.
- Blockers or open questions: clean current `origin/main` fails `operator_2_5d_cohort_dependency_closure` because eight source-strip paths are unavailable; original F3 worktree remains dirty and 614 commits behind current main.
