# Committed PASS closeout correction

Workstream: `agent-paired-review-committed-pass-closeout-correction-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933

## Change

Replaced the undefined `_passing_outcome_error` call in the committed-review closeout path. The coordinator now parses the archived outcome with `review_outcome.parse_review_outcome` and uses `outcome_identity_error` for exact PASS identity checks.

For this coordinator-only continuation, run and cycle identity are taken from the exact preserved `continuation-01/metadata.json`. The coordinator cross-checks the original run, single reviewer launch and successful exit, verified dispatcher receipt, continuation branch/worktree/packet, target and implementation pins, recovery plan digest, original run evidence manifest, and preserved supervisor lock inode/device. Optional host-evidence run/cycle fields are checked when supplied and may be absent when continuation metadata authenticates them.

The reviewer PASS is authenticated from the preserved continuation session itself. Its invocation must be an ephemeral Codex reviewer launch, the JSONL must contain one completed thread/turn, and the full saved final message must match the exact redacted/truncated `safe_output()` transformation from runner/redactor sources pinned at the reviewed main. The resulting thread ID and JSONL/final-message SHA-256 digests must equal the preserved recovery-plan session record. The reviewer-authored final must support PASS; its canonical archived outcome, receipt and summary are verified separately. The recovery plan corroborates the reviewer evidence but does not establish the PASS by itself.

The regression exercises a committed, clean reviewer branch and verifies `_finish_via_workstream` is reached only for the fully bound PASS, including a saved final longer than the JSONL sanitizer's 1,200-character limit. Adversarial cases cover missing, malformed, findings and human-required outcomes; incorrect outcome and continuation identities; inconsistent claim evidence; foreign continuation; mismatched optional host fields; changed lock provenance; tampered full final; arbitrary prefix capture; mutually consistent but replayed session files; dirty worktree; and out-of-scope commit. Rejected cases preserve Git HEAD and do not invoke lifecycle finish.

## Validation

- `test_paired_review_runner`: 273 tests passed.
- `WorkstreamTests.test_finish_rejects_unbound_archive_followup_before_push`: passed.
- `py_compile` for the runner and its test module: passed.
- `git diff --check`: passed.

Independent fresh-context review, exact-head CI, conditional merge, and the original protected same-claim closeout remain the next gates.
