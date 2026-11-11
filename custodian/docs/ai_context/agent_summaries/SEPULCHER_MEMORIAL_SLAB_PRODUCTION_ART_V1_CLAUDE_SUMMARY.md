# Sepulcher Memorial Slab Production Art V1

Workstream: `sepulcher-memorial-slab-production-art-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac

## Result

Installed the user's human-approved refined Memorial Slab in the production Hub as one Asset Pipeline V2 `world_prop` state. Only the slab drawing in `SepulcherGraveEvidence::_draw()` changed; the grave world anchor, three reading positions, dialogue, choices, collision/navigation, and persistence behavior remain unchanged. No new art was generated and no paired review was required by the packet.

## Source and normalization

- Dropbox path: `/CUSTODIAN/implementation_inputs/custodian_sepulcher_memorial_slab_refined_v2_source_20261102.png`
- Dropbox file ID/revision: `id:8NXqdXuW6GUAAAAAAAAGsw` / `65f4aa8f42035915cdd61`
- Dropbox content hash (not SHA-256): `fa15ca085092805147abfdd73bdfef0053d4f7344c84ac9bea7cd73e0052ad39`
- Source size and pixels: 2,252,263 bytes; 1620x971; RGBA; alpha extrema 0–255.
- Source SHA-256: `349d642e74f246fc277993c5bfd46889795e3f771d7846e98daba9b031b2d028`
- Approval: user explicitly approved installation in this conversation; the existing source-review schema receipt is pinned to the exact source SHA and Dropbox object.
- Normalization: Asset V2 sprite-import plan `26176cf0ddc50de88942f5108e95bbfbf097992f43e07714ff8f139cb0ce4e56`, `illustrated_structure_soft`, Lanczos, contain, center anchor. Output is 160x96 RGBA with 96 distinct alpha values and no silhouette crop.
- Normalized/runtime SHA-256: `374235ea43ebad385df86b30cb1f7dfd27d330a10d50476955a1fce8b2248312`
- Source master: `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/memorial_slab_source.png`
- Normalization plan: `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/memorial_slab.normalization_plan.json`

## Asset V2 and runtime

- Family/state: `hub_sepulcher_grave_evidence_art/memorial_slab`, required 1-frame omni `copy` state, 160x96.
- Family: `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`
- Runtime resource: `res://content/sprites/environment/props/hub/sepulcher_grave/hub_sepulcher_grave_evidence_art/runtime/body/hub_sepulcher_grave_evidence_art__body__environment__memorial_slab__omni__1f__160x96.png`
- Ingest job: `job_20261107T070300Z_3d825703`; catalog and source-review records updated.
- Consumer: `custodian/game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd`; the registered texture is drawn centered on `(-1984,-3200)`. The four procedural slab primitives were removed. Existing world label and reading markers remain in their prior map-owned layers.
- Asset V2 status: 1/1 required; imported, bound, runtime-verified.
- Compact active HubRuntimeHost render: `/home/braydenchaffee/custodian-memorial-slab-evidence/sepulcher-memorial-slab-runtime.png`, 480x270, SHA-256 `436368e7c5063a9715af7a0941e10463c3ce2bd539ea9544db1378424962340c`. It shows the runtime slab and all three existing inspection markers. The existing blockout label `SepulcherInteriorSample` overlaps part of the art in this debug capture; no map-label or gameplay change was made.

## Validation

- `hub_sepulcher_grave_evidence_smoke.gd`: PASS; verifies production consumer uses the registered 160x96 Asset V2 texture and all three readings/persistence work.
- `hub_sepulcher_grave_resolution_smoke.gd`: PASS; both resolution choices and return growth preserved.
- `hub_first_set_blockout_smoke.gd`: PASS; route/collision clearances unchanged.
- `run_validation.py --changed --base origin/main --json`: PASS, 9/9 selected checks, including the Hub art manifest, Asset V2 and both grave smokes. Durable report: `/home/braydenchaffee/custodian-memorial-slab-evidence/changed-validation.json` (final hash is reported at closeout).
- `asset plan`: passed before ingest with exactly one `create` operation, no warnings, and the expected resource path. `asset status`: 1/1 required ready. `asset needs --check`: PASS.
- `asset doctor`: reports four unrelated existing catalog hash mismatches for `awakening_designation_locker/{authorize_open,closed,empty,open_loaded}`. No Sepulcher slab issue is reported.
- `validate_hub_art_manifest.py`: PASS; JSON/Markdown manifest consistency retained.
- `git diff --check`: PASS.

## Completion and limits

The art manifest JSON and Markdown were updated only for this approved slab's hashes, Dropbox identity, Asset V2 job, approval and runtime status. The exact next art asset was not selected. The global Asset V2 doctor findings above remain outside this workstream and are not represented as fixed.

## Process Feedback

- Outcome: `success`; friction severity: `medium`.
- A first full-project editor import crashed while reimporting unrelated fonts, and an initial concurrent Godot smoke run had route failures. A single serialized first import completed, after which the grave smoke passed serially; final changed-file validation passed 9/9.
- For future fresh worktrees, initialize the Godot cache once before scene-dependent tests and run Godot smokes serially. Use the Asset V2 replayable soft-alpha sprite-import plan for illustrated RGBA sources.
