# AGENT ORPHAN RECOVERY OBSERVABILITY V1 (OR1)

- Packet schema: custodian.task_packet.v2
- Workstream: agent-orphan-recovery-observability-v1
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-agent-paired-review-coordinator-boundary-v1-review-corrections-2
- Locks: agent-session-observability
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-orphan-recovery-observability-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: supervised execution liveness, Git worktree provenance and review-runner integration require independent falsification
- Reviewed main: 58934945d0e97020f8caffe078e865eb94409ced
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Visual review: none
- Goal: Reliably distinguish a live Codex/review execution from a terminated, recoverable or ambiguous CUSTODIAN workstream, without destroying work or weakening current dispatcher locks.
- Completion boundary: Provide one verified subprocess-supervision journal and read-only deterministic orphan inventory, integrating existing dispatcher claim receipts, workstream traces and paired-review runner's supervised child. **No** automatic parking, claim release, remote lease mutation, archive or packet lifecycle status change in OR1.
- Current measured state: `dispatch.py audit --json` classifies remote agent branches, attached worktrees, dirty state and remote claim refs, but does not prove OS execution ownership. `dispatch.py` counts each remote `agent/<id>` branch as a live claimed workstream for packet `Locks:`. `dispatch-claims/<id>` is an assignment-time create-only claim, not a renewed session lease. `workstream.py resume` requires clean attached checkouts. `paired_review_runner.py` retains `post_exit_recovery` metadata and recovery card but exposes no supported resume. On current main, the old PF5 cycle-1 and cycle-2 re-review packets are both archived complete/passed; they are not a current live lock.
- Evidence: `custodian/tools/agent/{dispatch.py,workstream.py,workflow_control.py,run_trace.py,paired_review_runner.py}`; `custodian/tools/agent/test_{dispatch,workstream,paired_review_runner}.py`; `custodian/docs/ai_context/{AGENT_WORKSTREAM_LIFECYCLE.md,AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md}`; `custodian/docs/ai_context/BRANCH_ARCHIVE.md`.
- Task-specific authority: Proposed supervisor V1 spec; `dispatch.py` remains job board/lock authority, `workflow_control.py` owns assignment/claim/mutex, `workstream.py` owns checkout/finish, and `paired_review_runner.py` owns independent review; `AGENT_WORKSTREAM_LIFECYCLE.md` prohibits deletion on age and preserves original work.
- Work surface: NEW bounded `custodian/tools/agent/session_supervisor.py`, `custodian/tools/agent/workstream_recovery.py` and focused fixtures, validation manifest registration, narrowly scoped usage documentation. Consume existing dispatcher receipts, workstream traces and paired-review metadata through read-only interfaces. **Do not edit** existing `dispatch.py`, `workflow_control.py`, `workstream.py`, `paired_review_runner.py`, their production logic, or any currently claimed agent's worktree in OR1. All shared integration hooks and lease/lock mutations belong to OR2, which retains `agent-workflow`.
- Change:
  1. Inspect live main and existing runnable Codex and paired-review entrypoints. Introduce a lightweight supervised launch for *one already dispatched* workstream and observe exact parent/child process group, PID+OS starttime/boot ID, host, run token, worktree/branch/upstream SHA, packet and returned claim receipt. Do not re-implement `dispatch claim` and do not call `codex` without explicit user/CLI execution request.
  2. Record append-only redacted metadata in the Git common directory with local permission protection and atomic fsync-safe durable status updates; no prompts, credentials, chat transcripts, source contents or Git `main` writes. Integrate with existing `RunTrace` naming/owner rather than parallel huge logs. Ensure unique run IDs and cross-process fencing against reused PIDs.
  3. Observe process exit on normal return, SIGINT/SIGHUP/SIGTERM, sudden death, old boot, lost parent with live descendant, and explicit review-runner `post_exit_recovery` while keeping all original evidence. Heartbeat cannot expire a confirmed living process. A session launched outside supervision must be `UNMANAGED_UNKNOWN`; foreign host remains `FOREIGN_HOST_UNKNOWN`.
  4. Provide `workstream_recovery.py audit --json` with source-linked classifications and a concise human display: LIVE, EXITED_CONFIRMED, LANDED_PENDING_TEARDOWN, RECOVERABLE_CLEAN, RECOVERABLE_DIRTY, REVIEW_FINDINGS_OR_BLOCKED, UNMANAGED_UNKNOWN, FOREIGN_HOST_UNKNOWN, REMOTE_RACE_OR_AMBIGUOUS. Include exact remote/local SHA, dirty/untracked counts, journal/run IDs, affected lock, recommended safe action and named evidence gap.
  5. Record current `post_exit_recovery` and active local claim as recoverable blockers, **not** passing reviews. Never change the target or receipt. Emit planned conditional next steps for future OR2 lease integration, without claiming it is present.
  6. Add isolated temporary-repository/synthetic process tests including long-idle live Codex, PID reuse, host reboot, SIGKILL, background child survival, two concurrent supervisor claims, crash-before-journal, malformed/forged metadata, untracked user files and read-only side effects. Existing dispatcher, pairing, finish, and review exact-byte fixtures must keep passing.
- Preserve: All remote `agent/*` refs, `dispatch-claims/*`, current locking/claim semantics, active Codex/reviewer processes, clean/dirty/untracked attached worktrees, ignored persistent artist workspace, main, archive tags, original validation/traces, review receipt/pinning and no forced Git operations.
- Non-goals: Automated lock release, parking or claim theft, timer service, daemon, branch/worktree deletion, Git remote lease, approval/receipt fabrication, restoring active Codex sessions, new global queue or alternative dispatcher.
- Acceptance: (A) a running but silent process remains LIVE; (B) terminated run with matching boot/start/run identity is EXITED_CONFIRMED; (C) reused PID/foreign host/unmanaged/ambiguous descendent cannot be classified as safe; (D) every inventory classification cites source evidence and next action; (E) review `post_exit_recovery` remains nonpassing; (F) exactly zero worktree/source/branch/claim ref/status modifications in audit-only commands; (G) existing agent dispatch and independent paired review regressions remain green.
- Validation: Focused `python3 -m unittest` tests under `custodian/tools/agent` for new supervisor/audit plus `test_dispatch`, `test_workstream`, `test_paired_review_runner`; `python3 custodian/tools/agent/check_ai_context.py --json`, `python3 custodian/tools/agent/validate_review_pairing.py`, `python3 custodian/tools/agent/task_packet_index.py`, `python3 custodian/tools/validation/run_validation.py --changed --json`, `git diff --check`. Register any new script and avoid expensive project-wide Godot tests for tooling-only changes.
- Task overrides: none
- Deferred: Actual automatic safe parking/lease release/claim reclassification and opt-in user timer in OR2. Existing historical/unmanaged branches stay protected.

## Handoff

- Next workstream: review-agent-orphan-recovery-observability-v1
- Next packet state: ready/auto
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Next action: Independent test of live vs truly dead liveness and read-only preservation, then OR2.
- Blockers or open questions: No liveness policy decision blocks this read-only slice; current authoring chat is recorded in this packet.

## Cooperative-pause observability addition (2026-10-25)

Keep OR1 **read-only**. In addition to crash/exit observation, capture a deliberate `PAUSE_REQUESTED` event from a verified supervised agent or user shutdown, bound to its run nonce, exact parent/child start identity, boot, host and workstream. The event is *intent*, not exit proof and not a release of locks. Observe whether the whole process tree has actually stopped; a live/quiet Codex process, child process, tmux session, active review coordinator or unknown owner remains `LIVE` or `UNMANAGED_UNKNOWN`, never presumed parked. Emit `EXITED_CONFIRMED` only with genuine same-host evidence. Append durable idempotent before/after records outside the worktree and provide handoff data consumable by OR2 without giving OR1 lease or Git mutation authority.

Add focused tests for explicit pause followed by actual process exit, pause with a still-running descendant, Ctrl-C/terminal closure, interrupted journal writes, PID recycling, two wrappers for the same claimed workstream and external unmanaged Codex sessions. OR1 must not change any worktree byte, owner lease, dispatcher eligibility, packet state or `agent-workflow` occupancy. OR2 performs the eventual fence and park after independently accepted OR1 proof. The user wants default cooperative pause for future **supervised** sessions; no background timer is authorized by this decision.

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925

## OR1 independent bootstrap boundary (2026-10-25)

At confirmed `origin/main@bda39de1d68fa8f61f77e70ef7e696c6395d4f5d`, OR1 is not claimed, its PF5 cycle-2 reviewed dependency exists archived complete with a canonical `passed` receipt, and OR1/OR2 code does not exist. The current shared `agent-workflow` execution lock is held by historical claimed agent branches. **The independent OR1 observer requires no write access to that shared authority.** Its narrower `agent-session-observability` lock is legitimate only while OR1 remains additive and read-only with respect to the production dispatcher/runner/workstream/claim protocol. No weakening of existing held locks or launch through a claimed worktree is authorized.

Implement `session_supervisor.py` as an explicit optional wrapper for **future authorized, already-dispatched** sessions and `workstream_recovery.py audit` as a read-only evidence consumer; keep process/journal writes private to their own Git-common-dir records. Read existing paired-review run evidence and call existing claim/audit APIs read-only, but defer paired-review runner hook/injection, `dispatch.py` lock resolver changes, execution leases, `pause --apply`, actual `PARKED` writes, and all active-run mutations to OR2. New tests must prove no shared-source/Git-ref changes, no true owner inferred from remote branch age, and no mutation of the root or the dedicated Operator art worktree.

**Claim gate:** After this change lands, ask the live dispatcher whether the OR1 packet is eligible. An archived `Status: complete` dependency alone is insufficient without the canonical accepted review and queue validation. If it is not eligible, preserve the reason and correct the actual predicate instead of bypassing dispatch. OR2 still retains the broad `agent-workflow` lock and is not made claimable by this change.

**Separate incident:** The host-reported `operator-ranged-domain-extraction` is an uninstrumented `operator-runtime` holder; its remote branch diverges from `main` and has 3 unique commits. This packet does not park, edit, restore, or delete that owner's work, and may not rewrite the pinned failed renderer review.

## Completion Truth
- Completion schema: custodian.task_completion.v1
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: `session_supervisor.py` and `workstream_recovery.py` add explicit supervised liveness and a read-only recovery audit; 18 focused tests plus 351 existing dispatch/workstream/paired-review regressions passed; changed-file validation passed 15/15; read-only live audit preserved coordination and Operator art worktree status/refs and the root PNG SHA-256.
- Landed implementation: pending `workstream.py finish`.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: none; historical paired-review recovery metadata produces many conservative unresolved rows, as required when no canonical passing receipt is established.
- Root cause / contributing factors: historical claim and review metadata records do not prove current process ownership or successful review completion.
- Prevention / pipeline improvement: the observer binds local liveness to PID start ticks, boot and host identity, and leaves unverifiable review outcomes nonpassing.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: focused synthetic process tests and before/after root/art-worktree status, ref and hash comparisons.
