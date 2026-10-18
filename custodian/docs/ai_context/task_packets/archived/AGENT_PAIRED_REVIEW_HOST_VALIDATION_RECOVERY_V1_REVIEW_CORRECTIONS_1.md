# PAIRED REVIEW HOST VALIDATION RECOVERY — REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Kind: `correction`
- Status: `complete`
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
- Current measured state: `The preserved W1 run is host_validation_recovery at 20261017T200919Z-e0b32b5c1a3b. Its truncated claim.stdout has no structured sentinel; the complete CLAIMED identity header verifies against the canonical workstream, packet and recovery_worktree. Under the user's one-time maintenance authorization, the clean W1 checkout was re-anchored from e621d0329f49447f41d61e95b4df9220690625bb to its immutable reviewed_main b5b85ca47a1eacad9879c6abf55257d378ae0c91 after publishing and verifying refs/heads/recovery/w1-review-worktree-backlog-census-v1-review-corrections-1-e621d032 at e621d032. All three intervening Operator packet commits are ancestors of origin/main@623dd45ddf35f9c88460386ac047db3e9c1f8d52 and remain reachable from the backup ref. The original remote W1 claim still points to b5b85ca4; the local attached checkout is clean at the same SHA. The corrected read-only plan now passes with source span 6c818d16ed7c3dd19f156b80348fa4bc6929c748..1b586174fa7fbd9c1c94e6adbc36ee85bf809f4f and plan digest 1dafc8f77edaa6653504f2e2e36262a7cfe8c40e3431143c3fecdced1745ed1d. It creates no continuation and changes no original run evidence.`
- Evidence: `Original run directory .git/custodian-review-runs/review-worktree-backlog-census-and-safety-ledger-v1-review-corrections-1/20261017T200919Z-e0b32b5c1a3b; unchanged hashes for RECOVERY.md (56cb8a174df2e91f9f7bf29dc80dd06059153493580d540ffcd9abdbe675dd9e), claim.stderr (e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855), claim.stdout (46dfa3728dedd7e8931ed79db10551ddc4f3a606da0484ca88dedc7af9d0ff03), coordinator-validation.json (8f1af7c5138644cb07a10a262582f7c1141757f506c95a9aa91f40979cf632b8), metadata.json (24c3f02cd7f05ae2644eb89e4713d066ce80d769fd713fbf9471604a91965956), validation.json (25c31227a4c8ae1d95d6d61692ac67e50f7045d310ff151312e5401a893f1a11); remote backup ref at e621d032; before/after worktree/ref verification; read-only plan JSON and source-span provenance; tests and changed-file validation report.`
- Task-specific authority: `The archived parent implementation and accepted review; paired_review_runner.py owns same-claim recovery; dispatch.py owns current claim/ref eligibility; the original W1 run's claim, metadata and reports are immutable evidence.`
- Work surface: `custodian/tools/agent/paired_review_runner.py and custodian/tools/agent/test_paired_review_runner.py; bounded lifecycle wording only if needed.`
- Required correction: `Use one shared exact claim resolver in both plan and apply. Prefer a valid structured claim receipt. For a historical truncated/missing sentinel only, derive expected branch from agent/<exact workstream>, expected packet from the exact current review packet, and expected worktree from recovery_worktree; require the complete unique human header to match those identities exactly. Then verify the existing worktree is attached to this repository, has the expected branch, is clean and pinned to reviewed_main, and the remote claim ref still equals reviewed_main. Do not create a claim-receipt.json, edit any original run file, fall back on conflicting or parseable-but-invalid JSON, or weaken any current structured-claim checks.`
- Preserve: `Every original W1 run/evidence byte and the remote claim ref; the prior failed validation; source-span and archive identity checks; all three moved commits through origin/main and the independently verified backup ref; explicit plan-hash authorization; exclusive continuation child; fresh reviewer; no second claim or claim release before accepted review.`
- Non-goals: `No edits to the W1 run directory or evidence; no W2/W5 release; no generalized claim migration or unrelated post_exit_recovery changes.`
- Acceptance: `1) The exact W1 legacy run produces a read-only plan that pins its original claim, branch, packet, worktree, reviewed main and evidence digests while leaving all source evidence byte-identical. 2) Plan and apply use the same verifier and an apply requires the exact fresh plan digest. 3) Conflicting headers, wrong/missing identity, dirty or moved worktree, moved remote claim, malformed structured receipts, and a forged legacy sentinel fail closed. 4) Existing structured receipt behavior and all previously accepted recovery tests remain green. 5) No duplicate dispatcher claim is created.`
- Validation: `Add focused temporary-repository cases for exact legacy plan/apply, structured receipt precedence, truncated sentinel with matching and conflicting headers, absent metadata fields, moved remote ref, dirty/moved worktree, and plan/apply digest mismatch. Run python3 custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/agent/test_dispatch.py; python3 custodian/tools/agent/test_workstream.py; python3 custodian/tools/agent/test_review_outcome.py; python3 custodian/tools/agent/test_task_packet_contract.py; python3 custodian/tools/validation/run_validation.py --changed --json; require complete coverage and git diff --check.`
- Task overrides: `none`
- Deferred: `Any new post_exit_recovery semantics or claim-record migration.`

## Delta Rules

- Address only `R1-01`; preserve the parent implementation and accepted review receipts.
- This correction must not modify or synthesize any file in the protected W1 run directory.
- If the exact legacy claim cannot be bound to the canonical workstream, packet, existing recovery_worktree, local branch and remote branch, leave the W1 claim protected and report the precise evidence gap.
- One-time maintenance exception authorized by the user in the current planning refresh: only after a clean W1 checkout, exclusive supervisor lock, exact branch/ref/worktree identity, unchanged run-evidence hashes, current-main ancestry for all three Operator commits, and successful publication/verification of the independent remote backup ref, re-anchor the attached W1 branch from `e621d0329f49447f41d61e95b4df9220690625bb` to pinned `b5b85ca47a1eacad9879c6abf55257d378ae0c91`. Do not reset any other checkout/ref or edit original run files. The remote claim remains at the pinned SHA.


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The exact original W1 legacy claim was verified without changing its run evidence. After the user-authorized one-time re-anchor, the read-only recovery plan passed from a clean coordinator at `origin/main@623dd45ddf35f9c88460386ac047db3e9c1f8d52`, pinning the original claim/worktree, implementation `b5b85ca47a1eacad9879c6abf55257d378ae0c91`, and source span `6c818d16ed7c3dd19f156b80348fa4bc6929c748..1b586174fa7fbd9c1c94e6adbc36ee85bf809f4f`; plan SHA-256 `1dafc8f77edaa6653504f2e2e36262a7cfe8c40e3431143c3fecdced1745ed1d`. All six original run-file hashes remained unchanged. The three moved commits remain reachable from current main and verified backup ref `recovery/w1-review-worktree-backlog-census-v1-review-corrections-1-e621d032`. Required runner, dispatcher, workstream, review-outcome, packet-contract and changed-file validations passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `high`
- What went wrong: `The original claim.stdout was truncated before the structured sentinel, and the attached W1 checkout had advanced three commits beyond its pinned review baseline.`
- Root cause / contributing factors: `Historical claim output was length-limited; unrelated Operator packet commits were made in the protected W1 worktree, though all three were already on current main.`
- Prevention / pipeline improvement: `The shared verifier now supports only a uniquely matching complete legacy identity header; exact HEAD checks remain fail-closed. The user-authorized one-time re-anchor was performed only after a verified remote backup and exact before/after evidence checks.`
- Tooling / docs drift discovered: `Legacy claim output can truncate before its structured sentinel; the durable run metadata still provides the exact recovery_worktree needed for narrow verification.`
- Follow-up: `fixed-in-scope`
- What worked: `A read-only plan against the preserved run passed after the clean checkout was restored to its pinned baseline; original evidence remained byte-identical and the three commits remain recoverable from main and the backup ref.`

## Next Handoff

- Next workstream: `review-agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Refresh reason: `none`
- Next action: `Finish and land this validated correction; then launch its fresh independent paired review. After that review passes, regenerate the W1 plan on current main and apply only its exact plan digest.`
- Blockers or open questions: `The W1 reviewer has not yet been launched; continuation remains gated on this correction's independent PASS. W2 and W5 remain blocked.`
