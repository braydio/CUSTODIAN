# Operator V6 — accepted crossover, full-cycle continuity checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
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

Prepared manifest target:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-crossover-continuity-loop-r1/REVIEW_MANIFEST.json`.
Publish after committing implementation so the manifest points at the code that
produced it; record upload receipt in the same durable summary afterward.

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

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: literal static-pose locking cannot satisfy the existing step budget; static renderer branch choices differed; first full rendered fit left F14 contact outside tolerance.
- Root cause / contributing factors: accepted visual poses were sparse references, not a feasible exact temporal path; near-straight IK ambiguity; numeric planning did not reserve sufficient raster-phase correction room; initial optimizer scaling was poor.
- Prevention / pipeline improvement: endpoint feasibility checks, immutable target hashes with explicit fitted deviations, stable planned-knee rendering, tighter internal guards and final rendered contact/crossover validation.
- Tooling / docs drift discovered: five-pose hold and old viewer labels were updated to accepted calibration/full continuity state; tested numerical dependencies recorded.
- Follow-up: operator-2-5d-ne-walk-retargeting
- What worked: no reannotation or recovery; existing mechanical limits rejected the failed candidate and the final rendered result established all 15 checks.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: complete 15-frame visual-loop review after accepted calibration and bounded continuity fit.
- Next action: publish committed full-cycle review, obtain human frame/part-specific decision, record it and clean reviewed manifest; retain branch/checkpoint.
- Blockers or open questions: full animation aesthetics/crossover rhythm, fitted F12/F15, working support transitions and gaps/secondary motion remain human-owned; merge/runtime/timing explicitly unauthorized.
