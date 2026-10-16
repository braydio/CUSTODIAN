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
