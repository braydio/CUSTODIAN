# REVIEW: CONVOY TRACE + BOUNDED SALVAGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-empty-convoy-recovery-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-empty-convoy-recovery-v1`
- Locks: `procgen-authored-convoy, campaign-encounter`
- Review: `none`
- Review target workstream: `campaign-empty-convoy-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_EMPTY_CONVOY_RECOVERY_V1.md`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `none`
- Goal: Independently falsify the implementation packet's acceptance against landed main, not just its claimed unit tests.
- Reviewed implementation acceptance: No duplicate reward after spam, reload, reconnection/revisit; no negative/unknown item; evidence available without reward; non-convoy campaigns unaffected.
- Review evidence: Archived implementation packet/summary; scoped runtime diff; focused smoke; directly affected regressions.
- Correction threshold: Acceptance failure or missing material proof is blocking; optional polish goes to deferred work. Create bounded correction + paired review if blocking.
- Focused validation: New convoy-evidence/ledger exactly-once smoke + C1/C2; changed-file validation. Prefer objective state/position/scripted metrics; at most two ROI stills when readability cannot be settled structurally.
- Review focus: Seed-specific optional site, existing threat semantics and resource ledger authority. Also check no new currency schema, cross-run reward, restored scout requirement, resolved cargo identity.
- Acceptance: Publish independent findings-first receipt with stable R0-NN findings and proof; no implementation edits in review. On success archive complete so the declared successor can claim.
- Non-goals: Do not implement new event functionality, art, generalized event infrastructure or opportunistic refactors.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Dependency assumption
The implementation `campaign-empty-convoy-recovery-v1` has landed and its archive is accessible at the named path. Inspect the real implementation's chosen private seams; judge the contract, not proposed function names.

## Handoff
- Next action: On passing review, unlock the next slice in this event chain if any.
- Blockers or open questions: Implementation must archive complete.
