# REVIEW: AGENT REVIEW PIPELINE

- Workstream: `review-agent-review-pipeline`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-review-pipeline`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `agent-review-pipeline`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_REVIEW_PIPELINE.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the newly landed CUSTODIAN review pipeline against its own packet contract and live repository behavior.
- Review focus: independence; dispatcher/workstream reuse; historical packet safety; paired-review enforcement; findings-first behavior; correction/re-review generation; finite escalation; human visual-decision protection; docs/tooling consistency.
- Acceptance: Produce a findings-first independent review of live `main`. Either record a clean `passed` receipt or concrete findings. Blocking findings create `agent-review-pipeline-review-corrections-1` plus its paired review packet. Do not patch reviewed implementation code inside this review workstream.
- Non-goals: Do not redesign dispatcher, add pre-land review, add continuous workers, or fix reviewed implementation directly.
- Task overrides: Review-only with respect to the reviewed implementation. Repository/document mutations required for review receipt and follow-up packet creation are allowed.

## Procedure

1. Claim only after dependency `agent-review-pipeline` is complete on `origin/main`.
2. Read root/local AGENTS, this packet, archived `AGENT_REVIEW_PIPELINE.md`, its closing summary, lifecycle/template/review prompt, and live dispatcher/review/workstream tooling.
3. Inspect live behavior and focused tests against archived acceptance.
4. Report confirmed findings first with file/line references where practical.
5. Classify each item as blocking confirmed defect, non-blocking confirmed issue, evidence gap/question, or optional improvement.
6. Do not modify reviewed implementation/runtime code.
7. Update the archived implementation packet's Independent Review receipt.
8. If blocking findings exist, create `AGENT_REVIEW_PIPELINE_REVIEW_CORRECTIONS_1.md` and `REVIEW_AGENT_REVIEW_PIPELINE_REVIEW_CORRECTIONS_1.md` with the new workflow.
9. If clean, set receipt `passed` and create no correction.
10. Complete/archive this review packet through the normal workstream lifecycle.

## Review Emphasis

Pay special attention to concurrency and failure behavior. Parser-only tests are insufficient if branch/worktree/dispatch integration can still duplicate, lose, or recursively generate work.

Confirm that subjective human decisions cannot be silently converted into technical passes.

## Handoff

- Next action: This should be the first automatically claimed independent review after the pipeline lands.
- Blockers or open questions: Blocked only by `agent-review-pipeline`.