# REVIEW: SEPULCHER GRAVE ATTESTATION + PALE GROWTH

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-sepulcher-grave-resolution-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `hub-sepulcher-grave-resolution-v1`
- Locks: `hub-event-persistence, hub-sepulcher`
- Review: `none`
- Review target workstream: `hub-sepulcher-grave-resolution-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_SEPULCHER_GRAVE_RESOLUTION_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Visual review: `conditional`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: Both choices test separately, exactly-once on button spam and snapshot restore; flower/growth appears after resolution only and never blocks collision; post-resolution reread works; no Contract side effects.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New grave-resolution smoke + G1 smoke + HubState persistence + Hub first-set traversal; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: G1 evidence progression, HubState snapshot/restore, normal optional route traversal. Also check no npc/dialogue framework, doctrine reward, combat, required raster art or forced story progression.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit and push only the review receipt, review packet lifecycle/archive metadata, required closing summary and bounded correction/re-review packets; do not edit reviewed production implementation or unrelated work.`

## Dependency assumption
The implementation `hub-sepulcher-grave-resolution-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
