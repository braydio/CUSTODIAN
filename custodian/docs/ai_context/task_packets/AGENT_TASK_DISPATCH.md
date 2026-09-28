# AGENT TASK DISPATCH

- Workstream: `agent-task-dispatch`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Goal: Make `origin/main` the durable CUSTODIAN job board so a Codex terminal can claim the correct implementation packet without the user copying packet text, choosing a branch, or coordinating worktrees by hand.
- Current measured state: Task packets, stable workstream IDs, isolated `agent/<workstream-id>` worktrees, push-first checkpoints, serialized `land_main.py` landing, artifact finalization, and branch cleanup already exist. The missing seam is deterministic task discovery/claiming between a `ready` packet on `origin/main` and `workstream.py start <id>`.
- Task-specific authority: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/docs/ai_context/task_packets/README.md`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, and `custodian/tools/agent/workstream.py`.
- Change: Add a small repository-native dispatcher that reads packet state from fetched `origin/main`, chooses or explicitly claims one eligible workstream, starts/resumes the existing isolated workstream through `workstream.py`, and prints the exact assigned worktree/packet for the agent to execute.
- Preserve: Existing workstream branch identity, isolation, push-first recovery, finish/landing behavior, artifact preflight, no-force-push policy, packet archival rules, and human/developer authority over baseline acceptance.
- Non-goals: No daemon, web service, database, GitHub App, autonomous infinite worker loop, automatic second-job claim, packet execution engine, new landing system, replacement for `workstream.py`, replacement for task packets, or broad rewrite of the agent workflow.
- Acceptance: From any local Codex terminal, one repository command can safely claim the next eligible auto-dispatch packet, create/resume exactly one `agent/<workstream-id>` worktree, and report the packet path. Two local terminals cannot claim the same task. Manual packets are never auto-claimed. Unmet dependencies and conflicting locks prevent claims with explicit reasons. The dispatcher works from fetched `origin/main` even when the coordination checkout itself has not been pulled.
- Task overrides: `none`
- Deferred: Continuous worker mode; remote multi-host lease service; generated replacement for the manually maintained task-packet README inventory; automatic packet generation from design docs.

## Ownership And Timing

- Owner: agent workflow
- Agent/session: Codex bootstrap
- Created: 2026-09-28
- Last updated: 2026-09-28

## Required Packet Metadata Contract

Extend the active task-packet convention with these optional dispatch fields:

```text
- Dispatch: `auto` | `manual`
- Priority: `P0` | `P1` | `P2` | `P3`
- Depends on: `none` or comma-separated workstream IDs
- Locks: `none` or comma-separated narrow lock IDs
```

Rules:

1. Missing `Dispatch` means **manual**. Existing historical packets must never become runnable merely because the dispatcher is installed.
2. `claim-next` considers only packets with:
   - `Status: ready`
   - `Dispatch: auto`
   - a valid lowercase-kebab `Workstream`
   - all declared dependencies complete
   - no active claim for the same workstream
   - no lock conflict with another claimed workstream.
3. `Priority` defaults to `P2` when omitted. Lower number is higher priority.
4. Stable tie-breaker for equal priority must be deterministic, preferably packet repository path lexicographic order. Do not depend on filesystem enumeration order.
5. `Depends on: none` means no dependency. A dependency is complete only when `origin/main` contains an archived packet with the matching `Workstream` and `Status: complete`.
6. `Locks` represent narrow contentious ownership, not broad domains. Examples: `asset-catalog`, `level-registry`, `agent-workflow`. Do not introduce giant locks such as `runtime` or `docs`.
7. The dispatcher does not mutate the packet on `main` when claiming it. The existing task workstream owns normal packet progression to `in_progress`, `complete`, archive, and landing.

## Work Surface

Primary implementation:

- `custodian/tools/agent/dispatch.py`
- focused tests under `custodian/tools/agent/`
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`
- `custodian/docs/ai_context/task_packets/README.md`
- `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`
- `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `AGENTS.md` and/or `custodian/AGENTS.md` only where a short routing rule is needed
- `custodian/tools/validation/validation_manifest.json` if the focused dispatcher tests belong in the normal changed-file selection

Use the existing `workstream.py` API/authority. If a small extraction makes programmatic reuse cleaner, keep `workstream.py` behavior and CLI compatibility intact.

## Command Contract

Implement these V1 commands:

```bash
python3 custodian/tools/agent/dispatch.py status
python3 custodian/tools/agent/dispatch.py claim-next --agent codex
python3 custodian/tools/agent/dispatch.py claim <workstream-id> --agent codex
```

`--agent` is descriptive output/session context only in V1. Do not create a second persistent identity database.

### `status`

Fetch/prune origin, read active packet metadata from **`origin/main`**, inspect local worktrees and fetched remote `origin/agent/*` refs, and print a compact deterministic queue grouped by:

- `READY`
- `CLAIMED`
- `BLOCKED`
- `MANUAL`

For blocked tasks, state the concrete reason:

```text
dependency: twin-solaria-runtime-v1
lock: asset-catalog held by <workstream>
already claimed
invalid packet metadata
```

Status is read-only.

### `claim-next`

1. Fetch/prune `origin`.
2. Acquire a **local process mutex** covering selection through successful `workstream.start()`. Prefer a repository-local lock using `fcntl.flock` on Linux. Do not commit lock files.
3. Read candidate packet content directly from `origin/main`; do not depend on the coordination checkout being current.
4. Resolve dependencies, existing claims, and active lock conflicts.
5. Sort eligible jobs deterministically by priority then stable packet path.
6. Select exactly one job.
7. Call/reuse the existing `workstream.py start <workstream-id>` behavior rather than reimplementing branch/worktree policy.
8. Because `workstream.py start` pushes the canonical `agent/<id>` branch immediately, that remote branch becomes the durable claim visible to later dispatches.
9. Print the exact workstream, branch, worktree path, and packet path from the claimed worktree.
10. Stop. Do not run the implementation packet or claim another job.

Expected human-facing result:

```text
CLAIMED
workstream: twin-solaria-runtime-v1
branch: agent/twin-solaria-runtime-v1
worktree: /.../.custodian-worktrees/twin-solaria-runtime-v1-...
packet: custodian/docs/ai_context/task_packets/TWIN_SOLARIA_RUNTIME_V1.md

NEXT:
cd <worktree>
Read AGENTS.md, custodian/AGENTS.md, then <packet>.
Implement only this workstream and finish through workstream.py.
```

If no task is eligible, return success with a clear `NO ELIGIBLE AUTO TASK` summary and reasons/counts. Do not guess a task.

### `claim <workstream-id>`

Explicitly claim the named packet, including `Dispatch: manual` packets.

Still require:

- packet exists on `origin/main`;
- valid workstream identity;
- `Status: ready`;
- dependencies satisfied;
- no existing claim;
- no conflicting lock.

Do not add a V1 `--force` bypass.

## Packet Discovery

Do not require `git pull`.

A suitable implementation is to enumerate active packet paths from the fetched `origin/main` tree and read each candidate with Git plumbing such as `git show origin/main:<path>`.

Discovery scope:

```text
custodian/docs/ai_context/task_packets/*.md
```

Exclude:

- `task_packets/README.md`
- `task_packets/archived/**`
- templates or non-packet support files if any exist.

Dependency resolution may inspect archived packets on `origin/main`.

Do not parse the manually maintained README index as task truth.

## Claim And Lock Semantics

### Existing claim

A workstream counts as claimed if either:

- fetched `origin/agent/<workstream-id>` exists; or
- a local attached worktree is already on `agent/<workstream-id>`.

This keeps recovery branches authoritative and prevents duplicate local work.

### Lock conflict

For each currently claimed `agent/<id>` that corresponds to a packet on `origin/main`, collect that packet's declared locks.

A ready packet conflicts when its non-`none` lock set intersects the lock set of a claimed packet.

Fail closed for a malformed lock declaration on an auto-dispatch packet. Do not infer broad ownership from changed files.

### Concurrency

The target operating environment is multiple Codex terminals on the same development machine.

The local mutex must make this safe:

```text
terminal A: claim-next -> task A
terminal B: claim-next -> task B
```

not:

```text
terminal A: selects task A
terminal B: selects task A
```

Remote branch publication remains the durable claim after the local mutex is released.

A true cross-machine race may fail at remote branch publication. V1 should fail safely and report the retained worktree/branch state rather than reset, force-push, or delete uncertain work. Do not build a distributed lease service in this task.

## Repository Routing Rule

After the dispatcher exists, add a short inherited routing rule so a user can tell any Codex terminal:

> Take the next CUSTODIAN task.

The repository instruction should direct the agent to run:

```bash
python3 custodian/tools/agent/dispatch.py claim-next --agent codex
```

Then enter the returned worktree, read the returned packet, and execute only that workstream.

Also document explicit selection:

> Take CUSTODIAN workstream `<id>`.

which maps to:

```bash
python3 custodian/tools/agent/dispatch.py claim <id> --agent codex
```

Do not add large duplicated workflow prose to `AGENTS.md`; link to the lifecycle authority.

## Tests

Add focused temporary-repository tests for at least:

1. missing `Dispatch` is manual and never auto-claimed;
2. `Dispatch: manual` skipped by `claim-next`;
3. `Dispatch: auto` + `Status: ready` is eligible;
4. non-`ready` packets are not eligible;
5. P0 sorts before P1/P2/P3;
6. equal-priority ordering is deterministic;
7. dependency blocks until an archived complete matching workstream exists on `origin/main`;
8. incomplete/active matching dependency does not satisfy it;
9. remote `origin/agent/<id>` excludes duplicate claim;
10. local attached `agent/<id>` excludes duplicate claim;
11. lock collision blocks the second task and identifies the holder;
12. disjoint locks permit parallel claims;
13. stale local `main` does not hide a newer packet already present on `origin/main`;
14. two concurrent local claim attempts cannot select the same workstream;
15. explicit `claim <id>` may claim a manual packet but still respects dependencies/locks;
16. malformed dispatch metadata fails closed for auto-dispatch and is visible in `status`;
17. no eligible task is a clean non-destructive result;
18. the dispatcher delegates worktree creation/resume to existing workstream lifecycle semantics rather than creating a parallel branch policy.

Tests must use temporary repositories/worktrees and must not touch the developer's live branches.

Register the focused test in the validation manifest if that is consistent with current agent-tooling tests.

## Documentation And Drift Remediation

As part of implementation:

1. Update `AGENT_TASK_PACKET_TEMPLATE.md` with the dispatch metadata and safe defaults.
2. Update `task_packets/README.md` to document auto/manual dispatch behavior.
3. Update `AGENT_WORKSTREAM_LIFECYCLE.md` so dispatch is the preferred front door when a packet is queued, while direct `workstream.py start <id>` remains valid.
4. Update `AGENT_AUTOMATION_BACKLOG.md` to mark the dispatcher implemented and retain genuinely deferred automation.
5. Update `VALIDATION_RECIPES.md` with the focused dispatcher test command.
6. Update `FILE_INDEX.md` for the new CLI/test ownership.
7. Update `CURRENT_STATE.md` only if it currently describes agent execution in a way made stale by this change.
8. Keep the existing manually maintained packet README inventory for V1 unless removing/generating it is genuinely required. A derived/generated queue view is deferred; `dispatch.py status` is the live truth.

## Acceptance Walkthrough

Before closeout, demonstrate in a temporary repository or safe fixture:

### A. Auto dispatch

```text
TASK_A: ready / auto / P0
TASK_B: ready / auto / P1
```

First claim returns A.

Second claim returns B.

### B. Manual safety

```text
TASK_MANUAL: ready / manual / P0
```

`claim-next` does not select it.

`claim task-manual` does.

### C. Dependency

```text
B depends on A
```

B is blocked before A has a complete archived packet on `origin/main`.

B becomes eligible after that completion exists.

### D. Lock

```text
A locks asset-catalog
B locks asset-catalog
C locks level-registry
```

With A claimed:

- B is blocked;
- C remains eligible.

### E. Stale coordination checkout

Put a ready packet on remote `main` while local `main` remains behind.

`dispatch.py status` and `claim-next` must still see the remote packet after fetch.

## Completion

Use the normal `agent-task-dispatch` workstream lifecycle.

Before `workstream.py finish`:

- change this packet to `Status: complete`;
- add concise completion/deferred notes;
- move it to `task_packets/archived/AGENT_TASK_DISPATCH.md`;
- remove its active README entry;
- commit the required root closing summary;
- provide the green focused validation JSON required by the existing lifecycle.

Completion report should state only:

- dispatcher commands implemented;
- packet metadata contract;
- concurrency/claim mechanism;
- focused tests and result;
- changed validation result;
- any deferred cross-machine or continuous-worker work;
- landed main SHA.

## Handoff

- Next action: Codex should manually start `agent-task-dispatch` once, implement this packet, validate, and land it. After that, future queued implementation packets should be written to `main` with `Dispatch: auto` when safe.
- Best starting files: `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `custodian/docs/ai_context/task_packets/README.md`.
- Blockers or open questions: None. Keep V1 local-machine safe and repository-native; distributed leasing and continuous workers are explicitly deferred.
