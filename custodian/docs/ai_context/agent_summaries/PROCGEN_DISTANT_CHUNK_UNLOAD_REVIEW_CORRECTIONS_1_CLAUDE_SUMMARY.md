# PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1 summary

Workstream `procgen-distant-chunk-unload-review-corrections-1` closes `R0-01`..`R0-05`.

- **R0-01** `_drain_residency_eviction()` no longer flushes the resident-window resync per eviction-frame. `_process_streaming_reveal_queue()` accumulates the existing rebuild accumulator while a rebuild is pending and flushes on `streaming_visual_rebuild_interval_sec` (queue-drained flush now needs a reveal-owed flag or the interval).
- **R0-02..R0-05** `procgen_distant_chunk_unload_smoke.gd` gains: real `NavigationSystem` rebuild after unload, real portal-protected DORMANT far chunk never evicted, foliage kind/cluster/collision/blocker parity across unload and reload, and a before/after painted/cache/generated/road count fixture. New accessor `debug_get_foliage_entry_metadata()`.
- **Validation** focused smoke, parent regression list, and S1 quick (`determinism_ok=true`) all green; reinstating the direct flush fails the new R0-01 assertions. The R0-01 proof checks pending/interval behavior, not a per-frame sync call count.

## Reminder

This work ran on `agent/procgen-distant-chunk-unload-review-corrections-1` in a separate worktree. Switch back to `main` (or your previous branch) in the main checkout for other work.
