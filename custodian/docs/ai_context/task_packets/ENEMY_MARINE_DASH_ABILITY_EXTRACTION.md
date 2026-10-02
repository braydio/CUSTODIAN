# ENEMY MARINE DASH ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-marine-dash-ability-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `02ca0025b8`
- Goal: Move Marine Dash from `enemy.gd` into one complete actor-local ability authority while preserving the current tactical-dash behavior, tuning, combat results, presentation requests, and Sundered Keep ambush integration.
- Completion boundary: This workstream owns only Marine Dash state/tuning extraction, the narrow `Enemy` service/delegation seam required by that extraction, direct Marine-dash callers, focused validation ownership, and consequence-driven docs. It is done when Marine Dash phase/timer/target/reset/cadence mutation no longer lives in `enemy.gd`, no external runtime calls Marine's old private phase helpers, and focused behavior-equivalence gates are green.
- Current measured state: Rechecked at claimed `main@735c8c6914`: the Marine state/logic and callers match the authored baseline. On `main@02ca0025b8`, `enemy.gd` is ~4,958 lines. Marine Dash tuning exports and its windup/travel/impact/recovery/reset state machine are still hosted there. `sundered_keep_marine_ambush.gd` directly calls `_start_marine_dash_windup`. Existing focused tests inspect private Marine fields/helpers. `GruntFalconPunch` is already a complete actor-local ability module and is the nearest proven extraction pattern; current docs explicitly say to compare Marine Dash before inventing any generic ability base.
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

- Next action: resume the published workstream after `agent-validation-baseline-repair` resolves baseline unit gates; rerun changed-file validation, then archive and finish. Implementation and focused Marine gates are complete.
- Best starting files: `enemy.gd`, `abilities/grunt_falcon_punch.gd`, Marine design doc, Marine smoke, spatial telemetry smoke, and Sundered Keep Marine ambush.
- Blockers or open questions: required changed-file sweep fails pre-existing `agent_workflow_contract` and `review_pairing_contract` unit gates; all 8 selected actor and 3 integration checks pass separately. The unrelated unregistered large-layout smoke also reproduces five metadata failures on baseline runtime and has its own draft follow-up.

## Landing Retry

Resumed and synchronized with `origin/main@e49c8452f`; merge `ff94ff32e` is
conflict-free and changes no Marine/Enemy/ambush runtime files. The two focused
blocker gates were rerun and still fail with the same baseline causes. Retain
blocked/manual status and the published checkpoint until baseline validation
repair permits a green closeout. The closing summary contains the retry receipt.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `removed`
- Evidence: MarineDash/config own the complete former actor authority; 26 defaults/26 scene values preserved; old actor mutable fields/helpers removed; all 11 selected runtime checks pass. Required changed-file closeout fails baseline agent_workflow_contract and review_pairing_contract, so lifecycle completion/landing is blocked. See ENEMY_MARINE_DASH_ABILITY_EXTRACTION_CLAUDE_SUMMARY.md and the agent-validation-baseline-repair draft.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: required closeout failed pre-existing workflow/queue gates and skipped runtime tiers; exploratory legacy layout smoke also failed baseline metadata checks; two new test parse errors were corrected.
- Root cause / contributing factors: expired temporary-routing assertions, validation-path guard versus project-relative/planned-new-test packet semantics, and historical layout preservation drift.
- Prevention / pipeline improvement: registered focused Marine/ambush ownership, proved layout failures on baseline, and authored bounded draft repair packets rather than changing unrelated runtime or weakening guards.
- Tooling / docs drift discovered: removed expiry workflow still required by smoke; eight unrelated ready-packet validation references rejected; 11 pre-existing context/index findings; graph stale/empty; unmanaged task index is documented deferred state.
- Follow-up: agent-validation-baseline-repair
- What worked: all 11 selected runtime gates and exact tuning comparison passed.
