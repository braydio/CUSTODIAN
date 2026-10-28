# TASK 016 — shoulder symmetry and rigging

**Workstream:** `operator-shoulder-symmetry-and-rigging-v1`
**Branch:** `agent/operator-shoulder-symmetry-and-rigging-v1`
**Status:** `MODEL_SHOULDER_REPAIR_REQUIRED`
**Starting reference:** shoulder study `d8a1e656dcac52e69196779f3ad77eb457d6f2d7`; motion source ITER005 `6b89c4d50`.

## Outcome

Stopped after Phase A, before editing the model. The existing shoulder study's 917-face source selector produces disconnected patches rather than a defensible pauldron boundary. Integrating, mirroring, deleting, or merely reweighting those patches would not meet the requested geometry and rigging guarantees.

## Measurements

- Torso mirror plane: x = +2.386 mm.
- Baseline selector counts: anatomical Left 503 faces / 864 vertices; anatomical Right 414 faces / 733 vertices.
- Topology check: Left largest connected face component 41 faces, 865 boundary edges; Right largest component 35 faces, 742 boundary edges. Each side has more than eight components.
- Baseline selected surface mirrored nearest-neighbor error: mean 31.16 mm, p95 68.50 mm, max 87.21 mm.
- Existing Variant A overlay mirrored error: mean 29.53 mm, p95 66.58 mm, max 86.96 mm.
- Existing Variant A is not rigged: no armature modifier or vertex groups. Original surfaces remain underneath. Existing intersection evidence records 96 triangle-pair overlaps involving 52 overlay faces.
- Camera S image-left is anatomical Right, below the measured mirror plane.

These selector-derived comparisons do not independently quantify the baseline sculpt's anatomical asymmetry because selected topology differs between sides. This limitation is explicit in `task016_phaseA/TASK016_REPORT.md`.

## Files

- `custodian/asset_drop/source_work/operator/operator_3d_master/scripts/rig_diag/diagnose_shoulder_asymmetry.py`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task016_phaseA/check_shoulder_patch_topology.py`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task016_phaseA/phaseA_shoulder_asymmetry.json`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task016_phaseA/phaseA_shoulder_patch_intersections.png`
- `custodian/asset_drop/source_work/operator/operator_3d_master/rig_diagnostics/meshy-004_rigged/task016_phaseA/TASK016_REPORT.md`

The four individual diagnostic direction renders are retained locally as generated evidence, not included in the compact commit.

## Preservation and validation

No geometry, weights, animation, armature rest transforms, materials, or source models were changed. No `.blend` derivative or GLB was created. Read-only inspection and the topology script completed; no motion, export/reimport, or corrected-model render checks were run because there is no justified corrected model to validate. No Dropbox review bundle was published; the required before/after evidence does not exist without the derivative.

ITER005 source, shoulder-study source blends, original Claude worktree, and coordination checkout were preserved. All work and eventual commit are confined to the new isolated Task 016 worktree.

## Next requirement

Provide a topology-separated pauldron source or authorize a bounded segmentation/annotation task that identifies exact plate perimeters while protecting the underlying torso and arm surfaces. Then repeat the authorized one-derivative implementation and validation cycle. No human aesthetic verdict is sought at this stage; this is a geometry-authority blocker.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: the static study selector was treated as a plate source despite selecting disconnected, unequal face islands.
- Root cause / contributing factors: the study duplicated a weight-and-bounds mask but did not provide topology-separated armor regions or exact replacement boundaries.
- Prevention / pipeline improvement: static shape studies should preserve source face IDs and expose a validated connected plate perimeter before being handed off as an integration source.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: isolated worktree and read-only phase A diagnostics exposed the construction limitation before altering the source rig.

## Next Handoff
- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: exact pauldron geometry boundary is not established by existing source topology.
- Next action: supply or authorize topology-separated pauldron source geometry / bounded segmentation, then define a fresh correction task.
- Blockers or open questions: which existing faces or separately authored plate mesh represent the intended shoulder armor without removing unrelated body surfaces?
