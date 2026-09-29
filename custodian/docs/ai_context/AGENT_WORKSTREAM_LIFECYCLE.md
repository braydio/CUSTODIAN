# Agent Workstream Lifecycle

Normal implementation runs use an isolated ephemeral worktree. For queued
packet work, prefer `dispatch.py claim-next --agent codex`, or use
`dispatch.py claim <id> --agent codex` for explicit selection. The dispatcher
reads fetched `origin/main`, checks packet dependencies and locks, then
delegates branch/worktree creation or resume to `workstream.py`. Direct
`workstream.py start <id>` remains valid. Read-only and review-only work may
stay in the coordination checkout. If a worktree cannot be
used, document the reason in the task record. The project-root checkout is not
the default implementation surface.

## Start or resume

Derive one stable lowercase kebab-case ID for a coherent task. Run from the
repository coordination checkout:

```bash
python3 custodian/tools/agent/workstream.py start <workstream-id>
```

Queued packet front door:

```bash
python3 custodian/tools/agent/dispatch.py status
python3 custodian/tools/agent/dispatch.py claim-next --agent codex
python3 custodian/tools/agent/dispatch.py claim <workstream-id> --agent codex
```

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
durable and committed. Validation JSON is normally an ephemeral input to finish
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

## Exit paths

For blocked, paused, or review-pending work, make intentional commits, ensure
the worktree is clean, and run:

```bash
python3 custodian/tools/agent/workstream.py checkpoint <workstream-id>
```

This pushes and verifies the branch while retaining it as active. Optional
`--remove-worktree` removes only its clean checkout; the local and remote branch
remain.

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
