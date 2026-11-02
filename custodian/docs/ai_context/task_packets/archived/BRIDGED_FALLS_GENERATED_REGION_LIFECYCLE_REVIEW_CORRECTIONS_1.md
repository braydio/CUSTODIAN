# CORRECTION: Bridged Falls Generated Region Lifecycle — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-generated-region-lifecycle-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-bridged-falls-generated-region-lifecycle`
- Locks: `route-runtime, level-loader, procgen-region-host`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `520af6d832a4a79fe2fee110e3424ae1f1083dcd`
- Parent implementation: `bridged-falls-generated-region-lifecycle` — `custodian/docs/ai_context/task_packets/archived/BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE.md`
- Parent review: `review-bridged-falls-generated-region-lifecycle` — `custodian/docs/ai_context/task_packets/archived/REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE.md`
- Findings addressed: `R0-01`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Affected acceptance: Parent implementation Acceptance 5 and 7: generation failure must roll back to the authored source and preserve the source, actor, and camera identity.
- Current defect/evidence: `GeneratedRegionLevel._await_level_data()` waits indefinitely for `level_data_ready`. `ProcGenTilemap.generate()` returns without emitting that signal when its ProcGen owner or required floor/wall layers are missing; `_on_procgen_finished()` is the only observed emission path. The current lifecycle smoke verifies a late missing-spawn failure but does not exercise a generation failure.
- Goal: Every generated-region stage resolves with success or failure, so a generation failure reaches the existing route rollback transaction instead of leaving the source and actor frozen.
- Completion boundary: Add a fail-closed generated-map completion path and deterministic regression for a ProcGenTilemap whose required generation dependencies are invalid. Prove the route returns to the authored source with the same actor and camera binding.
- Current measured state: A missing required layer causes `ProcGenTilemap.generate()` to return before signal emission; the adapter has no timeout or failure signal and remains suspended.
- Evidence: Parent review finding `R0-01` in `REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_CLAUDE_SUMMARY.md`; archived parent implementation packet and summary; live `generated_region_level.gd` and `proc_gen_tilemap.gd`; `generated_region_route_lifecycle_smoke.gd`.
- Task-specific authority: `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`; the parent implementation packet's failed-generation rollback contract; `ProcGenTilemap` remains generation authority and `LevelLoader`/`RouteTraversalManager` remain staging/rollback authorities.
- Work surface: `custodian/game/world/levels/generated_region_level.gd`; focused coverage in `custodian/tools/validation/generated_region_route_lifecycle_smoke.gd` and its fixture scene; changed-file ownership in `custodian/tools/validation/validation_manifest.json` and expected controlled-failure classification in `custodian/tools/validation/known_headless_warnings.json`.
- Required correction: Make invalid generation dependencies resolve as an explicit failure consumed by `GeneratedRegionLevel` and propagated by `LevelLoader.stage_level_async()`. Preserve successful asynchronous generation. Avoid unbounded polling; ensure cleanup discards the staged map and route rollback reactivates the source and refreshes the camera. Add a deterministic negative control for missing required generation dependencies.
- Preserve: Existing generated-region success path; explicit seed/profile handling; canonical playable-component spawn validation; authored-to-generated-to-authored traversal; `@world_origin`; Operator/camera identity; single active route authority; existing authored route behavior and ProcGen ownership.
- Non-goals: No Ash-Bell Highlands or Bridged Falls content, no generator redesign, no changes to authored-route semantics, and no unrelated failure-timeout policy work.
- Acceptance:
  1. An invalid ProcGenTilemap generation dependency causes staging to fail promptly with a useful reason rather than waiting indefinitely.
  2. The route rollback leaves the authored source active and visible, restores the same Operator identity and position, and rebinds the shared camera to the authored map.
  3. The existing successful generated-region lifecycle and late missing-spawn negative control still pass.
  4. The correction introduces no second transition, generation, navigation, collision, or route-state authority.
- Validation: Run the expanded `generated_region_route_lifecycle_smoke.gd` first, including the missing-dependency failure and rollback assertions. Then run `ash_bell_lower_quarter_route_smoke.gd` and `procgen_intent_graph_smoke.gd`; run `sundered_keep_route_graph_smoke.gd` and record its known baseline arrival-guard result. Finish with changed-file validation, task packet index, and `git diff --check`.
- Task overrides: `none`
- Deferred: The Sundered Keep arrival-guard baseline failure remains outside this correction.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `generated_region_route_lifecycle_smoke.gd` passes with successful generated traversal, late missing-spawn rollback, and missing-ProcGen-owner rollback. The missing-owner case returns `generated-region map has no ProcGen owner` and restores authored node, actor identity/position, visibility/process state, and camera map. `ash_bell_lower_quarter_route_smoke.gd` and `procgen_intent_graph_smoke.gd` pass. `sundered_keep_route_graph_smoke.gd` reproduces the documented Front Gate arrival-guard failure. Final changed-file validation passes 7/7 with complete coverage after registering the lifecycle smoke and classifying its four exact expected route rollback errors. The initial broader ProcGen sweep selected 31 checks and exposed the unrelated `procgen_ambient_enemy_real_world_spawn` baseline failure (seed 12345: 72 main-component tiles, 0 safe tiles), reproduced on clean project-root main at `9038f8eee`; the narrower final adapter change no longer modifies ProcGenTilemap and does not select that broad sweep. `git diff --check` passed.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The first broad changed-file run selected an unrelated ProcGen ambient-spawn smoke that fails on clean main, while the focused lifecycle smoke was absent from the manifest and its intentional rollback ERROR logs were treated as fatal.`
- Root cause / contributing factors: `Seed 12345 produced a 72-tile accepted component with zero safe spawn cells. The validation manifest had no generated-region owner entry, and the warning registry did not identify the exact route rollback errors emitted by the negative controls.`
- Prevention / pipeline improvement: `Registered the generated-region lifecycle test and added exact expected-error patterns for its two controlled rollback cases; final changed-file validation now selects a bounded, fully covered set.`
- Tooling / docs drift discovered: `Generated-region lifecycle changed-file coverage and expected controlled-failure classification were absent; both are fixed in-scope.`
- Follow-up: `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- What worked: `The staging adapter preflights ProcGen, floor-layer, and wall-layer dependencies before awaiting level_data_ready directly, while the existing route manager owns rollback.`

## Next Handoff

- Next workstream: `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: `none`
- Next action: After correction 1 lands, run its paired fresh-context review against the failure and rollback contract.
- Blockers or open questions: none.
