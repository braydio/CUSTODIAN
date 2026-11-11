# Procgen Chunk Lifecycle State Machine (M4) — Closing Summary

M3 fixed pause-aware tile-level PREPARE/COMMIT but left chunk-level
bookkeeping exactly as it had been for years: two dictionaries,
`_revealed_chunks` and `_queued_chunks`, that were never truthful.
`_queue_chunk_for_reveal()` marked `_queued_chunks[chunk]=true`, immediately
called `_get_chunk_tiles()` to enumerate the chunk's tiles, and
`_get_chunk_tiles()` itself marked `_revealed_chunks[chunk]=true` and erased
the queued entry -- all before a single tile had actually been painted. A
chunk could sit with zero committed tiles and still read as "revealed" to
anything that asked, including `_is_tile_currently_visible()`, which decided
whether a runtime mutation (e.g. wall destruction creating new floor) should
paint immediately. This task's job was to replace that with one real state
machine and fix the fallout.

## What landed

`ProcGenChunkLifecycle` (`custodian/game/world/procgen/streaming/procgen_chunk_lifecycle.gd`)
is a plain `RefCounted` state machine, one record per chunk coordinate:

```
UNSEEN -> QUEUED -> PREPARED -> REVEALING -> VISIBLE -> DORMANT -> UNLOADED
```

- `request(chunk, planned_tile_count)`: `UNSEEN -> QUEUED`, or straight to
  `VISIBLE` for a zero-content chunk so it can never churn/requeue.
  Idempotent against anything already QUEUED or further along.
- `note_prepared(chunk)` / `note_committed(chunk)`: called once per tile
  event. `QUEUED -> PREPARED` only once every planned tile is prepared with
  none yet committed; first commit moves `QUEUED`/`PREPARED -> REVEALING`;
  the last commit moves `-> VISIBLE`.
- `sync_active_window(center_chunk, radius)`: `VISIBLE -> DORMANT` for
  resident chunks that fall outside the active radius, and back on
  re-entry. Presentation is never touched by this transition either
  direction -- M4 never removes a DORMANT chunk's painted tiles.
- `force_unload(chunk)`: the narrow debug/test-only path to `UNLOADED`
  (the only call site is `_unload_chunk`, itself only reachable when
  `streaming_unload_distant_chunks` is explicitly enabled, which stays
  false by default).
- Every illegal call (progress reported against a chunk that was never
  requested, `force_unload` on a non-resident chunk) is rejected,
  `push_error`'d, and counted -- never silently coerced.

`ProcGenTilemap` keeps owning tile/world semantics and the shared
`_streaming_reveal_queue`; its chunk adapters (`_queue_chunk_for_reveal`,
`_reveal_chunk_immediately`, `_update_streaming_chunks`, `_unload_chunk`,
`_prepare_streaming_reveal`) now register/query state through the lifecycle
authority instead of the two old dictionaries, which are gone entirely.
`_get_chunk_tiles()` lost its two side-effecting lines and is now pure
enumeration, safe to call speculatively.

`ProcGenPauseAwareStreaming` (M3) gained two optional, narrow progress
callbacks -- `on_tile_prepared`/`on_tile_committed`, each taking one
`Vector2i` tile -- fired right after its own PREPARE/COMMIT bookkeeping.
`ProcGenTilemap` is the only thing that wires them, converting tile to
chunk and forwarding to the lifecycle authority. Neither M3 nor M4 know
about each other's internals; M3 still owns the only tile queue.

`_is_tile_currently_visible()` was rewritten to query canonical painted-cell
TileMap state directly (`floor_tilemap.get_cell_source_id(tile) != -1 or
walls_tilemap.get_cell_source_id(tile) != -1`) instead of chunk membership.
This is exact in every lifecycle state without any new per-tile bookkeeping:
a REVEALING chunk can have some tiles committed and some not, and only the
TileMap itself can answer that for one specific tile.

## A design correction mid-task

My first pass made `UNLOADED` sticky -- once a chunk force-unloaded, a later
`request()` would be ignored, reasoning that "M6 owns the real
`DORMANT -> UNLOADED -> reload` policy" meant M4 shouldn't support re-entry
at all. That broke an existing, already-required regression:
`procgen_road_semantics_v2_smoke.gd` legitimately force-unloads a chunk and
immediately re-reveals it to prove a ruined-road decal survives the round
trip -- a test that passed before this change and must keep passing. The
fix: separate the reload *mechanism* (re-requesting an unloaded chunk
correctly restarts its lifecycle) from the reload *policy* (deciding
when/whether that should happen, which really is M6's). `is_requested()`
now treats `UNLOADED` as not-currently-requested, and `request()` on an
`UNLOADED` chunk starts a fresh record. Production still never exercises
this path at all (`streaming_unload_distant_chunks` stays false), so nothing
about default behavior changed -- only the state machine's own internal
correctness under the existing debug/test seam.

## Fixing two other external consumers of the removed dictionaries

Two more places read `_revealed_chunks`/`_queued_chunks` via dynamic
property access that the earlier packet audit had already flagged by
reference count but is worth stating plainly:

- `custodian/tools/validation/procgen_performance_baseline_bench.gd` (part
  of the required S1 quick benchmark) read `_revealed_chunks.size()` for its
  `revealed_peak`/`revealed_before`/`revealed_after` metrics.
- `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`
  (the structured snapshot both the benchmark and other tooling consume)
  read both dictionaries directly for `revealed_chunk_count`/
  `queued_chunk_count`.

Both now call new public `ProcGenTilemap` API --
`get_resident_chunk_count()` (VISIBLE + DORMANT) and
`get_pending_chunk_count()` (QUEUED + PREPARED + REVEALING) -- which are the
exact semantic equivalents of what the old dictionaries represented.

## Validation

All run from `custodian/` after a headless `--import` pass against this
fresh ephemeral worktree:

- `procgen_chunk_lifecycle_smoke.gd` (new) -- PASS. A pure unit-contract
  pass proves: idempotent `request()`; `QUEUED -> PREPARED -> REVEALING ->
  VISIBLE` in order; zero-content chunks resolving straight to VISIBLE and
  never churning; `DORMANT`/`VISIBLE` active-window exit and re-entry;
  illegal-call detection and rejection with no state coercion; deterministic
  snapshot counts and coordinate-stable debug ordering. A live
  `ProcGenTilemap` integration pass then proves: speculative
  `_get_chunk_tiles()` calls never mutate lifecycle state; the immediate-
  radius spawn chunk reaches VISIBLE synchronously during generation; an
  outer chunk is left QUEUED immediately after generation (before any frame
  ticks); a zero-content far-outside chunk resolves to VISIBLE with no
  queue/commit; a tile-budgeted chunk visibly passes through REVEALING with
  exact per-tile visibility truth along the way; moving the active window
  away marks a resident chunk DORMANT with zero presentation change, and
  moving back returns it to VISIBLE with zero duplicate tile commits; and
  the debug-only `debug_force_unload_chunk` reaches UNLOADED and genuinely
  erases that tile's visibility.
- `procgen_pause_aware_streaming_smoke.gd` -- PASS, unchanged.
- `procgen_candidate_promotion_smoke.gd` (manifest id
  `procgen_candidate_materializer_parity`) -- PASS, restored to required
  regression status per the packet (its old obsolete strict streamed-floor
  assertion is confirmed gone).
- `procgen_runtime_health_smoke.gd`, `procgen_macro_presentation_smoke.gd`,
  `procgen_walkable_boundary_smoke.gd` -- PASS.
- `procgen_road_semantics_v2_smoke.gd` -- PASS after the one required fix
  (see below).
- `runtime_wall_collision_compaction_smoke.gd` -- PASS, `bodies=19
  shapes=443`, identical to the M1/M2-recorded baseline.
- `ash_bell_threadway_causeway_smoke.gd` -- PASS, proving the M2 `flush_now`
  synchronous exception (which this task never touches) still holds.
- S1 quick benchmark -- `determinism_ok=true`, 48x48 seed-420777 fingerprint
  `1773840677`, identical to M1/M2/M3. No deterministic-output regression.
- `run_validation.py --changed --json` -- 25 tests selected by file
  ownership, all 25 pass (two full sequential runs were needed: the first
  surfaced the harness-classification issue below, fixed, then a clean
  re-run confirmed all 25 green).
- `git diff --check` -- clean.

### Required fix inside `procgen_road_semantics_v2_smoke.gd`

The test previously wrote `tilemap._revealed_chunks[chunk] = true` directly
to fake residency before exercising `_unload_chunk`/re-reveal. With the
dictionary gone this would not even parse. Replaced with a real call to
`tilemap.call("_reveal_chunk_immediately", chunk)` immediately before the
existing `_unload_chunk` call -- the same adapter the test already calls for
its second (re-reveal) step, now also used to legitimately establish
residency for the first step, rather than hand-poking removed state.

### Harness classification issue, not a real failure

The new smoke's unit-contract pass deliberately triggers
`ProcGenChunkLifecycle`'s `push_error` calls to prove illegal transitions
fail loudly (required by the packet). `run_validation.py` classifies any
stderr line containing `ERROR:` as fatal regardless of the script's own exit
code or printed `PASS`, so the harness-run failed even though the test
itself passed cleanly every time it was run directly. Fixed by adding two
narrowly-scoped patterns to `custodian/tools/validation/
known_headless_warnings.json` (`known_chunk_lifecycle_illegal_transition_test`,
`known_chunk_lifecycle_force_unload_illegal_test`) matching only this
class's own illegal-transition message prefix, then re-verified both the
single-test harness run and the full 25-test changed-file sweep green.

Moment Forge was not run: this is lifecycle/bookkeeping and telemetry work
with no new or altered animation/VFX/camera/audio timing, and the smoke
suite above (including the live integration pass with real presentation
checks) already exercises the correctness-sensitive paths.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: (1) the first UNLOADED design was sticky/terminal, which broke the already-required `procgen_road_semantics_v2_smoke.gd`'s unload/re-reveal round trip; (2) the validation harness fails a test on any `ERROR:` stderr line regardless of exit code, so the new smoke's intentional illegal-transition `push_error` calls needed a harness-level allowlist fix before the full suite could go green; (3) `run_validation.py --changed` has no dry-run/preview mode (`--list` ignores selection), so confirming the fix required two full sequential sweeps.
- Root cause / contributing factors: (1) conflated "M6 owns the reload policy" (a non-goal about decision-making) with "M4 must not support the reload mechanism at all" (an unwarranted, narrower reading). (2) the known-warnings registry has no per-test-scoped "this exact error is this test's own expected assertion" concept, only a global message-pattern allowlist.
- Prevention / pipeline improvement: (1) fixed in scope -- `is_requested()`/`request()` treat UNLOADED as not-currently-requested, matching the old erase-based behavior's re-entry capability while still letting `get_state()` observe UNLOADED as a real transient state immediately after `force_unload`. (2) fixed in scope by adding the two narrow patterns to `known_headless_warnings.json`.
- Tooling / docs drift discovered: `run_validation.py`'s known-warning registry matches by global message pattern with no way for a test to declare "this specific error is my own expected assertion output," which risks masking an unrelated real bug that happens to hit the same message prefix in some other future test. Recorded in the task packet's Execution Feedback as well.
- Follow-up: `manual-follow-up` on the known-warnings registry's lack of per-test scoping; this is the same general category of pipeline/tooling gap as M3's dispatcher-claim-gate and landing-race findings, intentionally not fixed inside this procgen runtime workstream.
- What worked: deriving tile-level visibility truth directly from canonical TileMap paint state (instead of inventing new per-tile bookkeeping) made the hardest acceptance point -- truthful visibility during partial REVEALING -- fall out for free; and keeping M3's tile queue storage untouched (shared by reference, same pattern as that task) meant the chunk-lifecycle integration needed zero changes to M3's own public contract beyond two additive optional callbacks.
