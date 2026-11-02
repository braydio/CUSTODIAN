# PROCGEN AMBIENT REAL-WORLD SPAWN RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-ambient-real-world-spawn-recovery-v1`
- Status: `complete`
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
- Reviewed main: `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten or replace it.
- Goal: Make the real generated-world ambient-spawn integration complete reliably for a fixed seed, with stage evidence that identifies the actual slow or rejecting authority and without changing deterministic candidate selection.
- Completion boundary: Reproduce the timeout at seed `3348744079`; add bounded stage timings for candidate generation/level-data extraction, semantic evaluation/required-ingress validation, accepted-candidate final materialization, and loader activation/real camp-enemy activation; fix only the stage demonstrated to cause the failure; prove actual Grunt and PursuitFrame population in a generated world; preserve the 180-second validation timeout.
- Current measured state: Baseline evidence at `75f38a8b17b845c901b50660bbc4083c51707e0b` reproduces exact seed `3348744079` timing out at 180s, with attempts 0-2 exhausting 65 candidates and attempt 3 accepting after about 229.7s. The implementation caches immutable ordered edge candidates, walkability/spawn/reservation/corridor predicates, and authored fallback score rankings within one resolver instance. The fallback ranking preserves the original empty-level-data candidate source and stable score tie order. Post-change decision fingerprints match baseline (`487025759`, `714827931`, `2976889989`); attempt 3 retains semantic fingerprint `948758187` and world fingerprint `1640760788`. Exact-seed attempt evaluation completed in 92.5s, final promotion in 33.5s, and the real smoke passed under the unchanged 180-second bound. It placed 8 markers/camps, spawned 1 Grunt and 1 PursuitFrame, and used the production NavigationSystem (9,951 authoritative floor cells; 622 navigation points). H5 is not an ownership blocker; `ContractWorldLoader` remains read-only.
- Evidence: preserved recovery evidence commit `75f38a8b17b845c901b50660bbc4083c51707e0b`; `custodian/tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd`; `custodian/game/world/procgen/custodian_contract_map.gd::generate_contract`; `candidate_semantic_adapter.gd`; `generation/candidate_evaluator.gd`; `generation/procgen_candidate_materializer.gd`; `custodian/game/systems/core/systems/navigation_system.gd`; read-only reference to `contract_world_loader.gd::_rebuild_navigation`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`.
- Task-specific authority: ProcGen generation/evaluation/materialization owners in the runtime optimization roadmap and `custodian/game/world/procgen/generation/README.md`; the smoke's real generated map, real walkability authority, and actual Grunt/PursuitFrame acceptance remain authoritative for the integration result.
- Work surface: The specifically measured generation/semantic/required-ingress evaluation authority; bounded stage instrumentation in `CustodianContractMap`; `custodian/tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd`; test-only setup needed to supply the real `NavigationSystem` contract. `ContractWorldLoader` is read-only for this slice. No H5 packet/branch mutation, unrelated gameplay work, or broad loader refactor.
- Change: The exact-seed baseline reproduction and stage localization are already satisfied by the preserved evidence above; remeasure after synchronizing current main, but do not burn another long diagnostic unless the failure shape materially changed. Before optimization, record a compact deterministic decision fingerprint for each attempt: attempt index, ordered candidate identity/count, required-ingress result/rejection reason, and eventual accepted candidate/world fingerprint. Optimize only repeated computation demonstrated inside generation/semantic/required-ingress evaluation so the same candidate sequence reaches the same attempt-3 accepted world substantially faster. Preserve RNG consumption, candidate order, scoring, connector rules, rejection reasons, and required-ingress semantics. Reuse/cache already-derived immutable candidate/semantic/connectivity facts where profiling proves repeated work; do not skip rejected candidates, lower the 65-candidate search contract, weaken the Ritualant ingress requirement, or change accepted-candidate selection. The previously tested front-queue rewrite in `_runtime_floor_component()` had no material timing effect and is explicitly out unless new profiling disproves that result. Repair the focused real-world smoke's navigation fixture inside the smoke/test-support surface. Prefer instantiating the production `NavigationSystem` script and letting existing `ContractWorldLoader._rebuild_navigation()` call its public `set_runtime_tilemaps(...)/rebuild()` contract; a minimal stand-in is acceptable only if it truthfully rebuilds from the generated map's runtime navigation/walkability authority and preserves the smoke's real actor-spawn proof. Do not change `ContractWorldLoader` merely to accommodate the fixture, and do not fake `rebuild()` as an unconditional no-op/success path. Keep compact flushed phase/attempt diagnostics sufficient to attribute future timeouts without per-candidate log spam. After the measured generation/evaluation correction and fixture repair, the unchanged 180-second smoke must reach marker/camp placement and observe at least one real `EnemyGrunt` and one real `PursuitFrame`.
- Preserve: Exact deterministic candidate ordering, rejection sequence, attempt-3 accepted world/output fingerprint, required-ingress acceptance contract and connector rules; unchanged 180-second timeout; genuine runtime navigation/walkability checks; camp activation range, caps, family choice, and spawn cadence; `ContractWorldLoader` behavior; H5 implementation.
- Non-goals: No suppression of the real-world test; no fabricated success/no-op navigation; no timeout increase; no candidate skipping/reordering or Ritualant ingress weakening; no retry of the disproven front-queue optimization without new profiling evidence; no unrelated Vaultwing patch; no H5 code/packet edits; no `ContractWorldLoader` implementation changes; no broad ProcGen refactor.
- Acceptance: (1) Exact seed `3348744079` has durable before-correction evidence reproducing the 180-second failure and the attempt-0..3 stage timings. (2) Before/after decision fingerprints prove attempts 0-2 retain the same ordered candidate/rejection results and attempt 3 retains the same accepted candidate/world fingerprint. (3) The correction is tied to measured repeated work in generation/semantic/required-ingress evaluation; candidate order, RNG use, scoring, connector rules and ingress semantics are unchanged. (4) Acceptance is reached with enough headroom for the complete real-world integration to finish inside the existing 180-second timeout; target the generation+acceptance path materially below the budget rather than a marginal pass. (5) The smoke fixture satisfies the production navigation contract without modifying `ContractWorldLoader`; real generated-map walkability/navigation is used. (6) The real generated-world smoke observes marker/camp placement plus at least one `EnemyGrunt` and one `PursuitFrame`. (7) Relevant ProcGen generation, ingress, navigation, ambient spawn and loader regressions pass; changed-file validation is green apart from independently reproduced unrelated baselines, which must be named explicitly. (8) No H5-owned code/packet or loader/bootstrap implementation is changed.
- Validation: Fetch/reconcile current main first. Preserve the existing `75f38a8b...` before-correction evidence; if the live failure shape still matches, use focused profiling runs rather than repeating multi-minute diagnostics gratuitously. Add a deterministic attempt/candidate/ingress fingerprint fixture or report, then optimize the measured owner and compare before/after fingerprints. Repair the smoke navigation fixture and run `procgen_ambient_enemy_real_world_spawn` with exact seed `3348744079` under its unchanged 180-second manifest timeout. Also run `procgen_encounter_cadence`, `ambient_actor_spawn_walkability`, `contract_world_ingress_spawn_clearance`, `contract_world_playable_region_spawn_validity`, navigation-focused coverage that exercises real `NavigationSystem.rebuild()`, `world_contract_prewarm`, and directly affected generation/materialization regressions. Finish with changed-file validation and `git diff --check`; do not raise the 180-second timeout.
- Task overrides: `none`
- Deferred: Broad ambient population architecture/reservations; enemy AI or encounter redesign; any loader/bootstrap ownership change; retirement/supersession cleanup of the redundant `vaultwing-world-spawn-integrity-recovery-v1` pair.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: `n/a`
- Evidence: Exact-seed smoke passed under 180s; attempt and accepted-world fingerprints match baseline; real NavigationSystem and both enemy families verified. Changed-file validation passed 10/10 selected tests; focused generation/materialization/navigation/spawn/loader regressions passed; `git diff --check` passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The first resolver cache retained a mismatch in the legacy fallback candidate source; fingerprint comparison exposed it before final validation, and the cache was aligned to the original empty-level-data scan.
- Root cause / contributing factors: Repeated fallback ranking and linear floor membership scans dominated rejected ingress evaluation; the smoke rig had drifted from the production NavigationSystem API.
- Prevention / pipeline improvement: Preserve attempt-level timings/fingerprints and compatibility details in deterministic fallback paths.
- Tooling / docs drift discovered: none
- Follow-up: none

## Next Handoff

- Next workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: none
- Next action: Archive/close the implementation packet through the workstream finish lifecycle, land on origin/main, then launch the paired review in a fresh context.
- Blockers or open questions: none. `ContractWorldLoader` remains read-only; reviewer should falsify candidate fingerprints, full 180-second completion, and real navigation/actor proof.


## Planning Refresh

- Refresh reason: `2026-10-15 exact-seed evidence localized the timeout to repeated required-ingress rejection/evaluation and exposed a stale NavigationSystem smoke fixture; live H5 does not own ambient-spawn-activation, so both repairs remain inside this packet while ContractWorldLoader stays read-only`
- Refresh owner: `ChatGPT/user planning`
- ChatGPT/user planning refresh required: `no`
- Refreshed against live main: `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1`
- Preserved evidence branch commit: `75f38a8b17b845c901b50660bbc4083c51707e0b`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
