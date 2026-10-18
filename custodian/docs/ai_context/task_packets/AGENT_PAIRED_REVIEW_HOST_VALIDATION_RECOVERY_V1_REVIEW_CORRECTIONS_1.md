# PAIRED REVIEW HOST VALIDATION RECOVERY — REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-host-validation-recovery-v1`
- Locks: `paired-review-host-validation, paired-review-same-run-continuation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `the accepted pre-launch plan fails on the exact preserved legacy claim receipt it was created to recover`
- Parent implementation: `agent-paired-review-host-validation-recovery-v1`; archived `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_HOST_VALIDATION_RECOVERY_V1.md`
- Parent review: `review-agent-paired-review-host-validation-recovery-v1`; archived `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_HOST_VALIDATION_RECOVERY_V1.md`
- Findings addressed: `R1-01`
- Affected acceptance: `Parent A3 and A4: exact same-claim plan/apply recovery for a preserved host_validation_recovery run, including authentic legacy claim evidence`
- Reviewed main: `427c1491bfee734ecc4d89ef887654e9fb2a1e4e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `none`
- Summary backlink: `Repeat the exact Authoring chat URL in correction/review summaries and Next Handoff.`
- Goal: `The read-only recovery planner can verify and plan the exact preserved W1 claim whose historical dispatcher output is truncated, without changing any original evidence.`
- Completion boundary: `Unify strict structured-claim verification and narrowly bounded legacy-header verification across host recovery planning and apply; add adversarial regression coverage for the exact old run shape.`
- Current measured state: `The preserved W1 run is still host_validation_recovery at 20261017T200919Z-e0b32b5c1a3b. It has no claim-receipt.json; claim.stdout contains a complete CLAIMED identity header but its trailing structured sentinel is truncated. metadata.json omits branch/worktree/packet, while recovery_worktree records the exact worktree. The new read-only plan fails with “dispatcher did not return exactly one structured claim receipt” because _host_recovery_plan_unlocked calls parse_claim_receipt directly. The continuation path has a legacy helper but it requires the absent metadata fields.`
- Evidence: `The original private run directory under .git/custodian-review-runs/review-worktree-backlog-census-and-safety-ledger-v1-review-corrections-1/20261017T200919Z-e0b32b5c1a3b; its unchanged metadata.json, claim.stdout, RECOVERY.md, validation.json and coordinator-validation.json; current paired_review_runner.py::_host_recovery_plan_unlocked and _legacy_claim_receipt; the reproduced read-only plan failure.`
- Task-specific authority: `The archived parent implementation and accepted review; paired_review_runner.py owns same-claim recovery; dispatch.py owns current claim/ref eligibility; the original W1 run's claim, metadata and reports are immutable evidence.`
- Work surface: `custodian/tools/agent/paired_review_runner.py and custodian/tools/agent/test_paired_review_runner.py; bounded lifecycle wording only if needed.`
- Required correction: `Use one shared exact claim resolver in both plan and apply. Prefer a valid structured claim receipt. For a historical truncated/missing sentinel only, derive expected branch from agent/<exact workstream>, expected packet from the exact current review packet, and expected worktree from recovery_worktree; require the complete unique human header to match those identities exactly. Then verify the existing worktree is attached to this repository, has the expected branch, is clean and pinned to reviewed_main, and the remote claim ref still equals reviewed_main. Do not create a claim-receipt.json, edit any original run file, fall back on conflicting or parseable-but-invalid JSON, or weaken any current structured-claim checks.`
- Preserve: `All original W1 run bytes and refs; the prior failed validation; source-span and archive identity checks; explicit plan-hash authorization; exclusive continuation child; fresh reviewer; no second claim, reset, cleanup, or claim release before accepted review.`
- Non-goals: `No edits to the W1 worktree or evidence; no W2/W5 release; no generalized claim migration or unrelated post_exit_recovery changes.`
- Acceptance: `1) The exact W1 legacy run produces a read-only plan that pins its original claim, branch, packet, worktree, reviewed main and evidence digests while leaving all source evidence byte-identical. 2) Plan and apply use the same verifier and an apply requires the exact fresh plan digest. 3) Conflicting headers, wrong/missing identity, dirty or moved worktree, moved remote claim, malformed structured receipts, and a forged legacy sentinel fail closed. 4) Existing structured receipt behavior and all previously accepted recovery tests remain green. 5) No duplicate dispatcher claim is created.`
- Validation: `Add focused temporary-repository cases for exact legacy plan/apply, structured receipt precedence, truncated sentinel with matching and conflicting headers, absent metadata fields, moved remote ref, dirty/moved worktree, and plan/apply digest mismatch. Run python3 custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/agent/test_dispatch.py; python3 custodian/tools/agent/test_workstream.py; python3 custodian/tools/agent/test_review_outcome.py; python3 custodian/tools/agent/test_task_packet_contract.py; python3 custodian/tools/validation/run_validation.py --changed --json; require complete coverage and git diff --check.`
- Task overrides: `none`
- Deferred: `Any new post_exit_recovery semantics or claim-record migration.`

## Delta Rules

- Address only `R1-01`; preserve the parent implementation and accepted review receipts.
- This correction must not modify or synthesize any file in the protected W1 run directory.
- If the exact legacy claim cannot be bound to the canonical workstream, packet, existing recovery_worktree, local branch and remote branch, leave the W1 claim protected and report the precise evidence gap.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none | ...`
- Root cause / contributing factors: `none | ...`
- Prevention / pipeline improvement: `none | ...`
- Tooling / docs drift discovered: `none | ...`
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`

## Next Handoff

- Next workstream: `review-agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Refresh reason: `none`
- Next action: `Run the fresh independent correction review after the implementation lands and archives.`
- Blockers or open questions: `The exact legacy claim must continue to validate against the preserved original run; no W1 continuation may launch if identity verification fails.`
