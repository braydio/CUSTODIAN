# GAME TSCN OPERATOR STARTUP INTEGRITY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `game-tscn-operator-startup-integrity-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `contract-world-loader, game-scene-startup, procgen-spawn-integrity`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `review-game-tscn-operator-startup-integrity-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `this repairs the real production GameRoot startup path after multiple focused spawn fixes passed while the actual game scene still left the live Operator at its authored legacy coordinates; fresh-context review must prove the literal production boot and fail-closed contracts rather than another production-shaped approximation`
- Reviewed main: `c5ba129967e0428702af95da476b8271f178efbe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`.
- Goal: Make the literal production `res://scenes/game.tscn` boot finish with the canonical `/root/GameRoot/World/Operator` on the generated contract world's selected safe procgen tile, never silently remaining at the scene-authored legacy coordinates, while adding startup receipts and fail-closed invariants that make future boot/spawn regressions immediately attributable.
- Completion boundary: Done when a real production-scene startup regression loads the actual `game.tscn`, waits for the real ContractMap/ContractWorldLoader boot to settle, proves exactly one canonical player/Operator identity, proves one successful contract install for the active generation, proves the final Operator tile/position/visibility/process state match the loader's recorded canonical placement and generated procgen authority, and fails if the Operator remains at or is restored to the authored legacy position; ContractWorldLoader records one bounded spawn/startup receipt and refuses `contract_ready` when the receipt/current Operator diverge; Dev Observatory exposes transition-level startup identity/phase/receipt/failure evidence without per-frame spam; existing no-safe-cell and spawn-presentation failure paths remain fail-closed; AR3/AR4 ingress/camera ordering and S1 determinism remain intact.
- Current measured state:
  - A direct user Dev Observatory export from the literal production scene reports `Scene: GameRoot (res://scenes/game.tscn)`, uptime `2m 22s`, `123 events`, and `0 warnings`.
  - The generated procgen world is active: map `192x160`, `8205` floor cells, `954` wall cells, navigation revision `4` completed with no pending rebuild, and the runtime snapshot source is `/root/GameRoot/World/ProcGenRuntime/ProcGenMap`.
  - Registered world ingresses eventually placed, including Forlorn Ritualant at tile `[92,151]`, Ash Bell Lower Quarter at `[82,56]`, and Lords of Pain Test Gallery at `[66,52]`.
  - The same session reports `player_alive=true`, normal Operator weapon/ammo/stamina gauges, and `player_position={"x":717,"y":-485}`.
  - Live `game.tscn` authors `World/Operator.position = Vector2(717.45905, -485.33954)` and `World/Camera2D.position = Vector2(720, -480)`. The observed runtime player position therefore matches the scene-authored legacy placeholder rather than demonstrating generated-world relocation.
  - Dev Observatory currently samples `get_first_node_in_group("player")`, so the live evidence also leaves one identity ambiguity: either the canonical Operator was never relocated, it was relocated then clobbered back, or an unexpected competing `player` group node is being sampled. This packet must resolve that ambiguity from the actual production tree.
  - Existing focused spawn corrections/reviews are green: canonical playable-region validity, deterministic main-component fallback, fail-closed no-safe behavior, and selected-tile presentation residency all have focused coverage. Those tests were insufficient because none made the literal normal `game.tscn` boot the final acceptance boundary.
  - Archive Resolve code/review lineage is complete; its deferred live gameplay judgment remains blocked on this startup defect. Do not retune Archive Resolve in this packet.
  - The same Observatory session latched one unclassified performance incident with a `1116.93 ms` worst frame. Treat this only as a reason to improve startup phase attribution; do not turn this packet into a renderer/performance rewrite.
- Evidence:
  - user Dev Observatory export described above;
  - `custodian/scenes/game.tscn`;
  - `custodian/game/systems/core/systems/contract_world_loader.gd`;
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`;
  - `custodian/game/systems/debug/dev_observatory.gd`;
  - `custodian/tools/validation/contract_world_operator_spawn_residency_smoke.gd`;
  - `custodian/tools/validation/contract_world_operator_void_spawn_failsafe_smoke.gd`;
  - `custodian/tools/validation/contract_world_playable_region_spawn_validity_smoke.gd`;
  - `custodian/tools/validation/contract_world_archive_resolve_ingress_smoke.gd`;
  - archived spawn-correction implementation/review receipts.
- Task-specific authority: `ContractWorldLoader` owns production contract install and final Operator placement orchestration; `ProcGenTilemap` owns canonical spawn validity/runtime walkability/main playable component and presentation residency; `game.tscn` owns the authored scene placeholder only; the scene-authored Operator coordinates are never gameplay spawn authority.
- Work surface: Prefer `contract_world_loader.gd`, one new production-scene startup smoke under `custodian/tools/validation/`, `validation_manifest.json`, and bounded Dev Observatory startup telemetry. Touch `game.tscn`, ContractMap/bootstrap, or player-group ownership only when live investigation proves the defect lives there. Update concise current-state/roadmap/task-index docs made stale by the fix. Do not broaden into procgen topology, Archive Resolve tuning, vehicles, combat, camera redesign, or general observability refactors.
- Change:
  1. Reproduce the defect through the literal `res://scenes/game.tscn` production boot before changing behavior. Capture the actual scene tree identity of every node in groups `player` and `operator`, the canonical `/root/GameRoot/World/Operator` instance ID/path/visibility/process mode/position, ContractWorldLoader bind state, latest contract generation identity, install trace, active procgen map, and GameState ready/failure state. The implementation summary must state which of the three hypotheses was true: placement never ran, placement ran then was clobbered, or the wrong player identity was sampled.
  2. Add a real production-scene startup integration smoke. Instantiate/run the actual `game.tscn` with the production ContractMap + ContractWorldLoader path, not a hand-built loader fixture. Wait with a bounded timeout for one terminal contract state. A successful boot must prove the actual scene Operator no longer equals the authored legacy position and round-trips through the active ProcGenTilemap to the exact selected canonical spawn tile.
  3. Make canonical Operator identity explicit at startup. In production there must be exactly one canonical scene Operator at `/root/GameRoot/World/Operator`; it must be the player-group node used by gameplay/observability after boot. Fail the focused regression if multiple live `player` identities can satisfy player sampling or if the canonical path is missing/replaced unexpectedly. Do not create a new player registry unless live architecture genuinely lacks a usable authority.
  4. Add one bounded `operator placement receipt` owned by ContractWorldLoader for the active contract generation. It should record at minimum generation identity when available, Operator instance ID/path, selected source (`compound` / `player_spawn` / `main_component_fallback`), selected tile, selected world position, presentation-readiness result, and the component-query count already available from the install trace. Expose a read-only duplicate for validation/diagnostics. Do not make gameplay depend on Dev Observatory.
  5. Harden the transition immediately before `contract_ready`: if Operator relocation is enabled, require the live canonical Operator instance to still match the placement receipt, still round-trip to the selected tile, still be on painted realized floor, and still be visible/process-enabled according to the successful restore contract. Reuse already-computed placement facts and cheap current-position checks; do not re-run the main playable-component flood/query merely to prove what the receipt already established. If this invariant fails, fail contract activation through the existing failure authority instead of silently publishing a playable world at stale coordinates.
  6. Preserve the existing genuine no-safe-cell and presentation-realization failure semantics. A fix must never make the authored `(717,-485)`-class scene coordinate a fallback spawn. If startup cannot prove a canonical safe placement, the Operator remains non-playable and GameState records contract failure.
  7. Prevent duplicate contract installation for one generation if the real boot investigation reveals a signal + `get_latest_contract()` race. Use the smallest generation/contract identity guard consistent with the live ContractMap contract. Do not add a global event bus or suppress legitimate future regenerations. If no duplicate application exists in the reproduced boot, leave behavior unchanged and only retain proof in the startup smoke.
  8. Add transition-level Dev Observatory startup attribution, not per-frame polling. Surface enough bounded data to answer future reports from one export: ContractWorldLoader bound/unbound, active contract generation/terminal state, placement receipt source/tile/world position/Operator instance, final ready/failure phase, player-group identity count, and any post-placement divergence detected before ready. Prefer one structured gauge/receipt plus transition events over dozens of scalar gauges.
  9. Add startup phase timing around the existing install phases so a future multi-hundred-ms/second startup hitch can be attributed to contract generation/install/ingress/spawn/camera/navigation rather than reported only as an unclassified frame. Keep this instrumentation lightweight, transition-level, and dev-observatory-owned. Do not solve the unrelated `1116.93 ms` incident unless the new timing directly identifies this spawn/startup path as its owner.
  10. Mark the scene-authored Operator coordinates in code/docs as editor/bootstrap placeholder data only if that is not already explicit. Do not "fix" the defect by merely moving the authored scene node to a nicer coordinate; the production boot must prove generated relocation.
  11. Mutation-check the new literal-scene smoke. At minimum, temporarily disable/skip the real loader's Operator placement or restore the Operator to the authored legacy position immediately before ready and require the regression to fail. If the root cause was duplicate/wrong player identity, add a second focused mutation/fixture proving that identity guard catches it.
  12. Reconcile active docs after the fix: Archive Resolve remains technically closed but its real playtest becomes unblocked; spawn residency/failsafe docs must no longer imply that production startup was fully proven before this literal-scene regression existed. Keep history intact; update only active truth.
- Additional repository/game hardening included by this packet:
  - Production-scene boot becomes a first-class validation owner so future changes to `game.tscn`, ContractWorldLoader, ContractMap/bootstrap, Operator scene/group identity, ProcGenTilemap spawn seams, camera startup, or Archive Resolve ingress can select this regression through `validation_manifest.json`.
  - Final `contract_ready` gains a cheap, explicit Operator-placement consistency gate, preventing "map generated but player silently stayed at editor coordinates" from becoming a valid runtime state again.
  - Dev Observatory gains enough startup provenance to distinguish missing placement, post-placement clobber, duplicate player identity, and fail-closed spawn errors from one user export.
  - Startup phase timing makes future boot hitch triage actionable without adding broad always-on profiling.
  - The regression must be hermetic with a bounded timeout and must leave no save/profile/user-state residue, so it is safe in ordinary changed-file validation.
- Preserve:
  - canonical spawn authority: `is_valid_spawn_cell()` + runtime navigation walkability + accepted main playable component + ingress-clearance exclusion;
  - existing preferred selection order: compound -> exported player spawn -> deterministic accepted-component fallback;
  - selected-tile presentation realization through existing ProcGen lifecycle/payload/commit authority;
  - no extra AR3/AR4 playable-component query after final placement;
  - camera refresh and Archive Resolve ingress only after successful Operator placement;
  - streaming/lifecycle/cache ownership;
  - navigation/collision/terrain authority;
  - vehicle lifecycle and no auto-enter-on-load behavior;
  - S1 determinism fingerprint `1773840677` unless live main has intentionally changed the canonical benchmark, in which case report and reconcile authority rather than silently updating expectations.
- Non-goals: No procgen topology redesign; no playable-area expansion; no map-size change; no Archive Resolve visual tuning; no camera redesign; no vehicle fix; no combat changes; no general performance optimization; no replacing ContractWorldLoader with a new startup manager; no generic player registry unless required by an independently proven identity defect; no moving the authored scene Operator and calling that the fix.
- Acceptance:
  1. The implementation summary records the reproduced root cause from the real `game.tscn` boot: placement skipped, post-placement clobber, wrong player identity, or another precisely evidenced cause.
  2. New production-scene startup smoke runs the literal `res://scenes/game.tscn` path with real ContractMap/ContractWorldLoader and a bounded terminal-state timeout.
  3. On successful boot, exactly one canonical production player identity is proven and it is `/root/GameRoot/World/Operator`.
  4. Successful boot emits/retains a placement receipt with Operator instance/path, source, tile, world position and presentation-ready status.
  5. Final canonical Operator position differs from the authored legacy `Vector2(717.45905,-485.33954)` placeholder and round-trips to the receipt's selected tile on the active ProcGenTilemap.
  6. That final tile is canonical spawn-valid, runtime-navigation-walkable, outside ingress dressing clearance, part of the accepted main playable component as established during selection, and realized as painted floor before Operator control is restored.
  7. Contract ready is impossible when the live Operator instance/path/position diverges from the successful placement receipt before ready; the existing contract-failure path is used instead.
  8. Registered-ingress -> Operator placement -> Gothic compound connection -> Archive Resolve ingress -> camera refresh -> navigation -> contract ready ordering remains correct.
  9. Genuine no-safe-cell and spawn-presentation-realization failures remain fail-closed, with no visible/control-ready Operator at the scene-authored placeholder.
  10. The production-scene smoke fails under a mutation that skips placement or restores the legacy coordinates before ready.
  11. Dev Observatory can distinguish successful placement, missing placement, pre-ready clobber, and player-identity mismatch from bounded transition-level evidence; no per-frame event spam is introduced.
  12. Startup phase timing is available in dev evidence and does not materially perturb normal-frame performance.
  13. Validation ownership selects the new production-scene smoke for changes to the startup/spawn authority surface.
  14. Existing spawn validity/residency/failsafe/ingress smokes, Archive Resolve AR3/AR4 focused smokes, procgen streaming/lifecycle/runtime-health regressions, vehicle runtime lifecycle, and S1 quick remain green.
  15. `git diff --check`, changed-file validation, and directly affected current validation owners pass; unrelated pre-existing failures are called out explicitly rather than folded into this packet.
- Validation:
  - Reproduce once through the actual `game.tscn` boot and save the before-fix install/identity evidence in the implementation summary.
  - Add and run the new production-scene startup smoke, recommended ID `game_scene_operator_startup_integrity` unless live naming conventions suggest a clearer owner.
  - Run `contract_world_operator_spawn_residency`.
  - Run `contract_world_operator_void_spawn_failsafe`.
  - Run `contract_world_playable_region_spawn_validity`.
  - Run `contract_world_ingress_spawn_clearance`.
  - Run `contract_world_archive_resolve_ingress`.
  - Run `procgen_archive_resolve_semantic_echo` and `procgen_archive_resolve_frontier_restraint`.
  - Run streaming/lifecycle/payload-cache/runtime-health and vehicle-runtime-lifecycle owners selected by live validation manifest.
  - Run S1 quick / canonical procgen performance baseline.
  - Run the placement/clobber mutation check and any identity mutation required by the discovered root cause.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Visual review: `none`
- Task overrides: `none`
- Deferred:
  - Human Archive Resolve game-feel/playtest resumes only after this packet lands and the user can launch ordinary gameplay at the generated spawn.
  - Investigate the separate unclassified `1116.93 ms` Dev Observatory incident after startup integrity is restored unless phase timing directly proves this startup path owns it.
  - Broader ContractWorldLoader extraction/decomplexification remains a separate architectural slice.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes — literal production game.tscn reaches ready with one canonical generated-world Operator placement, bounded startup diagnostics, and a fail-closed pre-ready receipt check`
- Completion boundary satisfied: `yes — the production scene smoke proves exact receipt/tile identity, phase ordering, canonical player identity, painted floor, visibility, and enabled processing`
- Acceptance satisfied: `yes — literal production startup and mutation proof, focused spawn/ingress/AR3/AR4/streaming/lifecycle/cache/runtime-health/vehicle checks, S1 quick baseline, and complete changed-file coverage are established; remaining changed-sweep failures are documented clean-main baseline failures in unrelated Vaultwing and ambient-spawn owners`
- Superseded/legacy production path disposition: `scene-authored Operator coordinates remain editor/bootstrap placeholder only; never runtime fallback authority`
- Evidence: `GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1_CLAUDE_SUMMARY.md; literal scene seed 1773840677 selected tile (88,180), one player identity, generation receipt, ready validation valid=true; pre-ready legacy-position mutation failed activation with operator_placement_diverged_before_ready; focused acceptance owners and startup owner pass; changed sweep has complete coverage with unrelated clean-main baseline failures documented`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `focused spawn fixtures passed while the literal production startup left the Operator at its authored placeholder because a registered ingress clearance covered every safe cell in the accepted 72-cell component; optional Vaultwing population also emitted unrelated missing-asset errors in the startup proof and was isolated at the fixture boundary`
- Root cause / contributing factors: `Forlorn edge placement had no minimum distance from the live ProcGen spawn; its 27x19-tile dressing clearance overlapped the canonical spawn. level_data.player_spawn used a different coordinate and was not the live map authority. An unnecessary generation guard initially suppressed intentional same-instance failure/recovery coverage and was removed.`
- Prevention / pipeline improvement: `live-map spawn clearance constraints for world ingress placement; literal production-scene startup owner; generation-scoped placement receipt, transition-level diagnostics, phase timings, and a cheap pre-ready consistency gate`
- Tooling / docs drift discovered: `the paired-review packet had parser-invisible target fields, Review: manual, and a noncanonical override; corrected to the dispatcher contract`
- Follow-up: `fixed-in-scope`
- What worked: `existing spawn validity/residency/failsafe authorities provided narrow reusable predicates without a spawn redesign`

## Next Handoff

- Next workstream: `review-game-tscn-operator-startup-integrity-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `Run the fresh-context paired review after the implementation lands; if passed, unblock the user's deferred Archive Resolve playtest.`
- Blockers or open questions: `none`
