# REVIEW: ROAD WITNESS TESTIMONY + REVISIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-road-procession-testimony-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `hub-road-procession-testimony-v1`
- Locks: `hub-road-procession`
- Review: `none`
- Review target workstream: `hub-road-procession-testimony-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_ROAD_PROCESSION_TESTIMONY_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Visual review: `conditional`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: Three testimonies individually readable; completion persisted and reversible only by explicit state reset; single revisit bell, no re-triggers on collider spam; controls/navigation unaffected.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New testimony/revisit smoke + P1 timeline + Hub route and HubState persist regressions. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: P1 three-beat timing, 5 Road plates, uninterrupted navigation. Also check no apparition sprites, dialogue-tree engine, additional world-state manager or global audio rewrite.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit and push only the review receipt, review packet lifecycle/archive metadata, required closing summary and bounded correction/re-review packets; do not edit reviewed production implementation or unrelated work.`

## Dependency assumption
The implementation `hub-road-procession-testimony-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
