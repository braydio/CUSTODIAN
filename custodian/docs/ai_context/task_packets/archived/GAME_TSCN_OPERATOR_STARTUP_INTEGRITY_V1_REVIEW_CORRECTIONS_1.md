# CORRECTION: GAME TSCN OPERATOR STARTUP INTEGRITY REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `game-tscn-operator-startup-integrity-v1-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-game-tscn-operator-startup-integrity-v1`
- Locks: `contract-world-loader, game-scene-startup, procgen-spawn-integrity`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-game-tscn-operator-startup-integrity-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `579121331d74f754daf86cc1009617a2934f89b4`
- Parent implementation: `game-tscn-operator-startup-integrity-v1; custodian/docs/ai_context/task_packets/archived/GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1.md`
- Parent review: `review-game-tscn-operator-startup-integrity-v1; custodian/docs/ai_context/task_packets/archived/REVIEW_GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: `The successful production boot's final Operator position must round-trip to the placement receipt's selected tile/world position.`
- Current defect/evidence: `The independent production-scene smoke reports the ready-time receipt/snapshot at world position (2832,5776), tile (88,180), but its terminal live Operator is at (2832,5793.039), tile (88,181). The loader's pre-ready gate and the smoke's current assertions do not detect this subsequent displacement.`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: `Keep the canonical Operator's settled production-start position consistent with its accepted safe placement receipt, or fail contract activation when that consistency cannot be established.`
- Completion boundary: `A literal game.tscn boot samples the live Operator after physics has had an opportunity to move it. The final position remains on the receipt's selected canonical tile and is still safe/presented, or contract readiness is withheld. The receipt and smoke truthfully describe that settled position.`
- Current measured state: `On main 579121331, game_scene_operator_startup_integrity passed, but the smoke's final live position was 17.039 pixels below the recorded placement position and round-tripped to the next tile.`
- Evidence: `R0-01 in REVIEW_GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1.md; independent validation output from game_scene_operator_startup_integrity; custodian/game/systems/core/systems/contract_world_loader.gd; custodian/tools/validation/game_scene_operator_startup_integrity_smoke.gd.`
- Task-specific authority: `The archived parent implementation packet and its acceptance; ContractWorldLoader owns final generated placement and readiness; ProcGenTilemap owns canonical spawn safety, main-component membership, and tile conversion.`
- Work surface: `custodian/game/systems/core/systems/contract_world_loader.gd; custodian/tools/validation/game_scene_operator_startup_integrity_smoke.gd; validation_manifest.json only if ownership changes.`
- Required correction: `Trace why the production Operator moves after contract_ready. Ensure the settled position remains within the accepted receipt tile and canonical safe placement, or keep the Operator non-playable and fail closed. Update the literal-scene smoke to assert against the actual live Operator after a physics step and retain the legacy-position mutation control. Do not recompute the main playable component in the pre-ready/settling consistency check.`
- Preserve: `The live-map spawn authority, compound -> player_spawn -> main-component fallback order, generation-scoped receipt, single component query, no-safe/presentation-realization failures, ingress/Archive Resolve/camera/navigation ordering, S1 determinism, and bounded transition telemetry.`
- Non-goals: `No topology or ingress redesign, no Archive Resolve retuning, no camera/vehicle changes, no general physics rewrite, and no edits outside R0-01.`
- Acceptance: `1. A fresh literal game.tscn boot records a final live position that round-trips to the receipt's selected tile after at least one physics step. 2. That settled tile remains canonical-spawn-valid, walkable, outside ingress clearance, and in the accepted component as proven by the original selection. 3. If post-placement movement leaves the accepted safe placement, contract_ready is not published and the existing failure path is used. 4. The smoke fails under a pre-ready legacy-position mutation. 5. Existing no-safe/presentation failure behavior, ordering, focused spawn regressions, and S1 determinism remain intact.`
- Validation: `Rerun game_scene_operator_startup_integrity and its legacy-position mutation; contract_world_operator_spawn_residency; contract_world_operator_void_spawn_failsafe; contract_world_playable_region_spawn_validity; contract_world_ingress_spawn_clearance; contract_world_archive_resolve_ingress; procgen_archive_resolve_semantic_echo; procgen_archive_resolve_frontier_restraint; affected streaming/lifecycle/runtime-health and vehicle owners; procgen_performance_baseline_quick; git diff --check.`
- Task overrides: `none`
- Deferred: `The user's Archive Resolve live playtest remains deferred until this correction and its paired review pass.`


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `Final validation runner passed game_scene_operator_startup_integrity (236938 ms); literal production smoke sampled after physics and reported live position (2832,5776), tile (88,180), matching the receipt, with no slide collisions. The legacy-position mutation produced operator_placement_diverged_before_ready and a nonzero smoke result. Focused spawn, playable-region, ingress, Archive Resolve, streaming, lifecycle, runtime-health, and vehicle checks passed. procgen_performance_baseline_quick direct run passed with determinism_ok=true. The post-sync changed-file sweep was 15/18: its red results were the documented ambient-spawn timeout and Vaultwing missing-asset/type failures; the focused startup owner passed again after sync. git diff --check passed for the correction before merge; incoming main has two unrelated roadmap trailing-space lines.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The initial asynchronous readiness experiment broke synchronous spawn fixtures; it was removed. The first terminal alternate-tile adjustment had no effect when the compound supplied no alternate tile; a bounded 32-pixel fallback resolved the actual overlap. The registered S1 runner timed out at 120 seconds, while the documented direct quick profile completed successfully in 151 seconds.`
- Root cause / contributing factors: `The contract loader placed the static CommandTerminal body on the same tile as the Operator after choosing the spawn, and the first live move_and_slide depenetrated the Operator into the next tile. The original smoke sampled after that movement but checked only the ready-time receipt.`
- Prevention / pipeline improvement: `Avoid positioning the terminal body on the selected Operator tile; synchronously reject a pre-ready physics-shape overlap, and retain a literal-scene post-physics receipt comparison.`
- Tooling / docs drift discovered: `The registered quick validation timeout (120 seconds) is shorter than the observed 151-second documented direct quick profile on this host. The post-sync full changed-file sweep includes documented unrelated ambient-spawn and Vaultwing baseline failures.`
- Follow-up: `none`
- What worked: `The terminal overlap adjustment and post-physics literal-scene assertion proved the receipt/live-position invariant.`

## Independent Review

- Status: `passed`
- Review workstream: `review-game-tscn-operator-startup-integrity-v1-review-corrections-1`
- Reviewed on main: `d7e4145f7`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- R0-01: `fixed` — production terminal placement avoids the selected Operator tile; pre-ready validation rejects shape overlap, and the literal-scene smoke now checks the live position after physics against both the selected receipt tile and world position.
- Focused validation: `game_scene_operator_startup_integrity` passed (167468 ms); the isolated legacy-position mutation failed (exit 1), withholding `contract_ready` and failing the receipt/live-state assertions; `contract_world_operator_spawn_residency`, `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, `contract_world_archive_resolve_ingress`, `procgen_archive_resolve_semantic_echo`, and `procgen_archive_resolve_frontier_restraint` passed. S1 quick passed with `determinism_ok=true` and matching 48x48 seed-420777 fingerprints `1773840677`. `git diff --check` passed. The code-review graph was unavailable in this checkout; review used the archived contract, commit diff, focused source, and runtime evidence.
- Evidence limits: `The mutation was run in a separate disposable worktree and changed no reviewed files. The spawn-residency fixture emitted a NavigationSystem-not-found warning but passed its explicit smoke assertions. The validator reports known Godot exit leaks for the production scene; no subjective visual review was required.`
- Detailed review summary: `REVIEW_GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`
- Reviewer independence: `Fresh reviewer workstream reconstructed the correction from the archived target packet, prior independent finding, implementation summary, landed correction diff, live code, and focused runtime checks. The reviewed implementation and smoke files were not modified in the review worktree.`
