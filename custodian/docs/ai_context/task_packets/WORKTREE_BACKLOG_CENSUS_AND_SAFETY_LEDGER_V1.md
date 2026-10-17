# WORKTREE BACKLOG CENSUS AND SAFETY LEDGER V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-census-and-safety-ledger-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P0
- Depends on: none
- Locks: worktree-backlog-census
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-worktree-backlog-census-and-safety-ledger-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: multi-worktree safety, preserved unique history and original-claim ownership require an independent review
- Reviewed main: c02747856055d38cb8ea6871b49257cfcee82dad
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Produce one exact, reproducible, read-only machine-local ledger for every attached, detached, claim-only and packet-invalid identity, without altering any claimant.
- Completion boundary: Introduce a bounded read-only census/report command and durable scrubbed ledger; resolve the reported 36 versus 35 named mismatch, including transit-lift, and mark unknown owners protected. No cleanup, automatic parking, packet status edits, or worktree writes.
- Current measured state: User host-local read-only census on 2026-10-17 reports 36 unfinished attachments, 17 dirty, 19 clean, but names 17 dirty + 18 clean only; 10 unique-ahead HEADs include a transit-lift identity not named in either list. Also 2 archived residue, 11 detached, 65 invalid-recovery and 2 claim-only refs. This is source-reported evidence, not independently rerun in the user's machine. Consult custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md and refetch main/host before mutation.
- Evidence: custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py audit --json; git worktree list --porcelain; workstream/branch_hygiene source and current remote claims.
- Task-specific authority: AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md; branch_hygiene.py and task_packet_contract.py; reviewed OR1/OR2 outcomes when those authorities are required.
- Work surface: custodian/tools/agent/worktree_backlog_census.py (new read-only orchestration); custodian/tools/agent/dispatch.py (read-only API/use, no new claim authority); custodian/tools/agent/workstream.py (read-only); custodian/tools/agent/branch_hygiene.py (read-only); custodian/tools/agent/test_worktree_backlog_census.py (new); custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md (measured row update).
- Change: Run original `dispatch.py audit --json`, `git worktree list --porcelain`, exact `git -C <worktree> status --porcelain=v2 -z`, `git rev-list --left-right --count origin/main...HEAD` with checked exit codes, and `for-each-ref`/`merge-base` without mutation. Resolve symlink identities, duplicate physical worktrees, missing paths, detached heads, local-only refs, valid/invalid packet paths, interrupted remote claim refs, and historical archive status. Mark live owner evidence separately from mere branch existence; do not infer process liveness from missing PID. Output stable normalized JSON and human-readable ledger, redacting secrets and file content. Explicitly compare the 17 dirties and 18 named cleans against all actual 36 and flag the unidentified checkout. Record 10 reported unique HEADs including transit-lift, 2 archived residue, 11 detached, 65 invalid and 2 interrupted claims as *reported baselines* and revise exact counts only from new host evidence. Preserve counts and source provenance.
- Preserve: Every original worktree, local committed/uncommitted/UID or support file, original review disposition, remote claim/branch, exact Authoring chat, user-owned root, asset pipeline; complete archived/accepted review distinction.
- Non-goals: No mass gc, force reset/clean/remove, fabricated PASS, blanket queue metadata rewrite, overlapping independent OR1/OR2 authority, new general dispatcher, gameplay/art changes, auto-acceptance after administratively closed findings.
- Acceptance: Every actual attached/detached path appears once; unmatched/missing named 36th worktree is identified or explicitly blocks downstream cleanup; classification includes paths, SHAs, claim status, dirty counts, unique-commit proof and authoritative safety action; no files/refs/worktrees/packet states changed by census. Wrong repo path, stale origin/main, permission denied, disappearing path, malformed porcelain and duplicate identity stop/mark UNKNOWN_PROTECT.
- Validation: Add temp bare repo + clean/dirty attached worktree + detached support + ahead-only commit + untracked .gd.uid + fake claim-only ref, malformed packet and missing worktree cases. Compare before/after exact Git and status bytes; run python3 custodian/tools/agent/test_dispatch.py, python3 custodian/tools/agent/test_branch_hygiene.py and canonical `run_validation.py --changed --json`; check_ai_context, review pairing, task index, git diff --check.
- Task overrides: none
- Deferred: Irreducible user decisions, foreign live owners, unsupported local preservation/retirement and materially distinct code corrections must be left explicitly protected and separately authorized.

## Handoff

- Next workstream: review-worktree-backlog-census-and-safety-ledger-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Do not begin destructive or claim-releasing action; release the reviewed normalized census to W2 and W5. Independently re-audit live origin/main and dispatcher at claim and closeout; follow original workstream's ownership gate.
- Blockers or open questions: Targeted authoring preflight pending; dependency- and lock-gated until live dispatcher authorizes. Historical count discrepancy is a required W1 acceptance blocker, not permission to skip a checkout.
