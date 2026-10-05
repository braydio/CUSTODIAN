# REVIEW: VISUAL REVIEW HANDOFF LIFECYCLE HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-visual-review-handoff-lifecycle-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `visual-review-handoff-lifecycle-hardening`
- Locks: `agent-workflow, visual-review-handoff`
- Review: `none`
- Review target workstream: `visual-review-handoff-lifecycle-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_REVIEW_HANDOFF_LIFECYCLE_HARDENING.md`
- Reviewed main: `4811bffc9e0ff66e2be1c07be632c8abaeb203db`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify authoring-chat provenance, autonomous claim routing, same-workstream human-review pause behavior, and exact reviewed-evidence cleanup safety.
- Reviewed implementation acceptance: Use the archived implementation packet Acceptance verbatim.
- Review evidence: Reuse focused unit/changed-file results, then inspect live main and add fresh hostile-path cleanup/claim/summary checks where needed.
- Correction threshold: Any path that deletes outside the exact review run, drops/rewrites the authoring URL, silently claims unrelated work while human review is pending, or bypasses the finish backlink gate is blocking.
- Focused validation: `test_task_packet_contract.py`; `test_dispatch.py`; `test_workstream_artifacts.py`; `test_publish_review_artifacts.py`; review-pairing and changed-file validation.
- Review focus: Cleanup confinement; malformed/stale latest pointer behavior; explicit retain semantics; claim receipt provenance; historical packet compatibility; summary backlink enforcement only when a real URL is recorded.
- Acceptance: Produce a findings-first independent review of live main and append a durable Independent Review receipt to the archived target. Do not patch reviewed implementation code.
- Non-goals: No runtime/gameplay work; no subjective art review; no historical Dropbox mass cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Close review or author bounded corrections from confirmed findings.`
- Blockers or open questions: `none`
