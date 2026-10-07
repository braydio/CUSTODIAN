# REVIEW: AWAKENING 04→05 DIRECT CONNECTOR CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-room-connectors-polish`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `awakening-room-connectors-polish`
- Locks: `awakening-runtime, awakening-art-registration, awakening-04-05-connector-presentation`
- Review: `none`
- Review target workstream: `awakening-room-connectors-polish`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_ROOM_CONNECTORS_POLISH.md`
- Reviewed main: `41a2f8e17c49d58e3a527d165afb998f8243bb70`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Independently verify that the landed 04→05 correction uses the exact approved `connector.png`, preserves its complete alpha silhouette, derives the runtime canvas/transform from the current source and room contacts rather than the legacy 1024×576 placement, and leaves gameplay traversal unchanged.
- Reviewed implementation acceptance: Reuse every acceptance item from archived `AWAKENING_ROOM_CONNECTORS_POLISH.md`. In particular, prove no nontransparent source pixel was cropped, no old room-strip/reconstruction product remains scene-bound, and the final measured transform registers both Locker and Dust contacts while preserving the exact dogleg gameplay footprint.
- Review evidence: implementation source receipt/hash/dimensions/alpha bounds; Asset V2 family/catalog/runtime receipts; source-vs-runtime silhouette comparison; measured room-contact registration; scene binding; bidirectional traversal telemetry; compact join evidence only if machine checks cannot settle a visible seam question.
- Correction threshold: Any source mismatch, cropped nontransparent region, use of remembered/legacy dimensions as authority, hidden nonuniform stretch, wrong world registration, missing authored connector chunk, residual compositor/room-strip authority, altered gameplay geometry, whole-room partial-alpha join, or Asset V2/catalog mismatch is blocking.
- Focused validation: Re-run family status/doctor; source-vs-runtime alpha-bound/full-silhouette assertion; Awakening scene/geometry/progression; bidirectional 04→05 scenario; inspect exact scene texture binding and effective z/alpha.
- Review focus: The user's current defect is concrete, not subjective. The correct image must be complete and correctly placed. Do not pass merely because a 1024×576 sprite exists or because the route is traversable.
- Acceptance: Findings-first independent review. Pass only when exact-source provenance, full silhouette preservation, measured registration, unchanged dogleg traversal, and direct Asset V2 binding are all proven. Blocking defects/material evidence gaps create the normal bounded correction/re-review pair.
- Non-goals: No Dust/Locker room redesign; no 05→06 connection implementation; no Hub work; no replacement art generation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `awakening-lower-upper-spine-connection`
- Next packet state: `ready after this review passes`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Refresh reason: `none`
- Next action: On pass, release the lower→upper Awakening spine connection slice.
- Blockers or open questions: `none`
