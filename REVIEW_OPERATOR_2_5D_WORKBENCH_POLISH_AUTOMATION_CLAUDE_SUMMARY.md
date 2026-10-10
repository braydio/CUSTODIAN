# WB25-3 Independent Paired Review

## Review Findings

- **R0-01 — `blocking_defect`, domain `implementation`, disposition `correction`.** Affected acceptance: parent acceptance 5 (exact tiny detached-island candidate and semantic protection), 7 (approved registration apply through confined mutation), and 11 (apply translates the approved proposal through an ordinary scoped Art Agent transaction). In `custodian/tools/operator/operator_2_5d_polish.py::Operator2DPolish.apply`, the method trusts the caller's proposal dictionary. It verifies only the advertised `status`, `mutates`, frame, and editable layer, then forwards supplied pixels to `erase_pixels` or supplied bounds/deltas to `move_region`. It does not compare those values with a freshly generated proposal or current render/landmarks/masks. An independent negative probe passed a proposal claiming area 1 and bounds `[0,0,1,1]`, with arbitrary pixels `[[0,0],[15,15]]`; `apply()` returned `APPLIED` and sent both coordinates to the mutation service under a body/frame-1 scope. This bypasses the 1..4-pixel cap, detached-component rule, exact-bounds relation and semantic-protection checks. Require fresh proposal validation/authentication before mutation. The correction pair is cycle 1 and was targeted-preflighted.

## Review Result

- Outcome: `findings`
- Reviewed main: `c447db62d5c6f434394d6c634e1e191952658cc5`
- Reviewed implementation commit: `c928fddb7`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow, visual`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Human-decision finding IDs: `none`

## Evidence

- `python3 custodian/tools/validation/run_validation.py --test operator_2_5d_polish --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_2_5d_ingress --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_art_agent_service --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_art_agent_aseprite --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_art_registration_profile --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_animation_workbench --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_workbench_ui --json` — PASS; optional interactive Textual pilot skipped because Textual is not installed.
- `python3 custodian/tools/agent/validate_task_packet_authoring.py custodian/docs/ai_context/task_packets/OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_REVIEW_CORRECTIONS_1.md custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_REVIEW_CORRECTIONS_1.md` — PASS.
- The live UI 2.5D guard blocks both `Publish` and `Validation` for `operator_2_5d_128` selections. The POLISH panel exposes no publish action.
- `git diff --check` — PASS.
- The target's scoped implementation diff against reviewed main is the landed `c928fddb7` change. No post-land edits to the reviewed operator implementation were found in current `origin/main`.
- No canonical source/runtime/publisher files were changed by this review.

## Review Conclusion

The independent-workbench attach, profile compatibility, temporal metrics and primary proposal gates have focused green checks and consistent live code paths. The apply boundary remains unsafe because proposal dictionaries are trusted as authority. The correction packet requires current geometry/protection recomputation and forged/stale/malformed proposal rejection while preserving valid exact apply, journal and undo behavior. No subjective art-direction decision remains; visual review is not needed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: The focused smoke covers valid proposals and some negative eligibility cases but does not attempt a forged apply payload.
- Root cause / contributing factors: Apply's test fake proves frame/layer scope and undo delegation but not proposal integrity at the mutation boundary.
- Prevention / pipeline improvement: Add adversarial proposal forgery fixtures to the focused smoke, including arbitrary erase pixels and planted/manual offsets.
- Tooling / docs drift discovered: Optional Textual UI pilot is skipped when Textual is absent; the service/UI smoke remains runnable.
- Follow-up: operator-2-5d-workbench-polish-automation-review-corrections-1
- What worked: The review's direct service-boundary negative probe exposed a mutation-authority gap not detected by the producer-level smoke.

## Next Handoff

- Next workstream: operator-2-5d-workbench-polish-automation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction after this review receipt lands and archives, then run its fresh paired review.
- Blockers or open questions: none
