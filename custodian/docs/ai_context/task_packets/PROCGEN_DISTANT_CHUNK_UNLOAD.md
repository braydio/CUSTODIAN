# PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-distant-chunk-unload`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-chunk-payload-cache`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7911a70deb326b8e3abbe5a46446a4b79cb031f7`
- Goal: Enable bounded distant chunk unload/reload using the proven lifecycle/cache without losing authoritative world mutations or causing visible traversal churn.
- Completion boundary: PROVISIONAL ONLY until M5 lands and its paired MR5 review passes. Do not implement production unload from this blocked packet. After reviewed M5, re-derive unload eligibility, hysteresis, disposable presentation/runtime state, reload restoration, cache-retention/eviction behavior if any, mutation-overlay persistence, acceptance, and validation from the actual landed lifecycle + cache APIs.
- Current measured state: Production unload is still disabled via `ProcGenTilemap.streaming_unload_distant_chunks = false`; current erasure lives in `ProcGenTilemap._unload_chunk`. M4 and MR4 are complete. M5 has now been re-derived to `ready/auto` but is not implemented yet; its paired review `review-procgen-chunk-payload-cache` is the required architecture/correctness gate. Therefore there is still no landed reviewed cache basis for safe production `DORMANT -> UNLOADED -> reload`, hysteresis, cache retention, or mutation-persistent reload policy.
- Evidence: reviewed M4/MR4 summaries and lifecycle owner; ready M5 packet and paired MR5 packet; current `custodian/game/world/procgen/proc_gen_tilemap.gd` streaming config, `_update_streaming_chunks`, `_unload_chunk`, `_refresh_macro_streaming_visibility`; M3 pause-aware streaming owner; M2 derived rebuild scheduler.
- Task-specific authority: Reviewed M4 lifecycle plus the reviewed M5 cache authority once MR5 passes; current interest/reveal semantics, runtime mutation authority, and `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`.
- Work surface: Intentionally not locked while blocked. After MR5, re-derive the production unload policy inside `custodian/game/world/procgen/streaming/` against the exact landed lifecycle/cache owners, with `proc_gen_tilemap.gd` reduced to disposal/rebuild adapters only where still necessary. Exact unload owner filename, hysteresis/config, cache-retention/eviction behavior, and reload scheduling must come from measured reviewed M5 state.
- Change: None while blocked. Refresh this same packet after MR5 rather than creating an M6_v2 workstream.
- Preserve: Player-visible continuity, world mutation persistence, ingress/road/terrain semantics, collision/nav correctness near the active area, authoritative semantic residency.
- Non-goals: No implementation before refresh; no semantic world-data eviction; no save-system changes; no renderer batching.
- Acceptance: Not implementation-ready. Replace after MR5 with measured unload/reload, hysteresis/no-thrash, cache interaction, node/memory reduction, mutation-persistence, presentation parity, and scheduler gates.
- Validation: Not implementation-ready. Refresh after MR5 with focused unload/reload/cache/mutation-persistence proof plus the landed M5 cache smoke, M4 lifecycle, M3 pause streaming, runtime wall collision compaction, road/macro presentation, navigation/runtime-health, candidate materializer, and S1 runtime evidence.
- Task overrides: `none`
- Deferred: Runtime lane convergence and D-lane extraction remain after a reviewed production unload implementation.

## Handoff

- Next action: Do not claim. Refresh against live main only after `review-procgen-chunk-payload-cache` passes and any correction/re-review cycle is closed.
- Best starting files: reviewed M4 lifecycle authority, reviewed landed M5 cache authority/summary, current `_unload_chunk`, M3 queue owner, mutation scheduler, S1 runtime metrics.
- Blockers or open questions: Blocked intentionally on reviewed M5/MR5 evidence.
