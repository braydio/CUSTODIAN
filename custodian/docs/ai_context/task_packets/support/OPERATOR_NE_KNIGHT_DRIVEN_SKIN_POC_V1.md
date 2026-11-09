# Operator NE · Knight-driven Custodian skin · Implementation contract v1

- Workstream: `operator-2-5d-ne-walk-retargeting`
- Branch: existing retained `agent/operator-2-5d-ne-walk-retargeting`, no new worktree
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe
- Gate: manual, review-only five-pose experiment; final 15-frame and R4 human hold retained

## A. Engineering decision

Implement a REAL raster/rig authoring POC: **Knight NE traced motion drives Custodian semantic artwork**, instead of the R2/R3 method of resynthesizing around the old V6 smoothed leg pose. This is not generative art. Do NOT feed the generated concept sheets back as inputs.

Important source facts:
- `custodian/dev/test_sprites/Knight/Walk.png` is a Git-LFS flattened animation sheet (oid SHA256 `60e6b25fba5413e0342365bce82b09d8f3ea10626ad1a98f7dd5f8889d13e22b`; LFS size 430153), NOT a skeletal rig. Its row order is not this project's NE pose authority.
- Original toggleable Knight debug skin was retired in C2b, because its compatibility SpriteFrames names did not match canonical playback. Do NOT restore it, its DevConsole command or animation-name fallbacks.
- `HumanoidCutoutRig2D` is an existing 96×96 S/N/E/W enemy visual tool. Borrow its semantic cutout/pivot/draw-order concept, NOT its runtime implementation or 96px atlas; no runtime scene/code changes.
- Correct input is the workstream's **explicitly human-approved Knight NE donor**, already traced at 15 frames with nine anatomical landmarks each. No image inference/retracing.

The deliverable is exactly **five individual poses F01/F05/F07/F12/F15**, not a five-frame looping animation. Validate all 15 Knight pose records numerically, render only five Custodian poses, publish true pixel comparisons, then STOP. There is no FPS authority. The existing parked R4 F07/F08 near-foot repair stays available if this POC fails.

## B. Immutable inputs and locations (all must hash-match)

1. Knight NE raster: `$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1/reference/knight_ne_walk_reference_15f_128.png`, SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; 1920×128, 15 horizontal 128×128 RGBA frames. Verify `MANIFEST.json` and reassemble all 15 source crops pixel-exactly; only accept another local file if it has SAME SHA and shape.
2. Existing donor traces: `custodian/tools/operator/ne_walk_retarget/annotations.json`, SHA256 `a96b58383aaf38f3215c929e4411eb45e10e0e73bf031a93e25d31e2ce751f58`, corroborated by `crossover_acceptance.json`. Each frame has `landmarks` with `xy` for pelvis and near/far hip/knee/ankle/toe, plus support. 15×9=135 landmark records, near/far identities fixed, ankle order crosses at 2→3 and 7→8.
3. Accepted Custodian Aseprite rig: `$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`, SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`, RGBA 128×128. Source `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149` is locked, unchanged.
4. Required original comparison: Iteration004 15-frame strip `operator_ne_walk_v6_15f.png` SHA256 `e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a` and `report.json` SHA256 `88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a`, within `$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/`. R3 preview `043d4f43c13e96e5010d5db2a1f58c2118b425c69e668264e613ab5802abc1b1` optional, comparison only, if already locally present.
5. Canonical frame 128×128; x-center 64, root `(64,106)`, ground reference y107. NE near/far projected sole heights are **different**, not screen-half and not blanket y107. Accepted neutral rig joints: near hip(63,75), knee(65,89), ankle(66,100), toe(75,104); far hip(53,75), knee(52,83), ankle(50,88), toe(48,91).

Missing/mismatched hashes, orientation, RGBA mode, source layers, frame count or annotation support = FAIL CLOSED before output. Do not fetch new third-party donor, guess row order, rebuild Aseprite rig, relabel fast-attack art as a walk reference, or modify original inputs.

## C. Exact implementation files

Add only new *offline-authoring* files:
- `custodian/tools/operator/ne_walk_retarget/knight_skin_poc/pose_map.py`: source normalization and 15-frame Knight→Operator numerical map.
- `custodian/tools/operator/ne_walk_retarget/knight_skin_poc/skin_renderer.py`: accepted Aseprite part extraction, neutral layer decomposition, inverse-nearest geometry warps, apron rule, semantic pixel-owner maps and final compositing.
- `custodian/tools/operator/ne_walk_retarget/knight_skin_poc/review.py`: authentic Knight/skin/original contact sheets, limb overlay, nearest-neighbor closeups and audited JSON/PNG output.
- `custodian/tools/operator/ne_walk_retarget/knight_skin_poc/run.py`: CLI, source SHA gate, single fresh output folder, five-pose render, preparation of curated Dropbox handoff.
- `custodian/tools/operator/ne_walk_retarget/knight_skin_poc/README.md`: narrow command, usage, source hashes, known upper-body limitation.
- `custodian/tools/validation/operator_ne_knight_skin_poc_smoke.py` plus bounded `custodian/tools/validation/validation_manifest.json` ownership entry covering ALL new paths.

Reuse `clean_silhouette_r2.py::parse_aseprite_rig` and its inverse-nearest `rigid_warp` when they meet the neutral-part contract. **Do not use R2's `build_frame` rectangular erase or R3's boot-to-sole bridge.** Do not modify `operator.gd`, `operator.tscn`, Knight art, the production SpriteFrames, the 96px enemy rig, `motion_plan.py`/`continuity.py`/`batch.lua`, R2/R3 scripts or outputs. No duplicate worktree.

## D. Exact motion driving algorithm (no invented tuning)

Validate all 15 accepted donor annotation frames, nine landmarks each. For each frame index i and both anatomical identities s in {near,far}:

```python
u_thigh = unit(knight_knee[s] - knight_hip[s])
u_shin  = unit(knight_ankle[s] - knight_knee[s])
u_foot  = unit(knight_toe[s] - knight_ankle[s])
hip[s] = rig_hip_neutral[s] + ONE_cycle_scale * (knight_pelvis[i] - mean_knight_pelvis)
knee[s] = hip[s] + rig_thigh_length[s] * u_thigh
ankle[s] = knee[s] + rig_shin_length[s] * u_shin
toe[s] = ankle[s] + rig_foot_length[s] * u_foot
```

`unit(v)=v/||v||`. Fail on zero-length/nonfinite donor joints. `ONE_cycle_scale` is the accepted mean rig thigh+shin total divided by mean donor thigh+shin total over all 15 frames. Record it once; no per-frame/per-side smoothing, clamping, invented IK branch, independent ankle fit, hidden near/far swap or custom yaw. Preserve donor's near/far anatomical identities across 2→3 and 7→8; preserve its annotated support schedule (6→7 and 13→14).

For **only** F01/F05/F07/F12/F15, align the **whole posed character by one translation**, using the donor-annotated anatomical support foot to match the accepted corresponding frame's **projected** support foot/contact target in the Iteration004 report. Record raw and translated joints, screen-space contact residual, scale, reference plane and projected pelvis/root delta. Never move individual hips/ankles after projection to falsify a contact pass. A legitimately occluded planted F07 far sole is valid with geometry evidence; do not force its alpha into view.

Only compare these poses with Iteration004 and R3; DO NOT use their solved/smoothed gait as the driving motion. The five sparse frames cannot establish full-loop temporal continuity or FPS.

## E. Real Custodian skin raster algorithm

Required approved rig layers, exact identifiers:
`__RIG_REFERENCE_LOCKED_FULL_BODY`,
`__RIG_PART_thigh_near_visible`, `__RIG_PART_shin_near_visible`, `__RIG_PART_foot_near_visible`,
`__RIG_PART_thigh_far_visible`, `__RIG_PART_shin_far_visible`, `__RIG_PART_foot_far_visible`,
`__RIG_PART_robe_far`, `__RIG_PART_robe_center`, `__RIG_PART_robe_near`.

No fake hood/torso/arm cels if absent. Build static neutral torso/hood/arms residual from the locked original using actual semantic owner masks, never a broad lower-body rectangle. Before animation, reassemble the NE **neutral** pose from residual plus nine parts and report image/palette/alpha differences against the locked full-body source. If a neutral boot ghost or unrelated unowned hole remains, fail with an owner-mask diagnostic rather than deleting pixels indiscriminately.

From the neutral accepted rig, inverse-nearest warp each thigh hip→knee, shin knee→ankle, boot ankle→toe into the exact donor-driven joint positions. Maintain semantically owned RGBA pixels and transparent masks. Composite back-to-front in approved NE order: far thigh, shin, boot; robe_far; near thigh, shin, boot; robe_center; robe_near; with locked upper-body base behind. Output must contain **zero Knight pixels**. The independent upper-body parts are missing from this accepted rig, so leave upper-body essentially static and honestly mark this POC's limited arm sway; don't invent a skeletal model or fake upper-body secondary motion.

Initial apron experiment uses semantic rig robe layers only; deterministic integer per-row shear after waist y73:
```python
v = clamp((y - 73) / 24.0, 0, 1)
stride = clamp((ankle_near.x-hip_near.x) - (ankle_far.x-hip_far.x), -8, 8)
near_shift = round(v * clamp(0.25 * stride, -2, 2))
far_shift = round(v * clamp(-0.15 * stride, -2, 2))
center_shift = round(near_shift / 2)
```
Do not edit these constants while executing. Maintain pixel-perfect nearest sampling, source palette only, true binary alpha. No blur, broad-erasure mask, invented colors, polygon brush, R3 orphan bridge, or output outside 128px cell. A layer insufficient for a crossing -> FAIL/diagnostic, not a fabricated garment.

Track per-pixel layer owner before/after composite. Validate visible near boot linkage with near shin after occlusion (F05/F07/F12), and classify occluded far boot semantically rather than left/right screen region. Fail on genuinely ownerless changed distal clusters. Source-to-output shape/art fidelity remains a **human review question**, not a numeric score proclaiming accepted art.

## F. Tests and output contract

Focused smoke must negative-control: wrong Knight SHA, wrong rig, 14 donor frames, flipped near/far identity, zero-length joints, incorrect support, spurious neutral boot, disconnected visible near foot, exposed legitimately occluded far foot, wrong palette, nonbinary alpha, spilled cell pixels and overwrite of output folder. Check frame registration/root, source files remain byte-identical, deterministic same-run output SHA, source color set only, 8-neighbor component ownership, and projected anatomical sole residual (visible support <=2px horizontal and <=1px vertical; hidden support has separately proved geometric target). Preserve old R2/R3 files. Selected validation checks alone are NOT enough if the new files are uncovered; register the owner and run focused smoke first, then `git diff --check` and once `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`. No Godot boot or Asset V2 apply for offline authoring-only scope.

Run from existing retained worktree, with a **fresh, nonexistent** output:
```bash
python3 custodian/tools/operator/ne_walk_retarget/knight_skin_poc/run.py \
  --donor-bundle "$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1" \
  --rig "$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite" \
  --baseline "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png" \
  --output "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_009_knight_driven_skin_poc_v1"
```

Curate EXACTLY six review artifacts (generated by code, NOT imagegen):
1. `custodian_knight_driven_poc_5f_640x128.png`: transparent 640x128, five 128x128 sparse frames only, NOT a playable cycle.
2. `KNIGHT_SKIN_5POSE_COMPARISON.png`: five rows of actual Knight | pivot/owner overlay | new Custodian | unchanged Iteration004.
3. `KNIGHT_SKIN_CROSSOVER_CLOSEUPS.png`: 3x/4x nearest-neighbor near/far masked F05/F07/F12 + F15/F01 silhouette pair.
4. `KNIGHT_SKIN_POC_AUDIT.json`: full 15 source pose map; five rendered pose/part reports; hashes, support residuals, ownership and overflow QA; explicit art_accepted=false, runtime_ready=false, fps=null.
5. `REVIEW_PIXELS.json`: authenticated base64 comparison/closeups for Dropbox text bridge with dimensions and SHA.
6. `REVIEW_NOTES.md`: reproducible command, commit, test receipts, known static upper-body limitation, exact art questions.

## G. Dropbox, lifecycle and stop

Publish the six curated files (nothing else) through `custodian/tools/iteration/publish_review_artifacts.py`, with:
`--important`; `--reason "genuine Knight-driven Custodian skin requires human visual acceptance"`; `--workstream operator-2-5d-ne-walk-retargeting`; `--run-id iter-009-knight-driven-skin-poc-v1`; `--authoring-chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`; `--source <curated-dir>`; `--max-files 6`; `--max-keyframes 0` and three `--question` values: (a) clear F05/F07 crossover and NE-facing boots? (b) believable F12 leg excursion/apron? (c) do F15 and F01 plausibly belong in the same cycle, without claiming smooth playback? The publisher owns remote lookup, hashes and cleanup receipt. Expected:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-009-knight-driven-skin-poc-v1/REVIEW_MANIFEST.json`.
Default delete-after-review; keep it until verdict documented.

On technical success, stage ONLY new offline POC scripts, narrow validation registry/test and concise summary; commit/push to SAME retained branch using `[skip render]`, without touching unrelated untracked R1 imports/`.gd.uid`. Report branch SHA, objective QA and Dropbox path. **STOP.** No Iteration010, 15-frame full render, R4 restart, merged main, archive, Workstream finish, Runtime SpriteFrames, Godot scene integration, asset_drop normalization/inbox or official FPS without separate human decision. Subjective acceptance remains ChatGPT/user-owned.

PoC pass -> authorize full 15-frame offline expansion via new review here. PoC fail -> classify whether source part coverage, torso constraints, pose geometry or apron occlusion caused failure; do not tune autonomously. R4 near-foot repair remains parked, not discarded.
