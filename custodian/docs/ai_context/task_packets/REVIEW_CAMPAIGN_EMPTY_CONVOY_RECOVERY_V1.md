# REVIEW: CONVOY TRACE + BOUNDED SALVAGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-empty-convoy-recovery-v1`
- Kind: `review`
- Status: `blocked`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `campaign-empty-convoy-recovery-v1`
- Locks: `procgen-authored-convoy, campaign-encounter`
- Review: `none`
- Review target workstream: `campaign-empty-convoy-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_EMPTY_CONVOY_RECOVERY_V1.md`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
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


## Owner-waived prelaunch disposition

- Disposition: `owner_waived_prelaunch`
- Implementation commit and landed main: `e346eaea2f6b9a2068f160f58b50d090427bda61`
- Validation: report SHA-256 `47c768aa45894545c0f6e1b101faf3ecd99c7420088a9213e25188cebcf53ccf`; 8/8 selected checks passed with complete changed-source coverage.
- Gate result: read-only host source gate reproduced the expected failure: `changed validation manifest has no authenticated source-span provenance`. The implementation changed `custodian/tools/validation/validation_manifest.json`; no accepted historical exact-source attestation covers this change.
- Reviewer: not launched; review not performed; no independent PASS.
- Authorization: final C3 closeout control in https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
