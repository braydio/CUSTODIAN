# PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE summary

Workstream `procgen-archive-resolve-presentation-spine` (AR1).

**What landed**
- `ProcGenRevealPresentation` (`streaming/procgen_reveal_presentation.gd`), mounted as the `ArchiveResolveVeil` MultiMeshInstance2D in `proc_gen_map.tscn` (z 2: over terrain/walls, under actors). One batched node, fixed slot pool, no per-cell Nodes/Tweens/Timers/materials.
- States `requested -> committed-ready -> resolving -> settled`; only committed tiles resolve. Presentation clock advances only from unpaused procgen `_process`. Operator safety halo force-settles committed cells only. Lifecycle-derived `first_resolve` vs `reacquisition` identity with an ever-resolved consistency counter.
- `ProcGenTilemap` seams: request observation before lifecycle request/commit in both `_queue_chunk_for_reveal` and `_reveal_chunk_immediately`; immediate reveal now reports through `_on_streaming_tile_committed` (same adapter as queued commits, M4 counts unchanged); unload observed after disposal; reset in `_prepare_streaming_reveal`; `archive_resolve` block in runtime health.
- `archive_resolve_enabled=false` is the oracle: no veil, commits settle immediately.

**Validation**: new `procgen_reveal_presentation` smoke (mutation-checked: removing immediate-path request observation fails it). Passing: pause_aware_streaming, chunk_lifecycle, chunk_payload_cache, distant_chunk_unload, runtime_health, candidate_materializer_parity, region_frame; S1 quick `determinism_ok=true`; `git diff --check`.

**Not done / notes**: no renderer capture (aesthetic approval deferred to AR2). Slot capacity defaults to 8192; overflow fails open and is counted (`overflow_count`). Tuning knobs (starts/frame, duration, halo, color) live on the veil node. Paired `review-procgen-archive-resolve-presentation-spine` should now be claimable.

## Reminder

Ran on `agent/procgen-archive-resolve-presentation-spine` in a separate worktree. Switch the main checkout back to `main` (or your previous branch).
