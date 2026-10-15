# Procgen Showcase Seed Comparison

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-seed-comparison`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector`
- Locks: `procgen-showcase-inspector`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-showcase-seed-comparison`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Compare up to three accepted seed/profile runs with reproducible lightweight structural and visual review evidence, without multiple resident simulation worlds.
- Completion boundary: Ship the exact PGA-7 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: Existing validation/Moment Forge can capture deterministic evidence; no showcase saved-comparison format or bound capture budget exists.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_seed_comparison.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_gallery_controls.gd`, `custodian/content/data/dev/procgen_showcase/seed_review_schema.v1.json`, `procgen_showcase_seed_comparison_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`.
- Change: Capture read-only structured run receipts for at most three sequential accepted maps: explicit seed/profile, map size, generation fingerprint, route/POI/playability/collision summary, build time and failure reason. Display A/B/C comparison cards while only ONE real arena remains loaded. Add opt-in minimal deterministic ROI screenshots through existing capture/Moment Forge tooling; no persistent media stored as runtime content. Compare true semantic differences, mark absent/unsupported metrics N/A. Export a compact JSON receipt usable for review.
- Preserve: No parallel 3x procgen maps, no gameplay authority in UI, no new screenshot infrastructure unless the existing tool genuinely lacks a required narrow seam.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Repeated same seed produces identical comparable structural fields; different seeds remain distinct; failed runs cannot masquerade as passes; memory/node counts stay bounded after three captures.
- Validation: NEW seed-comparison smoke for stable serial receipts, reset, cap, negative states and leaks; existing targeted capture and generation tests; changed/diff.
- Task overrides: `none`
- Deferred: Subjective gallery aesthetics remain human approval; large video capture not required.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Refresh actual structured inspector/capture capabilities, memory budget and existing capture command before implementation.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-seed-comparison`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
