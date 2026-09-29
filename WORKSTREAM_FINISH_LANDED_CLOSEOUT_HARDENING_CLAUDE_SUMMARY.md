# Workstream Finish Landed Closeout Hardening Summary

## Delivered

Fixed `workstream.py finish`'s recurring already-landed edge (real-world
trigger: `asset-requirements-pipeline`) so an agent never needs manual landing
surgery after a task has genuinely already landed.

- **F1/F2 — durable summary proof + early already-landed short-circuit.**
  Replaced the `git diff --name-only origin/main...HEAD`-based summary check
  (which goes empty once HEAD is already an ancestor of `origin/main`, since
  their merge-base then becomes HEAD itself) with
  `closing_summary_committed_for_workstream`, which proves the summary via
  `git cat-file -e HEAD:<name>` — durable, independent of any moving diff.
  Added `task_head_reachable_from_main`, checked immediately after the
  artifact/summary/validation gates and again after synchronization; either
  hit skips `sync_main`/`land_main.py` entirely and goes straight to verified
  teardown, never rewriting or remerging already-landed history.
- **F3 — readable state machine, no second landing authority.** `finish` now
  reads as PREPARED → (ALREADY_LANDED | SYNC_REQUIRED → READY_TO_LAND) →
  teardown, as plain conditional branching with comments naming each state —
  not an enum/database. `land_main.py` remains the sole active landing
  authority; it is only ever skipped once already-landed is independently
  proven, never reimplemented.
- **F4 — regression coverage for `land_main.py`'s publication guard.** Four of
  five required scenarios were already covered; added the missing one
  (`test_task_already_on_main_is_a_successful_noop`) confirming `land_main.py`
  itself already handles "task already on main" as a clean no-op.
- **F5 — root-sync safety, made explicit.** Behavior was already correct
  (subordinate, fast-forward-only, never touches a dirty root); added direct
  assertions (dirty stays untouched; clean fast-forwards) so a future change
  to this code can't silently turn it into a stash/reset.
- **Idempotence.** Teardown now tolerates a remote branch already deleted by
  an interrupted prior `finish` (only `"remote ref does not exist"` is
  tolerated; any other push failure still raises). Re-running `finish` with
  no attached worktree and no remote branch reports a clear already-finished
  result when the closing summary is durably present on `origin/main`, or
  fails closed with an explicit "investigate before recreating anything"
  message otherwise — it never guesses or encourages recreating work.
- Updated `AGENT_WORKSTREAM_LIFECYCLE.md` (new "Already-landed closeout"
  subsection) and `FILE_INDEX.md`'s `workstream.py` entry. Left
  `VALIDATION_RECIPES.md` and `AGENT_AUTOMATION_BACKLOG.md` unchanged — no
  command surface changed and neither currently makes a claim this work
  invalidates.

## Validation

- `python3 -m unittest custodian.tools.agent.test_workstream`: **18 passed**
  (9 pre-existing + 9 new — already-landed short-circuit with a direct proof
  the old diff is empty at that point; artifact-gate and green-validation
  still enforced on the already-landed path; an extra unlanded commit still
  uses the normal land path; main-advancement still requires and honors
  `--validation-report-after-sync`; teardown tolerates an already-deleted
  remote branch; already-finished reported cleanly with nothing attached;
  an unverifiable/bogus workstream still fails closed; dirty persistent root
  stays untouched; clean persistent root fast-forwards).
- `python3 -m unittest custodian.tools.agent.test_land_main`: **11 passed**
  (10 pre-existing + 1 new: task already on `origin/main` is a successful
  no-op).
- `python3 custodian/tools/agent/test_dispatch.py`: **56 passed**, unaffected
  by this task (dispatcher claim/receipt/review-pairing logic untouched).
- `python3 custodian/tools/validation/agent_workflow_smoke.py`: **passed**
  (runs its own internal `test_dispatch.py` and `test_land_main.py`
  re-invocations, both green; "PASS agent workflow contracts").
- `python3 -m unittest ... test_land_main test_workstream
  test_workstream_artifacts test_branch_hygiene`: **41 passed** together.
- `python3 -m py_compile custodian/tools/agent/workstream.py
  custodian/tools/agent/land_main.py`: clean. `git diff --check`: clean.
- This packet's own landing is the normal (not already-landed) path — per
  the packet's own instruction, I did not try to force a circular
  already-landed self-demonstration in the production repo; the fast path is
  proven in the temporary-repository test suite above, and its paired review
  can independently reproduce it in a fixture if desired.
- Moment Forge: not run — workflow/tooling only, no runtime or presentation
  behavior changed.

## Awkward Parts And Deferred Work

- One existing test fixture, `test_finish_lands_verifies_and_tears_down`,
  used a summary name (`SAMPLE_CLAUDE_SUMMARY.md`) that didn't match its
  workstream ID (`finish-me`) — harmless under the old loose "any
  `*_CLAUDE_SUMMARY.md` in the diff" check, but incompatible with the new
  exact-name proof. Before hardening this, I audited every real archived
  packet in the live repository for the same mismatch the task packet warned
  about (a summary named after the "work slice" rather than the literal
  workstream ID) — found zero mismatches — so I renamed the test fixture's
  file to `FINISH_ME_CLAUDE_SUMMARY.md` rather than weakening the check to
  accommodate a placeholder that doesn't reflect real repository convention.
  The strict transform is the primary check; an explicitly-documented
  alternate name (parsed from the packet body) is the one legitimate
  fallback the task packet asked for.
- `_finish_without_attached_worktree`'s already-finished success path does
  not require an archived+complete packet to exist (only that the closing
  summary is durably on `origin/main`), because task packets are optional
  per repository convention — requiring one would incorrectly fail closed
  for a legitimate skip-tier, packet-less task that already fully finished
  and was torn down.
- Deferred, unchanged from the packet's own scope: automatic reconciliation
  of arbitrary manually rewritten task history; distributed cross-host
  landing leases beyond current Git/lock policy; auto-cleaning the user's
  dirty root checkout.
