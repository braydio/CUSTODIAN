# REVIEW: OPERATOR WORKBENCH NEW ANIMATION CREATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-animation-creation`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-animation-creation`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-animation-creation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_ANIMATION_CREATION.md`
- Reviewed main: `180bcec63`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
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

## Review Outcome

- Verdict: `findings`
- Blocking finding: `R0-01` — every valid new-animation publication through the shared UI/CLI service raises NameError before readiness or source mutation.
- Durable evidence: `REVIEW_OPERATOR_WORKBENCH_ANIMATION_CREATION_CLAUDE_SUMMARY.md`; real saved-Aseprite full-body/modular service reproductions and four focused compatibility smokes.
- Correction workstream: `operator-workbench-animation-creation-review-corrections-1`
- Implementation files changed by this review: none.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Creation publication acceptance was reported green while the shared UI/CLI service path always raises NameError; the packet's Reviewed main predates the implementation.
- Root cause / contributing factors: Creation fixtures exercise lower-level publication with downstream stages stubbed; UI smoke never exercises creation publication and its optional Textual pilot is skipped. The inherited Reviewed main field was not refreshed at implementation closeout.
- Prevention / pipeline improvement: The bounded correction requires real-model/real-workbench service publication fixtures for both templates, plus immutable live-target references in correction/re-review metadata.
- Tooling / docs drift discovered: Reviewed main 0a4bd5ec35 is an October 3 task-index change; actual implementation is 3e4a4df336ed963c096018319cc9208b33b39573 on the reviewed checkout 180bcec63.
- Follow-up: operator-workbench-animation-creation-review-corrections-1
- What worked: Fresh saved-Aseprite fixtures reproduced the defect for both templates and proved failure preserves document and manifest hashes.

## Next Handoff

- Next workstream: operator-workbench-animation-creation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction, then its paired cycle-1 re-review. Resume downstream cockpit/UX planning only after correction review passes.
- Blockers or open questions: New-animation UI/CLI publication is blocked by R0-01; optional interactive Textual pilot remains unrun.
