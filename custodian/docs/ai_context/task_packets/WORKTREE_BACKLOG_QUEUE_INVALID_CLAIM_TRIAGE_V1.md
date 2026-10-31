# WORKTREE BACKLOG QUEUE INVALID CLAIM TRIAGE V1

- Packet schema: custodian.task_packet.v2
- Workstream: worktree-backlog-queue-invalid-claim-triage-v1
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P1
- Depends on: review-worktree-backlog-census-and-safety-ledger-v1
- Locks: worktree-backlog-queue-triage
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-worktree-backlog-queue-invalid-claim-triage-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: multi-worktree safety, preserved unique history and original-claim ownership require an independent review
- Reviewed main: c02747856055d38cb8ea6871b49257cfcee82dad
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Separate genuine queue/schema/review-provenance defects from 65 reported invalid-recovery classifications and two claim-only interrupted dispatch refs, without overwriting live claims or diluting validation.
- Completion boundary: Read-only exact-ID queue and remote-claim triage with bounded correction suggestions; apply only provably safe metadata fixes under normal review, never blanket `Status: complete`, claim deletion or eligibility override.
- Current measured state: User host-local read-only census on 2026-10-17 reports 36 unfinished attachments, 17 dirty, 19 clean, but names 17 dirty + 18 clean only; 10 unique-ahead HEADs include a transit-lift identity not named in either list. Also 2 archived residue, 11 detached, 65 invalid-recovery and 2 claim-only refs. This is source-reported evidence, not independently rerun in the user's machine. Consult custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md and refetch main/host before mutation.
- Evidence: custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py audit --json; git worktree list --porcelain; workstream/branch_hygiene source and current remote claims.
- Task-specific authority: AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md; branch_hygiene.py and task_packet_contract.py; reviewed OR1/OR2 outcomes when those authorities are required.
- Work surface: custodian/tools/agent/dispatch.py; custodian/tools/agent/task_packet_contract.py; custodian/tools/agent/validate_review_pairing.py; custodian/tools/agent/task_packet_index.py; custodian/tools/agent/workflow_control.py; existing tests test_dispatch.py, test_task_packet_contract.py, test_workflow_control.py; ledger per-row appendix and correction packets only if necessary.
- Change: On current origin/main re-run `dispatch.py audit --json` and capture each of 65 invalid_recovery records with *exact reason* (malformed header, missing target, dependency, review outcome, bad validation path, stale archive, claimed conflict or interrupted claim). Compare against current user baseline, avoid assuming these counts still apply. For each of two claim-only refs read exact remote claim SHA, run receipt, branch absence, creator/provenance and in-flight process evidence; no-delete until original claimant proven dead and recovery owner permitted. Classify `SCHEMA_CORRECTION`, `REVIEW_PROVENANCE`, `LIVENESS_ORPHAN`, `VALID_BLOCKED`, `STALE_INDEX`, `UNKNOWN_PROTECT` and emit minimal correction plan. Fix only directly proven parser/index/documentation drift without changing acceptance semantics; put high-impact shared gating corrections in own narrowly reviewed follow-up packet, not one 65-row bulk patch.
- Preserve: Every original worktree, local committed/uncommitted/UID or support file, original review disposition, remote claim/branch, exact Authoring chat, user-owned root, asset pipeline; complete archived/accepted review distinction.
- Non-goals: No mass gc, force reset/clean/remove, fabricated PASS, blanket queue metadata rewrite, overlapping independent OR1/OR2 authority, new general dispatcher, gameplay/art changes, auto-acceptance after administratively closed findings.
- Acceptance: Every actually invalid packet and claim-only ref receives exact IDs, upstream reason and next owner, no duplicate/omitted rows, and testable minimal correction or protected decision. Zero invalids reported only if fresh audit proves zero. No abandoned assumption from process absence; no claim theft, fake pass or mass metadata conversion. All queue/index/schema controls remain green.
- Validation: Synthetic missing review target, findings-only archived outcome, malformed ready packet, stale README, two remote-only claim refs, foreign claimed ref and simultaneous remote push. Run test_dispatch, task_packet_contract, workflow_control, validate_review_pairing, task_packet_index and changed-file canonical suite.
- Task overrides: none
- Deferred: Irreducible user decisions, foreign live owners, unsupported local preservation/retirement and materially distinct code corrections must be left explicitly protected and separately authorized.

## Handoff

- Next workstream: review-worktree-backlog-queue-invalid-claim-triage-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Produce bounded prioritized correction follow-ups; do not auto-interfere with W3 owner recovery. Independently re-audit live origin/main and dispatcher at claim and closeout; follow original workstream's ownership gate.
- Blockers or open questions: Targeted authoring preflight pending; dependency- and lock-gated until live dispatcher authorizes. Historical count discrepancy is a required W1 acceptance blocker, not permission to skip a checkout.
