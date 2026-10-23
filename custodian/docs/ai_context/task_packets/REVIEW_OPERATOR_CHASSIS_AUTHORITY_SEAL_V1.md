# REVIEW OPERATOR CHASSIS AUTHORITY SEAL V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-chassis-authority-seal-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `operator-chassis-authority-seal-v1`
- Locks: `operator-runtime, validation-infrastructure`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Falsify any bogus zero-debt result and any bypass of a permanent Actor authority boundary.`
- Review target workstream: `operator-chassis-authority-seal-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently determine whether the landed seal genuinely blocks `operator.gd` rebloat without becoming a paperwork-only metric or breaking legitimate Operator orchestration.
- Reviewed implementation acceptance: All seven numbered acceptance items in the exact archived `OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md`.
- Review evidence: Landed implementation SHA + source-to-budget audit; actual mutated GDScript positive/negative controls; removed controller and enlarged existing-method adversarial fixtures; workstream finish blocked/green receipts; manifest selection; focused agent-validation tests.
- Correction threshold: New Operator-owned gameplay state, rebaseline/exception bypass, ineffective existing-method checks, aliased enemy motor calls missed, disabled pre-landing check, accidental weakening of general finish validation, silently stale budget, or incorrectly claimed server-side protection are material R0 blockers.
- Focused validation: Independently rerun the newly landed authority-guard tests and adversarial mutation fixtures; existing `custodian/tools/validation/operator_architecture_debt_audit.py --final`, `custodian/tools/validation/operator_runtime_path_audit.py --final`, `custodian/tools/validation/operator_runtime_animation_authority_smoke.py --final`, focused validation-manifest and workstream-finish regression, then changed-file validation and `git diff --check`.
- Review focus: Compare live original baseline/owners against the landed budget; actively mutate a copy to add a clock/stateful method, enlarge an existing method, raise budgets, hide foreign motor behind alias, delete a controller and move its state into the actor, and bypass changed-file selection. Confirm every red check prevents landing, not merely logs a warning.
- Acceptance: Fresh independent findings-first review with stable R0-NN IDs. No blocking false negatives, false final-zero, operational or workflow bypass; full proof of monotonic ratchet and bounded migration exceptions. Accept only with precise durable receipt or author scoped correction/re-review pair. Review must not edit implementation.
- Non-goals: No implementation edits, no unrelated Operator extraction, no alteration of app server/branch settings, no art work.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation is archived complete at origin/main, in a fresh independent context.
2. Reconstruct ownership and test fixtures from actual landed code, not from implementer narrative or green count alone.
3. Falsify all numbered acceptance criteria, including clean/dirty target worktree and policy edits; keep unrelated worktrees untouched.
4. Record findings-first receipt; corrections follow normal bounded reviewed cycle and preserve original authoring chat value.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `draft/manual only during automatic authoring handoff; do not claim this review until implementation completes`
- Next action: `Independently review exactly the landed seal and unblock the queued F2/F3/F5/F6 packet dependencies only after PASS.`
- Blockers or open questions: `implementation dependency only`
