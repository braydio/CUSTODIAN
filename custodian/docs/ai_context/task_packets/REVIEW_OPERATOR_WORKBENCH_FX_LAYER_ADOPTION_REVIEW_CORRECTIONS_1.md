# REVIEW: OPERATOR WORKBENCH FX LAYER ADOPTION REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-fx-layer-adoption-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-fx-layer-adoption-review-corrections-1`
- Locks: `operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-fx-layer-adoption-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_FX_LAYER_ADOPTION_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `1e62ce7e2ff5dec8e1c76cff1850715f5a1e89dd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/closeout summary and the final `## Next Handoff`.
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, asset-pipeline, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify that correction `R0-01` closes the REPLACE source-conflict window without weakening successful publication, CREATE collision refusal, or rollback ownership.
- Reviewed correction acceptance: The publisher must refuse when a canonical REPLACE target changes after adoption and before replacement; rollback must not overwrite or delete an external concurrent replacement; successful existing CREATE/REPLACE and mirrored transactions remain intact.
- Review evidence: Parent review receipt and focused correction interleaving/rollback fixtures.
- Correction threshold: Create another correction only for a confirmed acceptance defect or material proof gap. At the maximum automatic review cycle, unresolved findings become `human_required`.
- Focused validation: Run the mirror publish smoke, Workbench model/Aseprite smoke, and changed-file validation required by the correction packet. Inspect exact bytes and transaction journal for both interleaving controls.
- Review focus: Verify the test mutates the target after freshness validation and before swap; ensure the code binds preimage bytes to the adopted contract at mutation time; verify rollback preserves changes it does not own.
- Acceptance: Produce a findings-first independent review. Report addressed finding `R0-01` as `fixed`, `unresolved`, or `regressed`, with exact evidence and any new cycle-scoped IDs. Do not patch reviewed implementation code.
- Non-goals: Do not expand beyond correction finding `R0-01`, change gameplay/art, or review unrelated Workbench flows.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim after correction `operator-workbench-fx-layer-adoption-review-corrections-1` lands and archives.
2. Reconstruct the correction from its packet, parent finding `R0-01`, source diff, focused controls, and live implementation.
3. Independently verify the mutation interleaving and rollback ownership; do not infer safety from a unit helper or success-path test alone.
4. Append the re-review disposition to the archived parent review packet and close this packet through the normal workstream lifecycle.

## Handoff

- Next action: Auto-dispatch after the correction lands and archives.
- Blockers or open questions: none.
