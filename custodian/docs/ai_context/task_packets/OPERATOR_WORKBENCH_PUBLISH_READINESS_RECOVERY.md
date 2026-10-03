# OPERATOR WORKBENCH PUBLISH READINESS AND RECOVERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-publish-readiness-recovery`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-workbench-publish-readiness-recovery`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `44bf03388c`
- Goal: Make Operator Workbench publication behave as one self-preparing, fail-closed transaction from the artist's perspective: before canonical mutation begins, OPUI must know whether the exact selected animation can publish from the dedicated art checkout, perform only objectively safe preparation, surface actionable blockers once rather than serially, and leave Git in a clean or explicitly recoverable state after success or failure.
- Completion boundary: Add one authoritative publish-readiness/preparation contract spanning the persistent `workbench/operator-art` checkout, selected Workbench manifest, local-only LFS/materialization requirements, mandatory sparse validation dependencies, and import-sensitive Git metadata. Wire that contract into the existing Publish review/action so known-safe preparation happens before source mutation, stale/unsafe state fails before mutation, and publication-generated metadata churn is either transactionally restored or promoted to explicit `RECOVERY_REQUIRED`. Preserve the current scoped source→runtime transaction and `land_main.py` landing authority rather than introducing a second publisher.
- Current measured state:
  - `operator_art_worktree.py::ensure_art_worktree()` already fetches `origin/main`, fast-forwards only a clean idle art branch with `ahead == 0`, preserves dirty/ahead/diverged/`LAND PENDING` state, reapplies the per-worktree `operator-authoring-v1` sparse profile, and hydrates Operator source/runtime LFS PNGs from the local cache only.
  - `operator_art_worktree.py::publish_to_main()` refuses any pre-existing tracked or untracked dirt, then fetches `origin/main`, checks selected canonical paths for upstream source conflicts, executes the Workbench publisher, rejects changed paths outside a fixed allowlist, stages only allowed outputs, commits, and lands through the reviewed Operator publication handoff.
  - `_status_paths()` currently reports a flat path set. Publish therefore knows only “dirty” versus “clean”; it does not distinguish unknown user edits, `LAND PENDING`, an interrupted Workbench transaction, selected publication outputs, or machine-generated Godot import metadata.
  - `hydrate_operator_art_from_cache()` scans only `OPERATOR_LFS_GLOBS`. The sparse profile includes the game/tool/resource surface needed by mandatory validation, but there is no single pre-publish proof that every load-bearing tracked/LFS dependency for the current validation path is physically usable before canonical mutation starts.
  - `godot_import_preflight.py` correctly rejects checked-out Git LFS pointer text, but intentionally ignores sparse-omitted paths; it does not prove the Workbench sparse profile contains every resource that the mandatory Operator validation scenes will load.
  - Current main now also carries `operator_runtime_spriteframes_import_smoke.py`, which validates all 588 canonical Operator texture imports. The historical east/west `block_hold_01` invalid-sidecar defect was repaired by `e3d4e7f98` and the full-checkout modular-layer smoke passes; do not reimplement that repair in this packet.
  - The resumed sparse-correction workstream exposed a separate local-materialization gap: a sparse validation checkout can need LFS-backed dependencies that are not present in the shared LFS object cache even though the developer/coordination checkout already has the exact canonical bytes hydrated. Current docs previously said “local cache only” and did not define a safe donor-checkout fallback.
  - `animation_workbench.py::state()` detects existing manifest bindings whose recorded source hash changed or disappeared, and `ensure()` refuses `STALE`; however publication readiness is not projected as one structured result before the Publish transaction, and the existing Workbench/FX-adoption roadmap separately owns broader canonical binding-set evolution.
  - `animation_workbench.py::publish()` already journals and rolls back selected canonical source assets plus generated Operator resources. It does not own a Git-level preimage/postimage contract for unrelated tracked `.import`/`.uid` metadata that a project-wide Godot import can rewrite.
  - Production incident on 2026-10-01: publishing `unarmed/defense/block_hold_01` required serial manual recovery because the persistent art branch was behind `main` and dirty; old block-hold LFS images were not materialized; the saved Workbench baseline no longer represented the intended current canonical baseline; import/validation then exposed two missing audio resources; and the successful Godot import created unrelated tracked metadata churn that had to be cleaned before the publication could land. The animation ultimately landed at `affc8adb`, proving the art transaction can succeed but also showing that readiness failures are discovered too late and one-at-a-time.
  - Current design deliberately keeps the persistent art checkout and scoped publisher as the authority. This packet hardens that architecture; it does not replace it.
- Evidence:
  - `custodian/tools/operator/operator_art_worktree.py::{ensure_art_worktree,_ensure_sparse_and_current,hydrate_operator_art_from_cache,checkout_identity,_status_paths,publication_allowlist,publish_to_main,retry_pending_land}`
  - `custodian/tools/operator/animation_workbench.py::{state,ensure,refresh,publish,_godot_import,_validation_commands}`
  - `custodian/tools/pipelines/godot_import_preflight.py`
  - `custodian/tools/operator/ui/service.py::{publish_preview,publish}`
  - `custodian/tools/operator/ui/app.py::{_prepare_publish,_mutate}`
  - `custodian/tools/validation/operator_art_worktree_smoke.py`
  - `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - landed Operator publication `affc8adb` and the 2026-10-01 failure sequence above
- Task-specific authority:
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md` for canonical source, disposable Workbench, isolated checkout, reviewed Publish-to-Main, retry, and no-bypass boundaries.
  - `custodian/tools/operator/operator_art_worktree.py` for checkout identity, sparse profile, local LFS hydration, scoped staging, pending-land recovery, and landing.
  - `custodian/tools/operator/animation_workbench.py` for saved-document export, source/runtime transaction, generated resources, validation order, rollback journal, and selected Workbench source-contract freshness.
  - `custodian/tools/pipelines/godot_import_preflight.py` for project-import LFS pointer safety.
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md` for current sparse Workbench/Godot validation procedure and resource-budget rules.
  - `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` only as a boundary: that later packet owns CREATE-capable FX binding-set/adoption semantics. This packet may detect stale existing publication baselines but must not pre-implement general new-layer adoption.
- Work surface:
  - Primary owners: `custodian/tools/operator/operator_art_worktree.py`, `custodian/tools/operator/animation_workbench.py`, `custodian/tools/operator/ui/service.py`, and the narrow Publish projection/action in `custodian/tools/operator/ui/app.py`.
  - Supporting pipeline owner: `custodian/tools/pipelines/godot_import_preflight.py` only where a reusable read-only/materialization check belongs there rather than in Workbench-specific code.
  - Focused regression owners: `custodian/tools/validation/operator_art_worktree_smoke.py`, `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`, `custodian/tools/validation/operator_workbench_ui_smoke.py`, and existing Workbench validation fixtures.
  - Documentation: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `FILE_INDEX.md`, and `VALIDATION_RECIPES.md` only where live workflow truth changes.
- Change:
  1. Introduce one structured publish-readiness result owned by the Workbench service/art-worktree boundary. It must represent at least checkout identity, branch relation to `origin/main`, pending-land state, dirty-path classification, sparse-profile health, required local materialization/dependency status, selected Workbench source-contract freshness, and whether publication is ready, safely preparable, or blocked. Do not use free-form error parsing as state authority.
  2. Split readiness into a read-only inspection phase and an explicitly user-initiated preparation phase. Opening/refreshing the main browser must not mutate Git. Entering the Publish flow may run bounded safe preparation before the final review is shown; the final publish action must revalidate the same invariants immediately before canonical mutation to close the race.
  3. Preserve the current worktree identity contract. Publication remains enabled only from the dedicated `workbench/operator-art` checkout. Coordination `main`, arbitrary worktrees, detached HEADs, and unexpected branches remain non-publishing surfaces.
  4. Safe preparation may automatically:
     - fetch `origin/main`;
     - fast-forward `workbench/operator-art` only when it is clean, has no `LAND PENDING`, and is not ahead/diverged;
     - reapply the known sparse profile only when doing so is proven non-destructive by the existing profile rules;
     - materialize required LFS objects through the local-only resolver: use the existing Git LFS object cache first; when the cache lacks an object but the coordination/developer checkout has the same repository-relative path hydrated, reuse that donor only after its SHA-256 and byte size exactly match the target pointer's OID/size; never implicitly fetch from the network;
     - restore exact transaction-generated import metadata preimages after a Workbench-owned import only under the bounded rule below.
     It must never reset, rebase, stash, discard, force-checkout, or overwrite unknown user work.
  5. Replace flat “dirty checkout” reporting in the Publish path with deterministic categories. At minimum distinguish:
     - unknown/user tracked or untracked changes: block and preserve;
     - `LAND PENDING`: route to existing retry authority;
     - active/interrupted Workbench transaction state: report the journal and existing recovery path;
     - selected/allowed publication outputs: only legal inside the transaction that created them;
     - known import metadata churn generated by this publication's own Godot import: eligible for exact preimage restoration only when all restoration predicates pass.
     The implementation may choose private type/helper names, but callers and tests must consume structured categories rather than matching prose.
  6. Add a pre-mutation sparse/materialization dependency proof for the current mandatory Workbench validation path. Derive it from live validation/resource authority rather than a second hand-maintained list where practical. It must catch both checked-out LFS pointer stubs and tracked resources that the sparse Workbench promises to make available but that are physically missing/unusable before `publish()` replaces canonical source. If a legitimate mandatory dependency is missing from the sparse profile, fix the narrow profile dependency and test it; do not broaden to whole content trees as a shortcut.
  7. Local LFS behavior stays bandwidth-safe and deterministic. Resolve required LFS content in this order:
     - existing local/shared Git LFS object cache;
     - a trusted hydrated local checkout, normally the coordination checkout already supplied to the Operator worktree helper, but only for the same repository-relative path and only after SHA-256 + byte-size equality with the target LFS pointer;
     - explicit blocked state naming the missing path/OID.
     Donor-copy hydration must copy only verified LFS payload bytes, never adjacent tracked files, `.import` sidecars, generated resources, or donor checkout edits whose bytes do not match the target pointer. The target path must remain Git-clean after hydration. Do not call `git lfs pull` or `git lfs fetch`.
  8. Add an explicit selected-manifest freshness check before publication. For every existing publishing binding, compare the manifest's recorded source identity/path/hash/frame/canvas/timing contract required by the transaction with current canonical authority. A mismatch must produce `WORKBENCH REBASE/REFRESH REQUIRED` before export/source mutation unless the existing reviewed stale-source escape hatch is explicitly used. Do not silently rewrite an edited Workbench baseline. Do not implement the FX-adoption packet's general missing/new binding-set semantics here.
  9. Immediately before the Workbench-owned Godot import, record a bounded Git/preimage receipt sufficient to distinguish pre-existing state from metadata written by that import. After import/validation:
     - a tracked `.import` or `.uid` path outside the legitimate publication allowlist may be auto-restored only if it was clean before this transaction, was changed/created by this transaction's import window, is classified as Godot-generated metadata, and the exact pre-transaction bytes/existence state are known;
     - restoration must use the captured exact preimage or equivalent exact blob authority, never a wildcard repository reset;
     - record each restored path in the Workbench transaction/recovery receipt;
     - any unexpected non-metadata file, ambiguous provenance, failed restoration, or path that was dirty before the transaction must block as `RECOVERY_REQUIRED` and remain preserved.
  10. Strengthen failure postconditions. Before canonical mutation, a failed readiness/preparation step must leave tracked repository bytes unchanged except safe branch fast-forward/sparse materialization operations that are themselves the requested preparation. Once canonical mutation begins, existing source/runtime rollback plus the new metadata restoration must produce either:
      - a clean dedicated art checkout with the transaction marked rolled back; or
      - `RECOVERY_REQUIRED` with a journal naming every unresolved path and no automatic destructive cleanup.
      “Unexpected dirt; clean it manually” without provenance/journal is not an acceptable normal failure state.
  11. Project the readiness result into the existing Publish review UI without a cockpit redesign. The artist should see one compact readiness/preparation status and exact blockers before confirming Publish. Safe preparation may refresh that status; unknown/user dirt must never get a one-click destructive “clean” action.
  12. Preserve the existing source-conflict race check against fresh `origin/main`, exact publication allowlist staging, deterministic commit/landing, and resumable `LAND PENDING`. Readiness does not authorize more output paths.
- Preserve:
  - Persistent dedicated `workbench/operator-art` worktree and `operator-authoring-v1` sparse-profile architecture.
  - Coordination `main` as non-publishing authoring coordination checkout.
  - Canonical Operator source PNGs as authoring authority; generated runtime/catalog/resources remain projections.
  - Existing Workbench saved-document requirement, frame/canvas migration audits, transaction journal, source/runtime rollback, scoped publication allowlist, upstream selected-source conflict refusal, deterministic commit, `land_main.py` handoff, and pending-land retry.
  - User changes, unknown untracked files, dirty/ahead/diverged branches, and uncached LFS gaps are preserved/fail-closed rather than reset or fetched around.
  - Current gameplay/runtime animation behavior and pixels.
  - The future FX layer adoption packet's ownership of absent/new canonical binding creation and explicit layer-adoption semantics.
- Non-goals:
  - Do not redesign Git worktrees repository-wide or modify general agent workstream/landing semantics.
  - Do not replace the Operator publisher with Asset Pipeline V2 or a generic asset publisher.
  - Do not fetch Git LFS objects from the network.
  - Do not auto-stash, auto-rebase, auto-reset, force-checkout, delete unknown files, or add a generic “clean checkout” button.
  - Do not broadly materialize the full repository to make Godot happy; keep the sparse dependency closure measured and narrow.
  - Do not change Operator art, animation timing, hit windows, combat behavior, semantic identity, or mirror policy.
  - Do not implement general Workbench CREATE/new-layer adoption; `operator-workbench-fx-layer-adoption` owns that.
  - Do not make Godot `.import`/`.uid` files globally disposable. Only exact transaction-generated metadata with a proven preimage may be restored automatically.
  - Do not weaken mandatory import or Operator scene/runtime validation to make publication pass.
- Acceptance:
  - From a fixture dedicated art checkout that is clean, behind `origin/main`, and ahead by zero, Publish preparation fast-forwards safely before canonical mutation; ignored Workbench state survives and the selected session remains usable.
  - Dirty-state fixtures prove unknown tracked and untracked paths are reported individually, preserved byte-for-byte, and block before source export/mutation. No reset/stash/rebase/clean command is issued.
  - `LAND PENDING` is recognized as resumable state and uses the existing retry path without re-exporting Workbench pixels.
  - An interrupted/rolled-back Workbench transaction is classified separately from arbitrary dirt and reports its durable transaction journal/recovery status.
  - Fixture LFS cases prove: locally cached required objects can be materialized without network access; when cache content is absent, an exact hydrated coordination-checkout donor succeeds only when its SHA-256 and byte size match the target pointer; donor pointer/mismatch/missing cases fail closed; the target stays Git-clean; truly unavailable required objects block with actionable exact path/OID; publication preparation never invokes an LFS network fetch.
  - A fixture mandatory-validation dependency outside the original Operator PNG globs, including an audio/resource analogue, is detected as missing/unusable before canonical mutation. The final sparse dependency contract contains only the measured required addition, not a blanket content tree.
  - A stale existing Workbench source-contract baseline is rejected before export/canonical replacement and names the selected identity/path that drifted. A clean current baseline remains publishable. Edited Workbench pixels are not silently discarded by freshness repair.
  - A fixture Godot-import subprocess that modifies unrelated clean tracked `.import`/`.uid` metadata is followed by exact preimage restoration; those paths are recorded as restored and the checkout is clean after a successful publication.
  - Negative controls prove that pre-existing dirty metadata, ambiguous non-metadata output, or a changed path without a known preimage is never auto-restored and instead produces `RECOVERY_REQUIRED`.
  - Injected downstream failure after source replacement restores selected source/runtime/generated resources and transaction-generated metadata to their exact pre-transaction bytes, leaving either a clean checkout or a durable `RECOVERY_REQUIRED` journal with exact unresolved paths.
  - Successful fixture publication still stages only `publication_allowlist()`, commits once, lands through the existing approved Operator publication path, verifies reachability from fresh `origin/main`, and leaves no stray tracked/untracked publication residue.
  - Publish review/UI projects READY / safe-preparation-required / blocked state without requiring the artist to infer Git/LFS/import state from terminal errors.
  - Existing sparse-worktree, mirror-publish, Workbench UI, and animation-workbench regressions remain green.
  - No Operator source/runtime pixels or gameplay behavior change as part of this tooling packet.
  - Documentation describes the same readiness/recovery contract that tests and runtime tooling enforce, including the prohibition on destructive automatic Git cleanup.
- Validation:
  - Extend and run `python3 custodian/tools/validation/operator_art_worktree_smoke.py` first with fixture-isolated cases for clean-behind preparation, dirty classification/preservation, local-cache LFS success, verified hydrated-donor fallback, donor hash/size mismatch refusal, truly unavailable LFS failure, pending-land routing, and clean-or-recovery failure postconditions.
  - Extend and run `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` with import-metadata preimage restoration, ambiguous-output negative controls, source/runtime rollback, and same-named generated-resource backup safety.
  - Extend and run `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` for structured readiness projection and blocked/safe-preparation/ready Publish review states without canonical source mutation.
  - Run `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` for existing source-contract/stale-workbench behavior and transaction invariants.
  - Run `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian` only after fixture/local-only materialization setup has proven required checked-out LFS assets are hydrated. Cache and verified donor-checkout hydration are allowed; network LFS fetches are not.
  - Run the current narrow Operator compatibility/modular-layer validation selected by the Workbench publication recipe, then one `python3 custodian/tools/validation/run_validation.py --changed --json` closeout sweep and `git diff --check`.
  - No renderer captures or model-vision review are required; all acceptance is Git, filesystem, contract, transaction, and validation-state behavior.
- Task overrides: `none`
- Deferred:
  - General new canonical layer/source creation and saved `vfx`/`fx` adoption remain in `operator-workbench-fx-layer-adoption`.
  - Repository-wide Git worktree self-healing, general Godot import-sandboxing, and non-Operator publisher cleanup remain separate architecture work.
  - Network LFS acquisition remains explicit human/operator action outside the Workbench.
  - Page-3/PREVIEW asynchronous refresh safety is the next dedicated packet `operator-workbench-browser-preview-refresh-hardening`.

## Plan

1. Reproduce the recent failure classes in fixture-isolated publication tests before changing production code.
2. Establish the structured readiness/classification model and read-only inspection.
3. Add bounded safe preparation and selected-manifest/materialization checks before source mutation.
4. Add import-window preimage capture/restoration and clean-or-`RECOVERY_REQUIRED` postconditions.
5. Project readiness into Publish review, then rerun focused fixture publication and UI regressions.
6. Reconcile Workbench design/current-state/index/validation docs and close through normal workstream lifecycle.

## Handoff

- Next action: Auto-claim `operator-workbench-publish-readiness-recovery` after the sparse-checkout correction review dependency completes.
- Best starting files: `custodian/tools/operator/operator_art_worktree.py`, `custodian/tools/operator/animation_workbench.py`, `custodian/tools/operator/ui/service.py`, `custodian/tools/validation/operator_art_worktree_smoke.py`.
- Blockers or open questions: None requiring user design judgment. Safe automatic actions are deliberately limited to clean FF sync, existing sparse-profile application, local-only LFS materialization (cache first, exact verified hydrated donor second), and exact transaction-generated metadata restoration with proven preimages.

## Completion Truth

Required before completion.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes | no`
- Completion boundary satisfied: `yes | no`
- Acceptance satisfied: `yes | no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: fill with exact implemented files and focused validation results

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none` or concrete failures/near-misses
- Root cause / contributing factors: `none` or concise cause
- Prevention / pipeline improvement: `none` or smallest repeatable fix
- Tooling / docs drift discovered: `none` or exact stale/missing authority
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`
- What worked: optional, one short line at most