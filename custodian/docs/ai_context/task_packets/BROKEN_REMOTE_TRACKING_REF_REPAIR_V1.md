# BROKEN REMOTE TRACKING REF REPAIR V1

- Packet schema: custodian.task_packet.v2
- Category: agent-ops
- Workstream: broken-remote-tracking-ref-repair-v1
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: manual
- Priority: P0
- Depends on: none
- Locks: git-ref-maintenance, agent-dispatcher
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-broken-remote-tracking-ref-repair-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: editing malformed local Git reference metadata requires independently verifiable exact-scope preservation and fail-closed concurrency handling
- Reviewed main: 5b74eb565b47b1b9c7f7edcf4fadffc1e65f62db
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
- Prior orchestration chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef81ab-23fc-83ea-8010-74334c76fb3a
- Visual review: none
- Goal: Restore canonical dispatcher audits blocked by malformed empty local remote-tracking references without losing any legitimate Git object, ref, worktree, or original recovery evidence.
- Completion boundary: Implement and validate an exact-ref, manifest-driven host-local repair with dry-run as default. Repair ONLY the sixteen verified zero-byte loose refs under refs/remotes/origin/custodian/legacy-quarantined/ that are absent from remote heads, with preserved evidence and deterministic rollback. Establish a clean canonical dispatcher audit; do not claim W2 as part of this packet.
- Current measured state: B-006 and B-007 preflight on 2026-11-09 report sixteen zero-byte loose refs, absent from advertised origin, no corresponding packed refs, failed git remote prune origin and git update-ref -d. Root main ee2d0c829b3d5860f5d20a6be46e3d94693fe518 is dirty and five commits behind advertised origin/main 5b74eb565b47b1b9c7f7edcf4fadffc1e65f62db. These are host-reported observations, not a current dispatcher audit.
- Evidence: B-001, B-006, B-007 host reports retained by owner; re-verify all host facts before applying.
- Task-specific authority: AGENTS.md; custodian/AGENTS.md where relevant; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/tools/agent/dispatch.py; existing agent packet/claim/review contracts.
- Publication inputs: none
- Existing required repository inputs are tracked on main. Private host evidence is deliberately not committed and must be independently re-read on the authorized host.
- Work surface: focused new maintenance implementation and tests under custodian/tools/agent/; no gameplay, worktree data, dispatcher semantics, remote refs or task status edits.
- Change: First check exact Git common-dir root and a narrowly enumerated allowlist derived from an explicit, reviewed manifest, not filesystem glob deletion. Require safe regular files (no symlinks), size zero, expected device/inode/mode/mtime, absence from packed refs and live advertised remote refs, unchanged advertised main, clean reference transaction exclusion/concurrent-use detection, and preserved pre-state path and metadata manifest. Fail closed on any mismatch or concurrency. Record the private backup/quarantine location outside the Git common directory, restrictive permissions, fsync and verified manifest before editing any ref. Use a minimal, supported host-local operation only if native Git deletion cannot handle the malformed refs; never broadly rewrite ref storage. Make dry-run idempotent; apply idempotent only when its exact validation passes; provide exact rollback instructions without overwriting valid newly created refs. Verify all other refs, HEAD, local root status, worktree registration, shared objects and LFS cache unchanged. Test canonical dispatcher audit only when the ref store is healthy; its known fetch/prune behavior must be reported as a side effect, not called read-only.
- Preserve: All original object data, legitimate loose/packed refs, remote claims, dispatcher states, worktrees, dirty root files, pending review receipts, asset LFS objects, and private evidence. No wildcard path removal, force, git gc, general prune or worktree cleanup.
- Non-goals: No worktree retirement; no W2 implementation/claim; no remote branch deletion; no reset/stash/sync of dirty root; no change to fail-closed process-use rules; no blanket dispatcher redesign.
- Acceptance: Controlled positive fixture repairs only an explicit absent empty remote-tracking ref; negative fixtures reject a nonempty ref, advertised ref, packed ref, symlink, unexpectedly modified identity, wrong namespace, permissions error, concurrent ref creation, missing backup, and partial failure. Exact 16 host refs are preserved in a private manifest and verified backup before host repair. After repair, no unrelated refs differ; canonical audit completes and reports its real eligibility decision (or exact separately attributable failure). Any mismatch yields BLOCKED with originals retained.
- Validation: Isolated temporary Git repos and bare remotes, focused agent tests, git diff --check, affected validation manifest checks, complete changed-file validation where supported; test rollback and idempotent no-op. An independent fresh-context reviewer must inspect host evidence before accepting completion.
- Task overrides: none
- Deferred: Genuine current ownership conflict, missing host privileges, unavailable preservation location, concurrent Git writers or new reference failure remain blocked; do not improvise.
- Authoring status: Draft for repository authority review. Do not auto-dispatch until authoring chat, publication, dependency and claim checks are completed.

## Handoff

- Next workstream: review-broken-remote-tracking-ref-repair-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: yes, current chat backlink required
- Next action: Complete packet authoring/approval, publish paired packet atomically through repository lifecycle, then run the canonical dispatcher claim route.
- Blockers or open questions: Cannot assert dispatcher eligibility while malformed local refs persist; host-only repair and its independent review remain outstanding.
