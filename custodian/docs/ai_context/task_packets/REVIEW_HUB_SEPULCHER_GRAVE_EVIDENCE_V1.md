# REVIEW: SEPULCHER GRAVE EVIDENCE + HUB PERSISTENCE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-sepulcher-grave-evidence-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `hub-sepulcher-grave-evidence-v1`
- Locks: `hub-event-persistence, hub-sepulcher`
- Review: `none`
- Review target workstream: `hub-sepulcher-grave-evidence-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_SEPULCHER_GRAVE_EVIDENCE_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Visual review: `none`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: All three readings reachable in order using real Operator; fixed date and three identities accurate; repeated spam cannot skip; reload/snapshot restores exact stage; legacy snapshot defaults empty; other HubState fields bit-for-bit preserved.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New small grave-stage/persistence smoke; HubState outcome+scenario regression and hub_first_set_blockout_smoke; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Hub nav, both connectors, Dais prewarm, Crown/Muster routes and existing HubState keys. Also check no adjudication/flower yet; no generic quest framework, camera takeover, new art, or alternate hub state singleton.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit and push only the review receipt, review packet lifecycle/archive metadata, required closing summary and bounded correction/re-review packets; do not edit reviewed production implementation or unrelated work.`

## Dependency assumption
The implementation `hub-sepulcher-grave-evidence-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
