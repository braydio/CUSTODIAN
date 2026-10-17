# Operator V6 — exact NE donor and crossover calibration checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
Status: **five calibration poses uploaded; human calibration review required**.
This is a retained branch checkpoint, not a completed/merged animation workstream.
No runtime publication or timing decision. Rig recovery remains closed.

## Current human decision and source lock

The user rejects the previous V6 animation and revokes the east-facing donor
concern. The actual NE donor is `~/Knight_NE_Reference.png`, SHA256
`20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`.
It is 1920x128 RGBA, 15 native 128px cells. It differs from the old ZIP strip in
26,103 RGBA pixels. `donor_authority.json` pins exact bytes and raw RGBA pixels;
`CROSSOVER_CORRECTION_BRIEF.md` records the human correction and five-pose boundary.

Immutable source-only bundle/crops:
`~/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1/`.
All 15 file hashes and exact reassembly pass. Original home source and previous
ZIP/bundle are preserved. No generic runtime asset family or ingest was created.

Accepted rig remains `operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`, SHA256
`b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`.
Locked original `SINGLE_FRAME.aseprite` remains SHA256
`0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`
(as pinned in rig_acceptance.json and measured locked_input_hashes.json).
The accepted far pivots (53,75)/(52,83)/(50,88)/(48,91), 52/47/21 segmentation,
four hidden cover pixels and neutral identity are unchanged. No recovered-source
11-pixel differences were incorporated. Final hash checks confirm all three inputs
unchanged. Original checkpoints 230a0b207, 8a254e0f1, 78598929a and 2ff294117 remain
in ancestry; resume merged fetched origin/main at 2d005547d without landing this work.

## What this slice changed

- Replaced all 135 provisional landmarks with exact-sheet traces; recorded stable
  anatomical identity, visible/occluded estimates, editable support hypotheses,
  crossing metadata and no invented numeric confidence. Inferred coordinates need
  not hit opaque pixels. Frame 7's dark brown toe has a source-sampled material
  note; visibility validation does not silently mistake its boot color for shadow.
- New `crossover.py` / `calibration.lua` render exactly five static poses, using
  the pinned V5.5 helper core and shared inverse rigid raster. No full cycle is
  regenerated. Segment-direction transfer removes the former per-ankle neutral
  bias, swing attenuation and cyclic smoothing from this isolated calibration.
- Stable near+ / far− IK retains exact accepted lengths. Explicit inward target
  corrections ≤0.051px respect the existing .05px reach safety margin. Existing
  fit/contact/step/rotation thresholds remain unchanged. Secondary motion is
  neutral to isolate the leg presentation; old secondary implementation is retained.
- The actual pose masks quantify limb/distal overlap, costume coverage, visible
  limb pixels and support-sole occluders. No whole-limb draw-order swaps were added.
- `run.py` rejects superseded donor authority and refuses full-cycle regeneration
  until the calibration gate is explicitly resolved. Negative controls exercise
  these refusals; existing annotations cannot silently feed the old full batch.
- Updated native README and FILE_INDEX; extended the existing motion smoke test
  with source lock, all-15 crossover/branch/length checks and pre-write full-cycle
  gate rejection. No task packet was duplicated; native briefs remain authority.

## Observed results and limits

Ankle x-order reversals: **2→3 and 7→8**. Provisional support transitions:
**6→7 and 13→14** (near 14–6, far 7–13). Lead, support and foreground ownership
are separate concepts. These traces/support labels remain human-unaccepted.

Five sparse comparison poses, **12/2/7/5/15**, cover near lead, approach, crossing,
opposite lead and seam return. They are not a five-frame animation.

| Frame | Donor ankle dx | Operator ankle dx | Visible far pixels | Sole dx / dy px |
|---|---:|---:|---:|---:|
| 12 | 29 | 37.857 | 110 | 0.335 / -0.059 |
| 2 | 3 | 2.360 | 88 | 0.467 / -0.033 |
| 7 | -1 | -1.161 | 72 | 0.231 / 0.767 |
| 5 | -13 | -14.644 | 17 | 0.231 / 0.326 |
| 15 | 11 | 10.493 | 109 | 0.585 / 0.266 |

**5/5 static pose checks pass**: contact, reach, accepted segment lengths, ≤8px
knee fit, palette subset, binary alpha, cell bounds and donor ankle lead sign.
Only frame 2 needs a quarter-pixel support correction (0,-0.25), re-solving IK.
Maximum sole residuals 0.585px x / 0.767px y remain below the original 2 / 1 limits.

The retained near foreground order allows both lead signs. It did not by itself
prevent crossing once targets changed. At frame 7 the near shin covers the far
boot's single lowest sole pixel: transformed-boot contact passes, visible sole
count is zero. This is explicitly a visibility finding, not a claim of exposed
support. Frame 5 has only 17 visible far-limb pixels after near leg/costume
coverage (36 far pixels covered by costume). Human review must decide readability
and whether any local distal correction is anatomically warranted. Do not reverse
whole limbs to manufacture visible contact.

The old ±24° foot-pitch cap remains. Far toe mismatch after clamping is 36–126°
in this set; near maximum 18.4°. These are not exact matched toe orientations.
The far projected toe vector/occluded donor toe inference need review; do not
reinterpret this as the revoked donor-facing diagnosis. Enclosed transparency
remains a diagnostic: 7/11/8/1/3 pixels for frames 12/2/7/5/15 respectively. No hole,
secondary-motion or overall aesthetic acceptance is claimed.

The unsmoothed all-15 numerical proposal still fails existing 8px joint / 60°
rotation transition checks at **2→3, 6→7, 9→10, 10→11, 12→13, 13→14**.
Branch changes and knee-fit failures: zero. The numerical 15→1 transition is within
limits. These failures are deliberately not smoothed away before calibration.
There is **no new 15-frame full-pass count**. Previous 3/15 → 5/15 → 15/15 numeric
progress remains historical evidence from the superseded donor; the last animation
is rejected. Static 5/5 is not full-cycle acceptance.

## Validation evidence

Final local output:
`~/Downloads/operator_ne_master_audit_implementation_v1/crossover_calibration_review_v1/`

- Exact-source and accepted-rig Aseprite execution via `crossover.py`: five static
  poses, 15 source-frame hashes/reassembly, structural rig gate and source hash
  unchanged; `calibration_report.json`, `motion_plan.json`, `run_receipt.json`.
- `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py`: PASS,
  including all-15 length/branch/lead checks, unchanged-threshold negative control,
  and full-cycle CLI refusal before writing any output.
- `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`:
  **11/11 PASS**, no failed/skipped/timed-out/infrastructure checks, complete changed
  coverage. `changed_validation.json` stays local. Memory checked before sweep.
- Old ZIP donor against corrected annotations: rejected `source hash mismatch`.
- `git diff --check`: PASS. `locked_input_hashes.json` confirms three exact inputs.

The first direct-angle diagnostic exposed straight-limb reach margin hits and
lost ordering on unequal projected limbs. Trace reinspection corrected distal
coordinates; stable-branch IK and explicit tiny inward reach corrections resolve
static geometry without relaxing its gates. A temporary added visible-sole check
caught the frame 7 occlusion; visibility is now reported separately because hidden
contact is legitimate and was never an existing contact requirement.

## Review workflow

Prior rejected review
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-cyclic-loop-r1/REVIEW_MANIFEST.json`
was deleted with its default policy after recording the decision.

The five-pose packet contains one native comparison sheet, one 15-cell donor
annotation sheet and one ownership sheet plus exact annotations/metrics/questions.
Five sparse phases are explicitly requested; numbers cannot decide anatomical
identity or crossover readability. No motion capture was produced.

Published review manifest:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/ne-donor-crossover-calibration-v2/REVIEW_MANIFEST.json`.
Publisher receipt: uploaded, nine files including manifest, delete-after-review;
implementation commit `43edaf3d7b11c44f7d937df31f10ce432aa10945`. The initial v1
upload carried pre-implementation HEAD metadata and was deleted as a superseded
upload by Codex, explicitly **not** a visual approval. Local evidence is preserved.
The corrected manifest points at the committed implementation. Its exact cleanup:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/ne-donor-crossover-calibration-v2/REVIEW_MANIFEST.json --reviewed-by chatgpt-user
```

Reviewer questions:
1. Are all 15 limb identities and inferred far-leg coordinates credible through
   2→3 and 7→8? Specify frame/joint corrections if needed.
2. Do five Operator poses preserve readable crossover, especially frame 7's hidden
   far sole and frame 5's robe coverage?
3. Confirm/correct support 6/7 and 13/14. Is calibration ready for continuity fitting
   with the reported boot-pitch limit, or which pose/annotation must change first?

After recording the decision, execute the new manifest's emitted cleanup command.
Rig acceptance persists. Animation, timing and runtime publication remain unapproved.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: previous mechanical success did not establish donor crossover fidelity; supplied authoritative source differs from the prior bundle; first review upload used pre-implementation HEAD metadata.
- Root cause / contributing factors: per-limb neutral target bias and phase filtering obscured crossover; reference anatomy/support stayed provisional; upload preceded the code checkpoint.
- Prevention / pipeline improvement: exact donor authority lock, explicit lead-order regression, sparse calibration gate before another full render, committed implementation before replacement review upload.
- Tooling / docs drift discovered: old README donor/support/mapping descriptions were historical; marked superseded and replaced current run instructions.
- Follow-up: operator-2-5d-ne-walk-retargeting
- What worked: retained rig acceptance and narrow mask/contact evidence isolated the remaining gait/occlusion questions.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: review corrected donor annotations, five crossover poses, support hypothesis and occlusion readability before full-cycle fitting.
- Next action: review the published calibration packet, obtain frame/joint-specific human decision, record it, clean reviewed manifest, then resume bounded continuity/occlusion correction.
- Blockers or open questions: six proposed adjacent transitions still fail; boot-pitch mismatch, frame 7 hidden far sole and frame 5 robe coverage need explicit review. No main merge/runtime/timing authorization.
