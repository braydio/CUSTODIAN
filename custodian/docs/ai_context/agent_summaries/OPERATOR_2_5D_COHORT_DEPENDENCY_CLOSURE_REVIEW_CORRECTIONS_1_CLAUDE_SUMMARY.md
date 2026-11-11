# Operator 2.5D cohort dependency closure correction 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Result

Closed R0-01 in the bounded read-only report/probe correction. The four locomotion transition rows now cite live `operator._update_animation` and, where applicable, `operator._sync_modular_locomotion_layers` definitions. The two posture-transition rows cite the actor posture updater and `UnarmedPosturePresentation.advance`. Six other preemption/settle edges explicitly carry `UNKNOWN` evidence with a concrete reason instead of presenting descriptive consumer text as a resolved symbol.

The report producer resolves each source reference against the current checkout before emitting it. An unresolved reference becomes `UNKNOWN` and cannot be classified `CLOSED`. The focused smoke checks every emitted edge evidence object, rejects the former nonexistent `_sync_animation_from_state` reference and an empty unknown reason, verifies deterministic output, and preserves the `NOT_RELEASE_ELIGIBLE` result. Markdown now shows the same edge-specific evidence as the JSON report.

No runtime, art, source intake, animation timing, policy, or release files changed. The report still describes the seven-family / 56-direction candidate with zero effective verified directions and all twelve transition/preemption edges not closed.

## Validation

- `operator_2_5d_cohort_dependency_closure_smoke.py` — PASS.
- `operator_animation_targets_smoke.py` — PASS.
- `operator_workbench_production_queue_smoke.py` — PASS.
- `run_validation.py --changed --base origin/main --json` — PASS; 1 selected test, complete changed-file coverage, no failures.
- Report regeneration — `NOT_RELEASE_ELIGIBLE`, 7 families / 56 slots; deterministic equality verified by the focused smoke.
- `git diff --check` — PASS.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: none
- Root cause / contributing factors: none
- Prevention / pipeline improvement: source-reference resolution and negative controls are now part of the report smoke.
- Tooling / docs drift discovered: report edge evidence previously repeated consumer labels without checking source definitions.
- Follow-up: review-operator-2-5d-cohort-dependency-closure-review-corrections-1
- What worked: narrow producer-side validation kept the correction read-only and deterministic.

## Next Handoff
- Next workstream: review-operator-2-5d-cohort-dependency-closure-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Land this correction and run its fresh paired review; then return corrected closure evidence to the authoring chat. WB25-6 remains gated.
- Blockers or open questions: Six preemption/settle evidence edges remain explicitly unknown; no production cohort, timing, or release decision is authorized by this correction.
