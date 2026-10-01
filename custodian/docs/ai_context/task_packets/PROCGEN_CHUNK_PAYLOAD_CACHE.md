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
- Reviewed main: `e6e5e5c9bb8b93d9df81f7cb9645a8d2d88cce56`
- Goal: Cache immutable/reusable per-chunk derived payloads so reveal and future unload/re-reveal do not recompute stable chunk semantics.
- Completion boundary: PROVISIONAL ONLY until reviewed M4 lands. Before this packet may return to `ready`, re-derive its exact cache owner, payload boundary, invalidation rules, acceptance, and focused validation from the reviewed `procgen-chunk-lifecycle-state-machine` implementation. Do not implement M5 from this blocked packet.
- Current measured state: M4 has been re-authored but has not yet landed/reviewed, so there is no live canonical chunk-lifecycle record or reviewed PREPARED/DORMANT contract on which a truthful cache design can depend. The previous packet falsely described chunk lifecycle as already explicit and therefore violated the current-measured-state rule.
- Evidence: `custodian/docs/ai_context/task_packets/PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md`; `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md`; current M3 authority in `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`; current reveal consumers in `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: The reviewed M4 lifecycle authority once landed; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; immutable accepted-world semantics and runtime mutation overlays.
- Work surface: Intentionally not locked while blocked. Expected domain remains focused streaming payload/cache types plus narrow adapters to existing foliage/road/macro/collision reveal consumers, but exact files/API must be re-measured after M4 review.
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
