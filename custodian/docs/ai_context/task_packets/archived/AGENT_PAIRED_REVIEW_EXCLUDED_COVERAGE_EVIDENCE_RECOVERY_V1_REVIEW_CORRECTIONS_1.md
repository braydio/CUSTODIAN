# Correction: Authenticate attested manifest changes during paired-review continuation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-pinned-manifest-continuation-correction`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `This correction changes the trust boundary for pinned source attestations and validation-manifest policy; a fresh independent review must falsify both accepted and adversarial continuation paths.`
- Reviewed main: `28a887ce55628c3516a52af24c7084e156f9be1a`
- Parent implementation: `agent-paired-review-excluded-coverage-evidence-recovery-v1`, archived at `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_EXCLUDED_COVERAGE_EVIDENCE_RECOVERY_V1.md`
- Parent review: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1`, active preserved claim pinned to its original run; its reported PASS remains unaccepted until canonical closeout.
- Findings addressed: `OWNER-01, OWNER-02` (project-owner-authorized corrective defects; these are not retroactively attributed to the preserved review's PASS, which recorded no findings).
- Affected acceptance: Authenticated source-span continuation reports must use consistent pinned coverage policy in failed-report authentication, successful-report validation, and continuation closeout; attested manifest changes may not widen global policy.
- Current measured state: The pinned Procession source-span attestation names `validation_manifest.json`; its test-definition delta does not change `coverage_excludes`. The original report remains host-validation failed before reviewer launch. A prior fresh review of the coverage correction reported PASS with no findings, but canonical acceptance is still blocked at closeout.
- Current defect/evidence: The preserved Procession run `20261023T150519Z-8f6f90e681a3` is blocked before reviewer launch. Its exact source-span attestation includes `custodian/tools/validation/validation_manifest.json`, while the pinned `coverage_excludes` policy is unchanged and a test definition is changed. `_validate_canonical_coverage()` rejects every changed validation manifest, and at least one successful continuation verification calls `_validate_report()` without the manifest pinned to `reviewed_main`.
- Goal: Make all paired-review continuation paths consistently authenticate coverage using the immutable reviewed-main policy while permitting only attested test-definition changes that preserve that policy.
- Completion boundary: Correct the pinned manifest/source-span validation and report-verification seams with adversarial regression tests. Land one implementation correction, obtain its fresh paired independent review and canonical acceptance, then stop. Do not recover or apply the preserved coverage/Procession plans in this workstream.
- Evidence: `paired_review_host_validation.py`, `paired_review_runner.py`, `run_validation.py`, `validation_manifest.json`, the Procession source-span attestation `road_procession_p1_source_scope_v1.json`, and preserved run metadata/reports. The Procession report identifies a test-definition delta while baseline `coverage_excludes` is unchanged.
- Task-specific authority: Root and `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/AGENT_CORRECTION_PACKET_TEMPLATE.md`; original excluded-coverage implementation/review packets; `custodian/tools/validation/run_validation.py`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; focused fixtures/tests in `custodian/tools/agent/test_paired_review_runner.py`; only the exact manifest and attestation comparison helpers required by those tests.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/validation/run_validation.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/review_scope_attestations/road_procession_p1_source_scope_v1.json`, and `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (all tracked at reviewed main).
- Required correction: (OWNER-01) Authenticate original/revised validation manifests from the exact `reviewed_main` and attested source-span base Git revisions. Reuse `run_validation.py` manifest comparison and changed-test selection, require manifest self-checks, and accept test-definition edits only when canonical selection and ownership are complete and the baseline global policy is unchanged. (OWNER-02) Load and pass the authenticated `reviewed_main` coverage manifest through every failed-report authentication, successful-report validation, and continuation-closeout call to `_validate_report`; absent, malformed, mismatched, or unauthenticated policy fails closed. Validate exact path inventory, blobs/modes, ancestry, attestation identity, selected tests, owners, exclusions, uncovered files, and complete report/digest accounting consistently.
- Preserve: Both original review claims, worktrees, locks, run IDs, reviewer verdicts, report/provenance bytes, and all original evidence; `coverage_excludes` and other global validation policy; pinned reviewed-main/source-span identities; dispatcher and reviewer independence gates.
- Non-goals: Do not apply either existing recovery plan; change a preserved run, report, verdict, claim, lock, worktree or reviewed-main pin; broaden policy exclusions; trust checkout-current manifests, report-supplied policy or synthetic manifests; weaken hashes, modes, ancestry, digests, selected test ownership, or complete coverage; alter Procession gameplay/runtime code; create another workstream or global recovery mechanism.
- Acceptance: (1) Valid attested manifest test-definition changes with unchanged baseline `coverage_excludes` pass exact-revision comparison and canonical changed-test selection. (2) Excluded source-hashed attestation documents are classified using only the pinned baseline policy. (3) All failure, success and continuation closeout paths use the same authenticated policy object. (4) Forged/missing attestation, mismatched manifest hash/content, changed exclusion/global policy, malformed/duplicate/removed test definitions, bogus selection, missing owner, incorrectly excluded Python, extra/overlapping/uncovered paths, altered report digests, changed claim/worktree metadata, failed validation, and timeout are rejected. (5) The preserved original reviewer verdict and every original evidence byte remain unchanged. (6) Focused tests and full runner tests pass; canonical changed-file validation is complete.
- Validation: Add positive and negative fixtures for each case above to `python3 custodian/tools/agent/test_paired_review_runner.py`; run that complete paired-review runner suite, canonical `run_validation.py --changed` from the pinned base, packet authoring and pairing checks, and `git diff --check`. Record test outputs and immutable fixture hashes without altering `.git/custodian-review-runs` evidence.
- Task overrides: `none`
- Deferred: Same-run recovery of the two preserved reviews, including Procession run `20261023T150519Z-8f6f90e681a3`; these remain explicitly gated on this correction's formal independent PASS and lifecycle closeout.

## Handoff

- Next workstream: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f`
- Next action: Fresh independent review of the landed correction; only after its canonical acceptance may either preserved recovery plan be generated/applied.
- Blockers or open questions: No preexisting canonical R-cycle findings exist because the original review recorded a PASS; OWNER-01/OWNER-02 retain the task owner's explicit attribution and must not be represented as historical reviewer findings.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: The validator now compares the manifest at the exact source-span base with the immutable reviewed-main manifest, authenticates the Procession attestation and manifest blob/mode, rejects global policy changes, and applies canonical test selection/coverage in failed-report, successful-report, and closeout paths. After synchronizing with current `origin/main`, the paired-review runner suite passed 252 tests and canonical changed-file validation passed all 3 selected checks with complete coverage. The runner used a process-local 360-second timeout; no shared manifest or validation policy changed. A separate fresh post-land review is required before either preserved recovery plan may be considered.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The repository's default 120-second budget timed out on the 247-test paired-review runner suite. The canonical changed-file validation was rerun with a process-local 360-second timeout; no shared manifest or validation policy was changed.
- Root cause / contributing factors: The runner suite takes approximately 155 seconds on this host.
- Prevention / pipeline improvement: Consider revising the paired-review runner test's manifest timeout in a separately scoped validation-manifest change if this duration is expected to persist.
- Tooling / docs drift discovered: The current runner timeout is shorter than the measured full-suite duration.
- Follow-up: `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`; after formal acceptance, resume only the exact preserved same-run review continuations.
- What worked: Exact Git revision reads, a verified attestation, and report-path regression tests kept the exception narrow and auditable.
