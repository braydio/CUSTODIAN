# Procgen Showcase Runtime Inspector

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-runtime-inspector`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-showcase-generation-controls, review-procgen-showcase-exhibit-catalog`
- Locks: `procgen-showcase-inspector`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-showcase-runtime-inspector`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `conditional`
- Goal: Inspect live accepted generated-world truth through read-only terrain/route/playability/POI/asset provenance overlays without new authority.
- Completion boundary: Ship the exact PGA-5 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: ProcGenTilemap exposes generation/export and debug/read-only contracts, but a gallery-scoped structured snapshot with bounded overlay cost has not been proven.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_inspector.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_overlay.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd`, `custodian/game/world/procgen/generation/accepted_world_export.gd` (read-only consumption), `procgen_showcase_inspector_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Expose event/request-driven inspector snapshots of accepted seed, attempt count/failure reason, playable component/spawn evidence, floor/collision/navigation, route bands/anchors, sites and registered presentation provenance when available. Render limited toggleable debug overlays using copied read-only descriptors. Query existing canonical get_level_data/debug getters; add an explicitly read-only projection adapter only if public API is insufficient. No per-frame world scan, fake labels or input from overlay to gameplay authority.
- Preserve: No candidate mutation, pathfinding duplication, public debug data changing generation fingerprint, or global HUD/Operator UI takeover.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Overlay counts/fingerprints agree with map owners; disabled costs near zero; opaque/missing fields say unavailable; teardown and seed swap cannot show stale data.
- Validation: NEW inspector smoke with real fixed-seed snapshot/overlay toggles and stale teardown; directly affected existing procgen debug/playability tests; changed/diff.
- Task overrides: `none`
- Deferred: Human visual comparison deferred to PGA-7; no new semantic authority.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Preparatory implementation audit (2026-10-15; live main `96c44f5444abb87eb5c054ad883e69d023ff845f`)

**This is a preparatory exact-path implementation plan, not the final realized-API refresh.** PGA-5 is still `draft/manual`; the relevant predecessor reviews and direct API checks named below remain mandatory. Do not add `Authoring handoff: auto`, promote, or claim as a result of this section.

### Canonical snapshot boundaries (pre-PGA-2/PGA-4 API freeze)
- `custodian/game/world/procgen/generation/accepted_world_export.gd::ProcgenAcceptedWorldExport.LEVEL_DATA_SCHEMA` owns the exported generated-world keys and detached copies. Consume exported `floor_cells`, `wall_cells`, `region_tiles`, `road_semantics`, `main_route_cells`, `route_playability`, `biome_summary`, `encounter_plan`, `faction_activity_sites` and other **present** keys as data. Do NOT invoke its mutating `capture_tile_state` from a debug overlay.
- `ProcGenTilemap.get_level_data()`, `get_runtime_health_snapshot()` and `ProcgenPerformanceSnapshot.generation_snapshot(tilemap)` are existing read APIs. `CandidateSemanticAdapter.fingerprint_runtime_state` is the existing fingerprint authority. Stage/report facts must be scoped to the gallery host's accepted map, not arbitrary `SceneTree` first-node selection.
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_inspector.gd` should project one detached, versioned readout per accepted `generation_id` / session request, with `available`, `unavailable` or `not_applicable` per field. Compare counts to source dictionaries, not painted/unpainted streaming visibility when those differ.
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_overlay.gd` is presentation-only. Build bounded spatial glyphs/lines from the snapshot (and only for explicit enabled layers or changed events); no continual full-map scan, render-side collision inference, accepting input as gameplay data, or write into `ProcGenTilemap`.
- Provenance: resolve catalog `exhibit_id` to actual loaded `source authority` and optional runtime asset reference from **landed PGA-2**, with truthful N/A if unresolved. Do not render pending Asset V2 inbox items or claim an unavailable actor/biome.
- Planned `procgen_showcase_inspector_smoke.gd` under `custodian/tools/validation/levels/`: fixed accepted map + source parity, disabled overlay cost bounded, clear on seed/session change/host disposal, missing-data N/A and absence of source mutation. Run `procgen_accepted_world_export_parity`, `procgen_candidate_semantic_model` and the PGA-2/PGA-4 focused smokes.

### Required *final* refresh after PGA-2 and PGA-4 reviews
Resolve the exact catalog lookup API and session accepted-map/level_data getter from their landed sources/review receipts. Choose a narrow read-only host/session projection if needed; do not access private fields or create a second map-export authority. Retain `draft/manual` until this is inspected on main.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Refresh actual landed catalog/controls/accepted-world read APIs before choosing overlay snapshot owners.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-runtime-inspector`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
