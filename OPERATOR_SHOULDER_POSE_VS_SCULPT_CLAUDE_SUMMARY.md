# Operator Shoulder Pose-versus-Sculpt Diagnostic Summary

Workstream: `operator-shoulder-symmetry-and-rigging-v1`
Branch: `agent/operator-shoulder-pose-diagnostic-v1`
Status: `READY_FOR_HUMAN_VISUAL_REVIEW`

## Result

Ran one isolated diagnostic on the original ITER005 blend, without saving changes to the source model. The source blend SHA-256 is recorded in the report and JSON. Before/after signatures match for body coordinates/topology, vertex-group weights, armature rest matrices, and action curves.

The exact right-shoulder correction calculated from mirrored bone coordinates is a head translation of `(0, -43.806911, +0.000238)` mm and shortest-arc quaternion `(w,x,y,z) = (0.997759044, 0.000000056, 0.000000286, 0.066909902)`, or +7.673004 degrees about armature-local +Z. The right bone is 8.444 mm longer than the left, so both endpoints cannot be made coincident while preserving its length.

The position-plus-rotation condition improved reflected 37×37 px shoulder-patch IoU from 0.7973 to 0.8520 in front and 0.7626 to 0.8531 in rear. Rotation-only moved those measures to 0.8069 and 0.7718. In running probes, position-plus-rotation produced up to 91.6% absolute edge-length change (95th percentile 11.8%); rotation-only peaked at 30.3% (95th percentile 5.1%). These are reported as measured differences, with no invented pass threshold.

Recommendation: **mixed evidence**. Bone placement/orientation is a demonstrated contributor to neutral bilateral silhouette mismatch, but position-plus-rotation is not recommended for direct application to the running retargeting pipeline based on this diagnostic. A measurable contour residual remains and this experiment does not isolate whether it comes from sculpt, weights, or their interaction. The visual verdict and next decision remain with the user/ChatGPT.

## Evidence

- Diagnostic report: `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_pose_vs_sculpt_iter001/REPORT_pose_vs_sculpt.md`
- Correction JSON, including matrices, projections, render metrics, motion matrices and source-preservation hashes: `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_pose_vs_sculpt_iter001/shoulder_pose_correction.json`
- Native 128 all-eight comparison, native 512 shoulder crops, and frame 6/13/16 four-direction comparisons are beside the report. Raw renders are retained beneath `renders/` and `motion/`.
- Reproduction script: `custodian/asset_drop/source_work/operator/operator_3d_master/scripts/rig_diag/diagnose_shoulder_pose_vs_sculpt.py`
- Local artifact SHA-256 manifest: `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/shoulder_pose_vs_sculpt_iter001/SHA256SUMS.txt`

## Scope and negative controls

No production mesh, rest bone, weight, action, GLB, Godot asset, or runtime policy was changed. No shoulder geometry variant was created. The user-provided original, Task017 artifacts, and ITER005 source remain unmodified. The worktree is isolated from the coordination checkout and preservation worktrees.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: initial ROI projection used the last rendered camera direction; corrected before final measurements. Blender 5.2 action channels required layered Action channel-bag traversal.
- Root cause / contributing factors: existing study helper did not expose a pose-condition evaluation interface; Blender's action API differs from legacy F-Curve access.
- Prevention / pipeline improvement: add a reusable pose-condition diagnostic harness with camera-aware fixed ROIs and Blender 5.x action-channel access.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: source-preservation hashes, fixed-camera rendering, and joint-centered bilateral silhouette patches separated neutral alignment from animation deformation.

## Next Handoff
- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: human visual decision required on the pose-vs-sculpt evidence and running deformation tradeoff.
- Next action: review the published diagnostic evidence and decide whether to keep the rig unchanged or authorize a narrowly scoped follow-up.
- Blockers or open questions: whether the residual mismatch is acceptable and whether any pose-space correction is visually beneficial through motion.
