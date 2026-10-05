# OPERATOR WORKBENCH BACKGROUND BASE SYNC

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-background-base-sync`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-publish-readiness-recovery`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-background-base-sync`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `persistent authoring-checkout lifecycle change that preserves unpublished binary art while advancing its repository base`
- Reviewed main: `7cfa2c12f5a99a90bfe087117856d16c92f8772a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Make normal `opui` startup self-heal the persistent sparse `workbench/operator-art` checkout when it is merely behind `origin/main` and its only local dirt is provably Workbench-owned unpublished art residue, so unfinished publication/edit output cannot indefinitely pin both the artwork checkout and the Workbench code to an old repository revision.
- Completion boundary:
  - Replace the current "existing OPUI checkout startup is inspection-only" rule with one bounded, fail-closed launch reconciliation owned by `operator_art_worktree.py`.
  - A safe reconcile must preserve unpublished Workbench-owned local bytes exactly, advance an ahead-zero checkout to current `origin/main` with FF-only semantics, re-establish the current sparse/dependency profile, restore the exact unpublished bytes, and prove the resulting dirty set is identical to the preserved set.
  - Unknown user dirt, staged/index changes, local commits ahead of main, `LAND PENDING`, unresolved Workbench transactions, same-path upstream changes, symlinks, or incomplete recovery proof remain real blockers and must never be auto-discarded, rebased, stashed, published, or guessed through.
  - Do not change the canonical source -> runtime publication transaction, landing authority, animation art, gameplay/runtime animation behavior, or the UX Hierarchy V1 visual redesign beyond projecting the new structured reconciliation state.
- Current measured state:
  - `tools/custodian_aliases.sh::opui` invokes the current coordination-main `operator_art_worktree.py ensure`, then launches `operator_cli.py ui` from the returned art checkout. Therefore the OPUI code version is the art checkout's HEAD.
  - `operator_art_worktree.ensure_art_worktree()` explicitly treats an already-attached art checkout as a read-only startup boundary: it preserves the checkout and returns without fetching/fast-forwarding it.
  - `prepare_publish_checkout()` fetches and fast-forwards only when the checkout has no dirty paths, no pending land, no unresolved transaction, no source-freshness blocker, and no local commits ahead of main.
  - `operator_art_worktree_smoke.py::startup_read_only_smoke()` currently asserts that reopening OPUI must not synchronize Git.
  - `operator_art_worktree_smoke.py::sparse_sync_smoke()` currently asserts that one dirty authored Operator source file blocks all synchronization even when the branch is ahead zero.
  - Checkout identity renders raw repository relation as `ahead N / behind N`. A value such as `behind 256` counts repository commits, not 256 Operator animation changes. Most of those commits may be unrelated to Operator art because the sparse checkout limits materialized paths, not Git history.
  - User-observed case: unfinished Fast 01 publication/edit residue replaced 96px sheets with 128px sheets. Those tracked changes prevented the dedicated art checkout from advancing, which also kept the OPUI code in that checkout behind current main.
  - The landed publish-readiness/recovery authority already records transaction journals/preimages and fails closed on ambiguous residue. This packet must compose with that authority, not weaken its rollback/recovery guarantees.
- Evidence:
  - `tools/custodian_aliases.sh::opui`
  - `custodian/tools/operator/operator_art_worktree.py::{ensure_art_worktree,_ensure_sparse_and_current,_status_paths,_dirty_categories,checkout_identity,inspect_publish_readiness,prepare_publish_checkout,publication_allowlist,upstream_source_conflicts}`
  - `custodian/tools/operator/ui/service.py::{checkout_identity,readiness,prepare_publish}`
  - `custodian/tools/validation/operator_art_worktree_smoke.py::{startup_read_only_smoke,sparse_sync_smoke,readiness_classification_smoke,launcher_smoke}`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - archived `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` and its paired review
  - `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_CLAUDE_SUMMARY.md`
- Task-specific authority:
  - `operator_art_worktree.py` remains the sole owner of the persistent art checkout's Git/sparse/readiness lifecycle.
  - Workbench transaction journals/preimages remain the authority for interrupted publication recovery.
  - Ignored `.ai/operator_animation_workbench/` state remains disposable authoring/recovery state and must never become canonical production authority.
  - `origin/main` remains repository base truth; synchronization is FF-only for this persistent branch.
  - Canonical source PNGs remain production source authority. Background reconciliation preserves local unpublished bytes but never publishes them.
- Work surface:
  - Primary: `custodian/tools/operator/operator_art_worktree.py`.
  - Required focused regression: `custodian/tools/validation/operator_art_worktree_smoke.py`.
  - UI projection/regression where needed: `custodian/tools/operator/ui/state.py`, `custodian/tools/operator/ui/service.py`, `custodian/tools/validation/operator_workbench_ui_smoke.py`.
  - Launcher only if needed for a structured reconciliation receipt: `tools/custodian_aliases.sh`.
  - Validation ownership only if current manifest coverage is insufficient: `custodian/tools/validation/validation_manifest.json`.
  - Live docs after implementation: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, and `custodian/docs/ai_context/FILE_INDEX.md`.
- Change:
  1. Add one structured launch/base reconciliation result below `operator_art_worktree.py`'s existing lock. Recommended shape, names flexible:
     ```python
     @dataclass(frozen=True)
     class LaunchReconcileResult:
         status: str                 # current | synced | synced_preserved | blocked | recovery_required
         before_relation: str
         after_relation: str
         preserved_paths: tuple[str, ...]
         blockers: tuple[str, ...]
         receipt: str | None
     ```
     Keep it machine-readable enough for UI projection; do not make widgets parse human Git strings.
  2. Existing-checkout `ensure_art_worktree()` must fetch `origin/main` and invoke the bounded reconciler before returning the path. New-checkout behavior remains sparse/current as today. The art-worktree lock continues to serialize checkout lifecycle mutation.
  3. Only attempt dirty preservation/rebase when all of the following are true:
     - checkout identity is the dedicated `workbench/operator-art` branch;
     - `ahead == 0`;
     - no `LAND PENDING` receipt;
     - no unresolved Workbench transaction journal;
     - no staged/index changes;
     - every dirty path is provably Workbench-owned publication/edit residue;
     - `origin/main` did not change any of those dirty paths since current HEAD;
     - every preserved file is an ordinary file below the checkout with no symlink/path escape.
  4. Determine Workbench-owned dirt from current saved Workbench manifests plus existing publication contracts, not merely from a broad `custodian/content/sprites/operator/**` prefix. Recommended implementation:
     - scan valid ignored `.ai/operator_animation_workbench/**/workbench.json` manifests;
     - collect each binding's `source_contract.path` and `publish_contract.path`;
     - expand those through the existing `publication_allowlist()` logic for exact generated/runtime/timing sidecars;
     - include only transaction-journal-owned metadata paths when an already-resolved journal proves their ownership/preimage;
     - classify anything else as unknown user dirt and fail closed.
     A stale/malformed manifest must not grant ownership to arbitrary paths.
  5. Replace the current path-only status helper internally with, or add alongside it, a status-entry parser that preserves index/worktree status. Do not automatically reconcile staged paths. Normal Workbench residue is expected to be unstaged until the reviewed publish transaction stages it.
  6. Before clearing any reconciliable dirty path, write an ignored exact-byte recovery snapshot under a bounded Workbench recovery directory, for example:
     ```text
     .ai/operator_animation_workbench/recovery/base_sync/<run-id>/
         snapshot.json
         payload/<repo-relative-file>
     ```
     The snapshot records at least old HEAD, fetched origin/main SHA, path/status, existence/deletion state, byte size, SHA-256, and whether the path was tracked or untracked. Never copy symlinks. Upload/publish nothing.
  7. Check upstream overlap before mutation. With `ahead == 0`, compare HEAD -> fetched `origin/main` for the exact preserved path set. If any preserved path changed upstream, return a specific `same-path upstream conflict` blocker and leave HEAD/local bytes untouched.
  8. Clear only the declared preserved paths so FF-only can run:
     - use path-scoped `git restore --worktree --source=HEAD -- <tracked paths>` or an equally narrow reviewed primitive;
     - remove only snapshot-declared safe untracked paths;
     - do not use broad `git reset --hard`, `git clean`, automatic `git stash`, or rebase;
     - verify the checkout is Git-clean before advancing.
  9. FF-only to fetched `origin/main` with hooks suppressed as the existing synchronization path does. Then reapply the current sparse profile and required local-only LFS/dependency preparation while the checkout is clean.
  10. Reapply the preserved local unpublished state by exact bytes/deletion intent from the snapshot. Use atomic file replacement where practical. Verify:
      - every preserved file hash/size or deletion matches the snapshot;
      - no extra dirty path appeared;
      - the final dirty path set equals the preserved path set exactly;
      - HEAD equals fetched `origin/main`;
      - ignored Workbench/Aseprite bytes outside the recovery snapshot are unchanged.
      Successful reconciliation leaves the unpublished art dirty on top of current main. It does not silently mark it published, saved, or accepted.
  11. On a fully verified successful reapply, retain a compact ignored receipt with before/after SHAs and hashes; the full temporary payload may be deleted only after the exact final-state verification succeeds. If reconciliation fails after mutation begins, retain enough exact payload/receipt data to recover and classify the state `RECOVERY_REQUIRED`; never report ordinary success.
  12. Keep local commits, `LAND PENDING`, unresolved transaction state, same-path upstream changes, staged changes, and unknown dirt out of this automatic path. Preserve them byte-for-byte and surface one actionable blocker.
  13. Do not make raw `behind N` an artist-facing workload metric. Structured UI state should mean:
      - successful launch reconcile -> `MAIN READY`;
      - short in-flight reconcile -> `UPDATING WORKBENCH` or equivalent;
      - unsafe reconcile -> `MAIN BLOCKED` plus one concise reason.
      Raw ahead/behind counts remain Tier-3 diagnostics for UX1/UX3.
  14. Preserve explicit Publish preparation as a second safety check. A later publish must re-inspect checkout/main/source freshness before canonical mutation even if launch reconciliation succeeded.
  15. Update the active Workbench design/docs from "existing startup is read-only" to the new bounded self-healing rule only after the behavior and focused tests land.
- Recommended implementation sketch:
  ```python
  def reconcile_for_launch(root, coordination_root, workspace_root):
      fetch_origin_main(root)
      state = inspect_launch_reconcile_state(...)
      if state.current:
          return CURRENT
      if state.ahead or state.pending_land or state.transaction:
          return BLOCKED(state.reason)
      if not state.dirty:
          ff_only_to_origin_main(root)
          repair_sparse_and_local_dependencies(root, coordination_root)
          return SYNCED

      owned = workbench_owned_dirty_paths(root, workspace_root)
      if state.dirty_paths - owned:
          return BLOCKED("unknown local changes")
      if state.has_staged_paths:
          return BLOCKED("staged local changes")
      if upstream_changed_any(root, state.dirty_paths):
          return BLOCKED("same-path upstream conflict")

      snapshot = snapshot_exact_local_state(root, state.dirty_entries, workspace_root)
      clear_only_snapshot_paths(root, snapshot)
      verify_clean(root)
      ff_only_to_origin_main(root)
      repair_sparse_and_local_dependencies(root, coordination_root)
      restore_snapshot_exact_bytes(root, snapshot)
      verify_restored_dirty_set_and_hashes(root, snapshot)
      finalize_recovery_receipt(snapshot)
      return SYNCED_PRESERVED
  ```
  This is guidance, not a requirement to use these exact private names.
- Preserve:
  - Dedicated persistent `workbench/operator-art` checkout and `operator-authoring-v1` sparse architecture.
  - Exact ignored Aseprite/Workbench document bytes.
  - Existing local-only LFS policy.
  - Existing source freshness checks.
  - Existing publication allowlist, transaction journal, rollback, commit, `LAND PENDING`, and `land_main.py` authority.
  - Unknown local user work and local commits.
  - Coordination-main checkout contents; this packet does not turn coordination main into tracked-publish authority.
- Non-goals:
  - No automatic publication of dirty art.
  - No automatic Aseprite Save.
  - No automatic discard of an unfinished Workbench.
  - No generic repository/worktree self-healing framework.
  - No rebase, broad reset/clean, or hidden stash/pop workflow.
  - No network LFS acquisition beyond the existing policy.
  - No animation resize, Fast-chain art correction, source/runtime schema change, or gameplay behavior change.
  - No UX Hierarchy redesign. UX1/UX3 only consume the structured result after this backend lands.
- Acceptance:
  1. Clean-behind launch fixture: reopening OPUI/ensure advances the existing dedicated checkout to fetched `origin/main` before launching the checkout-local UI code; ignored Workbench bytes remain byte-identical.
  2. Dirty Workbench-owned binary fixture: an existing 96px-equivalent tracked PNG is changed locally to distinct 128px-equivalent binary bytes while unrelated `origin/main` commits advance. Launch reconciliation snapshots it, FFs to current main, restores the exact local binary bytes, leaves that path dirty, and reports HEAD == origin/main with no data loss or manual cleanup.
  3. Multi-output fixture: source/runtime/timing/generated outputs provably belonging to one saved Workbench are preserved together; final dirty set equals the original allowed set and no unrelated path appears.
  4. Sparse proof: unrelated upstream game commits advance repository history but their materialized files remain absent when outside the sparse profile. `behind N` is proven to be repository-history distance, not an Operator-change count.
  5. Same-path conflict fixture: if origin/main changed one preserved local path, automatic reconciliation performs no checkout/base mutation and preserves the exact local bytes.
  6. Unknown-dirt fixture: one unrelated tracked or untracked user file prevents automatic dirty reconcile; no snapshot-clear/FF occurs and bytes remain unchanged.
  7. Staged-change fixture fails closed without changing index/worktree state.
  8. Ahead/diverged local-commit fixture remains preserved; no rebase/reset occurs.
  9. `LAND PENDING` and unresolved-transaction fixtures remain on their existing recovery paths and are never rewritten by background sync.
  10. Successful dirty reconcile leaves a verifiable ignored receipt with old/new SHAs and preserved-path hashes. Failed post-snapshot reconciliation retains recovery evidence and reports `RECOVERY_REQUIRED`.
  11. Publish preparation still rechecks readiness and source conflict before mutation after a successful launch reconcile.
  12. UI/service projection can distinguish current/synced-preserved/blocked/recovery-required without parsing `ahead N / behind N` text. Raw commit counts remain available in diagnostics only.
  13. No canonical Operator art is auto-published, no gameplay/runtime animation behavior changes, and no unrelated sparse file is materialized merely because main advanced.
- Validation:
  - Rewrite/extend `python3 custodian/tools/validation/operator_art_worktree_smoke.py` first:
    - replace `startup_read_only_smoke` with launch self-heal coverage;
    - replace the "dirty authoring content blocks all synchronization" expectation with exact-byte safe preserve/FF/reapply coverage;
    - add same-path conflict, unknown dirt, staged dirt, ahead commit, pending land, unresolved transaction, recovery receipt, and unrelated sparse-upstream cases.
  - Extend `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` for structured reconciliation projection and raw behind-count demotion.
  - Keep existing publish/mirror/recovery smoke(s) green to prove the publication transaction did not weaken.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json` after focused checks pass.
  - Run `python3 custodian/tools/agent/check_ai_context.py`.
  - Run `git diff --check`.
- Task overrides:
  - `TASK OVERRIDE: the user explicitly changes the prior read-only existing-checkout startup policy. OPUI startup may perform the bounded FF-only background reconciliation defined here when and only when exact Workbench-owned local bytes can be preserved and reverified; this does not authorize automatic publication, broad reset/clean/stash/rebase, or disposal of unknown local work.`
- Deferred:
  - UX1 owns final artist-facing wording/hierarchy for MAIN READY / MAIN BLOCKED and diagnostics disclosure.
  - UX3 owns Publish decision-surface wording after this backend is available.
  - General Git/worktree self-healing remains out of scope.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending execution`
- Root cause / contributing factors: `pending execution`
- Prevention / pipeline improvement: `pending execution`
- Tooling / docs drift discovered: `pending execution`
- Follow-up: `pending execution`
- What worked: `pending execution`

## Handoff

- Next workstream: `review-operator-workbench-background-base-sync`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Run the paired fresh-context post-land review before the browser/PREVIEW hardening packet becomes the next backend slice.`
- Blockers or open questions: `none`
