# Paired Review Checkpoint-Resume Merge Provenance Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1`
- Locks: `paired-review-resume-merge-provenance`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `the checkpoint-resume merge exception controls source ownership and must withstand adversarial Git-history fixtures`
- Reviewed main: `f2ba5b1feafba3e0092b79016b2dd85467592825`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `none`
- Goal: Prove that the checkpoint-resume merge exception rejects malformed Git ancestry, altered merge results, source loss or mutation, and source/test ownership laundering.
- Completion boundary: Add focused real-Git negative fixtures for review finding `R0-01`, fix any demonstrated resolver defects within the existing host-validation boundary, validate the full paired-review suite, and obtain the fresh-context paired review. Do not resume either protected Grunt review in this cycle.
- Current measured state: The landed implementation `00cdfd382a3007c30cd42609b4a63146daf0ad32` passes 126 paired-review tests and the historical `f76854cf → d0e44dd8 → 08236e69 → ff48e1d0 → 447c358c` replay. The independent review found that five trace mutations do not cover the packet's required A3 merge/source adversarial cases.
- Findings addressed: `R0-01`
- Evidence: Archived implementation packet `AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1.md`; archived findings review with `R0-01`; summary `REVIEW_AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1_CLAUDE_SUMMARY.md`; pinned source and lifecycle traces named by those artifacts.
- Required correction: Add real-Git negative fixtures for altered merge trees/parents, unrelated or extra parents/merges, source loss or synchronized-main mutation, undocumented local sources, and unowned tests. Keep overlap ownership and the exact historical replay covered; fix a resolver gate only if a failing fixture demonstrates an actual escape.
- Task-specific authority: The archived implementation's A3 acceptance and validation contract; the exact landed source span and immutable checkpoint/resume trace; `paired_review_host_validation.py` source-span and ownership gates; `test_paired_review_runner.py` real-Git fixtures.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; required root summary `AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`. Do not change `workstream.py`, the protected review claims, or the raster artifacts.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1.md`; `REVIEW_AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1_CLAUDE_SUMMARY.md`
- Change: Add isolated real-Git fixtures that directly falsify each checkpoint-resume merge predicate. Keep the accepted historical replay and ordinary no-merge/final-sync cases green. If a negative fixture demonstrates an actual resolver escape, fix only that source-span gate and add the failing fixture first.
- Preserve: The implementation and findings review receipts; exact Grunt attestation implementation, original reviewer run `20261019T205853Z-8671cc448942`, original Grunt reviewer run `20261019T173219Z-d9252b20c85f`, all associated claims/worktrees and visual-review evidence.
- Non-goals: Generic merge acceptance; changing runtime/gameplay, raster art, protected review claims, or `workstream.py`; changing the human visual decision; bypassing host validation or weakening source ownership.
- Acceptance: A1: a two-parent merge with altered tree or reordered parents is rejected even when trace fields are otherwise valid. A2: unrelated second parent, octopus merge, additional/repeated merge, or first parent other than the immediately preceding authored source commit is rejected. A3: deletion/loss of an owned source at the merge and later source mutation on the synchronized-main path fail closed. A4: undocumented local source and unowned test paths are rejected; a workstream-owned path touched on both sides remains in the owned inventory and requires coverage. A5: accepted historical replay still selects only the workstream's non-merge authored source paths and passes coordinator coverage plus immutable evidence revalidation. A6: all existing paired-review source-span, archive, UID, and exact-scope positive/negative tests remain green.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`. The adversarial controls must use real Git commits/trees and assert the specific expected rejection path, not a hand-constructed pass report alone.
- Task overrides: `none`
- Deferred: Only after this correction review passes, resume the same preserved Grunt attestation review run `20261019T205853Z-8671cc448942` with a read-only host-validation recovery plan. Do not apply it without validating the exact plan digest. Then proceed to original Grunt review only after the attestation review passes.

## Execution

1. Claim through the dispatcher only after automatic authoring handoff promotes the pair and confirms eligibility.
2. Reproduce each A3 omission with minimal real-Git fixtures before changing resolver behavior.
3. Commit implementation/tests/summary together, archive the correction packet in a separate archive-only closeout, and finish through `workstream.py`.
4. Run the paired review from a fresh context. Stop on findings for another bounded correction cycle; never touch the protected Grunt review runs here.

## Handoff

- Refresh reason: The prior automatic handoff rejected this correction because it omitted the dispatcher-required `Findings addressed: R0-01` lineage field; that exact archived finding is now pinned above.
- Next workstream: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`
- Next action after implementation landing: run the fresh-context independent review.
