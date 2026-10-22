# REVIEW: ROAD PROCESSION SPATIAL BEAT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-road-empty-procession-sequence-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `hub-road-empty-procession-sequence-v1`
- Locks: `hub-road-procession`
- Review: `none`
- Review target workstream: `hub-road-empty-procession-sequence-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_ROAD_EMPTY_PROCESSION_SEQUENCE_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `conditional`
- Goal: Independently falsify the landed playable **post-Awakening Hub** Procession against the original acceptance and real-Operator traversal, not merely scripts.
- Reviewed implementation acceptance: Single activation, correct south/mid/north order, safe pause/Hub leave/return, replay does not relaunch full spectacle, no plate changes, clear traversal.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; H1/H2 first-set walking/clearance proof; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New procession-timeline smoke, Road/Hub geometry and HubState snapshot regressions; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Inspect real HubRuntimeHost -> HubFirstSetMap path and H1 route clearance; the Awakening Road scene is NOT the playable north-processional authority. Normal player control, Dais route, Road collisions and Crown ingress. Also check no testimony station yet, new lighting scheduler, cutscene system, new artwork.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Runtime boundary
The first-set blockout/nav owns Hub North Processional traversability; Awakening deliberately does not build that segment. Existing five Road plate pairs are presentation-only and cannot prove route/triggers. Reject trigger positions that a real Operator cannot reach via Hub entry and ForumSouth without teleportation.

## Dependency assumption
The implementation `hub-road-empty-procession-sequence-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
