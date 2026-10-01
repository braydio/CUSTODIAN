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
- Reviewed main: `97a470fd99f8577ab6e929327d255c71f440778d`
- Goal: Enable bounded distant chunk unload/reload using the proven lifecycle/cache without losing authoritative world mutations or causing visible traversal churn.
- Completion boundary: PROVISIONAL ONLY until M5 lands and its cache/lifecycle interaction is measured. Do not implement production unload from this blocked packet. Before returning to `ready`, re-derive unload eligibility, hysteresis, disposable presentation/runtime state, reload restoration, mutation-overlay persistence, acceptance, and validation from live reviewed M4 + landed M5.
- Current measured state: Production `streaming_unload_distant_chunks` is false. M4 lifecycle has not yet landed and M5 is now explicitly refresh-gated, so the old packet's claim that lifecycle/cache already provide a safe unload basis is not current truth.
- Evidence: current `proc_gen_tilemap.gd` `_unload_chunk` path and unload config; blocked M5 packet; re-authored M4 packet/review; detailed procgen optimization roadmap.
- Task-specific authority: Reviewed M4 lifecycle plus landed M5 cache once they exist; current interest/reveal semantics and runtime mutation authority.
- Work surface: Intentionally not locked while blocked. Expected domain remains streaming policy/config plus unload/reload adapters, but exact owner/API must be re-measured after M5.
- Change: None while blocked. Refresh this same packet after M5 rather than creating M6_v2.
- Preserve: Player-visible continuity, world mutation persistence, ingress/road/terrain semantics, collision/nav correctness near the active area, authoritative semantic residency.
- Non-goals: No implementation before refresh; no semantic world-data eviction; no save-system changes; no renderer batching.
- Acceptance: Not implementation-ready. Replace after M5 with measured unload/reload, hysteresis/no-thrash, node/memory reduction, mutation-persistence, presentation parity, and scheduler gates.
- Validation: Not implementation-ready. Refresh after M5 with focused unload/reload proof before broader streaming/mutation/S1 validation.
- Task overrides: `none`
- Deferred: Runtime lane convergence and D-lane extraction remain after a reviewed production unload implementation.

## Handoff

- Next action: Do not claim. Refresh against live main only after M5 is complete and any required review/correction is closed.
- Best starting files: landed M4 lifecycle authority, landed M5 cache authority, current `_unload_chunk`, mutation scheduler, S1 runtime metrics.
- Blockers or open questions: Blocked intentionally on M5 evidence.
