# LORDS OF PAIN TEST GALLERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `lords-of-pain-test-gallery`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `level-registry, lords-of-pain-gallery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-lords-of-pain-test-gallery`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default: new registered authored level, procgen ingress/return, third-party asset intake, and temporary interaction adapters`
- Reviewed main: `977488efdecf`
- Authoring chat: `not-recorded`
- Goal: Create a walkable in-game Lords of Pain asset test gallery that renders and exercises every semantic item in the archived pack, uses the persistent CUSTODIAN Operator and normal authored-level lifecycle, exposes at least two terrain treatments, provides gameplay-consistent interactions for activatable/breakable/loot/VFX content, and is reachable from and returnable to the procgen world through the normal registered world-ingress path with District Transfer Frame presentation.
- Completion boundary: Inventory the locally available full Lords of Pain pack; normalize only the gallery-required source through Asset Pipeline V2; scaffold and register one production-style authored test destination plus its standalone playtest wrapper; build terrain/prop/actor/VFX/UI sections covering every entry in the pack indexes; use existing gameplay systems where a clean authority exists and scene-local temporary adapters otherwise; add a procgen world ingress and return path; prove enter, walk, interact, return, and re-enter. Done means every `Asset Index (FULL)` entry has a visible/testable representation and every `Animation Index (FULL)` actor state is reachable from the gallery without introducing a competing global gameplay system.
- Current measured state: `archive/dev/LordsOfPain/` exists on main with license and FULL/DEMO asset + animation indexes, but no CUSTODIAN gallery level, registered level definition, Asset V2 gallery families, or world ingress exists. The hydrated 7.2 MB `LordsOfPain.zip` contains only `(DEMO) Lords Of Pain - Old School Isometric Assets/` and 539 PNGs. Source coverage preflight found 25 of 32 FULL semantic asset entries with no file match and 30 of 34 indexed animation states with no frames. See `custodian/content/data/dev/lords_of_pain/SOURCE_COVERAGE_BLOCKER.md` and `gallery_source_coverage.json`. The live authored-level pipeline is `AuthoredLevel2D -> LevelRegistry/RouteTraversalManager -> WorldIngressSpawner/WorldIngressSite -> LevelLoader`; the current District Transfer Frame presentation assets are consumed by `gothic_compound_travel_gate.gd`.
- Evidence: `archive/dev/LordsOfPain/Asset Index (FULL).txt`; `archive/dev/LordsOfPain/Animation Index (FULL).txt`; `archive/dev/LordsOfPain/Licence.txt`; `archive/dev/LordsOfPain/LordsOfPain.zip`; `custodian/content/data/dev/lords_of_pain/SOURCE_COVERAGE_BLOCKER.md`; `custodian/content/data/dev/lords_of_pain/gallery_source_coverage.json`; `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; `custodian/game/world/levels/authored_level_2d.gd`; `custodian/game/world/levels/level_definition.gd`; `custodian/game/world/levels/world_ingress_definition.gd`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/levels/interactable_level_exit_2d.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; `custodian/game/world/procgen/world_ingress_spawner.gd`; `custodian/game/world/gothic_compound/gothic_compound_travel_gate.gd`; `custodian/content/metadata/assets/families/meridian_hardened_floor.asset.json`.
- Task-specific authority: `AUTHORED_LEVEL_AUTHORING_PIPELINE.md` owns level/scaffold/registry/Operator ownership; `ASSET_PIPELINE_V2.md` and live `custodian/tools/assets/` own non-Operator asset intake; the two Lords of Pain FULL indexes own pack coverage; the pack license owns allowed use/modification; existing level/ingress/runtime code owns transition behavior; District Transfer Frame runtime assets own the visual vocabulary only, not a second transition authority.
- Work surface: Primary new runtime surface under `custodian/game/world/levels/authored/dev/lords_of_pain_gallery/`; level definition under `custodian/content/levels/dev/` and one entry in `custodian/content/levels/levels.json`; one standalone playtest under `custodian/scenes/debug/`; gallery metadata under `custodian/content/data/dev/lords_of_pain/`; gallery-specific source/inbox families under `custodian/asset_drop/source_work/dev/lords_of_pain/` and `custodian/asset_drop/inbox/dev_lop_*/`; runtime outputs only where Asset V2 routes them. Existing procgen/level authorities should receive configuration/integration only, not a parallel loader or portal manager.
- Change: Implement the following coherent slice.
  1. **Hydrate and inventory source.** Inspect the local worktree's `archive/dev/LordsOfPain/`. If `LordsOfPain.zip` is still an LFS pointer, run `git lfs pull --include="archive/dev/LordsOfPain/LordsOfPain.zip"` and inspect/extract it to a temporary directory outside tracked runtime paths. Build a deterministic gallery manifest that maps every FULL-index semantic item and actor animation to actual source files, dimensions, frame count/directions, license provenance, and intended Asset V2 family/state. Fail closed with a concrete missing-item report if the hydrated archive still cannot satisfy the FULL indexes; do not silently drop index entries.
  2. **Asset Pipeline V2 intake.** Do not reference repo-root `archive/dev/` directly from Godot runtime. Copy immutable source masters into `custodian/asset_drop/source_work/dev/lords_of_pain/<family_id>/` using `<state_id>_source.png`; normalize gallery inputs into `custodian/asset_drop/inbox/<family_id>/<state_id>.png`; create/update current `custodian.asset_family.v2` contracts and run the live `asset plan/status/doctor/ingest` flow. Use semantic family IDs prefixed `dev_lop_` (examples: `dev_lop_barrel`, `dev_lop_brazier`, `dev_lop_skeleton`, `dev_lop_ground_stone`, `dev_lop_glint`). Prefer current supported kinds matching the asset (`world_prop`, `effect`, `tile`, etc.); if an actor/UI item lacks a specialized supported kind, use the current generic supported kind rather than adding a new Asset V2 kind just for this gallery. Keep one coherent canvas contract per family; split a family when variants cannot share the live schema cleanly. Route these assets to a clearly dev/gallery-owned runtime domain such as `sprites/dev/lords_of_pain` if accepted by the live schema. Do not add them to production `REQUIRED_ASSETS` demand unless the implementation discovers they are intentionally becoming production dependencies.
  3. **Scaffold through the normal level tool.** Use `res://tools/level_authoring/create_level.gd` / `LevelScaffoldGenerator`, dry-run first, to create level id `lords_of_pain_test_gallery`, display name `Lords of Pain Test Gallery`, region `dev`, class `LordsOfPainTestGallery`, `Spawn_Main`, gameplay presentation, session/reset-on-entry lifecycle, and roughly a `4096x2560` authored canvas. Do not hand-create a structurally divergent level when the generator can own the standard roots/definition/playtest. Production scene must not own an Operator, camera, or PlayerController; the standalone playtest may.
  4. **Gallery spatial blockout.** Use the existing 32px level/grid vocabulary and keep primary walk aisles at least 128px wide. Build four connected, labeled sections: (a) **Stone Court** using Lords of Pain Ground Stone + Variation x2 + Darken and the static architectural/dressing props; (b) **Hardstand Interaction Yard** using the existing `meridian_hardened_floor` family for a contrasting real CUSTODIAN surface and the breakable/loot/lightable props; (c) **Actor/Combat Bays** with one contained bay each for Warrior, Knight, Fighter, Subservient, Skeleton, and Demonlord; (d) **VFX/UI Lab** with trigger stands for Zone/Glint/Flame/Flames/Glow/Swoosh and a gallery-local UI display that can render all Cursor Gauntlet, Filter Vignette, Highlight, and Loot Indicator variants without pretending those UI assets are world props. Place a Spawn/Return concourse between the sections. Exact decoration is not art-direction authority; optimize for readable comparison and short walking distances.
  5. **Coverage behavior.** Instantiate every multiplicity in the FULL index: Bones x3, Wall x3, Column x2, Gemstones x4, the complete UI variant counts, and each other semantic family. For actor families, one live display instance per actor is sufficient if the gallery control can cycle every animation named in `Animation Index (FULL).txt`; expose direction cycling for all source directions that actually exist instead of cloning 16 actors. A compact label/readout should show semantic family, state/animation, direction, frame count, and source provenance for the currently selected display.
  6. **Gameplay-consistent interaction adapters.** Reuse the live `interactable` contract (`get_interaction_prompt/position/distance`, `interact(actor)`) and existing CUSTODIAN authorities when they fit cleanly. Breakable Barrel/Crate/Brazier should accept real damage/destruction when a reusable current component exists; otherwise a gallery-local adapter may expose deterministic `INTACT -> BREAK -> RESET`. Brazier/Torch should toggle/activate their lit/flame/glow presentation. Breaking a loot-bearing prop should trigger a Gold Drop/Glint sample, and Gold/Gemstone samples should exercise the nearest existing pickup/loot presentation without mutating production economy data; if no safe inventory-backed item definition exists, use a local pickup adapter that hides/respawns and records the interaction. VFX stands trigger their one-shot/loop samples. Actor bays cycle their indexed animation states; Skeleton/Demonlord may use existing combat/damage authority only if it can be composed without invasive enemy redesign, otherwise use a gallery-local health/animation adapter that can demonstrate attack/hit/death/reset. Temporary adapters live under the gallery directory, are named `lords_of_pain_gallery_*`, and must not become global gameplay authority.
  7. **Procgen ingress and return.** Register the level as a normal `world_ingress` destination with a nonempty `ingress` block and target `Spawn_Main`. Use a custom `site_scene_path` only if needed to present the ingress with the existing District Transfer Frame asset vocabulary. Transition authority remains `WorldIngressSite/LevelLoader/RouteTraversalManager`; do not reuse `GothicCompoundTravelGate`'s connected-map travel logic as a second loader. It is acceptable to reuse its District Transfer Frame texture set/layout as presentation. Inside the gallery, place a matching District Transfer Frame-styled `InteractableLevelExit2D`/small gallery bridge that requests `return_world` through the normal authored-level return path. Entering from procgen must use the persistent live Operator and returning must restore the same procgen origin, camera binding, UI mode, and world branch.
  8. **Standalone playtest.** Keep the generated standalone playtest operational for rapid gallery iteration with a real Operator/controller/camera wrapper while preserving the production scene's no-Operator ownership rule.
- Preserve: Existing procgen generation/placement semantics; existing world ingress and route lifecycle behavior; current District Transfer Frame behavior in Gothic Compound; current `meridian_hardened_floor` family/runtime files; all Lords of Pain source masters and license text; default Operator/combat/inventory/economy behavior outside the gallery; Asset Pipeline V2 canonical naming/routing; no direct runtime dependency on repo-root archive paths.
- Non-goals: Do not make Lords of Pain the production art style; do not replace CUSTODIAN enemies/Operator/UI; do not redesign procgen, level routing, damage, inventory, loot, or interaction architecture; do not create a new global portal manager; do not implement final level art/lighting/audio; do not balance Demonlord/Skeleton as production enemies; do not redistribute the third-party pack or move the source archive out of its licensed repository context; do not require every directional frame to be simultaneously visible.
- Acceptance: (1) `lords_of_pain_test_gallery` is registered and loadable through the normal level registry; (2) procgen places one gallery ingress and the live persistent Operator can enter, walk the complete gallery, return to the exact origin, and re-enter; (3) no Operator/camera/PlayerController exists in the production level scene; (4) every semantic entry and multiplicity in `Asset Index (FULL).txt` has a deterministic manifest row and visible/testable gallery representation, with no silent omissions; (5) every actor animation named by `Animation Index (FULL).txt` can be selected and played for its available directions; (6) Lords of Pain terrain and the existing Meridian hardened floor are both visibly exercised in separate walkable sections; (7) Barrel/Crate/Brazier/Torch/loot/VFX samples perform gameplay-consistent activation/reset behavior and interaction between breakable -> loot/glint and lightable -> flame/glow is demonstrable; (8) the ingress and return frames use District Transfer Frame presentation while the existing LevelLoader/route lifecycle remains the sole travel authority; (9) no Godot resource directly references `archive/dev/LordsOfPain`; all runtime textures are cataloged Asset V2 outputs with source provenance; (10) `asset doctor` is healthy for the added families and the level/registry/ingress focused tests pass; (11) one deterministic overview plus a small set of section crops is generated for human inspection, but subjective approval is not required for completion because this is a functional test gallery rather than production art.
- Validation: Dry-run then apply the existing level scaffold path; run `custodian/tools/validation/level_scaffold_generator_smoke.gd`, `custodian/tools/validation/level_registry_contract_smoke.gd`, `custodian/tools/validation/world_ingress_spawner_smoke.gd`, `custodian/tools/validation/authored_level_ingress_return_smoke.gd`, `custodian/tools/validation/world_ingress_physics_reentry_smoke.gd`, and `custodian/tools/validation/level_camera_rebind_smoke.gd`; run `custodian/tools/assets/asset.py` doctor/status for every added `dev_lop_*` family; add one focused gallery smoke that proves manifest/index coverage, production-scene ownership, navigation between all four sections, deterministic interaction/reset state, and procgen enter/return/re-entry, then add its exact live path to this packet before closeout; run changed-file validation once and `git diff --check`. For visual evidence, machine-check asset/frame/state coverage first, then capture one full-gallery overview and only the minimum focused crops needed to show the four section types.
- Task overrides: `none`
- Deferred: Production promotion of any Lords of Pain asset; production enemy behavior/tuning for Skeleton/Demonlord; long-term reusable destructible/lightable adapters if the temporary gallery adapters reveal a real project-wide need; final District Transfer Frame presentation-component extraction; final gallery art polish.

## Suggested level scaffold starting command

Run from repository root and inspect the dry-run result before applying. Adjust only flags required by the live generator contract.

```bash
godot --headless --path custodian \
  --script res://tools/level_authoring/create_level.gd -- \
  --level-id lords_of_pain_test_gallery \
  --display-name "Lords of Pain Test Gallery" \
  --region dev \
  --class-name LordsOfPainTestGallery \
  --spawn-id Spawn_Main \
  --return-spawn-id Return_Main \
  --ingress-prompt "ENTER LORDS OF PAIN GALLERY" \
  --world-context campaign_region \
  --playtest-profile gameplay \
  --canvas-size 4096x2560 \
  --presentation-profile gameplay \
  --cache-policy snapshot_and_unload \
  --state-policy reset_on_entry \
  --dry-run
```

After the scaffold is validated, rerun without `--dry-run`, then update the generated definition to the live `world_ingress` schema and add the District Transfer Frame presentation `site_scene_path` if required.

## Asset family naming contract

New gallery-only families use:

```text
family id:   dev_lop_<semantic_family>
source_work: custodian/asset_drop/source_work/dev/lords_of_pain/dev_lop_<semantic_family>/<state>_source.png
inbox:       custodian/asset_drop/inbox/dev_lop_<semantic_family>/<state>.png
runtime:     Asset Pipeline V2 canonical output under a dev/gallery-owned sprites domain
```

Examples:

```text
dev_lop_barrel       states: intact, break
dev_lop_crate        states: intact, break
dev_lop_brazier      states: unlit, lit, break (+ fx state only if source/schema supports it)
dev_lop_gold_drop    states: idle/available source animation(s)
dev_lop_skeleton     states: indexed idle/walk/attack/death animation sources
dev_lop_demonlord    states: indexed idle/walk/attack1/attack2/intro/laugh/death
dev_lop_ground_stone states: base, variation_01, variation_02, darken
dev_lop_glint        states: glint
```

Do not guess dimensions/frame counts from filenames or the FULL index. Inspect actual hydrated source pixels and record them in the gallery manifest/family contracts.

## Documentation drift check

The FULL indexes advertise substantially more content than the GitHub-visible extracted tree currently exposes. Treat that as an **availability/provenance distinction**, not permission to silently revise the indexes. At closeout:

- keep the archive indexes/license unchanged unless the hydrated archive proves they are factually wrong;
- document the gallery manifest as the exact source-to-runtime coverage truth;
- update `CURRENT_STATE.md` and `FILE_INDEX.md` only for the new gallery/level entrypoints that are actually live;
- do not add a second missing-asset tracker;
- if the local LFS archive materially disagrees with the FULL indexes, record the mismatch in the closing summary and leave the packet incomplete until the user-visible coverage boundary is resolved.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `no`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: source preflight only; implementation was stopped before gallery/runtime creation because the hydrated archive is a DEMO subset. The scaffold dry-run accepted `full`; its first trial used the unsupported `gameplay` playtest profile and made no repository changes. Godot emitted project startup/class-cache parse and missing-import errors during scaffold validation. No gallery scene or registry entry was retained.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `blocked`
- Friction severity: `high`
- What went wrong: `the hydrated archive contains only the DEMO subset and lacks most FULL-index assets and animations`
- Root cause / contributing factors: `the repository's LordsOfPain.zip does not contain the full pack assumed by this task packet`
- Prevention / pipeline improvement: `stage the complete licensed source archive and run the recorded FULL-index coverage preflight before gallery scaffolding`
- Tooling / docs drift discovered: `the packet described a possible archive/index mismatch but current measured state did not reflect that the LFS object itself is DEMO-only`
- Follow-up: `manual-follow-up`

## Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `Provide the complete licensed Lords of Pain source archive, then resume this workstream and regenerate the coverage inventory against both FULL indexes.`
- Blockers or open questions: `current hydrated LordsOfPain.zip is DEMO-only and cannot satisfy FULL-index coverage`
