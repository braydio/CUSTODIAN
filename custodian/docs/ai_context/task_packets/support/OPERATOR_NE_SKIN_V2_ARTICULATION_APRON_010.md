# Operator NE Skin V2: cutout audit and apron-variant proof (Iteration 010)

- Workstream: `operator-2-5d-ne-walk-retargeting`, existing retained implementation branch only
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe
- State: exact ChatGPT-authored program ready for one offline, manual five-pose render; no runtime, canonical asset, FPS or merge
- Source files: [exact compressed code bundle](./OPERATOR_NE_SKIN_V2_SOURCE_BUNDLE.tar.xz.base64), SHA256 **`fb398d43d795293fc40267a3497ab0e32eb05a419aff2a897ccb1baf15ea914a`** after base64-decode to .tar.xz; eight relative paths and seven member hashes in `skin_v2/SKIN_V2_PACKAGE_MANIFEST.json`
- A matching direct user ZIP also exists, SHA256 `9bd145e30aa50e9282067df814ef5f9c81b4eeaaac427129592ec84ebe4448aa`, but the workflow **does not depend on that download** because exact executable code is present in GitHub main

## What is actually implemented

Stage A: `apron_authority.audit_neutral` reads the accepted 128x128 RGBA Aseprite, its locked-full-body reference and nine semantic lower-body/robe part cels. It asserts disjoint, authentic pixel owners, exact source colors and **zero mismatches** on full-body neutral reassembly. The 1,458 static residual pixels are labeled in a **provisional** head/upper-body/pelvis audit picture; they do not acquire fabricated hood, torso, shoulder or arm pivots. Existing cels and source SHA are immutable. A genuine upper-body articulation rig requires another reviewed source-authoring stage.

Stage B: `apron_authority.aperture_warp` creates `neutral`, `far_cross`, `near_open` apron silhouettes **only** from the nine accepted semantic cels, with no generated pixels. F01/F15 retain existing POC neutral; F05/F07 get far-cross; F12 gets near-open. Each panel has an anchored top three opaque rows and inverse-nearest hem displacement:
- `far_cross`: `robe_far=(-2,0)`, `robe_center=(2,1)`, `robe_near=(3,1)`
- `near_open`: `robe_far=(0,0)`, `robe_center=(-2,-1)`, `robe_near=(-5,-2)`
All values are signed 128px source-cell pixels (x,y) at hem. The source palette and binary alpha are mandatory. These are finite **test variants**, not claims of authentic cloth folds, stretch or hidden art.

Stage C: real Knight NE source traces, accepted 128px rig and Iteration004 baseline are SHA-pinned by the existing `knight_skin_poc.run.load_inputs`. Preserve the POC's **true** near/far hip/knee/ankle/toe and sole alignment. Render 5 sparse poses `F01/F05/F07/F12/F15`; do not run a full animation or retime. Create neutral mask, before/after apron sheets, final origin-palette RGBA strip and a **source-backed transparent gap** map (red newly cleared, blue newly filled). Treat gaps as possible missing covered costume backing, not authorized painted pixels. Reject if alpha/source SHA, neutral lock, original support-foot visibility or five-frame determinism regresses.

## Exact repo paths

New files, already authored and archived above:
```
custodian/tools/operator/ne_walk_retarget/skin_v2/
  apron_authority.py
  run.py
  run_skin_v2.sh
  register_validation.py
  README.md
  CODEX_IMPLEMENTATION.md
  SKIN_V2_PACKAGE_MANIFEST.json
custodian/tools/validation/operator_ne_skin_v2_smoke.py
```
The registration helper idempotently adds `operator_ne_skin_v2_apron` to live `custodian/tools/validation/validation_manifest.json`, scoped only to these files. No edits permitted to `operator.gd`, `operator.tscn`, original art, R1/R2/R3, existing Knight POC, runtime resources or asset importers.

### Retrieve the authored source without duplicate worktree

From the existing retained implementation checkout:
```bash
git fetch origin
git show origin/main:custodian/docs/ai_context/task_packets/support/OPERATOR_NE_SKIN_V2_SOURCE_BUNDLE.tar.xz.base64 | base64 -d > /tmp/operator_ne_skin_v2_010.tar.xz
echo 'fb398d43d795293fc40267a3497ab0e32eb05a419aff2a897ccb1baf15ea914a  /tmp/operator_ne_skin_v2_010.tar.xz' | sha256sum -c -
tar -tJf /tmp/operator_ne_skin_v2_010.tar.xz
```
Check none of its eight relative destinations exist with different content. Extract to **the same retained checkout** with `tar -xJf ... -C "$(git rev-parse --show-toplevel)"`. Verify all SHA values from `SKIN_V2_PACKAGE_MANIFEST.json`, no overwrites or duplicate worktree. The canonical CLI, validation, stage/commit and Dropbox publisher command are inside the archived `skin_v2/CODEX_IMPLEMENTATION.md` and must be followed exactly.

### Source specifications / Asset Pipeline V2

No new art assets are created or ingested in this iteration. Preserve `custodian/asset_drop/source_work/operator/operator_ne_skin_v2/` as proposed source-work only. Should the human review prove a missing hidden surface, author new transparent RGBA 128x128 one-frame layers under provisional family `operator_ne_skin_v2` through the actual live Asset Pipeline V2 intake, with explicit semantic IDs and provenance, **after separate approval**. No inbox files or runtime packs are authorized now. Existing Fast Attack 4 remains unrelated.

### Local review output

Fresh-only directory `~/Downloads/operator_ne_master_audit_implementation_v1/iter_010_skin_v2_articulation_apron_proof/`, seven files: 640x128 sparse strip; 768x280 neutral ownership audit; 1024x1400 5-pose before/after/owner sheet; 768x1400 apron transparency gap map; `SKIN_V2_ART_REQUIREMENTS.json`; `REVIEW_PIXELS.json`; `REVIEW_NOTES.md`. No new arm art, newly painted backing or FPS.

Publish **exactly** seven source-raster files through existing `publish_review_artifacts.py` to:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-010-skin-v2-articulation-apron-proof/REVIEW_MANIFEST.json`.
Report real candidate hash, missing backing regions, F05/F07 far-boot visibility, F12 apron appearance, test results and branch checkpoint. Then STOP, wait for human art verdict. No Iteration 011, full 15-frame loop, landing or runtime change.

### Synthetic validation completed by ChatGPT

The exact script passes on a nine-layer synthetic rig: zero-pixel neutral reassembly; three deterministic garment variants; original source palette and binary alpha; gap ledger; negative controls for missing part owner, unknown variant, changed source/unsourced pixel, overlapping owners and nonbinary source alpha. **The real accepted rig, Knight inputs and output have not been run in this environment.** Stop on any real input or rendition failure and return to this authoring chat; don't adjust authored constants.
