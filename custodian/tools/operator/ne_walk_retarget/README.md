# NE walk retarget experiment V6

Preview-only adaptation of the user's local V5.5 Aseprite rig solver. The external
handoff is preserved in `BRIEF.md`; it remains the acceptance contract. No asset
family, canonical source, Workbench approval, timing decision, or runtime is changed.

## Run

Requires Python + Pillow, Aseprite with Lua support, the exact V5.5 script pinned
in `v55_dependency.json`, and a saved finalized 128px RGBA rig master. The original
V5.5 script stays intact; the generated batch removes its obsolete embedded Knight
pixels/landmarks and UI, then reuses its pivot, source-part, IK and raster functions.
No V5.5 one-frame retarget function is called.

```bash
python3 custodian/tools/operator/ne_walk_retarget/run.py \
  --bundle ~/Downloads/custodian_operator_ne_knight_15f_reference_v1 \
  --rig ~/Temp/RigPivotBuildingTemp.aseprite \
  --output ~/Downloads/custodian_operator_ne_knight_15f_reference_v1/preview_v6_new
```

Output must be a new directory outside the active Godot project. Each run records
its full invocation, rig/dependency/annotation hashes, source-frame verification,
Aseprite log, per-frame failures, contacts, knee-fit errors, clamps, swing reduction,
branch flips, adjacent angular/joint steps and 15→1 pixel/joint discontinuity.
Exit 0 means the implemented geometry checks passed; exit 2 means a diagnostic
preview was generated with failed frames. Neither exit means art or timing approval.
Aseprite sometimes returns exit 0 on Lua errors, so the driver also requires its
completed report. An exception stops before a successful receipt.

`operator_ne_walk_v6_PREVIEW_ONLY.aseprite` has 15 clean preview cels, hidden QA,
reference and marker tracks, plus hidden locked copies of the original source rig
layers/pivots. Its mandatory editor durations are placeholders (100ms), not timing
authority. No GIF or runtime clock is generated. The clean PNG is 1920×128 RGBA;
individual cells are exactly 128×128. No resizing occurs.

## Annotation and contact model

`annotations.json` contains nine independently traced landmarks per frame, unique
IDs, image hashes, editable coordinates, visible/occluded estimates and provenance.
They are provisional agent traces, with **no human approval or numeric confidence**.
Metal/boot sampling catches shadow/empty markers conservatively; brightness alone
is not an anatomy detector or proof of correct limb ownership.

Near/far identities persist across crossings. The supplied near 1–2 → far 3–8 →
near 9–15 schedule is carried as a hypothesis. Contact interval timing and world-space
support/swing clearance cannot be established from the shadow or one projection.
Do not call a low contact residual proof of accepted gait.

The batch uses one cohort reference scale, preserves each canonical segment length,
and maps each limb's phase displacement about its own mean onto its source ankle.
Pelvis bob follows donor pelvis displacement about its cohort mean, with explicit
7px/6px bounds and the existing bounded support-reach correction. Foot targets move
through treadmill phases; no fixed-support-coordinate template is repeated. The
rig's source neutral depth planes are preserved. Root (64,106), center x=64, and
semantic ground y=107 stay fixed; neither alpha bottom nor every sole is forced
to y=107. Failed reach/contact fits remain failures.

Swing displacement blends toward neutral using the explicit 0.5 experiment control;
reductions are reported. The raster correction tries at most ±3px and re-solves IK
for every candidate. Upper-body counter-motion and robe response are independent,
disabled controls until authored. The output palette must be a subset of exact rig
part colors. Hole detection has no authored coverage mask and is explicitly unproven.

Edit JSON for reproducible marker overrides and rerun to a fresh directory. The
hidden marker cels are an editable inspection copy; edits to those cels do not
silently replace JSON input authority. No automatic publication exists.

## Review boundary

A candidate needs all 15 individual geometry checks, reference annotation/support
confirmation, authored coverage/hole review, coherent upper-body/robe motion,
visual 15→1 loop acceptance, explicit timing and the existing specialized Operator
source/Workbench gates. The diagnostic experiment does not grant any of these.
Use the compact `contact_sheet.png`, clean strip, Aseprite tracks and `report.json`
for the smallest next correction. Verify the intended rig master first if its pivot
geometry is surprising; do not edit source pivots just to get green metrics.

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
publication is not part of this tool. The candidate remains visually unaccepted.

## Accepted rig and cyclic V6 continuation

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
