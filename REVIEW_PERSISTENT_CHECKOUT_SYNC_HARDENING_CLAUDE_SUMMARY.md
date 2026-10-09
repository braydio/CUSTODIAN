# Persistent Checkout Sync Hardening Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

Fresh-context review of landed implementation commit `58bab17248d444315cd8fa7785fe295acf31eb14` found one blocking workflow-performance defect, `R0-01`. The implementation's `_ignored_manifest()` reads and hashes every ignored file on every snapshot. The persistent project root reports 134,037 ignored entries; a read-only root status probe remained in `path.read_bytes()` hashing after more than 60 seconds and was interrupted. The implementation summary records about eight minutes for the same ignored-tree scan. This affects `csync status`, root apply, and OPUI startup's coordination sync attempt.

The correction and paired fresh-context re-review packets are ready. They restrict ignored-file checking to incoming candidate paths while retaining collision refusal and ignored Workbench byte checks. No implementation code was edited in this review.

Validation evidence:
- `python3 custodian/tools/validation/persistent_checkout_sync_smoke.py` — PASS: root sync and preservation, art sync/blockers, lock/race, ignored collision, shell routing.
- `python3 custodian/tools/validation/operator_art_worktree_smoke.py` — PASS.
- `python3 custodian/tools/agent/test_workstream.py` — PASS, 38 tests.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — PASS; optional Textual Pilot skipped because UI requirements are not installed.
- `bash -n tools/custodian_aliases.sh` and `git diff --check` — PASS.
- Read-only real-root status probe — INTERRUPTED after >60 seconds while hashing ignored files; `git ls-files --others --ignored --exclude-standard -z` reports 134,037 entries.

The focused fixtures substantiate the sync safety claims, but they did not expose the production ignored-tree scaling cost. The correction packet adds a large ignored-tree regression fixture.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: root status hashing did not finish within a minute because every ignored file was read.
- Root cause / contributing factors: `_ignored_manifest()` computes complete content hashes instead of checking only candidate paths.
- Prevention / pipeline improvement: correction cycle 1 adds path-scoped collision and ignored-byte verification with a large-tree fixture.
- Tooling / docs drift discovered: none
- Follow-up: persistent-checkout-sync-hardening-review-corrections-1
- What worked: temporary real Git repositories exercised fast-forward and destructive-safety behavior directly.

## Next Handoff
- Next workstream: persistent-checkout-sync-hardening-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Claim correction cycle 1, remove ignored-tree-wide hashing while retaining path-scoped collision safety, then run paired fresh-context re-review.
- Blockers or open questions: none
