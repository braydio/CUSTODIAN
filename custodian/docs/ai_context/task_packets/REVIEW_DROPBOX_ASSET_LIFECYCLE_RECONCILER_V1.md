# REVIEW: DROPBOX ASSET LIFECYCLE RECONCILER V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-dropbox-asset-lifecycle-reconciler-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `dropbox-asset-lifecycle-reconciler-v1`
- Locks: `asset-pipeline, dropbox-handoff`
- Review: `none`
- Review target workstream: `dropbox-asset-lifecycle-reconciler-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/DROPBOX_ASSET_LIFECYCLE_RECONCILER_V1.md`
- Reviewed main: `b438c31dec2007acc6d3b6c78efa1f57e7da047f`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the Dropbox lifecycle scanner's source-approval separation, accurate unknown-vs-missing statuses, complete remote discovery, and read-only boundary against actual Asset V2/Git/Dropbox authority.
- Review evidence: Archived target packet, approval schema, CLI tests, real remote read-only audit, code diff, actual family catalog and seeded 2026-10-13 inventory.
- Correction threshold: Unreviewed Dropbox upload becomes approved/ingestable, current runtime inferred from Dropbox, partial family claimed complete, human review bypassed, remote data mutated, silent failures, zip path abuse, credentials exposed, duplicate registry authority or nondeterministic report.
- Focused validation: Reproduce fixture and remote read-only tests, test missing/unindexed 2026-10-13 lift ZIP and double-count trap in Ash-Bell static closeout, inspect `asset.py` and `asset_status.py` authority.
- Review focus: Ensure read-only auditing does not stage binary files or modify checked-in catalogs; report exact proof for each status and explicit lack of proof otherwise.
- Acceptance: Findings-first passed/failed review receipt with stable finding IDs and narrow correction packets only if necessary.
- Non-goals: No direct edits to reviewed implementation or auto-ingest.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Return reviewed scanner to ChatGPT for verified-stage and Dropbox publish design completion.
- Blockers or open questions: Review requires a landed implementation and real audit evidence.
