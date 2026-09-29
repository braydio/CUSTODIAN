# WORKSTREAM FINISH LANDED CLOSEOUT HARDENING

- Workstream: `workstream-finish-landed-closeout-hardening`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-review-pipeline`
- Locks: `agent-workflow`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-workstream-finish-landed-closeout-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Make `workstream.py finish` robust when task history has already reached `origin/main`, when `origin/main` advances during closeout, and when the persistent root checkout is intentionally dirty/behind, so agents never need to improvise manual landing cleanup after a valid task has already landed.
- Current measured state: The live `asset-requirements-pipeline` completed at `9d5d743062d44ba736c3631c94f1fc506ca2555d`, is reachable from `origin/main`, has an archived complete packet and committed closing summary, and passed focused plus merged-tree changed-unit validation. Its normal `workstream.py finish` flow nevertheless failed after synchronization/landing because the helper reasoned about task-local history relative to the now-advanced `origin/main`, and the summary preflight/range logic no longer identified the already-landed task summary. A similar already-published/landing edge was previously recorded by Twin Solaria runtime closeout. This is recurring workflow debt.
- Task-specific authority: `custodian/tools/agent/workstream.py`, `custodian/tools/agent/land_main.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, live dispatcher/review workflow, and archived task evidence for `asset-requirements-pipeline`.
- Change: Separate task-artifact validation from the moving `origin/main...HEAD` diff, teach finish/landing to recognize the already-landed state before attempting history-changing synchronization, and make post-land teardown idempotent and safe when the task is proven reachable from `origin/main`.
- Preserve: no force push; no reset/stash of user work; published-history safety; green validation requirement; archived-packet gate; closing-summary requirement; local/remote workstream cleanup only after reachability proof; dirty root checkout remains untouched; serialization of main landing; recovery state is preserved on ambiguity.
- Non-goals: No new dispatcher queue, no continuous worker loop, no automatic cleanup of arbitrary stale branches, no mutation of unrelated dirty root files, no weakening of validation or artifact gates, no rebasing already-published work solely to make history pretty.
- Acceptance: A normal task can run `finish` exactly once even if its task commit has already reached `origin/main` or `origin/main` advanced after validation. Finish proves the archived packet, closing summary, validation, and task reachability from durable history; skips unnecessary rebase/merge/landing work when already landed; safely removes the task branch/worktree; and leaves a dirty persistent main checkout behind with an explicit sync-pending message. Re-running finish after successful cleanup produces a clear already-finished/no-attached-worktree result rather than encouraging manual surgery.
- Task overrides: `none`
- Deferred: Automatic reconciliation of arbitrary manually rewritten task history; distributed cross-host landing leases beyond current Git/lock policy; auto-cleaning the user's dirty root checkout.

## Findings To Correct

### F1 — HIGH: closing-summary proof is tied to a moving diff

Current `finish()` derives:

```python
git diff --name-only origin/main...HEAD
```

and requires one of those paths to end in `_CLAUDE_SUMMARY.md`.

That works only while the task branch still contains commits not already reachable from `origin/main`.

Once the task is already landed, `origin/main...HEAD` may be empty or otherwise cease to represent the task's authored change surface. A valid committed summary can then be reported as missing.

Replace this with durable task-artifact proof independent of the moving diff.

Preferred sources of truth, in order:

1. associated archived packet identity for `workstream_id`;
2. its declared/derived closing-summary filename convention;
3. repository history proving that summary path exists in the task's durable landed history.

A simpler implementation is acceptable if it is deterministic and survives the already-landed state.

Do not weaken the requirement that the summary be committed.

### F2 — HIGH: finish does not short-circuit an already-landed task early enough

Before synchronizing/rebasing/merging task history, `finish` should fetch current remote state and ask:

```text
Is the task HEAD already an ancestor of origin/main?
```

If yes:

- do not call `sync_main()`;
- do not invoke `land_main.py`;
- do not rewrite/remerge task history;
- perform artifact/validation/reachability checks;
- proceed to safe branch/worktree teardown.

If the exact task HEAD is not an ancestor but the task's durable implementation is already present through a known landing/recovery merge commit, fail closed unless the lineage can be proven deterministically. Do not guess equivalence from filenames alone.

### F3 — MEDIUM: landing/synchronization state machine mixes pre-land and post-land concerns

Current `finish` performs summary proof, push, main synchronization, revalidation, second push, `land_main.py`, reachability verification, and teardown in one linear path.

Refactor only enough to make explicit states such as:

```text
PREPARED
SYNC_REQUIRED
READY_TO_LAND
ALREADY_LANDED
LANDED
READY_TO_TEARDOWN
FINISHED
```

This need not become a persistent database or enum-heavy framework. The goal is readable branching and idempotent behavior.

Do not create a second landing authority.

### F4 — MEDIUM: published-history protection and normal task upstream must agree

`land_main.py` intentionally refuses to rebase commits already published on unrelated remote refs while ignoring the task's own configured upstream.

Add regression coverage for:

- normal push-first workstream upstream;
- fetched own remote branch;
- unrelated archive/recovery refs that genuinely should block a rebase;
- task already on `origin/main`;
- workstream branch merged with a newer `origin/main` commit before landing.

The guard must not mistake the task's own canonical remote branch for unrelated publication, but it must continue to block rewriting commits reachable from other durable refs.

### F5 — LOW: root checkout sync is already correctly subordinate

Preserve the current good behavior:

- after successful landing/teardown, search for persistent `main` checkout;
- if clean, fast-forward it;
- if dirty, print sync pending and do not touch it.

Add a focused assertion so future cleanup changes cannot turn this into an implicit stash/reset/checkout.

The user's reported dirty root with unrelated Operator/generated files is expected and should remain untouched.

## Recommended Implementation Shape

Prefer small helpers in `workstream.py`, for example conceptually:

```python
def task_head_reachable_from_main(...)
def closing_summary_committed_for_workstream(...)
def finish_already_landed(...)
def teardown_verified_workstream(...)
```

The exact names are not mandated.

Keep `land_main.py` as the sole active landing helper for tasks that are not already landed.

Do not duplicate its serialized push logic inside `workstream.py`.

## Durable Summary Proof

Implement one source of truth.

A strong option:

- associated archived packet must exist and be complete;
- derive the expected root summary path from workstream ID:
  `<WORKSTREAM_ID_UPPER_UNDERSCORE>_CLAUDE_SUMMARY.md`;
- permit an explicitly documented alternate summary only if current lifecycle already supports one;
- use `git cat-file -e <commit>:<path>` / equivalent to prove it is committed in the relevant task/landed history.

If current repository convention has legitimate summary names that do not exactly match the workstream transformation, first inspect live completed packets and centralize the existing convention instead of breaking them.

Do not use working-tree existence alone.

## Already-Landed Fast Path

After initial artifact and validation gates and a fresh fetch:

```text
if HEAD is ancestor of origin/main:
    verify summary + archived packet
    verify remote/main reachability
    teardown
    root sync if safe
    finish
else:
    normal synchronize -> revalidate if tree changed -> land -> verify -> teardown
```

If the workstream branch has advanced after an older task commit landed, do not discard those extra commits. Normal landing/recovery rules apply.

## Idempotence / Recovery

Cover these outcomes explicitly:

### Task already landed, branch still attached

Expected: successful teardown.

### Task landed, remote task branch already deleted, local worktree still attached

Expected: verify main reachability, remove local worktree/branch safely if lineage is clear.

### Task landed and worktree already removed

Expected: status/finish gives a clear `already finished / no attached worktree` result. It must not tell the operator to recreate work just to clean up.

### Main advanced but task not landed

Expected: current merge-based `sync_main` behavior remains. If tree changes, require green `--validation-report-after-sync`.

### Merge conflict

Expected: preserve worktree and fail closed.

### Dirty root main

Expected: successful task teardown plus `persistent root synchronization pending (dirty)`. No root mutation.

## Focused Tests

Use temporary bare remotes and real worktrees. Add at least:

1. normal clean task finish still lands and tears down;
2. task HEAD already reachable from `origin/main` before `finish` skips sync/land and tears down;
3. closing summary remains provable when `origin/main...HEAD` is empty;
4. archived complete packet remains required on already-landed path;
5. green validation remains required on already-landed path;
6. task branch with additional unlanded commit does not incorrectly use already-landed path;
7. main advancement requiring merge still requests after-sync validation;
8. own `origin/agent/<id>` publication does not trigger unrelated-published-history rejection;
9. genuinely unrelated remote ref containing a to-be-rebased commit still blocks rewrite;
10. landed task with deleted remote workstream branch can clean local attached state safely;
11. already-removed task reports clean already-finished state;
12. dirty persistent main checkout is not changed during teardown;
13. clean persistent main checkout fast-forwards after teardown;
14. existing dispatcher remote-claim tests remain green;
15. review-pipeline workstream tests remain green.

## Regression Evidence

Use the landed `asset-requirements-pipeline` history as a real-world reproduction reference:

```text
landed main: 9d5d743062d44ba736c3631c94f1fc506ca2555d
packet: task_packets/archived/ASSET_REQUIREMENTS_PIPELINE.md
summary: ASSET_REQUIREMENTS_PIPELINE_CLAUDE_SUMMARY.md
```

Do not alter that completed asset implementation to make the workflow test easier.

Also preserve the earlier Twin Solaria closeout report as historical evidence that this edge is recurring.

## Documentation Drift

Update:

- `AGENT_WORKSTREAM_LIFECYCLE.md` with the already-landed closeout path;
- `VALIDATION_RECIPES.md` with the focused agent workflow test if command ownership changes;
- `FILE_INDEX.md` for any new helper/test ownership;
- `AGENT_AUTOMATION_BACKLOG.md` only if it currently describes manual landing recovery as expected workflow.

Do not edit asset requirement docs except to correct a direct false workflow claim.

## Validation

Run the focused agent workflow tests first.

At minimum:

```bash
python3 custodian/tools/agent/test_dispatch.py
python3 custodian/tools/validation/agent_workflow_smoke.py
python3 -m py_compile   custodian/tools/agent/workstream.py   custodian/tools/agent/land_main.py

git diff --check
```

Use the repository's current changed-file validation closeout after focused tests.

No Moment Forge.

## Completion

Before normal finish:

- archive this packet complete;
- leave the paired review packet active;
- commit `WORKSTREAM_FINISH_LANDED_CLOSEOUT_HARDENING_CLAUDE_SUMMARY.md`;
- include focused test counts and at least one explicit already-landed-path test result;
- land through the corrected normal lifecycle itself if safe.

If using this very packet to prove the corrected already-landed behavior would require circular manual intervention, land normally and let the paired review reproduce the fast path in a temporary fixture. Do not create artificial remote state in the production repo.

## Completion Notes

- F1/F2 fixed together: `closing_summary_committed_for_workstream` proves the
  summary via `git cat-file -e HEAD:<name>` (never a diff against a moving
  `origin/main`), and `task_head_reachable_from_main` short-circuits straight
  to teardown before `sync_main`/`land_main.py` are ever called. Verified the
  bug condition directly in a test: once HEAD is landed,
  `git diff origin/main...HEAD` really is empty (merge-base becomes HEAD
  itself), yet `finish` still succeeds.
- F3: `finish` now reads as PREPARED → (ALREADY_LANDED | SYNC_REQUIRED →
  READY_TO_LAND) → teardown, as plain conditional branching (no enum/database),
  with `land_main.py` remaining the sole landing authority — it is only ever
  skipped when already-landed is independently proven, never reimplemented.
- F4: `land_main.py`'s existing unrelated-vs-own-upstream guard needed no
  behavior change; added the one genuinely missing regression
  (`test_task_already_on_main_is_a_successful_noop`) to the four scenarios
  already covered.
- F5: root-sync stayed exactly as-is; added explicit dirty-untouched and
  clean-fast-forwards assertions so a future change can't turn it into an
  implicit stash/reset.
- Idempotence: teardown tolerates an already-deleted remote branch
  (`"remote ref does not exist"` only); a `finish` re-run with nothing
  attached reports a clear already-finished result when the summary is
  durably on `origin/main`, or fails closed with "investigate before
  recreating anything" otherwise — it never guesses.
- Checked the "declared/derived closing-summary filename convention" caution
  against every real archived packet before implementing: zero mismatches
  between `<workstream-id-upper>_CLAUDE_SUMMARY.md` and the actual committed
  filename, so the strict transform is safe as the primary check; an
  explicitly-documented-alternate fallback (regex over the packet body) covers
  the one case the packet warned about, without weakening the default.
- Focused tests: `test_workstream.py` 18/18 (9 pre-existing + 9 new, covering
  packet items 1–3, 4–7, 10–13 directly); `test_land_main.py` 11/11 (10
  pre-existing + 1 new, item 8/9/4); `test_dispatch.py` 56/56 unaffected
  (items 14–15); `agent_workflow_smoke.py` green; `git diff --check` clean.
- One existing test fixture (`test_finish_lands_verifies_and_tears_down`) used
  a placeholder summary name (`SAMPLE_CLAUDE_SUMMARY.md`) unrelated to its
  workstream ID; renamed to `FINISH_ME_CLAUDE_SUMMARY.md` to match real
  convention now that the check is exact-name based, and used it to add the
  missing clean-root-fast-forward assertion (item 13).

## Handoff

- Next action: After the review-pipeline bootstrap and its self-review complete, auto-dispatch this P0 workflow hardening before ordinary P1 production tasks.
- Best starting files: `workstream.py`, `land_main.py`, agent workflow focused tests, archived `ASSET_REQUIREMENTS_PIPELINE.md`, and its root summary.
- Blockers or open questions: None. The dirty root checkout is not a blocker and must remain untouched.

## Independent Review

- Status: `passed`
- Review workstream: `review-workstream-finish-landed-closeout-hardening`
- Reviewed on main: `745a9ea56`
- Review modes: `code, architecture, workflow`
- Blocking findings: `0`
- Non-blocking findings: `1`
- Detailed review summary: `REVIEW_WORKSTREAM_FINISH_LANDED_CLOSEOUT_HARDENING_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

### Review Notes

- The already-landed path verifies the complete archived packet, committed closing summary, green validation, and exact HEAD ancestry before teardown. It bypasses `sync_main` and `land_main.py`; extra unlanded commits use normal synchronization/landing. Temporary-remote tests pass for these paths, own versus unrelated published refs, root fast-forward, and interrupted teardown.
- A focused temporary-repository probe verified the dirty-root promise more strongly than the committed test: tracked and untracked bytes and the exact porcelain status were unchanged after finish.
- Non-blocking test gap: `test_finish_leaves_dirty_persistent_root_untouched` checks that an untracked file still exists and that root HEAD did not fast-forward, but does not compare pre/post file bytes or `git status --porcelain`. A stash-only regression could therefore evade the permanent assertion even though the current implementation is read-only in that branch.
- Corrected the stale validation command in this archived packet: `agent_workflow_contract_smoke.py` does not exist; `agent_workflow_smoke.py` is the live passing workflow contract smoke.
