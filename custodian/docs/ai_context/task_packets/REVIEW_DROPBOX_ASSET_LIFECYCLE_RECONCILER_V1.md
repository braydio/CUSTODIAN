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

## Independent Review

### Findings (2026-10-13)

- `DBX-RVW-001` — **Blocking, remote smoke not reproducible.** The required current read-only remote validation could not complete in this claimed checkout: `python3 custodian/tools/assets/dropbox_asset_audit.py --remote git-dropbox-sync scan --json` exited 2 with `Dropbox audit failed: Cannot complete remote lane asset_batches`. A direct `rclone lsf --recursive --files-only git-dropbox-sync:CUSTODIAN/asset_batches` also remained stalled and was interrupted. The historical 2026-10-13 snapshot and completion summary are durable evidence, but do not independently reproduce live discovery. The review must be resumed when remote access responds.
- `DBX-RVW-002` — **Non-blocking, doctor drift confirmed.** `asset.py doctor` reports four awakening designation-locker catalog hash mismatches, matching the implementation summary's declared pre-existing drift. `asset.py needs --check` passes.
- Offline test suite passed: `python3 -m unittest custodian.tools.assets.test_dropbox_asset_audit` (6 tests). `python3 custodian/tools/agent/task_packet_index.py` passed. Checkout remained clean after read-only checks.
- Durable evidence: pinned reviewed main `48646ce06a630d8d524353df6d335d53fbef1747`; implementation commit `7cae2a34874737afd0ecc4c685847702f7051ea0`; remote failure recorded above; historical inventory snapshot `custodian/docs/ai_context/asset_audits/DROPBOX_ASSET_FAMILY_BASELINE_20261013.json` records the lift package as source-only and both static packages against the same six-plus-six families.
- Review result: **blocked** pending reproducible live remote smoke. No passing receipt is issued. No reviewed implementation files were changed.


### Recovery check (2026-10-13)

After the fresh reviewer exited, a new read-only audit from the coordination checkout completed successfully against `git-dropbox-sync`: all three lanes, 26 ZIPs, 88 families, and 24 findings. This confirms the remote listing is responsive again, but it does not constitute an independent review receipt. The prior paired-review runner is in protected `post_exit_recovery` because its reviewer returned blocked validation; preserve this branch and do not reclaim or mark the review complete. Continue only through the repository's explicit manual recovery procedure, then obtain a fresh independent review decision.
