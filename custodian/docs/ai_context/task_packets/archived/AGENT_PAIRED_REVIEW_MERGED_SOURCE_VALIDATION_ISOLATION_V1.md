# Paired Review Merged-Source Validation Isolation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-merged-source-validation-isolation-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-paired-review-merged-source-validation-isolation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-merged-source-validation-isolation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Host-validation source-span and failed-report classification jointly govern whether a protected reviewer can launch; both provenance and fail-closed behavior need an independent review.`
- Reviewed main: `cbf38b479381255e8f56d59998a0313a62f1a017`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
- Visual review: `none`
- Goal: Make paired-review host validation measure the exact authenticated implementation source span and safely recognize a coverage-only validation failure so unrelated later-main changes cannot strand a protected review or make incomplete coverage appear green.
- Completion boundary: Correct source-span selection and coverage-only failed-report authentication in the paired-review host recovery path; add real-Git and adversarial regression coverage; land the implementation and its durable evidence. Do not run recovery apply or launch the protected reviewer.
- Current measured state: Protected review `review-agent-paired-review-archived-receipt-capture-recovery-v1`, claim run `20261031T024502Z-72cdecbbefd8`, is held before reviewer launch. Host run `20261031T024441Z-9c08b75951b6` selected 9 checks and all passed, but exited 6 with incomplete coverage and 13 uncovered paths. Its source-validation range included unrelated later-main Operator 3D files: those paths occur in `f848228723513d21412aee0fdbd6bec6514db4e8..33b4f73468d221034f4df2edd62c548a33effce3`, but not in implementation-only `f848228723513d21412aee0fdbd6bec6514db4e8..1f7c71191dc69ab61a8eed155533def427c41bcf`. The recovery planner's current failed-host-report authentication supports test/import failures but not this exact coverage-only exit-6 report. The original run's tool output from one read-only planner invocation is unavailable after context compaction and must not be reconstructed or repeated.
- Evidence: Preserved local host evidence under `.git/custodian-review-runs/review-agent-paired-review-archived-receipt-capture-recovery-v1/20261031T024441Z-9c08b75951b6/`; host report SHA-256 `5cf51bbcf58dad3759852345153c8788e2c9108be9969b43aa8fdcef4faab9b4`; immutable implementation/landing SHAs above; current source `paired_review_host_validation.py`, `paired_review_runner.py`, canonical validation runner and manifest, and their tests.
- Task-specific authority: This packet; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, and `custodian/tools/agent/test_paired_review_runner.py`; update canonical validation ownership only if required to test the correction without weakening existing manifest exclusions or completeness rules.
- Publication inputs: custodian/tools/agent/paired_review_host_validation.py, custodian/tools/agent/paired_review_runner.py, custodian/tools/agent/test_paired_review_runner.py, custodian/tools/agent/workflow_control.py, custodian/tools/agent/review_outcome.py, custodian/tools/agent/review_receipt_delta.py, custodian/tools/validation/run_validation.py, custodian/tools/validation/validation_manifest.json, custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md, custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md, custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md, custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json, custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md
- Change: Derive the validation inventory from authenticated provenance for the exact implementation source-bearing span, excluding unrelated later-main merges while retaining every actual implementation source path. Authenticate a coverage-only failed host report only when exit code is 6, the test/summary inventory is complete and internally consistent, every selected check passed, the uncovered inventory is exact and nonempty, source and claim/run/main identities are verified, and original report bytes/hash are preserved. The result remains a failed/incomplete validation state; it may support only an explicitly authorized, append-only same-run recovery plan and later apply. Preserve canonical manifest ownership and ordinary coverage-completeness requirements.
- Preserve: The held review claim, lock, branch, worktree, pinned target and evidence; all original host-run files byte-for-byte; existing failed-test/import recovery semantics; exact source provenance, validation manifest ownership, reviewer independence, explicit plan/apply authorization, and all unrelated workstreams.
- Non-goals: No recovery apply, reviewer launch/relaunch, claim/lock release, verdict acceptance, source-scope attestation exception, manifest exclusion weakening, broad validation bypass, historical report rewrite, or cleanup of protected files/worktrees.
- Acceptance: (1) Real temporary-Git histories prove source-bearing changes are derived from authenticated implementation provenance and omit unrelated later-main paths. (2) An actual implementation source path cannot be hidden as unrelated or omitted from required coverage. (3) The exact coverage-only exit-6 report shape is authenticated as a failed/incomplete report only with a complete consistent summary, all selected checks passing, exact nonempty uncovered inventory, matching source/claim/run/main identities and original report digest. (4) The correction cannot convert incomplete coverage to a passing validation or launch a reviewer without the existing separate plan/apply and review gates. (5) Reject forged, partial, conflicting, stale, tampered or replayed provenance/report evidence; wrong run/claim/target/main; incomplete test inventory; exit/summary disagreement; modified original bytes; repeated continuation; missing required coverage; changing remote refs; and any unauthorized reviewer relaunch. (6) Existing source-span and manifest exclusion cases remain intact; canonical manifest ownership is not broadened to accommodate unrelated files. (7) Original protected claim, lock, worktree and run files remain unchanged.
- Validation: Add focused real-Git regression cases for merged-main contamination and source-bearing-span derivation, plus positive/negative coverage-only report fixtures and all rejection controls above. Run the focused new tests, `python3 -m unittest custodian.tools.agent.test_paired_review_runner`, canonical changed-file validation against the exact implementation source span with complete coverage, `python3 custodian/tools/agent/validate_task_packet_authoring.py` on this pair, `python3 custodian/tools/agent/check_packet_categories.py` on this pair, and `git diff --check`. Do not run broad Godot sweeps. Before recovery planning for the preserved run, require this implementation to land and receive its own fresh independent accepted review; any recovery apply and protected reviewer launch remain separately authorized operations.
- Task overrides: `none`
- Deferred: Any recovery plan/apply for host run `20261031T024441Z-9c08b75951b6`; resumption of the protected review; any action on the four other protected review claims; any additional claim or worktree beyond the one implementation assignment authorized by RC-027.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: The coordinator now supplies canonical validation with an explicit, sorted inventory derived from the authenticated implementation source span and only the exact authorized Procession fixture overlay. Host validation and later verification require report inventory and command arguments to match that authenticated set. The legacy coverage-only exit-6 path is recognized only after exact session/claim/target/main/source-span, unchanged source hashes, report digest, complete all-passing test inventory, and canonical nonempty uncovered coverage are verified. The report remains failed/incomplete. Focused host-validation tests passed 112/112; the complete paired-review runner suite passed 245/245; canonical exact changed-file validation passed 7/7 with complete coverage using a process-local 360-second timeout for the 130.2-second runner test; packet authoring and category preflights passed. Original protected review artifacts and claim state remain unchanged. The protected review still requires its own separate recovery authorization after this correction receives fresh independent review.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The canonical runner test exceeded its default 120-second test budget during concurrent validation activity. Its direct full-suite run passed; canonical validation was rerun with a process-local 360-second timeout and passed all selected checks. No repository-wide timeout or validation policy was changed.
- Root cause / contributing factors: The paired-review runner suite takes about 130 seconds on this host, slightly longer than the default canonical test budget.
- Prevention / pipeline improvement: If this measured duration persists, revise the paired-review test timeout in a separate validation-manifest workstream.
- Tooling / docs drift discovered: The packet still described worktree/claim creation as deferred under the capacity hold after RC-027 had passed its two-sample capacity gate and authorized this exact implementation claim. This packet now records that single authorized assignment and leaves further claims deferred.
- Follow-up: `review-agent-paired-review-merged-source-validation-isolation-v1`; recover the preserved archived-receipt review only after this implementation receives its own fresh independent accepted review and a separate recovery authorization.
- What worked: The exact source inventory prevented later-main paths from entering validation; adversarial report checks kept incomplete coverage nonpassing; all validation used the canonical manifest without broadening exclusions.

## Handoff

- Next workstream: `review-agent-paired-review-merged-source-validation-isolation-v1`
- Next packet state: `dependency-gated until this implementation lands and archives complete`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
- Refresh instruction: `After implementation lands, recheck current main, exact paired-review dispatcher eligibility, no conflicting lock, protected claims unchanged, and sufficient disk capacity before launching the one named fresh-context review. Stop and preserve if capacity falls below the active control's floor or ENOSPC recurs.`
- Blockers or open questions: `Implementation is complete and validation is green. A later origin/main advance occurred during implementation; canonical workstream finish must synchronize and validate the merged source span before landing. This workstream does not authorize protected recovery or reviewer relaunch.`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
