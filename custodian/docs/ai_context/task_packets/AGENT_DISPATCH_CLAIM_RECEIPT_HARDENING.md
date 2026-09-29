# AGENT DISPATCH CLAIM RECEIPT HARDENING

- Workstream: `agent-dispatch-claim-receipt-hardening`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-task-dispatch-review-corrections`
- Locks: `agent-workflow`
- Goal: Make a successful dispatcher claim unambiguous, machine-verifiable, recoverable after lost terminal output, and impossible for an agent to confuse with an unrelated already-attached worktree.
- Current measured state: On reviewed `main@791eb9a`, `dispatch.py` already performs safe fetched-`origin/main` selection, remote compare-and-set claim acquisition, claimed-workstream exclusion, workstream creation/resume through `workstream.py`, remote branch publication verification, and a single human-readable success banner. A Codex session nevertheless inferred ownership from visible worktree activity after failing to capture the claim command's result; `dispatch.py status` showed Baby Opossum READY and Twin Solaria CLAIMED, but the session entered the wrong already-owned worktree. No evidence indicates the dispatcher actually assigned the claimed Twin Solaria workstream.
- Task-specific authority: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, root/local `AGENTS.md`, archived `AGENT_TASK_DISPATCH*.md`, and current task-packet dispatcher conventions.
- Change: Add a deterministic structured claim receipt, durable Git-common-dir last-claim recovery, explicit created/resumed checkout disposition, post-start identity assertions, richer already-claimed diagnostics, and a short agent handshake rule requiring the returned claim identity to be verified before entering a worktree.
- Preserve: Existing remote claim refs, priority/dependency/lock selection, local mutex, fetched-`origin/main` packet truth, `workstream.py` checkout authority, one-task-per-claim behavior, no force/reset/stash policy, and `claim-next` behavior that skips already-claimed tasks rather than blocking the queue.
- Non-goals: No new scheduler, daemon, database, lease service, worktree ownership database, automatic task execution, change to task priority/dependency semantics, replacement of `workstream.py`, or rewrite of remote claim acquisition.
- Acceptance: Every successful claim emits and persists one authoritative receipt identifying the selected workstream/branch/worktree/packet, prior packet status, whether the checkout was created or resumed, and final verification state. Agents can recover the last claim after stdout loss. Explicit claims of already-claimed work show the canonical branch and attached local worktree when known. The dispatcher fails closed if the returned checkout identity does not match the selected workstream. Focused tests reproduce the reported confusion case and prove the correct Baby Opossum assignment despite an unrelated claimed Twin Solaria worktree.
- Task overrides: `none`
- Deferred: Cross-host liveness beyond existing Git refs; historical claim log beyond the single last successful local receipt; continuous workers; UI/dashboard presentation.

## Incident Contract

The reported failure mode was:

1. `dispatch.py status` showed:
   - `baby-opossum-runtime-hardening` READY;
   - Twin Solaria CLAIMED.
2. An already-existing Twin Solaria worktree was visible locally.
3. The agent ran `claim-next` but did not retain or inspect the command's completion output.
4. It inferred the assignment from worktree activity and entered the wrong checkout.

The correction must make this mistake hard to reproduce without changing the safe claim-selection architecture that is already working.

## Required Implementation

### 1. Structured successful-claim receipt

After all existing branch publication checks succeed, construct one canonical claim result object.

Required fields:

```json
{
  "schema": "custodian.dispatch.claim.v1",
  "result": "claimed",
  "workstream": "baby-opossum-runtime-hardening",
  "prior_status": "ready",
  "branch": "agent/baby-opossum-runtime-hardening",
  "worktree": "/absolute/path",
  "packet": "custodian/docs/ai_context/task_packets/BABY_OPOSSUM_RUNTIME_HARDENING.md",
  "checkout": "created",
  "verified": true,
  "agent": "codex"
}
```

`checkout` must be one of:

```text
created
resumed
```

Do not guess this from whether the directory happened to exist after the call. Extend/reuse `workstream.py` narrowly enough to return a trustworthy disposition while preserving its current CLI and callers.

Human output may remain concise, but it must derive from the same result object.

Emit one stable machine-readable sentinel after the human banner:

```text
CUSTODIAN_DISPATCH_RESULT_JSON:{...}
```

Use deterministic JSON key ordering where practical.

### 2. Durable local last-claim receipt

Persist the successful receipt under the Git common directory, not the repository worktree.

Preferred location:

```text
<git-common-dir>/custodian-dispatch/last-claim.json
```

Requirements:

- write only after the final claim verification succeeds;
- create parent directory if needed;
- atomic replace/write;
- never commit it;
- store only dispatcher/workstream metadata, not secrets;
- one latest successful local claim is sufficient for V1.

Add:

```bash
python3 custodian/tools/agent/dispatch.py last-claim
python3 custodian/tools/agent/dispatch.py last-claim --json
```

Human mode prints the same assignment fields and the exact `cd <worktree>` continuation.

If no receipt exists, return a clear nonzero/no-receipt result rather than inventing state.

A stale receipt is historical evidence only. `last-claim` should say whether its branch/worktree still appears current after a fetch/check; it must not silently mutate or re-claim anything.

### 3. Post-start identity verification

Before printing/persisting `CLAIMED`, verify all of:

1. returned worktree path exists;
2. its attached branch is exactly `agent/<selected.workstream>`;
3. fetched `origin/agent/<selected.workstream>` exists;
4. selected workstream is now recognized by dispatcher claimed-state logic.

If any check fails:

- do not write a successful receipt;
- do not print `CLAIMED`;
- fail closed with `dispatch: BLOCKED`;
- preserve uncertain recovery refs/worktree state for inspection.

Do not auto-delete or reset anything merely because verification failed.

### 4. Already-claimed diagnostics

Explicit:

```bash
dispatch.py claim <workstream-id> --agent codex
```

already refuses a claimed workstream. Improve the error/report so it includes, when known:

```text
ALREADY CLAIMED
workstream: <id>
branch: agent/<id>
worktree: <attached local path or not attached locally>
```

This is diagnostic only.

For `claim-next`, preserve current behavior: already-claimed tasks are excluded and the next eligible task may be selected. Do not let an already-claimed P0/P1 monopolize the queue.

### 5. Agent handshake rule

Add one compact rule to the active agent/workstream authority, preferably `AGENT_WORKSTREAM_LIFECYCLE.md` and only the shortest routing line needed in `custodian/AGENTS.md` if required:

```text
After claim/claim-next, the returned dispatch receipt is the assignment authority.
Never infer ownership from worktree creation, terminal activity, branch existence,
or another task being active. Before entering the checkout, verify the receipt's
workstream/branch/worktree; if stdout was lost, recover with dispatch.py last-claim.
```

Document the optional verification:

```bash
git -C <returned-worktree> branch --show-current
python3 custodian/tools/agent/dispatch.py status
```

The branch must equal `agent/<returned-workstream>`, and status must recognize that same ID as claimed.

Do not require agents to manually re-run these checks when the dispatcher already reports `verified: true`; the commands are recovery/debug proof, not normal duplicate ceremony.

## Focused Regression Coverage

Extend `custodian/tools/agent/test_dispatch.py` using temporary repositories/worktrees.

At minimum prove:

1. **Reported incident fixture**
   - unrelated Twin-like workstream already has a local attached worktree + remote canonical branch;
   - Baby-like task is READY and higher/next eligible;
   - `claim-next` selects Baby-like task;
   - receipt names only Baby-like workstream/worktree/packet.

2. **Structured result**
   - successful claim includes every V1 schema field;
   - sentinel JSON parses and matches human identity fields.

3. **Created disposition**
   - new workstream reports `checkout: created`.

4. **Resumed disposition**
   - canonical existing unclaimed/resumable workstream path reports `checkout: resumed` under whatever resume state the live workstream lifecycle legitimately supports.
   - Do not weaken claimed-state exclusion merely to manufacture this test.

5. **Durable recovery**
   - success writes `last-claim.json`;
   - `last-claim --json` reproduces selected identity;
   - no-receipt case is explicit/nonzero;
   - stale/missing checkout is reported as stale, not silently recreated.

6. **Already claimed explicit diagnostic**
   - error/report includes workstream, canonical branch, and local attached path when available.

7. **Post-start identity mismatch**
   - mock `workstream.start()` returning/attaching the wrong branch/path;
   - dispatcher fails closed;
   - no success receipt is written.

8. **Claim-next semantics preserved**
   - an already-claimed higher-priority task does not block a lower-priority eligible task.

Keep all existing concurrency, remote-claim, dependency, lock, coordination-checkout, malformed-metadata, and manual-dispatch tests green.

## Validation

Run focused first:

```bash
python3 custodian/tools/agent/test_dispatch.py
python3 custodian/tools/validation/agent_workflow_smoke.py
git diff --check
```

Run any current prompt/template or AI-context checks selected by the changed files.

Then run the repository's changed-unit closeout according to live AGENTS/workstream policy.

No Godot runtime sweep is required for this workflow-only correction.

## Documentation Drift

Reconcile only active workflow authority made stale by this implementation:

- `AGENT_WORKSTREAM_LIFECYCLE.md`;
- `task_packets/README.md` dispatch description if needed;
- `VALIDATION_RECIPES.md` if the new `last-claim` CLI belongs there;
- `FILE_INDEX.md` only if it indexes dispatcher command surfaces;
- `AGENT_AUTOMATION_BACKLOG.md` only if its dispatcher status description becomes false.

Do not rewrite archived dispatcher packets. They are historical evidence.

## Completion

Before normal finish:

- mark/archive this packet through current lifecycle;
- write `AGENT_DISPATCH_CLAIM_RECEIPT_HARDENING_CLAUDE_SUMMARY.md`;
- report the final receipt schema, receipt path, CLI recovery command, focused test count/results, changed-unit result, and any remaining intentionally deferred dispatch ergonomics.

## Handoff

- Next action: `python3 custodian/tools/agent/dispatch.py claim agent-dispatch-claim-receipt-hardening --agent codex`
- Best starting files: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Blockers or open questions: The packet intentionally shares `agent-workflow` lock with in-flight workflow work. Let the dispatcher serialize it rather than bypassing the lock.
