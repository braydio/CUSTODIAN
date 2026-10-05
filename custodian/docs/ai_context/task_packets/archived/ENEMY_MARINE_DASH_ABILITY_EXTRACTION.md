# ENEMY MARINE DASH ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-marine-dash-ability-extraction-recovery-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-enemy-marine-dash-ability-extraction-recovery-1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `5a82486a46f30ad8753625133e1c6cee7eddd958`
- Authoring chat: `not-recorded`
- Goal: Move Marine Dash from `enemy.gd` into one complete actor-local ability authority while preserving the current tactical-dash behavior, tuning, combat results, presentation requests, and Sundered Keep ambush integration.
- Completion boundary: This workstream owns only Marine Dash state/tuning extraction, the narrow `Enemy` service/delegation seam required by that extraction, direct Marine-dash callers, focused validation ownership, and consequence-driven docs. It is done when Marine Dash phase/timer/target/reset/cadence mutation no longer lives in `enemy.gd`, no external runtime calls Marine's old private phase helpers, and focused behavior-equivalence gates are green.
- Current measured state: The recovery implementation is applied to current main at `2c32f596e` using only the Marine extraction commit's scoped delta; stale donor packet drafts, summaries, and stale documentation/manifest snapshots were excluded. `MarineDash` and `MarineDashConfig` now own dash state/tuning; `enemy.gd` is 4,615 lines, 343 fewer than the 4,958-line baseline. All 26 default and 26 scene tuning values match the pre-extraction files. The Marine, spatial telemetry, and production ambush focused Godot gates pass. Required `run_validation.py --changed --json` fails one unrelated `grunt_falcon_reversal` actor assertion (`ordinary paired critical must remain 96x96`) and skips three higher-tier checks; the same assertion reproduces on the clean project-root main checkout. The workstream is blocked from normal landing until that baseline validation gate is repaired.
- Evidence: `custodian/game/actors/enemies/enemy.gd`; `custodian/game/actors/enemies/abilities/grunt_falcon_punch.gd`; `custodian/game/actors/enemies/abilities/README.md`; `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd`; `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd`; `custodian/tools/validation/enemy_hit_spatial_telemetry_smoke.gd`; `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`; current shared combat/engagement contracts; existing Falcon ability boundary as a structural reference only.
- Work surface: Primary owner is `custodian/game/actors/enemies/abilities/` plus a typed Marine Dash config under its existing config convention. Expected consumers are `enemy.gd`, `enemy_marine.tscn`, `sundered_keep_marine_ambush.gd`, focused Marine/spatial validation, validation-manifest ownership, and active ownership/current-state docs made false by the extraction.
- Change: Create one focused Marine Dash ability authority that owns Marine-specific phase, clocks, committed/captured target data, quick/charged selection, prediction/lock state, travel/contact bookkeeping, impact-lock/recovery/reset state, deterministic cadence, and read-only debug snapshot. Move Marine-specific tuning into a typed config/resource where practical. Keep `Enemy` as the host that supplies narrow shared services such as position/velocity movement application, relationship/target checks, hit application/context, engagement token access, presentation requests, camera/hitstop/observability hooks, and collision/world queries. Replace external private-helper calls with one explicit actor/ability request seam. Remove old duplicate Marine mutable state and phase methods after callers/tests migrate. Do not create a generic `EnemyAbilityBase` in this slice.
- Preserve: Exact current quick/charged tactical loop; launch-band semantics; prediction timing; one-hit behavior; wall/static collision behavior; attack IDs/spatial telemetry; dodge/block/parry outcomes; hitstop/camera feedback; reset behavior; Sundered Keep ambush intent; current Marine scene identity/tuning values; BSM strategic authority; deterministic fixed-step ownership.
- Non-goals: No Marine combat rebalance; no new art/audio; no Savage/Falcon rewrite; no generic ability hierarchy; no BSM redesign; no relationship/allegiance redesign; no broad `enemy.gd` cleanup outside code made dead by the extraction.
- Acceptance: Marine Dash state mutation is owned by the new ability/config and not duplicated in `enemy.gd`; old Marine phase/timer/target/reset fields and complete phase methods are removed from `enemy.gd`; external runtime no longer calls `_start_marine_dash_*` private helpers; current tactical quick/charged/prediction/reset behavior and current numeric tuning remain equivalent; attack/spatial telemetry still reports the same Marine attack lifecycle; direct validation inspects the typed ability/public diagnostic seam rather than reaching into actor-private phase state; validation-manifest ownership includes the extracted module so later edits select focused Marine checks; `enemy.gd` has net-negative Marine-specific state/logic.
- Validation: Focused first: existing `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd` and `custodian/tools/validation/enemy_hit_spatial_telemetry_smoke.gd`, updated to use the new seam. Run the Sundered Keep large-layout/ambush-relevant focused gate already registered by the live validation manifest if changed paths select it. Then run `python3 custodian/tools/validation/run_validation.py --changed --json` once at closeout. Moment Forge is optional only if the extraction changes presentation timing in a way structured tests cannot prove; ordinary behavior-equivalence extraction should not require full-frame capture.
- Task overrides: `none`
- Deferred: Savage pounce/chain extraction; ordinary melee controller; generic ability abstraction; broader non-player family convergence.

## Handoff

- Next action: Land the validated extraction, then let `review-enemy-marine-dash-ability-extraction-recovery-1` run as the fresh-context paired review.
- Best starting files: `enemy.gd`, `abilities/grunt_falcon_punch.gd`, Marine design doc, Marine smoke, spatial telemetry smoke, and Sundered Keep Marine ambush.
- Blockers or open questions: none. The `grunt_falcon_reversal` smoke now measures the published ordinary-critical frame texture directly; the changed-file closeout passes all 23 selected checks.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `removed`
- Evidence: `MarineDash` owns dash phases/clocks/charge/prediction/contact/cadence/reset and `MarineDashConfig` owns typed values. The original and Marine-scene values match across all 26 fields. Focused Marine, spatial telemetry, and production ambush checks pass; static search finds no old actor phase fields or external private phase-helper calls. The `grunt_falcon_reversal` smoke now reads the ordinary-critical animation's actual published first-frame texture and confirms 96×96. The packet pairing contract accepts intentionally blocked/manual paired reviews when their implementation packet is planning-gated, while ready/auto implementations still require ready/auto reviews. Changed-file closeout against `origin/main` passes all 23 selected checks with no failures or skips.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: Latest-main closeout exposed a stale packet-pairing validator rule and the known Falcon smoke assertion; resolving the main-sync merge also required preserving newer packet-index and architecture content.
- Root cause / contributing factors: Blocked/manual planning packets legitimately paired with blocked/manual reviews were rejected by the validator, and the Falcon smoke treated an absent `frame_size` dictionary entry as evidence about the actual animation texture size.
- Prevention / pipeline improvement: Pairing validation now permits blocked/manual review pairs only while their implementation is gated; asset-size checks inspect published frame textures rather than metadata the runtime profile does not promise.
- Tooling / docs drift discovered: The review-pairing contract did not represent planning-gated implementation/review pairs present on main; `grunt_falcon_reversal_smoke.gd` asserted a profile key that `_get_paired_execution_profile` never returns; `task_packet_index.py --write` still requires a Ready/Auto heading removed from the current README structure.
- Follow-up: `fixed-in-scope`
- What worked: Existing Marine behavior/parity evidence remained valid after sync; focused tests and the complete 23-check changed-file closeout now pass.

## Independent Review

- Status: `pending`
- Review workstream: `review-enemy-marine-dash-ability-extraction-recovery-1`
- Reviewed on main: `1ba0981e7859fa91ae86ea3bc638c0ce2474a1ad`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, workflow`
- Blocking defects: `0`
- Material evidence gaps: `1`
- Non-blocking issues: `1`
- Optional improvements: `0`
- Correction finding IDs: `R0-02` (external coverage repair pending)
- Next-slice finding IDs: `R0-01`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_ENEMY_MARINE_DASH_ABILITY_EXTRACTION_RECOVERY_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `review-enemy-marine-dash-ability-extraction-recovery-1` (resume after external coverage repair)
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
