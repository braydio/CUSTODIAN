# WORKTREE BACKLOG CENSUS AND SAFETY LEDGER V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-census-and-safety-ledger-v1
- Status: `complete`
- Dispatch: `auto`
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
- Current measured state: W1 independently captured 62 canonical worktree paths on 2026-10-17 at `origin/main@2f38903cd8c44c8dff95841b6bc2701b57c3adfd`: 38 attached agent worktrees map to active packets (20 dirty, 18 clean), 2 attached archived packet worktrees, 11 detached worktrees, and 2 additional agent branches have no matching active or archived packet. The 35 originally named unfinished identities plus `transit-lift-runtime-foundation-v1` reconcile the reported 36. There are 11 attached agent HEADs ahead of origin/main, 65 dispatcher invalid-recovery rows, and 2 interrupted/claim-only refs. Full normalized rows and fingerprints are in `custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md`; no owner liveness is inferred.
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

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `worktree_backlog_census.py --json` captured 62 unique canonical paths and normalized all requested worktree, packet, claim, ancestry, dirtiness, process-provenance, and protection fields. The measured ledger resolves the named-count discrepancy and retains every path row without raw status paths or file contents.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial census prototype tests exposed malformed path conversion and fixture interception errors; corrected before validation. The first live snapshot also showed that archived rows and unrelated attached roots must remain distinct from active packet-bearing checkouts.
- Root cause / contributing factors: The baseline enumerated only named unfinished branches while `git worktree list` also includes detached, archived, auxiliary, and new active worktrees.
- Prevention / pipeline improvement: Keep the census as a one-row-per-canonical-path inventory and reconcile packet, archived, and branch-only identities as separate evidence classes. Preserve raw porcelain only as a local hash, never filenames or file contents.
- Tooling / docs drift discovered: Dispatcher audit reports queue identity but not process liveness; the census correctly leaves execution provenance unknown. Two local agent branches have no active/archived packet mapping, and the ahead-head count increased from 10 to 11.
- Follow-up: worktree-backlog-dirty-and-unique-preservation-v1
- What worked: Temporary bare-remote tests cover attached dirty/ahead state, detached support, fake interrupted claims, malformed packet identity, missing paths, and before/after refs/status.

## Next Handoff

- Next workstream: review-worktree-backlog-census-and-safety-ledger-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: Land and archive W1 through the normal lifecycle; then start its fresh-context paired review. Preserve the census as the input to W2 and W5; do not clean or release any discovered owner.
- Blockers or open questions: Two agent branches lack packet identity and remain UNKNOWN_PROTECT; W2/W5 must inspect their authority before any mutation.
