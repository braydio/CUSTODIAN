# Knight-driven Custodian skin POC

This offline authoring experiment maps the 15 manually traced, approved Knight NE
poses onto the accepted 128×128 Custodian semantic rig. It renders only F01,
F05, F07, F12 and F15 as separate review poses. The 640×128 output is a sparse
contact strip, not a playable animation or an FPS recommendation.

The runner reuses the existing R2 Aseprite part parser and inverse-nearest bone
warp. It does not call R2's frame compositor or R3's boot bridge. New pixels
come only from the accepted Custodian rig's palette. The upper body stays static
because the accepted rig does not provide independently animated upper-body
cels; arm sway is not fabricated.

## Run

Use a new output directory. The runner verifies the source bundle, hashes,
annotations, rig, source image, Iteration 004 baseline and report before writing.

```bash
python3 custodian/tools/operator/ne_walk_retarget/knight_skin_poc/run.py \
  --donor-bundle "$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1" \
  --rig "$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite" \
  --baseline "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png" \
  --output "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_009_knight_driven_skin_poc_v1"
```

The output directory must not exist. The runner creates exactly these six review
artifacts: the five-pose transparent strip, the authentic four-column pose
comparison, semantic crossover closeups, the machine audit, embedded review
pixels, and concise review notes. It does not upload or publish runtime art.

## Pinned input identities

- Knight NE 15-frame raster: `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`
- Annotation trace: `a96b58383aaf38f3215c929e4411eb45e10e0e73bf031a93e25d31e2ce751f58`
- Accepted Custodian rig: `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`
- Locked `SINGLE_FRAME.aseprite`: `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`
- Iteration 004 strip: `e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a`
- Iteration 004 report: `88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a`

Any missing/mismatched source fails closed. The report explicitly retains
`art_accepted=false`, `runtime_ready=false`, and `fps=null` pending human review.
