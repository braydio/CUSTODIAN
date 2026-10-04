# REVIEW: ASSET WORKBENCH REVIEW STUDIO R1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-asset-workbench-review-studio-r1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `asset-workbench-review-studio-r1`
- Locks: `asset-workbench-ui, asset-workbench-review`
- Review: `none`
- Review target workstream: `asset-workbench-review-studio-r1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ASSET_WORKBENCH_REVIEW_STUDIO.md`
- Reviewed main: `5a82486a46f30ad8753625133e1c6cee7eddd958`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify Slice 2 Review Studio is a read-only extension of the landed Asset Workbench family navigator and Asset V2 truth, with exact pixel/frame handling and no second review/cache authority.
- Reviewed implementation acceptance: Reuse the archived implementation packet's full Acceptance contract.
- Review evidence: Landed Slice 1 APIs, archived Slice 2 packet/summary, focused Review Studio smoke, Asset V2 inspector/plan/catalog parity, LFS-pointer negative cases, Operator preview regressions if shared widgets moved.
- Correction threshold: Any asset mutation, guessed geometry, untrusted runtime preview treated as canonical, duplicate semantic cache, broken LFS diagnosis, resampling, or Operator preview regression is correction-worthy.
- Focused validation: Re-run the implementation's focused Review Studio tests, Asset V2 read-path regressions, and Operator preview/UI regression only when shared code changed; finish with changed-file validation and `git diff --check`.
- Review focus: landed Slice 1 extension instead of replacement; staged/runtime provenance; exact frame extraction; no implicit network/LFS fetch; integer/native raster fidelity; diagnostics fail soft; no mutation surface.
- Acceptance: Findings-first fresh-context review with pass or bounded correction packet. Do not patch reviewed implementation.
- Non-goals: No ingest/mutation actions, design mode, actor sequence runtime, or unrelated Operator tooling.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Auto-dispatch after `asset-workbench-review-studio-r1` completes and archives.
- Blockers or open questions: none.
