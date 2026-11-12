# Operator 2.5D Workbench Polish Automation Review Corrections 1 (R0-01)

## Result

Closed the proposal-integrity gap at `Operator2DPolish.apply()`. Before creating any edit scope, apply now checks the exact target editable layer and frame, re-inspects the physical Workbench contract, renders the current frame set, reloads current masks and landmarks, and recomputes the allowed proposal.

Detached erase proposals must match a current 1–4 pixel detached component exactly: frame, bounds, area, and every pixel coordinate are checked with strict integer shapes. The operation is constructed from the fresh candidate, never from untrusted proposal coordinates. Protected, disappeared, changed, malformed, oversized, out-of-frame, or fabricated islands fail before `apply_operation()`.

Manual Center X and planted registration proposals also require the complete frame-offset set, integer values, bounds, and mode-specific authority fields to match a fresh derivation. Planted registration is recomputed from current approved support evidence and remains unavailable for locomotion or missing/contrary evidence. The resulting move uses only the freshly derived bounds and dx/dy. Valid operations continue through the ordinary scoped Art Agent journal and undo path.

## Evidence

- `operator_2_5d_polish_smoke` passes the forged two-coordinate/one-pixel probe, protected mask, stale/disappeared island, oversized area, out-of-bounds pixel and malformed frame cases. Rejected cases do not reach the mutation service.
- A fresh exact three-pixel detached island applies once as `erase_pixels` under the frame/layer scope and is undoable.
- A fresh planted proposal applies only its current derived `move_region`; forged offsets and missing support fail before mutation. A forged Center X offset is rejected.
- All packet-named checks pass: `operator_2_5d_polish`, `operator_2_5d_ingress`, `operator_art_agent_service`, `operator_art_agent_aseprite`, `operator_art_registration_profile`, `operator_animation_workbench`, and `operator_workbench_ui`.
- Python compile checks and `git diff --check` pass. The UI smoke reports its optional interactive Textual pilot skipped because Textual is not installed.
- No canonical source, runtime, or publisher files changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first focused smoke run exposed one missing helper import in the expanded adversarial fixture; fixed before the packet validation run.
- Root cause / contributing factors: Proposal forgery had not previously been tested at the apply boundary.
- Prevention / pipeline improvement: Keep malformed/stale/forged proposal cases next to the valid apply/undo path in the focused smoke.
- Tooling / docs drift discovered: The optional Textual UI interaction pilot is skipped without the package installed; service/UI validation is available.
- Follow-up: none
- What worked: Recomputing operation data from current render and semantics kept the fix narrow and preserved Art Agent as the sole mutation/journal authority.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-polish-automation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the cycle-1 paired review in a fresh reviewer context.
- Blockers or open questions: none.
