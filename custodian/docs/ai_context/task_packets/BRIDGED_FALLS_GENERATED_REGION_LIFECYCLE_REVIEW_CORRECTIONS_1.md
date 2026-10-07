# CORRECTION: Bridged Falls Generated Region Lifecycle — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-generated-region-lifecycle-review-corrections-1`
- Status: `ready`
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
- Work surface: `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd` only if the narrowest solution requires an explicit completion/failure signal; focused coverage in `custodian/tools/validation/generated_region_route_lifecycle_smoke.gd` and its fixture scene if needed.
- Required correction: Make invalid generation resolve as an explicit failure consumed by `GeneratedRegionLevel` and propagated by `LevelLoader.stage_level_async()`. Preserve successful asynchronous generation. Avoid unbounded polling; ensure cleanup discards the staged map and route rollback reactivates the source and refreshes the camera. Add a deterministic negative control for missing required generation dependencies.
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

## Next Handoff

- Next workstream: `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: `none`
- Next action: After correction 1 lands, run its paired fresh-context review against the failure and rollback contract.
- Blockers or open questions: none.
