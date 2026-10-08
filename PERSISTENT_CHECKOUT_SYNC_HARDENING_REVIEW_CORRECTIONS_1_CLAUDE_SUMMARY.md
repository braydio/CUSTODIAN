# Persistent Checkout Sync Hardening Review Corrections 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

Closed blocking finding R0-01 from the paired review. Persistent sync no longer enumerates or hashes all ignored files. It now checks only incoming tracked paths and their ancestors, recording path type, tracked status, and `skip-worktree` state for race revalidation. Exact ignored/untracked destinations, directory collisions, sparse skip-worktree overlays, and non-directory ancestors block before fast-forward. Unrelated ignored siblings are outside the incoming path set, so Git's FF-only update leaves them in place without inspecting their contents.

The smoke now covers an ignored file collision, an ignored directory collision, a tracked sparse `skip-worktree` overlay, and an unrelated ignored tree of 2,048 files. The performance fixture fails if sync enumerates ignored paths, walks the ignored directory, or reads any file contents. Its status+sync completed in 0.08 seconds. The live root status probe returned CURRENT in 0.226 seconds despite 134,037 ignored entries.

Validation:
- `python3 custodian/tools/validation/persistent_checkout_sync_smoke.py` — all eight groups passed; ignored fixture status+sync 0.08s.
- `python3 custodian/tools/validation/operator_art_worktree_smoke.py` — passed.
- `python3 custodian/tools/agent/test_workstream.py` — 38 tests passed.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — service/UI smoke passed; optional Textual pilot skipped because its requirements are not installed.
- Live root `status root` probe — CURRENT in 0.226s.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — passed 2/2 tests with complete coverage.
- `python3 -m py_compile ...`, `bash -n tools/custodian_aliases.sh`, and `git diff --check` — passed.

The first fixture expectation assumed read-only status fetched the remote. It correctly uses the existing tracking ref, so the test now checks CURRENT before apply and then proves apply fetches and synchronizes. No root ignored files were changed during the live probe.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial fixture conflated read-only status with remote-fetching apply behavior.
- Root cause / contributing factors: Status is intentionally read-only and classifies the local tracking ref.
- Prevention / pipeline improvement: Fixture separates read-only status from apply/fetch and traps ignored traversal/content reads.
- Tooling / docs drift discovered: none
- Follow-up: review-persistent-checkout-sync-hardening-review-corrections-1
- What worked: Candidate-scoped collision checks preserve safety and make live status bounded by incoming path count rather than ignored-tree size.

## Next Handoff
- Next workstream: review-persistent-checkout-sync-hardening-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Run the paired fresh-context review of correction cycle 1.
- Blockers or open questions: none
