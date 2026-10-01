# PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-distant-chunk-unload`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-chunk-payload-cache`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Enable bounded distant chunk unload/reload using the proven lifecycle/cache without losing authoritative world mutations or causing visible traversal churn.
- Completion boundary: PROVISIONAL ONLY until M5 lands and its cache/lifecycle interaction is measured. Do not implement production unload from this blocked packet. Before returning to `ready`, re-derive unload eligibility, hysteresis, disposable presentation/runtime state, reload restoration, mutation-overlay persistence, acceptance, and validation from live reviewed M4 + landed M5.
- Current measured state: Production unload is still disabled via `ProcGenTilemap.streaming_unload_distant_chunks = false`; current cleanup lives in `ProcGenTilemap._unload_chunk`. M4 is in progress and M5 is deliberately blocked, so there is still no reviewed lifecycle/cache basis for safe DORMANT -> UNLOADED -> reload behavior. The existing runtime wall, road decal, foliage, macro-presentation, navigation, and mutation-overlay cleanup/rebuild interactions must be re-measured after M5 rather than assumed.
- Evidence: current `custodian/game/world/procgen/proc_gen_tilemap.gd` streaming config, `_update_streaming_chunks`, `_unload_chunk`, `_refresh_macro_streaming_visibility`; `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`; blocked M5 packet; M4 lifecycle packet/review; M2 derived rebuild scheduler.
- Task-specific authority: Reviewed M4 lifecycle plus landed M5 cache once they exist; current interest/reveal semantics and runtime mutation authority.
- Work surface: Intentionally not locked while blocked. After M5, re-derive the production unload policy inside `custodian/game/world/procgen/streaming/` against the landed lifecycle/cache owner, with `proc_gen_tilemap.gd` reduced to disposal/rebuild adapters only where still necessary. Exact hysteresis/config/API must come from measured M5 state.
- Change: None while blocked. Refresh this same packet after M5 rather than creating M6_v2.
- Preserve: Player-visible continuity, world mutation persistence, ingress/road/terrain semantics, collision/nav correctness near the active area, authoritative semantic residency.
- Non-goals: No implementation before refresh; no semantic world-data eviction; no save-system changes; no renderer batching.
- Acceptance: Not implementation-ready. Replace after M5 with measured unload/reload, hysteresis/no-thrash, node/memory reduction, mutation-persistence, presentation parity, and scheduler gates.
- Validation: Not implementation-ready. Refresh after M5 with a focused unload/reload/mutation-persistence smoke plus existing M3 lifecycle, runtime wall collision compaction, road/macro presentation, navigation/runtime-health, candidate materializer, and S1 runtime evidence.
- Task overrides: `none`
- Deferred: Runtime lane convergence and D-lane extraction remain after a reviewed production unload implementation.

## Handoff

- Next action: Do not claim. Refresh against live main only after M5 is complete and any required review/correction is closed.
- Best starting files: landed M4 lifecycle authority, landed M5 cache authority, current `_unload_chunk`, mutation scheduler, S1 runtime metrics.
- Blockers or open questions: Blocked intentionally on M5 evidence.
