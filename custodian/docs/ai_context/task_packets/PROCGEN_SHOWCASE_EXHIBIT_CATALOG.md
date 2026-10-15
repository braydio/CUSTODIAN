# Procgen Showcase Exhibit Catalog

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-exhibit-catalog`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-procgen-showcase-gallery-shell`
- Locks: `procgen-showcase-catalog`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-showcase-exhibit-catalog`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new game-world/dev-tool boundary; fresh independent proof`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Expose canonical, inspectable examples of the existing procgen semantic vocabulary in five gallery wings without replacing game data authorities.
- Completion boundary: Ship the exact PGA-2 scoped behavior on real repository owners, register its focused smoke and pass the paired fresh-context review; no proxy closure or speculative ownership changes.
- Current measured state: LoP uses a scoped gallery manifest and runtime asset previews. Existing procgen profile/catalog/road/playability/dressing authorities remain distributed; there is no showcase exhibit registry.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/`; `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `custodian/game/world/levels/level_loader.gd`; `design/04_architecture/ASSET_PIPELINE_V2.md`.
- Work surface: `custodian/content/data/dev/procgen_showcase/exhibits.v1.json`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_catalog.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_presenter.gd`, `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.gd`, `custodian/tools/validation/levels/procgen_showcase_exhibit_catalog_smoke.gd`, `custodian/tools/validation/validation_manifest.json`.
- Change: Define a dev-only JSON manifest with stable exhibit_id, wing, title, category, source authority path/id, supported runtime preview reference, and semantic selector capability (inspect_only or candidate_query). Validate every reference against actual registered runtime assets or semantic APIs, not raw Asset V2 inbox/source_work. Build bounded exhibit label/detail/readout selection and visually display only proven available states. Populate at least two canonical available examples each for Terrain/Topology/Sites; truthful available-or-N/A entries for Population and Presentation. Never infer walkability/collision from textures or export a parallel biome/route catalog.
- Preserve: Actual procgen profile, terrain, path, site, actor and Asset V2 ownership; no fabricated missing assets. Selected exhibit must be data-only, no unvalidated seed generation.
- Non-goals: Do not add a second generator, parallel gameplay authority, fake telemetry, noncanonical runtime art files, generic procgen refactor, or unrelated NPA/LoP modifications.
- Acceptance: Every available exhibit resolves real provenance; duplicates/missing refs rejected or explicitly N/A; five wings render truthful entries; selection does not alter generation or global game state; LoP/NPA unchanged.
- Validation: NEW exhibit-catalog smoke using real catalog/runtime reference fixtures and manifest registration; existing Asset V2 status/catalog checks only where touched; shell smoke; changed/diff.
- Task overrides: `none`
- Deferred: Semantic exemplar search and live-world selection deferred to PGA-6. No artwork generation.

## Implementation detail
- Follow the exact consumer/owner paths above; when a new file is named it is the intended destination, not a claim it already exists.
- Use existing functions and read-only APIs whenever possible; add just a focused controller or accessor, not large stateful blocks in `proc_gen_tilemap.gd`.
- If real code diverges materially from the packet's ownership boundary, stop and request the scoped architecture refresh instead of improvising a second system.

## Next Handoff
- Next workstream: `review-procgen-showcase-exhibit-catalog`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `normal independent fresh-context review of landed implementation`
- Next action: `Land, archive implementation, then run fresh paired review; do not advance the subsequent PGA slice until review archives complete.`
- Blockers or open questions: `Automated authoring preflight/promotion remains to be verified on live main`
