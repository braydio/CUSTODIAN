# Agent Workstream Lifecycle Summary

This slice adds `workstream.py` for stable-ID start/status/checkpoint/finish/gc
and `branch_hygiene.py` for report-first, ancestry-based branch disposition.
Normal implementation now uses an external ephemeral worktree; checkpoint
keeps active recovery refs, and finish pushes before landing, verifies
reachability, then removes the completed workstream. `land_main.py` ignores only
the current branch's configured upstream in its pushed-history guard.

The initial fetched remote census contained 19 refs including `main`. The
coordination checkout was dirty with five generated/untracked files and remains
untouched. Branch cleanup removed six refs already contained by main, archived
eight unique heads, and removed the duplicate `codex/twin-solaria-runtime-v1a-main-sync`
ref after verifying its exact head was preserved by the canonical donor tag.
The three active connector, Operator, and Twin workstream branches remain.
Archived terrain files are present in current main; the stale Operator branch's
Fast 01 behavior is already implemented on main; the mixed Twin donor's source
and production authored-level foundation are present on main. Their full unique
heads remain available by tag for selective archaeology.

The lifecycle tests use temporary bare remotes and cover branch creation/resume,
fast-forward and merge synchronization, conflict preservation, checkpoint,
finish/cleanup, own-vs-unrelated published refs, main race retry, report-only
hygiene, protected branches, and tag-before-delete behavior. A test fixture
initially failed because its supposed divergent branch actually pointed at main;
the graph was corrected. Finish cleanup also exposed that local `main` can lag
fresh `origin/main`; local branch removal now occurs only after remote ancestry
verification.

Validation: 20 focused Git lifecycle tests pass; `agent_workflow_smoke.py`,
changed-file validation (3/3 selected checks), Python compilation, and
`git diff --check` pass. The persistent root's five untracked generated files
prevented the safe root fast-forward, so root synchronization remains pending.
Pre-existing task worktrees were left untouched; this lifecycle removes only
its own ephemeral worktree after verified landing.
