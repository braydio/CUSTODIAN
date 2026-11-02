# REVIEW: GENERATED CONVOY POCKET PLACEMENT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-empty-convoy-placement-v1`
- Kind: `review`
- Status: `blocked`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-empty-convoy-placement-v1`
- Locks: `procgen-authored-convoy`
- Review: `none`
- Review target workstream: `campaign-empty-convoy-placement-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_EMPTY_CONVOY_PLACEMENT_V1.md`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `conditional`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: Fixed-seed replay stable, multi-seed safety valid, no overlapping required objectives/paths/clearance, absent valid pocket -> safe no-op; unload/reveal repeat same placement.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New convoy-placement fixed multi-seed smoke; existing procgen placement/nav/streaming validations, changed-file closeout. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Route ingress, objectives, biome/material surfaces, navigation/collision, other landmarks and accepted seed. Also check no convoy combat, salvage, new vehicle raster, restorability, topology rewrite or spawned hostile units.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Dependency assumption
The implementation `campaign-empty-convoy-placement-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Owner disposition
- Disposition: `owner_waived_prelaunch`
- Review workstream: `review-campaign-empty-convoy-placement-v1`
- Review run: `not-created`; read-only exact source-scope preflight completed before claim or reviewer checkout.
- Implementation commit: `47fd0755203dc22fb7149889253154741c78689b`
- Verified landing: `0cdb0c8c8b583a166df06315a3ec01119ce675c1`
- Implementation validation: `5/5 passed` with complete changed-source coverage and zero failed, timed out, skipped, or infrastructure-error checks; report SHA-256 `bc0db96d3a41e6cbb32ba06935eb1464c0d96a0ee1cfbfe8b63ee63d35219b50`.
- Review launch: The read-only exact host source-scope preflight blocked before claim because `changed validation manifest is not covered by an accepted exact source attestation`.
- Reviewer verdict or acceptance: `none`; no independent reviewer process launched and no PASS or acceptance was produced.
- Further review, source-attestation recovery, or correction authorized: `no` for this exact landed implementation.
- Administrative disposition: closed by explicit coordinator/project-owner waiver; this packet remains blocked/manual, not complete, independently accepted, or claimable.
- Authorizing planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
