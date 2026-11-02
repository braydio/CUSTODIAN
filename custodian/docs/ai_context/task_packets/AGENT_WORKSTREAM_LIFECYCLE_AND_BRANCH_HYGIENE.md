# AGENT WORKSTREAM LIFECYCLE AND BRANCH HYGIENE

## Workstream identity

- Workstream: `agent-workstream-lifecycle`
- Branch: `agent/agent-workstream-lifecycle`
- Base at start: `origin/main@576934b47de37a8c755955cff86540fbbc8b18f0`
- Status: complete on merge to current main

## Goal

Make a stable `agent/<workstream-id>` branch in an ephemeral sibling worktree
the normal implementation surface. Add safe start, status, checkpoint, finish,
and GC commands. Fix own-remote-ref handling in `land_main.py`; add report-first
branch classification and archive-before-delete operations; reconcile workflow
docs; preserve unique historical branch heads as annotated archive tags and
record retirements in `BRANCH_ARCHIVE.md`.

## Non-negotiable safety

- Never reset, stash, or force-push.
- Never remove a dirty or uncommitted worktree automatically.
- Push the workstream before landing; delete it only after ancestry verification.
- Preserve unique history with a remotely verified annotated archive tag before
  deleting its branch.
- The persistent project-root checkout remains coordination-only and may stay
  unsynchronized if dirty or divergent.

## Acceptance

- `workstream.py` implements stable-ID start/resume, status, checkpoint, finish,
  and prune/report GC behavior.
- Existing remote workstreams merge latest main without rewriting published
  history; conflicts preserve the worktree and remote ref.
- `land_main.py` ignores only the current branch's expected own remote-tracking
  ref; commits on other remote refs remain blockers.
- Finish validates, pushes, synchronizes, revalidates after a main merge, lands,
  verifies ancestry, deletes the remote branch, tears down the local worktree and
  branch, prunes, and safely attempts root fast-forward sync.
- `branch_hygiene.py` defaults to report-only, honors protected refs, supports
  landed/identical safe deletion, and verifies archive tags and ledger entries
  before deleting divergent refs.
- Unit tests cover start/resume, malformed IDs, dirty worktree refusal, main
  fast-forward/merge/conflict, checkpoint, finish/cleanup, own-vs-unrelated
  publication guards, races, and branch archive protection.
- Workflow docs and AI context match the tool behavior.
- Remote branches in the task's live census are reconciled; unique historical
  heads are tagged and ledgered before deletion.
- Initial remote census: 19 refs. Expected normal post-finish state: main plus
  the three active agent workstreams.
- Root worktree changes remain untouched; current root has five generated,
  untracked import sidecars that must be preserved.

## Validation

- `python3 custodian/tools/agent/test_land_main.py`
- `python3 custodian/tools/agent/test_workstream.py`
- `python3 custodian/tools/agent/test_branch_hygiene.py`
- `python3 custodian/tools/validation/agent_workflow_smoke.py`
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`
- `git diff --check`
- Final remote census, archive-tag SHA verification, worktree list, and root
  checkout safety inspection.

## Completion notes

Record main before/after SHAs, remote branch counts before/after, branch
dispositions, archive tags, active workstreams, worktrees retained, tests,
root-sync outcome, and any blocked cleanup.
