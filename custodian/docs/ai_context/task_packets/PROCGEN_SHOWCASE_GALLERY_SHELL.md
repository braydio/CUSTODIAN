# Procgen Showcase Gallery Shell

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-gallery-shell`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `procgen-showcase-level`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-showcase-gallery-shell`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Register a dev-only authored showcase gallery with a central sealed arena threshold, five explorable exhibit wings and one real-Operator standalone playtest.
- Completion boundary: Ship the exact PGA-1 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: LoP and NPA are separately registered authored dev levels; no procgen showcase level or gallery exists. Level registry and LevelPlaytestBootstrap conventions are live.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.tscn`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_authoring.tscn`, `custodian/content/levels/dev/procgen_showcase_gallery/procgen_showcase_gallery.json`, `custodian/content/levels/levels.json`, `custodian/tools/validation/validation_manifest.json`, `procgen_showcase_gallery_shell_smoke.gd` (planned in `custodian/tools/validation/levels/`).
- Change: Use AuthoredLevel2D and the actual LoP/NPA scaffold: Spawn_Main, Return_Main, WorldIngressSite, InteractableLevelExit2D, registered metadata, normal reset-on-entry dev level, Collision/POI authoring scene. Create five connected gallery wings (Terrain, Topology, Sites, Population, Presentation), neutral collision-safe exhibit plinths/markers and a gated central arena threshold. The arena is intentionally empty/inert here. Single Operator/controller/camera + ordinary combat/navigation roots only in wrapper; no player copy in production scene. Do not fake an in-gallery generated map.
- Preserve: World ingress/return, same Operator identity, level loader and NPA/LoP registrations. Spatial layout must allow replaceable arena staging with adequate footprint; declare its coordinate/anchor seam in the scene, no speculative runtime map.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: All five wings accessible and physically connected; return and re-entry preserve the Operator; default central threshold cannot enter unloaded terrain; production scene has zero Operators/controllers/cameras; wrapper exactly one; all level definition paths validate.
- Validation: Existing level_registry_contract, authored_level_ingress_return, world_ingress_physics_reentry, npa_showcase_arena_foundation and lords_of_pain_test_gallery; NEW shell smoke implemented and registered in validation_manifest; then --changed and diff checks.
- Task overrides: `none`
- Deferred: Real map realization and controls belong to PGA-3/4; no new art or Asset V2 family.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Next Handoff
- Next workstream: `review-procgen-showcase-gallery-shell`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Automated authoring preflight/promotion remains to be verified on live main`

## Publication Gate
Do not claim this draft implementation until the opted-in authoring handoff has validated the pair, promoted both to ready/auto, and verified the canonical queue index on live main.
