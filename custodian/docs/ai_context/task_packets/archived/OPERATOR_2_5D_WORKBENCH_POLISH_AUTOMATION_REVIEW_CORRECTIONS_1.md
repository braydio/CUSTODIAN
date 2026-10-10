# CORRECTION: OPERATOR 2.5D WORKBENCH POLISH AUTOMATION REVIEW

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-polish-automation-review-corrections-1
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-polish-automation
- Locks: operator-art-agent, operator-aseprite-tooling, operator-workbench-ui
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-polish-automation-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: c447db62d5c6f434394d6c634e1e191952658cc5
- Parent implementation: operator-2-5d-workbench-polish-automation; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION.md
- Parent review: review-operator-2-5d-workbench-polish-automation; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION.md
- Findings addressed: R0-01
- Affected acceptance: Parent acceptance 5, 7, and 11: detached-component removal is exact and protected; registration apply uses the authorized confined mutation path; each apply translates an approved proposal to existing bounded operations.
- Current defect/evidence: `Operator2DPolish.apply()` trusts caller-supplied proposal status, area, pixels, bounds and offsets. A forged proposal claiming area 1 and a one-pixel bound but carrying two arbitrary pixels was accepted and forwarded to `erase_pixels` under only a body-layer/frame scope.
- Goal: Ensure every applied polish proposal is freshly validated against the exact current Workbench render, semantic protections, proposal rules, and operation bounds before mutation.
- Completion boundary: Close R0-01 through narrow proposal validation and regression coverage. Do not redesign POLISH or alter unrelated Art Agent operations.
- Current measured state: Forged detached-component proposal produced APPLIED and forwarded coordinates `[(0,0),(15,15)]`; required 1..4 pixel, detached, protected-mask-aware exact candidate checks were bypassed.
- Evidence: Archived parent review receipt R0-01 and `REVIEW_OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_CLAUDE_SUMMARY.md`.
- Task-specific authority: Archived WB25-3 packet mutation-safety clauses 9 and 11; Art Agent's exact layer/frame scope, stale/hash checks, journal and undo contract.
- Work surface: `custodian/tools/operator/operator_2_5d_polish.py`, focused `operator_2_5d_polish` validation, and only direct consumers if required.
- Required correction: Reject malformed, stale, forged, clipped, out-of-frame, protected, oversized or non-exact erase proposals; recompute or otherwise authenticate exact candidate pixels/bounds from current clean renders and current masks/landmarks immediately before apply. Validate registration offsets/bounds against a fresh proposal derived from current support evidence and ensure only the resulting rectangle/delta reaches `move_region`. Preserve scoped journaling and undo.
- Preserve: Exact Workbench identity/physical contract; intentional pixels; existing Art Agent scope/journal/undo ownership; publication-free boundary; proposal non-mutation.
- Non-goals: New mutation primitives, broader UI redesign, canonical/runtime publication, automatic repaint or anatomy changes.
- Acceptance: (1) The forged two-coordinate/one-pixel proposal is rejected before any mutation call. (2) A current exact three-pixel detached island proposal still applies once, journals, and undoes. (3) protected, oversized, stale, malformed and out-of-bounds proposals fail closed. (4) forged planted/manual offsets or bounds cannot move pixels beyond a freshly derived approved proposal. (5) all packet-named focused validation and `git diff --check` pass; canonical/runtime bytes remain untouched.
- Validation: `operator_2_5d_polish`, `operator_2_5d_ingress`, `operator_art_agent_service`, `operator_art_agent_aseprite`, `operator_art_registration_profile`, `operator_animation_workbench`, `operator_workbench_ui`, compile checks, and `git diff --check`.
- Task overrides: none
- Deferred: none

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first focused smoke run exposed a missing import in the new adversarial fixture; it was corrected before the full packet checks.
- Root cause / contributing factors: The correction smoke grew from producer-level checks to exercise the apply boundary and needed one additional proposal helper import.
- Prevention / pipeline improvement: Keep adversarial validation at the mutation boundary and rerun the focused smoke after fixture edits.
- Tooling / docs drift discovered: The optional Textual interaction pilot is skipped because Textual is not installed; the service/UI smoke passes.
- Follow-up: none

## Completion Truth

- Completion schema: custodian.task_completion.v1
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: The focused smoke rejects forged/stale/protected/oversized/out-of-bounds erase and forged registration proposals before mutation, accepts a fresh exact 3-pixel candidate through scoped apply/undo delegation, and all packet-named checks pass.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-polish-automation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the cycle-1 paired review in a fresh reviewer context and independently attack proposal fabrication and stale application.
- Blockers or open questions: none
