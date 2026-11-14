# Procgen Showcase Generation Controls

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-generation-controls`
- Kind: `implementation`
- Category: `world-procgen`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-showcase-generated-arena`
- Locks: `procgen-showcase-level`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `Paired review retired 2026-11-12 by owner decision; focused validation is the acceptance gate.`
- Reviewed main: `9e0bfa8ddab729c4b02365a98afa9fb0f448b365`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Visual review: `none`
- Goal: Provide reproducible seed/profile/size presets and safe same-seed/reroll/regenerate controls for the one real arena.
- Completion boundary: Ship the exact PGA-4 scoped behavior on the existing gallery owners, register its focused smoke, pass affected runtime validation, and obtain owner review of the landed change; no proxy closure or speculative ownership changes.
- Current measured state: Procgen generation and generated-region entry are already async, with real failure paths; gallery has no generation input/session state. Candidate evaluator owns acceptance.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_host.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_controls.gd`, `custodian/content/data/dev/procgen_showcase/generation_presets.v1.json`, `procgen_showcase_generation_controls_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Use a dev-only session controller holding explicit immutable generation request (seed, bounded map_size, room_count, validated real profile) and state IDLE/BUILDING/READY/FAILED. UI exposes same seed, next explicit seed, predefined profile/size, cancel/retry and clear errors. Construct next arena in isolated staging; only swap active map when real accepted-ready and Operator can transfer to valid spawn. Guard busy requests, queued reroll, stale completion tokens, actor inside arena, teardown, cancellation and same-seed repeat. Reset old map nodes and camera/nav references transactionally. No global Input alias collision.
- Preserve: No changes to real generator candidate selection, world RNG, Hub/mission state or seed identity; keep the curated wings stable during re-generation.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Same request gives identical semantic/world fingerprint; reroll changes explicit seed; failure retains safe prior world or safely returns Operator; no leaked maps, stale callbacks or duplicated Operator/camera.
- Validation: NEW generation-controls smoke including overlapping requests, failure and two identical runs; generated-region lifecycle; shell/arena; changed/diff.
- Task overrides: `none`
- Deferred: Search-by-exhibit and batch comparison.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Preparatory implementation audit (2026-10-15; live main `96c44f5444abb87eb5c054ad883e69d023ff845f`)

**Historical preparation record.** The exact paths listed here remain useful; the following realized-API refresh supersedes this section’s stale pre-PGA-3 staging assumptions and paired-review references. The packet remains `draft/manual` until its planning/authoring work is published and authorized through current repository policy.

### Bounded implementation plan (historical; reconcile with realized API below)
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd` is the sole dev-only request/session authority. Keep a request generation token, one current accepted host and at most one staging host. State transitions `IDLE -> BUILDING -> READY` or `FAILED`; a superseded/cancelled asynchronous completion must release only its own staged host and must not touch the current accepted world.
- `ProcgenArenaHost` is a fixed-request host rather than a configurable staging API. Add only narrow request parameters/factory behavior or a safe session-owned host seam; keep region construction, actor/camera transfer, and disposal with the host. Never call a second `LevelLoader.commit_staged_level` or manipulate `GeneratedRegionLevel._map` directly.
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_controls.gd` is input/presentation only: seed display, repeat identical request, explicit next-seed choice, profile/size preset choice, busy/cancel/retry and specific failure readout. Disable invalid actions rather than queue unbounded generation. No global input remapping.
- `custodian/content/data/dev/procgen_showcase/generation_presets.v1.json`: stable `preset_id`, actual existing profile reference, integer seed, `map_size`, `room_count`; validate against the **landed** `GeneratedRegionLevel.prepare_generated_region` request shape and production profile/source limits before selecting numeric bounds. Do not invent profiles or create an alternate generator.
- Determinism proof: execute request A twice after clearing the disposable map and compare canonical generated cell/semantic fingerprint using existing `ProcgenPerformanceSnapshot.fingerprint_generation` / `CandidateSemanticAdapter.fingerprint_runtime_state` where compatible; do **not** compare wall-clock elapsed time as part of determinism. Test A -> B -> A, stale completion, failed validation, Operator-inside-arena reroll refusal/explicit safe return, exact map/camera/Operator node residency and teardown.
- Planned focused smoke: `procgen_showcase_generation_controls_smoke.gd` under `custodian/tools/validation/levels/`, registered with file-ownership mapping in `validation_manifest.json`. Run `generated_region_route_lifecycle` and PGA-1/PGA-3 smokes before full changed-file gate.

### Realized PGA-3 API refresh (2026-11-14; main `f1bccf0d4eb8d06d20f3be52edc4bfde7afda9b3`)

The implementation owner is `ProcgenArenaHost` at `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_host.gd`. Its public interaction surface is `can_interact(actor)`, `interact(actor)`, `get_interaction_position()`, `get_interaction_distance()`, `get_interaction_prompt()`, `get_arena_status()`, and `cancel_generation()`. It currently hard-codes seed `417203`, map size `[96, 96]`, room count `12`, profile `sundered_keep_ascent`, and spawn `ArenaSpawn`; it does not expose a configurable request or staging/commit/dispose API. `cancel_generation()` sets a permanent cancellation flag and prevents pending `_ready()` staging from being accepted; `_exit_tree()` cancels. `_dispose_region()` is private and calls `queue_free()` on its owned `GeneratedRegionLevel`.

`GeneratedRegionLevel.prepare_generated_region(request)` accepts `scene_path`, integer `seed`, two-element `map_size`, integer `room_count`, `profile_id`, a profile dictionary and `spawns`. It instantiates the requested ProcGen scene, disables auto/random seeding, applies seed/size/room/profile before adding the map, awaits `level_data_ready`, validates the canonical spawn/main playable component/navigation, and returns `{succeeded, level_data, identity}`. Failure queues its map for freeing and clears spawn/identity state. On success, the region owns the map; `get_generated_map()` is a read-only accessor, `has_spawn()`/`get_spawn_position()` expose accepted spawn data, `activate_route_node()` moves the existing actor and binds the existing Camera2D, and `refresh_route_camera()` rebinds the camera to the region-owned map. The wrapper has no public cancellation token, duplicate-request lock, or immediate dispose method. `queue_free()` on the owned region is the present teardown mechanism.

PGA-3 entry transfers the existing Operator to `ArenaSpawn` through `activate_route_node()`. Return restores the saved gallery position and calls the gallery's `refresh_route_camera()`; camera restoration is verified against `get_runtime_map()`. A failed return retains the generated map and Operator in the arena. Normal return disposes the region, so regeneration creates a fresh host/region. The gallery constructs its host in `_ready()`; safe replacement must not add a second host, Operator, Camera2D, LevelLoader destination or generator. A PGA-4 session may own at most one accepted host and one hidden staging host, and must defer replacement while the Operator occupies the accepted arena. Do not invoke private `_dispose_region()` or mutate `GeneratedRegionLevel._map`.

Supported profile IDs in `custodian/content/procgen/world_profiles/` are `sundered_keep_ascent` and `sundered_keep_vista_approach`. The PGA-3 host currently uses only `sundered_keep_ascent`; the vista profile is not yet proven as a valid gallery arena preset. No supported configurable `map_size`/`room_count` range is declared by the generated-region wrapper or PGA-3 host. The separate `CustodianContractMap` production path clamps profile map dimensions to at least 64 and rounds them to 16-cell increments; its world profiles carry their own per-profile ranges, and room counts default to 12–22 (overridable by profile). This is not a validated range contract for `prepare_generated_region`. Until a real-profile focused smoke establishes additional cases, presets must use the proven `[96, 96]`, 12-room request. Do not market derived ranges as supported API.

Determinism can be measured with `ProcgenPerformanceSnapshot.fingerprint_generation(tilemap)` or `CandidateSemanticAdapter.fingerprint_runtime_state(map_instance)`. Both fingerprint canonical generated floor/wall cells (including tile identity for the runtime fingerprint), independent of elapsed timings. There is no current session-level request token or cross-host duplicate suppression; PGA-4 must add those above the host boundary. Existing host cancellation only handles a cancelled/disposed host after its awaited prepare completes; stale completion ownership, overlap rejection and transactional active-host replacement are PGA-4 responsibilities.

The final API reconciliation is complete for the currently landed main. Keep this packet `draft/manual` until the targeted implementation authoring validation passes; only then follow the owner-authorized publication and dispatch sequence. No paired-review packet is part of this task.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `complete for current PGA-3 main API`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Refresh instruction: `Use the actual host/region boundaries documented above. Keep draft/manual until the canonical implementation packet authoring validation succeeds; publish only the implementation packet under current policy. No paired review or review dependency.`

## Next Handoff
- Next workstream: `procgen-showcase-runtime-inspector`
- Next packet state: `draft/manual`; refresh after PGA-4 owner acceptance
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Refresh reason: `reconcile inspector inputs with the landed PGA-4 session and controls API`
- Next action: `After PGA-4 lands and receives owner review, refresh the successor packet against actual session/controls APIs; do not create paired-review artifacts.`
- Blockers or open questions: `PGA-4 session API and focused runtime evidence are not yet landed`
