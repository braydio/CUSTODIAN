# Review Paired Review Post-Merge Follow-Up Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-post-merge-followup-provenance-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-post-merge-followup-provenance-v1`
- Locks: `paired-review-noop-sync-provenance, paired-review-source-span-provenance`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-paired-review-post-merge-followup-provenance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_POST_MERGE_FOLLOWUP_PROVENANCE_V1.md`
- Reviewed main: `e3eb9985b35bc9437f458728023b13ab88af4269`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify source-span attribution across canonical archive, exact sync merge, and bounded post-merge follow-up commits without weakening trace provenance or archive path authority.
- Current measured state: The held reset and Blender review plans fail before reviewer launch on the current host validator. The reset's exact final source-bearing commit follows an archive-first merge; the Blender history is a source-bearing archive whose declared Blender authoring file currently fails the source-path contract. Two exited review claims that held the provenance locks are preserved as `legacy_quarantined`; their original reviews remain unresolved. The reset, scoped-snapshot, and Blender claims remain preserved and unlaunched.
- Evidence: The archived implementation packet and diff; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`; exact reset trace `agent-diagnostics/agent-execution-reset-v1/20261020T135839Z-db96534ed3a7`; commits `bf0f59f478`, `f43f3e6ec3`, `f635c33d8b`; Blender merge `2e0ea6a67c4fc6b1a55078fa04ad4ee3eb3efcf1` and exact archived Blender packet/worktree source evidence.
- Task-specific authority: The implementation packet's exact acceptance, the V1.2 campaign amendment, immutable lifecycle traces, and existing source-span/file-mode/documentation/coverage validators. Reviewer authors judgment; test output alone is not acceptance.
- Work surface: Review-only reads of `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/test_workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, and the archived target packet. Only the canonical review receipt, this review packet's archive/index metadata, its required closing summary, and an authorized bounded correction/re-review packet may be written.
- Publication inputs: `none` (the implementation target and validation authorities are already tracked on `origin/main`).
- Review focus: Independently resolve the exact reset claim/landing traces and prove the returned canonical archive, sync merge, final source head, event cardinality, and changed-file set. Inspect the f635 diffs and verify only the exact test regression plus bounded archived-packet/root-summary metadata are included; test hostile real-Git variants for forged event identity, true/no-op sync ambiguity, parent reversal, extra descendants, source mutation, wrong claim or reviewed-main identity, and archive path/mode attacks. Verify Blender `.blend` admission is scoped to the exact declared source-work path, packet SHA, tracked regular-file mode, and existing source evidence, with negative unlisted/binary/symlink/executable controls. Verify preflight and finish fail before push/landing for unbound post-archive descendants while normal archive-last and declared source-bearing archive behavior remains intact. Confirm no protected original run, branch, worktree, claim, trace, evidence, or review outcome changed.
- Acceptance: Findings-first fresh-context review of each acceptance item in the archived implementation packet. PASS only when the historical reset and Blender cases resolve under exact source provenance, all adversarial controls fail closed, producer-side prevention is effective before publication, focused and changed validations are complete, and original protected identities remain unchanged. Otherwise record concrete findings truthfully; do not apply any protected recovery plan or create an unbounded correction cascade.
- Validation: Independently run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`, `python3 -m unittest custodian.tools.agent.test_workstream -v`, the dedicated quarantine suite, and `python3 custodian/tools/validation/run_validation.py --changed --json`; inspect changed-file coverage, exact historical traces/commit diffs, `py_compile`, and `git diff --check`. Review source and fixtures directly; a green suite is necessary but not a substitute for provenance judgment.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Reconstruct the target from its landed source diff, archived packet, test fixtures, immutable reset/Blender refs, and independent validation artifacts in a fresh reviewer context.
2. Evaluate the exact positive and negative source-provenance cases and producer-side finish gate. Treat review-run application as out of scope.
3. Close with canonical PASS only if all requirements are met; otherwise retain specific findings and preserve all original review claims.

## Next Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: On genuine accepted PASS, make read-only same-run recovery plans for the original scoped-snapshot, reset, and Blender runs in campaign order; apply only freshly verified exact digests.
- Blockers or open questions: The historical no-op and source-span reviews remain unresolved despite their administrative quarantine; do not call either accepted.
