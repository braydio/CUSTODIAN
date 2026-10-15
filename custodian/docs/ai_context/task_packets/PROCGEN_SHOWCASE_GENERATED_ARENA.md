# Procgen Showcase Generated Arena

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-generated-arena`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-procgen-showcase-gallery-shell`
- Locks: `procgen-showcase-level`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-showcase-generated-arena`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `conditional`
- Goal: Embed one authentic, bounded procgen world into the dev gallery as a safe playable arena using the existing generated-region preparation authority.
- Completion boundary: Ship the exact PGA-3 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: PGA-1's reviewed shell is live with five wings, an ArenaThreshold marker at (0,-520), and collision-sealed north rail from (-210,-520) to (210,-520). `GeneratedRegionLevel.prepare_generated_region` stages a real ProcGenTilemap, validates accepted main playable component/spawn/nav, and owns map cleanup. `LevelLoader` still has one active destination, while the gallery's playtest wrapper owns the sole Operator/controller/camera. The child-host transfer path requires implementation and runtime proof, not a second registered level.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_host.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.gd`, `custodian/game/world/levels/generated_region_level.gd` (only for a narrow read-only accessor if unavoidable), `custodian/game/world/procgen/proc_gen_map.tscn` (consume unmodified), `procgen_showcase_generated_arena_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Implement one dev-only arena host child inside the authored level. Consume `GeneratedRegionLevel.prepare_generated_region(request)` to stage a disposable real `ProcGenTilemap` using `scene_path`, explicit seed/map size/room count/profile and a named spawn. Do not copy the generation/spawn validation algorithm. Place the generated host at a proven nonoverlapping world-space offset from the authored gallery, derived from the actual map/gallery bounds. Retain the collision-sealed ArenaThreshold rail; add an explicit nearby interaction which becomes usable only after accepted-map, canonical spawn, walkability and camera prerequisites are satisfied, and transfers the SAME Operator to `get_spawn_position`. Rebind the sole camera using the existing generated-region adapter; verify/fail-close any activation failure and restore prior Operator position, camera, control and gallery collision state. Provide a deliberate return interaction restoring the gallery camera through `AuthoredLevel2D.refresh_route_camera` before disposing the map. Keep the existing outer `return_world` exit unchanged. The level loader still considers the showcase ONE active authored level. If `GeneratedRegionLevel` requires adaptation, restrict it to a narrow read-only map accessor (for verification/camera/nav), not a second generator.
- Preserve: Single Operator/controller/camera, real generation seed and profile semantics, 32px map, collision/nav/spawn, route manager, no extra LevelLoader active instance. Do not modify campaign topology or generator acceptance rules.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: One actual ProcGenTilemap staged through `GeneratedRegionLevel`, accepted map, named canonical safe spawn; physically sealed arena rail remains; explicit transfer sends the same Operator to accepted spawn and returns it to the original safe gallery position; generated and gallery bounds do not overlap; failed/cancelled stage or failed activation leaves gallery, camera and movement authority intact; no void-spawn, leaked world, duplicate active level/Operator/camera, or camera binding leak. Preserve all PGA-1 five-wing/layout/ingress/return guarantees.
- Validation: NEW `procgen_showcase_generated_arena_smoke.gd` (planned under `custodian/tools/validation/levels/` at implementation time) with one actual seeded generated map, verified map/gallery nonoverlap, entry under the intact collision rail via explicit interaction, canonical spawn/nav proof, same-Operator/camera round trip, double-entry rejection, failure/cancel rollback, and no active-map leak; run `generated_region_route_lifecycle`, `procgen_playability`, `procgen_showcase_gallery_shell`, then changed-file validation/`git diff --check`. Keep any slow/blocked upstream ProcGen tests truthful; do not waive a red required sweep or raise timeouts.
- Task overrides: `none`
- Deferred: Repeated regeneration, UX and condition searches later. No fake map preview.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh instruction: `The required post-PGA-1 architecture refresh was completed against the landed shell and passed archive: retain the sealed threshold, reuse GeneratedRegionLevel, do not create a nested LevelLoader or second Operator/camera. No material change to the user-approved five-wing layout is proposed. Execute the exact bounded acceptance checks below; if actual runtime constraints require opening/relocating the threshold or altering level ownership, stop and request a new human planning decision. Before claim, automatic paired authoring preflight must promote both draft/manual packets and verify the generated managed index.`

## Verified PGA-1 integration boundary (2026-10-15)
- Source: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.gd` and `.tscn`; `get_arena_threshold_segment()` returns the existing collision segment. The scene provides `Markers/ArenaThreshold` at (0,-520), and `Collision/PathBoundaryCollision` currently has 10 required rail children. Preserve those geometry expectations and the existing shell smoke as an unchanged regression contract.
- Use `custodian/game/world/levels/generated_region_level.gd::prepare_generated_region(request)`, `has_spawn`, `get_spawn_position`, `activate_route_node`, `refresh_route_camera` as the existing single-map staging/validation interface; do not access or rewrite `_map` externally. Only a narrow read-only accessor is permitted where necessary.
- `custodian/game/world/levels/level_loader.gd` retains one active authored level; do not call nested `stage_level_async/commit_staged_level` to register a second active destination from inside the gallery. The generated host is a disposal-owned child of that authored level.
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn` supplies `/root/GameRoot/World/{Operator,Camera2D}` and the real navigation/combat roots. The production gallery scene owns none; gate transfer on the availability of the existing actor and camera, validate map spawn/nav, keep one camera binding and restore it upon return.
- Existing `AuthoredLevel2D.refresh_route_camera(actor)` can restore the gallery binding on return. On failure, preserve the source camera/actor state even if `activate_route_node` moved the actor before returning false; test this negative path explicitly.
- Accept no speculative generator tuning, altered candidate ordering, second physical corridor or new asset families. PGA-4 owns repeated seeds/regeneration and controls.

## Publication Gate
**Satisfied:** GitHub automatic packet authoring handoff passed targeted preflight and published both PGA-3 implementation/review packets as `ready/auto`, with the canonical managed index updated, at `95c89d47ac893f1c78d6cc91910a97960cac8802` (2026-10-15). The dispatcher remains the sole claim/lock authority. Passing authoring is not evidence of landed runtime implementation or independent review.

## Next Handoff
- Next workstream: `review-procgen-showcase-generated-arena`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
