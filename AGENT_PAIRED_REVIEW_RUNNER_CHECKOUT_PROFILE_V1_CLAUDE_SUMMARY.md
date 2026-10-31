# Paired-review runner checkout-profile integration

Workstream: `agent-paired-review-runner-checkout-profile-v1`

Claim run: `20261031T141754Z-06d667c64286`

Status: implementation and changed-file validation complete; canonical finish and fresh paired review pending.

## Implementation

- Added opt-in `--checkout-profile` support to the canonical paired-review runner. Existing invocations retain full-checkout behavior.
- Before a profiled claim, the runner verifies the exact published packets, their publication inputs, the target implementation commit and its full diff, recursive local Python imports, and the validation manifest's declared script and scenario paths.
- Profile coverage is checked before dispatch. The selected profile and digest are passed to the dispatcher, verified against its claim receipt, and recorded in run metadata.
- Expanded the tracked bootstrap profile to include the runner's review, validation, workflow-smoke, and manifest dependencies, including the required `.agents/skills/custodian-next/SKILL.md` and this closing summary.
- Added regression coverage for safe manifest dependency parsing, script/scenario path resolution, profile coverage, and refusal before claim when a dependency is omitted.

## Validation

- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`: passed; 2/2 selected checks passed, coverage complete, zero uncovered files. The profile JSON is the one declared selector exclusion.
- `paired_review_runner_unit`: 266 tests passed.
- `agent_workflow_contract`: passed, including its nested workflow checks.
- Targeted manifest closure and fail-before-claim tests: 3 passed.
- `py_compile` for the changed Python files and `git diff --check`: passed.
- The genuinely sparse worktree materialized the full required checkout profile. The validation manifest yielded 342 declared dependency paths with zero profile omissions. The local sparse worktree measured 27,234,304 allocated bytes across 2,324 files before adding this summary and the final skill materialization; the review profile includes both required paths.
- No protected Awakening, G2, or Procession claim, lock, worktree, or reviewer process was changed or launched.

## Next handoff

After canonical implementation landing, check dispatcher eligibility and launch the existing fresh independent review through `paired_review_runner.py` using the published checkout profile. A launch is not acceptance. Only after that review passes should the outstanding lightweight-LFS provisioning review be retried; the preserved Awakening recovery remains downstream of its accepted PASS.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933
