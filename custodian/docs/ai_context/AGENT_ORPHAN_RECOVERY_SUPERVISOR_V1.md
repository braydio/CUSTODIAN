# CUSTODIAN Workstream Orphan Recovery Supervisor V1

**Status:** design-approved direction; implementation not yet landed.  
**Date:** 2026-10-11. **Investigated main:** `316c984cbb62cc067ab7fc8483994f02573d6f8b`.  
**Authoring chat:** `not-recorded` (request exact current ChatGPT conversation URL before future handoff relinking).  
**Implementing workstreams:** `agent-orphan-recovery-observability-v1`, then `agent-orphan-recovery-fenced-parking-v1`, each with an independent paired review.

## The problem and existing ownership

`custodian/tools/agent/dispatch.py` currently treats published `origin/agent/<workstream>` branches as **active claims**, using branch existence for logical `Locks:` conflicts. The create-only `dispatch-claims/<id>` ref is a short-lived *assignment* mutex, not a renewable execution lease. Thus closing a Codex terminal may leave a legitimate recovery branch/worktree and simultaneously strand unrelated work behind its logical lock. `dispatch.py audit --json` already reports packet/branch/worktree/claim dispositions, `workstream.py resume` handles clean existing worktrees, and `branch_hygiene.py` can retire approved exact-SHA stale refs. None currently proves which *process* is alive or safely releases execution ownership while preserving a dirty working tree. `paired_review_runner.py` records `post_exit_recovery` and retains evidence but has no supported resume/reconcile command.

The original PF5 cycle-1 and cycle-2 correction review packets are **both now archived complete with passing receipts** on main at the investigated revision. Do not represent their old lock incident as currently active. Their earlier incident still motivates general recovery resilience. An archived complete packet is not automatically evidence that arbitrary later unfinished tasks are safe to abandon.

**Decision:** Make the lifetime of **execution ownership** independent of the lifetime of the **preserved work branch**. A process exit should create a recoverable parked workstream rather than silently discarding work or holding all unrelated locks forever.

## Trust model and two-slice implementation

### Slice OR1: supervised session and read-only diagnosis

- Introduce one bounded `session_supervisor.py` / `workstream_recovery.py audit` under `custodian/tools/agent/`, reusing `workflow_control.py`, existing trace, dispatcher audit, and actual subprocess identities. No second dispatcher or stateful agent.
- Support explicit supervised launch of **one** Codex CLI implementation session and integration with `paired_review_runner.py`'s already supervised subprocess. Do not presume an arbitrary Codex session launched outside the wrapper is tracked; label it `UNMANAGED_UNKNOWN`. The wrapper is launched *after* an exact verified dispatcher receipt, never substitutes for remote claim creation.
- Persist a redacted, append-only, locally protected ownership journal outside worktrees under the Git common directory. Record exact workstream, run ID/nonce, branch, worktree path, claimed packet/ref and immutable SHA, host/boot identity, parent/child process group, OS process start identity (prevents PID reuse), start/last heartbeat/exit, and integration with `run_trace.py`. Do not log prompts, chats, credential values, stdout, or repository contents.
- Heartbeat only while verified supervision holds a live process/descendant; graceful normal exit, SIGINT/SIGHUP/SIGTERM, process crash, daemon restart, reboot, and PID reuse have deterministic classifications. Monotonic local liveness + boot ID outweigh wall-clock age. A quiet **living** Codex process is still `LIVE`; stale timestamps by themselves never establish death. Repeated durable observations after a safety/grace interval should be used to distinguish a clean exit from uncertainty.
- Read-only `audit --json` returns: `LIVE`, `EXITED_CONFIRMED`, `LANDED_PENDING_TEARDOWN`, `RECOVERABLE_CLEAN`, `RECOVERABLE_DIRTY`, `UNMANAGED_UNKNOWN`, `FOREIGN_HOST_UNKNOWN`, `REVIEW_FINDINGS_OR_BLOCKED`, `REMOTE_RACE_OR_AMBIGUOUS`. Include the exact evidence and suggested next safe command for every row. No automatic ref deletion, `git clean/reset/stash`, receipt publication, packet status edit or lock reassignment in OR1.
- Provide optional lightweight process-exit hook; no polling daemon or global timer required in OR1. A future `systemd --user` timer is optional and must stay host-local.

### Slice OR2: exact-owner fenced recovery and safe parking

- Add **one purpose-specific, remotely visible execution-owner lease/ref**, separate from the existing create-only `dispatch-claims/<id>` assignment claim, canonical `agent/<id>` work branch, and diagnostic refs. Store owner run token, host, scope and expected branch head in its small metadata commit. All mutations of this lease ref are compare-and-swap against its **exact expected object ID**; Git ref update is permitted for this lease ref only, never a force-push to an implementation branch or main. Verify remote response/readback and stop closed on token/head mismatch, unreachable remote, competing owner or unknown host. Preserve current initial-claim cross-clone atomicity.
- Integrate lease acquisition/renewal/release at the existing dispatch/workstream runner boundary and logical-lock eligibility, not by introducing another scheduler/dispatcher. **Legacy branches with no recognized supported lease remain protected as claimed**, not auto-retrofitted. A remote branch with a recognized, independently verified `PARKED` owner state can stop holding unrelated logical locks while continuing to block duplicate claims for its own workstream. A different host's stale heartbeat alone is never permission to steal its lease.
- On exact-supervised session exit, stage an idempotent two-phase recovery: (1) **fence** the terminated run and verify original claim/worktree/remote SHA and no live process or related subprocess (including tmux descendants); (2) classify and preserve all recoverable bytes/commits, then publish `PARKED` ownership and release only its *execution* lock. Capture a local checksummed recovery manifest and exact tracked/untracked file inventory with secure local content snapshot when needed. Respect size/privacy/ignored-art boundaries: if durable preservation cannot be proven, keep `NEEDS_REVIEW` and preserve the lock/worktree. Never copy private `.env`, ignored persistent artist workspace, credentials, or arbitrary large binaries to public Git or diagnostics. A clean empty claim can be made same-ID claimable only after exact remote/local branch and packet proofs plus fenced teardown; any unique commits, dirty files or live reviewer evidence must remain attached/parked, **not discarded**.
- `workstream.py recover <workstream-id> --plan/--apply` (or an equivalently narrow subcommand) and `paired_review_runner.py recover <id>` must consume preserved run IDs, not create duplicate claims. Recovery is deterministic and idempotent on repeated invocations, supports graceful exit hooks and optional host-local `systemd --user` service/timer (on exit, at shell start, and periodic check). A timer must only mutate **confirmed same-host terminated sessions with exact-token fencing**; `UNKNOWN` stays nonmutating. Require opt-in for the timer and provide one-command uninstall; no perpetual AI worker.
- Recoveries after partial finish/land must use existing `workstream.py preflight/finish` gates, summary, green validation and reachability evidence. A process closing while code is unvalidated is not a successful implementation. No automated Git landing just because a process died. Preserve `BRANCH_ARCHIVE.md` and `branch_hygiene.py` exact-SHA archive-first retirement rules.
- An independent review with genuine `findings` / `human_required` is **concluded but not accepted**: allow a separately verified truthful findings-only closeout/park contract, never create a synthetic `passed` target receipt, never mark its implementation accepted and never satisfy downstream accepted-review dependencies merely by releasing the execution lease. Coordinate with the existing PF5 `review_receipt_delta.py` verifier and `paired_review_runner.py`. If a full findings-only lifecycle requires a separate migration of dispatcher dependency semantics, **fail closed and emit a bounded correction packet** rather than weaken the receipt requirement. Do not rewrite past reviewed target bytes.

## Recovery decision table

| Observed state | Automatic action | Protected property |
| --- | --- | --- |
| Matching live process/start/boot + valid lease | None, keep `LIVE` | Quiet but active agents never evicted |
| Verified owner exit, clean checkout, unique branch commits | `PARKED` after exact Git SHA/ref/owner proof | Commits survive on `agent/<id>`, cannot duplicate-claim |
| Verified owner exit, dirty tracked/untracked checkout | Snapshot/inventory locally and `PARKED` **only if durable preservation succeeds**; otherwise `NEEDS_REVIEW` | Original dirty worktree never reset, removed or stashed |
| Verified complete archive + actual landed HEAD, clean checkout | Resume existing idempotent finish/teardown only with normal validation/provenance evidence | No fake completion; skip re-merge |
| Empty never-started assignment, verified sole owner terminated | Exact SHA-fenced claim reconciliation then safely release for new dispatch | No duplicate claims and no overwritten branch |
| Reviewer finding or `post_exit_recovery` | Preserve findings; recover existing run; truthful nonpassing park/closeout only via an authorized review outcome path | No fabricated passed receipt or downstream release |
| Foreign host, PID reused, untracked supervisor, missing remote, changed lease HEAD, unknown artifact bytes | `NEEDS_REVIEW`, no mutation | Never reclaim on inactivity/age alone |

## Operator ergonomics

Normal usage should be `custodian-next` or a project `cagent` wrapper that launches a supervised single-pair Codex session. It captures the verified dispatcher workstream and invokes the reviewer under its separate fresh-context coordinator. On a terminal close, the wrapper exits and the host-local supervisor parks the run. On the next invocation, show the user's **same** recoverable workstream first and resume its existing worktree/branch after an exact ownership check; never auto-start another unrelated packet.

Proposed compact commands (implementation interface, not existing CLI):

```bash
python3 custodian/tools/agent/workstream_recovery.py audit --json
python3 custodian/tools/agent/workstream_recovery.py recover <workstream-id> --plan
python3 custodian/tools/agent/workstream_recovery.py recover <workstream-id> --apply
python3 custodian/tools/agent/session_supervisor.py run <workstream-id> -- codex exec ...
```

Example useful UI line: `ORPHANED 2 | AUTO-PARKED 1 | NEEDS_REVIEW 1 | BLOCKED-BY-LEASE 0`, with exact workstream, current host/owner, branch, dirty/untracked count, last event, recommendation and provenance paths.

## Safety and measurable outcomes

Never auto-delete a worktree, unique branch, source art, ignored `.ai` artist data, recovery snapshot or diagnostic run evidence; never fake receipts; never treat branch age or expired heartbeat as conclusive death; never start Codex/review work without an actual dispatch-accepted claim or supported resume; never acquire/releases locks outside existing cross-clone serialization. Fail closed on unreachable Git remote, clean-but-unique history, active child process, ambiguous host, dirty backup failure, changed expected ref, and concurrent sessions. Tests must use isolated temporary Git repositories/remotes and process fixtures, not the live user's dirty worktrees.

OR1 independent review proves read-only inventory accuracy and complete negative controls. OR2 independent review proves simulated 2-host races, genuine live vs stopped process, owner-token fencing, interrupted recovery at each stage, dirty/clean/unique history, idempotent `PARKED` re-entry, review findings not equal PASS, and original dispatcher/finish preservation. Ship an opt-in no-delete/release dry run before enabling an automatic exit hook or user timer.

## Current documentation drift

- `AGENT_AUTOMATION_BACKLOG.md` previously explicitly deferred execution leases and continuous workers. This plan **proposes leases without a continuous worker**; do not state they are implemented until OR2 has passed review.
- `AGENT_WORKSTREAM_LIFECYCLE.md` currently supports `resume` for clean checkouts only; dirty/uncommitted resumptions are not yet a supported automated path.
- `dispatch.py` claims are branch-derived; `paired_review_runner.py`'s `post_exit_recovery` is a protective hold with no `recover` command.
- Earlier PF5 review documentation describing the R1 fixes as unreviewed is stale as of investigated main: both cycle-1 and cycle-2 reviewed packets now exist as archived `Status: complete`. Do not remove historical findings from the original receipts.
