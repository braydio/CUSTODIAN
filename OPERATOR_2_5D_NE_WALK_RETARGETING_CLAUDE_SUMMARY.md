# Operator V6 — accepted crossover, full-cycle continuity checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe
Status: **bounded continuity implementation validated; full 15-frame visual review
pending**. Retain branch/worktree/checkpoints. No main merge, runtime publication
or timing approval. Human calibration acceptance does not accept this animation.

## Human decision recorded

At checkpoint `65369509d`, the human ACCEPTED the five-pose crossover foundation:
leg identities and gait alternation credible; F07 hidden far sole legitimate;
F05 robe coverage acceptable with caution; support handoffs 6/7 and 13/14 accepted
provisionally as working transitions. Authorized bounded continuity/transition
fitting, local occlusion review if needed and full 15-frame regeneration.

`crossover_acceptance.json` records that decision, exact source/rig/annotation/
mapping hashes, reviewed pose geometry and PNG hashes. `donor_authority.json`
authorizes full preview regeneration; CLI requires the human receipt and unchanged
accepted inputs before writing output. `CROSSOVER_CORRECTION_BRIEF.md` carries the
native decision continuation. No new/duplicate task packet was invented.

The accepted calibration Dropbox manifest
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/ne-donor-crossover-calibration-v2/REVIEW_MANIFEST.json`
was cleaned after recording the decision; publisher returned `deleted` and removed
its latest pointer. This decision and receipt remain durable in Git.

## Immutable authority preserved

- Actual NE donor `~/Knight_NE_Reference.png`, SHA256
  `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`.
- Original `~/Downloads/SINGLE_FRAME.aseprite`, 2191 opaque pixels, SHA256
  `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`.
- Accepted `operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`, SHA256
  `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`.
- All 135 annotated coordinates and `crossover.py` are byte-unchanged; accepted
  52/47/21 far ownership, four hidden covers, pivots/lengths/palette and neutral
  reconstruction remain intact. Recovered source's 11 differing pixels excluded.
- Original source-only donor bundle remains under
  `~/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1/`.
  All 15 hashes and exact reassembly pass. No source/runtime ingest or asset family.

Final `locked_input_hashes.json` confirms unchanged donor/original/rig bytes. Earlier
checkpoints including 8a254e0f1, 2ff294117 and 65369509d remain in branch ancestry.
No donor direction or rig recovery work was reopened.

## Implementation and why exact static locks were infeasible

New `continuity.py` fits angles around the same accepted segment-direction mapping.
It retains exact lengths, fixed pelvis/hips and consistent near+ / far− knee branches.
It preserves every donor lead sign, at least 75% target ankle separation and a .5px
internal sign margin. No old neutral ankle bias, swing attenuation or phase filter.
Five accepted poses stay immutable as comparison targets, weighted four times the
intermediate target cost, with a 6px maximum fitted-joint deviation.

Exact full-cycle keyframe locking is mathematically impossible under the unchanged
8px step limit: F12→F15 near toe covers 33.56px in three steps (maximum allowed
24px). F5→F7 far ankle also exceeds 16px in two steps. The implementation preserves
accepted mapping/annotation/reference pixels and reports necessary fitted deviations;
it does not overwrite those inputs or silently relax their temporal thresholds.

The five static renders also used varying near-straight IK branches. Full-cycle
fitting starts from stable branches in the unchanged numerical mapping, weights the
actual accepted rendered geometry as targets and passes planned knees into render
IK. This removes branch switching without reopening anatomical source recovery.

SLSQP operates in exact-length angular coordinates with fixed branches, original
fit/reach gates, cyclic seam and all-frame crossover guards. Initial solver scaling
was poorly conditioned; normalizing objective/constraints resolved convergence.
`requirements-continuity.txt` records tested NumPy 2.5.4 / SciPy 1.18.1; no package
was installed or external service used. Reports record versions/iterations/residual.

The first mechanically valid 7.95px planning guard left F14 contact y error
-1.136px; rendered result was 14/15 and was rejected. Planning now uses tighter
7.6px / 58° guards to reserve raster correction room. Acceptance remains **8px fit,
8px adjacent joint, 60° rotation, sole 2px x / 1px y**. No threshold was relaxed.
Only F7 needs (0,-0.25)px quarter-pixel support correction, with IK re-solved.

`occlusion.lua` measures actual transformed owner masks, visible limb pixels,
costume coverage and support-sole occluders. It never changes compositing order.
No repaint, whole-limb swap or visibility-driven forced exposure was added. Existing
independent upper-body 2° and robe phase controls remain. `run.py` checks rendered
lead ordering and the calibration fitting envelope, exposes per-joint deviations
and includes full plan/acceptance data. Viewer labels fitting deviation accurately
and still requires an explicit non-authoritative playback rate.

## Final measured result

| Measure | Current rendered result | Existing limit |
|---|---:|---:|
| Full frame checks | **15/15** | 15 |
| Rendered support contacts | **15/15** | 15 |
| Max adjacent joint step | 7.600px | 8px |
| Max adjacent rotation | 58.000° | 60° |
| Max knee fit | 5.395px | 8px |
| Max sole residual x / y | 1.086 / 0.999162px | 2 / 1px |
| Knee branch flips | 0 | 0 |
| 15→1 max joint step | 7.600px | 8px |
| Max enclosed transparency | 14px/frame | diagnostic, not approval |

All six known transitions now pass: **2→3, 6→7, 9→10, 10→11, 12→13, 13→14**.
Both lead-order reversals remain **2→3 and 7→8**. All cells 128×128 RGBA, strip
1920×128, palette subset/binary alpha/bounds pass. No edge clipping. Original
3/15 → accepted-rig 5/15 baselines are historical. The old-donor 15/15 animation was
rejected; this is a new 15/15 result on the human-accepted crossover foundation.

| Frame | Working support | Near-minus-far ankle x | Sole dx / dy px | Visible far pixels |
|---|---|---:|---:|---:|
| 5 | near | -14.998 | 0.064 / -0.476 | 21 |
| 6 | near | -11.128 | 0.472 / 0.481 | 30 |
| 7 | far | -2.482 | -0.601 / -0.280 | 75 |
| 13 | far | 29.485 | 0.647 / -0.999 | 106 |
| 14 | near | 23.194 | -0.158 / 0.147 | 108 |

Working 6/7 and 13/14 contact/continuity checks pass, but dynamic perceptual support
and a world-space ground plane cannot be established solely from one projection.
F07 now has two visible sole pixels as a consequence of fitting, not forced exposure
or a layer-order change. F05 has 21 visible far pixels vs 17 in the accepted static;
no local occlusion edit was necessary. Human readability judgment remains required.

## Fidelity costs and unresolved visual questions

Max deviation from the unchanged raw mapping ankle targets is **7.340px**, including
intermediate poses not part of the five-pose review. Exact per-joint comparisons:

| Reviewed frame | Near max joint change | Far max joint change |
|---|---:|---:|
| 12 | 5.755px | 0.866px |
| 2 | 1.555px | 2.071px |
| 7 | 0.536px | 1.626px |
| 5 | 1.365px | 0.596px |
| 15 | 5.439px | 0.898px |

All remain inside the explicit 6px reviewed-target fitting envelope. F12/F15 need
the largest near-foot changes to meet the transition limit. The inherited ±24°
boot-pitch cap and significant far-toe donor mismatch remain; no exact toe matching
or new direction diagnosis. Enclosed transparent regions may be intended gaps or
costume seams; their maximum 14px is not aesthetic approval. Numeric success is
not acceptance of gait rhythm, secondary motion, seam or animation timing.

## Concrete validation

Final local output:
`~/Downloads/operator_ne_master_audit_implementation_v1/v6_accepted_crossover_continuity_review_v1/`

- Actual Aseprite `run.py` against accepted rig/exact donor: **15/15** final rendered
  checks, source/preflight hashes/reassembly, lengths/fit/contacts/branches/crossover,
  all 15 cyclic transitions, palette and bounds. Raw Lua log/report preserved.
- `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py`: PASS;
  reproduces the six baseline failures and verifies fitted cyclic invariants,
  missing acceptance, changed annotations, inverted lead, fitting-envelope breach,
  original segment/root/threshold and seam negative controls.
- `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`:
  **11/11 PASS**, full changed coverage, no failed/skipped/timed-out/infrastructure
  checks. Memory checked first; one sweep. JSON stays local.
- `node --check .../viewer_syntax_check.js`: PASS for generated HTML viewer script.
- `git diff --check`: PASS. Accepted mapping/annotation hash checks and final three
  source-file hashes unchanged. No active runtime file was edited.

## Full-cycle review handoff

Published manifest:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-crossover-continuity-loop-r1/REVIEW_MANIFEST.json`.
Publisher confirmed `uploaded`, seven files including manifest, default
`delete-after-review`. Implementation commit:
`a69aa5f4094a3e1b6d9d2d12d214552d95ce1dec`. The manifest points at committed code
and the final report records matching implementation hashes. Exact cleanup after
recording the next human decision:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-crossover-continuity-loop-r1/REVIEW_MANIFEST.json --reviewed-by chatgpt-user
```

The compact packet contains a single interactive full-loop viewer, native all-15
Knight/Operator sheet, five accepted→fitted comparisons and machine evidence/notes.
A full cycle is required to judge phase rhythm, support transitions, secondary
motion and seam; scalar checks cannot decide those. No video/GIF, asset resizing
or repeated runtime captures. Review playback FPS never approves authoritative timing.

Exact reviewer questions:
1. Does the full loop preserve accepted NE gait alternation and both crossovers,
   including readable opposite lead around F5?
2. Are support handoffs 6→7 and 13→14 smooth and plausible, without treating hidden
   support soles as defects by themselves?
3. Are fitted F12/F15 changes and 15→1 acceptable? Inspect upper-body/robe motion
   and marked enclosed regions for unintended costume gaps.

After a human decision, record it before cleaning the emitted delete-after-review
manifest. Retain rig and calibration acceptance independently. Do not merge,
publish runtime assets or approve timing under this slice.

## Iteration 001 — pitch fidelity and alpha-gap audit

The latest packet authorized a single objective correction on the retained
`agent/operator-2-5d-ne-walk-retargeting` branch. `continuity.py` now adds the
specified 64.0 wrapped pitch-fit term, with swing weight 1.0 and stance weight
0.25, while leaving the IK envelope, support, crossover, calibration locks and
pitch bounds intact. `run.py` validates an immutable same-source baseline and
writes per-frame pitch/contact/calibration/crossover comparisons; its quality
gate requires at least 10% aggregate improvement and rejects any side/frame
worsening above 5 degrees. The viewer adds the requested 6x nearest-neighbor
ROI and void/pitch diagnostics without altering rendered pixels. Numerical
negative controls cover angular wrapping, swing/stance weights and a masked
per-foot regression.

Candidate evidence was generated from the exact accepted NE donor and rig. The
weighted absolute pitch error fell from 207.892° to 119.727° (42.41%); the
largest per-frame/side worsening was 2.985°. All 15 rendered frames passed,
including contact, geometry and continuity; the lead reversals stayed 2→3 and
7→8, support handoffs stayed 6→7 and 13→14, there were zero branch flips, and
the 15→1 seam step was 7.600px. The 6px calibration envelope, palette and
immutable source hashes passed. This is a technical candidate, not visual or
timing acceptance.

Focused motion-plan and rigid-raster smokes passed. `run_validation.py
--changed --base HEAD --json` passed 2/2 selected checks with full changed-file
coverage; `py_compile` and `git diff --check` passed. The six-file visual
handoff is published at
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-001-pitch-and-gap-audit/REVIEW_MANIFEST.json`
with delete-after-review retention. It records the exact authoring chat:
https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe

## Iteration 002 — reference-sheet integrity

The user confirmed the Iteration 001 pair sheet used Operator pixels in both
columns. Its uploaded `REFERENCE_OPERATOR_15_POSES.png` SHA-256 is
`f9d283a638d6cd9abd37fe3bce296b47705964563bd44c99f18dcfee18e898db`. The error
was in review-packet assembly: the left side was copied from a prior Operator
render. The Iteration 001 report remains unchanged and still matches its published
SHA-256 `3cc70f881d04cae1ab8217aa46481cf40344c30a4a0523270488d26da0acded4`;
its 15/15 geometry/contact evidence and 42.41% pitch improvement remain technical
evidence only.

Iteration 002 added a shared, fail-closed Knight/Operator sheet builder and a
one-shot CLI in `review_viewer.py`. Before generating, it checks accepted donor
and rig receipts, the Iteration 001 report identity, 1920x128 RGBA strips, all
15 donor/candidate frame crops and exact reassembly, and both PNGs embedded in
the existing `LOOP_REVIEW.html`. The CLI wrote only to the new local staging
directory; it did not modify the prior output or rerender Aseprite. `run.py` now
uses the same builder on future successful renders. The registered smoke tests
synthetic gray/gold strips, alpha compositing, all 15 pair positions/order and
per-frame pixel hashes, and rejects swapped inputs, spoofed donor hashes and
same-sprite inputs.

Verified Knight donor strip SHA-256:
`20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba` (RGBA-pixel
SHA-256 `cff7cca675f071c05353b11d74a9580645a295d2f3f62eef84f3ba7dd4f7464a`).
The retained Operator strip SHA-256 is
`ba512279d2e153fd84ca3093d638f63877785ffdda5923d8e4f932b6b01dcb85`. The
unchanged self-contained viewer embeds those exact Knight and Operator bytes.
Corrected paired sheet SHA-256:
`adde4812e067e8f39c38fc2eab34187e0d798db8af809c31f1dd80c743e9bcfd`; its
provenance receipt records each frame's hashes, crop/panel coordinates and
post-composite pixel identity.

The six-file corrected handoff from Iteration 002 was published at
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-002-reference-sheet-integrity/REVIEW_MANIFEST.json`
with the exact authoring chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe. It preserves the Iteration 001 report,
viewer and pitch comparison. The corrected pixels are now available for human
review; no gait, transition, timing or artistic approval is claimed.

## Iteration 003 — visual-byte bridge (transport only)

The exact packet-authorized two-image Dropbox bridge was published at
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-003-visual-byte-bridge/REVIEW_MANIFEST.json`
with delete-after-review retention. The manifest lists exactly four source artifacts:
`REVIEW_PIXELS.json` (`e204311250cd008f8634ca4f59f6fd0121149a75abc4166eb8004a9813f9aef4`),
`REFERENCE_OPERATOR_15_POSES.png`
(`adde4812e067e8f39c38fc2eab34187e0d798db8af809c31f1dd80c743e9bcfd`),
`TRANSITION_ALPHA_DETAIL.png`
(`783dc8ebfa9ee64ab0858bd6f30fb181c27a95311d7c49ed42712fcdb25969e2`), and
`REVIEW_NOTES.md`
(`c5ddd7b89fd4a790cae3d380ea6bf78639fee7c3e331b2d0a7a4d11bc312e12b`). Dropbox text fetch returned the full JSON; both embedded PNGs were locally decoded and SHA/dimension verified. The corrected contact sheet and ROI bridge payload hashes match; source candidate strip and report hashes remain `ba512279d2e153fd84ca3093d638f63877785ffdda5923d8e4f932b6b01dcb85` and `3cc70f881d04cae1ab8217aa46481cf40344c30a4a0523270488d26da0acded4`.

The ROI sheet contains 4x nearest-neighbor crops from F01/F02/F05/F06/F07/F09/F10/F11/F12/F13/F14/F15 at source rectangle x=40..101, y=63..111, with support, void pixel totals and magenta outlines from the unchanged report. No source/runtime/animation files were changed. The publisher ran from the clean coordination checkout, so the Dropbox manifest's `git.commit` is `934805e71ac4e82c4588365f5e7e1dddea912eaa` on `main`; this is transport metadata and does not identify the retained implementation checkpoint `c834aa20faea6bb7d21fec54c1b998f63b9dadc8`. The packet requires this iteration to stop for the human visual verdict.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the Iteration 001 staging script mislabeled a prior Operator render as the Knight. I also launched this workstream's changed-file validation while another worktree's broad sweep was active; this run selected two Python unit checks and passed, but the launch ordering violated the resource guidance.
- Root cause / contributing factors: the handoff script selected a convenient prior render instead of the locked donor bundle; the validation command was chained after a process listing rather than gated on its result.
- Prevention / pipeline improvement: generate future pair sheets only through the shared provenance builder and keep the synthetic identity negative controls; treat any active validation process as a stop condition before launching a changed-file sweep.
- Tooling / docs drift discovered: the review README now documents the erroneous Iteration 001 panel, exact hashes and the verified one-shot repair route.
- Follow-up: manual-follow-up
- What worked: source strips, viewer-embedded PNGs, output frames and published report were all hash-bound; the faulty old review run was preserved and the corrected bundle used a fresh run ID.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe
- Refresh reason: visual acceptance of the NE gait requires review of the authentic Knight-versus-Operator pair; support transitions and enclosed regions remain subjective.
- Next action: inspect the Iteration 003 Dropbox visual-byte bridge, record the frame-specific human verdict, then run the emitted delete-after-review cleanup command.
- Blockers or open questions: final gait acceptance, timing, runtime publication and landing remain unapproved.
