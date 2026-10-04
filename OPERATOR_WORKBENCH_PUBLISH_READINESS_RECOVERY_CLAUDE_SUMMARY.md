# Operator Workbench Publish Readiness and Recovery Summary

Implemented `operator-workbench-publish-readiness-recovery` in the isolated
worktree. Publish readiness now reports checkout identity/relation, pending
landing and interrupted transactions, categorized dirty paths, sparse health,
checked-out missing/LFS dependencies, and selected source-contract drift.
Startup inspection is read-only; explicit Publish preparation is limited to a
clean fast-forward, the existing sparse profile, and exact local-only LFS
materialization from cache or a byte-verified same-path donor. Confirmation
rechecks readiness before canonical mutation.

Workbench publication records tracked `.import`/`.uid` preimages and import
window changes, restores exact unrelated metadata, and leaves ambiguous output
as `RECOVERY_REQUIRED`. Journals keep primary and recovery failures separate;
rollback reaches `ROLLED_BACK` only after exact source/runtime/resource,
metadata, document-byte, and Git-cleanliness checks. Aseprite inspection now
checks saved canvas/frame/timing contracts and reconciles obsolete frame
metadata only after backing up both the manifest and unchanged saved document.
`LAND PENDING` carries a stable path/blob identity and rejects rewritten
candidates with added outputs.

Key evidence and negative controls:

- `operator_art_worktree_smoke.py`: clean-behind preparation, dirty-state and
  sparse startup preservation, cache/donor/missing LFS cases, and rejected
  pending-land relink when a rewritten candidate adds a path. The test remote
  intentionally rejects one push to exercise resumable landing, then accepts
  the retry.
- `operator_workbench_mirror_publish_smoke.py`: exact unrelated import
  metadata restoration, pre-existing dirty metadata refusal, ambiguous
  non-metadata output recovery, source/runtime rollback, and original failure
  preservation.
- `operator_animation_workbench_smoke.py`: saved-document mismatch refusal and
  byte-preserving reconciliation for an obsolete frame migration; current
  Aseprite frame-migration and canvas cases still pass.
- `operator_workbench_ui_smoke.py`: readiness projection and blocked startup
  state remain usable. Optional Textual pilot skipped because Textual is not
  installed.
- `godot_import_preflight.py --project-dir custodian`: pass, no checked-out LFS
  pointers. `run_validation.py --changed --json`: 19/19 passed, complete changed
  file coverage, zero uncovered files. `git diff --check` passes.

No canonical Operator art pixels or gameplay behavior changed. The R2 handoff
remains deferred until its architecture refresh. The paired post-land review
`review-operator-workbench-publish-readiness-recovery` is the follow-up.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first negative LFS fixture reused an OID already cached by its success case. The import-metadata test initially stubbed the shared subprocess entrypoint and accidentally hid real Git status.
- Root cause / contributing factors: Shared fixture object identity; overly broad subprocess mocking.
- Prevention / pipeline improvement: Use unique OIDs for negative cache controls and route test stubs by exact subprocess command while leaving Git queries real.
- Tooling / docs drift discovered: Workbench docs still described startup synchronization and cache-only Operator hydration; both are corrected.
- Follow-up: fixed-in-scope
- What worked: Fixture-local Git/LFS and Aseprite inspection gave deterministic recovery evidence without touching production art.
