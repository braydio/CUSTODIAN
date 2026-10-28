# Task 002 proposal: one Neutral Idle Blender proof

This is a proposal only. Task 001 ends at compiler-interface approval; no Task 002 work is authorized by this document.

## Required human-provided inputs

1. One authorized Neutral Idle Mixamo FBX in a declared local input directory, with its original filename intact. Do not download a replacement automatically.
2. An explicit `.blend` master path and SHA-256, plus its master contract: Blender version, exact armature object and skeleton signature, rest-pose hash, mesh/material hashes, texture hashes, retarget configuration hash, and canonical camera/registration profile. The master may be named experimental for a proof; it is not treated as production-approved.
3. Human confirmation that this exact source/master pairing may be inspected and used for a non-production proof. If source acquisition or master selection remains unresolved, stop before Blender.
4. An authorized Blender executable/version and a declared retarget/inspection script. First inspect the original `inspect_fbx.py`, `retarget_run.py`, and `render_rigged.py` plus ITER003–005 diagnostics when their owner makes them available. Record which routines are reusable and which are fixed to `Running.fbx` or ITER005; do not patch those diagnostics as part of this proof.

## Single-clip procedure

1. Hash the FBX and all master dependencies. Generate a Blender inspection proof that records source skeleton identity/signature, action identity, authored FPS and inclusive keyframe range, root-motion state/trajectory, and the exact target master/retarget policy hashes.
2. Validate the manifest and proof before import. Retarget without changing action timing or source files. Keep original trajectory samples in a separate sidecar; for the sprite action, state explicitly whether root translation is retained or extracted. The sidecar and pose policy must declare one Godot application route to prevent double displacement.
3. Process only `neutral_idle`, selecting the exact action by inspected identity. Support its full declared frame range even if it is 264 or 299 frames. Use the manifest loop endpoint rule; do not infer loop status from the action name.
4. Render all eight independent directions as full-body 128×128 RGBA at fixed 45° elevation and 50 px/m, master-derived fixed scale, and root pixel `(64,106)`. Do not mirror, zoom per frame, composite upper/lower body layers, or alter the master. Capture a native 512px diagnostic only when a predeclared technical QA question requires it.
5. Produce a candidate receipt with exact dependency/output hashes, sampled frame indices, trajectory hash, registration checks, alpha/canvas checks, per-direction completeness and deterministic rerun fingerprints. Keep all generated work under a dedicated ignored/source-work proof directory; do not write to Workbench, canonical source, Asset V2 inbox, runtime, or production selectors.
6. Stop after technical QA and a compact review package. A technical pass is not visual approval, timing authority, Asset V2 acceptance or runtime publication. Human review must decide the candidate before any later 2.5D ingress task.

## Acceptance for a future packet

The same input hashes produce the same inspection/retarget/render receipt and output fingerprints; action timing matches the source inspection proof; the trajectory is preserved separately and cannot be applied twice; all eight views meet the fixed output/registration contract; no source/master/runtime bytes change; the receipt remains `candidate_unapproved`. Any missing source, master hash, compatible-rig proof, Blender script, or human authorization blocks the proof.
