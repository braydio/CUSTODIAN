# REVIEW AGENT PAIRED REVIEW GODOT CACHE ACCESS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-godot-cache-access-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-godot-cache-access-v1`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `agent-paired-review-godot-cache-access-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_GODOT_CACHE_ACCESS_V1.md`
- Reviewed main: `075025f41a6a7f6bafb6df13a816d54a23dc87af`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove the paired-review sandbox gains only the CUSTODIAN validation cache access it needs while retaining real Godot concurrency controls and restricted Git authority.
- Reviewed implementation acceptance: Reuse every acceptance item from the archived implementation packet.
- Review evidence: Landed runner diff; paired-review argv/path fixture; real `GodotJobBudget`/project-lock fixture; sandbox Git-write negative control; changed-file report.
- Correction threshold: Any ability to write shared Git metadata, a split/private machine-wide budget namespace, injected lock disable, overly broad home-directory access, or inability to run ordinary locked validation from the restricted reviewer requires a correction.
- Focused validation: Independently exercise paired-review launch construction and the real lock smoke; verify the same job-budget slot namespace is visible across reviewer/coordinator processes; verify Git metadata restrictions remain intact; run changed-file validation, AI-context/pair/index checks and `git diff --check`.
- Review focus: Least writable sandbox scope; no lock bypass; same machine-wide budget; no reviewer Git authority expansion; backwards compatibility with existing paired-review coordinator closeout.
- Acceptance: Fresh findings-first review with zero blocking defects/material evidence gaps for pass.
- Non-goals: No recovery of historical review runs; no gameplay changes; no generalized sandbox permission redesign.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: `No successor; future paired reviews consume the hardened runner.`
- Blockers or open questions: `none`
