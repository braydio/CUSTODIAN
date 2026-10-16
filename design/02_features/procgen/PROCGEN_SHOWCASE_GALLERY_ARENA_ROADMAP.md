# Procgen Showcase Gallery Arena · Implementation Roadmap

**Status:** executing. PGA-1 landed and independently reviewed/passed; PGA-2 and PGA-3 implementation/review pairs are published `ready/auto`; PGA-4–8 remain manual planning drafts.
**Original architecture baseline:** `main@1326220d8172cee9322363b7a5c020acaf41f64c` (2026-10-14).
**PGA-1 verified:** implementation `b7ba5f154cbdee49ad9f56506868b95a0c02d301`; passed fresh-context review archived on main with 6 focused and 46/46 changed-file checks, zero blocking defects/gaps (2026-10-15).
**Post-review refresh:** verified against `main@8edc7252b1f1f71d057d7d9b92977b58922bfbdc` (2026-10-15); targeted authoring workflow passed and published PGA-3 pair/index at `95c89d47ac893f1c78d6cc91910a97960cac8802`. Claim eligibility still depends on fresh dispatcher claims/locks.
**Workstream family:** `procgen-showcase-`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e
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
| PGA-1 | `procgen-showcase-gallery-shell` | `none` | **complete/archived; independent review passed** | initial gallery-shell |
| PGA-2 | `procgen-showcase-exhibit-catalog` | `review-procgen-showcase-gallery-shell` | **ready/auto; review prerequisite archived/passed; dispatcher claim still controls** | catalog after gallery-shell review |
| PGA-3 | `procgen-showcase-generated-arena` | `review-procgen-showcase-gallery-shell` | **ready/auto; post-PGA-1 architecture refreshed, automatic paired preflight/queue index PASS** | generated-world host |
| PGA-4 | `procgen-showcase-generation-controls` | `review-procgen-showcase-generated-arena` | draft/manual; explicit ChatGPT/user refresh after dependencies land | seed/session lifecycle |
| PGA-5 | `procgen-showcase-runtime-inspector` | `review-procgen-showcase-generation-controls, review-procgen-showcase-exhibit-catalog` | draft/manual; explicit ChatGPT/user refresh after dependencies land | read-only runtime diagnostics |
| PGA-6 | `procgen-showcase-exemplar-search` | `review-procgen-showcase-exhibit-catalog, review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector` | draft/manual; explicit ChatGPT/user refresh after dependencies land | semantic exemplar lookup |
| PGA-7 | `procgen-showcase-seed-comparison` | `review-procgen-showcase-generation-controls, review-procgen-showcase-runtime-inspector` | draft/manual; explicit ChatGPT/user refresh after dependencies land | seed comparison/capture |
| PGA-8 | `procgen-showcase-integration-closeout` | `review-procgen-showcase-exemplar-search, review-procgen-showcase-seed-comparison` | draft/manual; explicit ChatGPT/user refresh after dependencies land | integration validation |

**Count:** 16 packets. PGA-1's implementation and independent review are archived. PGA-2's packet pair was already promoted to ready/auto and its PGA-1 review dependency is now satisfied; check dispatcher claims/locks before claiming. PGA-3 completed its required post-PGA-1 architecture refresh; GitHub automatic authoring preflight passed and promoted both PGA-3 packets to ready/auto at `95c89d47`. Check live dispatcher claims/locks before any implementation claim. PGA-4 through PGA-8 retain their mandatory future manual/API refresh after their upstream reviews. A completed implementation alone does **not** unblock a review-dependent successor.

## Sequential implementation preparation (2026-10-15)

**User execution preference:** implement in ascending PGA slice order, even where the dependency DAG would technically permit independent parallel implementations. Do not create concurrent gallery-owner worktrees merely because both PGA-2 and PGA-3 are `ready/auto`. Run the independent fresh-context review and archive it before starting the next implementation. Planned sequence: PGA-2 and its review, PGA-3 and its review, PGA-4 and review, PGA-5 and review, PGA-6 and review, PGA-7 and review, PGA-8 and review. PGA-1 implementation/review are already archived complete.

A preparatory live-main audit updated exact-file-path implementation notes and paired independent-review probes for **PGA-4 through PGA-8**. These remain **`draft/manual`, NOT claimable**: PGA-4 needs the actual PGA-3 host/return API; PGA-5 needs the landed catalog and session exports; PGA-6 needs proven catalog query predicates, inspector read APIs and measured generation cost; PGA-7 needs real session/inspector/capture APIs; PGA-8 needs all predecessor archives and real end-to-end proof. After each predecessor's independent review passes, reconcile its successor against the actual archived diff and receipt in a planning refresh, run `python3 custodian/tools/agent/validate_task_packet_authoring.py <implementation-packet> <paired-review-packet>`, and only then safely publish a truly ready pair plus regenerated queue index. Until then, the new notes are a head start, not permission to self-promote or bypass the queue.

**Concrete read authorities verified during preparation:** `custodian/game/world/levels/generated_region_level.gd::prepare_generated_region`; `custodian/game/world/procgen/generation/accepted_world_export.gd::ProcgenAcceptedWorldExport.LEVEL_DATA_SCHEMA` and detached `build_level_data`; `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd` and `CandidateSemanticAdapter.fingerprint_runtime_state`; `custodian/debug/debug_snapshot_collector.gd` (background reference only, not a second gallery overlay authority). Do not infer future API names for the not-yet-landed gallery host, catalog, inspector or session.

**Authoring backlinks:** PGA-4–8 implementation/review packets now reuse the original program authoring chat already recorded at the roadmap top. Their `Refresh planning chat: not-recorded` fields remain deliberately unresolved until the actual current conversation URL is furnished, rather than falsely identifying an older conversation as this refresh.

## Workflow, asset and acceptance guardrails

- Root `AGENTS.md`, `custodian/AGENTS.md` and `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` own worktree/dispatch/paired-review policy. PGA-1 and PGA-2 pairs already passed automatic authoring promotion; PGA-1 also passed implementation/review closeout. PGA-3's refreshed pair passed the GitHub targeted authoring handoff and was published ready/auto with a verified managed index. This is **not** proof of a workstream claim, implementation, or passed post-land review.
- PGA-4+ have no auto-handoff marker and retain explicit future manual review/architecture-refresh gates. Use exact `Review:` pairing and never bypass dispatch locks.
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

## PGA-1 Gallery Shell (2026-10-15)

`procgen_showcase_gallery` is now registered as a reset-on-entry dev destination.
Its authored floor regions connect the Terrain, Topology, Sites, Population,
and Presentation wings around a central concourse; the arena threshold remains
collision-sealed and labeled as unloaded. The production destination owns no
Operator, controller, camera, generator, or generated map. Its standalone
playtest wrapper owns one real Operator/controller/camera, and the registered
ingress/return path reuses the same Operator across reset-on-entry visits.
PGA-1 implementation and its fresh-context independent review are **complete**.
The archived review reports zero blocking defects/material gaps and a green
46/46 changed-file sweep. PGA-2's catalog and PGA-3's generated arena are both ready/auto,
**subject to the dispatcher's current locks/claims**. The generated arena remains outside the
PGA-1 shell's scope.

## PGA-3 post-PGA-1 architecture refresh (2026-10-15)

The landed shell provides `Markers/ArenaThreshold` at `Vector2(0, -520)`,
a collision-backed sealed north threshold `(-210,-520) -> (210,-520)`, and a
single standalone playtest Operator/controller/camera under
`GameRoot/World`. The threshold remains **sealed**: PGA-3 must use a deliberate
interaction and validated transfer, not open the collision rail or connect
arbitrary generation to the authored floor.

`GeneratedRegionLevel.prepare_generated_region(request)` is the existing
real-map staging/validation authority. It takes `scene_path`, `seed`,
`map_size`, `room_count`, `profile` and `spawns`, then verifies the
canonical main playable component, spawn and runtime navigation; it exposes
`has_spawn`, `get_spawn_position`, `activate_route_node` and camera refresh.
PGA-3 should wrap that adapter in one disposable child host, preserve the
outer gallery as the sole LevelLoader active destination, and refuse transfer
until staged map/spawn/camera/nav state is valid. Compute map/gallery spatial
separation from actual bounds rather than inventing an authored corridor.

A failed or interrupted stage must retain gallery walkability, Operator
identity and camera binding. On return, restore the gallery camera via
`AuthoredLevel2D.refresh_route_camera` before releasing/discarding generated
state; the existing outer `return_world` path remains untouched. No change
to the agreed five-wing layout, seal or encounter/candidate authority is
authorized. The PGA-3 implementation and review packets contain exact-path
handoffs. Automatic authoring publication **passed** in commit `95c89d47`; implementation and independent review remain outstanding.

## Future scope, deliberately not included

Fictional Hub Archive interpretation, production gameplay placement, new source artwork, a novel generic forced-feature generator, and a complete new actor/NPA system are follow-ons, not hidden PGA acceptance.
