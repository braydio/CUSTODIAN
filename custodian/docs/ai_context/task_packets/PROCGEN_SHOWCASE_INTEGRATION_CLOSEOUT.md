# Procgen Showcase Integration Closeout

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-integration-closeout`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-showcase-exemplar-search, review-procgen-showcase-seed-comparison`
- Locks: `procgen-showcase-level, procgen-showcase-inspector`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-showcase-integration-closeout`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `conditional`
- Goal: Deliver and independently prove the complete real-Operator gallery-to-generated-arena workflow with functional five-wing exhibits, debug provenance, exemplar queries and comparison.
- Completion boundary: Ship the exact PGA-8 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: Integration depends on independently reviewed shell, catalog, host, controls, inspector, exemplar and comparison; no complete program-level acceptance exists.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/generation/`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/`, `custodian/content/data/dev/procgen_showcase/`, `custodian/content/levels/dev/procgen_showcase_gallery/procgen_showcase_gallery.json`, `procgen_showcase_integration_smoke.gd` (planned in `custodian/tools/validation/levels/`), `custodian/tools/validation/validation_manifest.json`, `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`.
- Change: Perform honest program integration: real Operator arrival, five gallery wings, select canonical exhibit, generate/enter/exit valid seed, reroll/retry, inspect actual world semantics, bounded exemplar success/failure, compare saved seed receipts, return to origin. Correct only integration seams and user-facing affordance/navigation failures; eliminate stale N/A/ready statements in affected current docs after source proof. Verify no production/world-transition regression, no leak and practical interactive generation/performance. Send one compact human visual handoff if material composition decision remains, not unbounded screenshots.
- Preserve: All existing unrelated gameplay/procgen, LoP and NPA dev levels, current Asset V2 families, accepted-region semantics, Operator/route single ownership, Render skip policy.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: All predecessors reviewed; complete smoke passes with real Operator plus negative controls; 0 unsupported exhibit claims; deterministic same seed and bounded resources; up-to-date tracked program state; review reports zero blocking findings/material evidence gaps.
- Validation: NEW program integration smoke; each predecessor focused smoke and directly affected level/procgen validations; --changed and queue/index/diff checks; visual ROI only after structural checks.
- Task overrides: `none`
- Deferred: Shipping an in-fiction Hub archive room, new art, vehicle-specific tests and gameplay mission integration are separate future authoring choices.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Preparatory implementation audit (2026-10-15; live main `96c44f5444abb87eb5c054ad883e69d023ff845f`)

**This is a preparatory exact-path implementation plan, not the final realized-API refresh.** PGA-8 is still `draft/manual`; the relevant predecessor reviews and direct API checks named below remain mandatory. Do not add `Authoring handoff: auto`, promote, or claim as a result of this section.

### End-to-end proof matrix (predecessors still outstanding)
- Use only reviewed components and their actual source owners: PGA-1 gallery shell (`procgen_showcase_gallery.gd/.tscn`); PGA-2 `procgen_exhibit_catalog.gd` / `procgen_exhibit_presenter.gd`; PGA-3 `procgen_arena_host.gd`; PGA-4 `procgen_arena_session.gd` / `procgen_gallery_controls.gd`; PGA-5 `procgen_gallery_inspector.gd` / `procgen_gallery_overlay.gd`; PGA-6 `procgen_exemplar_resolver.gd`; PGA-7 `procgen_seed_comparison.gd`. Do not implement missing predecessor behavior inside closeout.
- `custodian/tools/validation/levels/procgen_showcase_integration_smoke.gd` (planned): real Operator comes via registered dev gallery ingress, visits each of five wings, inspects canonical entry and honest N/A, stages a real accepted generated map, crosses sealed threshold only through explicit valid transfer, checks actual spawn/nav/camera, inspects source-parity live data, returns to gallery then to origin.
- Negative proof: no map or invalid spawn blocks transfer; cancellation/stale seed request preserves Operator/camera/outer return; unsupported exemplar predicate is unavailable, a real matching query gives accepted evidence or finite NOT_FOUND; A/B/C receipts are capped and structural fingerprints deterministic; no leaked map/actor/scene state after repeated cycles.
- Preserve `LevelLoader` single-active-level and actual `GeneratedRegionLevel.prepare_generated_region` ownership; never relax accepted-world ingress/spawn rules or replace real data with gallery stubs to pass validation.
- Closeout drift scope only: update `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md` and directly affected active specs to **actual shipped status**. Avoid sweeping unrelated docs; preserve separate completed-packet and review identities.
- Validation order: each predecessor's registered focused smoke, integrated real-Operator smoke, level/route and procgen safety regressions, full changed-file manifest sweep, `git diff --check`, packet/queue lifecycle checks. Record measured runtime generation/capture budgets and optional narrow human visual handoff, not invented performance numbers.

### Required *final* refresh after PGA-6 and PGA-7 reviews
Inventory the exact seven predecessor implementation+review archives, approved catalog/query capabilities, real world/camera/Operator transitions, and executable capture/receipt APIs. If any predecessor has nonpassing review or material open finding, do not promote closeout. The originally locked eight-pair program stays unchanged; corrections are separate bounded workstreams only if findings justify them.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `not-recorded`
- Refresh instruction: `Refresh seven predecessor review receipts, exact scene contracts and any human visual decision before closeout.` Bring the exact predecessor closing summary/review finding IDs plus refreshed `origin/main` code paths to this planning chat. Reconcile ownership and test paths; then run targeted paired authoring preflight, promote both to ready/auto and regenerate managed README. Never self-promote this draft from dependency completion alone.

## Next Handoff
- Next workstream: `review-procgen-showcase-integration-closeout`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Explicit architecture/API refresh required before promotion`
