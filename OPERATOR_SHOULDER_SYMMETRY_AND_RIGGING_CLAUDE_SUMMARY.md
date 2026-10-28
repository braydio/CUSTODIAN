# TASK 017 — clean pauldron geometry and rigging proof

**Workstream:** `operator-shoulder-symmetry-and-rigging-v1`
**Task branch:** `agent/operator-shoulder-symmetry-and-rigging-v1-task017`
**Starting checkpoint:** `285cff6f99a4dac4cb49267db76f46697d8df455`
**Motion reference:** ITER005 `6b89c4d503bb2d73d2783443d4280f313c681bfa`
**Status:** `MODEL_SHOULDER_REPAIR_REQUIRED`

## Outcome

Created one reversible derivative with a new matched pair of closed pauldron shells. The shell meshes are manifold, symmetric to within 0.000030 mm, rigidly weighted to their corresponding shoulder bones, and clear of the upper-arm surface through 21 unique ITER005 frames, the loop endpoint, and two temporary raised-arm probes.

The candidate fails clean added-shell integration. Across the cycle, shell surfaces intersect 98 source body faces on anatomical Left and 113 on Right. Those regions comprise 44 and 43 disconnected components, respectively, and orthographic camera-ray checks find 50 / 53 of those source-face centers exposed as first-hit surfaces in at least one direction/frame. This is not a confined hidden attachment overlap. The exact body face IDs are preserved in the diagnostics. No body geometry was removed and no second geometry attempt was made.

No GLB was exported because geometry integrity failed. The candidate remains in the experiment worktree, not production. No runtime changes, merge, promotion, or freeze occurred.

## Geometry and preservation

- Two separate objects: 434 vertices, 456 faces, 864 triangles each (868 added vertices, 912 faces, 1,728 triangles total).
- Dimensions: 234 × 290 × 145 mm; 4 mm shell thickness; 295 mm outer projection relative to mean shoulder joint; ridge 166 mm above the mean shoulder-bone head.
- One normalized 1.0 weight per vertex to the matching shoulder bone; no new bones; matching Armature modifiers; existing `BakedMaterial` and nearest-surface source UV projection.
- Existing body geometry and weights, body material slots/modifiers, bone set/rest transforms, ITER005 action curves, 30 fps timing, and 1–22 action range all hash-match the ITER005 source.
- Maximum endpoint vertex delta: body 0.00160 mm; left shell 0.00096 mm; right shell 0.00036 mm.
- Upper-arm intersection pairs: zero. Minimum shell-to-arm vertex clearance: 33.95 mm Left / 11.74 mm Right in the run; 8.4 / 10.5 mm in the temporary 75° probes.
- Body-shell intersection pair counts: 86–131 Left / 119–148 Right through frames 1–22.
- Body-overlap region analysis: 98 faces / 181 vertices / 44 components / 186 boundary edges Left; 113 faces / 191 vertices / 43 components / 195 boundary edges Right. Largest components are 11 and 16 faces. This identifies affected faces, not permission to delete them; an exact minimal removal/retopology region is not established.

## Evidence

The retained Dropbox `REVIEW_MANIFEST.json` is recorded below after publication. It contains hashes for the published report, comparison images, loop, and objective diagnostics. Large model files and raw frame PNGs remain local in the experiment worktree.

- Static 128px three-way, all eight directions.
- Static native 512px three-way, all eight directions; six-view shoulder closeups.
- Three-way 128px silhouette sheet.
- Corrected 21-frame, eight-direction 128px loop; unchanged ITER005 comparison at frames 6, 16, and 13.
- 512px geometry/attachment/intersection diagnostic.
- Geometry, overlap visibility, and overlap-region JSON reports.
- Fixed camera contract preserved: scale 1.23547, 45° elevation, 50 px/m at 128px, root pixel (64,106), eight directions, no mirroring. No edge-touch clipping was found in 192 static and loop frames.

## Files

- Candidate: `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task017_clean_pauldrons/operator_iter005_clean_pauldrons_task017.blend` (local, uncommitted model artifact).
- Task report: `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task017_clean_pauldrons/TASK017_REPORT.md`.
- Build / validation / render tools: `scripts/rig_diag/create_task017_clean_pauldrons.py`, `validate_task017_clean_pauldrons.py`, `render_task017_pauldrons.py`, `measure_task017_overlap_visibility.py`, and `analyze_task017_overlap_regions.py`.
- Machine-readable results: `task017_geometry_build.json`, `geometry_validation.json`, `overlap_visibility.json`, `overlap_region_analysis.json`, `render_metadata.json`, `evidence_sha256.json`.
- Render evidence files are listed in the review manifest and remain under `task017_clean_pauldrons/` locally.

## Human review boundary

No subjective judgment was made about style, fit, proportions, or preference. Please review whether the shell form follows Variant A's direction and whether the marked source-body intersections make this added-shell approach unsuitable. The branch remains experimental; a new repair or face-removal task needs explicit authorization.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the new shells were structurally matched and rigged, but overlap testing found exposed intersection regions on the preserved source body.
- Root cause / contributing factors: the existing shoulder surface envelope intersects the added shell in many disconnected source-face islands.
- Prevention / pipeline improvement: require overlap visibility and connected-component checks before treating independently authored armor shells as integration-ready.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: direct source hashes, full-cycle bvh checks, arm-clearance probes, and orthographic face-ray tests exposed the integration issue without destructive edits.

## Next Handoff
- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: decide whether to authorize a new clearance design or a narrowly specified body-surface replacement task based on the affected face sets and review images.
- Next action: human visual/technical review; do not continue modeling automatically.
- Blockers or open questions: should the next task prioritize shell clearance/repositioning, or authorize a bounded topological body-surface integration for the 98/113 face regions?
