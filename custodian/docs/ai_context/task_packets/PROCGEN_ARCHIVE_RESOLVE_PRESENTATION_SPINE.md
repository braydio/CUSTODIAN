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
- Reviewed main: `36cb18230796ec844a7796f0a246085c96179e20`
- Goal: Add the presentation-only Archive Resolve spine that hides chunk cadence behind a continuous deterministic world-space reveal frontier without changing generation, PREPARE/COMMIT, collision, navigation, residency, or semantic authority.
- Completion boundary: Done when one focused reveal-presentation owner consumes the reviewed post-MR6 tile request/commit/unload seams, maintains an always-resolved player safety halo, renders an unresolved diagnostic veil through one batched presentation path, distinguishes first-resolution from reacquisition, freezes with pause, and makes chunk boundaries visually unobservable in flat diagnostic mode while all streaming/gameplay fingerprints remain unchanged.
- Current measured state: Current production streaming uses 16x16 chunks, immediate radius 1, active radius 2, and a 96-tile-per-frame reveal budget. M3 already owns tile PREPARE/COMMIT, M4 owns chunk lifecycle, M5 owns derived payload caching, and M6/MR6 are the remaining residency/unload gate. No dedicated reveal-presentation owner exists. Visible world timing still follows tile/chunk commit closely enough that catch-up can read as loading rather than intentional resolution.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`; current `custodian/game/world/procgen/proc_gen_tilemap.gd` request/commit/reveal hooks; `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`; `procgen_chunk_lifecycle.gd`; `procgen_chunk_payload_cache.gd`; active M6/MR6 packets.
- Task-specific authority: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed M6/MR6 residency behavior once landed; M3/M4/M5 streaming ownership.
- Work surface: Expected focused owner under `custodian/game/world/procgen/streaming/`, expected scene integration in `proc_gen_map.tscn`, narrow callbacks from the post-MR6 streaming façade/service, one focused smoke, runtime-health/observability seam, and current-state/index docs. Exact hook names must be refreshed from live main after MR6.
- Change: Introduce a presentation-only Archive Resolve owner. It may track requested, committed-ready, resolving, settled, and reacquisition presentation state. It may never own chunk lifecycle or gameplay semantics. Request observation must create/retain unresolved coverage before authoritative pixels can visibly pop. Commit observation marks a tile presentation-ready but does not force immediate visual settlement. Unload observation clears disposable presentation and marks previously resolved cells for shorter reacquisition. Use one pooled/batched frontier representation, not per-cell nodes/tweens.
- Preserve: Existing M3 PREPARE/COMMIT ordering and pause contract; M4 lifecycle; M5 payload semantics; reviewed M6 residency/unload authority; exact generated floor/wall/road/biome/surface/route/collision/navigation fingerprints; current streaming determinism; UI/Operator readability; candidate/final generation behavior.
- Non-goals: No final Archive Resolve shader polish; no semantic pre-echo; no new procgen generation behavior; no full-screen post-process requirement; no chunk-size/radius/budget retune; no road/landmark changes; no M6 implementation edits beyond the smallest post-review observation seam required by this presentation consumer.
- Acceptance: Flat diagnostic veil demonstrates that visible reveal no longer exposes 16x16 chunk boundaries; only committed tiles may settle; safety halo never leaves the Operator adjacent to invisible committed blockers/hazards; first-resolve vs reacquisition identity is deterministic; disabling the system restores ordinary committed streaming; pause freezes presentation phase; no per-cell Node/Tween allocation; streaming/gameplay fingerprints and M3/M4/M5/M6 counters remain unchanged except new presentation telemetry.
- Validation: After refresh, add one focused Archive Resolve spine smoke that falsifies request-before-commit coverage, committed-only settlement, safety-halo forcing, pause freeze, unload/reacquisition identity, deterministic ordering, disabled-effect fallback, and semantic fingerprint parity. Re-run the focused post-MR6 streaming/lifecycle/cache/residency/runtime-health smokes selected by the manifest, then changed-file closeout. Visual proof for AR1 is one diagnostic capture/video showing no visible chunk rectangles; aesthetic approval is deferred to AR2.
- Task overrides: `none`
- Deferred: Archive Resolve shader/art treatment is AR2. Semantic pre-echo, initial spawn resolve, and final reacquisition polish are AR3.

## Temporary Refresh Gate — REMOVE WHEN THIS PACKET IS REFRESHED

This packet is intentionally pre-authored before M6/MR6 have landed.

Before implementation:

1. wait for `review-procgen-distant-chunk-unload` to complete cleanly;
2. fetch current `origin/main`;
3. re-read the reviewed M6/MR6 implementation and `STREAMING_REVEAL_PRESENTATION_V1.md`;
4. replace `Reviewed main`, `Current measured state`, `Evidence`, `Work surface`, exact request/commit/unload hook names, and focused validation with the live post-MR6 seams;
5. confirm D1/D2/D3 have not already moved those seams;
6. remove this entire **Temporary Refresh Gate** section;
7. only then change `Status` from `blocked` to `ready`.

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

- Next action: Refresh this packet immediately after reviewed MR6, then implement AR1 before the refresh-gated D1/D2/D3 extraction packets move the streaming façade seam.
- Best starting files: reviewed post-MR6 streaming owner(s), `proc_gen_map.tscn`, `proc_gen_tilemap.gd` façade callbacks, `STREAMING_REVEAL_PRESENTATION_V1.md`.
- Blockers or open questions: Exact post-MR6 unload/reacquisition callback surface is intentionally not guessed in this pre-authored packet.
