# Procgen Showcase Exemplar Search

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-showcase-exemplar-search`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `procgen-showcase-exhibit-catalog, procgen-showcase-generation-controls, procgen-showcase-runtime-inspector`
- Locks: `procgen-showcase-exemplar`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `Paired review retired 2026-11-12. Focused positive/negative/cancellation real-world smoke, predecessor regressions, semantic parity and changed-file checks prove the bounded transaction boundary; owner reviews landing.`
- Reviewed main: `98dcde474ed92ae36a1d45c5f8faf94b1e75d1f6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Visual review: `none`
- Goal: Make SHOW IN GENERATED WORLD find a reproducibly generated accepted world containing an actually proven catalog semantic exhibit, using bounded serialized search without forced features or corrupting the currently accepted map.
- Completion boundary: A real, deterministic semantic match is proven in an accepted generated map; nonmatches/cancellation/unsupported entries never silently replace or mutate the accepted map; gallery selection and arena-entry controls are integrated; focused and affected regression checks pass; owner reviews the landing. No fake matches or proxy closure.
- Current measured state: PGA-5 merged as PR #155 at `98dcde474ed92ae36a1d45c5f8faf94b1e75d1f6`. `exhibits.v1.json` contains nine entries, all `inspect_only`; there are zero approved `candidate_query` selectors today. `ProcgenArenaSession.request_generation()` stages normally but `_on_candidate_staged()` automatically accepts every ready candidate; it has no search-only preacceptance semantic gate. `ProcgenArenaHost.get_inspector_snapshot()` currently refuses unaccepted hosts. No generic forced-exhibit hook exists.
- Evidence: `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/content/data/dev/procgen_showcase/exhibits.v1.json`; `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_arena_{session,host}.gd`; `procgen_gallery_inspector.gd`; PR #155 focused-smoke PASS and canonical changed-file 8/8 PASS.
- Task-specific authority: Root and custodian `AGENTS.md`; `design/02_features/procgen/PROCGEN_SHOWCASE_GALLERY_ARENA_ROADMAP.md`; `custodian/game/world/procgen/generation/` (read-only generation/candidate authority); `custodian/game/world/levels/generated_region_level.gd`.
- Work surface: `custodian/game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exemplar_resolver.gd`; `procgen_arena_session.gd`; `procgen_arena_host.gd`; `procgen_exhibit_catalog.gd`; `procgen_exhibit_presenter.gd`; `procgen_gallery_controls.gd`; `procgen_showcase_gallery.gd`; `custodian/content/data/dev/procgen_showcase/exhibits.v1.json`; `custodian/tools/validation/levels/procgen_showcase_exemplar_smoke.gd`; `custodian/tools/validation/validation_manifest.json`; related packet/roadmap/summary/index updates.
- Change: Integrate a search-owned finite, deterministic seed enumerator with session-controlled serialized staging and **predicate-gated pre-acceptance**. Inspect only detached read-only candidate data; discard nonmatching candidates before promotion. Only exact source-ID predicates with demonstrated positive real-map proof may enable catalog `candidate_query`; all others remain truthfully disabled. Preserve current world, Operator, camera and ordinary regeneration semantics across NOT_FOUND/UNSUPPORTED/CANCELLED/FAILED.
- Preserve: One canonical generator, one accepted arena host, session/token ownership, profile/map size/room count, spawned player, navigation and camera, generated-world determinism and fingerprint, gallery and LevelLoader authority, prior untracked/ignored files, Asset Pipeline V2 boundaries.
- Non-goals: No second generator, forced terrain/site insertion, synthetic semantic telemetry, global search backend, content assets, unrestricted multi-seed concurrent exploration, speculative teleportation, unrelated Sundered Keep smoke corrections or generic procgen rewrites.
- Acceptance: One real positive fixture produces a truthful MATCH and matching accepted fingerprint; negative finite search reports NOT_FOUND while preserving original host/seed/fingerprint; cancellation fences late callbacks and keeps accepted map; unsupported never launches generation; search search state and UI are accurate; no duplicate Operator/camera/accepted maps.
- Validation: `procgen_showcase_exemplar` (register exact ID in `validation_manifest.json`), `procgen_showcase_exhibit_catalog`, `procgen_showcase_generated_arena`, `procgen_showcase_generation_controls`, `procgen_showcase_runtime_inspector`, `procgen_candidate_semantic_model`, `procgen_accepted_world_export_parity`, `contract_world_playable_region_spawn_validity`, and canonical changed-file validation; `git diff --check`.
- Task overrides: `none`
- Deferred: Topology forcing, unproven site/presentation predicates and artistic seed comparison require separate production designs or PGA-7.

## Exact implemented-API contract and changes (RC-079)

1. `ProcgenExhibitCatalog.load_report()/validate_manifest()` already verifies wing, source path/ID and preview resource. It accepts `selector_capability` values `inspect_only` and `candidate_query`, but the nine live entries are ALL `inspect_only`. Add a fail-closed predicate registry validating explicit `predicate_id`, `predicate_version` and `source_authority_id`. Do not imply a working selector merely from the accepted enum.
2. `ProcgenArenaSession` owns `_accepted_host`, `_staging_host`, `_token`, `_accepted_revision`, `request_generation(seed,preset)`, `cancel_generation()`, `session_updated(status)` and `get_accepted_inspector_snapshot()`. Its normal `_on_candidate_staged` accepts all valid staged maps; implement a *search-specific* conditional acceptance path without changing ordinary PGA-4 reroll semantics. Reject overlapping ordinary generation/search; retain accepted world throughout unmatched staging. On terminal match use the same accepted-host promotion and status publication machinery; on failure discard only staging and preserve prior accepted revision/fingerprint.
3. `ProcgenArenaHost` already stages a real `GeneratedRegionLevel` child at the gallery sibling path and computes the accepted generation fingerprint. Its `get_inspector_snapshot()` returns detached `data.biome_id_by_cell`, `data.region_tiles`, `exhibit_provenance`, spawn/playability and fingerprint but refuses unaccepted staging ownership. Add ONLY a narrow read-only, detached staged semantic projection accessible to the owning session after successful staging, never directly to untrusted UI. It must never export map/host/Node/Resource instances or forge accepted-state identity.
4. `procgen_exemplar_resolver.gd` owns a revisioned search token, requested exhibit/predicate, effective preset/profile key, exact seed enumeration, finite candidate budget, attempts and terminal statuses `MATCH`, `NOT_FOUND`, `UNSUPPORTED`, `FAILED`, `CANCELLED`. Ascending deterministic seeds within 0..2147483647, explicit no-wrap behavior, serialized staging, no per-frame full map scan. Determine a conservative cap from measured candidate latency and local resources; record actual attempt count, cap and explicit failure reasons. Cancel or newer token fences every callback.
5. Candidate predicate proof: inspect actual real accepted fixtures for `terrain.scrubland`=`scrubland`, `terrain.woodland`=`woodland`, `topology.room`=`labyrinth_room`, `topology.corridor`=`labyrinth_corridor` using `data.biome_id_by_cell`, `data.region_tiles` and exact-ID `exhibit_provenance`. These are PROPOSED, not presently verified as search predicates. Only enable proven positive reproducible entries individually. Leave faction worksite, story room, population unavailable and terrain stamps inspect-only unless an equally direct canonical proof is demonstrated in this scope. If no positive predicate proves out, fail closed, do not release fake enabled buttons, report missing authority as scoped blocker.
6. Use current `procgen_exhibit_presenter.gd` selected wing/item, `procgen_gallery_controls.gd` status controls and `procgen_showcase_gallery.gd` composition. Add SHOW IN GENERATED WORLD only for validated entries. For others show disabled/UNSUPPORTED with reason. During search display seed, attempt/cap, preset and rejection/cancel status; provide cancel, disallow ordinary generation overlap, do not move Operator while evaluating. On MATCH preserve existing safe accepted arena entry rather than teleporting to an unverified semantic cell.
7. Positive cache (if added) stores immutable receipt only under complete seed/effective-preset/semantic-predicate-version/generator-contract identity and revalidates on newly realized map. No cache is required for the initial slice; omitting it is preferable to an unsafe cache.

## Focused real Godot test

Create `custodian/tools/validation/levels/procgen_showcase_exemplar_smoke.gd` and register ID `procgen_showcase_exemplar` with exact ownership of gallery scripts, manifest and smoke. Test: (A) deterministic MATCH on real accepted world with proven semantic target and equal accepted fingerprint; (B) exhausted finite negative returns NOT_FOUND without accepted map/Operator/camera/fingerprint changes; (C) cancellation during staging releases ownership and prevents late acceptance; (D) unsupported no generation; (E) repeated same inputs yield same seed and semantic answer; (F) no leaked extra active map, duplicate Operator/camera, stale callback/inspector; (G) PGA-4 ordinary reroll and PGA-5 inspector still operate normally.

## Execution, publication and stopping conditions

- This packet is explicitly user-authorized for implementation following PGA-5 landing, and is published as `draft/manual` with `Authoring handoff: auto`. The existing GitHub targeted authoring workflow must validate and promote to `ready/auto` before `dispatch.py claim`. DO NOT claim draft bytes or modify the coordination-root worktree.
- Once promoted, fetch current `origin/main`, verify the promoted exact packet, existing claims/writers, resource headroom and the settled PGA-5 merged SHA; then claim only `procgen-showcase-exemplar-search` in an isolated V2 checkout. No prior worktree-retirement ratio exists. Do not create alternate claims or new review packets.
- Implement, run the focused positive/negative/cancel smoke, affected PGA-2/3/4/5 and semantic/export/playability regressions, and changed-file gate. Push first coherent SHA and draft PR for ChatGPT-owned GitHub landing. Preserve normal rollback and registry/Asset V2 restrictions.
- Return verified predicate IDs, known real positive seed, per-attempt latency/cap, actual acceptance/negative/cancel receipts, smoke results, branch SHA and draft PR. Do not merge or invent a result.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Refresh instruction: `Owner-authorized RC-079 planning refresh is complete against PGA-5 landed main. The execution agent may reconcile minor runtime details within the fixed scope but must not redefine semantic predicates without reproducible source evidence. Automatic authoring retry should validate/promote this still-opted draft; runtime predicate proofs are implementation acceptance, not a second planning prerequisite.`

## Next Handoff

- Next workstream: `procgen-showcase-seed-comparison`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af77714-565c-83ea-be53-4049119e3619`
- Refresh reason: `PGA-7 requires actual landed PGA-6 search and inspector APIs and a distinct owner-authorized realized-API refresh.`
- Next action: `After PGA-6 merge, ChatGPT performs the PGA-7 packet refresh on remote main and delegates only implementation to Codex. No paired review task.`
- Blockers or open questions: `No confirmed candidate_query positives until runtime proof; the implementer must fail closed if canonical identities cannot be demonstrated.`
