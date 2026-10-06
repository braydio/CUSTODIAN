# ASSET DOWNLOADS INTAKE SWEEP

- Packet schema: `custodian.task_packet.v2`
- Workstream: `asset-downloads-intake-sweep`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `asset-pipeline`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `asset-pipeline, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Reviewed main: `7a8ad89c84263043d2fb127576ba0aba47789f06`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Branch: `agent/asset-downloads-intake-sweep`

## Goal

Close the known local asset-intake backlog without turning `~/Downloads` into a production authority.

This slice has two responsibilities only:

1. publish the supplied missing Awakening Recovery Ambulatory `service_basin_b` through its existing Asset Pipeline V2 family; and
2. inventory CUSTODIAN-relevant asset packs still present in `~/Downloads`, processing only packs that already have an active repository authority or that can be preserved safely as reference/source material without inventing runtime ownership.

## Mandatory Basin B Handoff

The authoritative handoff ZIP was uploaded to Dropbox at:

`/CUSTODIAN/implementation_inputs/awakening_service_basin_b_handoff_v1.zip`

Prefer a local copy at:

`~/Downloads/awakening_service_basin_b_handoff_v1.zip`

If the local file is absent and this agent environment can access the Dropbox connector/mount, retrieve that exact Dropbox file. If neither route is available, report the basin handoff as blocked by source-file availability and continue only the Downloads inventory portion. Do not reconstruct the supplied art from screenshots or prose.

The ZIP contains:

- `MANIFEST.json`
- `README.md`
- `CODEX_IMPLEMENTATION.md`
- `VALIDATION.txt`
- source master:
  `source_work/awakening_ambulatory_fixtures/service_basin_b_source.png`
- normalized intake:
  `inbox/awakening_ambulatory_fixtures/service_basin_b.png`

Expected supplied normalized SHA-256:

`b8e068ced61b6a7416b8b5be6ed2da881e5d7861e48faf7e4ea46a2e7cba6924`

Expected source-master SHA-256:

`506f36de93096f32b37991fc7a4a5b27d0bb476c00afe7d47d3b608f010efc15`

### Basin B Contract

Existing family authority:

`custodian/content/metadata/assets/families/awakening_ambulatory_fixtures.asset.json`

State:

`service_basin_b`

Contract:

- required: true
- priority: P1
- kind: world_prop
- layer: body
- action group: fixture
- variant: service_basin_b
- direction: omni
- layout: copy
- frames: 1
- frame size: 128×128
- PNG RGBA with real alpha

Canonical source target:

`custodian/asset_drop/source_work/awakening/awakening_ambulatory_fixtures/service_basin_b_source.png`

Canonical inbox target:

`custodian/asset_drop/inbox/awakening_ambulatory_fixtures/service_basin_b.png`

Expected runtime identity:

`custodian/content/sprites/environment/props/awakening/awakening_ambulatory_fixtures/runtime/body/awakening_ambulatory_fixtures__body__fixture__service_basin_b__omni__1f__128.png`

The repository already contains an older un-ingested `service_basin_b_source.png`. Preserve that prior source in a clearly named pre-handoff history folder before replacing the canonical source master.

Use the current live Asset Pipeline V2 CLI discovered through:

`python3 custodian/tools/assets/asset.py --help`

Run the live equivalent of plan, ingest, status, and one doctor check for `awakening_ambulatory_fixtures`.

Acceptance for Basin B:

- package hashes match before installation;
- source master is preserved and replaced intentionally;
- normalized input is exactly 128×128 RGBA with real alpha;
- Asset V2 performs the runtime publish;
- family reaches 6/6 required states ready;
- runtime/import/catalog/receipt agree;
- focused Asset V2 validation and changed-file closeout pass.

Do not add a separate scene sprite merely to make the state visible. The active Awakening manifest currently classifies the published Ambulatory fixture states as `BAKED_ONLY`; this slice closes the asset-family gap, not room composition.

## Downloads Asset-Pack Sweep

After Basin B, inspect only the immediate contents and obvious asset-pack descendants of `~/Downloads`.

Do not recursively ingest arbitrary personal downloads.

Eligible candidates are limited to:

- files/folders clearly named for CUSTODIAN handoffs;
- Kenney asset packs already discussed or already referenced by active repository packets/docs;
- ZIPs/folders containing an explicit CUSTODIAN manifest/readme/task handoff;
- source packs whose license/provenance is bundled and whose intended repository role can be resolved from an existing family, packet, or source-library contract.

### Known outstanding pack

The existing packet:

`custodian/docs/ai_context/task_packets/KENNEY_PATTERN_LINES_SOURCE_LIBRARY.md`

owns the four downloaded Kenney Pattern Pack Lines variants.

If that packet is still active on rebased main and all four expected local variants are present, implement it according to its own contract instead of duplicating its library logic here.

Once implemented, archive/update that packet according to current task lifecycle policy and record its landed evidence in this workstream closeout.

### Other downloaded packs

For each additional relevant pack discovered:

1. record filename/folder, detected pack/product name, file count, dimensions where practical, license/provenance, and why it is CUSTODIAN-relevant;
2. search current repository authority before copying anything;
3. if an active existing packet already owns it, do not duplicate that work. Report the owning packet and leave the source untouched unless this workstream can safely execute that existing packet under current dispatch rules;
4. if it is useful only as reusable source/reference material, preserve it under the surviving general third-party/reference source-library convention. Do not create a parallel library root;
5. if production promotion would require a new family, new scene placement, subjective selection, or art-direction decision, do not invent that contract. Preserve/index the source and report it as deferred;
6. never copy unrelated downloads into the repository.

## Inventory Receipt

Create one compact receipt under:

`custodian/docs/ai_context/reports/assets/asset_downloads_intake_sweep.json`

Use an existing reports/assets convention if live main has a more specific surviving location.

For each inspected CUSTODIAN-relevant item record:

- local basename/path relative to `~/Downloads`
- classification: `implemented`, `reference_preserved`, `owned_by_existing_packet`, `deferred_needs_design`, or `ignored_unrelated`
- owning family/packet/library when known
- license/provenance status
- hashes for copied source files
- final repository paths for any preserved/implemented content

Do not enumerate unrelated personal files in committed repository docs. The `ignored_unrelated` classification should be aggregated as a count only.

## Preserve

- existing Asset V2 identities and runtime naming;
- prior Basin B source history;
- existing Kenney K3D experimental sources;
- active third-party/reference library conventions;
- local source archives/downloads;
- current Awakening scene composition and BAKED_ONLY doctrine.

## Non-goals

- no new gameplay/runtime architecture;
- no redesign of Recovery Ambulatory;
- no scene binding for Basin B;
- no automatic promotion of every downloaded pack into runtime;
- no new Asset V2 family unless one already exists and clearly owns the supplied asset;
- no broad cleanup of `~/Downloads`;
- no deletion of user downloads;
- no image generation or subjective art replacement.

## Documentation Drift Check

Reconcile current generated/active asset status after Basin B lands.

The old `custodian/asset_drop/inbox/awakening_ingest_manifest.json` and historical bundle manifests must not override the live Asset V2 family/catalog truth if they disagree. Update only active/generated authorities through their current generator/tooling.

If `REQUIRED_ASSETS.md` still claims `service_basin_b` is missing after a successful ingest, regenerate the owning required-assets view rather than hand-editing the generated file.

## Validation

Run, in this order:

1. handoff hash/dimension/alpha checks;
2. focused Asset V2 plan/ingest/status/doctor for `awakening_ambulatory_fixtures`;
3. the validation required by any existing asset-pack packet actually executed during this sweep;
4. `git diff --check`;
5. current changed-file validation closeout.

Do not start with a full-project test sweep.

## Completion Report

Report only:

- Basin B ingest job ID, runtime path, SHA-256, and final family completeness;
- which Downloads packs were found relevant;
- which were implemented, reference-preserved, delegated to an existing packet, or deferred;
- repository paths created/changed;
- focused validation results;
- any documentation drift fixed;
- anything still requiring human art/design choice.

## Next Handoff

After this closes, return to the active Awakening presentation sequence. The remaining scene-level work should not be silently absorbed here.
