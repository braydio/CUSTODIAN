# Agent Workstream Lifecycle

Normal implementation runs use an isolated ephemeral worktree. For queued
packet work, prefer `dispatch.py claim-next --agent <agent-id>` (for example
`--agent claude` or `--agent codex`), or use `dispatch.py claim <id> --agent
<agent-id>` for explicit selection. Omitting `--agent` falls back to the
`CUSTODIAN_AGENT_ID` environment variable, then a neutral `unspecified` —
never a silently assumed agent brand. The dispatcher
reads fetched `origin/main`, checks packet dependencies and locks, then
delegates branch/worktree creation to `workstream.py` under the same local
mutex and remote unique-claim protocol. Direct `workstream.py start <id>` uses
that exclusive protocol for manual/unpacketed starts and fails closed if the
branch, claim, or checkout already exists. It never silently adopts existing
state. Truly read-only reviews may stay in
the coordination checkout; paired post-land reviews that commit durable
artifacts use their own workstream worktree. If a worktree cannot be
used, document the reason in the task record. The project-root checkout is not
the default implementation surface.

## Start or resume

Derive one stable lowercase kebab-case ID for a coherent task. Run from the
repository coordination checkout:

```bash
python3 custodian/tools/agent/workstream.py start <workstream-id>
```

Existing task state requires the explicit recovery command after inspection:

```bash
python3 custodian/tools/agent/workstream.py resume <workstream-id>
```

`resume` preserves dirty checkouts and only proceeds with a clean attached
checkout or an explicitly selected published `origin/agent/<id>` branch. A
remote claim without that branch is interrupted recovery state; ordinary
start will not clear it. After verifying no live claimant, an operator may
explicitly remove the `dispatch-claims/<id>` ref. Every start/claim/finish
records a local trace under the Git common directory and best-effort publishes
diagnostics under `agent-diagnostics/<id>/<run-id>`. Inspect with
`python3 custodian/tools/agent/run_trace.py list` or
`python3 custodian/tools/agent/run_trace.py export <run-id> --json`.
Diagnostics contain lifecycle metadata only and cannot be landed as task code.

Queued packet front door:

```bash
python3 custodian/tools/agent/dispatch.py status
python3 custodian/tools/agent/dispatch.py claim-next --agent <agent-id>
python3 custodian/tools/agent/dispatch.py claim <workstream-id> --agent <agent-id>
```

Codex convenience routing is versioned in
`.agents/skills/custodian-next/SKILL.md` and
`custodian/tools/agent/prompts/custodian-next.md`. The skill may be invoked as
`$custodian-next`. Because Codex custom prompts are user-scoped, install the
repository prompt link with:

```bash
python3 custodian/tools/agent/install_codex_prompts.py
python3 custodian/tools/agent/install_codex_prompts.py --check
```

After a Codex restart, `/prompts:custodian-next` applies the same routing:
continue an already-active current workstream; otherwise prefer the durable
same-series `Next Handoff`; stop on refresh/dependency/manual gates; only then
fall back to global `claim-next`. It is a prompt/skill front end over the
existing dispatcher, not a second scheduler.

A successful claim ends with `CLAIMED` and one
`CUSTODIAN_DISPATCH_RESULT_JSON:{...}` line: the receipt is the assignment
authority. Never infer ownership from worktree creation, terminal activity,
branch existence, or another task being active. Before entering the checkout,
verify the receipt's workstream/branch/worktree; if stdout was lost, recover
with:

```bash
python3 custodian/tools/agent/dispatch.py last-claim
python3 custodian/tools/agent/dispatch.py last-claim --json
```

`last-claim` is read-only recovery: it reports whether the receipt still looks
current (worktree present, on the expected branch, remote branch still
published) or stale, but never re-claims or recreates anything. Do not require
agents to manually re-run these checks when the dispatcher already reports
`verified: true`; the commands above are recovery/debug proof, not normal
duplicate ceremony. When verification is needed:

```bash
git -C <returned-worktree> branch --show-current
python3 custodian/tools/agent/dispatch.py status
```

The branch must equal `agent/<returned-workstream>`, and status must recognize
that same ID as claimed.

The tool fetches and prunes `origin`, then creates or resumes
`agent/<workstream-id>` in a sibling `.custodian-worktrees/` directory. An
existing remote branch is canonical. It is synchronized with `origin/main` by
fast-forward or a normal merge; published workstream history is never rebased.
If the branch is attached to a dirty worktree, stop and preserve it.

Before creating a workstream, `dispatch.py` atomically acquires the remote
`refs/heads/dispatch-claims/<workstream-id>` ref using a unique claimant commit
and a normal create-only push. Once `agent/<workstream-id>` is confirmed
published, it explicitly deletes the temporary claim. A temporary claim without
the agent branch means acquisition was interrupted: status marks it blocked and
prints the ref to inspect and a normal explicit-delete recovery command. Verify
there is no live claimant before deleting; V1 never expires claims by age. If
both refs exist, the workstream branch is canonical and the temporary claim is
cleanup residue.

Run implementation, validation, asset ingest, generated-file review, packet and
documentation edits, and the required `<TASK>_CLAUDE_SUMMARY.md` inside that
worktree. Commit only scoped task files. The task branch is pushed before
landing, providing a remote recovery ref.

### Run-artifact contract

A worktree is disposable; its unresolved artifacts are not. If a task packet is
used, give it the stable `Workstream` ID. Before finish, the associated packet
must be `complete`, moved to `task_packets/archived/`, and absent from the
packet README's active/recently-complete sections. The root closing summary is
durable and committed. Its `## Process Feedback` receipt records execution
friction/prevention for every normal implementation. For V2 task packets, mirror
the same receipt into `## Execution Feedback` before marking the packet complete
and archiving it. Validation JSON is normally an ephemeral input to finish
unless the task specifically needs it retained. Temporary logs/caches/previews
may be deleted deliberately, while review evidence is retained only when it has
future review value. Asset Pipeline V2 `source_work/` and `inbox/` material is
never disposable merely because it was created during a run.

`workstream.py finish` runs an artifact preflight before synchronization and
again after synchronizing latest main. Any untracked file blocks teardown and is
classified as task-packet, closing-summary, Asset V2 source, review evidence,
disposable candidate, or unclassified. The agent must explicitly commit durable
material or remove disposable material; ambiguous files are never silently
removed.

## Default Execution Economy

These are repository-default execution steps for claimed packet work; do not
copy this list into individual task packets.

1. Read the current packet.
2. Read the immediate predecessor closing summary when the task depends on an
   architecture-shifting predecessor.
3. Use the code-review graph first when available.
4. Otherwise search exact symbols/paths before reading large files. For large
   files, prefer targeted symbol/range retrieval over a default whole-file read.
5. Read direct callers/callees only as needed.
6. Do not reread completed packets or broad roadmaps unless a concrete
   contradiction requires it.
7. Reuse landed benchmark/validation evidence instead of rediscovering it.
8. Run the highest-risk focused falsification first, then one normal closeout
   sweep.

A packet's `Status: complete` is not itself proof that its stated Goal/
Completion boundary hold; see `AGENT_TASK_PACKET_TEMPLATE.md`'s `## Completion
Truth` receipt, which `workstream.py finish` enforces for current V2
`implementation`/`correction` packets before teardown.

## Subagent/Fork Safety

Default to a single agent implementing one packet. Use research forks/subagents
only when the work is genuinely independent and parallelism materially reduces
wall time.

- A read-only research fork must not share writable authority over the parent
  implementation worktree. Use tool restrictions or a separate isolated
  checkout/context; if the platform cannot enforce read-only mutation, do the
  targeted research in the parent instead.
- Never allow two implementation-capable forks to concurrently edit the same
  worktree without an explicitly scoped multi-writer task contract.
- If a fork stalls and the parent can obtain the fact with a few targeted
  reads/searches, stop the fork rather than waiting/polling repeatedly.
- Verify fork claims against live code before implementation when the result
  names APIs/paths not already known; a fork's summary describes what it
  intended to do, not necessarily what it verified.

This is instruction/contract hardening, not a requirement to build a general
subagent manager.

## Exit paths

For blocked, paused, or review-pending work, make intentional commits, ensure
the worktree is clean, and run:

```bash
python3 custodian/tools/agent/workstream.py checkpoint <workstream-id>
```

This pushes and verifies the branch while retaining it as active. Optional
`--remove-worktree` removes only its clean checkout; the local and remote branch
remain.

Paired post-land review workstreams are review-only with respect to the target implementation and must start from a **fresh reviewer context**. Do not continue the implementation session/conversation into its paired review. The same model/agent family is allowed only when a new reviewer context/workstream reconstructs the task from durable repository evidence; record provenance as `same-agent-fresh-context`. A different agent/context records `different-agent`. If a fresh context is unavailable, the result is ad hoc self-review and does not satisfy the paired-review contract. The review packet may authorize a bounded repository-artifact commit. When that exact override is present, the reviewer stages only the
archived target's `Independent Review` receipt, the required review closing
summary, the review packet's lifecycle/archive metadata, and bounded correction
plus re-review packets. The reviewer never stages reviewed implementation files
or unrelated work. A clean or non-blocking-only result completes, pushes, and
lands these artifacts through the ordinary checkpoint/finish lifecycle without
a routine user-authorization prompt. Stop for user judgment only when the
receipt is `human_required`. An ad hoc/read-only review without this paired
packet override remains uncommitted and must say so explicitly.

For completed validated work, provide a green focused validation JSON report:

```bash
python3 custodian/tools/agent/workstream.py finish <workstream-id> \
  --validation-report /path/to/validation.json
```

If the implementation packet declared `Review: auto`, its paired independent
review is a separate follow-on workstream that becomes eligible once this one
lands and archives — it is never a condition of `finish` itself. `finish`
closes this worktree normally regardless of review outcome; see
`task_packets/README.md`'s Paired Review And Correction section for the full
post-land review and correction lifecycle.

If finish merges newer main into the published branch, provide a second green
report with `--validation-report-after-sync`. Finish pushes before landing,
uses `land_main.py` internally for serialized/race-safe landing, verifies the
landing by ancestry from freshly fetched `origin/main`, then deletes the remote
branch and tears down the local worktree/branch. `land_main.py` refuses
destructive direct invocation outside this finish handoff; the reviewed
Operator art publisher has a separately scoped explicit argument accepted only
for `workbench/operator-art` to `origin/main`. `--dry-run` remains available
for inspection. Before that proof, every failure retains
the recovery branch and worktree. Root checkout synchronization is attempted
only from a clean `main` checkout using fast-forward-only; otherwise it remains
pending without reset, stash, or branch switching.

### Already-landed closeout

The closing-summary and reachability checks are independent of any diff
against `origin/main`. Once a task's exact HEAD is already an ancestor of
`origin/main` — a prior `finish` landed it but was interrupted before
teardown, or `land_main.py` reported "already up to date" after a lost push
response — `finish` proves the artifact gate, the summary (via `git cat-file
-e HEAD:<summary>`, not a moving diff), and green validation exactly as
normal, then skips `sync_main`/`land_main.py` entirely and goes straight to
verified teardown. It never rewrites or remerges already-landed history. A
task branch with additional commits beyond an already-landed point is not
mistaken for finished; the normal synchronize → land path still applies to
the remainder.

Re-running `finish` after teardown already completed (no attached worktree,
no remote branch) reports a clear already-finished result rather than an
error, provided the closing summary is durably present on `origin/main`;
otherwise it fails closed rather than guessing. It never encourages
recreating a worktree just to clean up.

`workstream.py gc` runs fetch/prune and emits the branch hygiene report.
`branch_hygiene.py` is report-only by default. Its classifications are based on
ancestry and commit counts; unique `agent/*` refs classify as `ACTIVE`, and the
tool never age-deletes. `--apply` deletes branches fully contained by main and
archive-tags unique history before deleting the branch. Protected refs cannot
be deleted. Archive tags use
`archive/<sanitized-branch>-<YYYYMMDD>` and are recorded in
`BRANCH_ARCHIVE.md`.

Never force-push, reset user work, or stash automatically. Branches are active
work queues; tags retain unique retired history.