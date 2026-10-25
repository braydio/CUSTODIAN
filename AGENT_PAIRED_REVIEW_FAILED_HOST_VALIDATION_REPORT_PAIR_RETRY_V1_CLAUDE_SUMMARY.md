# Failed Pre-review Host-validation Report Retry

Workstream: `agent-paired-review-failed-host-validation-report-pair-retry-v1`

## Outcome

The paired-review runner now admits bounded same-claim retry for complete,
authenticated failed pre-review host-validation report pairs. The prior
workstream/run exception is removed. Original reports remain immutable, report
and metadata hashes are pinned in the plan, and retry attempts remain
append-only under the existing two-attempt limit. Retry attempts must retain
the pinned main and implementation identity, canonical `--changed --base
<implementation-parent> --json` invocation, clean source bytes, complete
coverage, and zero reviewer launches. Reviewer launch remains gated on a
genuinely green canonical host-validation result.

Regression coverage uses temporary real Git repositories to accept a complete
failed test report pair, bind its source hashes to committed and checkout bytes,
and reject incomplete coverage, mismatched report hashes, source drift, prior
reviewer execution, changed original evidence, changed attempt reports, and
retry exhaustion. The existing exact import-sidecar recovery test remains
green.

## Investigation Evidence

The protected run `20261025T034024Z-5cc171b374a4` is a normal failed validation,
not an import failure. Its report SHA-256 is
`dd7d2ca69555b73f3b8b9926b12016fd56cd343d6b17788a77b7201ff321a455`; its
coordinator metadata SHA-256 is
`0f673735c1174b2464680ea3550620f7de80e54b51400968941325d9d3e3d00d`. It
selected 15 checks: 13 passed, one failed, one was skipped after the unit-tier
failure. `operator_2_5d_review` failed its renderer assertion after 90.372
seconds. Import had completed and reported 13 generated artifacts. The
manifest at correction landing `482cd88edc5490c83f34f1793dea39ccfb0f3977`
already had `operator_2_5d_review.needs_import: true` and `timeout_sec: 180`.
No manifest change was needed.

The failed report pair is now classified by the runner as
`failed_validation`; source identity matches the exact pinned checkout at
`482cd88edc5490c83f34f1793dea39ccfb0f3977`, and that checkout remains clean.
No retry or reviewer launch has yet modified the protected run.

## Validation

- Paired-review runner suite: 186 tests passed.
- Canonical `paired_review_runner_unit`: passed, 186 tests, 54.340 seconds.
- Changed-file validation: passed both selected checks with complete coverage:
  `agent_workflow_contract` and `paired_review_runner_unit`.
- Python compile checks and `git diff --check`: passed.
- Moment Forge: not run — runner tooling change has no runtime or presentation effect.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The existing retry admission accepted only one historical import failure, while the protected run contains a complete ordinary test-failure report pair.
- Root cause / contributing factors: The retry path coupled its eligibility to a workstream/run constant and an import-specific exception instead of authenticating the pre-review report pair and source identity.
- Prevention / pipeline improvement: Retry admission now validates report completeness, exact source/provenance hashes, claim identity, source cleanliness, reviewer count, original evidence manifest, and finite attempt history before retry.
- Tooling / docs drift discovered: A prior `needs_import: false` diagnosis contradicts both the manifest at the implementation landing SHA and the preserved host report. At that SHA, `needs_import` was true and the timeout was 180 seconds; the actual failure was the `operator_2_5d_review` renderer assertion.
- Follow-up: fixed-in-scope
- What worked: The preserved report pair and immutable source hashes identified the actual failure without altering the run.

## Next Handoff

- Next workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Land this runner correction, then plan and apply the exact same-claim host-validation retry for run `20261025T034024Z-5cc171b374a4`. Launch the fresh independent reviewer only after full validation passes. After acceptance, resume the primary review run `20261025T032358Z-3b242f79acdc` and complete its review and closeout.
- Blockers or open questions: none
