# Procgen Pause-Aware Streaming (M3) — Closing Summary

M2 made walkable-boundary and shadow rebuilds batch, but explicitly deferred
pause semantics: `ProcGenTilemap`'s streaming-reveal work ran only inside its
own ordinary `_process`, which already stops entirely while
`SceneTree.paused` is true (PauseUI sets that flag; the node never opted into
a non-default `process_mode`). That already satisfied half the contract
(pausing freezes authoritative commits and never enqueues new player-driven
discovery) for free, but it also meant *nothing* — not even harmless,
non-authoritative preparation of work already queued before pause — could
advance while paused. This task's job was to add that other half without
touching the frozen half.

## What landed

`ProcGenPauseAwareStreaming` (`custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`)
is a small `Node` with `process_mode = PROCESS_MODE_ALWAYS`, added as a child
of `ProcGenTilemap`. It is the single owner of the PREPARE/COMMIT lifecycle:

- **PREPARE** (`_process`, gated on `get_tree().paused` internally — the only
  place in this change that intentionally keeps ticking while paused): pops a
  budgeted number of tiles off the shared, already-queued reveal list and
  converts each into an immutable `{tile, floor_data, wall_data}` record via
  a pure lookup Callable supplied by `ProcGenTilemap`. This never touches
  TileMap/collision/foliage/navigation state — it only looks up data that was
  already fixed deterministically at generation time.
- **COMMIT** (`drain_commit`, called from `ProcGenTilemap._process_streaming_reveal_queue`,
  which — unchanged from before this task — only runs while unpaused): applies
  prepared records first (FIFO, original order), then falls through to
  building+committing any remaining un-prepared queued tiles directly. This is
  the actual authoritative mutation (`floor_tilemap.set_cell`, foliage siting
  and spawn, wall collision spawn) and is byte-for-byte the same code the
  pre-M3 `_reveal_tile` ran, just split into a pure build step and a mutating
  commit step.

`ProcGenTilemap` keeps owning the shared `_streaming_reveal_queue` field and
all tile/world semantics; it was deliberately **not** migrated into the new
authority's own storage. The authority holds the exact same `Array[Vector2i]`
object by reference (shared, not copied), so `_queue_chunk_for_reveal` still
appends to the field other code and two existing validation scripts
(`procgen_performance_baseline_bench.gd`, `procgen_candidate_promotion_smoke.gd`)
already introspect via `map.get("_streaming_reveal_queue")`, with zero changes
needed to either of them. `ProcGenTilemap` was narrowed to integration/
delegation for this behavior: `_queue_chunk_for_reveal` calls `enqueue_many`,
`_process_streaming_reveal_queue` calls `drain_commit` (falling back to the
old inline loop only if the authority somehow failed to construct),
`_prepare_streaming_reveal` calls `reset()`, and `_refresh_navigation_after_wall_change`
now also checks `has_prepared()` so it doesn't force an immediate rebuild
while prepared-but-uncommitted work is still outstanding.

A second, explicit defense-in-depth guard was added directly to
`_update_streaming_chunks` (`if get_tree().paused: return`) even though the
outer `_process` gate already prevents it from running while paused — the
packet's "pausing must not enqueue new reveal work" requirement is strong
enough to want it provable locally, not just inherited from an outer gate
that something else could change later.

The authority also owns `requested`/`prepared`/`deferred`/`prepared_pending`/
`resumed`/`committed` counters, exposed via `get_snapshot()` and folded into
`get_runtime_health_snapshot()["pause_aware_streaming"]` for Observatory/
telemetry parity with the M2 scheduler snapshot. A resume transition is
recorded exactly once per pause episode that actually prepared something —
`_advance_prepare()` sets a pending flag directly whenever it prepares at
least one tile, and `ProcGenTilemap` consumes it exactly once the next time
its own (necessarily-unpaused) `_process` runs `_process_streaming_reveal_queue`.
This was deliberately designed to not depend on comparing this node's own
tick to its parent's tick ordering within a frame — an earlier draft tried
exactly that (tracking a `_was_paused` flag inside the authority's own
`_process` and inferring the transition from it) and it worked, but lagged
the resume event by one frame relative to the first commit because Godot
processes the parent (`ProcGenTilemap`) before this child in the same frame;
setting the flag directly from the only place that does real pause-time work
removes that dependency entirely.

## What was preserved untouched

- M2's explicit `flush_now` synchronous exception for
  `_claim_isolated_world_overlook_pocket` — not read, not referenced, not
  modified by this change at all.
- Normal (never-paused) streaming behavior: PREPARE only ever runs while
  `SceneTree.paused` is true, so `_prepared` stays empty for the entire
  unpaused lifetime of a session that never pauses, and `drain_commit`
  degrades to exactly the old inline build+commit loop in that case.
- M4/M5/M6 chunk-lifecycle/cache/unload semantics — not pre-implemented;
  `_prepared` records are plain dictionaries, not a second mutable
  chunk-state authority.

## Validation

All run from `custodian/` after a headless `--import` pass against this
fresh ephemeral worktree (no prior `.godot` cache):

- `procgen_pause_aware_streaming_smoke.gd` (new) — PASS. One scenario proves,
  in order: (1) across 6 paused ticks, floor topology, navigation completion
  count, walkable-boundary rebuild count, and wall rebuild count are all
  unchanged from the pre-pause baseline; (2) PREPARE's `prepared` counter
  advances for already-queued tiles while paused, with the queue+prepared
  total exactly conserved (no duplication or loss); (3) `committed` stays
  exactly at its pre-pause value for the entire paused window; (4) on resume,
  the first unpaused frame commits a positive amount bounded by
  `streaming_reveal_tiles_per_frame`, and the resume transition is recorded
  exactly once; (5) full drain takes multiple frames (not an unbounded
  single-frame burst) and ends with `requested == committed`; (6) the M2
  navigation scheduler's commit count after the drain is small relative to
  the number of frames drained, not one-per-tile, proving continued
  coalescing through the existing scheduler seam.
- `procgen_derived_rebuild_scheduler_smoke.gd` — PASS (unchanged ledger logic).
- `procgen_walkable_boundary_smoke.gd` — PASS.
- `procgen_runtime_health_smoke.gd` — PASS.
- `ash_bell_threadway_causeway_smoke.gd` — PASS (proves the M2 `flush_now`
  synchronous postcondition this task never touches still holds).
- S1 quick benchmark (`procgen_performance_baseline_bench.gd`) —
  `determinism_ok=true`, 48x48 seed-420777 fingerprint `1773840677`, identical
  to M1/M2's recorded value. No deterministic-output regression.
- `procgen_candidate_promotion_smoke.gd` — run informationally only, per this
  packet's explicit instruction not to treat it as a required gate (it has a
  documented, independent pre-existing streaming assertion issue unrelated to
  M3). It passed cleanly in this run.

Moment Forge was not run: this change is streaming-pipeline lifecycle/
bookkeeping with no new or altered animation/VFX/camera/audio timing, and the
smoke suite above already exercises the correctness-sensitive paths
(frontier freeze, collision/navigation publication freeze, bounded resume
drain, M2 coalescing).

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: claiming this packet was blocked before any implementation could start — `dispatch.py`'s structural validation-reference gate rejects a ready/auto packet whose `Validation` field names a script that doesn't yet exist on `origin/main`, but this packet's own `Work surface` required authoring exactly that script (`procgen_pause_aware_streaming_smoke.gd`) as part of the implementation, producing a claim deadlock. A second packet (`asset-handoff-bundle-installer-v1`) is blocked by the identical pattern today, confirming it's systemic. Separately, the new smoke's first two draft iterations had false failures from test-harness gaps, not implementation bugs: `ProcGenTilemap._process()` only does per-frame streaming work when its parent is literally named `"ProcGenRuntime"` (`_is_attached_to_runtime_world`), and the pre-pause baseline must be captured after generation's own immediate-chunk `call_deferred` navigation/boundary/shadow flush settles, comparing cumulative counters as deltas rather than against an absolute zero.
- Root cause / contributing factors: the claim-gate's path-existence check has no allowance for a path a ready packet's own `Work surface` declares it will create — it treats "new validation file this task will author" the same as "stale/renamed path," which is the case it was actually built to catch.
- Prevention / pipeline improvement: fixed in scope for this workstream only, by pre-seeding an honest, intentionally-failing placeholder stub for the exact missing path directly on `main` (commit `bbecf6b3e`, explicitly approved by the user before pushing) to satisfy the gate, then replacing it with the real smoke inside this workstream. The gate's underlying behavior is unchanged and will reproduce for the next packet shaped this way.
- Tooling / docs drift discovered: `validate_packet_validation_references` (`custodian/tools/agent/task_packet_contract.py`) should exempt paths a ready packet's own `Work surface`/`Validation` text identifies as new-to-this-task, instead of requiring them to pre-exist before the packet implementing them can be claimed. Recorded in this packet's `Execution Feedback` as well.
- Follow-up: manual-follow-up — a dispatcher-maintainer decision is needed on how to distinguish "new file this packet will create" from "stale/renamed path" in that gate; `asset-handoff-bundle-installer-v1` remains blocked by it today.
- What worked: keeping `_streaming_reveal_queue` as a real, unmoved field (shared by reference with the new authority) instead of migrating its storage meant both pre-existing external introspection points needed zero changes; splitting `_reveal_tile` into a pure build step and a mutating commit step reused the exact pre-M3 logic verbatim, which is most of why normal unpaused streaming and the S1 fingerprint came out unchanged on the first real attempt.
