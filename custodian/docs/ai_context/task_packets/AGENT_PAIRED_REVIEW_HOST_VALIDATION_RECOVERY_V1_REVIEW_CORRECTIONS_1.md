# PAIRED REVIEW HOST VALIDATION RECOVERY — REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Kind: `correction`
- Status: `in_progress`
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
- Current measured state: `The preserved W1 run is host_validation_recovery at 20261017T200919Z-e0b32b5c1a3b. Its claim.stdout has no claim-receipt.json or structured sentinel; the complete CLAIMED identity header is intact and the output is cut off during NEXT instructions. The corrected planner verifies that header, but then fails its required pinned-worktree gate: local branch HEAD e621d0329f49447f41d61e95b4df9220690625bb is three commits ahead of reviewed_main b5b85ca47a1eacad9879c6abf55257d378ae0c91. origin/agent/review-worktree-backlog-census-and-safety-ledger-v1-review-corrections-1 remains at b5b85ca4. The worktree is clean; all three unique commits change only OPERATOR_2_5D_NE_WALK_RETARGETING.md. The runner correctly refuses to review from the moved local branch.`
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
- Outcome: `blocked`
- Friction severity: `high`
- What went wrong: `The exact W1 plan advanced beyond the legacy claim-header failure but stopped because the preserved local claim branch has three unique commits beyond its pinned baseline.`
- Root cause / contributing factors: `The W1 worktree branch contains three unrelated Operator task-packet commits absent from its remote claim ref; those bytes and commits must remain preserved.`
- Prevention / pipeline improvement: `Keep the moved-branch gate fail-closed; resolve ownership and choose a preservation-safe review checkout strategy before any reviewer launch.`
- Tooling / docs drift discovered: `The W1 host_validation_recovery metadata records recovery_worktree and the remote claim remains pinned, but the attached local branch has advanced beyond reviewed_main.`
- Follow-up: `manual-follow-up`
- What worked: `The legacy claim header is now checked against canonical claim identity, and the planner exposes the later moved-branch blocker without changing the original run.`

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Refresh reason: `The exact W1 claim's attached local branch is three commits beyond reviewed_main while its remote claim remains pinned; a safe route must preserve all commits and avoid reviewing unrelated branch content.`
- Next action: `Review the exact W1 branch/worktree evidence and authorize a separate preservation-safe recovery design before any continuation or reviewer launch.`
- Blockers or open questions: `The W1 review remains in host_validation_recovery. Its worktree and three unique commits, claim ref, and failed run evidence remain protected. W2 and W5 remain blocked.`
