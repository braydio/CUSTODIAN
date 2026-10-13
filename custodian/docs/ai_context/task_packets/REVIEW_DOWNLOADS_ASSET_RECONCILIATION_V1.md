# REVIEW DOWNLOADS ASSET RECONCILIATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-downloads-asset-reconciliation-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `downloads-asset-reconciliation-v1`
- Locks: `downloads-housekeeping`
- Review: `none`
- Review target workstream: `downloads-asset-reconciliation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/DOWNLOADS_ASSET_RECONCILIATION_V1.md`
- Reviewed main: `48646ce06a630d8d524353df6d335d53fbef1747`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `asset-pipeline, workflow, code`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the local Downloads inventory and deletion plan contain no filename-based assumptions and that no filesystem or Dropbox changes occurred.
- Reviewed implementation acceptance: Read and independently check each acceptance criterion in the archived `DOWNLOADS_ASSET_RECONCILIATION_V1.md`; reuse documented SHA-256/run receipts and recheck any material ambiguous candidate.
- Review evidence: Archived packet, runtime catalog/receipts, actual local stat/hash report, Dropbox listing/verified ZIP members where applicable, ledger, scoped diff.
- Correction threshold: Any deletion lacking exact hash-backed duplicate or backed-up source proof, broken source chain, unsafe traversal, out-of-scope mutation, misattributed ingestion, deleted unclassified personal data, or false completed count is a blocking defect requiring bounded correction and re-review.
- Focused validation: Recompute a random/full risk-weighted sample of hashes, every proposed delete/remote-match proof, and fixture tests; confirm root checkout and Downloads remained untouched.
- Review focus: Exact SHA/ZIP member comparison, completeness including hidden files, Kenney source/runtime receipts, remote counterpart byte verification and preservation of unknown private items.
- Acceptance: Independent findings-first review with stable R0 IDs and exact proof status. Pass only if no blocking defect and no material gap; preserve protected recovery behavior on reviewer failure.
- Non-goals: No implementation or deletion during review; do not patch reviewed implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Return current verified classifications/deletion evidence and any named successor whose dependencies are now satisfied.
- Blockers or open questions: Protected human/non-CUSTODIAN file classifications must not be waived just to empty Downloads.
