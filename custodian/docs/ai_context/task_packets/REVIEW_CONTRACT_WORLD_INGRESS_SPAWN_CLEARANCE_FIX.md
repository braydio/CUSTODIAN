# REVIEW: CONTRACT WORLD INGRESS SPAWN CLEARANCE FIX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-contract-world-ingress-spawn-clearance-fix`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `contract-world-ingress-spawn-clearance-fix`
- Locks: `contract-world-loader`
- Review: `none`
- Review target workstream: `contract-world-ingress-spawn-clearance-fix`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CONTRACT_WORLD_INGRESS_SPAWN_CLEARANCE_FIX.md`
- Reviewed main: `5c06a1c2fb950b944185385e0b04793a88c62544`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the reproducible Forlorn Ritualant surface-ingress spawn collision is actually prevented by authority/order correctness rather than hidden by a seed-specific relocation hack.
- Reviewed implementation acceptance: Reuse all acceptance items from the implementation packet. Treat structural-ingress-before-Operator ordering, canonical clearance-query reuse, safe fallback selection, deterministic collision-clear spawn, required Ritualant ingress preservation, and no generation/AR2 drift as explicit obligations.
- Review evidence: Archived implementation packet/summary; live ContractWorldLoader install order; WorldIngressSpawner placement + dressing-clearance claim; ProcGenTilemap clearance query; focused overlap regression; Ash Bell/world-ingress required-contract regressions.
- Correction threshold: Any path that can still choose the Operator position before ingress structural claims, any spawn candidate allowed inside ingress clearance, any loss of required Ritualant ingress/route validity, nondeterministic fallback spawn, or a test that does not actually overlap the old preferred spawn with authored ingress collision is correction-worthy.
- Focused validation: First inspect/run the dedicated overlap regression and require it to demonstrate the pre-fix failure shape rather than only an arbitrary safe map. Verify the selected world position with a real Operator-sized collision query. Then rerun world-ingress, Ash Bell presentation, required-ingress sweep, population placement, stuck-pocket/camera regressions and changed-file checks.
- Review focus: Ensure one authority chain: ingress placement claims structural space, then ContractWorldLoader selects final actor position from the resulting map/clearance truth. Reject solutions that duplicate clearance rectangles in the loader, weaken Ash Bell collision, hardcode a different spawn, or paper over the issue with a one-frame teleport after physics begins.
- Acceptance: Produce a findings-first independent review. Blocking defects/material proof gaps create `contract-world-ingress-spawn-clearance-fix-review-corrections-1` plus paired re-review. A clean/non-blocking pass closes the hotfix.
- Non-goals: Do not review AR2 shader aesthetics, redesign world placement extraction, change Forlorn Underground, or broaden into generic collision resolution.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: Hotfix is closed after a clean/non-blocking review.
- Blockers or open questions: none
