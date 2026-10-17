# Operator NE walk V6 — continuity after accepted crossover calibration

Workstream: `operator-2-5d-ne-walk-retargeting`

## Current slice and authority

The human accepted the five-pose calibration at checkpoint `65369509d`, including
F07's legitimate hidden sole, F05's readability caution and working support handoffs
6/7 and 13/14. `crossover_acceptance.json` pins the exact annotations, mapping code,
reviewed pose geometry/pixels, donor and rig. It authorizes continuity fitting and
full-cycle **preview**, not animation acceptance, runtime publication or timing.
The calibration review manifest has been cleaned after recording this decision.

```bash
python3 custodian/tools/operator/ne_walk_retarget/run.py \
  --bundle ~/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1 \
  --rig ~/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite \
  --output ~/Downloads/operator_ne_master_audit_implementation_v1/continuity_preview_new
```

Requires the prior Python/Pillow + Aseprite dependencies and the tested NumPy/SciPy
versions in `requirements-continuity.txt`. Nothing installs dependencies silently.
The CLI verifies human acceptance before writing output or starting Aseprite.
Accepted `annotations.json` and `crossover.py` are unchanged and hash-checked.

`continuity.py` fits joint angles around that same segment-direction mapping using
SLSQP. It retains exact rig lengths, pelvis/hip geometry, one knee branch per leg,
all-frame lead ordering, and at least 75% of target ankle separation. The five
reviewed poses stay immutable as reference targets, with a 6px maximum fitted
joint deviation; actual deviations are recorded separately. They cannot all stay
exact in a continuous cycle: F12→F15 near-toe displacement is 33.56px across three
steps, while the unchanged 8px step limit permits at most 24px. No accepted input
pose, source art, annotation or mapping is rewritten to fit this constraint.

The fitter uses tighter internal 7.6px / 58° guards to leave room for bounded raster
contact correction. Acceptance remains 8px fit / 8px joint step / 60° rotation,
2px x / 1px y rendered sole contact. The old ±24° pitch cap remains and its known
far-toe mismatch is not an exact-pose claim. Objective conditioning does not
change any geometric acceptance threshold. Five reviewed targets receive greater
fit weight; a small cyclic acceleration cost distributes correction without the
old phase filter, neutral ankle bias or swing attenuation.

The ordinary batch uses the fitted knee as IK preference, preventing the varying
near-straight branch choices in the five static renders from leaking into the
cycle. Existing independent 2° upper-body and robe phase controls are retained.
`occlusion.lua` only measures overlap, visible limb pixels and support-sole
occluders; it never changes draw order. No local repainting or forced exposure of
F07's sole is performed. F05 remains a focused human readability question.

Outputs include all 15 clean cells, a 1920×128 strip, editable Aseprite preview,
QA, per-frame contacts and seam checks, calibrated-pose deviations and an HTML
loop viewer. Playback requires an explicit review-rate selection; mandatory
Aseprite editor durations are placeholders and timing remains unknown. Full-cycle
visual acceptance is a separate human gate. No merge or runtime publication.

## Accepted calibration implementation (retained reference)

Workstream: `operator-2-5d-ne-walk-retargeting`

`CROSSOVER_CORRECTION_BRIEF.md` is the current bounded slice. `BRIEF.md` and
`MASTER_AUDIT_BRIEF.md` remain underlying contracts. The prior full-cycle animation
was rejected; the rig and subsequent crossover calibration are accepted. `donor_authority.json` pins the actual
`~/Knight_NE_Reference.png` NE strip. Do not investigate the revoked direction concern.
No merge, source/runtime publication, or timing decision is authorized.

## Current run: five poses only

```bash
python3 custodian/tools/operator/ne_walk_retarget/crossover.py \
  --bundle ~/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1 \
  --rig ~/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite \
  --output ~/Downloads/operator_ne_master_audit_implementation_v1/crossover_calibration_new
```

Requires Python/Pillow, Aseprite and the exact installed V5.5 dependency pinned in
`v55_dependency.json`. Output must be fresh and outside the active project. Source
bundle contains the exact supplied strip, 15 exact native crops and MANIFEST.json;
all are hash-checked and reassembled pixel-exactly. The original home file and old
ZIP/bundle remain untouched. Source reference is not a runtime asset family.

`annotations.json` contains 15 newly traced nine-landmark records against this
sheet, stable anatomical identities, visibility/inference notes and provisional
support. An opaque brown boot tip has an explicit sampled-material review; dark
or transparent pixels alone never authenticate anatomy. Inferred occluded pivots
are allowed to fall off opaque pixels. The human acceptance receipt now accepts
this crossover foundation; the frozen trace provenance/status text is historical.
Support handoffs remain provisionally accepted for dynamic full-cycle review.

Screen ankle order reverses at 2→3 and 7→8. Provisional support changes at 6→7 and
13→14; support and foreground depth are separate from screen lead. Calibration
frames 12/2/7/5/15 cover near lead, approach, crossing, opposite lead and seam return.
They are a sparse set, **not a five-frame playback sequence**.

The calibration normalizes donor segment directions to the accepted projected
lengths. It exposes explicit reach/lead corrections, then solves stable near+ /
far− IK under the existing limits. It does not apply the previous per-ankle neutral
bias, 0.5 swing attenuation or cyclic filter. Secondary motion stays neutral for
this isolated leg review. Boot pitch retains the existing ±24° cap, with its donor
mismatch reported; no exact toe-pitch match is claimed.

`calibration.lua` renders only five poses with the shared inverse rigid raster and
sole-aware contact checks. Quarter-pixel support correction stays within ±3px and
re-solves IK. Reports check unchanged segment lengths, fit ≤8px, source palette,
binary alpha, cell bounds and ankle lead sign. All 15 proposed numerical poses are
also audited against 8px adjacent-joint / 60° rotation limits, including the seam;
failures stay failures. Static calibration passes do not grant cyclic acceptance.

## Occlusion and review boundary

The exact donor's near contour remains foreground at traced overlaps; a screen
lead reversal does not imply a depth swap. Keep the anatomical part order for now,
and quantify actual overlap, costume coverage, visible leg pixels and support-sole
occluders. Frame 7's far sole is hidden by the near shin; its boot contact is still
measured. Do not reorder an entire limb just to expose a legitimately hidden sole.
The human must judge whether this presentation preserves readable crossover.

Outputs include five clean native 128px PNGs, a compact comparison, five ownership
masks, 15 annotated donor cells, complete annotations/plan/metrics and a run receipt.
No animation, GIF, editor timing or runtime output is generated. The full-cycle entrypoint now requires the recorded human acceptance and pinned
calibration inputs; the continuity fitter above handles the newly authorized slice.

Mechanical fixture tests are in `operator_ne_motion_plan_smoke.py`; real Aseprite
and the accepted rig remain necessary to establish rendered pose/contact evidence.
The original 15/15 mechanical result belongs to a rejected animation using the
superseded donor. It is not evidence for the corrected cycle.

## Historical tooling retained

The following records the recovery and previous cyclic implementation. Accepted
rig geometry is current; previous donor annotations/support and animation are not.

## Master audit and recovery checkpoint

`MASTER_AUDIT_BRIEF.md` is the supplied audit instruction. Reproduce its comparison
and create a disposable segmentation-restored candidate with:

```bash
python3 custodian/tools/operator/ne_walk_retarget/master_audit.py \
  --original ~/Downloads/SINGLE_FRAME.aseprite \
  --recovered ~/Downloads/custodian_operator_ne_rig_recovery_audit_v1/operator_ne_rig_RECOVERED_FROM_V6_UNVERIFIED.aseprite \
  --output ~/Downloads/operator_ne_master_audit_new
```

The tool exports with real Aseprite, verifies exact visible ownership and neutral
pixel identity, records all 18 parsed pivots, checks both boots and shin art, and
compares the two locked sources. The recovered foot's original owners are counted
by pixel coordinate. A round-tripped candidate preserves every original `__RIG_`
layer byte-for-byte, strips old working references, and adds a hidden QA guide.
This restores pre-regression segmentation as an **incomplete candidate**. It does
not invent missing boot pixels or approve the older source. Input files are hashed
before/after. No source parts are mixed across versions.

`run.py` now performs this structural rig preflight before launching V6. Empty shin
art, missing/invalid boots, anomalously short shin geometry needing review, or a
toe outside the boot envelope block the solver. The 0.4 shin/thigh review trigger
is a conservative diagnostic, not a universal anatomical law or replacement for
human inspection. The V6 `batch.lua` and all its tolerances are unchanged.

The portable `operator_ne_rig_master_audit_smoke.py` checks lossless partitions,
duplicate ownership, recoloring, empty-shin misclassification, missing boot,
short-chain and toe-envelope rejection. It supplies validation ownership for this
experiment; it does not replace a real Aseprite run or a human anatomy decision.

## Human-selected anatomy recovery

`RECOVERY_DECISION.md` records the user's selected immutable original and authoring
route. `recover.py` accepts only that exact SHA256 and writes to a new local directory:

```bash
python3 custodian/tools/operator/ne_walk_retarget/recover.py \
  --original ~/Downloads/SINGLE_FRAME.aseprite \
  --output ~/Downloads/operator_ne_anatomy_recovery_new
```

`recover_far_leg.lua` traces provisional far-leg ownership from the selected rendered
anatomy: visible proximal leg y78–83, distal leg y84–88, cuff/sole y89–91. Proposed
far pivots are hip (53,75), knee (52,83), ankle (50,88), toe (48,91). The hip remains
an occluded inference; marker opacity is not an acceptance rule. The shortened far
projected chain (8.062px thigh + 5.385px shin) needs human visual review against the
near chain (14.142 + 11.045px); numeric gate success does not approve proportions.

Reclassification moves 39 distal thigh pixels to shin and 21 original distal shin
pixels to the boot. It retains independent 52px thigh / 47px shin / 21px boot art.
Two hidden shin and two hidden boot joint-cover pixels copy exact selected-source
colors and are fully covered by the original visible owners in neutral. No newer
V6 source pixel, rescaling, mirroring or near-boot copy is involved.

The driver verifies the selected locked source and neutral composite pixel-exactly,
all unrelated rig layers unchanged, the 18-pivot parse, palette subset, visible
ownership, positive segment lengths, and six IK/raster contact probes at -15/0/+15
degrees for both sides. It reopens the saved candidate through real Aseprite before
reporting technical success. Run V6 separately against that candidate only after
these checks pass. The solver and its tolerances remain unchanged; source/timing
publication is not part of this tool. The candidate was subsequently human-accepted; see `rig_acceptance.json`. Recovery remains closed.

## Historical cyclic V6 implementation — animation rejected

`rig_acceptance.json` records the user's hash-bound rig acceptance. V6 checks that
exact file before planning; source/geometry recovery is closed. Animation and timing
are separate pending decisions.

`motion_plan.py` searches a cyclic path inside the original ±7px x / ±6px y pelvis
box, retaining exact accepted segment lengths. The old per-frame projection could
throw away reachable bounded solutions. The new planner chooses one knee branch
per limb over the whole cycle and includes frame 15→1 in path selection.

A declared cyclic `[1,4,6,4,1]/16` filter operates on canonical reference ankle
positions and boot pitches before IK. It removes the discontinuities introduced by
frame-local support/swing mapping. Its deviation from raw reference targets is
reported independently of IK/contact residual, including warnings above 3px.
The current maximum is 6.423px; gait fidelity requires human animation review.
This filtering does not change rig geometry or source art.

The planner rejects changes to the existing 8px knee-fit, 8px joint-step and 60°
rotation limits. Every rendered result is checked again after raster correction.
Quarter-pixel support-ankle corrections remain inside the existing ±3px budget;
each re-solves IK and checks branch/neighbor compatibility. They are not boot slides.
Inverse nearest-neighbor rigid sampling avoids forward-splat interior holes and
preserves source colors/binary alpha. Enclosed transparent regions are still
reported because separate moving parts can expose gaps; do not auto-approve them
as intentional or paint over them.

Upper-body counter-motion is a separate 2° phase sinusoid; robe far/near/center
motion uses separate phase curves (1.6° far/near amplitude, 0.8° center). Robe motion
no longer follows thigh rotation. These additions do not imply authored timing.

`LOOP_REVIEW.html` embeds the clean Operator strip and Knight reference, supports
manual forward/reverse stepping across 15→1, and requires an explicit rate selection
before playback. Its review rate creates no timing decision. The optional transparent-
region overlay and per-frame deviation/contact readings support the human loop
review. The PNG and Aseprite clean tracks remain free of guides/donor pixels.

Portable motion tests and a real-Aseprite filled-shape raster test are registered
in the repository validation manifest. Actual per-frame JSON remains the evidence
for real rig contact/continuity; fixture tests do not approve animation aesthetics.
