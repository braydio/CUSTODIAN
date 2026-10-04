# REVIEW: OPERATOR WORKBENCH NEW ANIMATION CREATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-animation-creation`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-animation-creation`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-animation-creation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_ANIMATION_CREATION.md`
- Reviewed main: `0a4bd5ec35`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that OPUI can create a genuinely absent Operator semantic animation and publish it through the existing specialized Operator production transaction without bypassing canonical schema, collision safety, rollback, runtime rebuild/import, or the external-art intake boundary.
- Reviewed implementation acceptance: Review the archived implementation packet's creation-plan, blank/reference-backed Workbench, full-body/modular templates, preview-before-publish, direct CREATE transaction, race refusal, exact rollback, post-publish normalization, browser refresh, dormant/unwired truth, and explicit mirror behavior.
- Review evidence: Reuse fixture hashes, creation plans, transaction journals, rollback receipts, UI/CLI projections, generated runtime/catalog checks, changed-file validation and closing summary. Gather fresh evidence only for acceptance not already proven.
- Correction threshold: Any canonical-path derivation outside the Operator schema, silent overwrite, incomplete rollback, inbox bypass for external untrusted input, forced inbox round-trip for native Workbench pixels, false LIVE/runtime-use claim, or duplicated publisher is blocking.
- Focused validation: Inspect one successful full-body CREATE, one modular CREATE, one target-race refusal, and one injected rollback journal; rerun focused Workbench UI/model/mirror/art-worktree fixtures plus import/SpriteFrames/runtime checks as needed. Confirm the resulting published animation is catalog-present and truthfully DORMANT when no consumer exists.
- Review focus:
  - Verify the creation flow consumes the inherited startup/receipt/frame-contract/recovery semantics instead of adding a second recovery path; saved creation documents must survive all blocked/error states.
  - one creation/publication authority;
  - no canonical file written before explicit Publish;
  - schema-derived paths only;
  - exact saved Aseprite pixels;
  - direct native Workbench creation uses specialized Operator backend rather than needless inbox staging;
  - external/generated input boundary remains `asset_drop/source_work|inbox`;
  - rollback deletes new outputs completely;
  - UI and CLI are projections over the same backend;
  - no gameplay selector/runtime behavior is invented by tooling.
- Acceptance: Produce a findings-first review with stable cycle-scoped IDs for any findings. A clean result records passed creation/rollback/pipeline integration and allows the UX hierarchy refresh to treat New Animation as existing backend capability. Do not patch reviewed implementation code.
- Non-goals: No UX hierarchy redesign, autonomous generation, gameplay wiring, or external import wizard in the review workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Auto-dispatch after `operator-workbench-animation-creation` completes and archives.
- Blockers or open questions: none.