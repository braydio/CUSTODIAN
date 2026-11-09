# Paired-review closeout coverage policy

- Packet schema: `custodian.task_packet.v2`
- Workstream: agent-paired-review-closeout-coverage-policy-v1
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-paired-review-closeout-coverage-policy`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: review-agent-paired-review-closeout-coverage-policy-v1
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: The correction changes a pinned-evidence trust boundary in coordinator closeout. A fresh independent review must verify that excluded paths use only the immutable reviewed-main policy and that malformed or forged evidence still fails closed.
- Reviewed main: `0100d8a2af1c0378006a4f01fd6801a4104b41f2`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Visual review: `none`
- Goal: Make coordinator-side verification accept valid host-validation reports with policy-excluded files by authenticating their coverage against the immutable reviewed-main manifest.
- Completion boundary: Correct `_verify_host_validation_at_commit()` and add focused regression coverage for its pinned policy path. Complete the normal implementation validation and land this workstream so its paired fresh-context review can verify the behavior. Do not alter the preserved failed validation report or close out the separate protected review in this workstream.
- Current measured state: On `origin/main` `0100d8a2af1c0378006a4f01fd6801a4104b41f2`, `_verify_host_validation_at_commit()` calls `_validate_report(report, expected_span.get("paths") or [])` without a coverage manifest. A guarded continuation of preserved review run `20261030T140657Z-02779c6591d9` rejected its otherwise green report with `host validation exclusions have no pinned coverage policy`. The adjacent `verify_coordinator_validation()` loads `_pinned_coverage_manifest(repo, reviewed_main)` and supplies it.
- Evidence: `custodian/tools/agent/paired_review_runner.py` (`_verify_host_validation_at_commit`); `custodian/tools/agent/paired_review_host_validation.py` (`_pinned_coverage_manifest`, `_validate_report`, and `verify_coordinator_validation`); `custodian/tools/agent/test_paired_review_runner.py`; preserved continuation `20261030T140657Z-02779c6591d9` reports original host validation passed 4/4 with complete coverage and report SHA-256 `32f05572c0cb9912abfe74fc9ad854204c25568c721b373846459a5d9855b932`. That host-private run is preservation evidence, not a required publication input.
- Task-specific authority: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; focused tests in `custodian/tools/agent/test_paired_review_runner.py`. Change other host-validation files only if a focused test proves a narrowly necessary shared seam; do not change the pinned coverage policy.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/validation/run_validation.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (all already tracked at the reviewed main SHA).
- Change: In `_verify_host_validation_at_commit()`, load the canonical manifest with `host_validation._pinned_coverage_manifest(repo, reviewed_main)`. If that helper raises `HostValidationError`, pass `None` so `_validate_report()` retains its fail-closed behavior when exclusions require unavailable policy. Otherwise pass the immutable reviewed-main manifest as the third `_validate_report()` argument. Match `verify_coordinator_validation()`; never source policy from the working tree, report JSON, arbitrary current main, or a synthetic replacement.
- Preserve: Original validation report/provenance bytes and their digests; hash-bound source verification, source-span identity, complete selected-test ownership, and existing canonical exclusion policy; the separate protected review claim, worktree, lock, reviewer PASS, `continuation-01`, and run evidence for `review-agent-paired-review-excluded-coverage-evidence-recovery-v1` / `20261030T140657Z-02779c6591d9`.
- Non-goals: Do not edit or reclassify historical report bytes; do not invoke or retry the protected review runner from this implementation; do not launch a reviewer for that old review; do not release its lock; do not broaden coverage exclusions, create workstream-specific policy, weaken hash/digest checks, or implement unrelated recovery behavior.
- Acceptance: (1) A report containing the canonical excluded JSON path passes `_verify_host_validation_at_commit()` only when the genuine manifest loaded from the exact `reviewed_main` authorizes that exclusion. (2) Missing or malformed pinned policy with claimed exclusions fails closed. (3) Fabricated, extra, duplicate, overlapping, or wrong-baseline exclusions fail; changed/mismatched manifest, source hashes, report/provenance digests, or source-span identity fail. (4) Missing covered-file test ownership and failed or timed-out validation remain nonpassing. (5) Tests prove source policy is read from `reviewed_main`, not the working tree or report JSON. (6) The preserved report/provenance bytes remain unchanged. (7) Existing hash-bound source verification and complete selected-test coverage remain enforced.
- Validation: Add focused regression coverage for `_verify_host_validation_at_commit()` in `custodian/tools/agent/test_paired_review_runner.py`, including the canonical excluded-file positive case and adversarial policy/source-integrity failures. Run `python3 custodian/tools/agent/test_paired_review_runner.py`, `git diff --check`, and the workstream's required focused validation/closeout checks. A failed or timed-out validation is not a pass.
- Task overrides: `none`
- Deferred: After this implementation and its fresh independent paired review are accepted, return to the preserved run `20261030T140657Z-02779c6591d9`. Only a separately authorized, fail-closed coordinator-only retry may verify and land its existing reviewer PASS; do not relaunch that reviewer or mutate its original report.

## Execution instructions

Claim only after the dispatcher confirms published eligibility and a coordinator decision authorizes execution. Use the normal isolated workstream lifecycle, keep the source change limited to the pinned-manifest argument and focused tests, and complete the normal validation and landing steps before the paired post-land review. Preserve the separate protected recovery claim throughout.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `custodian/tools/agent/paired_review_runner.py` now loads the coverage manifest pinned to immutable `reviewed_main` and passes it to `_validate_report()`; eight direct regression cases cover authenticated positive policy and fail-closed adversarial cases; the original report/provenance bytes are asserted unchanged. Focused regression suite passed 8 tests, full paired-review runner suite passed 218 tests, canonical changed-file validation passed both selected test groups with complete coverage, and `git diff --check` passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `none`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: Canonical changed-file validation confirmed complete ownership and passed both selected suites.

## Handoff

- Next workstream: review-agent-paired-review-closeout-coverage-policy-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: none
- Next action: Await separate coordinator authorization before claiming the fresh-context paired independent review.
- Blockers or open questions: Execution remains withheld until the dispatcher confirms published eligibility and a subsequent matching coordinator decision authorizes it.
