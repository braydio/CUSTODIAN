# REVIEW: FORUM HEARING EVIDENCE PLINTHS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-forum-hearing-evidence-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `hub-forum-hearing-evidence-v1`
- Locks: `hub-forum-hearing, hub-event-persistence`
- Review: `none`
- Review target workstream: `hub-forum-hearing-evidence-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_FORUM_HEARING_EVIDENCE_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Visual review: `none`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: 3 distinct reachable inspections persist through Hub transitions; Dais behavior and generation_count unchanged throughout hearing interaction; no duplicate prompts or collision obstruction.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: Focused 3-inspection hearing smoke; hub_forum_adjudication_smoke, HubState persistence, Hub blockout; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Dais interaction priority, accepted scenario and prewarm count; Forum ingress/exit clearance. Also check no hearing decision yet, new independent persistence manager, cinematic camera, art commission.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit and push only the review receipt, review packet lifecycle/archive metadata, required closing summary and bounded correction/re-review packets; do not edit reviewed production implementation or unrelated work.`

## Dependency assumption
The implementation `hub-forum-hearing-evidence-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
