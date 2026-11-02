# GAME TSCN OPERATOR STARTUP INTEGRITY V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Result

Implemented and validated the literal `res://scenes/game.tscn` Operator startup path. The root cause was a registered Forlorn ingress whose 27×19-tile ProcGen dressing clearance covered all 72 cells in the accepted main component. The Operator placement branch therefore never ran and the canonical scene node remained at its editor placeholder. The production tree had exactly one player identity, so this was not a sampling or post-placement clobber defect.

The placement metadata now keeps the Forlorn ingress at least 16 tiles from the live `ProcGenTilemap.get_player_spawn()`. The lower-quarter ingress uses the same live-map spawn authority for its clearance constraint. This matters because `level_data.player_spawn` and the map's canonical spawn differed in the reproduced production boot. Existing ingress clearance exclusions and no-safe-cell failure semantics remain intact.

`ContractWorldLoader` now disables the Operator before generated placement, records a generation-scoped placement receipt, captures phase durations and transition diagnostics, restores Operator control only after ingress/compound/Archive Resolve/camera/navigation work, and checks the receipt against the live canonical Operator immediately before `contract_ready`. A missing canonical Operator, missing contract-map binding, or divergent placement goes through the existing failure path. Deferred runtime-node cleanup now passes an instance ID rather than a Node argument.

## Evidence

- Before-fix literal-scene reproduction, bootstrap seed `1773840677`, map seed `3207627847`: `no_canonical_safe_spawn`; accepted main component 72 cells; safe component 0; ingress-clearance exclusions 72; live spawn `(88,180)` lay inside clearance `[71,170] size (27,19)`. The canonical `/root/GameRoot/World/Operator` was the only `player` identity and remained at `(717.45905,-485.33954)`. Root cause: placement skipped due to no safe tile.
- Final literal-scene run, same bootstrap seed, accepted map seed `3207643685`: passed with one canonical player identity; selected tile `(88,180)`; exact receipt position `(2832,5776)`; presentation ready, painted floor, navigation walkable, outside ingress clearance, and `ready` validation true. Phase order covered registered ingresses, Operator placement, compound connection, Archive Resolve ingress, camera, navigation, receipt, and contract ready.
- Mutation control temporarily restored the Operator to `(717.45905,-485.33954)` immediately before the ready gate. The loader reported `operator_placement_diverged_before_ready`, left the scene not ready, and the smoke exited 1 as expected. The temporary mutation was removed.
- Passed focused validation: `contract_world_operator_spawn_residency`, `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, `contract_world_archive_resolve_ingress`, `procgen_archive_resolve_semantic_echo`, `procgen_archive_resolve_frontier_restraint`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_runtime_health`, and `vehicle_runtime_lifecycle`.
- `procgen_performance_baseline_quick` exceeded its registered 120-second timeout. Running the same quick script directly completed successfully in about 160 seconds: `determinism_ok=true`; both 48×48 seed-420777 fingerprints were `1773840677`; the 64×64 runtime case completed.
- `git diff --check` passed and the validation manifest parses as JSON. Changed-file coverage is complete; known unrelated baseline owners below remain reported rather than suppressed.
- The production-scene smoke suppresses optional Vaultwing scene creation before adding the production scene to its tree, keeping the proof scoped to Operator readiness. `game_scene_operator_startup_integrity` passed in 167.8 seconds; only recognized Godot exit leak notices remained.
- `world_contract_prewarm` initially exposed scene-tree cleanup calls from an out-of-tree failure fixture. The loader now guards scene-tree-only observability and failure cleanup; the focused owner passed after this fix.
- Commit-aware changed validation selected 31 owners with complete file coverage: 28 passed, two failed, and one timed out. The startup owner and `world_contract_prewarm` pass. Remaining failures/timeouts are baseline: missing Vaultwing bonding PNGs in `vaultwing_bond`, `Array`/`Array[Node]` spawn errors in `vaultwing_world_spawn`, and the 180-second `procgen_ambient_enemy_real_world_spawn` timeout. The Vaultwing bonding asset failure was reproduced against clean project-root `main`; the ambient-spawn failure was already reproduced on clean `main` in the preceding handoff. The Sundered Keep arrival-guard baseline remains unchanged. A separate green `contract_world_ingress_spawn_clearance` JSON report is used for lifecycle finish's focused-green gate; it does not replace the full changed-file report.

## Changed Files

- `custodian/game/systems/core/systems/contract_world_loader.gd`
- `custodian/game/world/levels/world_ingress_placement_resolver.gd`
- `custodian/content/routes/ash_bell/forlorn_ritualant_underground_route.json`
- `custodian/content/routes/ash_bell/lower_quarter_route.json`
- `custodian/tools/validation/game_scene_operator_startup_integrity_smoke.gd` and `.uid`
- `custodian/tools/validation/validation_manifest.json`
- Existing ingress and Archive Resolve phase assertions updated for the actual install ordering.
- `custodian/docs/ai_context/CURRENT_STATE.md`
- Paired review packet metadata repaired to match the dispatcher/parser contract.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: focused spawn fixtures passed while production ingress clearance could consume every safe starting cell; an overbroad same-generation guard also suppressed intended failure/recovery exercises until removed.
- Root cause / contributing factors: the Forlorn ingress resolver did not protect the canonical live spawn; level-data spawn coordinates were not the live map's spawn authority.
- Prevention / pipeline improvement: literal production-scene startup owner, live-map ingress clearance constraints, and a pre-ready receipt invariant with transition-level diagnostics.
- Tooling / docs drift discovered: paired-review target metadata was outside the parser's header region, its dispatch intent and bounded task override were malformed; fixed in the current branch.
- Follow-up: fixed-in-scope
- What worked: existing spawn predicates, ingress clearance authority, and focused negative controls localized the defect without topology or Archive Resolve redesign.

## Next Handoff
- Next workstream: review-game-tscn-operator-startup-integrity-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: claim the paired review from a fresh reviewer context after this implementation lands.
- Blockers or open questions: unrelated baseline failures remain in `vaultwing_bond`, `vaultwing_world_spawn`, `procgen_ambient_enemy_real_world_spawn`, and the documented Sundered Keep arrival guard; none is in this packet's changed startup path.
