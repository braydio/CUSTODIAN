# WORKTREE BACKLOG ARCHIVED AND DETACHED RECONCILIATION V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-archived-and-detached-reconciliation-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: review-worktree-backlog-owned-work-recovery-v1
- Locks: agent-branch-hygiene, worktree-backlog-retirement
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-worktree-backlog-archived-and-detached-reconciliation-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: multi-worktree safety, preserved unique history and original-claim ownership require an independent review
- Reviewed main: c02747856055d38cb8ea6871b49257cfcee82dad
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Safely reconcile archived-complete checkout leftovers and detached capture/support worktrees, without destroying unique history, media or user changes.
- Completion boundary: Evaluate two archived-attached leftover checkouts and eleven detached worktrees using refreshed evidence; apply only exact, independently proven retirements through existing branch_hygiene/worktree lifecycle authority. Dirty/unique/unknown are preserved rather than forcibly removed.
- Current measured state: User host-local read-only census on 2026-10-17 reports 36 unfinished attachments, 17 dirty, 19 clean, but names 17 dirty + 18 clean only; 10 unique-ahead HEADs include a transit-lift identity not named in either list. Also 2 archived residue, 11 detached, 65 invalid-recovery and 2 claim-only refs. This is source-reported evidence, not independently rerun in the user's machine. Consult custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md and refetch main/host before mutation.
- Evidence: custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py audit --json; git worktree list --porcelain; workstream/branch_hygiene source and current remote claims.
- Task-specific authority: AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md; branch_hygiene.py and task_packet_contract.py; reviewed OR1/OR2 outcomes when those authorities are required.
- Work surface: custodian/tools/agent/branch_hygiene.py; custodian/tools/agent/workstream.py; custodian/tools/agent/worktree_backlog_census.py; custodian/tools/agent/worktree_evidence_preserve.py; custodian/tools/agent/test_branch_hygiene.py; custodian/docs/ai_context/BRANCH_ARCHIVE.md; ledger audited dispositions; no game or art source edits.
- Change: For `review-agent-next-execution-boundary-v1` (dirty archived-attached) and `review-compound-connected-bunker-blockout` (clean archived-attached), reverify archived packet, exact accepted versus findings outcome, original remote ref, sidecars, preservation receipts, Git liveness and unique commits. Archived complete findings ≠ accepted PASS. For 11 detached, resolve ownership/purpose, including two Alpine cliff captures and media/visual evidence dependencies. Require exact per-path no-active-owner and full preservation proof before any teardown. Use supported `branch_hygiene.py` report-first and archive-tag-before-retire with verified SHA, durable ledger and explicit scoped authorization; fail if worktree attached/dirty/unlanded data or output of review still referenced. Never run broad `git worktree prune`, forced remove or wildcard branch delete. Retain special support/capture artifacts unless lossless relocation and reviewer evidence links are verified.
- Preserve: Every original worktree, local committed/uncommitted/UID or support file, original review disposition, remote claim/branch, exact Authoring chat, user-owned root, asset pipeline; complete archived/accepted review distinction.
- Non-goals: No mass gc, force reset/clean/remove, fabricated PASS, blanket queue metadata rewrite, overlapping independent OR1/OR2 authority, new general dispatcher, gameplay/art changes, auto-acceptance after administratively closed findings.
- Acceptance: All 2 archived leftovers and 11 detached get individually reviewed `RETIRED_VERIFIED|PRESERVED_FOR_EVIDENCE|ACTIVE_PROTECT|BLOCKED_UNKNOWN`; each retired path proven data-neutral and archived with SHA; no deleted data/branches absent archive or verified main ancestry; original claims and independent review records unaffected. Provide before/after worktree census and exception list.
- Validation: Temp archived complete/findings review with dirty .uid, clean archived checkout with attached-but-active process, detached Alpine capture with unique media, branch with commits absent from main, race in removal; branch_hygiene/workstream and changed-file validation.
- Task overrides: none
- Deferred: Irreducible user decisions, foreign live owners, unsupported local preservation/retirement and materially distinct code corrections must be left explicitly protected and separately authorized.

## Handoff

- Next workstream: review-worktree-backlog-archived-and-detached-reconciliation-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: No further automatic removal. Report total preserved, retired, outstanding, acceptance truth. Independently re-audit live origin/main and dispatcher at claim and closeout; follow original workstream's ownership gate.
- Blockers or open questions: Targeted authoring preflight pending; dependency- and lock-gated until live dispatcher authorizes. Historical count discrepancy is a required W1 acceptance blocker, not permission to skip a checkout.
