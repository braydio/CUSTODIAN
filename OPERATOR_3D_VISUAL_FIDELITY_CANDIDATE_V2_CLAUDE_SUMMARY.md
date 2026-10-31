# Operator 3D Visual Fidelity Candidate V2

Status: bounded experimental candidate and review proof complete; human visual decision pending.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1

## Workstream and boundary

- Implemented in the isolated manual branch `manual/operator-3d-visual-fidelity-candidate-v2` because the named production packet was dependency-lock-blocked. No dispatcher claim was made, no packet metadata was changed, and no production asset was promoted.
- The source ITER005 `.blend`, GLB, FBX, source motion/receipts, and Task 017 donor were read-only. The donor remains in its original dirty Task 017 worktree.
- Candidate state remains `candidate_unapproved` / `experimental`. Stop here for human visual review.

## Candidate files

- Final combined candidate: `custodian/asset_drop/source_work/operator/operator_3d_master/masters/operator_3d_iter005_visual_fidelity_candidate_v002/operator_3d_iter005_visual_fidelity_candidate_v002.blend`
  - SHA-256: `2c4c097039b25727c0ce51f22251d33462b6f020ad4f8863d23913b4efe7dc23`
- Pose/proportion stage SHA-256: `7ec75e6f59495ce7fbe9d5d5062d95a9fc1605e79a7002c10427be0b1ce80d56`
- Material/visor stage SHA-256: `33c12ba593b01861bfa5f137813af0c650f779ccfc4e462876c893221ebcc3ef`
- Master contract, source lineage, snapshot and component-by-component measurements are beside the candidate in `master.v1.json`, `source_lineage.v1.json`, `snapshot_manifest.v1.json` and `correction_report.v1.json`.
- Candidate rig has 42 bones and retains the source identity, rest-pose hash and skeleton signature. The neutral overlay keeps frames 1–264 and does not modify the rest pose.

## Correction status

1. **Stance — implemented in the neutral idle overlay.** Two-bone IK moves ankle targets to ±0.16 m around the pelvis with matched depth. Measured separation is 0.320 m at frames 1 and 263, and 0.3195 m at frame 132; the baseline values were 0.3592 m, 0.3592 m and 0.3610 m respectively. This changes only the scoped idle presentation.
2. **Torso/proportions — partial.** `output_unwrapped` has scoped waist/upper torso width factors of 0.97/1.03 across 602 torso vertices, with 1.04 lower-leg and 1.03 boot width factors. The rendered torso still reads hunched and needs a specific follow-up correction.
3. **Cloak — partial.** `output_unwrapped` lower panels use a 1.16 flare factor across 3,254 weighted vertices. Panel separation and temporal cloth clearance are not proven.
4. **Pauldrons — partial, clearance blocked.** Task 017’s symmetric shells are included in the derivative with 434 vertices each, 4 cm projection and 1.5 cm lift, weighted to the matching shoulder. Measured shell/body overlap remains 145/163 triangle pairs at rest and 86–134 in the sampled running poses. A boolean experiment damaged source topology and was discarded; body clearance remains unresolved.
5. **Hood/visor — partial.** The final amber core uses 3 faces; its local region uses 18 faces within a 2.5 cm radius, with no global bloom. Directional visibility is preserved by the source-facing surfaces. The final 1–2px appearance and face-cavity readability remain for human review.
6. **Materials/lighting — partial.** A controlled 0.16 albedo contrast and amber material assignments were added while preserving source metallic/roughness maps and using consistent render lighting. The source has one baked body material, so armor/cloth/gold do not yet have separate PBR responses.
7. **Pixel sharpness — partial, comparison complete.** The proof contains 12 native 128 renders and 12 independent native 512 renders reduced once using `pixelart --choose 1`. The converter’s content-fit was followed only by integer pixel translation to restore the camera root `(64,106)`. The comparison and raster metrics are in the handoff; final aesthetic approval remains human-owned.

## Verification and visual handoff

- Master schema validation: pass. Neutral motion contract and source hashes: pass.
- Render proof: 48 staged 128px images, 12 native 512px images, 12 reduced 128px images, and 32 adjacent-frame images. All used the same fixed scale `1.2287417600294088`, camera contract and registered root.
- Python compile and `git diff --check`: pass. No focused test files were present in the animation compiler or model inspector directories.
- Exact visual review manifest: `/CUSTODIAN/visual_review/operator-3d-visual-fidelity-candidate-v2/20261031T110654Z/REVIEW_MANIFEST.json`
- The handoff uses the default `delete-after-review` retention policy. After the human decision is recorded, use the cleanup command in the manifest.

## Human decision questions

- Does the S/SE/SW/E stance and silhouette at 128px follow the approved correction direction at frames 1, 132 and 263?
- Is the amber visor core directional and compact, with a restrained local glow and a dark faceless hood?
- Do the shoulder contours, cloak hem/panel separation, torso proportions and graphite/gold/cloth contrast match the approved direction?
- Does the independently rendered 512px output, reduced once and root-registered, preserve the native 128px sharpness?

## Next boundary

Wait for the human review. Do not run full rendering or production promotion until the review decision and remaining shoulder clearance/proportion questions are resolved.
