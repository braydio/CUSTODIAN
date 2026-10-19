# Operator NE Skin V2 · Neutral rig and apron-authoring proof

Workstream: `operator-2-5d-ne-walk-retargeting` · Iteration 010 · review only.
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe

## Use

All implementation code is ChatGPT authored and independently synthetically tested.
Luna runs it, diagnoses real-accepted-rig failures, publishes exactly one review, then STOPS.

```bash
python3 custodian/tools/validation/operator_ne_skin_v2_smoke.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/register_validation.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/run.py \
  --donor-bundle "$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1" \
  --rig "$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite" \
  --baseline "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png" \
  --source-aseprite "$HOME/Downloads/SINGLE_FRAME.aseprite" \
  --output "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_010_skin_v2_articulation_apron_proof"
```

## Input and transformation authority

- Knight donor 15f SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`
- Knight NE landmark trace SHA256 `a96b58383aaf38f3215c929e4411eb45e10e0e73bf031a93e25d31e2ce751f58`
- Accepted Custodian rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`
- Original locked Aseprite SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`
- Iteration004 strip SHA256 `e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a`
- Iteration004 contact report SHA256 `88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a`

The upstream `knight_skin_poc.run.load_inputs` enforces these identities, 15 source poses,
source dimensions and immutability. It must not be replaced with unknown donor frames.

## Stage A: Source ownership audit (no art modification)

1. The neutral rig must reassemble pixel-identically from the nine authentic lower/robe
   semantic layers plus its residual. Reject any missing, overlapping or changed source cel.
2. The 1,458-pixel upper-body residual is **NOT A RIG**. It is displayed with provisional
   head/upper/pelvis bands for manual art-ownership review. Neither script nor Codex is
   allowed to infer an authoritative independent hood/shoulder/arm cel from this picture.
3. Produce `SKIN_V2_NEUTRAL_OWNER_AUDIT.png` before discussing pivot expansion.

## Stage B: Three apron states (real source pixels only)

`neutral` (F01 and F15) retains the exact previously rendered POC apron treatment.
`far_cross` (F05 and F07) uses hem-level signed displacements:
`robe_far=(-2,0)`, `robe_center=(+2,+1)`, `robe_near=(+3,+1)`.
`near_open` (F12): `robe_far=(0,0)`, `robe_center=(-2,-1)`, `robe_near=(-5,-2)`.

All figures are source pixels `(x,y)`. The top three opaque rows of each panel stay
pixel locked, with nearest-neighbor inverse sampling from waist to hem. The source color
set and binary alpha never change. These are controlled **experiments**, not claims that
new backing material or realistic stretch was created.

The gap auditor records any apron-zone pixels that become newly transparent (red) or
newly filled (blue). Red cells are questions for human art authoring, not automatically
invalid or automatically safe to paint. **No hidden backing pixels are generated.**

Five samples only, 5×128×128. Full walk, arm motion, attack VFX, Knight orientation, FPS,
Asset Pipeline V2 normalization and runtime remain out of scope.

## Candidate files

Exactly seven items in the fresh output directory:

- `SKIN_V2_5POSE_640x128.png` 640×128 transparent source-pixel strip (not a looping walk)
- `SKIN_V2_NEUTRAL_OWNER_AUDIT.png` 768×280 comparison at 2× scale
- `SKIN_V2_5POSE_APRON_REVIEW.png` 1024×1400 (5 rows, four actual-pixel views)
- `SKIN_V2_GAP_AND_OCCLUSION_MAP.png` 768×1400 (five before/after/gap rows)
- `SKIN_V2_ART_REQUIREMENTS.json` source/ownership/variant/hole ledger
- `REVIEW_PIXELS.json` includes all three authenticated PNG review images for Dropbox text preview
- `REVIEW_NOTES.md` brief human checklist and limitations

**Note:** raster output dimension values above are computed from 128×128 native cells
shown at 2× plus 24px label strip. They are not a request for new runtime sheet sizes.

## Asset Pipeline V2

This is an offline SOURCE_WORK authoring experiment; do not stage under `asset_drop/inbox`.
If hidden cloth/arm backing is actually required after human review, the proposed distinct
family is `operator_ne_skin_v2`, source_work:
`custodian/asset_drop/source_work/operator/operator_ne_skin_v2/`.
Each missing cel is 128×128, one transparent RGBA pose/layer, with a named semantic owner,
provided pixel provenance, and no independent FPS. Initial expected state IDs:
`robe_near_open`, `robe_far_cross`, `robe_backing_hidden`,
`upper_arm_near_hidden`, `upper_arm_far_hidden`; actual necessity remains UNVERIFIED.
Any *new* material should first use Asset Pipeline V2 intake with a full manifest and
user approval; no art assets are created by this package.
