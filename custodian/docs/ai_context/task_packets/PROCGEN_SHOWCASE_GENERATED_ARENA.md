# Procgen Showcase Generated Arena

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-generated-arena`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
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
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Embed one authentic, bounded procgen world into the dev gallery as a safe playable arena using the existing generated-region preparation authority.
- Completion boundary: Ship the exact PGA-3 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: GeneratedRegionLevel.prepare_generated_region already configures a real ProcGenTilemap, asserts valid main playable component/spawn and owns map cleanup; LevelLoader does not permit another active level. A nested instance/activation seam is not yet proven.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_host.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.gd`, `custodian/game/world/levels/generated_region_level.gd` (only for a narrow read-only accessor if unavoidable), `custodian/game/world/procgen/proc_gen_map.tscn` (consume unmodified), `custodian/tools/validation/levels/procgen_showcase_generated_arena_smoke.gd`, `custodian/tools/validation/validation_manifest.json`.
- Change: Implement one dev-only arena host child inside the authored level. Consume GeneratedRegionLevel.prepare_generated_region(request) or extract a minimal reusable map staging adapter if lifecycle ownership makes nesting unsafe; do not copy its generation/spawn validation algorithm. Use explicit world-space arena bounds and a controlled entry/return threshold to a validated generated spawn. Do not falsely paint an authored walkable corridor into arbitrary generated topology. Keep gallery walkable after a failed preparation; fail closed with explicit reason. Existing level loader still considers the showcase ONE active authored level.
- Preserve: Single Operator/controller/camera, real generation seed and profile semantics, 32px map, collision/nav/spawn, route manager, no extra LevelLoader active instance. Do not modify campaign topology or generator acceptance rules.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: One actual ProcGenTilemap, accepted map, named safe spawn, Operator can enter/leave using validated transfer, no overlap/escape/void-spawn; host failure leaves safe gallery; no double active level or camera binding leak.
- Validation: NEW generated arena smoke with real seeded procgen, failed-seed/invalid-spawn test, single-Operator and return; generated_region_route_lifecycle, procgen_playability, existing shell; changed/diff.
- Task overrides: `none`
- Deferred: Repeated regeneration, UX and condition searches later. No fake map preview.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Real generated-region-to-authored-level staging/entry and camera ownership must be reconciled against landed PGA-1; user must approve any material change from a safe gated threshold to a different physical layout.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-generated-arena`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
