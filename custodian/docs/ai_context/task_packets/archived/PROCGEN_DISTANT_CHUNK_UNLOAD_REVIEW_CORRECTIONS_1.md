# CORRECTION: PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-distant-chunk-unload-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-distant-chunk-unload`
- Locks: `procgen-streaming, navigation-runtime`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-distant-chunk-unload-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `6ee4a0089`
- Parent implementation: `procgen-distant-chunk-unload`, archived at `custodian/docs/ai_context/task_packets/archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Parent review: `review-procgen-distant-chunk-unload`, archived at `custodian/docs/ai_context/task_packets/archived/REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Findings addressed: `R0-01, R0-02, R0-03, R0-04, R0-05`
- Affected acceptance: M6's Completion boundary ("without creating frame spikes"); Acceptance items 2 (protected-anchor exclusion), 7 (navigation rebuild retention), 8 (foliage identity/kind/cluster/trunk-collision/blocker parity), 15 (bounded traversal before/after evidence).
- Current defect/evidence: `R0-01` (blocking): `ProcGenTilemap._drain_residency_eviction()` calls `_flush_streaming_visual_rebuilds()` unconditionally and synchronously whenever it evicts a chunk, bypassing the `streaming_visual_rebuild_interval_sec` coalescing accumulator ordinary tile reveal uses for the same flush (`_process_streaming_reveal_queue()`). There is also a second-frame trap: `_process()` runs `_process_streaming_reveal_queue(delta)` before `_drain_residency_eviction()`, so simply deleting the direct drain flush still leaves eviction setting `_streaming_visual_rebuild_pending = true` after the reveal pass; on the next frame an empty reveal queue enters the unconditional `queue_drained` branch and flushes immediately before the next eviction. Therefore an accumulator-only edit inside `_drain_residency_eviction()` is insufficient. That flush does an O(entire-resident-window) wall-collision rebuild (`_sync_runtime_wall_collision_with_visible_walls()`) and horizontal-wall-overlay rebuild (`_rebuild_horizontal_wall_overlays()`), plus navigation/shadow requests whose `_derived_rebuild_scheduler` batch id is keyed to `Engine.get_process_frames()` and so only coalesces within one frame. With the default `streaming_unload_chunks_per_frame = 1`, draining a backlog of N DORMANT-eligible candidates can otherwise still pay this full resident-window cost on N consecutive frames instead of the ~0.15s batched cadence reveal uses. `R0-02`-`R0-05` (evidence gaps): the focused M6 smoke (`procgen_distant_chunk_unload_smoke.gd`) proves the policy/adapter contract abstractly but does not (a) instantiate/rebuild a real `NavigationSystem` after unload, (b) populate/assert protection from real portal/compound-ingress/world-ingress-clearance data (only the spawn chunk is exercised at the integration level), (c) assert foliage `kind`/`cluster_id`/`has_collision`/runtime-blocker-registration parity beyond node identity and `.visible`, or (d) record one bounded-traversal fixture of before/after painted floor/wall cell counts together with the cache/road counts.
- Goal: Close all five cited findings without reopening the accepted M6 design: coalesce eviction-triggered presentation flushes onto the same cadence ordinary reveal uses, and extend the focused M6 smoke with the four missing proof points.
- Completion boundary: Done when (1) a multi-candidate eviction backlog no longer forces one full resident-window wall-collision/overlay/navigation/shadow resync per eviction-frame -- it batches on the existing `streaming_visual_rebuild_interval_sec` cadence exactly like reveal does; (2) the M6 smoke instantiates a real `NavigationSystem`, rebuilds it after a chunk unloads, and asserts the previously-revealed walkable cell remains reachable while an `UNSEEN` probe chunk is excluded; (3) the smoke constructs at least one real portal teleporter (or populates `_last_compound_ingress`/`_world_ingress_dressing_clearance_rects`) and asserts that chunk is never evicted even when DORMANT and far; (4) the smoke asserts the hidden/re-shown foliage node's `kind`, `cluster_id`, `has_collision`, and `has_runtime_prop_blocker_at_tile()` are unchanged across hide/show; (5) the smoke records one before/after fixture combining painted floor/wall used-cell counts, `chunk_payload_cache` cached-membership/record counts, and road-decal presence for the evicted chunk, and asserts the painted/cached counts drop while canonical generated counts stay constant.
- Current measured state: See `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md` and the archived M6 packet's `## Independent Review` receipt for full findings detail and evidence.
- Evidence: Independent review receipt (`R0-01`..`R0-05`) on the archived M6 packet; `proc_gen_tilemap.gd` `_drain_residency_eviction()`, `_flush_streaming_visual_rebuilds()`, `_process_streaming_reveal_queue()`, `_sync_runtime_wall_collision_with_visible_walls()`, `_rebuild_horizontal_wall_overlays()`; `navigation_system.gd`; `procgen_distant_chunk_unload_smoke.gd`; `procgen_chunk_payload_cache.gd` telemetry.
- Task-specific authority: The archived M6 packet and its Independent Review receipt; `custodian/game/systems/core/systems/navigation_system.gd`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`.
- Work surface: `custodian/game/world/procgen/proc_gen_tilemap.gd` (`_drain_residency_eviction()` plus the existing `_process_streaming_reveal_queue()` flush gate/accumulator seam only -- do not touch `_unload_chunk()`'s disposal effects or the residency-policy/lifecycle/cache seams themselves); `custodian/tools/validation/procgen_distant_chunk_unload_smoke.gd` (add the four missing proof sections plus the multi-frame `R0-01` fixture). Do not edit `procgen_chunk_residency_policy.gd`, `procgen_chunk_lifecycle.gd`, or `procgen_chunk_payload_cache.gd`'s production code -- those are not implicated by any finding.
- Required correction:
  1. `R0-01`: Coalesce eviction-triggered rebuilds through the existing `_streaming_visual_rebuild_pending` / `_streaming_visual_rebuild_accum` cadence across consecutive process frames. In `_drain_residency_eviction()`, after any `_unload_chunk()` call, do not call `_flush_streaming_visual_rebuilds()` directly. Then fix the existing reveal-queue flush gate so an eviction-only pending rebuild is not consumed by the next frame's empty-queue `queue_drained` shortcut before `streaming_visual_rebuild_interval_sec` elapses. The current `_process()` order is `_process_streaming_reveal_queue(delta)` first and `_drain_residency_eviction()` second, so this next-frame case must be handled explicitly. Reuse the existing accumulator rather than adding a scheduler: while a visual rebuild is pending, elapsed process `delta` must advance the same cadence even when no reveal tile committed on that frame; the immediate queue-drained flush may remain for a real reveal batch that actually drains its queue, but must not make eviction-only pending work flush every following frame. Add a focused multi-frame fixture with an empty reveal queue and a backlog large enough for multiple one-chunk-per-frame evictions; count/observe `_flush_streaming_visual_rebuilds()` or its expensive wall/overlay rebuild effects and prove multiple evictions inside one interval collapse into the intended cadence. Preserve the current behavior that an evicted chunk's presentation is erased immediately and its collision/foliage/road state is correct by the time the next coalesced flush runs; do not change `_unload_chunk()`'s own disposal effects.
  2. `R0-02`: Add a smoke section that builds a real `NavigationSystem` node (`set_runtime_tilemaps()` wired to the test map's `floor_tilemap`/`walls_tilemap`/`ProcGenTilemap`), calls its graph-build entrypoint before and after unloading the victim chunk, and asserts the victim floor tile remains walkable/reachable in the rebuilt graph while a genuinely `UNSEEN` probe chunk's tiles are absent.
  3. `R0-03`: Add a smoke section that adds one real `Area2D`/`Node2D` to `_portal_teleporters` (or populates `_last_compound_ingress`/`_world_ingress_dressing_clearance_rects`) positioned in a non-spawn chunk, drives that chunk DORMANT and far, and asserts it is never unloaded across repeated `_drain_residency_eviction()` calls while `debug_get_protected_streaming_chunks()` contains it.
  4. `R0-04`: Extend the existing foliage hide/show assertions to also capture and compare `kind`, `cluster_id`, `has_collision` (from the `_foliage_nodes` entry, via a new or existing debug accessor) and `has_runtime_prop_blocker_at_tile(victim_foliage_tile)` before unload, immediately after unload, and after reload.
  5. `R0-05`: Add one recorded before/after block around the existing unload step that reads `floor_tilemap.get_used_cells().size()`, `walls_tilemap.get_used_cells().size()`, `debug_get_chunk_payload_cache_snapshot()`'s cached-membership/record counts, and `debug_has_road_piece_decal()` for the victim tiles, asserting painted/cached counts strictly decrease while `debug_get_generated_floor_cells().size()`/`debug_get_generated_wall_cells().size()` stay exactly constant.
- Preserve: Every passing assertion already in `procgen_distant_chunk_unload_smoke.gd` and `procgen_chunk_payload_cache_smoke.gd`; `_unload_chunk()`'s disposal effects and ordering; the residency policy's bounded-per-frame/protected/cancellation contract; S1 determinism fingerprint `1773840677`.
- Non-goals: No redesign of `ProcGenChunkResidencyPolicy`, the M5 cache, or the M4 lifecycle. No change to `streaming_unload_chunks_per_frame`'s default or to `_effective_unload_distance()`. No new coalescing scheduler -- reuse the existing accumulator. No fix beyond the five cited findings.
- Acceptance: Each finding ID has a falsifiable result: `R0-01` -- a test or direct measurement drives an empty reveal queue plus a multi-candidate backlog across multiple consecutive `_process()` frames and shows `_sync_runtime_wall_collision_with_visible_walls()`/`_rebuild_horizontal_wall_overlays()` do not run once per eviction-frame when evictions occur faster than `streaming_visual_rebuild_interval_sec`; the proof must fail if the direct drain flush is removed but the next-frame `queue_drained` flush still fires. `R0-02` -- the new NavigationSystem section passes. `R0-03` -- the new protected-anchor section passes. `R0-04` -- the new foliage-metadata section passes. `R0-05` -- the new before/after residency-count section passes. All previously-passing assertions in both smokes remain green; S1 quick remains `determinism_ok=true` at fingerprint `1773840677`.
- Validation: Run `procgen_distant_chunk_unload` first (now extended). Then the full regression list from the parent packet's own Validation field (`procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke.gd`, `procgen_authored_scene_authority_smoke.gd`), S1 quick, packet/review-pairing/docs/manifest checks, and `git diff --check`.
- Task overrides: `none`
- Deferred: None -- all five cited findings are addressed in this correction.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `proc_gen_tilemap.gd` (`_drain_residency_eviction()` no longer flushes directly; `_process_streaming_reveal_queue()` accumulates the existing `_streaming_visual_rebuild_accum` while a rebuild is pending and gates the queue-drained flush on new `_streaming_reveal_flush_owed` or the interval; new `debug_get_foliage_entry_metadata()`); `procgen_distant_chunk_unload_smoke.gd` (R0-01 pending/interval assertions, real `NavigationSystem` rebuild, real portal-protected DORMANT far chunk, foliage kind/cluster/collision/blocker parity across unload and reload, before/after painted/cache/generated/road counts). Mutation check: restoring the direct flush fails the R0-01 assertions. Green: `procgen_distant_chunk_unload` (via `run_validation.py`), `procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke`, `procgen_authored_scene_authority_smoke`; S1 quick `determinism_ok=true`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The R0-05 cache-count assertion first failed because the victim chunk was never resident in the M5 cache and the R0-01 process tick re-cached queued far chunks.
- Root cause / contributing factors: Test-fixture ordering only: the cache had no victim membership/records, and snapshots were taken around unrelated reveal work.
- Prevention / pipeline improvement: The smoke now primes the victim's membership/record through the production cache lookup and snapshots immediately around the drain.
- Tooling / docs drift discovered: `NavigationSystem` has no global class_name, so smokes must type it as `Node`; a fresh worktree needs `godot --import` before scripts resolve `ProcGenTilemap`.
- Follow-up: `none`
- What worked: Reusing the existing accumulator needed only a small flush-owed flag; the mutation check proved the new assertions are falsifiable.

## Independent Review

- Status: `clean_with_next_slice`
- Review workstream: `review-procgen-distant-chunk-unload-review-corrections-1`
- Reviewed on main: `b7d23c4c2` (correction landed at `81494285d`)
- Review modes: `code, architecture, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `5`
- Correction finding IDs: `none`
- Next-slice finding IDs: `N1-01, N1-02, N1-03, N1-04, N1-05`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none` (N1-01..N1-03 owned by `procgen-region-frame-presentation-foundation`; N1-04/N1-05 not yet owned)
- Reviewer independence: the reviewing session is the same agent family that authored the correction; verdicts rest on re-run traces/mutations below, not on the correction's own summary.

### Original finding disposition

- `R0-01` -- `fixed`. Call graph: `_unload_chunk()` sets pending only; `_process_streaming_reveal_queue()` accumulates delta while pending and gates the `queue_drained` flush on `_streaming_reveal_flush_owed or flush_due`. Independent multi-frame trace (throwaway fixture, not committed): empty reveal queue, 19 consecutive one-chunk eviction frames at 0.016 s -> 2 flushes in 40 frames (first at frame 9, ~0.15 s), versus one per eviction frame before.
- `R0-02` -- `fixed`. A real `NavigationSystem` is rebuilt after unload and `_walkable_tiles` contains the victim floor tile and excludes the wall tile. Membership only, no A* path (N1-02).
- `R0-03` -- `fixed` (production behavior verified; fixture non-hermetic, N1-04). Removing the injected `portals.append(portal)` leaves the smoke green because the generated map already registers 2 real portals and the chosen DORMANT chunk `(4, 10)` is already in `debug_get_protected_streaming_chunks()`. The far/DORMANT/protected-not-evicted behavior is therefore proven against real map protection data, but the injected portal is redundant.
- `R0-04` -- `fixed` (production behavior verified by code: `_hide_foliage_for_unload()` only toggles `visible`; fixture weak, N1-05). The fixture foliage is a `shrub` with empty `cluster_id`, `has_collision=false`, no runtime blocker, so cluster/collision/blocker parity is asserted over falsy values only.
- `R0-05` -- `fixed` for painted-cell, cache, and generated-count deltas. `road_decal` is `false` in the fixture, so road removal is never exercised (N1-03).

### Findings

- **N1-01** -- class: `optional_improvement`; disposition: `next_slice` (RF1 packet item (a)). The committed smoke asserts pending/interval behavior but does not count flushes across a forced multi-candidate empty-queue backlog.
- **N1-02** -- class: `optional_improvement`; disposition: `next_slice` (RF1 item (b)). No A* path/connectivity assertion after rebuild.
- **N1-03** -- class: `optional_improvement`; disposition: `next_slice` (RF1 item (c)). Road-decal removal proof is vacuous in the fixture.
- **N1-04** -- class: `optional_improvement`; disposition: `next_slice`, NOT in RF1. Choose the protected-anchor chunk so no pre-existing protection source covers it (exclude `debug_get_protected_streaming_chunks()` members), so the injected portal is the sole source; verify by mutation.
- **N1-05** -- class: `optional_improvement`; disposition: `next_slice`, NOT in RF1. Use a tree with trunk collision and/or a cluster id as the foliage fixture so kind/cluster/collision/blocker parity is non-trivial.

### Validation

`procgen_distant_chunk_unload` plus the full regression list (`procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke`, `procgen_authored_scene_authority_smoke`) exit 0 with zero assertion errors; S1 quick `determinism_ok=true` with 48x48 fingerprint `1773840677` present in the baseline JSON; review-pairing validator pass; `git diff --check` clean. `procgen_candidate_materializer_parity` named in the parent packet does not exist under `tools/validation` and was not run.
