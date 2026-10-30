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

## Corrected accepted 128px vs. 3D visual comparison

The previous A/B package is withdrawn as design evidence: it compared the candidate with the live legacy 96px runtime idle, which lacks exact diagonal art. The runtime screenshots and technical smoke data remain diagnostic evidence only. This corrected package uses the accepted, hash-verified 128px 8-direction full-body source. It reuses the existing 2,104-frame v2 candidate without rerendering or mutation.

Local bundle: `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/visual_comparison_approved128_20261030T1254/review_bundle/`

- `operator_3d_vs_approved_8dir.png`: first, middle and last accepted 2D atlas frames and candidate frames across N/NE/E/SE/S/SW/W/NW. Both sources are shown in native 128×128 cells with nearest-neighbor enlargement only.
- `operator_3d_vs_approved_ingame.png`: South middle-frame side-by-side captures through the same actual Awakening scene, camera, spawn, floor, shadow and viewport. Captures were made separately, with only one body owner active each time.
- `operator_3d_vs_approved_motion.mp4`: H.264 `yuv420p`, 3840×1440, 30fps, 526 frames / 17.533s. Four A/B pairs show N, NE, S and SW. This is two complete 263-frame candidate loops. The accepted 15-frame source uses a labeled 10fps preview cadence because its source FPS is unknown; cycles are not retimed or synchronized by dropping/duplicating frames.
- `operator_3d_technical_comparison.md`: source/runtime distinction, capture controls, QA measurements, limits and review questions.
- `comparison_manifest.json`: pinned source, candidate, scene and runtime identities, timing, transforms, prop state, and artifact hashes.

The accepted source SHA-256 is `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`; it is an accepted art source, not runtime-promoted and has no approved FPS. The live `operator.tscn` still uses the `legacy_96` runtime resource and diagonal fallback behavior; WB25-6 remains `draft/manual`. No production runtime source or timing authority changed.

Both presentations use preview scale 1.0 and offset `(0,-42)`, with root pixel `(64,106)`. The Awakening source scene still contains `RuinFloorCrackC`; the capture hid only that exact no-collision Sprite2D detail in the isolated preview instance after checking its texture and position. The authored scene remains untouched.

Dropbox handoff: `/CUSTODIAN/visual_review/operator-3d-animation-batch-executor-v1/20261030T170942Z/REVIEW_MANIFEST.json`. The five listed artifacts and their SHA-256/byte counts were independently verified from Dropbox. Retention is delete-after-review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the previous visual A/B used legacy 96px runtime artwork instead of the accepted 128px design source; initial captures also exposed preview-control and shadow-presentation issues. Southwest alpha touches the bottom row in 152 frames and repeat render pixels are not fully deterministic.
- Root cause / contributing factors: the preview treated the current runtime resource as the approved design reference; the runtime is still `legacy_96`, while the accepted 128px source is not runtime-promoted. A prior source/selector distinction was missing.
- Prevention / pipeline improvement: keep accepted design reference and live runtime identities explicit in preview requests and labels; verify all eight reference directions before comparison; continue recording alpha-boundary and repeated-render evidence.
- Tooling / docs drift discovered: none
- Follow-up: human-visual-review-required
- What worked: hash-bound packaging and the Awakening smoke validated every frame through the real presenter before the compact visual handoff

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: Human visual assessment of corrected hands, stance, foot contact and subtle movement is required before further retarget iteration or executor expansion.
- Next action: Review the published A/B comparison package, record the visual decision, then explicitly continue this same workstream if engineering should resume.
- Blockers or open questions: Does the candidate preserve the accepted 128px Operator identity? Are hands, arms, stance, grounding and subtle motion acceptable across the loop? Is Southwest boundary contact acceptable?
