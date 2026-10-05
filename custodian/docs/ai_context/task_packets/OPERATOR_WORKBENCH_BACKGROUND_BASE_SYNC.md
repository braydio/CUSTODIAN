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
- Review rationale: `persistent authoring-checkout lifecycle and interrupted-publication finalization change across a Git/pixel safety boundary`
- Reviewed main: `7cfa2c12f5a99a90bfe087117856d16c92f8772a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Make normal `opui` startup keep the persistent sparse `workbench/operator-art` checkout current without artist intervention whenever synchronization is provably safe, including automatically finishing a previously user-approved publication that validated its canonical outputs but was interrupted before Git commit/landing. Routine repository lag must not pin both art and checkout-local Workbench code to an old revision.
- Completion boundary:
  - Existing-checkout startup becomes a bounded self-healing lifecycle rather than an inspection-only boundary.
  - Clean ahead-zero lag fast-forwards automatically.
  - Existing `LAND PENDING` is retried automatically when its current exact-identity proof still passes.
  - A new durable **publication-finalization receipt** bridges the current gap between a successful Workbench transaction and the existing Git commit/`LAND PENDING` receipt. If a user-approved publication has already validated and its dirty postimage is exact, startup resumes finalization rather than leaving canonical outputs dirty indefinitely.
  - The currently stranded Fast 01 96px -> 128px publication residue is inspected once during this workstream. If the existing COMMITTED Workbench transaction, saved manifest, current dirty set, hashes and upstream path history prove it is exactly a previously approved/validated publication awaiting Git finalization, finish it through the same scoped commit/landing path. If that proof does not hold, preserve it and report the exact blocker rather than guessing.
  - Unknown dirty work, staged/index changes, local commits ahead of main, unresolved Workbench transactions, source/postimage mismatch, same-path upstream conflicts, or incomplete recovery proof remain fail-closed blockers. Do not generically carry arbitrary dirty bytes across a base update.
  - Do not change animation art semantics, runtime/gameplay animation behavior, source/runtime naming, or the UX Hierarchy visual redesign beyond exposing structured reconciliation state for later UX packets.
- Current measured state:
  - `tools/custodian_aliases.sh::opui` invokes current coordination-main `operator_art_worktree.py ensure`, then launches `operator_cli.py ui` **from the returned art checkout**. Therefore an art checkout that is behind main also runs an older copy of OPUI code.
  - `operator_art_worktree.ensure_art_worktree()` explicitly leaves an existing attached art checkout untouched at startup; only initial creation fetches/advances it.
  - `prepare_publish_checkout()` can fetch/FF only after readiness proves no dirty paths, no pending land, no unresolved transaction, no source-freshness blocker and no local commits ahead of main.
  - `animation_workbench.publish()` requires a clean Git pre-state, writes exact source/resource/import preimages, validates canonical mutation, then marks its local transaction journal `COMMITTED` before returning changed targets.
  - `operator_art_worktree.publish_to_main()` runs **outside** that Workbench transaction. After `publish_once()` returns, it discovers the Git dirty set, validates the allowlist, stages, commits, writes `publish_land_pending.json`, then lands. There is currently no durable outer receipt before the Workbench transaction returns. A process/session interruption after Workbench `COMMITTED` but before Git commit leaves validated canonical outputs dirty with no automatic resume path.
  - `operator_art_worktree_smoke.py::startup_read_only_smoke()` currently asserts reopening OPUI does not synchronize Git. `sparse_sync_smoke()` asserts dirty authored/canonical content blocks all synchronization.
  - Checkout identity renders repository ancestry as `ahead N / behind N`. `behind 256` means 256 repository commits behind `origin/main`; it does **not** mean 256 Operator animation changes. Sparse checkout constrains the materialized file set, not commit ancestry, so many commits may concern unrelated game systems.
  - User-observed live case: the persistent art checkout still contains Fast 01 publication changes replacing 96px sheets with 128px sheets. Those tracked changes prevent the existing clean-only FF path and therefore keep checkout-local Workbench code behind main.
  - Existing publish-readiness/recovery already proves exact rollback/preimage behavior and `LAND PENDING` identity. This packet must extend that proof chain, not replace it with generic stash/reset behavior.
- Evidence:
  - `tools/custodian_aliases.sh::opui`
  - `custodian/tools/operator/operator_art_worktree.py::{ensure_art_worktree,_ensure_sparse_and_current,_status_paths,_dirty_categories,checkout_identity,inspect_publish_readiness,prepare_publish_checkout,publication_allowlist,upstream_source_conflicts,publish_to_main,retry_pending_land}`
  - `custodian/tools/operator/animation_workbench.py::{publish,_journal_stage,_verify_rollback_preimages}`
  - `custodian/tools/operator/ui/service.py::{checkout_identity,readiness,publish_preview,publish}`
  - `custodian/tools/validation/operator_art_worktree_smoke.py::{startup_read_only_smoke,sparse_sync_smoke,readiness_classification_smoke,launcher_smoke}`
  - `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - archived `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` plus its paired review
  - `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_CLAUDE_SUMMARY.md`
- Task-specific authority:
  - `operator_art_worktree.py` remains the sole owner of persistent art-checkout Git/sparse/startup/landing lifecycle.
  - `animation_workbench.py` remains the sole authority for the canonical art mutation transaction and its source/resource/import preimage/postimage proof.
  - A new finalization handshake may bridge those two authorities, but it must not create a second publisher.
  - `origin/main` remains repository base truth. This persistent branch may only advance by the existing FF/serialized landing semantics; no rebase/reset-history path is introduced.
  - Canonical source PNGs remain source authority. Ignored `.ai/operator_animation_workbench/` receipts/backups are recovery evidence only.
- Work surface:
  - Primary: `custodian/tools/operator/operator_art_worktree.py`.
  - Transaction handshake: `custodian/tools/operator/animation_workbench.py`.
  - UI orchestration/projection: `custodian/tools/operator/ui/service.py` and, only if a new typed projection is needed, `custodian/tools/operator/ui/state.py`.
  - Required focused tests: `custodian/tools/validation/operator_art_worktree_smoke.py`, `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`, and `custodian/tools/validation/operator_workbench_ui_smoke.py`.
  - Launcher: `tools/custodian_aliases.sh` only if the existing `ensure` exit/output contract cannot carry the new lifecycle cleanly.
  - Validation ownership: `custodian/tools/validation/validation_manifest.json` only if current owner coverage does not select all changed helpers/tests.
  - Active docs after behavior lands: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, and `custodian/docs/ai_context/FILE_INDEX.md`.
- Change:
  1. Add one structured launch reconciliation result below the existing art-worktree lock. Recommended public shape, private names flexible:
     ```python
     @dataclass(frozen=True)
     class LaunchReconcileResult:
         status: str  # current | synced | finalized_and_synced | blocked | recovery_required
         before_relation: str
         after_relation: str
         finalized_identity: dict[str, str] | None
         blocker: str | None
         receipt: str | None
     ```
     UI/service code must not parse human `ahead N / behind N` strings to decide workflow state.
  2. Introduce a durable ignored outer finalization receipt, for example:
     ```text
     .ai/operator_animation_workbench/publish_finalize_pending.json
     ```
     Schema recommendation:
     ```json
     {
       "schema": "custodian.operator_art_publish_finalize.v1",
       "state": "mutation_authorized|validated_outputs_pending_git|git_committed|land_pending|landed|recovery_required",
       "identity": {"profile":"...","group":"...","action":"...","direction":"..."},
       "branch": "workbench/operator-art",
       "base_head": "<sha>",
       "origin_main_at_start": "<sha>",
       "canonical_paths": ["..."],
       "allowlist": ["..."],
       "mirror": false,
       "transaction_journal": "<workspace-relative journal path or null>",
       "validated_outputs": [{"path":"...","exists":true,"size_bytes":0,"sha256":"..."}],
       "commit": null
     }
     ```
     The exact schema may be cleaner, but it must bind explicit user publication intent, base identity, scoped paths, exact validated postimages and transition to the existing landing receipt.
  3. `publish_to_main()` must write the outer receipt **before** invoking canonical mutation, after checkout/source readiness and the user-selected identity/allowlist are known. It must never create this receipt merely from opening OPUI or viewing Publish.
  4. Extend the Workbench transaction commit boundary so a successful `animation_workbench.publish()` exposes durable finalization proof before returning. Preferred seam: record in its COMMITTED transaction journal the Git base HEAD, semantic identity, final exact Git-visible postimage path set and per-file existence/size/SHA-256 after validation/metadata restoration. If keeping that data in the outer receipt is cleaner, use an atomic callback/handshake that is written as part of the COMMITTED transition rather than leaving an unprotected process-crash gap.
  5. After the Workbench transaction reaches COMMITTED, `publish_to_main()` updates/validates the outer receipt, confirms the current dirty set is exactly the approved publication allowlist/postimage set, stages only that set, commits with existing deterministic summary rules, moves to the existing `LAND PENDING` identity, and lands as today. On success, mark/remove the finalization receipt only after landed reachability is proven.
  6. Add `resume_pending_publication_finalize()` (name flexible) for startup/recovery:
     - require dedicated art branch;
     - fetch `origin/main`;
     - verify outer receipt schema/identity/base and corresponding COMMITTED Workbench transaction;
     - verify every current dirty path is declared and every declared postimage hash/size/existence matches;
     - reject staged paths not created by the verified resume step;
     - check that `origin/main` has not changed any canonical/published path since the receipt's base;
     - if proof passes, stage only the verified set, commit using the recorded semantic identity, create/update existing landing receipt, and call the existing serialized landing authority;
     - if proof fails, mutate nothing and report a precise blocker or `RECOVERY_REQUIRED`.
  7. Existing `LAND PENDING` should be an automatic launch-resume candidate. Reuse `retry_pending_land()` and its stable publication identity. If its proof passes, retry landing without asking the artist to click Publish again. If it fails, preserve the receipt/branch and surface the blocker.
  8. After pending publication/landing recovery, if the art checkout is clean and `ahead == 0`, fetch/FF-only to current `origin/main`, reapply/verify the current sparse profile, and perform the existing local-only exact LFS/dependency preparation. Ignored Workbench/Aseprite workspace bytes must remain unchanged.
  9. A dirty checkout **without** a verifiable finalization/landing receipt is not a generic auto-sync candidate. Do not snapshot arbitrary dirt and carry it across main. Preserve it exactly and return `blocked`. This includes unknown tracked/untracked user work, staged changes, unresolved transactions and local commits.
  10. Add a bounded legacy recovery path for the user's current Fast 01 residue created before the new outer-receipt schema:
      - inspect the latest relevant saved Workbench manifest and COMMITTED transaction journal;
      - reconstruct only the exact expected source/runtime/timing/generated-resource output set using current publication contracts/allowlist;
      - require current dirty set to equal that reconstructed set with no staged/unknown paths;
      - require source target hashes and generated-resource hashes recorded by the journal to match; derive runtime/timing postimages only through the same deterministic current pipeline/manifest evidence, not by directory prefix;
      - require no upstream change to any affected canonical path since the transaction/base;
      - record a one-time recovery receipt before mutation;
      - only if all evidence proves "validated publication awaiting Git finalization", finish the existing publication through scoped commit/landing and then sync current main.
      If any proof is missing or contradictory, leave the live art checkout untouched and report the exact evidence gap. Do not classify age or filename alone as proof.
  11. Preserve existing Workbench failure recovery. PREPARED/SOURCE_SWAPPED/RUNTIME_BUILT/GODOT_IMPORTED/RESOURCES_BUILT/VALIDATED/RECOVERY_REQUIRED transactions do not become Git-finalization candidates unless the canonical Workbench transaction itself reaches its proven COMMITTED boundary.
  12. Keep the finalization receipt and transaction journal linked. A normal successful publication should end with no stale "pending" receipt. A failure after canonical mutation must leave either verified rollback or durable recovery evidence sufficient to explain every remaining dirty path.
  13. Artist-facing state must not use raw commit distance as workload. Backend/service projection should expose:
      - `MAIN READY` after current/synced/finalized-and-synced;
      - optional brief `UPDATING WORKBENCH` while a bounded launch reconcile is actually executing;
      - `MAIN BLOCKED` plus one concise reason for an unsafe state.
      Raw branch/ahead/behind/sparse details remain diagnostic.
  14. Preserve explicit Publish preparation and immediate pre-mutation revalidation as independent safety gates. Background launch recovery is not permission to skip source freshness, dependency audit, compatibility preflight, publication allowlist, validation or landing checks.
  15. Update active Workbench docs from "existing startup is read-only" to the new bounded self-healing contract only after focused implementation evidence passes.
- Recommended implementation sketch:
  ```python
  def reconcile_for_opui_launch(root, coordination_root, workspace_root):
      fetch_origin_main(root)

      if land_pending_receipt(root, workspace_root):
          result = retry_pending_land(root, land_pending_path(...))
          if not result:
              return BLOCKED("pending landing could not be proven")
          fetch_origin_main(root)

      if finalize_pending_receipt(root, workspace_root):
          result = resume_pending_publication_finalize(...)
          if result.status not in {"landed", "already_landed"}:
              return result
          fetch_origin_main(root)

      state = inspect_checkout(root, workspace_root)
      if state.dirty or state.transaction or state.ahead:
          return BLOCKED(state.concise_reason)

      if state.behind:
          ff_only_to_origin_main(root)
      repair_sparse_profile(root)
      hydrate_required_lfs_locally(root, coordination_root)
      verify_clean_and_current(root)
      return SYNCED if state.behind else CURRENT
  ```
  Publication-side handshake recommendation:
  ```python
  receipt = begin_finalize_receipt(identity, base_head, canonical_paths, allowlist)
  changed_sources = publish_once()  # Workbench transaction must durably reach COMMITTED
  postimages = prove_validated_postimages_from_committed_transaction(...)
  update_finalize_receipt(receipt, "validated_outputs_pending_git", postimages)
  stage_only_verified_postimages(...)
  commit = commit_scoped_publication(identity)
  promote_to_land_pending(receipt, commit)
  landed = retry_pending_land(...)
  finish_finalize_receipt_only_after_reachability(landed)
  ```
  These are behavioral recommendations, not mandatory private names.
- Preserve:
  - Dedicated persistent `workbench/operator-art` sparse checkout and `operator-authoring-v1` profile.
  - Exact ignored Aseprite/Workbench workspace bytes.
  - Existing local-only LFS policy.
  - Existing source freshness, publication allowlist, validation and compatibility gates.
  - Workbench transaction preimages/rollback and `RECOVERY_REQUIRED`.
  - Existing commit/`LAND PENDING`/serialized `land_main.py` authority.
  - Unknown local user work and local commits.
  - Coordination-main checkout contents; coordination main does not become tracked-publish authority.
- Non-goals:
  - No publication merely because a path is under Operator source/runtime directories.
  - No auto-publication of ordinary unapproved dirty files.
  - No automatic Aseprite Save.
  - No generic dirty-byte carry-forward across main.
  - No broad `git reset --hard`, `git clean`, hidden stash/pop, rebase or force push.
  - No generic repository/worktree self-healing framework.
  - No network LFS acquisition beyond existing policy.
  - No animation resize, Fast-chain art correction, source/runtime schema change or gameplay behavior change.
  - No UX Hierarchy redesign. UX1/UX3/UX5 consume the structured result after this backend lands.
- Acceptance:
  1. **Clean behind:** reopening `opui` advances an existing clean ahead-zero art checkout to fetched `origin/main` automatically before checkout-local UI code launches; ignored Workbench bytes are byte-identical.
  2. **Interrupted validated publication:** fixture starts with a user-authorized finalization receipt + COMMITTED Workbench transaction + exact dirty source/runtime/resource postimages but no Git commit. Launch verifies all bytes, stages only the declared set, commits, lands, removes/resolves pending receipts, and ends clean/current without another Publish click.
  3. **Crash-window proof:** interruption at every meaningful boundary between finalization-receipt creation, Workbench COMMITTED, postimage receipt, Git commit and LAND PENDING either resumes deterministically or fails closed with complete recovery evidence. No state silently becomes ordinary unknown dirt.
  4. **Fast 01 live recovery:** the current 96px -> 128px Fast 01 residue is either proven byte-for-byte as a validated previous publication and finalized/landed, or preserved untouched with a precise evidence gap. Merely having Fast 01 filenames/128px dimensions is insufficient proof.
  5. **Sparse history semantics:** unrelated upstream game commits may increase raw `behind N`, but sparse-omitted unrelated files remain absent. Tests/documentation explicitly prove the number is repository commit distance, not animation-change count.
  6. **Same-path upstream conflict:** if `origin/main` changed any affected canonical path since the pending publication's base, automatic finalization/base sync performs no commit/landing and preserves all local bytes/receipts.
  7. **Unknown dirt:** unrelated tracked or untracked user changes with no verified pending-publication ownership block background sync without mutation.
  8. **Staged dirt:** pre-existing staged/index changes fail closed without altering index or worktree.
  9. **Ahead/diverged local commit:** preserved; no rebase/reset/automatic history rewrite.
  10. **Unresolved Workbench transaction:** any non-COMMITTED/ROLLED_BACK unresolved state stays on existing transaction recovery and is not Git-finalized.
  11. **LAND PENDING:** a valid pending receipt auto-retries landing; invalid identity/proof stays preserved and blocked.
  12. **Publish remains safe:** a normal new publication still runs readiness/source/conflict/preflight/validation checks, exact allowlist staging and serialized landing. The new resume path cannot broaden the staged set.
  13. **UI projection:** service/state can distinguish current/synced/finalized-and-synced/blocked/recovery-required without parsing raw `ahead N / behind N` text. Routine safe lag resolves to `MAIN READY`; raw commit counts are diagnostics only.
  14. No canonical Operator art is changed by the background-sync mechanism except completing a separately proven, previously user-authorized publication. No gameplay/runtime animation semantics change.
- Validation:
  - Rewrite/extend `python3 custodian/tools/validation/operator_art_worktree_smoke.py` first:
    - replace `startup_read_only_smoke` with clean launch self-heal;
    - add interrupted-COMMITTED-publication resume;
    - simulate crash windows across receipt/transaction/commit/landing boundaries;
    - add same-path conflict, unknown/staged dirt, ahead commit, unresolved transaction, valid/invalid LAND PENDING and unrelated sparse-upstream cases.
  - Extend `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` so direct/mirror transactions expose exact finalization postimages and retain rollback guarantees.
  - Extend `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` for structured reconciliation projection and raw behind-count demotion.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json` after focused checks pass.
  - Run `python3 custodian/tools/agent/check_ai_context.py` and review-pairing validation.
  - Run `git diff --check`.
- Task overrides:
  - `TASK OVERRIDE: the user explicitly changes the prior read-only existing-checkout startup policy. OPUI startup may automatically fast-forward a clean ahead-zero art checkout, retry a previously authorized LAND PENDING receipt, and finish a previously user-authorized Workbench publication only when durable transaction/finalization evidence proves the exact validated postimages and scoped Git operation. This does not authorize publishing arbitrary dirty files, broad reset/clean/stash/rebase, or disposal of unknown local work.`
  - `TASK OVERRIDE: during this workstream, inspect the user's existing persistent art checkout and attempt the one-time Fast 01 stranded-publication recovery described above. Mutate it only if the exact existing transaction/postimage/upstream proof passes; otherwise preserve it and report the blocker.`
- Deferred:
  - UX1 owns final artist-facing MAIN READY / MAIN BLOCKED hierarchy.
  - UX3 owns Publish decision-surface wording after this backend is available.
  - UX5 owns final cross-mode consistency and diagnostic demotion.
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
- Next action: `Run the paired fresh-context post-land review before the browser/PREVIEW hardening packet becomes eligible.`
- Blockers or open questions: `none`
