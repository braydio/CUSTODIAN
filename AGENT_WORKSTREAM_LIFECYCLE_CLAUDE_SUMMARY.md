# Agent Workstream Lifecycle Summary

The implementation adds `workstream.py` for stable-ID start/status/checkpoint/
finish/gc and `branch_hygiene.py` for report-first, ancestry-based branch
disposition. Normal implementation now uses an external ephemeral worktree;
checkpoint keeps active recovery refs, and finish pushes before landing, verifies
reachability, then removes the completed workstream. `land_main.py` now ignores
only the current branch's configured upstream in its pushed-history guard.

The initial fetched remote census contained 19 refs including `main`. The
coordination checkout was dirty with five generated/untracked files; it was
preserved untouched. The lifecycle tests use temporary bare remotes and cover
creation/resume, fast-forward and merge synchronization, conflict preservation,
checkpoint, finish/cleanup, own-vs-unrelated published refs, and main race retry.
The first tests exposed an incorrect expectation in the hygiene fixture and a
local branch deletion that relied on stale local `main`; both were corrected by
making the graph genuinely divergent and requiring a fresh remote ancestry
proof before local teardown.

Branch cleanup is performed only after a fresh fetch and exact-head recheck.
Unique old Python, reorganization, terrain, Operator, and mixed Twin Solaria
heads are retained by verified archive tags; the duplicate Twin donor sync ref
will be removed only after the canonical donor archive tag is verified. The
three active connector, Operator, and Twin workstream branches remain in place.

Validation so far: 16 focused Git lifecycle tests pass; the existing
`agent_workflow_smoke.py` passes; Python compilation and `git diff --check` pass.
Changed-file validation and final remote/worktree census remain to be recorded
after branch hygiene is complete.
