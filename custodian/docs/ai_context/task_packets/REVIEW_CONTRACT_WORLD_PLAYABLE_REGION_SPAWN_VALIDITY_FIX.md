# REVIEW: CONTRACT WORLD PLAYABLE REGION SPAWN VALIDITY FIX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-contract-world-playable-region-spawn-validity-fix`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `contract-world-playable-region-spawn-validity-fix`
- Locks: `contract-world-loader, procgen-playability`
- Review: `none`
- Review target workstream: `contract-world-playable-region-spawn-validity-fix`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX.md`
- Reviewed main: `4fab463d2c347327b48a7417a41e6eada3b63ee1`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Summary backlink: Every durable review/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Independently prove that current-main contract-world start placement can no longer put the Operator on locally painted but disconnected/outside-playable floor, and that the fix consumes existing procgen playability authority instead of creating a new loader-owned connectivity system.
- Reviewed implementation acceptance: Reuse the implementation packet acceptance exactly, with particular scrutiny on accepted/main reachable-component membership, fallback behavior, deterministic selection, fail-closed behavior, and preservation of the earlier ingress-clearance fix.
- Review evidence: Archived implementation packet/summary; final loader spawn predicate; existing procgen/playability owner/query used by the patch; focused bad-component fixture; RuntimeWalkableBoundary/playability regression; ingress-clearance regression; current-main playtest reproduction recorded in the authoring chat.
- Correction threshold: Any path where painted floor alone can satisfy final spawn validity, any loader-local duplicate flood-fill/component registry, fallback bypass, post-camera teleport workaround, loss of deterministic selection, or failure to reproduce a truly disconnected/outside-playable candidate is correction-worthy.
- Focused validation: Inspect the fixture first and confirm the deliberately invalid candidate really is floor/wall-clear yet excluded from the accepted playable component. Verify final Operator tile against the production authority, not just the test's duplicate expectation. Re-run ingress clearance, route playability, walkable boundary, contract placement and camera handoff checks.
- Review focus: The core invariant is "spawn belongs to authoritative playable world", not "spawn has a floor sprite". Do not accept a solution that merely moves the bad test seed or enlarges the map.
- Acceptance: Findings-first independent review. Blocking defects/material gaps create `contract-world-playable-region-spawn-validity-fix-review-corrections-1` plus paired re-review. A clean/non-blocking pass releases AR3's initial-spawn presentation dependency.
- Non-goals: No AR3 tuning, map-size recommendation, procgen topology redesign, or Sundered overlook work.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `procgen-archive-resolve-semantic-echo`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Next action: A clean review satisfies AR3's spawn-correctness prerequisite.
- Blockers or open questions: none.
