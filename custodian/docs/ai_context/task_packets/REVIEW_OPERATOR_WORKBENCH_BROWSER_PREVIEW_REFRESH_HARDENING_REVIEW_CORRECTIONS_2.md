# REVIEW: OPERATOR WORKBENCH BROWSER / PREVIEW — CORRECTION CYCLE 2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-2`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-browser-preview-refresh-hardening-review-corrections-2`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_2.md`
- Reviewed main: `18d5f1f7392dc44ba1b70e4465e615866b7837ca`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context` or `different-agent`, record actual provenance at execution
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `2`
- Max automatic review cycles: `2`
- Goal: Independently verify R1-01 document-ownership closure and remaining R0-04 proof without regressing R0-01/R0-02/R0-03 or parent acceptance.
- Reviewed implementation acceptance: Archived cycle-2 correction acceptance plus preserved parent/cycle-1 acceptance; retain original IDs as fixed/unresolved/regressed and new findings as R2-NN.
- Review evidence: `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md` executable issue-to-result probe, cycle-2 summary/negative controls, archived parent/correction evidence, live source/diff.
- Correction threshold: Confirmed stale document/result mutation or material missing proof requires human decision at this maximum cycle; never create automatic cycle 3.
- Focused validation: Rerun pinned expanded UI smoke; independently repeat document switch during actual app/server issue-to-result and synchronous preview-loader awaits; inspect selection/source/mode matrix and full accepted mutation assertions; smallest changed-artifact closeout validation.
- Review focus: Active editor path independent from supplied event/result path; document/revision/output/UI identity/generation/source checks at each await and before commit; disconnected editor rejection; valid current result and saved-preview fallback; one accepted snapshot and preserved deletion/modal/PUBLISH/tick behavior.
- Acceptance: Findings-first fresh review; append Independent Review receipt to archived cycle-2 packet. If correction-worthy findings remain, set receipt to human_required and report exact evidence and authoring chat for user/ChatGPT decision. If clean, identify FX-adoption lane's exact live dependency/refresh gate as immediate successor.
- Non-goals: No reviewed implementation edits, art/runtime/publisher/layout redesign, or renderer recapture.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Claim only after cycle 2 archives complete. Reconstruct from durable repository evidence in a fresh context. This is the final automatic review; unresolved acceptance/correctness findings require human decision in the exact authoring conversation above. Do not skip to FX adoption while corrections or human gates remain unresolved.

## Handoff

- Next action: Claim after correction cycle 2 lands; independently verify R1-01/R0-04 and preserved R0-01/R0-02/R0-03.
- Blockers or open questions: Correction dependency; maximum-cycle escalation if unresolved.
