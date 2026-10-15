# Procgen Showcase Generation Controls

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-generation-controls`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-showcase-generated-arena`
- Locks: `procgen-showcase-level`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-showcase-generation-controls`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Provide reproducible seed/profile/size presets and safe same-seed/reroll/regenerate controls for the one real arena.
- Completion boundary: Ship the exact PGA-4 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
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

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Refresh actual PGA-3 hosted-map creation/disposal API and safely realized Operator entry/exit before writing controls.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-generation-controls`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
