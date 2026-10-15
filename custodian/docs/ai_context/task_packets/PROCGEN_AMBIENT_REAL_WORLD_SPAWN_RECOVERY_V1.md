# PROCGEN AMBIENT REAL-WORLD SPAWN RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-ambient-real-world-spawn-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `procgen-generation, ambient-spawn-activation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `deterministic generated-world pipeline and real actor activation require independent runtime verification`
- Reviewed main: `80bb91444`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten or replace it.
- Goal: Make the real generated-world ambient-spawn integration complete reliably for a fixed seed, with stage evidence that identifies the actual slow or rejecting authority and without changing deterministic candidate selection.
- Completion boundary: Reproduce the timeout at seed `3348744079`; add bounded stage timings for candidate generation/level-data extraction, semantic evaluation/required-ingress validation, accepted-candidate final materialization, and loader activation/real camp-enemy activation; fix only the stage demonstrated to cause the failure; prove actual Grunt and PursuitFrame population in a generated world; preserve the 180-second validation timeout.
- Current measured state: On H5's prior synchronized main (`b0cbd649`), `procgen_ambient_enemy_real_world_spawn` timed out at 180068 ms. Candidate generation logged completion for seed `3348744079` after approximately 16.8 seconds; no further stdout/stderr appeared. Historical failures include required-ingress rejection and zero camp markers, so the present failure stage is unknown. A later `vaultwing-runtime-hardening` implementation independently corrected the typed `VaultwingSpawner` pruning and brittle `vaultwing_world_spawn` fixture/header defects that the older `vaultwing-world-spawn-integrity-recovery-v1` packet had been authored to fix; its synchronized validation reports `vaultwing_world_spawn` passing. Therefore the old Vaultwing recovery/review pair is no longer a technical prerequisite for ambient-spawn diagnosis. Current main must be remeasured at execution.
- Evidence: `custodian/tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd`; `custodian/game/world/procgen/custodian_contract_map.gd::generate_contract`; `candidate_semantic_adapter.gd`; `generation/candidate_evaluator.gd`; `generation/procgen_candidate_materializer.gd`; `custodian/game/systems/core/systems/contract_world_loader.gd::_on_contract_generated`; prior report `/tmp/h5-20261010-ambient-spawn.json`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`.
- Task-specific authority: ProcGen generation/evaluation/materialization owners in the runtime optimization roadmap and `custodian/game/world/procgen/generation/README.md`; the smoke's real generated map, real walkability authority, and actual Grunt/PursuitFrame acceptance remain authoritative for the integration result.
- Work surface: Stage instrumentation in `CustodianContractMap` and the focused ambient-spawn smoke; the specifically measured generation/evaluation/materialization authority; no unrelated gameplay or broad loader refactor.
- Change: First reproduce the exact seed on current main. Emit bounded, flushed timing markers around the four stated phases so a timeout identifies the last completed phase. Record attempt acceptance/rejection reasons, required-ingress facts, selected candidate identity, marker/camp counts, and actor spawn results as compact structured diagnostics. Preserve RNG use, candidate order, scoring, required-ingress rules, and timeout. After locating the stall or rejected condition, fix that owning stage only. Do not edit H5 packets/branch or its `ContractWorldLoader`/bootstrap files; if timing proves the needed fix belongs in an H5-locked loader seam, stop and report the exact ownership conflict rather than bypassing it.
- Preserve: Exact deterministic candidate selection and output; required-ingress acceptance contract; no increased test timeout; genuine runtime walkability checks; camp activation range, caps, family choice, and spawn cadence; H5 implementation and owner lock.
- Non-goals: No suppression of the real-world test; no fabricated success or fixture-only walkability; no timeout increase; no unrelated Vaultwing patch; no H5 code/packet edits; no broad ContractWorldLoader refactor or changes outside the measured failing authority.
- Acceptance: (1) Exact seed `3348744079` reproduces the initial failure on current main before correction, or the non-reproduction is fully recorded with current stage metrics. (2) A report identifies durations and last completed event for all four phases; no phase is inferred solely from missing output. (3) The root cause is tied to evidence from the exact stage, including ingress/marker rejection as competing explanations. (4) The fix preserves deterministic selection and required-ingress semantics. (5) The real generated-world smoke observes at least one `EnemyGrunt` and one `PursuitFrame`, with actual camp/marker and runtime-walkability evidence. (6) The existing 180-second test limit is unchanged. (7) Relevant ProcGen generation, ambient spawn, and loader regressions pass; full changed-file validation is complete and green. (8) No H5-owned loader/bootstrap files are changed.
- Validation: Current-main import preflight; run `procgen_ambient_enemy_real_world_spawn` with exact `--seed=3348744079` first and save complete JSON/logs. Then test stage instrumentation against the same seed; run the focused real-world spawn smoke plus `procgen_encounter_cadence`, `ambient_actor_spawn_walkability`, `contract_world_ingress_spawn_clearance`, `contract_world_playable_region_spawn_validity`, `world_contract_prewarm`, and directly selected generation/materialization regressions. Compare deterministic candidate/seed/output fingerprints before and after. Finish with complete changed validation and `git diff --check`; do not raise the 180-second timeout.
- Task overrides: `none`
- Deferred: H5 final synchronization/closeout; broad ambient population architecture or reservations; loader ownership changes if gated by H5; enemy AI or encounter redesign; retirement/supersession cleanup of the now-redundant `vaultwing-world-spawn-integrity-recovery-v1` pair.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: no
- Completion boundary satisfied: no
- Acceptance satisfied: no
- Superseded/legacy production path disposition: `n/a`
- Evidence: Pending execution.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: none
- What went wrong: none
- Root cause / contributing factors: none
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: none
- Follow-up: none

## Next Handoff

- Next workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: none
- Next action: Claim directly when the `procgen-generation` and `ambient-spawn-activation` locks are available; first reproduce the exact ambient timeout on current main, localize it with stage evidence, then land and run the paired review.
- Blockers or open questions: none; the historical Vaultwing recovery dependency was removed as stale because its intended defect was already corrected by later Vaultwing runtime hardening.


## Planning Refresh

- Refresh reason: `removed stale dependency on the unexecuted vaultwing-world-spawn-integrity-recovery-v1 pair; later vaultwing-runtime-hardening already landed the exact world-spawn fixture/pruning corrections and reports vaultwing_world_spawn green`
- Refresh owner: `ChatGPT/user planning`
- ChatGPT/user planning refresh required: `no`
- Refreshed against live main: `b7ba5f154cbdee49ad9f56506868b95a0c02d301`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
