# Paired Review Host Validation: Braced Work Surface Paths V1

Workstream: `agent-paired-review-braced-work-surface-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## Delivered

- Added bounded brace-list expansion for backtick-delimited repository-relative file paths in the archived target packet's `Work surface` field. Directory segments and filename alternatives are literal; names must be unique and count 2–32; suffixes must be implementation suffixes. Invalid, nested, absolute, traversal, wildcard, duplicate, oversized, or unsupported forms fail closed.
- Applied only the exact expanded paths to the existing documented path set. Existing trace identity, source-span, archive, file-mode, validation coverage, and post-validation hash checks remain in force. Existing literal-path, markdown, and filename fallback behavior was not broadened.
- Added table-driven malformed-input coverage and synthetic source-bearing Git fixtures for the seven-file MF1 list, omitted and extra paths, basename/prefix lookalikes, and declarations outside `Work surface`.
- Added a read-only regression against the local MF1 source/archive landing. It resolves base `55918d257cb3c663fb066f56eb79b23d174b7ae2` to `645f1a701696045149fbf9dd3c988cbbadfcf06b` through trace run `20261019T111751Z-bc1d9d1546fb`.

## Evidence

- `PYTHONPATH=custodian/tools/agent python3 -m unittest test_paired_review_runner.PairedReviewHostValidationTests`: 41 tests passed.
- `run_validation.py --changed --json`: 2 selected, 2 passed, 0 failed.
- `compileall` and `git diff --check`: passed.
- The original MF1 review claim, worktree, archived packet, and run evidence were not modified. The correction itself does not apply the protected MF1 recovery plan or create a reviewer verdict.

## Rough edges

The suggested dotted unittest invocation could not resolve sibling imports in this checkout; adding `custodian/tools/agent` to `PYTHONPATH` ran the intended class successfully. The fresh worktree also needed `.ai/` created before redirecting validation JSON.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial test import and report redirection commands needed fresh-worktree setup.
- Root cause / contributing factors: The unit test imports sibling coordinator modules directly; `.ai/` is absent until created.
- Prevention / pipeline improvement: Document/use the working `PYTHONPATH` invocation and create `.ai/` before report redirection.
- Tooling / docs drift discovered: none beyond the braced-path recognition defect fixed here.
- Follow-up: none
- What worked: Synthetic archive fixtures exercised authorization and provenance through the real resolver, with a read-only positive check against MF1's pinned landing.

## Next Handoff

- Next workstream: review-agent-paired-review-braced-work-surface-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Refresh reason: none
- Next action: Run the independent paired review; after it passes, resume the original MF1 review through its exact same-run host-validation recovery plan.
- Blockers or open questions: Original MF1 review remains protected in `host_validation_recovery`; this implementation does not apply its continuation or claim a reviewer verdict.
