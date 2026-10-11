# Existing Commanded Droid Hardening

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-existing-drone-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-7-commanded-ally-contracts, review-npa-showcase-existing-enemy-hardening`
- Locks: `drone-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-existing-drone-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `44d49b7dd91fc8dc603be1b2a63be91a3246b028`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Prove and harden the real existing CombatDrone/AlliedInfantryDroid production-scene command behavior as the tested donor for future M-7; register meaningful integration/observability coverage without reimplementing the reviewed NPA-7 projectile/relationship policy.
- Completion boundary: Land one genuinely new or strengthened manifest-owned real-scene DroneManager→AlliedInfantryDroid command integration smoke, covering command state, navigation/guard/recall, replacement, status and source ownership, with only red-before-green runtime fixes when a live defect is reproduced. Archive a validated implementation and obtain a fresh paired review; no diagram-only/proxy closure.
- Current measured state: NPA-7 implementation/review are archived complete (implementation 64306601e824012017d8f6a653438951e53a8975; independent review pass, review landing f7c1ea6b3b18ecce2754ef2cb9fa17985708dd7c). Existing-enemy hardening review is archived passed. DroneManager owns command input and member registration; DroneSquadState owns mode/fire/follow/anchor; DroneTargeting uses ActorRelationshipResolver for auto hostility versus explicit drone_command_target passive Shrumb; CombatDrone composes ActorAllegianceComponent and rechecks eligibility at each projectile. AlliedInfantryDroid inherits CombatDrone. Registered commanded_ally_targeting_contract, actor_relationship_contract and allied_drone_navigation_walkability already prove NPA-7. Direct drone_follower_commands_smoke.gd, main_scene_allied_droid_smoke.gd, debug_collector_combat_drone_smoke.gd exist but are not registered manifest IDs as of reviewed main.
- Evidence: Archived NPA_7_COMMANDED_ALLY_CONTRACTS.md and REVIEW_NPA_7_COMMANDED_ALLY_CONTRACTS.md; REVIEW_NPA_7_COMMANDED_ALLY_CONTRACTS_CLAUDE_SUMMARY.md; REVIEW_NPA_SHOWCASE_EXISTING_ENEMY_HARDENING_CLAUDE_SUMMARY.md; live CombatDrone/AlliedInfantryDroid, DroneManager/DroneTargeting/DroneSquadState; commanded_ally_targeting_contract_smoke.gd and three direct drone smokes; validation_manifest.json.
- Task-specific authority: design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md; design/04_architecture/ACTOR_RELATIONSHIP_AND_TARGETABILITY.md; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md; reviewed NPA-7 contract.
- Work surface: custodian/tools/validation/{drone_follower_commands_smoke,main_scene_allied_droid_smoke,debug_collector_combat_drone_smoke,commanded_ally_targeting_contract_smoke}.gd; one additional bounded production-scene command fixture if needed; custodian/tools/validation/validation_manifest.json; only demonstrably defective existing custodian/game/actors/allies/{combat_drone,allied_infantry_droid}.gd or custodian/game/systems/drone/{drone_manager,drone_targeting,drone_squad_state}.gd; scoped docs.
- Change: Baseline actual scene and focused smokes after LFS/import preflight. Register existing direct smoke coverage as canonical manifest IDs, or merge unique coverage into an owned nonduplicate check, with exact source/scene/test owners. Add real production DroneManager→AlliedInfantryDroid command integration proving FOLLOW/HOLD/INTERCEPT/RECALL, FIRE AT WILL/HOLD FIRE, CLOSE/FAR/FREE_ROAM, guard-anchor placement/reticle/marker, no-path/leash stop, replacement-cap/slot identity and inheritance of current orders. Use real actor/projectile behavior where relevant, not helper-only assertions. Preserve NPA-7 commanded_ally_targeting_contract as sole policy/projectile regression owner for auto-hostile versus explicit passive Shrumb, allegiance/death/untargetable changes mid-burst. Prove main-scene droid presentation and status/observability; add transition-level diagnostics only if a real gap is demonstrated. Red-before-green regressions for any source fixes; no artificial runtime churn when only manifest/test hardening is required.
- Preserve: NPA-7's reviewed ActorRelationshipResolver/ActorAllegianceComponent and shot-time validation; DroneManager raw input and command authorization; DroneSquadState roster/modes; AlliedInfantryDroid inheritance, original presentation and current production-default scene; existing inputs, formation, leashes, weapon tuning, existing HUD/Operator/level-loader and squad-local DRONE_01 slot identity.
- Non-goals: No M-7 actor scene/skin/profile (separate npa-showcase-escort-frame-m7-actor); no NPA-8 bonded Vaultwing/fauna commands; no second command/targeting authority, Enemy inheritance, generic NPC base, global campaign injection, asset generation, combat balance change or dummy proxy implementation.
- Acceptance: (1) Exact NPA-7 implementation and review, and existing-enemy review, are archived complete; (2) at least one newly registered check executes real DroneManager + actual AlliedInfantryDroid scene and verifies representative command, navigation and guard/recall transitions; (3) direct smoke behavior has explicit manifest-owned coverage, no imaginary test IDs or redundant test launches; (4) cap, destroyed/freed prune, manager-scoped slot reuse and replacement mode/fire/follow/anchor/valid-target inheritance are verified; (5) canonical NPA-7 real projectile check passes auto vs explicit passive Shrumb, mid-burst flip and dead/freed cases without a duplicate policy implementation; (6) main-scene droid/status/animations and original production defaults remain intact; (7) actual runtime defects only are fixed with failing-first regression, while code changes to tests/manifest count as meaningful hardening when no runtime defect exists; (8) complete based changed-file coverage and final fresh independent paired review pass.
- Validation: Inspect live run_validation.py --help, Godot preflight/import contract and manifest IDs. Run registered commanded_ally_targeting_contract, actor_relationship_contract, allied_drone_navigation_walkability; execute unregistered direct drone_follower_commands_smoke.gd, main_scene_allied_droid_smoke.gd and debug_collector_combat_drone_smoke.gd via Godot only until registered (then use exact new IDs). Run real-scene command/replacement smoke, python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json with complete coverage, AI-context, review pairing, task packet index, diff check; fail closed on Godot fatal diagnostics and use existing job budget.
- Task overrides: `none`
- Deferred: M-7 actor art/scene in npa-showcase-escort-frame-m7-actor; separate Vaultwing proof, NPA-8 and future asset intake.

## Refresh Planning Authority
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Resolved. NPA-7 and existing-enemy paired reviews are landed, and current DroneManager/DroneTargeting APIs and registered/direct test evidence were inspected on main@44d49b7dd91fc8dc603be1b2a63be91a3246b028. Reinspect current APIs in claimed worktree only; no NPA-7 reimplementation or human design gate.

## Publication / Claim Gate
This pair was refreshed against actual NPA-7 and existing-enemy review archives. Dispatcher eligibility is authoritative only after both ready/auto files and the managed index are published on origin/main; the claiming agent must run targeted authoring, pairing and index checks. Reviewer claims remain dependency-gated until this implementation is complete and archived.

## Next Handoff
- Next workstream: `review-npa-showcase-existing-drone-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: Implement this bounded drone/droid hardening slice, archive it complete, then run the paired review through `paired_review_runner.py` in a fresh reviewer context.
- Blockers or open questions: `none`
