# Operator 3D Animation Batch Executor V1 — corrected Neutral Idle preview

Workstream: `operator-3d-animation-batch-executor-v1`

## Delivered

Resumed the existing claimed workstream and used the complete calibrated v2 rest-frame retarget, not the rejected Task 002 receipt. It contains frames 1–264 at authored 30 FPS for the compatible 42-bone Operator rig; source frame 264 is the verified duplicate loop endpoint, so the candidate samples 1–263. Source trajectory remains separate metadata from in-place poses.

Rendered a new candidate under the experimental ITER005 baseline: eight independent directions × 263 frames = 2,104 128×128 RGBA images; 45° elevation, 50 px/m, root `(64,106)`, fixed master-derived scale `1.2287417600294088`, no mirroring. Candidate version is `neutral_idle_rest_frame_v2_awakening_128_v1`; job ID is `op3d-neutral-idle-v2-f7832b29158a1aa7e78e9c53`; receipt SHA-256 is `5c237de902397e1bae1f0de6bc3951334369b95db46c9b9e9064ef38b916853b`. The rejected receipt remains unchanged at SHA-256 `1fd0b407d4ac1267b687cea024647ff7be7bf6bc8fe95b08dcc1b300aa13aee6`.

Added a dev-only wrapper for the real Awakening scene at Attestation Gallery (`zone03_attestation`), spawn `(0,-1824)`, facing South, with the real camera at its authored `1.89` zoom. The wrapper disables its actor simulation/collision and progression triggers while retaining real lighting, underlay, foreground/occlusion, Operator presenter and renderer. It preserves the candidate/approved toggle, eight direction controls, authored-FPS playback and unapproved badge; the exact candidate version is displayed. A preview-instance-only alpha blend is applied to the existing shadow texture/material to avoid the multiply material's opaque-looking rectangle on the floor; no source/runtime material or scene was changed.

## Verification and findings

- `python3 -m unittest custodian.tools.validation.test_operator_3d_animation_preview_package -v` — 9 passed.
- `python3 -m py_compile .../finalize_corrected_neutral_idle.py .../preview_package.py` — passed.
- `git diff --check` — passed.
- Final Awakening preview package smoke — passed: exact 2,104 frames loaded and checked at 30 FPS; eight directions, correct scene/camera/spawn, one visible body owner, visible shadow, zero ground-registration residual, disabled gameplay/triggers, no timing authority and no production approval.
- Repeated 24 key renders (frames 1, 132, 263 in all eight directions): 19 decoded RGBA matches, 0 PNG byte-identical outputs. This nondeterminism is recorded in the QA report.
- Southwest alpha touches the last image row in 152/263 frames. The candidate QA records this as a visual-review finding. Existing cycle diagnostics report zero below-ground mesh frames and minimum mesh height `0.00116504 m`.
- Retarget measurements: mean normalized ankle spacing `0.496191` target leg lengths and `1.213221` pelvis widths; mean elbow angles L/R `157.217° / 162.146°`; mean knee angles L/R `159.929° / 153.098°`; mean shoulder-to-wrist direction error L/R `7.49° / 17.012°`.
- Experimental master and original FBX hashes remained respectively `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969` and `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`. Original rejected receipt hash also remains unchanged.
- No shoulder geometry, ITER005 Running, source FBX, master `.blend`, canonical/runtime/Workbench assets, timing authority or production scene was changed.

## Visual handoff

- Final loop: `neutral_idle_awakening_full_loop.mp4`, 1280×720 H.264, 30 FPS, 263 frames, 8.766667 seconds; SHA-256 `1b8440a522394a517803f862e599f94566c3e798e13793995e9e84917c41a084`.
- Matched previous-vs-corrected South comparison: frames 1, 132 and 263, same Awakening scene, camera and scale.
- Dropbox manifest: `/CUSTODIAN/visual_review/operator-3d-animation-batch-executor-v1/20261030T032053Z/REVIEW_MANIFEST.json`
- Review questions: Do the corrected hands and arms read relaxed through the loop? Does the stance/weight distribution look natural, including Southwest boundary contact and the raised-foot/stagger impression? Does the idle read alive at actual game scale?
- Default cleanup after the human decision: delete-after-review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the first in-game capture exposed preview controls over the Awakening HUD and an opaque-looking shadow rectangle; wide-view QA also found frequent Southwest last-row contact and repeated renders were not bit-identical
- Root cause / contributing factors: the preview reused the old top-left control placement and the runtime multiply shadow material's transparent texels darkened the scene; the fixed camera/scale produced a directional boundary contact; Blender EEVEE output varied between processes
- Prevention / pipeline improvement: capture the actual target environment early, test alpha bounds across all directions, and report repeat-render pixel identity instead of assuming determinism
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: hash-bound packaging and the Awakening smoke validated every frame through the real presenter before the compact visual handoff

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: Human visual assessment of corrected hands, stance, foot contact and subtle movement is required before further retarget iteration or executor expansion.
- Next action: Review the published full loop and matched comparison, record the visual decision, then explicitly continue this same workstream if engineering should resume.
- Blockers or open questions: Does the corrected hand/arm pose remain relaxed in motion? Is the Southwest boundary contact acceptable? Does the idle feel alive at the Awakening camera scale?
