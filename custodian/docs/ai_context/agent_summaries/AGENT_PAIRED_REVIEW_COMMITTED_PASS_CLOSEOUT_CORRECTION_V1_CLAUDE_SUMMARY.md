# Committed PASS closeout correction

Workstream: `agent-paired-review-committed-pass-closeout-correction-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933

## Change

PR #104 adds fail-closed authentication for a committed review PASS. The coordinator binds the original reviewer session to source-pinned `safe_output()`/`redact()` capture behavior, exact JSONL and final-message digests, one completed reviewer turn, immutable claim and continuation identity, and the archived outcome. It uses the existing `_host_validation_claim_receipt` resolver for the historical 1,200-byte `claim.stdout` plus complete structured receipt.

Session command failures are classified separately. Exploratory `rg` no-match and parser-import errors do not fail a session by themselves. Fatal session errors, contradictory verdicts, non-empty continuation stderr, and an unrecovered required profile dependency failure hold closeout. The guard detects the original required failure inside an exit-zero combined shell event. The protected original PASS remains unaccepted; the new code does not author or reinterpret reviewer evidence.

## Protected review and source-pinned profile assessment

The protected review remains `review-agent-paired-review-runner-profile-summary-coverage-v1`, run `20261031T154752Z-1243f08594ef`, claim `20261031T154805Z-601d4382c346`. Its original run remains `claim_profile_mismatch`; its single reviewer launch and `continuation-01` evidence are preserved. The original run manifest matches its saved continuation metadata; the lock remains device/inode `66306:10653181`; protected worktree HEAD is `81fb8ca935bb2d5f9f00f18d547c185035e7b8dd` and clean. A read-only canary returns HOLD for the unrecovered required profile dependency failure.

At reviewed baseline `e1bff4eb3360e7f0fcdbc5bb67fa86bc2b600f4f`, using the source-identical runner blob `a47de5cc082561edaa4e3597cc8a57e43d76e9c6e92f5edd9654cdee2d4bc98d`:

- A1 PASS: the profile adds exactly `AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1_CLAUDE_SUMMARY.md` and `AGENT_PAIRED_REVIEW_RUNNER_PROFILE_SUMMARY_COVERAGE_V1_CLAUDE_SUMMARY.md`; no include paths are removed and other profile keys are unchanged.
- A2 PASS: the JSON profile parses with 49 includes and digest `fc632cc325cb3cfc5fb4567be2de91ae46a103c378ca5405165b2589fd6428f6`; the pinned tree inventory accepts 2,319 entries.
- A3 PARTIAL / overall HOLD: exact runner validation for the profile-summary review passes with 399 required paths and zero uncovered. Exact validation for the active grammar review packet and its archived implementation target fails because that active review packet also declares the absent active implementation path `custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1.md`. Only the archived implementation target is tracked. Removing the stale extra declaration in memory yields 401 required paths with zero uncovered, but this counterfactual is not a validation of the unchanged published packet.
- A4 PASS: this correction performed no dispatcher claim and launched no reviewer. The protected run still records one reviewer launch; no active reviewer process was found.
- A5 PASS: the archived grammar implementation packet is byte-identical between commits `57f796040cc3e3a51a213b529a2baeeef6fa9627` and `e1bff4eb3360e7f0fcdbc5bb67fa86bc2b600f4f` (SHA-256 `8b4711579df6aa06743fc5f1570578430cd4a2f2d0e4acb72ba322a02fb46160`). The profile correction commit changes none of the grammar implementation files.

The previous wrong active implementation path is recorded as a stale declared input/test-path error, not as a successful validation. The grammar review's A3 dependency closure remains unsatisfied and the original PASS remains HOLD.

The repository's exact `--recover-checkout-profile-mismatch` plan/apply route is not currently eligible: its guards require the original run's initial evidence manifest and no existing continuation, while this protected run already contains `continuation-01`. Ordinary `--continue-run` is restricted to `post_exit_recovery`, not this run's `claim_profile_mismatch` phase. No claim, lock, packet, or reviewer evidence was changed to bypass those guards. A governance decision is needed to establish the smallest supported resolution for the stale published dependency and existing continuation before any fresh reviewer can be launched.

## Validation

- `test_paired_review_runner`: 274 tests passed.
- `WorkstreamTests.test_finish_rejects_unbound_archive_followup_before_push`: passed.
- `py_compile` for runner and tests: passed.
- `git diff --check`: passed.
- Original exact-run read-only canary: HOLD for required profile dependency failure.
- PR #104 is still unmerged at published head `904dcf5f2bac3f66245d3fc221c4a6e6c7581073`; the corrected head, fresh-context code review, and exact-head CI are pending.

## Handoff

RC-123 authorizes only the defensive guard on PR #104, followed by fresh-context exact-head review and green CI before a normal conditional merge. Do not run coordinator finish on the protected original claim. Preserve its claim, evidence, worktree, and lock until a separately authorized supported recovery path is established.
