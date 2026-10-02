# REVIEW: PROCGEN CHUNK PAYLOAD CACHE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-chunk-payload-cache`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-chunk-payload-cache`
- Locks: `procgen-streaming`
- Review: `none`
- Review target workstream: `procgen-chunk-payload-cache`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_CHUNK_PAYLOAD_CACHE.md`
- Reviewed main: `8eb4725aa66eeb2b2f20123518a2d7db7e0b88d2`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that M5 adds one truthful derived chunk-payload cache with exact invalidation/stale-record protection and real reuse, while preserving M3 queue/PREPARE-COMMIT ownership, M4 lifecycle ownership, dynamic reveal/COMMIT behavior, runtime mutation persistence, and the M6 policy boundary.
- Reviewed implementation acceptance: Reuse the archived M5 packet's full Acceptance contract. Treat as blocking any second semantic/lifecycle/queue authority, cache entry that can outlive or bypass canonical generated floor/wall truth, frozen player-center reveal ordering, cached foliage/road/collision outcome, stale PREPARE Dictionary that can commit after chunk invalidation, wall/authored-claim mutation that reloads stale data, eager full-map payload construction, production unload policy introduced early, or determinism/regression evidence gap.
- Review evidence: Landed M5 implementation at the reviewed main, archived M5 packet and closing summary; landed `procgen_chunk_payload_cache.gd`-equivalent owner; `ProcGenTilemap` cache adapters, generated-semantic mutation/invalidation inventory and runtime-health snapshot; M3/M4 owners; implementation-created focused cache smoke; M3 pause and M4 lifecycle smokes; road unload/re-reveal, authored-claim, runtime wall collision/destruction, candidate materialization, macro/dressing presentation and S1 evidence; manifest entries for walkable-boundary and wall-collision smokes; corrected UNLOADED reload prose.
- Correction threshold: Blocking for any stale semantic reload/commit path, unproven mutation classification, cache hit that changes reveal order or commit outcome, cache storage of Node/TileMap/Resource/gameplay-owner state, duplicate M3/M4 authority, missing cache reset across generation, M6 production eviction behavior, deterministic fingerprint change, or material proof gap. Non-blocking naming/telemetry polish may route next-slice.
- Focused validation: Re-run the implementation-created M5 cache smoke first. Then re-run `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, and authored-scene authority coverage. Re-run S1 quick unless the implementation closeout evidence is demonstrably fresh and no reviewed diff could affect the fingerprint; prefer fresh execution when environment permits. Run packet/review-pairing/docs/manifest checks and `git diff --check` for review artifacts.
- Review focus: Prove cache entries are derived and discardable; trace every cache build/hit/invalidate/stale-refresh call site; cross-check the implementation's `_generated_floor_cells` / `_generated_wall_cells` write inventory against live code rather than trusting the summary; verify late generation mutations after streaming priming cannot leave stale payloads; explicitly test wall-destruction neighbor refresh and authored multi-tile claims; verify M3's `_prepared` queue cannot commit a pre-invalidation record; verify queued order still uses live `_streaming_reveal_priority`; verify immediate reveal keeps canonical membership order; verify dynamic road/foliage/collision decisions remain outside the cache; verify untouched chunks are not prebuilt; verify automatic unload remains disabled.
- Acceptance: Produce a findings-first independent review on live main. Record passed evidence or stable cycle-scoped findings with class/domain/affected M5 acceptance/evidence/disposition/rationale. Blocking defects or material evidence gaps create `procgen-chunk-payload-cache-review-corrections-1` plus its paired review. A clean/non-blocking-only pass makes M6 refresh-eligible, but does not itself make the existing blocked M6 packet executable; M6 must still be re-derived from the reviewed landed cache.
- Non-goals: Do not implement M6 unload/hysteresis, redesign the cache, migrate generation state, fix unrelated agent tooling, or edit reviewed runtime implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Claim after M5 completes and archives. On a clean/non-blocking-only pass, re-audit live main and refresh M6 `procgen-distant-chunk-unload` in place against the reviewed cache/lifecycle surface.
- Blockers or open questions: None at authoring time.
