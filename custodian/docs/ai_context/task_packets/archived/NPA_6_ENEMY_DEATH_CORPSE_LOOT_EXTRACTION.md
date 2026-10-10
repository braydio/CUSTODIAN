# NPA-6: ENEMY HEALTH, DEATH, CORPSE AND LOOT LIFECYCLE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-6-enemy-death-corpse-loot-extraction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-5-enemy-reaction-posture-extraction`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-6-enemy-death-corpse-loot-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Enemy health/death and corpse/loot lifecycle ownership is a high-risk runtime authority migration with broad compatibility and reification consumers.`
- Reviewed main: `dd17a65e7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Move standard Enemy health and death/corpse lifecycle state out of `enemy.gd` into one focused lifecycle authority while preserving the existing Enemy-facing combat, loot, simulation and presentation contracts.
- Completion boundary: One landed `EnemyLifecycle` authority plus typed configuration owns health mutation, ALIVE→DYING→LOOTABLE_CORPSE/EMPTY_CORPSE transitions, one-time loot payload construction, and corpse cleanup timing. Enemy remains the standard combat-agent coordinator and supplies narrow host services for reactions, abilities, BSM, observability, animation, UI, world history, and host-node changes. Existing `EnemyCorpseLoot` remains the one-time pickup/award boundary; `EnemyLootCarrier` remains the stolen-resource carrier.
- Current measured state: On `dd17a65e7`, `enemy.gd` exports `health`, `max_health`, legacy and table loot settings, and corpse timing/marker tuning; it stores `dead`, `life_state`, pending payload, corpse-loot reference, and empty-corpse timers. `take_damage`, `_damage_result`, `die`, loot rolling/payload construction, corpse finalization, and cleanup remain in the coordinator. `EnemyCorpseLoot` already owns validated one-time collection, reward application, pickup feedback and visual hue restoration. `EnemyLootCarrier` owns captured vault-resource payloads. World-simulation reification and validation code use the Enemy life-state façade.
- Evidence: `custodian/game/actors/enemies/enemy.gd`; `custodian/game/actors/enemies/components/enemy_corpse_loot.gd`; `custodian/game/actors/enemies/components/enemy_loot_carrier.gd`; `custodian/tools/validation/lootable_corpse_beacon_smoke.gd`; `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd`; `custodian/tools/validation/world_simulation_actor_reification_handoff_smoke.gd`; reviewed NPA-5 implementation/review summaries and archived packets.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md` owns composition and anti-godfile boundaries; `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` owns current subsystem ownership; archived NPA-5 packet and review receipt own the newly reviewed reaction/parry-critical seams; `EnemyCorpseLoot` owns actual one-time pickup and award behavior.
- Work surface: `custodian/game/actors/enemies/enemy.gd`; new `EnemyLifecycle` script/config under `custodian/game/actors/enemies/components/`; Enemy scene/config bindings; `EnemyCorpseLoot` and `EnemyLootCarrier` only where the new host seam requires it; world-simulation/reification callers; focused validation and `custodian/tools/validation/validation_manifest.json`; current-state and ownership documentation.
- Change:
  1. Add a focused `EnemyLifecycle` authority with typed `EnemyLifecycleConfig`. It is the sole mutable owner of current/max health, dead/life state, pending corpse payload, corpse-loot lifecycle reference, and empty-corpse cleanup clocks. Configuration owns the actor-authored health, drop, pickup and corpse-expiry tuning currently serialized on Enemy scenes.
  2. Move damage acceptance/health arithmetic and the structured damage-result contract behind this owner. Preserve the public `Enemy.take_damage(...)` and `Enemy._damage_result(...)` compatibility surfaces as narrow delegates where callers require them.
  3. Move one-time loot selection/payload assembly from legacy drops, typed loot-table entries, and `EnemyLootCarrier.take_payload()` behind the lifecycle owner. Preserve the rule that any non-empty configured loot table suppresses fallback PARTS even when a particular roll is empty.
  4. Move the ALIVE→DYING transition, pending payload ownership, lootable/empty corpse transition, and offscreen/hard-lifetime cleanup behind the lifecycle owner. Preserve `Enemy.die()`, `dead`, `life_state`, the `LifeState` values, and `enemy_died` as stable Enemy-facing façade contracts used by runtime/reification consumers.
  5. Keep effectful host integrations on Enemy behind narrow lifecycle callbacks: reaction and attack cancellation, BSM notification, group/collider/runtime shutdown, health UI and damage popup, death animation/SFX, game/observability/world-history/material reporting, camera notification, and the existing signal. The lifecycle authority must not take over movement, animation playback, HUD rendering, global service policy, or archetype behavior.
  6. Keep `EnemyCorpseLoot` responsible for collection validation, same-frame once-only reward delivery, resource/vault/material awards, toasts, marker, sound, and visual restoration. Keep `EnemyLootCarrier` responsible for capturing stolen resources; lifecycle owns only the single transfer into a death payload.
  7. Migrate all active Enemy scene tuning to the typed lifecycle config without changing authored health, loot/drop probabilities/amounts, pickup radius/offset, empty-corpse minimum/offscreen/hard lifetimes, or default values. Remove duplicate authoritative lifecycle fields/logic from `enemy.gd`.
  8. Replace direct private lifecycle mutation in tests/callers with supported facade or semantic lifecycle APIs. Preserve world-simulation reification's ability to restore life-state through an explicit typed boundary.
  9. Update validation ownership and architecture/current-state/ownership documentation to name the new owner and surviving host boundary.
- Preserve: Damage clamping and exact result keys/semantics; ignored damage to dead or zero-health actors; `on_damaged`/assault/reaction/UI ordering; difficulty scaling behavior; all lethal paths including paired execution; once-only `die()` and payload transfer; Grunt/Marine/Savage/other authored loot values and RNG probabilities; legacy fallback suppression rules; vault loot recovery; collector validation and no double award; life-state names/transitions; enemy death signal/event/stat ordering; animation/SFX timing; observatory living/corpse gauge balance including exit cleanup; target/group/collision shutdown; minimum/offscreen/hard corpse expiry; active-camera bounds behavior; NPA-5's once-only paired-execution damage service and recovery behavior; deterministic world reification contracts.
- Non-goals: No new loot economy or reward types; no loot balance or tuning changes; no corpse art/marker/audio redesign; no general actor health superclass; no relationship, persistence schema, spawn, wave, Operator death, or campaign changes; no Enemy behavior/ability/reaction extraction beyond calls needed to preserve lifecycle ordering; no NPC-family convergence.
- Acceptance: (1) `EnemyLifecycle` + config are the only mutable runtime owner for health/dead/life-state/payload/corpse-timer data; (2) Enemy retains compatible public damage/death/life-state/signal surfaces without shadow state; (3) health arithmetic and structured result values remain behaviorally equivalent for alive, zero-damage, dead, nonlethal, and lethal cases; (4) lethal damage, direct death, paired-execution lethality, and repeated death all transition exactly once; (5) payload is built and carrier contents consumed once; configured typed-table fallback suppression and legacy drop behavior remain exact; (6) loot collection still awards each ledger/vault/material payload at most once and only to valid collectors; (7) all active authored scene values match pre-migration effective values; (8) corpse cleanup waits for both the minimum age and offscreen check, retains the hard lifetime, and preserves camera-margin geometry; (9) NPA-5 host callbacks, token validation and damage-consumption boundary remain intact; (10) reification callers use a supported typed seam and no tests or production callers mutate lifecycle-private fields; (11) `enemy.gd` is net-negative for lifecycle state/logic and no universal health/lifecycle superclass is added; (12) validation ownership covers new modules/configs and affected callers; (13) focused regressions and changed-file validation pass; (14) current-state/ownership/design roadmap accurately record NPA-6 complete.
- Validation: Add a focused lifecycle smoke for damage result parity, exactly-once lethal/death/payload transitions, all loot payload classes and fallback suppression, valid/invalid/repeated corpse collection, reification life-state restoration, and minimum/offscreen/hard cleanup boundaries. Run `lootable_corpse_beacon`, `authored_vault_grunt_loot_marine`, world-simulation actor reification handoff, `enemy_reaction_posture`, paired-execution/lethal controls, and affected Enemy combat regressions independently. Then run `python3 custodian/tools/validation/run_validation.py --changed --json`, `git diff --check`, `python3 custodian/tools/agent/check_ai_context.py --json`, and the targeted/repo pairing checks required by workstream closeout. Avoid broad actor-tier sweeps unless a focused gap requires them; respect the validation resource budget.
- Task overrides: `none`
- Deferred: Cross-family shared health contracts; persistent enemy identity/reification architecture; loot economy changes; corpse presentation iteration.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `EnemyLifecycle` + `EnemyLifecycleConfig` now own health/death, damage results, payload construction, corpse state and cleanup clocks; Enemy scene tuning moved to typed configs with unchanged values. Focused lifecycle/combat checks passed 10/10; changed-file validation passed 40/40 with complete coverage; `git diff --check` passed; AI-context validation found zero findings. See `NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION_CLAUDE_SUMMARY.md`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first parser pass found that GDScript cannot cast with the nested `LifeState` enum name; the expanded corpse smoke also exposed a brittle assertion that expected exactly two toasts despite random typed drops. The first changed sweep passed all selected tests but exposed missing validation ownership for the newly migrated scene configs.
- Root cause / contributing factors: The enum is an integer-backed namespace rather than a callable constructor; the old toast assertion counted a random number of successful table rolls; new config resources and scenes needed an explicit owning test.
- Prevention / pipeline improvement: Keep enum-backed public state as integer values at the façade; assert reward categories rather than random toast counts; add config parity owners whenever scene-authoring values move into typed resources.
- Tooling / docs drift discovered: None.
- Follow-up: fixed-in-scope
- What worked: Focused corpse, loot, reification and combat tests gave direct evidence for preserved behavior; the config smoke closed coverage gaps without instantiating unrelated presentation behavior.

## Handoff

- Next workstream: `review-npa-6-enemy-death-corpse-loot-extraction`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: Run the paired review through `paired_review_runner.py` in its fresh reviewer context after this implementation lands.
- Blockers or open questions: `none`
