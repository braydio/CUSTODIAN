# Procgen Runtime Mutation Scheduler Cutover — Closing Summary

M1 built `ProcGenDerivedRebuildScheduler` as a request/commit ledger but left
every producer calling its request+commit pair unconditionally around a full
rebuild every single time it was invoked — the ledger recorded coalescing
opportunities without anyone acting on them. This task made two of the three
remaining non-navigation systems actually batch: `_rebuild_runtime_walkable_
boundary` and `_refresh_shadows` now follow navigation's existing dirty-flag +
`call_deferred` pattern (`_navigation_rebuild_deferred` /
`_flush_navigation_rebuild`). The first `request()` in a scheduler batch
schedules a deferred flush; every later request in the same batch just marks
the ledger (coalesced) and returns without redoing the rebuild. The flush does
the real work once and commits once.

`_claim_isolated_world_overlook_pocket` needed an explicit synchronous
exception: it is a one-call API whose caller inspects walkability on the newly
isolated pocket in the same line, with no frame yield in between. Deferring its
boundary rebuild broke `ash_bell_threadway_causeway_smoke.gd`'s pre-Knot
frontier check (confirmed by running it and watching it fail, then re-passing
once `flush_now: bool` was added and wired at that one call site). The other
two callers of `_rebuild_runtime_walkable_boundary` — generation and connector
commit — were already proven tolerant of one frame of latency by
`procgen_walkable_boundary_smoke.gd` (calls the function directly, then
`await physics_frame`) and `procgen_runtime_health_smoke.gd` (two
`await process_frame` after a connector resolve before checking rebuild
counts), so those two stay deferred.

Shadows turned out to already be internally coalesced:
`shadow_system.request_regenerate()` has its own `_regeneration_queued` guard
and `call_deferred("_regenerate_deferred")`, so the actual expensive redraw
was already at most once per frame regardless of how many times
`_refresh_shadows()` was called. The scheduler's own commit/telemetry calls
were the only thing still firing once per caller instead of once per actual
regenerate. The fix there is purely a bookkeeping correction (defer the
`commit()`/`_record_runtime_mutation()` calls to match when the real work
happens), not a behavior change to the shadow system itself.

Full wall-collision rebuild (`_rebuild_runtime_wall_collision`) was
deliberately left untouched. It has exactly one call site in the entire
runtime (initial generation); `damage_wall_tile` and blocker
register/unregister already mutate collision incrementally
(`_spawn_runtime_wall_body` / `_remove_runtime_wall_body`) rather than calling
the full rebuild. There is no second producer to coalesce against, so
converting it to the deferred pattern would only add a frame of latency to
generation for zero measured benefit. This is a negative finding worth
recording explicitly rather than papering over with an unneeded refactor.

Topology (`commit_runtime_walkable_connector_plan`, the stuck-pocket repair
path) was also left as-is: its request+commit pair wraps the actual floor/wall
tile-authority write itself, not a derived recomputation, and both existing
call sites already batch everything they touch into one request/commit per
real logical mutation. There was nothing to cut over there.

## Validation

All run from `custodian/` after `git lfs checkout` (materialize already-cached
LFS objects, no network fetch) and a headless `--import` pass against a fresh
ephemeral worktree with no prior `.godot` cache:

- `procgen_derived_rebuild_scheduler_smoke.gd` — PASS (unit-level ledger logic, unchanged).
- `procgen_walkable_boundary_smoke.gd` — PASS (direct call + one `physics_frame`).
- `procgen_runtime_health_smoke.gd` — PASS (connector commit path, scheduler snapshot assertions).
- `ash_bell_threadway_causeway_smoke.gd` — PASS (failed once pre-fix on the pocket-claim synchronous-frontier check; passes after `flush_now`).
- `ash_bell_threadway_generation_contract_smoke.gd` — PASS, seeds=16.
- `runtime_wall_collision_compaction_smoke.gd` — PASS, 19 bodies / 443 shapes (matches M1's recorded baseline exactly).
- `procgen_stuck_pocket_smoke.gd` — PASS.
- `navigation_elevation_smoke.gd` — PASS.
- `compound_wall_smoke.gd`, `compound_road_wall_smoke.gd`, `procgen_authored_scene_authority_smoke.gd`, `procgen_road_surface_roles_smoke.gd` — PASS (adjacent wall/road/streaming coverage, run for breadth since they exercise wall-authority and streaming-reveal paths near this change).
- S1 quick benchmark (`procgen_performance_baseline_bench.gd`) — `determinism_ok=true`; both 48x48 seed-420777 runs produced fingerprint `1773840677`, identical to M1's recorded value, so the deterministic generation output is unchanged.

S1's scripted runtime-streaming case is the acceptance proof for the actual
cutover: its `derived_rebuild_scheduler` snapshot shows `shadows` and
`presentation` at 5 requested → 1 committed (4 coalesced) in that scenario,
versus M1's always-1:1 request:commit ratio. `navigation` shows its
pre-existing 2 requested → 1 committed. `walkable_boundary`, `collision`, and
`topology` were not exercised with a repeat in-batch caller by that specific
scripted scenario (0 or 1:1), which is expected — not every system gets a
multi-producer collision in every scenario, and this does not indicate the
cutover is incomplete for those systems (walkable_boundary's coalescing is
exercised by the connector/health smoke instead, just not inside the S1
benchmark's scripted path).

Moment Forge was not run: this change only touches collision/boundary/shadow
rebuild cadence and scheduler bookkeeping, with no new or altered
animation/VFX/camera/audio timing, and the smoke suite above already falsifies
the correctness-sensitive paths.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: the first pass at deferring `_rebuild_runtime_walkable_boundary` broke `ash_bell_threadway_causeway_smoke.gd` because `_claim_isolated_world_overlook_pocket` is a synchronous API whose caller checks the physical frontier immediately; this was only caught by actually running the smoke, not by static reasoning about call sites.
- Root cause / contributing factors: three call sites share one rebuild function, and only one of the three needs a synchronous postcondition; nothing in the function signature flagged which.
- Prevention / pipeline improvement: added an explicit `flush_now: bool` parameter and a code comment at both the function and the one call site that needs it, so the next migration (M3 pause-aware streaming) has a visible precedent for "most callers tolerate deferral; the ones that don't say so explicitly."
- Tooling / docs drift discovered: none.
- Follow-up: none — M3 `procgen-pause-aware-streaming` is eligible next.
- What worked: running the full adjacent smoke set (not just the two most obviously relevant tests) caught the one real regression before closeout; the S1 benchmark's existing `derived_rebuild_scheduler` snapshot field required no new instrumentation to prove the coalescing acceptance criterion.
