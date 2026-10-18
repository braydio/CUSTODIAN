# CUSTODIAN Operator NE walk R2: bone-anchored semantic raster cleanup

Workstream `operator-2-5d-ne-walk-retargeting`. Chat and review authority:
https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe

**Reason for R2:** R1 replaced whole lower-body poses from the alternate walk, disrupting the validated F05/F12/F13 stride. R2 must use the accepted motion plan as pose authority and the 128×128 neutral Operator rig layers as contour authority, not the alternate strip's frame-to-frame geometry.

## Authority

- **Motion:** Immutable Iteration 004 `operator_ne_walk_v6_15f.png` (1920×128, 15 frames), `report.json`, support identity and near/far hip/knee/ankle/toe landmarks. Their hashes are embedded in `clean_silhouette_r2.py`. F12 near toe remains at x≈91, rather than collapsing toward the alternate walk's foot.
- **Art/parts:** Human-accepted `operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite` SHA256 `b7002e...b11a8dcdae815a0ff5`. Its exact 128×128 `__RIG_PART_` semantic cel masks own near and far thigh, shin, boots, and three robe pieces. Original locked 128×128 full-body raster must equal the style reference.
- **Visual reference:** cleaner 15-frame strip (1920×128) and idle (1920×128) are read-only source-work references, not a substitute gait. The 10-frame walk (1280×128) is a supplementary visual look-reference only.
- **Presentation:** native RGBA with binary alpha; same source palette, no new hues, no resampling blur or interpolated subpixel RGBA, no authoritative FPS.

## Authored R2 transformations

1. For each frame and each anatomical bone, inverse-sample a neutral semantic part onto the accepted frame's endpoints: far thigh hip→knee, far shin knee→ankle, far boot ankle→toe; same three independently for near leg. The inverse transform reads source RGBA using nearest-neighbor, never forward-splats pixels. It does not alter or re-solve the motion report. The original neutral near source pivots are hip (63,75), knee (65,89), ankle (66,100), toe (75,104); accepted far source is (53,75),(52,83),(50,88),(48,91).
2. Warp each apron piece from neutral style with a continuous small hem displacement weighted by accepted knee travel and gait phase. Far/center/near gains are 0.20/0.12/0.23, bounded ±4px. This is an authored drape candidate; no recreation of the alternate strip's leg poses.
3. Replace only the bounded 128×128 lower-body compartment; preserve all source pixels above row 68 and protect the right forearm crossing zone. Composite lower parts in fixed anatomical depth order. Report anatomical knee/ankle nearest-part distances; fail closed above 4.5px. Do not swap whole limbs per support frame.
4. Preserve the exact **original rendered planted-sole** pixel row for the identified anatomical support leg, from `report.json`'s `rendered_boot_contact`. Erase candidate **support-foot** texels at and below that row and restore the original bottom two active pixels of the sole locally. This prevents gross planted-foot drift without asserting that every visual/occlusion contact has been revalidated.
5. Emit 15-frame candidate, full before/after, 10 crop closeups, per-frame contact audit and the two-image authenticated Dropbox payload. Each output remains disposable and marked REVIEW ONLY.

## Constraints and failure modes

- Local synthetic smoke verifies rig-layer parsing against `SINGLE_FRAME.aseprite` fixture, binary alpha, input hash failures, non-duplicated skeleton targets, nearest-neighbor source palette, intact upper pixels, and sole preservation over 15 generated poses. **This does not prove the live accepted recovered rig/candidate will pass**. If either side's joint-mask-distance guard or accepted input hash fails, STOP: no human-reviewed candidate is published; report the exact blocker for a ChatGPT-authored revision.
- No Aseprite rendering, changes to the original/approved rig, actor/runtime registration, stage-time gameplay FPS, or animation publication.
- Validation registry must explicitly select `operator_ne_r2_reference_manifest` when `docs/REFERENCE_MANIFEST.json` or the four reference assets change. The included idempotent registration script performs only that narrow one-time modification.
- Asset V2: input art remains in `custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1/`. No file is placed in `custodian/asset_drop/inbox/` until a separate user-approved normalized asset handoff. Proposed final family **after** acceptance: `operator_ne_walk`; 15 frames ×128×128, 1920×128 RGBA horizontal strip. FPS unset.

## Human review priorities

- F05/F07 crossover near-leg compass direction and readable shin-to-boot attachment.
- F11/F12/F13 strongly extended near leg, particularly preservation of F12 toe at x≈91 and shoe profile continuity.
- F06→F07, F13→F14 true anatomical support transitions; F15→F01 apron/boot seam.
- Apron opening/compression from the accepted gait, rather than donor-frame substitution.
