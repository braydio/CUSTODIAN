# ENEMY MARINE DASH ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-marine-dash-ability-extraction-recovery-1`
- Status: `ready`
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
- Current measured state: A stranded implementation checkpoint exists at `origin/agent/enemy-marine-dash-ability-extraction`: it is 3 unique commits ahead and hundreds of commits behind current main. Its durable summary reports the complete MarineDash/MarineDashConfig extraction, `enemy.gd` reduced by 343 lines, exact 26-value tuning parity, 11 selected runtime gates green, and no task-owned runtime failures; landing stopped only on the repository-wide workflow/review-pairing gate defects that have since been repaired. Current `main` still exposes this packet as `ready` under the old branch identity, so dispatch treats it as permanently claimed. This recovery packet starts from fresh main and selectively reconciles the validated checkpoint rather than resuming/merging the stale branch wholesale.
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

- Next action: Claim this refreshed recovery workstream. Diff the stranded `origin/agent/enemy-marine-dash-ability-extraction` checkpoint against current main, reuse only still-valid extraction/config/test/docs changes, re-run the focused Marine + ambush + spatial gates and repaired closeout, then land normally. If fresh main already implements any checkpoint delta, drop that donor change rather than duplicating it.
- Best starting files: `enemy.gd`, `abilities/grunt_falcon_punch.gd`, Marine design doc, Marine smoke, spatial telemetry smoke, and Sundered Keep Marine ambush.
- Blockers or open questions: none. The old branch is donor evidence only and no longer owns the queue lock after this re-key. If fresh main materially changed Marine ownership, reconcile to current authority rather than preserving stale branch structure.
