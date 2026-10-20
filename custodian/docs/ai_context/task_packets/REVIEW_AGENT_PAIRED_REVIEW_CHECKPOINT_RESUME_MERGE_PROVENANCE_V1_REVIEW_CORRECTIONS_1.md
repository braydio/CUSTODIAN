# Review Paired Review Checkpoint-Resume Merge Provenance Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Locks: `paired-review-resume-merge-provenance`
- Review: `none`
- Review target workstream: `agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `f2ba5b1feafba3e0092b79016b2dd85467592825`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently close finding `R0-01` by falsifying the checkpoint-resume merge and owned-source negative cases with real Git histories.
- Reviewed implementation acceptance: The correction must meet A1-A6 of its archived implementation packet and preserve all original checkpoint-resume provenance gates.
- Review evidence: Exact correction source diff, the prior review's `R0-01`, complete paired-review unit suite, changed-file validation JSON, and real-Git fixtures exercising the rejected histories.
- Correction threshold: Any accepted forged merge, lost/mutated owned source, undocumented local source, unowned test, or incomplete validation coverage is a blocking correction finding. Do not create another correction cycle for stylistic preferences.
- Focused validation: Run the full paired-review runner unit suite and changed-file validation against the pinned implementation; independently inspect each real-Git negative fixture and verify its failure reason.
- Review focus: Altered merge tree, wrong/reordered/octopus parents, unrelated second parent, repeated merge, source loss, synchronized-main source mutation, undocumented source/test ownership, overlap preservation, and historical positive replay.
- Acceptance: Produce a findings-first fresh-context review with canonical cycle-scoped IDs. PASS only when every A1-A6 assertion is demonstrated and all existing source-span regressions remain green. Findings must identify the exact failing predicate and preserve the review claim/worktree.
- Non-goals: Modify the reviewed implementation, change protected Grunt runs, generalize merge support, or make a visual art decision.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the correction implementation has landed and dispatcher eligibility is confirmed.
2. Start from a fresh reviewer context and reconstruct the implementation from the archived packet and landed diff.
3. Inspect the real-Git fixtures and run the required validation; do not modify implementation code.
4. Record a canonical PASS or findings outcome and close through `paired_review_runner.py`.

## Handoff

- Refresh reason: The paired implementation packet is being republished to add the dispatcher-required `Findings addressed: R0-01` lineage field after the prior automatic handoff rejected its omission.
- Next workstream: `none`
- Only an independent PASS authorizes read-only planning for the held Grunt attestation review.
