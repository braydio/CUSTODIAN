# REVIEW: VISUAL REVIEW DROPBOX LIFECYCLE HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-visual-review-dropbox-lifecycle-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `visual-review-dropbox-lifecycle-hardening`
- Locks: `agent-workflow, visual-review-transport`
- Review: `none`
- Review target workstream: `visual-review-dropbox-lifecycle-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_REVIEW_DROPBOX_LIFECYCLE_HARDENING.md`
- Reviewed main: `7a8ad89c84263043d2fb127576ba0aba47789f06`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Visual review: `none`
- Goal: Independently verify the new authoring-chat, autonomous-claim, summary-backlink and Dropbox reviewed-evidence cleanup contract.
- Reviewed implementation acceptance: Reconstruct and verify every Acceptance item from the archived implementation packet, especially exact backlink enforcement and path-safe/idempotent cleanup.
- Review evidence: Reuse focused implementation tests and durable receipts, then gather only missing adversarial proof.
- Correction threshold: Any route that deletes unreviewed/retained/wrong-run Dropbox content, clears a newer LATEST pointer, lets a recorded authoring-chat backlink disappear from the durable summary, or weakens ready/auto claim gating is blocking.
- Focused validation: Re-run the visual-review handoff unit tests, focused agent workflow tests, AI-context/review-pairing validators, and changed-file validation.
- Review focus: Legacy packet compatibility; claim receipt truth; exact summary backlink matching; cleanup schema/identity/retention safety; idempotence; authoring-chat visual-review round trip; no coupling to destructive ChatGPT connector deletion.
- Acceptance: Findings-first independent review with stable cycle IDs and a durable passed/findings/human_required receipt. Do not edit reviewed implementation code.
- Non-goals: Do not redesign Dropbox implementation-input transport, Asset V2, or subjective review policy.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Return to the owning feature DAG.`
- Blockers or open questions: `none`
