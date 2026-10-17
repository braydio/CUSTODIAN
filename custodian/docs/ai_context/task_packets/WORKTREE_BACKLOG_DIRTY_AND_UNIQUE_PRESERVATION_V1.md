# WORKTREE BACKLOG DIRTY AND UNIQUE PRESERVATION V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-dirty-and-unique-preservation-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P0
- Depends on: review-worktree-backlog-census-and-safety-ledger-v1
- Locks: worktree-backlog-preservation
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-worktree-backlog-dirty-and-unique-preservation-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: multi-worktree safety, preserved unique history and original-claim ownership require an independent review
- Reviewed main: c02747856055d38cb8ea6871b49257cfcee82dad
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Prove that all original dirty work and unique unlanded HEAD history have byte-safe recovery copies before any archive, adoption or retirement decision.
- Completion boundary: A plan-first, explicitly authorized host-local preservation tool/receipt. Preserve 17 reported dirty entries, 10 unique-HEAD cases and unknown extras from W1; leave all original checkout and remote claim bytes unchanged. Mark unsupported or potentially secret data unsafe rather than silently skipping.
- Current measured state: User host-local read-only census on 2026-10-17 reports 36 unfinished attachments, 17 dirty, 19 clean, but names 17 dirty + 18 clean only; 10 unique-ahead HEADs include a transit-lift identity not named in either list. Also 2 archived residue, 11 detached, 65 invalid-recovery and 2 claim-only refs. This is source-reported evidence, not independently rerun in the user's machine. Consult custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md and refetch main/host before mutation.
- Evidence: custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py audit --json; git worktree list --porcelain; workstream/branch_hygiene source and current remote claims.
- Task-specific authority: AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md; branch_hygiene.py and task_packet_contract.py; reviewed OR1/OR2 outcomes when those authorities are required.
- Work surface: custodian/tools/agent/worktree_evidence_preserve.py (new, no worktree write); custodian/tools/agent/worktree_backlog_census.py (reuse); custodian/tools/agent/branch_hygiene.py (read-only classification); custodian/tools/agent/test_worktree_evidence_preserve.py (new); existing custodian/tools/agent/persistent_checkout_sync.py (reference only); update ledger receipt references only.
- Change: Add `--plan --json` and exact `--apply --authorize-preservation` over selected W1 row identities, never a wildcard. Under a private Git common-dir recovery evidence directory, exclusive-create + fsync + SHA256 verify index/staged and unstaged binary diffs, tracked worktree bytes where needed, nonignored untracked raw file bytes including .uid sidecars, symlink types/modes and HEAD/merge-base/remote claim refs. Preserve unique ahead commits in a verified private git bundle before any branch retirement; record bundle verify and checksum, and fail closed if an unlanded local-only HEAD cannot be proven durable. Never copy secrets to remote, commit binary snapshots or publish private bytes to repository; block on sensitive/unsafe paths, size caps, missing sources, path races, symlink escape, irreconcilable Git LFS pointers or incomplete copy. Re-hash source after snapshot to detect races; emit read-only receipt index and per-row `PRESERVED_FULL|PRESERVED_PARTIAL|BLOCKED`; no original data deletion. Reconcile transit-lift classification. Do not modify original claimed branch/worktree just to make it clean.
- Preserve: Every original worktree, local committed/uncommitted/UID or support file, original review disposition, remote claim/branch, exact Authoring chat, user-owned root, asset pipeline; complete archived/accepted review distinction.
- Non-goals: No mass gc, force reset/clean/remove, fabricated PASS, blanket queue metadata rewrite, overlapping independent OR1/OR2 authority, new general dispatcher, gameplay/art changes, auto-acceptance after administratively closed findings.
- Acceptance: Every affected dirty/unique original row has a VERIFIED_FULL receipt or explicit preserved-state blocker. Exact local HEAD refs, staged/index, untracked and committed unique history remain bit-identical before/after. Broken copy, interrupted write, secret path, unverified git bundle or changed source results BLOCKED, never safe-cleanup. No claim/packet status changed and no normal root sync attempted.
- Validation: Temp bare remote and worktrees: dirty binary/UID, staged conflict, ahead 26 commits, local-only branch, broken bundle, LFS pointer, symlink attack, permission error, interruption and changed source race; verify SHA256/HEAD/index before and after. Run focused branch_hygiene, workstream, persistent_checkout_sync tests and changed-file suite; require paired review.
- Task overrides: none
- Deferred: Irreducible user decisions, foreign live owners, unsupported local preservation/retirement and materially distinct code corrections must be left explicitly protected and separately authorized.

## Handoff

- Next workstream: review-worktree-backlog-dirty-and-unique-preservation-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: W3 may triage original ownership and W4 may examine residue only with full preservation proof. Independently re-audit live origin/main and dispatcher at claim and closeout; follow original workstream's ownership gate.
- Blockers or open questions: Targeted authoring preflight pending; dependency- and lock-gated until live dispatcher authorizes. Historical count discrepancy is a required W1 acceptance blocker, not permission to skip a checkout.
