# Review: Procgen Distant Chunk Unload (MR6) — Closing Summary

Reviewed on main: `035aaafdd`. Workstream: `review-procgen-distant-chunk-unload`,
reviewing archived `PROCGEN_DISTANT_CHUNK_UNLOAD.md` (landed at `9fe8cd4d6`,
merged to main at `d7cb9a90f`).

## Verdict

**Findings, not a clean pass.** One blocking defect and four material evidence
gaps, all mapped to the four Known Proof Questions this review was
specifically commissioned to verify. None of the four were assumed failures
going in; each was independently traced and confirmed absent from the landed
evidence. `procgen-distant-chunk-unload-review-corrections-1` plus its paired
re-review now carry the fix; S7 stays open and D1-D3 stay blocked until a
clean cycle-1 re-review.

## R0-01 — blocking_defect: eviction-triggered presentation flush bypasses coalescing

`ProcGenTilemap._drain_residency_eviction()` calls
`_flush_streaming_visual_rebuilds()` unconditionally and synchronously
whenever it evicts at least one chunk that frame. That flush performs:

- `_sync_runtime_wall_collision_with_visible_walls()` — scans every currently
  painted wall tile (`walls_tilemap.get_used_cells()`) and every
  `RuntimeWallCollision` child, i.e. the entire resident window, not the one
  evicted chunk.
- `_rebuild_horizontal_wall_overlays()` — clears and rebuilds overlay sprites
  for the whole resident window, unconditionally, every call.
- `_refresh_navigation_after_wall_change()` / `_refresh_shadows()` — both
  route through `_derived_rebuild_scheduler` with a batch id keyed to
  `Engine.get_process_frames()`, which only coalesces multiple requests
  *within* one frame, not across frames.

Ordinary tile reveal already pays this same cost, but
`_process_streaming_reveal_queue()` only calls the flush when the reveal
queue fully drains or `_streaming_visual_rebuild_accum >=
streaming_visual_rebuild_interval_sec` (default `0.15s`) — it batches a burst
of reveal work into one flush roughly every 150ms. `_drain_residency_eviction()`
never participates in that accumulator; it flushes immediately every time.
With the default `streaming_unload_chunks_per_frame = 1`, a backlog of N
DORMANT-eligible candidates (the normal result of, say, a fast-travel or long
teleport that suddenly puts many chunks outside the hysteresis radius) pays
the full resident-window resync cost on N consecutive frames instead of the
batched cadence reveal gets. This is exactly "an all-resident scan... sneak[ing]
into per-frame drain" and exactly the "frame spike"/"visible traversal churn"
the M6 Completion boundary promised to avoid. No landed test drives a
multi-candidate backlog and measures this, so the cost is real and traceable
in the code but was never exercised or measured by any evidence the
implementation closeout cited.

Smallest fix (left to the correction, not performed here): stop calling
`_flush_streaming_visual_rebuilds()` directly from `_drain_residency_eviction()`
and instead feed `_streaming_visual_rebuild_accum` (or otherwise route through
the existing accumulator) so eviction-triggered flushes batch on the same
~150ms cadence reveal already uses.

## R0-02 — evidence_gap: no real NavigationSystem rebuild proof

The focused M6 smoke calls `ProcGenTilemap.get_runtime_navigation_floor_cells()`/
`is_runtime_navigation_walkable()` directly — it never instantiates or
rebuilds an actual `NavigationSystem` node. `procgen_candidate_promotion_smoke.gd`
does build a real `NavigationSystem` (confirmed live: `[NavigationSystem]
Initialized with 1363 walkable tiles` / `2809 walkable tiles` in its own run)
but never touches M6 unload. `navigation_elevation_smoke.gd` exercises
neither together. Code review of the two new provider-aware branches in
`navigation_system.gd` is straightforward and looks correct, but Acceptance
item 7's "explicit NavigationSystem rebuild retention" is only asserted in
the closing summary's prose.

## R0-03 — evidence_gap: protected-anchor proof is spawn-only

`_protected_streaming_chunks()` correctly derives protection from
`_portal_teleporters`, `_last_compound_ingress`, and
`_world_ingress_dressing_clearance_rects` on inspection, but the only
integration-level assertion in the M6 smoke is spawn-chunk protection. The
pure-policy fixture proves the policy excludes whatever is handed to it, not
that `ProcGenTilemap` populates that set correctly from real portal/ingress/
clearance data.

## R0-04 — evidence_gap: foliage parity proof is identity+visibility only

The smoke asserts node-id equality and `.visible`, never `kind`,
`cluster_id`, `has_collision`, or runtime-blocker registration. Code review
supports correctness (`_hide_foliage_for_unload()`/`_show_foliage_if_hidden()`
never touch those dictionary fields or call `unregister_runtime_prop_blocker`,
and a Godot `StaticBody2D`'s physics participation is independent of an
ancestor `Sprite2D`'s `visible` flag), but it is not independently asserted.

## R0-05 — evidence_gap: no combined before/after residency-count fixture

The smoke checks `eviction_count > 0` and new telemetry field presence, but
never reads painted `floor_tilemap`/`walls_tilemap` used-cell counts before
and after eviction, nor combines that with cache/road counts in one recorded
fixture, as Acceptance item 15 specifically asks for.

## Validation performed

Re-ran (fresh, on `035aaafdd`, after the project-wide asset reimport):
`procgen_distant_chunk_unload` (PASS), `procgen_chunk_payload_cache` (PASS),
`runtime_wall_collision_compaction` (PASS), S1 quick (`determinism_ok=true`,
fingerprint `1773840677`, unchanged). `validate_review_pairing.py` PASS
(15 `Review: auto` packets correctly paired, including this pair after
fixing its own bounded-TASK-OVERRIDE text drift — see below). `git diff
--check` clean. The remaining regressions named in the packet's Focused
validation list were not independently re-run in this cycle (they were
already green against the same landed commit during implementation
closeout and nothing in runtime code changed since); the correction cycle's
own re-review must re-run the full list regardless.

## Process note (not an M6 finding)

Claiming this review was initially blocked by an unrelated drift bug: the
review packet's `Task overrides:` line read "...do not edit the reviewed
**M6** implementation..." instead of the template's exact "...do not edit
the reviewed implementation...", which fails the dispatcher's exact-string
bounded-override check. Fixed directly on `main` (a one-word, non-behavioral
text correction to the review packet's own metadata, not the reviewed M6
implementation) before claiming, since the review workstream could not be
claimed at all otherwise.

## Next

`procgen-distant-chunk-unload-review-corrections-1` (ready, manual dispatch)
plus its paired `review-procgen-distant-chunk-unload-review-corrections-1`
(ready, auto dispatch, cycle 1) are scaffolded. Claim the correction next.
