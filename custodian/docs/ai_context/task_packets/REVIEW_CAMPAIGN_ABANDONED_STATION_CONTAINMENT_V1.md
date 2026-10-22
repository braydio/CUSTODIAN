# REVIEW: STATION CONTAINMENT CHOICE + COMPLETION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-abandoned-station-containment-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-abandoned-station-containment-v1`
- Locks: `procgen-authored-alpine-station`
- Review: `none`
- Review target workstream: `campaign-abandoned-station-containment-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_ABANDONED_STATION_CONTAINMENT_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `none`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: Both choices independently tested; no duplicate completion across repeat interactions and run revisit; no choice following expiry; all exits/normal objectives remain available.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New containment resolution smoke, S1/S2 and mission/WorldEventMemory regressions; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: S1/S2 weather/timer and local failure; global CampaignOutcome, HubState and extraction ownership. Also check no new continuity physics engine, proven origin of anomalies, new campaignoutcome schema, compulsory story lock.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Dependency assumption
The implementation `campaign-abandoned-station-containment-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
