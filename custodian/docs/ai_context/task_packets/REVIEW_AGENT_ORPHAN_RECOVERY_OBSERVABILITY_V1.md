# REVIEW: AGENT ORPHAN RECOVERY OBSERVABILITY V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-orphan-recovery-observability-v1
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: agent-orphan-recovery-observability-v1
- Locks: agent-session-observability
- Review: none
- Review target workstream: agent-orphan-recovery-observability-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1.md
- Reviewed main: 58934945d0e97020f8caffe078e865eb94409ced
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently demonstrate that OR1's live/dead/worktree classification is accurate, read-only and impossible to turn into implicit claim release or review acceptance.
- Reviewed implementation acceptance: Replay A–G of archived `AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1.md`; every evidenced probe must point to actual process/boot/start/branch/worktree/trace truth.
- Review evidence: New supervisor/audit source/tests and their recorded output, current dispatch/workstream/paired-review implementation and V1 design spec. Use temporary bare remote/clone and process fixtures; never run destructive probes on the user's persistent checkout or actual queued packet.
- Correction threshold: Any false EXITED for live child, PID reuse, remote host or missing metadata; any audit mutation; any ability to claim a fake completed review; or missing required negative tests is blocking. Optional formatting changes are not.
- Focused validation: Independently reproduce live-idle and post-exit cases, SIGTERM/SIGKILL with descendants, PID reused, boot changed, remote unknown, missing metadata, dirty/untracked art preserving no-change before/after hashes; run focused existing agent workflow and full changed-file ownership. Verify root chat provenance uses not-recorded until supplied instead of a different conversation.
- Review focus: Verify supervisory PID group/boot identity against OS semantics; prevent caller-created JSON from claiming verified liveness; only dispatcher still issues actual Git assignment. `post_exit_recovery` must remain unfinished, not converted to green. Confirm no unscoped process signal or running Codex termination.
- Acceptance: Fresh findings-first review with zero blocking defects and material proof gaps, exact source evidence and independent end-to-end negative controls. Keep OR2 disabled until this passes. Record stable finding IDs and bounded corrections if necessary.
- Non-goals: No session takeover, lease expiry, auto park, branch cleanup, synthetic reviewed-target receipt or new dispatcher.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Use `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` from a fresh context, reading the actual archived target and reproducing independent process/remote tests.

## Handoff

- Next workstream: agent-orphan-recovery-fenced-parking-v1
- Next packet state: ready/auto, dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Next action: Allow OR2 only after exact OR1 review acceptance; no human decision required for proof-driven safe parking.
- Blockers or open questions: Foreign/unmanaged sessions stay protected.

## Additional independent falsification: pause is not parking (2026-10-25)

Verify that OR1 records `PAUSE_REQUESTED` only for the exact supervised process identity, exposes a provable stopped-vs-live tree, and remains strictly diagnostic. Construct a fake pause event with a living descendant, changed PID start time, foreign host and tampered journal; none may classify as `EXITED_CONFIRMED` or release the `agent-workflow` lock. A clean voluntary exit must be evidenced but still **not** mutate remote execution leases, Git branch refs, worktree bytes, reviewer status or dispatcher claimability. The resumed/preserved identity contract is reserved to OR2.

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925

## Independent bootstrap scope review (2026-10-25)

Prove OR1 touches only new observational/supervision wrappers, synthetic fixtures, bounded validation registration and truthful documentation; any changes to production `dispatch.py`, `workflow_control.py`, `workstream.py`, `paired_review_runner.py` or their lock/review authority are **blocking** and must be deferred to the OR2 `agent-workflow` workstream. Inspect actual unmodified before/after Git blobs of those shared authorities. Run host-compatible false-liveness negative controls and confirm an uninstrumented `agent/operator-ranged-domain-extraction` remains `UNMANAGED_UNKNOWN` rather than classified EXITED because its branch is old/idle. No remote execution ref mutation and no release of `operator-runtime` or `agent-workflow` is allowed. OR2's independent review remains required.
