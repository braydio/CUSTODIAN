# PROCGEN CHUNK PAYLOAD CACHE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-chunk-payload-cache`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-chunk-lifecycle-state-machine`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Cache immutable/reusable per-chunk derived payloads so reveal and future unload/re-reveal do not recompute stable chunk semantics.
- Completion boundary: PROVISIONAL ONLY until reviewed M4 lands. Before this packet may return to `ready`, re-derive its exact cache owner, payload boundary, invalidation rules, acceptance, and focused validation from the reviewed `procgen-chunk-lifecycle-state-machine` implementation. Do not implement M5 from this blocked packet.
- Current measured state: M4 `procgen-chunk-lifecycle-state-machine` is now actively claimed on `agent/procgen-chunk-lifecycle-state-machine`; no landed canonical lifecycle owner exists on `main` yet. Current live streaming authority is still `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd` plus `ProcGenTilemap`'s shared `_streaming_reveal_queue`. Therefore cache ownership, lifecycle-record shape, PREPARED/DORMANT semantics, and invalidation seams remain unknowable until M4 lands and its paired review passes.
- Evidence: active M4 packet/claim; `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/streaming/` current directory; M4 paired review packet; detailed procgen roadmap.
- Task-specific authority: The reviewed M4 lifecycle authority once landed; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; immutable accepted-world semantics and runtime mutation overlays.
- Work surface: Intentionally not locked while blocked. The eventual cache belongs under `custodian/game/world/procgen/streaming/` adjacent to the landed M4 lifecycle owner and M3 pause-aware streaming authority, with only narrow adapters in `proc_gen_tilemap.gd`. Exact filename/API and which payloads are cacheable must be re-derived from reviewed M4, not guessed now.
- Change: None while blocked. After reviewed M4, refresh this packet in place rather than creating M5_v2. The refreshed contract must build payloads from authoritative accepted-world state, separate immutable cache content from mutable destruction/blocker overlays, and avoid duplicating lifecycle or M3 queue authority.
- Preserve: Visible output, mutation persistence, exact wall destruction/runtime blockers, road/macro/foliage determinism, M3 pause behavior, M4 lifecycle ownership, memory safety.
- Non-goals: No implementation before refresh; no production unload yet; no generic global cache; no renderer batching.
- Acceptance: Not implementation-ready. Refresh against reviewed M4 first, then replace this field with measurable cache hit/miss, parity, mutation-persistence, and lifecycle integration gates.
- Validation: Not implementation-ready. The refreshed packet must name focused lifecycle/cache falsification first and only then directly affected streaming/mutation/S1 regressions.
- Task overrides: `none`
- Deferred: Production distant unload follows only after reviewed cache correctness.

## Handoff

- Next action: Do not claim. After `review-procgen-chunk-lifecycle-state-machine` passes, re-audit live main and rewrite this same packet to current V2 ready/auto quality.
- Best starting files: reviewed M4 packet/summary/lifecycle authority; M3 streaming authority; live reveal consumers and S1 streaming metrics.
- Blockers or open questions: Blocked intentionally on reviewed M4 evidence.
