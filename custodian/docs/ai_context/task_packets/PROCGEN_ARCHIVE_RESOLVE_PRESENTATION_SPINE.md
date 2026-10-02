# PROCGEN ARCHIVE RESOLVE PRESENTATION SPINE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-presentation-spine`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-distant-chunk-unload`
- Locks: `procgen-runtime, procgen-presentation`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `1e525e8c9c545b90760c22ccb512645a043ebe34`
- Goal: Add the presentation-only Archive Resolve spine that hides chunk cadence behind a continuous deterministic world-space reveal frontier without changing generation, PREPARE/COMMIT, collision, navigation, residency, or semantic authority.
- Completion boundary: Done when one focused reveal-presentation owner consumes the reviewed post-MR6 tile request/commit/unload seams, maintains an always-resolved player safety halo, renders an unresolved diagnostic veil through one batched presentation path, distinguishes first-resolution from reacquisition, freezes with pause, and makes chunk boundaries visually unobservable in flat diagnostic mode while all streaming/gameplay fingerprints remain unchanged.
- Current measured state: M6 is landed and production distant unload now defaults on. `ProcGenTilemap` requests ordinary streaming through `_queue_chunk_for_reveal()` / `_reveal_chunk_immediately()`, commits authoritative prepared records through `_commit_tile_reveal_record()`, and disposes distant presentation/cache residency through `_unload_chunk()` after `ProcGenChunkResidencyPolicy` selects/revalidates DORMANT candidates. M3 remains the only PREPARE/COMMIT queue owner; M4 remains lifecycle owner; M5 remains payload-cache owner; M6 owns residency policy and UNLOADED reacquisition returns through the same request/cache/lifecycle path. MR6 is the only remaining streaming-architecture gate. No dedicated reveal-presentation owner exists, so committed pixels still become directly visible and visible cadence can expose streaming catch-up. Region Frame presentation is now separately designed under `PROCGEN_REGION_FRAME_PROFILES.md`; Archive Resolve must cover requested/generated region cells only and must never become the permanent world-edge underlay.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; landed `PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md`; archived M6 packet; live `proc_gen_tilemap.gd` request/commit/unload seams named above; `procgen_pause_aware_streaming.gd`; `procgen_chunk_lifecycle.gd`; `procgen_chunk_payload_cache.gd`; `procgen_chunk_residency_policy.gd`; current MR6 packet; `PROCGEN_REGION_FRAME_PROFILES.md` for the permanent-underlay separation.
- Task-specific authority: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed M6/MR6 residency behavior once landed; M3/M4/M5 streaming ownership.
- Work surface: Expected focused owner under `custodian/game/world/procgen/streaming/`, expected scene integration in `proc_gen_map.tscn`, and the smallest observation callbacks around live `_queue_chunk_for_reveal()` / `_reveal_chunk_immediately()`, successful `_commit_tile_reveal_record()` completion, and `_unload_chunk()` / lifecycle reacquisition. Do not move those authorities into the presentation owner. Add one focused smoke after its path exists, runtime-health/observability fields, and current-state/index docs.
- Change: Introduce a presentation-only Archive Resolve owner. It may track requested, committed-ready, resolving, settled, and reacquisition presentation state. It may never own chunk lifecycle or gameplay semantics. Request observation must create/retain unresolved coverage before authoritative pixels can visibly pop. Commit observation marks a tile presentation-ready but does not force immediate visual settlement. Unload observation clears disposable presentation and marks previously resolved cells for shorter reacquisition. Use one pooled/batched frontier representation, not per-cell nodes/tweens.
- Preserve: Existing M3 PREPARE/COMMIT ordering and pause contract; M4 lifecycle; M5 payload semantics; reviewed M6 residency/unload authority; exact generated floor/wall/road/biome/surface/route/collision/navigation fingerprints; current streaming determinism; UI/Operator readability; candidate/final generation behavior.
- Non-goals: No final Archive Resolve shader polish; no semantic pre-echo; no new procgen generation behavior; no full-screen post-process requirement; no chunk-size/radius/budget retune; no road/landmark changes; no M6 implementation edits beyond the smallest post-review observation seam required by this presentation consumer.
- Acceptance: Flat diagnostic veil demonstrates that visible reveal no longer exposes 16x16 chunk boundaries; only committed tiles may settle; safety halo never leaves the Operator adjacent to invisible committed blockers/hazards; first-resolve vs reacquisition identity is deterministic; disabling the system restores ordinary committed streaming; pause freezes presentation phase; no per-cell Node/Tween allocation; streaming/gameplay fingerprints and M3/M4/M5/M6 counters remain unchanged except new presentation telemetry.
- Validation: After refresh, add one focused Archive Resolve spine smoke that falsifies request-before-commit coverage, committed-only settlement, safety-halo forcing, pause freeze, unload/reacquisition identity, deterministic ordering, disabled-effect fallback, and semantic fingerprint parity. Re-run the focused post-MR6 streaming/lifecycle/cache/residency/runtime-health smokes selected by the manifest, then changed-file closeout. Visual proof for AR1 is one diagnostic capture/video showing no visible chunk rectangles; aesthetic approval is deferred to AR2.
- Task overrides: `none`
- Deferred: Archive Resolve shader/art treatment is AR2. Semantic pre-echo, initial spawn resolve, and final reacquisition polish are AR3.

## Temporary Refresh Gate — REMOVE WHEN THIS PACKET IS REFRESHED

This packet was pre-authored before M6. M6 is now landed; only MR6 remains as the streaming-architecture gate.

Before implementation:

1. wait for `review-procgen-distant-chunk-unload` to complete cleanly;
2. fetch current `origin/main` and read the MR6 receipt/corrections if any;
3. confirm the exact M6 request/commit/unload hooks named above survived review;
4. update `Reviewed main` and validation to the reviewed post-MR6 state;
5. confirm the sibling Region Frame packet remains a separate permanent-underlay consumer and D1/D2/D3 have not already moved the streaming seam;
6. remove this entire **Temporary Refresh Gate** section;
7. only then change `Status` to `ready` and `Dispatch` to `auto`.

Do not implement from this pre-MR6 packet while this section remains.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: After a clean MR6, refresh this packet in place and make AR1 ready/auto. Region Frame foundation may proceed as a sibling under its own lock; neither owns the other's state.
- Best starting files: reviewed post-MR6 streaming owner(s), `proc_gen_map.tscn`, `proc_gen_tilemap.gd` façade callbacks, `STREAMING_REVEAL_PRESENTATION_V1.md`.
- Blockers or open questions: Exact post-MR6 unload/reacquisition callback surface is intentionally not guessed in this pre-authored packet.
