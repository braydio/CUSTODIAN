# TASK 016 Phase A — shoulder construction blocker

**Workstream:** `operator-shoulder-symmetry-and-rigging-v1`
**Status:** `MODEL_SHOULDER_REPAIR_REQUIRED`
**Result:** No corrected model derivative was created. Geometry, weights, and animation were not modified.

## Inputs inspected

- `shoulder_plate_study_iter001/BASELINE.blend`
- `shoulder_plate_study_iter001/VARIANT_A_MODERATE.blend`
- `run_iter005/operator_run_mixamo_iter005_contact_ik.blend` was preserved; no changes were made to it.
- Existing generation, render, and validation scripts, plus the prior Variant A intersection results.

## Findings

The image-left pauldron in camera S is the anatomical `RightShoulder` (world x below the torso mirror plane); the mapping is recorded in `phaseA_shoulder_asymmetry.json`. The common mirror plane from shoulder-joint positions is x=+2.386 mm.

The baseline patch selector does not isolate a continuous shoulder plate. It selects 503 faces / 864 unique vertices on anatomical Left and 414 faces / 733 vertices on anatomical Right. A topology check found at least 8 disconnected components on each side (Left largest component 41 faces; Right 35), with 865 and 742 boundary edges respectively. These are fragmented islands, not a safely replaceable plate boundary. Their UVs span nearly the full texture on both sides, and selected-face normals vary widely (Left 0.8–176.9°, Right 3.6–169.3° relative to the outward shoulder axis).

The asymmetric selector returns 89 more Left faces (21.5% more than Right). The mirrored selected-surface nearest-neighbor deviation is mean 31.16 mm, p95 68.50 mm, maximum 87.21 mm. Variant A's duplicated overlay remains unweighted and unarmatured. Its overlay symmetry deviation is mean 29.53 mm, p95 66.58 mm, maximum 86.96 mm. The original faces remain under it; the previous intersection check reports 96 overlay/base triangle pairs across 52 overlay faces.

This evidence supports that the static study's source-face selection is asymmetric and structurally unsuitable for integration. It does not isolate how much additional discrepancy belongs to the underlying sculpt versus the face selector, because the selector has no coherent corresponding surface regions. The symmetric ±40 mm / +15 mm overlay translation is not itself the identified side-specific difference. A body surface texture/material face mask is also not a safe substitute for a topology boundary.

## Stop rationale

Mirroring, deleting, or replacing these selected faces would alter hundreds of disconnected regions with no reliable plate perimeter, risk removing unrelated torso/arm surfaces, and could not be shown to preserve the underlying body. Reusing the existing overlay would retain the known unweighted, intersecting construction. Attaching that overlay to a shoulder bone would make it move but would not resolve its construction or establish clearance. Either route would produce a derivative that appears technically complete while bypassing the task's integration requirements.

Per the bounded task instruction, work stopped before geometry or rig edits. ITER005 action, weights, materials, mesh topology, and source files remain unchanged. No raised-arm or run deformation claims are made.

## Evidence

- `phaseA_shoulder_asymmetry.json` — geometric bounds, weights, mirror-plane and intersection measures.
- `phaseA_shoulder_patch_intersections.png` — diagnostic surface-selection and intersection overview; cyan marks selected source regions, magenta the detached Variant A overlay, and red the detected overlap regions.
- `diagnose_shoulder_asymmetry.py` — reproducible read-only Phase A inspection.
- `check_shoulder_patch_topology.py` — reproducible selector topology / UV / normal check.

## Changes and validation

- Model geometry changed: none.
- Vertex weights / groups changed: none.
- Animation or rest transforms changed: none.
- New `.blend` / `.glb`: none.
- Validation completed: read-only source comparisons, selector connected-component / boundary-edge check, weight and bounds measurements, and visual inspection of the diagnostic projection.
- Validation not run: corrected-model motion clearance, export/reimport, and before/after render suite, because no justified corrected derivative could be constructed from the fragmented source selection.
- No Dropbox review bundle was published: the required three-way and motion evidence cannot exist without a corrected derivative. The compact Phase A evidence is retained in this branch for a focused geometry-authoring decision.

## Required next input

Provide or authorize a source with a reliable pauldron perimeter / region annotation (or a topology-separated shoulder armor object), or authorize a new bounded source-segmentation task. Once a real plate region is identifiable, the requested matched construction, bone attachment, and single validation cycle can proceed. No subjective visual selection is being requested here; the blocker is the absence of a defensible geometry boundary.
