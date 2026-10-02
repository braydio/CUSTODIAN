# REVIEW: PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-distant-chunk-unload`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-distant-chunk-unload`
- Locks: `procgen-streaming, navigation-runtime`
- Review: `none`
- Review target workstream: `procgen-distant-chunk-unload`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Reviewed main: `5c38717f1c3f9605a9991968e4b2a12de69391a9`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that M6 enables bounded production chunk residency shedding without making painted presentation authoritative for collision/navigation/simulation, without losing runtime mutations, and without introducing a second lifecycle/cache/reload mechanism.
- Reviewed implementation acceptance: Reuse the archived M6 packet's full Acceptance contract. Treat as blocking any eviction of non-DORMANT/in-flight chunks; unbounded unload burst; cache eviction that changes semantic revision; unloaded wall collision disappearing solely because presentation is erased; navigation losing previously revealed unloaded walkable cells after rebuild or gaining UNSEEN cells; foliage node reroll/recreation or blocker loss; runtime wall/authored mutation repainting an UNLOADED chunk early; road/macro/reload parity loss; protected portal/spawn/ingress eviction; production default enabled without focused evidence; or determinism/fingerprint regression.
- Review evidence: Landed M6 closing summary + archived packet; `procgen_chunk_residency_policy.gd`; M4 lifecycle owner; M5 cache owner + eviction API; ProcGenTilemap residency/unload/reload/navigation-provider seams; NavigationSystem's provider-aware rebuild; focused M6 smoke + manifest entry; M3/M4/M5 regressions; runtime wall/navigation/foliage/road/macro/authored-mutation evidence; S1 quick.
- Correction threshold: Blocking for any gameplay authority derived from painted residency, stale or duplicated lifecycle/cache/reload state, mutation loss/resurrection, unbounded frame work, unsafe instant-travel landing, missing nav/collision proof, or material evidence gap. Minor naming/comment/telemetry polish may be non-blocking only when behavior and ownership are unambiguous.
- Focused validation: Run the implementation-created M6 smoke first. Then rerun `procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke.gd`, and authored-scene authority coverage. Run S1 quick fresh unless the implementation closeout is demonstrably from the exact reviewed main and no review artifact can affect runtime. Run packet/review-pairing/docs/manifest checks and `git diff --check`.
- Review focus: Trace only the exact M6 seams, not the whole procgen tree: residency-policy candidate selection/budget; lifecycle DORMANT/UNLOADED transitions; cache `evict_chunk` reverse-index cleanup; `_unload_chunk` concrete disposal; runtime-wall collision cleanup semantics; NavigationSystem provider-aware cell source; foliage hide/show identity; streaming paint guard for the named M5 mutation setters; protected anchor set; runtime-health telemetry. Verify the implementation did not solve safety by silently increasing unload distance to map scale or by retuning SimulationInterestManager.
- Acceptance: Produce a findings-first independent review on live main. Blocking defects/material evidence gaps create `procgen-distant-chunk-unload-review-corrections-1` plus its paired review. A clean/non-blocking-only pass closes S7 and makes D1-D3 refresh-eligible; it does not itself rewrite those packets.
- Non-goals: Do not implement D1-D3, GenerationGrid, renderer batching, simulation-tier changes, generic pooling, or unrelated agent-tooling fixes. Do not edit the reviewed M6 implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Search Budget

Start only from the archived M6 packet/summary and the files it names. Do not re-run a broad repo archaeology. Expand only if a focused failing test identifies an uncovered authority/caller.

## Handoff

- Next action: Claim after M6 completes/archives. On clean/non-blocking-only pass, mark S7 complete and refresh D1/D2/D3 in place from the reviewed live architecture.
- Blockers or open questions: None at authoring time.
