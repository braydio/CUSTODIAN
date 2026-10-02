# REVIEW: PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-distant-chunk-unload`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-distant-chunk-unload`
- Locks: `procgen-streaming, navigation-runtime`
- Review: `none`
- Review target workstream: `procgen-distant-chunk-unload`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- Reviewed main: `5ff71747fa3cb01988621abaa0071ca6b8657167`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that M6's production-default distant residency eviction is actually safe under the landed runtime, especially where M6 deliberately decoupled painted presentation from gameplay collision/navigation and where its closing summary claims proof beyond what the focused smoke currently asserts.
- Reviewed implementation acceptance: Reuse the archived M6 packet's full 15-item Acceptance contract. Treat as blocking any eviction of non-DORMANT/in-flight chunks; unbounded unload burst; cache eviction that changes semantic identity; wall collision disappearing only because presentation unloads; NavigationSystem losing previously revealed unloaded walkability or gaining UNSEEN cells after a real rebuild; foliage identity/blocker/collision loss; runtime mutation repainting an UNLOADED chunk prematurely; stale payload resurrection; road/macro reload parity loss; unsafe portal/ingress/spawn eviction; production default enabled without adequate runtime proof; or deterministic fingerprint regression.
- Current measured state: M6 landed at `9fe8cd4d6` and production `streaming_unload_distant_chunks` now defaults `true`. `ProcGenChunkResidencyPolicy` owns deterministic DORMANT-only farthest-first eviction candidates; `ProcGenTilemap` drains at most `streaming_unload_chunks_per_frame=1` by default and revalidates state/distance/protection immediately before unload. `_unload_chunk()` now erases painted Floor/Walls, hides existing foliage nodes, removes road decals, evicts the M5 payload, forces M4 UNLOADED and refreshes macro visibility without destroying canonical semantics or runtime wall bodies. Runtime wall cleanup now consults `_generated_wall_cells`, and NavigationSystem can source graph cells from `ProcGenTilemap.get_runtime_navigation_floor_cells()` plus `is_runtime_navigation_walkable()`. M5 `evict_chunk()` drops cached membership/records without revision churn. The focused M6 smoke is substantial but does **not** directly instantiate/rebuild NavigationSystem after unload, does **not** prove real portal/compound-ingress/world-ingress protected anchors, and does **not** directly assert foliage blocker/trunk-collision/cluster metadata parity. Acceptance item 15's explicit before/after painted-cell/cache/road residency accounting is also not captured in one bounded traversal fixture; cache-record eviction and road parity are instead split across existing regressions.
- Evidence: `PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md`; archived M6 packet; `custodian/game/world/procgen/streaming/procgen_chunk_residency_policy.gd`; `procgen_chunk_lifecycle.gd`; `procgen_chunk_payload_cache.gd`; live `proc_gen_tilemap.gd` functions `_update_streaming_chunks`, `_drain_residency_eviction`, `_is_chunk_eviction_valid`, `_protected_streaming_chunks`, `_effective_unload_distance`, `_unload_chunk`, `_sync_runtime_wall_collision_with_visible_walls`, `get_runtime_navigation_floor_cells`, `is_runtime_navigation_walkable`, foliage hide/show and M5 mutation setters; `custodian/game/systems/core/systems/navigation_system.gd`; `procgen_distant_chunk_unload_smoke.gd`; `procgen_chunk_payload_cache_smoke.gd`; `procgen_road_semantics_v2_smoke.gd`; `procgen_macro_presentation_smoke.gd`; S1 fingerprint `1773840677`.
- Review focus: Review only the M6 seams. Do not re-audit general procgen. Trace (1) residency policy selection/order/cancellation; (2) lifecycle VISIBLE/DORMANT/UNLOADED/re-request; (3) protected-anchor derivation; (4) concrete unload effects; (5) M5 per-chunk eviction and stale-record identity; (6) collision retention and genuine-destruction cleanup; (7) NavigationSystem's provider-aware rebuild path; (8) foliage hide/show identity + gameplay blocker/collision state; (9) unloaded runtime mutation; (10) road/macro reload parity; (11) runtime telemetry and actual residency reduction; (12) no SimulationInterestManager retune or second reload queue.
- Known proof questions: Do **not** infer these from the M6 summary. Verify each independently:
  1. A real `NavigationSystem` instance/rebuild after a chunk is UNLOADED still contains the previously revealed walkable cells and excludes an otherwise-canonical UNSEEN chunk.
  2. Real portal endpoint chunks, compound ingress chunks, and world-ingress clearance chunks are protected from production eviction, not merely the spawn chunk.
  3. Foliage unload/reload preserves exact node identity **and** kind/cluster metadata, trunk collision/body state and runtime blocker registration.
  4. One bounded traversal evidence case records before/after painted Floor/Wall counts, M5 cached membership/record counts and road-decal count, proving the residency drop while canonical generated counts and gameplay authority stay constant.
  5. The default-on path remains bounded under the production `16x16` chunk size and does not sneak an all-resident scan into per-frame drain.
- Correction threshold: A concrete behavioral defect is `blocking_defect`. Any required M6 acceptance proof above that is missing or only asserted in prose is `evidence_gap`; do not downgrade it merely because the implementation looks plausible. Non-behavioral telemetry naming/comment polish may be non-blocking. If any blocking defect or material evidence gap remains, author `procgen-distant-chunk-unload-review-corrections-1` plus its paired re-review and leave S7 open.
- Focused validation: Run `procgen_distant_chunk_unload` first. Then run `procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke.gd`, and `procgen_authored_scene_authority_smoke.gd`. Inspect whether those existing tests actually close the four Known proof questions; if not, report an evidence gap rather than treating “green suite” as sufficient. Run S1 quick and require `determinism_ok=true` with fingerprint `1773840677` unless main has an independently justified new baseline. Run packet/review-pairing/docs/manifest checks and `git diff --check`.
- Acceptance: Produce a findings-first independent review receipt on current live main. A clean/non-blocking-only pass closes S7 and makes D1/D2/D3 refresh-eligible. Any blocking defect/material evidence gap creates the bounded correction/re-review pair and leaves D1-D3 blocked. The review does not itself modify M6 runtime code.
- Non-goals: No D1-D3 implementation; no Region Frame/Archive Resolve implementation; no GenerationGrid; no renderer batching; no simulation-tier retune; no generic pooling; no unrelated agent-tooling repair.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Search Budget

Start from exactly:

- `PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md`
- archived `PROCGEN_DISTANT_CHUNK_UNLOAD.md`
- `streaming/procgen_chunk_residency_policy.gd`
- `streaming/procgen_chunk_lifecycle.gd`
- `streaming/procgen_chunk_payload_cache.gd`
- the named M6 functions in `proc_gen_tilemap.gd`
- `NavigationSystem._build_navigation_graph()` and `_is_walkable()`
- `procgen_distant_chunk_unload_smoke.gd`
- the exact regressions named above

Do not begin with repo-wide search. Expand only when a focused test or ownership trace points to a missing caller.

## Review Findings Format

Use stable IDs:

- `R0-01`, `R0-02`, ...
- class: `blocking_defect | evidence_gap | non_blocking_issue | optional_improvement`
- exact file/function/test evidence
- why it violates or satisfies the archived M6 acceptance contract
- smallest correction workstream if material

Do not reproduce broad code summaries when there are no findings.

## Handoff

- Next action: Review complete with findings. Claim `procgen-distant-chunk-unload-review-corrections-1` to resolve `R0-01`-`R0-05` on the archived M6 packet, then its paired `review-procgen-distant-chunk-unload-review-corrections-1`.
- Outcome: Not a clean pass. All four Known Proof Questions were genuine evidence gaps (not yet independently proven), and code review of the per-frame eviction drain found one real blocking defect: `_drain_residency_eviction()` forces an unthrottled full resident-window presentation resync on every eviction-frame instead of coalescing on the same cadence ordinary reveal already uses. S7 remains open; D1-D3 stay blocked until a clean/non-blocking-only cycle-1 re-review.
- Blockers or open questions: None. See the archived M6 packet's `## Independent Review` receipt for full finding detail.
