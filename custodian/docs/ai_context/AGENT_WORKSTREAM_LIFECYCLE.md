# Agent Workstream Lifecycle

Normal implementation runs use an isolated ephemeral worktree. Read-only and
review-only work may stay in the coordination checkout. If a worktree cannot be
used, document the reason in the task record. The project-root checkout is not
the default implementation surface.

## Start or resume

Derive one stable lowercase kebab-case ID for a coherent task. Run from the
repository coordination checkout:

```bash
python3 custodian/tools/agent/workstream.py start <workstream-id>
```

The tool fetches and prunes `origin`, then creates or resumes
`agent/<workstream-id>` in a sibling `.custodian-worktrees/` directory. An
existing remote branch is canonical. It is synchronized with `origin/main` by
fast-forward or a normal merge; published workstream history is never rebased.
If the branch is attached to a dirty worktree, stop and preserve it.

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

If finish merges newer main into the published branch, provide a second green
report with `--validation-report-after-sync`. Finish pushes before landing,
uses `land_main.py` for serialized/race-safe landing, verifies the landing by
ancestry from freshly fetched `origin/main`, then deletes the remote branch and
tears down the local worktree/branch. Before that proof, every failure retains
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
