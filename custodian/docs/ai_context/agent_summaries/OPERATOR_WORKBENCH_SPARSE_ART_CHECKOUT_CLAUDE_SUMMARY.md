# Operator Workbench Sparse Art Checkout — Completion Summary

Implemented the per-worktree `operator-authoring-v1` sparse profile and safe synchronization for the persistent `workbench/operator-art` checkout. New worktrees are sparse before checkout. Existing clean, idle checkouts fast-forward only when they have no local commits ahead, no pending landing, and no dirty paths. Dirty/ahead/pending legacy checkouts fail closed with their changed paths. The UI now reports sparse profile health and checkout state.

## Evidence

- The measured profile has 85 path patterns. A temporary proof checkout materialized 9,706 non-cache files at 334 MB; after Godot import it measured 16,010 files / 534 MB including `.godot/`. Unrelated enemy art, reports, and asset-drop inputs stayed absent. Exact referenced audio and image files were present while same-directory siblings stayed omitted.
- The live `CUSTODIAN-operator-art` checkout was not migrated: OPUI is still running and the checkout has 7,915 dirty tracked paths. Its 2,216 ignored `.ai/operator_animation_workbench` files (109,261,361 bytes) all matched the pre-migration SHA-256 manifest. No live `.ai` or art files were changed.
- The root CUSTODIAN checkout still has unrelated dirty work, so post-land root synchronization may need to remain pending.
- Disk cleanup increased free space to 118 GB (87% used). Six clean CUSTODIAN worktrees were moved to Trash. Trash could not be fully emptied because it contains a root-owned protected `Override-RSA/creds` directory; no privilege escalation was attempted.

## Validation

- Passed: `operator_art_worktree_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, `operator_workbench_mirror_publish_smoke.py`, compatibility-resource `--check`, animation-contract report, Godot editor import after cache initialization, and `operator_modular_layers_smoke.gd` from the temporary sparse checkout.
- `operator_animation_contract_report.py`: 60/63 present, 0 required missing, 3 optional missing.
- The required changed-unit gate ran but was not green: unrelated `review_pairing_contract` findings remain on `origin/main` for a stale Awakening validation-script reference and the preexisting malformed sparse-checkout review packet. The changed Operator tests passed after local LFS hydration of test fixtures.
- `git diff --check` passed.

## Files Changed

- `custodian/tools/operator/operator_art_worktree.py`
- `custodian/tools/operator/ui/service.py`
- `custodian/tools/validation/operator_art_worktree_smoke.py`
- `custodian/tools/validation/validation_manifest.json`
- `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Task packet archived at `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`; active index updated.
- `custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md` received the exact bounded post-land review override required by the repository validator.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: Godot's live project/autoload graph required a wider sparse dependency profile than the initial cone estimate; fresh import produced transient UID-cache warnings. The changed-unit gate exposed unrelated stale packet metadata on `origin/main`.
- Root cause / contributing factors: The modular Operator smoke initializes the normal project resource graph, and the review-pairing validator checks ready packets against `origin/main`.
- Prevention / pipeline improvement: Keep fixture coverage for exact file dependencies and same-directory exclusions; repeat the focused smoke after Godot's first import populates its cache.
- Tooling / docs drift discovered: On this host, Git LFS checkout can rewrite the tracked post-commit hook; scoped hydration now restores its exact bytes. The preexisting live art checkout must wait for its dirty tracked state and running OPUI session before in-place sparse migration.
- Follow-up: manual-follow-up
- What worked: Local-cache LFS hydration and isolated sparse validation avoided changing production art or the user's workbench files.
