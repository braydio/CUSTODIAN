# Independent Review: Inherited-Main Resume Provenance Correction

- Review workstream: `review-agent-workstream-inherited-main-resume-provenance-v1`
- Review target workstream: `agent-workstream-inherited-main-resume-provenance-v1`
- Reviewed main: `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`
- Reviewed implementation commit: `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`
- Source span inspected: `5de7fa9fe52bd9b467319042c50b9d280fe59acc`..`acc88b8585361c2a075f4f63499629bf0f22b168`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Run ID: `20261101T225910Z-3be5be94e46a`
- Review cycle: `0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb

## Findings

**R0-01 — Missing focused adversarial coverage for the independent consumer.** The source-span consumer in `paired_review_host_validation.py` now admits a merge as inherited when it matches a resume event and the reviewed main first-parent history, then excludes that merge’s paths from the task-authored source inventory. The changed consumer test file adds no real-Git fixture for this new inherited-main branch; the only newly added behavior-specific fixture is in `test_workstream.py` and exercises the producer. Existing consumer tests cover checkpoint/resume synchronization and other historical resume paths, but do not establish positive and negative behavior for this distinct inherited-main classification. The coordinator report's broad `paired_review_runner_unit` pass and complete file coverage do not show that the new consumer branch or its required adversarial controls ran. Since this consumer is an independent acceptance authority, the missing evidence is material to the packet's explicit requirement to independently prove that inherited paths are excluded and forged, mismatched, or out-of-boundary resume histories fail closed. Add focused real-Git positive and negative consumer cases before accepting this change.

The implementation diff was reviewed at both the source span and archive landing. The producer checks ordered resume events, main first-parent membership, deterministic merge trees, and published append-only trace snapshots; the consumer similarly derives inherited merges from Git history and pinned resume records. I found no specific bypass in those inspected code paths. This verdict is findings because the independent-consumer acceptance evidence is incomplete, not because the implementation was shown to accept a forged history.

## Evidence inspected

- `AGENTS.md`, `custodian/AGENTS.md`, active review packet, archived implementation packet, and implementation summary.
- Pinned implementation and main identity: `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`.
- Source-span commits: `5de7fa9fe52bd9b467319042c50b9d280fe59acc` through `acc88b8585361c2a075f4f63499629bf0f22b168`.
- Archive landing diff at `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`.
- Immutable coordinator report: `/home/braydenchaffee/Projects/CUSTODIAN/.git/custodian-review-runs/review-agent-workstream-inherited-main-resume-provenance-v1/20261101T225910Z-3be5be94e46a/validation.json`; SHA-256 verified as `9e95267f6eaf09cb8fdcee55c047dfb2c333df602180b71a75a3bb6cfc03a4d7`. It reports 9/9 selected checks passed, complete coverage, and zero failures, skips, timeouts, or infrastructure errors. I did not run or alter this report.
- The review checkout was clean before review artifact creation. No tests or host validation were run in this reviewer turn.

## Review Outcome

- Schema: `custodian.review_outcome.v1`
- Outcome: `findings`
- Review workstream: `review-agent-workstream-inherited-main-resume-provenance-v1`
- Review target workstream: `agent-workstream-inherited-main-resume-provenance-v1`
- Reviewed main: `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`
- Reviewed implementation commit: `40b8126d6abdd57d36528b7e7f8efd68df2e88f6`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Run ID: `20261101T225910Z-3be5be94e46a`
- Review cycle: `0`
- Finding IDs: `R0-01`

## Next Handoff

- Next workstream: `agent-workstream-canonical-summary-rename-recovery-v1`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: Independent review R0-01 identifies a material consumer real-Git evidence gap.
- Next action: Obtain a human decision on a narrowly scoped test-coverage correction and subsequent fresh independent acceptance.
- Blockers or open questions: The provenance implementation is not independently accepted. Original summary-rename finish remains blocked and its existing claim must be preserved.
