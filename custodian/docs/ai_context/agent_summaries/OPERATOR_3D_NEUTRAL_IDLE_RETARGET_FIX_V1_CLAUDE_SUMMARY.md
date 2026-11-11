# Operator Neutral Idle Retarget Fix V1

Workstream: `operator-3d-neutral-idle-retarget-fix-v1`

Status: `READY_FOR_HUMAN_VISUAL_REVIEW` — both motion outputs remain candidate-only and unapproved.

Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f

## Implementation

- Replaced source-to-target rest-axis transfer with the shared per-bone quaternion calibration `Q_target_world(t) = Q_source_world(t) * inverse(Q_source_reference_world) * Q_target_rest_world`. The reference is Neutral Idle frame 1, SHA-256 `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`, and is applied identically to both clips.
- Cleared the master’s assigned Running action in the temporary in-memory scene before retarget evaluation; no saved master or action data was modified.
- Added source-thigh-head-relative ankle placement, target chain-length scaling, source knee-plane hints, and analytic two-bone IK. Root trajectory remains separate metadata; target pelvis translation remains at rest. No mesh, weights, rest transforms, materials, animation timing, or original master content changed.
- Added source-relative foot/toe stability detection (<=5 mm per source frame), requiring source sole height within 40 mm of ground, and a weighted sole-clearance constraint. Contact sole vertices are identified from existing foot/toe weights and rest-space height; only contact ankle targets move, by measured IK correction. New Idle needed up to 5.79 mm left / 21.38 mm right. Neutral Idle needed no ankle correction.
- Replaced `ImageChops.difference(...).getbbox()` with exact decoded RGBA byte comparison. Regression tests cover same-alpha RGB changes and the equal-pixel control.

Changed implementation files:

- `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`
- `custodian/tools/operator/animation_compiler/finalize_neutral_idle_candidate.py`
- `custodian/tools/operator/animation_compiler/retarget_calibration.py`
- `custodian/tools/operator/animation_compiler/contracts/mixamo_rest_frame_retarget_policy_v2.json`
- `custodian/tools/validation/test_operator_neutral_idle_proof.py`

## Measurements

Inputs verified against pinned hashes: Neutral Idle FBX `40fda03b…84e1a3`, new Idle FBX `dbab0637…c3b7895`, ITER005 master `a0bdf6c1…17dd969`. They remain unchanged.

| Clip / measurement | Source | Previous Neutral retarget | Corrected |
|---|---:|---:|---:|
| Neutral ankle spacing / leg length, full unique cycle | 0.3945 | 0.7170 | 0.4962 |
| Neutral lateral spacing / pelvis width | 1.3769 | 1.9177 | 1.2132 |
| New Idle ankle spacing / leg length, full unique cycle | 0.3141 | n/a | 0.4508 |
| New Idle lateral spacing / pelvis width | 1.5598 | n/a | 1.3111 |

The corrected Neutral stance ratio is 30.8% lower than the previous retarget and remains 25.8% wider than source after target-leg-length normalization. New Idle remains 43.5% wider by that normalization; it is narrower than source relative to target pelvis width. These denominators are not interchangeable.

Across all unique frames, source and corrected mean knee angles closely agree: Neutral left/right `160.10° / 153.28°` vs `159.96° / 153.08°`; new Idle `163.20° / 167.25°` vs `163.08° / 167.15°`. Mean shoulder-to-wrist direction error is Neutral `7.49° / 17.01°` and new Idle `6.04° / 17.03°` (left/right). Some right-arm directional residual remains.

Both source clips have stable, near-ground sole landmarks: Neutral source minimum foot/toe Z is `+2.31 mm` left and `+0.009 mm` right; new Idle is `+1.14 mm` left and `+0.008 mm` right. After correction, the minimum whole-mesh Z is Neutral `+1.165 mm` and new Idle `+1.000 mm`; zero unique frames penetrate below ground. All tested ankle goals were reached without IK reach clamping.

Neutral source range is 1–264 at 30 FPS, with duplicate endpoint verified; output uses 263 unique frames. New Idle is 1–251 at 30 FPS, duplicate endpoint verified; output uses 250 unique frames. Target loop endpoint deltas are Neutral `0.000018° / 0.000000185 m`; new Idle `0.04038° / 0 m` (rotation / location), within the declared tolerances. Root travel is stored separately.

Full-cycle measurements, all packet sample-frame landmarks, IK diagnostics, repeat checks and artifact paths are in `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/retarget_fix_v1/qa/retarget_fix_validation_report.v1.json`. Candidate and input hashes are in `qa/candidate_manifest.v1.json`.

## Evidence and limitations

- Native 128px eight-direction samples: `review/neutral_idle_128_eight_direction_samples.png`, `review/idle_128_eight_direction_samples.png`.
- Native 512px source / previous / corrected front and side comparisons plus focused front/right-side/rear and Neutral-versus-new-Idle sheets are under `review/`.
- Full-duration 30 FPS comparison MP4s: `/home/braydenchaffee/Downloads/neutral_idle_source_previous_corrected.mp4` (263 unique frames) and `/home/braydenchaffee/Downloads/new_idle_source_neutral_new_candidate.mp4` (250 unique frames). Both are also in the proof review directory.
- Exact repeat check: 22/24 samples had equal decoded RGBA buffers. Two samples differed in exactly one RGB pixel each with identical alpha; all PNG file-byte hashes differed. The former alpha-bounds check falsely reported such RGB-only differences as equal. Exact details are in `qa/repeat_render_check.v1.json`. The new comparator reports the differences correctly; the underlying single-pixel renderer variation remains.
- Neutral Idle SW alpha reaches the last native image row in six sampled frames. The preserved Task 002 output exhibits the same boundary contact. New Idle samples do not touch the image boundary. The fixed camera/root registration was preserved.
- No full eight-direction frame library, GLB, production/runtime asset, or approval was produced.

The provisional technical recommendation is **Neutral Idle as the lead for human review**: its normalized stance residual is smaller and its mean elbow angles are slightly closer to source. New Idle matches knee angles slightly more closely and remains a viable alternate. This recommendation does not judge naturalness or visual quality; the human review retains that decision.

Dropbox review bundle: `/CUSTODIAN/visual_review/operator-3d-neutral-idle-retarget-fix-v1/operator-neutral-idle-retarget-fix-final-20261028/REVIEW_MANIFEST.json`. Retention is `delete-after-review`; the publisher emitted the cleanup command in its handoff.

## Validation

- `python3 -m unittest custodian.tools.validation.test_operator_3d_animation_compiler custodian.tools.validation.test_operator_neutral_idle_proof -v` — 32 tests passed.
- `py_compile` on changed Python files — passed.
- Blender 5.2.3 source inspections, retarget runs, all-frame mesh/landmark checks, sampled 128px / 512px renders, full-duration front previews, and loop validation — completed.
- Exact source/master SHA-256 recheck — passed.
- `git diff --check`, `check_ai_context.py`, and `task_packet_index.py` — passed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: exact repeat rendering exposed two one-pixel RGB variations previously hidden by alpha-only bounding-box comparison.
- Root cause / contributing factors: the old equality predicate ignored RGB differences when alpha was equal; the renderer also has small one-pixel variation in a few repeat samples.
- Prevention / pipeline improvement: compare decoded RGBA bytes and retain same-alpha RGB regression coverage; report actual repeat counts instead of inferring deterministic equality.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-3d-neutral-idle-retarget-fix-v1
- What worked: hash-pinned shared calibration and source-derived contact-phase IK were reusable across both exact Mixamo clips.

## Next Handoff

- Next workstream: review-operator-3d-neutral-idle-retarget-fix-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: none
- Next action: land and archive this implementation, complete the paired fresh-context technical review, then wait for human visual assessment.
- Blockers or open questions: reviewer should confirm the residual one-pixel renderer nondeterminism is accurately bounded; human reviewers decide which idle looks more natural and should be the default.
