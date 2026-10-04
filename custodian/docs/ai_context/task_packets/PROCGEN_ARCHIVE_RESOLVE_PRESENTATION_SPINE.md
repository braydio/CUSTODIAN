# PROCGEN ARCHIVE RESOLVE PRESENTATION SPINE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-presentation-spine`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime, procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-presentation-spine`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `7d553787ae92bad652f92ee8214b8da990115bb2`
- Authoring chat: `not-recorded`
- Goal: Add the presentation-only Archive Resolve spine that hides chunk cadence behind one continuous deterministic world-space reveal frontier without changing generation, PREPARE/COMMIT, collision, navigation, residency, Region Frame, or semantic authority.
- Completion boundary: Done when one focused `ProcGenRevealPresentation` owner consumes the reviewed request/commit/unload seams, covers requested cells before authoritative pixels can visibly pop, settles only committed cells, maintains an always-resolved Operator safety halo, renders unresolved/resolving cells through one batched flat diagnostic veil, distinguishes first-resolution from reacquisition, freezes on pause through its own presentation clock, can be disabled without changing streaming behavior, and makes 16x16 chunk cadence visually unobservable while streaming/gameplay fingerprints remain unchanged.
- Current measured state: On `main@1c88f456`, M3 still owns the shared tile request/PREPARE/COMMIT queue through `ProcGenPauseAwareStreaming`; M4 `ProcGenChunkLifecycle` still owns `UNSEEN -> QUEUED/PREPARED/REVEALING/VISIBLE/DORMANT/UNLOADED`; M5 owns cache residency; M6 owns DORMANT candidate selection/revalidation and `_unload_chunk()` presentation/cache disposal. The landed M6C1 path batches eviction-triggered wall/overlay/navigation/shadow resyncs through the existing reveal cadence. Queued request enters through `_queue_chunk_for_reveal()`; immediate-radius request/commit enters through `_reveal_chunk_immediately()`; queued authoritative COMMIT executes `_commit_tile_reveal_record()` before `ProcGenPauseAwareStreaming` invokes `_on_streaming_tile_committed(tile)`; immediate commit currently calls `_reveal_tile(tile)` then `_chunk_lifecycle.note_committed(chunk_pos)` directly; unload erases painted Floor/Walls, hides foliage, removes road decals, evicts the M5 payload, forces lifecycle `UNLOADED`, and leaves canonical semantics/collision/navigation authority intact. No reveal-presentation owner or veil exists. RF1 is a separate permanent exterior-frame consumer and must not be absorbed here. MR6R1 has passed with 0 blocking defects and 0 material evidence gaps; the reviewed M6 request/commit/unload seam is now the stable AR1 dependency.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; `custodian/game/world/procgen/proc_gen_tilemap.gd` (`_ready`, `_process`, `_queue_chunk_for_reveal`, `_reveal_chunk_immediately`, `_on_streaming_tile_committed`, `_commit_tile_reveal_record`, `_unload_chunk`); `streaming/procgen_pause_aware_streaming.gd`; `streaming/procgen_chunk_lifecycle.gd`; `streaming/procgen_chunk_payload_cache.gd`; `streaming/procgen_chunk_residency_policy.gd`; `proc_gen_map.tscn`; `procgen_distant_chunk_unload_smoke.gd`; refreshed RF1 packet for the permanent-underlay separation.
- Task-specific authority: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed M3-M6 streaming contracts; `PROCGEN_REGION_FRAME_PROFILES.md` only for the rule that permanent exterior depth belongs to Region Frame rather than Archive Resolve.
- Work surface: Add one focused owner at `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`; integrate one batched world-space veil under `proc_gen_map.tscn` at a presentation layer that covers generated terrain/dressing but remains below actors/markers; add only narrow observation/delegation in `proc_gen_tilemap.gd`; add focused validation/manifest ownership, aggregate observability, and only docs made stale by implementation. Do not move request/PREPARE/COMMIT, lifecycle, cache, residency, generation, collision, navigation, or Region Frame state into the new owner.
- Change: Give the presentation owner only `requested`, `committed-ready`, `resolving`, `settled`, and generation/session-scoped `ever-resolved` presentation state. A tile may enter presentation state only through existing streaming callbacks. The owner must never infer or mutate chunk lifecycle independently.
- Change: Unify commit observation through the existing `_on_streaming_tile_committed(tile)` façade adapter: queued M3 commits already arrive there after `_commit_tile_reveal_record()`; immediate-radius reveal should report each successful `_reveal_tile(tile)` through the same adapter instead of separately calling lifecycle `note_committed`. The adapter continues forwarding M4 progress and additionally notifies presentation. Do not add a second COMMIT authority or modify `ProcGenPauseAwareStreaming` ownership.
- Change: Observe request before any authoritative immediate commit. In both `_queue_chunk_for_reveal()` and `_reveal_chunk_immediately()`, capture the chunk's pre-request lifecycle state, obtain deterministic cached tile membership, notify presentation of the requested tile set, then call the existing lifecycle request/enqueue or immediate commit path. `UNLOADED` pre-request state marks reacquisition; all other first requests use first-resolution. The presentation owner may also retain its own session `ever-resolved` set as a consistency check, but it may not override lifecycle.
- Change: Observe unload after the existing visual/cache disposal path without changing its semantics. The presentation owner removes active veil/frontier slots for that chunk and retains only minimal session reacquisition memory; it must not veto, delay, select, or authorize unload.
- Change: Reset presentation from the existing streaming reset/generation path before initial chunk priming. The initial immediate-radius request still creates veil coverage before painting, then commit observation makes those tiles eligible to settle. AR1 does not add the stronger ingress choreography reserved for AR3.
- Change: Implement the diagnostic veil as one pooled/batched world-space primitive, preferably a single `MultiMeshInstance2D`/equivalent with reusable slots and per-instance transform/color/custom data. Do not create per-cell Nodes, Tweens, Timers, materials, or scene instances. Slightly overlap the 32 px semantic cell footprint so cracks/checkerboard seams do not expose the grid. Keep this AR1 material visually flat/diagnostic; graphite/dither/brass/phase-misalignment treatment belongs to AR2.
- Change: Drive settlement from a pause-safe presentation clock advanced only during ordinary unpaused procgen processing. Only `committed-ready` cells may resolve. Use deterministic world-cell identity/order with no unseeded randomness. Bound ordinary settlement work per frame and force-settle already-committed cells inside an exported/default-small safety halo around the Operator; the halo may accelerate presentation only and may never reveal an uncommitted cell. Final numeric art timing remains AR2/AR3 tuning, but AR1 must expose stable configuration rather than embedding magic values across integration code.
- Change: Expose a compact snapshot with at least effect enabled, requested/uncommitted count, committed-ready count, active resolving/frontier count, settled count, forced-safety-settle count, first-resolve count, reacquisition count, presentation time, and active batched-instance count. Telemetry is aggregate/transition-level only; no per-cell or per-frame log spam.
- Change: When Archive Resolve is disabled, requested/commit/unload observation remains safe but no veil may hide committed world; committed presentation settles immediately and all M3-M6 behavior/counters remain unchanged. This disabled path is the regression oracle.
- Preserve: Exact M3 PREPARE/COMMIT ordering/pause semantics; M4 lifecycle counts/transitions; M5 cache identity/invalidation; reviewed M6 unload/reacquisition and coalesced rebuild behavior; generated floor/wall/road/biome/surface/route/collision/navigation fingerprints; immediate-radius deterministic tile iteration; queued reveal priority; RF1 Region Frame/permanent exterior ownership; candidate/final materialization behavior; Operator/UI readability.
- Non-goals: No final Archive Resolve shader art; no semantic pre-echo; no ingress/spawn pulse choreography; no audio; no particles; no full-screen post-process; no chunk-size/radius/reveal-budget retune; no road/landmark/biome authority changes; no Region Frame changes; no per-cell object graph; no M6 residency/cache/lifecycle redesign. Do not fold the RF1-carried M6 proof-hardening work into AR1.
- Acceptance: (1) In flat diagnostic mode, a production-size traversal cannot reveal 16x16 chunk rectangles or one-chunk catch-up cadence; unresolved coverage is continuous over the visible requested frontier. (2) Request observation precedes immediate and queued visible commit exposure; no authoritative committed tile can appear for a frame before its veil record exists when the effect is enabled. (3) Presentation never settles a tile before authoritative COMMIT. (4) Immediate and queued commits both use the same post-commit presentation adapter while preserving exact M4 committed counts/transitions. (5) A configurable safety halo force-settles only already-committed nearby cells and keeps the Operator from reaching an invisible committed blocker/hazard. (6) A previously settled then M6-unloaded chunk reacquires with deterministic `reacquisition` identity; first-request chunks remain `first_resolve`; unload selection/counters are unchanged. (7) Pause freezes presentation time/phase and resume continues without a time jump; M3 PREPARE may still progress while paused exactly as before, but no presentation settlement occurs behind pause. (8) Disabling the effect yields ordinary committed streaming with zero active veil instances and identical gameplay/streaming fingerprints. (9) The active frontier is one batched/shared-material path with no per-cell Node/Tween/Timer/material creation and bounded reusable slot capacity. (10) Same generation seed + same committed tile sequence + same fixed-tick player trajectory yields identical presentation order/identity. (11) Aggregate snapshot/counters are bounded and do not emit per-cell logs. (12) RF1/permanent underlay remains independently owned and visible outside Archive Resolve; AR1 never veils permanent exterior depth.
- Validation: Create one focused AR1 smoke and register it once the path exists. It must falsify request-before-commit coverage on both queued and immediate paths, committed-only settlement, shared commit-adapter lifecycle parity, safety-halo committed-only forcing, unload/reacquisition identity, pause freeze with M3 PREPARE parity, deterministic ordering, disabled-effect fallback, batched-instance/no-per-cell-object behavior, and semantic/streaming fingerprint parity. Run that first. Then run existing `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, candidate materializer parity, S1 quick, packet/review-pairing/docs/manifest checks, and `git diff --check`. Visual evidence economy: structured counters and a deterministic frontier trace come first; retain at most one short diagnostic traversal capture proving the absence of visible chunk rectangles and correct actor-over-veil layering. Aesthetic approval is deferred to AR2.
- Task overrides: `none`
- Deferred: AR2 owns graphite/soot world-space dissolve, dither, brass/amber registration edge and phase misregistration. AR3 owns bounded semantic pre-echo, stronger initial spawn/ingress resolve and final reacquisition timing polish.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`; `custodian/tools/validation/procgen_reveal_presentation_smoke.gd` (mutation-checked: dropping immediate-path request observation fails it); packet regression suites and S1 quick (`determinism_ok=true`) green. No renderer capture was taken; visual approval is deferred to AR2.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `none`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `review-procgen-archive-resolve-presentation-spine`

## Handoff

- Next workstream: `review-procgen-archive-resolve-presentation-spine`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Complete AR1, then let ARR1 claim automatically from a fresh reviewer context.
- Blockers or open questions: None. No unresolved AR1 architecture choice remains.
