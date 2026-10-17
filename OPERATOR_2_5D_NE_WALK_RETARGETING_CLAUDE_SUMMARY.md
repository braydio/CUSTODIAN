# Operator NE walk — reboot pause checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
Status: **paused at the user's explicit request for a reboot**. Preserve the branch
and worktree. No main merge, runtime publication, or timing approval.

## Accepted baseline — do not reopen rig recovery

The user accepted checkpoint `8a254e0f1`'s recovered rig as the authoring/retargeting
baseline. Acceptance is recorded in `RECOVERY_DECISION.md` and `rig_acceptance.json`.

Rig:
`~/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`
SHA256: `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`.

Selected immutable source remains original SINGLE_FRAME, 2191 opaque pixels,
SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`.
Accepted far chain: hip (53,75), knee (52,83), ankle (50,88), toe (48,91);
accepted shorter NE projection, 52/47/21 visible ownership and four hidden joint
cover pixels. Rig recovery is closed. Source art and rig geometry must remain fixed.
Animation, runtime publication and timing are still unapproved.

The accepted anatomy review manifest was cleaned through the publisher's emitted
`--reviewed-manifest .../anatomy-recovery-20261016/REVIEW_MANIFEST.json --reviewed-by
chatgpt-user` command after recording the decision. Result: status deleted,
latest_pointer_removed true, retention policy delete-after-review. No cloud cleanup
remains for that accepted review. A future animation review needs a new manifest.

## Last rendered baseline — unchanged this turn

`~/Downloads/operator_ne_master_audit_implementation_v1/v6_recovered_run01/`
contains the last actual rendered preview and report: **5/15 full passes**, compared
with 3/15 before recovery; **13/15 contacts**, compared with 14/15 before recovery.
Frames 5 and 13 fail reach/contact; other defects include knee branch changes and
excessive adjacent joint/rotation jumps. That animation remains rejected.

The earlier audit/recovery code, selected-source evidence and human-reviewed master
remain preserved at `8a254e0f1` and in the Downloads evidence tree. The older
`230a0b207` checkpoint is also retained in branch ancestry.

## New root-cause evidence

1. The current renderer projects the pelvis toward the support ankle, then discards
   the entire correction if any component exceeds the ±7px x / ±6px y bounds.
   A quarter-pixel search finds valid bilateral reachable positions *inside* the
   unchanged bounds for both failures: frame 5 has 45 feasible sampled positions
   (one near 57.75,72); frame 13 has 48 (one near 61,72). Discarding the correction
   is therefore a solver-selection defect, not proof that accepted rig geometry
   must change.
2. Knee branches are independently chosen per frame, allowing flips.
3. The raw support/swing mapping introduces target discontinuities: near ankle
   frame 2→3 is 15.81px. Smoothing ankle position alone still leaves a toe step
   8.77px because boot pitch remains unsmoothed. The 8px joint limit was retained.

## In-progress implementation — NOT wired into rendering

Added `custodian/tools/operator/ne_walk_retarget/motion_plan.py`, a pure numerical
prototype. It preserves accepted segment lengths and pelvis bounds, computes
reference-target deviations, applies a declared cyclic [1,4,6,4,1]/16 filter to
both ankle position and boot pitch, and searches a cyclic path with one fixed
knee branch per limb. Candidate/transition selection enforces existing 8px knee-fit,
8px adjacent joint, and 60° rotation limits, including frame 15→1.

One numerical run found a feasible cycle, using near branch +1 / far branch -1,
in about 12.7 seconds. This is **not rendered contact proof, a 15/15 rendered pass,
or human animation acceptance**. Filter deviation from raw donor targets must be
quantified and exposed to the reviewer; do not hide stride changes or soften QA.
The prototype currently samples quarter-pixel root positions, retains up to 96
candidates per frame and checks up to 12 initial states. Failure means no solution
was found by that bounded search, not a general impossibility proof.

Saved numerical result (reboot-safe):
`~/Downloads/operator_ne_master_audit_implementation_v1/motion_solver_pause_checkpoint/numerical_motion_plan.json`.
Do not depend on the earlier `/tmp/ne_motion_plan_initial.json` after reboot.

## Exact restart work

Resume this existing workstream through workstream.py; do not create a duplicate
claim or reopen rig recovery. Verify the accepted rig SHA before rendering.

1. Add meaningful portable numerical regression coverage for bounded pelvis
   projection, fixed knee branches, unsmoothed-pitch toe jumps, cyclic seam and
   rejection of unreachable targets/changed limits. The current prototype has
   numerical real-input evidence and compilation only, not dedicated unit coverage.
2. Wire the planned pelvis/ankle/knee branch/pitch into batch.lua through run.py.
   Preserve source/rig identity and retain exact acceptance thresholds. Per-frame
   raw-vs-planned target deviation must be reported separately from IK residual.
3. Rasterize and verify actual boot contacts, keeping the existing ±3px IK re-solved
   raster correction budget. Temporal constraints must still hold after raster
   corrections; do not slide boot pixels independently.
4. Re-run all 15 frames against the accepted baseline. Report full/count/contact
   changes honestly. Numerical plan success does not guarantee pixel success.
5. Add controlled upper-body counter-motion and robe secondary motion as separate
   additions, then perform the complete 15-frame visual-loop review. Unknown timing
   stays unknown. Use compact evidence and a fresh human animation decision.

The user's priority order remains: frames 5/13 contact and reach; knee/support
continuity; adjacent jumps; upper-body/robe; complete loop review. Do not relax
thresholds merely to raise pass counts. Keep runtime isolated and source pixels fixed.

## Validation at pause

- Accepted rig SHA matches the user's exact approved hash.
- Previous rendering results remain 5/15; no new Aseprite batch has run this turn.
- New pure numerical plan: feasible path found on real accepted-rig/reference data.
- New module Python compilation and git diff --check pass.
- No broad suite or animation success is claimed for the unintegrated prototype.
- Prior checkpoint's focused and real-Aseprite recovery validation remains durable
  in its summary/history and Downloads reports; it is not substituted for future
  motion validation.
- Moment Forge: not run — isolated authoring tooling, no runtime changes.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: greedy support projection discarded feasible bounded solutions; independent pitch/branch choices caused temporal discontinuities.
- Root cause / contributing factors: frame-local solver and validation after pose selection rather than cyclic constrained selection.
- Prevention / pipeline improvement: explicit cyclic numerical plan and fixed-rig constraints, then independent raster proof; preserve intermediate evidence for reboot resume.
- Tooling / docs drift discovered: numerical prototype is not yet integrated or dedicated-test covered; do not infer rendered success from its result.
- Follow-up: manual-follow-up
- What worked: accepted rig identity checked, completed review evidence cleaned, deterministic root-cause reproduction and a reboot-safe numerical checkpoint.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: wait for user resume after reboot, then continue the exact restart work above on the retained branch.
- Blockers or open questions: user-requested pause; rendered motion/contact proof and later human animation acceptance remain outstanding. Rig baseline acceptance is complete.
