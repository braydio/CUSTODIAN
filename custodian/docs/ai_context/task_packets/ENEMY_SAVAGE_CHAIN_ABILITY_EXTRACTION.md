# ENEMY SAVAGE CHAIN ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-savage-chain-ability-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-savage-pounce-ability-extraction, review-enemy-savage-pounce-ability-extraction`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-enemy-savage-chain-ability-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `state-machine/ownership extraction; independent review should verify two-hit/guard-pressure equivalence, pounce priority, and removal of parallel state`
- Reviewed main: `current-main-at-claim`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Move the Savage two-hit chain lifecycle out of `enemy.gd` into one actor-local `SavageChain` authority while preserving the current rushdown cadence, pounce-first priority, two-hit damage and guard-pressure semantics, and the generic ordinary-melee surface NPA-4 still needs to inspect.
- Completion boundary: This slice owns only Savage chain-specific state, chain-only tuning, chain execution, focused diagnostics/tests, and the narrow public host services required to resolve the existing contact contract. It does not extract ordinary Enemy melee cadence/damage/windup/contact tuning, does not modify Savage pounce behavior, and does not introduce a generic ability hierarchy.
- Current measured state: NPA-2 implementation is landed and its fresh paired review passed with 0 defects / 0 material gaps on review branch `eec8419f6`; review landing remains blocked only by the unrelated `living-world-abstract-activity-foundation` review-pairing defect. The reviewed pounce seam is stable: `SavagePounce` owns pounce phase/timer/cooldown/direction/start/hit-target state plus the 13-value typed config; `enemy.gd` keeps only the pounce feature/config binding, fixed-step priority and narrow host services. The two-hit chain remains entirely actor-owned in `enemy.gd`: six chain-only tuning exports (`gap=0.10`, `second_windup=0.16`, `second_damage=12`, `recovery=0.55`, guard pressure `10 -> 22`) plus three mutable runtime fields (phase, timer, committed direction), and methods `_start_savage_chain`, `_update_savage_chain`, `_resolve_savage_chain_hit`, `_finish_savage_chain`. The first hit still uses generic Savage `damage=10` and generic `attack_windup_duration=0.26`; the host's generic `damage_timer/damage_interval` still schedules when a chain may start. Current contact uses the standard radial-arc contract at 40 px plus generic grace/arc tuning. Pounce is attempted first in `_attack_target()`; only when pounce declines and no chain is active does generic cadence advance toward chain start.
- Evidence: Passed NPA-2 review summary `REVIEW_ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION_CLAUDE_SUMMARY.md` from review branch `eec8419f6`; archived NPA-2 implementation packet/summary; `custodian/game/actors/enemies/abilities/savage_pounce.gd`; `savage_pounce_config.gd`; `enemy.gd`; `enemy_savage.tscn`; `custodian/tools/validation/{enemy_savage_smoke,savage_runtime_smoke}.gd`; `custodian/game/actors/enemies/abilities/README.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; reviewed NPA-2 pounce seam; current Savage runtime scene/tuning; live shared hit/guard/contact and fixed-step contracts.
- Work surface: New focused `custodian/game/actors/enemies/abilities/savage_chain.gd`, `savage_chain_config.gd`, and `configs/savage_chain_default.tres` (exact private filenames may vary only to match established ability conventions); `enemy.gd` setup/delegation/public host-service seam; `enemy_savage.tscn`; `enemy_savage_smoke.gd`; `savage_runtime_smoke.gd`; validation-manifest ownership; consequence-driven architecture/context/abilities docs.
- Change:
  1. Keep `savage_chain_enabled` as the actor/archetype feature toggle.
  2. Move the six chain-only tuning values into typed `SavageChainConfig`: gap `0.10`, second windup `0.16`, second damage `12`, recovery `0.55`, first guard-stamina pressure `10`, second guard-stamina pressure `22`.
  3. Move the three chain runtime fields into `SavageChain`: phase, phase timer, and committed direction.
  4. Preserve generic Enemy cadence as host-owned for NPA-4: `damage_timer/damage_interval` still decides when to request a chain start; base first-hit damage still comes from current `damage`; first windup still comes from current `attack_windup_duration`.
  5. Preserve pounce-first ordering exactly: host attack selection calls `SavagePounce.try_start()` first; only if it declines may generic cadence request `SavageChain.start()`. Fixed-step update ticks pounce first and chain second.
  6. The chain owns windup_1 -> hit_1 -> gap -> windup_2 -> hit_2 -> recovery -> finish, committed direction, interruption/reset and read-only debug state. It must continue to evaluate the host's current target at hit time rather than inventing captured-target semantics.
  7. Do not copy generic 40 px/grace/arc contact tuning into the Savage config. Expose the narrowest public host contact geometry/query seam needed so `SavageChain` can use the current standard melee radial-arc contract without calling private actor methods. This seam is intentionally preserved for NPA-4 comparison.
  8. Extend the existing public ability-hit gateway only as narrowly as required to carry the current guard-stamina override; preserve all existing pounce/Marine/Falcon callers through defaults. Do not let `SavageChain` call `_apply_enemy_hit_to_target` directly.
  9. Preserve current chain attack-context behavior. The current chain supplies no dedicated ability attack ID; do not invent one in this extraction unless an existing failing test proves identity is required for correctness.
  10. Replace actor-private chain state reads in interruption, Dagger/Vigil commitment protection, custom presentation priority, Savage diagnostics and validation with `SavageChain.is_active()/get_debug_state()/cancel()` or equally narrow read-only APIs.
- Preserve: Savage scene HP/speed/base damage/profile; `damage=10` first hit; `attack_windup_duration=0.26` first windup; `damage_interval` scheduling; chain 0.10 gap, 0.16 second windup, 12 second damage, 0.55 recovery, guard pressure 10/22; current radial-arc contact geometry and target-at-hit-time behavior; pounce-before-chain ordering; pounce config/state/API; ordinary LIGHT damage commitment behavior; Vigil Fast-03 commitment protection; parry/stagger/critical interruption; BSM behavior/profile; deterministic fixed-step execution and current presentation fallback.
- Non-goals: No ordinary generic melee extraction; no generic cadence/config migration; no Savage rebalance; no new art/animation wiring; no generic ability base; no pounce changes; no reaction/posture/loot work; no new attack-ID semantics.
- Acceptance: (1) `enemy.gd` no longer contains the six chain-only tuning exports, three mutable chain fields, or complete start/update/resolve/finish chain phase machine; (2) one typed `SavageChain` + `SavageChainConfig` owns those facts; (3) `savage_chain_enabled` remains a host feature toggle; (4) generic `damage_timer/damage_interval`, base `damage=10`, first windup `0.26`, and generic melee contact geometry remain host/shared authority for NPA-4; (5) exact two-hit order/timing/damage/guard costs remain equivalent; (6) pounce still gets first refusal and NPA-2 files/behavior remain unchanged except compilation-safe shared-service defaults if unavoidable; (7) parry/stagger/critical cancellation and ordinary-LIGHT/Vigil commitment protection remain equivalent; (8) presentation priority queries the ability instead of actor-private fields; (9) focused tests consume the typed ability/debug seam, not `_savage_chain_phase` or private phase methods; (10) validation ownership includes the new module/config; (11) no generic ability superclass or duplicate contact tuning is created; (12) after this slice `enemy.gd` contains no Marine Dash, Savage pounce, or Savage chain phase machine.
- Validation: Update `enemy_savage_smoke.gd` as the primary chain-equivalence gate using the typed ability/public seam. Prove exact config values, first windup, first hit 10 + guard 10, gap, second windup, second hit 12 + guard 22, recovery, spatial miss, target-at-hit-time behavior, parry/stagger cancellation, ordinary-LIGHT non-cancellation, pounce-first priority and pounce negative-control equivalence. Update `savage_runtime_smoke.gd` so active-chain presentation priority is entered through the ability rather than writing `_savage_chain_phase`. Run directly selected combat/guard/spatial regressions and NPA-2 pounce smoke as a regression. Register manifest ownership for new ability/config. Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: NPA-4 ordinary standard-enemy melee cadence/execution/contact authority; NPA-5 reaction/posture/parry-critical; NPA-6 death/corpse/loot; later cross-family convergence.

## Handoff

- Next workstream: `review-enemy-savage-chain-ability-extraction`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none; NPA-3 has been remeasured against the passed NPA-2 review and current chain ownership`
- Next action: Once the NPA-2 review workstream actually lands/archives, let the dispatcher make NPA-3 eligible; after NPA-3 lands, launch its paired review through the fresh paired-review runner if that tooling has landed, otherwise use the existing fresh-context review method.
- Blockers or open questions: `mechanical dependency only: review-enemy-savage-pounce-ability-extraction must land/complete; no remaining NPA-3 planning question`
