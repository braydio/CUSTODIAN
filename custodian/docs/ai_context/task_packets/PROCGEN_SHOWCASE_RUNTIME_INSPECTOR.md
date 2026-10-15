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
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Inspect live accepted generated-world truth through read-only terrain/route/playability/POI/asset provenance overlays without new authority.
- Completion boundary: Ship the exact PGA-5 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: ProcGenTilemap exposes generation/export and debug/read-only contracts, but a gallery-scoped structured snapshot with bounded overlay cost has not been proven.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_inspector.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_overlay.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_session.gd`, `custodian/game/world/procgen/generation/accepted_world_export.gd` (read-only consumption), `custodian/tools/validation/levels/procgen_showcase_inspector_smoke.gd`, `custodian/tools/validation/validation_manifest.json`.
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
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
