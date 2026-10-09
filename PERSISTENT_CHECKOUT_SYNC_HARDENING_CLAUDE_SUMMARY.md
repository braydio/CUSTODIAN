# Persistent Checkout Sync Hardening

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

Implemented one shared persistent-checkout sync authority for coordination `main` and the Operator art worktree. The CLI provides read-only status and guarded apply operations, reports structured checkout state and exact blockers, serializes mutations with an advisory lock, revalidates immediately before fast-forward, and only uses `merge --ff-only`. Git hooks are disabled during the mutation and LFS smudging is skipped. Dirty, ahead, diverged, detached, wrong-branch, pending-publication, recovery, and Aseprite-open states are preserved.

Integrated the helper into workstream teardown, Operator art publication sync, and normal OPUI startup. OPUI attempts root synchronization before resolving its persistent art checkout and synchronizes art before launching the UI; blockers are projected into the mounted UI state. Added `csync` and `opui-sync` wrappers while keeping Git policy in Python. Updated current-state, lifecycle, and workbench documentation to describe the new automatic safe-sync boundary.

The focused fixture smoke proves root/art current and behind paths, idempotency, preservation blockers, ignored-byte hashes, concurrent lock contention, race rejection, shell routing, and OPUI status projection. The first changed-file sweep found missing validation ownership for the new smoke; after registration, its first run found the fixture assumed the bare remote's default branch was `main`. The fixture now explicitly checks out `main` before creating remote commits.

Validation run before closeout:
- `python3 custodian/tools/validation/persistent_checkout_sync_smoke.py` — all seven groups passed after the fixture correction.
- `python3 custodian/tools/validation/operator_art_worktree_smoke.py` — passed.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — passed; optional Textual pilot skipped because `custodian/tools/operator/ui/requirements.txt` is not installed.
- `python3 custodian/tools/agent/test_workstream.py` — 38 tests passed.
- `python3 -m py_compile ...`, `bash -n tools/custodian_aliases.sh`, and `git diff --check` — passed.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — passed, 25/25 selected tests, complete changed-file coverage; report: `/tmp/persistent-checkout-sync-hardening-validation.json`.

No pixel/art outputs were changed. No ignored state or user checkout data was changed by implementation validation; all Git sync fixtures use temporary repositories. No known blockers remain.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The initial changed-file sweep rejected the unregistered smoke, then exposed a bare-remote default-branch assumption in the new fixture.
- Root cause / contributing factors: The validation manifest had no owner mapping for the standalone smoke, and fixture clone behavior depended on the bare repository's symbolic HEAD.
- Prevention / pipeline improvement: Registered the test and explicitly selects `main` in its donor repository.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Isolated temporary repositories made sync safety, races, and byte preservation directly measurable.

## Next Handoff
- Next workstream: review-persistent-checkout-sync-hardening
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Run the paired fresh-context review of the landed implementation.
- Blockers or open questions: none
