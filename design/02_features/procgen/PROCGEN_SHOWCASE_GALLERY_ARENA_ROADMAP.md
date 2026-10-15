# Procgen Showcase Gallery Arena · Implementation Roadmap

**Status:** authorized planning program; packet promotion / manual refresh follows live DAG and per-pair authoring preflight.
**Baseline inspected:** `main@1326220d8172cee9322363b7a5c020acaf41f64c` (2026-10-14).
**Workstream family:** `procgen-showcase-`
**Authoring chat:** not-recorded (replace with exact current conversation URL once provided; never substitute an older planning URL).
**Estimate locked:** **8 implementation workstreams + 8 fresh-context paired reviews = 16 task packets**, plus this roadmap; corrections spawned by findings are not pre-counted.

## Observed live authority and decision

- `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/` is a registered, scoped authored asset gallery, using a manifest and one playable standalone Operator.
- `custodian/game/world/levels/authored/dev/npa_showcase_arena/` is a registered authored 5-zone actor proving ground; `npa_showcase_arena_foundation_smoke.gd` is its level contract proof. Reuse conventions, not its NPA actors as fake procgen tests.
- `custodian/game/world/levels/generated_region_level.gd` already instantiates the real `res://game/world/procgen/proc_gen_map.tscn`, configures explicit seed/map size/room count/profile, awaits `level_data_ready`, requires canonical valid spawn, main playable component and runtime navigation, and binds the camera. It currently assumes its own map; do not copy generation code into the gallery.
- `custodian/game/world/levels/level_loader.gd` supports **one** active authored or generated level; its generated-region path uses asynchronous staging. A gallery-embedded arena is therefore a **dev-only staged child map**, not a second nested LevelLoader active level.
- `custodian/game/world/procgen/custodian_contract_map.gd` and `custodian/game/world/procgen/generation/{candidate_evaluator,candidate_semantic_adapter,procgen_candidate_materializer}.gd` own production candidate selection. Read only; no alternate preview generator.
- `custodian/content/levels/levels.json`, `custodian/tools/validation/validation_manifest.json` and existing `LevelPlaytestBootstrap` own registration/test patterns.
- Production `ProcGenTilemap` under `custodian/game/world/procgen/proc_gen_tilemap.gd` is large; new dev controller state belongs in focused new files, with at most a narrow read-only accessor on existing authorities.
- `design/04_architecture/REGION_GENERATION_SYSTEM.md` still describes an early BSP/Edgar phase picture despite later accepted-candidate/spawn/biome work. Treat that section as a drift candidate; update only in the appropriate source-owner documentation pass, never as a stealth architecture rewrite. NPA program planning headers likewise require rechecking against archival proof before quoting current completion.

## Spatial and lifecycle lock

One dev-only registered authored destination, with five accessible curated wings around an isolated arena portal/threshold. The gallery never owns collision/nav/world generation. Real generated map creation happens in a dedicated host; map acceptance, terrain, route, playability, spawn and candidate authority remain unchanged. Gallery and generated map may use an explicit transition to a safe spawn: do not pretend arbitrary seeded topology physically joins an authored hallway. Exactly one real Operator/controller/camera in the standalone wrapper; production scene has none. Generated world is disposable and may be regenerated only through transactional staging. An absent catalog entry renders N/A; no art/source files from Asset V2 inbox are consumed as runtime.

## Program DAG and packet accounting

| Slice | Implementation (paired review is `review-<id>`) | Depends on completed *reviews* | Publication now | Scope |
| --- | --- | --- | --- | --- |
| PGA-1 | `procgen-showcase-gallery-shell` | `none` | draft/manual + automatic authoring handoff → ready/auto on validator PASS | initial gallery-shell |
| PGA-2 | `procgen-showcase-exhibit-catalog` | `review-procgen-showcase-gallery-shell` | draft/manual + automatic authoring handoff → ready/auto on validator PASS | catalog after gallery-shell review |
| PGA-3 | `procgen-showcase-generated-arena` | `review-procgen-showcase-gallery-shell` | draft/manual; explicit ChatGPT/user refresh after dependencies land | generated-world host |
| PGA-4 | `procgen-showcase-generation-controls` | `review-procgen-showcase-generated-arena` | draft/manual; explicit ChatGPT/user refresh after dependencies land | seed/session lifecycle |
| PGA-5 | `procgen-showcase-runtime-inspector` | `review-procgen-showcase-generation-controls, review-procgen-showcase-exhibit-catalog` | draft/manual; explicit ChatGPT/user refresh after dependencies land | read-only runtime diagnostics |
| PGA-6 | `procgen-showcase-exemplar-search` | `review-procgen-showcase-exhibit-catalog, review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector` | draft/manual; explicit ChatGPT/user refresh after dependencies land | semantic exemplar lookup |
| PGA-7 | `procgen-showcase-seed-comparison` | `review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector` | draft/manual; explicit ChatGPT/user refresh after dependencies land | seed comparison/capture |
| PGA-8 | `procgen-showcase-integration-closeout` | `review-procgen-showcase-exemplar-search, review-procgen-showcase-seed-comparison` | draft/manual; explicit ChatGPT/user refresh after dependencies land | integration validation |

**Count:** 16 packets. PGA-1 is root. PGA-2 has the mechanical PGA-1 review dependency but its manifest/selection semantics are already specified; it can be auto-promoted after targeted preflight. PGA-3 through PGA-8 intentionally require a **manual architecture/API refresh** after upstream reviews land; their contracts are durable scopes, not authorization to claim prematurely. A completed implementation alone does **not** unblock its review-dependent successor.

## Workflow, asset and acceptance guardrails

- Root `AGENTS.md`, `custodian/AGENTS.md` and `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` own worktree/dispatch/paired-review policy. For PGA-1/PGA-2 both sides have `Authoring handoff: auto` and start `draft/manual`; GitHub workflow promotion is contingent on passing the targeted validator and queue checks. Until promoted and observed on main they are **not confirmed claimable**.
- PGA-3+ have no auto-handoff marker; an intentional live-main refresh, targeted authoring preflight, index generation and safe publication are necessary first. Use exact `Review:` pairing and never bypass dispatch locks.
- No new images are required for the first eight slices. Existing ingested production art and canonical metadata only. If later explicitly commissioned: separate Asset Pipeline V2 family under `custodian/content/metadata/assets/families/`, source in `custodian/asset_drop/source_work/procgen_showcase/<family>/<state>_source.png`, normalized intake `custodian/asset_drop/inbox/<family>/<state>.png`; exact source/normalized pixels and frames must be established against the actual family/consumer before creating a claimable art task. Do not invent them now.
- Each implementation adds its own focused smoke under `custodian/tools/validation/levels/` and registers ownership in `validation_manifest.json`. Run existing directly affected smoke before changed-file closeout. Gallery controls must never mutate Hub, world acceptance, candidate selection, real actor health, or canonical collision/nav.
- Inspect performance of generated seeds before offering unbounded search or concurrent maps. Exemplar search must be bounded and may truthfully fail; comparison stores lightweight receipts and at most one active generated world.
- Human artistic approval is not silently inferred from technical tests; use narrow visual review only where presentation cannot be verified with state/geometry/pixel metrics.
- **Documentation drift:** on every land, compare actual code and archived review truth with `CURRENT_STATE.md`, `FILE_INDEX.md`, this roadmap, and relevant NPA/procgen spec; update only actually stale assertions without creating duplicate trackers.
- **Publication verification:** fetch live `main`, inspect packet headers and generated README/dispatcher state. A remote push or `Authoring handoff: auto` marker by itself is not proof of validator pass, queue eligibility, or execution.

## Proposed human-review milestones

1. After PGA-1 reviewed: spatial layout/threshold and gallery walkaround; reconcile PGA-3 host.
2. After PGA-3 reviewed: true generated spawn, camera/nav and safe exit proof; refresh PGA-4/5.
3. After PGA-5 reviewed: confirm which semantics have truthful query predicates; refresh PGA-6/7.
4. After PGA-7 reviewed: end-to-end UI/visual acceptance for PGA-8 without repeating code evidence.

## Packet destinations

- PGA-1: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_GALLERY_SHELL.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_GALLERY_SHELL.md`
- PGA-2: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_EXHIBIT_CATALOG.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_EXHIBIT_CATALOG.md`
- PGA-3: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_GENERATED_ARENA.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_GENERATED_ARENA.md`
- PGA-4: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_GENERATION_CONTROLS.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_GENERATION_CONTROLS.md`
- PGA-5: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_RUNTIME_INSPECTOR.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_RUNTIME_INSPECTOR.md`
- PGA-6: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_EXEMPLAR_SEARCH.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_EXEMPLAR_SEARCH.md`
- PGA-7: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_SEED_COMPARISON.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_SEED_COMPARISON.md`
- PGA-8: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_INTEGRATION_CLOSEOUT.md` and `custodian/docs/ai_context/task_packets/REVIEW_PROCGEN_SHOWCASE_INTEGRATION_CLOSEOUT.md`

## Future scope, deliberately not included

Fictional Hub Archive interpretation, production gameplay placement, new source artwork, a novel generic forced-feature generator, and a complete new actor/NPA system are follow-ons, not hidden PGA acceptance.
