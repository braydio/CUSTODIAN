# Task 002 proposal: one Neutral Idle Blender proof

This was a proposal. Execution was subsequently authorized by `OPERATOR_3D_NEUTRAL_IDLE_BLENDER_PROOF_V1.md`, including the user's narrow waiver of the Task 001 independent review only for this experimental proof.

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

## Experimental proof result

Proof root: `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/`.

- Source FBX SHA-256: `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`; action `Armature|mixamo.com|Layer0`, 30 FPS, frames 1–264.
- Experimental master SHA-256: `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`.
- Eight directions × 263 frames at 128×128 RGBA; candidate technical QA passes. The source trajectory is separate; no runtime timing was inferred.
- Repeated retargeted motion file SHA-256 matched exactly. All 24 repeated sample renders matched decoded pixels; PNG file bytes differed, recorded as bounded encoder variation.
- Candidate receipt: `candidate/neutral_idle_candidate_receipt.v1.json`; state `candidate_unapproved`; production approval false. Compiler receipt `check --candidate-only` reports no staleness; default production validation still requires runtime timing authority.
- Dropbox handoff manifest is recorded in the durable workstream summary. Human animation-quality review is still required; no aesthetic approval is claimed.
