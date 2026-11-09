# REVIEW BROKEN REMOTE TRACKING REF REPAIR V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-broken-remote-tracking-ref-repair-v1
- Kind: review
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: manual
- Priority: P0
- Depends on: broken-remote-tracking-ref-repair-v1
- Locks: git-ref-maintenance, agent-dispatcher
- Review: none
- Review stage: post-land
- Review modes: code, workflow, safety
- Paired review workstream: none
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently falsify scope, ref preservation, backup identity, concurrency and dispatcher recovery claims
- Review target workstream: broken-remote-tracking-ref-repair-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/BROKEN_REMOTE_TRACKING_REF_REPAIR_V1.md
- Reviewed main: 5b74eb565b47b1b9c7f7edcf4fadffc1e65f62db
- Authoring chat: pending current Phase B conversation URL
- Prior orchestration chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef81ab-23fc-83ea-8010-74334c76fb3a
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Goal: Independently verify the exact malformed-reference metadata repair, retention of all legitimate Git state, reversible evidence and canonical dispatcher outcome.
- Reviewed implementation acceptance: All acceptance and preservation requirements of archived BROKEN_REMOTE_TRACKING_REF_REPAIR_V1.md.
- Review evidence: Pinned implementation/main SHAs; exact original 16-file identity manifest and verified backup hashes; original/current advertised remote refs; before/after reference inventories; root and worktree status; focused negative test results; actual dispatcher audit result and its observed side effects.
- Correction threshold: Any removed valid or advertised ref, changed existing object, absent private backup, changed HEAD/claim/worktree, unverified same-path race, symlink traversal, failed rollback, unauthorized root modification, skipped tests or unreviewed host-side metadata mutation blocks PASS. Dispatcher returning a queue result does not itself validate repair safety.
- Focused validation: Fresh clone/temp Git fixtures for all positive/negative scenarios, source review of exact path and TOCTOU checks, checksum/identity verification of preserved private host evidence, post-state Git reference integrity, focused agent test suite and complete selected changed-file checks.
- Review focus: Git common-dir identity, safe enumerated scope, null/zero-byte loose refs, packfile interaction, concurrent ref writers, backup and atomicity, unusual paths, idempotence, original W2 dependency/claim invariants and no retroactive reinterpretation of historic claims.
- Acceptance: PASS only with independently proven data-neutral host repair and complete required tests. Otherwise record stable R0-NN findings with a bounded correction and re-review; never mark the blocked W2 packet claimable by inference.
- Non-goals: No broad ref cleanup, direct W2 claim, worktree retirement, approval of unknown process owners, or new dispatcher implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only its durable receipt, review-packet lifecycle/archive metadata, required closing summary and bounded correction/re-review packets; do not modify reviewed implementation source or unrelated work.`
- Authoring status: Draft only. Not a review receipt or implementation approval.

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: yes, current chat backlink required
- Next action: Review pinned implementation evidence in a fresh context and record PASS or precise findings.
- Blockers or open questions: Host repair, test results, independent acceptance and canonical dispatcher audit remain outstanding.
