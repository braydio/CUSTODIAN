# Operator NE V6 — cyclic motion implementation and animation-review handoff

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
Status: **resumed; 15/15 existing numeric frame checks pass; human animation review
pending**. This is not blanket pixel/art acceptance. The branch/worktree remains
active; no main merge, runtime publication, or timing approval.

## Accepted authority preserved

The exact user-accepted authoring/retargeting rig remains
`~/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`,
SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`.
`rig_acceptance.json` and `RECOVERY_DECISION.md` record the human decision. The CLI
now checks that hash before planning. Do not reopen rig recovery.

Selected original SINGLE_FRAME remains 2191 opaque pixels, SHA256
`0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`.
Both input files were checked unchanged after execution. No accepted source pixels,
rig pivots, segment lengths, 52/47/21 far ownership, or four hidden cover pixels
were changed. Recovered V6's 11 source differences remain excluded.

The prior rig review's delete-after-review cleanup completed before reboot. The
new animation review is separate. User resume revoked the explicit reboot pause;
implementation continued on the retained branch from checkpoint `78598929a`.
Original checkpoints `230a0b207` and `8a254e0f1` remain in branch ancestry.

## What changed and why

- `motion_plan.py`: bounded cyclic pose selection replaces the greedy support-only
  projection that discarded reachable in-bounds solutions. It retains the accepted
  ±7px x / ±6px y pelvis envelope and exact segment lengths, chooses one branch per
  limb across the complete cycle, and checks 15→1 during path selection.
- Raw support/swing targets had a 15.81px near-ankle jump at 2→3. A declared cyclic
  `[1,4,6,4,1]/16` filter operates on both canonical ankle positions and boot pitch
  before IK. Smoothing position alone still left an 8.77px toe jump. This motion
  edit is reported separately from IK/contact error, not hidden as exact donor fit.
- `batch.lua` uses the selected pelvis/targets/branch/pitch. Quarter-pixel ankle
  corrections remain within the existing ±3px budget, always re-solving IK and
  checking branch/adjacent compatibility. Final checks run on the rendered result.
  Integer shifts alone could not change a pitched boot's lowest sole-row ownership.
- `rigid_raster.lua`: inverse nearest-neighbor rigid sampling replaces forward
  rounded splats, avoiding interior holes in transformed filled parts. No source
  colors are invented, no source pixels are edited, and binary alpha is retained.
- Upper-body counter-motion is a separate 2° phase sinusoid. Robe far/near use
  separate 1.6° phase curves and center 0.8°; robes no longer inherit thigh rotation.
  These are pose-phase controls, not an authored animation clock.
- `run.py`: verifies accepted rig identity, validates fixed limits and numeric plan,
  audits rendered segment lengths/root bounds/contact/continuity, exposes raw target
  and pitch deviations, and reports enclosed transparent components with coordinates.
- `review_viewer.py`: self-contained `LOOP_REVIEW.html`, clean Operator/reference
  comparison, manual forward/reverse stepping across the seam, explicit review-rate
  selection before Play, and optional enclosed-transparency overlay. It records no
  approval or authoritative timing.
- Added portable motion and real-Aseprite filled-shape raster regressions, registered
  validation owners, and updated README/FILE_INDEX. No game runtime file changed.

## Measured outcome

| Measure | Original prototype | Accepted-rig baseline | Current cyclic + secondary |
|---|---|---|---|
| Existing full frame checks | 3/15 | 5/15 | **15/15** |
| Rendered support-contact checks | 14/15 | 13/15 | **15/15** |
| Frame 5 / 13 reach/contact | failures | failures | **pass / pass** |
| Knee branch changes | present | present | **0** |
| Max adjacent joint step | failing frames | failing frames | **5.997px**, limit 8 |
| Max adjacent segment rotation | failing frames | failing frames | **27.807°**, limit 60 |
| Max sole error x / y | failed contacts | failed contacts | **0.993 / 0.927px**, limits 2 / 1 |
| 15→1 max joint step | 4.556px | 2.737px | **2.885px** |

Final quarter-pixel corrections: frame 4 (-0.25,0), frames 12 and 13 (0,-0.25).
No independent foot-image sliding. Near/far numeric branch signs are
1 / -1 throughout. Branch consistency is
not a human-approved anatomical/gait decision.

| Frame | Sole dx / dy px | Knee fit near / far px | Raw-target deviation near / far px | Enclosed transparency px |
|---|---|---|---|---|
| 1 | -0.235 / 0.210 | 0.207 / 3.801 | 0.719 / 0.969 | 20 |
| 2 | -0.993 / 0.533 | 6.532 / 6.763 | 6.423 / 4.486 | 3 |
| 3 | 0.533 / 0.549 | 4.562 / 1.328 | 4.371 / 1.882 | 5 |
| 4 | 0.172 / 0.197 | 1.388 / 0.743 | 1.794 / 0.568 | 12 |
| 5 | -0.463 / 0.474 | 0.863 / 0.631 | 1.273 / 1.454 | 17 |
| 6 | -0.108 / 0.280 | 1.078 / 0.197 | 0.285 / 4.539 | 8 |
| 7 | 0.575 / -0.392 | 4.306 / 0.330 | 0.358 / 0.698 | 8 |
| 8 | 0.557 / -0.927 | 2.901 / 1.312 | 2.081 / 6.272 | 22 |
| 9 | -0.081 / 0.129 | 2.746 / 3.002 | 3.136 / 1.679 | 1 |
| 10 | 0.452 / -0.072 | 3.111 / 4.115 | 1.901 / 0.825 | 2 |
| 11 | -0.467 / -0.241 | 4.045 / 6.734 | 1.584 / 0.294 | 13 |
| 12 | -0.354 / -0.241 | 4.557 / 6.671 | 1.977 / 0.599 | 8 |
| 13 | 0.260 / -0.322 | 5.896 / 4.516 | 2.096 / 2.227 | 20 |
| 14 | -0.677 / -0.161 | 5.029 / 4.109 | 1.252 / 1.055 | 5 |
| 15 | 0.291 / 0.001 | 2.911 / 4.722 | 0.665 / 0.332 | 21 |

All cells are 128×128 RGBA, the clean strip 1920×128 (15×1), source palette subset
and binary alpha pass, no cell-edge clipping occurs. Root (64,106), center x=64 and
semantic ground 107 remain fixed. Different source neutral foot depth planes are
preserved rather than forcing every sole to the same screen row. All 15 donor file
hashes and exact source-frame reassembly still pass.

## Remaining visual questions — do not overstate numeric success

Maximum raw-reference target deviation is **6.423px**, pitch deviation **10.547°**.
This is motion smoothing with a fidelity cost. The reviewer must decide whether the
result retains the intended NE walk, near/far identities and support transitions.
Reference landmarks/support schedule remain provisional estimates until reviewed.

The neutral source has no enclosed transparent components. The final animation has
**up to 22 enclosed transparent pixels per frame**, across components whose bounding
boxes are recorded. Inverse nearest sampling removes forward-splat interior holes,
but moving separate semantic parts can still expose limb gaps or costume seams.
The viewer marks these regions. Their intended/defective status is not self-approved;
there is no blanket pixel-hole PASS and no automatic filling of unpainted anatomy.

The existing 8px knee-fit, 8px adjacent-joint and 60° rotation limits are unchanged
and protected by a rejection test. No acceptance threshold was relaxed to reach
15/15. Timing remains unknown/null. Aseprite editor frame durations remain preview
placeholders; the viewer preselects no FPS and creates no timing decision.

## Exact durable local evidence

Final output: `/home/braydenchaffee/Downloads/operator_ne_master_audit_implementation_v1/v6_cyclic_secondary_run01`

- `operator_ne_walk_v6_PREVIEW_ONLY.aseprite`: separate clean, QA, donor, marker and
  source-context tracks. No canonical Workbench or runtime intake.
- `operator_ne_walk_v6_15f.png`, `frame_01.png` … `frame_15.png`: clean output.
- `report.json`: all frame/transition/pixel metrics and implementation SHA256s.
- `motion_plan.json`: chosen cyclic path, raw targets, branch signs, objective score.
- `rig_preflight/audit.json`, `input_validation.json`, `run_receipt.json`, Aseprite
  log, generated Lua and source palette: reproducibility/provenance.
- `LOOP_REVIEW.html`: standalone interactive human loop review.
- `REFERENCE_OPERATOR_CONTACT_SHEET.png`: one paired 15-pose contact sheet.
- `REVIEW_NOTES.md`, `visual_review_handoff.txt`: reviewer contract and publisher receipt.
- `changed_validation.json`: 37/37 repository checks passed, complete changed-file
  coverage at the validation run.

Source hashes in `report.json` bind the final numerical/raster/report/viewer code.
The report and viewer were enriched after rendering; final analysis re-read the
same PNG/JSON evidence and still reports 15/15. No pixel render was substituted.

## Reproduction and validation

```bash
python3 custodian/tools/operator/ne_walk_retarget/run.py \
  --bundle ~/Downloads/custodian_operator_ne_knight_15f_reference_v1 \
  --rig ~/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite \
  --output <fresh-directory-outside-active-project>
python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py
python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py
python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json
git diff --check
```

- Real Aseprite render: **15/15** numeric frame checks, **15/15** rendered contact.
- Motion smoke: exact lengths/branches, unreachable targets, toe-pitch discontinuity,
  cyclic seam, root-bound and geometry mutation, widened-limit refusal all PASS.
- Real-Aseprite raster fixture: neutral identity, filled interior at ±15°/±37°,
  palette and binary alpha PASS. It explicitly skips when Aseprite is unavailable;
  Aseprite was available and executed here.
- Broad changed-file validation: **37/37 PASS**, coverage complete. Run once after
  checking free memory/no competing headless sweep. Final report/viewer enrichment
  was then checked by Python compilation, real evidence re-analysis and `node --check`
  of the generated JS; no browser playback or human art acceptance is claimed.
- Python compilation and whitespace checks PASS. Moment Forge: not run — isolated
  authoring tooling, no runtime change. Generated import UID files were deliberately
  classified/removed; no source/inbox material was treated as disposable.

An initial cyclic render hit JSON serialization nulls when returning decoded JSON
point objects to Aseprite's encoder. Explicit plain-point copies corrected that;
final evidence contains all joints and analysis fails closed on missing points.
The first raster attempt still missed pitched-boot contact in frame 13; subpixel
IK correction within the original budget corrected raster phase. These are recorded
as implementation friction, not omitted successes-only history.

## Required human animation review

Authoring chat: not-recorded
Dropbox manifest:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-cyclic-loop-r1/REVIEW_MANIFEST.json`

Exact questions:

1. Does the full 15-frame loop, including 15→1 and near/far support transitions,
   retain the intended NE walk gait relative to the Knight reference despite maximum
   6.423px / 10.547deg filtering deviations?
2. Are the upper-body counter-motion and separate robe motion coherent with the
   accepted Operator body and costume?
3. Are the marked enclosed transparent regions (up to 22 pixels in a frame)
   intentional/acceptable gaps, or seams requiring correction? If correction is
   needed, identify frames and regions using the viewer overlay/report coordinates.

One paired contact sheet plus the self-contained viewer covers all 15 authored
poses, because two keyframes cannot establish gait/secondary-motion continuity or
the loop seam. No repeated game full-frame captures or motion video were needed.
The bundle has five artifacts plus its manifest and defaults to delete-after-review.
After recording the user's animation decision, resume this same workstream and run:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --reviewed-manifest /CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-cyclic-loop-r1/REVIEW_MANIFEST.json \
  --reviewed-by chatgpt-user
```

The publisher records pre-checkpoint HEAD `78598929a`; artifact SHA256s and the
implementation hashes in report.json bind this new review evidence. The new code
is checkpointed on the same branch with this summary, without main landing.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: numerical continuity did not initially imply raster contact; Aseprite JSON point objects serialized as null; separate moving parts still expose visually ambiguous enclosed transparency.
- Root cause / contributing factors: greedy frame-local selection, raster phase of pitched soles, forward splat holes and SDK serialization boundaries.
- Prevention / pipeline improvement: cyclic bounded selection, exact limits/length regression tests, independent raster probes, plain report points, topology metrics and explicit human fidelity/seam review.
- Tooling / docs drift discovered: older disabled-secondary and single-frame descriptions are superseded by the cyclic continuation section; no runtime authority changed.
- Follow-up: fixed-in-scope
- What worked: accepted rig stayed immutable; source and acceptance thresholds stayed fixed; actual 15-frame raster/continuity evidence and reviewer-controlled loop inspection.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: complete animation fidelity/secondary-motion/enclosed-gap visual decision is required; rig acceptance remains complete.
- Next action: review LOOP_REVIEW.html or the exact Dropbox manifest; record animation acceptance/corrections and clean reviewed cloud evidence; then continue this same branch.
- Blockers or open questions: target-filter fidelity, support/gait appearance, secondary motion and possible costume seams; animation/timing/runtime publication remain unapproved. Do not merge until the audit's accepted-cycle gate is satisfied.
