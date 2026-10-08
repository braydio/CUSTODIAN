# Persistent Checkout Sync Hardening Review Corrections 1 — Independent Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

## Findings first

- **R0-01: fixed.** The correction replaces full ignored-tree enumeration and SHA-256 hashing with `_candidate_state` checks for incoming changed paths and their ancestors. The inspected state captures path kind, tracked status, and skip-worktree state for signature revalidation. No new blocking defect or material evidence gap was found; no cycle-2 correction packet is needed.

## Evidence

- `run_validation.py --test persistent_checkout_sync --json`: passed with 1/1 selected checks, complete report schema. `persistent_checkout_sync_smoke.py`: all eight groups passed. The ignored-tree fixture contained 2,048 unrelated files; ignored listing, traversal under the fixture directory, and all file-content reads were trapped while status plus safe sync ran. It completed in 0.09s.
- The same fixture passed exact ignored-file, ignored-directory, and sparse skip-worktree overlay collision checks; all preserved HEAD and protected bytes. Dirty/ahead/diverged preservation, pending/recovery/Aseprite, lock/race revalidation, shell routing, and FF-only behavior passed in the real temporary-Git fixtures.
- `operator_art_worktree_smoke.py`: passed.
- `test_workstream.py`: 38 tests passed.
- `operator_workbench_ui_smoke.py`: passed service projections, dry-run safety, and discovery checks. Optional Textual pilot skipped because UI requirements are unavailable.
- Live persistent-root read-only status: CURRENT in 0.252s. Prior durable correction evidence measured 134,037 ignored entries and 0.226s. I did not enumerate the live root's ignored tree.
- Merge retains `GIT_LFS_SKIP_SMUDGE=1`; the reviewed diff adds no LFS acquisition or destructive Git operation.

## Friction and limits

`/usr/bin/time` is unavailable in the environment; shell `time` supplied the live-root timing. The optional Textual pilot could not run without its declared optional UI requirements. These do not weaken the reviewed acceptance evidence.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: `/usr/bin/time` unavailable; optional Textual pilot dependencies unavailable.
- Root cause / contributing factors: local tool and optional environment dependency gaps.
- Prevention / pipeline improvement: shell timing used; no fixture changes required.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: focused fixture independently trapped ignored-tree listings, directory walks, and content reads while proving collision guards.

## Next Handoff
- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Review chain complete; no correction cycle required.
- Blockers or open questions: none
