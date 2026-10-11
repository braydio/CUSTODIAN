# CORRECTION: OPERATOR BASELINE VALIDATION REHABILITATION REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-baseline-validation-rehabilitation-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-baseline-validation-rehabilitation`
- Locks: `operator-validation`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, workflow`
- Paired review workstream: `review-operator-baseline-validation-rehabilitation-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `e03a82582204269c12e998e986a33e269f661429`
- Parent implementation: `operator-baseline-validation-rehabilitation`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_BASELINE_VALIDATION_REHABILITATION.md`
- Parent review: `review-operator-baseline-validation-rehabilitation`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_BASELINE_VALIDATION_REHABILITATION.md`
- Findings addressed: `R0-01`
- Affected acceptance: archived parent implementation Acceptance 1 and 4
- Current defect/evidence: the parry counter smoke checks that a melee state is active after success recovery, but does not count starts or establish a successful no-buffer negative control.
- Goal: Make the parry counter regression fail on duplicate starts and on an attack starting without buffered input.
- Completion boundary: update only the focused ranged-ready smoke to assert exactly one counter start at the authoritative post-parry neutral callback and zero starts for a successful parry with no buffered attack.
- Current measured state: `operator_ranged_ready_input` passes, but its current assertion cannot distinguish one start from multiple starts and has no no-buffer counter control.
- Evidence: `OPERATOR_BASELINE_VALIDATION_REHABILITATION_REVIEW_CLAUDE_SUMMARY.md`, finding `R0-01`.
- Task-specific authority: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`; original archived implementation packet and review receipt.
- Work surface: `custodian/tools/validation/operator_ranged_ready_input_smoke.gd` only, unless a narrow validation-owned observation hook is required and approved by the task's repository authority.
- Required correction: add an observable start count tied to the existing attack-start path; prove one start for buffered parry input and no start for a successful parry without buffered input. Preserve fixed-tick/post-parry callback ownership and all existing parry, no-buffer, and authored timing assertions.
- Preserve: post-parry action arbitration behavior, counter timing, combat values, and the original three regression histories.
- Non-goals: production gameplay changes, combat tuning, unrelated ranged-ready tests, stealth-perception, NPA, and Vaultwing work.
- Acceptance:
  1. A successful parry with buffered primary starts exactly one attack at the post-parry neutral boundary.
  2. A successful parry without buffered primary starts zero attacks.
  3. The smoke fails if either assertion is intentionally violated; existing focused test remains green.
- Validation: run `python3 custodian/tools/validation/run_validation.py --test operator_ranged_ready_input --json`, `git diff --check`, and the required changed-file coverage/report after synchronization.
- Task overrides: `none`
- Deferred: none

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: not-started
- Friction severity: none
- What went wrong: n/a
- Root cause / contributing factors: n/a
- Prevention / pipeline improvement: n/a
- Tooling / docs drift discovered: n/a
- Follow-up: none
