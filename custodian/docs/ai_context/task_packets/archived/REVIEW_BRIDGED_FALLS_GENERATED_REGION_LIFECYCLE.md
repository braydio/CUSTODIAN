# REVIEW: BRIDGED FALLS — GENERATED REGION LIFECYCLE FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-bridged-falls-generated-region-lifecycle`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `bridged-falls-generated-region-lifecycle`
- Locks: `route-runtime, level-loader, procgen-region-host`
- Review: `none`
- Review target workstream: `bridged-falls-generated-region-lifecycle`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE.md`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed generated-region route-node seam without redesigning it.
- Reviewed implementation acceptance: Verify the archived implementation packet's authored -> generated -> back contract, deterministic lifecycle, single authority, actor/camera binding, rollback, and unchanged `@world_origin`/authored-route behavior.
- Review evidence: Archived packet/summary, live generated-region adapter/registry/loader code, its focused lifecycle regression, and fresh route/procgen traces.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. Route non-blocking cleanup to BF2/deferred.
- Focused validation: `generated_region_route_lifecycle_smoke.gd` passed after project import; its late missing-spawn negative control emitted the expected failure and proved source/actor/camera rollback. `sundered_keep_route_graph_smoke.gd` reproduced the documented baseline arrival-guard failure. `ash_bell_lower_quarter_route_smoke.gd` and `procgen_intent_graph_smoke.gd` passed.
- Review focus: Hidden second transition authority, premature source deactivation, live Node leakage into route state, incorrect `@world_origin` reuse, nondeterministic seed handling, camera/Operator rollback gaps, authored route regressions.
- Acceptance: Produce a findings-first independent review of live main with stable finding IDs and required dispositions; do not patch reviewed runtime code.
- Non-goals: Do not implement Ash-Bell Highlands or Bridged Falls content.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `bridged-falls-generated-region-lifecycle-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: `none`
- Next action: After this review archives complete, claim the bounded R0-01 correction; then run its paired review from a fresh context.
- Blockers or open questions: The Sundered Keep route graph smoke retains the documented baseline arrival-guard failure.

## Review Findings

### R0-01

- Class: `blocking_defect`
- Domain: `implementation`
- Acceptance affected: Implementation Acceptance 5 and 7 — failed generation must roll back to the authored source; forced generation failure must preserve source, actor, and camera identity.
- Evidence: `GeneratedRegionLevel._await_level_data()` connects to `level_data_ready`, calls `ProcGenTilemap.generate()`, and loops until the signal arrives (`custodian/game/world/levels/generated_region_level.gd:111-117`). `ProcGenTilemap.generate()` returns without emitting that signal when its ProcGen owner or required floor/wall layers are missing (`custodian/game/world/procgen/proc_gen_tilemap.gd:1085-1101`); the signal is emitted later only in `_on_procgen_finished()` (`:1132-1170`). A failed generation therefore leaves `stage_level_async()` suspended after the source route node and actor have been frozen, so `_rollback()` is never reached. The focused lifecycle smoke covers a late missing-spawn failure, not a generation failure.
- Disposition: `correction`
- Rationale: The indefinite wait violates explicit failure rollback acceptance and can strand the route with no active gameplay authority. Add a bounded completion/failure path and a deterministic missing-dependency regression before the paired review can pass.

## Independent Review Receipt

- Status: `findings`
- Review workstream: `review-bridged-falls-generated-region-lifecycle`
- Reviewed on main: `520af6d832a4a79fe2fee110e3424ae1f1083dcd`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_CLAUDE_SUMMARY.md`
- Follow-up workstream: `bridged-falls-generated-region-lifecycle-review-corrections-1`
- Reviewer independence: `The reviewer claimed the paired packet in a fresh workstream and reconstructed the target from the archived implementation packet/summary, active route architecture, live code, and fresh runtime traces. The reviewed implementation was not modified.`
