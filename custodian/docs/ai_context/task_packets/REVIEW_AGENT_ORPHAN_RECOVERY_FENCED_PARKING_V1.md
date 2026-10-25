# REVIEW: AGENT ORPHAN RECOVERY FENCED PARKING V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-orphan-recovery-fenced-parking-v1
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: agent-orphan-recovery-fenced-parking-v1
- Locks: agent-workflow
- Review: none
- Review target workstream: agent-orphan-recovery-fenced-parking-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_ORPHAN_RECOVERY_FENCED_PARKING_V1.md
- Reviewed main: 58934945d0e97020f8caffe078e865eb94409ced
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently prove that verified dead local Codex execution releases only an execution lease without losing code or relaxing CUSTODIAN's review/dispatch safety.
- Reviewed implementation acceptance: Independently verify A–I in archived `AGENT_ORPHAN_RECOVERY_FENCED_PARKING_V1.md`; require meaningful tests against actual core process/remote Git paths, not all-mocked success.
- Review evidence: Latest main implementation of new CAS owner-ref and dispatcher lock resolver, OR1 accepted liveness proof, `workstream.py` recovery logic, paired review runner, temporary bare-remote race logs, protected dirty checkout and local recovery journal, existing original PF5 review outcome evidence.
- Correction threshold: Any false positive orphan, lost file/commit, remotely stolen lease, double-claimed workstream, follow-on dependency mistakenly released after `findings`, weakened validation/receipt gate, artifact leak or OS process termination is blocking; no cosmetic rework within review.
- Focused validation: Reproduce live-dormant, SIGKILL, child still running, PID recycle, reboot/foreign host, dirty and local-only commit, protected ignored artist art, stale/changed ref, concurrent owner CAS, crash at every recovery stage and retry idempotence. Confirm existing PF5 exact-byte target receipt tests still fail closed and the old review claim cannot be retroactively marked `passed` by a new owner token. Re-run all named focused test modules, changed coverage, packet pairing and index.
- Review focus: Demonstrate the clear separation of execution lease, persisted agent branch, packet lifecycle and reviewed-acceptance state. A clean state alone never grants a synthetic green artifact. New timer is optional and disabled by default; tests must not destroy any real worktree/branch. The reviewer cannot author a cleanup policy or force Git refs.
- Acceptance: 0 blocking findings and 0 material evidence gaps, independent race and fault-injection reproduction, explicit list of branches/artifacts not touched. Publish a findings-first receipt and stable corrections for any blocking gap.
- Non-goals: Automatic cleanup of historical unobserved Codex runs, forced lease takeover from other hosts, restoring/recreating agent text sessions, deleting tags or making `Status: complete` equivalent to PASS.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Use `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; run fresh-context independent temporary-remote and OS-process tests and preserve original state if any required proof is missing.

## Handoff

- Next workstream: none
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Refresh reason: Host opt-in for timer and user-facing default/ownership policy after accepted recovery proof; unknown foreign-host takeover is never automatic.
- Next action: Return the verified command/telemetry and enable optional host-local supervisor only with user consent.
- Blockers or open questions: None for executing fixture-safe implementation; reviewer must not enable background timer autonomously.

## Cooperative pause/resume independent review (2026-10-25)

In addition to A–I, independently reproduce real process and temporary bare-remote scenarios for `ACTIVE -> PAUSE_REQUESTED -> PARK_PREPARED -> PARKED -> RESUME_PREPARED -> ACTIVE`. Verify supervised graceful exit triggers parking without an installed timer; no lease unlock while any owned reviewer/process descendant remains live; a parked branch remains claimed and its local worktree, staged/unstaged, untracked art and commits remain unchanged. On resume, two simultaneous callers across separate clones must never both acquire execution ownership; conflicting locks must prevent resumption rather than launch duplicate work.

Fault-inject every journal, snapshot, CAS and readback boundary, including disk exhaustion, Git remote outage, PID reuse and foreign host. Verify that `findings` and `human_required` are not promoted to PASS; old uninstrumented historical reviews, especially `review-agent-paired-review-godot-cache-access-v1`, are **not** automatically parked. The one-off exact parking pilot may not be repurposed or weakened. No periodic host service or timer may be installed by implementation or review. Report exact original workstream claim and proof of non-loss after every fault injection.

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
