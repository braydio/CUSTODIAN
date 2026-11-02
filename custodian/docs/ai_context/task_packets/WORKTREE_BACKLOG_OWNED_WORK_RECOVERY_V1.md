# WORKTREE BACKLOG OWNED WORK RECOVERY V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-owned-work-recovery-v1
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P1
- Depends on: review-worktree-backlog-dirty-and-unique-preservation-v1
- Locks: worktree-backlog-owned-recovery
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-worktree-backlog-owned-work-recovery-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: multi-worktree safety, preserved unique history and original-claim ownership require an independent review
- Reviewed main: c02747856055d38cb8ea6871b49257cfcee82dad
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: For all unfinished attached packet worktrees, determine and execute only the original-owner-supported continuation, finishing or bounded correction path, without discarding unique work or laundering reviews.
- Completion boundary: Classify all W1 unfinished original identities and produce per-owner safely actionable ordered recovery; recover/finish only eligible exact original claims using existing lifecycle commands. No speculative auto-adoption or mass re-claim. Unproven/foreign owner stays preserved.
- Current measured state: User host-local read-only census on 2026-10-17 reports 36 unfinished attachments, 17 dirty, 19 clean, but names 17 dirty + 18 clean only; 10 unique-ahead HEADs include a transit-lift identity not named in either list. Also 2 archived residue, 11 detached, 65 invalid-recovery and 2 claim-only refs. This is source-reported evidence, not independently rerun in the user's machine. Consult custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md and refetch main/host before mutation.
- Evidence: custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py audit --json; git worktree list --porcelain; workstream/branch_hygiene source and current remote claims.
- Task-specific authority: AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md; branch_hygiene.py and task_packet_contract.py; reviewed OR1/OR2 outcomes when those authorities are required.
- Work surface: custodian/tools/agent/worktree_backlog_census.py; custodian/tools/agent/workstream.py; custodian/tools/agent/dispatch.py; custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/branch_hygiene.py; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; focused `custodian/tools/agent/test_worktree_backlog_census.py` and existing workstream/review tests. Minimal row disposition updates in ledger only.
- Change: Consume W1 immutable census and W2 preservation receipts, refetch current main/claims. Split ACTIVE_PROTECT vs originally-owned recoverable vs draft/manual vs blocked vs review-awaiting-verdict; never change original packet to `ready` solely for cleanup. For current claims, use exact original run/branch/worktree and approved workstream resume/finish; if dirty, preserve and require a supported non-destructive path instead of `workstream.py resume` on dirt. For protected `post_exit_recovery` reviews, only use independently accepted same-run continuation and an actual reviewer-authored PASS/findings decision. For dead-owner lease parking, require OR1/OR2 independently accepted before mutating lease and use original fencing. Verify finished code is reachable on fetched origin/main, exact archived completion and reviewer pairing before freeing locks. Donor-only unique commits require per-commit relevance/merge/conflict assessment, never bulk merge stale art. Emit outcomes `RESUMED_ORIGINAL|LANDED_VERIFIED|BLOCKED_OWNER|PARKED_AUTHORIZED|DONOR_PRESERVED|DRAFT_RETAINED` per exact workstream.
- Preserve: Every original worktree, local committed/uncommitted/UID or support file, original review disposition, remote claim/branch, exact Authoring chat, user-owned root, asset pipeline; complete archived/accepted review distinction.
- Non-goals: No mass gc, force reset/clean/remove, fabricated PASS, blanket queue metadata rewrite, overlapping independent OR1/OR2 authority, new general dispatcher, gameplay/art changes, auto-acceptance after administratively closed findings.
- Acceptance: All unfinished named/actual identities receive a concrete evidence-backed disposition and next command; no live owner terminated, no duplicate claim/ref or forged review, no dirty data lost. Successful finish includes green canonical validation, landed SHA, archive, review status; otherwise remains protected. Demonstrate failure with missing original claim, contaminated review receipt, stale run ID, active worker or absent OR2 acceptance.
- Validation: Replay synthetic 17 dirty/18 named clean/one unknown, original claim and process alive, dirty review with no PASS, local-only 20 commits, interrupted landing, approved OR2 parked owner, manual drafts and blocked packets; existing dispatch, workstream, paired_review_runner and review_receipt_delta suites plus canonical changed-file validation.
- Task overrides: none
- Deferred: Irreducible user decisions, foreign live owners, unsupported local preservation/retirement and materially distinct code corrections must be left explicitly protected and separately authorized.

## Handoff

- Next workstream: review-worktree-backlog-owned-work-recovery-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: W4 may retire only individually proven residual checkouts. Preserve all deferred scope in ledger. Independently re-audit live origin/main and dispatcher at claim and closeout; follow original workstream's ownership gate.
- Blockers or open questions: Targeted authoring preflight pending; dependency- and lock-gated until live dispatcher authorizes. Historical count discrepancy is a required W1 acceptance blocker, not permission to skip a checkout.
