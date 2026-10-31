# Review: Paired Review Merged-Source Validation Isolation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-merged-source-validation-isolation-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-merged-source-validation-isolation-v1`
- Locks: `agent-paired-review-merged-source-validation-isolation`
- Review: `none`
- Review target workstream: `agent-paired-review-merged-source-validation-isolation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_MERGED_SOURCE_VALIDATION_ISOLATION_V1.md`
- Reviewed main: `cbf38b479381255e8f56d59998a0313a62f1a017`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently determine whether the correction isolates paired-review validation to authenticated implementation source changes and authenticates the exact coverage-only failed-host-report shape without treating incomplete coverage as success.
- Reviewed implementation acceptance: `All seven acceptance criteria in the implementation packet, especially exact provenance-derived source span, exit-6 coverage-only report authentication, immutable original evidence, complete coverage requirement and preserved plan/apply/reviewer gates.`
- Review evidence: `Landed implementation diff and archived packet; durable focused and canonical validation evidence; original host-validation report/hash and run identity available only through the owner-controlled local preserved run; fresh source inspection and real-Git positive/negative tests.`
- Correction threshold: `Create a correction only for a confirmed defect or material proof gap in source-span derivation, coverage-only failure authentication, evidence integrity, authorization, or fail-closed behavior. Preserve the original held review and all ambiguous evidence.`
- Focused validation: `Run the correction's real-Git source-span tests, coverage-only report tests and adversarial controls; rerun the full paired-review unit suite and canonical changed-file validation; independently compare the original run files before/after and verify complete coverage for the exact implementation span.`
- Review focus: `Merged-main contamination; exact provenance and source-bearing commit span; coverage-only exit 6 versus true test/import failure; completeness and consistency of selected checks and uncovered inventory; no incomplete-to-green conversion; immutable original report/claim/run; exact authorization, plan digest and apply boundaries; changing remote refs; reviewer launch prohibition until correction PASS and separate authorization.`
- Acceptance: `Produce a findings-first independent review from a fresh context. Verify each implementation acceptance claim against source and tests, including falsifying every required negative control. Record a canonical passed receipt only when source-span provenance is exact, the coverage-only shape is recognized solely as failed/incomplete, required coverage remains enforced, original protected evidence is unchanged, and no authorization/reviewer gate is bypassed. Otherwise record concrete findings; do not alter the implementation or the protected review.`
- Non-goals: `Do not edit the implementation, apply host recovery, launch or relaunch the protected reviewer, change its verdict, release its claim/lock, alter original run files, broaden manifest exclusions, or clean protected worktrees.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Wait until the implementation packet is archived complete on `origin/main`; reconcile exact target commit, source files, review branch and remote state.
2. Start a fresh independent reviewer context. Read the archived implementation packet, root and `custodian/AGENTS.md`, lifecycle authority, durable summary and validation evidence.
3. Inspect the exact original host-run evidence through the owner-controlled local path without modifying it. Verify the source/run/claim identities and compare all original evidence bytes before and after review.
4. Reproduce both reported historical defects in disposable real-Git fixtures: unrelated later-main source changes must not enter implementation coverage; coverage-only exit 6 must remain failed/incomplete and authenticate only with exact complete evidence.
5. Falsify malformed or incomplete inventories, missing/extra source, false exclusion, report/summary mismatch, altered original report, wrong source/claim/run/main, forged provenance, replay, changed refs, stale plan, attempted reviewer launch and incomplete coverage.
6. Record findings first with stable `R0-NN` IDs, or a canonical PASS receipt only when all acceptance conditions are independently supported. Never plan/apply recovery or launch the protected reviewer as part of this review.

## Next Handoff

- Next workstream: `none`
- Next packet state: `manual capacity hold`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
- Refresh reason: `No refresh; the implementation and paired review remain non-dispatchable until verified disk capacity is adequate. No claim/worktree may be created while the capacity hold remains.`
- Next action: `After implementation lands and its review passes, resume only the existing protected review through a separately authorized read-only recovery plan and explicit apply; do not create a new claim for it.`
- Blockers or open questions: `Original planner result is unavailable after context compaction and must not be guessed or retried. Original run files and protected reviewer identity must remain byte-for-byte and identity-stable.`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199
