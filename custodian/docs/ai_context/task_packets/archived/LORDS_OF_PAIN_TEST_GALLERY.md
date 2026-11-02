# LORDS OF PAIN TEST GALLERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `lords-of-pain-test-gallery`
- Status: `complete`
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
- Reviewed main: `76b91527c17d`
- Authoring chat: `not-recorded`
- Implementation sidecar: `custodian/docs/ai_context/task_packets/support/LORDS_OF_PAIN_TEST_GALLERY_IMPLEMENTATION_GLOSSARY.md`
- User scope update (2026-10-03): use the available DEMO indexes for this gallery. The user approved dropping the three DEMO-index entries with no source files: Cursor Gauntlet, Rocks, and Mushrooms. This scope update supersedes any FULL-index coverage requirements below or in the supporting sidecar. Cover the remaining seven semantic entries (Warrior, Skeleton, Highlight, Loot Indicator, Gold Drop, Glint, Ground Stone) and all four DEMO animation states (Warrior armed idle/walk; Skeleton default walk/special death). Record all three exclusions in `gallery_manifest.json` and prove they have no source/runtime binding; do not fabricate substitutes.
- Goal: Create a walkable in-game gallery for the locally available Lords of Pain DEMO pack, use the persistent CUSTODIAN Operator and normal authored-level lifecycle, and connect it to procgen through registered ingress and return routing with District Transfer Frame presentation.
- Completion boundary: The DEMO manifest accounts for seven available semantic entries and five indexed animation entries (Gold Drop plus four actor states), with explicit records for the three user-approved exclusions. All directional variants for indexed animations are staged through Asset V2 and selectable in the gallery. The registered production destination and standalone playtest load, and normal procgen enter/return/re-entry contracts pass. FULL-pack-only requirements in historical text below are superseded by the user scope update above.
- Current measured state: seven DEMO semantics were normalized into 84 Asset V2 runtime outputs across seven families. The manifest records the five DEMO animation entries, all 16 directions for each, source provenance, and three user-approved exclusions. The generated level is registered with its own ingress presentation and District Transfer Frame return.
- Evidence: `archive/dev/LordsOfPain/Asset Index (DEMO).txt`; `archive/dev/LordsOfPain/Animation Index (DEMO).txt`; `archive/dev/LordsOfPain/Licence.txt`; `archive/dev/LordsOfPain/LordsOfPain.zip`; `custodian/content/data/dev/lords_of_pain/gallery_manifest.json`; `custodian/docs/ai_context/task_packets/evidence/lords_of_pain_test_gallery/`; `custodian/docs/ai_context/task_packets/support/LORDS_OF_PAIN_TEST_GALLERY_IMPLEMENTATION_GLOSSARY.md`; active level and Asset V2 authorities.
- Task-specific authority: `AUTHORED_LEVEL_AUTHORING_PIPELINE.md`, `ASSET_PIPELINE_V2.md`, the two DEMO indexes, user scope update above, pack license, and current route runtime.
- Work surface: Use the scaffold-generator-owned paths exactly: `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/` for the production scene/script, generated standalone playtest, authoring scene, and gallery-local presentation; `custodian/content/levels/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery.json` plus its `.levelgen.json`; one entry in `custodian/content/levels/levels.json`; focused smoke at `custodian/tools/validation/levels/lords_of_pain_test_gallery_smoke.gd`; gallery metadata under `custodian/content/data/dev/lords_of_pain/`; gallery-specific source/inbox families under `custodian/asset_drop/source_work/dev/lords_of_pain/` and `custodian/asset_drop/inbox/dev_lop_*/`; runtime outputs only where Asset V2 routes them. Existing procgen/level authorities remain the transition authority; do not add a parallel loader or portal manager. See the implementation sidecar for current APIs and exact scaffold paths.
- Change: Implement the DEMO-scoped slice.
  1. Inventory the hydrated archive against the two DEMO indexes. The manifest must include Warrior, Skeleton, Highlight, Loot Indicator, Gold Drop, Glint, and Ground Stone, plus Gold Drop and all four DEMO actor animation entries. Record Cursor Gauntlet, Rocks, and Mushrooms as user-approved exclusions with missing-source evidence.
  2. Preserve immutable source masters under `custodian/asset_drop/source_work/dev/lords_of_pain/`, normalize seven supported families under `dev_lop_*`, and use Asset V2 plan/status/doctor/ingest. Runtime resources must not reference `archive/dev/LordsOfPain/` directly.
  3. Scaffold and register the `4096x2560` authored destination through `create_level.gd`, with a named `Spawn_Main`, normal world-ingress definition, reset-on-entry lifecycle, production scene free of Operator/camera/controller ownership, and generated standalone playtest wrapper.
  4. Build a connected, labeled walking layout that shows the DEMO Ground Stone beside actual `meridian_hardened_floor` art, Gold Drop and Glint samples, Highlight and Loot Indicator as UI samples, and Warrior/Skeleton displays. Cycle all 16 authored directions and the applicable animation states from the gallery controls. Keep the currently selected semantic/state/direction readable.
  5. Add a local pickup/reset interaction for Gold Drop. Use the existing `WorldIngressSite` → `LevelLoader` / `RouteTraversalManager` entry and return lifecycle, and District Transfer Frame presentation at the procgen ingress and gallery return. Preserve the same Operator and verify return/re-entry with the focused lifecycle tests.
- Preserve: Existing procgen generation/placement semantics; existing world ingress and route lifecycle behavior; current District Transfer Frame behavior in Gothic Compound; current `meridian_hardened_floor` family/runtime files; all Lords of Pain source masters and license text; default Operator/combat/inventory/economy behavior outside the gallery; Asset Pipeline V2 canonical naming/routing; no direct runtime dependency on repo-root archive paths.
- Non-goals: Do not make Lords of Pain the production art style; do not replace CUSTODIAN enemies/Operator/UI; do not redesign procgen, level routing, damage, inventory, loot, or interaction architecture; do not create a new global portal manager; do not implement final level art/lighting/audio; do not balance Demonlord/Skeleton as production enemies; do not redistribute the third-party pack or move the source archive out of its licensed repository context; do not require every directional frame to be simultaneously visible.
- Acceptance: (1) `lords_of_pain_test_gallery` is registered and loadable through the normal level registry; (2) the normal procgen ingress and return lifecycle smokes pass, preserving the live Operator/camera and proving re-entry; (3) the production level scene contains no Operator, camera, or PlayerController; (4) the manifest covers exactly seven available DEMO semantic entries, records all three user-approved exclusions, and contains no direct archive runtime path; (5) Gold Drop, Glint, Highlight, Loot Indicator, and Ground Stone are visibly/testably bound; (6) all 16 authored directions for Warrior idle/walk and Skeleton walk/death are represented in the manifest and selectable in the gallery; (7) Lords of Pain Ground Stone and real Meridian hardened floor runtime art appear in separate walkable sections; (8) both ingress and return use District Transfer Frame presentation while existing WorldIngressSite/LevelLoader/RouteTraversalManager remain the travel authority; (9) all seven added Asset V2 families pass `asset doctor`; (10) the scaffold, registry, ingress, return, physics re-entry, camera rebind, and focused gallery smokes pass. Human art-direction approval is not required for this functional gallery.
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
  --exit return_world:ReturnWorld \
  --ingress-prompt "ENTER LORDS OF PAIN GALLERY" \
  --world-context campaign_region \
  --playtest-profile full \
  --canvas-size 4096x2560 \
  --presentation-profile gameplay \
  --cache-policy snapshot_and_unload \
  --state-policy reset_on_entry \
  --dry-run
```

After the scaffold is validated, rerun without `--dry-run`, then update the generated definition to the live `world_ingress` schema and add the District Transfer Frame presentation `site_scene_path` if required. The generated `ReturnWorld` starts as `LevelExit2D`; replace it with or restyle it as an `InteractableLevelExit2D` while preserving `exit_id = &"return_world"`.

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

Do not guess dimensions/frame counts from filenames. Inspect actual hydrated source pixels and record them in the gallery manifest/family contracts.

## Documentation drift check

The active scope is the two DEMO indexes. The user has approved three source-missing DEMO exclusions; do not infer or implement coverage from the superseded FULL scope. At closeout:

- keep the archive indexes/license unchanged unless the hydrated archive proves they are factually wrong;
- document the gallery manifest as the exact source-to-runtime coverage truth;
- update `CURRENT_STATE.md` and `FILE_INDEX.md` only for the new gallery/level entrypoints that are actually live;
- do not add a second missing-asset tracker;
- record the exact DEMO-to-manifest coverage and exclusions; retain both source indexes and license unchanged.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: DEMO manifest; seven healthy Asset V2 family contracts/catalog entries; generated production/playtest scenes and registry definition; one overview and two bounded crops; passing scaffold, registry, ingress, return, physics re-entry, camera rebind, and gallery smokes.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `the first batch launch started parallel Asset V2 transactions; interruption left isolated temporary files. Sequential reruns replaced partial outputs and completed normal archive transactions. The scaffold's absolute design-doc path also failed project-relative registry validation. Initial changed-file validation found no owner mapping for the new gallery assets/scenes; the gallery smoke is now registered for those files.`
- Root cause / contributing factors: `a yielded shell session was treated as a completed sequential ingest; the level generator serialized a checkout-specific absolute design path; the validation manifest lacked a DEMO gallery owner/test entry`
- Prevention / pipeline improvement: `poll each transaction to completion before starting the next; keep generated definition doc paths project-relative; register new scoped runtime assets and scenes with a focused owner smoke`
- Tooling / docs drift discovered: `sidecar example uses unsupported playtest profile gameplay; live values are movement/combat/full. Superseded FULL requirements and paired-review criteria were reconciled to the user's DEMO scope.`
- Follow-up: `fixed-in-scope`

## Handoff

- Next workstream: `review-lords-of-pain-test-gallery`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `Start the paired fresh-context post-land review against the archived DEMO-scoped packet.`
- Blockers or open questions: `none`
