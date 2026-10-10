# Paired Review Runner Successor Handoff Gate Fix

- Packet schema: `custodian.task_packet.v2`
- Workstream: `paired-review-runner-successor-gate-fix`
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: `operator-2-5d-workbench-review-automation`
- Locks: `paired-review-runner`
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: `review-paired-review-runner-successor-gate-fix`
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: `A false human gate blocks the exact fresh-context paired review lifecycle; current and successor packet authority must not be conflated.`
- Reviewed main: `73eaf5fcf61c962497da02b2f383fadd2865af7f`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: Allow an eligible paired review to launch when human-refresh fields describe only its future successor, while continuing to block genuine current-review human gates.
- Completion boundary: Correct current-review gate detection in `paired_review_runner.py` and add focused regression tests. Preserve dispatcher eligibility, target validation, visual gates, and no-claim-before-preflight behavior.
- Current measured state: Runner scans the full review packet for refresh fields, so the archived WB25-4 review is falsely blocked by its successor WB25-5 refresh under `## Handoff`.
- Evidence: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md`; reproduced preclaim false-gate output.
- Task-specific authority: Current review eligibility is defined by its own authority; future successor handoff fields apply only after review completion. Dispatcher remains the sole claim authority.
- Work surface: `custodian/tools/agent/paired_review_runner.py` and `custodian/tools/agent/test_paired_review_runner.py`.
- Change: Scope current-review human-refresh checks to the current packet authority and exclude successor `## Handoff` / `## Next Handoff`; add positive and negative regression fixtures.
- Preserve: Current review refresh/human/visual gates; dispatcher and Codex preflight order; target validation; durable recovery behavior.
- Non-goals: No dispatch schema, WB25-4 implementation, WB25-5 planning, or human decision policy changes.
- Acceptance: Actual WB25-4 review packet passes eligibility; a genuine current review refresh gate, human owner, and required visual decision still fail before claim; regression tests pass.
- Validation: Run `python3 -m unittest test_paired_review_runner.py` from `custodian/tools/agent/`, changed-file validation, py_compile, and `git diff --check`; then launch the exact WB25-4 review through the runner.
- Deferred: Unrelated paired-review runner changes.

## Agent Handoff / Planning Decisions — 2026-10-10

- The WB25-4 review packet is ready/auto and its target implementation has landed and archived complete at `73eaf5fcf61c962497da02b2f383fadd2865af7f`.
- Running `python3 custodian/tools/agent/paired_review_runner.py review-operator-2-5d-workbench-review-automation` failed before claim with `review packet requires a human planning/decision gate`.
- The exact refresh fields occur under that review packet's `## Handoff`, which describes WB25-5 after the review closes. The packet explicitly says this successor refresh is not a gate on the current review.
- The user authorized a separate bounded runner correction in the WB25-4 handoff. No new product/design decision is required. Keep the fix out of WB25-4's implementation diff.

## Current Measured State

The runner in `custodian/tools/agent/paired_review_runner.py` applies regex checks for `ChatGPT/user planning refresh required: yes` and human-owned `Refresh owner` over the entire review packet. `REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md` has both values in its future `## Handoff`; the runner refuses it before claim. Existing `test_paired_review_runner.py` verifies a current packet header gate but has no successor-handoff false-gate regression.

## Evidence

- `custodian/tools/agent/paired_review_runner.py`, `validate_eligible_review()`
- `custodian/tools/agent/test_paired_review_runner.py`, `test_human_gate_and_non_review_are_refused()`
- `custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md`, current-review/successor clarification and `## Handoff`
- Reproduction: `python3 custodian/tools/agent/paired_review_runner.py review-operator-2-5d-workbench-review-automation` prints `BLOCKED: review packet requires a human planning/decision gate` before claim.

## Task-specific authority

- Current paired-review packet fields govern current-review eligibility.
- Its successor `## Handoff` describes authority after successful current review and does not gate that review.
- `dispatch.py` remains the sole claim and eligibility authority; runner Codex preflight must continue to happen before dispatch claim.
- Repository lifecycle requires fresh-context review and the normal workstream finish path.

## Work surface

- Primary: `custodian/tools/agent/paired_review_runner.py`
- Regression tests: `custodian/tools/agent/test_paired_review_runner.py`
- No unrelated runtime or packet lifecycle changes.

## Change

1. Scope refresh/human-gate checks to the current review packet authority and exclude its top-level successor `## Handoff` / `## Next Handoff` block.
2. Continue rejecting current-review planning-refresh/human-decision requirements, `Refresh owner: chatgpt-user|human`, and `Visual review: required` before any dispatcher claim.
3. Add a fixture whose successor handoff says refresh is required and owner is `chatgpt-user`; it must pass preclaim packet validation when the current review has no gate.
4. Keep/add a fixture where the current review's own authority requires refresh; it must still be refused before claim.

## Preserve

- Dispatcher claim is authoritative and occurs only after packet and Codex preflight.
- Existing packet target/archive/dependency checks, visual gate, Codex flags, locking, and durable recovery artifacts.
- Current review gate refusals and no claim on failed preflight.

## Non-goals

- No review/implementation code changes for WB25-4.
- No changes to task packet schema or dispatch eligibility.
- No alteration of WB25-5 refresh requirements or any human-owned decision.

## Acceptance

1. The actual archived WB25-4 review packet passes `validate_eligible_review()` despite its successor refresh fields in `## Handoff`.
2. A synthetic current-review refresh gate still raises before dispatcher claim.
3. A synthetic current-review human owner and `Visual review: required` remain blocked.
4. Focused runner tests pass; changed-file validation covers the runner/test changes; `git diff --check` passes.

## Validation

- From `custodian/tools/agent/`: `python3 -m unittest test_paired_review_runner.py`.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`.
- `python3 -m py_compile custodian/tools/agent/paired_review_runner.py custodian/tools/agent/test_paired_review_runner.py`.
- `git diff --check`.
- Run the runner against `review-operator-2-5d-workbench-review-automation` after fix and verify its exact workstream claim receipt before fresh-context launch.

## Task overrides

- none

## Deferred

- Other paired-review runner parsing or lifecycle behavior not required by acceptance.

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh status: `consumed; the WB25-4 handoff directly authorized this bounded correction`
- Refresh instruction: `Do not change product design or human approval policy; scope only current-review gate detection.`

## Handoff

- Next workstream: `review-paired-review-runner-successor-gate-fix`
- Next packet state: `ready/auto behind implementation`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `none`
- Next action: `After this implementation lands and archives complete, start its paired fresh-context review.`
- Blockers or open questions: `none`
