# Review Owner Review Exception Direct PR Provenance Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Locks: `agent-workflow`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_OWNER_REVIEW_EXCEPTION_DIRECT_PR_PROVENANCE_RECOVERY_V1.md`
- Reviewed main: `a3fb2f8b4fe854af9607ee71a8beb3022014de58`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the exact V2/direct-PR source-span exception is pinned to authenticated historical evidence and cannot weaken ordinary review provenance.
- Reviewed implementation acceptance: Require the verifier to authenticate only the exact source base/commit, archive introduction and packet blob, owner-authorized handoff, original V2 acquisition receipt, PR #126 merge ancestry, exact source/test path and blob continuity, and lack of conflicting lifecycle provenance. Recompute the proof during every resolver call. Keep generic source-span behavior and all review outcomes unchanged.
- Review evidence: Reproduce the positive source-span resolution from live Git objects; independently inspect the original private acquisition SHA and identity; verify handoff authorization and commit ancestry; exercise exact-history adversarial rejection tests; confirm the preserved review remains without a verdict before recovery planning.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in the exact provenance contract. Do not patch the implementation from this reviewer workstream.
- Focused validation: Re-run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; inspect the exact source-span report; run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` and confirm complete coverage; validate packet/index/pairing and diff checks. Report any proof the host-private receipt cannot be reauthenticated.
- Review focus: Challenge every individual trust edge: exact trigger tuple; full parent order; source base and source head; archive packet bytes; exact handoff content and object; private receipt hash/schema/identity; derived source path set; blob continuity through later main; no-conflicting-trace requirement; and revalidation on post-review. Try changed path/blob/receipt/parent/merge identities and legacy trace ambiguity. Check that ordinary resolver behavior is untouched and no outcome, claim, branch, acquisition, or original review evidence changes.
- Acceptance: Produce a findings-first independent review of the landed implementation. Record a truthful passed or findings receipt with stable IDs and evidence. A pass requires exact positive resolution and fail-closed rejection across all declared adversarial cases; no fabricated lifecycle event or retirement receipt; no modifications to the reviewed correction; original held review and G checkout remain untouched. Do not recover/apply the preserved run or launch another reviewer from this packet.
- Non-goals: Do not introduce other direct-PR exceptions, generic fallback authorization, external GitHub queries as a substitute for immutable local proof, lifecycle trace fabrication, V2 receipt mutation, original-run recovery, owner exception activation, or Operator runtime changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: After this review reaches a genuine accepted PASS and lands, the orchestrator may authorize the read-only recovery plan for run `20261110T060821Z-f29fdcb6eb2f`. This reviewer must not apply it or continue that review itself.

- Publication hold: Do not claim until this implementation/review pair is published together and the automatic authoring handoff validates and promotes both packets to ready/auto. This is a temporary publication hold; no design or owner decision remains.

## Handoff

- Next workstream: `review-agent-owner-review-exception-closeout-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e
- Refresh reason: `none`
- Next action: After this independent review is accepted and landed, report the P0 gate state and wait for orchestration authorization before planning recovery for the preserved correction review.
- Blockers or open questions: The original correction review and owner-exception review remain unresolved; no Operator decomposition task may be inferred eligible from this provenance fix alone.
