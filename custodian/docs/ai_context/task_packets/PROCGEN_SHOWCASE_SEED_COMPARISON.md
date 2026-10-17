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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
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

## Preparatory implementation audit (2026-10-15; live main `96c44f5444abb87eb5c054ad883e69d023ff845f`)

**This is a preparatory exact-path implementation plan, not the final realized-API refresh.** PGA-7 is still `draft/manual`; the relevant predecessor reviews and direct API checks named below remain mandatory. Do not add `Authoring handoff: auto`, promote, or claim as a result of this section.

### Three-run receipt contract (pre-PGA-4/PGA-5 freeze)
- `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_seed_comparison.gd` is a **read-only serial receipt collector** over the actual PGA-4 host/session and PGA-5 inspector. Limit A/B/C to three saved slots; no simultaneous three-world generation and no second active `LevelLoader`.
- `custodian/content/data/dev/procgen_showcase/seed_review_schema.v1.json` should describe stable `schema`, `slot`, `request` (seed/profile/map_size/room_count), `result_status` (accepted/rejected/failed), canonical `fingerprint`, approved structural fields with provenance/availability and diagnostic `elapsed_ms` **outside** deterministic comparison. Absent values must remain N/A. Never claim screenshots are generated by default.
- Capture `ProcgenAcceptedWorldExport` / `ProcgenPerformanceSnapshot` detached structural facts before the next map is discarded; do not retain Node, Resource or live map references in a receipt. Only one gallery arena map may be resident; later slots are plain data. Copy/expose immutable JSON-safe values and reject huge cell arrays unless an explicit bounded summary is derived.
- Add a strictly opt-in minimal ROI screenshot through existing review/capture tooling *if the live capture API supports it*. Screenshots are evidence-only and not added to source/runtime or Asset V2. If capture is not available, structural receipt alone must remain usable; do not invent a new screenshot service.
- Required negative paths: two identical requests yield identical structural fingerprint and compare-ready fields; different accepted seeds remain identifiable; rejected/failed maps cannot inherit an earlier PASS or image; slot-4 attempt fails explicitly; clearing/changing slots does not resurrect discarded maps; no duplicate Operator/camera.
- Planned `procgen_showcase_seed_comparison_smoke.gd` under `custodian/tools/validation/levels/`; verify PGA-4/PGA-5 focused smokes, `procgen_accepted_world_export_parity` and complete changed-file sweep.

### Required *final* refresh after PGA-4/PGA-5 reviews
Bind the receipt fields to actual session/inspector public APIs, measure realistic map/capture retention cost and identify the reviewed ROI capture invocation if any. Keep `draft/manual` until real host and inspector results are archived.

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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
