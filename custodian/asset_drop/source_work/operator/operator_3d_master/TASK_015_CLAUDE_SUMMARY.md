# Task 015 handoff (INTERRUPTED, partial; status stays `RUN_MOTION_NEEDS_REPAIR`)

Worktree: `~/Projects/.custodian-worktrees/operator-3d-master-modeling-proof-v1-20261027T094310Z-29f13eccf5dc`, fast-forwarded to `5e7f8c703` (Task 015 spec).
**Nothing is committed or pushed.** Not done: Dropbox publish, GLB export/reimport, tests, annotated before/after images, final report. No Godot/main/approval work.

## Baseline verified
`run_iter001` .blend/.glb and `iter-003` .blend match `SHA256SUMS_run_iter001.txt`. Baselines were not modified.

## New scripts (all in `scripts/rig_diag/`, untracked)
- `phase1_ledger.py`: renders beauty plus exact per-triangle face-ID masks, using the run_iter001 camera and scale (x1.23547). Frame 0 means rest pose. Decode is exact (0 invalid pixels) once dither is off. It also emits a pixel ledger.
- `dump_mesh_motion.py`: dumps rest and posed vertices, weights, skin matrices K, and bones to npz. numpy LBS matches Blender to 0.0004 mm.
- `hidden_test.py`: dense rest-pose visibility via BVH rays (200 directions, 3 sample points per triangle).
- `repair_plan_run_iter002.py`: numpy weight-repair planner (no faces deleted, rest unchanged).
- `apply_weights_run_iter002.py`: writes planned weights into a copy of the blend.
- Output so far: `rig_diagnostics/meshy-004_rigged/run_iter002/operator_run_mixamo_iter002.blend` plus `apply_report.json`. It has 393 vertices reweighted, 0.0 mm rest change, weights normalized, max 4 influences, 10,367 triangles unchanged.
- Scratch (not in repo): `/tmp/claude-1000/-home-braydenchaffee-Projects-CUSTODIAN/e2bde477-0f81-4f7d-9003-d7cf0ff55ba6/scratchpad/` holds `p1/` (baseline renders, ids, `base.npz`, `frag_tris.json`, `hidden.json`, `plan.json`) and `p2/` (iter002 renders).

## Phase 1 findings
1. **Fragments are real and measurable.** Alpha components disconnected from the body:
   - Baseline at 512 px: 85/168 views, 129 components, 5,618 px.
   - Baseline at 128 px: 49/168 views, 277 px.
   - Worst views: SE f19/f12/f20, N f21/f11.
2. **116 triangles** appear in disconnected fragments across all views (IDs in `p1/frag_tris.json`).
   - 102 are tiny index-isolated components, the iter-002/003 detach patches.
   - 90 are weighted to LeftUpLeg/RightUpLeg, some with Bone_004/005 cloth weight.
   - Their rest-position twins (same position, other mesh component) were e.g. 100% `RightHand`.
   - Baseline anchor separation was up to 645 mm.
3. **Deletion is NOT justified.** 75/116 are visible at rest in the 8 contract views at 512 px, and 0/116 are hidden in the dense 200-direction test (each is visible from at least 10 directions). Only 160 of the 1,860 detach patches ever tear more than 30 mm. The 1,860 island group must not be deleted.
4. **Stretch edges:** I count **17** distinct edges over 3x (spec says ~40), max 6.44x. They are listed with indices, weights, and frames in `p1/stretch_edges_base.json`.
   - 9 are inside detach patches.
   - 7 are Hips<->RightShoulder at z≈1.15. Torso vertices keep RightArm weight because iter-003's `grp()` classed Shoulder as "other" and skipped them.
   - The rest are shoulder/arm boundary (z 1.13-1.19) and thigh/skirt (z 0.57-0.64).
5. **Not done in Phase 1:**
   - Foot-stance and skating analysis (use toe/heel/sole trajectories and seconds at dt=1/30).
   - Shoulder/arm-swing check against the reference skeleton.
   - Annotated 128/512 side-by-sides and the formal defect ledger file.

## Phase 2 result so far (`run_iter002`, weights only)
- **Stretch: fixed.** Cluster-mean weight harmonization over 79 vertices gives max 2.97x, 0 edges over 3x, 0 frames with >3x edges (was 11/frame), and p99.9 max 2.35x (was 2.56). Edge-length arithmetic only; not yet visually verified.
- **Fragments: only partly fixed.** Each patch's vertices copy the weights of the non-patch body vertex at the same position, or the nearest one.
  - Anchor separation after: max 41.7 mm (the rest distance), down from 645 mm.
  - Disconnected pixels at 512 px: 5,618 -> 3,697. Views affected: 85 -> 83. Components: 129 -> 105.
  - At 128 px: 277 -> 190 px, views 49 -> 51. Not clean.
  - Rest ID masks are identical in all 8 directions at both resolutions.
- **Remaining fragments:** 79 distinct triangles (75 of the original 116 plus 4 new). Most are LeftUpLeg ~0.62 / Bone_012 ~0.37 at rest z≈0.72.
  - Example: SE f19 has a 26-triangle cluster (IDs 8794, 8795, 8818, ...) at the left hip.
  - In 3D these sit only 5-10 mm from the nearest body vertex in both rest and posed space, so they are **not tearing away by vertex distance**.
  - The disconnected-alpha test may therefore be flagging a thin cloth/skirt flap that is visually separated by a gap. That would not be a weighting error.
  - Bone_012 is a cloth chain bone using the unverified 50% follow heuristic.

## Suggested next steps
1. Identify what the 26-triangle cluster belongs to (normal/area, rest neighbors, material). Check whether it is a legitimate skirt flap and whether the Bone_012 follow factor opens the gap. Measure whether lowering the cloth follow improves it across all frames, per spec item 4.
2. Decide whether alpha-disconnected is the right defect metric. It may also be worth adding "dark pixels with no connection through the beauty image".
3. Finish the Phase 1 deliverables (foot skating, arm swing, annotated images, ledger JSON).
4. Run the full 21 frames x 8 directions metric comparison (iter001 vs iter002). Then export a GLB, reimport it in a clean Blender, run the fast tests plus targeted replay, and publish the real renders to a new Dropbox run with hash verification. Mark `RUN_MOTION_NEEDS_REPAIR` unless the fragments are genuinely gone.
5. Per the task and memory conventions: commit single-purpose changes, and remind the user to switch back to their original branch (this was a separate worktree).

## Codex continuation — 2026-10-28

- Preserved and resumed from the existing local WIP commit `a1eb44a9762c83b3bcf6fe594faae7cb9a5bb564` in a separate Codex worktree. The original worktree is unchanged. Fetch showed `origin/agent/operator-3d-master-modeling-proof-v1` still at `5e7f8c70346dd539dc0ef229700e40432ce6335c`; the WIP commit was not remotely visible at that point.
- Independently recomputed the 21-frame >3× edge count: 17 unique edges, not approximately 40. The raw vertex trajectories and `stretch_edges_base.json` agree. The approximate count has no edge-ID ledger.
- Reused the existing complete 128px/512px before-and-after renders and face-ID ledgers. Fragment pixels improved 31.4% at 128px and 34.2% at 512px, while affected 128px views rose 49→51. Residual left-hip cloth gap remains unresolved; no triangles were deleted.
- Measured source versus target gait. Arm/forearm direction error is ≤0.00005°. Stance-width ratio and toe axes differ in rest pose; skating remains inconclusive from sparse moving contact samples. No arbitrary gait offsets were applied.
- Exported and clean-reimported an animated iter002 GLB: 0.70s, 21 samples, maximum vertex delta 0.00228mm, loop seam 0.00187mm, 42 bones, 10,367 triangles, normalized weights, UV and 4096px textures retained.
- Validation: 45 asset-pipeline tests including Blender integration; 10 review-publisher tests; both new scripts compile; baseline SHA256SUMS pass.
- Retained Dropbox review manifest: `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter002-review-20261028/REVIEW_MANIFEST.json`.
- Status remains `RUN_MOTION_NEEDS_REPAIR`. Human visual review is required before another subjective repair. No runtime changes, main merge, candidate approval, or freeze.

See `rig_diagnostics/meshy-004_rigged/run_iter002/REPORT_task015_codex.md` for the detailed report.

## Codex human-review iteration — 2026-10-28

- User rejected the iter002 running gait visually and authorized a new reversible derivative. Original iter002 files remain unchanged.
- Iter003 copies the active run action and minimally rotates the four left/right leg-chain axes per frame to match the actual Mixamo FBX. It preserves 30fps / 0.70s timing, 17,578 vertices, 10,367 triangles, topology, rest positions, skin weights, bones, UVs, materials and textures; no cloth geometry was removed.
- Animated toe-axis errors: left 17.53°→0°, right 49.98°→0°. Mean knee width ratio: 1.393→0.909 (source 0.853). Mean stance width ratio: 1.565→0.755 (source 0.535). Arm swing and timing remain intact. The unanimated rest pose is unchanged.
- Whole-clip stretch stays at 2.969× max and 0 edges over 3×; maximum p99.9 improves 2.354×→2.320×. However, 42 vertices penetrate below −5mm in at least one frame, max depth 32.0mm versus 2.7mm before. Fixed heel/toe points show contact windows but pelvis-relative speeds of about 3.6–3.8m/s; right toe remains without contact samples.
- Residual fragments are retained. The fragment metric is nearly flat/slightly worse: 128px 190→188 pixels with affected views 51→58; 512px 3,697→3,749 pixels with affected views 83→84.
- Fresh rest + 21-frame renders were generated independently at 128px and 512px across all eight directions with the canonical camera. The review package includes representative sheets and all-eight-direction loops. Face-ID passes have zero invalid pixels.
- GLB clean reimport initially selected an inactive source action and failed. Export was corrected to active-action-only; the resulting GLB reimports with one corrected action over 0.700s, maximum vertex delta 0.00228mm, seam 0.00186mm, 42 bones, 10,367 triangles, normalized weights, UVMap, and 4096px textures.
- Validation: 45 asset-pipeline tests passed with Blender integration; 10 review-publisher tests passed; baseline SHA256SUMS passed; diagnostic scripts compile. No runtime change, main merge, promotion, freeze, or artistic approval.
- Dropbox review manifest: `/CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter003-review-20261028/REVIEW_MANIFEST.json`.
- Status remains `RUN_MOTION_NEEDS_REPAIR`; visual assessment belongs to the user and ChatGPT.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the first GLB export replayed an inactive source action; stable contact speeds and ground penetration remain unresolved.
- Root cause / contributing factors: inactive source action was retained in Blender's datablocks; source-axis alignment alone does not enforce planted-foot contact.
- Prevention / pipeline improvement: export only the active action and verify its identity; measure fixed landmarks relative to pelvis and test ground penetration.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: preserved iter002 and created a separate, measurable derivative without mesh/weight edits.

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: visually assess gait, ground contact, and residual fragments before authorizing another correction.
- Next action: review the iter003 Dropbox manifest and record a visual decision.
- Blockers or open questions: skating/ground penetration need a decision; rest-pose toe asymmetry remains outside the animated action.
