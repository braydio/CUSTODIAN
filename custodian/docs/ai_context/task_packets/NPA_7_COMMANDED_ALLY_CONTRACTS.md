# NPA-7: COMMANDED ALLY RELATIONSHIP, TARGETING AND IDENTITY CONTRACTS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-7-commanded-ally-contracts`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-6-enemy-death-corpse-loot-extraction`
- Locks: `ally-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-7-commanded-ally-contracts`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Relationship qualification can cause friendly fire and break explicit neutral commands; independent post-land verification required.`
- Reviewed main: `55905da45588857f4c6847aaba5b506d090a4a3a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Integrate commanded drones/droids with already-live shared relationship/targetability contracts while preserving squad command behavior, explicit-target exceptions and manager-scoped identity. No universal NPC command brain or Enemy inheritance.
- Completion boundary: Live `CombatDrone` and its `AlliedInfantryDroid` subclass expose one compositional ally relationship and use the same mode-aware qualification from command issue through projectile commit. `DroneManager` continues to own input/orders, `DroneSquadState` squad mode/roster, and CombatDrone physical movement/weapon execution.
- Current measured state: CombatDrone independently subclasses `CharacterBody2D`, adds `ally`, `allied_drone`, `defense`, `turret` groups and owns movement, weapon bursts, HP and destroyed state. `AlliedInfantryDroid` inherits it for presentation. Manager authorizes squad commands and `DRONE_01`-style slot labels; `DroneTargeting` delegates autonomous scan to `ActorRelationshipResolver`, while explicit `drone_command_target` group selection intentionally permits passive Shrumbs. Target setter and final `_fire_once` path do not yet share one final targetability guard. Existing `ActorAllegianceComponent` and `ActorRelationshipResolver` already own relationship truth. NPA-6 was implemented/reviewed (zero findings; post-sync 42/42 green). No executable NPA-7 packet existed on reviewed baseline.
- Evidence: `custodian/game/actors/allies/{combat_drone,allied_infantry_droid}.gd`; `custodian/game/systems/drone/{drone_manager,drone_targeting,drone_squad_state,drone_command_profile}.gd`; `custodian/game/actors/core/actor_allegiance_component.gd`; `custodian/game/systems/combat/actor_relationship_resolver.gd`; existing relationship/drone smokes; `REVIEW_NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION_CLAUDE_SUMMARY.md`.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `design/04_architecture/ACTOR_RELATIONSHIP_AND_TARGETABILITY.md`; `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md`; `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md`; reviewed NPA-6 archive/receipt.
- Work surface: `custodian/game/actors/allies/{combat_drone,allied_infantry_droid}.gd`; `custodian/game/systems/drone/{drone_manager,drone_targeting,drone_squad_state}.gd`; narrowly justified shared relationship integration files only if required; focused validation scripts/manifest and scoped architecture/current-state docs.
- Change:
  1. Use existing `ActorAllegianceComponent` or a comparably narrow existing adapter to expose semantic `operator_allied` from CombatDrone. AlliedInfantryDroid inherits it. Preserve `ally`/`defense`/`turret` discovery groups and projectile-team compatibility; don't add unsupported dynamic defection.
  2. Unify drone-specific target eligibility in `DroneTargeting`, distinguishing autonomous (alive, non-passive, semantic hostile, targetable) from Operator-explicit command (a valid `drone_command_target` may be passive/neutral, or an eligible hostile). The explicit exception must reject dead/freed/newly allied/deliberately untargetable targets but must not rewrite global resolver hostility rules.
  3. Apply matching source-aware validation when the manager issues/retains an order, the actor receives/retains it, targeting refreshes, `_update_weapon` runs, and `_fire_once` commits every projectile/burst round. If allegiance, targetability, death, instance validity, or order changes mid-burst, cancel subsequent shots. No single-frame friendly fire. A direct `set_command_target()` call cannot bypass the policy.
  4. Keep DroneManager the sole player-input/squad authorization owner and DroneSquadState the only authoritative squad mode/fire/follow/anchor/roster owner. CombatDrone executes local movement/weapon state; do not add a shadow squad mode/command machine. Preserve FOLLOW/HOLD/INTERCEPT/RECALL, CLOSE/FAR/FREE_ROAM, projected guard anchors, leash and no-path stops, immediate hold-fire cancellation, input chord and hover/reticle behavior.
  5. Preserve `drone_id` as manager-scoped member/slot identity; ensure destroyed/pruned/replacement registrations and current squad summary remain stable. Document that recycled squad slots are not save-stable unique creature IDs. Do not add cross-family identity or persistence.
  6. Add a deterministic focused test for auto-vs-explicit policy, opted-in passive Shrumb, disallowed targets, live allegiance/targetability flip between acquisition and a queued burst round, and manager→drone→weapon integration. Test true projectile emission/non-emission, not merely helper return values. Include destroyed/replaced squad-member behavior and droid inheritance.
  7. Register changed source ownership and new/supplementary smoke in `custodian/tools/validation/validation_manifest.json`. Existing scripts `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and `debug_collector_combat_drone_smoke.gd` were **not registered IDs** on planning main: run directly or deliberately add canonical manifest entries rather than invoking them as imaginary IDs. Reconcile NPA-6 review completion, current NPA-7 scope and NPA-8 planning gate in scoped docs/ownership map.
- Preserve: All existing input modes, squad/formation/guard/recall/navigation/leashes, target hover/reticle, explicit passive Shrumb commands, autonomous enemy-only scan, 0.18s scan cadence, burst timing and damage, health/destroyed rules, droid sprites/status, slot and member replacement, projectile team and compatibility groups; shared resolver behavior for unrelated actors.
- Non-goals: No Enemy inheritance, generic NPC base/command framework, global hostility rewrite, drone faction flips, durable cross-family IDs, save schema, bonded Vaultwing commands/perception (NPA-8), turret/social/boss convergence, drone fabrication/repair, combat balance, HUD or asset/art/VFX/audio changes.
- Acceptance: (1) compositionally expressed ally relationship and existing inheritance retained; (2) autonomous targets always require resolver-qualified hostility/non-passive targetability; (3) Operator-explicit opted-in passive Shrumb works, never autonomously acquired; (4) live valid hostile remains attackable; (5) newly allied/dead/freed/untargetable loses eligibility before further shots, including burst; (6) direct drone setter, manager and final weapon gate agree; (7) no duplicated squad command/identity authority; (8) existing controls, formation, navigation, leash, fire discipline, droid presentation, projectile team and status are unchanged; (9) slot replacement/destroyed identities are safe and clearly squad-local; (10) deterministic real actor-to-projectile regression; (11) manifest/changed-file coverage is complete; (12) architecture and current-state docs match landed runtime.
- Validation: On planning baseline, manifest registered `actor_relationship_contract` and `allied_drone_navigation_walkability`. Run those with the live `run_validation.py` targeted-test syntax after checking `--help`. Existing `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and `debug_collector_combat_drone_smoke.gd` exist but were not registered IDs: execute directly through `godot --headless --path custodian --script res://tools/validation/<name>.gd` as appropriate or add canonical manifest entries. Add one focused transition-and-shot test and prove it is selected for modified drone sources. Then run `python3 custodian/tools/validation/run_validation.py --changed --json`, `python3 custodian/tools/agent/check_ai_context.py --json`, applicable pairing/authoring checks and LFS-filter-safe `git diff --check`. Check current manifest and resource budget before broad sweeps.
- Task overrides: `none`
- Deferred: Bonded Vaultwing commands and identity (NPA-8); any real cross-family command model only after second independent family; turret/social convergence (NPA-9/10); optional unused compatibility removal (NPA-11).

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `no`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Implementation changes are present in the claimed worktree. The focused `commanded_ally_targeting_contract` smoke passes with real projectile emission/damage and no-fire transitions; `allied_drone_navigation_walkability` passes. The changed-file sweep has complete coverage but is blocked by pre-existing `actor_relationship_contract` and unrelated `world_transition_handoff` failures; the actor relationship failure was also reproduced on clean `origin/main@1da9c970`.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: The required changed-file sweep is not green because the existing actor relationship contract fails on clean main and the unrelated world transition handoff smoke fails in this worktree.
- Root cause / contributing factors: Existing actor relationship fixtures include legacy Enemy allegiance assertions and Vaultwing animation resources whose imports are unavailable in the main checkout; the unrelated route handoff scenario also fails in the changed sweep. These failures are outside NPA-7's implementation surface.
- Prevention / pipeline improvement: Keep baseline reproductions for shared validation failures and resolve them in their owning workstreams before treating downstream changed sweeps as green.
- Tooling / docs drift discovered: The changed-file sweep selects shared relationship and route tests because `DroneManager` and the validation manifest are registered owners; report their failures separately from NPA-7's focused runtime evidence.
- Follow-up: `npa-7-commanded-ally-contracts`
- What worked: A deterministic actor-to-projectile smoke proved the explicit passive-Shrumb exception, neutral explicit targeting, target flips before first fire and mid-burst, direct-setter rejection, real damage, and squad-slot replacement.

## Refresh Planning Authority

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: `NPA-7 planning completed in this packet; remeasure against current main at publication, without requiring a fresh human planning cycle unless an actual contract conflict emerges.`

## Handoff

- Next workstream: `npa-7-commanded-ally-contracts`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: `Resume this claimed implementation workstream after the repository's baseline actor_relationship_contract and world_transition_handoff validation failures are corrected; rerun required validation, then land and launch review-npa-7-commanded-ally-contracts in a fresh context.`
- Blockers or open questions: `Changed-file validation is red on existing non-NPA-7 contracts; do not land until the required sweep is green.`
