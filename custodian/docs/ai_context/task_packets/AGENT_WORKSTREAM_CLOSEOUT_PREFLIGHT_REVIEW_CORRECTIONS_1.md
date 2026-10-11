# AGENT WORKSTREAM CLOSEOUT PREFLIGHT — REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-workstream-closeout-preflight-review-corrections-1`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-workstream-closeout-preflight-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `Close confirmed R0-01 false-ready result at the shared workstream validation gate`
- Findings addressed: `R0-01`
- Reviewed main: `7e8049e96baa70630f9d66ed5520fbed83f998a3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in correction/review summaries and Next Handoff.
- Goal: Ensure workstream closeout never treats a validation report with incomplete coverage as green.
- Completion boundary: Correct the shared validation-report predicate consumed by both read-only preflight and authoritative finish, with focused regression coverage for incomplete and missing coverage; preserve finish synchronization and landing authority.
- Current measured state: The archived independent review reproduced a schema-valid report with `passed: true`, one passing test, and `coverage.complete: false` returning `ready_before_sync: true` and `validation.green: true`. The same helper `_validation_data_green()` is used by preflight and finish.
- Required correction: Require explicit `coverage.complete: true` in `_validation_data_green()` and add regression fixtures for incomplete, absent/malformed, and complete coverage so preflight and finish fail closed on the same cases.
- Evidence: `REVIEW_AGENT_WORKSTREAM_CLOSEOUT_PREFLIGHT_V1_CLAUDE_SUMMARY.md`; archived review packet `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_CLOSEOUT_PREFLIGHT_V1.md`; `custodian/tools/agent/workstream.py`; `custodian/tools/validation/run_validation.py` coverage result contract.
- Task-specific authority: `workstream.py` remains the authoritative finisher; `run_validation.py` defines complete coverage as part of an overall successful validation report.
- Work surface: `custodian/tools/agent/workstream.py`; focused fixtures in `custodian/tools/agent/test_workstream_artifacts.py` and, if required by the shared finish call path, `custodian/tools/agent/test_workstream.py`.
- Change: Make `_validation_data_green()` return true only for the expected report schema, `passed: true`, a non-empty list of passing test records, and an explicit `coverage` object with `complete: true`. Ensure preflight reports incomplete or absent coverage as non-green and blocking. Add temporary-repository regression coverage for `coverage.complete: false` and absent/malformed coverage; retain the complete-coverage green control.
- Preserve: Read-only behavior of preflight; finish remains responsible for synchronization, after-sync validation and race-safe landing; `post_sync.status` remains `unknown` in preflight; malformed/non-green reports fail closed; no report can assert that landing occurred.
- Non-goals: No changes to synchronization, branch merge policy, artifact classification, test selection, validation-runner coverage calculation, or unrelated lifecycle behavior.
- Acceptance: 1) The review's exact `passed: true` / passing-test / incomplete-coverage fixture no longer yields green or ready. 2) Missing or malformed coverage is non-green. 3) Explicit complete coverage with passing tests remains green. 4) The same shared predicate gates both preflight and finish. 5) Existing negative controls and nonmutating preflight behavior remain passing.
- Validation: Run `python3 -m unittest -q custodian.tools.agent.test_workstream_artifacts custodian.tools.agent.test_workstream`; run the focused `agent_workflow_contract` validation; run `python3 custodian/tools/agent/check_ai_context.py --json`, `python3 custodian/tools/agent/validate_review_pairing.py`, `python3 custodian/tools/agent/task_packet_index.py`, changed-file validation with complete coverage, and `git diff --check`.
- Task overrides: `none`
- Deferred: Broader validation report schema/version changes.

## Handoff

- Next workstream: `review-agent-workstream-closeout-preflight-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After correction lands and archives, run the independent paired correction review in fresh context.`
- Blockers or open questions: `none`
