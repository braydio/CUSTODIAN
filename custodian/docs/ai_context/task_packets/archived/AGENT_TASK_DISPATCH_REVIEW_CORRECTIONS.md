# AGENT TASK DISPATCH REVIEW CORRECTIONS

- Workstream: `agent-task-dispatch-review-corrections`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-task-dispatch`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `none`
- Goal: Harden the live repository task dispatcher where second-pass review found one real concurrency hole, one coordination-path proof gap, and closeout documentation drift before the independent-review pipeline builds on top of it.
- Current measured state: `dispatch.py` now has 28 temporary-repository tests covering independent-clone remote claim races, interrupted-claim recovery, cleanup failure, and attached coordination-worktree dispatch, in addition to prior selection and locking contracts.
- Task-specific authority: archived `custodian/docs/ai_context/task_packets/archived/AGENT_TASK_DISPATCH.md`, `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, and root/local AGENTS workflow rules.
- Change: Add a repository-native exclusive remote claim primitive that prevents two separate clones/Git common directories from both successfully claiming the same workstream; add missing coordination-checkout coverage; repair dispatcher closeout docs drift. Preserve the existing CLI and one-task-per-claim workflow.
- Preserve: Same-machine local mutex, fetched-`origin/main` packet truth, manual-by-default dispatch, priority/path ordering, archived-complete dependency semantics, narrow lock semantics, `workstream.py` branch/worktree authority, no force-push/reset/stash behavior, and safe retention of uncertain recovery state.
- Non-goals: No distributed lease service, daemon, database, GitHub App, continuous worker loop, reviewer pipeline implementation, broad workstream rewrite, automatic stale-claim age deletion, or change to task priority/dependency policy.
- Acceptance: Two independent clones racing to claim one ready auto task cannot both succeed. Exactly one acquires the remote claim and starts/publishes the workstream; the other fails closed or observes it claimed. Dispatch from a non-main attached worktree still resolves the coordination checkout correctly. Dispatcher docs/indexes point to the archived bootstrap record and live tooling rather than a nonexistent active packet.
- Task overrides: `none`
- Deferred: Cross-host liveness/lease expiry, stale remote-claim automatic recovery, continuous workers, and the review pipeline itself.

## Findings To Correct

### F1 — HIGH: remote branch publication is not exclusive across clones

The live dispatcher serializes claims with:

```text
<git-common-dir>/custodian-dispatch.lock
```

This correctly protects multiple terminals sharing one repository/common directory.

It then relies on publication of:

```text
origin/agent/<workstream-id>
```

as the durable claim.

However, two independent clones can both:

1. fetch the same `origin/main`;
2. see no `origin/agent/<id>`;
3. create local `agent/<id>` at the same base OID;
4. push that same OID.

The first push creates the remote branch. The second push may also succeed as an
up-to-date push because it proposes the same object ID.

Therefore remote branch existence alone does **not** make initial claim acquisition
exclusive across separate Git common directories.

The original bootstrap packet deferred a distributed lease service, but it also
required cross-machine races to fail safely. Fix this without introducing a
service.

### Required behavioral contract

Introduce the smallest Git-native remote compare-and-set/create-only claim step
before `workstream.py start`.

Requirements:

- claim acquisition uses a remote ref whose proposed value is unique per claimant,
  so simultaneous creation attempts cannot both be accepted;
- normal Git push semantics must reject the losing claimant;
- never use `--force`, `--force-with-lease`, reset, or destructive ref rewrite;
- after the canonical `origin/agent/<id>` workstream branch is confirmed published,
  the temporary claim ref may be removed through a normal explicit delete;
- if the process dies after acquiring the temporary claim but before publishing the
  workstream branch, the ref must remain visible and cause future dispatch attempts
  to fail closed with recovery instructions;
- do not automatically age-delete an unresolved remote claim in V1;
- status output must make the recovery state legible.

A reasonable implementation is a temporary fixed remote ref per workstream backed by
a unique commit/tag object, for example conceptually:

```text
refs/heads/dispatch-claims/<workstream-id>
```

The unique object should have the fetched `origin/main` tree/parent and claimant
metadata only. Two contenders then propose different OIDs to the same absent ref:
one normal create succeeds, the other normal push is rejected.

This is an implementation suggestion, not a mandate. Use a cleaner Git-native
create-only primitive if available, while preserving the no-force/no-service
contract.

Do **not** leave meaningless claim commits in the eventual `agent/<id>` history
or land them to `main` merely to solve exclusivity.

### Recovery semantics

Distinguish:

```text
temporary remote claim exists + agent branch exists
    -> task is claimed; temporary ref may be cleaned up

temporary remote claim exists + agent branch absent
    -> claim acquisition was interrupted; BLOCKED/RECOVERY REQUIRED

agent branch exists + temporary claim absent
    -> normal claimed workstream
```

Provide an explicit, non-destructive recovery instruction. Do not silently delete
the claim.

### F2 — MEDIUM: coordination checkout path is not covered

Live `dispatch.py` contains `_coordination_repo()` so invoking the dispatcher from
an attached task worktree can find the persistent main checkout and create/resume
sibling task worktrees from the intended coordination surface.

The current focused suite does not exercise this path.

Add a real temporary-repository test that:

1. creates the persistent main checkout;
2. attaches a different `agent/existing-task` worktree;
3. invokes dispatcher status/claim from that non-main worktree;
4. proves packet truth still comes from fetched `origin/main`;
5. proves the newly claimed worktree is created through the shared coordination
   repository/common worktree pool;
6. proves existing-task files/branch are untouched.

This is an evidence gap rather than a confirmed runtime failure. Do not refactor the
helper unless the test exposes a defect.

### F3 — LOW: dispatcher closeout documentation drift

Current main still contains stale dispatcher references:

- `custodian/docs/ai_context/FILE_INDEX.md` points to
  `task_packets/AGENT_TASK_DISPATCH.md` and calls it a ready bootstrap packet,
  but the packet is now archived at
  `task_packets/archived/AGENT_TASK_DISPATCH.md`.
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` says:
  "A ready implementation packet now exists at
  `custodian/docs/ai_context/task_packets/AGENT_TASK_DISPATCH.md`"
  under an "Implemented" heading.

Correct those to current truth:

- archived packet = historical implementation/acceptance record;
- `custodian/tools/agent/dispatch.py` = live authority/tool;
- dispatcher is implemented;
- review pipeline is the next queued bootstrap stage.

Search for equivalent stale active-path claims and fix only genuine dispatcher
closeout drift.

## Work Surface

Expected primary files:

- `custodian/tools/agent/dispatch.py`
- `custodian/tools/agent/test_dispatch.py`
- `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` only if remote-claim
  recovery behavior changes the documented lifecycle
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` only if the focused command
  changes
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`
- validation-manifest ownership only if needed

Avoid changes to `workstream.py` unless a narrow reusable helper is genuinely the
cleanest way to keep branch publication authority single-sourced.

## Focused Tests

Preserve all existing dispatcher tests and add coverage for at least:

1. two independent clones concurrently attempt to claim the same ready task;
2. exactly one obtains the exclusive remote claim;
3. loser does not create/publish a second active implementation worktree;
4. interrupted remote claim without `agent/<id>` fails closed and is visible in
   `status`;
5. remote claim + published agent branch is recognized as claimed;
6. temporary claim cleanup after successful branch publication is safe;
7. cleanup failure does not make the already published workstream claim disappear;
8. dispatcher invoked from an attached non-main task worktree resolves the
   coordination checkout and shared pool correctly;
9. existing 23 dispatcher tests remain green;
10. workstream/landing tests remain green.

Use separate temporary clones against one bare remote for the exclusivity test. A
same-process/thread test sharing one common directory is not sufficient to prove F1.

## Validation

Run:

```bash
python3 custodian/tools/agent/test_dispatch.py
```

plus the existing focused agent workflow contract and the current changed-file
closeout recipe.

Also run:

```bash
python3 -m py_compile   custodian/tools/agent/dispatch.py   custodian/tools/agent/test_dispatch.py

git diff --check
```

If the unrelated lattice canon validation failure from the bootstrap summary still
exists on current main, report it accurately; do not edit unrelated lore in this
workstream.

## Completion

Before normal `workstream.py finish`:

- mark this packet complete and archive it;
- remove it from the active packet README;
- update dispatcher docs/index truth;
- commit the required closing summary;
- provide green focused validation JSON.

This workstream does not require independent review yet because
`agent-review-pipeline` is intentionally blocked behind it and is the next bootstrap
stage.

## Handoff

- Next action: auto-dispatch this correction before `agent-review-pipeline`.
- Best starting files: `dispatch.py`, `test_dispatch.py`, archived
  `AGENT_TASK_DISPATCH.md`.
- Blockers or open questions: None. Keep the correction repository-native and small;
  do not expand it into distributed leasing.

## Completion Notes

- Added a unique claimant commit pushed to `refs/heads/dispatch-claims/<id>` with normal create-only Git semantics. A race loser cannot also create the same absent ref.
- Confirmed the canonical `agent/<id>` remote branch before explicitly deleting the temporary claim. Interrupted claims are shown as blocked with non-destructive inspection and recovery guidance; cleanup failure retains the marker while the published workstream remains claimed.
- Added separate-clone contention and non-main attached-worktree coordination tests. The full focused dispatcher suite passes 28 tests.
- Corrected dispatcher index/backlog/lifecycle wording and archived this completed packet.
- Moment Forge: not run — tooling and documentation only; no runtime or presentation behavior changed.
- Lattice canon validation was not part of this workstream and was not run independently.
