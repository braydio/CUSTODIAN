# REVIEW: STATION SERVICES + LOCAL 90S STABILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-abandoned-station-stability-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-abandoned-station-stability-v1`
- Locks: `procgen-authored-alpine-station`
- Review: `none`
- Review target workstream: `campaign-abandoned-station-stability-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_ABANDONED_STATION_STABILITY_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `conditional`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: Service permutations equivalent, timer exactly 90 sim seconds, expiry and success disjoint, no duplicate service; weather outside site unchanged; leaving event can't softlock campaign.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New fixed-step station-stability smoke and S1 multi-seed + environment/lighting smoke; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Weather schedule ownership, deterministic fixed-step, normal combat and world generation. Also check no new time system, mission-wide failure, invented weather sprites, forced station decision.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Dependency assumption
The implementation `campaign-abandoned-station-stability-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
