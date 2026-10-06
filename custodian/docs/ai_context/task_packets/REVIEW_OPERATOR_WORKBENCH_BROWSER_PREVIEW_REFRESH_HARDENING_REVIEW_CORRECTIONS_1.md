# REVIEW: OPERATOR WORKBENCH BROWSER / PREVIEW CORRECTIONS — CYCLE 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `83f5a9dcebf91df7e853a02fbaffbb652490b777`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context` or `different-agent`, record actual provenance at execution
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify correction cycle 1 closes R0-01 through R0-04 without regressing original browser/PREVIEW semantics.
- Reviewed implementation acceptance: The archived correction packet's complete acceptance and the preserved parent acceptance; retain original IDs as fixed, unresolved, or regressed.
- Review evidence: Parent review summary `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_CLAUDE_SUMMARY.md` and its executable probes, correction summary and deterministic test results, live source and diff.
- Correction threshold: Confirmed stale application/transaction defects or material missing required proof become bounded cycle-2 correction work; optional polish does not.
- Focused validation: Rerun the expanded smoke with pinned Textual; independently exercise issue-to-result live generation and browser-owned session ownership; reuse structured evidence for preservation; run supporting discovery smoke only when corrected semantics warrant it and smallest changed-file closeout validation.
- Review focus: Guard before accepted mutation, preserve prior coherent state on all projection failures, successful deletion remains visible, command cause binds export to originating generation, no duplicate session/browser authorities, PUBLISH coalescing and tick controls remain proved.
- Acceptance: Findings-first fresh review; append Independent Review receipt to archived correction packet and classify each retained ID fixed/unresolved/regressed. New findings use R1-NN. If needed create bounded cycle-2 correction plus paired review; never patch reviewed implementation.
- Non-goals: No art/runtime/publisher/layout redesign or renderer recapture.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Claim only after correction archives complete. Reconstruct from durable evidence in a fresh context. Follow the ordinary paired-review lifecycle and maximum-cycle gate. After a clean result, identify the FX-adoption lane's exact live dependency/refresh gate before handoff; do not silently skip the same-series successor.

## Handoff

- Next action: Claim only after correction cycle 1 lands and archives; verify all four original finding IDs.
- Blockers or open questions: none beyond the correction dependency.
