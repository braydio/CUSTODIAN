# NPA-4 STANDARD ENEMY MELEE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-4-standard-enemy-melee-extraction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-enemy-savage-chain-ability-extraction`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-4-standard-enemy-melee-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `ordinary melee is still a dense mutable authority inside enemy.gd and is consumed by reaction/presentation/telemetry callers; fresh review must prove one-owner extraction without stealing reaction or special-ability authority`
- Reviewed main: `dd61bca01cf7572136aac397993cdc053e83bd3c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Extract ordinary standard-combat-agent melee execution from `enemy.gd` into one focused authority so baseline melee owns its own commitment, windup, contact snapshot, hit/whiff resolution, recovery/redecision and cancellation state without becoming a universal NPC combat base or absorbing special abilities/reactions.
- Completion boundary: Move the ordinary melee transaction and its melee-only mutable state behind one `StandardEnemyMelee` authority plus typed `StandardEnemyMeleeConfig`. Keep actor-level damage, target, locomotion, shared hit resolution, engagement coordinator, semantic presentation, strategic behavior, reactions, special abilities and persistence in their existing owners. Remove direct external reads/writes of ordinary-melee private fields and replace them with semantic module APIs.
- Current measured state: NPA-3 implementation and independent fresh-context review are complete; review reports 0 defects, 0 material gaps and 0 other findings. `enemy.gd` is ~4,468 lines. Ordinary baseline melee still owns `used_strong_attack`, `_attack_windup_timer`, `_pending_attack_damage`, `_windup_attack_is_strong`, committed forward/range/range-source/arc, `_pending_attack_id`, `_attack_recovery_timer`, and `_attack_redecision_timer`, plus start/update/execute/cancel/context/spatial/recovery methods. Current authored melee policy is: base actor damage supplied by host; first ordinary attack uses `strong_attack_multiplier=3.0`; player contact range 40px unless a variant profile supplies attack range; structure contact uses `structure_attack_range`; windup default 0.10s, recovery 0.40s, redecision 0.28s, tracking lock 0.12s, grace 1.15 + 10px, arc 95°. Scene overrides: Grunt windup 0.42/recovery 0.40/tracking 0.12; Marine windup 0.45; Savage windup 0.26/arc 115; Pursuit Frame windup 0.46/recovery 0.48. NPA-3 deliberately left Savage first-hit damage/windup/contact on this ordinary-melee surface, so SavageChain must continue to obtain the exact same host-facing values after extraction.
- Evidence: `REVIEW_ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION_CLAUDE_SUMMARY.md`; archived NPA-3 packet; current `enemy.gd`; `enemy_behavior_state_machine.gd`; Grunt/Marine/Savage/Pursuit scenes; `EnemyHitSpatialContract`; `enemy_grunt_notice_and_attack_cadence_smoke.gd`; `enemy_hit_spatial_telemetry_smoke.gd`; `combat_exchange_commitment_smoke.gd`; `operator_guard_flow_smoke.gd`; `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Task-specific authority: `NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md` owns NPA decomposition; `COMBAT_FEEL_SYSTEM.md` owns authored baseline cadence/readability; reviewed NPA-3 owns Savage special semantics; current shared hit/engagement/presentation/reaction authorities remain upstream/downstream contracts.
- Work surface: New focused `custodian/game/actors/enemies/combat/standard_enemy_melee.gd` and typed config/resource surface (exact private filename may vary to match conventions); `enemy.gd` setup/delegation/public host APIs; Grunt/Marine/Savage/Pursuit scene config bindings as needed; SavageChain getter adaptation only where required for preserved first-hit/windup/contact values; focused validation and validation-manifest ownership; consequence-driven architecture/current-state docs.
- Change:
  1. Introduce `StandardEnemyMelee` with explicit setup against one Enemy host and typed `StandardEnemyMeleeConfig`.
  2. Move ordinary-melee mutable state into it: opening-strong-consumed flag; windup timer; queued damage/strong flag; committed forward/range/range-source/arc; pending attack ID; recovery timer; redecision timer.
  3. Move the complete baseline transaction: eligibility, start, tracking until lock, engagement-token claim, hit/whiff/no-target resolution, recovery/redecision, cancellation, debug snapshot and ordinary-melee observability.
  4. Config owns ordinary-melee-specific policy/tuning only: strong-opening multiplier, player contact range, windup, recovery, redecision delay, tracking lock, grace multiplier, grace pixels and contact arc. Preserve exact defaults/scene overrides.
  5. Keep actor `damage`, `structure_attack_range`, current target, variant profile data and shared attack-sequence counter outside the module. The module snapshots/queries them through narrow host APIs.
  6. Preserve current attack-ID format for ordinary melee. If the shared sequence remains host-owned, expose a narrow host allocator that returns the legacy `<instance>:<sequence>` form instead of changing telemetry identity.
  7. Preserve variant contact range semantics. A live `_variant_profile.attack_range` continues to override ordinary contact range. Do **not** make variant `attack_cooldown` suddenly control baseline cadence in this packet; current code maps it to `damage_interval`, while baseline melee uses recovery + redecision. Record that as separate design/debt evidence rather than silently changing procgen variant balance.
  8. Do not move `damage_timer/damage_interval` into StandardEnemyMelee. Live callsites show they remain host/special compatibility state, including Savage-chain cadence and MarineDash setup.
  9. Preserve special selection order. Savage pounce/chain, Falcon Punch and Marine Dash remain checked before ordinary-melee start. StandardEnemyMelee only runs when those paths decline/are not applicable.
  10. Preserve fixed-step ordering: recovery/redecision advances at the same current point; active ordinary windup/resolve remains after special-ability ticks and reaction interruption checks.
  11. Reaction code keeps authority over deciding when stagger/parry/critical interrupts happen, but it must call `standard_melee.cancel(...)` rather than zeroing melee fields. NPA-5 therefore still owns reaction/posture policy.
  12. Replace direct commitment checks in grunt flavor/presentation, light-flinch suppression, Dagger finisher facing preservation, debug snapshots and tests with semantic `is_committed()/is_active()/get_debug_state()` queries.
  13. Presentation stays semantic/presentation-owned. StandardEnemyMelee may request “ordinary melee started/finished/cancelled” through narrow host presentation hooks, but must not own SpriteFrames/animation backend state.
  14. Shared `_apply_enemy_hit_to_target` / `resolve_ability_hit` remains host-level because special abilities consume it too; the melee module calls the public host hit seam with its own attack ID + spatial contract.
- Preserve: Exact Grunt/Marine/Savage/Pursuit windup/recovery/contact values; first ordinary strong attack behavior including strong whiff counting as consumed; 40px normal-player contact contract; variant-range and structure-range sources; tracking-lock semantics; target-at-resolution behavior; radial-arc/grace math; engagement token timing; hit/whiff telemetry fields and ordinary attack-ID shape; block/parry/dodge/damage outcomes; BSM and legacy fallback callers; Savage pounce/chain priority and first-hit values; Falcon normal-attack notification; ordinary LIGHT commitment survival; Dagger finisher facing behavior.
- Non-goals: No reaction/posture/parry-critical extraction; no death/corpse/loot work; no special-ability rewrite; no generic NPC/ability/combat base; no variant balance/cooldown repair; no Operator melee changes; no art/audio retune; no behavior-state-machine redesign.
- Acceptance: (1) ordinary melee mutable state listed above no longer lives in `enemy.gd`; (2) one StandardEnemyMelee authority owns lifecycle/context/recovery state; (3) typed config preserves exact defaults and scene overrides; (4) host damage/target/shared hit/engagement/presentation/reaction/special authorities remain external; (5) special-attack-first ordering remains identical; (6) fixed-step timing/order remains equivalent; (7) first strong ordinary swing and strong-whiff consumption remain equivalent; (8) player/variant/structure contact range source and radial-arc telemetry remain equivalent; (9) parry/stagger/critical cancellation works only through semantic module cancellation; (10) light-flinch/Dagger/presentation/debug callers no longer inspect private melee fields; (11) SavageChain still receives identical first-hit damage/windup/contact semantics; (12) variant `attack_cooldown` behavior is preserved, not silently activated; (13) `damage_timer/damage_interval` remain outside ordinary melee unless live implementation evidence proves a different current consumer contract and the packet is stopped for refresh; (14) focused validation owns the new files and tests consume public/typed seams; (15) `enemy.gd` loses the complete ordinary-melee phase/transaction machine.
- Validation: Add/refresh a focused standard-enemy-melee smoke that exercises start -> tracking -> lock -> hit, whiff out-of-range/out-of-arc, no-target cancellation, block/parry/dodge/damage results, first-strong hit + strong-whiff consumption, recovery/redecision timing, variant/player/structure contact sources, semantic commitment queries, stagger/critical cancellation and special-priority negative controls. Re-run `enemy_grunt_notice_and_attack_cadence_smoke.gd`, `enemy_hit_spatial_telemetry_smoke.gd`, `combat_exchange_commitment_smoke.gd`, `operator_guard_flow_smoke.gd`, Grunt Falcon, Marine Dash, Savage/NPA-3 regressions, and affected BSM/legacy-fallback checks. Add a variant negative control proving this extraction does not silently change current `attack_cooldown` behavior. Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: NPA-5 reaction/posture/parry-critical authority; NPA-6 death/corpse/loot; explicit procgen variant attack-cooldown design/correction; later shared-family convergence.


## Completion Truth

- Ordinary melee lifecycle state and transaction logic now live in `StandardEnemyMelee`; `enemy.gd` is the shared host and is 4,201 lines (266 fewer than the 4,467-line main baseline at claim).
- Typed `StandardEnemyMeleeConfig` and base/Grunt/Marine/Savage/Pursuit resources preserve the reviewed defaults and authored scene values. `SavageChain` reads its first-hit windup through the public melee seam.
- Shared damage, current target, hit resolver, engagement coordinator, reaction authority, presentation, special selection, and `damage_timer`/`damage_interval` remain host or existing ability concerns. No ordinary-melee private fields or transaction helpers remain in active callers; the historical drone archive remains unchanged.
- Focused standard melee coverage passes for opening strong hit/whiff consumption, target-at-resolution, tracking lock, hit/blocked/parried/dodged outcomes, no-target resolution, contact sources and grace/arc, recovery/redecision, semantic commitment, and the variant cooldown negative control. The ambient Shrumb inherited scene also loads with its base melee config.
- The required changed-file sweep passed 31/31 selected checks with complete ownership coverage. `git diff --check` passed.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: Initial focused validation caught a missing host release method, a malformed conditional, and an attempted call to a nonexistent facing API; these were corrected. The commitment regression fixture initially used a plain Node2D without a physics RID; it now uses CharacterBody2D. The first changed sweep exposed two changed callers without manifest ownership, which were registered. A procgen spawn integration check timed out at its 180-second cap when assigned the ambient scene; that scene is now loaded directly by the focused smoke, and the final changed sweep passes.
- Root cause / contributing factors: Extraction removed a shared token helper together with the ordinary transaction; the new fixture did not initially satisfy the perception component's physics-query contract; ownership metadata for newly changed caller paths was incomplete.
- Prevention / pipeline improvement: Keep shared engagement token release at the Enemy host boundary, use physics-body fixtures wherever perception queries can run, and register each changed scene/source against the narrowest relevant validation owner before the changed-file sweep. Fixed in scope.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Public semantic APIs kept reaction/commitment regressions independent of private transaction fields.

## Next Handoff
- Next workstream: `review-npa-4-standard-enemy-melee-extraction`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Start the paired post-land review in a fresh reviewer context after this implementation lands; do not continue this implementation context as reviewer.
- Blockers or open questions: none


- Next workstream: `review-npa-4-standard-enemy-melee-extraction`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: After NPA-4 lands, launch its paired review in a fresh Codex context through the autonomous paired-review runner if that tooling is landed and reviewed; otherwise use the existing fresh-context review path.
- Blockers or open questions: `none`
