# AGENT ORPHAN RECOVERY OBSERVABILITY V1 (OR1)

- Packet schema: custodian.task_packet.v2
- Workstream: agent-orphan-recovery-observability-v1
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: review-agent-paired-review-coordinator-boundary-v1-review-corrections-2
- Locks: agent-workflow
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-orphan-recovery-observability-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: supervised execution liveness, Git worktree provenance and review-runner integration require independent falsification
- Reviewed main: 316c984cbb62cc067ab7fc8483994f02573d6f8b
- Authoring chat: not-recorded
- Visual review: none
- Goal: Reliably distinguish a live Codex/review execution from a terminated, recoverable or ambiguous CUSTODIAN workstream, without destroying work or weakening current dispatcher locks.
- Completion boundary: Provide one verified subprocess-supervision journal and read-only deterministic orphan inventory, integrating existing dispatcher claim receipts, workstream traces and paired-review runner's supervised child. **No** automatic parking, claim release, remote lease mutation, archive or packet lifecycle status change in OR1.
- Current measured state: `dispatch.py audit --json` classifies remote agent branches, attached worktrees, dirty state and remote claim refs, but does not prove OS execution ownership. `dispatch.py` counts each remote `agent/<id>` branch as a live claimed workstream for packet `Locks:`. `dispatch-claims/<id>` is an assignment-time create-only claim, not a renewed session lease. `workstream.py resume` requires clean attached checkouts. `paired_review_runner.py` retains `post_exit_recovery` metadata and recovery card but exposes no supported resume. On current main, the old PF5 cycle-1 and cycle-2 re-review packets are both archived complete/passed; they are not a current live lock.
- Evidence: `custodian/tools/agent/{dispatch.py,workstream.py,workflow_control.py,run_trace.py,paired_review_runner.py}`; `custodian/tools/agent/test_{dispatch,workstream,paired_review_runner}.py`; `custodian/docs/ai_context/{AGENT_WORKSTREAM_LIFECYCLE.md,AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md}`; `custodian/docs/ai_context/BRANCH_ARCHIVE.md`.
- Task-specific authority: Proposed supervisor V1 spec; `dispatch.py` remains job board/lock authority, `workflow_control.py` owns assignment/claim/mutex, `workstream.py` owns checkout/finish, and `paired_review_runner.py` owns independent review; `AGENT_WORKSTREAM_LIFECYCLE.md` prohibits deletion on age and preserves original work.
- Work surface: bounded `custodian/tools/agent/session_supervisor.py` and `workstream_recovery.py` (names adaptable if existing owner fits better); minimal `paired_review_runner.py` invocation hook and `dispatch.py` receipt/event integration, focused process/claim tests, registration in `custodian/tools/validation/validation_manifest.json` or exact live manifest location; lifecycle guide/read-only command.
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
- Authoring chat: not-recorded
- Next action: Independent test of live vs truly dead liveness and read-only preservation, then OR2.
- Blockers or open questions: No liveness policy decision blocking this read-only slice; exact current chat URL not supplied and must not be inferred.
